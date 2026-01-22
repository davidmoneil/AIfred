---
description: Autonomously execute /export via signal-based watcher
allowed-tools: Bash(.claude/scripts/*)
---

# Auto Export

Trigger the built-in `/export` command autonomously via the signal-based watcher.

**IMPORTANT**: Always pass a filename to avoid opening an interactive menu.

## Usage Modes

### Mode 1: Fire-and-Forget (Default)

When the user asks to "export conversation", "save chat", "download transcript":

**Step 1**: Extract or generate filename
- "export to my-session.md" → filename: "my-session.md"
- "just export" → filename: "session-YYYYMMDD-HHMM.md" (generate)

**Step 2**: Send signal with filename
```bash
.claude/scripts/signal-helper.sh export "FILENAME_HERE"
```

### Mode 2: With Auto-Resume

When Jarvis needs to export AND continue working automatically:

```bash
.claude/scripts/signal-helper.sh with-resume /export "session-$(date +%Y%m%d-%H%M).md" "continue" 3
```

Parameters:
- Command: `/export`
- Args: Filename (REQUIRED - never empty)
- Resume message: `"continue"` (sent after export completes)
- Resume delay: `3` (seconds)

## CRITICAL: Always Pass Filename

**DO NOT** send `/export` without a filename - it will open an interactive menu.

**DO** always generate a filename if user doesn't provide one:
```bash
# Generate timestamp-based filename
.claude/scripts/signal-helper.sh export "session-$(date +%Y%m%d-%H%M).md"
```

## Examples

### Example 1: User-specified filename

User: "Export this conversation to feature-work.md"

Response:
1. Run: `.claude/scripts/signal-helper.sh export "feature-work.md"`
2. Say: "Signal sent for /export. Conversation will be exported to feature-work.md."
3. Continue with any other pending work

### Example 2: Auto-generated filename

User: "Export this conversation"

Response:
1. Run: `.claude/scripts/signal-helper.sh export "session-$(date +%Y%m%d-%H%M).md"`
2. Say: "Signal sent for /export with auto-generated filename."
3. Continue with any other pending work

### Example 3: Export with auto-resume (JICM workflow)

When Jarvis exports conversation before JICM compression:
1. Run: `.claude/scripts/signal-helper.sh with-resume /export "pre-jicm-$(date +%Y%m%d-%H%M).md" "continue" 3`
2. Say: "Signal sent for /export with auto-resume."
3. Watcher exports, waits 3s, then sends "continue"

## Related

- `/compact` — Compress context after export
- `self-monitoring-commands.md` — Full pattern documentation
