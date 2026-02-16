#!/bin/bash
# dashboard.sh - Headless Claude observability dashboard
#
# Part of the Headless Claude system (Phase 4: Observability).
# Terminal dashboard for job status, costs, and health at a glance.
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
STATE_DIR="$JOBS_DIR/state"
LAST_RUN_FILE="$STATE_DIR/last-run.json"
LOCKS_DIR="$STATE_DIR/locks"
NOTIFICATIONS_FILE="$JOBS_DIR/notifications.jsonl"
COST_REPORT="$SCRIPT_DIR/cost-report.sh"
OLLAMA_URL="${OLLAMA_URL:-http://localhost:11434}"
PUSHGATEWAY_URL="${PUSHGATEWAY_URL:-http://localhost:9091}"

# Colors
JSON_MODE=false
if [ -t 1 ]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    CYAN='\033[0;36m'
    BOLD='\033[1m'
    DIM='\033[2m'
    NC='\033[0m'
else
    RED='' GREEN='' YELLOW='' BLUE='' CYAN='' BOLD='' DIM='' NC=''
fi

# Find yq
YQ=""
for yq_path in "yq" "$HOME/.local/bin/yq" "/usr/local/bin/yq" "/snap/bin/yq"; do
    if command -v "$yq_path" &>/dev/null 2>&1 || [ -x "$yq_path" ]; then
        YQ="$yq_path"
        break
    fi
done
if [ -z "$YQ" ]; then
    echo "Error: yq not found" >&2
    exit 1
fi

# Read a value from registry for a job, falling back to defaults
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

# ============================================================================
# Section: Engine Status
# ============================================================================

check_engine_status() {
    local claude_status ollama_status pushgw_status

    # Claude CLI
    if command -v claude &>/dev/null; then
        claude_status="${GREEN}available${NC}"
    else
        claude_status="${RED}not found${NC}"
    fi

    # Ollama
    if curl -s --max-time 3 "$OLLAMA_URL/api/tags" >/dev/null 2>&1; then
        local model_count
        model_count=$(curl -s --max-time 3 "$OLLAMA_URL/api/tags" 2>/dev/null | jq '.models | length' 2>/dev/null || echo "?")
        ollama_status="${GREEN}running${NC} (${model_count} models)"
    else
        ollama_status="${RED}unreachable${NC}"
    fi

    # Pushgateway
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
        last_run=$(jq -r --arg job "$job" '.[$job] // 0' "$LAST_RUN_FILE" 2>/dev/null || echo "0")

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

        # Last run result from notifications
        cost_str="--"
        result_str="--"
        if [ -f "$NOTIFICATIONS_FILE" ] && [ "$last_run" -gt 0 ]; then
            local last_notif
            last_notif=$(grep "\"$job\"" "$NOTIFICATIONS_FILE" 2>/dev/null | tail -1)
            if [ -n "$last_notif" ]; then
                cost_str=$(echo "$last_notif" | jq -r '.cost_usd // "--"' 2>/dev/null)
                [ "$cost_str" != "--" ] && [ "$cost_str" != "unknown" ] && cost_str="\$$cost_str"
                [ "$cost_str" = "unknown" ] && cost_str="--"
                local sev
                sev=$(echo "$last_notif" | jq -r '.severity // "info"' 2>/dev/null)
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
        last_run=$(jq -r --arg job "$job" '.[$job] // 0' "$LAST_RUN_FILE" 2>/dev/null || echo "0")

        # Status
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

        # Last notification
        cost_str="0"
        severity="unknown"
        if [ -f "$NOTIFICATIONS_FILE" ] && [ "$last_run" -gt 0 ]; then
            local last_notif
            last_notif=$(grep "\"$job\"" "$NOTIFICATIONS_FILE" 2>/dev/null | tail -1)
            if [ -n "$last_notif" ]; then
                cost_str=$(echo "$last_notif" | jq -r '.cost_usd // "0"' 2>/dev/null)
                [ "$cost_str" = "unknown" ] && cost_str="0"
                severity=$(echo "$last_notif" | jq -r '.severity // "unknown"' 2>/dev/null)
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

    if [ ! -f "$NOTIFICATIONS_FILE" ]; then
        echo "  No cost data yet."
        return
    fi

    local today today_cost week_cost month_cost
    today=$(date +%Y-%m-%d)
    local week_ago month_ago
    week_ago=$(date -d "7 days ago" +%Y-%m-%d 2>/dev/null || date -v-7d +%Y-%m-%d 2>/dev/null)
    month_ago=$(date -d "30 days ago" +%Y-%m-%d 2>/dev/null || date -v-30d +%Y-%m-%d 2>/dev/null)

    today_cost=$(jq -s --arg d "$today" \
        '[.[] | select(.timestamp[:10] == $d and .cost_usd != null and .cost_usd != "unknown") | .cost_usd | tostring | tonumber] | add // 0 | tostring | .[0:6]' \
        "$NOTIFICATIONS_FILE" 2>/dev/null -r || echo "0")

    week_cost=$(jq -s --arg d "$week_ago" \
        '[.[] | select(.timestamp >= $d and .cost_usd != null and .cost_usd != "unknown") | .cost_usd | tostring | tonumber] | add // 0 | tostring | .[0:6]' \
        "$NOTIFICATIONS_FILE" 2>/dev/null -r || echo "0")

    month_cost=$(jq -s --arg d "$month_ago" \
        '[.[] | select(.timestamp >= $d and .cost_usd != null and .cost_usd != "unknown") | .cost_usd | tostring | tonumber] | add // 0 | tostring | .[0:6]' \
        "$NOTIFICATIONS_FILE" 2>/dev/null -r || echo "0")

    printf "  %-10s %s\n" "Today:" "\$$today_cost"
    printf "  %-10s %s\n" "7 days:" "\$$week_cost"
    printf "  %-10s %s\n" "30 days:" "\$$month_cost"

    # Engine breakdown (30 days)
    echo ""
    echo "  By engine (30 days):"
    jq -s --arg d "$month_ago" '
        [.[] | select(.timestamp >= $d and .cost_usd != null and .cost_usd != "unknown")]
        | group_by(.engine // "claude-code")
        | map("    " + (.[0].engine // "claude-code") + ": $" + (map(.cost_usd | tostring | tonumber) | add // 0 | tostring | .[0:6]) + " (" + (length | tostring) + " runs)")
        | .[]' "$NOTIFICATIONS_FILE" 2>/dev/null -r || true
}

cost_summary_json() {
    if [ ! -f "$NOTIFICATIONS_FILE" ]; then
        echo '{"today": 0, "week": 0, "month": 0, "by_engine": []}'
        return
    fi

    local today week_ago month_ago
    today=$(date +%Y-%m-%d)
    week_ago=$(date -d "7 days ago" +%Y-%m-%d 2>/dev/null || date -v-7d +%Y-%m-%d 2>/dev/null)
    month_ago=$(date -d "30 days ago" +%Y-%m-%d 2>/dev/null || date -v-30d +%Y-%m-%d 2>/dev/null)

    jq -s --arg today "$today" --arg week "$week_ago" --arg month "$month_ago" '{
        today: ([.[] | select(.timestamp[:10] == $today and .cost_usd != null and .cost_usd != "unknown") | .cost_usd | tostring | tonumber] | add // 0),
        week: ([.[] | select(.timestamp >= $week and .cost_usd != null and .cost_usd != "unknown") | .cost_usd | tostring | tonumber] | add // 0),
        month: ([.[] | select(.timestamp >= $month and .cost_usd != null and .cost_usd != "unknown") | .cost_usd | tostring | tonumber] | add // 0),
        by_engine: ([.[] | select(.timestamp >= $month and .cost_usd != null and .cost_usd != "unknown")]
            | group_by(.engine // "claude-code")
            | map({engine: (.[0].engine // "claude-code"), cost: (map(.cost_usd | tostring | tonumber) | add // 0), runs: length}))
    }' "$NOTIFICATIONS_FILE" 2>/dev/null || echo '{"today":0,"week":0,"month":0,"by_engine":[]}'
}

# ============================================================================
# Section: Recent Activity
# ============================================================================

print_recent_activity() {
    echo ""
    echo -e "${BOLD}Recent Activity${NC}"
    echo "───────────────"

    if [ ! -f "$NOTIFICATIONS_FILE" ]; then
        echo "  No activity yet."
        return
    fi

    printf "  %-10s %-18s %-22s %-8s %s\n" "SEVERITY" "TIMESTAMP" "JOB" "COST" "SUMMARY"
    printf "  %-10s %-18s %-22s %-8s %s\n" "────────" "─────────" "───" "────" "───────"

    tail -10 "$NOTIFICATIONS_FILE" | jq -r \
        '[.severity, .timestamp, .job, (.cost_usd // "--"), (.summary // "")[0:50]] | @tsv' 2>/dev/null | \
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
    if [ ! -f "$NOTIFICATIONS_FILE" ]; then
        echo "[]"
        return
    fi
    tail -10 "$NOTIFICATIONS_FILE" | jq -s '.' 2>/dev/null || echo "[]"
}

# ============================================================================
# Section: Alerts
# ============================================================================

print_alerts() {
    if [ ! -f "$NOTIFICATIONS_FILE" ]; then
        return
    fi

    local unacked
    unacked=$(jq -s '[.[] | select(.acknowledged == false and (.severity == "critical" or .severity == "warning"))]' \
        "$NOTIFICATIONS_FILE" 2>/dev/null)
    local count
    count=$(echo "$unacked" | jq 'length' 2>/dev/null || echo "0")

    if [ "$count" -gt 0 ]; then
        echo ""
        echo -e "${BOLD}${RED}Unacknowledged Alerts ($count)${NC}"
        echo "─────────────────────────────"
        echo "$unacked" | jq -r '.[] |
            "  [" + .severity + "] " + .job + ": " + (.summary // "no summary")[0:60] + " (id: " + .id + ")"' 2>/dev/null
        echo ""
        echo -e "  ${DIM}Acknowledge: dispatcher.sh --ack <id>${NC}"
    fi
}

alerts_json() {
    if [ ! -f "$NOTIFICATIONS_FILE" ]; then
        echo "[]"
        return
    fi
    jq -s '[.[] | select(.acknowledged == false and (.severity == "critical" or .severity == "warning"))]' \
        "$NOTIFICATIONS_FILE" 2>/dev/null || echo "[]"
}

# ============================================================================
# Summary (one-line)
# ============================================================================

print_summary() {
    local job_count running_count alert_count today_cost

    job_count=$("$YQ" '.jobs | keys | length' "$REGISTRY" 2>/dev/null || echo "0")
    running_count=$(find "$LOCKS_DIR" -name "*.lock" 2>/dev/null | wc -l)

    if [ -f "$NOTIFICATIONS_FILE" ]; then
        alert_count=$(jq -s '[.[] | select(.acknowledged == false and (.severity == "critical" or .severity == "warning"))] | length' \
            "$NOTIFICATIONS_FILE" 2>/dev/null || echo "0")
        local today
        today=$(date +%Y-%m-%d)
        today_cost=$(jq -s --arg d "$today" \
            '[.[] | select(.timestamp[:10] == $d and .cost_usd != null and .cost_usd != "unknown") | .cost_usd | tostring | tonumber] | add // 0 | tostring | .[0:5]' \
            "$NOTIFICATIONS_FILE" 2>/dev/null -r || echo "0")
    else
        alert_count=0
        today_cost="0"
    fi

    if [ "$JSON_MODE" = "true" ]; then
        jq -nc --argjson jobs "$job_count" --argjson running "$running_count" \
            --argjson alerts "$alert_count" --arg cost "$today_cost" \
            '{jobs: $jobs, running: $running, alerts: $alerts, today_cost_usd: ($cost | tonumber)}'
    else
        local alert_display=""
        if [ "$alert_count" -gt 0 ]; then
            alert_display=" ${RED}${alert_count} alerts${NC}"
        fi
        echo -e "Headless: ${job_count} jobs, ${running_count} running, \$${today_cost} today${alert_display}"
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
[ ! -f "$LAST_RUN_FILE" ] && echo '{}' > "$LAST_RUN_FILE"

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
            echo -e "${BOLD}  Headless Claude Dashboard${NC}"
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
