---
description: Signal the auto-clear watcher to send /clear command
allowed-tools: Bash(.claude/scripts/*)
---

# Trigger Clear

This command signals the auto-clear-watcher to send the `/clear` command automatically.

**IMPORTANT**: This only works if `auto-clear-watcher.sh` is running in another terminal.

## Usage

When instructed to "run /clear" or "clear the conversation", execute:

```bash
# Create signal file for watcher
echo "$(date -u +%Y-%m-%dT%H:%M:%SZ)" > .claude/context/.auto-clear-signal
```

Then inform the user:

```
Signal sent to auto-clear watcher.

If watcher is running: /clear will execute in ~2 seconds
If watcher is NOT running: Please type /clear manually

To start the watcher (in another terminal):
  .claude/scripts/auto-clear-watcher.sh
```

## How It Works

1. This command creates a signal file
2. The `auto-clear-watcher.sh` script (running in separate terminal) detects it
3. Watcher sends `/clear` keystroke via AppleScript (macOS) or xdotool (Linux)
4. Conversation clears, SessionStart hook loads checkpoint, work resumes

## Prerequisites

Start the watcher before using this command:

```bash
# In a separate terminal window
cd /Users/aircannon/Claude/Jarvis
.claude/scripts/auto-clear-watcher.sh
```

The watcher must be running for automatic `/clear` to work.
