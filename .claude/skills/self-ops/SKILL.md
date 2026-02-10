---
name: self-ops
model: sonnet
version: 1.0.0
description: >
  Self-improvement, status monitoring, and validation workflows.
  Use when: self-improve, reflect, evolve, research, maintain, jarvis status,
  AC component status, health check, tooling health, validate selection, design review.
absorbs: self-improvement, jarvis-status, validation
---

## Quick Actions

| Need | Command | Detail |
|------|---------|--------|
| Full improvement cycle | `/self-improve` | AC-05→08→07→06 sequence |
| Analyze corrections | `/reflect` | AC-05 |
| Implement proposals | `/evolve` | AC-06 |
| Research improvements | `/research` | AC-07 |
| Codebase hygiene | `/maintain` | AC-08 |
| Autonomic system status | `/jarvis-status` | AC-01 through AC-09 health |
| Tooling validation | `/tooling-health` | MCPs, hooks, skills, agents |
| Infrastructure health | `/health-report` | Docker, Memory, context files |
| Selection audit | `/validate-selection` | Tool/agent selection accuracy |
| Pre-impl design review | `/design-review "task"` | PARC pattern check |

## Router

```
What do you need?
├── Self-improvement cycle → Read skills/self-improvement/SKILL.md
│   AC-05 reflect → AC-08 maintain → AC-07 research → AC-06 evolve
│   Reports: .claude/reports/{reflections,maintenance,research,evolutions}/
│
├── System status / health → Read skills/jarvis-status/SKILL.md
│   Benchmark: node .claude/scripts/benchmark-runner.js --all --json
│   Scoring:   node .claude/scripts/scoring-engine.js --session --json
│   JICM:      jq '.context_window' ~/.claude/logs/statusline-input.json
│
├── Validation workflows → Read skills/validation/SKILL.md
│   /tooling-health — MCPs, plugins, hooks, skills, subagents
│   /health-report — Docker, Memory MCP, context freshness
│   /validate-selection — 10 test cases, 80%+ target
│   /design-review "task" — PARC (Prompt→Assess→Relate→Create)
│
└── MCP-specific validation → Read skills/mcp-validation/SKILL.md
```

## Risk Levels (AC-06 Evolution)

| Risk | Auto-Approve | Examples |
|------|-------------|----------|
| Low | Yes | Doc updates, config tweaks |
| Medium | No | Hook/command/pattern changes |
| High | No | Core changes, dependencies |

R&D proposals (AC-07) always require approval.

## Key Paths

- Reports: `.claude/reports/` (reflections, evolutions, research, maintenance)
- Evolution queue: `.claude/state/queues/evolution-queue.yaml`
- Selection log: `.claude/logs/selection-audit.jsonl`
- Component specs: `.claude/context/components/AC-{05,06,07,08}.md`
