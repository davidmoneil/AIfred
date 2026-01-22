---
description: Autonomously execute /security-review via signal-based watcher
allowed-tools: Bash(.claude/scripts/*)
---

# Auto Security Review

Trigger the built-in `/security-review` command autonomously via the signal-based watcher.

**Note**: `/security-review` performs security review of pending changes.

## Usage Modes

### Mode 1: Fire-and-Forget (Default)

When the user asks to "security review", "security check", "vulnerability scan":

```bash
.claude/scripts/signal-helper.sh security-review
```

### Mode 2: With Auto-Resume

When Jarvis needs to run security review AND continue working automatically:

```bash
.claude/scripts/signal-helper.sh with-resume /security-review "" "continue" 10
```

Parameters:
- Command: `/security-review`
- Args: `""` (none)
- Resume message: `"continue"` (sent after review completes)
- Resume delay: `10` (seconds - security review takes longer)

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

### Example 1: Simple security review

User: "Run a security review on my code"

Response:
1. Run: `.claude/scripts/signal-helper.sh security-review`
2. Say: "Signal sent for /security-review. Security analysis will begin shortly."
3. Continue with any other pending work

### Example 2: Security review with auto-resume

When Jarvis autonomously reviews security as part of a workflow:
1. Run: `.claude/scripts/signal-helper.sh with-resume /security-review "" "continue" 10`
2. Say: "Signal sent for /security-review with auto-resume."
3. Watcher sends /security-review, waits 10s, then sends "continue"

## Related

- `/review` — General code review
- `self-monitoring-commands.md` — Full pattern documentation
