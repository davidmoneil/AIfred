---
description: Autonomously execute /usage via signal-based watcher
allowed-tools: Bash(.claude/scripts/*)
---

# Auto Usage

Trigger the built-in `/usage` command autonomously via the signal-based watcher.

## Usage

When the user asks to "show usage", "token usage", "how much context used", or similar:

### Create Signal

```bash
source .claude/scripts/signal-helper.sh && signal_usage
```

### Inform User

```
Signal sent for /usage. The watcher will execute it in ~2 seconds.

Token usage information will be displayed.
```

## Example

User: "How much of my context have I used?"

Response:
1. Run: `source .claude/scripts/signal-helper.sh && signal_usage`
2. Say: "Signal sent for /usage. Token usage stats will be displayed momentarily."
