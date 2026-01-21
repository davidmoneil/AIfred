---
description: Autonomously execute /rename via signal-based watcher
allowed-tools: Bash(.claude/scripts/*)
---

# Auto Rename

Trigger the built-in `/rename` command autonomously via the signal-based watcher.

## Usage

When the user asks to "rename session", "call this session X", "name this chat", or similar:

### Step 1: Extract Session Name (required)

The name argument is required. Extract from user request.

Examples:
- "rename this to Feature Implementation" → name: "Feature Implementation"
- "call this session Bug Fix Sprint" → name: "Bug Fix Sprint"
- "just rename it" → ASK: "What would you like to name this session?"

### Step 2: Create Signal

```bash
source .claude/scripts/signal-helper.sh && signal_rename "SESSION_NAME_HERE"
```

Replace `SESSION_NAME_HERE` with the extracted name.

### Step 3: Inform User

```
Signal sent for /rename "SESSION_NAME". The watcher will execute it in ~2 seconds.

The session will be renamed to: SESSION_NAME
```

## Prerequisites

- Watcher must be running (check with `watcher_status`)
- Name argument is REQUIRED - ask user if not provided

## Example

User: "Rename this session to Autonomous Commands Implementation"

Response:
1. Run: `source .claude/scripts/signal-helper.sh && signal_rename "Autonomous Commands Implementation"`
2. Say: "Signal sent for /rename. Session will be renamed to 'Autonomous Commands Implementation'."
