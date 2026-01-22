# Jarvis Hooks

Automatic behaviors that run before/after tool executions.

**Last Updated**: 2026-01-21
**Registered Hooks**: 9 (see settings.json)
**Unregistered Files**: 17 (flagged for PR-10.5 review)

> **JICM v2 Note**: `context-accumulator.js` removed from PostToolUse hooks.
> Context monitoring now handled by `jarvis-watcher.sh` (polls status line).

---

## Registered Hooks (Active)

These hooks are registered in `settings.json` and actively execute:

### Lifecycle

| Hook | Event | Purpose |
|------|-------|---------|
| `session-start.sh` | SessionStart | Auto-load context, checkpoint handling, MCP suggestions |
| `pre-compact.sh` | PreCompact | Preserve context before compaction |
| `stop-auto-clear.sh` | Stop | Clean up auto-clear watcher |
| `subagent-stop.js` | SubagentStop | Agent chaining & activity logging |

### User Prompt Processing

| Hook | Event | Purpose |
|------|-------|---------|
| `minimal-test.sh` | UserPromptSubmit | Basic prompt validation |
| `orchestration-detector.js` | UserPromptSubmit | Detect complex tasks, suggest orchestration |
| `self-correction-capture.js` | UserPromptSubmit | Capture corrections as lessons |

### Post Tool Processing

| Hook | Event | Purpose |
|------|-------|---------|
| `cross-project-commit-tracker.js` | PostToolUse | Track commits across projects |
| `selection-audit.js` | PostToolUse | Audit tool selection decisions |
| `milestone-detector.js` | PostToolUse | Detect milestone completions |

> **Removed**: `context-accumulator.js` — Context monitoring moved to jarvis-watcher.sh (JICM v2)

---

## Unregistered Files (PR-10.5 Review Required)

These JS files exist but are NOT registered in settings.json:

### Potentially Needed (Critical)

| File | Intended Purpose | Status |
|------|-----------------|--------|
| `dangerous-op-guard.js` | Block destructive commands | **NEEDS REGISTRATION** |
| `workspace-guard.js` | Block writes to AIfred baseline | **NEEDS REGISTRATION** |
| `secret-scanner.js` | Block commits with secrets | **NEEDS REGISTRATION** |
| `permission-gate.js` | Soft-gate policy-crossing ops | **NEEDS REGISTRATION** |

### May Be Superseded

| File | Reason |
|------|--------|
| `session-start.js` | Replaced by `session-start.sh` |
| `pre-compact.js` | Replaced by `pre-compact.sh` |
| `session-stop.js` | Possibly replaced by `stop-auto-clear.sh` |

### Needs Evaluation

| File | Intended Purpose |
|------|-----------------|
| `audit-logger.js` | Log all tool executions |
| `context-reminder.js` | Prompt for documentation |
| `doc-sync-trigger.js` | Track code changes, suggest sync |
| `docker-health-check.js` | Verify container health |
| `memory-maintenance.js` | Track Memory MCP entity access |
| `project-detector.js` | Auto-detect GitHub URLs |
| `session-exit-enforcer.js` | Track activity for exit |
| `session-tracker.js` | Track session lifecycle |
| `worktree-manager.js` | Track worktrees |

---

## Hook Types

| Type | When | Use For |
|------|------|---------|
| `SessionStart` | When Claude starts | Auto-load context, initialize state |
| `UserPromptSubmit` | User submits prompt | Validation, detection |
| `PreToolUse` | Before tool runs | Validation, logging, blocking |
| `PostToolUse` | After tool completes | Verification, cleanup |
| `Notification` | Session events | Lifecycle tracking |
| `Stop` | When Claude ends | Cleanup |
| `SubagentStop` | Agent completes | Agent chaining |
| `PreCompact` | Before compaction | Preserve state |

---

## Registered Hook Details

### session-start.sh

Main session initialization hook:
- Loads checkpoint files for context restoration
- Suggests MCPs based on session-state.md
- Launches auto-clear watcher on startup
- Handles startup, resume, clear, compact events

### orchestration-detector.js

Detects complex tasks and suggests orchestration:
- Scores prompts for complexity signals
- Auto-invokes `/orchestration:plan` for high scores (18+)
- Logs detections to `.claude/logs/orchestration-detections.jsonl`

### context-accumulator.js

Tracks context token usage:
- Monitors tool results for token consumption
- Writes estimates to `.claude/logs/context-estimate.json`
- Enables JICM (Jarvis Intelligent Context Management)

### selection-audit.js

Audits tool selection decisions:
- Logs to `.claude/logs/selection-audit.jsonl`
- Used for selection intelligence validation

---

## Configuration

Hooks are registered in `.claude/settings.json` under the `hooks` key.

Example registration:
```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "node $CLAUDE_PROJECT_DIR/.claude/hooks/context-accumulator.js"
          }
        ]
      }
    ]
  }
}
```

---

## Logs

Active logs written by registered hooks:

| Log File | Written By |
|----------|------------|
| `session-start-diagnostic.log` | `session-start.sh` |
| `orchestration-detections.jsonl` | `orchestration-detector.js` |
| `corrections.jsonl` | `self-correction-capture.js` |
| `context-estimate.json` | `context-accumulator.js` |
| `selection-audit.jsonl` | `selection-audit.js` |
| `agent-activity.jsonl` | `subagent-stop.js` |

---

## PR-10.5 Action Items

1. **Register critical guardrail hooks** if they should be active
2. **Archive superseded JS files** that have shell replacements
3. **Evaluate remaining hooks** for usefulness vs complexity cost

See: `docs/reports/validation/hooks-registration-audit-2026-01-09.md`

---

*Jarvis Hooks — Updated 2026-01-09 (PR-10 audit)*
