# Context Index

Central navigation for the AIfred knowledge base.

---

## Quick Access

| Need | Location |
|------|----------|
| Current work status | @.claude/context/session-state.md |
| Active tasks | @.claude/context/projects/current-priorities.md |
| All paths | @paths-registry.yaml |

---

## Knowledge Base Structure

### Systems (Infrastructure Documentation)
```
systems/
├── _template.md          # Template for new services
└── (your services here)
```

**Purpose**: Reference documentation for infrastructure. Created via `/discover` command.

### Projects (Active Initiatives)
```
projects/
└── current-priorities.md  # Active todos and priorities
```

**Purpose**: Track ongoing work and priorities.

### Workflows (Repeatable Procedures)
```
workflows/
├── session-exit.md       # End session procedure
└── _template.md          # Template for new workflows
```

**Purpose**: Step-by-step guides for recurring tasks.

### Standards (Conventions & Terminology)
```
standards/
├── _index.md                   # Standards directory index
├── severity-status-system.md   # Universal severity levels, status values
└── model-selection.md          # When to use Opus vs Sonnet vs Haiku
```

**Purpose**: Project-wide standards for naming, classification, and terminology. Ensures consistency across commands, scripts, and documentation.

**Active Standards**:
- ✅ **Severity/Status System**: `[X] CRITICAL` / `[!] HIGH` / `[~] MEDIUM` / `[-] LOW`
- ✅ **Model Selection**: Opus for architecture, Sonnet for dev, Haiku for quick checks

### Patterns (Reusable Implementations)
```
patterns/
├── _index.md                    # Patterns directory index
├── agent-selection-pattern.md   # Choose agents vs subagents vs skills vs tools
├── memory-storage-pattern.md    # When/how to store in Memory MCP
├── prompt-design-review.md      # PARC pattern for design review
├── session-start-checklist.md   # Mandatory session start steps
├── branching-strategy.md        # Git branching for Project Aion
├── workspace-path-policy.md     # Where projects and docs live
└── mcp-loading-strategy.md      # Always-On vs On-Demand MCPs
```

**Purpose**: Extracted patterns from recurring practices. Reference when implementing similar functionality.

**Active Patterns**:
- ✅ **Agent Selection**: Choose between custom agents, built-in subagents, skills, and direct tools
- ✅ **Memory Storage Pattern**: Decision framework for Memory MCP storage
- ✅ **PARC Design Review**: Prompt → Assess → Relate → Create pre-implementation check
- ✅ **Session Start Checklist**: Mandatory steps at session start (includes baseline check)
- ✅ **Workspace Path Policy**: Where projects and documentation live

### Upstream (AIfred Baseline Tracking)
```
upstream/
├── port-log.md               # History of porting decisions
└── sync-report-YYYY-MM-DD.md # Generated sync reports
```

**Purpose**: Track changes from the read-only AIfred baseline for controlled porting to Jarvis.

**Commands**:
- `/sync-aifred-baseline` — Analyze baseline changes, generate adopt/adapt/reject report

### Designs (Architecture Documents)
```
designs/
└── (architecture documents here)
```

**Purpose**: Design documents for significant system architectures. These describe the "why" and "how" before implementation begins.

### Integrations (API & Integration Guides)
```
integrations/
├── memory-usage.md       # Memory MCP guidelines
├── capability-matrix.md  # Task → tool selection matrix (PR-5)
├── overlap-analysis.md   # Tool overlap & conflict resolution (PR-5)
└── mcp-installation.md   # Stage 1 MCP installation guide (PR-5)
```

**Purpose**: Documentation for connecting systems and tool selection.

**PR-5 Core Tooling Baseline**:
- ✅ **Capability Matrix**: Task type → preferred tool → fallback
- ✅ **Overlap Analysis**: Conflict resolution between tools
- ✅ **MCP Installation**: Stage 1 server installation procedures

### Learning (Background Knowledge)
```
learning/
└── (notes and insights)
```

**Purpose**: Background knowledge that informs decisions.

---

## Project Aion Documentation

All Project Aion evolution documentation is now consolidated in `projects/project-aion/`:

```
projects/project-aion/
├── roadmap.md                    # Master development roadmap
├── archon-identity.md            # Archon identity and terminology
├── versioning-policy.md          # Version bumping rules
├── one-shot-prd.md               # Benchmark specification
├── pr2-validation.md             # Validation document
├── ideas/                        # Brainstorms and future planning
│   ├── tool-conformity-pattern.md
│   ├── setup-regression-testing.md
│   ├── testing-validation-cadence.md
│   ├── project-structure-clarity.md
│   └── venv-strategy.md
└── plans/                        # PR implementation plans
    └── pr-4-implementation-plan.md
```

**Design Principle**:
- **BEHAVIOR** (how Jarvis operates) → `.claude/context/` (patterns, standards, workflows)
- **EVOLUTION** (how Jarvis improves) → `projects/project-aion/` (roadmap, plans, ideas)

**Exception**: `current-priorities.md` stays in `.claude/context/projects/` as it's operational context.

---

## File Lifecycle

1. **Discovery**: New findings go in `knowledge/notes/`
2. **Documentation**: Clean notes move to `knowledge/docs/`
3. **Context**: Stable, frequently-used info becomes context files
4. **Automation**: Proven processes become slash commands

---

## Tips for Claude

When asked about infrastructure:
1. Check this index to find relevant context files
2. Load the specific context files using @ imports
3. If information isn't documented yet, help create it

When documenting discoveries:
1. Use appropriate template from systems/projects/workflows
2. Follow naming conventions (descriptive-hyphenated-names.md)
3. Keep files concise (50-200 lines ideal)
4. Link to related context files

When implementing tasks:
1. **Apply PARC first** - check patterns before coding
2. Use severity system for reporting issues
3. Consider agent selection for complex tasks
4. Store learnings in Memory MCP when appropriate

---

## Maintenance

**Create a context file when**:
- You've referenced information 3+ times
- It's critical for a system or project
- It contains commands/paths you need regularly

**Update existing files when**:
- You discover new information
- A configuration changed
- You solved a problem worth documenting

**Refactor when**:
- A file exceeds 300 lines (split it)
- Multiple files duplicate info (consolidate)
- Structure doesn't match how you work

---

## Setup Status

**Run `/setup` to configure your environment and populate this knowledge base.**

After setup, discovered systems will appear in the `systems/` directory.

---

## Recent Updates

**2026-01-06**: PR-5 Core Tooling Baseline
- ✅ Created capability matrix document (task → tool selection)
- ✅ Created overlap analysis document (conflict resolution)
- ✅ Created MCP installation guide (Stage 1 servers)
- ✅ Created `/tooling-health` command for tooling validation
- ✅ Updated integrations directory structure

**2026-01-05**: Project Structure Reorganization
- ✅ Consolidated all Project Aion docs into `projects/project-aion/`
- ✅ Moved `docs/project-aion/` contents to `projects/project-aion/`
- ✅ Moved `Project_Aion.md` to `projects/project-aion/roadmap.md`
- ✅ Moved ideas from `.claude/context/ideas/` to `projects/project-aion/ideas/`
- ✅ Established BEHAVIOR vs EVOLUTION separation principle
- ✅ Created testing-validation-cadence.md, project-structure-clarity.md, venv-strategy.md brainstorms

**2026-01-05**: PR-3 Upstream Sync Workflow
- ✅ Added `/sync-aifred-baseline` command for controlled baseline porting
- ✅ Created `upstream/` context directory with port-log and sync reports
- ✅ Updated session-start-checklist with sync integration
- ✅ Extended paths-registry.yaml with sync tracking fields

**2026-01-01**: Standards and Patterns
- ✅ Added standards directory with severity-status-system.md and model-selection.md
- ✅ Added patterns directory with agent-selection, memory-storage, and PARC patterns
- ✅ Created designs directory for architecture documents
- ✅ Added /design-review command for explicit PARC invocation
- ✅ Updated CLAUDE.md with Quick Links, Built-in Subagents, Advanced Task Patterns

---

*Last Updated: 2026-01-06*
