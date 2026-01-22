---
description: Autonomously execute /todos via signal-based watcher
allowed-tools: Bash(.claude/scripts/*)
---

# Auto Todos

Trigger the built-in `/todos` command autonomously via the signal-based watcher.

**Note**: `/todos` lists current TODO entries tracked by Claude Code.

## Usage Modes

### Mode 1: Fire-and-Forget (Default)

When the user asks to "show todos", "my tasks", "todo list":

```bash
.claude/scripts/signal-helper.sh todos
```

### Mode 2: With Auto-Resume

When Jarvis needs to check todos AND continue working automatically:

```bash
.claude/scripts/signal-helper.sh with-resume /todos "" "continue" 3
```

Parameters:
- Command: `/todos`
- Args: `""` (none)
- Resume message: `"continue"` (sent after todos display)
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

### Example 1: Simple todos check

User: "What's on my todo list?"

Response:
1. Run: `.claude/scripts/signal-helper.sh todos`
2. Say: "Signal sent for /todos. Todo list will appear shortly."
3. Continue with any other pending work

### Example 2: Todos check with auto-resume

User: "Check todos and keep working"

Response:
1. Run: `.claude/scripts/signal-helper.sh with-resume /todos "" "continue" 3`
2. Say: "Signal sent for /todos with auto-resume."
3. Watcher sends /todos, waits 3s, then sends "continue"

## Related

- TodoWrite tool — Programmatic todo management
- `self-monitoring-commands.md` — Full pattern documentation
