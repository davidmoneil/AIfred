---
description: Autonomously execute /bashes via signal-based watcher
allowed-tools: Bash(.claude/scripts/*)
---

# Auto Bashes

Trigger the built-in `/bashes` command autonomously via the signal-based watcher.

**Note**: `/bashes` shows running bash processes/background shells.

## Usage Modes

### Mode 1: Fire-and-Forget (Default)

When the user asks to "show bash processes", "running commands", "background shells":

```bash
.claude/scripts/signal-helper.sh bashes
```

### Mode 2: With Auto-Resume

When Jarvis needs to check running processes AND continue working automatically:

```bash
.claude/scripts/signal-helper.sh with-resume /bashes "" "continue" 3
```

Parameters:
- Command: `/bashes`
- Args: `""` (none)
- Resume message: `"continue"` (sent after bashes display)
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

### Example 1: Simple bashes check

User: "What bash commands are running?"

Response:
1. Run: `.claude/scripts/signal-helper.sh bashes`
2. Say: "Signal sent for /bashes. Running processes will appear shortly."
3. Continue with any other pending work

### Example 2: Bashes check with auto-resume

When Jarvis checks for background tasks as part of cleanup:
1. Run: `.claude/scripts/signal-helper.sh with-resume /bashes "" "continue" 3`
2. Say: "Signal sent for /bashes with auto-resume."
3. Watcher sends /bashes, waits 3s, then sends "continue"

## Related

- `self-monitoring-commands.md` — Full pattern documentation
