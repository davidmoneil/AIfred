#!/bin/bash
# dashboard.sh - Headless job observability dashboard
#
# Terminal dashboard for job status, costs, and health at a glance.
# Backed by SQLite (jobs.db).
#
# Usage:
#   dashboard.sh                  # Full dashboard
#   dashboard.sh --summary        # One-line status
#   dashboard.sh --costs          # Costs section only
#   dashboard.sh --json           # Full JSON output
#
# Also invokable via: dispatcher.sh --dashboard [--summary|--costs|--json]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
JOBS_DIR="$(dirname "$SCRIPT_DIR")"
REGISTRY="$JOBS_DIR/registry.yaml"

# Shared utilities (colors, logging, require_yq, reg_get)
source "$SCRIPT_DIR/common.sh"
STATE_DIR="$JOBS_DIR/state"
LOCKS_DIR="$STATE_DIR/locks"
JOBSDB="$SCRIPT_DIR/jobsdb.py"
COST_REPORT="$SCRIPT_DIR/cost-report.sh"
OLLAMA_URL="${OLLAMA_URL:-http://localhost:11434}"
PUSHGATEWAY_URL="${PUSHGATEWAY_URL:-http://localhost:9091}"

# SQLite helper
_db() { python3 "$JOBSDB" "$@"; }

# Colors, logging, require_yq, reg_get loaded from common.sh
# Extra dashboard-specific colors
JSON_MODE=false
if [ -t 1 ]; then
    BOLD='\033[1m'
    DIM='\033[2m'
else
    BOLD='' DIM=''
fi

# Set up yq
YQ=$(require_yq)

# ============================================================================
# Section: Engine Status
# ============================================================================

check_engine_status() {
    local claude_status ollama_status pushgw_status

    if command -v claude &>/dev/null; then
        claude_status="${GREEN}available${NC}"
    else
        claude_status="${RED}not found${NC}"
    fi

    if curl -s --max-time 3 "$OLLAMA_URL/api/tags" >/dev/null 2>&1; then
        local model_count
        model_count=$(curl -s --max-time 3 "$OLLAMA_URL/api/tags" 2>/dev/null | jq '.models | length' 2>/dev/null || echo "?")
        ollama_status="${GREEN}running${NC} (${model_count} models)"
    else
        ollama_status="${RED}unreachable${NC}"
    fi

    if curl -s --max-time 3 "$PUSHGATEWAY_URL/-/healthy" >/dev/null 2>&1; then
        pushgw_status="${GREEN}healthy${NC}"
    else
        pushgw_status="${YELLOW}unreachable${NC}"
    fi

    echo -e "${BOLD}Engine Status${NC}"
    echo "─────────────"
    echo -e "  Claude CLI:   $claude_status"
    echo -e "  Ollama:       $ollama_status"
    echo -e "  Pushgateway:  $pushgw_status"
}

engine_status_json() {
    local claude_ok=false ollama_ok=false pushgw_ok=false
    local ollama_models=0

    command -v claude &>/dev/null && claude_ok=true

    if curl -s --max-time 3 "$OLLAMA_URL/api/tags" >/dev/null 2>&1; then
        ollama_ok=true
        ollama_models=$(curl -s --max-time 3 "$OLLAMA_URL/api/tags" 2>/dev/null | jq '.models | length' 2>/dev/null || echo "0")
    fi

    curl -s --max-time 3 "$PUSHGATEWAY_URL/-/healthy" >/dev/null 2>&1 && pushgw_ok=true

    jq -nc \
        --argjson claude "$claude_ok" \
        --argjson ollama "$ollama_ok" \
        --argjson ollama_models "$ollama_models" \
        --argjson pushgw "$pushgw_ok" \
        '{claude_cli: $claude, ollama: {available: $ollama, models: $ollama_models}, pushgateway: $pushgw}'
}

# ============================================================================
# Section: Job Status Table
# ============================================================================

print_job_table() {
    echo ""
    echo -e "${BOLD}Job Status${NC}"
    echo "──────────"
    printf "  %-22s %-12s %-8s %-18s %-10s %s\n" "JOB" "ENGINE" "STATUS" "LAST RUN" "COST" "RESULT"
    printf "  %-22s %-12s %-8s %-18s %-10s %s\n" "───" "──────" "──────" "────────" "────" "──────"

    while IFS= read -r job; do
        local engine enabled last_run last_str status_icon cost_str result_str
        local lock_file="$LOCKS_DIR/${job}.lock"

        engine=$(reg_get "$job" "engine" "claude-code")
        enabled=$(reg_get "$job" "enabled" "true")
        last_run=$(_db exec-scalar "SELECT COALESCE(last_run, 0) FROM job_state WHERE job = ?" "$job")
        last_run="${last_run:-0}"

        if [ "$last_run" -eq 0 ]; then
            last_str="never"
        else
            last_str=$(date -d "@$last_run" '+%m-%d %H:%M' 2>/dev/null || echo "?")
        fi

        # Status
        if [ "$enabled" = "false" ]; then
            status_icon="${DIM}disabled${NC}"
        elif [ -f "$lock_file" ]; then
            local pid
            pid=$(cat "$lock_file" 2>/dev/null || echo "")
            if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
                status_icon="${CYAN}running${NC}"
            else
                status_icon="${YELLOW}stale${NC}"
            fi
        else
            status_icon="${GREEN}ready${NC}"
        fi

        # Last run result from events
        cost_str="--"
        result_str="--"
        if [ "$last_run" -gt 0 ]; then
            local last_notif
            last_notif=$(_db exec-raw \
                "SELECT COALESCE(json_extract(data, '$.cost_usd'), 'unknown'), severity FROM events WHERE event_type = 'job_completed' AND json_extract(data, '$.job') = ? ORDER BY id DESC LIMIT 1" \
                "$job")
            if [ -n "$last_notif" ]; then
                local cost sev
                IFS=$'\t' read -r cost sev <<< "$last_notif"
                cost_str="$cost"
                [ "$cost_str" != "--" ] && [ "$cost_str" != "unknown" ] && cost_str="\$$cost_str"
                [ "$cost_str" = "unknown" ] && cost_str="--"
                case "$sev" in
                    critical) result_str="${RED}critical${NC}" ;;
                    warning)  result_str="${YELLOW}warning${NC}" ;;
                    info)     result_str="${GREEN}ok${NC}" ;;
                    *)        result_str="$sev" ;;
                esac
            fi
        fi

        printf "  %-22s %-12s %-8b %-18s %-10s %b\n" \
            "$job" "$engine" "$status_icon" "$last_str" "$cost_str" "$result_str"
    done < <("$YQ" '.jobs | keys | .[]' "$REGISTRY" 2>/dev/null)
}

job_table_json() {
    local jobs_json="[]"

    while IFS= read -r job; do
        local engine enabled last_run status cost_str severity
        local lock_file="$LOCKS_DIR/${job}.lock"

        engine=$(reg_get "$job" "engine" "claude-code")
        enabled=$(reg_get "$job" "enabled" "true")
        last_run=$(_db exec-scalar "SELECT COALESCE(last_run, 0) FROM job_state WHERE job = ?" "$job")
        last_run="${last_run:-0}"

        if [ "$enabled" = "false" ]; then
            status="disabled"
        elif [ -f "$lock_file" ]; then
            local pid
            pid=$(cat "$lock_file" 2>/dev/null || echo "")
            if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
                status="running"
            else
                status="stale_lock"
            fi
        else
            status="ready"
        fi

        cost_str="0"
        severity="unknown"
        if [ "$last_run" -gt 0 ]; then
            local last_notif
            last_notif=$(_db exec-raw \
                "SELECT COALESCE(json_extract(data, '$.cost_usd'), '0'), severity FROM events WHERE event_type = 'job_completed' AND json_extract(data, '$.job') = ? ORDER BY id DESC LIMIT 1" \
                "$job")
            if [ -n "$last_notif" ]; then
                IFS=$'\t' read -r cost_str severity <<< "$last_notif"
                [ "$cost_str" = "unknown" ] && cost_str="0"
            fi
        fi

        jobs_json=$(echo "$jobs_json" | jq --arg job "$job" --arg eng "$engine" \
            --arg status "$status" --argjson lr "$last_run" \
            --arg cost "$cost_str" --arg sev "$severity" \
            '. + [{job: $job, engine: $eng, status: $status, last_run: $lr, last_cost_usd: ($cost | tonumber), last_severity: $sev}]')
    done < <("$YQ" '.jobs | keys | .[]' "$REGISTRY" 2>/dev/null)

    echo "$jobs_json"
}

# ============================================================================
# Section: Cost Summary
# ============================================================================

print_cost_summary() {
    echo ""
    echo -e "${BOLD}Cost Summary${NC}"
    echo "────────────"

    local today today_cost week_cost month_cost
    today=$(date +%Y-%m-%d)
    local week_ago month_ago
    week_ago=$(date -d "7 days ago" +%Y-%m-%d 2>/dev/null || date -v-7d +%Y-%m-%d 2>/dev/null)
    month_ago=$(date -d "30 days ago" +%Y-%m-%d 2>/dev/null || date -v-30d +%Y-%m-%d 2>/dev/null)

    today_cost=$(_db exec-scalar \
        "SELECT COALESCE(SUBSTR(CAST(SUM(CAST(json_extract(data, '$.cost_usd') AS REAL)) AS TEXT), 1, 6), '0') FROM events WHERE event_type = 'job_completed' AND SUBSTR(created_at, 1, 10) = ? AND json_extract(data, '$.cost_usd') IS NOT NULL AND json_extract(data, '$.cost_usd') != 'unknown'" \
        "$today")
    today_cost="${today_cost:-0}"

    week_cost=$(_db exec-scalar \
        "SELECT COALESCE(SUBSTR(CAST(SUM(CAST(json_extract(data, '$.cost_usd') AS REAL)) AS TEXT), 1, 6), '0') FROM events WHERE event_type = 'job_completed' AND created_at >= ? AND json_extract(data, '$.cost_usd') IS NOT NULL AND json_extract(data, '$.cost_usd') != 'unknown'" \
        "$week_ago")
    week_cost="${week_cost:-0}"

    month_cost=$(_db exec-scalar \
        "SELECT COALESCE(SUBSTR(CAST(SUM(CAST(json_extract(data, '$.cost_usd') AS REAL)) AS TEXT), 1, 6), '0') FROM events WHERE event_type = 'job_completed' AND created_at >= ? AND json_extract(data, '$.cost_usd') IS NOT NULL AND json_extract(data, '$.cost_usd') != 'unknown'" \
        "$month_ago")
    month_cost="${month_cost:-0}"

    printf "  %-10s %s\n" "Today:" "\$$today_cost"
    printf "  %-10s %s\n" "7 days:" "\$$week_cost"
    printf "  %-10s %s\n" "30 days:" "\$$month_cost"

    # Engine breakdown (30 days)
    echo ""
    echo "  By engine (30 days):"
    _db exec-raw \
        "SELECT COALESCE(json_extract(data, '$.engine'), 'claude-code') as engine,
                SUBSTR(CAST(SUM(CAST(json_extract(data, '$.cost_usd') AS REAL)) AS TEXT), 1, 6) as cost,
                COUNT(*) as runs
         FROM events
         WHERE event_type = 'job_completed' AND created_at >= ?
           AND json_extract(data, '$.cost_usd') IS NOT NULL
           AND json_extract(data, '$.cost_usd') != 'unknown'
         GROUP BY engine ORDER BY engine" \
        "$month_ago" | \
    while IFS=$'\t' read -r eng cost runs; do
        echo "    ${eng}: \$${cost} (${runs} runs)"
    done
}

cost_summary_json() {
    local today week_ago month_ago
    today=$(date +%Y-%m-%d)
    week_ago=$(date -d "7 days ago" +%Y-%m-%d 2>/dev/null || date -v-7d +%Y-%m-%d 2>/dev/null)
    month_ago=$(date -d "30 days ago" +%Y-%m-%d 2>/dev/null || date -v-30d +%Y-%m-%d 2>/dev/null)

    local tc wc mc
    tc=$(_db exec-scalar \
        "SELECT COALESCE(SUM(CAST(json_extract(data, '$.cost_usd') AS REAL)), 0) FROM events WHERE event_type = 'job_completed' AND SUBSTR(created_at, 1, 10) = ? AND json_extract(data, '$.cost_usd') IS NOT NULL AND json_extract(data, '$.cost_usd') != 'unknown'" \
        "$today")
    wc=$(_db exec-scalar \
        "SELECT COALESCE(SUM(CAST(json_extract(data, '$.cost_usd') AS REAL)), 0) FROM events WHERE event_type = 'job_completed' AND created_at >= ? AND json_extract(data, '$.cost_usd') IS NOT NULL AND json_extract(data, '$.cost_usd') != 'unknown'" \
        "$week_ago")
    mc=$(_db exec-scalar \
        "SELECT COALESCE(SUM(CAST(json_extract(data, '$.cost_usd') AS REAL)), 0) FROM events WHERE event_type = 'job_completed' AND created_at >= ? AND json_extract(data, '$.cost_usd') IS NOT NULL AND json_extract(data, '$.cost_usd') != 'unknown'" \
        "$month_ago")

    # Engine breakdown
    local engines="[]"
    while IFS=$'\t' read -r eng cost runs; do
        [ -z "$eng" ] && continue
        engines=$(echo "$engines" | jq --arg e "$eng" --arg c "$cost" --argjson r "$runs" \
            '. + [{engine: $e, cost: ($c | tonumber), runs: $r}]')
    done < <(_db exec-raw \
        "SELECT COALESCE(json_extract(data, '$.engine'), 'claude-code'),
                CAST(SUM(CAST(json_extract(data, '$.cost_usd') AS REAL)) AS TEXT),
                COUNT(*)
         FROM events WHERE event_type = 'job_completed' AND created_at >= ?
           AND json_extract(data, '$.cost_usd') IS NOT NULL AND json_extract(data, '$.cost_usd') != 'unknown'
         GROUP BY 1" "$month_ago")

    jq -nc --argjson t "${tc:-0}" --argjson w "${wc:-0}" --argjson m "${mc:-0}" --argjson e "$engines" \
        '{today: $t, week: $w, month: $m, by_engine: $e}'
}

# ============================================================================
# Section: Recent Activity
# ============================================================================

print_recent_activity() {
    echo ""
    echo -e "${BOLD}Recent Activity${NC}"
    echo "───────────────"

    local count
    count=$(_db exec-scalar "SELECT COUNT(*) FROM events WHERE event_type = 'job_completed'")
    if [ "$count" = "0" ]; then
        echo "  No activity yet."
        return
    fi

    printf "  %-10s %-18s %-22s %-8s %s\n" "SEVERITY" "TIMESTAMP" "JOB" "COST" "SUMMARY"
    printf "  %-10s %-18s %-22s %-8s %s\n" "────────" "─────────" "───" "────" "───────"

    _db exec-raw \
        "SELECT severity, created_at, json_extract(data, '$.job'),
                COALESCE(json_extract(data, '$.cost_usd'), '--'),
                SUBSTR(COALESCE(json_extract(data, '$.summary'), ''), 1, 50)
         FROM events WHERE event_type = 'job_completed'
         ORDER BY id DESC LIMIT 10" | \
    tac | \
    while IFS=$'\t' read -r sev ts job cost summary; do
        local sev_display ts_short cost_display
        case "$sev" in
            critical) sev_display="${RED}CRITICAL${NC}" ;;
            warning)  sev_display="${YELLOW}WARNING${NC}" ;;
            info)     sev_display="${GREEN}info${NC}" ;;
            *)        sev_display="$sev" ;;
        esac
        ts_short=$(echo "$ts" | sed 's/T/ /;s/:[0-9]*Z$//')
        cost_display="$cost"
        [ "$cost" != "--" ] && [ "$cost" != "unknown" ] && cost_display="\$$cost"
        [ "$cost" = "unknown" ] && cost_display="--"
        printf "  %-10b %-18s %-22s %-8s %s\n" "$sev_display" "$ts_short" "$job" "$cost_display" "$summary"
    done
}

recent_activity_json() {
    _db exec \
        "SELECT CAST(id AS TEXT) as id, created_at as timestamp,
                json_extract(data, '$.job') as job, severity,
                COALESCE(json_extract(data, '$.summary'), '') as summary,
                COALESCE(json_extract(data, '$.cost_usd'), 'unknown') as cost_usd
         FROM events WHERE event_type = 'job_completed'
         ORDER BY id DESC LIMIT 10" | jq -s 'reverse' 2>/dev/null || echo "[]"
}

# ============================================================================
# Section: Alerts
# ============================================================================

print_alerts() {
    local count
    count=$(_db exec-scalar \
        "SELECT COUNT(*) FROM events WHERE event_type = 'job_completed' AND status NOT IN ('delivered', 'acknowledged') AND severity IN ('critical', 'warning')")

    if [ "$count" -gt 0 ]; then
        echo ""
        echo -e "${BOLD}${RED}Unacknowledged Alerts ($count)${NC}"
        echo "─────────────────────────────"
        _db exec-raw \
            "SELECT severity, json_extract(data, '$.job'), SUBSTR(COALESCE(json_extract(data, '$.summary'), 'no summary'), 1, 60), id
             FROM events WHERE event_type = 'job_completed' AND status NOT IN ('delivered', 'acknowledged') AND severity IN ('critical', 'warning')
             ORDER BY id" | \
        while IFS=$'\t' read -r sev job summary eid; do
            echo "  [$sev] $job: $summary (id: $eid)"
        done
        echo ""
        echo -e "  ${DIM}Acknowledge: dispatcher.sh --ack <id>${NC}"
    fi
}

alerts_json() {
    _db exec \
        "SELECT CAST(id AS TEXT) as id, json_extract(data, '$.job') as job, severity,
                COALESCE(json_extract(data, '$.summary'), '') as summary
         FROM events WHERE event_type = 'job_completed'
           AND status NOT IN ('delivered', 'acknowledged')
           AND severity IN ('critical', 'warning')
         ORDER BY id" | jq -s '.' 2>/dev/null || echo "[]"
}

# ============================================================================
# Summary (one-line)
# ============================================================================

print_summary() {
    local job_count running_count alert_count today_cost

    job_count=$("$YQ" '.jobs | keys | length' "$REGISTRY" 2>/dev/null || echo "0")
    running_count=$(find "$LOCKS_DIR" -name "*.lock" 2>/dev/null | wc -l)

    alert_count=$(_db exec-scalar \
        "SELECT COUNT(*) FROM events WHERE event_type = 'job_completed' AND status NOT IN ('delivered', 'acknowledged') AND severity IN ('critical', 'warning')")
    alert_count="${alert_count:-0}"

    local today
    today=$(date +%Y-%m-%d)
    today_cost=$(_db exec-scalar \
        "SELECT COALESCE(SUBSTR(CAST(SUM(CAST(json_extract(data, '$.cost_usd') AS REAL)) AS TEXT), 1, 5), '0') FROM events WHERE event_type = 'job_completed' AND SUBSTR(created_at, 1, 10) = ? AND json_extract(data, '$.cost_usd') IS NOT NULL AND json_extract(data, '$.cost_usd') != 'unknown'" \
        "$today")
    today_cost="${today_cost:-0}"

    if [ "$JSON_MODE" = "true" ]; then
        jq -nc --argjson jobs "$job_count" --argjson running "$running_count" \
            --argjson alerts "$alert_count" --arg cost "$today_cost" \
            '{jobs: $jobs, running: $running, alerts: $alerts, today_cost_usd: ($cost | tonumber)}'
    else
        local alert_display=""
        if [ "$alert_count" -gt 0 ]; then
            alert_display=" ${RED}${alert_count} alerts${NC}"
        fi
        echo -e "Jobs: ${job_count} jobs, ${running_count} running, \$${today_cost} today${alert_display}"
    fi
}

# ============================================================================
# Main
# ============================================================================

MODE="full"

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            echo "Usage: dashboard.sh [--summary|--costs|--json]"
            exit 0
            ;;
        --summary) MODE="summary"; shift ;;
        --costs) MODE="costs"; shift ;;
        --json) JSON_MODE=true; RED='' GREEN='' YELLOW='' BLUE='' CYAN='' BOLD='' DIM='' NC=''; shift ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

# Ensure state
mkdir -p "$STATE_DIR" "$LOCKS_DIR"

case "$MODE" in
    summary)
        print_summary
        ;;
    costs)
        if [ "$JSON_MODE" = "true" ]; then
            cost_summary_json
        else
            print_cost_summary
            echo ""
        fi
        ;;
    full)
        if [ "$JSON_MODE" = "true" ]; then
            jq -nc \
                --argjson engines "$(engine_status_json)" \
                --argjson jobs "$(job_table_json)" \
                --argjson costs "$(cost_summary_json)" \
                --argjson recent "$(recent_activity_json)" \
                --argjson alerts "$(alerts_json)" \
                --arg generated "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
                '{generated: $generated, engines: $engines, jobs: $jobs, costs: $costs, recent_activity: $recent, alerts: $alerts}'
        else
            echo ""
            echo -e "${BOLD}════════════════════════════════════════${NC}"
            echo -e "${BOLD}  AIfred Jobs Dashboard${NC}"
            echo -e "${BOLD}════════════════════════════════════════${NC}"
            echo -e "  ${DIM}$(date '+%Y-%m-%d %H:%M:%S')${NC}"
            echo ""
            check_engine_status
            print_job_table
            print_cost_summary
            print_recent_activity
            print_alerts
            echo ""
        fi
        ;;
esac

exit 0
