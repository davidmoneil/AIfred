#!/bin/bash
# Session Start Hook - JSON Output Format (Required by Claude Code)
# Fires on: startup, resume, clear, compact
# Output: JSON with systemMessage field

# Read input from stdin (JSON)
INPUT=$(cat)

# Parse source from input
SOURCE=$(echo "$INPUT" | jq -r '.source // "unknown"')
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"')
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Log to diagnostic file
LOG_DIR="$CLAUDE_PROJECT_DIR/.claude/logs"
mkdir -p "$LOG_DIR"
echo "$TIMESTAMP | SessionStart | source=$SOURCE | session=$SESSION_ID" >> "$LOG_DIR/session-start-diagnostic.log"

# Check for checkpoint file
CHECKPOINT_FILE="$CLAUDE_PROJECT_DIR/.claude/context/.soft-restart-checkpoint.md"

if [ -f "$CHECKPOINT_FILE" ]; then
    # Checkpoint exists - load and display
    CHECKPOINT_CONTENT=$(cat "$CHECKPOINT_FILE" | jq -Rs .)

    # Build JSON message
    MESSAGE="SOFT RESTART ($SOURCE) - CHECKPOINT LOADED\n\nCheckpoint Context:\n"
    MESSAGE="$MESSAGE$(cat "$CHECKPOINT_FILE")\n\n"
    MESSAGE="${MESSAGE}Say 'continue' or describe what to do next."

    # Clear checkpoint after loading (one-time use)
    rm "$CHECKPOINT_FILE"

    # Output JSON with systemMessage
    echo "{\"systemMessage\": $(echo "$MESSAGE" | jq -Rs .)}"

elif [ "$SOURCE" = "clear" ]; then
    # No checkpoint, source is clear
    MESSAGE="CONVERSATION CLEARED\n\n"
    MESSAGE="${MESSAGE}No checkpoint found - starting fresh.\n"
    MESSAGE="${MESSAGE}Use /soft-restart before /clear to preserve context."

    echo "{\"systemMessage\": $(echo "$MESSAGE" | jq -Rs .)}"

else
    # Normal startup - minimal output or none
    # Output empty JSON (no message needed for normal startup)
    echo "{}"
fi

# Exit success
exit 0
