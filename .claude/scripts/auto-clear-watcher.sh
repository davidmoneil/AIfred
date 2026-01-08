#!/bin/bash
# Auto-Clear Watcher for Jarvis
# Monitors for clear signal and sends /clear keystroke to terminal
#
# USAGE:
#   1. Start this in a separate terminal: .claude/scripts/auto-clear-watcher.sh
#   2. Use Jarvis normally
#   3. When PreCompact creates checkpoint, this script will auto-type /clear
#
# REQUIRES: osascript (macOS) or xdotool (Linux)

SIGNAL_FILE="$HOME/Claude/Jarvis/.claude/context/.auto-clear-signal"
CHECK_INTERVAL=2  # seconds

echo "🔄 Auto-Clear Watcher Started"
echo "   Monitoring for: $SIGNAL_FILE"
echo "   Press Ctrl+C to stop"
echo ""

cleanup() {
    rm -f "$SIGNAL_FILE" 2>/dev/null
    echo "👋 Watcher stopped"
    exit 0
}
trap cleanup INT TERM

while true; do
    if [[ -f "$SIGNAL_FILE" ]]; then
        echo "📍 Signal detected! Waiting 2s for Claude to finish..."
        sleep 2

        # Remove signal file first
        rm -f "$SIGNAL_FILE"

        # Detect OS and send keystroke
        if [[ "$(uname)" == "Darwin" ]]; then
            # macOS: Use AppleScript to send keystrokes to Terminal
            echo "⌨️  Sending /clear to Terminal..."
            osascript <<'APPLESCRIPT'
tell application "Terminal"
    activate
    delay 0.5
    tell application "System Events"
        keystroke "/clear"
        keystroke return
    end tell
end tell
APPLESCRIPT
            echo "✅ /clear sent!"
        elif command -v xdotool &> /dev/null; then
            # Linux with xdotool
            echo "⌨️  Sending /clear via xdotool..."
            xdotool type "/clear"
            xdotool key Return
            echo "✅ /clear sent!"
        else
            echo "❌ No automation tool available (need osascript or xdotool)"
            echo "   Please type /clear manually"
        fi
    fi

    sleep $CHECK_INTERVAL
done
