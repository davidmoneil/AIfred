# Project Aion — Versioning Policy

*Last updated: 2026-01-05*

---

## Overview

This document defines the versioning scheme for Project Aion Archons, ensuring consistent tracking of changes, releases, and lineage.

---

## Version Format

Archons use **semantic versioning** with three components:

```
MAJOR.MINOR.PATCH
  │     │     │
  │     │     └── Benchmark/test reports, documentation, minor fixes
  │     └──────── Feature additions, normal development pushes
  └────────────── Breaking changes, major architectural shifts
```

**Examples**:
- `1.0.0` → Initial release
- `1.1.0` → New feature added
- `1.1.1` → Test report or documentation update
- `2.0.0` → Breaking architectural change

---

## Version Bump Rules

### When to Bump PATCH (x.x.+1)

Increment the patch version for:
- Benchmark or test report pushes
- Documentation-only updates
- Typo fixes and minor corrections
- Configuration tweaks that don't change behavior

### When to Bump MINOR (x.+1.0)

Increment the minor version (and reset patch to 0) for:
- Normal development pushes with new functionality
- New commands, agents, or skills added
- New MCP integrations
- Feature enhancements
- Non-breaking refactors

### When to Bump MAJOR (+1.0.0)

Increment the major version (and reset minor and patch to 0) for:
- Breaking changes to commands or APIs
- Major architectural restructuring
- Changes that require user migration steps
- Significant behavioral changes

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
