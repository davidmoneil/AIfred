---
description: Autonomously execute /context via signal-based watcher
allowed-tools: Bash(.claude/scripts/*)
---

# Auto Context

Trigger the built-in `/context` command autonomously via the signal-based watcher.

## Usage

When the user asks to "show context", "context info", "what's in context", or similar:

### Create Signal

```bash
source .claude/scripts/signal-helper.sh && signal_context
```

### Inform User

```
Signal sent for /context. The watcher will execute it in ~2 seconds.

Context information will be displayed.
```

## Example

User: "What's currently in my context?"

Response:
1. Run: `source .claude/scripts/signal-helper.sh && signal_context`
2. Say: "Signal sent for /context. Context details will be displayed momentarily."
