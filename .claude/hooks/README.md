# Jarvis Hooks

Automatic behaviors that run before/after tool executions.

**Last Updated**: 2026-01-06
**Total Hooks**: 18

---

## Installed Hooks

### Lifecycle Hooks

| Hook | Event | Purpose |
|------|-------|---------|
| `session-start.js` | SessionStart | Auto-load context on startup |
| `session-stop.js` | Stop | Desktop notification when done |
| `subagent-stop.js` | SubagentStop | Agent chaining & activity logging |
| `pre-compact.js` | PreCompact | Preserve context before compaction |
| `self-correction-capture.js` | UserPromptSubmit | Detect corrections, save lessons |
| `worktree-manager.js` | PostToolUse | Track worktrees, warn cross-access |

### Guardrail Hooks (Jarvis-specific, PR-4a)

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

### Documentation Hooks

| Hook | Event | Purpose |
|------|-------|---------|
| `doc-sync-trigger.js` | PostToolUse | Track code changes, suggest sync after 5+ |

### Utility Hooks

| Hook | Event | Purpose |
|------|-------|---------|
| `project-detector.js` | UserPromptSubmit | Auto-detect GitHub URLs and "new project" requests |

---

## Hook Types

| Type | When | Use For |
|------|------|---------|
| `SessionStart` | When Claude starts | Auto-load context, initialize state |
| `UserPromptSubmit` | User submits prompt | Correction detection, validation |
| `PreToolUse` | Before tool runs | Validation, logging, blocking |
| `PostToolUse` | After tool completes | Verification, cleanup, notifications |
| `Notification` | Session events | Lifecycle tracking |
| `Stop` | When Claude ends | Notifications, cleanup |
| `SubagentStop` | Agent completes | Agent chaining, orchestration |
| `PreCompact` | Before compaction | Preserve critical state |

---

## Lifecycle Hooks Details

### session-start.js
Auto-loads context when Claude Code starts:
- Current git branch and uncommitted changes count
- Session state (truncated to 2000 chars)
- Current priorities (truncated to 1500 chars)
- AIfred baseline status check

**Result**: No more manual "read session-state.md" at session start.

### session-stop.js
Sends desktop notification when session ends:
- ✅ "Jarvis Session Complete" - Normal completion
- ⚠️ "Jarvis Session Stopped" - Error occurred
- 🛑 "Jarvis Session Cancelled" - User cancelled

**macOS**: Uses osascript (automatic)
**Linux requirement**: `sudo apt install libnotify-bin`

### subagent-stop.js
Handles spawned agent completion:
- Logs to `.claude/logs/agent-activity.jsonl`
- Detects HIGH/CRITICAL issues in output
- Suggests next actions based on agent type

### pre-compact.js
Preserves critical context before compaction:
- Key sections from session-state.md
- Recent blockers
- Compaction timestamp
- Logs to `.claude/logs/compaction-history.jsonl`

### self-correction-capture.js
Detects when user corrects Claude:
- Patterns: "No, actually...", "That's wrong", "You should have..."
- Severity levels: HIGH, MEDIUM, LOW
- Logs to `.claude/logs/corrections.jsonl`
- Prompts to save lessons for HIGH/MEDIUM severity

### worktree-manager.js
Tracks git worktree context:
- Detects worktree vs main repo
- Warns about cross-worktree file access
- Logs state to `.claude/logs/.worktree-state.json`

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

## Documentation Sync Trigger

The `doc-sync-trigger.js` hook automatically tracks code changes:

**How It Works**:
1. Monitors Write/Edit operations on significant files
2. Tracks changes in `.claude/logs/.doc-sync-state.json`
3. After 5+ changes in 24 hours, suggests `/agent memory-bank-synchronizer`
4. 4-hour cooldown between suggestions

**Significant Files**:
- `.claude/commands/`, `.claude/agents/`, `.claude/hooks/`, `.claude/skills/`
- `projects/`, `scripts/`, `docker/`
- `docker-compose*.yaml`, `external-sources/`

**Related**: @.claude/agents/memory-bank-synchronizer.md

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
module.exports = {
  name: 'hook-name',
  description: 'What this hook does',
  event: 'PreToolUse', // or PostToolUse, SessionStart, etc.

  async handler(context) {
    const { tool, parameters, result } = context;

    // Your logic here

    // Return { proceed: true } to continue
    // Return { block: true, message: "reason" } to block
    return { proceed: true };
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
- Entity metadata: `.claude/agents/memory/entity-metadata.json`
- Agent activity: `.claude/logs/agent-activity.jsonl`
- Corrections: `.claude/logs/corrections.jsonl`
- Doc sync state: `.claude/logs/.doc-sync-state.json`
- Worktree state: `.claude/logs/.worktree-state.json`
- Compaction history: `.claude/logs/compaction-history.jsonl`

---

*Jarvis Hooks v1.4.0 - Added lifecycle hooks and doc-sync from AIfred baseline af66364*
