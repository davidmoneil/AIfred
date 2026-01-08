#!/bin/bash
# Launch Auto-Clear Watcher in a new terminal window
# Called by SessionStart hook to ensure watcher is always running
#
# Features:
# - Checks if watcher is already running (avoids duplicates)
# - Opens new Terminal window on macOS
# - Falls back to background process on Linux
# - Self-terminates when main session ends

WATCHER_SCRIPT="$CLAUDE_PROJECT_DIR/.claude/scripts/auto-clear-watcher.sh"
PID_FILE="$CLAUDE_PROJECT_DIR/.claude/context/.watcher-pid"
LOG_FILE="$CLAUDE_PROJECT_DIR/.claude/logs/watcher-launcher.log"

mkdir -p "$(dirname "$LOG_FILE")"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Check if watcher is already running
if [[ -f "$PID_FILE" ]]; then
    OLD_PID=$(cat "$PID_FILE")
    if ps -p "$OLD_PID" > /dev/null 2>&1; then
        echo "$TIMESTAMP | Watcher already running (PID: $OLD_PID)" >> "$LOG_FILE"
        exit 0
    else
        echo "$TIMESTAMP | Stale PID file found, removing" >> "$LOG_FILE"
        rm -f "$PID_FILE"
    fi
fi

# Launch based on OS
if [[ "$(uname)" == "Darwin" ]]; then
    # macOS: Open new Terminal window with watcher
    echo "$TIMESTAMP | Launching watcher in new Terminal window (macOS)" >> "$LOG_FILE"

    osascript <<EOF
tell application "Terminal"
    -- Create new window with watcher
    do script "cd '$CLAUDE_PROJECT_DIR' && echo '🔄 Auto-Clear Watcher' && echo 'Monitoring for checkpoint signals...' && echo '' && '$WATCHER_SCRIPT'; echo 'Watcher stopped. You can close this window.'"

    -- Optional: Make the window smaller and position it
    set bounds of front window to {50, 50, 500, 300}
    set custom title of front window to "Jarvis Watcher"
end tell
EOF

    # Give it a moment to start
    sleep 1

    # Find and record the PID (best effort)
    WATCHER_PID=$(pgrep -f "auto-clear-watcher.sh" | head -1)
    if [[ -n "$WATCHER_PID" ]]; then
        echo "$WATCHER_PID" > "$PID_FILE"
        echo "$TIMESTAMP | Watcher launched (PID: $WATCHER_PID)" >> "$LOG_FILE"
    else
        echo "$TIMESTAMP | Watcher launched but PID not found" >> "$LOG_FILE"
    fi

elif [[ "$(uname)" == "Linux" ]]; then
    # Linux: Try various terminal emulators
    echo "$TIMESTAMP | Launching watcher (Linux)" >> "$LOG_FILE"

    if command -v gnome-terminal &> /dev/null; then
        gnome-terminal --title="Jarvis Watcher" -- bash -c "cd '$CLAUDE_PROJECT_DIR' && '$WATCHER_SCRIPT'; read -p 'Watcher stopped. Press Enter to close.'"
    elif command -v xterm &> /dev/null; then
        xterm -title "Jarvis Watcher" -e "cd '$CLAUDE_PROJECT_DIR' && '$WATCHER_SCRIPT'; read -p 'Watcher stopped. Press Enter to close.'" &
    elif command -v konsole &> /dev/null; then
        konsole --new-tab -e bash -c "cd '$CLAUDE_PROJECT_DIR' && '$WATCHER_SCRIPT'; read -p 'Watcher stopped. Press Enter to close.'" &
    else
        # Fallback: background process (no separate terminal)
        echo "$TIMESTAMP | No GUI terminal found, running in background" >> "$LOG_FILE"
        nohup "$WATCHER_SCRIPT" > "$CLAUDE_PROJECT_DIR/.claude/logs/watcher-output.log" 2>&1 &
        echo $! > "$PID_FILE"
    fi

    sleep 1
    WATCHER_PID=$(pgrep -f "auto-clear-watcher.sh" | head -1)
    [[ -n "$WATCHER_PID" ]] && echo "$WATCHER_PID" > "$PID_FILE"

else
    echo "$TIMESTAMP | Unknown OS: $(uname)" >> "$LOG_FILE"
    exit 1
fi

echo "$TIMESTAMP | Launcher complete" >> "$LOG_FILE"
exit 0
