#!/bin/bash
# dispatcher.sh - Master headless scheduler
#
# Part of the Headless Claude system.
# Runs every 5 minutes via single cron entry. Pure bash, no LLM.
# Reads registry.yaml, checks schedules vs last-run timestamps,
# and launches due jobs via executor.sh.
#
# Usage:
#   dispatcher.sh                    # Normal scheduled run
#   dispatcher.sh --list             # Show all jobs and next run times
#   dispatcher.sh --run <job-name>   # Force-run a specific job now
#   dispatcher.sh --dry-run          # Show what would run without executing
#   dispatcher.sh --check            # Check which jobs are due right now
#
# Cron entry:
#   */5 * * * * /path/to/aifred/.claude/jobs/dispatcher.sh >> /path/to/aifred/.claude/logs/headless/dispatcher.log 2>&1
#


set -euo pipefail

# ============================================================================
# Configuration
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AIFRED_HOME="${AIFRED_HOME:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
PROJECT_DIR="${PROJECT_DIR:-$AIFRED_HOME}"
REGISTRY="$SCRIPT_DIR/registry.yaml"
EXECUTOR="$SCRIPT_DIR/executor.sh"
STATE_DIR="$SCRIPT_DIR/state"
LOCKS_DIR="$STATE_DIR/locks"
LAST_RUN_FILE="$STATE_DIR/last-run.json"
QUEUE_FILE="$SCRIPT_DIR/queue.json"
NOTIFICATIONS_FILE="$SCRIPT_DIR/notifications.jsonl"
LOG_DIR="$PROJECT_DIR/.claude/logs/headless"
DISPATCHER_LOCK="$LOCKS_DIR/dispatcher.lock"

# Colors (only when interactive)
if [ -t 1 ]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    CYAN='\033[0;36m'
    NC='\033[0m'
else
    RED='' GREEN='' YELLOW='' BLUE='' CYAN='' NC=''
fi

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
dispatcher.sh - Master headless scheduler

USAGE:
    dispatcher.sh [OPTIONS]

OPTIONS:
    --list              Show all registered jobs with schedule info
    --run <job-name>    Force-run a specific job immediately
    --param key=value   Pass parameter to job (repeatable, use with --run)
    --dry-run           Show what would execute without running
    --check             Check which jobs are due right now
    --status            Show last run status for all jobs
    --dashboard         Show observability dashboard (job status, costs, health)
    --history [N]       Show last N notification records (default: 20)
    --history --job <n> Filter history by job name
    --history --severity <level>  Filter by severity (critical/warning/info)
    --history --unack   Show unacknowledged notifications only
    --ack <id>          Acknowledge a notification by ID
    -h, --help          Show this help

EXAMPLES:
    dispatcher.sh                        # Normal cron execution
    dispatcher.sh --list                 # Show registered jobs
    dispatcher.sh --run health-summary   # Force-run a job
    dispatcher.sh --run abs-librarian --param permission_profile=elevated  # With params
    dispatcher.sh --dry-run              # Preview what would run
    dispatcher.sh --check                # Check due jobs
    dispatcher.sh --status               # Show last run times
    dispatcher.sh --dashboard            # Observability dashboard
    dispatcher.sh --dashboard --summary  # One-line status
    dispatcher.sh --dashboard --json     # JSON output
    dispatcher.sh --history              # Last 20 notifications
    dispatcher.sh --history 50           # Last 50 notifications
    dispatcher.sh --history --severity critical  # Critical only
    dispatcher.sh --ack health-summary-1707400800  # Acknowledge
EOF
}

# Find yq binary
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

# Ensure state directories exist
ensure_state() {
    mkdir -p "$STATE_DIR" "$LOCKS_DIR" "$LOG_DIR"
    if [ ! -f "$LAST_RUN_FILE" ]; then
        echo '{}' > "$LAST_RUN_FILE"
    fi
}

# Get last run timestamp for a job (epoch seconds, 0 if never run)
get_last_run() {
    local job="$1"
    if [ ! -f "$LAST_RUN_FILE" ]; then
        echo "0"
        return
    fi
    local ts
    ts=$(jq -r --arg job "$job" '.[$job] // 0' "$LAST_RUN_FILE" 2>/dev/null || echo "0")
    echo "$ts"
}

# Update last run timestamp for a job
set_last_run() {
    local job="$1"
    local now
    now=$(date +%s)
    local tmp
    tmp=$(mktemp)
    if [ -f "$LAST_RUN_FILE" ]; then
        jq --arg job "$job" --argjson ts "$now" '.[$job] = $ts' "$LAST_RUN_FILE" > "$tmp" 2>/dev/null && mv "$tmp" "$LAST_RUN_FILE"
    else
        echo "{\"$job\": $now}" > "$LAST_RUN_FILE"
    fi
}

# Acquire lock for a job. Returns 0 if acquired, 1 if already locked.
acquire_lock() {
    local job="$1"
    local lock_file="$LOCKS_DIR/${job}.lock"

    if [ -f "$lock_file" ]; then
        local pid
        pid=$(cat "$lock_file" 2>/dev/null || echo "")
        if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
            # Process still running
            return 1
        else
            # Stale lock — process died
            log_warning "Removing stale lock for $job (PID $pid)"
            rm -f "$lock_file"
        fi
    fi

    echo $$ > "$lock_file"
    return 0
}

# Release lock for a job
release_lock() {
    local job="$1"
    rm -f "$LOCKS_DIR/${job}.lock"
}

# Acquire dispatcher-level lock (prevent overlapping dispatchers)
acquire_dispatcher_lock() {
    if [ -f "$DISPATCHER_LOCK" ]; then
        local pid
        pid=$(cat "$DISPATCHER_LOCK" 2>/dev/null || echo "")
        if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
            log_warning "Another dispatcher is running (PID $pid). Exiting."
            exit 0
        else
            log_warning "Removing stale dispatcher lock (PID $pid)"
            rm -f "$DISPATCHER_LOCK"
        fi
    fi
    echo $$ > "$DISPATCHER_LOCK"
}

release_dispatcher_lock() {
    rm -f "$DISPATCHER_LOCK"
}

# Check if an interval-based job is due
# Usage: is_interval_due <job_name> <every_hours>
is_interval_due() {
    local job="$1"
    local every_hours="$2"
    local last_run
    last_run=$(get_last_run "$job")
    local now
    now=$(date +%s)
    local interval_secs=$((every_hours * 3600))
    local next_due=$((last_run + interval_secs))

    if [ "$now" -ge "$next_due" ]; then
        return 0
    fi
    return 1
}

# Check if a weekly job is due
# Usage: is_weekly_due <job_name> <day_name> <hour>
is_weekly_due() {
    local job="$1"
    local target_day="$2"
    local target_hour="$3"
    local last_run
    last_run=$(get_last_run "$job")

    # Get current day and hour
    local current_day
    current_day=$(date +%A | tr '[:upper:]' '[:lower:]')
    local current_hour
    current_hour=$(date +%-H)
    target_day=$(echo "$target_day" | tr '[:upper:]' '[:lower:]')

    # Check if today is the target day and we're past the target hour
    if [ "$current_day" != "$target_day" ]; then
        return 1
    fi

    if [ "$current_hour" -lt "$target_hour" ]; then
        return 1
    fi

    # Check if already run this week (within last 6 days)
    local now
    now=$(date +%s)
    local six_days=$((6 * 86400))
    if [ "$last_run" -gt $((now - six_days)) ]; then
        return 1
    fi

    return 0
}

# Get all job names from registry
get_job_names() {
    "$YQ" '.jobs | keys | .[]' "$REGISTRY" 2>/dev/null
}

# Read a value from registry for a job, falling back to defaults
# Note: Uses explicit null check instead of yq's // operator,
# because // treats 'false' as falsy and skips it.
reg_get() {
    local job="$1" key="$2" default="${3:-}"
    local val
    val=$("$YQ" ".jobs.${job}.${key}" "$REGISTRY" 2>/dev/null)
    if [ -z "$val" ] || [ "$val" = "null" ]; then
        val=$("$YQ" ".defaults.${key}" "$REGISTRY" 2>/dev/null)
    fi
    if [ -z "$val" ] || [ "$val" = "null" ]; then
        echo "$default"
    else
        echo "$val"
    fi
}

# Check if a job is due based on its schedule
is_job_due() {
    local job="$1"

    local enabled
    enabled=$(reg_get "$job" "enabled" "true")
    if [ "$enabled" = "false" ]; then
        return 1
    fi

    local schedule_type
    schedule_type=$("$YQ" ".jobs.${job}.schedule.type" "$REGISTRY" 2>/dev/null)

    case "$schedule_type" in
        interval)
            local every_hours
            every_hours=$("$YQ" ".jobs.${job}.schedule.every_hours" "$REGISTRY" 2>/dev/null)
            if [ -z "$every_hours" ] || [ "$every_hours" = "null" ]; then
                log_warning "Job $job: interval schedule missing every_hours"
                return 1
            fi
            is_interval_due "$job" "$every_hours"
            return $?
            ;;
        weekly)
            local day hour
            day=$("$YQ" ".jobs.${job}.schedule.day" "$REGISTRY" 2>/dev/null)
            hour=$("$YQ" ".jobs.${job}.schedule.hour // 0" "$REGISTRY" 2>/dev/null)
            if [ -z "$day" ] || [ "$day" = "null" ]; then
                log_warning "Job $job: weekly schedule missing day"
                return 1
            fi
            is_weekly_due "$job" "$day" "$hour"
            return $?
            ;;
        on-demand)
            # On-demand jobs are never auto-scheduled
            return 1
            ;;
        *)
            log_warning "Job $job: unknown schedule type '$schedule_type'"
            return 1
            ;;
    esac
}

# Run a job via executor.sh
run_job() {
    local job="$1"
    shift
    local extra_args=("$@")

    if ! acquire_lock "$job"; then
        log_warning "Job $job is already running (locked). Skipping."
        return 0
    fi

    log_info "Running job: $job"

    local start_time
    start_time=$(date +%s)

    # Run executor in background, capture exit code
    "$EXECUTOR" --job "$job" "${extra_args[@]}" 2>&1 | while IFS= read -r line; do
        echo "  [$job] $line"
    done
    local exit_code=${PIPESTATUS[0]}

    local end_time
    end_time=$(date +%s)
    local duration=$((end_time - start_time))

    if [ "$exit_code" -eq 0 ]; then
        log_success "Job $job completed in ${duration}s"
        set_last_run "$job"
    else
        log_error "Job $job failed (exit code $exit_code) after ${duration}s"
    fi

    release_lock "$job"
    return "$exit_code"
}

# Check queue for answered questions and re-trigger waiting jobs
process_queue_answers() {
    if [ ! -f "$QUEUE_FILE" ]; then
        return
    fi

    local answered_jobs
    answered_jobs=$(jq -r '[.questions[] | select(.status == "answered")] | .[].job' "$QUEUE_FILE" 2>/dev/null | sort -u)

    if [ -z "$answered_jobs" ]; then
        return
    fi

    while IFS= read -r job; do
        if [ -z "$job" ]; then continue; fi

        local answer
        answer=$(jq -r --arg job "$job" \
            '[.questions[] | select(.job == $job and .status == "answered")] | first | .answer' \
            "$QUEUE_FILE" 2>/dev/null)

        if [ -n "$answer" ] && [ "$answer" != "null" ]; then
            log_info "Queue answer found for $job: $answer"
            run_job "$job" --answer "$answer"
        fi
    done <<< "$answered_jobs"
}

# List all jobs with their schedule info
list_jobs() {
    echo ""
    echo "Headless Claude Job Registry"
    echo "============================"
    echo ""
    printf "%-22s %-14s %-15s %-10s %s\n" "JOB" "PERSONA" "SCHEDULE" "ENABLED" "LAST RUN"
    printf "%-22s %-14s %-15s %-10s %s\n" "---" "-------" "--------" "-------" "--------"

    while IFS= read -r job; do
        local persona schedule_type enabled last_run last_run_str schedule_desc

        persona=$(reg_get "$job" "persona" "?")
        schedule_type=$("$YQ" ".jobs.${job}.schedule.type" "$REGISTRY" 2>/dev/null)
        enabled=$(reg_get "$job" "enabled" "true")
        last_run=$(get_last_run "$job")

        if [ "$last_run" -eq 0 ]; then
            last_run_str="never"
        else
            last_run_str=$(date -d "@$last_run" '+%Y-%m-%d %H:%M' 2>/dev/null || echo "unknown")
        fi

        case "$schedule_type" in
            interval)
                local hours
                hours=$("$YQ" ".jobs.${job}.schedule.every_hours" "$REGISTRY" 2>/dev/null)
                schedule_desc="every ${hours}h"
                ;;
            weekly)
                local day hour
                day=$("$YQ" ".jobs.${job}.schedule.day" "$REGISTRY" 2>/dev/null)
                hour=$("$YQ" ".jobs.${job}.schedule.hour // 0" "$REGISTRY" 2>/dev/null)
                schedule_desc="${day} ${hour}:00"
                ;;
            on-demand)
                schedule_desc="on-demand"
                ;;
            *)
                schedule_desc="$schedule_type"
                ;;
        esac

        printf "%-22s %-14s %-15s %-10s %s\n" "$job" "$persona" "$schedule_desc" "$enabled" "$last_run_str"
    done < <(get_job_names)
    echo ""
}

# Show status of all jobs
show_status() {
    echo ""
    echo "Headless Claude Job Status"
    echo "=========================="
    echo ""

    while IFS= read -r job; do
        local enabled last_run last_run_str is_due lock_file status_icon

        enabled=$(reg_get "$job" "enabled" "true")
        last_run=$(get_last_run "$job")
        lock_file="$LOCKS_DIR/${job}.lock"

        if [ "$last_run" -eq 0 ]; then
            last_run_str="never"
        else
            last_run_str=$(date -d "@$last_run" '+%Y-%m-%d %H:%M:%S' 2>/dev/null || echo "unknown")
        fi

        # Check status
        if [ "$enabled" = "false" ]; then
            status_icon="${YELLOW}DISABLED${NC}"
        elif [ -f "$lock_file" ]; then
            local pid
            pid=$(cat "$lock_file" 2>/dev/null || echo "")
            if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
                status_icon="${CYAN}RUNNING${NC} (PID $pid)"
            else
                status_icon="${YELLOW}STALE LOCK${NC}"
            fi
        elif is_job_due "$job" 2>/dev/null; then
            status_icon="${GREEN}DUE${NC}"
        else
            status_icon="idle"
        fi

        echo -e "  $job: $status_icon (last: $last_run_str)"
    done < <(get_job_names)

    # Queue status
    if [ -f "$QUEUE_FILE" ]; then
        local pending answered
        pending=$(jq '[.questions[] | select(.status == "pending")] | length' "$QUEUE_FILE" 2>/dev/null || echo "0")
        answered=$(jq '[.questions[] | select(.status == "answered")] | length' "$QUEUE_FILE" 2>/dev/null || echo "0")
        echo ""
        echo "  Queue: $pending pending, $answered answered"
    fi
    echo ""
}

# Check which jobs are due (without running them)
check_due() {
    echo ""
    echo "Jobs Due Now"
    echo "============"
    local any_due=false

    while IFS= read -r job; do
        if is_job_due "$job" 2>/dev/null; then
            local last_run
            last_run=$(get_last_run "$job")
            local last_str="never"
            if [ "$last_run" -gt 0 ]; then
                last_str=$(date -d "@$last_run" '+%Y-%m-%d %H:%M' 2>/dev/null || echo "unknown")
            fi
            echo -e "  ${GREEN}DUE${NC}: $job (last run: $last_str)"
            any_due=true
        fi
    done < <(get_job_names)

    if [ "$any_due" = "false" ]; then
        echo "  No jobs are due right now."
    fi

    # Check queue
    if [ -f "$QUEUE_FILE" ]; then
        local answered
        answered=$(jq -r '[.questions[] | select(.status == "answered")] | .[].job' "$QUEUE_FILE" 2>/dev/null)
        if [ -n "$answered" ]; then
            echo ""
            echo "Queue answers waiting:"
            while IFS= read -r job; do
                [ -z "$job" ] && continue
                echo -e "  ${CYAN}ANSWER${NC}: $job"
            done <<< "$answered"
        fi
    fi
    echo ""
}

# Show notification history with filtering
show_history() {
    local limit="${1:-20}"
    local filter_job="${2:-}"
    local filter_severity="${3:-}"
    local filter_unack="${4:-false}"

    if [ ! -f "$NOTIFICATIONS_FILE" ]; then
        echo "No notifications yet."
        return
    fi

    echo ""
    echo "Notification History"
    echo "===================="

    # Build jq filter
    local jq_filter="."
    if [ -n "$filter_job" ]; then
        jq_filter="$jq_filter | select(.job == \"$filter_job\")"
    fi
    if [ -n "$filter_severity" ]; then
        jq_filter="$jq_filter | select(.severity == \"$filter_severity\")"
    fi
    if [ "$filter_unack" = "true" ]; then
        jq_filter="$jq_filter | select(.acknowledged == false)"
    fi

    # Read JSONL, apply filters, take last N
    local records
    records=$(jq -s "[.[] | $jq_filter] | .[-${limit}:][]" "$NOTIFICATIONS_FILE" 2>/dev/null)

    if [ -z "$records" ]; then
        echo "  No matching notifications."
        echo ""
        return
    fi

    echo ""
    printf "%-10s %-20s %-22s %-9s %s\n" "SEVERITY" "TIMESTAMP" "JOB" "COST" "SUMMARY"
    printf "%-10s %-20s %-22s %-9s %s\n" "--------" "---------" "---" "----" "-------"

    echo "$records" | jq -r '[.severity, .timestamp, .job, .cost_usd, .summary, .acknowledged, .id] | @tsv' 2>/dev/null | \
    while IFS=$'\t' read -r sev ts job cost summary acked id; do
        # Colorize severity
        local sev_display
        case "$sev" in
            critical) sev_display="${RED}CRITICAL${NC}" ;;
            warning)  sev_display="${YELLOW}WARNING${NC}" ;;
            info)     sev_display="${GREEN}info${NC}" ;;
            *)        sev_display="$sev" ;;
        esac

        # Format timestamp (strip seconds and timezone)
        local ts_short
        ts_short=$(echo "$ts" | sed 's/T/ /;s/:[0-9]*Z$//')

        # Ack indicator
        local ack_mark=""
        if [ "$acked" = "true" ]; then
            ack_mark=" [ack]"
        fi

        # Cost display
        local cost_display
        if [ "$cost" = "unknown" ]; then
            cost_display="--"
        else
            cost_display="\$$cost"
        fi

        printf "  %-10b %-20s %-22s %-9s %s%s\n" \
            "$sev_display" "$ts_short" "$job" "$cost_display" "$summary" "$ack_mark"
    done

    # Show totals
    local total
    total=$(jq -s "[.[] | $jq_filter] | length" "$NOTIFICATIONS_FILE" 2>/dev/null || echo "0")
    echo ""
    echo "  Showing last $limit of $total matching notifications."
    echo ""
}

# Acknowledge a notification by ID
ack_notification() {
    local target_id="$1"

    if [ ! -f "$NOTIFICATIONS_FILE" ]; then
        log_error "No notifications file found."
        return 1
    fi

    # Check if ID exists
    if ! grep -q "\"id\":\"$target_id\"" "$NOTIFICATIONS_FILE" 2>/dev/null; then
        log_error "Notification not found: $target_id"
        return 1
    fi

    # Update the record in-place (rewrite file with acknowledged=true for matching ID)
    local tmp
    tmp=$(mktemp)
    while IFS= read -r line; do
        if echo "$line" | jq -e --arg id "$target_id" '.id == $id' &>/dev/null; then
            echo "$line" | jq -c '.acknowledged = true'
        else
            echo "$line"
        fi
    done < "$NOTIFICATIONS_FILE" > "$tmp" && mv "$tmp" "$NOTIFICATIONS_FILE"

    log_success "Acknowledged: $target_id"
}

# ============================================================================
# Main
# ============================================================================

# Parse arguments
MODE="dispatch"
FORCE_JOB=""
FORCE_PARAMS=()
DRY_RUN=false
HISTORY_LIMIT=20
HISTORY_JOB=""
HISTORY_SEVERITY=""
HISTORY_UNACK=false
ACK_ID=""
DASHBOARD_ARGS=()

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help) show_help; exit 0 ;;
        --list) MODE="list"; shift ;;
        --run) MODE="force-run"; FORCE_JOB="$2"; shift 2 ;;
        --param) FORCE_PARAMS+=("--param" "$2"); shift 2 ;;
        --dry-run) DRY_RUN=true; shift ;;
        --check) MODE="check"; shift ;;
        --status) MODE="status"; shift ;;
        --dashboard) MODE="dashboard"; shift ;;
        --summary) DASHBOARD_ARGS+=("--summary"); shift ;;
        --costs) DASHBOARD_ARGS+=("--costs"); shift ;;
        --json) DASHBOARD_ARGS+=("--json"); shift ;;
        --history)
            MODE="history"
            shift
            # Check for optional numeric limit (next arg is a number)
            if [[ $# -gt 0 && "$1" =~ ^[0-9]+$ ]]; then
                HISTORY_LIMIT="$1"; shift
            fi
            ;;
        --job)
            HISTORY_JOB="$2"; shift 2
            ;;
        --severity)
            HISTORY_SEVERITY="$2"; shift 2
            ;;
        --unack)
            HISTORY_UNACK=true; shift
            ;;
        --ack) MODE="ack"; ACK_ID="$2"; shift 2 ;;
        *) log_error "Unknown option: $1"; show_help; exit 1 ;;
    esac
done

# Find yq
YQ=$(require_yq)

# Validate registry exists
if [ ! -f "$REGISTRY" ]; then
    log_error "Registry not found: $REGISTRY"
    exit 1
fi

# Validate executor exists
if [ ! -x "$EXECUTOR" ]; then
    log_error "Executor not found or not executable: $EXECUTOR"
    exit 1
fi

# Ensure state directories
ensure_state

# Handle modes
case "$MODE" in
    list)
        list_jobs
        exit 0
        ;;
    status)
        show_status
        exit 0
        ;;
    check)
        check_due
        exit 0
        ;;
    dashboard)
        DASHBOARD_SCRIPT="$SCRIPT_DIR/lib/dashboard.sh"
        if [ ! -x "$DASHBOARD_SCRIPT" ]; then
            log_error "Dashboard script not found: $DASHBOARD_SCRIPT"
            exit 1
        fi
        "$DASHBOARD_SCRIPT" ${DASHBOARD_ARGS[@]+"${DASHBOARD_ARGS[@]}"}
        exit 0
        ;;
    history)
        show_history "$HISTORY_LIMIT" "$HISTORY_JOB" "$HISTORY_SEVERITY" "$HISTORY_UNACK"
        exit 0
        ;;
    ack)
        if [ -z "$ACK_ID" ]; then
            log_error "Notification ID required for --ack"
            exit 1
        fi
        ack_notification "$ACK_ID"
        exit 0
        ;;
    force-run)
        if [ -z "$FORCE_JOB" ]; then
            log_error "Job name required for --run"
            exit 1
        fi
        # Validate job exists
        if [ "$("$YQ" ".jobs.${FORCE_JOB}" "$REGISTRY" 2>/dev/null)" = "null" ]; then
            log_error "Unknown job: $FORCE_JOB"
            exit 1
        fi
        log_info "Force-running job: $FORCE_JOB"
        run_job "$FORCE_JOB" ${FORCE_PARAMS[@]+"${FORCE_PARAMS[@]}"}
        exit $?
        ;;
    dispatch)
        # Normal dispatch cycle — fall through to main logic below
        ;;
esac

# ============================================================================
# Normal Dispatch Cycle
# ============================================================================

# Acquire dispatcher lock (prevent overlapping runs)
acquire_dispatcher_lock
trap release_dispatcher_lock EXIT

log_info "Dispatcher cycle starting"

JOBS_RUN=0
JOBS_SKIPPED=0
JOBS_FAILED=0

# Step 1: Process any answered queue questions first
process_queue_answers

# Step 2: Check each job's schedule
while IFS= read -r job; do
    if is_job_due "$job" 2>/dev/null; then
        if [ "$DRY_RUN" = "true" ]; then
            log_info "[DRY RUN] Would run: $job"
            JOBS_RUN=$((JOBS_RUN + 1))
        else
            if run_job "$job"; then
                JOBS_RUN=$((JOBS_RUN + 1))
            else
                JOBS_FAILED=$((JOBS_FAILED + 1))
            fi
        fi
    else
        JOBS_SKIPPED=$((JOBS_SKIPPED + 1))
    fi
done < <(get_job_names)

# Summary
if [ "$DRY_RUN" = "true" ]; then
    log_info "Dispatch cycle complete (DRY RUN): $JOBS_RUN would run, $JOBS_SKIPPED not due"
else
    log_info "Dispatch cycle complete: $JOBS_RUN run, $JOBS_SKIPPED not due, $JOBS_FAILED failed"

    # Run message relay after dispatch cycle (delivers pending notifications)
    RELAY="$SCRIPT_DIR/lib/msg-relay.sh"
    if [ -x "$RELAY" ]; then
        "$RELAY" 2>&1 | tee -a "$LOG_DIR/relay.log" || true
    fi
fi

exit 0
