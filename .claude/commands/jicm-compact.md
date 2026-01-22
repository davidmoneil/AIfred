---
description: JICM - Trigger native /compact via signal-based watcher
allowed-tools: Bash(.claude/scripts/*)
---

# JICM Compact

Trigger the built-in `/compact` command autonomously via the signal-based watcher.

> **Note**: Renamed from `/auto-compact` to avoid conflict with native Claude Code command.

## Usage Modes

### Mode 1: Fire-and-Forget (Default)

When the user asks to "compact context", "reduce tokens", "summarize conversation":

**Step 1**: Extract focus instructions (if provided)
- "compact focusing on the code changes" → "Focus on code changes"
- "just compact" → "" (empty)

**Step 2**: Send signal
```bash
.claude/scripts/signal-helper.sh compact "INSTRUCTIONS_HERE"
```

### Mode 2: With Auto-Resume

When Jarvis needs to compact AND continue working automatically:

```bash
.claude/scripts/signal-helper.sh with-resume /compact "Focus on recent work" "continue" 5
```

Parameters:
- Command: `/compact`
- Args: Focus instructions (or empty string)
- Resume message: `"continue"` (sent after compact completes)
- Resume delay: `5` (seconds - compact takes longer)

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

### Example 1: Simple compaction

User: "Compact the context"

Response:
1. Run: `.claude/scripts/signal-helper.sh compact ""`
2. Say: "Signal sent for /compact."
3. Continue with any other pending work

### Example 2: Focused compaction with auto-resume

User: "Compact focusing on code changes and continue"

Response:
1. Run: `.claude/scripts/signal-helper.sh with-resume /compact "Focus on code changes" "continue" 5`
2. Say: "Signal sent for /compact with auto-resume."
3. Watcher compacts, waits 5s, then sends "continue"

## Related

- `/context` — Check context usage before compacting
- `self-monitoring-commands.md` — Full pattern documentation
