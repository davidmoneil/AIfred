#!/bin/bash
# watch-jicm.sh — JICM state monitor with one-shot and continuous modes
#
# Reads .jicm-state and presents it as formatted dashboard or JSON.
# One-shot JSON mode is critical for Jarvis-dev automation (Bash tool parsing).
#
# Usage: watch-jicm.sh [--once] [--json] [--interval SEC]
#
# Part of Jarvis dev-ops testing infrastructure.
set -euo pipefail

# ─── Configuration ──────────────────────────────────────────────────────────
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$HOME/Claude/Jarvis}"
STATE_FILE="$PROJECT_DIR/.claude/context/.jicm-state"
SLEEP_SIGNAL="$PROJECT_DIR/.claude/context/.jicm-sleep.signal"
INTERVAL=2
ONCE=false
JSON_MODE=false

# ─── Colors (ANSI-C quoting) ───────────────────────────────────────────────
C_RESET=$'\e[0m'
C_BOLD=$'\e[1m'
C_DIM=$'\e[2m'
C_GREEN=$'\e[32m'
C_YELLOW=$'\e[33m'
C_CYAN=$'\e[36m'
C_RED=$'\e[31m'
C_MAGENTA=$'\e[35m'

# ─── Usage ──────────────────────────────────────────────────────────────────
show_usage() {
    cat <<EOF
watch-jicm.sh — JICM state monitor

Usage: watch-jicm.sh [options]

Options:
  --once              Print state once and exit (for Jarvis-dev Bash calls)
  --json              Output as JSON (for programmatic parsing)
  --interval SEC      Refresh interval in continuous mode (default: 2)
  -h, --help          Show this help

Examples:
  watch-jicm.sh --once --json     # One-shot JSON for automation
  watch-jicm.sh --interval 1      # Live dashboard, 1s refresh
EOF
    exit 0
}

# ─── Argument Parsing ──────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
    case $1 in
        --once)     ONCE=true; shift ;;
        --json)     JSON_MODE=true; shift ;;
        --interval) INTERVAL="$2"; shift 2 ;;
        -h|--help)  show_usage ;;
        *)          shift ;;
    esac
done

# ─── State Reader ──────────────────────────────────────────────────────────
# Parse .jicm-state YAML fields with awk
read_field() {
    local field="$1"
    local default="${2:-}"
    if [[ -f "$STATE_FILE" ]]; then
        awk -v f="$field" '/^[a-z_]+:/{if($1==f":") print $2}' "$STATE_FILE" 2>/dev/null || echo "$default"
    else
        echo "$default"
    fi
    return 0
}

# ─── JSON Output ──────────────────────────────────────────────────────────
output_json() {
    local state context_pct tokens compressions errors sleeping cooldown

    if [[ ! -f "$STATE_FILE" ]]; then
        echo '{"error":"no_state_file","state":"UNKNOWN","context_pct":0}'
        return 0
    fi

    state=$(read_field "state" "UNKNOWN")
    context_pct=$(read_field "context_pct" "0")
    tokens=$(read_field "tokens" "0")
    compressions=$(read_field "compressions" "0")
    errors=$(read_field "errors" "0")
    sleeping="false"
    [[ -f "$SLEEP_SIGNAL" ]] && sleeping="true"
    cooldown=$(read_field "cooldown_until" "0")

    # Use jq if available, else manual JSON
    if command -v jq &>/dev/null; then
        jq -n \
            --arg s "$state" \
            --argjson cp "${context_pct:-0}" \
            --argjson t "${tokens:-0}" \
            --argjson c "${compressions:-0}" \
            --argjson e "${errors:-0}" \
            --argjson sl "$sleeping" \
            --argjson cd "${cooldown:-0}" \
            '{state:$s, context_pct:$cp, tokens:$t, compressions:$c, errors:$e, sleeping:$sl, cooldown_until:$cd}'
    else
        echo "{\"state\":\"$state\",\"context_pct\":$context_pct,\"tokens\":$tokens,\"compressions\":$compressions,\"errors\":$errors,\"sleeping\":$sleeping,\"cooldown_until\":$cooldown}"
    fi
    return 0
}

# ─── Dashboard Output ─────────────────────────────────────────────────────
output_dashboard() {
    if [[ ! -f "$STATE_FILE" ]]; then
        echo "JICM State: ${C_RED}NO STATE FILE${C_RESET}"
        echo "  Expected: $STATE_FILE"
        return 0
    fi

    local state context_pct tokens compressions errors sleeping
    state=$(read_field "state" "UNKNOWN")
    context_pct=$(read_field "context_pct" "0")
    tokens=$(read_field "tokens" "0")
    compressions=$(read_field "compressions" "0")
    errors=$(read_field "errors" "0")
    sleeping="false"
    [[ -f "$SLEEP_SIGNAL" ]] && sleeping="true"

    # Color-code state
    local state_color="$C_DIM"
    case "$state" in
        WATCHING)    state_color="$C_GREEN" ;;
        HALTING)     state_color="$C_YELLOW" ;;
        COMPRESSING) state_color="$C_CYAN" ;;
        CLEARING)    state_color="$C_RED" ;;
        RESTORING)   state_color="$C_MAGENTA" ;;
    esac

    # Progress bar
    local bar_width=30
    local pct_num="${context_pct:-0}"
    local filled=$(( pct_num * bar_width / 100 ))
    [[ $filled -gt $bar_width ]] && filled=$bar_width
    local empty=$(( bar_width - filled ))
    local bar=""
    local i
    for (( i=0; i<filled; i++ )); do bar+="█"; done
    for (( i=0; i<empty; i++ )); do bar+="░"; done

    printf '\\033[H\\033[2J'  # Clear screen (continuous mode)
    echo "${C_BOLD}JICM State Monitor${C_RESET}"
    echo ""
    echo "  State:        ${state_color}${C_BOLD}${state}${C_RESET}"
    echo "  Context:      [${bar}] ${pct_num}%"
    echo "  Tokens:       ${tokens}"
    echo "  Compressions: ${compressions}"
    echo "  Errors:       ${errors}"
    echo "  Sleeping:     ${sleeping}"
    echo ""
    echo "  ${C_DIM}Updated: $(date +%H:%M:%S)${C_RESET}"
    return 0
}

# ─── Main ──────────────────────────────────────────────────────────────────
if [[ "$ONCE" == "true" ]]; then
    if [[ "$JSON_MODE" == "true" ]]; then
        output_json
    else
        # One-shot dashboard without screen clear
        if [[ ! -f "$STATE_FILE" ]]; then
            echo "JICM State: NO STATE FILE"
            exit 1
        fi
        local_state=$(read_field "state" "UNKNOWN")
        local_pct=$(read_field "context_pct" "0")
        local_tokens=$(read_field "tokens" "0")
        local_compressions=$(read_field "compressions" "0")
        echo "State: $local_state | Context: ${local_pct}% | Tokens: $local_tokens | Compressions: $local_compressions"
    fi
    exit 0
fi

# Continuous mode
trap 'echo ""; echo "Monitor stopped."; exit 0' INT TERM

while true; do
    if [[ "$JSON_MODE" == "true" ]]; then
        output_json
    else
        output_dashboard
    fi
    sleep "$INTERVAL"
done
