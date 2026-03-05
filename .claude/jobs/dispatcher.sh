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
#   */5 * * * * ${PROJECT_DIR:-$PWD}/.claude/jobs/dispatcher.sh >> ${PROJECT_DIR:-$PWD}/.claude/logs/headless/dispatcher.log 2>&1

set -euo pipefail

# ============================================================================
# Configuration
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="${PROJECT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
JOBS_DIR="$SCRIPT_DIR"
REGISTRY="$SCRIPT_DIR/registry.yaml"
EXECUTOR="$SCRIPT_DIR/executor.sh"
STATE_DIR="$SCRIPT_DIR/state"
LOCKS_DIR="$STATE_DIR/locks"
QUEUE_FILE="$SCRIPT_DIR/queue.json"
JOBSDB="$SCRIPT_DIR/lib/jobsdb.py"

# Shared utilities (colors, logging, require_yq, reg_get)
source "$SCRIPT_DIR/lib/common.sh"
LOG_DIR="$PROJECT_DIR/.claude/logs/headless"
DISPATCHER_LOCK="$LOCKS_DIR/dispatcher.lock"

# SQLite helper
_db() { python3 "$JOBSDB" "$@"; }

# ============================================================================
# Functions (colors, logging, require_yq, reg_get loaded from lib/common.sh)
# ============================================================================

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

# require_yq() — loaded from lib/common.sh

# Ensure state directories and DB exist
ensure_state() {
    mkdir -p "$STATE_DIR" "$LOCKS_DIR" "$LOG_DIR"
    _db init > /dev/null
}

# Get last run timestamp for a job (epoch seconds, 0 if never run)
get_last_run() {
    local job="$1"
    local ts
    ts=$(_db exec-scalar "SELECT COALESCE(last_run, 0) FROM job_state WHERE job = ?" "$job")
    echo "${ts:-0}"
}

# Update last run timestamp for a job
set_last_run() {
    local job="$1"
    local now
    now=$(date +%s)
    _db exec "INSERT INTO job_state (job, last_run) VALUES (?, ?) ON CONFLICT(job) DO UPDATE SET last_run = ?" "$job" "$now" "$now" > /dev/null
}

# Get failure state for a job (returns JSON or empty)
get_failure_state() {
    local job="$1"
    _db exec "SELECT fail_count, last_failure FROM job_state WHERE job = ? AND fail_count > 0" "$job"
}

# Record a failure for a job
record_failure() {
    local job="$1"
    local now
    now=$(date +%s)
    _db exec "INSERT INTO job_state (job, fail_count, last_failure) VALUES (?, 1, ?) ON CONFLICT(job) DO UPDATE SET fail_count = fail_count + 1, last_failure = ?" "$job" "$now" "$now" > /dev/null
}

# Clear failure state for a job (on success)
clear_failure() {
    local job="$1"
    _db exec "UPDATE job_state SET fail_count = 0, last_failure = NULL WHERE job = ?" "$job" > /dev/null
}

# Check if a failed job is eligible for retry
# Returns 0 if retry is due, 1 otherwise
is_retry_due() {
    local job="$1"

    # Get failure state from DB
    local fail_data
    fail_data=$(_db exec-raw "SELECT fail_count, COALESCE(last_failure, 0) FROM job_state WHERE job = ?" "$job")
    if [ -z "$fail_data" ]; then
        return 1
    fi

    local count last_failure
    IFS=$'\t' read -r count last_failure <<< "$fail_data"
    count="${count:-0}"
    last_failure="${last_failure:-0}"

    if [ "$count" -eq 0 ]; then
        return 1
    fi

    local max_retries
    max_retries=$(reg_get "$job" "max_retries" "1")
    local backoff_hours
    backoff_hours=$(reg_get "$job" "retry_backoff_hours" "1")

    local now
    now=$(date +%s)

    # Exhausted retries — wait for next schedule window
    if [ "$count" -ge "$max_retries" ]; then
        return 1
    fi

    # Check backoff period
    local backoff_secs=$((backoff_hours * 3600))
    if [ "$now" -ge $((last_failure + backoff_secs)) ]; then
        return 0
    fi

    return 1
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

    # Atomic lock acquisition via noclobber
    if (set -o noclobber; echo $$ > "$lock_file") 2>/dev/null; then
        return 0
    else
        # noclobber failed — file was created between our check and write (race)
        log_warning "Lock race detected for $job, skipping"
        return 1
    fi
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
    # Atomic lock acquisition via noclobber
    if ! (set -o noclobber; echo $$ > "$DISPATCHER_LOCK") 2>/dev/null; then
        log_warning "Dispatcher lock race — another instance started. Exiting."
        exit 0
    fi
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

    # Not due on schedule — but check if a retry is needed after failure
    if is_retry_due "$job"; then
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
        # Already ran this week — but check if a retry is due after failure
        if is_retry_due "$job"; then
            return 0
        fi
        return 1
    fi

    return 0
}

# Check if a daily job is due
# Usage: is_daily_due <job_name> <hour>
is_daily_due() {
    local job="$1"
    local target_hour="$2"
    local last_run
    last_run=$(get_last_run "$job")

    # Check if we're past the target hour
    local current_hour
    current_hour=$(date +%-H)

    if [ "$current_hour" -lt "$target_hour" ]; then
        return 1
    fi

    # Check if already run today (within last 14 hours)
    # 14h window: a job scheduled at hour 0 runs at ~00:05, next check at 00:00
    # next day is ~24h later, well past the 14h window. Meanwhile, a same-day
    # re-check at hour 6 (6h later) is still within window and won't re-fire.
    local now
    now=$(date +%s)
    local fourteen_hours=$((14 * 3600))
    if [ "$last_run" -gt $((now - fourteen_hours)) ]; then
        # Already ran today — but check if a retry is due after failure
        if is_retry_due "$job"; then
            return 0
        fi
        return 1
    fi

    return 0
}

# Get all job names from registry
get_job_names() {
    "$YQ" '.jobs | keys | .[]' "$REGISTRY" 2>/dev/null
}

# reg_get() — loaded from lib/common.sh

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
        daily)
            local hour
            hour=$("$YQ" ".jobs.${job}.schedule.hour // 0" "$REGISTRY" 2>/dev/null)
            is_daily_due "$job" "$hour"
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

# Run pre_check gate for a job. Returns 0 if check passes (or no pre_check defined),
# returns 1 if check fails (job should be skipped).
run_pre_check() {
    local job="$1"
    local pre_check
    pre_check=$("$YQ" ".jobs.${job}.pre_check" "$REGISTRY" 2>/dev/null)

    if [ -z "$pre_check" ] || [ "$pre_check" = "null" ]; then
        return 0  # No pre_check defined, always pass
    fi

    # Run the pre_check command with a short timeout
    if timeout 30 bash -c "$pre_check" >/dev/null 2>&1; then
        return 0  # Changes detected, proceed with LLM
    else
        return 1  # No changes, skip LLM invocation
    fi
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

    # Detect team jobs — route to team-runner.py instead of executor.sh
    local runner="$EXECUTOR"
    local is_team
    is_team=$("$YQ" ".jobs.${job}.team" "$REGISTRY" 2>/dev/null)
    if [ -n "$is_team" ] && [ "$is_team" != "null" ]; then
        runner="$SCRIPT_DIR/team-runner.py"
        log_info "Team job detected, using team-runner.py"
    fi

    # Run executor (or team-runner), capture exit code reliably via temp file
    # (piping through while-loop loses PIPESTATUS in bash)
    local tmp_output
    tmp_output=$(mktemp)
    "$runner" --job "$job" "${extra_args[@]}" > "$tmp_output" 2>&1
    local exit_code=$?
    # Display output with job prefix
    while IFS= read -r line; do
        echo "  [$job] $line"
    done < "$tmp_output"
    rm -f "$tmp_output"

    local end_time
    end_time=$(date +%s)
    local duration=$((end_time - start_time))

    if [ "$exit_code" -eq 0 ]; then
        log_success "Job $job completed in ${duration}s"
        set_last_run "$job"
        clear_failure "$job"
    else
        log_error "Job $job failed (exit code $exit_code) after ${duration}s"
        record_failure "$job"
        set_last_run "$job"  # Prevent immediate 5-min re-fire; retry after backoff
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
            daily)
                local hour
                hour=$("$YQ" ".jobs.${job}.schedule.hour // 0" "$REGISTRY" 2>/dev/null)
                schedule_desc="daily ${hour}:00"
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

# Query normalized event records from SQLite
_normalize_events() {
    _db exec "SELECT
        CAST(id AS TEXT) as id,
        created_at as timestamp,
        json_extract(data, '$.job') as job,
        severity,
        COALESCE(json_extract(data, '$.title'), '') as title,
        COALESCE(json_extract(data, '$.summary'), '') as summary,
        COALESCE(json_extract(data, '$.exit_code'), 0) as exit_code,
        COALESCE(json_extract(data, '$.cost_usd'), 'unknown') as cost_usd,
        COALESCE(json_extract(data, '$.duration_secs'), 0) as duration_secs,
        COALESCE(json_extract(data, '$.engine'), 'claude-code') as engine,
        COALESCE(json_extract(data, '$.output_file'), '') as output_file,
        CASE WHEN status = 'delivered' THEN 1 ELSE 0 END as acknowledged
    FROM events WHERE event_type = 'job_completed' ORDER BY id"
}

# Show notification history with filtering
show_history() {
    local limit="${1:-20}"
    local filter_job="${2:-}"
    local filter_severity="${3:-}"
    local filter_unack="${4:-false}"

    echo ""
    echo "Notification History"
    echo "===================="

    # Build SQL WHERE clause
    local wheres=("event_type = 'job_completed'")
    local params=()
    if [ -n "$filter_job" ]; then
        wheres+=("json_extract(data, '$.job') = ?")
        params+=("$filter_job")
    fi
    if [ -n "$filter_severity" ]; then
        wheres+=("severity = ?")
        params+=("$filter_severity")
    fi
    if [ "$filter_unack" = "true" ]; then
        wheres+=("status != 'delivered' AND status != 'acknowledged'")
    fi

    local where_clause=""
    for i in "${!wheres[@]}"; do
        [ "$i" -gt 0 ] && where_clause="$where_clause AND "
        where_clause="$where_clause${wheres[$i]}"
    done

    # Get total count
    local total
    total=$(_db exec-scalar "SELECT COUNT(*) FROM events WHERE $where_clause" "${params[@]}")

    if [ "$total" = "0" ]; then
        echo "  No matching notifications."
        echo ""
        return
    fi

    echo ""
    printf "%-10s %-20s %-22s %-9s %s\n" "SEVERITY" "TIMESTAMP" "JOB" "COST" "SUMMARY"
    printf "%-10s %-20s %-22s %-9s %s\n" "--------" "---------" "---" "----" "-------"

    _db exec-raw "SELECT severity, created_at, json_extract(data, '$.job'),
        COALESCE(json_extract(data, '$.cost_usd'), 'unknown'),
        COALESCE(json_extract(data, '$.summary'), ''),
        CASE WHEN status = 'delivered' OR status = 'acknowledged' THEN 1 ELSE 0 END,
        id
    FROM events WHERE $where_clause ORDER BY id DESC LIMIT ?" "${params[@]}" "$limit" | \
    tac | \
    while IFS=$'\t' read -r sev ts job cost summary acked id; do
        local sev_display
        case "$sev" in
            critical) sev_display="${RED}CRITICAL${NC}" ;;
            warning)  sev_display="${YELLOW}WARNING${NC}" ;;
            info)     sev_display="${GREEN}info${NC}" ;;
            *)        sev_display="$sev" ;;
        esac

        local ts_short
        ts_short=$(echo "$ts" | sed 's/T/ /;s/:[0-9]*Z$//')

        local ack_mark=""
        [ "$acked" = "1" ] && ack_mark=" [ack]"

        local cost_display
        if [ "$cost" = "unknown" ]; then
            cost_display="--"
        else
            cost_display="\$$cost"
        fi

        printf "  %-10b %-20s %-22s %-9s %s%s\n" \
            "$sev_display" "$ts_short" "$job" "$cost_display" "$summary" "$ack_mark"
    done

    echo ""
    echo "  Showing last $limit of $total matching notifications."
    echo ""
}

# Acknowledge a notification by ID
ack_notification() {
    local target_id="$1"

    # Check if ID exists
    local exists
    exists=$(_db exec-scalar "SELECT COUNT(*) FROM events WHERE id = ?" "$target_id")
    if [ "$exists" = "0" ]; then
        log_error "Notification not found: $target_id"
        return 1
    fi

    _db exec "UPDATE events SET status = 'acknowledged' WHERE id = ?" "$target_id" > /dev/null
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
JOBS_GATED=0

# Step 1: Process any answered queue questions first
process_queue_answers

# Step 2: Check each job's schedule
while IFS= read -r job; do
    if is_job_due "$job" 2>/dev/null; then
        # Run pre_check gate before invoking LLM
        if ! run_pre_check "$job"; then
            log_info "Job $job: pre_check gate — no changes detected, skipping LLM"
            set_last_run "$job"  # Keep schedule on track
            JOBS_GATED=$((JOBS_GATED + 1))
            continue
        fi
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
    log_info "Dispatch cycle complete (DRY RUN): $JOBS_RUN would run, $JOBS_SKIPPED not due, $JOBS_GATED gated"
else
    log_info "Dispatch cycle complete: $JOBS_RUN run, $JOBS_SKIPPED not due, $JOBS_GATED gated, $JOBS_FAILED failed"

    # Rotate old execution logs (30-day retention)
    if [ -d "$LOG_DIR/executions" ]; then
        OLD_LOG_COUNT=$(find "$LOG_DIR/executions" -type f -mtime +30 2>/dev/null | wc -l)
        if [ "$OLD_LOG_COUNT" -gt 0 ]; then
            find "$LOG_DIR/executions" -type f -mtime +30 -delete 2>/dev/null || true
            log_info "Log rotation: cleaned $OLD_LOG_COUNT files older than 30 days from executions/"
        fi
    fi

    # Pipeline stall detection (schedule-aware)
    # Threshold scales with job schedule: interval jobs get 3x their interval,
    # weekly jobs get 10 days, daily jobs get 3 days. On-demand jobs are skipped.
    # Alerts are throttled to once per 24h via state file.
    NOW_EPOCH=$(date +%s)
    STALL_ALERT_FILE="$STATE_DIR/last-stall-alert"
    STALL_COOLDOWN=86400  # 24 hours between stall alerts
    STALE_JOBS=""

    # Check cooldown — skip stall check if we alerted recently
    LAST_STALL_ALERT=0
    [ -f "$STALL_ALERT_FILE" ] && LAST_STALL_ALERT=$(cat "$STALL_ALERT_FILE" 2>/dev/null || echo "0")
    STALL_ALERT_AGE=$((NOW_EPOCH - LAST_STALL_ALERT))

    if [ "$STALL_ALERT_AGE" -gt "$STALL_COOLDOWN" ]; then
        while IFS= read -r stall_job; do
            stall_enabled=$(reg_get "$stall_job" "enabled" "true")
            [ "$stall_enabled" = "false" ] && continue

            # Skip on-demand/webhook jobs — they run when triggered, not on a schedule
            stall_type=$(reg_get "$stall_job" "schedule.type" "")
            [ "$stall_type" = "on-demand" ] && continue

            stall_last_run=$(get_last_run "$stall_job")
            [ "$stall_last_run" -eq 0 ] && continue  # Never run — not a stall

            # Calculate schedule-aware threshold
            stall_threshold=259200  # default 3 days
            case "$stall_type" in
                interval)
                    stall_hours=$(reg_get "$stall_job" "schedule.every_hours" "24")
                    stall_threshold=$(( stall_hours * 3600 * 3 ))  # 3x the interval
                    ;;
                weekly)
                    stall_threshold=$((10 * 86400))  # 10 days for weekly jobs
                    ;;
                daily)
                    stall_threshold=$((3 * 86400))   # 3 days for daily jobs
                    ;;
            esac

            stall_age=$((NOW_EPOCH - stall_last_run))
            if [ "$stall_age" -gt "$stall_threshold" ]; then
                stall_days=$((stall_age / 86400))
                STALE_JOBS="${STALE_JOBS}${stall_job} (${stall_days}d), "
            fi
        done < <(get_job_names)

        if [ -n "$STALE_JOBS" ]; then
            STALE_JOBS="${STALE_JOBS%, }"
            log_warning "Pipeline stall detected: $STALE_JOBS"
            MSGBUS="$SCRIPT_DIR/lib/msgbus.sh"
            if [ -x "$MSGBUS" ]; then
                "$MSGBUS" send --type "job_completed" \
                    --source "headless:dispatcher" \
                    --severity "warning" \
                    --data "$(jq -nc \
                        --arg job "dispatcher" \
                        --arg title "Pipeline stall alert" \
                        --arg sum "Stale jobs: $STALE_JOBS" \
                        '{job:$job,title:$title,summary:$sum,exit_code:0,cost_usd:"0",duration_secs:0,output_file:""}')" \
                    > /dev/null 2>&1 || true
            fi
            echo "$NOW_EPOCH" > "$STALL_ALERT_FILE"
        fi
    fi

    # Failure alerting (check if any jobs failed this cycle)
    if [ "$JOBS_FAILED" -gt 0 ]; then
        MSGBUS="$SCRIPT_DIR/lib/msgbus.sh"
        if [ -x "$MSGBUS" ]; then
            "$MSGBUS" send --type "job_failed" \
                --source "headless:dispatcher" \
                --severity "warning" \
                --data "$(jq -nc \
                    --arg job "dispatcher" \
                    --arg title "Dispatch cycle failures" \
                    --arg sum "Jobs dispatch: $JOBS_FAILED job(s) failed this cycle" \
                    --argjson failed "$JOBS_FAILED" \
                    '{job:$job,title:$title,summary:$sum,exit_code:1,cost_usd:"0",duration_secs:0,output_file:"",failed_count:$failed}')" \
                > /dev/null 2>&1 || true
        fi
    fi

    # Run message relay after dispatch cycle (delivers pending notifications)
    RELAY="$SCRIPT_DIR/lib/msg-relay.sh"
    if [ -x "$RELAY" ]; then
        "$RELAY" 2>&1 | tee -a "$LOG_DIR/relay.log" || true
    fi
fi

# Touch heartbeat file so external watchdog can detect stalled dispatcher
touch "$STATE_DIR/dispatcher-heartbeat" 2>/dev/null || true

exit 0
