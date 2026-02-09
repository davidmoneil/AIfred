# Nous Layer Topology

Detailed map of the Nous (knowledge) layer — `/.claude/context/`.

**Version**: 1.0.0

---

## Layer Overview

Nous is what Jarvis KNOWS — accumulated wisdom that shapes decisions.

```
/.claude/context/
├── _index.md                 # Navigation hub (Map of Nous)
├── session-state.md          # Current work status [UPDATE FREQUENTLY]
├── current-priorities.md     # Active task queue [UPDATE ON COMPLETION]
├── configuration-summary.md  # Current setup state
│
├── patterns/                 # Behavioral rules (51 patterns)
├── standards/                # Conventions (5 standards)
├── workflows/                # Large task procedures
├── designs/                  # Architecture philosophy
├── components/               # AC-01 through AC-09 specs
├── integrations/             # Tool/MCP knowledge
├── reference/                # On-demand documentation
├── psyche/                   # Topology maps (you are here)
├── troubleshooting/          # Problem resolutions
├── lessons/                  # Corrections and learnings
├── guides/                   # How-to documentation
├── research/                 # R&D agenda
├── systems/                  # Host environment docs
├── infrastructure/           # Capability architecture specs
├── plans/                    # Session work plans
└── archive/                  # Historical states
```

---

## Directory Details

### patterns/ — Behavioral Rules

**51 patterns** organized by category:

| Category | Key Patterns |
|----------|-------------|
| Mandatory | wiggum-loop, startup-protocol, jicm, selection-intelligence-guide |
| Selection | agent-selection, tool-selection-intelligence, mcp-loading-strategy |
| Self-Improvement | self-reflection, self-evolution, rd-cycles, maintenance |
| Development | branching-strategy, milestone-review, project-reporting |
| Infrastructure | service-lifecycle, docker-operations, mcp-design-patterns |

**Index**: `patterns/_index.md`
**Strictness hierarchy**: ALWAYS > Recommended > Optional

### standards/ — Conventions

| Standard | Purpose |
|----------|---------|
| readme-standard.md | README requirements |
| severity-status-system.md | Status markers |
| model-selection.md | Opus/Sonnet/Haiku selection |

### components/ — Autonomic Specs

| Component | Purpose |
|-----------|---------|
| AC-01-self-launch.md | Session initialization |
| AC-02-wiggum-loop.md | Multi-pass verification |
| AC-03-milestone-review.md | Quality gates |
| AC-04-jicm.md | Context management |
| AC-05-self-reflection.md | Learning capture |
| AC-06-self-evolution.md | Self-improvement |
| AC-07-rd-cycles.md | Research |
| AC-08-maintenance.md | Health checks |
| AC-09-session-completion.md | Session exit |

**Orchestration diagram**: `orchestration-overview.md`

### integrations/ — Tool Knowledge

| Document | Purpose |
|----------|---------|
| capability-map.yaml | Manifest router (v5.9.0 authoritative source) |
| overlap-analysis.md | Tool conflict resolution |
| mcp-installation.md | MCP setup guide |
| memory-usage.md | Memory MCP guidelines |
| skills-selection-guide.md | Skill selection |

### reference/ — On-Demand Docs

| Document | Purpose |
|----------|---------|
| glossary.md | All terminology definitions |
| mcp-decision-map.md | Consolidated MCP selection |
| mcp-decomposition-registry.md | MCP→skill decomposition history (v5.0) |
| tool-reconstruction-backlog.md | 43 prioritized reconstruction items |
| commands-quick-ref.md | All commands by category |
| workflow-patterns.md | PARC, DDLA, COSA |
| project-management.md | Project management reference |

### psyche/ — Topology Maps

| Document | Purpose |
|----------|---------|
| _index.md | Master Archon topology |
| nous-map.md | This document |
| pneuma-map.md | Capabilities layer |
| soma-map.md | Infrastructure layer |
| capability-map.yaml | Manifest router (tool/skill/agent selection) |
| autopoietic-paradigm.md | Self-organizing system philosophy |
| self-knowledge/ | Operational introspection (strengths, weaknesses, patterns) |

### troubleshooting/ — Problem Solutions

| Document | Problem Type |
|----------|-------------|
| _index.md | Problem navigation |
| agent-format-migration.md | Agent YAML issues |
| hookify-import-fix.md | Import resolution |

### lessons/ — Memory

| Directory | Contents |
|-----------|----------|
| corrections.md | Documented corrections |
| self-corrections.md | Self-identified mistakes |
| patterns/ | Recurring patterns |
| problems/ | Problem descriptions |
| solutions/ | Solution templates |

---

## Key Files (High Frequency Access)

| File | Update Frequency | Purpose |
|------|------------------|---------|
| session-state.md | Every session | Current work status |
| current-priorities.md | On completion | Task queue |
| _index.md | Rarely | Navigation hub |
| patterns/_index.md | On new patterns | Pattern directory |

---

## Neuro Connections (From Nous)

### To Pneuma

```
patterns/ ─────────────► agents/ (agent-selection-pattern)
patterns/ ─────────────► commands/ (command definitions)
integrations/ ─────────► skills/ (skills-selection-guide)
components/ ───────────► scripts/ (AC implementation scripts)
```

### To Soma

```
designs/ ──────────────► projects/project-aion/designs/
lessons/ ──────────────► projects/project-aion/progress/
research/ ─────────────► projects/project-aion/evolution/
```

### Internal (Within Nous)

```
_index.md ─────────────► All directories
patterns/_index.md ────► Individual patterns
components/ ───────────► patterns/ (AC→pattern mapping)
troubleshooting/ ──────► lessons/ (problem→learning)
```

---

## Hierarchy Within Nous

```
Standards (MUST follow)
    ↓
Patterns (SHOULD follow)
    ↓
Workflows (Large task procedures)
    ↓
Designs (Architecture philosophy)
    ↓
Plans (Session-level work)
    ↓
Lessons (Memory)
```

---

*Jarvis — Nous Layer Topology*
