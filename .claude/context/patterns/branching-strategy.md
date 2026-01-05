# Project Aion Branching Strategy

*Last updated: 2026-01-05*
*Established: PR-1 Implementation*

---

## Overview

This document defines the Git branching strategy for Project Aion and all Archon development.

---

## Repository Structure

**Repository**: `davidmoneil/AIfred` (GitHub)

| Branch | Purpose | Access |
|--------|---------|--------|
| `main` | AIfred baseline (upstream) | **Read-only** — pull only |
| `Project_Aion` | All Archon development | **Read-write** — commit and push |

---

## Branch Policies

### `main` Branch (AIfred Baseline)

**STATUS: READ-ONLY**

The `main` branch is the upstream AIfred baseline by David O'Neil. Project Aion treats this as a read-only reference.

**Allowed Operations:**
- `git fetch origin main`
- `git pull origin main` (into local mirror only)
- Reading/diffing for upstream sync analysis

**Prohibited Operations:**
- `git push` to main
- Creating commits on main
- Merging into main
- Any modifications whatsoever

### `Project_Aion` Branch

**STATUS: ACTIVE DEVELOPMENT**

The `Project_Aion` branch is where all Archon development occurs. This includes:
- Jarvis (master Archon)
- Jeeves (always-on Archon)
- Wallace (creative writer Archon)
- All Project Aion documentation and features

**Allowed Operations:**
- All standard Git operations
- Commits, pushes, pulls
- Feature branches off Project_Aion
- Tags and releases

---

## Workflow

### Daily Development

```bash
# Ensure you're on Project_Aion branch
git checkout Project_Aion

# Do work, commit changes
git add -A
git commit -m "Description of changes"

# Push to remote
git push origin Project_Aion
```

### Checking for Upstream Updates

```bash
# Fetch baseline updates (read-only check)
git fetch origin main

# Compare baseline to Project_Aion
git log origin/main..Project_Aion --oneline

# If porting needed, use PR-3 sync workflow
```

### Upstream Sync (PR-3 Workflow)

When incorporating changes from `main` baseline:

1. Fetch: `git fetch origin main`
2. Diff: Compare `main` vs `Project_Aion`
3. Classify: Safe / unsafe / manual review
4. Port: Cherry-pick or adapt changes
5. Commit: To `Project_Aion` branch only
6. Log: Record in port log

---

## Session Start Checklist Update

Per PR-1.D, the session start checklist includes:

```bash
# Check baseline for updates
git fetch origin main
git log origin/main..HEAD --oneline

# If baseline has new commits, consider for PR-3 sync
```

---

## Local Directory Mapping

| Local Path | Branch | Purpose |
|------------|--------|---------|
| `/Users/aircannon/Claude/Jarvis/` | `Project_Aion` | Active development |
| `/Users/aircannon/Claude/AIfred/` | `main` (mirror) | Baseline reference only |

---

## Commit Message Convention

When committing to `Project_Aion`:

```
<Type>: <Short description>

<Detailed description if needed>

PR-X reference (if applicable)

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation only
- `refactor`: Code restructuring
- `test`: Adding/updating tests
- `chore`: Maintenance tasks

---

## Related Documents

- @.claude/context/patterns/session-start-checklist.md — Session start with baseline check
- @docs/project-aion/versioning-policy.md — Version bumping rules
- @CHANGELOG.md — Release history

---

*Pattern: Branching Strategy — Project Aion Development on `Project_Aion` branch*
