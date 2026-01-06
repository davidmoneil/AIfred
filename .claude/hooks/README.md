# AIfred Hooks

Automatic behaviors that run before/after tool executions.

**Last Updated**: 2026-01-05
**Total Hooks**: 15

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

### Core Hooks
| Hook | Event | Purpose |
|------|-------|---------|
| `audit-logger.js` | PreToolUse | Log all tool executions |
| `session-tracker.js` | Notification | Track session lifecycle |
| `session-exit-enforcer.js` | PostToolUse | Track activity for exit |
| `secret-scanner.js` | PreToolUse | Block commits with secrets |
| `context-reminder.js` | PostToolUse | Prompt for documentation |
| `docker-health-check.js` | PostToolUse | Verify container health |
| `memory-maintenance.js` | PostToolUse | Track Memory MCP entity access for pruning |

### Documentation Hooks
| Hook | Event | Purpose |
|------|-------|---------|
| `doc-sync-trigger.js` | PostToolUse | Track code changes, suggest sync after 5+ |

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

**Result**: No more "read session-state.md" at session start.

### session-stop.js
Sends desktop notification when session ends:
- ✅ "Claude Code Complete" - Normal completion
- ⚠️ "Claude Code Stopped" - Error occurred
- 🛑 "Claude Code Cancelled" - User cancelled

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

### self-correction-capture.js
Detects when user corrects Claude:
- Patterns: "No, actually...", "That's wrong", "You should have..."
- Severity levels: HIGH, MEDIUM, LOW
- Logs to `.claude/logs/corrections.jsonl`
- Prompts to save lessons to `.claude/context/lessons/corrections.md`

### worktree-manager.js
Tracks git worktree context:
- Detects worktree vs main repo
- Warns about cross-worktree file access
- Logs state to `.claude/logs/.worktree-state.json`

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
- `src/`, `lib/`, `scripts/`
- `docker-compose*.yaml`, `external-sources/`

**Related**: @.claude/agents/memory-bank-synchronizer.md

---

*AIfred Hooks v1.2 - Added doc-sync-trigger for documentation synchronization*
