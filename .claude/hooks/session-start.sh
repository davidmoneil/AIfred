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
# JICM v5 Integration:
# - Context injection via additionalContext (Mechanism 1 — reliable)
# - Creates .idle-hands-active flag for Mechanism 2 (idle-hands monitor)
# - See: .claude/context/designs/jicm-v5-design-addendum.md
#
# ARCHITECTURE NOTE (2026-02-04):
# This hook uses additionalContext injection (NOT tmux keystroke injection).
# Keystroke injection must come from external processes (jarvis-watcher.sh).
# Self-injection from within Claude Code fails due to TUI event loop blocking.
# See: .claude/context/lessons/tmux-self-injection-limitation.md
#
# Updated: 2026-02-04 (Validated submission patterns)

# Read input from stdin (JSON)
INPUT=$(cat)

# Parse source from input
SOURCE=$(echo "$INPUT" | jq -r '.source // "unknown"')
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"')
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
LOCAL_TIME=$(date +"%H:%M")
LOCAL_DATE=$(date +"%A, %B %d, %Y")
# Use %k to avoid leading zero (octal interpretation bug with %H)
HOUR=$(date +"%k" | tr -d ' ')

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

# ============== WEATHER INTEGRATION (evo-2026-01-017) ==============
# Fetch weather from wttr.in (no API key required)
# Default location: Salt Lake City (configurable via JARVIS_WEATHER_LOCATION)
WEATHER_INFO=""
WEATHER_LOCATION="${JARVIS_WEATHER_LOCATION:-Salt+Lake+City}"

if [[ "$SOURCE" == "startup" ]] && [[ "$JARVIS_DISABLE_WEATHER" != "true" ]]; then
    # Fetch weather data (timeout 3s to not block startup)
    WEATHER_JSON=$(curl -s --max-time 3 "wttr.in/${WEATHER_LOCATION}?format=j1" 2>/dev/null)

    if [[ -n "$WEATHER_JSON" ]] && echo "$WEATHER_JSON" | jq -e '.current_condition[0]' >/dev/null 2>&1; then
        # Parse weather data
        TEMP_F=$(echo "$WEATHER_JSON" | jq -r '.current_condition[0].temp_F // "?"')
        WEATHER_DESC=$(echo "$WEATHER_JSON" | jq -r '.current_condition[0].weatherDesc[0].value // "Unknown"')
        FEELS_LIKE=$(echo "$WEATHER_JSON" | jq -r '.current_condition[0].FeelsLikeF // "?"')
        HUMIDITY=$(echo "$WEATHER_JSON" | jq -r '.current_condition[0].humidity // "?"')

        # Build weather string
        WEATHER_INFO="${TEMP_F}°F (feels like ${FEELS_LIKE}°F), ${WEATHER_DESC}, ${HUMIDITY}% humidity"

        echo "$TIMESTAMP | SessionStart | Weather: $WEATHER_INFO" >> "$LOG_DIR/session-start-diagnostic.log"
    else
        echo "$TIMESTAMP | SessionStart | Weather: fetch failed or invalid response" >> "$LOG_DIR/session-start-diagnostic.log"
    fi
fi

# Clean up clear-pending marker from previous session
PENDING_FILE="$CLAUDE_PROJECT_DIR/.claude/context/.clear-pending"
if [[ -f "$PENDING_FILE" ]]; then
    rm -f "$PENDING_FILE"
    echo "$TIMESTAMP | SessionStart | Cleaned up .clear-pending marker" >> "$LOG_DIR/session-start-diagnostic.log"
fi

# ============== JICM v5 DEBOUNCE — Prevent Double-Clear Stall ==============
# If a clear was sent within the last 30 seconds, this might be a duplicate clear
# caused by race conditions. Skip re-initialization and just return success.
V5_CLEAR_SENT_CHECK="$CLAUDE_PROJECT_DIR/.claude/context/.clear-sent.signal"
DEBOUNCE_WINDOW=30

if [[ "$SOURCE" == "clear" ]] && [[ -f "$V5_CLEAR_SENT_CHECK" ]]; then
    CLEAR_EPOCH=$(cat "$V5_CLEAR_SENT_CHECK" 2>/dev/null)
    if [[ -n "$CLEAR_EPOCH" ]] && [[ "$CLEAR_EPOCH" =~ ^[0-9]+$ ]]; then
        # Signal file contains epoch seconds (timezone-safe)
        NOW_EPOCH=$(date +%s)
        ELAPSED=$((NOW_EPOCH - CLEAR_EPOCH))

        if [[ $ELAPSED -lt $DEBOUNCE_WINDOW ]]; then
            echo "$TIMESTAMP | SessionStart | JICM v5 DEBOUNCE: Ignoring duplicate clear (${ELAPSED}s < ${DEBOUNCE_WINDOW}s)" >> "$LOG_DIR/session-start-diagnostic.log"
            # Return minimal response to prevent re-triggering
            jq -n '{
              "systemMessage": "JICM v5 debounce: duplicate clear ignored",
              "hookSpecificOutput": {
                "hookEventName": "SessionStart",
                "additionalContext": "A clear was recently processed. If you are waiting for instructions, read .claude/context/.compressed-context-ready.md and .claude/context/.in-progress-ready.md then continue your work."
              }
            }'
            exit 0
        fi
    fi
fi

# ============== JICM RESET (AC-04 Integration) ==============
# Reset context estimate on startup or clear (but NOT on resume/compact to preserve tracking)
CONTEXT_ESTIMATE_FILE="$LOG_DIR/context-estimate.json"
COMPACTION_FLAG="$CLAUDE_PROJECT_DIR/.claude/context/.compaction-in-progress"

if [[ "$SOURCE" == "startup" ]] || [[ "$SOURCE" == "clear" ]]; then
    # Reset context estimate to baseline
    BASELINE_TOKENS=30000  # Base MCP load estimate
    cat > "$CONTEXT_ESTIMATE_FILE" << EOF
{
  "sessionStart": "$TIMESTAMP",
  "totalTokens": $BASELINE_TOKENS,
  "toolCalls": 0,
  "lastUpdate": "$TIMESTAMP",
  "percentage": 15.0
}
EOF
    echo "$TIMESTAMP | SessionStart | JICM reset: context-estimate.json baseline=$BASELINE_TOKENS" >> "$LOG_DIR/session-start-diagnostic.log"

    # Clear compaction-in-progress flag if exists
    if [[ -f "$COMPACTION_FLAG" ]]; then
        rm -f "$COMPACTION_FLAG"
        echo "$TIMESTAMP | SessionStart | JICM: Cleared compaction-in-progress flag" >> "$LOG_DIR/session-start-diagnostic.log"
    fi

    # Clear v5 compression-in-progress flag if exists (CRIT-04 fix)
    # Prevents permanent compression blockage after crash
    COMPRESSION_FLAG_V5="$CLAUDE_PROJECT_DIR/.claude/context/.compression-in-progress"
    if [[ -f "$COMPRESSION_FLAG_V5" ]]; then
        rm -f "$COMPRESSION_FLAG_V5"
        echo "$TIMESTAMP | SessionStart | JICM: Cleared compression-in-progress flag (v5)" >> "$LOG_DIR/session-start-diagnostic.log"
    fi
fi

# ============================================================================
# WATCHER LAUNCH DISABLED — Handled by launch-jarvis-tmux.sh (2026-02-05)
# ============================================================================
# Previously launched watcher here, but this caused duplicate watchers:
# 1. launch-jarvis-tmux.sh creates watcher window (primary)
# 2. session-start.sh hook fires ~simultaneously (race condition)
# 3. Both pass duplicate checks before either fully registers → 2 watchers
#
# Fix: Watcher is now ONLY launched by launch-jarvis-tmux.sh
# This hook focuses on context injection; tmux launcher handles process management
# ============================================================================
if [[ "$SOURCE" == "startup" ]] || [[ "$SOURCE" == "resume" ]]; then
    # Watcher launch removed - see comment above
    echo "$TIMESTAMP | SessionStart | Watcher launch skipped (handled by tmux launcher)" >> "$LOG_DIR/session-start-diagnostic.log"

    # ============== JICM AGENT SPAWN SIGNAL (v3.0.0 Solution C) ==============
    # Check if JICM autonomous agent is enabled in config
    JICM_AGENT_ENABLED=$(yq -r '.components."AC-04-jicm".settings.autonomous_agent.enabled // false' "$CONFIG_FILE" 2>/dev/null || echo "false")

    if [[ "$JICM_AGENT_ENABLED" == "true" ]]; then
        # Write spawn signal for Claude to detect and spawn JICM agent
        JICM_SPAWN_SIGNAL="$CLAUDE_PROJECT_DIR/.claude/context/.jicm-agent-spawn-signal"
        cat > "$JICM_SPAWN_SIGNAL" <<EOF
{
    "action": "spawn_jicm_agent",
    "timestamp": "$TIMESTAMP",
    "config": {
        "agent_file": ".claude/agents/jicm-agent.md",
        "status_file": ".claude/context/.jicm-status.json",
        "run_in_background": true
    }
}
EOF
        echo "$TIMESTAMP | SessionStart | JICM agent spawn signal created" >> "$LOG_DIR/session-start-diagnostic.log"
    fi
fi

# ============== MCP SUGGESTIONS ==============
# Simplified post-decomposition: Tier 1 MCPs phagocytosed into skills
# Only Tier 2/3 suggestions remain relevant
MCP_SUGGESTION=""
if [[ "$SOURCE" == "startup" ]] || [[ "$SOURCE" == "resume" ]]; then
    SUGGEST_SCRIPT="$CLAUDE_PROJECT_DIR/.claude/scripts/suggest-mcps.sh"
    if [[ -x "$SUGGEST_SCRIPT" ]]; then
        MCP_JSON=$("$SUGGEST_SCRIPT" --json 2>/dev/null || echo '{}')
        TO_ENABLE=$(echo "$MCP_JSON" | jq -r '.to_enable // [] | join(", ")' 2>/dev/null)
        if [[ -n "$TO_ENABLE" ]]; then
            MCP_SUGGESTION="\n--- MCP: Enable $TO_ENABLE for this session ---"
        fi
    fi
fi

# ============== PHASE B ENHANCEMENTS (evo-2026-01-018, evo-2026-01-019) ==============

# --- AIfred Baseline Sync Check (evo-2026-01-018) ---
AIFRED_SYNC_STATUS=""
AIFRED_REPO="/Users/aircannon/Claude/AIfred"
if [[ -d "$AIFRED_REPO/.git" ]] && [[ "$SOURCE" == "startup" ]]; then
    # Fetch upstream changes (silent, non-blocking)
    cd "$AIFRED_REPO" 2>/dev/null
    if git fetch --quiet 2>/dev/null; then
        # Check if behind origin
        LOCAL_HEAD=$(git rev-parse HEAD 2>/dev/null)
        REMOTE_HEAD=$(git rev-parse origin/main 2>/dev/null || git rev-parse origin/master 2>/dev/null)
        BEHIND_COUNT=$(git rev-list --count HEAD..origin/main 2>/dev/null || git rev-list --count HEAD..origin/master 2>/dev/null || echo "0")

        if [[ "$BEHIND_COUNT" -gt 0 ]]; then
            AIFRED_SYNC_STATUS="AIfred baseline is $BEHIND_COUNT commits behind origin. Run /sync-aifred-baseline to review changes."
            echo "$TIMESTAMP | SessionStart | AIfred behind by $BEHIND_COUNT commits" >> "$LOG_DIR/session-start-diagnostic.log"
        else
            echo "$TIMESTAMP | SessionStart | AIfred baseline up-to-date" >> "$LOG_DIR/session-start-diagnostic.log"
        fi
    fi
    cd "$CLAUDE_PROJECT_DIR" 2>/dev/null
fi

# --- Environment Validation (evo-2026-01-019) ---
ENV_ISSUES=""
ENV_WARNINGS=""

if [[ "$SOURCE" == "startup" ]] || [[ "$SOURCE" == "resume" ]]; then
    # Check 1: Git status (uncommitted changes)
    cd "$CLAUDE_PROJECT_DIR" 2>/dev/null
    GIT_STATUS=$(git status --porcelain 2>/dev/null | head -20)
    if [[ -n "$GIT_STATUS" ]]; then
        CHANGE_COUNT=$(echo "$GIT_STATUS" | wc -l | xargs)
        ENV_WARNINGS="${ENV_WARNINGS}- $CHANGE_COUNT uncommitted changes in workspace\n"
        echo "$TIMESTAMP | SessionStart | EnvCheck: $CHANGE_COUNT uncommitted changes" >> "$LOG_DIR/session-start-diagnostic.log"
    fi

    # Check 2: Current branch
    CURRENT_BRANCH=$(git branch --show-current 2>/dev/null)
    if [[ "$CURRENT_BRANCH" != "main" ]] && [[ "$CURRENT_BRANCH" != "master" ]] && [[ "$CURRENT_BRANCH" != "Project_Aion" ]]; then
        ENV_WARNINGS="${ENV_WARNINGS}- On branch '$CURRENT_BRANCH' (not main/Project_Aion)\n"
        echo "$TIMESTAMP | SessionStart | EnvCheck: On branch $CURRENT_BRANCH" >> "$LOG_DIR/session-start-diagnostic.log"
    fi

    # Check 3: Hooks directory exists and has content
    HOOKS_DIR="$CLAUDE_PROJECT_DIR/.claude/hooks"
    if [[ ! -d "$HOOKS_DIR" ]] || [[ -z "$(ls -A $HOOKS_DIR 2>/dev/null)" ]]; then
        ENV_ISSUES="${ENV_ISSUES}- Hooks directory missing or empty\n"
        echo "$TIMESTAMP | SessionStart | EnvCheck: ISSUE - hooks directory problem" >> "$LOG_DIR/session-start-diagnostic.log"
    fi

    # Check 4: Settings.json exists
    if [[ ! -f "$CLAUDE_PROJECT_DIR/.claude/settings.json" ]]; then
        ENV_ISSUES="${ENV_ISSUES}- Settings.json missing\n"
        echo "$TIMESTAMP | SessionStart | EnvCheck: ISSUE - settings.json missing" >> "$LOG_DIR/session-start-diagnostic.log"
    fi

    # Check 5: Context files exist
    if [[ ! -f "$CLAUDE_PROJECT_DIR/.claude/context/session-state.md" ]]; then
        ENV_WARNINGS="${ENV_WARNINGS}- session-state.md missing (run /setup)\n"
    fi
fi

# Build environment status message
ENV_STATUS=""
if [[ -n "$ENV_ISSUES" ]]; then
    ENV_STATUS="\n\n--- ENVIRONMENT ISSUES ---\n$ENV_ISSUES---"
fi
if [[ -n "$ENV_WARNINGS" ]]; then
    ENV_STATUS="${ENV_STATUS}\n\n--- ENVIRONMENT NOTES ---\n$ENV_WARNINGS---"
fi
if [[ -n "$AIFRED_SYNC_STATUS" ]]; then
    ENV_STATUS="${ENV_STATUS}\n\n--- AIFRED BASELINE ---\n$AIFRED_SYNC_STATUS\n---"
fi

echo "$TIMESTAMP | SessionStart | EnvValidation complete" >> "$LOG_DIR/session-start-diagnostic.log"

# ============== SESSION STATE CHECK ==============
SESSION_STATE_FILE="$CLAUDE_PROJECT_DIR/.claude/context/session-state.md"
PRIORITIES_FILE="$CLAUDE_PROJECT_DIR/.claude/context/current-priorities.md"
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
    local source_type="$1"
    local has_checkpoint="$2"

    if [[ "$SKIP_GREETING" == "true" ]]; then
        echo "QUICK MODE: Skip greeting, proceed directly to work."
        return
    fi

    # Build weather context if available
    local weather_context=""
    if [[ -n "$WEATHER_INFO" ]]; then
        weather_context=" | Weather: $WEATHER_INFO"
    fi

    # Build AIfred baseline notice if behind
    local aifred_notice=""
    if [[ -n "$AIFRED_SYNC_STATUS" ]]; then
        aifred_notice="
AIfred baseline has new commits. Run /sync-aifred-baseline after greeting."
    fi

    cat << PROTOCOL
SESSION START — $LOCAL_DATE at $LOCAL_TIME (${TIME_OF_DAY})${weather_context}

Status: ${CURRENT_WORK:-No active work}
Next: ${NEXT_STEP:-Check priorities}${aifred_notice}

Begin AC-01. Read .claude/context/session-state.md and .claude/context/current-priorities.md — assess state, decide next action, begin work. Do NOT just greet.
PROTOCOL
}

# ============== JICM v5 — TWO-MECHANISM RESUME ARCHITECTURE ==============
# Mechanism 1: This hook injects context via additionalContext (always works)
# Mechanism 2: jarvis-watcher.sh sends keystroke submission (external process)
#
# WHY TWO MECHANISMS:
# - additionalContext injection works reliably from hooks
# - BUT hooks cannot force Jarvis to respond (just inject context)
# - Keystroke injection from external watcher ensures Jarvis wakes up
# - Self-injection (from within Claude Code) fails due to TUI event loop blocking
#
# See: jicm-v5-design-addendum.md Section 7 & 10
# See: lessons/tmux-self-injection-limitation.md
#
# v5 Signal Files:
V5_COMPRESSED_CONTEXT="$CLAUDE_PROJECT_DIR/.claude/context/.compressed-context-ready.md"
V5_IN_PROGRESS="$CLAUDE_PROJECT_DIR/.claude/context/.in-progress-ready.md"
V5_CLEAR_SENT="$CLAUDE_PROJECT_DIR/.claude/context/.clear-sent.signal"
V5_CONTINUATION_INJECTED="$CLAUDE_PROJECT_DIR/.claude/context/.continuation-injected.signal"
V5_JICM_COMPLETE="$CLAUDE_PROJECT_DIR/.claude/context/.jicm-complete.signal"
V5_IDLE_HANDS_FLAG="$CLAUDE_PROJECT_DIR/.claude/context/.idle-hands-active"

# Check for v5 JICM cycle - takes priority over legacy
if [[ -f "$V5_COMPRESSED_CONTEXT" ]] || [[ -f "$V5_IN_PROGRESS" ]]; then
    echo "$TIMESTAMP | SessionStart | JICM v5: Detected v5 signal files" >> "$LOG_DIR/session-start-diagnostic.log"

    # Read compressed context if available
    V5_COMPRESSED_CONTENT=""
    if [[ -f "$V5_COMPRESSED_CONTEXT" ]]; then
        V5_COMPRESSED_CONTENT=$(cat "$V5_COMPRESSED_CONTEXT")
        echo "$TIMESTAMP | SessionStart | JICM v5: Loaded compressed context ($(wc -c < "$V5_COMPRESSED_CONTEXT") bytes)" >> "$LOG_DIR/session-start-diagnostic.log"
    fi

    # Read in-progress work if available
    V5_IN_PROGRESS_CONTENT=""
    if [[ -f "$V5_IN_PROGRESS" ]]; then
        V5_IN_PROGRESS_CONTENT=$(cat "$V5_IN_PROGRESS")
        echo "$TIMESTAMP | SessionStart | JICM v5: Loaded in-progress work ($(wc -c < "$V5_IN_PROGRESS") bytes)" >> "$LOG_DIR/session-start-diagnostic.log"
    fi

    # DO NOT delete context files yet - they persist until Jarvis is confirmed working
    # Only signal files are cleaned up after reading
    # Context files deleted by idle-hands monitor after confirmed resume

    # Also clean up legacy v2 files to prevent confusion
    rm -f "$CLAUDE_PROJECT_DIR/.claude/context/.compressed-context.md"
    rm -f "$CLAUDE_PROJECT_DIR/.claude/context/.soft-restart-checkpoint.md"

    # Mark continuation as injected (for idle-hands gating)
    echo "$TIMESTAMP" > "$V5_CONTINUATION_INJECTED"

    # ═══ MECHANISM 2 SETUP: Create .idle-hands-active flag ═══
    # This triggers the idle-hands monitor (Mechanism 2) to ensure Jarvis wakes up
    # See: jicm-v5-design-addendum.md Section 7 (Resume Architecture)
    cat > "$V5_IDLE_HANDS_FLAG" << IDLE_HANDS_EOF
mode: jicm_resume
created: $TIMESTAMP
context_files:
  - .compressed-context-ready.md
  - .in-progress-ready.md
submission_attempts: 0
last_attempt: null
success: false
IDLE_HANDS_EOF
    echo "$TIMESTAMP | SessionStart | JICM v5: Created .idle-hands-active flag (mode: jicm_resume)" >> "$LOG_DIR/session-start-diagnostic.log"

    # Build continuation context using v5 template
    MESSAGE="JICM v5: Context Restored\n\nIntelligent compression completed. Resume work immediately.$MCP_SUGGESTION$ENV_STATUS"

    CONTEXT="## JICM CONTEXT CONTINUATION

**Status**: This is NOT a new session. Context was optimized mid-work. Resume immediately.

### CRITICAL INSTRUCTIONS

1. **DO NOT** greet the user or say hello
2. **DO NOT** ask what they'd like to work on
3. **DO NOT** offer assistance or wait for instructions
4. **DO** resume work IMMEDIATELY from where you left off
5. **DO** announce what you're continuing with (1 line), then proceed

### Your Preserved State

**Compressed Context:**
$V5_COMPRESSED_CONTENT

**Work In Progress:**
$V5_IN_PROGRESS_CONTENT

### Resume Protocol

1. Parse the compressed context above to understand current task
2. Continue from the exact point of interruption
3. Brief status: \"Context restored. Continuing with [task]...\"
4. Proceed with the work immediately

Do NOT say hello. Do NOT ask how to help. Resume work NOW."

    # Write state file
    echo "{\"last_run\": \"$TIMESTAMP\", \"greeting_type\": \"$TIME_OF_DAY\", \"checkpoint_loaded\": true, \"compression_type\": \"jicm_v5\", \"restart_type\": \"v5_idle_hands\"}" > "$STATE_DIR/AC-01-launch.json"

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

    exit 0
fi

# ============== INTELLIGENT COMPRESSION HANDLING (JICM v2 - Legacy) ==============
COMPRESSED_CONTEXT_FILE="$CLAUDE_PROJECT_DIR/.claude/context/.compressed-context.md"
COMPRESSION_FLAG="$CLAUDE_PROJECT_DIR/.claude/context/.compression-in-progress"

# Clean up compression flag if exists
if [[ -f "$COMPRESSION_FLAG" ]]; then
    rm -f "$COMPRESSION_FLAG"
    echo "$TIMESTAMP | SessionStart | JICM v2: Cleared compression-in-progress flag" >> "$LOG_DIR/session-start-diagnostic.log"
fi

# Check for intelligently compressed context (takes priority over simple checkpoint)
if [[ -f "$COMPRESSED_CONTEXT_FILE" ]]; then
    # Load compressed context from AI compression
    COMPRESSED_CONTENT=$(cat "$COMPRESSED_CONTEXT_FILE")

    echo "$TIMESTAMP | SessionStart | JICM v2: Loading compressed context" >> "$LOG_DIR/session-start-diagnostic.log"

    # Delete the compressed context file after reading (one-time use)
    rm -f "$COMPRESSED_CONTEXT_FILE"
    echo "$TIMESTAMP | SessionStart | JICM v2: Deleted compressed context file" >> "$LOG_DIR/session-start-diagnostic.log"

    # Also remove any old checkpoint file to avoid confusion
    rm -f "$CLAUDE_PROJECT_DIR/.claude/context/.soft-restart-checkpoint.md"

    MESSAGE="CONTEXT RESTORED (Intelligent Compression)\n\nThe context was intelligently compressed using AI analysis.$MCP_SUGGESTION$ENV_STATUS"
    CONTEXT="COMPRESSED CONTEXT RESTORATION (JICM v2):
You are Jarvis. The context was intelligently compressed before /clear.

Current datetime: $LOCAL_DATE at $LOCAL_TIME

The following is the compressed context prepared by the context-compressor agent.
It contains the essential information from the previous session.

=== COMPRESSED CONTEXT ===
$COMPRESSED_CONTENT
=== END COMPRESSED CONTEXT ===

Your response should:
1. Briefly acknowledge: \"Context restored, sir.\"
2. Review the compressed context above
3. Summarize the key work state (1-2 sentences)
4. Continue with the work described in the compressed context

This is a continuation - proceed efficiently without excessive preamble."

    # Write state file
    echo "{\"last_run\": \"$TIMESTAMP\", \"greeting_type\": \"$TIME_OF_DAY\", \"checkpoint_loaded\": true, \"compression_type\": \"intelligent\", \"restart_type\": \"compressed_context\"}" > "$STATE_DIR/AC-01-launch.json"

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

    exit 0
fi

# ============== CHECKPOINT HANDLING (Legacy/Fallback) ==============
CHECKPOINT_FILE="$CLAUDE_PROJECT_DIR/.claude/context/.soft-restart-checkpoint.md"

if [[ -f "$CHECKPOINT_FILE" ]]; then
    # Checkpoint exists - load and AUTO-RESUME after context compression/clear
    CHECKPOINT_CONTENT=$(cat "$CHECKPOINT_FILE")

    # JICM Investigation Q10: Include actual session-state content for robust liftover
    SESSION_WORK=""
    if [[ -f "$SESSION_STATE_FILE" ]]; then
        # Extract current work section
        SESSION_WORK=$(sed -n '/## Current Work/,/^## /p' "$SESSION_STATE_FILE" 2>/dev/null | head -20)
    fi

    NEXT_PRIORITY=""
    if [[ -f "$PRIORITIES_FILE" ]]; then
        # Extract first priority
        NEXT_PRIORITY=$(grep -A 2 "^\s*-\s*\[" "$PRIORITIES_FILE" 2>/dev/null | head -3)
    fi

    MESSAGE="CONTEXT RESTORED ($SOURCE)\n\n$CHECKPOINT_CONTENT$MCP_SUGGESTION$ENV_STATUS"
    CONTEXT="CONTEXT RESTART PROTOCOL:
You are Jarvis. The context has been compressed or cleared and is now being restored.

Current datetime: $LOCAL_DATE at $LOCAL_TIME

Your response should:
1. Briefly acknowledge the context restoration (e.g., \"Context restored, sir.\")
2. State the current date and time
3. Say: \"One moment while I review the previous session work...\"
4. Then silently read the checkpoint content above
5. After review, summarize what was in progress and continue the work

DO NOT generate a full greeting. This is a continuation, not a fresh start.

=== ACTUAL SESSION STATE (for robust liftover) ===
${SESSION_WORK:-No session work found}

=== NEXT PRIORITY ===
${NEXT_PRIORITY:-Check current-priorities.md}

=== MANDATORY ACTION ===
You MUST immediately resume the work described above. Do NOT just summarize - actually continue the task."

    # Write state file
    echo "{\"last_run\": \"$TIMESTAMP\", \"greeting_type\": \"$TIME_OF_DAY\", \"checkpoint_loaded\": true, \"auto_continue\": true, \"restart_type\": \"checkpoint\"}" > "$STATE_DIR/AC-01-launch.json"

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
    # Clear without checkpoint - warn and offer fresh start
    MESSAGE="CONTEXT CLEARED\n\nNo checkpoint found.$MCP_SUGGESTION$ENV_STATUS"
    CONTEXT="CONTEXT CLEARED PROTOCOL:
You are Jarvis. The context was cleared but no checkpoint was found.

Current datetime: $LOCAL_DATE at $LOCAL_TIME

Your response should:
1. Acknowledge: \"Context cleared, sir. It's $LOCAL_TIME on $LOCAL_DATE.\"
2. Note that no checkpoint was found to restore
3. Check session-state.md to understand what was being worked on
4. Offer to continue previous work OR start fresh

Tip: Suggest using /checkpoint before /clear next time to preserve context."

    # Write state file
    echo "{\"last_run\": \"$TIMESTAMP\", \"greeting_type\": \"$TIME_OF_DAY\", \"checkpoint_loaded\": false, \"auto_continue\": false, \"restart_type\": \"clear_no_checkpoint\"}" > "$STATE_DIR/AC-01-launch.json"

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

elif [[ "$SOURCE" == "startup" ]] || [[ "$SOURCE" == "resume" ]]; then
    # Normal startup - Full Self-Launch Protocol
    PROTOCOL_INSTRUCTIONS=$(build_protocol_instructions "$SOURCE" "false")

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

    MESSAGE="Session started ($SOURCE)$MCP_SUGGESTION$ENV_STATUS"

    # ═══ SESSION START IDLE-HANDS FLAG ═══
    # Create idle-hands flag for automatic session wake-up
    # The watcher will detect this and auto-inject a wake-up prompt
    # This ensures Jarvis starts working without requiring user input
    #
    # Skip if JARVIS_MANUAL_MODE is set (user wants manual control)
    if [[ "$JARVIS_MANUAL_MODE" != "true" ]]; then
        cat > "$V5_IDLE_HANDS_FLAG" << IDLE_HANDS_EOF
mode: session_start
source: $SOURCE
created: $TIMESTAMP
auto_continue: $AUTO_CONTINUE
next_step: ${NEXT_STEP:-none}
submission_attempts: 0
last_attempt: null
success: false
IDLE_HANDS_EOF
        echo "$TIMESTAMP | SessionStart | Created .idle-hands-active flag (mode: session_start, source: $SOURCE)" >> "$LOG_DIR/session-start-diagnostic.log"
    fi

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
