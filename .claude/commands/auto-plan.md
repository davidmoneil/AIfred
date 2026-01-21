---
description: Autonomously execute /plan via signal-based watcher
allowed-tools: Bash(.claude/scripts/*)
---

# Auto Plan

Trigger the built-in `/plan` command autonomously via the signal-based watcher.

## Usage

When the user asks to "enter plan mode", "plan this", "create implementation plan", or similar:

### Create Signal

```bash
source .claude/scripts/signal-helper.sh && signal_plan
```

### Inform User

```
Signal sent for /plan. The watcher will execute it in ~2 seconds.

Plan mode will be activated.
```

## Example

User: "Let's plan out this feature"

Response:
1. Run: `source .claude/scripts/signal-helper.sh && signal_plan`
2. Say: "Signal sent for /plan. Plan mode will be activated momentarily."
