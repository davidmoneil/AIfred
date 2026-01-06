# Changelog

All notable changes to Jarvis (Project Aion Master Archon) will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/),
and this project adheres to [Semantic Versioning](https://semver.org/).

---

## [Unreleased]

*No unreleased changes*

---

## [1.5.0] - 2026-01-06

**PR-5: Core Tooling Baseline** — Establish minimal, reliable default toolbox

### Added

#### Capability Matrix
- **`.claude/context/integrations/capability-matrix.md`** — Task → tool selection matrix
  - File operations, git operations, web/research, GitHub, code exploration
  - Development workflows, document generation, infrastructure
  - Decision tree for tool selection
  - Loading strategy summary (Always-On vs On-Demand)

#### Overlap Analysis
- **`.claude/context/integrations/overlap-analysis.md`** — Tool overlap & conflict resolution
  - Identified 9 overlap categories with resolution rules
  - Selection priority for each category
  - Hard rules and soft rules for conflict prevention
  - Monitoring and adjustment guidelines

#### MCP Installation Guide
- **`.claude/context/integrations/mcp-installation.md`** — Stage 1 MCP installation
  - 7 Stage 1 servers: Memory, Filesystem, Fetch, Time, Git, Sequential Thinking, GitHub
  - Installation commands, validation procedures, token costs
  - Bulk installation script
  - Prerequisites check

#### Tooling Health Command
- **`.claude/commands/tooling-health.md`** — `/tooling-health` command
  - Validates MCP servers, plugins, skills, built-in tools, subagents
  - Reports Stage 1 baseline coverage
  - Provides installation recommendations

### Updated
- **CLAUDE.md** — Added Tooling quick links section, `/tooling-health` command
- **`.claude/context/_index.md`** — Added integrations documentation

### Research Findings

Official Anthropic tooling inventory:
- **7 Core MCP Servers** (modelcontextprotocol/servers)
- **13 Official Claude Code Plugins** (anthropics/claude-code/plugins)
- **16 Official Skills** (anthropics/skills)
- **5 Built-in Subagents** (Explore, Plan, claude-code-guide, general-purpose, statusline-setup)

---

## [1.4.0] - 2026-01-06

**Skills System & Lifecycle Hooks** — Full compliance with AIfred baseline af66364

### Added

#### Skills System

New abstraction layer for multi-step workflow guidance:

- **`.claude/skills/_index.md`** — Skills directory index
  - Documents Skills vs Commands vs Agents decision guide
  - Directory structure and frontmatter conventions

- **`.claude/skills/session-management/SKILL.md`** — Session lifecycle skill
  - Comprehensive session management: start, during, checkpoint, end
  - Visual workflow diagram
  - Component references: hooks, commands, state files
  - Integration points with Memory MCP, doc sync, guardrails

- **`.claude/skills/session-management/examples/typical-session.md`** — Usage walkthrough
  - Multi-session feature development example
  - Demonstrates checkpoint, doc sync, and proper exit

#### Lifecycle Hooks (6 new hooks)

- **`session-start.js`** (SessionStart) — Auto-load context on startup
  - Injects session-state.md, current-priorities.md
  - Shows git branch and status
  - Checks AIfred baseline for updates

- **`session-stop.js`** (Stop) — Desktop notification on exit
  - macOS: Uses osascript
  - Linux: Uses notify-send
  - Different notifications for success/error/cancel

- **`self-correction-capture.js`** (UserPromptSubmit) — Capture corrections as lessons
  - Detects patterns: "No, actually...", "That's wrong", etc.
  - Severity levels: HIGH, MEDIUM, LOW
  - Logs to `.claude/logs/corrections.jsonl`

- **`subagent-stop.js`** (SubagentStop) — Agent completion handling
  - Logs to `.claude/logs/agent-activity.jsonl`
  - Detects HIGH/CRITICAL issues in output
  - Agent-specific follow-up suggestions

- **`pre-compact.js`** (PreCompact) — Preserve context before compaction
  - Extracts key sections from session-state.md
  - Logs to `.claude/logs/compaction-history.jsonl`
  - Ensures critical context survives compaction

- **`worktree-manager.js`** (PostToolUse) — Git worktree tracking
  - Detects worktree vs main repo
  - Warns about cross-worktree file access
  - Logs state to `.claude/logs/.worktree-state.json`

#### Documentation Synchronization

- **`doc-sync-trigger.js`** (PostToolUse) — Track code changes
  - Monitors Write/Edit on significant files
  - After 5+ changes in 24 hours, suggests sync
  - 4-hour cooldown between suggestions
  - State persists to `.claude/logs/.doc-sync-state.json`

- **`memory-bank-synchronizer`** agent — Sync documentation with code
  - Maintains consistency between code, docs, and Memory graph
  - CRITICAL preservation rules: never delete user content
  - Safe updates: code examples, paths, counts, versions
  - Results to `.claude/agents/results/memory-bank-synchronizer/`

### Changed

#### CLAUDE.md Enhancements

- Added **Skills System** section with available skills and decision guide
- Added **Documentation Synchronization** section
- Added `memory-bank-synchronizer` to agents list
- Updated hooks table (now 18 hooks)
- Added session-management skill to Quick Links
- Updated version to 1.4.0
- Updated baseline reference to `af66364`

#### hooks/README.md Overhaul

- Reorganized into categories: Lifecycle, Guardrail, Security, Observability, Documentation, Utility
- Added detailed descriptions for all 6 new lifecycle hooks
- Added Documentation Sync Trigger section
- Updated hook count to 18
- Added new log file locations

### Technical Summary

| Category | Before | After |
|----------|--------|-------|
| Total hooks | 11 | 18 |
| Total agents | 3 | 4 |
| Skills | 0 | 1 |
| Hook types | 4 | 8 |

### Port Classification

From AIfred baseline `af66364`:

| Classification | Count | Items |
|----------------|-------|-------|
| ADOPT | 2 | doc-sync-trigger.js, agent results .gitkeep |
| ADAPT | 10 | memory-bank-synchronizer, skills/*, hooks/README.md, CLAUDE.md |
| IMPLEMENT | 6 | session-start, session-stop, self-correction-capture, subagent-stop, pre-compact, worktree-manager |

---

## [1.3.1] - 2026-01-06

**Validation & UX Improvements** — Post-v1.3.0 thorough validation with fixes

### Added

#### Validation Scripts
- **`scripts/setup-readiness.sh`** — Standalone readiness report script
  - Accepts optional JARVIS_PATH argument for testing
  - Clean terminal output (no raw bash shown to user)
  - Proper exit codes (0=ready, 1=degraded, 2=not ready)
- **`scripts/validate-hooks.sh`** — Hook syntax validation script
  - Clean pass/fail output per hook
  - No confusing intermediate errors
  - Shows actual error messages on failure

#### Setup UX Improvements Brainstorm
- **`projects/project-aion/ideas/setup-ux-improvements.md`**
  - Documents UX issues found during Option C validation
  - Tracks fixes applied and remaining items

### Changed

#### Phase 1: System Discovery
- Updated projects_root detection to recommend `~/Claude/Projects` as default
- Added clear explanation of the recommended location

#### Phase 2: Purpose Interview
- Changed project management question to present `~/Claude/Projects` as recommended default
- Added follow-up options for existing projects in other locations

#### Phase 4: MCP Integration (Major Refactor)
- Made MCP entirely **optional** (Jarvis works without it)
- Added three clear options: Skip / Docker Desktop MCP / Manual configuration
- Removed incorrect mcp-gateway docker-compose.yml (was treating stdio server as daemon)
- Added `docker/mcp-gateway/README.md` explaining actual architecture
- Clarified Docker Desktop MCP vs Docker CLI requirements

#### Phase 5: Hooks & Automation
- Updated to use `scripts/validate-hooks.sh` for validation

#### Phase 6: Agent Deployment
- Added agent selection interview section
- Users can now choose: Install all / Select specific / Skip
- Default remains "install all core agents"

### Reorganized

#### Project Structure (BEHAVIOR vs EVOLUTION separation)
- Moved `docs/project-aion/` → `projects/project-aion/`
- Moved `Project_Aion.md` → `projects/project-aion/roadmap.md`
- Moved `.claude/context/ideas/` → `projects/project-aion/ideas/`
- Established clear separation:
  - `.claude/context/` = BEHAVIOR (how Jarvis operates)
  - `projects/project-aion/` = EVOLUTION (how Jarvis improves)

### Validation

**Option C Thorough Validation** completed successfully:
- Fresh clone to `/tmp/jarvis-validation-test/`
- Full `/setup` run from Phase 0A
- Result: **17/17 checks passed, FULLY READY**

---

## [1.3.0] - 2026-01-05

**PR-4 Complete: Setup Preflight + Guardrails** — Three-layer validation system

### Added

#### Setup Readiness Command (PR-4c)

- **`/setup-readiness`** (`.claude/commands/setup-readiness.md`)
  - Post-setup validation command generating deterministic readiness report
  - Checks: environment, structure, components, tools
  - Status levels: FULLY READY, READY (warnings), DEGRADED, NOT READY
  - Severity ratings: Critical, High, Medium, Low
  - Exit codes for automation (0=ready, 1=degraded, 2=not ready)

#### Setup Validation Pattern

- **`setup-validation.md`** (`.claude/context/patterns/`)
  - Documents three-layer validation approach: Preflight → Readiness → Health
  - Defines validation tiers: Quick (2s), Standard (10s), Deep (60s)
  - Troubleshooting guidance for common failures
  - Integration points with session start, health check, end session

#### Ideas Directory

- **`.claude/context/ideas/`** — New brainstorm/planning space
  - `tool-conformity-pattern.md`: External tool behavior normalization (future PR-9b)
  - `setup-regression-testing.md`: Periodic re-validation after tool additions (future PR-10b)

#### PR-4 Plan Archive

- **`docs/project-aion/plans/`** — Conformant location for implementation plans
  - Moved `wild-mapping-rose.md` from `~/.claude/plans/` to `pr-4-implementation-plan.md`
  - Establishes convention for plan file storage within Jarvis workspace

### Changed

#### Setup Command Updates

- **`setup.md`**: Enhanced phase descriptions
  - Phase numbers now 0A-7 (was 0-7)
  - Added PR references (PR-4a, PR-4b, PR-4c)
  - Added final verification step calling `/setup-readiness`
  - Updated wizard version to 1.3

#### Finalization Phase Updates

- **`07-finalization.md`**: Added readiness verification step
  - Step 6: Verify Readiness (before git commit)
  - Updated cleanup checklist to include readiness check
  - Renumbered subsequent steps (7-8)

#### CLAUDE.md Updates

- Added **Guardrails (PR-4a)** section documenting protection hooks
- Added **Setup Validation (PR-4)** section with three-layer validation overview
- Added `/setup-readiness` to Available Commands
- Updated version references to 1.3.0

#### Context Index Updates

- Added Ideas section to context index
- Added Project Aion Plans section
- Updated Recent Updates with PR-4c changes

### PR-4 Summary

PR-4 implements a complete setup validation system:

| Sub-PR | Version | What |
|--------|---------|------|
| PR-4a | v1.2.1 | Guardrail hooks (workspace-guard, dangerous-op-guard, permission-gate) |
| PR-4b | v1.2.2 | Preflight system (workspace-allowlist.yaml, 00-preflight.md) |
| PR-4c | v1.3.0 | Readiness report (setup-readiness.md, setup-validation pattern) |

The three layers work together:
1. **Preflight** (pre-setup): Validates workspace boundaries
2. **Readiness** (post-setup): Confirms all components installed
3. **Health** (ongoing): Detects regression and drift

---

## [1.2.2] - 2026-01-05

**PR-4b: Preflight System** — Second sub-PR of Setup Preflight + Guardrails

### Added

#### Workspace Allowlist Configuration

- **`workspace-allowlist.yaml`** (`.claude/config/`)
  - Declarative workspace boundary definitions
  - Used by guardrail hooks for access control
  - Sections: core_workspaces, readonly_workspaces, project_workspaces, forbidden_paths, warn_paths
  - Configurable hook error behavior (block/warn/allow)
  - Support for user overrides with explicit confirmation

#### Environment Preflight Phase

- **`00-preflight.md`** (`.claude/archive/setup-phases/`)
  - New Phase 0A: Environment preflight checks
  - Validates workspace configuration before `/setup` proceeds
  - Checks: workspace isolation, forbidden paths, required structure, git status
  - Produces deterministic PASS/FAIL with actionable guidance
  - Executable bash script included for automation

### Changed

- **`00-prerequisites.md`**: Renamed from Phase 0 to Phase 0B
  - Now runs after preflight passes
  - Updated header, footer, and references
  - Changed "AIfred" references to "Jarvis"

### Technical Notes

- Preflight checks are **blocking** — setup cannot proceed until all required checks pass
- Recommended checks produce warnings but don't block
- Allowlist config is read by `workspace-guard.js` hook (from PR-4a)
- Phase numbering now 0A-7 (was 0-7), total 8 phases

---

## [1.2.1] - 2026-01-05

**PR-4a: Guardrail Hooks** — First sub-PR of Setup Preflight + Guardrails

### Added

#### Guardrail Hooks

Three new hooks implementing workspace protection and safety guardrails:

- **`workspace-guard.js`** (PreToolUse)
  - Blocks Write/Edit operations to AIfred baseline (always)
  - Blocks operations to forbidden system paths (`/`, `/etc`, `/usr`, `~/.ssh`, etc.)
  - Warns on operations outside Jarvis workspace
  - Fail-open behavior: logs warning but allows on config errors

- **`dangerous-op-guard.js`** (PreToolUse)
  - Blocks destructive patterns: `rm -rf /`, `sudo rm -rf`, `mkfs`, disk `dd`, fork bombs
  - Blocks force push to main/master branches
  - Warns on `rm -r`, `git reset --hard`, `git clean -fd`
  - Fail-open behavior: logs warning but allows on pattern errors

- **`permission-gate.js`** (UserPromptSubmit)
  - Soft-gates policy-crossing operations with system reminders
  - Detects: AIfred baseline mentions, force push, mass deletion, protected branches, credentials
  - Formalizes the "ad-hoc permission check" pattern from PR-3 validation
  - Suggests using AskUserQuestion for explicit confirmation

#### Settings Protection

- Added AIfred baseline to `settings.json` deny patterns:
  - `Write(/Users/aircannon/Claude/AIfred/**)`
  - `Edit(/Users/aircannon/Claude/AIfred/**)`

### Changed

- Updated hooks README with guardrail hook documentation
- Renamed hooks README from "AIfred Hooks" to "Jarvis Hooks"
- Reorganized hook table into categories: Guardrail, Security, Observability

### Technical Notes

- All guardrail hooks use **fail-open** pattern (prioritize availability)
- Multi-layer baseline protection: hooks + settings.json deny patterns
- PR-4a is the first of three sub-PRs for PR-4 (Setup Preflight + Guardrails)
- PR-4b will add preflight system, PR-4c will add readiness report

---

## [1.2.0] - 2026-01-05

**PR-3: Upstream Sync Workflow** — Controlled porting from AIfred baseline

### Added

#### `/sync-aifred-baseline` Command
- Analyze AIfred baseline changes for controlled porting to Jarvis
- **Dry-run mode** (default): Report only, no changes applied
- **Full mode**: Generate patches and offer to apply with review
- Structured adopt/adapt/reject/defer classification system
- Location: `.claude/commands/sync-aifred-baseline.md`

#### Port Log Tracking
- Audit trail for all porting decisions at `.claude/context/upstream/port-log.md`
- Tracks: baseline commit, Jarvis commit, classification, rationale, modifications
- Initial fork from `dc0e8ac` documented

#### Sync Report Format
- Standardized reports at `.claude/context/upstream/sync-report-*.md`
- Includes: summary counts, detailed analysis per file, recommended actions
- First report generated for validation (no upstream changes at time of release)

#### Session-Start Integration
- Enhanced `session-start-checklist.md` with sync workflow reference
- Quick check for new changes since last sync point
- Links to `/sync-aifred-baseline` for deeper analysis

#### Registry Updates
- Extended `paths-registry.yaml` with sync tracking fields:
  - `last_synced_commit`: Commit hash Jarvis last synced from
  - `last_sync_date`: When sync occurred
  - `sync_command`: Reference to the sync command
  - `port_log`: Path to port log file

### Changed
- **Milestone-Based Versioning**: Version bumps now tied to PR/roadmap lifecycle
  - PATCH for validation/benchmarks, MINOR for PR completion, MAJOR for phase completion

### Validation Status

> **Note**: This release establishes the upstream sync infrastructure. Full workflow
> validation requires upstream changes to exist in the AIfred baseline. The command
> structure, report format, and tracking systems have been validated with a "no changes"
> scenario. Real-world validation will occur when David O'Neil pushes updates to the
> AIfred baseline `main` branch.
>
> **Action Required**: Run `/sync-aifred-baseline` when baseline updates are detected
> to validate the full adopt/adapt/reject workflow.

---

## [1.1.0] - 2026-01-05

### Added

#### Branching Strategy
- Established `Project_Aion` branch for all Archon development
  - `.claude/context/patterns/branching-strategy.md`
  - `main` branch remains read-only baseline
  - All commits/pushes go to `Project_Aion` branch

#### PR-2: Workspace & Project Summaries (Complete)
- **Project Summary Template**: Standardized template for tracking projects
  - `knowledge/templates/project-summary.md`
  - Distinct from project-context.md (summary vs detailed notes)
- **Refined /register-project Command**: Updated for workspace-path-policy compliance
  - Supports both local paths and GitHub URLs
  - Creates summary in `Jarvis/projects/`
  - Documents path policy and special cases
- **Refined /create-project Command**: Updated for workspace-path-policy compliance
  - Creates projects at `/Users/aircannon/Claude/<name>/`
  - Initializes with `.claude/CLAUDE.md`
  - Supports `--github` flag for repo creation
- **Updated paths-registry.yaml**: Fixed project paths
  - `projects_root` now correctly points to `/Users/aircannon/Claude`
  - Added `summaries_path` for clarity
  - Added `jarvis` section with version info
  - Added `aifred_baseline` section for read-only tracking
- **PR-2 Validation Document**: Smoke tests for project registration
  - `docs/project-aion/pr2-validation.md`

---

## [1.0.0] - 2026-01-05

### Added

#### PR-1.A/B: Archon Identity
- **Project Aion Identity**: Established Archon terminology and identity documentation
  - Jarvis as master Archon (dev + infrastructure + Archon builder)
  - Jeeves as always-on Archon (concept stage)
  - Wallace as creative writer Archon (concept stage)
- **Upstream Relationship**: Documented AIfred baseline as read-only reference
  - Derived from AIfred baseline commit `dc0e8ac` (2026-01-03)
  - Controlled porting workflow: pull → diff → propose → apply

#### PR-1.C: Baseline Update
- Updated AIfred baseline mirror to latest commit `dc0e8ac`

#### PR-1.D: Session Start Pattern
- **Session Start Checklist**: New pattern requiring baseline update check at session start
  - `.claude/context/patterns/session-start-checklist.md`
  - Integrated into CLAUDE.md Session Management section

#### PR-1.E: Workspace Path Policy
- **Workspace Path Policy**: Canonical locations for all projects and docs
  - `.claude/context/patterns/workspace-path-policy.md`
  - Projects root: `/Users/aircannon/Claude/<ProjectName>/`
  - Project Aion docs: `docs/project-aion/`
  - Jarvis summaries: `projects/`

#### PR-1.F/G: Versioning
- **Versioning Policy**: Semantic versioning with lineage tracking
  - MAJOR.MINOR.PATCH scheme
  - Patch bumps for benchmarks/tests
  - Minor bumps for features
  - Major bumps for breaking changes
- **Changelog Convention**: Keep a Changelog format
- **Version Tracking**: VERSION file and documentation references
- **Version Bump Script**: `scripts/bump-version.sh` for automation

#### PR-1.H: Archive Pattern
- **Archive System**: Pattern for archiving obsolete documentation
  - `docs/archive/` directory created
  - `docs/archive/archive-log.md` for tracking
  - Archived `PROJECT-PLAN.md` (superseded by Project Aion roadmap)

#### PR-2 (Partial): One-Shot PRD
- **One-Shot PRD Template**: Minimal end-to-end deliverable spec for autonomy benchmarking
  - `docs/project-aion/one-shot-prd.md`
  - Aion Hello Console specification

### Foundation (Inherited from AIfred baseline)
- Session management with `/end-session`
- Audit logging via hooks
- Custom agents: docker-deployer, service-troubleshooter, deep-research
- MCP integration framework
- Project registration system
- PARC, DDLA, COSA workflow patterns

---

## Lineage

| Property | Value |
|----------|-------|
| **Archon** | Jarvis (Master) |
| **Derived From** | [AIfred baseline](https://github.com/davidmoneil/AIfred) by David O'Neil |
| **Baseline Commit** | `dc0e8ac` (2026-01-03) |
| **Divergence** | Project Aion follows independent development track |

---

*Jarvis — Project Aion Master Archon*
