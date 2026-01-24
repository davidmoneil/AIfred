#!/bin/bash
# Stop the Jarvis Watcher
# Called when session ends or manually to clean up

PID_FILE="$CLAUDE_PROJECT_DIR/.claude/context/.watcher-pid"
SIGNAL_FILE="$CLAUDE_PROJECT_DIR/.claude/context/.auto-clear-signal"
LOG_FILE="$CLAUDE_PROJECT_DIR/.claude/logs/watcher-launcher.log"

TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Clean up signal file
rm -f "$SIGNAL_FILE"

# Stop watcher process if running
if [[ -f "$PID_FILE" ]]; then
    OLD_PID=$(cat "$PID_FILE")
    if ps -p "$OLD_PID" > /dev/null 2>&1; then
        echo "$TIMESTAMP | Stopping watcher (PID: $OLD_PID)" >> "$LOG_FILE"
        kill "$OLD_PID" 2>/dev/null
        sleep 1
        # Force kill if still running
        if ps -p "$OLD_PID" > /dev/null 2>&1; then
            kill -9 "$OLD_PID" 2>/dev/null
        fi
        echo "Watcher stopped (PID: $OLD_PID)"
    else
        echo "Watcher was not running"
    fi
    rm -f "$PID_FILE"
else
    # Try to find and kill by process name
    WATCHER_PID=$(pgrep -f "jarvis-watcher.sh" | head -1)
    if [[ -n "$WATCHER_PID" ]]; then
        echo "$TIMESTAMP | Stopping watcher by name (PID: $WATCHER_PID)" >> "$LOG_FILE"
        kill "$WATCHER_PID" 2>/dev/null
        echo "Watcher stopped (PID: $WATCHER_PID)"
    else
        echo "No watcher process found"
    fi
fi

echo "$TIMESTAMP | Watcher cleanup complete" >> "$LOG_FILE"
