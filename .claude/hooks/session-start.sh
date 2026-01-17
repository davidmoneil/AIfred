#!/bin/bash
# Session Start Hook - Self-Launch Protocol (AC-01)
# Fires on: startup, resume, clear, compact
# Output: JSON with systemMessage and additionalContext
#
# Features (PR-12.1):
# - Phase A: Greeting & Orientation (time-aware greeting)
# - Phase B: System Review (context loading, baseline check)
# - Phase C: User Briefing (status, autonomous initiation)
# - Checkpoint loading for context restoration
# - MCP suggestions based on work type
# - Auto-clear watcher launch
#
# Updated: 2026-01-16 (PR-12.1 Self-Launch Protocol)

# Read input from stdin (JSON)
INPUT=$(cat)

# Parse source from input
SOURCE=$(echo "$INPUT" | jq -r '.source // "unknown"')
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"')
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
LOCAL_TIME=$(date +"%H:%M")
HOUR=$(date +"%H")

# Log to diagnostic file
LOG_DIR="$CLAUDE_PROJECT_DIR/.claude/logs"
STATE_DIR="$CLAUDE_PROJECT_DIR/.claude/state/components"
mkdir -p "$LOG_DIR" "$STATE_DIR"
echo "$TIMESTAMP | SessionStart | source=$SOURCE | session=$SESSION_ID | local_time=$LOCAL_TIME" >> "$LOG_DIR/session-start-diagnostic.log"

# ============== AUTONOMY CONFIG CHECK ==============
CONFIG_FILE="$CLAUDE_PROJECT_DIR/.claude/config/autonomy-config.yaml"
SKIP_GREETING="false"
AUTO_CONTINUE="true"

# Check environment overrides
if [[ "$JARVIS_DISABLE_AC01" == "true" ]]; then
    echo "$TIMESTAMP | SessionStart | AC-01 disabled via environment" >> "$LOG_DIR/session-start-diagnostic.log"
    echo "{}"
    exit 0
fi

if [[ "$JARVIS_QUICK_MODE" == "true" ]]; then
    SKIP_GREETING="true"
fi

if [[ "$JARVIS_MANUAL_MODE" == "true" ]]; then
    AUTO_CONTINUE="false"
fi

# ============== PHASE A: TIME-OF-DAY GREETING ==============
# Determine greeting based on hour
if (( HOUR >= 5 && HOUR < 12 )); then
    TIME_OF_DAY="morning"
    GREETING="Good morning"
elif (( HOUR >= 12 && HOUR < 17 )); then
    TIME_OF_DAY="afternoon"
    GREETING="Good afternoon"
elif (( HOUR >= 17 && HOUR < 21 )); then
    TIME_OF_DAY="evening"
    GREETING="Good evening"
else
    TIME_OF_DAY="night"
    GREETING="Good evening"
fi

echo "$TIMESTAMP | SessionStart | time_of_day=$TIME_OF_DAY" >> "$LOG_DIR/session-start-diagnostic.log"

# Clean up clear-pending marker from previous session
PENDING_FILE="$CLAUDE_PROJECT_DIR/.claude/context/.clear-pending"
if [[ -f "$PENDING_FILE" ]]; then
    rm -f "$PENDING_FILE"
    echo "$TIMESTAMP | SessionStart | Cleaned up .clear-pending marker" >> "$LOG_DIR/session-start-diagnostic.log"
fi

# Launch auto-clear watcher on startup (not on clear/compact to avoid duplicates)
if [[ "$SOURCE" == "startup" ]] || [[ "$SOURCE" == "resume" ]]; then
    # Launch watcher in background (don't block hook)
    if [[ -x "$CLAUDE_PROJECT_DIR/.claude/scripts/launch-watcher.sh" ]]; then
        "$CLAUDE_PROJECT_DIR/.claude/scripts/launch-watcher.sh" &
        echo "$TIMESTAMP | SessionStart | Launched watcher" >> "$LOG_DIR/session-start-diagnostic.log"
    fi
fi

# ============== MCP SUGGESTIONS ==============
MCP_SUGGESTION=""
if [[ "$SOURCE" == "startup" ]] || [[ "$SOURCE" == "resume" ]]; then
    SUGGEST_SCRIPT="$CLAUDE_PROJECT_DIR/.claude/scripts/suggest-mcps.sh"
    if [[ -x "$SUGGEST_SCRIPT" ]]; then
        MCP_JSON=$("$SUGGEST_SCRIPT" --json 2>/dev/null || echo '{}')
        TO_ENABLE=$(echo "$MCP_JSON" | jq -r '.to_enable // [] | join(", ")' 2>/dev/null)
        TO_DISABLE=$(echo "$MCP_JSON" | jq -r '.to_disable // [] | join(", ")' 2>/dev/null)
        TIER3_WARN=$(echo "$MCP_JSON" | jq -r '.tier3_warnings // [] | join(", ")' 2>/dev/null)

        if [[ -n "$TO_ENABLE" ]] || [[ -n "$TO_DISABLE" ]]; then
            MCP_SUGGESTION="\n\n--- MCP SUGGESTIONS ---\n"
            [[ -n "$TO_ENABLE" ]] && MCP_SUGGESTION="${MCP_SUGGESTION}Enable: $TO_ENABLE\n"
            [[ -n "$TO_DISABLE" ]] && MCP_SUGGESTION="${MCP_SUGGESTION}Disable: $TO_DISABLE\n"
            [[ -n "$TIER3_WARN" ]] && MCP_SUGGESTION="${MCP_SUGGESTION}Tier 3 (high cost): $TIER3_WARN\n"
            MCP_SUGGESTION="${MCP_SUGGESTION}---"
        fi
        echo "$TIMESTAMP | SessionStart | MCP suggestions: enable=[$TO_ENABLE] disable=[$TO_DISABLE]" >> "$LOG_DIR/session-start-diagnostic.log"
    fi
fi

# ============== SESSION STATE CHECK ==============
SESSION_STATE_FILE="$CLAUDE_PROJECT_DIR/.claude/context/session-state.md"
PRIORITIES_FILE="$CLAUDE_PROJECT_DIR/.claude/context/projects/current-priorities.md"
CURRENT_WORK=""
NEXT_STEP=""

if [[ -f "$SESSION_STATE_FILE" ]]; then
    # Extract current work status
    CURRENT_WORK=$(grep -A 1 "Current Work" "$SESSION_STATE_FILE" 2>/dev/null | tail -1 | sed 's/\*\*//g' | xargs)
fi

if [[ -f "$PRIORITIES_FILE" ]]; then
    # Extract next step
    NEXT_STEP=$(grep "Next Step" "$PRIORITIES_FILE" 2>/dev/null | head -1 | sed 's/.*Next Step.*: //' | xargs)
fi

echo "$TIMESTAMP | SessionStart | current_work='$CURRENT_WORK' next_step='$NEXT_STEP'" >> "$LOG_DIR/session-start-diagnostic.log"

# ============== BUILD SELF-LAUNCH PROTOCOL INSTRUCTIONS ==============
build_protocol_instructions() {
    local greeting_text="$1"
    local has_checkpoint="$2"

    if [[ "$SKIP_GREETING" == "true" ]]; then
        echo "QUICK MODE: Skip greeting, proceed directly to work."
        return
    fi

    cat << PROTOCOL
SELF-LAUNCH PROTOCOL (AC-01)

PHASE A - GREETING:
$greeting_text, sir.
(Optional: Use DateTime MCP for precise time, WebSearch for weather if desired)

PHASE B - SYSTEM REVIEW:
Review these files silently:
- .claude/context/session-state.md (current work status)
- .claude/context/projects/current-priorities.md (task backlog)

PHASE C - BRIEFING:
After greeting, provide brief status and AUTONOMOUSLY suggest next action:
- Current work: ${CURRENT_WORK:-"No active work"}
- Next step: ${NEXT_STEP:-"Check priorities"}

AUTONOMY RULE: NEVER simply "await instructions" - always suggest or begin work.
PROTOCOL
}

# ============== CHECKPOINT HANDLING ==============
CHECKPOINT_FILE="$CLAUDE_PROJECT_DIR/.claude/context/.soft-restart-checkpoint.md"

if [[ -f "$CHECKPOINT_FILE" ]]; then
    # Checkpoint exists - load and AUTO-RESUME
    CHECKPOINT_CONTENT=$(cat "$CHECKPOINT_FILE")

    # Build greeting with checkpoint
    if [[ "$SKIP_GREETING" != "true" ]]; then
        GREETING_SECTION="$GREETING, sir. Resuming from checkpoint.\n\n"
    else
        GREETING_SECTION=""
    fi

    MESSAGE="${GREETING_SECTION}CHECKPOINT LOADED ($SOURCE)\n\n$CHECKPOINT_CONTENT$MCP_SUGGESTION"
    CONTEXT="AUTO-RESUME: A context checkpoint was just loaded. First, acknowledge with a brief greeting appropriate for $TIME_OF_DAY. Then continue working on the tasks listed in 'Next Steps After Restart' above. Do NOT wait for user input - proceed immediately with the work."

    # Write state file
    echo "{\"last_run\": \"$TIMESTAMP\", \"greeting_type\": \"$TIME_OF_DAY\", \"checkpoint_loaded\": true, \"auto_continue\": true}" > "$STATE_DIR/AC-01-launch.json"

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

elif [[ "$SOURCE" == "clear" ]]; then
    # No checkpoint, source is clear
    MESSAGE="CONVERSATION CLEARED\n\nNo checkpoint found - starting fresh.\nUse /context-checkpoint before /clear to preserve context.$MCP_SUGGESTION"

    # Write state file
    echo "{\"last_run\": \"$TIMESTAMP\", \"greeting_type\": \"$TIME_OF_DAY\", \"checkpoint_loaded\": false, \"auto_continue\": false}" > "$STATE_DIR/AC-01-launch.json"

    echo "{\"systemMessage\": $(echo "$MESSAGE" | jq -Rs .)}"

elif [[ "$SOURCE" == "startup" ]] || [[ "$SOURCE" == "resume" ]]; then
    # Normal startup - Full Self-Launch Protocol
    PROTOCOL_INSTRUCTIONS=$(build_protocol_instructions "$GREETING" "false")

    if [[ "$AUTO_CONTINUE" == "true" ]] && [[ -n "$NEXT_STEP" ]]; then
        # Autonomous initiation
        CONTEXT="$PROTOCOL_INSTRUCTIONS

AUTONOMOUS INITIATION: After greeting and brief status, proceed with: $NEXT_STEP
Do not wait for user confirmation unless the task requires it."
    else
        # Present options
        CONTEXT="$PROTOCOL_INSTRUCTIONS

Present status and offer to continue with pending work or suggest alternatives."
    fi

    MESSAGE="Session started ($SOURCE)$MCP_SUGGESTION"

    # Write state file
    echo "{\"last_run\": \"$TIMESTAMP\", \"greeting_type\": \"$TIME_OF_DAY\", \"checkpoint_loaded\": false, \"auto_continue\": $AUTO_CONTINUE}" > "$STATE_DIR/AC-01-launch.json"

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

else
    # Compact or other - minimal output
    echo "{}"
fi

# Exit success
exit 0
