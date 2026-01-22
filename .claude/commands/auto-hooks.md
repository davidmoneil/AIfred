---
description: Autonomously execute /hooks via signal-based watcher
allowed-tools: Bash(.claude/scripts/*)
---

# Auto Hooks

Trigger the built-in `/hooks` command autonomously via the signal-based watcher.

**Note**: `/hooks` lists registered hooks in Claude Code.

## Usage Modes

### Mode 1: Fire-and-Forget (Default)

When the user asks to "list hooks", "show hooks", "registered hooks":

```bash
.claude/scripts/signal-helper.sh hooks
```

### Mode 2: With Auto-Resume

When Jarvis needs to check hooks AND continue working automatically:

```bash
.claude/scripts/signal-helper.sh with-resume /hooks "" "continue" 3
```

Parameters:
- Command: `/hooks`
- Args: `""` (none)
- Resume message: `"continue"` (sent after hooks display)
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

### Example 1: Simple hooks check

User: "What hooks are registered?"

Response:
1. Run: `.claude/scripts/signal-helper.sh hooks`
2. Say: "Signal sent for /hooks. Hook list will appear shortly."
3. Continue with any other pending work

### Example 2: Hooks check with auto-resume

When Jarvis audits hook configuration:
1. Run: `.claude/scripts/signal-helper.sh with-resume /hooks "" "continue" 3`
2. Say: "Signal sent for /hooks with auto-resume."
3. Watcher sends /hooks, waits 3s, then sends "continue"

## Related

- `/tooling-health` — Comprehensive health check
- `self-monitoring-commands.md` — Full pattern documentation
