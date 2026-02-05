#!/bin/bash
# Launch Jarvis Watcher
# Called by SessionStart hook to ensure watcher is always running
#
# Features:
# - Checks if watcher is already running (avoids duplicates)
# - Uses atomic mutex lock to prevent race conditions
# - Prefers tmux window (terminal-agnostic, works in iTerm2/Terminal/any)
# - Falls back to background process if not in tmux
# - Self-terminates when main session ends
#
# Updated: 2026-01-31 — Added mutex lock for race condition prevention

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$HOME/Claude/Jarvis}"
TMUX_BIN="${TMUX_BIN:-$HOME/bin/tmux}"
TMUX_SESSION="${TMUX_SESSION:-jarvis}"

WATCHER_SCRIPT="$PROJECT_DIR/.claude/scripts/jarvis-watcher.sh"
PID_FILE="$PROJECT_DIR/.claude/context/.watcher-pid"
LOCK_DIR="$PROJECT_DIR/.claude/context/.watcher-launch.lock"
LOG_FILE="$PROJECT_DIR/.claude/logs/watcher-launcher.log"

# Watcher configuration (JICM v5: 50% threshold)
WATCHER_THRESHOLD="${JARVIS_WATCHER_THRESHOLD:-80}"
WATCHER_INTERVAL="${JARVIS_WATCHER_INTERVAL:-5}"

mkdir -p "$(dirname "$LOG_FILE")"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

log() {
    echo "$TIMESTAMP | $1" >> "$LOG_FILE"
}

# Cleanup function for lock
cleanup_lock() {
    rmdir "$LOCK_DIR" 2>/dev/null
}

# ============================================================================
# ATOMIC MUTEX LOCK — Prevent race conditions during launch
# ============================================================================
# mkdir is atomic on POSIX systems - if it succeeds, we have the lock
# Lock expires after 30s to handle crashed launchers

# Check for stale lock (older than 30 seconds)
if [[ -d "$LOCK_DIR" ]]; then
    lock_age=$(( $(date +%s) - $(stat -f %m "$LOCK_DIR" 2>/dev/null || echo "0") ))
    if [[ $lock_age -gt 30 ]]; then
        log "Removing stale lock (${lock_age}s old)"
        rmdir "$LOCK_DIR" 2>/dev/null
    fi
fi

# Try to acquire lock
if ! mkdir "$LOCK_DIR" 2>/dev/null; then
    log "Another launcher is running (lock exists)"
    exit 0
fi

# Ensure lock is cleaned up on exit
trap cleanup_lock EXIT

# ============================================================================
# CHECK IF WATCHER IS ALREADY RUNNING
# ============================================================================

# Check by PID file
if [[ -f "$PID_FILE" ]]; then
    OLD_PID=$(cat "$PID_FILE")
    if ps -p "$OLD_PID" > /dev/null 2>&1; then
        log "Watcher already running (PID: $OLD_PID)"
        exit 0
    else
        log "Stale PID file found, removing"
        rm -f "$PID_FILE"
    fi
fi

# Also check by process name (backup check)
EXISTING_PID=$(pgrep -f "jarvis-watcher.sh" | head -1)
if [[ -n "$EXISTING_PID" ]]; then
    log "Watcher already running (found PID: $EXISTING_PID)"
    echo "$EXISTING_PID" > "$PID_FILE"
    exit 0
fi

# ============================================================================
# PREFERRED: Launch in tmux window (terminal-agnostic)
# ============================================================================
# If tmux is available and we have a session, create a new window for watcher
# This works regardless of which terminal app (iTerm2, Terminal, etc.)

if [[ -x "$TMUX_BIN" ]] && "$TMUX_BIN" has-session -t "$TMUX_SESSION" 2>/dev/null; then
    log "Launching watcher in tmux window (session: $TMUX_SESSION)"

    # Check if watcher window already exists
    if "$TMUX_BIN" list-windows -t "$TMUX_SESSION" -F "#{window_name}" 2>/dev/null | grep -q "^watcher$"; then
        log "Watcher window already exists in tmux"
        exit 0
    fi

    # Create new window for watcher (don't switch to it)
    "$TMUX_BIN" new-window -t "$TMUX_SESSION" -n "watcher" -d \
        "cd '$PROJECT_DIR' && '$WATCHER_SCRIPT' --threshold $WATCHER_THRESHOLD --interval $WATCHER_INTERVAL; echo 'Watcher stopped. Press Enter to close.'; read"

    sleep 1

    # Find and record the PID
    WATCHER_PID=$(pgrep -f "jarvis-watcher.sh" | head -1)
    if [[ -n "$WATCHER_PID" ]]; then
        echo "$WATCHER_PID" > "$PID_FILE"
        log "Watcher launched in tmux (PID: $WATCHER_PID)"
    else
        log "Watcher window created but PID not found"
    fi

    exit 0
fi

# ============================================================================
# FALLBACK: Background process (no tmux available)
# ============================================================================
log "No tmux session found, running watcher in background"

nohup "$WATCHER_SCRIPT" --threshold "$WATCHER_THRESHOLD" --interval "$WATCHER_INTERVAL" \
    > "$PROJECT_DIR/.claude/logs/watcher-output.log" 2>&1 &
WATCHER_PID=$!

echo "$WATCHER_PID" > "$PID_FILE"
log "Watcher launched in background (PID: $WATCHER_PID)"

exit 0
