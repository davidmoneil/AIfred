---
description: Autonomously execute /status via signal-based watcher
allowed-tools: Bash(.claude/scripts/*)
---

# Auto Status

Trigger the built-in `/status` command autonomously via the signal-based watcher.

## Usage

When the user asks to "show status", "session status", "what's the status", or similar:

### Create Signal

```bash
source .claude/scripts/signal-helper.sh && signal_status
```

### Inform User

```
Signal sent for /status. The watcher will execute it in ~2 seconds.

Session status information will be displayed.
```

## Example

User: "Show me the session status"

Response:
1. Run: `source .claude/scripts/signal-helper.sh && signal_status`
2. Say: "Signal sent for /status. Status information will be displayed momentarily."
