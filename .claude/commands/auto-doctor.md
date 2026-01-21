---
description: Autonomously execute /doctor via signal-based watcher
allowed-tools: Bash(.claude/scripts/*)
---

# Auto Doctor

Trigger the built-in `/doctor` command autonomously via the signal-based watcher.

## Usage

When the user asks to "run doctor", "health check", "diagnose issues", or similar:

### Create Signal

```bash
source .claude/scripts/signal-helper.sh && signal_doctor
```

### Inform User

```
Signal sent for /doctor. The watcher will execute it in ~2 seconds.

Health diagnostics will be run.
```

## Example

User: "Run the doctor check"

Response:
1. Run: `source .claude/scripts/signal-helper.sh && signal_doctor`
2. Say: "Signal sent for /doctor. Diagnostics will run momentarily."
