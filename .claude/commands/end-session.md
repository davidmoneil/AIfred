---
description: Clean session exit with documentation
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash(git:*)
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

### 5. GitHub Push (Optional)

If GitHub integration is enabled:

```bash
git push origin main
```

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
