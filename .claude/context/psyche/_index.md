# Psyche — Master Archon Topology

The complete structural map of Jarvis as an Archon.

**Version**: 1.0.0
**Purpose**: "You are here" navigation for the entire Archon structure

---

## The Archon Structure

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              JARVIS ARCHON                                   │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                         NOUS (Knowledge)                             │   │
│  │                       /.claude/context/                              │   │
│  │                                                                      │   │
│  │  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐  │   │
│  │  │ patterns │ │standards │ │workflows │ │ designs  │ │components│  │   │
│  │  │   (39)   │ │   (5)    │ │   (1)    │ │  (arch)  │ │  (AC-*)  │  │   │
│  │  └──────────┘ └──────────┘ └──────────┘ └──────────┘ └──────────┘  │   │
│  │  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐  │   │
│  │  │integrat- │ │ lessons  │ │reference │ │ psyche   │ │ trouble- │  │   │
│  │  │  ions    │ │ (memory) │ │(on-demand│ │(topology)│ │ shooting │  │   │
│  │  └──────────┘ └──────────┘ └──────────┘ └──────────┘ └──────────┘  │   │
│  │                                                                      │   │
│  │  Session: session-state.md | current-priorities.md | _index.md      │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                     │                                       │
│                                     │ Neuro                                 │
│                                     │ (connections)                         │
│                                     ▼                                       │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                        PNEUMA (Capabilities)                         │   │
│  │                            /.claude/                                 │   │
│  │                                                                      │   │
│  │  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐  │   │
│  │  │ agents   │ │ commands │ │  skills  │ │  hooks   │ │ scripts  │  │   │
│  │  │  (12)    │ │  (35)    │ │  (22)    │ │  (28)    │ │ (session)│  │   │
│  │  └──────────┘ └──────────┘ └──────────┘ └──────────┘ └──────────┘  │   │
│  │  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐  │   │
│  │  │  state   │ │  config  │ │ metrics  │ │ reports  │ │  logs    │  │   │
│  │  │(runtime) │ │(settings)│ │(telemetry│ │(AC output│ │(telemetry│  │   │
│  │  └──────────┘ └──────────┘ └──────────┘ └──────────┘ └──────────┘  │   │
│  │                                                                      │   │
│  │  Identity: CLAUDE.md | jarvis-identity.md | settings.json           │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                     │                                       │
│                                     │ Neuro                                 │
│                                     │ (connections)                         │
│                                     ▼                                       │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                        SOMA (Infrastructure)                         │   │
│  │                            /Jarvis/                                  │   │
│  │                                                                      │   │
│  │  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐  │   │
│  │  │  docker  │ │ scripts  │ │  models  │ │ lancedb  │ │   docs   │  │   │
│  │  │(services)│ │ (system) │ │ (local)  │ │ (vector) │ │  (user)  │  │   │
│  │  └──────────┘ └──────────┘ └──────────┘ └──────────┘ └──────────┘  │   │
│  │  ┌──────────────────────────────────────────────────────────────┐  │   │
│  │  │                      projects/project-aion/                   │  │   │
│  │  │  designs | plans | progress | evolution | ideas | reports     │  │   │
│  │  └──────────────────────────────────────────────────────────────┘  │   │
│  │                                                                      │   │
│  │  Configuration: paths-registry.yaml | CHANGELOG.md                  │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Layer Summaries

### Nous (Knowledge) — What Jarvis KNOWS

| Directory | Purpose | Key Files |
|-----------|---------|-----------|
| patterns/ | Behavioral rules | 48 patterns, wiggum-loop, selection-intelligence |
| standards/ | Conventions | readme-standard, model-selection |
| components/ | AC specs | AC-01 through AC-09 |
| integrations/ | Tool knowledge | capability-map.yaml (manifest router) |
| reference/ | On-demand docs | glossary, mcp-decision-map |
| psyche/ | Topology maps | This document |
| psyche/self-knowledge/ | Operational introspection | strengths, weaknesses, patterns-observed |

**Detail**: [nous-map.md](nous-map.md)

### Pneuma (Capabilities) — What Jarvis CAN DO

| Directory | Purpose | Count |
|-----------|---------|-------|
| agents/ | Custom agents | 12 active |
| commands/ | Slash commands | 35 |
| skills/ | On-demand skills | 22 |
| hooks/ | Event automation | 28 registered |
| scripts/ | Session scripts | ~20 |

**Detail**: [pneuma-map.md](pneuma-map.md)

### Soma (Infrastructure) — How Jarvis INTERACTS

| Directory | Purpose |
|-----------|---------|
| docker/ | Container services |
| scripts/ | System utilities |
| models/ | Local model storage |
| projects/ | Development workspaces |
| docs/ | User documentation |

**Detail**: [soma-map.md](soma-map.md)

---

## Neuro Pathways (Key Connections)

### Primary Navigation Paths

```
CLAUDE.md
    │
    ├─→ patterns/_index.md ─→ Individual patterns
    │
    ├─→ context/_index.md ─→ All Nous directories
    │
    ├─→ session-state.md ─→ Current work status
    │
    └─→ current-priorities.md ─→ Task queue
```

### Pattern → Implementation

```
Pattern file
    │
    ├─→ References other patterns (prerequisites)
    │
    ├─→ References components (AC specs)
    │
    └─→ Points to Pneuma capabilities (agents, scripts)
```

### Selection Intelligence

```
Task arrives
    │
    ├─→ selection-intelligence-guide.md (quick)
    │
    ├─→ capability-map.yaml (manifest router)
    │
    └─→ agent-selection-pattern.md (agents)
```

---

## Quick Navigation

| I want to... | Go to... |
|--------------|----------|
| Understand Jarvis structure | This document |
| Find a pattern | `patterns/_index.md` |
| Select a tool | `psyche/capability-map.yaml` |
| Check current work | `session-state.md` |
| See what's next | `current-priorities.md` |
| Find an agent | `.claude/agents/README.md` |
| Use a skill | `.claude/skills/_index.md` |
| Troubleshoot | `troubleshooting/_index.md` |
| Look up a term | `reference/glossary.md` |

---

## Cross-References

- **Glossary**: `reference/glossary.md` — All terminology
- **Component Orchestration**: `components/orchestration-overview.md`
- **Selection Intelligence**: `patterns/selection-intelligence-guide.md`
- **Orchestration Philosophy**: `designs/orchestration-philosophy.md`

---

*Psyche v1.0.0 — Master Archon Topology*
