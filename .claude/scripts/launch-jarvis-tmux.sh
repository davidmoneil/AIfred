#!/bin/bash
# Launch Jarvis (Claude) in a tmux session for autonomous control
# This enables auto-command execution via tmux send-keys
#
# Layout:
# ┌─────────────────────────────────────────┐
# │                                         │
# │            Claude Code (window 0)       │
# │                                         │
# └─────────────────────────────────────────┘
# ┌─────────────────────────────────────────┐
# │            Watcher (window 1)           │
# └─────────────────────────────────────────┘
#
# The watcher runs in a tmux window (not separate terminal) and handles:
#   - Context monitoring (polls status line for token count)
#   - Command signal execution (watches for signal files)
#   - JICM workflow coordination (/intelligent-compress → /clear sequence)
#
# iTerm2 Integration:
#   Use --iterm2 flag to attach with tmux -CC for native iTerm2 tabs
#   This makes tmux windows appear as standard iTerm2 tabs/windows
#
# Updated: 2026-01-20 — Terminal-agnostic, iTerm2 integration support

TMUX_BIN="${TMUX_BIN:-$HOME/bin/tmux}"
SESSION_NAME="${TMUX_SESSION:-jarvis}"
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$HOME/Claude/Jarvis}"
WATCHER_SCRIPT="$PROJECT_DIR/.claude/scripts/jarvis-watcher.sh"

# Parse arguments
ITERM2_MODE=false
while [[ $# -gt 0 ]]; do
    case $1 in
        --iterm2|-i) ITERM2_MODE=true; shift ;;
        *) shift ;;
    esac
done

# Auto-detect iTerm2
if [[ "$TERM_PROGRAM" == "iTerm.app" ]] && [[ "$ITERM2_MODE" != "true" ]]; then
    echo "Detected iTerm2. Use --iterm2 flag for native tab integration."
fi

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
    if [[ "$ITERM2_MODE" == "true" ]]; then
        echo "Attaching with iTerm2 integration..."
        exec "$TMUX_BIN" -CC attach-session -t "$SESSION_NAME"
    else
        echo "Attaching..."
        exec "$TMUX_BIN" attach-session -t "$SESSION_NAME"
    fi
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

# Context management environment variables
# - CLAUDE_AUTOCOMPACT_PCT_OVERRIDE: Delay native auto-compact to 99% (JICM handles at 77%)
# - ENABLE_TOOL_SEARCH: Enable MCP tool search to reduce context usage
# - CLAUDE_CODE_MAX_OUTPUT_TOKENS: Set max output to 20K (affects effective context budget)
CLAUDE_ENV="CLAUDE_AUTOCOMPACT_PCT_OVERRIDE=99 ENABLE_TOOL_SEARCH=true CLAUDE_CODE_MAX_OUTPUT_TOKENS=20000"

# Create new tmux session with Claude in the main pane
# Environment variables are exported inline before the claude command
"$TMUX_BIN" new-session -d -s "$SESSION_NAME" -c "$PROJECT_DIR" \
    "export $CLAUDE_ENV && claude --dangerously-skip-permissions --verbose --debug" 

# Give Claude a moment to start
sleep 2

# Launch watcher in a tmux window (terminal-agnostic)
if [[ "$WATCHER_ENABLED" = true ]]; then
    echo "Launching Jarvis watcher in tmux window..."

    # Set environment for watcher
    export TMUX_BIN="$TMUX_BIN"
    export TMUX_SESSION="$SESSION_NAME"
    export CLAUDE_PROJECT_DIR="$PROJECT_DIR"

    # Create watcher window (window 1, detached so we stay on window 0)
    # Threshold 80% (from autonomy-config.yaml threshold_percentage)
    "$TMUX_BIN" new-window -t "$SESSION_NAME" -n "watcher" -d \
        "cd '$PROJECT_DIR' && '$WATCHER_SCRIPT' --threshold 80 --interval 30; echo 'Watcher stopped.'; read"
fi

# Set tmux options for better experience
"$TMUX_BIN" set-option -t "$SESSION_NAME" mouse on 2>/dev/null || true
"$TMUX_BIN" set-option -t "$SESSION_NAME" history-limit 50000 2>/dev/null || true

echo ""
echo -e "${GREEN}Jarvis is ready!${NC}"
echo ""
echo "Windows:"
echo "  Window 0: Claude Code"
echo "  Window 1: Watcher (context monitor + signal handler)"
echo ""

if [[ "$ITERM2_MODE" == "true" ]]; then
    echo "iTerm2 Integration Mode:"
    echo "  - tmux windows will appear as native iTerm2 tabs"
    echo "  - Switch windows: Cmd+[Number] or Cmd+Shift+[/]"
    echo "  - Dashboard: Shell > tmux > Dashboard"
    echo ""
    echo "Attaching with iTerm2 integration..."
    exec "$TMUX_BIN" -CC attach-session -t "$SESSION_NAME"
else
    echo "Keyboard shortcuts:"
    echo "  Ctrl+b then 0/1   - Switch to window 0 (Claude) or 1 (Watcher)"
    echo "  Ctrl+b then d     - Detach (leave running)"
    echo "  Ctrl+b then x     - Close current window"
    echo ""
    echo "Attaching to session..."
    exec "$TMUX_BIN" attach-session -t "$SESSION_NAME"
fi
