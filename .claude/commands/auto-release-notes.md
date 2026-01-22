---
description: Autonomously execute /release-notes via signal-based watcher
allowed-tools: Bash(.claude/scripts/*)
---

# Auto Release Notes

Trigger the built-in `/release-notes` command autonomously via the signal-based watcher.

**Note**: `/release-notes` shows Claude Code release notes/changelog.

## Usage Modes

### Mode 1: Fire-and-Forget (Default)

When the user asks to "show release notes", "what's new", "changelog":

```bash
.claude/scripts/signal-helper.sh release-notes
```

### Mode 2: With Auto-Resume

When Jarvis needs to check release notes AND continue working automatically:

```bash
.claude/scripts/signal-helper.sh with-resume /release-notes "" "continue" 3
```

Parameters:
- Command: `/release-notes`
- Args: `""` (none)
- Resume message: `"continue"` (sent after notes display)
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

### Example 1: Simple release notes check

User: "What's new in Claude Code?"

Response:
1. Run: `.claude/scripts/signal-helper.sh release-notes`
2. Say: "Signal sent for /release-notes. Release notes will appear shortly."
3. Continue with any other pending work

### Example 2: Release notes with auto-resume

When Jarvis checks for new features as part of R&D:
1. Run: `.claude/scripts/signal-helper.sh with-resume /release-notes "" "continue" 3`
2. Say: "Signal sent for /release-notes with auto-resume."
3. Watcher sends /release-notes, waits 3s, then sends "continue"

## Related

- `/doctor` — Check Claude Code installation
- `self-monitoring-commands.md` — Full pattern documentation
