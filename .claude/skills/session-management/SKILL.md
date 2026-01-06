---
name: session-management
version: 1.0.0
description: Manage Claude Code sessions effectively - starting, tracking, checkpointing, and exiting with proper documentation
category: workflow
tags: [session, context, continuity, priorities, audit]
created: 2026-01-05
ported_from: AIProjects
---

# Session Management Skill

Comprehensive session lifecycle management including context preservation, priority tracking, and documentation updates.

---

## Overview

This skill consolidates everything related to Claude Code session management:
- **Starting**: Auto-loaded context via hooks
- **During**: Activity tracking, orchestration detection
- **Checkpointing**: Save state for MCP restarts
- **Ending**: Proper exit procedure with documentation

**Value**: Ensures work context is never lost across sessions.

---

## Quick Actions

| Need | Action | Reference |
|------|--------|-----------|
| Save state before restart | `/checkpoint` | @.claude/commands/checkpoint.md |
| Update completed work | `/update-priorities complete "item"` | @.claude/commands/update-priorities.md |
| Review priorities | `/update-priorities review` | @.claude/commands/update-priorities.md |
| Set session name | `/audit-log session "name"` | @.claude/commands/audit-log.md |
| Check exit checklist | Read exit procedure | @.claude/context/workflows/session-exit-procedure.md |
| Resume orchestration | `/orchestration:resume` | @.claude/commands/orchestration/resume.md |

---

## Session Lifecycle

```
┌─────────────────────────────────────────────────────────────────┐
│                    SESSION LIFECYCLE                            │
├─────────────────────────────────────────────────────────────────┤
│  START                                                          │
│  └─ session-start.js hook (automatic)                           │
│     ├─ Loads session-state.md content                           │
│     ├─ Loads current-priorities.md content                      │
│     ├─ Shows git branch context                                 │
│     └─ Detects worktree if applicable                           │
├─────────────────────────────────────────────────────────────────┤
│  DURING                                                         │
│  ├─ audit-logger.js → Logs all tool executions                  │
│  ├─ session-exit-enforcer.js → Tracks exit checklist            │
│  ├─ orchestration-detector.js → Detects complex tasks           │
│  ├─ self-correction-capture.js → Captures lessons               │
│  └─ doc-sync-trigger.js → Tracks code changes                   │
├─────────────────────────────────────────────────────────────────┤
│  CHECKPOINT (when On-Demand MCP needed)                         │
│  └─ /checkpoint                                                 │
│     ├─ Updates session-state.md with current work               │
│     ├─ Lists pending tasks                                      │
│     └─ Provides MCP enable instructions                         │
├─────────────────────────────────────────────────────────────────┤
│  END                                                            │
│  ├─ /update-priorities complete "item" (if work done)           │
│  ├─ Update session-state.md (status, next steps)                │
│  ├─ Commit and push changes                                     │
│  └─ session-stop.js → Desktop notification                      │
└─────────────────────────────────────────────────────────────────┘
```

---

## Components Reference

### Hooks (Automatic)

These run automatically - no action needed.

| Hook | Event | Purpose |
|------|-------|---------|
| `session-start.js` | SessionStart | Auto-load context files |
| `session-stop.js` | Stop | Desktop notification |
| `session-exit-enforcer.js` | PreToolUse | Track exit checklist |
| `audit-logger.js` | PreToolUse | Log all activity |
| `orchestration-detector.js` | UserPromptSubmit | Detect complex tasks |
| `self-correction-capture.js` | UserPromptSubmit | Capture corrections |

### Commands (Manual)

Invoke these when needed.

| Command | Purpose | When to Use |
|---------|---------|-------------|
| `/checkpoint` | Save state for restart | Before enabling On-Demand MCP |
| `/update-priorities` | Manage priorities | Completing work, reviewing |
| `/audit-log` | Manage audit logging | Setting session name |
| `/orchestration:resume` | Resume orchestration | Returning to complex task |

### State Files

These files persist across sessions.

| File | Purpose | Update Frequency |
|------|---------|------------------|
| `session-state.md` | Current work status, blockers, next steps | Every session |
| `current-priorities.md` | Active priorities and completed work | When work completes |
| `.claude/logs/audit.jsonl` | Tool execution history | Automatic |

---

## Detailed Workflows

### Starting a Session

**What happens automatically**:
1. `session-start.js` hook fires
2. Reads and injects `session-state.md` (truncated to 2000 chars)
3. Reads and injects `current-priorities.md` (truncated to 1500 chars)
4. Shows git branch and uncommitted changes count
5. If in worktree, shows worktree context

**What you should do**:
1. Review the injected context (shown automatically)
2. Check for blockers or next steps from previous session
3. If orchestration was active, run `/orchestration:resume`
4. Optionally set session name: `/audit-log session "Feature X"`

### During a Session

**Automatic behaviors**:
- All tool executions logged to `audit.jsonl`
- Complex prompts trigger orchestration suggestions
- User corrections captured for lessons learned
- Code changes tracked by doc-sync-trigger

**Manual actions**:
- Use `TodoWrite` for tracking current task items
- Use `/orchestration:commit T1.2` to link commits to tasks
- Run `/agent memory-bank-synchronizer` if sync suggested

### Checkpointing (MCP Restart)

When you need an On-Demand MCP that's not enabled:

1. Run `/checkpoint`
2. The command will:
   - Save current work state to `session-state.md`
   - List any pending tasks
   - Provide exact enable instructions
3. Exit Claude Code
4. Enable the MCP in settings
5. Restart Claude Code
6. Context auto-loads via hook

### Ending a Session

**Quick Exit** (minimum):
```
1. Update session-state.md (status: idle, next steps)
2. Commit and push changes
```

**Proper Exit** (recommended):
```
1. /update-priorities complete "item" (if work completed)
2. Update session-state.md:
   - Status: idle
   - Summary of what was done
   - Next steps for continuation
   - Any blockers discovered
3. git add . && git commit -m "..." && git push
4. session-stop.js sends notification
```

**Full Exit** (complex sessions):
See @.claude/context/workflows/session-exit-procedure.md for 19-step process.

---

## Integration Points

### With Orchestration System

- `orchestration-detector.js` detects complex tasks during session
- Active orchestrations tracked in `session-state.md`
- `/orchestration:resume` restores context after break
- `/orchestration:commit` links commits to specific tasks

### With Priority System

- `current-priorities.md` loaded at session start
- `/update-priorities complete` marks work done
- Orchestration completion updates linked priorities

### With Memory MCP

- `self-correction-capture.js` prompts for lesson storage
- Lessons stored as Memory entities
- `memory-bank-synchronizer` agent syncs Memory ↔ docs

### With Documentation Sync

- `doc-sync-trigger.js` tracks code changes during session
- After 5+ significant changes, suggests sync
- `/agent memory-bank-synchronizer` aligns docs with code

---

## Troubleshooting

### Context not loading at start?
- Verify `session-start.js` hook exists in `.claude/hooks/`
- Check hook is valid: `node -c .claude/hooks/session-start.js`
- Ensure `session-state.md` exists

### Exit checklist not tracking?
- Verify `session-exit-enforcer.js` hook exists
- Hook tracks: session-state.md updates, priorities updates, git commits

### Desktop notification not appearing?
- Linux: `sudo apt install libnotify-bin`
- macOS: Should work automatically
- Check `session-stop.js` hook exists

---

## Related Documentation

- @.claude/context/workflows/session-exit-procedure.md - Full 19-step exit procedure
- @.claude/context/session-state.md - Session state file
- @.claude/context/projects/current-priorities.md - Priorities file
- @.claude/hooks/README.md - All hooks documentation
- @.claude/orchestration/README.md - Orchestration system
- @.claude/context/patterns/mcp-loading-strategy.md - MCP On-Demand pattern
