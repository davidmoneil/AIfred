#!/bin/bash
# ============================================================================
# Command Handler — Standalone Signal File Processor
# ============================================================================
#
# Polls .command-signal for JSON command requests and injects them into the
# Claude Code tmux pane via send-keys. Extracted from jarvis-watcher.sh (v5)
# to decouple command delivery from JICM context monitoring.
#
# Signal file format (JSON):
#   { "command": "/compact", "args": "", "source": "autonomous-commands" }
#
# Usage:
#   .claude/scripts/command-handler.sh [--interval SEC]
#
# ============================================================================

set -euo pipefail

# Trap ERR for debugging (bash 3.2 macOS compatibility)
trap 'echo "[ERR] Line $LINENO (exit $?)" >&2' ERR

# =============================================================================
# CONFIGURATION
# =============================================================================

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$HOME/Claude/Jarvis}"
TMUX_BIN="${TMUX_BIN:-$HOME/bin/tmux}"
TMUX_SESSION="${TMUX_SESSION:-jarvis}"
TMUX_TARGET="${TMUX_SESSION}:0"

# Paths
SIGNAL_FILE="$PROJECT_DIR/.claude/context/.command-signal"
LOG_FILE="$PROJECT_DIR/.claude/logs/command-handler.log"
PID_FILE="$PROJECT_DIR/.claude/context/.command-handler.pid"

# Timing
POLL_INTERVAL=${1:-3}
if [[ "${1:-}" == "--interval" ]]; then
    POLL_INTERVAL="${2:-3}"
fi

# Supported commands (whitelist)
SUPPORTED_COMMANDS=(
    "/compact" "/rename" "/resume" "/export" "/doctor"
    "/status" "/usage" "/cost" "/bashes" "/review"
    "/plan" "/security-review" "/stats" "/todos" "/context"
    "/hooks" "/release-notes" "/clear" "/statusline"
    "/intelligent-compress"
)

# =============================================================================
# SETUP
# =============================================================================

mkdir -p "$(dirname "$LOG_FILE")"
mkdir -p "$(dirname "$PID_FILE")"

# PID file for concurrent handler detection
check_existing_handler() {
    if [[ -f "$PID_FILE" ]]; then
        local old_pid
        old_pid=$(cat "$PID_FILE" 2>/dev/null || echo "0")
        if [[ -n "$old_pid" ]] && [[ "$old_pid" != "0" ]] && kill -0 "$old_pid" 2>/dev/null; then
            echo "ERROR: Another command handler is already running (PID $old_pid)"
            echo "Kill it with: kill $old_pid"
            exit 1
        fi
        rm -f "$PID_FILE"
    fi
    echo $$ > "$PID_FILE"
}

check_existing_handler

# =============================================================================
# LOGGING
# =============================================================================

log() {
    local level="$1"
    local msg="$2"
    local timestamp
    timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    echo "$timestamp | $level | $msg" >> "$LOG_FILE"
}

# Log rotation (keep last 50KB)
rotate_log() {
    if [[ -f "$LOG_FILE" ]]; then
        local size
        size=$(wc -c < "$LOG_FILE" 2>/dev/null | tr -d ' ' || echo "0")
        if [[ "$size" -gt 51200 ]]; then
            local rotated="${LOG_FILE}.1"
            mv "$LOG_FILE" "$rotated" 2>/dev/null || true
            log INFO "Log rotated ($size bytes)"
        fi
    fi
}

rotate_log

# =============================================================================
# TMUX INTERACTION
# =============================================================================

tmux_has_session() {
    "$TMUX_BIN" has-session -t "$TMUX_SESSION" 2>/dev/null
    return $?
}

is_claude_busy() {
    # Returns via echo: "busy" or "idle" (not return codes — bash 3.2 set -e safety)
    local pane_content
    pane_content=$("$TMUX_BIN" capture-pane -t "$TMUX_TARGET" -p 2>/dev/null || echo "")

    # Check last 5 lines for spinner/processing indicators
    local busy_match
    busy_match=$(echo "$pane_content" | tail -5 | grep -cE '[⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏◐◓◑◒▁▂▃▄▅▆▇]|Thinking|Processing|⣾⣽⣻⢿⡿⣟⣯⣷' || true)

    if [[ "$busy_match" -gt 0 ]]; then
        echo "busy"
        return 0
    fi
    echo "idle"
    return 0
}

wait_for_idle_brief() {
    local max_wait=${1:-30}
    local poll_interval=2
    local waited=0

    while [[ $waited -lt $max_wait ]]; do
        local status
        status=$(is_claude_busy)
        if [[ "$status" == "idle" ]]; then
            return 0
        fi
        log CMD "Waiting for Claude to finish generating... (${waited}s/${max_wait}s)"
        sleep "$poll_interval"
        waited=$((waited + poll_interval))
    done

    log WARN "wait_for_idle_brief: Claude still busy after ${max_wait}s, proceeding anyway"
    return 0
}

# =============================================================================
# COMMAND EXECUTION
# =============================================================================

is_valid_command() {
    local cmd="$1"
    for valid in "${SUPPORTED_COMMANDS[@]}"; do
        if [[ "$cmd" == "$valid" ]]; then
            return 0
        fi
    done
    return 1
}

send_command() {
    local command="$1"
    local args="${2:-}"

    if ! "$TMUX_BIN" has-session -t "$TMUX_SESSION" 2>/dev/null; then
        log ERROR "tmux session '$TMUX_SESSION' not found"
        return 0
    fi

    local full_command="$command"
    if [[ -n "$args" ]]; then
        full_command="$command $args"
    fi

    wait_for_idle_brief 30

    log CMD "Sending: $full_command"
    # Canonical pattern: text via -l, then C-m as SEPARATE call
    "$TMUX_BIN" send-keys -t "$TMUX_TARGET" -l "$full_command"
    sleep 0.1
    "$TMUX_BIN" send-keys -t "$TMUX_TARGET" C-m
    return 0
}

send_text() {
    local text="$1"
    if ! "$TMUX_BIN" has-session -t "$TMUX_SESSION" 2>/dev/null; then
        log ERROR "tmux session '$TMUX_SESSION' not found"
        return 0
    fi

    wait_for_idle_brief 30

    log CMD "Sending text (${#text} chars)"
    "$TMUX_BIN" send-keys -t "$TMUX_TARGET" -l "$text"
    sleep 0.1
    "$TMUX_BIN" send-keys -t "$TMUX_TARGET" C-m
    return 0
}

# =============================================================================
# SIGNAL FILE PROCESSING
# =============================================================================

process_signal_file() {
    if [[ ! -f "$SIGNAL_FILE" ]]; then
        return 1
    fi

    local signal_content
    signal_content=$(cat "$SIGNAL_FILE")

    local command args source
    command=$(echo "$signal_content" | jq -r '.command // empty' 2>/dev/null || echo "")
    args=$(echo "$signal_content" | jq -r '.args // empty' 2>/dev/null || echo "")
    source=$(echo "$signal_content" | jq -r '.source // "unknown"' 2>/dev/null || echo "unknown")

    if [[ -z "$command" ]]; then
        log WARN "Invalid signal file (no command)"
        rm -f "$SIGNAL_FILE"
        return 1
    fi

    if ! is_valid_command "$command"; then
        log WARN "Command not in whitelist: $command"
        rm -f "$SIGNAL_FILE"
        return 1
    fi

    log INFO "Processing signal: $command from $source"
    rm -f "$SIGNAL_FILE"
    send_command "$command" "$args"
    return 0
}

# =============================================================================
# CLEANUP
# =============================================================================

cleanup() {
    rm -f "$PID_FILE"
    log INFO "Command handler stopped (PID $$)"
}

trap cleanup INT TERM HUP EXIT

# =============================================================================
# MAIN LOOP
# =============================================================================

main() {
    log INFO "Command handler started (PID $$, interval ${POLL_INTERVAL}s)"
    echo "Command handler started (PID $$)"
    echo "  Signal file: $SIGNAL_FILE"
    echo "  Poll interval: ${POLL_INTERVAL}s"
    echo "  Supported commands: ${#SUPPORTED_COMMANDS[@]}"
    echo ""

    local poll_count=0

    while true; do
        # Verify tmux session still exists
        if ! tmux_has_session; then
            log ERROR "tmux session lost — exiting"
            exit 1
        fi

        # Check for command signal
        if process_signal_file; then
            sleep 1  # Brief pause after command delivery
        fi

        # Periodic log rotation (every 500 polls)
        poll_count=$((poll_count + 1))
        if [[ $((poll_count % 500)) -eq 0 ]]; then
            rotate_log
        fi

        sleep "$POLL_INTERVAL"
    done
}

main
