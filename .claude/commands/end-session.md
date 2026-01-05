---
description: Clean session exit with documentation
allowed-tools: Read, Write, Edit, Bash(git:*)
---

# End Session

You are running the Jarvis (Project Aion) session exit procedure.

## Session Activity Check

First, check what was done this session:

1. Read `.claude/logs/.session-activity` to see tracked activities
2. Check for uncommitted git changes: `git status`
3. Review current session-state.md

## Exit Checklist

Execute these steps:

### 1. Update Session State

Update `.claude/context/session-state.md`:

- Set status to 🟢 Idle (or 🟡 Active if continuing later)
- Update "What Was Accomplished" with today's work
- Update "Next Session Pickup" with next steps (if any)
- List key files modified

### 2. Review Todos

Check if any todos remain:
- Mark completed items
- Move incomplete items to current-priorities.md
- Clear session todo list

### 3. Update Priorities

Update `.claude/context/projects/current-priorities.md`:
- Add completed items to "Completed" section with date
- Add any new items discovered during session

### 4. Version Bump Check (Milestone-Based)

**Evaluate if a version bump is needed** based on session accomplishments:

| What was accomplished? | Bump Type | Command |
|------------------------|-----------|---------|
| PR completed from roadmap | **MINOR** | `./scripts/bump-version.sh minor` |
| Validation tests/benchmarks added | **PATCH** | `./scripts/bump-version.sh patch` |
| Final PR of a phase complete | **MAJOR** | `./scripts/bump-version.sh major` |
| Work-in-progress (PR not complete) | None | Skip version bump |

**If version bump needed**:

```bash
# 1. Bump version
./scripts/bump-version.sh [patch|minor|major]

# 2. Update CHANGELOG.md
#    - Move [Unreleased] items to new version section
#    - Add release date

# 3. Update version references if needed:
#    - README.md
#    - .claude/CLAUDE.md (header + footer)
#    - docs/project-aion/archon-identity.md
```

**PR-to-Version Reference** (see `docs/project-aion/versioning-policy.md`):

| PR | Target Version |
|----|----------------|
| PR-1 | 1.0.0 ✅ |
| PR-2 | 1.1.0 |
| PR-3 | 1.2.0 |
| PR-4 | 1.3.0 |
| PR-10 | 2.0.0 (Phase 5) |
| PR-14 | 3.0.0 (Phase 6) |

### 5. Git Commit

If there are uncommitted changes:

```bash
git status
git add -A

# Standard session commit (no version bump):
git commit -m "Session: [brief description of work done]

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>"

# OR Release commit (with version bump):
git commit -m "Release vX.X.X - [PR description]

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>"
```

### 6. GitHub Push

Push to Project_Aion branch (NOT main — main is read-only baseline):

```bash
git push origin Project_Aion
```

### 7. Tag Release (Optional)

For MINOR and MAJOR bumps, create a git tag:

```bash
git tag vX.X.X
git push origin vX.X.X
```

### 8. Clear Session Activity

Reset the session activity tracker for next session.

### 9. Disable On-Demand MCPs

Check session-state.md for any On-Demand MCPs enabled this session.
List them for user to disable (they must be OFF by default per MCP Loading Strategy).

## Summary

After completing the checklist, provide a summary:

```
Session Exit Complete
━━━━━━━━━━━━━━━━━━━━━

✅ Session state updated
✅ Priorities updated
✅ Version: [current version] → [new version] (or "unchanged")
✅ Changes committed: [commit hash]
✅ Pushed to Project_Aion branch

Files Modified:
- [list of files]

Version Info:
- Current: vX.X.X
- PR Status: [PR-N in progress / complete]
- Next milestone: vX.X.X (PR-N)

Next Time:
- [next steps from session-state.md]
```

---

*Jarvis v1.1.0 — Project Aion Master Archon*
