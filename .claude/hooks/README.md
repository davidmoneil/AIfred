# Jarvis Hooks

Automatic behaviors that run before/after tool executions.

---

## Installed Hooks

### Guardrail Hooks (PR-4a)

| Hook | Event | Purpose |
|------|-------|---------|
| `workspace-guard.js` | PreToolUse | **Block** writes to AIfred baseline and forbidden paths |
| `dangerous-op-guard.js` | PreToolUse | **Block** destructive shell commands |
| `permission-gate.js` | UserPromptSubmit | **Soft gate** policy-crossing operations |

### Security Hooks

| Hook | Event | Purpose |
|------|-------|---------|
| `secret-scanner.js` | PreToolUse | Block commits with secrets |

### Observability Hooks

| Hook | Event | Purpose |
|------|-------|---------|
| `audit-logger.js` | PreToolUse | Log all tool executions |
| `session-tracker.js` | Notification | Track session lifecycle |
| `session-exit-enforcer.js` | PostToolUse | Track activity for exit |
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

## Guardrail Hooks (PR-4a)

### workspace-guard.js

Enforces workspace boundaries by blocking write operations to protected paths:

**Blocked (always)**:
- Any Write/Edit to `/Users/aircannon/Claude/AIfred/**` (read-only baseline)
- Operations to forbidden system paths (`/`, `/etc`, `/usr`, `~/.ssh`, etc.)

**Warned (but allowed)**:
- Write/Edit operations outside Jarvis workspace (may be registered projects)

**Behavior**: Fail-open — if the hook encounters an error loading config, it logs a `[!] HIGH` warning but allows the operation to proceed.

### dangerous-op-guard.js

Blocks dangerous shell commands that could cause harm:

**Blocked patterns**:
- `rm -rf /` or similar root deletions
- `sudo rm -rf` anywhere sensitive
- `mkfs` (filesystem formatting)
- `dd` to disk devices
- Force push to main/master
- Fork bombs

**Warned patterns** (allowed but flagged):
- `rm -r` (recursive delete)
- `git reset --hard`
- `git clean -fd`
- Recursive chmod/chown

**Behavior**: Fail-open — on pattern matching errors, logs warning but allows operation.

### permission-gate.js

Soft-gates policy-crossing operations by injecting system reminders:

**Gated patterns**:
- Operations mentioning AIfred baseline
- Force push requests
- Mass deletion requests
- Protected branch operations (main/master)
- Credential/secret handling

**Behavior**: Does NOT block — adds `<permission-gate>` system reminders suggesting Claude use AskUserQuestion to confirm intent with the user.

---

*Jarvis Hooks v1.2.1 - Added guardrail hooks (PR-4a)*
