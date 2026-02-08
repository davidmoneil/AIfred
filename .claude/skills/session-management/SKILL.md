---
name: session-management
version: 2.0.0
description: Session lifecycle — start, checkpoint, exit with context preservation
---

## Quick Actions

| Need | Action |
|------|--------|
| Save state before restart | `/checkpoint` |
| Clean session exit | `/end-session` |
| Check session state | Read `session-state.md` |
| Check priorities | Read `current-priorities.md` |

## Lifecycle

```
START (AC-01, automatic via session-start.sh)
├── Phase A: Time-aware greeting
├── Phase B: Load session-state + priorities
└── Phase C: Suggest next action

DURING (hooks run automatically)
├── audit-logger.js → log tool executions
├── self-correction-capture.js → capture lessons
└── doc-sync-trigger.js → track code changes

CHECKPOINT (/checkpoint)
├── Save work state to session-state.md
└── Provide MCP restart instructions

END (/end-session)
├── Update session-state.md
├── Commit and push changes
└── session-stop.js → notification
```

## Launch Modes

| Mode | Command | Behavior |
|------|---------|----------|
| Continue (default) | `launch-jarvis-tmux.sh` | Resume previous session |
| Fresh | `launch-jarvis-tmux.sh --fresh` | Clean start, options menu |

State files: `session-state.md`, `current-priorities.md`, `.claude/logs/audit.jsonl`
