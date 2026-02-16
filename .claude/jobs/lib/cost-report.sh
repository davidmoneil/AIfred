#!/bin/bash
# cost-report.sh - Aggregate headless job costs from notifications.jsonl
#
# Part of the Headless Claude system (Phase 3: Observability).
# Deterministic bash script — no LLM costs to run.
#
# Usage:
#   cost-report.sh                          # Daily costs, past 7 days
#   cost-report.sh --period weekly          # Weekly totals, past 4 weeks
#   cost-report.sh --today                  # Today's total
#   cost-report.sh --alert-threshold 5.00   # Alert if today > $5 (via message bus)
#   cost-report.sh --json                   # JSON output for dashboard
#   cost-report.sh --engine ollama          # Filter by engine

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
JOBS_DIR="$(dirname "$SCRIPT_DIR")"
NOTIFICATIONS_FILE="$JOBS_DIR/notifications.jsonl"
MSGBUS="$SCRIPT_DIR/msgbus.sh"

# Temp file for filtered data (cleaned up on exit)
DATA_FILE=$(mktemp)
trap 'rm -f "$DATA_FILE"' EXIT

# Colors (only when interactive and not --json)
JSON_MODE=false
if [ -t 1 ]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    CYAN='\033[0;36m'
    BOLD='\033[1m'
    NC='\033[0m'
else
    RED='' GREEN='' YELLOW='' BLUE='' CYAN='' BOLD='' NC=''
fi

# ============================================================================
# Functions
# ============================================================================

show_help() {
    cat << 'EOF'
cost-report.sh - Headless Claude cost aggregation

USAGE:
    cost-report.sh [OPTIONS]

OPTIONS:
    --period <daily|weekly>   Aggregation period (default: daily)
    --today                   Show today's costs only
    --days <N>                Number of days to show (default: 7 for daily, 28 for weekly)
    --engine <name>           Filter by engine (claude-code, ollama)
    --alert-threshold <USD>   Alert via message bus if today's cost exceeds threshold
    --json                    Output JSON (for dashboard integration)
    -h, --help                Show this help

EXAMPLES:
    cost-report.sh                            # Daily costs, past 7 days
    cost-report.sh --period weekly            # Weekly totals, past 4 weeks
    cost-report.sh --today                    # Today's spending
    cost-report.sh --alert-threshold 5.00     # Alert if today > $5
    cost-report.sh --json                     # JSON for dashboard
EOF
}

# Load and filter notifications into DATA_FILE
load_notifications() {
    local engine_filter="${1:-}"

    if [ ! -f "$NOTIFICATIONS_FILE" ]; then
        echo "[]" > "$DATA_FILE"
        return
    fi

    if [ -n "$engine_filter" ]; then
        jq -s --arg eng "$engine_filter" '
            [.[] | select(.engine == $eng)
                 | select(has("cost_usd"))
                 | select((.cost_usd | type) == "string")
                 | select((.cost_usd == "unknown") | not)]
        ' "$NOTIFICATIONS_FILE" > "$DATA_FILE" 2>/dev/null || echo "[]" > "$DATA_FILE"
    else
        jq -s '
            [.[] | select(has("cost_usd"))
                 | select((.cost_usd | type) == "string")
                 | select((.cost_usd == "unknown") | not)]
        ' "$NOTIFICATIONS_FILE" > "$DATA_FILE" 2>/dev/null || { echo "[]" > "$DATA_FILE"; }
    fi
}

# Aggregate costs by date (reads from DATA_FILE)
aggregate_daily() {
    local days="$1"
    local cutoff
    cutoff=$(date -d "$days days ago" +%Y-%m-%d 2>/dev/null || date -v-${days}d +%Y-%m-%d 2>/dev/null)

    jq -r --arg cutoff "$cutoff" '
        [.[] | select(.timestamp >= $cutoff)]
        | group_by(.timestamp[:10])
        | map({
            date: .[0].timestamp[:10],
            total: (map(.cost_usd | tostring | tonumber) | add // 0),
            count: length,
            by_engine: (group_by(.engine // "claude-code") | map({
                engine: (.[0].engine // "claude-code"),
                cost: (map(.cost_usd | tostring | tonumber) | add // 0),
                count: length
            })),
            by_job: (group_by(.job) | map({
                job: .[0].job,
                cost: (map(.cost_usd | tostring | tonumber) | add // 0),
                count: length
            }) | sort_by(-.cost))
        })
        | sort_by(.date)
        | reverse
    ' "$DATA_FILE" 2>/dev/null || echo "[]"
}

# Aggregate costs by week (reads from DATA_FILE)
aggregate_weekly() {
    local weeks="$1"
    local cutoff_days=$((weeks * 7))
    local cutoff
    cutoff=$(date -d "$cutoff_days days ago" +%Y-%m-%d 2>/dev/null || date -v-${cutoff_days}d +%Y-%m-%d 2>/dev/null)

    jq -r --arg cutoff "$cutoff" '
        [.[] | select(.timestamp >= $cutoff)]
        | group_by(.timestamp[:4] + "-W" + ((.timestamp[:10] | strptime("%Y-%m-%d") | strftime("%V"))))
        | map({
            week: .[0].timestamp[:4] + "-W" + (.[0].timestamp[:10] | strptime("%Y-%m-%d") | strftime("%V")),
            total: (map(.cost_usd | tostring | tonumber) | add // 0),
            count: length,
            by_engine: (group_by(.engine // "claude-code") | map({
                engine: (.[0].engine // "claude-code"),
                cost: (map(.cost_usd | tostring | tonumber) | add // 0),
                count: length
            }))
        })
        | sort_by(.week)
        | reverse
    ' "$DATA_FILE" 2>/dev/null || echo "[]"
}

# Get today's total cost (reads from DATA_FILE)
today_total() {
    local today
    today=$(date +%Y-%m-%d)

    jq -r --arg today "$today" '
        [.[] | select(.timestamp[:10] == $today)]
        | {
            date: $today,
            total: (map(.cost_usd | tostring | tonumber) | add // 0),
            count: length,
            by_engine: (group_by(.engine // "claude-code") | map({
                engine: (.[0].engine // "claude-code"),
                cost: (map(.cost_usd | tostring | tonumber) | add // 0),
                count: length
            })),
            by_job: (group_by(.job) | map({
                job: .[0].job,
                cost: (map(.cost_usd | tostring | tonumber) | add // 0),
                count: length
            }) | sort_by(-.cost))
        }
    ' "$DATA_FILE" 2>/dev/null || echo "{}"
}

# Print daily report (terminal)
print_daily_report() {
    local aggregated="$1"
    local total_cost

    echo ""
    echo -e "${BOLD}Headless Claude Cost Report — Daily${NC}"
    echo "===================================="
    echo ""
    printf "%-12s %10s %8s %s\n" "DATE" "COST" "RUNS" "ENGINES"
    printf "%-12s %10s %8s %s\n" "----" "----" "----" "-------"

    echo "$aggregated" | jq -r '.[] |
        [.date, (.total | tostring | .[0:6]), (.count | tostring),
         (.by_engine | map(.engine + ":" + (.count | tostring)) | join(", "))]
        | @tsv' 2>/dev/null | \
    while IFS=$'\t' read -r date cost count engines; do
        printf "%-12s %9s %8s %s\n" "$date" "\$$cost" "$count" "$engines"
    done

    total_cost=$(echo "$aggregated" | jq '[.[].total] | add // 0 | tostring | .[0:6]' -r 2>/dev/null)
    echo ""
    echo -e "  ${BOLD}Period total: \$${total_cost}${NC}"
    echo ""
}

# Print weekly report (terminal)
print_weekly_report() {
    local aggregated="$1"
    local total_cost

    echo ""
    echo -e "${BOLD}Headless Claude Cost Report — Weekly${NC}"
    echo "====================================="
    echo ""
    printf "%-12s %10s %8s %s\n" "WEEK" "COST" "RUNS" "ENGINES"
    printf "%-12s %10s %8s %s\n" "----" "----" "----" "-------"

    echo "$aggregated" | jq -r '.[] |
        [.week, (.total | tostring | .[0:6]), (.count | tostring),
         (.by_engine | map(.engine + ":" + (.count | tostring)) | join(", "))]
        | @tsv' 2>/dev/null | \
    while IFS=$'\t' read -r week cost count engines; do
        printf "%-12s %9s %8s %s\n" "$week" "\$$cost" "$count" "$engines"
    done

    total_cost=$(echo "$aggregated" | jq '[.[].total] | add // 0 | tostring | .[0:6]' -r 2>/dev/null)
    echo ""
    echo -e "  ${BOLD}Period total: \$${total_cost}${NC}"
    echo ""
}

# Print today report (terminal)
print_today_report() {
    local today_data="$1"
    local total count

    total=$(echo "$today_data" | jq -r '.total | tostring | .[0:6]' 2>/dev/null)
    count=$(echo "$today_data" | jq -r '.count' 2>/dev/null)

    echo ""
    echo -e "${BOLD}Today's Headless Claude Costs${NC}"
    echo "============================="
    echo ""
    echo -e "  Total: ${BOLD}\$${total}${NC} across ${count} runs"
    echo ""

    # Engine breakdown
    echo "  By engine:"
    echo "$today_data" | jq -r '.by_engine[] |
        "    " + .engine + ": $" + (.cost | tostring | .[0:6]) + " (" + (.count | tostring) + " runs)"' 2>/dev/null

    # Job breakdown
    echo ""
    echo "  By job:"
    echo "$today_data" | jq -r '.by_job[] |
        "    " + .job + ": $" + (.cost | tostring | .[0:6]) + " (" + (.count | tostring) + " runs)"' 2>/dev/null
    echo ""
}

# Check cost threshold and alert
check_threshold() {
    local today_data="$1" threshold="$2"
    local total
    total=$(echo "$today_data" | jq -r '.total' 2>/dev/null || echo "0")

    local exceeded
    exceeded=$(echo "$total $threshold" | awk '{print ($1 > $2) ? "yes" : "no"}')

    if [ "$exceeded" = "yes" ]; then
        local msg="Daily headless cost alert: \$${total} exceeds threshold \$${threshold}"

        if [ -x "$MSGBUS" ]; then
            "$MSGBUS" send --type cost_alert \
                --source "headless:cost-report" \
                --severity warning \
                --data "$(jq -nc \
                    --arg total "$total" \
                    --arg threshold "$threshold" \
                    --arg date "$(date +%Y-%m-%d)" \
                    '{total_usd: ($total | tonumber), threshold_usd: ($threshold | tonumber), date: $date}')" \
                > /dev/null 2>&1 || true
        fi

        echo -e "${RED}ALERT: $msg${NC}" >&2
        return 1
    fi
    return 0
}

# ============================================================================
# Main
# ============================================================================

PERIOD="daily"
DAYS=""
ENGINE_FILTER=""
ALERT_THRESHOLD=""
TODAY_ONLY=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help) show_help; exit 0 ;;
        --period) PERIOD="$2"; shift 2 ;;
        --days) DAYS="$2"; shift 2 ;;
        --engine) ENGINE_FILTER="$2"; shift 2 ;;
        --alert-threshold) ALERT_THRESHOLD="$2"; shift 2 ;;
        --today) TODAY_ONLY=true; shift ;;
        --json) JSON_MODE=true; RED='' GREEN='' YELLOW='' BLUE='' CYAN='' BOLD='' NC=''; shift ;;
        *) echo "Unknown option: $1"; show_help; exit 1 ;;
    esac
done

# Set default days
if [ -z "$DAYS" ]; then
    case "$PERIOD" in
        daily)  DAYS=7 ;;
        weekly) DAYS=4 ;;  # weeks, not days
    esac
fi

# Load filtered data into temp file
load_notifications "$ENGINE_FILTER"

# Handle alert threshold (always checks today, can combine with other modes)
if [ -n "$ALERT_THRESHOLD" ]; then
    TODAY_DATA=$(today_total)
    check_threshold "$TODAY_DATA" "$ALERT_THRESHOLD" || true
fi

# Today-only mode
if [ "$TODAY_ONLY" = "true" ]; then
    TODAY_DATA=$(today_total)
    if [ "$JSON_MODE" = "true" ]; then
        echo "$TODAY_DATA" | jq '.'
    else
        print_today_report "$TODAY_DATA"
    fi
    exit 0
fi

# Period-based reports
case "$PERIOD" in
    daily)
        AGG=$(aggregate_daily "$DAYS")
        if [ "$JSON_MODE" = "true" ]; then
            echo "$AGG" | jq '.'
        else
            print_daily_report "$AGG"
        fi
        ;;
    weekly)
        AGG=$(aggregate_weekly "$DAYS")
        if [ "$JSON_MODE" = "true" ]; then
            echo "$AGG" | jq '.'
        else
            print_weekly_report "$AGG"
        fi
        ;;
    *)
        echo "Unknown period: $PERIOD (use daily or weekly)"
        exit 1
        ;;
esac

exit 0
