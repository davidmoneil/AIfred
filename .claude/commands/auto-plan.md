---
description: Autonomously execute /plan via signal-based watcher
allowed-tools: Bash(.claude/scripts/*)
---

# Auto Plan

Trigger the built-in `/plan` command autonomously via the signal-based watcher.

**Note**: `/plan` enters plan mode for implementation planning.

## Usage Modes

### Mode 1: Fire-and-Forget (Default)

When the user asks to "enter plan mode", "plan this", "create implementation plan":

```bash
.claude/scripts/signal-helper.sh plan
```

### Mode 2: With Auto-Resume

When Jarvis needs to enter plan mode AND continue after:

```bash
.claude/scripts/signal-helper.sh with-resume /plan "" "continue" 3
```

Parameters:
- Command: `/plan`
- Args: `""` (none)
- Resume message: `"continue"` (sent after plan mode activates)
- Resume delay: `3` (seconds)

**Note**: Auto-resume for /plan is less common since plan mode changes the interaction flow.

## CRITICAL: Fire-and-Forget Pattern

**DO NOT:**
- Verify the signal was created
- Check watcher status
- Wait for the command to execute
- Block on any follow-up checks

**DO:**
- Send the signal
- Inform the user briefly
- **CONTINUE with other work immediately**

The signal system is asynchronous. Trust the watcher.

## Examples

### Example 1: Enter plan mode

User: "Let's plan out this feature"

Response:
1. Run: `.claude/scripts/signal-helper.sh plan`
2. Say: "Signal sent for /plan. Plan mode will activate shortly."
3. Continue with any other pending work

### Example 2: Plan mode with auto-resume

When Jarvis needs to enter plan mode as part of a workflow:
1. Run: `.claude/scripts/signal-helper.sh with-resume /plan "" "continue" 3`
2. Say: "Signal sent for /plan with auto-resume."
3. Watcher sends /plan, waits 3s, then sends "continue"

## Related

- `EnterPlanMode` tool — Direct plan mode entry
- `self-monitoring-commands.md` — Full pattern documentation
