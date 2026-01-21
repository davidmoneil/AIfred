---
description: Autonomously execute /stats via signal-based watcher
allowed-tools: Bash(.claude/scripts/*)
---

# Auto Stats

Trigger the built-in `/stats` command autonomously via the signal-based watcher.

## Usage

When the user asks to "show statistics", "session stats", "metrics", or similar:

### Create Signal

```bash
source .claude/scripts/signal-helper.sh && signal_stats
```

### Inform User

```
Signal sent for /stats. The watcher will execute it in ~2 seconds.

Session statistics will be displayed.
```

## Example

User: "Show me the session statistics"

Response:
1. Run: `source .claude/scripts/signal-helper.sh && signal_stats`
2. Say: "Signal sent for /stats. Statistics will be displayed momentarily."
