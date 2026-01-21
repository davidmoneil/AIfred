#!/bin/bash
# Launch Jarvis (Claude) in a tmux session for autonomous control
# This enables auto-command execution via tmux send-keys
#
# Layout:
# ┌─────────────────────────────────────────┐
# │                                         │
# │            Claude Code (main)           │
# │                                         │
# │                                         │
# ├─────────────────────────────────────────┤
# │    Unified Jarvis Watcher (12 lines)    │
# └─────────────────────────────────────────┘
#
# The watcher handles:
#   - Context monitoring (polls status line for token count)
#   - Command signal execution (watches for signal files)
#   - JICM workflow coordination (/context → /clear sequence)

TMUX_BIN="${TMUX_BIN:-$HOME/bin/tmux}"
SESSION_NAME="${TMUX_SESSION:-jarvis}"
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$HOME/Claude/Jarvis}"
WATCHER_SCRIPT="$PROJECT_DIR/.claude/scripts/jarvis-watcher.sh"
WATCHER_PANE_HEIGHT=12  # lines for watcher pane

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

# Split window and start watcher in bottom pane (if enabled)
if [[ "$WATCHER_ENABLED" = true ]]; then
    echo "Starting unified Jarvis watcher..."

    # Split horizontally, create bottom pane for watcher
    # Pass environment variables and threshold setting
    "$TMUX_BIN" split-window -t "$SESSION_NAME" -v -l $WATCHER_PANE_HEIGHT -c "$PROJECT_DIR" \
        "export TMUX_BIN='$TMUX_BIN'; export TMUX_SESSION='$SESSION_NAME'; export CLAUDE_PROJECT_DIR='$PROJECT_DIR'; $WATCHER_SCRIPT --threshold 80 --interval 30"

    # Select the main pane (Claude) so it's focused when we attach
    "$TMUX_BIN" select-pane -t "$SESSION_NAME":0.0
fi

# Set tmux options for better experience
"$TMUX_BIN" set-option -t "$SESSION_NAME" mouse on 2>/dev/null || true
"$TMUX_BIN" set-option -t "$SESSION_NAME" history-limit 50000 2>/dev/null || true

echo ""
echo -e "${GREEN}Jarvis is ready!${NC}"
echo ""
echo "Keyboard shortcuts:"
echo "  Ctrl+b then d     - Detach (leave running)"
echo "  Ctrl+b then ↑/↓   - Switch between panes"
echo "  Ctrl+b then z     - Zoom current pane"
echo "  Ctrl+b then x     - Close current pane"
echo ""
echo "Attaching to session..."

# Attach to the session
exec "$TMUX_BIN" attach-session -t "$SESSION_NAME"
