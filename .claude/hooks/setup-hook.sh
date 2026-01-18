#!/bin/bash
# Setup Hook - Repository Setup and Maintenance (evo-2026-01-022)
# Triggered via: claude --init, claude --init-only, claude --maintenance
# Output: JSON with systemMessage and additionalContext
#
# Features:
# - Initial repository setup validation
# - Maintenance mode for periodic health checks
# - Directory structure verification
# - Configuration validation
#
# Created: 2026-01-18 (R&D Cycle implementation)

# Read input from stdin (JSON)
INPUT=$(cat)

# Parse trigger type from input
TRIGGER_TYPE=$(echo "$INPUT" | jq -r '.trigger // "unknown"')
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"')
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Log to diagnostic file
LOG_DIR="$CLAUDE_PROJECT_DIR/.claude/logs"
mkdir -p "$LOG_DIR"
echo "$TIMESTAMP | SetupHook | trigger=$TRIGGER_TYPE | session=$SESSION_ID" >> "$LOG_DIR/setup-hook.log"

# ============== DIRECTORY STRUCTURE VALIDATION ==============
REQUIRED_DIRS=(
    ".claude/context"
    ".claude/context/patterns"
    ".claude/context/projects"
    ".claude/context/lessons"
    ".claude/context/research"
    ".claude/hooks"
    ".claude/scripts"
    ".claude/commands"
    ".claude/skills"
    ".claude/state"
    ".claude/state/queues"
    ".claude/state/components"
    ".claude/logs"
    ".claude/plans"
    ".claude/persona"
)

MISSING_DIRS=""
for dir in "${REQUIRED_DIRS[@]}"; do
    if [[ ! -d "$CLAUDE_PROJECT_DIR/$dir" ]]; then
        MISSING_DIRS="${MISSING_DIRS}  - $dir\n"
        # Auto-create missing directories
        mkdir -p "$CLAUDE_PROJECT_DIR/$dir"
        echo "$TIMESTAMP | SetupHook | Created missing directory: $dir" >> "$LOG_DIR/setup-hook.log"
    fi
done

# ============== REQUIRED FILES CHECK ==============
REQUIRED_FILES=(
    ".claude/settings.json"
    ".claude/CLAUDE.md"
    ".claude/context/session-state.md"
    ".claude/persona/jarvis-identity.md"
)

MISSING_FILES=""
for file in "${REQUIRED_FILES[@]}"; do
    if [[ ! -f "$CLAUDE_PROJECT_DIR/$file" ]]; then
        MISSING_FILES="${MISSING_FILES}  - $file\n"
    fi
done

# ============== HOOKS VALIDATION ==============
HOOKS_STATUS="OK"
SETTINGS_FILE="$CLAUDE_PROJECT_DIR/.claude/settings.json"
if [[ -f "$SETTINGS_FILE" ]]; then
    HOOK_COUNT=$(jq '.hooks | keys | length' "$SETTINGS_FILE" 2>/dev/null || echo "0")
    if [[ "$HOOK_COUNT" -lt 3 ]]; then
        HOOKS_STATUS="WARNING: Only $HOOK_COUNT hook types registered"
    else
        HOOKS_STATUS="$HOOK_COUNT hook types registered"
    fi
fi

# ============== MCP CONFIGURATION CHECK ==============
MCP_STATUS=""
MCP_COUNT=$(claude mcp list 2>/dev/null | grep -c "^" || echo "0")
if [[ "$MCP_COUNT" -gt 0 ]]; then
    MCP_STATUS="$MCP_COUNT MCP servers configured"
else
    MCP_STATUS="No MCP servers found (run 'claude mcp add' to configure)"
fi

# ============== BUILD SETUP REPORT ==============
SETUP_REPORT="JARVIS SETUP VALIDATION
========================

Trigger: $TRIGGER_TYPE
Timestamp: $TIMESTAMP

DIRECTORY STRUCTURE
-------------------"

if [[ -z "$MISSING_DIRS" ]]; then
    SETUP_REPORT="${SETUP_REPORT}
All required directories present ✓"
else
    SETUP_REPORT="${SETUP_REPORT}
Created missing directories:
$MISSING_DIRS"
fi

SETUP_REPORT="${SETUP_REPORT}

REQUIRED FILES
--------------"

if [[ -z "$MISSING_FILES" ]]; then
    SETUP_REPORT="${SETUP_REPORT}
All required files present ✓"
else
    SETUP_REPORT="${SETUP_REPORT}
Missing files (action required):
$MISSING_FILES"
fi

SETUP_REPORT="${SETUP_REPORT}

CONFIGURATION
-------------
Hooks: $HOOKS_STATUS
MCPs: $MCP_STATUS

NEXT STEPS
----------"

if [[ "$TRIGGER_TYPE" == "init" ]] || [[ "$TRIGGER_TYPE" == "init-only" ]]; then
    SETUP_REPORT="${SETUP_REPORT}
Initial setup complete. Run /tooling-health for full validation."
elif [[ "$TRIGGER_TYPE" == "maintenance" ]]; then
    SETUP_REPORT="${SETUP_REPORT}
Maintenance check complete. Review any warnings above."
else
    SETUP_REPORT="${SETUP_REPORT}
Setup validation complete."
fi

# ============== BUILD ADDITIONAL CONTEXT ==============
if [[ -n "$MISSING_FILES" ]]; then
    CONTEXT="SETUP INCOMPLETE: Some required files are missing. You may need to run /setup or create these files manually. Review the setup report and take corrective action."
elif [[ "$TRIGGER_TYPE" == "maintenance" ]]; then
    CONTEXT="MAINTENANCE MODE: This is a periodic maintenance check. Review the validation report and address any warnings. Consider running /sync-aifred-baseline if baseline sync is needed."
else
    CONTEXT="SETUP VALIDATION PASSED: Jarvis directory structure and configuration validated. Ready for operation."
fi

# Write state file
STATE_DIR="$CLAUDE_PROJECT_DIR/.claude/state/components"
mkdir -p "$STATE_DIR"
echo "{\"last_run\": \"$TIMESTAMP\", \"trigger\": \"$TRIGGER_TYPE\", \"missing_dirs\": $(echo -n "$MISSING_DIRS" | wc -l | xargs), \"missing_files\": $(echo -n "$MISSING_FILES" | wc -l | xargs)}" > "$STATE_DIR/setup-hook.json"

# Output JSON response
jq -n \
  --arg msg "$SETUP_REPORT" \
  --arg ctx "$CONTEXT" \
  '{
    "systemMessage": $msg,
    "hookSpecificOutput": {
      "hookEventName": "Setup",
      "additionalContext": $ctx
    }
  }'

echo "$TIMESTAMP | SetupHook | Complete" >> "$LOG_DIR/setup-hook.log"
exit 0
