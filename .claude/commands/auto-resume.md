---
description: Autonomously execute /resume via signal-based watcher
allowed-tools: Bash(.claude/scripts/*)
---

# Auto Resume

Trigger the built-in `/resume` command autonomously via the signal-based watcher.

**Note**: `/resume` restores a previous conversation. Without a session ID, opens picker.

## Usage Modes

### Mode 1: Fire-and-Forget (Default)

When the user asks to "resume session", "continue from checkpoint", "restore previous":

**Without session ID** (opens picker):
```bash
.claude/scripts/signal-helper.sh resume
```

**With session ID**:
```bash
.claude/scripts/signal-helper.sh resume "SESSION_ID"
```

### Mode 2: With Auto-Resume

When Jarvis needs to resume a session AND continue working automatically:

```bash
.claude/scripts/signal-helper.sh with-resume /resume "SESSION_ID" "continue" 5
```

Parameters:
- Command: `/resume`
- Args: Session ID (optional - empty opens picker)
- Resume message: `"continue"` (sent after resume completes)
- Resume delay: `5` (seconds - resume can take longer)

## CRITICAL: Fire-and-Forget Pattern

**DO NOT:**
- Verify the signal was created
- Check watcher status
- Wait for the command to execute
- Block on any follow-up checks

**DO:**
- Send the signal
- Inform the user briefly
- **CONTINUE with other work immediately**

The signal system is asynchronous. Trust the watcher.

## Examples

### Example 1: Resume most recent (picker)

User: "Resume the previous session"

Response:
1. Run: `.claude/scripts/signal-helper.sh resume`
2. Say: "Signal sent for /resume. Session picker will appear shortly."
3. Continue with any other pending work

### Example 2: Resume specific session

User: "Resume session abc123"

Response:
1. Run: `.claude/scripts/signal-helper.sh resume "abc123"`
2. Say: "Signal sent for /resume session abc123."
3. Continue with any other pending work

### Example 3: Resume with auto-resume (automated workflow)

When Jarvis auto-resumes after a checkpoint:
1. Run: `.claude/scripts/signal-helper.sh with-resume /resume "" "continue" 5`
2. Watcher sends /resume (opens picker), user selects, waits 5s, then sends "continue"

## Related

- `/checkpoint` — Save session state
- `self-monitoring-commands.md` — Full pattern documentation
