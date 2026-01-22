---
description: Autonomously execute /usage via signal-based watcher
allowed-tools: Bash(.claude/scripts/*)
---

# Auto Usage

Trigger the built-in `/usage` command autonomously via the signal-based watcher.

## Usage Modes

### Mode 1: Fire-and-Forget (Default)

When the user asks to "show usage", "token usage", "how much context used":

```bash
.claude/scripts/signal-helper.sh usage
```

### Mode 2: With Auto-Resume

When you need to check usage AND continue working automatically after:

```bash
.claude/scripts/signal-helper.sh with-resume /usage "" "continue" 3
```

Parameters:
- Command: `/usage`
- Args: `""` (none)
- Resume message: `"continue"` (sent after /usage completes)
- Resume delay: `3` (seconds to wait before sending resume message)

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

### Example 1: Simple usage check

User: "How much of my context have I used?"

Response:
1. Run: `.claude/scripts/signal-helper.sh usage`
2. Say: "Signal sent for /usage. Token usage will appear shortly."
3. Continue with any other pending work

### Example 2: Usage check with auto-resume

User: "Check usage and continue working"

Response:
1. Run: `.claude/scripts/signal-helper.sh with-resume /usage "" "continue" 3`
2. Say: "Signal sent for /usage with auto-resume. Will continue automatically after display."
3. Watcher sends /usage, waits 3s, then sends "continue" to resume work
