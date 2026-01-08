#!/bin/bash
# Session Start Hook - JSON Output Format (Required by Claude Code)
# Fires on: startup, resume, clear, compact
# Output: JSON with systemMessage and additionalContext for auto-resume
#
# Features:
# - Loads checkpoint files for context restoration
# - Suggests MCPs based on "Next Step" in session-state.md
# - Launches auto-clear watcher on startup
#
# Updated: 2026-01-09 (MCP Initialization Protocol)

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

# Clean up clear-pending marker from previous session
PENDING_FILE="$CLAUDE_PROJECT_DIR/.claude/context/.clear-pending"
if [[ -f "$PENDING_FILE" ]]; then
    rm -f "$PENDING_FILE"
    echo "$TIMESTAMP | SessionStart | Cleaned up .clear-pending marker" >> "$LOG_DIR/session-start-diagnostic.log"
fi

# Launch auto-clear watcher on startup (not on clear/compact to avoid duplicates)
if [[ "$SOURCE" == "startup" ]] || [[ "$SOURCE" == "resume" ]]; then
    # Launch watcher in background (don't block hook)
    "$CLAUDE_PROJECT_DIR/.claude/scripts/launch-watcher.sh" &
    echo "$TIMESTAMP | SessionStart | Launched watcher" >> "$LOG_DIR/session-start-diagnostic.log"
fi

# ============== MCP SUGGESTIONS ==============
# Only run on startup/resume (not clear/compact to avoid noise)
MCP_SUGGESTION=""
if [[ "$SOURCE" == "startup" ]] || [[ "$SOURCE" == "resume" ]]; then
    SUGGEST_SCRIPT="$CLAUDE_PROJECT_DIR/.claude/scripts/suggest-mcps.sh"
    if [[ -x "$SUGGEST_SCRIPT" ]]; then
        # Get JSON output from suggest script
        MCP_JSON=$("$SUGGEST_SCRIPT" --json 2>/dev/null || echo '{}')

        # Parse results
        TO_ENABLE=$(echo "$MCP_JSON" | jq -r '.to_enable // [] | join(", ")' 2>/dev/null)
        TO_DISABLE=$(echo "$MCP_JSON" | jq -r '.to_disable // [] | join(", ")' 2>/dev/null)
        TIER3_WARN=$(echo "$MCP_JSON" | jq -r '.tier3_warnings // [] | join(", ")' 2>/dev/null)

        # Build suggestion message if there are recommendations
        if [[ -n "$TO_ENABLE" ]] || [[ -n "$TO_DISABLE" ]]; then
            MCP_SUGGESTION="\n\n--- MCP SUGGESTIONS ---\n"

            if [[ -n "$TO_ENABLE" ]]; then
                MCP_SUGGESTION="${MCP_SUGGESTION}Enable for this session: $TO_ENABLE\n"
                MCP_SUGGESTION="${MCP_SUGGESTION}  Run: .claude/scripts/enable-mcps.sh $TO_ENABLE && /clear\n"
            fi

            if [[ -n "$TO_DISABLE" ]]; then
                MCP_SUGGESTION="${MCP_SUGGESTION}Consider disabling (not needed): $TO_DISABLE\n"
                MCP_SUGGESTION="${MCP_SUGGESTION}  Run: .claude/scripts/disable-mcps.sh $TO_DISABLE && /clear\n"
            fi

            if [[ -n "$TIER3_WARN" ]]; then
                MCP_SUGGESTION="${MCP_SUGGESTION}Note: $TIER3_WARN are Tier 3 (high token cost) - consider isolated invocation\n"
            fi

            MCP_SUGGESTION="${MCP_SUGGESTION}---"
        fi

        echo "$TIMESTAMP | SessionStart | MCP suggestions: enable=[$TO_ENABLE] disable=[$TO_DISABLE]" >> "$LOG_DIR/session-start-diagnostic.log"
    fi
fi

# ============== CHECKPOINT HANDLING ==============
CHECKPOINT_FILE="$CLAUDE_PROJECT_DIR/.claude/context/.soft-restart-checkpoint.md"

if [ -f "$CHECKPOINT_FILE" ]; then
    # Checkpoint exists - load and AUTO-RESUME
    CHECKPOINT_CONTENT=$(cat "$CHECKPOINT_FILE")

    # Build system message with checkpoint and MCP suggestions
    MESSAGE="CHECKPOINT LOADED ($SOURCE)\n\n$CHECKPOINT_CONTENT$MCP_SUGGESTION"

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
    MESSAGE="CONVERSATION CLEARED\n\nNo checkpoint found - starting fresh.\nUse /context-checkpoint before /clear to preserve context.$MCP_SUGGESTION"

    echo "{\"systemMessage\": $(echo "$MESSAGE" | jq -Rs .)}"

elif [[ "$SOURCE" == "startup" ]] || [[ "$SOURCE" == "resume" ]]; then
    # Normal startup with MCP suggestions
    if [[ -n "$MCP_SUGGESTION" ]]; then
        MESSAGE="Session started.$MCP_SUGGESTION"
        echo "{\"systemMessage\": $(echo "$MESSAGE" | jq -Rs .)}"
    else
        echo "{}"
    fi

else
    # Compact or other - minimal output
    echo "{}"
fi

# Exit success
exit 0
