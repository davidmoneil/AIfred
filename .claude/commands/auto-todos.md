---
description: Autonomously execute /todos via signal-based watcher
allowed-tools: Bash(.claude/scripts/*)
---

# Auto Todos

Trigger the built-in `/todos` command autonomously via the signal-based watcher.

## Usage

When the user asks to "show todos", "my tasks", "todo list", or similar:

### Create Signal

```bash
source .claude/scripts/signal-helper.sh && signal_todos
```

### Inform User

```
Signal sent for /todos. The watcher will execute it in ~2 seconds.

Todo list will be displayed.
```

## Example

User: "What's on my todo list?"

Response:
1. Run: `source .claude/scripts/signal-helper.sh && signal_todos`
2. Say: "Signal sent for /todos. Todo list will be displayed momentarily."
