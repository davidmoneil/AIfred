---
description: Autonomously execute /release-notes via signal-based watcher
allowed-tools: Bash(.claude/scripts/*)
---

# Auto Release Notes

Trigger the built-in `/release-notes` command autonomously via the signal-based watcher.

## Usage

When the user asks to "show release notes", "what's new", "changelog", or similar:

### Create Signal

```bash
source .claude/scripts/signal-helper.sh && signal_release_notes
```

### Inform User

```
Signal sent for /release-notes. The watcher will execute it in ~2 seconds.

Release notes will be displayed.
```

## Example

User: "What's new in Claude Code?"

Response:
1. Run: `source .claude/scripts/signal-helper.sh && signal_release_notes`
2. Say: "Signal sent for /release-notes. Release notes will be displayed momentarily."
