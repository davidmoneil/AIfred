---
description: Autonomously execute /context via signal-based watcher
allowed-tools: Bash(.claude/scripts/*)
---

# Auto Context

Trigger the built-in `/context` command autonomously via the signal-based watcher.

**Note**: `/context` shows CONTEXT WINDOW usage (tokens in conversation), NOT token budget. For budget, use `/usage`.

## Usage Modes

### Mode 1: Fire-and-Forget (Default)

When the user asks to "show context", "context info", "what's in context":

```bash
.claude/scripts/signal-helper.sh context
```

### Mode 2: With Auto-Resume

When Jarvis needs to check context AND continue working automatically (self-monitoring):

```bash
.claude/scripts/signal-helper.sh with-resume /context "" "continue" 3
```

Parameters:
- Command: `/context`
- Args: `""` (none)
- Resume message: `"continue"` (sent after /context completes)
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

### Example 1: Simple context check

User: "What's currently in my context?"

Response:
1. Run: `.claude/scripts/signal-helper.sh context`
2. Say: "Signal sent for /context. Context details will appear shortly."
3. Continue with any other pending work

### Example 2: Context check with auto-resume (self-monitoring)

User: "Check context and continue working"

Response:
1. Run: `.claude/scripts/signal-helper.sh with-resume /context "" "continue" 3`
2. Say: "Signal sent for /context with auto-resume. Will continue automatically."
3. Watcher sends /context, waits 3s, then sends "continue" to resume work

### Example 3: JICM self-monitoring workflow

When Jarvis needs to autonomously check context for JICM decision:
1. Run: `.claude/scripts/signal-helper.sh with-resume /context "" "continue" 3`
2. After resume, evaluate context breakdown in system-reminder
3. Decide if JICM compression is needed based on percentage

## Related

- `/usage` — Token BUDGET (quota), not context window
- `.claude/context/.watcher-status` — Real-time context monitoring
- `self-monitoring-commands.md` — Full pattern documentation
