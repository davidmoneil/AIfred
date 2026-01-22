---
description: Autonomously execute /review via signal-based watcher
allowed-tools: Bash(.claude/scripts/*)
---

# Auto Review

Trigger the built-in `/review` command autonomously via the signal-based watcher.

**Note**: `/review` initiates a code review on current files/changes.

## Usage Modes

### Mode 1: Fire-and-Forget (Default)

When the user asks to "review code", "code review", "review changes":

```bash
.claude/scripts/signal-helper.sh review
```

### Mode 2: With Auto-Resume

When Jarvis needs to run code review AND continue working automatically:

```bash
.claude/scripts/signal-helper.sh with-resume /review "" "continue" 10
```

Parameters:
- Command: `/review`
- Args: `""` (none)
- Resume message: `"continue"` (sent after review completes)
- Resume delay: `10` (seconds - review takes longer)

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

### Example 1: Simple code review

User: "Can you review my code changes?"

Response:
1. Run: `.claude/scripts/signal-helper.sh review`
2. Say: "Signal sent for /review. Code review will begin shortly."
3. Continue with any other pending work

### Example 2: Code review with auto-resume

When Jarvis autonomously reviews code as part of a workflow:
1. Run: `.claude/scripts/signal-helper.sh with-resume /review "" "continue" 10`
2. Say: "Signal sent for /review with auto-resume."
3. Watcher sends /review, waits 10s, then sends "continue"

## Related

- `/security-review` — Security-focused review
- `pr-review-toolkit` plugin — Comprehensive PR review
- `self-monitoring-commands.md` — Full pattern documentation
