#!/bin/bash
# Status Line Context Capture for Jarvis
#
# This script serves two purposes:
# 1. Displays a status line (required by Claude Code)
# 2. Captures context data to a file for autonomous reading
#
# The key insight: Claude Code passes context_window data via stdin JSON
# to status line scripts. We capture this data to a file that Jarvis can
# read programmatically, solving the "can't see /context output" problem.
#
# Usage: Configure in .claude/settings.json:
#   "statusLine": {
#     "type": "command",
#     "command": "~/.claude/scripts/statusline-context-capture.sh"
#   }

set -euo pipefail

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$HOME/Claude/Jarvis}"
CONTEXT_FILE="$PROJECT_DIR/.claude/context/.statusline-context.json"
DISPLAY_FILE="$PROJECT_DIR/.claude/context/.context-display.txt"

# Ensure directories exist
mkdir -p "$(dirname "$CONTEXT_FILE")"

# Read JSON input from stdin (Claude Code provides this)
INPUT=$(cat)

# Save raw context data to file (for programmatic access)
echo "$INPUT" > "$CONTEXT_FILE"

# Extract key values using jq
MODEL=$(echo "$INPUT" | jq -r '.model.display_name // "Unknown"')
USED_PCT=$(echo "$INPUT" | jq -r '.context_window.used_percentage // 0')
REMAINING_PCT=$(echo "$INPUT" | jq -r '.context_window.remaining_percentage // 100')
INPUT_TOKENS=$(echo "$INPUT" | jq -r '.context_window.total_input_tokens // 0')
OUTPUT_TOKENS=$(echo "$INPUT" | jq -r '.context_window.total_output_tokens // 0')
CONTEXT_SIZE=$(echo "$INPUT" | jq -r '.context_window.context_window_size // 200000')
COST=$(echo "$INPUT" | jq -r '.cost.total_cost_usd // 0')
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"')
TRANSCRIPT_PATH=$(echo "$INPUT" | jq -r '.transcript_path // ""')

# Calculate total tokens
TOTAL_TOKENS=$((INPUT_TOKENS + OUTPUT_TOKENS))

# Format cost
COST_FMT=$(printf "%.2f" "$COST")

# Create human-readable display file (for Jarvis to read and summarize)
{
    echo "# Context Status (captured $(date -u +%Y-%m-%dT%H:%M:%SZ))"
    echo ""
    echo "## Summary"
    echo "- **Model**: $MODEL"
    echo "- **Context Used**: ${USED_PCT}% (${TOTAL_TOKENS} tokens)"
    echo "- **Context Remaining**: ${REMAINING_PCT}%"
    echo "- **Session Cost**: \$${COST_FMT}"
    echo ""
    echo "## Details"
    echo "- Input Tokens: $INPUT_TOKENS"
    echo "- Output Tokens: $OUTPUT_TOKENS"
    echo "- Context Window Size: $CONTEXT_SIZE"
    echo "- Session ID: $SESSION_ID"
    if [[ -n "$TRANSCRIPT_PATH" ]]; then
        echo "- Transcript: $TRANSCRIPT_PATH"
    fi
} > "$DISPLAY_FILE"

# Determine status color based on usage
if (( $(echo "$USED_PCT > 80" | bc -l) )); then
    # Red - critical
    COLOR="\033[0;31m"
    INDICATOR="🔴"
elif (( $(echo "$USED_PCT > 60" | bc -l) )); then
    # Yellow - warning
    COLOR="\033[1;33m"
    INDICATOR="🟡"
else
    # Green - healthy
    COLOR="\033[0;32m"
    INDICATOR="🟢"
fi
NC="\033[0m"

# Build visual progress bar (10 chars)
FILLED=$((USED_PCT / 10))
EMPTY=$((10 - FILLED))
BAR=""
for ((i=0; i<FILLED; i++)); do BAR+="▓"; done
for ((i=0; i<EMPTY; i++)); do BAR+="░"; done

# Output the status line (what Claude Code displays)
# Format: [Model] Context: XX% [▓▓▓░░░░░░░] | $X.XX
printf "${COLOR}${INDICATOR}${NC} [%s] %s%% [%s] | \$%s" "$MODEL" "$USED_PCT" "$BAR" "$COST_FMT"
