#!/bin/bash
# executor.sh - Persona-aware headless Claude execution
#
# Part of the Headless Claude system.
# Loads a persona (prompt + permissions + config), builds the execution
# environment, and runs claude -p with appropriate guardrails.
#
# Usage:
#   executor.sh --job <job-name> [--param key=value] [--answer "text"]
#   executor.sh --job health-summary
#   executor.sh --job plex-troubleshoot --param issue="won't start" --param safety_mode=safe-fixes
#   executor.sh --job upgrade-discover --answer "Approve upgrade"
#


set -euo pipefail

# Ensure claude CLI is on PATH (cron uses minimal PATH)
export PATH="$HOME/.local/bin:$PATH"

# ============================================================================
# Configuration
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AIFRED_HOME="${AIFRED_HOME:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
PROJECT_DIR="${PROJECT_DIR:-$AIFRED_HOME}"
JOBS_DIR="$SCRIPT_DIR"
REGISTRY="$JOBS_DIR/registry.yaml"
PERSONAS_DIR="$JOBS_DIR/personas"
QUEUE_FILE="$JOBS_DIR/queue.json"
LOG_DIR="$PROJECT_DIR/.claude/logs/headless"
EXEC_LOG_DIR="$LOG_DIR/executions"
NOTIFICATIONS_FILE="$JOBS_DIR/notifications.jsonl"
SEND_TELEGRAM="$JOBS_DIR/lib/send-telegram.sh"
MSGBUS="$JOBS_DIR/lib/msgbus.sh"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# ============================================================================
# Functions
# ============================================================================

log() { echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] $1"; }
log_info() { log "${BLUE}INFO${NC}: $1"; }
log_success() { log "${GREEN}OK${NC}: $1"; }
log_warning() { log "${YELLOW}WARN${NC}: $1"; }
log_error() { log "${RED}ERROR${NC}: $1"; }

show_help() {
    cat << 'EOF'
executor.sh - Persona-aware headless Claude execution

USAGE:
    executor.sh --job <job-name> [OPTIONS]

OPTIONS:
    --job <name>          Job name (must exist in registry.yaml)
    --param key=value     Pass parameter to job (repeatable)
    --answer "text"       Provide answer from question queue
    --dry-run             Show what would execute without running
    --verbose             Show full prompt and config
    -h, --help            Show this help

EXAMPLES:
    executor.sh --job health-summary
    executor.sh --job plex-troubleshoot --param issue="high cpu" --param safety_mode=safe-fixes
    executor.sh --job upgrade-discover --dry-run
    executor.sh --job plex-troubleshoot --answer "Approve reboot"
EOF
}

# Check for yq
require_yq() {
    for yq_path in "yq" "$HOME/.local/bin/yq" "/usr/local/bin/yq" "/snap/bin/yq"; do
        if command -v "$yq_path" &>/dev/null 2>&1 || [ -x "$yq_path" ]; then
            echo "$yq_path"
            return 0
        fi
    done
    log_error "yq is required. Install: wget -qO ~/.local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 && chmod +x ~/.local/bin/yq"
    exit 1
}

# Read a value from registry.yaml for a given job
# Note: Uses explicit null check instead of yq's // operator,
# because // treats 'false' as falsy and skips it.
reg_get() {
    local job="$1" key="$2" default="${3:-}"
    local val
    val=$("$YQ" ".jobs.${job}.${key}" "$REGISTRY" 2>/dev/null)
    if [ -z "$val" ] || [ "$val" = "null" ]; then
        # Try defaults
        val=$("$YQ" ".defaults.${key}" "$REGISTRY" 2>/dev/null)
    fi
    if [ -z "$val" ] || [ "$val" = "null" ]; then
        echo "$default"
    else
        echo "$val"
    fi
}

# Determine notification severity from output content and exit code
# Uses phrase patterns to avoid false positives from headings like "Critical Services"
determine_severity() {
    local exit_code="$1" response="$2"
    if [ "$exit_code" -ne 0 ]; then
        echo "critical"
    elif echo "$response" | grep -qiP '(CRITICAL\s*(alert|error|failure|issue|finding|problem)|URGENT|SECURITY\s*(vuln|issue|alert|breach)|❌\s*(DEGRADED|FAIL|DOWN|CRITICAL))'; then
        echo "critical"
    elif echo "$response" | grep -qiP '(WARNING\s*:|action required|needs?\s+(fix|attention|restart)|QUESTION:|❌\s*(DEGRADED|DOWN))'; then
        echo "warning"
    else
        echo "info"
    fi
}

# Extract a short, meaningful summary from Claude's response
# Skips markdown noise (---, headings, metadata lines) to find the verdict
extract_summary() {
    local response="$1"
    local summary=""

    # Strategy 1: Look for "Overall/Status/Result: VALUE" lines (must have colon + value)
    summary=$(echo "$response" | grep -iP '(overall\s*(health|status|result)|status\s*:).*[:]\s*.+' | head -1 | sed 's/^[#*| -]*//' | sed 's/\*//g' | xargs)

    # Strategy 2: Look for lines with clear pass/fail indicators
    if [ -z "$summary" ]; then
        summary=$(echo "$response" | grep -iP '(no changes detected|no issues|no new files|all.*healthy|all.*operational|GOOD|DEGRADED|FAIL|ERROR|DOWN)' | grep -vP '^#{1,4}\s' | head -1 | sed 's/^[#*| -]*//' | sed 's/\*//g' | xargs)
    fi

    # Strategy 3: Look for action-required lines
    if [ -z "$summary" ]; then
        summary=$(echo "$response" | grep -iP '(action required|action needed|needs?\s+(fix|attention|restart))' | head -1 | sed 's/^[#*| -]*//' | sed 's/\*//g' | xargs)
    fi

    # Strategy 4: First meaningful line (skip markdown noise)
    if [ -z "$summary" ]; then
        summary=$(echo "$response" | grep -vP '^\s*$|^---$|^#{1,4}\s|^\*{2,}|^\|.*\||^Generated|^Execution Time' | head -1 | sed 's/^[#*| -]*//' | xargs)
    fi

    # Truncate to 150 chars
    if [ ${#summary} -gt 150 ]; then
        summary="${summary:0:147}..."
    fi

    # Fallback
    if [ -z "$summary" ]; then
        summary="Job completed"
    fi
    echo "$summary"
}

# Extract specific issue/action details from Claude's response (for warning/critical)
# Returns bullet-pointed list of issues, max 5 lines
extract_details() {
    local response="$1"
    local details=""

    # Strategy 1: Numbered items with descriptions (e.g., "1. **service** - description")
    details=$(echo "$response" | grep -iP '^\s*\d+\.\s+' | grep -iP '[-—:]\s+\S' | head -5 | sed 's/^[[:space:]]*//' | sed 's/\*//g' | sed 's/^[0-9]*\.\s*/• /')

    # Strategy 2: Action required/needed lines
    if [ -z "$details" ]; then
        details=$(echo "$response" | grep -iP '(action required|action needed|needs?\s+(fix|attention|restart)|should be|recommend)' | grep -vP '^#{1,4}\s' | head -3 | sed 's/^[#*| -]*/• /' | sed 's/\*//g')
    fi

    # Strategy 3: Lines with error/down/unhealthy/degraded indicators
    if [ -z "$details" ]; then
        details=$(echo "$response" | grep -iP '(unhealthy|down|degraded|failing|failed|error|missing|not found|not running)' | grep -vP '^#{1,4}\s|^\|' | head -3 | sed 's/^[#*| -]*/• /' | sed 's/\*//g')
    fi

    echo "$details"
}

# Write a notification to the message bus (relay handles Telegram delivery)
# Args: job severity title summary exit_code cost duration output_file [details] [engine]
write_notification() {
    local job="$1" severity="$2" title="$3" summary="$4"
    local exit_code="$5" cost="$6" duration="$7" output_file="$8"
    local details="${9:-}"
    local engine="${10:-${ENGINE:-claude-code}}"
    local event_type="job_completed"
    [ "$exit_code" -ne 0 ] 2>/dev/null && event_type="job_failed"

    if [ -x "$MSGBUS" ]; then
        "$MSGBUS" send --type "$event_type" \
            --source "headless:$job" \
            --severity "$severity" \
            --data "$(jq -nc \
                --arg job "$job" \
                --arg title "$title" \
                --arg sum "$summary" \
                --arg det "$details" \
                --argjson ec "${exit_code:-0}" \
                --arg cost "$cost" \
                --arg dur "$duration" \
                --arg out "$output_file" \
                --arg eng "$engine" \
                '{
                    job: $job,
                    title: $title,
                    summary: $sum,
                    details: (if $det == "" then null else $det end),
                    exit_code: $ec,
                    cost_usd: $cost,
                    duration_secs: ($dur | tonumber),
                    output_file: $out,
                    engine: $eng
                }')" > /dev/null 2>&1 || true
    fi

    # Legacy dual-write (remove after migration validation)
    local id="${job}-$(date +%s)"
    local timestamp
    timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    local record
    record=$(jq -nc \
        --arg id "$id" --arg ts "$timestamp" --arg job "$job" \
        --arg sev "$severity" --arg title "$title" --arg sum "$summary" \
        --argjson ec "${exit_code:-0}" --arg cost "$cost" --arg dur "$duration" \
        --arg out "$output_file" --arg eng "$engine" \
        '{id:$id,timestamp:$ts,job:$job,severity:$sev,title:$title,summary:$sum,exit_code:$ec,cost_usd:$cost,duration_secs:($dur|tonumber),output_file:$out,engine:$eng,notified:false,acknowledged:false}')
    echo "$record" >> "$NOTIFICATIONS_FILE"
}

# Push metrics to Prometheus Pushgateway
# Silently skips if pushgateway is unreachable (safe to deploy before container exists)
PUSHGATEWAY_URL="${PUSHGATEWAY_URL:-http://localhost:9091}"

push_metrics() {
    local job="$1" engine="$2" model="$3" duration="$4" cost="$5" success="$6" severity="$7"

    # Quick check — skip silently if pushgateway isn't reachable
    if ! curl -s --max-time 2 "$PUSHGATEWAY_URL/-/healthy" >/dev/null 2>&1; then
        return 0
    fi

    local status="success"
    [ "$success" -ne 1 ] 2>/dev/null && status="failure"

    cat <<METRICS_EOF | curl -s --max-time 5 --data-binary @- "$PUSHGATEWAY_URL/metrics/job/headless_claude/instance/${job}" >/dev/null 2>&1 || true
# HELP headless_job_duration_seconds Duration of headless job execution
# TYPE headless_job_duration_seconds gauge
headless_job_duration_seconds{engine="${engine}",model="${model}",severity="${severity}"} ${duration}
# HELP headless_job_cost_usd Cost in USD of job execution
# TYPE headless_job_cost_usd gauge
headless_job_cost_usd{engine="${engine}",model="${model}"} ${cost:-0}
# HELP headless_job_success Whether the last job run succeeded (1=yes, 0=no)
# TYPE headless_job_success gauge
headless_job_success{engine="${engine}",model="${model}"} ${success}
# HELP headless_job_last_run_timestamp_seconds Unix timestamp of last job execution
# TYPE headless_job_last_run_timestamp_seconds gauge
headless_job_last_run_timestamp_seconds{engine="${engine}",model="${model}"} $(date +%s)
# HELP headless_job_runs_total Total number of job runs by status
# TYPE headless_job_runs_total counter
headless_job_runs_total{engine="${engine}",model="${model}",status="${status}"} 1
METRICS_EOF
}

# Build --allowedTools string from persona permissions.yaml
build_allowed_tools() {
    local persona_dir="$1"
    local perms_file="$persona_dir/permissions.yaml"
    local tools=""

    if [ ! -f "$perms_file" ]; then
        log_error "Permissions file not found: $perms_file"
        exit 1
    fi

    # Read allowed_tools array
    local tool_count
    tool_count=$("$YQ" '.allowed_tools | length' "$perms_file" 2>/dev/null || echo "0")

    for ((i=0; i<tool_count; i++)); do
        local tool
        tool=$("$YQ" ".allowed_tools[$i]" "$perms_file" 2>/dev/null)
        if [ -n "$tools" ]; then
            tools="$tools,$tool"
        else
            tools="$tool"
        fi
    done

    # Read allowed_bash and convert to Bash() patterns
    local bash_count
    bash_count=$("$YQ" '.allowed_bash | length' "$perms_file" 2>/dev/null || echo "0")

    for ((i=0; i<bash_count; i++)); do
        local bash_pattern
        bash_pattern=$("$YQ" ".allowed_bash[$i]" "$perms_file" 2>/dev/null)
        if [ -n "$tools" ]; then
            tools="$tools,Bash($bash_pattern)"
        else
            tools="Bash($bash_pattern)"
        fi
    done

    echo "$tools"
}

# Build the full prompt from persona + job + params + answer
build_prompt() {
    local persona_dir="$1"
    local job_prompt="$2"
    local params="$3"
    local answer="$4"
    local prompt_file="$persona_dir/prompt.md"

    local persona_prompt=""
    if [ -f "$prompt_file" ]; then
        persona_prompt=$(cat "$prompt_file")
    fi

    local full_prompt="$persona_prompt

---
## Job Context

**Job**: $JOB_NAME
**Execution Time**: $(date '+%Y-%m-%d %H:%M:%S')
**Session ID**: headless-${JOB_NAME}-$(date +%Y%m%d-%H%M%S)
**Invoked by**: Headless Claude dispatcher

### Task
$job_prompt"

    # Add parameters if any
    if [ -n "$params" ]; then
        full_prompt="$full_prompt

### Parameters
$params"
    fi

    # Add answer from queue if provided
    if [ -n "$answer" ]; then
        full_prompt="$full_prompt

### Human Response (from question queue)
The human has responded to your previous question with:
$answer

Please proceed with the task using this response."
    fi

    echo "$full_prompt"
}

# ============================================================================
# Engine Routing
# ============================================================================

OLLAMA_URL="${OLLAMA_URL:-http://localhost:11434}"

# Resolve which engine to use for this job
# Priority: job engine > persona engine.default > registry defaults.engine > "claude-code"
resolve_engine() {
    local job="$1" persona_dir="$2"
    local engine=""

    # 1. Job-level override
    engine=$("$YQ" ".jobs.${job}.engine" "$REGISTRY" 2>/dev/null)
    if [ -n "$engine" ] && [ "$engine" != "null" ]; then
        echo "$engine"
        return
    fi

    # 2. Persona config engine.default
    local persona_config="$persona_dir/config.yaml"
    if [ -f "$persona_config" ]; then
        engine=$("$YQ" '.engine.default' "$persona_config" 2>/dev/null)
        if [ -n "$engine" ] && [ "$engine" != "null" ]; then
            echo "$engine"
            return
        fi
    fi

    # 3. Registry defaults.engine
    engine=$("$YQ" '.defaults.engine' "$REGISTRY" 2>/dev/null)
    if [ -n "$engine" ] && [ "$engine" != "null" ]; then
        echo "$engine"
        return
    fi

    # 4. Hardcoded fallback
    echo "claude-code"
}

# Check if Ollama is responsive (reuses pattern from fabric-wrapper.sh)
check_ollama_health() {
    curl -s --max-time 5 "${OLLAMA_URL}/api/tags" >/dev/null 2>&1
}

# Execute a prompt via Ollama API
# Returns JSON envelope matching Claude output format
execute_ollama() {
    local prompt="$1" model="$2" timeout_secs="${3:-300}"

    local response
    response=$(curl -s --max-time "$timeout_secs" "$OLLAMA_URL/api/generate" \
        -H "Content-Type: application/json" \
        -d "$(jq -n --arg model "$model" --arg prompt "$prompt" '{
            model: $model,
            prompt: $prompt,
            stream: false,
            options: {
                temperature: 0.3,
                num_predict: 8000
            }
        }')" 2>/dev/null)

    if [ -z "$response" ]; then
        echo '{"error":"ollama_timeout","result":"Ollama request timed out"}'
        return 1
    fi

    # Extract response text and wrap in Claude-compatible envelope
    local text
    text=$(echo "$response" | jq -r '.response // empty' 2>/dev/null)

    if [ -z "$text" ]; then
        local err
        err=$(echo "$response" | jq -r '.error // "unknown error"' 2>/dev/null)
        echo "{\"error\":\"ollama_error\",\"result\":\"Ollama error: $err\"}"
        return 1
    fi

    jq -nc \
        --arg result "$text" \
        --arg model "$model" \
        '{result: $result, total_cost_usd: 0, model: $model, engine: "ollama", num_turns: 1}'
}

# Dispatch execution to the appropriate engine
execute_engine() {
    local engine="$1" prompt="$2" model="$3"
    shift 3
    # Remaining args are claude-specific flags

    case "$engine" in
        claude-code)
            # Run existing claude -p command with all flags
            claude -p "$prompt" "$@" 2>&1
            ;;
        ollama)
            if ! check_ollama_health; then
                log_error "Ollama is not responsive at $OLLAMA_URL" | tee -a "$LOG_FILE"
                echo '{"error":"ollama_unreachable","result":"Ollama service is not running or unreachable"}'
                return 1
            fi
            local timeout_secs=$((${TIMEOUT_MINUTES:-10} * 60))
            execute_ollama "$prompt" "$model" "$timeout_secs"
            ;;
        *)
            log_error "Unknown engine: $engine" | tee -a "$LOG_FILE"
            echo "{\"error\":\"unknown_engine\",\"result\":\"Unknown engine: $engine\"}"
            return 1
            ;;
    esac
}

# Check message bus for answered questions for this job
check_queue_answers() {
    local job="$1"

    # Check message bus first
    if [ -x "$MSGBUS" ]; then
        local answer
        answer=$("$MSGBUS" query --type question_answered --job "$job" --status pending 2>/dev/null \
            | jq -r '.data.answer // empty' 2>/dev/null | head -1)
        if [ -n "$answer" ]; then
            echo "$answer"
            return
        fi
    fi

    # Legacy fallback: check queue.json
    if [ -f "$QUEUE_FILE" ]; then
        local answers
        answers=$(jq -r --arg job "$job" \
            '[.questions[] | select(.job == $job and .status == "answered")] | first // empty | .answer // empty' \
            "$QUEUE_FILE" 2>/dev/null || echo "")
        echo "$answers"
        return
    fi

    echo ""
}

# Mark a queue question as processed (legacy, kept for migration period)
mark_question_processed() {
    local job="$1"
    if [ ! -f "$QUEUE_FILE" ]; then return; fi
    local tmp
    tmp=$(mktemp)
    jq --arg job "$job" \
        '(.questions[] | select(.job == $job and .status == "answered")).status = "processed"' \
        "$QUEUE_FILE" > "$tmp" 2>/dev/null && mv "$tmp" "$QUEUE_FILE"
}

# Write a question to the message bus (relay handles Telegram delivery)
write_question_to_queue() {
    local job="$1" question="$2" options="${3:-Approve|Deny|Skip}"

    if [ -x "$MSGBUS" ]; then
        "$MSGBUS" send --type question_asked \
            --source "headless:$job" \
            --severity question \
            --data "$(jq -nc \
                --arg job "$job" \
                --arg q "$question" \
                --arg opts "$options" \
                '{job:$job,question:$q,options:($opts|split("|"))}')" \
            > /dev/null 2>&1 || true
    fi

    log_info "Question written to bus for $job"
}

# ============================================================================
# Main
# ============================================================================

# Parse arguments
JOB_NAME=""
PARAMS=""
ANSWER=""
DRY_RUN=false
VERBOSE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help) show_help; exit 0 ;;
        --job) JOB_NAME="$2"; shift 2 ;;
        --param)
            if [ -n "$PARAMS" ]; then
                PARAMS="$PARAMS
- $2"
            else
                PARAMS="- $2"
            fi
            shift 2
            ;;
        --answer) ANSWER="$2"; shift 2 ;;
        --dry-run) DRY_RUN=true; shift ;;
        --verbose) VERBOSE=true; shift ;;
        *) log_error "Unknown option: $1"; show_help; exit 1 ;;
    esac
done

if [ -z "$JOB_NAME" ]; then
    log_error "Job name required. Use --job <name>"
    show_help
    exit 1
fi

# Find yq
YQ=$(require_yq)

# Validate job exists in registry
if ! "$YQ" ".jobs.${JOB_NAME}" "$REGISTRY" &>/dev/null || \
   [ "$("$YQ" ".jobs.${JOB_NAME}" "$REGISTRY" 2>/dev/null)" = "null" ]; then
    log_error "Unknown job: $JOB_NAME"
    echo "Available jobs:"
    "$YQ" '.jobs | keys | .[]' "$REGISTRY" 2>/dev/null
    exit 1
fi

# Check if job is enabled
ENABLED=$(reg_get "$JOB_NAME" "enabled" "true")
if [ "$ENABLED" = "false" ]; then
    log_warning "Job $JOB_NAME is disabled in registry"
    exit 0
fi

# Load job configuration
PERSONA_NAME=$(reg_get "$JOB_NAME" "persona" "investigator")
PERSONA_DIR="$PERSONAS_DIR/$PERSONA_NAME"
MAX_TURNS=$(reg_get "$JOB_NAME" "max_turns" "10")
MAX_BUDGET=$(reg_get "$JOB_NAME" "max_budget_usd" "2.00")
MODEL=$(reg_get "$JOB_NAME" "model" "sonnet")
TIMEOUT_MINUTES=$(reg_get "$JOB_NAME" "timeout_minutes" "10")
JOB_PROMPT=$("$YQ" ".jobs.${JOB_NAME}.prompt" "$REGISTRY" 2>/dev/null || echo "")

# Validate persona exists
if [ ! -d "$PERSONA_DIR" ]; then
    log_error "Persona not found: $PERSONA_DIR"
    exit 1
fi

# Resolve execution engine
ENGINE=$(resolve_engine "$JOB_NAME" "$PERSONA_DIR")

# Build allowed tools and add-dir flags (claude-code only)
ALLOWED_TOOLS=""
ADD_DIR_FLAGS=""
if [ "$ENGINE" = "claude-code" ]; then
    ALLOWED_TOOLS=$(build_allowed_tools "$PERSONA_DIR")

    PERSONA_CONFIG="$PERSONA_DIR/config.yaml"
    if [ -f "$PERSONA_CONFIG" ]; then
        ADD_DIR_COUNT=$("$YQ" '.add_dirs | length' "$PERSONA_CONFIG" 2>/dev/null || echo "0")
        for ((i=0; i<ADD_DIR_COUNT; i++)); do
            ADD_DIR=$("$YQ" ".add_dirs[$i]" "$PERSONA_CONFIG" 2>/dev/null)
            if [ -n "$ADD_DIR" ] && [ "$ADD_DIR" != "null" ]; then
                ADD_DIR_FLAGS="$ADD_DIR_FLAGS --add-dir $ADD_DIR"
            fi
        done
    fi
fi

# Check queue for answers
if [ -z "$ANSWER" ]; then
    QUEUE_ANSWER=$(check_queue_answers "$JOB_NAME")
    if [ -n "$QUEUE_ANSWER" ]; then
        ANSWER="$QUEUE_ANSWER"
        log_info "Found answer from queue: $ANSWER"
        mark_question_processed "$JOB_NAME"
    fi
fi

# Build full prompt
FULL_PROMPT=$(build_prompt "$PERSONA_DIR" "$JOB_PROMPT" "$PARAMS" "$ANSWER")

# Setup logging
mkdir -p "$EXEC_LOG_DIR"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
LOG_FILE="$EXEC_LOG_DIR/${JOB_NAME}-${TIMESTAMP}.log"
OUTPUT_FILE="$EXEC_LOG_DIR/${JOB_NAME}-${TIMESTAMP}.json"

log_info "Job: $JOB_NAME" | tee -a "$LOG_FILE"
log_info "Engine: $ENGINE" | tee -a "$LOG_FILE"
log_info "Persona: $PERSONA_NAME" | tee -a "$LOG_FILE"
log_info "Model: $MODEL" | tee -a "$LOG_FILE"
if [ "$ENGINE" = "claude-code" ]; then
    log_info "Max turns: $MAX_TURNS" | tee -a "$LOG_FILE"
    log_info "Max budget: \$$MAX_BUDGET" | tee -a "$LOG_FILE"
fi

if [ "$VERBOSE" = "true" ]; then
    if [ -n "$ALLOWED_TOOLS" ]; then
        log_info "Allowed tools: $ALLOWED_TOOLS" | tee -a "$LOG_FILE"
    fi
    if [ -n "$ADD_DIR_FLAGS" ]; then
        log_info "Add dirs:$ADD_DIR_FLAGS" | tee -a "$LOG_FILE"
    fi
    log_info "Prompt:" | tee -a "$LOG_FILE"
    echo "$FULL_PROMPT" | tee -a "$LOG_FILE"
fi

# Dry run
if [ "$DRY_RUN" = "true" ]; then
    echo ""
    echo "=== DRY RUN ==="
    echo "Job: $JOB_NAME"
    echo "Engine: $ENGINE"
    echo "Persona: $PERSONA_NAME ($PERSONA_DIR)"
    echo "Model: $MODEL"
    echo ""
    echo "Prompt preview (first 500 chars):"
    echo "${FULL_PROMPT:0:500}..."
    echo ""
    if [ "$ENGINE" = "claude-code" ]; then
        echo "Max turns: $MAX_TURNS"
        echo "Max budget: \$$MAX_BUDGET"
        echo "Tools: $ALLOWED_TOOLS"
        if [ -n "$ADD_DIR_FLAGS" ]; then
            echo "Add dirs:$ADD_DIR_FLAGS"
        fi
        echo ""
        echo "Would execute:"
        echo "  cd $PROJECT_DIR"
        echo "  claude -p \"<prompt>\" --model $MODEL --allowedTools \"...\" --max-turns $MAX_TURNS --output-format json$ADD_DIR_FLAGS"
    elif [ "$ENGINE" = "ollama" ]; then
        echo "Ollama URL: $OLLAMA_URL"
        echo "Timeout: ${TIMEOUT_MINUTES}m"
        echo ""
        echo "Would execute:"
        echo "  curl -s $OLLAMA_URL/api/generate -d '{model: \"$MODEL\", prompt: \"<prompt>\", stream: false}'"
    fi
    exit 0
fi

# Set Beads actor for audit trail
export BEADS_ACTOR="headless-${JOB_NAME}-$(date +%Y%m%d)"

# Execute via engine
cd "$PROJECT_DIR"

if [ "$ENGINE" = "claude-code" ] && ! command -v claude &>/dev/null; then
    log_error "claude command not found" | tee -a "$LOG_FILE"
    exit 1
fi

log_info "Executing via $ENGINE ..." | tee -a "$LOG_FILE"

EXEC_START=$(date +%s)
EXEC_EXIT_CODE=0

if [ "$ENGINE" = "claude-code" ]; then
    RESULT=$(execute_engine "$ENGINE" "$FULL_PROMPT" "$MODEL" \
        --model "$MODEL" \
        --allowedTools "$ALLOWED_TOOLS" \
        --max-turns "$MAX_TURNS" \
        --output-format json \
        --no-session-persistence \
        $ADD_DIR_FLAGS \
        2>&1) || {
        EXEC_EXIT_CODE=$?
    }
else
    RESULT=$(execute_engine "$ENGINE" "$FULL_PROMPT" "$MODEL" 2>&1) || {
        EXEC_EXIT_CODE=$?
    }
fi

if [ "$EXEC_EXIT_CODE" -ne 0 ]; then
    log_error "Execution failed (engine: $ENGINE)" | tee -a "$LOG_FILE"
    echo "$RESULT" >> "$LOG_FILE"
    echo "{\"status\":\"error\",\"job\":\"$JOB_NAME\",\"engine\":\"$ENGINE\",\"error\":\"execution_failed\"}" > "$OUTPUT_FILE"

    # Write failure notification
    EXEC_END=$(date +%s)
    EXEC_DURATION=$((EXEC_END - EXEC_START))
    write_notification "$JOB_NAME" "critical" "$JOB_NAME failed" \
        "Execution failed with exit code $EXEC_EXIT_CODE (engine: $ENGINE)" \
        "$EXEC_EXIT_CODE" "unknown" "$EXEC_DURATION" "$OUTPUT_FILE"

    exit 1
fi

EXEC_END=$(date +%s)
EXEC_DURATION=$((EXEC_END - EXEC_START))

# Save output
echo "$RESULT" > "$OUTPUT_FILE"
log_success "Output saved: $OUTPUT_FILE" | tee -a "$LOG_FILE"

# Extract response and check for questions
RESPONSE=""
COST="unknown"
if command -v jq &>/dev/null; then
    RESPONSE=$(echo "$RESULT" | jq -r '.result // .response // ""' 2>/dev/null || echo "$RESULT")
    COST=$(echo "$RESULT" | jq -r '.total_cost_usd // .cost_usd // "unknown"' 2>/dev/null || echo "unknown")

    # Check for max_turns failure (no .result field)
    SUBTYPE=$(echo "$RESULT" | jq -r '.subtype // ""' 2>/dev/null || echo "")
    if [ "$SUBTYPE" = "error_max_turns" ]; then
        log_warning "Job hit max turns limit without completing" | tee -a "$LOG_FILE"
        NUM_TURNS=$(echo "$RESULT" | jq -r '.num_turns // "?"' 2>/dev/null || echo "?")
        DENIALS=$(echo "$RESULT" | jq -r '.permission_denials | length' 2>/dev/null || echo "0")
        if [ "$DENIALS" -gt 0 ]; then
            log_warning "Permission denials: $DENIALS (check allowed_tools/allowed_bash)" | tee -a "$LOG_FILE"
        fi
        if [ -z "$RESPONSE" ]; then
            RESPONSE="Job exceeded max turns ($NUM_TURNS). Permission denials: $DENIALS."
        fi
    fi
    log_info "Cost: \$$COST" | tee -a "$LOG_FILE"

    # Check for question indicators in output
    if echo "$RESPONSE" | grep -qi "QUESTION:"; then
        QUESTION=$(echo "$RESPONSE" | grep -oP 'QUESTION:\s*\K.*' | head -1)
        OPTIONS=$(echo "$RESPONSE" | grep -oP 'OPTIONS:\s*\K.*' | head -1)
        if [ -n "$QUESTION" ]; then
            write_question_to_queue "$JOB_NAME" "$QUESTION" "${OPTIONS:-Approve|Deny|Skip}"
        fi
    fi

    # Check for critical findings (uses same patterns as determine_severity)
    if echo "$RESPONSE" | grep -qiP '(CRITICAL\s*(alert|error|failure|issue|finding|problem)|URGENT|SECURITY\s*(vuln|issue|alert|breach)|❌\s*(DEGRADED|FAIL|DOWN|CRITICAL))'; then
        log_warning "ALERT: Critical finding in $JOB_NAME output" | tee -a "$LOG_FILE"
    fi
fi

# Write notification record
SEVERITY=$(determine_severity "$EXEC_EXIT_CODE" "$RESPONSE")
NOTIF_TITLE="$JOB_NAME completed"
[ "$SEVERITY" = "critical" ] && NOTIF_TITLE="$JOB_NAME: critical finding"
[ "$SEVERITY" = "warning" ] && NOTIF_TITLE="$JOB_NAME: warning"
NOTIF_SUMMARY=$(extract_summary "$RESPONSE")
NOTIF_DETAILS=""
if [ "$SEVERITY" != "info" ]; then
    NOTIF_DETAILS=$(extract_details "$RESPONSE")
fi
write_notification "$JOB_NAME" "$SEVERITY" "$NOTIF_TITLE" "$NOTIF_SUMMARY" \
    "$EXEC_EXIT_CODE" "$COST" "$EXEC_DURATION" "$OUTPUT_FILE" "$NOTIF_DETAILS"
log_info "Notification recorded: $SEVERITY (relay delivers)" | tee -a "$LOG_FILE"

# Push metrics to Prometheus
METRIC_SUCCESS=1
[ "$EXEC_EXIT_CODE" -ne 0 ] && METRIC_SUCCESS=0
METRIC_COST="$COST"
[ "$METRIC_COST" = "unknown" ] && METRIC_COST="0"
push_metrics "$JOB_NAME" "$ENGINE" "$MODEL" "$EXEC_DURATION" "$METRIC_COST" "$METRIC_SUCCESS" "$SEVERITY"

# Update latest symlink
LATEST_FILE="$EXEC_LOG_DIR/latest-${JOB_NAME}.json"
cp "$OUTPUT_FILE" "$LATEST_FILE"

log_success "Job completed: $JOB_NAME" | tee -a "$LOG_FILE"
echo ""
echo "========================================"
echo -e "${GREEN}Job completed: $JOB_NAME${NC}"
echo "========================================"
echo "  Log:    $LOG_FILE"
echo "  Output: $OUTPUT_FILE"
echo "  Latest: $LATEST_FILE"
echo "========================================"

exit 0
