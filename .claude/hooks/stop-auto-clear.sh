#!/bin/bash
# Stop Hook for Auto-Clear After Checkpoint
# When Claude tries to stop after a checkpoint was created, instruct it to trigger /clear

set -euo pipefail

# Read hook input
HOOK_INPUT=$(cat)
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Check if checkpoint exists and is recent (within last 60 seconds)
CHECKPOINT_FILE="$CLAUDE_PROJECT_DIR/.claude/context/.soft-restart-checkpoint.md"
SIGNAL_FILE="$CLAUDE_PROJECT_DIR/.claude/context/.auto-clear-signal"
PENDING_FILE="$CLAUDE_PROJECT_DIR/.claude/context/.clear-pending"

# Log
LOG_DIR="$CLAUDE_PROJECT_DIR/.claude/logs"
mkdir -p "$LOG_DIR"

if [[ ! -f "$CHECKPOINT_FILE" ]]; then
    # No checkpoint - allow normal stop
    exit 0
fi

# Check if /trigger-clear was already run (prevents loop)
if [[ -f "$PENDING_FILE" ]]; then
    echo "$TIMESTAMP | Stop | Clear already pending, allowing stop" >> "$LOG_DIR/session-start-diagnostic.log"
    exit 0
fi

# Check if signal file exists (watcher will handle)
if [[ -f "$SIGNAL_FILE" ]]; then
    echo "$TIMESTAMP | Stop | Signal file exists, allowing stop" >> "$LOG_DIR/session-start-diagnostic.log"
    exit 0
fi

# Check if checkpoint file was modified in the last 60 seconds
CHECKPOINT_AGE=$(($(date +%s) - $(stat -f %m "$CHECKPOINT_FILE" 2>/dev/null || stat -c %Y "$CHECKPOINT_FILE" 2>/dev/null)))

if [[ $CHECKPOINT_AGE -gt 60 ]]; then
    # Checkpoint is old - allow normal stop
    exit 0
fi

# Recent checkpoint exists but no signal file - this means:
# 1. Manual /context-checkpoint was run (not PreCompact)
# 2. We should prompt Claude to trigger clear

echo "$TIMESTAMP | Stop | Recent checkpoint detected, blocking stop to trigger clear" >> "$LOG_DIR/session-start-diagnostic.log"

# Block stop and instruct Claude to trigger clear
jq -n '{
  "decision": "block",
  "reason": "A context checkpoint was just created. To apply MCP changes and reduce context, run /trigger-clear now. This will signal the auto-clear watcher to send /clear.",
  "systemMessage": "🔄 Checkpoint detected - triggering auto-clear sequence"
}'

exit 0
