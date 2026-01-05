# Changelog

All notable changes to Jarvis (Project Aion Master Archon) will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/),
and this project adheres to [Semantic Versioning](https://semver.org/).

---

## [Unreleased]

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
