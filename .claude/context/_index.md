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
├── _index.md                          # Patterns directory index
├── agent-selection-pattern.md         # Choose agents vs subagents vs skills vs tools
├── memory-storage-pattern.md          # When/how to store in Memory MCP
├── prompt-design-review.md            # PARC pattern for design review
├── session-start-checklist.md         # Mandatory session start steps
├── branching-strategy.md              # Git branching for Project Aion
├── workspace-path-policy.md           # Where projects and docs live
├── mcp-loading-strategy.md            # 3-tier MCP loading (PR-8.5)
├── mcp-design-patterns.md             # Per-MCP best practices (PR-8.5) ← NEW
├── context-budget-management.md       # Context window optimization (PR-8)
├── plugin-decomposition-pattern.md    # Extract skills from plugins (PR-8)
├── automated-context-management.md    # Smart checkpoint workflow (PR-8.4)
├── mcp-validation-harness.md          # 5-phase MCP validation (PR-8.4)
├── batch-mcp-validation.md            # Batch testing for token limits (PR-8.5)
└── tool-selection-intelligence.md     # Research-backed tool modality selection (PR-9) ← NEW
```

**Purpose**: Extracted patterns from recurring practices. Reference when implementing similar functionality.

**Active Patterns**:
- ✅ **Agent Selection**: Choose between custom agents, built-in subagents, skills, and direct tools
- ✅ **Memory Storage Pattern**: Decision framework for Memory MCP storage
- ✅ **PARC Design Review**: Prompt → Assess → Relate → Create pre-implementation check
- ✅ **Session Start Checklist**: Mandatory steps at session start (includes baseline check)
- ✅ **Workspace Path Policy**: Where projects and documentation live
- ✅ **MCP Loading Strategy**: 3-tier loading (Always-On, Task-Scoped, On-Demand) (PR-8.5)
- ✅ **MCP Design Patterns**: Per-MCP best practices based on validation (PR-8.5)
- ✅ **Context Budget Management**: MCP loading tiers, plugin pruning, token budgets (PR-8)
- ✅ **Plugin Decomposition**: Extract/customize skills from bundled plugins (PR-8)
- ✅ **Automated Context Management**: Smart checkpoint with MCP optimization (PR-8.4)
- ✅ **MCP Validation Harness**: 5-phase validation for new MCPs (PR-8.4)
- ✅ **Batch MCP Validation**: Test MCPs in groups within token limits (PR-8.5)
- ✅ **Tool Selection Intelligence**: Research-backed precedence theory (PR-9) ← NEW

### Templates (Repeatable Workflow Templates)
```
templates/
├── tooling-evaluation-workflow.md      # Evaluate new tools (MCPs, plugins, skills)
├── overlap-analysis-workflow.md        # Identify and resolve tool overlaps
└── capability-matrix-update-workflow.md # Update capability matrix after changes
```

**Purpose**: Step-by-step templates for repeatable processes, ensuring consistency across tool evaluations and capability updates.

**Active Templates**:
- ✅ **Tooling Evaluation**: ADOPT/ADAPT/REJECT decisions for new tools
- ✅ **Overlap Analysis**: Detect and resolve tool conflicts
- ✅ **Capability Matrix Update**: Add tools to selection matrix

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
├── memory-usage.md            # Memory MCP guidelines
├── capability-matrix.md       # Task → tool selection matrix (PR-5/PR-7)
├── overlap-analysis.md        # Tool overlap & conflict resolution (PR-5)
├── mcp-installation.md        # Stage 1 MCP installation guide (PR-5)
└── skills-selection-guide.md  # Skills selection guide (PR-7)
```

**Purpose**: Documentation for connecting systems and tool selection.

**PR-5 Core Tooling Baseline**:
- ✅ **Capability Matrix**: Task type → preferred tool → fallback
- ✅ **Overlap Analysis**: Conflict resolution between tools
- ✅ **MCP Installation**: Stage 1 server installation procedures

**PR-7 Skills Inventory**:
- ✅ **Skills Selection Guide**: When to use which skill

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

**2026-01-09**: PR-8.5 MCP Initialization Protocol Implemented
- ✅ Created `suggest-mcps.sh` — Keyword-to-MCP mapping script
- ✅ Updated `session-start.sh` — Auto-suggests MCPs based on "Next Step"
- ✅ Updated `session-exit.md` — Added MCP state capture step
- ✅ Updated `session-state.md` — Added MCP State section template
- ✅ Updated `mcp-loading-strategy.md` — Full protocol documentation (v2.1)
- ✅ Updated `mcp-design-patterns.md` — Session lifecycle section (v1.1)

**2026-01-09**: PR-8.5 MCP Validation Complete + Documentation Revision
- ✅ Completed batch validation of all 17 MCPs (13/13 task MCPs + 4 core MCPs)
- ✅ Created mcp-design-patterns.md — Per-MCP best practices from validation
- ✅ Revised mcp-loading-strategy.md — Updated 3-tier system with accurate token costs
- ✅ Updated capability-matrix.md — Added research tool selection matrix
- ✅ Updated overlap-analysis.md — Added research MCP complementarity (section 5a)
- ✅ Documented 11 key discoveries from validation process

**2026-01-08**: PR-8.4 MCP Validation Harness
- ✅ Created 5-phase validation harness pattern
- ✅ Validated 17 MCPs across 4 batches
- ✅ Discovered tool loading limits (~45K tokens)
- ✅ DuckDuckGo removed (bot detection), Brave Search added

**2026-01-07**: PR-8 Context Budget Management (Extended Scope)
- ✅ Created context-budget-management.md pattern document
- ✅ Extended PR-8 scope in roadmap to include context optimization
- ✅ Defined MCP loading tiers (Always-On, Session-Scoped, Task-Scoped)
- ✅ Identified plugins for pruning (algorithmic-art, doc-coauthoring, slack-gif-creator)

**2026-01-07**: PR-7 Skills Inventory Complete (v1.7.0)
- ✅ Evaluated 64+ skills (16 official + 39 plugin + 9 project)
- ✅ Created skills evaluation report
- ✅ Created skills selection guide
- ✅ Added 5 overlap categories (11-15)

**2026-01-07**: PR-6 Plugins Expansion (Revised)
- ✅ Added browser-automation plugin evaluation
- ✅ Updated overlap analysis with browser automation category
- ✅ Updated capability matrix with browser automation selection rules
- ✅ Created templates directory with tooling workflows

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

*Last Updated: 2026-01-09*
