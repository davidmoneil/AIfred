---
description: Autonomously execute /rename via signal-based watcher
allowed-tools: Bash(.claude/scripts/*)
---

# Auto Rename

Trigger the built-in `/rename` command autonomously via the signal-based watcher.

**Note**: `/rename` renames the current session. A name is REQUIRED.

## Usage Modes

### Mode 1: Fire-and-Forget (Default)

When the user asks to "rename session", "call this session X", "name this chat":

**Step 1**: Extract session name (REQUIRED)
- "rename this to Feature Implementation" → name: "Feature Implementation"
- "just rename it" → ASK USER for a name

**Step 2**: Send signal with name
```bash
.claude/scripts/signal-helper.sh rename "SESSION_NAME_HERE"
```

### Mode 2: With Auto-Resume

When Jarvis needs to rename AND continue working automatically:

```bash
.claude/scripts/signal-helper.sh with-resume /rename "PR-12.11 Auto-Resume Implementation" "continue" 3
```

Parameters:
- Command: `/rename`
- Args: Session name (REQUIRED)
- Resume message: `"continue"` (sent after rename completes)
- Resume delay: `3` (seconds)

## CRITICAL: Name is Required

**DO NOT** send `/rename` without a name - always ask user if not provided.

## Examples

### Example 1: User-specified name

User: "Rename this session to Autonomous Commands Implementation"

Response:
1. Run: `.claude/scripts/signal-helper.sh rename "Autonomous Commands Implementation"`
2. Say: "Signal sent for /rename. Session will be renamed."
3. Continue with any other pending work

### Example 2: Name not provided

User: "Rename this session"

Response:
1. ASK: "What would you like to name this session?"
2. Wait for user response
3. Then send: `.claude/scripts/signal-helper.sh rename "USER_PROVIDED_NAME"`

### Example 3: Rename with auto-resume

When Jarvis renames as part of session setup:
1. Run: `.claude/scripts/signal-helper.sh with-resume /rename "Phase 6 Implementation" "continue" 3`
2. Say: "Signal sent for /rename with auto-resume."
3. Watcher renames, waits 3s, then sends "continue"

## Related

- `/end-session` — Clean session exit
- `self-monitoring-commands.md` — Full pattern documentation
