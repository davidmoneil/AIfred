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

# Determine status color based on JICM thresholds
# Green: 0-49% (safe)
# Yellow: 50-79% (JICM active zone)
# Red: 80-94% (critical)
# Magenta: 95%+ (auto-compact imminent)
if (( $(echo "$USED_PCT >= 95" | bc -l) )); then
    COLOR="\033[0;35m"  # Magenta - auto-compact zone
    INDICATOR="⚡"
elif (( $(echo "$USED_PCT >= 80" | bc -l) )); then
    COLOR="\033[0;31m"  # Red - critical
    INDICATOR="🔴"
elif (( $(echo "$USED_PCT >= 50" | bc -l) )); then
    COLOR="\033[1;33m"  # Yellow - JICM active
    INDICATOR="🟡"
else
    COLOR="\033[0;32m"  # Green - healthy
    INDICATOR="🟢"
fi
NC="\033[0m"

# Build enhanced progress bar (20 chars) with threshold markers
# Design: [▓▓▓▓▓▓▓▓▓▓│░░░░░░░░│█░]
#                    ^         ^
#                   50%       95%
#                   JICM    auto-compact

JICM_THRESHOLD=50      # JICM trigger point
AUTO_THRESHOLD=95      # Claude Code auto-compact threshold
OUTPUT_RESERVE=4       # ~8K tokens on 200K context (4%)
BAR_WIDTH=20

# Calculate positions in the bar
JICM_POS=$((JICM_THRESHOLD * BAR_WIDTH / 100))      # Position 10
AUTO_POS=$((AUTO_THRESHOLD * BAR_WIDTH / 100))      # Position 19
RESERVE_START=$(((100 - OUTPUT_RESERVE) * BAR_WIDTH / 100))  # Position 19
FILLED=$((USED_PCT * BAR_WIDTH / 100))

BAR=""
for ((i=0; i<BAR_WIDTH; i++)); do
    # Check for threshold markers (take priority)
    if [[ $i -eq $JICM_POS ]] || [[ $i -eq $AUTO_POS ]]; then
        BAR+="│"
        continue
    fi

    # Determine fill character
    if [[ $i -lt $FILLED ]]; then
        if [[ $i -ge $RESERVE_START ]]; then
            BAR+="█"  # Output reserved (used - danger zone)
        else
            BAR+="▓"  # Regular used
        fi
    else
        if [[ $i -ge $RESERVE_START ]]; then
            BAR+="▪"  # Output reserved (available)
        else
            BAR+="░"  # Empty/available
        fi
    fi
done

# Output the status line (what Claude Code displays)
# Format: [Model] Context: XX% [▓▓▓░░░░░░░] | $X.XX
printf "${COLOR}${INDICATOR}${NC} [%s] %s%% [%s] | \$%s" "$MODEL" "$USED_PCT" "$BAR" "$COST_FMT"
