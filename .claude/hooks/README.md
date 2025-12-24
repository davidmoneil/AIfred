# AIfred Hooks

Automatic behaviors that run before/after tool executions.

---

## Installed Hooks

| Hook | Event | Purpose |
|------|-------|---------|
| `audit-logger.js` | PreToolUse | Log all tool executions |
| `session-tracker.js` | Notification | Track session lifecycle |
| `session-exit-enforcer.js` | PostToolUse | Track activity for exit |
| `secret-scanner.js` | PreToolUse | Block commits with secrets |
| `context-reminder.js` | PostToolUse | Prompt for documentation |
| `docker-health-check.js` | PostToolUse | Verify container health |

---

## Hook Types

| Type | When | Use For |
|------|------|---------|
| `PreToolUse` | Before tool runs | Validation, logging, blocking |
| `PostToolUse` | After tool completes | Verification, cleanup, notifications |
| `Notification` | Session events | Lifecycle tracking |

---

## Creating New Hooks

```javascript
module.exports = {
  name: 'my-hook',
  description: 'What this hook does',
  event: 'PreToolUse',  // or PostToolUse, Notification

  async handler(context) {
    const { tool, parameters } = context;

    // Your logic here

    return { proceed: true };  // false to block
  }
};
```

---

## Configuration

### Audit Verbosity

```bash
export CLAUDE_AUDIT_VERBOSITY=standard  # minimal | standard | full
```

### Session Name

```bash
echo "My Session" > .claude/logs/.current-session
```

---

## Logs

- Audit log: `.claude/logs/audit.jsonl`
- Session activity: `.claude/logs/.session-activity`

---

*AIfred Hooks v1.0*
