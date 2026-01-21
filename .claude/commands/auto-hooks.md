---
description: Autonomously execute /hooks via signal-based watcher
allowed-tools: Bash(.claude/scripts/*)
---

# Auto Hooks

Trigger the built-in `/hooks` command autonomously via the signal-based watcher.

## Usage

When the user asks to "list hooks", "show hooks", "registered hooks", or similar:

### Create Signal

```bash
source .claude/scripts/signal-helper.sh && signal_hooks
```

### Inform User

```
Signal sent for /hooks. The watcher will execute it in ~2 seconds.

Registered hooks will be listed.
```

## Example

User: "What hooks are registered?"

Response:
1. Run: `source .claude/scripts/signal-helper.sh && signal_hooks`
2. Say: "Signal sent for /hooks. Hook list will be displayed momentarily."
