# Project Aion — Archon Identity

*Last updated: 2026-01-05*

---

## Overview

**Project Aion** is a collection of specialized AI assistants called **Archons**, derived from but divergent from the [AIfred baseline](https://github.com/davidmoneil/AIfred) by David O'Neil.

Each Archon is a distinct AI infrastructure configuration optimized for specific domains and workflows. Archons share common ancestry with AIfred but evolve independently to serve specialized purposes.

---

## Core Terminology

| Term | Definition |
|------|------------|
| **Project Aion** | The umbrella project containing all Archons |
| **Archon** | A specialized AI assistant configuration derived from AIfred |
| **AIfred baseline** | The upstream template repository (read-only reference) |
| **Port** | Adapting an upstream change for use in an Archon |

---

## The Archons

### Jarvis — Master Archon

**Role**: Development + Infrastructure + Archon Builder

Jarvis is the "master" Archon: a highly autonomous, self-improving, tool-rich AI infrastructure and software-development assistant.

**Capabilities**:
- Installs, validates, and uses MCP servers, Claude skills, and plugins
- Orchestrates agentic workflows for real project delivery
- Maintains session continuity, auditability, and versioned self-evolution
- Benchmarks itself against end-to-end demos
- Builds and configures other Archons

**Status**: Active (v1.2.0)

---

### Jeeves — Always-On Archon

**Role**: Personal Automation via Scheduled Jobs

Jeeves is an always-on Archon triggered by cron jobs for personal automation tasks that run without user initiation.

**Planned Capabilities**:
- Calendar reminders and scheduling assistance
- Daily encouragement and motivational content
- Scripture readings and thoughtful reflections
- Productivity tips and creative ideas
- Proactive notifications and alerts

**Status**: Concept Stage (not yet implemented)

---

### Wallace — Creative Writer Archon

**Role**: Creative Writing and Content Generation

Wallace is a creative writer Archon optimized for fiction, storytelling, and long-form content generation.

**Planned Capabilities**:
- Fiction writing assistance
- Story development and plot structuring
- Character development
- Worldbuilding
- Editorial feedback

**Status**: Concept Stage (not yet implemented)

---

## Relationship to Upstream

### AIfred Baseline

Project Aion Archons are **derived from** the AIfred baseline but follow a **divergent development track**.

| Aspect | Policy |
|--------|--------|
| Repository | [davidmoneil/AIfred](https://github.com/davidmoneil/AIfred) |
| Development Branch | `Project_Aion` — All Archon development |
| Baseline Branch | `main` — **Read-only** reference |
| Baseline Commit | `dc0e8ac` (2026-01-03) |
| Sync Method | Pull from `main` → Diff → Propose → Apply to `Project_Aion` only |
| Merge Back | Not intended — Archons diverge from baseline |

### Upstream Sync Workflow

Archons may incorporate improvements from the AIfred baseline through a controlled porting process:

1. **Pull**: Fetch AIfred baseline main into local mirror (`/Users/aircannon/Claude/AIfred`)
2. **Diff**: Compare baseline changes against Archon
3. **Classify**: Categorize changes as safe / unsafe / manual review
4. **Propose**: Generate port proposal with rationale
5. **Apply**: After user review, apply to Archon repo only

A port log tracks decisions with "adopt / adapt / reject" status and rationale.

---

## Safety Rules

### Baseline Read-Only Rule

> **Critical**: The AIfred baseline repository is **read-only** from Project Aion's perspective.

**Allowed Operations**:
- `git clone` from AIfred baseline
- `git fetch` / `git pull` from AIfred baseline main
- Reading files for diff/analysis

**Prohibited Operations**:
- Commits to AIfred baseline
- File edits within AIfred baseline
- Branch creation in AIfred baseline
- Hooks or config changes to AIfred baseline

### Workspace Boundaries

Archons operate within explicitly allowlisted directories:
- Archon's own workspace (e.g., `/Users/aircannon/Claude/Jarvis/`)
- Active target project workspace(s)
- Registered project paths in `paths-registry.yaml`

---

## Creating New Archons

New Archons should be created using Jarvis. Each new Archon:

1. Starts from a fresh AIfred baseline clone or Jarvis template
2. Receives its own identity document
3. Is registered in Project Aion documentation
4. Includes version tracking that references:
   - Its own version
   - The Jarvis version used to create it
   - The AIfred baseline commit it derives from

### Archon Registration Template

```markdown
### [Archon Name] — [Role Title]

**Role**: [Brief description]

[Detailed description of purpose and capabilities]

**Planned Capabilities**:
- Capability 1
- Capability 2

**Status**: [Active (vX.X.X) | Concept Stage | Development]

**Created**: Using Jarvis vX.X.X
**Baseline**: AIfred commit [hash]
```

---

## Version Tracking Across Archons

Each Archon maintains its own version while tracking lineage:

| Archon | Current Version | Created With | Baseline |
|--------|-----------------|--------------|----------|
| Jarvis | 1.2.0 | — | dc0e8ac |
| Jeeves | — | (pending) | — |
| Wallace | — | (pending) | — |

See [versioning-policy.md](./versioning-policy.md) for detailed versioning rules.

---

*Project Aion — Specialized AI Assistants for Every Purpose*
