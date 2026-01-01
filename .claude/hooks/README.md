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
| `memory-maintenance.js` | PostToolUse | Track Memory MCP entity access for pruning |

---

## Hook Types

| Type | When | Use For |
|------|------|---------|
| `PreToolUse` | Before tool runs | Validation, logging, blocking |
| `PostToolUse` | After tool completes | Verification, cleanup, notifications |
| `Notification` | Session events | Lifecycle tracking |

---

## Memory Maintenance Hook

The `memory-maintenance.js` hook automatically tracks when Memory MCP entities are accessed:

**Tracked Data** (in `.claude/agents/memory/entity-metadata.json`):
- `firstAccessed`: Date entity was first retrieved
- `lastAccessed`: Most recent access date
- `accessCount`: Total number of times accessed

**Use Cases**:
- Identify stale entities (not accessed in 90+ days)
- Prioritize frequently-used entities
- Enable intelligent pruning via `memory-prune.sh`

---

## Creating New Hooks

```javascript
module.exports = async (context) => {
  const { tool, tool_input, result } = context;

  // Your logic here

  // Return nothing to continue, or throw to block
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
- Entity metadata: `.claude/agents/memory/entity-metadata.json`

---

*AIfred Hooks v1.1 - Added memory maintenance tracking*
