# Phase 7: Archon Architecture & Navigation Strengthening

**Status**: Planning
**Scope**: Expanded Phase 7 — terminology replacement + navigation substrate (Neuro) strengthening
**Branch**: Project_Aion

---

## Overview

Phase 7 transforms the "Living Soul Architecture" into the **Archon Architecture** with Greek terminology, while simultaneously strengthening the navigation substrate (Neuro) that allows Jarvis to efficiently traverse from abstract intent to concrete action.

### Terminology Distinction

| Term | Greek | Meaning | Usage |
|------|-------|---------|-------|
| **Aion** (αἰών) | ay-ON | Age, epoch, eternity | The PROJECT — an era of autonomic AI entities |
| **Archon** (ἄρχων) | AR-kon | Ruler, leader, chief | The ENTITIES — individual autonomous agents (Jarvis is an Archon) |

**Project Aion** = The initiative to create autonomous AI entities
**Archon Architecture** = The pattern/blueprint for how an Archon is structured

### Greek Terminology Mapping

| Current | Greek | Pronunciation | Meaning |
|---------|-------|---------------|---------|
| Living Soul Architecture | **Archon Architecture** | AR-kon | The blueprint for autonomous entities |
| Mind Layer | **Nous Layer** | NOOS | Intellect, reason, understanding |
| Spirit Layer | **Pneuma Layer** | NYOO-mah | Breath, spirit, vital force |
| Body Layer | **Soma Layer** | SOH-mah | Physical body, form |
| Navigation substrate | **Neuro** (νεύρο) | NYOO-roh | Nerves, sinews — connections between layers |
| Network maps | **Psyche** (ψυχή) | sy-KEE | Soul — documented topology of the Neuro |

### Architectural Mapping

| Layer | Directory | Purpose |
|-------|-----------|---------|
| **Nous** | `/.claude/context/` | Knowledge, patterns, state |
| **Pneuma** | `/.claude/` | Capabilities, persona, tools |
| **Soma** | `/Jarvis/` | Infrastructure, interfaces |

### Neuro & Psyche Concepts

**Neuro** = The actual connections — cross-references, links, breadcrumb trails, @references
- Like nerves connecting thought (Nous) to action (Soma)
- The pathways that allow navigation from intent to implementation

**Psyche** = The documented maps OF the Neuro
- Master topology showing how all parts connect
- Stored in Memory MCP AND documentation files
- The "you are here" maps of Jarvis's internal structure

---

## Task Breakdown

### Part A: Terminology Replacement (~45 instances)

#### A1. Critical Documentation (Update First)
Files that define the architecture terminology:

1. **`.claude/context/_index.md`** — 7 instances
   - Version header: "Living Soul Architecture" → "Archon Architecture"
   - Section heading: "The Living Soul Architecture" → "The Archon Architecture"
   - Architecture table: Mind/Spirit/Body → Nous/Pneuma/Soma
   - Footer reference

2. **`.claude/context/standards/readme-standard.md`** — 6 instances
   - Template examples for layer footers
   - Hierarchy section headers

3. **`projects/project-aion/progress/2026-01-22-organization-findings.md`** — Multiple
   - Analysis document (historical, update for consistency)

4. **`projects/project-aion/plans/current/2026-01-22-organization-implementation-plan.md`** — Multiple
   - Implementation guide (historical, update for consistency)

#### A2. Session & Reflection Docs
5. **`.claude/context/session-state.md`** — 2 instances
6. **`.claude/reports/reflections/reflection-2026-01-22-2.md`** — 1 instance

#### A3. README Files (~35 files)
All README.md files with "*Jarvis — [Layer] Layer*" footers:

**Nous Layer** (17 READMEs in `.claude/context/*/`):
- research, designs, archive, plans, workflows, troubleshooting
- integrations, components, guides, lessons, systems, infrastructure
- patterns, standards, reference, upstream, etc.

**Pneuma Layer** (15 READMEs in `.claude/*/`):
- metrics, archive, test, config, secrets, review-criteria
- agents, state, scripts, commands, skills, reports, hooks, plugins

**Soma Layer** (5 READMEs in root directories):
- docker, projects, models, docs, scripts, lancedb

---

### Part B: Neuro Strengthening (Navigation Substrate)

#### B1. Create Glossary (HIGH PRIORITY)
**File**: `.claude/context/reference/glossary.md`

Define 50+ terms including:
- Aion, Archon (project vs entity distinction)
- Archon Architecture, Nous, Pneuma, Soma, Neuro, Psyche
- AC-01 through AC-09 (component IDs)
- Wiggum Loop, Ralph Loop, JICM
- PARC (Problem-Approach-Result-Considerations)
- DDLA, COSA, MCP, TodoWrite, etc.

#### B2. Create Component Orchestration Diagram
**File**: `.claude/context/components/orchestration-overview.md`

Document how AC-01 through AC-09 interact:
```
Session Start
    ↓
AC-01: Self-Launch
    ├─→ AC-02: Wiggum Loop (DEFAULT)
    │   ├─→ AC-03: Milestone Review
    │   ├─→ AC-04: JICM (context management)
    │   └─→ AC-05: Self-Reflection
    │
    └─→ AC-06: Self-Evolution (idle time)
        ├─→ AC-07: R&D Cycles
        └─→ AC-08: Maintenance
            ↓
        AC-09: Session Completion
```

#### B3. Create Parallelization Strategy Pattern
**File**: `.claude/context/patterns/parallelization-strategy.md`

Document:
- When to run tools/agents in parallel vs sequential
- MCP batching for token efficiency
- Examples of parallel dispatch patterns
- Independence criteria for parallel execution

#### B4. Create Generalist-to-Orchestrator Transition Guide
**File**: `.claude/context/designs/orchestration-philosophy.md`

Document:
- Design philosophy for coordinating vs executing
- When to delegate to agents vs self-execute
- Selection intelligence cascade
- Recursive loop composition (Wiggum within Wiggum)

#### B5. Consolidate MCP Decision Navigation
**File**: `.claude/context/reference/mcp-decision-map.md`

Consolidate from 4 scattered sources:
- capability-matrix.md (Tier 1/2/3)
- mcp-loading-strategy.md
- context-budget-management.md
- mcp-design-patterns.md

Single page answering: "Which MCP(s) for task X?"

#### B6. Create Troubleshooting Index
**File**: `.claude/context/troubleshooting/_index.md`

Index existing troubleshooting docs + common problems:
- MCP failures
- Hook errors
- Context exhaustion
- Agent failures
- Git/commit issues

#### B7. Create Pattern Dependency Graph
**Update**: `.claude/context/patterns/_index.md`

Add "Prerequisites" column to pattern table:
- Which patterns must be read before others
- Explicit dependency ordering

#### B8. Enhance CLAUDE.md Navigation
**Update**: `.claude/CLAUDE.md`

Add sections:
- Architecture overview (Archon/Nous/Pneuma/Soma/Neuro/Psyche)
- Link to component orchestration diagram
- Link to glossary
- Link to troubleshooting index
- Clarify Aion (project) vs Archon (entity) terminology

#### B9. Create Psyche Documents (Network Topology Maps)
The Psyche is the documented map of the Neuro (navigation connections).

**File**: `.claude/context/psyche/nous-map.md`
- Map of all Nous layer components and their connections
- Cross-references to Pneuma and Soma layers

**File**: `.claude/context/psyche/pneuma-map.md`
- Map of all Pneuma layer components (skills, agents, hooks, commands)
- How they connect to Nous knowledge and Soma infrastructure

**File**: `.claude/context/psyche/soma-map.md`
- Map of Soma layer infrastructure (Docker, scripts, projects)
- Integration points with Pneuma capabilities

**File**: `.claude/context/psyche/_index.md`
- Master topology showing the complete Archon structure
- Visual diagram of three-layer interconnections
- "You are here" navigation aid

#### B10. Memory MCP Integration
**Entity**: `Jarvis_Archon_Topology`

Store in Memory MCP:
- Core architectural relationships
- Key Neuro pathways (most important connections)
- Entity relationships: Jarvis → Nous → patterns → implementations
- Decisions about architecture evolution

This creates a dual-storage approach:
- **Psyche docs** = Human-readable detailed maps
- **Memory MCP** = Machine-queryable relationship graph

---

### Part C: Cross-Reference Verification

#### C1. Verify No Broken Links
Scan all .md files for:
- `@` references to moved/renamed files
- Internal markdown links
- paths-registry.yaml accuracy

#### C2. Create archon-architecture-pattern.md
**File**: `.claude/context/patterns/archon-architecture-pattern.md`

Document the Archon Architecture as a reusable pattern for other Archons:
- Three-layer structure (Nous/Pneuma/Soma)
- Neuro conventions (how to create navigation substrate)
- Psyche requirements (topology documentation)
- README standards
- Index file requirements
- Navigation breadcrumb conventions

This becomes THE reference for designing future Archons in Project Aion.

---

## Implementation Order

### Phase 7.1: Terminology Foundation
1. Update `readme-standard.md` with Greek terms (sets template)
2. Update `_index.md` with Archon Architecture
3. Update all README footers (batch operation using new standard)
4. Update historical docs (findings, plans, reflections) with Aion/Archon distinction noted
5. Update session-state.md

### Phase 7.2: Neuro Infrastructure (Navigation Substrate)
1. Create glossary.md (includes Aion/Archon distinction)
2. Create orchestration-overview.md
3. Create parallelization-strategy.md
4. Create orchestration-philosophy.md
5. Create mcp-decision-map.md
6. Create troubleshooting/_index.md

### Phase 7.3: Psyche Documentation (Topology Maps)
1. Create `.claude/context/psyche/` directory
2. Create nous-map.md (Nous layer topology)
3. Create pneuma-map.md (Pneuma layer topology)
4. Create soma-map.md (Soma layer topology)
5. Create psyche/_index.md (master topology)
6. Store key relationships in Memory MCP (Jarvis_Archon_Topology entity)

### Phase 7.4: Integration & Verification
1. Update patterns/_index.md with dependencies
2. Update CLAUDE.md with Archon Architecture and navigation links
3. Verify all cross-references (no broken Neuro pathways)
4. Create archon-architecture-pattern.md

### Phase 7.5: Commit
Single commit capturing all Phase 7 work:
```
refactor: Implement Archon Architecture with Greek terminology

- Establish Aion (project) vs Archon (entity) distinction
- Replace Living Soul → Archon, Mind → Nous, Spirit → Pneuma, Body → Soma
- Introduce Neuro (navigation substrate) and Psyche (topology maps) concepts
- Add glossary, orchestration diagram, parallelization pattern
- Create Psyche directory with layer topology maps
- Create navigation aids: MCP decision map, troubleshooting index
- Store Archon topology in Memory MCP
```

---

## Files to Create (13)

| File | Purpose |
|------|---------|
| `.claude/context/reference/glossary.md` | 50+ term definitions (Aion/Archon distinction) |
| `.claude/context/components/orchestration-overview.md` | AC interaction diagram |
| `.claude/context/patterns/parallelization-strategy.md` | Parallel execution guide |
| `.claude/context/designs/orchestration-philosophy.md` | Generalist→orchestrator |
| `.claude/context/reference/mcp-decision-map.md` | Consolidated MCP selection |
| `.claude/context/troubleshooting/_index.md` | Problem-type navigation |
| `.claude/context/patterns/archon-architecture-pattern.md` | Archon as reusable pattern |
| `.claude/context/reference/quick-navigation.md` | Mid-task reference card |
| `.claude/context/psyche/_index.md` | Master Archon topology |
| `.claude/context/psyche/nous-map.md` | Nous layer topology |
| `.claude/context/psyche/pneuma-map.md` | Pneuma layer topology |
| `.claude/context/psyche/soma-map.md` | Soma layer topology |
| `.claude/context/psyche/README.md` | Directory README |

## Memory MCP Entities to Create (1)

| Entity | Purpose |
|--------|---------|
| `Jarvis_Archon_Topology` | Machine-queryable relationship graph of Archon structure |

## Files to Update (~50)

| Category | Count | Updates |
|----------|-------|---------|
| Critical docs | 4 | _index.md, readme-standard.md, findings, plan |
| Session docs | 2 | session-state.md, reflection |
| README files | 37 | Layer footer terminology (Nous/Pneuma/Soma) |
| Pattern index | 1 | Add dependency column |
| CLAUDE.md | 1 | Add navigation links, Archon Architecture section |
| CLAUDE-full-reference.md | 1 | Add new document links |

---

## Verification

### Terminology Verification
```bash
# Should return 0 results after completion
grep -r "Living Soul" .claude/ projects/
grep -r "Mind Layer" .claude/ projects/
grep -r "Spirit Layer" .claude/ projects/
grep -r "Body Layer" .claude/ projects/
```

### Navigation Verification (Neuro Integrity)
- [ ] Glossary contains all AC-* components + Aion/Archon distinction
- [ ] Orchestration diagram shows all 9 components
- [ ] CLAUDE.md links to all new navigation docs
- [ ] patterns/_index.md has prerequisite column
- [ ] All @references in .md files resolve (no broken Neuro pathways)

### Psyche Verification (Topology Completeness)
- [ ] psyche/_index.md shows complete three-layer topology
- [ ] nous-map.md covers all `.claude/context/` directories
- [ ] pneuma-map.md covers all `.claude/` capabilities
- [ ] soma-map.md covers all `/Jarvis/` infrastructure
- [ ] Memory MCP entity `Jarvis_Archon_Topology` created with key relationships

### Architecture Verification
- [ ] Archon Architecture properly defined in _index.md
- [ ] Aion vs Archon distinction documented in glossary
- [ ] archon-architecture-pattern.md is complete and reusable
- [ ] Greek terminology consistent across all files

---

## Notes

- README updates can be batched with careful search/replace
- Historical documents (findings, plans) updated for consistency with Aion/Archon note
- **Aion** = Project (epoch of autonomous AI) — used in project-level context
- **Archon** = Entity (Jarvis is an Archon) — used in architectural context
- **Neuro** = The connections themselves (cross-refs, links, breadcrumbs)
- **Psyche** = The documented maps of those connections
- Glossary becomes the canonical definition source for all terminology
- Memory MCP provides machine-queryable complement to Psyche docs
