---
description: Autonomously execute /cost via signal-based watcher
allowed-tools: Bash(.claude/scripts/*)
---

# Auto Cost

Trigger the built-in `/cost` command autonomously via the signal-based watcher.

**Note**: `/cost` shows API cost/token statistics for the session.

## Usage Modes

### Mode 1: Fire-and-Forget (Default)

When the user asks to "show cost", "how much did this cost", "spending":

```bash
.claude/scripts/signal-helper.sh cost
```

### Mode 2: With Auto-Resume

When Jarvis needs to check cost AND continue working automatically:

```bash
.claude/scripts/signal-helper.sh with-resume /cost "" "continue" 3
```

Parameters:
- Command: `/cost`
- Args: `""` (none)
- Resume message: `"continue"` (sent after cost displays)
- Resume delay: `3` (seconds)

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

### Example 1: Simple cost check

User: "How much has this session cost?"

Response:
1. Run: `.claude/scripts/signal-helper.sh cost`
2. Say: "Signal sent for /cost. Cost info will appear shortly."
3. Continue with any other pending work

### Example 2: Cost check with auto-resume

User: "Check cost and continue working"

Response:
1. Run: `.claude/scripts/signal-helper.sh with-resume /cost "" "continue" 3`
2. Say: "Signal sent for /cost with auto-resume."
3. Watcher sends /cost, waits 3s, then sends "continue"

## Related

- `/usage` — Token BUDGET (quota limits)
- `/stats` — Session statistics
- `self-monitoring-commands.md` — Full pattern documentation
