#!/bin/bash
# Pre-Compact Hook - Auto-checkpoint before context compaction
# Fires when: context approaches limit and autocompaction is about to trigger
# Purpose: Create checkpoint and disable MCPs BEFORE context is lost

set -euo pipefail

# Read hook input from stdin
INPUT=$(cat)
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Log to diagnostic file
LOG_DIR="$CLAUDE_PROJECT_DIR/.claude/logs"
mkdir -p "$LOG_DIR"
echo "$TIMESTAMP | PreCompact | Auto-checkpoint triggered" >> "$LOG_DIR/session-start-diagnostic.log"

CHECKPOINT_FILE="$CLAUDE_PROJECT_DIR/.claude/context/.soft-restart-checkpoint.md"

# Create automatic checkpoint
cat > "$CHECKPOINT_FILE" << 'CHECKPOINT'
# Auto-Generated Context Checkpoint

**Created**: TIMESTAMP_PLACEHOLDER
**Reason**: PreCompact hook - context threshold exceeded

## Work Summary

This checkpoint was auto-generated when context approached the limit.
Check session-state.md and current-priorities.md for work context.

## Next Steps After Restart

1. Review session-state.md for current work status
2. Check current-priorities.md for next tasks
3. Continue from where you left off

## MCP State

MCPs will be disabled automatically if this checkpoint was created by PreCompact.
Run `.claude/scripts/list-mcp-status.sh` to see current state.

## Critical Context

- PreCompact auto-checkpoint triggered
- Context was approaching threshold
- Some conversation history may have been summarized

CHECKPOINT

# Replace timestamp placeholder
sed -i.bak "s/TIMESTAMP_PLACEHOLDER/$TIMESTAMP/" "$CHECKPOINT_FILE" && rm -f "${CHECKPOINT_FILE}.bak"

# Disable Tier 2 MCPs to reduce context on restart
# Only if the scripts exist
if [ -x "$CLAUDE_PROJECT_DIR/.claude/scripts/disable-mcps.sh" ]; then
    "$CLAUDE_PROJECT_DIR/.claude/scripts/disable-mcps.sh" github context7 sequential-thinking 2>/dev/null || true
    echo "$TIMESTAMP | PreCompact | Disabled Tier 2 MCPs" >> "$LOG_DIR/session-start-diagnostic.log"
fi

# NOTE: Signal file creation REMOVED per JICM investigation (Q10)
# PreCompact is BACKUP defense - checkpoint only, no /clear trigger
# JICM (context-accumulator.js) handles proactive /clear signals
echo "$TIMESTAMP | PreCompact | Checkpoint created (no signal - JICM decoupled)" >> "$LOG_DIR/session-start-diagnostic.log"

# Output message to user
MESSAGE="⚠️ CONTEXT THRESHOLD - BACKUP CHECKPOINT CREATED\n\n"
MESSAGE="${MESSAGE}Native auto-compact triggered. A backup checkpoint has been saved.\n\n"
MESSAGE="${MESSAGE}This means JICM's proactive threshold was missed.\n"
MESSAGE="${MESSAGE}After compaction, session-start will restore context.\n\n"
MESSAGE="${MESSAGE}Tier 2 MCPs have been disabled (github, context7, sequential-thinking)"

echo "{\"systemMessage\": $(echo "$MESSAGE" | jq -Rs .)}"

exit 0
