#!/bin/bash
# Launch Jarvis (Claude) in a tmux session for autonomous control
# This enables auto-clear via tmux send-keys

TMUX_BIN="$HOME/bin/tmux"
SESSION_NAME="jarvis"
PROJECT_DIR="$HOME/Claude/Jarvis"

# Check if tmux is available
if [[ ! -x "$TMUX_BIN" ]]; then
    echo "ERROR: tmux not found at $TMUX_BIN"
    exit 1
fi

# Check if session already exists
if "$TMUX_BIN" has-session -t "$SESSION_NAME" 2>/dev/null; then
    echo "Session '$SESSION_NAME' already exists."
    echo "Attaching..."
    exec "$TMUX_BIN" attach-session -t "$SESSION_NAME"
fi

# Create new tmux session with Claude
echo "Starting Jarvis in tmux session '$SESSION_NAME'..."

# Set TERM for best compatibility with Claude's ink UI
export TERM=xterm-256color

"$TMUX_BIN" new-session -d -s "$SESSION_NAME" -c "$PROJECT_DIR" \
    "claude --dangerously-skip-permissions --verbose --debug"

# Give Claude a moment to start
sleep 2

# Attach to the session
exec "$TMUX_BIN" attach-session -t "$SESSION_NAME"
