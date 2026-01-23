---
description: Clean session exit with documentation
allowed-tools: Read, Write, Edit, Bash(git:*)
---

# End Session

You are running the Jarvis (Project Aion) session exit procedure.

## Pre-Completion Offer (AC-09 Tier 2 Cycles)

**BEFORE proceeding with exit**, offer the user the option to run self-improvement cycles:

```
Before ending the session, would you like me to run any self-improvement cycles?

Available options:
1. `/self-improve` — Full cycle (reflection → maintenance → research → evolution)
2. `/maintain` — Quick maintenance check only
3. `/reflect` — Review session for learnings only
4. Skip — Proceed directly to exit

[Enter choice or press Enter to skip]
```

**If user chooses an option**: Run the selected command, then return here to complete exit.
**If user skips or presses Enter**: Proceed to exit procedure below.

---

## Pre-Exit Context Preparation

**Run this FIRST** to prepare context for clean restart:

### 0. Context Reset Preparation

Prepare context artifacts that help the next session start cleanly:

1. **Extract key session context** (similar to pre-compact):
   - Current task status from session-state.md
   - Any blockers encountered
   - MCPs currently enabled

2. **Clear any checkpoint files** (will be regenerated if needed):
   ```bash
   rm -f .claude/context/.soft-restart-checkpoint.md 2>/dev/null || true
   ```

3. **Log session end**:
   ```bash
   echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) | SessionEnd | /end-session invoked" >> .claude/logs/session-start-diagnostic.log
   ```

---

## Session Activity Check

Check what was done this session:

1. Read `.claude/logs/.session-activity` to see tracked activities
2. Check for uncommitted git changes: `git status`
3. Review current session-state.md

## Exit Checklist

Execute these steps:

### 1. Session State Archival Check

**Check if session-state.md needs archiving** (if over ~200 lines):

```bash
wc -l .claude/context/session-state.md
```

If over threshold, offer:
```
The session-state.md has grown large ([N] lines). Would you like to:
1. Archive and compress (recommended) — keeps recent summary, archives full history
2. Keep as-is — session state remains unchanged
```

**If archiving**: Run `.claude/scripts/archive-session-state.sh`

### 2. Update Session State & Context Docs

**Primary State Files** (ALWAYS update):

| File | Update |
|------|--------|
| `.claude/context/session-state.md` | Status, accomplishments, next steps, key files |
| `.claude/context/current-priorities.md` | Move completed to "Recently Completed", add new items |

**JICM Context Preservation Files** (update if relevant):

| File | When to Update |
|------|----------------|
| `.claude/context/upstream/integration-chronicle.md` | After AIfred integration milestones |
| `.claude/context/session-chronicle.md` | After significant multi-session work |
| `.claude/context/projects/pr-chronicle.md` | After PR completions |

**Update session-state.md**:
- Set status to 🟢 Idle (or 🟡 Active if continuing later)
- Update "What Was Accomplished" with today's work
- Update "Next Session Pickup" with next steps (if any)
- List key files modified

### 3. Review Todos

Check if any todos remain:
- Mark completed items
- Move incomplete items to current-priorities.md
- Clear session todo list

### 4. Verify Report Files (if /reflect or /maintain was run)

If self-improvement cycles were run this session, verify reports exist:

```bash
# Check for today's reports
ls -la .claude/reports/reflections/reflection-$(date +%Y-%m-%d)*.md 2>/dev/null
ls -la .claude/reports/maintenance/maintenance-$(date +%Y-%m-%d)*.md 2>/dev/null
```

**If reports are missing**, create them before proceeding.

### 5. Version Bump Check (Milestone-Based)

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
#    - projects/project-aion/archon-identity.md
```

**PR-to-Version Reference** (see `projects/project-aion/versioning-policy.md`):

| PR | Target Version |
|----|----------------|
| PR-1 | 1.0.0 ✅ |
| PR-2 | 1.1.0 |
| PR-3 | 1.2.0 |
| PR-4 | 1.3.0 |
| PR-10 | 2.0.0 (Phase 5) |
| PR-14 | 3.0.0 (Phase 6) |

### 6. Git Commit

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

### 7. GitHub Push

Push to Project_Aion branch (NOT main — main is read-only baseline):

```bash
git push origin Project_Aion
```

### 8. Tag Release (Optional)

For MINOR and MAJOR bumps, create a git tag:

```bash
git tag vX.X.X
git push origin vX.X.X
```

### 9. Clear Session Activity

Reset the session activity tracker for next session.

### 10. Cross-Project Commit Check (If Multi-Repo)

If commits were made to multiple repositories this session:

1. Check tracking file: `.claude/logs/cross-project-commits.json`
2. If exists and has unpushed commits:
   ```
   Ask user: "Push all unpushed commits across projects? [y/N]"
   ```
3. If yes, push each project's branch
4. Report results per project

### 11. Disable On-Demand MCPs

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

## Closing Salutation

**After the summary**, generate a personalized closing based on context:

1. Get current datetime by running: `date "+%A, %B %d at %H:%M"`
2. Optionally check weather via startup-greeting.js: `node .claude/scripts/startup-greeting.js --weather-only`

**Generate a brief, natural closing** that:
- Acknowledges the time (e.g., "Have a good evening" / "Enjoy your lunch" / "Get some rest")
- Optionally mentions weather if notable (e.g., "Stay warm out there")
- Signs off appropriately (e.g., "Until next time, sir.")

**Examples** (DO NOT use verbatim - generate naturally):
- "It's getting late, sir. Have a good evening, and I'll be here when you're ready to continue."
- "Enjoy your afternoon. The session state is saved and ready for pickup."
- "All set, sir. Cold one out there - stay warm."

---

*Jarvis v2.1.0 — Project Aion Master Archon (AC-09 pre-completion offer + personalized closing added)*
