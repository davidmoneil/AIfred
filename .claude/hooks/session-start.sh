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
# JICM v6 Integration:
# - Context injection via additionalContext (hook → Claude)
# - v6 watcher handles all state transitions via .jicm-state file
# - See: .claude/context/designs/jicm-v6-design.md
#
# Updated: 2026-02-11 (v6.1 — v5 code paths removed)

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

    # v5 debounce REMOVED (v6.1) — v6 state machine handles clear dedup via .jicm-state

# ============== JICM RESET (AC-04 Integration) ==============
# context-estimate.json write REMOVED (Tier 3+ cleanup) — no production code reads it.
# Watcher writes .watcher-status with live context percentage instead.
COMPACTION_FLAG="$CLAUDE_PROJECT_DIR/.claude/context/.compaction-in-progress"

if [[ "$SOURCE" == "startup" ]] || [[ "$SOURCE" == "clear" ]]; then
    # Clear compaction-in-progress flag if exists
    if [[ -f "$COMPACTION_FLAG" ]]; then
        rm -f "$COMPACTION_FLAG"
        echo "$TIMESTAMP | SessionStart | JICM: Cleared compaction-in-progress flag" >> "$LOG_DIR/session-start-diagnostic.log"
    fi

    # Clear compression-in-progress flag if exists (skill still writes this)
    COMPRESSION_FLAG="$CLAUDE_PROJECT_DIR/.claude/context/.compression-in-progress"
    if [[ -f "$COMPRESSION_FLAG" ]]; then
        rm -f "$COMPRESSION_FLAG"
        echo "$TIMESTAMP | SessionStart | JICM: Cleared compression-in-progress flag" >> "$LOG_DIR/session-start-diagnostic.log"
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

    # JICM agent spawn signal removed (Tier 1 pruning) — nobody reads .jicm-agent-spawn-signal.
    # JICM is fully managed by jicm-watcher.sh (v6 stop-and-wait).
fi

# ============== MCP SUGGESTIONS ==============
# Post-decomposition (v5.9.0): All Tier 1 MCPs phagocytosed into skills.
# Only 5 MCPs remain (memory, local-rag, fetch, git, playwright) — no suggestions needed.
MCP_SUGGESTION=""

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

# --- Claude Code Docs Sync (B.1 integration) ---
CLAUDE_DOCS_REPO="/Users/aircannon/Claude/GitRepos/claude-code-docs"
if [[ -d "$CLAUDE_DOCS_REPO/.git" ]] && [[ "$SOURCE" == "startup" ]]; then
    cd "$CLAUDE_DOCS_REPO" 2>/dev/null
    if git pull --quiet origin main 2>/dev/null; then
        echo "$TIMESTAMP | SessionStart | Claude docs: synced" >> "$LOG_DIR/session-start-diagnostic.log"
    else
        echo "$TIMESTAMP | SessionStart | Claude docs: sync failed (using cached)" >> "$LOG_DIR/session-start-diagnostic.log"
    fi
    cd "$CLAUDE_PROJECT_DIR" 2>/dev/null
fi

# --- JICM Session Memory Directory (B.4 Phase 2) ---
if [[ "$SOURCE" == "startup" ]] || [[ "$SOURCE" == "resume" ]]; then
    JICM_SESSION_ID=$(date +"%Y%m%d-%H%M%S")
    JICM_SESSION_DIR="$CLAUDE_PROJECT_DIR/.claude/context/jicm/sessions/$JICM_SESSION_ID"
    mkdir -p "$JICM_SESSION_DIR"
    # Write session metadata
    printf 'session_id: "%s"\nstarted: "%s"\nsource: "%s"\n' \
        "$JICM_SESSION_ID" "$TIMESTAMP" "$SOURCE" > "$JICM_SESSION_DIR/working-memory.yaml"
    printf 'session_id: "%s"\ndecisions: []\n' "$JICM_SESSION_ID" > "$JICM_SESSION_DIR/decisions.yaml"
    printf 'session_id: "%s"\nobservations: []\n' "$JICM_SESSION_ID" > "$JICM_SESSION_DIR/observations.yaml"
    # Track current session ID for other hooks
    echo "$JICM_SESSION_ID" > "$CLAUDE_PROJECT_DIR/.claude/context/jicm/.current-session-id"
    echo "$TIMESTAMP | SessionStart | JICM session dir: $JICM_SESSION_ID" >> "$LOG_DIR/session-start-diagnostic.log"
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
Status: ${CURRENT_WORK:-No active work} | Next: ${NEXT_STEP:-Check priorities}${aifred_notice}
Read session-state.md + current-priorities.md, then begin work. Do NOT just greet.
PROTOCOL
}

# ============== JICM v6 — STOP-AND-WAIT ARCHITECTURE ==============
# v6 uses a single .jicm-state file instead of multiple signal files.
# The watcher handles all state transitions; this hook just injects context.
# Detection: .jicm-state exists with state=clearing or state=restoring
# See: .claude/context/designs/jicm-v6-design.md
V6_STATE_FILE="$CLAUDE_PROJECT_DIR/.claude/context/.jicm-state"
V6_COMPRESSED="$CLAUDE_PROJECT_DIR/.claude/context/.compressed-context-ready.md"

if [[ "$SOURCE" == "clear" ]] && [[ -f "$V6_STATE_FILE" ]]; then
    V6_STATE=$(grep '^state:' "$V6_STATE_FILE" 2>/dev/null | head -1 | awk '{print $2}')

    if [[ "$V6_STATE" == "CLEARING" ]] || [[ "$V6_STATE" == "RESTORING" ]]; then
        echo "$TIMESTAMP | SessionStart | JICM v6: Detected state=$V6_STATE" >> "$LOG_DIR/session-start-diagnostic.log"

        V6_CONTEXT=""
        if [[ -f "$V6_COMPRESSED" ]]; then
            V6_CONTEXT=$(cat "$V6_COMPRESSED")
            echo "$TIMESTAMP | SessionStart | JICM v6: Loaded compressed context ($(wc -c < "$V6_COMPRESSED") bytes)" >> "$LOG_DIR/session-start-diagnostic.log"
        fi

        # NOTE: Session-state.md deliberately NOT loaded for mid-session restores.
        # It is stale during active work. Compressed context contains current state.
        # Session-state is for NEW session starts only (created at session end).

        MESSAGE="JICM v6: Context compressed and cleared.$ENV_STATUS"
        CONTEXT="JICM v6 CONTEXT RESTORATION — NOT a new session.
You are Jarvis. Context was compressed via stop-and-wait JICM cycle.
Resume work immediately. Do NOT greet. Do NOT ask what to work on.

Current datetime: $LOCAL_DATE at $LOCAL_TIME

Compressed Context:
$V6_CONTEXT

After reading compressed context, also read CLAUDE.md for guardrails.
Read .claude/context/psyche/capability-map.yaml for tool selection.
Resume: Parse above, continue from interruption point."

        # Write state file (AC-01)
        echo "{\"last_run\": \"$TIMESTAMP\", \"greeting_type\": \"$TIME_OF_DAY\", \"checkpoint_loaded\": true, \"compression_type\": \"jicm_v6\", \"restart_type\": \"v6_stop_and_wait\"}" > "$STATE_DIR/AC-01-launch.json"

        # NO .idle-hands-active flag — v6 watcher handles resume directly
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
fi

# JICM v5 code path REMOVED (v6.1, 2026-02-11)
# v5 used two-mechanism resume: hook injection + idle-hands keystroke monitor.
# v6 uses single .jicm-state file + stop-and-wait architecture (above).

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

    MESSAGE="CONTEXT RESTORED ($SOURCE)$ENV_STATUS"
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
    # Clear without checkpoint
    MESSAGE="CONTEXT CLEARED — No checkpoint found.$ENV_STATUS"
    CONTEXT="Context cleared, $LOCAL_DATE at $LOCAL_TIME. No checkpoint found.
Read session-state.md, offer to continue previous work or start fresh.
Tip: Suggest /checkpoint before /clear next time."

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
        CONTEXT="$PROTOCOL_INSTRUCTIONS
AUTO: Proceed with $NEXT_STEP without waiting for confirmation."
    else
        CONTEXT="$PROTOCOL_INSTRUCTIONS
Present status and offer to continue with pending work."
    fi

    MESSAGE="Session started ($SOURCE)$ENV_STATUS"

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
