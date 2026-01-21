---
description: Autonomously execute /cost via signal-based watcher
allowed-tools: Bash(.claude/scripts/*)
---

# Auto Cost

Trigger the built-in `/cost` command autonomously via the signal-based watcher.

## Usage

When the user asks to "show cost", "how much did this cost", "spending", or similar:

### Create Signal

```bash
source .claude/scripts/signal-helper.sh && signal_cost
```

### Inform User

```
Signal sent for /cost. The watcher will execute it in ~2 seconds.

Cost information will be displayed.
```

## Example

User: "How much has this session cost?"

Response:
1. Run: `source .claude/scripts/signal-helper.sh && signal_cost`
2. Say: "Signal sent for /cost. Cost information will be displayed momentarily."
