# Soma Layer Topology

Detailed map of the Soma (infrastructure) layer — `/Jarvis/`.

**Version**: 1.0.0

---

## Layer Overview

Soma is how Jarvis INTERACTS — the bridge between self and the external world.

```
/Jarvis/
├── .claude/                  # → Pneuma layer (see pneuma-map.md)
│
├── docker/                   # Container infrastructure
├── scripts/                  # System-level scripts
├── models/                   # Local model storage
├── lancedb/                  # Vector database
├── docs/                     # User documentation
│
├── projects/                 # Development workspaces
│   └── project-aion/         # Jarvis meta-project
│
├── paths-registry.yaml       # Infrastructure paths
├── CHANGELOG.md              # Version history
└── .gitignore                # Git exclusions
```

---

## Infrastructure Directories

### docker/ — Container Services

```
docker/
└── mcp-gateway/              # MCP gateway service
    ├── docker-compose.yaml
    ├── Dockerfile
    └── config/
```

**Purpose**: Container orchestration for external integrations

### scripts/ — System Scripts

| Script | Purpose |
|--------|---------|
| setup-readiness.sh | Pre-setup validation |
| validate-hooks.sh | Hook integrity checks |
| bump-version.sh | Version management |
| weekly-health-check.sh | Scheduled health |
| weekly-docker-restart.sh | Docker maintenance |
| weekly-context-analysis.sh | Context review |
| update-priorities-health.sh | Priority monitoring |

**Note**: These are SYSTEM scripts, not session scripts (which live in `/.claude/scripts/`)

### models/ — Local Models

```
models/
└── (downloaded model files)
```

**Purpose**: Local model storage, embeddings, offline operation

### lancedb/ — Vector Database

```
lancedb/
└── (vector database files)
```

**Purpose**: RAG operations, semantic search, document embeddings

### docs/ — User Documentation

```
docs/
├── user-guide.md             # Main user documentation
└── archive/                  # Historical documentation
```

**Purpose**: User-facing guides (distinct from internal Nous documentation)

---

## Projects Directory

### projects/project-aion/ — Meta-Project

Jarvis working on himself — the self-improvement project.

```
projects/project-aion/
├── roadmap.md                # Master development roadmap
├── versioning-policy.md      # Version bumping rules
│
├── designs/                  # Architecture documents
│   ├── current/              # Active designs
│   └── archive/              # Historical designs
│
├── plans/                    # Implementation plans
│   ├── current/              # Active plans
│   └── archive/              # Completed plans
│
├── progress/                 # Session/milestone tracking
│   ├── current/
│   │   ├── sessions/         # Session summaries
│   │   └── milestones/       # Milestone tracking
│   └── archive/              # Historical progress
│
├── evolution/                # Self-improvement tracking
│   ├── aifred-integration/   # AIfred baseline work
│   │   ├── chronicle.md      # Integration decisions
│   │   ├── roadmap.md        # Integration plan
│   │   └── sync-reports/     # Comparison reports
│   └── self-improvement/     # Autonomic improvements
│
├── ideas/                    # Brainstorms
│   ├── current/              # Active ideas
│   └── archive/              # Archived ideas
│
├── reports/                  # Analysis reports
│   ├── current/              # Active reports
│   └── archive/              # Historical reports
│
├── experiments/              # Experimental work
│   ├── current/              # Active experiments
│   └── archive/              # Completed experiments
│
└── external/                 # External project contexts
```

### Design Principle

**Deliverables stay separate from planning**:
- Planning/progress → `/Jarvis/projects/`
- Actual code → `/Users/aircannon/Claude/<ProjectName>/`
- Jarvis context → `/.claude/context/`

---

## Configuration Files

### paths-registry.yaml

Master registry of all infrastructure paths. Updated after major changes.

| Section | Purpose |
|---------|---------|
| projects | Project workspace paths |
| context | Context file locations |
| capabilities | Tool/agent paths |
| infrastructure | Docker, models, etc. |

### CHANGELOG.md

Version history for Jarvis. Updated on version bumps.

---

## Neuro Connections (From Soma)

### To Nous

```
projects/project-aion/designs/ ◄────── context/designs/ (operational vs project)
projects/project-aion/progress/ ◄───── context/lessons/ (progress→lessons)
projects/project-aion/evolution/ ◄──── context/research/ (research→evolution)
```

### To Pneuma

```
docker/ ◄──────────────────────────── scripts/docker-* (docker operations)
scripts/ ──────────────────────────► .claude/scripts/ (distinct purposes)
models/ ◄──────────────────────────── agents/ (local model usage)
```

### External Connections

```
/Jarvis/ ──────────────────────────► /Users/aircannon/Claude/*  (project codebases)
docker/ ───────────────────────────► External services (via containers)
models/ ◄──────────────────────────── External model sources
```

---

## Key Distinctions

| Aspect | Soma | Pneuma |
|--------|------|--------|
| Scripts | System-level (setup, health) | Session-level (MCP, signals) |
| Reports | Project analysis | Self-improvement outputs |
| Designs | Project architecture | Operational architecture |
| State | Git, paths registry | Component state, queues |

---

## Directory Counts

| Directory | Contents |
|-----------|----------|
| docker/ | 1 service (mcp-gateway) |
| scripts/ | ~10 system scripts |
| models/ | Variable (downloaded models) |
| lancedb/ | Vector database files |
| docs/ | User documentation |
| projects/ | 1 meta-project (project-aion) |

---

*Jarvis — Soma Layer Topology*
