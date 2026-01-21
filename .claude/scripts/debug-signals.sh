#!/bin/bash
# Debug utility for autonomous command signal system
# Usage: .claude/scripts/debug-signals.sh [command]
#
# Commands:
#   status    - Show watcher and signal status
#   log       - Show recent signal log entries
#   test      - Test signal creation and deletion
#   watch     - Live monitor for signals (Ctrl+C to stop)
#   clean     - Clean up stale signal files

set -euo pipefail

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$HOME/Claude/Jarvis}"
SIGNAL_FILE="$PROJECT_DIR/.claude/context/.command-signal"
LOG_FILE="$PROJECT_DIR/.claude/logs/command-signals.log"
PID_FILE="$PROJECT_DIR/.claude/context/.watcher-pid"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

header() {
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  $1${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
}

status_cmd() {
    header "Signal System Status"
    echo ""

    # Check watcher
    echo -e "${BLUE}Watcher Status:${NC}"
    if [[ -f "$PID_FILE" ]]; then
        local pid
        pid=$(cat "$PID_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            echo -e "  ${GREEN}✓ RUNNING${NC} (PID: $pid)"
        else
            echo -e "  ${RED}✗ STALE PID${NC} (PID file exists but process dead)"
        fi
    else
        echo -e "  ${YELLOW}○ NOT RUNNING${NC}"
    fi
    echo ""

    # Check tmux
    echo -e "${BLUE}tmux Status:${NC}"
    local tmux_bin="${TMUX_BIN:-$HOME/bin/tmux}"
    if [[ -x "$tmux_bin" ]]; then
        if "$tmux_bin" has-session -t jarvis 2>/dev/null; then
            echo -e "  ${GREEN}✓ Session 'jarvis' exists${NC}"
        else
            echo -e "  ${YELLOW}○ No 'jarvis' session${NC}"
        fi
    else
        echo -e "  ${RED}✗ tmux not found at $tmux_bin${NC}"
    fi
    echo ""

    # Check dependencies
    echo -e "${BLUE}Dependencies:${NC}"
    if command -v jq &>/dev/null; then
        echo -e "  ${GREEN}✓ jq installed${NC}"
    else
        echo -e "  ${RED}✗ jq not installed${NC}"
    fi
    echo ""

    # Check pending signal
    echo -e "${BLUE}Pending Signal:${NC}"
    if [[ -f "$SIGNAL_FILE" ]]; then
        echo -e "  ${YELLOW}⚠ Signal pending:${NC}"
        cat "$SIGNAL_FILE" | sed 's/^/    /'
    else
        echo -e "  ${GREEN}○ No pending signal${NC}"
    fi
    echo ""

    # Check log
    echo -e "${BLUE}Log File:${NC}"
    if [[ -f "$LOG_FILE" ]]; then
        local line_count
        line_count=$(wc -l < "$LOG_FILE" | tr -d ' ')
        echo -e "  ${GREEN}✓ Exists${NC} ($line_count entries)"
    else
        echo -e "  ${YELLOW}○ Not created yet${NC}"
    fi
}

log_cmd() {
    header "Recent Signal Log"
    echo ""
    if [[ -f "$LOG_FILE" ]]; then
        tail -20 "$LOG_FILE"
    else
        echo "No log file found at $LOG_FILE"
    fi
}

test_cmd() {
    header "Signal Test"
    echo ""

    echo -e "${BLUE}1. Testing signal creation...${NC}"
    source "$PROJECT_DIR/.claude/scripts/signal-helper.sh"
    send_command_signal "/status" "" "debug:test" "normal"
    echo ""

    echo -e "${BLUE}2. Verifying signal file...${NC}"
    if [[ -f "$SIGNAL_FILE" ]]; then
        echo -e "  ${GREEN}✓ Signal file created${NC}"
        cat "$SIGNAL_FILE" | sed 's/^/    /'
    else
        echo -e "  ${RED}✗ Signal file not created${NC}"
    fi
    echo ""

    echo -e "${BLUE}3. Cleaning up test signal...${NC}"
    rm -f "$SIGNAL_FILE"
    echo -e "  ${GREEN}✓ Test signal removed${NC}"
    echo ""

    echo -e "${GREEN}Test complete!${NC}"
    echo ""
    echo "Note: This test only verifies signal creation."
    echo "To test full execution, run with watcher active in tmux."
}

watch_cmd() {
    header "Live Signal Monitor (Ctrl+C to stop)"
    echo ""
    echo "Watching: $SIGNAL_FILE"
    echo "Log: $LOG_FILE"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    while true; do
        if [[ -f "$SIGNAL_FILE" ]]; then
            echo ""
            echo -e "$(date +%H:%M:%S) ${YELLOW}SIGNAL DETECTED:${NC}"
            cat "$SIGNAL_FILE" | sed 's/^/  /'
        fi
        sleep 1
    done
}

clean_cmd() {
    header "Cleanup"
    echo ""

    local cleaned=0

    if [[ -f "$SIGNAL_FILE" ]]; then
        rm -f "$SIGNAL_FILE"
        echo -e "${GREEN}✓ Removed stale signal file${NC}"
        ((cleaned++))
    fi

    if [[ -f "$PID_FILE" ]]; then
        local pid
        pid=$(cat "$PID_FILE")
        if ! kill -0 "$pid" 2>/dev/null; then
            rm -f "$PID_FILE"
            echo -e "${GREEN}✓ Removed stale PID file${NC}"
            ((cleaned++))
        fi
    fi

    local legacy_signal="$PROJECT_DIR/.claude/context/.auto-clear-signal"
    if [[ -f "$legacy_signal" ]]; then
        rm -f "$legacy_signal"
        echo -e "${GREEN}✓ Removed legacy clear signal${NC}"
        ((cleaned++))
    fi

    if [[ $cleaned -eq 0 ]]; then
        echo -e "${GREEN}Nothing to clean${NC}"
    fi
}

case "${1:-status}" in
    status)
        status_cmd
        ;;
    log)
        log_cmd
        ;;
    test)
        test_cmd
        ;;
    watch)
        watch_cmd
        ;;
    clean)
        clean_cmd
        ;;
    help|--help|-h)
        echo "Debug utility for autonomous command signal system"
        echo ""
        echo "Usage: $0 [command]"
        echo ""
        echo "Commands:"
        echo "  status  - Show watcher and signal status (default)"
        echo "  log     - Show recent signal log entries"
        echo "  test    - Test signal creation and deletion"
        echo "  watch   - Live monitor for signals (Ctrl+C to stop)"
        echo "  clean   - Clean up stale signal files"
        ;;
    *)
        echo "Unknown command: $1"
        echo "Run '$0 help' for usage"
        exit 1
        ;;
esac
