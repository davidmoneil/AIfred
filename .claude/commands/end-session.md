---
description: Clean session exit with documentation
allowed-tools: Read, Write, Edit, Bash(git:*)
---

# End Session

You are running the AIfred session exit procedure.

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

### 4. Git Commit

If there are uncommitted changes:

```bash
git status
git add -A
git commit -m "Session: [brief description of work done]

🤖 Generated with AIfred"
```

### 5. GitHub Push (Branch-Aware)

**Apply Git Operations Pattern** (@.claude/context/patterns/git-operations-pattern.md):

```bash
# Detect current branch
CURRENT_BRANCH=$(git branch --show-current)

# Check if push needed (only if ahead of remote)
if git status | grep -q "Your branch is ahead"; then
  # Push to current branch (not hardcoded main)
  git push origin $CURRENT_BRANCH
elif git status | grep -q "up to date"; then
  echo "✅ Already synced with remote"
else
  # No remote tracking - set up with:
  git push -u origin $CURRENT_BRANCH
fi
```

**Handle auth failures**: See Git Operations Pattern for credential setup

### 6. Clear Session Activity

Reset the session activity tracker for next session.

## Summary

After completing the checklist, provide a summary:

```
Session Exit Complete
━━━━━━━━━━━━━━━━━━━━━

✅ Session state updated
✅ Priorities updated
✅ Changes committed: [commit hash]
✅ Pushed to GitHub

Files Modified:
- [list of files]

Next Time:
- [next steps from session-state.md]
```

---

*AIfred Session Management*
