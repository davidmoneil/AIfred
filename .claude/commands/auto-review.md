---
description: Autonomously execute /review via signal-based watcher
allowed-tools: Bash(.claude/scripts/*)
---

# Auto Review

Trigger the built-in `/review` command autonomously via the signal-based watcher.

## Usage

When the user asks to "review code", "code review", "review changes", or similar:

### Create Signal

```bash
source .claude/scripts/signal-helper.sh && signal_review
```

### Inform User

```
Signal sent for /review. The watcher will execute it in ~2 seconds.

Code review will begin.
```

## Example

User: "Can you review my code changes?"

Response:
1. Run: `source .claude/scripts/signal-helper.sh && signal_review`
2. Say: "Signal sent for /review. Code review will begin momentarily."
