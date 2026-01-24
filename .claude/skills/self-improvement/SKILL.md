---
name: self-improvement
version: 1.0.0
description: |
  Jarvis self-improvement cycles - reflection, research, maintenance, and evolution.
  Use when: "self-improve", "reflect on session", "run reflection", "evolve jarvis",
  "research improvements", "maintenance check", "improve yourself", "analyze corrections",
  "learn from mistakes", "system improvement", "AC-05", "AC-06", "AC-07", "AC-08".
  Orchestrates AC-05 through AC-08 autonomic components for continuous improvement.
category: workflow
tags: [autonomic, improvement, reflection, evolution, research, maintenance]
created: 2026-01-23
---

# Self-Improvement Skill

Comprehensive self-improvement for Jarvis, orchestrating AC-05 through AC-08 autonomic components.

---

## Overview

This skill coordinates the four Tier 2 autonomic components that enable Jarvis to continuously improve:

| Component | Purpose | Trigger |
|-----------|---------|---------|
| **AC-05** Self-Reflection | Analyze corrections, identify patterns | `/reflect` |
| **AC-06** Self-Evolution | Implement approved proposals | `/evolve` |
| **AC-07** R&D Cycles | Discover external/internal improvements | `/research` |
| **AC-08** Maintenance | Codebase hygiene and health | `/maintain` |

---

## Quick Actions

| Need | Command |
|------|---------|
| Full improvement cycle | `/self-improve` |
| Analyze corrections | `/reflect` |
| Implement proposals | `/evolve` |
| Research improvements | `/research` |
| Health/hygiene check | `/maintain` |

---

## Improvement Cycle Sequence

When running `/self-improve`, components execute in order:

```
┌─────────────────────────────────────────────────────────────────┐
│                    SELF-IMPROVEMENT SEQUENCE                    │
├─────────────────────────────────────────────────────────────────┤
│  Phase 1: REFLECTION (AC-05) ~10-20 min                        │
│  ├─ Review corrections (user + self)                            │
│  ├─ Identify patterns and problems                              │
│  ├─ Generate evolution proposals                                │
│  └─ Output: reflection report + proposals                       │
├─────────────────────────────────────────────────────────────────┤
│  Phase 2: MAINTENANCE (AC-08) ~5-15 min                        │
│  ├─ Health checks (hooks, MCPs, settings)                       │
│  ├─ Freshness audits (stale docs)                               │
│  ├─ Organization review                                         │
│  └─ Output: maintenance report + proposals                      │
├─────────────────────────────────────────────────────────────────┤
│  Phase 3: R&D CYCLES (AC-07) ~15-30 min                        │
│  ├─ Check research agenda                                       │
│  ├─ Analyze token efficiency                                    │
│  ├─ External discovery (if agenda empty)                        │
│  └─ Output: R&D report + proposals (require approval)           │
├─────────────────────────────────────────────────────────────────┤
│  Phase 4: EVOLUTION (AC-06) ~20-60 min                         │
│  ├─ Triage all proposals                                        │
│  ├─ Implement LOW-risk (auto-approve)                           │
│  ├─ Queue MEDIUM/HIGH for approval                              │
│  └─ Output: evolution report + pending approvals                │
├─────────────────────────────────────────────────────────────────┤
│  Phase 5: SUMMARY                                               │
│  ├─ Present consolidated report                                 │
│  ├─ List pending approvals                                      │
│  └─ Await user decision                                         │
└─────────────────────────────────────────────────────────────────┘
```

---

## Command Reference

### /self-improve [options]

**Full orchestration** - runs all four components in sequence.

| Option | Description | Default |
|--------|-------------|---------|
| `--focus=<system>` | Run only specified system(s) | all |
| `--skip=<system>` | Skip specified system(s) | none |
| `--dry-run` | Plan only, no changes | false |
| `--time-limit=<min>` | Maximum runtime | 120 |

**Examples:**
```bash
/self-improve                        # Full cycle
/self-improve --focus=reflection     # Reflection only
/self-improve --skip=evolution       # Skip evolution
/self-improve --dry-run              # See what would happen
```

---

### /reflect [options]

**AC-05 Self-Reflection** - analyze corrections and generate insights.

| Option | Description | Default |
|--------|-------------|---------|
| `--depth` | quick, standard, thorough | standard |
| `--focus` | context, tools, hooks, docs, all | all |
| `--dry-run` | Show analysis without writing | false |

**Data Sources:**
- `corrections.md` (user corrections)
- `self-corrections.md` (Jarvis corrections)
- `selection-audit.jsonl` (tool selection)
- Git history

**Output:** `.claude/reports/reflections/reflection-YYYY-MM-DD.md`

---

### /evolve [options]

**AC-06 Self-Evolution** - implement queued proposals.

| Option | Description | Default |
|--------|-------------|---------|
| `--risk` | low, medium, high | all |
| `--proposal` | Specific proposal ID | all pending |
| `--dry-run` | Show without implementing | false |

**Seven-Step Pipeline:**
1. Queue Review
2. Approval Check
3. Branch Creation (`evolution/<id>`)
4. Implementation
5. Validation
6. Merge (if passes)
7. Cleanup

**Safety:** Never auto-approves medium/high risk. Branch isolation. Validation required.

**Output:** `.claude/reports/evolutions/evolution-YYYY-MM-DD.md`

---

### /research [options]

**AC-07 R&D Cycles** - discover improvements.

| Option | Description | Default |
|--------|-------------|---------|
| `--focus` | external, internal, all | all |
| `--topic` | Specific topic ID | all pending |
| `--quick` | Abbreviated research | false |

**External Research:**
- New MCPs (awesome-mcp, modelcontextprotocol)
- New plugins (claude-code-plugins)
- SOTA patterns

**Internal Research:**
- Token usage patterns
- File organization
- Context efficiency

**Classification:**
- **ADOPT**: Implement as-is
- **ADAPT**: Modify for Jarvis
- **DEFER**: Watch, revisit later
- **REJECT**: Not suitable

**All R&D proposals require user approval.**

**Output:** `.claude/reports/research/research-YYYY-MM-DD.md`

---

### /maintain [options]

**AC-08 Maintenance** - codebase hygiene.

| Option | Description | Default |
|--------|-------------|---------|
| `--scope` | jarvis, project, all | all |
| `--task` | cleanup, freshness, health, organization | all |
| `--quick` | Health checks only | false |

**Maintenance Tasks:**
1. **Cleanup**: Log rotation, temp removal, orphan detection
2. **Freshness Audit**: Stale docs (>30 days), dependencies
3. **Health Checks**: Hooks, settings, MCPs, git
4. **Organization Review**: Structure validation, duplicates

**Non-destructive by default.** Deletion requires approval.

**Output:** `.claude/reports/maintenance/maintenance-YYYY-MM-DD.md`

---

## Risk Levels & Approval

| Risk | Auto-Approve | Examples |
|------|--------------|----------|
| **Low** | Yes | Doc updates, config tweaks, comments |
| **Medium** | No | Hook changes, command changes, patterns |
| **High** | No | Core changes, dependencies, security |

**R&D proposals always require approval** (never auto-implemented).

---

## Reports Location

All improvement activities generate reports:

```
.claude/reports/
├── reflections/      # AC-05 reflection reports
├── evolutions/       # AC-06 evolution reports
├── research/         # AC-07 R&D reports
├── maintenance/      # AC-08 maintenance reports
└── self-improve/     # Consolidated improvement reports
```

---

## Integration

### With Wiggum Loop (AC-02)

Self-improvement runs under Wiggum Loop:
- TodoWrite tracks each phase
- Progress visible throughout
- Drift detection active

### With JICM (AC-04)

Context-aware execution:
- Monitor usage per phase
- Checkpoint if >70%
- Pause at CRITICAL threshold

### With Session Completion (AC-09)

Pre-completion offers self-improvement:
- `/end-session` offers "Run self-improvement first?"
- User can select focus areas

---

## Evolution Queue

Proposals are queued in `evolution-queue.yaml`:

```yaml
proposals:
  - id: refl-2026-01-001
    source: AC-05
    title: Add validation hook for selections
    risk: medium
    status: pending
    created: 2026-01-23
```

---

## State Persistence

State saved to `.claude/state/self-improve-state.json` for resume capability:
- Current phase
- Completed phases
- Proposals generated
- Options used

---

## Related Documentation

### Commands
- @.claude/commands/reflect.md
- @.claude/commands/evolve.md
- @.claude/commands/research.md
- @.claude/commands/maintain.md
- @.claude/commands/self-improve.md

### Components
- @.claude/context/components/AC-05-self-reflection.md
- @.claude/context/components/AC-06-self-evolution.md
- @.claude/context/components/AC-07-rd-cycles.md
- @.claude/context/components/AC-08-maintenance.md

### Patterns
- @.claude/context/patterns/self-reflection-pattern.md
- @.claude/context/patterns/self-evolution-pattern.md
- @.claude/context/patterns/rd-cycles-pattern.md
- @.claude/context/patterns/maintenance-pattern.md

---

*Self-Improvement Skill v1.0.0 - AC-05/06/07/08 Orchestration*
