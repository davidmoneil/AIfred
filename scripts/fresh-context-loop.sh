#!/bin/bash
# fresh-context-loop.sh - Execute tasks in fresh Claude instances
#
# Purpose: Run multiple tasks with fresh context per task (no context pollution)
# Source Pattern: snarktank/ralph (fresh context per iteration)
#
# Usage:
#   ./fresh-context-loop.sh <orchestration.yaml>
#   ./fresh-context-loop.sh --tasks "task1|task2|task3"
#   ./fresh-context-loop.sh --max-iterations 5 <orchestration.yaml>
#
# Features:
#   - Each task runs in a new Claude instance
#   - Progress persists via git commits + task file updates
#   - Loops until all tasks complete or max iterations
#   - Desktop notification when complete

set -euo pipefail

# ============================================================================
# Configuration
# ============================================================================

# Auto-detect project directory (use git root if available, else PWD)
PROJECT_DIR="${PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || echo "$PWD")}"
LOG_DIR="$PROJECT_DIR/.claude/logs/fresh-context"
STATE_FILE="$LOG_DIR/.loop-state.json"

# Defaults
DEFAULT_MAX_ITERATIONS=10
DEFAULT_MAX_TURNS=15
DEFAULT_MAX_BUDGET=5.00
DEFAULT_FAIL_THRESHOLD=3  # Skip task after this many failures

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ============================================================================
# Functions
# ============================================================================

log() {
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

log_success() {
    log "${GREEN}$1${NC}"
}

log_warning() {
    log "${YELLOW}WARNING: $1${NC}"
}

log_error() {
    log "${RED}ERROR: $1${NC}"
}

show_help() {
    cat << 'EOF'
fresh-context-loop.sh - Execute tasks in fresh Claude instances

USAGE:
    fresh-context-loop.sh [OPTIONS] <orchestration.yaml>
    fresh-context-loop.sh --tasks "task1|task2|task3" [OPTIONS]

OPTIONS:
    -h, --help              Show this help message
    -m, --max-iterations N  Maximum loop iterations (default: 10)
    -t, --max-turns N       Max Claude turns per task (default: 15)
    -b, --max-budget N      Max USD per task (default: 5.00)
    -f, --fail-threshold N  Skip task after N failures (default: 3)
    --dry-run               Show what would run without executing
    --tasks "t1|t2|t3"      Pipe-separated task list (instead of YAML)
    --verbose               Show detailed output

EXAMPLES:
    # Run from orchestration file
    ./fresh-context-loop.sh .claude/orchestration/my-feature.yaml

    # Run with inline tasks
    ./fresh-context-loop.sh --tasks "Write tests for auth module|Fix linting errors"

    # Dry run to see tasks
    ./fresh-context-loop.sh --dry-run .claude/orchestration/my-feature.yaml

TASK FILE FORMAT:
    Uses standard orchestration YAML. Each task needs:
    - description: What to do
    - done_criteria: How to verify completion
    - status: pending | in_progress | completed | blocked

HOW IT WORKS:
    1. Read task list from YAML or --tasks argument
    2. Find first pending task
    3. Spawn fresh Claude instance with ONLY that task
    4. Claude executes, commits, marks task complete
    5. Loop to step 2 until all tasks done or max iterations

EOF
}

# Send desktop notification (cross-platform)
notify() {
    local title="$1"
    local message="$2"

    if command -v notify-send &>/dev/null; then
        notify-send "$title" "$message" 2>/dev/null || true
    elif command -v osascript &>/dev/null; then
        osascript -e "display notification \"$message\" with title \"$title\"" 2>/dev/null || true
    fi
}

# Find yq binary
find_yq() {
    for yq_path in "yq" "$HOME/.local/bin/yq" "/usr/local/bin/yq" "/snap/bin/yq"; do
        if command -v "$yq_path" &>/dev/null 2>&1 || [ -x "$yq_path" ]; then
            echo "$yq_path"
            return 0
        fi
    done
    return 1
}

# Parse orchestration YAML to extract pending tasks
parse_orchestration_yaml() {
    local yaml_file="$1"
    local yq_bin

    yq_bin=$(find_yq) || {
        log_error "yq is required to parse YAML. Install with: wget -qO ~/.local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 && chmod +x ~/.local/bin/yq"
        exit 1
    }

    "$yq_bin" -o=json '[.phases[].tasks[] | select(.status == "pending" or .status == "in_progress")]' "$yaml_file" 2>/dev/null || echo "[]"
}

# Update task status in YAML file
update_task_status() {
    local yaml_file="$1"
    local task_id="$2"
    local new_status="$3"
    local commit_hash="${4:-}"
    local yq_bin

    yq_bin=$(find_yq) || {
        log_warning "yq not available, cannot update YAML"
        return 1
    }

    "$yq_bin" -i "(.phases[].tasks[] | select(.id == \"$task_id\")).status = \"$new_status\"" "$yaml_file" 2>/dev/null

    if [ -n "$commit_hash" ]; then
        "$yq_bin" -i "(.phases[].tasks[] | select(.id == \"$task_id\")).commits += [\"$commit_hash\"]" "$yaml_file" 2>/dev/null
    fi
}

# Initialize loop state file
init_state() {
    local task_source="$1"
    mkdir -p "$LOG_DIR"

    cat > "$STATE_FILE" << EOF
{
    "started_at": "$(date -Iseconds)",
    "task_source": "$task_source",
    "iterations": 0,
    "completed_tasks": [],
    "failed_tasks": [],
    "current_task": null
}
EOF
}

# Update loop state
update_state() {
    local key="$1"
    local value="$2"

    if [ -f "$STATE_FILE" ]; then
        if command -v jq &>/dev/null; then
            local tmp=$(mktemp)
            jq ".$key = $value" "$STATE_FILE" > "$tmp" && mv "$tmp" "$STATE_FILE"
        fi
    fi
}

# Build the prompt for Claude
build_task_prompt() {
    local task_description="$1"
    local done_criteria="$2"
    local task_id="${3:-}"

    cat << EOF
FRESH CONTEXT EXECUTION MODE

You are executing a single task from a larger orchestration. Focus ONLY on this task.
After completion, commit your changes and exit.

## Your Task
$task_description

## Done Criteria
$done_criteria

## Instructions
1. Read any files needed to understand context
2. Implement the change
3. Verify it meets the done criteria
4. Commit with message format: "[fresh-context] $task_id - <summary>"
5. Report completion status

## Important
- This is a FRESH context - you have no memory of previous tasks
- Do NOT try to do more than this one task
- If blocked, report clearly and exit
- On success, clearly state "TASK COMPLETED"
- On failure/blocked, state "TASK BLOCKED: <reason>"
EOF
}

# Run a single task in fresh Claude instance
execute_task() {
    local task_desc="$1"
    local done_criteria="$2"
    local task_id="${3:-}"
    local output_file="$LOG_DIR/task-$(date +%Y%m%d-%H%M%S).json"

    local prompt
    prompt=$(build_task_prompt "$task_desc" "$done_criteria" "$task_id")

    log "${BLUE}Executing task: ${task_id:-task}${NC}"
    log "Description: $task_desc"

    if [ "$DRY_RUN" = "true" ]; then
        log "[DRY RUN] Would execute Claude with prompt:"
        echo "$prompt" | head -20
        echo "..."
        return 0
    fi

    cd "$PROJECT_DIR"

    local ALLOWED_TOOLS="Read,Glob,Grep,Edit,Write,Bash(mkdir:*),Bash(git add:*),Bash(git commit:*),Bash(git status:*),Bash(ls:*),Bash(cat:*),mcp__filesystem__*,mcp__git__*"

    local result
    if result=$(claude -p "$prompt" \
        --max-turns "$MAX_TURNS" \
        --output-format json \
        --no-session-persistence \
        --allowedTools "$ALLOWED_TOOLS" \
        2>&1); then

        echo "$result" > "$output_file"

        if echo "$result" | grep -qi "TASK COMPLETED\|task completed successfully"; then
            log_success "Task completed: $task_id"
            return 0
        elif echo "$result" | grep -qi "TASK BLOCKED\|blocked\|cannot proceed"; then
            log_warning "Task blocked: $task_id"
            return 2
        else
            if git -C "$PROJECT_DIR" status --porcelain | grep -q .; then
                log_success "Task appears complete (changes detected)"
                return 0
            else
                log_warning "Task result unclear"
                return 1
            fi
        fi
    else
        log_error "Claude execution failed"
        echo "$result" > "$output_file"
        return 1
    fi
}

# ============================================================================
# Main Logic
# ============================================================================

MAX_ITERATIONS="$DEFAULT_MAX_ITERATIONS"
MAX_TURNS="$DEFAULT_MAX_TURNS"
MAX_BUDGET="$DEFAULT_MAX_BUDGET"
FAIL_THRESHOLD="$DEFAULT_FAIL_THRESHOLD"
DRY_RUN="false"
VERBOSE="false"
TASK_SOURCE=""
INLINE_TASKS=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -m|--max-iterations)
            MAX_ITERATIONS="$2"
            shift 2
            ;;
        -t|--max-turns)
            MAX_TURNS="$2"
            shift 2
            ;;
        -b|--max-budget)
            MAX_BUDGET="$2"
            shift 2
            ;;
        -f|--fail-threshold)
            FAIL_THRESHOLD="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN="true"
            shift
            ;;
        --verbose)
            VERBOSE="true"
            shift
            ;;
        --tasks)
            INLINE_TASKS="$2"
            shift 2
            ;;
        -*)
            log_error "Unknown option: $1"
            show_help
            exit 1
            ;;
        *)
            TASK_SOURCE="$1"
            shift
            ;;
    esac
done

if [ -z "$TASK_SOURCE" ] && [ -z "$INLINE_TASKS" ]; then
    log_error "No task source provided"
    show_help
    exit 1
fi

if [ -n "$TASK_SOURCE" ] && [ ! -f "$TASK_SOURCE" ]; then
    log_error "Task file not found: $TASK_SOURCE"
    exit 1
fi

mkdir -p "$LOG_DIR"
LOOP_LOG="$LOG_DIR/loop-$(date +%Y%m%d-%H%M%S).log"

echo "" | tee -a "$LOOP_LOG"
log "========================================" | tee -a "$LOOP_LOG"
log "Fresh Context Loop Starting"             | tee -a "$LOOP_LOG"
log "========================================" | tee -a "$LOOP_LOG"
log "Project: $PROJECT_DIR"                   | tee -a "$LOOP_LOG"
log "Max iterations: $MAX_ITERATIONS"         | tee -a "$LOOP_LOG"
log "Max turns per task: $MAX_TURNS"          | tee -a "$LOOP_LOG"
log "Fail threshold: $FAIL_THRESHOLD"         | tee -a "$LOOP_LOG"
log "Dry run: $DRY_RUN"                       | tee -a "$LOOP_LOG"

init_state "${TASK_SOURCE:-inline}"

declare -A TASK_FAILURES

ITERATION=0
COMPLETED=0
FAILED=0

while [ "$ITERATION" -lt "$MAX_ITERATIONS" ]; do
    ITERATION=$((ITERATION + 1))
    log "" | tee -a "$LOOP_LOG"
    log "--- Iteration $ITERATION of $MAX_ITERATIONS ---" | tee -a "$LOOP_LOG"

    if [ -n "$INLINE_TASKS" ]; then
        IFS='|' read -ra TASK_ARRAY <<< "$INLINE_TASKS"
        TASK_DESC=""
        TASK_ID=""

        for i in "${!TASK_ARRAY[@]}"; do
            task="${TASK_ARRAY[$i]}"
            task_id="inline-$i"
            failures="${TASK_FAILURES[$task_id]:-0}"

            if grep -q "\"$task_id\"" "$STATE_FILE" 2>/dev/null; then
                continue
            fi
            if [ "$failures" -ge "$FAIL_THRESHOLD" ]; then
                continue
            fi

            TASK_DESC="$task"
            TASK_ID="$task_id"
            DONE_CRITERIA="Task completed successfully"
            break
        done
    else
        TASKS_JSON=$(parse_orchestration_yaml "$TASK_SOURCE")

        if [ -z "$TASKS_JSON" ] || [ "$TASKS_JSON" = "[]" ]; then
            log_success "All tasks completed!" | tee -a "$LOOP_LOG"
            break
        fi

        if command -v jq &>/dev/null; then
            TASK_ID=$(echo "$TASKS_JSON" | jq -r '.[0].id // empty' 2>/dev/null || echo "")
            TASK_DESC=$(echo "$TASKS_JSON" | jq -r '.[0].description // empty' 2>/dev/null || echo "")
            DONE_CRITERIA=$(echo "$TASKS_JSON" | jq -r '.[0].done_criteria // "Task completed successfully"' 2>/dev/null || echo "Task completed successfully")
        else
            log_error "jq is required to parse task JSON"
            exit 1
        fi
    fi

    if [ -z "$TASK_DESC" ]; then
        log_success "All tasks completed or skipped!" | tee -a "$LOOP_LOG"
        break
    fi

    log "Task ID: $TASK_ID" | tee -a "$LOOP_LOG"
    log "Task: $TASK_DESC" | tee -a "$LOOP_LOG"

    update_state "iterations" "$ITERATION"
    update_state "current_task" "\"$TASK_ID\""

    if [ "$DRY_RUN" != "true" ] && [ -n "$TASK_SOURCE" ] && [ -f "$TASK_SOURCE" ]; then
        update_task_status "$TASK_SOURCE" "$TASK_ID" "in_progress"
    fi

    RESULT=0
    execute_task "$TASK_DESC" "${DONE_CRITERIA:-Task completed successfully}" "$TASK_ID" || RESULT=$?

    case $RESULT in
        0)
            COMPLETED=$((COMPLETED + 1))
            log_success "Task $TASK_ID completed (iteration $ITERATION)" | tee -a "$LOOP_LOG"

            if [ "$DRY_RUN" != "true" ] && [ -n "$TASK_SOURCE" ] && [ -f "$TASK_SOURCE" ]; then
                COMMIT_HASH=$(git -C "$PROJECT_DIR" rev-parse HEAD 2>/dev/null || echo "")
                update_task_status "$TASK_SOURCE" "$TASK_ID" "completed" "$COMMIT_HASH"
            fi

            if [ "$DRY_RUN" != "true" ]; then
                update_state "completed_tasks" "(.completed_tasks + [\"$TASK_ID\"])"
            fi
            ;;
        2)
            log_warning "Task $TASK_ID blocked - will skip" | tee -a "$LOOP_LOG"
            TASK_FAILURES[$TASK_ID]=$FAIL_THRESHOLD

            if [ "$DRY_RUN" != "true" ] && [ -n "$TASK_SOURCE" ] && [ -f "$TASK_SOURCE" ]; then
                update_task_status "$TASK_SOURCE" "$TASK_ID" "blocked"
            fi
            ;;
        *)
            TASK_FAILURES[$TASK_ID]=$((${TASK_FAILURES[$TASK_ID]:-0} + 1))
            local failures="${TASK_FAILURES[$TASK_ID]}"

            if [ "$failures" -ge "$FAIL_THRESHOLD" ]; then
                FAILED=$((FAILED + 1))
                log_error "Task $TASK_ID failed $failures times - skipping" | tee -a "$LOOP_LOG"
                update_state "failed_tasks" "(.failed_tasks + [\"$TASK_ID\"])"
            else
                log_warning "Task $TASK_ID failed (attempt $failures of $FAIL_THRESHOLD)" | tee -a "$LOOP_LOG"
            fi
            ;;
    esac
done

echo "" | tee -a "$LOOP_LOG"
log "========================================" | tee -a "$LOOP_LOG"
log "Fresh Context Loop Complete" | tee -a "$LOOP_LOG"
log "========================================" | tee -a "$LOOP_LOG"
log "Total iterations: $ITERATION" | tee -a "$LOOP_LOG"
log "Completed tasks: $COMPLETED" | tee -a "$LOOP_LOG"
log "Failed tasks: $FAILED" | tee -a "$LOOP_LOG"
log "Log file: $LOOP_LOG" | tee -a "$LOOP_LOG"

if [ "$COMPLETED" -gt 0 ] && [ "$FAILED" -eq 0 ]; then
    notify "Fresh Context Loop Complete" "All $COMPLETED tasks completed successfully!"
elif [ "$FAILED" -gt 0 ]; then
    notify "Fresh Context Loop Complete" "$COMPLETED completed, $FAILED failed"
else
    notify "Fresh Context Loop Complete" "No tasks were executed"
fi

if [ "$FAILED" -gt 0 ]; then
    exit 1
elif [ "$COMPLETED" -eq 0 ] && [ "$ITERATION" -ge "$MAX_ITERATIONS" ]; then
    log_warning "Max iterations reached without completing any tasks"
    exit 2
else
    exit 0
fi
