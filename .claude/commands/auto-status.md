---
description: Autonomously execute /status via signal-based watcher
allowed-tools: Bash(.claude/scripts/*)
---

# Auto Status

Trigger the built-in `/status` command autonomously via the signal-based watcher.

**NAMESPACE NOTE**: In Jarvis, `/status` is overridden by the custom status skill that shows autonomic system status. To access the native Claude Code settings panel, use `/auto-settings` instead.

## Usage Modes

### Mode 1: Fire-and-Forget (Default)

When the user asks to "show status", "session status", "what's the status":

```bash
.claude/scripts/signal-helper.sh status
```

**Note**: This will show the Jarvis autonomic status, not the native settings panel.

### Mode 2: With Auto-Resume

When Jarvis needs to check status AND continue working automatically:

```bash
.claude/scripts/signal-helper.sh with-resume /status "" "continue" 3
```

Parameters:
- Command: `/status`
- Args: `""` (none)
- Resume message: `"continue"` (sent after status displays)
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

### Example 1: Simple status check

User: "Show me the session status"

Response:
1. Run: `.claude/scripts/signal-helper.sh status`
2. Say: "Signal sent for /status. Status will appear shortly."
3. Continue with any other pending work

### Example 2: Status check with auto-resume

When Jarvis checks status as part of a workflow:
1. Run: `.claude/scripts/signal-helper.sh with-resume /status "" "continue" 3`
2. Say: "Signal sent for /status with auto-resume."
3. Watcher sends /status, waits 3s, then sends "continue"

## Related

- `/auto-settings` — Native Claude Code settings panel (version, model, account)
- `self-monitoring-commands.md` — Full pattern documentation
