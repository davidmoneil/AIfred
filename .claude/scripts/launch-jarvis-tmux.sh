#!/bin/bash
# Launch Jarvis (Claude) in a tmux session for autonomous control
# This enables auto-command execution via tmux send-keys
#
# Layout:
# ┌─────────────────────────────────────────┐
# │                                         │
# │            Claude Code (full window)    │
# │                                         │
# │                                         │
# └─────────────────────────────────────────┘
#
# The watcher runs in a separate Terminal.app window and handles:
#   - Context monitoring (polls status line for token count)
#   - Command signal execution (watches for signal files)
#   - JICM workflow coordination (/context → /clear sequence)

TMUX_BIN="${TMUX_BIN:-$HOME/bin/tmux}"
SESSION_NAME="${TMUX_SESSION:-jarvis}"
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$HOME/Claude/Jarvis}"
WATCHER_SCRIPT="$PROJECT_DIR/.claude/scripts/jarvis-watcher.sh"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}"
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║              JARVIS TMUX LAUNCHER v2.1                        ║"
echo "║         (with Unified Watcher & JICM support)                 ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Check if tmux is available
if [[ ! -x "$TMUX_BIN" ]]; then
    echo -e "${RED}ERROR: tmux not found at $TMUX_BIN${NC}"
    echo ""
    echo "To install tmux:"
    echo "  macOS: brew install tmux"
    echo "  Linux: apt-get install tmux"
    exit 1
fi

# Check if watcher script exists
if [[ ! -x "$WATCHER_SCRIPT" ]]; then
    echo -e "${YELLOW}WARNING: Watcher script not found at $WATCHER_SCRIPT${NC}"
    echo "Commands will need to be executed manually."
    WATCHER_ENABLED=false
else
    WATCHER_ENABLED=true
fi

# Check if jq is available (needed by watcher)
if ! command -v jq &> /dev/null; then
    echo -e "${YELLOW}WARNING: jq not installed (needed for watcher)${NC}"
    echo "Install with: brew install jq (macOS) or apt-get install jq (Linux)"
    WATCHER_ENABLED=false
fi

# Check if session already exists
if "$TMUX_BIN" has-session -t "$SESSION_NAME" 2>/dev/null; then
    echo -e "${GREEN}Session '$SESSION_NAME' already exists.${NC}"
    echo "Attaching..."
    exec "$TMUX_BIN" attach-session -t "$SESSION_NAME"
fi

# Ensure project directory exists
if [[ ! -d "$PROJECT_DIR" ]]; then
    echo -e "${RED}ERROR: Project directory not found: $PROJECT_DIR${NC}"
    exit 1
fi

echo -e "  ${CYAN}Project:${NC} $PROJECT_DIR"
echo -e "  ${CYAN}Session:${NC} $SESSION_NAME"
echo -e "  ${CYAN}Watcher:${NC} $([ "$WATCHER_ENABLED" = true ] && echo "${GREEN}ENABLED${NC}" || echo "${YELLOW}DISABLED${NC}")"
echo ""
echo "Starting Jarvis..."

# Set TERM for best compatibility with Claude's ink UI
export TERM=xterm-256color

# Create new tmux session with Claude in the main pane
"$TMUX_BIN" new-session -d -s "$SESSION_NAME" -c "$PROJECT_DIR" \
    "claude --dangerously-skip-permissions --verbose --debug"

# Give Claude a moment to start
sleep 2

# Launch watcher in a separate Terminal.app window (if enabled)
if [[ "$WATCHER_ENABLED" = true ]]; then
    echo "Launching Jarvis watcher in separate terminal..."

    # Create a small wrapper script that the terminal will run
    WATCHER_CMD="export TMUX_BIN='$TMUX_BIN'; export TMUX_SESSION='$SESSION_NAME'; export CLAUDE_PROJECT_DIR='$PROJECT_DIR'; cd '$PROJECT_DIR'; '$WATCHER_SCRIPT' --threshold 80 --interval 30"

    # Launch watcher in a separate Terminal.app window
    osascript <<EOF
tell application "Terminal"
    do script "$WATCHER_CMD"
    set custom title of front window to "Jarvis Watcher"
end tell
EOF
fi

# Set tmux options for better experience
"$TMUX_BIN" set-option -t "$SESSION_NAME" mouse on 2>/dev/null || true
"$TMUX_BIN" set-option -t "$SESSION_NAME" history-limit 50000 2>/dev/null || true

echo ""
echo -e "${GREEN}Jarvis is ready!${NC}"
echo ""
echo "Keyboard shortcuts:"
echo "  Ctrl+b then d     - Detach (leave running)"
echo "  Ctrl+b then x     - Close session"
echo ""
echo "Watcher running in separate Terminal window."
echo ""
echo "Attaching to session..."

# Attach to the session
exec "$TMUX_BIN" attach-session -t "$SESSION_NAME"
