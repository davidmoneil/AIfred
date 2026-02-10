---
name: context-management
model: sonnet
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

## Proactive Context Reduction

### Observation Masking (tool output compression)
Tool outputs consume **80%+ of context** in agent workflows. Replace verbose outputs with compact references:

```
Large tool output (>2000 tokens)?
├── Write full output to temp file: /tmp/jarvis-{operation}-{epoch}.md
├── Inject compact summary (100-200 tokens) into conversation
├── Include file reference for on-demand re-read
└── Net savings: 60-80% of masked observation tokens
```

**When to apply**: Glob results >50 files, Grep results >100 lines, Bash output >2000 chars, Read of >500 line files when only needing summary.

### Context Ordering (KV-Cache optimization)
Place stable content first in context for prefix cache reuse:
1. System prompt + CLAUDE.md (stable, rarely changes)
2. Capability-map.yaml + patterns (semi-stable)
3. Session state + task context (dynamic, changes frequently)
4. Tool outputs + conversation history (most volatile)

### Context Partitioning
For multi-phase tasks, isolate sub-agent contexts via Task tool — each agent gets a clean context focused on its subtask, preventing accumulation.

## Circuit Breakers

- Debounce: 300s between triggers | Max 5/session | 3 failures → standdown

## Infrastructure

Watcher: `jarvis-watcher.sh` (v5.8.2, state machine). Agent: `compression-agent` (sonnet, background). Hook: `precompact-analyzer.js`. Essentials: `compaction-essentials.md`.

## References

- **Context Snapshot**: See [references/context-snapshot.md](references/context-snapshot.md) for reading statusline-captured context data programmatically (bypasses TUI scraping).
