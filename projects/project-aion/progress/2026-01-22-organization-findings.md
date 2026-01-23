# Jarvis Organization Architecture — Findings Document

**Date**: 2026-01-22
**Session**: Organization & Document Management Review
**Status**: Analysis Complete — Implemented
**Note**: Terminology updated to Archon Architecture (Greek naming) per Phase 7

---

## Executive Summary

This document captures the findings from a comprehensive review of Jarvis' directory structure, with the goal of establishing clear organizational principles that distinguish between Jarvis' identity/memory, operational capabilities, and project development work.

The review adopts the **Archon Architecture** with three layers:
1. **Nous** (`/.claude/context/`) — Knowledge, patterns, state, memory
2. **Pneuma** (`/.claude/` excluding context) — Capabilities, persona, tools
3. **Soma** (`/Jarvis/` excluding .claude) — Infrastructure, interfaces, resources

> **Terminology Note**: Originally documented as "Living Soul" architecture with Mind/Spirit/Body layers. Updated 2026-01-22 to Greek terminology: Archon = entity (Jarvis), Aion = project era.

---

## Part 1: The Three-Layer Model

### Layer 1: Nous (`/.claude/context/`)

**Purpose**: What Jarvis KNOWS — accumulated wisdom that shapes decisions.

**Top-level files** (always in active context):
- `session-state.md` — Current work status
- `current-priorities.md` — Active task queue (moved up from projects/)
- `_index.md` — Navigation hub / "Map of the Mind"

**Subdirectory hierarchy** (ordered by abstraction level):

| Directory | Purpose | Strictness |
|-----------|---------|------------|
| `standards/` | Conventions and rules that MUST be followed | Highest |
| `patterns/` | Operational approaches to specific tasks | High |
| `workflows/` | Procedures for completing large tasks within sessions | Medium |
| `designs/` | Operational architecture designs (design philosophy) | Medium |
| `plans/` | Session-level work plans (generalized) | Flexible |
| `components/` | Autonomic Component specifications (AC-01 through AC-09) | Reference |
| `integrations/` | Tool/MCP knowledge and capability matrix | Reference |
| `infrastructure/` | Benchmark, telemetry, SOTA specifications | Reference |
| `lessons/` | Corrections, problem-solution pairs, learnings | Memory |
| `troubleshooting/` | Specific problem resolutions | Memory |
| `reference/` | Quick reference compressed knowledge | Reference |
| `guides/` | How-to documentation | Reference |
| `research/` | R&D agenda and exploration state | State |
| `systems/` | Host/environment documentation | Reference |
| `archive/` | Historical session states | Archive |

**Directories to REMOVE from context/**:
- `templates/` — Subfolders can have their own templates if needed
- `projects/` — Only had current-priorities.md, now moved up
- `upstream/` — Project Aion work, not Jarvis identity
- `analysis/` — Project Aion work, not Jarvis identity

### Layer 2: Pneuma (`/.claude/` excluding context)

**Purpose**: What Jarvis CAN DO — capabilities and character that enable action.

**Top-level files** (the "soul" definition):
- `CLAUDE.md` — Primary persona and behavior definition
- `CLAUDE-full-reference.md` — Extended reference
- `jarvis-identity.md` — Full persona specification (moved from persona/)
- `planning-tracker.yaml` — Registry of active planning/progress docs

**Subdirectory organization**:

| Directory | Purpose | Type |
|-----------|---------|------|
| `commands/` | Slash command definitions | Capability |
| `hooks/` | Event automation hooks | Capability |
| `skills/` | On-demand skill definitions | Capability |
| `agents/` | Agent definitions and memory | Capability |
| `scripts/` | Operational scripts (session-time) | Capability |
| `jobs/` | Scheduled maintenance jobs | Capability |
| `test/` | Test harnesses | Capability |
| `config/` | Runtime configuration | Configuration |
| `secrets/` | Credentials (gitignored) | Configuration |
| `state/` | Component states and queues | Operational State |
| `logs/` | Operational telemetry | Telemetry |
| `metrics/` | Performance metrics | Telemetry |
| `reports/` | Self-improvement cycle outputs | Operational Memory |
| `review-criteria/` | PR review standards | Standards |
| `orchestration/` | Task orchestration templates | Templates |
| `legal/` | Attribution, licenses | Metadata |
| `archive/` | General archives | Archive |

**Directories to REMOVE/MERGE**:
- `persona/` — Move contents up to top-level
- `evolution/` — Merge evolution-queue.yaml into `state/queues/`
- `plans/` — Move to `context/plans/` for session work plans

### Layer 3: Soma (`/Jarvis/` excluding .claude)

**Purpose**: How Jarvis INTERACTS — bridge between self and external world.

| Directory | Purpose |
|-----------|---------|
| `docker/` | Docker infrastructure |
| `docs/` | User-facing documentation |
| `external-sources/` | External dependencies |
| `lancedb/` | Vector database |
| `models/` | Local model storage |
| `projects/` | Project development workspaces |
| `scripts/` | System-level utilities (setup, weekly) |

**Root files**: CHANGELOG.md, VERSION, README.md, paths-registry.yaml

---

## Part 2: Specific Findings

### Finding 1: AIfred Integration Work is Misplaced

**Current location**: `/.claude/context/upstream/`
**Problem**: This is Project Aion development work, not Jarvis identity
**Contents**:
- integration-chronicle.md
- integration-roadmap-2026-01-21.md
- integration-recommendations-2026-01-21.md
- code-comparison-2026-01-21.md
- comprehensive-analysis-2026-01-21.md
- adhoc-assessment-*.md
- sync-report-*.md
- port-log.md

**Solution**: Move to `projects/project-aion/evolution/aifred-integration/`

### Finding 2: Analysis Artifacts are Misplaced

**Current location**: `/.claude/context/analysis/`
**Problem**: Contains `aifred-commands-catalog.md` — Project Aion work
**Solution**: Move to `projects/project-aion/analysis/`

### Finding 3: Redundant State Directories

**Issue**: `/.claude/evolution/` only contains `evolution-queue.yaml`
**Better location**: `/.claude/state/queues/evolution-queue.yaml`
**Action**: Merge and remove redundant directory

### Finding 4: Orphan Plans File

**Current location**: `/.claude/plans/humming-purring-adleman.md`
**Problem**: Single file in isolation, unclear purpose
**Solution**: Archive to Project Aion plans, repurpose `plans/` in context/

### Finding 5: Templates Directory is Redundant

**Current location**: `/.claude/context/templates/`
**Problem**: Centralized templates not needed; subfolders can have their own
**Solution**: Distribute templates to relevant directories, remove centralized folder

### Finding 6: Persona Files Should Be Top-Level

**Current location**: `/.claude/persona/`
**Problem**: Persona is core identity, should be alongside CLAUDE.md
**Solution**: Move `jarvis-identity.md` to `/.claude/jarvis-identity.md`

### Finding 7: current-priorities.md is Buried

**Current location**: `/.claude/context/projects/current-priorities.md`
**Problem**: Core operational file buried in subdirectory
**Solution**: Move to `/.claude/context/current-priorities.md`

### Finding 8: Some Orchestrations are Project Work

**Current location**: `/.claude/orchestration/`
**Problem**: Contains project-specific orchestrations mixed with templates
**Files to move**:
- `demo-a-orchestration.yaml` → Project Aion
- `phase-6-implementation.yaml` → Project Aion
- `2026-01-20-autonomous-command-wrappers.yaml` → Project Aion
**Keep**: `_template.yaml`, `README.md`

### Finding 9: Empty Report Subdirectories

**Location**: `/.claude/reports/evolutions/`, `research/`, `reviews/`
**Status**: Empty but intentionally prepared for AC-06, AC-07, AC-03 outputs
**Action**: Keep — these are correct placements awaiting content

### Finding 10: designs/ in context/ is Empty

**Current location**: `/.claude/context/designs/`
**Status**: Empty with .gitkeep
**Decision**: Repurpose for operational architecture designs (design philosophy, not project-specific designs)

---

## Part 3: Project Aion Structure

### Current State
```
projects/project-aion/
├── archon-identity.md
├── roadmap.md
├── versioning-policy.md
├── ideas/ (17 files, flat)
├── plans/ (13 files, includes prd-variants/)
├── reports/ (43 files, flat)
└── experiments/
```

### Proposed State
```
projects/project-aion/
├── roadmap.md
├── versioning-policy.md
├── archon-identity.md
│
├── designs/
│   ├── current/
│   │   └── phase-6-autonomy-design.md
│   └── archive/
│
├── ideas/
│   ├── current/
│   └── archive/
│
├── plans/
│   ├── current/
│   │   └── prd-variants/
│   └── archive/
│
├── progress/
│   ├── current/
│   │   ├── sessions/
│   │   └── milestones/
│   └── archive/
│
├── reports/
│   ├── current/
│   │   ├── testing/
│   │   ├── analysis/
│   │   └── experiments/
│   └── archive/
│
├── experiments/
│   ├── current/
│   └── archive/
│
├── evolution/
│   ├── aifred-integration/
│   │   ├── chronicle.md
│   │   ├── roadmap.md
│   │   └── sync-reports/
│   └── self-improvement/
│
├── analysis/
│   └── aifred-commands-catalog.md
│
└── external/
    └── [external project workspaces]
```

---

## Part 4: Planning Tracker Design

**Location Decision**: `/.claude/planning-tracker.yaml`

**Rationale**: This is operational state that Jarvis uses during sessions to know which documents to review. It sits at the Spirit layer alongside CLAUDE.md because it's about HOW Jarvis operates, not WHAT Jarvis knows.

**Structure**:
```yaml
# Active documents with checklists/exit criteria
# Jarvis maintains this as docs are created/archived

version: 1.0.0
last_updated: 2026-01-22

planning:
  - path: projects/project-aion/roadmap.md
    contains: [pr-status, deliverables, acceptance-criteria]
    scope: project-aion

  - path: projects/project-aion/designs/current/phase-6-autonomy-design.md
    contains: [sub-pr-checklists, acceptance-criteria]
    scope: phase-6

progress:
  - path: .claude/context/session-state.md
    contains: [current-work, next-steps]
    scope: active-session
    always_review: true

  - path: .claude/context/current-priorities.md
    contains: [task-status, recently-completed]
    scope: priorities
    always_review: true
```

---

## Part 5: Selection System Enhancement

The `patterns/` directory contains 40+ patterns. To ensure Jarvis unfailingly references them:

### CLAUDE.md Enhancement (Quick Selection Matrix)

Add to CLAUDE.md a strict selection directive:

```markdown
## Pattern Selection (MANDATORY)

Before beginning ANY significant task, consult the appropriate pattern:

| Task Type | Required Pattern | Location |
|-----------|-----------------|----------|
| Multi-step implementation | Wiggum Loop | @patterns/wiggum-loop-pattern.md |
| Milestone completion | Milestone Review | @patterns/milestone-review-pattern.md |
| Tool/agent selection | Selection Intelligence | @patterns/selection-intelligence-guide.md |
| Context management | JICM | @patterns/jicm-pattern.md |
| Session start | Startup Protocol | @patterns/startup-protocol.md |
| Session end | Session Exit | @workflows/session-exit.md |
| MCP loading | Context Budget | @patterns/context-budget-management.md |
| Research tasks | Agent Selection | @patterns/agent-selection-pattern.md |

**Wiggum Loop is DEFAULT** — multi-pass verification on all non-trivial tasks.
```

### patterns/_index.md Enhancement

Create a categorized index with selection guidance:

```markdown
## Pattern Categories

### Behavioral (ALWAYS follow)
- wiggum-loop-pattern.md — Multi-pass verification
- startup-protocol.md — Session initialization
- session-exit-workflow.md — Clean termination

### Selection (Consult for tool choices)
- selection-intelligence-guide.md — Master selection guide
- agent-selection-pattern.md — Agent vs subagent
- mcp-loading-strategy.md — MCP tier decisions

### Technical (Reference as needed)
- jicm-pattern.md — Context management
- context-budget-management.md — Token optimization
- milestone-review-pattern.md — Quality gates
```

---

## Part 6: Key Principles Established

### Principle 1: Top-Level Files are Sacred

**`/.claude/context/` top-level** (Mind's surface):
- `session-state.md`
- `current-priorities.md`
- `_index.md` (Map of the Mind)

**`/.claude/` top-level** (Soul's core):
- `CLAUDE.md`
- `CLAUDE-full-reference.md`
- `jarvis-identity.md`
- `planning-tracker.yaml`

**Everything else goes in subfolders** — strong argument required for top-level placement.

### Principle 2: Hierarchy of Behavioral Guidance

```
Standards (MUST follow)
    ↓
Patterns (SHOULD follow)
    ↓
Workflows (Procedures for large tasks)
    ↓
Designs (Architecture philosophy)
    ↓
Plans (Session-level work plans)
```

### Principle 3: Project Work vs Identity

- **Identity** (stays in /.claude): How Jarvis behaves, regardless of project
- **Project Work** (goes to projects/): Specific development artifacts

Test: "Would a fresh Jarvis instance need this?" → Yes = Identity, No = Project

### Principle 4: Templates are Local

No centralized `templates/` directory. Each subdirectory can have its own `templates/` if needed.

### Principle 5: current/archive Organization

All Project Aion directories use `current/` and `archive/` subdirectories for lifecycle management.

---

## Appendix: Complete Directory Inventory

### Directories to CREATE
- `projects/project-aion/designs/current/`
- `projects/project-aion/designs/archive/`
- `projects/project-aion/progress/current/sessions/`
- `projects/project-aion/progress/current/milestones/`
- `projects/project-aion/progress/archive/`
- `projects/project-aion/evolution/aifred-integration/`
- `projects/project-aion/evolution/self-improvement/`
- `projects/project-aion/analysis/`
- `projects/project-aion/external/`
- `.claude/context/plans/`

### Directories to REMOVE
- `.claude/context/templates/` (distribute contents first)
- `.claude/context/projects/` (after moving current-priorities.md)
- `.claude/context/upstream/` (after moving contents)
- `.claude/context/analysis/` (after moving contents)
- `.claude/persona/` (after moving contents)
- `.claude/evolution/` (after merging)
- `.claude/plans/` (after archiving orphan file)

### Files to MOVE
See Implementation Plan document for complete list.

---

*Findings Document — Jarvis Organization Architecture Review 2026-01-22*
