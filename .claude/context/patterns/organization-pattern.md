# Organization Pattern — Archon Architecture

Pattern for organizing files and directories according to the three-layer Archon Architecture.

**Version**: 1.0.0
**Type**: Structural
**Strictness**: Recommended

---

## Context

Jarvis follows the Archon Architecture, a three-layer organizational model using Greek terminology. This pattern provides guidance for file placement decisions.

---

## The Three Layers

### Nous (Knowledge) — `/.claude/context/`

**What it contains**: Everything Jarvis KNOWS — patterns, standards, workflows, state, lessons.

| Subdirectory | Purpose | Examples |
|--------------|---------|----------|
| `patterns/` | Behavioral rules | wiggum-loop, selection-intelligence |
| `standards/` | Conventions | readme-standard, model-selection |
| `workflows/` | Multi-step processes | session-exit, archon-maintenance |
| `components/` | AC specifications | AC-01 through AC-09 |
| `integrations/` | Tool knowledge | capability-matrix, mcp-installation |
| `reference/` | On-demand lookups | glossary, mcp-decision-map |
| `lessons/` | Captured learnings | problems/, solutions/, patterns/ |
| `psyche/` | Topology maps | _index.md, nous-map, pneuma-map |
| `troubleshooting/` | Problem resolution | _index.md, categorized guides |
| `archive/` | Historical state | session-state archives |

**Key files at context root**:
- `session-state.md` — Current work status
- `current-priorities.md` — Task queue
- `_index.md` — Map of Nous (navigation hub)

### Pneuma (Capabilities) — `/.claude/`

**What it contains**: Everything Jarvis CAN DO — agents, commands, skills, hooks.

| Subdirectory | Purpose | Examples |
|--------------|---------|----------|
| `agents/` | Custom subagents | code-review, deep-research |
| `commands/` | Slash commands | review-milestone, checkpoint |
| `skills/` | On-demand skills | pdf, docx, session-management |
| `hooks/` | Event automation | credential-guard, update-context-cache |
| `scripts/` | Session scripts | launch-jarvis-tmux |
| `state/` | Runtime state | queues/, component state |
| `reports/` | AC output | reviews/, maintenance/ |
| `logs/` | Telemetry | session logs, watcher logs |

**Key files at .claude root**:
- `CLAUDE.md` — Primary directive (loaded automatically)
- `jarvis-identity.md` — Persona definition
- `settings.json` — Project settings
- `planning-tracker.yaml` — Document registry

### Soma (Infrastructure) — `/Jarvis/`

**What it contains**: How Jarvis INTERACTS with the world — infrastructure, projects, external.

| Subdirectory | Purpose | Examples |
|--------------|---------|----------|
| `docker/` | Container services | Service definitions |
| `scripts/` | System utilities | Installation, maintenance |
| `models/` | Local model storage | Downloaded models |
| `docs/` | User documentation | User-facing docs |
| `projects/` | Development workspaces | project-aion/ |

---

## Project Aion Structure

Project-specific work lives in `/projects/project-aion/` with current/archive organization:

| Directory | Purpose |
|-----------|---------|
| `designs/current/` | Active design docs |
| `designs/archive/` | Historical designs |
| `plans/current/` | Active implementation plans |
| `plans/archive/` | Completed/abandoned plans |
| `ideas/current/` | Active exploration docs |
| `ideas/archive/` | Historical ideas |
| `reports/current/` | Recent reports |
| `reports/archive/` | Historical reports |
| `progress/current/` | Active tracking (sessions/, milestones/) |
| `progress/archive/` | Historical progress |
| `evolution/` | Integration and self-improvement work |
| `external/` | External project contexts |
| `analysis/` | Analysis documents |
| `experiments/` | Experimental work |

---

## Placement Decision Tree

When creating a new file, follow this decision tree:

```
Is it knowledge/patterns/state?
├─ Yes → Nous (/.claude/context/)
│   ├─ Pattern? → patterns/
│   ├─ Standard? → standards/
│   ├─ Multi-step process? → workflows/
│   ├─ AC specification? → components/
│   ├─ Tool integration? → integrations/
│   ├─ Lookup reference? → reference/
│   └─ Learning/lesson? → lessons/
│
├─ No → Is it a capability?
│   ├─ Yes → Pneuma (/.claude/)
│   │   ├─ Subagent? → agents/
│   │   ├─ Slash command? → commands/
│   │   ├─ Loadable skill? → skills/
│   │   ├─ Event hook? → hooks/
│   │   └─ Helper script? → scripts/
│   │
│   └─ No → Is it project work?
│       ├─ Yes → Soma (/projects/project-aion/)
│       │   ├─ Design/architecture? → designs/current/
│       │   ├─ Implementation plan? → plans/current/
│       │   ├─ Exploratory idea? → ideas/current/
│       │   ├─ Report/output? → reports/current/
│       │   └─ Progress tracking? → progress/current/
│       │
│       └─ No → Infrastructure
│           └─ Soma (/Jarvis/) appropriate location
```

---

## Current/Archive Convention

For time-bounded documents (plans, ideas, reports, progress):

| State | Location |
|-------|----------|
| Active work | `*/current/` |
| Completed/superseded | `*/archive/` |

**When to archive**:
- Plan implemented or abandoned
- Design superseded by newer version
- Report older than 30 days and not actively referenced
- Idea explored and decided (yes/no)

---

## Key Principles

1. **Layer separation**: Don't mix knowledge (Nous) with capabilities (Pneuma)
2. **Project isolation**: Project-specific work stays in `projects/`
3. **Current/Archive hygiene**: Move completed work to archive promptly
4. **README presence**: Every directory should have a README.md
5. **Progressive disclosure**: Index files point to subdirectories, not everything at once

---

## Anti-Patterns

| Don't | Do Instead |
|-------|------------|
| Put project plans in `.claude/context/` | Put in `projects/project-aion/plans/` |
| Create templates in random locations | Use `*/templates/` subdirectories |
| Leave completed plans in `current/` | Move to `archive/` when done |
| Create new top-level directories | Use existing structure or extend thoughtfully |
| Skip README.md for new directories | Always add README.md explaining purpose |

---

## Related

- `psyche/_index.md` — Master Archon topology
- `reference/glossary.md` — Terminology definitions
- `standards/readme-standard.md` — README requirements

---

*Organization Pattern v1.0.0 — Archon Architecture File Placement*
