# Changelog

All notable changes to Jarvis (Project Aion Master Archon) will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/),
and this project adheres to [Semantic Versioning](https://semver.org/).

---

## [Unreleased]

*No unreleased changes*

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
