#!/bin/bash
# Context Monitor for Jarvis JICM System
# Monitors token usage and triggers JICM when threshold is exceeded
#
# WHAT WE CAN CAPTURE:
#   - Total token count from status line (e.g., "120916 tokens")
#   - Percentage of max context (200K for Opus 4.5)
#
# WHAT WE CANNOT CAPTURE PROGRAMMATICALLY:
#   - Detailed breakdown by category (files, system prompt, conversation)
#   - The /context command output is ephemeral (renders as overlay, doesn't persist)
#   - This breakdown is only visible via /context in the Claude Code UI
#
# Two modes:
#   1. Timer mode: Polls status line every N seconds, triggers at threshold
#   2. Capture mode: Captures /context output (limited - see LIMITATIONS below)
#
# Usage:
#   .claude/scripts/context-monitor.sh watch [threshold_pct] [interval_sec]
#   .claude/scripts/context-monitor.sh capture-context
#   .claude/scripts/context-monitor.sh status
#
# Related scripts:
#   - capture-token-count.sh: Focused script for getting actual token count

set -euo pipefail

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$HOME/Claude/Jarvis}"
TMUX_BIN="${TMUX_BIN:-$HOME/bin/tmux}"
TMUX_SESSION="${TMUX_SESSION:-jarvis}"
CONTEXT_FILE="$PROJECT_DIR/.claude/context/.context-snapshot"
STATUS_FILE="$PROJECT_DIR/.claude/context/.context-status"
LOG_FILE="$PROJECT_DIR/.claude/logs/context-monitor.log"

# Default threshold: 65% of ~200k context = 130k tokens
DEFAULT_THRESHOLD_PCT=65
DEFAULT_INTERVAL=30  # seconds

# Max context (Opus 4.5 has ~200k)
MAX_CONTEXT_TOKENS=200000

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

mkdir -p "$(dirname "$LOG_FILE")"
mkdir -p "$(dirname "$CONTEXT_FILE")"

log() {
    local msg="$1"
    local timestamp
    timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    echo "$timestamp | $msg" >> "$LOG_FILE"
    echo -e "$msg"
}

# Get current token count from status line
get_token_count() {
    local tokens
    tokens=$("$TMUX_BIN" capture-pane -t "$TMUX_SESSION:0.0" -p 2>/dev/null | \
             grep -oE '[0-9,]+ tokens' | \
             tail -1 | \
             tr -d ', tokens' || echo "0")
    echo "${tokens:-0}"
}

# Calculate percentage of max context
calc_percentage() {
    local tokens="$1"
    local pct
    pct=$(echo "scale=1; ($tokens * 100) / $MAX_CONTEXT_TOKENS" | bc 2>/dev/null || echo "0")
    echo "$pct"
}

# Capture /context output by triggering it and capturing pane
capture_context_output() {
    log "Triggering /context capture..."

    # Record current line count
    local before_lines
    before_lines=$("$TMUX_BIN" capture-pane -t "$TMUX_SESSION:0.0" -p -S -500 | wc -l)

    # Send /context command
    "$TMUX_BIN" send-keys -t "$TMUX_SESSION:0.0" "/context" Enter

    # Wait for output (adaptive)
    sleep 2

    local wait_count=0
    local last_lines=0
    while [[ $wait_count -lt 10 ]]; do
        local current_lines
        current_lines=$("$TMUX_BIN" capture-pane -t "$TMUX_SESSION:0.0" -p -S -500 | wc -l)

        if [[ $current_lines -eq $last_lines ]] && [[ $current_lines -gt $before_lines ]]; then
            break
        fi

        last_lines=$current_lines
        sleep 0.5
        ((wait_count++))
    done

    # Capture full pane
    local captured
    captured=$("$TMUX_BIN" capture-pane -t "$TMUX_SESSION:0.0" -p -S -100)

    # Write to file
    {
        echo "# Context Snapshot"
        echo "# Captured: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
        echo ""
        echo "## Status Line"
        echo "$captured" | tail -10
        echo ""
        echo "## Full Capture"
        echo '```'
        echo "$captured"
        echo '```'
    } > "$CONTEXT_FILE"

    log "Context snapshot saved to: $CONTEXT_FILE"
}

# Update status file with current metrics
update_status() {
    local tokens="$1"
    local pct="$2"
    local threshold="$3"

    local status="normal"
    local pct_int
    pct_int=$(echo "$pct" | cut -d'.' -f1)

    if [[ $pct_int -ge $threshold ]]; then
        status="critical"
    elif [[ $pct_int -ge $((threshold - 10)) ]]; then
        status="warning"
    fi

    {
        echo "# Context Status"
        echo "timestamp: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
        echo "tokens: $tokens"
        echo "percentage: $pct%"
        echo "threshold: $threshold%"
        echo "status: $status"
        echo "max_context: $MAX_CONTEXT_TOKENS"
    } > "$STATUS_FILE"
}

# Watch mode: continuous monitoring
watch_mode() {
    local threshold="${1:-$DEFAULT_THRESHOLD_PCT}"
    local interval="${2:-$DEFAULT_INTERVAL}"

    echo -e "${CYAN}"
    echo "╔═══════════════════════════════════════════════════════════════╗"
    echo "║              JARVIS CONTEXT MONITOR                           ║"
    echo "╚═══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
    echo -e "  ${BLUE}Threshold:${NC}  ${threshold}% (~$((MAX_CONTEXT_TOKENS * threshold / 100)) tokens)"
    echo -e "  ${BLUE}Interval:${NC}   ${interval}s"
    echo -e "  ${BLUE}Max Context:${NC} ${MAX_CONTEXT_TOKENS} tokens"
    echo ""
    echo "  Press Ctrl+C to stop"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    local jicm_triggered=false

    while true; do
        local tokens
        tokens=$(get_token_count)

        if [[ "$tokens" == "0" ]]; then
            echo -e "$(date +%H:%M:%S) ${YELLOW}Could not read token count${NC}"
            sleep "$interval"
            continue
        fi

        local pct
        pct=$(calc_percentage "$tokens")
        local pct_int
        pct_int=$(echo "$pct" | cut -d'.' -f1)

        # Update status file
        update_status "$tokens" "$pct" "$threshold"

        # Display current status
        local color="$GREEN"
        local symbol="●"
        if [[ $pct_int -ge $threshold ]]; then
            color="$RED"
            symbol="⚠"
        elif [[ $pct_int -ge $((threshold - 10)) ]]; then
            color="$YELLOW"
            symbol="◐"
        fi

        echo -e "$(date +%H:%M:%S) ${color}${symbol}${NC} Tokens: ${tokens} (${pct}%)"

        # Trigger JICM if threshold exceeded and not already triggered
        if [[ $pct_int -ge $threshold ]] && [[ "$jicm_triggered" == "false" ]]; then
            log "${RED}THRESHOLD EXCEEDED${NC} - Triggering JICM"
            echo ""
            echo -e "  ${RED}╔═══════════════════════════════════════╗${NC}"
            echo -e "  ${RED}║  CONTEXT THRESHOLD EXCEEDED           ║${NC}"
            echo -e "  ${RED}║  Triggering JICM system...            ║${NC}"
            echo -e "  ${RED}╚═══════════════════════════════════════╝${NC}"
            echo ""

            # Capture context before triggering JICM
            capture_context_output

            # Trigger JICM signal (this will be picked up by the main watcher or hooks)
            echo "$(date -u +%Y-%m-%dT%H:%M:%SZ)" > "$PROJECT_DIR/.claude/context/.jicm-trigger"

            jicm_triggered=true
            log "JICM trigger created"
        fi

        # Reset trigger flag if we drop below threshold
        if [[ $pct_int -lt $((threshold - 5)) ]]; then
            jicm_triggered=false
        fi

        sleep "$interval"
    done
}

# Status mode: show current context status
status_mode() {
    local tokens
    tokens=$(get_token_count)

    if [[ "$tokens" == "0" ]]; then
        echo -e "${YELLOW}Could not read token count from tmux${NC}"
        echo "Make sure Jarvis is running in tmux session '$TMUX_SESSION'"
        exit 1
    fi

    local pct
    pct=$(calc_percentage "$tokens")

    echo -e "${CYAN}Context Status${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "  Tokens:     ${GREEN}$tokens${NC}"
    echo -e "  Percentage: ${GREEN}$pct%${NC}"
    echo -e "  Max:        $MAX_CONTEXT_TOKENS"
    echo ""

    # Show status file if exists
    if [[ -f "$STATUS_FILE" ]]; then
        echo "Last recorded status:"
        cat "$STATUS_FILE" | sed 's/^/  /'
    fi
}

# Main
case "${1:-status}" in
    watch)
        shift
        watch_mode "$@"
        ;;
    capture-context|capture)
        capture_context_output
        ;;
    status)
        status_mode
        ;;
    help|--help|-h)
        echo "Context Monitor for Jarvis JICM System"
        echo ""
        echo "Usage:"
        echo "  $0 status                    Show current context status"
        echo "  $0 watch [threshold] [interval]"
        echo "                               Watch mode with threshold % and interval seconds"
        echo "                               Default: 65% threshold, 30s interval"
        echo "  $0 capture-context           Capture /context output to file"
        echo ""
        echo "Files:"
        echo "  $STATUS_FILE   - Current status"
        echo "  $CONTEXT_FILE  - Last /context capture"
        echo "  $LOG_FILE      - Monitor log"
        ;;
    *)
        echo "Unknown command: $1"
        echo "Run '$0 help' for usage"
        exit 1
        ;;
esac
