---
description: Autonomously execute /export via signal-based watcher
allowed-tools: Bash(.claude/scripts/*)
---

# Auto Export

Trigger the built-in `/export` command autonomously via the signal-based watcher.

## Usage

When the user asks to "export conversation", "save chat", "download transcript", or similar:

### Step 1: Extract Filename (optional)

If user specifies a filename, extract it. Otherwise use default.

Examples:
- "export to my-session.md" → filename: "my-session.md"
- "just export the conversation" → filename: "" (use default)

### Step 2: Create Signal

```bash
source .claude/scripts/signal-helper.sh && signal_export "FILENAME_HERE"
```

Or for default filename:
```bash
source .claude/scripts/signal-helper.sh && signal_export
```

### Step 3: Inform User

```
Signal sent for /export. The watcher will execute it in ~2 seconds.

The conversation will be exported to the specified file.
```

## Example

User: "Export this conversation to feature-work.md"

Response:
1. Run: `source .claude/scripts/signal-helper.sh && signal_export "feature-work.md"`
2. Say: "Signal sent for /export. Conversation will be exported to feature-work.md."
