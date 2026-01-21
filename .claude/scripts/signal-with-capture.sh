#!/bin/bash
# Signal with Capture - Send command AND capture output
# This script sends a command via tmux and captures the resulting output
# so it can be read back into Claude's context.
#
# Usage:
#   .claude/scripts/signal-with-capture.sh <command> [args]
#
# Output is written to: .claude/context/.command-output
# Claude can then read this file to see the command results.

set -euo pipefail

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$HOME/Claude/Jarvis}"
OUTPUT_FILE="$PROJECT_DIR/.claude/context/.command-output"
TMUX_BIN="${TMUX_BIN:-$HOME/bin/tmux}"
TMUX_SESSION="${TMUX_SESSION:-jarvis}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Ensure we have a command
if [[ $# -lt 1 ]]; then
    echo "Usage: $0 <command> [args]"
    echo "Example: $0 /usage"
    echo "         $0 /context"
    exit 1
fi

COMMAND="$1"
shift
ARGS="${*:-}"

# Ensure command starts with /
if [[ ! "$COMMAND" =~ ^/ ]]; then
    COMMAND="/$COMMAND"
fi

FULL_COMMAND="$COMMAND"
if [[ -n "$ARGS" ]]; then
    FULL_COMMAND="$COMMAND $ARGS"
fi

# Check tmux session exists
if ! "$TMUX_BIN" has-session -t "$TMUX_SESSION" 2>/dev/null; then
    echo -e "${RED}ERROR: tmux session '$TMUX_SESSION' not found${NC}"
    echo "Start Jarvis with: .claude/scripts/launch-jarvis-tmux.sh"
    exit 1
fi

# Capture pane state BEFORE command (to know where new output starts)
BEFORE_LINES=$("$TMUX_BIN" capture-pane -t "$TMUX_SESSION" -p | wc -l)

echo "Sending: $FULL_COMMAND"

# Send the command
"$TMUX_BIN" send-keys -t "$TMUX_SESSION" "$FULL_COMMAND" Enter

# Wait for output to appear (adaptive wait)
# Start with short wait, extend if output is still being generated
sleep 1

# Capture multiple times to catch streaming output
MAX_WAIT=5
WAIT_COUNT=0
LAST_LINES=0

while [[ $WAIT_COUNT -lt $MAX_WAIT ]]; do
    CURRENT_LINES=$("$TMUX_BIN" capture-pane -t "$TMUX_SESSION" -p | wc -l)

    if [[ $CURRENT_LINES -eq $LAST_LINES ]] && [[ $CURRENT_LINES -gt $BEFORE_LINES ]]; then
        # Output has stabilized
        break
    fi

    LAST_LINES=$CURRENT_LINES
    sleep 0.5
    ((WAIT_COUNT++))
done

# Capture the pane content (last 100 lines should be enough for most commands)
CAPTURED=$("$TMUX_BIN" capture-pane -t "$TMUX_SESSION" -p -S -100)

# Write output with metadata
{
    echo "# Command Output Capture"
    echo "# Command: $FULL_COMMAND"
    echo "# Captured: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo "# Lines captured: $(echo "$CAPTURED" | wc -l)"
    echo ""
    echo "## Raw Pane Content (last 100 lines)"
    echo '```'
    echo "$CAPTURED"
    echo '```'
    echo ""
    echo "## Extracted Metrics"
    echo ""

    # Try to extract common metrics
    # Token count (appears at bottom of Claude Code UI)
    TOKEN_LINE=$(echo "$CAPTURED" | grep -E '[0-9,]+ tokens' | tail -1 || true)
    if [[ -n "$TOKEN_LINE" ]]; then
        echo "**Tokens**: $TOKEN_LINE"
    fi

    # Version info
    VERSION_LINE=$(echo "$CAPTURED" | grep -E 'current: [0-9]+\.[0-9]+\.[0-9]+' | tail -1 || true)
    if [[ -n "$VERSION_LINE" ]]; then
        echo "**Version**: $VERSION_LINE"
    fi

    # Cost info (if /cost was run)
    COST_LINE=$(echo "$CAPTURED" | grep -E '\$[0-9]+\.[0-9]+' | head -1 || true)
    if [[ -n "$COST_LINE" ]]; then
        echo "**Cost**: $COST_LINE"
    fi

} > "$OUTPUT_FILE"

echo -e "${GREEN}Output captured to: $OUTPUT_FILE${NC}"
echo ""
echo "Claude can read this file with:"
echo "  Read .claude/context/.command-output"
