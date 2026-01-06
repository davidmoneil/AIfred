# Workspace Path Policy

*Last updated: 2026-01-05*
*Established: PR-1.E*

---

## Overview

This document defines the canonical locations for all Jarvis-managed workspaces, projects, and documentation. Following this policy ensures predictable, organized file placement.

---

## Path Hierarchy

```
/Users/aircannon/Claude/
├── AIfred/                    # AIfred baseline (READ-ONLY mirror)
├── Jarvis/                    # Jarvis Archon workspace (this repo)
│   ├── .claude/
│   │   └── context/           # BEHAVIOR: Patterns, standards, workflows
│   └── projects/
│       └── project-aion/      # EVOLUTION: Roadmap, plans, ideas
├── <ProjectName>/             # External project workspaces
└── <OtherArchon>/             # Future Archons (Jeeves, Wallace, etc.)
```

---

## Canonical Paths

### 1. Projects Root

**Path**: `/Users/aircannon/Claude/`

This is the root directory for all Claude-assisted projects. Each project gets its own subdirectory.

| Content | Location |
|---------|----------|
| External projects | `/Users/aircannon/Claude/<ProjectName>/` |
| Jarvis itself | `/Users/aircannon/Claude/Jarvis/` |
| AIfred baseline | `/Users/aircannon/Claude/AIfred/` (read-only) |
| Future Archons | `/Users/aircannon/Claude/<ArchonName>/` |

### 2. Jarvis Project Summaries

**Path**: `/Users/aircannon/Claude/Jarvis/projects/`

When Jarvis works on external projects, it creates **summary documents** here (not code). These summaries provide context about projects without duplicating their content.

**Template**: `knowledge/templates/project-summary.md`

| Content Type | Location |
|--------------|----------|
| Project summary files | `projects/<project-name>.md` |
| Run reports | `projects/<project-name>-report-<date>.md` |
| Benchmark outputs | `projects/<project-name>-benchmark-<date>.md` |

**Example**: Working on a project called "MyApp":
- Code lives at: `/Users/aircannon/Claude/MyApp/`
- Summary lives at: `/Users/aircannon/Claude/Jarvis/projects/myapp.md`

### 3. Project Aion Documentation (EVOLUTION)

**Path**: `/Users/aircannon/Claude/Jarvis/projects/project-aion/`

Project Aion is special—Jarvis is working on itself. All evolution documentation lives here.

| Document | Path |
|----------|------|
| Feature Roadmap | `projects/project-aion/roadmap.md` |
| Archon Identity | `projects/project-aion/archon-identity.md` |
| Versioning Policy | `projects/project-aion/versioning-policy.md` |
| One-shot PRD | `projects/project-aion/one-shot-prd.md` |
| PR Implementation Plans | `projects/project-aion/plans/` |
| Brainstorms & Ideas | `projects/project-aion/ideas/` |

**Design Principle**: BEHAVIOR vs EVOLUTION separation
- **BEHAVIOR** (how Jarvis operates) → `.claude/context/`
- **EVOLUTION** (how Jarvis improves) → `projects/project-aion/`

### 4. AIfred Baseline Mirror

**Path**: `/Users/aircannon/Claude/AIfred/`

**STATUS: READ-ONLY**

This is a local mirror of the upstream AIfred baseline. It is used only for:
- Fetching updates: `git fetch` / `git pull`
- Comparing changes for potential porting

**Prohibited operations:**
- Editing files
- Creating commits
- Creating branches
- Adding hooks or configs

---

## Path Registry Integration

The `paths-registry.yaml` file at Jarvis root is the source of truth for all paths. Key entries:

```yaml
projects_root: /Users/aircannon/Claude
jarvis_root: /Users/aircannon/Claude/Jarvis
jarvis_summaries: /Users/aircannon/Claude/Jarvis/projects
jarvis_project_aion: /Users/aircannon/Claude/Jarvis/projects/project-aion
aifred_baseline: /Users/aircannon/Claude/AIfred  # READ-ONLY

development:
  projects:
    # External projects registered here
```

---

## Decision Rules

### Where Does Code Go?

| Scenario | Location |
|----------|----------|
| New external project | `/Users/aircannon/Claude/<ProjectName>/` |
| Jarvis internal changes | `/Users/aircannon/Claude/Jarvis/` |
| New Archon | `/Users/aircannon/Claude/<ArchonName>/` |
| Benchmarks (Demo apps) | `/Users/aircannon/Claude/<DemoName>/` |

### Where Do Docs Go?

| Document Type | Location |
|---------------|----------|
| Project context summary | `Jarvis/projects/<name>.md` |
| Project Aion (EVOLUTION) | `Jarvis/projects/project-aion/` |
| Jarvis BEHAVIOR patterns | `Jarvis/.claude/context/` |
| Project-specific docs | `<ProjectName>/docs/` |

### "Hub, Not Container" Principle

Jarvis is a **hub** that orchestrates projects stored elsewhere. It does not contain project code within itself (except its own codebase). This means:

- ✅ Jarvis tracks projects via summaries and registry
- ✅ Jarvis creates/clones projects at the projects root
- ✅ Jarvis stores its own evolution docs internally
- ❌ Jarvis does NOT embed project codebases within itself

---

## Examples

### Example 1: User Provides GitHub URL

```
User: "Clone https://github.com/example/myapp"

Action:
1. Clone to: /Users/aircannon/Claude/myapp/
2. Create summary: /Users/aircannon/Claude/Jarvis/projects/myapp.md
3. Register in: paths-registry.yaml under development.projects
```

### Example 2: User Says "New Project"

```
User: "Create a new project called DataPipeline"

Action:
1. Create at: /Users/aircannon/Claude/DataPipeline/
2. Initialize: git, README, .claude/CLAUDE.md
3. Create summary: /Users/aircannon/Claude/Jarvis/projects/DataPipeline.md
4. Register in: paths-registry.yaml
```

### Example 3: Benchmark Demo

```
Task: Execute one-shot PRD demo

Action:
1. Create repo at: /Users/aircannon/Claude/aion-hello-console-2026-01-05/
2. Push to: github.com/CannonCoPilot/aion-hello-console-2026-01-05
3. Create report: /Users/aircannon/Claude/Jarvis/projects/aion-hello-console-report.md
```

---

## Related Documents

- @paths-registry.yaml — Path registry source of truth
- @projects/project-aion/archon-identity.md — Project Aion identity
- @.claude/context/patterns/session-start-checklist.md — Session checklist including path context

---

*Pattern: Workspace Path Policy — Established PR-1.E, Updated PR-4c*
