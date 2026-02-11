#!/bin/bash
# Launch Jarvis (Claude) in a tmux session for autonomous control
# This enables auto-command execution via tmux send-keys
#
# Layout (Aion Quartet + Commands):
# ┌─────────────────────────────────────────┐
# │            Claude Code (window 0)       │
# └─────────────────────────────────────────┘
# ┌─────────────────────────────────────────┐
# │            Watcher (window 1)           │
# └─────────────────────────────────────────┘
# ┌─────────────────────────────────────────┐
# │            Ennoia (window 2)            │
# └─────────────────────────────────────────┘
# ┌─────────────────────────────────────────┐
# │            Virgil (window 3)            │
# └─────────────────────────────────────────┘
# ┌─────────────────────────────────────────┐
# │            Commands (window 4)          │
# └─────────────────────────────────────────┘
#
# Watcher (window 1): JICM v6 context monitoring + compression
# Commands (window 4): Signal file → command injection via send-keys
# Ennoia (window 2): Session orchestration, intent-driven wake-up
# Virgil (window 3): Task tracking, agent monitoring, file changes
#
# iTerm2 Integration:
#   Use --iterm2 flag to attach with tmux -CC for native iTerm2 tabs
#   This makes tmux windows appear as standard iTerm2 tabs/windows
#
# Updated: 2026-02-10 — Aion Quartet layout (Watcher W1, Ennoia W2, Virgil W3)

TMUX_BIN="${TMUX_BIN:-$HOME/bin/tmux}"
SESSION_NAME="${TMUX_SESSION:-jarvis}"
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$HOME/Claude/Jarvis}"
# JICM v6 watcher (v5 removed in v6.1)
WATCHER_SCRIPT="$PROJECT_DIR/.claude/scripts/jicm-watcher.sh"
WATCHER_VERSION="v6"
if [[ ! -x "$WATCHER_SCRIPT" ]]; then
    WATCHER_SCRIPT=""
    WATCHER_VERSION="none"
fi

# Parse arguments
ITERM2_MODE=false
FRESH_MODE=false
while [[ $# -gt 0 ]]; do
    case $1 in
        --iterm2|-i) ITERM2_MODE=true; shift ;;
        --fresh|-f) FRESH_MODE=true; shift ;;
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
if [[ -z "$WATCHER_SCRIPT" ]] || [[ ! -x "$WATCHER_SCRIPT" ]]; then
    echo -e "${YELLOW}WARNING: No watcher script found${NC}"
    echo "Commands will need to be executed manually."
    WATCHER_ENABLED=false
else
    WATCHER_ENABLED=true
    echo -e "  ${CYAN}Watcher:${NC} ${GREEN}$WATCHER_VERSION${NC} ($WATCHER_SCRIPT)"
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
# - ENABLE_TOOL_SEARCH: Enable MCP tool search to reduce context usage
# - CLAUDE_CODE_MAX_OUTPUT_TOKENS: Set max output to 20K (affects effective context budget)
# Note: CLAUDE_AUTOCOMPACT_PCT_OVERRIDE left at default (~95%, effective ~85%)
#       JICM triggers at 55% with 30% headroom before auto-compact
# Determine session type
if [[ "$FRESH_MODE" == "true" ]]; then
    JARVIS_SESSION_TYPE="fresh"
else
    JARVIS_SESSION_TYPE="continue"
fi

CLAUDE_ENV="ENABLE_TOOL_SEARCH=true CLAUDE_CODE_MAX_OUTPUT_TOKENS=20000 JARVIS_SESSION_TYPE=$JARVIS_SESSION_TYPE"

# Create new tmux session with Claude in the main pane
# Environment variables are exported inline before the claude command
CLAUDE_CMD="claude --dangerously-skip-permissions --verbose --debug --debug-file /Users/aircannon/Claude/Jarvis/.claude/logs/debug.log"
if [[ "$FRESH_MODE" != "true" ]]; then
    CLAUDE_CMD="$CLAUDE_CMD --continue"
fi

"$TMUX_BIN" new-session -d -s "$SESSION_NAME" -n "Jarvis" -c "$PROJECT_DIR" \
    "export $CLAUDE_ENV && $CLAUDE_CMD"

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
    # Threshold=55 (accounts for queuing delay before compression starts)
    "$TMUX_BIN" new-window -t "$SESSION_NAME" -n "Watcher" -d \
        "cd '$PROJECT_DIR' && '$WATCHER_SCRIPT' --threshold 55 --interval 5; echo 'Watcher stopped.'; read"
fi

# Launch Ennoia session orchestrator in a tmux window (window 2, detached)
ENNOIA_SCRIPT="$PROJECT_DIR/.claude/scripts/ennoia.sh"
if [[ -x "$ENNOIA_SCRIPT" ]]; then
    echo "Launching Ennoia orchestrator in tmux window..."
    "$TMUX_BIN" new-window -t "$SESSION_NAME" -n "Ennoia" -d \
        "cd '$PROJECT_DIR' && '$ENNOIA_SCRIPT'; echo 'Ennoia stopped.'; read"
fi

# Launch Virgil codebase guide in a tmux window (window 3, detached)
VIRGIL_SCRIPT="$PROJECT_DIR/.claude/scripts/virgil.sh"
if [[ -x "$VIRGIL_SCRIPT" ]]; then
    echo "Launching Virgil codebase guide in tmux window..."
    "$TMUX_BIN" new-window -t "$SESSION_NAME" -n "Virgil" -d \
        "cd '$PROJECT_DIR' && '$VIRGIL_SCRIPT'; echo 'Virgil stopped.'; read"
fi

# Launch command handler in a tmux window (window 4, detached)
CMD_HANDLER_SCRIPT="$PROJECT_DIR/.claude/scripts/command-handler.sh"
if [[ -x "$CMD_HANDLER_SCRIPT" ]]; then
    echo "Launching command handler in tmux window..."
    "$TMUX_BIN" new-window -t "$SESSION_NAME" -n "Commands" -d \
        "cd '$PROJECT_DIR' && '$CMD_HANDLER_SCRIPT' --interval 3; echo 'Command handler stopped.'; read"
fi

# Set tmux options for better experience
"$TMUX_BIN" set-option -t "$SESSION_NAME" mouse on 2>/dev/null || true
"$TMUX_BIN" set-option -t "$SESSION_NAME" history-limit 10000 2>/dev/null || true
# Prevent tmux from overriding window names with command names
"$TMUX_BIN" set-window-option -t "$SESSION_NAME:0" automatic-rename off 2>/dev/null || true
"$TMUX_BIN" set-window-option -t "$SESSION_NAME:1" automatic-rename off 2>/dev/null || true
"$TMUX_BIN" set-window-option -t "$SESSION_NAME:2" automatic-rename off 2>/dev/null || true
"$TMUX_BIN" set-window-option -t "$SESSION_NAME:3" automatic-rename off 2>/dev/null || true
"$TMUX_BIN" set-window-option -t "$SESSION_NAME:4" automatic-rename off 2>/dev/null || true

echo ""
echo -e "${GREEN}Jarvis is ready!${NC}"
echo ""
echo "Windows:"
echo "  Window 0: Jarvis"
echo "  Window 1: Watcher"
echo "  Window 2: Ennoia"
echo "  Window 3: Virgil"
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
    echo "  Ctrl+b then 0/1/2/3 - Switch to Jarvis (0), Watcher (1), Ennoia (2), Virgil (3)"
    echo "  Ctrl+b then d     - Detach (leave running)"
    echo "  Ctrl+b then x     - Close current window"
    echo ""
    echo "Attaching to session..."
    exec "$TMUX_BIN" attach-session -t "$SESSION_NAME"
fi
