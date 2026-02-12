#!/bin/bash
# restart-watcher.sh — Kill and restart JICM watcher with custom threshold
#
# Used by Jarvis-dev (W5) to restart the watcher in W1 with a lower threshold
# for fast JICM cycle testing. Uses tmux respawn-window to replace W1 contents.
#
# Usage: restart-watcher.sh [--threshold PCT] [--interval SEC] [--kill-only]
#
# Exit codes: 0=success, 1=error
#
# Part of Jarvis dev-ops testing infrastructure.
set -euo pipefail

# ─── Configuration ──────────────────────────────────────────────────────────
TMUX_BIN="${TMUX_BIN:-$HOME/bin/tmux}"
SESSION="${TMUX_SESSION:-jarvis}"
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$HOME/Claude/Jarvis}"
WATCHER_SCRIPT="$PROJECT_DIR/.claude/scripts/jicm-watcher.sh"
CONTEXT_DIR="$PROJECT_DIR/.claude/context"
PID_FILE="$CONTEXT_DIR/.jicm-watcher.pid"

THRESHOLD=55
INTERVAL=5
KILL_ONLY=false

# ─── Colors (ANSI-C quoting) ───────────────────────────────────────────────
C_RESET=$'\e[0m'
C_GREEN=$'\e[32m'
C_RED=$'\e[31m'
C_YELLOW=$'\e[33m'
C_DIM=$'\e[2m'

# ─── Usage ──────────────────────────────────────────────────────────────────
show_usage() {
    cat <<EOF
restart-watcher.sh — Kill and restart JICM watcher

Usage: restart-watcher.sh [options]

Options:
  --threshold PCT     Compression trigger % (default: 55)
  --interval SEC      Poll interval (default: 5)
  --kill-only         Kill watcher without restarting
  -h, --help          Show this help

Examples:
  restart-watcher.sh --threshold 15     # Fast cycle testing
  restart-watcher.sh --threshold 55     # Restore production threshold
  restart-watcher.sh --kill-only        # Stop watcher
EOF
    exit 0
}

# ─── Argument Parsing ──────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
    case $1 in
        --threshold) THRESHOLD="$2"; shift 2 ;;
        --interval)  INTERVAL="$2"; shift 2 ;;
        --kill-only) KILL_ONLY=true; shift ;;
        -h|--help)   show_usage ;;
        *)           shift ;;
    esac
done

# ─── Preflight ─────────────────────────────────────────────────────────────
if [[ ! -x "$WATCHER_SCRIPT" ]]; then
    echo "${C_RED}ERROR: Watcher script not found: $WATCHER_SCRIPT${C_RESET}" >&2
    exit 1
fi

if ! "$TMUX_BIN" has-session -t "$SESSION" 2>/dev/null; then
    echo "${C_RED}ERROR: tmux session '$SESSION' not found${C_RESET}" >&2
    exit 1
fi

# ─── Kill Current Watcher ─────────────────────────────────────────────────
echo "${C_DIM}Killing current watcher...${C_RESET}"

# Kill via PID file
if [[ -f "$PID_FILE" ]]; then
    local_pid=$(cat "$PID_FILE" 2>/dev/null || echo "")
    if [[ -n "$local_pid" ]] && kill -0 "$local_pid" 2>/dev/null; then
        kill "$local_pid" 2>/dev/null || true
        # Wait up to 3s for graceful exit
        local waited=0
        while [[ $waited -lt 3 ]] && kill -0 "$local_pid" 2>/dev/null; do
            sleep 1
            waited=$((waited + 1))
        done
        # Force kill if still alive
        if kill -0 "$local_pid" 2>/dev/null; then
            kill -9 "$local_pid" 2>/dev/null || true
        fi
        echo "  Killed watcher PID $local_pid"
    fi
fi

# Clean up signal files
rm -f "$PID_FILE"
rm -f "$CONTEXT_DIR/.jicm-state"
rm -f "$CONTEXT_DIR/.compression-done.signal"
rm -f "$CONTEXT_DIR/.compression-in-progress"
echo "  Cleaned signal files"

if [[ "$KILL_ONLY" == "true" ]]; then
    echo "${C_GREEN}Watcher killed (not restarting)${C_RESET}"
    exit 0
fi

# ─── Restart Watcher ──────────────────────────────────────────────────────
echo "${C_DIM}Restarting watcher (threshold=${THRESHOLD}%, interval=${INTERVAL}s)...${C_RESET}"

# Use respawn-window to replace W1 contents
"$TMUX_BIN" respawn-window -k -t "${SESSION}:1" \
    "cd '$PROJECT_DIR' && '$WATCHER_SCRIPT' --threshold $THRESHOLD --interval $INTERVAL; echo 'Watcher stopped.'; read" \
    2>/dev/null || {
    # Fallback: send-keys if respawn-window fails (window may be dead)
    echo "${C_YELLOW}respawn-window failed, trying send-keys...${C_RESET}" >&2
    "$TMUX_BIN" send-keys -t "${SESSION}:1" C-c 2>/dev/null || true
    sleep 1
    "$TMUX_BIN" send-keys -t "${SESSION}:1" -l "'$WATCHER_SCRIPT' --threshold $THRESHOLD --interval $INTERVAL" 2>/dev/null
    "$TMUX_BIN" send-keys -t "${SESSION}:1" C-m 2>/dev/null
}

# ─── Verify ────────────────────────────────────────────────────────────────
echo "${C_DIM}Verifying watcher started (waiting 5s)...${C_RESET}"
sleep 5

if [[ -f "$PID_FILE" ]]; then
    local_new_pid=$(cat "$PID_FILE" 2>/dev/null || echo "")
    if [[ -n "$local_new_pid" ]] && kill -0 "$local_new_pid" 2>/dev/null; then
        echo "${C_GREEN}Watcher restarted (PID $local_new_pid, threshold=${THRESHOLD}%)${C_RESET}"
        exit 0
    fi
fi

echo "${C_YELLOW}WARNING: Watcher PID file not found after restart${C_RESET}"
echo "  Check W1 manually: tmux select-window -t ${SESSION}:1"
exit 1
