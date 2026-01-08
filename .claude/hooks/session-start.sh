#!/bin/bash
# Session Start Hook - JSON Output Format (Required by Claude Code)
# Fires on: startup, resume, clear, compact
# Output: JSON with systemMessage and additionalContext for auto-resume

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
    # Checkpoint exists - load and AUTO-RESUME
    CHECKPOINT_CONTENT=$(cat "$CHECKPOINT_FILE")

    # Build system message
    MESSAGE="CHECKPOINT LOADED ($SOURCE)\n\n$CHECKPOINT_CONTENT"

    # Build additionalContext to trigger auto-resume
    # This tells Claude to immediately continue work without waiting for user
    CONTEXT="AUTO-RESUME: A context checkpoint was just loaded. Continue working on the tasks listed in 'Next Steps After Restart' above. Do NOT wait for user input - proceed immediately with the work."

    # NOTE: Checkpoint file is NOT deleted after loading
    # - Allows multiple /clear cycles with same checkpoint
    # - Will be overwritten by next /context-checkpoint

    # Output JSON with systemMessage AND additionalContext
    jq -n \
      --arg msg "$MESSAGE" \
      --arg ctx "$CONTEXT" \
      '{
        "systemMessage": $msg,
        "hookSpecificOutput": {
          "hookEventName": "SessionStart",
          "additionalContext": $ctx
        }
      }'

elif [ "$SOURCE" = "clear" ]; then
    # No checkpoint, source is clear
    MESSAGE="CONVERSATION CLEARED\n\nNo checkpoint found - starting fresh.\nUse /context-checkpoint before /clear to preserve context."

    echo "{\"systemMessage\": $(echo "$MESSAGE" | jq -Rs .)}"

else
    # Normal startup - minimal output or none
    echo "{}"
fi

# Exit success
exit 0
