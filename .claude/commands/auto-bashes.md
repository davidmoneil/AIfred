---
description: Autonomously execute /bashes via signal-based watcher
allowed-tools: Bash(.claude/scripts/*)
---

# Auto Bashes

Trigger the built-in `/bashes` command autonomously via the signal-based watcher.

## Usage

When the user asks to "show bash processes", "running commands", "background shells", or similar:

### Create Signal

```bash
source .claude/scripts/signal-helper.sh && signal_bashes
```

### Inform User

```
Signal sent for /bashes. The watcher will execute it in ~2 seconds.

Running bash processes will be listed.
```

## Example

User: "What bash commands are running?"

Response:
1. Run: `source .claude/scripts/signal-helper.sh && signal_bashes`
2. Say: "Signal sent for /bashes. Running processes will be displayed momentarily."
