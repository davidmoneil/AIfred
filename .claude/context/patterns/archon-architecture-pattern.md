# Archon Architecture Pattern

The reference architecture for designing autonomous AI entities (Archons) within Project Aion.

**Version**: 1.0.0
**Category**: Architecture
**Strictness**: Reference (for new Archon design)

---

## Overview

The Archon Architecture defines the standard three-layer structure for autonomous AI entities. This pattern establishes conventions for knowledge organization, capability structure, and infrastructure layout that enable effective self-improvement and orchestration.

---

## Terminology

| Term | Greek | Meaning |
|------|-------|---------|
| **Aion** | αἰών | Age, epoch — the PROJECT (era of autonomous AI) |
| **Archon** | ἄρχων | Ruler, leader — the ENTITY (individual autonomous agent) |
| **Nous** | νοῦς | Intellect — knowledge layer |
| **Pneuma** | πνεῦμα | Vital force — capabilities layer |
| **Soma** | σῶμα | Body — infrastructure layer |
| **Neuro** | νεύρο | Nerves — navigation substrate (connections) |
| **Psyche** | ψυχή | Soul — documented topology maps |

---

## The Three Layers

### Layer 1: Nous (Knowledge)

**Location**: `/.claude/context/`
**Purpose**: What the Archon KNOWS

Required directories:
```
context/
├── _index.md                 # Navigation hub
├── session-state.md          # Current work status
├── current-priorities.md     # Active task queue
│
├── patterns/                 # Behavioral rules
├── standards/                # Conventions
├── components/               # Autonomic component specs
├── integrations/             # Tool knowledge
├── reference/                # On-demand documentation
├── psyche/                   # Topology maps
├── troubleshooting/          # Problem solutions
├── lessons/                  # Memory
└── archive/                  # Historical
```

**Key requirement**: Every directory must have a README.md per readme-standard.

### Layer 2: Pneuma (Capabilities)

**Location**: `/.claude/`
**Purpose**: What the Archon CAN DO

Required directories:
```
.claude/
├── CLAUDE.md                 # Primary identity
├── <archon>-identity.md      # Persona specification
├── settings.json             # Configuration
│
├── context/                  # → Nous layer
│
├── agents/                   # Custom agents
├── commands/                 # Slash commands
├── skills/                   # On-demand skills
├── hooks/                    # Event automation
├── scripts/                  # Session scripts
│
├── state/                    # Runtime state
├── config/                   # Configuration
├── metrics/                  # Telemetry
├── reports/                  # Self-improvement outputs
└── logs/                     # Operational logs
```

### Layer 3: Soma (Infrastructure)

**Location**: `/[ArchonRoot]/`
**Purpose**: How the Archon INTERACTS

Required directories:
```
/[ArchonRoot]/
├── .claude/                  # → Pneuma layer
│
├── docker/                   # Container services
├── scripts/                  # System scripts
├── docs/                     # User documentation
├── projects/                 # Development workspaces
│   └── project-aion/         # Meta-project
│
├── paths-registry.yaml       # Path configuration
└── CHANGELOG.md              # Version history
```

---

## Neuro Conventions (Navigation Substrate)

The Neuro is the network of connections between layers. Conventions:

### 1. Reference Syntax

Use `@` prefix for cross-references in markdown:
```markdown
See @.claude/context/patterns/wiggum-loop-pattern.md
```

### 2. Index Files

Every major directory must have `_index.md` or `README.md`:
- `_index.md` for navigation hubs with comprehensive listings
- `README.md` for directory purpose and contents

### 3. Breadcrumb Trails

Documents should link to:
- Parent category/index
- Related patterns
- Implementation files (if applicable)

### 4. Hierarchy References

Pattern files should indicate strictness level:
- **ALWAYS** — Mandatory, apply in all cases
- **Recommended** — Apply unless good reason not to
- **Optional** — Apply when relevant

---

## Psyche Requirements (Topology Documentation)

Each Archon must maintain Psyche documents in `context/psyche/`:

### Required Files

| File | Purpose |
|------|---------|
| `_index.md` | Master topology diagram |
| `nous-map.md` | Nous layer detailed map |
| `pneuma-map.md` | Pneuma layer detailed map |
| `soma-map.md` | Soma layer detailed map |
| `README.md` | Directory purpose |

### Content Requirements

Each map must include:
1. Visual directory structure
2. Directory purpose descriptions
3. Key files and their roles
4. Neuro connections (to/from other layers)

---

## Autonomic Components

An Archon should implement these autonomic components:

| ID | Component | Purpose |
|----|-----------|---------|
| AC-01 | Self-Launch | Session initialization |
| AC-02 | Wiggum Loop | Multi-pass verification (DEFAULT) |
| AC-03 | Milestone Review | Quality gates |
| AC-04 | JICM | Context management |
| AC-05 | Self-Reflection | Learning capture |
| AC-06 | Self-Evolution | Self-improvement |
| AC-07 | R&D Cycles | Research |
| AC-08 | Maintenance | Health checks |
| AC-09 | Session Completion | Clean exit |

Component specs go in `context/components/AC-*.md`.

---

## README Standard

Every directory requires a README.md with:

```markdown
# [Directory Name]

**Purpose**: [One-line description]

**Layer**: [Nous | Pneuma | Soma]

---

## What Belongs Here

- [Item type 1]
- [Item type 2]

## What Does NOT Belong Here

- [Item type] → [correct location]

---

*[Archon Name] — [Layer] Layer*
```

---

## Memory MCP Integration

Store key architectural decisions in Memory MCP:

- Entity: `[ArchonName]_Archon_Topology`
- Include: Layer structure, component list, key terminology
- Update: When architecture changes significantly

---

## Checklist for New Archon

- [ ] Create three-layer directory structure
- [ ] Create all required subdirectories
- [ ] Create README.md for every directory
- [ ] Create `_index.md` navigation hubs
- [ ] Create Psyche topology maps
- [ ] Define persona in `[archon]-identity.md`
- [ ] Configure `CLAUDE.md` primary identity
- [ ] Create paths-registry.yaml
- [ ] Define autonomic components
- [ ] Store topology in Memory MCP

---

## Reference Implementation

Jarvis serves as the reference implementation of the Archon Architecture.
See `psyche/_index.md` for the complete topology.

---

*Jarvis — Nous Layer (Patterns)*
