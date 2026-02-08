---
name: context-management
version: 3.0.0
description: >
  JICM context monitoring, analysis, and compaction.
  Use when: context budget, JICM, smart compact, token usage, compaction.
---

## Quick Actions

| Need | Command |
|------|---------|
| Check context usage | Native `/context` |
| Detailed budget | `/context-budget` |
| Weekly analysis | `/context-analyze` |
| Manual JICM trigger | `/smart-compact` |
| Full checkpoint + clear | `/context-checkpoint` |
| Set threshold | `/autocompact-threshold <tokens>` |
| Report forgotten context | `/context-loss "desc"` |

## Thresholds (AC-04 JICM)

| Usage | Status | Action |
|-------|--------|--------|
| <50% | Healthy | Continue normally |
| 50-74% | Moderate | Checkpoint before heavy work |
| 75-84% | Warning | Run `/smart-compact` |
| 85%+ | Critical | `/context-checkpoint` then `/clear` |

## Decision Flow

```
Context high?
├── <50% → Continue
├── 50-74% → /checkpoint (optional)
├── 75-84% → /smart-compact
└── 85%+ → /context-checkpoint → /clear
```

JICM infrastructure: `jarvis-watcher.sh` (monitoring), `precompact-analyzer.js` (preservation), `context-compressor` agent (compression). See `compaction-essentials.md` for core patterns.
