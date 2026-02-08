---
name: context-management
version: 4.0.0
description: >
  JICM v5.8 context monitoring, analysis, and compaction.
  Use when: context budget, JICM, smart compact, token usage, compaction, compress.
---

## Quick Actions

| Need | Command |
|------|---------|
| Check context usage | Native `/context` |
| Detailed budget breakdown | `/context-budget` |
| Weekly analysis + archival | `/context-analyze` |
| Manual compression trigger | `/intelligent-compress` |
| Manual compact assessment | `/smart-compact` (assess) / `--full` (immediate) |
| Full checkpoint + MCP shed | `/context-checkpoint` → `/clear` |
| Set auto-trigger threshold | `/autocompact-threshold <tokens>` |
| Report forgotten context | `/context-loss "desc"` |

## Thresholds (AC-04 JICM v5.8.2)

| Usage | Status | Action |
|-------|--------|--------|
| <50% | Healthy | Continue normally |
| 50-64% | Caution | Log warning |
| 65% | Compress trigger | Watcher spawns `/intelligent-compress` |
| 73% | Emergency | Watcher sends native `/compact` fallback |
| 78.5% | Lockout ceiling | Claude Code auto-compacts (unrecoverable) |

## Automatic Flow (Watcher-Managed)

```
jarvis-watcher.sh polls every 30s
├── <65% → monitoring (no action)
├── 65% → /intelligent-compress → compression-agent (background)
│   └── agent writes .compressed-context-ready.md + signal
│       └── watcher detects → requests state dump → sends /clear
│           └── session-start hook injects checkpoint → resume
├── 73% → emergency /compact (native fallback)
└── 78.5% → Claude auto-compacts (avoid — data loss risk)
```

## Circuit Breakers

- Debounce: 300s between triggers | Max 5/session | 3 failures → standdown

## Infrastructure

Watcher: `jarvis-watcher.sh` (v5.8.2, state machine). Agent: `compression-agent` (sonnet, background). Hook: `precompact-analyzer.js`. Essentials: `compaction-essentials.md`.
