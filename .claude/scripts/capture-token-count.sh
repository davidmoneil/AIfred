#!/bin/bash
# Capture Token Count from Claude Code Status Line
# Part of JICM - Jarvis Intelligent Context Management
#
# Usage:
#   ./capture-token-count.sh              # Get current token count
#   ./capture-token-count.sh --json       # Output as JSON
#   ./capture-token-count.sh --update     # Update context-estimate.json
#
# Output:
#   Without flags: prints token count (e.g., "120916")
#   With --json: prints JSON object with all metrics
#   With --update: updates .claude/logs/context-estimate.json with actual count

set -euo pipefail

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$HOME/Claude/Jarvis}"
TMUX_BIN="${TMUX_BIN:-$HOME/bin/tmux}"
TMUX_SESSION="${TMUX_SESSION:-jarvis}"
ESTIMATE_FILE="$PROJECT_DIR/.claude/logs/context-estimate.json"
MAX_CONTEXT_TOKENS=200000

# Parse arguments
OUTPUT_MODE="plain"
while [[ $# -gt 0 ]]; do
    case $1 in
        --json) OUTPUT_MODE="json"; shift ;;
        --update) OUTPUT_MODE="update"; shift ;;
        -h|--help)
            echo "Usage: $0 [--json|--update]"
            echo "  --json    Output as JSON"
            echo "  --update  Update context-estimate.json"
            exit 0
            ;;
        *) shift ;;
    esac
done

# Check tmux session exists
if ! "$TMUX_BIN" has-session -t "$TMUX_SESSION" 2>/dev/null; then
    echo "ERROR: tmux session '$TMUX_SESSION' not found" >&2
    exit 1
fi

# Capture pane and extract token count from status line
# Status line format: "120916 tokens" or "120,916 tokens"
PANE_CONTENT=$("$TMUX_BIN" capture-pane -t "$TMUX_SESSION" -p 2>/dev/null || echo "")

# Try multiple patterns to find token count
TOKENS=0

# Pattern 1: "N tokens" at end of line (status bar format)
TOKEN_LINE=$(echo "$PANE_CONTENT" | grep -oE '[0-9,]+ tokens' | tail -1 || true)
if [[ -n "$TOKEN_LINE" ]]; then
    TOKENS=$(echo "$TOKEN_LINE" | tr -d ', tokens')
fi

# If still 0, try pattern 2: look for percentage format
if [[ "$TOKENS" == "0" ]] || [[ -z "$TOKENS" ]]; then
    # Pattern: "↓ 3.4k tokens"
    TOKEN_K_LINE=$(echo "$PANE_CONTENT" | grep -oE '↓ [0-9.]+k tokens' | tail -1 || true)
    if [[ -n "$TOKEN_K_LINE" ]]; then
        K_VALUE=$(echo "$TOKEN_K_LINE" | grep -oE '[0-9.]+' | head -1)
        TOKENS=$(echo "$K_VALUE * 1000" | bc | cut -d'.' -f1)
    fi
fi

# Calculate percentage
PERCENTAGE=0
if [[ "$TOKENS" -gt 0 ]]; then
    PERCENTAGE=$(echo "scale=2; ($TOKENS * 100) / $MAX_CONTEXT_TOKENS" | bc 2>/dev/null || echo "0")
fi

# Get timestamp
TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)

# Output based on mode
case "$OUTPUT_MODE" in
    plain)
        echo "$TOKENS"
        ;;
    json)
        cat <<EOF
{
  "timestamp": "$TIMESTAMP",
  "actualTokens": $TOKENS,
  "percentage": $PERCENTAGE,
  "maxContext": $MAX_CONTEXT_TOKENS,
  "source": "status_line"
}
EOF
        ;;
    update)
        # Load existing estimate file and merge
        if [[ -f "$ESTIMATE_FILE" ]]; then
            # Read existing values
            ESTIMATED_TOKENS=$(jq -r '.totalTokens // 0' "$ESTIMATE_FILE" 2>/dev/null || echo "0")
            TOOL_CALLS=$(jq -r '.toolCalls // 0' "$ESTIMATE_FILE" 2>/dev/null || echo "0")
            SESSION_START=$(jq -r '.sessionStart // ""' "$ESTIMATE_FILE" 2>/dev/null || echo "$TIMESTAMP")
        else
            ESTIMATED_TOKENS=0
            TOOL_CALLS=0
            SESSION_START="$TIMESTAMP"
        fi

        # Write updated file with both estimated and actual
        mkdir -p "$(dirname "$ESTIMATE_FILE")"
        cat > "$ESTIMATE_FILE" <<EOF
{
  "sessionStart": "$SESSION_START",
  "totalTokens": $ESTIMATED_TOKENS,
  "actualTokens": $TOKENS,
  "toolCalls": $TOOL_CALLS,
  "lastUpdate": "$TIMESTAMP",
  "percentage": $PERCENTAGE,
  "estimatedPercentage": $(echo "scale=2; ($ESTIMATED_TOKENS * 100) / $MAX_CONTEXT_TOKENS" | bc 2>/dev/null || echo "0"),
  "source": "combined"
}
EOF
        echo "Updated $ESTIMATE_FILE"
        echo "  Actual tokens: $TOKENS ($PERCENTAGE%)"
        echo "  Estimated tokens: $ESTIMATED_TOKENS"
        ;;
esac
