---
name: autonom-ops
model: sonnet
version: 1.0.0
description: >
  Session orchestration — autonomous commands, session lifecycle, context management, Ralph loop.
  Use when: compact context, rename session, resume session, export conversation, show status,
  checkpoint, end session, Ralph loop, JICM, context budget, signal commands, watcher.
absorbs: autonomous-commands, session-management, context-management, ralph-loop
---

## Quick Actions

| Need | Command/Action |
|------|---------------|
| Check context usage | `/context` (native) |
| Context budget breakdown | `/context-budget` |
| Manual compress | `/intelligent-compress` |
| Emergency compact | `/smart-compact --full` |
| Save checkpoint | `/checkpoint` |
| Clean session exit | `/end-session` |
| Start Ralph loop | `/ralph-loop "task" --max-iterations N` |
| Cancel Ralph loop | `/cancel-ralph` |
| Execute native command | `source .claude/scripts/signal-helper.sh && signal_<cmd>` |

## Router

```
What do you need?
├── Execute native slash command → Read skills/autonomous-commands/SKILL.md
│   Signal-based: signal_compact, signal_rename, signal_resume, etc.
│   Requires: tmux + watcher running (jarvis-watcher.sh for signals)
│   Pattern: source signal-helper.sh && signal_<command> [args]
│
├── Session lifecycle → Read skills/session-management/SKILL.md
│   Start (AC-01): greeting + load state + suggest action
│   Checkpoint: /checkpoint → save state for MCP restart
│   End (AC-09): /end-session → commit + push + notification
│   Modes: continue (default) or --fresh
│
├── Context management (JICM) → Read skills/context-management/SKILL.md
│   Thresholds: 50% caution, 65% compress, 73% emergency, 78.5% lockout
│   JICM Watcher: jicm-watcher.sh (v6 stop-and-wait, polls 5s)
│   Agent: compression-agent (sonnet, background)
│   Hook: precompact-analyzer.js
│
└── Iterative development → Read skills/ralph-loop/SKILL.md
    Core: same prompt repeated, Claude sees previous work in files
    Start: /ralph-loop "prompt" --max-iterations 20
    Cancel: /cancel-ralph
    Completion: <promise>DONE</promise> tag
```

## Key State Files

| File | Purpose |
|------|---------|
| `session-state.md` | Current work status |
| `current-priorities.md` | Task queue |
| `.command-signal` | Watcher signal (JSON) |
| `.ralph-loop.local.md` | Ralph loop state |
| `.jicm-status.json` | JICM agent status |
| `statusline-input.json` | Context usage (authoritative) |
