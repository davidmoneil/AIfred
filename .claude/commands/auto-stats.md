---
description: Autonomously execute /stats via signal-based watcher
allowed-tools: Bash(.claude/scripts/*)
---

# Auto Stats

Trigger the built-in `/stats` command autonomously via the signal-based watcher.

**Note**: `/stats` shows session statistics (messages, tool calls, duration, etc.).

## Usage Modes

### Mode 1: Fire-and-Forget (Default)

When the user asks to "show statistics", "session stats", "metrics":

```bash
.claude/scripts/signal-helper.sh stats
```

### Mode 2: With Auto-Resume

When Jarvis needs to check stats AND continue working automatically:

```bash
.claude/scripts/signal-helper.sh with-resume /stats "" "continue" 3
```

Parameters:
- Command: `/stats`
- Args: `""` (none)
- Resume message: `"continue"` (sent after stats display)
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

### Example 1: Simple stats check

User: "Show me the session statistics"

Response:
1. Run: `.claude/scripts/signal-helper.sh stats`
2. Say: "Signal sent for /stats. Statistics will appear shortly."
3. Continue with any other pending work

### Example 2: Stats check with auto-resume

User: "Check stats and keep working"

Response:
1. Run: `.claude/scripts/signal-helper.sh with-resume /stats "" "continue" 3`
2. Say: "Signal sent for /stats with auto-resume."
3. Watcher sends /stats, waits 3s, then sends "continue"

## Related

- `/cost` — API cost information
- `/usage` — Token budget limits
- `self-monitoring-commands.md` — Full pattern documentation
