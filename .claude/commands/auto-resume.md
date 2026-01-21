---
description: Autonomously execute /resume via signal-based watcher
allowed-tools: Bash(.claude/scripts/*)
---

# Auto Resume

Trigger the built-in `/resume` command autonomously via the signal-based watcher.

## Usage

When the user asks to "resume session", "continue from checkpoint", "restore previous session", or similar:

### Step 1: Extract Session ID (optional)

If user specifies a session, extract the identifier.

Examples:
- "resume the previous session" → session: "" (most recent)
- "resume session abc123" → session: "abc123"
- "continue from yesterday's checkpoint" → session: "" (let user pick)

### Step 2: Create Signal

```bash
# Resume most recent
source .claude/scripts/signal-helper.sh && signal_resume

# Resume specific session
source .claude/scripts/signal-helper.sh && signal_resume "SESSION_ID"
```

### Step 3: Inform User

```
Signal sent for /resume. The watcher will execute it in ~2 seconds.

Claude Code will show available sessions to resume.
```

## Prerequisites

- Watcher must be running (check with `watcher_status`)
- Session ID is optional - if not provided, shows session picker

## Example

User: "Resume the previous session"

Response:
1. Run: `source .claude/scripts/signal-helper.sh && signal_resume`
2. Say: "Signal sent for /resume. Available sessions will be displayed for selection."
