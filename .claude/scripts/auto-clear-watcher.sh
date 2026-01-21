#!/bin/bash
# Auto-Clear Watcher for Jarvis
# Monitors for clear signal and sends /clear keystroke to terminal
#
# This script is automatically launched by SessionStart hook.
# It runs in a separate Terminal window and monitors for checkpoint signals.
#
# REQUIRES: osascript (macOS) or xdotool (Linux)

# Use CLAUDE_PROJECT_DIR if set, otherwise default
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$HOME/Claude/Jarvis}"
SIGNAL_FILE="$PROJECT_DIR/.claude/context/.auto-clear-signal"
WINDOW_FILE="$PROJECT_DIR/.claude/context/.terminal-window-id"
CHECK_INTERVAL=2  # seconds

echo "╔══════════════════════════════════════════════════════════╗"
echo "║           JARVIS AUTO-CLEAR WATCHER                      ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""
echo "  Project: $PROJECT_DIR"
echo "  Signal:  $SIGNAL_FILE"
echo "  Status:  ACTIVE"
echo ""
echo "  This window will auto-send /clear when context checkpoint"
echo "  is triggered. Leave this window open during your session."
echo ""
echo "  Press Ctrl+C to stop"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

cleanup() {
    rm -f "$SIGNAL_FILE" 2>/dev/null
    echo ""
    echo "👋 Watcher stopped"
    exit 0
}
trap cleanup INT TERM

# Record our own PID
echo $$ > "$PROJECT_DIR/.claude/context/.watcher-pid"

while true; do
    if [[ -f "$SIGNAL_FILE" ]]; then
        SIGNAL_TIME=$(cat "$SIGNAL_FILE")
        echo ""
        echo "$(date +%H:%M:%S) 📍 SIGNAL DETECTED"
        echo "           Checkpoint created at: $SIGNAL_TIME"
        echo "           Waiting 3s for Claude to complete..."
        sleep 3

        # Remove signal file
        rm -f "$SIGNAL_FILE"

        # Detect OS and send keystroke
        if [[ "$(uname)" == "Darwin" ]]; then
            echo "           ⌨️  Sending /clear to Terminal..."

            # Play a subtle sound to indicate action (optional)
            # afplay /System/Library/Sounds/Pop.aiff &

            # METHOD 1: tmux send-keys (fully autonomous - requires Claude running in tmux)
            TMUX_BIN="$HOME/bin/tmux"
            TMUX_SESSION="jarvis"

            if [[ -x "$TMUX_BIN" ]] && "$TMUX_BIN" has-session -t "$TMUX_SESSION" 2>/dev/null; then
                echo "           Using tmux send-keys (fully autonomous)..."
                "$TMUX_BIN" send-keys -t "$TMUX_SESSION" "/clear" Enter
                echo "           ✅ /clear sent via tmux!"
                echo ""
                echo "           Session will restart and auto-resume."
                echo ""
                echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                continue
            fi

            # METHOD 2: Fallback - type /clear and alert user (semi-autonomous)
            echo "           tmux session not found - using fallback method..."
            osascript <<'APPLESCRIPT'
tell application "Terminal"
    activate
    delay 0.3
    repeat with w in windows
        if name of w contains "claude" then
            set frontmost of w to true
            exit repeat
        end if
    end repeat
end tell
tell application "System Events"
    tell process "Terminal"
        keystroke "/clear"
    end tell
end tell
APPLESCRIPT

            # Play alert sound
            afplay /System/Library/Sounds/Glass.aiff &

            echo ""
            echo "           ╔══════════════════════════════════════════════════════╗"
            echo "           ║  ⚠️  /clear TYPED - PRESS ENTER TO EXECUTE  ⚠️       ║"
            echo "           ╚══════════════════════════════════════════════════════╝"
            echo ""
            echo "           For FULLY AUTONOMOUS clearing, restart Claude with:"
            echo "           .claude/scripts/launch-jarvis-tmux.sh"
            echo ""

            if [[ $? -eq 0 ]]; then
                echo "           ✅ /clear typed into Claude input (press Enter)"
                echo ""
                echo "           Session will restart and auto-resume."
                echo ""
            else
                echo "           ❌ Failed to send keystroke"
                echo "           Please type /clear manually in the Claude window"
            fi

        elif command -v xdotool &> /dev/null; then
            echo "           ⌨️  Sending /clear via xdotool..."

            # Focus the most recent terminal window (not this one)
            # This is a best-effort approach for Linux
            CURRENT_WINDOW=$(xdotool getactivewindow)
            xdotool search --name "Terminal" | while read WID; do
                if [[ "$WID" != "$CURRENT_WINDOW" ]]; then
                    xdotool windowactivate "$WID"
                    break
                fi
            done

            sleep 0.3
            xdotool type "/clear"
            xdotool key Return
            echo "           ✅ /clear sent!"
        else
            echo "           ❌ No automation tool available"
            echo "           Please type /clear manually"
        fi

        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    fi

    sleep $CHECK_INTERVAL
done
