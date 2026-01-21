---
description: Autonomously execute /security-review via signal-based watcher
allowed-tools: Bash(.claude/scripts/*)
---

# Auto Security Review

Trigger the built-in `/security-review` command autonomously via the signal-based watcher.

## Usage

When the user asks to "security review", "security check", "vulnerability scan", or similar:

### Create Signal

```bash
source .claude/scripts/signal-helper.sh && signal_security_review
```

### Inform User

```
Signal sent for /security-review. The watcher will execute it in ~2 seconds.

Security review will begin.
```

## Example

User: "Run a security review on my code"

Response:
1. Run: `source .claude/scripts/signal-helper.sh && signal_security_review`
2. Say: "Signal sent for /security-review. Security analysis will begin momentarily."
