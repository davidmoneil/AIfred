# AIfred Versioning Policy

**Scheme**: Semantic Versioning — `Major.Minor.Patch`

**Single Source of Truth**: The `VERSION` file in the project root.

---

## Version Format

```
MAJOR.MINOR.PATCH
```

| Component | When to Bump | Examples |
|-----------|-------------|----------|
| **Major** | Breaking changes, architectural rewrites, incompatible config changes | 1.x.x → 2.0.0 |
| **Minor** | New features, new hooks/skills/commands, new profiles | 1.1.x → 1.2.0 |
| **Patch** | Bug fixes, documentation updates, tweaks to existing features | 1.1.0 → 1.1.1 |

---

## Rules

1. **Every release gets a git tag** matching the VERSION file (e.g., `v1.1.0`)
2. **Patch resets to 0** on minor bump (1.1.3 → 1.2.0)
3. **Minor and patch reset to 0** on major bump (1.9.5 → 2.0.0)
4. **VERSION file is updated first**, then tagged. Never tag without updating VERSION.
5. **Changelog in README.md** must have an entry for every minor and major release. Patch entries are optional but recommended.

---

## What Counts As What

### Major (breaking)
- CLAUDE.md structure changes that require user migration
- Hook API changes (new required fields, removed events)
- Profile format changes that break existing profiles
- Removal of commands/skills that users may depend on

### Minor (feature)
- New hooks, commands, skills, or agents
- New profiles or profile layers
- New scripts or automation capabilities
- New patterns or context documents
- Significant enhancements to existing features

### Patch (fix)
- Bug fixes in hooks or scripts
- Typo/documentation corrections
- Minor tweaks to existing behavior
- Config file adjustments that don't add features

---

## How to Bump

Use the bump script:

```bash
scripts/bump-version.sh patch   # 1.1.0 → 1.1.1
scripts/bump-version.sh minor   # 1.1.0 → 1.2.0
scripts/bump-version.sh major   # 1.1.0 → 2.0.0
```

The script will:
1. Read current version from `VERSION`
2. Calculate the new version
3. Update the `VERSION` file
4. Create a git tag `v<new-version>`
5. Print the old → new version

---

## Version Display

The session-start hook displays the current AIfred version alongside the Claude Code version at the start of every session:

```
Claude Code v2.1.39  |  AIfred v1.1.0
```

---

## History

AIfred used informal versioning (v1.x through v2.4.0 in changelogs) prior to adopting this policy. Version 1.1.0 is the baseline for the strict versioning system established 2026-02-12.
