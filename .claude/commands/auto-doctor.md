---
description: Autonomously execute /doctor via signal-based watcher
allowed-tools: Bash(.claude/scripts/*)
---

# Auto Doctor

Trigger the built-in `/doctor` command autonomously via the signal-based watcher.

**Note**: `/doctor` checks Claude Code installation and shows diagnostics.

## Usage Modes

### Mode 1: Fire-and-Forget (Default)

When the user asks to "run doctor", "health check", "diagnose issues":

```bash
.claude/scripts/signal-helper.sh doctor
```

### Mode 2: With Auto-Resume

When Jarvis needs to run diagnostics AND continue working automatically:

```bash
.claude/scripts/signal-helper.sh with-resume /doctor "" "continue" 5
```

Parameters:
- Command: `/doctor`
- Args: `""` (none)
- Resume message: `"continue"` (sent after diagnostics display)
- Resume delay: `5` (seconds - doctor output can be long)

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

### Example 1: Simple doctor check

User: "Run the doctor check"

Response:
1. Run: `.claude/scripts/signal-helper.sh doctor`
2. Say: "Signal sent for /doctor. Diagnostics will run shortly."
3. Continue with any other pending work

### Example 2: Doctor check with auto-resume (maintenance workflow)

When Jarvis autonomously checks system health:
1. Run: `.claude/scripts/signal-helper.sh with-resume /doctor "" "continue" 5`
2. Say: "Signal sent for /doctor with auto-resume."
3. Watcher sends /doctor, waits 5s, then sends "continue"
4. Jarvis can process diagnostic output from system-reminder

## Related

- `/tooling-health` — Jarvis-specific health check
- `self-monitoring-commands.md` — Full pattern documentation
