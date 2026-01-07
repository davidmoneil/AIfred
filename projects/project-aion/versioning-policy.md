# Project Aion — Versioning Policy

*Last updated: 2026-01-05*

---

## Overview

This document defines the **milestone-based versioning scheme** for Project Aion Archons. Version bumps are tied directly to the PR/roadmap lifecycle, creating predictable, auditable version increments.

---

## Version Format

Archons use **semantic versioning** with three components:

```
MAJOR.MINOR.PATCH
  │     │     │
  │     │     └── Validation pushes, benchmark reports, documentation fixes
  │     └──────── PR completion (feature delivery)
  └────────────── Roadmap phase completion (major capability milestone)
```

**Examples**:
- `1.0.0` → Initial release (PR-1 complete)
- `1.1.0` → PR-2 complete (new feature delivered)
- `1.1.1` → PR-2 validation tests added
- `2.0.0` → Phase 5 complete (tooling baseline established)

---

## Milestone-Based Version Bump Rules

Version bumps are **triggered by specific milestones** in the development lifecycle:

### PATCH Bump (x.x.+1) — Validation & Documentation

Trigger: **Validation push** or **documentation update**

Increment the patch version when:
- Validation/smoke tests are added or updated
- Benchmark results are recorded
- Documentation-only updates (README, patterns, guides)
- Typo fixes and minor corrections
- Configuration tweaks that don't change behavior

**Example workflow**:
```
Current: 1.2.0 (PR-3 complete)
Action:  Add PR-2 validation smoke tests
Result:  1.1.1
Commit:  "Release v1.1.1 - PR-2 validation tests"
```

### MINOR Bump (x.+1.0) — PR Completion

Trigger: **PR fully implemented and pushed**

Increment the minor version when:
- A PR from the roadmap is fully complete
- All PR deliverables are implemented
- Changes are committed and pushed to `Project_Aion` branch

**Example workflow**:
```
Current: 1.1.1
Action:  Complete PR-3 (Upstream Sync Workflow)
Result:  1.2.0
Commit:  "Release v1.2.0 - PR-3 complete"
```

**PR-to-Version Mapping** (Jarvis roadmap):

| PR | Description | Target Version |
|----|-------------|----------------|
| PR-1 | Archon Identity + Versioning | 1.0.0 ✅ |
| PR-2 | Workspace & Project Summaries | 1.1.0 ✅ |
| PR-3 | Upstream Sync Workflow | 1.2.0 ✅ |
| PR-4 | Setup Preflight + Guardrails | 1.3.0 ✅ |
| — | Skills System & Lifecycle Hooks | 1.4.0 ✅ |
| PR-5 | Core Tooling Baseline | 1.5.0 ✅ |
| PR-6 | Plugins Expansion | 1.6.0 |
| PR-7 | Skills Inventory | 1.7.0 |
| PR-8 | MCP Expansion | 1.8.0 |
| PR-9 | Selection Intelligence | 1.9.0 |
| PR-10 | Setup Upgrade | 2.0.0 |
| PR-11 | Autonomy & Permission Reduction | 2.1.0 |
| PR-12 | Self-Evolution Loop | 2.2.0 |
| PR-13 | Benchmark Demos | 2.3.0 |
| PR-14 | SOTA Research & Comparison | 3.0.0 |

### MAJOR Bump (+1.0.0) — Phase Completion

Trigger: **All PRs in a roadmap phase complete**

Increment the major version when:
- An entire roadmap phase is finished
- A significant capability milestone is reached
- Breaking changes require user migration

**Phase-to-Major-Version Mapping**:

| Phase | PRs Included | Major Version |
|-------|--------------|---------------|
| Phase 1 | PR-1 | 1.0.0 ✅ (Initial) |
| Phase 2 | PR-2 | 1.x.x (Minor accumulation) |
| Phase 3 | PR-3 | 1.x.x |
| Phase 4 | PR-4 | 1.x.x |
| Phase 5 | PR-5 → PR-10 | **2.0.0** (Tooling Complete) |
| Phase 6 | PR-11 → PR-14 | **3.0.0** (Autonomous Operation) |

---

## Version Bump Decision Tree

Use this flowchart when deciding version bumps:

```
┌─────────────────────────────────────────────────────────┐
│ What was pushed?                                        │
└─────────────────────────────────────────────────────────┘
                          │
          ┌───────────────┼───────────────┐
          ▼               ▼               ▼
   ┌──────────────┐ ┌──────────────┐ ┌──────────────┐
   │ Validation/  │ │ PR Complete  │ │ Phase        │
   │ Docs/Fixes   │ │ (Feature)    │ │ Complete     │
   └──────────────┘ └──────────────┘ └──────────────┘
          │               │               │
          ▼               ▼               ▼
   ┌──────────────┐ ┌──────────────┐ ┌──────────────┐
   │ PATCH        │ │ MINOR        │ │ MAJOR        │
   │ x.x.+1       │ │ x.+1.0       │ │ +1.0.0       │
   └──────────────┘ └──────────────┘ └──────────────┘
```

---

## Session-End Version Check

At session end (`/end-session`), evaluate version bump needs:

1. **Check session accomplishments**:
   - Was a PR completed? → MINOR bump
   - Were validation tests added? → PATCH bump
   - Was this the final PR of a phase? → MAJOR bump

2. **If version bump needed**:
   ```bash
   # Run appropriate bump
   ./scripts/bump-version.sh [patch|minor|major]

   # Update CHANGELOG.md
   # Update version references in docs
   # Commit with release message
   ```

3. **If no bump needed**:
   - Session work is part of an in-progress PR
   - Commit normally without version change

---

## Version Storage

### VERSION File

Each Archon maintains a `VERSION` file in its root directory:

```
1.0.0
```

This file:
- Contains only the version string (no newline at end)
- Is the single source of truth for the current version
- Is read by automation scripts for version bumping

### Version References in Documentation

The following files should reference the current version:
- `README.md` — In the header or status section
- `.claude/CLAUDE.md` — In the footer
- `docs/project-aion/archon-identity.md` — In the Archon table

---

## Lineage Tracking

### Jarvis (Master Archon)

Jarvis tracks:
- Its own version in `VERSION`
- The AIfred baseline commit it derives from

```markdown
Jarvis v1.0.0
Derived from: AIfred baseline commit 05e20e5 (2026-01-02)
```

### Secondary Archons (Jeeves, Wallace, etc.)

Secondary Archons track:
- Their own version
- The Jarvis version used to create them
- The AIfred baseline commit (inherited from Jarvis)

```markdown
Jeeves v0.1.0
Created using: Jarvis v1.2.0
Derived from: AIfred baseline commit 05e20e5
```

---

## Changelog Convention

### File Location

Each Archon maintains a `CHANGELOG.md` in its root directory.

### Format

Follow [Keep a Changelog](https://keepachangelog.com/) format:

```markdown
# Changelog

All notable changes to this Archon will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added
- New features

### Changed
- Changes to existing functionality

### Deprecated
- Features to be removed in future

### Removed
- Features removed in this release

### Fixed
- Bug fixes

### Security
- Security-related changes

## [1.0.0] - 2026-01-05

### Added
- Initial release
- Project Aion identity and versioning
```

### Entry Guidelines

- Write entries in imperative mood ("Add feature" not "Added feature")
- Include PR/issue references when applicable
- Group related changes together
- Keep entries concise but informative

---

## Release Process

### Standard Release

1. Update `VERSION` file with new version
2. Update `CHANGELOG.md`:
   - Move items from `[Unreleased]` to new version section
   - Add release date
3. Update version references in documentation
4. Commit with message: `Release vX.X.X`
5. Create git tag: `vX.X.X`
6. Push commit and tag

### Benchmark/Test Report Release

1. Increment patch version in `VERSION`
2. Add changelog entry under `[Unreleased]` or new patch section
3. Commit with message: `Release vX.X.X - [brief description]`
4. Tag optional for patch releases

---

## Automation

### Version Bump Script

A helper script at `scripts/bump-version.sh` can automate version bumps:

```bash
# Bump patch version
./scripts/bump-version.sh patch

# Bump minor version
./scripts/bump-version.sh minor

# Bump major version
./scripts/bump-version.sh major
```

---

## Examples

### Normal Feature Push (Minor Bump)

```
Before: 1.2.3
After:  1.3.0
Commit: "Add deep-research agent with citation support"
```

### Benchmark Report Push (Patch Bump)

```
Before: 1.3.0
After:  1.3.1
Commit: "Release v1.3.1 - Benchmark results for one-shot PRD"
```

### Breaking Change (Major Bump)

```
Before: 1.3.1
After:  2.0.0
Commit: "Release v2.0.0 - Restructure command system"
```

---

*Project Aion — Consistent Versioning for Reliable Evolution*
