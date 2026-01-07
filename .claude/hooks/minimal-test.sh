#!/bin/bash
# MINIMAL TEST HOOK - JSON Output Format
# Purpose: Validate that hooks execute and output is visible via systemMessage
# Event: UserPromptSubmit (fires every message)

# Log execution (proof hook ran)
LOG_FILE="$CLAUDE_PROJECT_DIR/.claude/logs/minimal-test.log"
mkdir -p "$(dirname "$LOG_FILE")"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
echo "$TIMESTAMP | HOOK FIRED" >> "$LOG_FILE"

# Output JSON with systemMessage field (should appear in system reminders)
echo '{"systemMessage": "MINIMAL TEST HOOK FIRED SUCCESSFULLY"}'

exit 0
