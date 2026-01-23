---
name: session-management
version: 1.0.0
description: Manage Claude Code sessions effectively - starting, tracking, checkpointing, and exiting with proper documentation
category: workflow
tags: [session, context, continuity, priorities, audit]
created: 2026-01-06
source: AIfred baseline af66364 (ported from AIProjects)
---

# Session Management Skill

Comprehensive session lifecycle management including context preservation, priority tracking, and documentation updates.

---

## Overview

This skill consolidates everything related to Claude Code session management:
- **Starting**: Auto-loaded context via hooks
- **During**: Activity tracking, code change detection
- **Checkpointing**: Save state for MCP restarts
- **Ending**: Proper exit procedure with documentation

**Value**: Ensures work context is never lost across sessions.

---

## Quick Actions

| Need | Action | Reference |
|------|--------|-----------|
| Save state before restart | `/checkpoint` | @.claude/commands/checkpoint.md |
| Clean session exit | `/end-session` | @.claude/commands/end-session.md |
| Check session state | Read session-state.md | @.claude/context/session-state.md |
| Sync AIfred baseline | `/sync-aifred-baseline` | @.claude/commands/sync-aifred-baseline.md |
| Check setup status | `/setup-readiness` | @.claude/commands/setup-readiness.md |

---

## Session Lifecycle

```
┌─────────────────────────────────────────────────────────────────┐
│                    SESSION LIFECYCLE                            │
├─────────────────────────────────────────────────────────────────┤
│  START (AC-01 Self-Launch Protocol)                             │
│  └─ session-start.sh hook (automatic)                           │
│     ├─ Phase A: Time-aware greeting with Jarvis persona         │
│     ├─ Phase B: Loads session-state.md + current-priorities.md  │
│     ├─ Phase C: Autonomous initiation based on state            │
│     ├─ Creates AC-01-launch.json state file                     │
│     └─ Launches auto-clear watcher for context management       │
├─────────────────────────────────────────────────────────────────┤
│  DURING                                                         │
│  ├─ audit-logger.js → Logs all tool executions                  │
│  ├─ session-exit-enforcer.js → Tracks exit checklist            │
│  ├─ self-correction-capture.js → Captures lessons               │
│  ├─ doc-sync-trigger.js → Tracks code changes                   │
│  └─ workspace-guard.js → Enforces workspace boundaries          │
├─────────────────────────────────────────────────────────────────┤
│  CHECKPOINT (when On-Demand MCP needed)                         │
│  └─ /checkpoint                                                 │
│     ├─ Updates session-state.md with current work               │
│     ├─ Lists pending tasks                                      │
│     └─ Provides MCP enable instructions                         │
├─────────────────────────────────────────────────────────────────┤
│  END                                                            │
│  ├─ /end-session                                                │
│  │   ├─ Update session-state.md (status, next steps)            │
│  │   ├─ Commit and push changes                                 │
│  │   └─ Disable any On-Demand MCPs enabled                      │
│  └─ session-stop.js → Desktop notification                      │
└─────────────────────────────────────────────────────────────────┘
```

---

## Components Reference

### Hooks (Automatic)

These run automatically - no action needed.

| Hook | Event | Purpose |
|------|-------|---------|
| `session-start.sh` | SessionStart | AC-01 Self-Launch Protocol |
| `session-stop.js` | Stop | Desktop notification |
| `session-exit-enforcer.js` | PostToolUse | Track exit checklist |
| `audit-logger.js` | PreToolUse | Log all activity |
| `self-correction-capture.js` | UserPromptSubmit | Capture corrections |
| `doc-sync-trigger.js` | PostToolUse | Track code changes |
| `pre-compact.js` | PreCompact | Preserve context before compaction |

### Commands (Manual)

Invoke these when needed.

| Command | Purpose | When to Use |
|---------|---------|-------------|
| `/checkpoint` | Save state for restart | Before enabling On-Demand MCP |
| `/end-session` | Clean session exit | End of work |
| `/sync-aifred-baseline` | Check upstream changes | Session start |
| `/setup-readiness` | Verify setup | After changes |

### State Files

These files persist across sessions.

| File | Purpose | Update Frequency |
|------|---------|------------------|
| `session-state.md` | Current work status, blockers, next steps | Every session |
| `current-priorities.md` | Active priorities and completed work | When work completes |
| `.claude/logs/audit.jsonl` | Tool execution history | Automatic |

### Session Identification

Claude Code provides `${CLAUDE_SESSION_ID}` — a unique identifier for each session.

**Uses**:
- Correlate telemetry events across a session
- Track work attribution in logs
- Enable session-aware skill execution
- Support `/resume` for session continuation

**Access in hooks/scripts**:
```javascript
const sessionId = process.env.CLAUDE_SESSION_ID;
```

**In skill YAML frontmatter**, use substitution:
```yaml
session: ${CLAUDE_SESSION_ID}
```

---

## Detailed Workflows

### Starting a Session

**What happens automatically** (AC-01 Self-Launch Protocol):
1. `session-start.sh` hook fires
2. **Phase A**: Time-aware greeting with Jarvis persona (morning/afternoon/evening)
3. **Phase B**: Context loading
   - Reads `session-state.md` for previous work status
   - Reads `current-priorities.md` for task backlog
   - Checks for checkpoint file (auto-resume if present)
   - Resets JICM context estimate
4. **Phase C**: Autonomous initiation
   - Suggests next action based on state
   - Never simply "awaits instructions"

**What you should do**:
1. Receive the greeting and status briefing
2. Jarvis will suggest continuing pending work or alternatives
3. If baseline has updates, run `/sync-aifred-baseline`
4. Proceed with suggested work or redirect as needed

**Reference**: @.claude/context/patterns/startup-protocol.md

### During a Session

**Automatic behaviors**:
- All tool executions logged to `audit.jsonl`
- User corrections captured for lessons learned
- Code changes tracked by doc-sync-trigger
- Workspace boundaries enforced by guardrail hooks

**Manual actions**:
- Use `TodoWrite` for tracking current task items
- Run `/agent memory-bank-synchronizer` if sync suggested
- Update session-state.md at major milestones

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
1. Run /end-session
2. The command will:
   - Update session-state.md
   - Review and clear todos
   - Commit changes if needed
   - Push to GitHub if applicable
   - Disable On-Demand MCPs
3. session-stop.js sends notification
```

---

## Integration Points

### With Upstream Sync

- `session-start.js` checks AIfred baseline status
- `/sync-aifred-baseline` analyzes upstream changes
- Port decisions recorded in port-log.md

### With Priority System

- `current-priorities.md` loaded at session start
- `/end-session` can update priorities
- Session state tracks current task

### With Memory MCP

- `self-correction-capture.js` prompts for lesson storage
- Lessons stored as Memory entities
- `memory-bank-synchronizer` agent syncs Memory ↔ docs

### With Documentation Sync

- `doc-sync-trigger.js` tracks code changes during session
- After 5+ significant changes, suggests sync
- `/agent memory-bank-synchronizer` aligns docs with code

### With Guardrails (Jarvis-specific)

- `workspace-guard.js` blocks writes to AIfred baseline
- `dangerous-op-guard.js` blocks destructive commands
- `permission-gate.js` soft-gates policy-crossing operations

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
- macOS: Should work automatically via osascript
- Linux: `sudo apt install libnotify-bin`
- Check `session-stop.js` hook exists

---

## Related Documentation

### Core References
- @.claude/context/session-state.md - Session state file
- @.claude/context/current-priorities.md - Priorities file
- @.claude/persona/jarvis-identity.md - Jarvis persona specification

### Patterns
- @.claude/context/patterns/startup-protocol.md - AC-01 three-phase startup protocol
- @.claude/context/patterns/session-start-checklist.md - Session start checklist
- @.claude/context/patterns/mcp-loading-strategy.md - MCP On-Demand pattern
- @.claude/context/patterns/automated-context-management.md - JICM context management

### Components
- @.claude/context/components/AC-01-self-launch.md - Self-Launch component spec

### Infrastructure
- @.claude/hooks/session-start.sh - Main startup hook
- @.claude/hooks/README.md - All hooks documentation
