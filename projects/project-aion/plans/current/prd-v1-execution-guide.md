# PRD-V1 Execution Guide

**For use in SECOND terminal window**

This guide provides the execution instructions for PRD-V1: Session Continuity Stress Test.

---

## Pre-Execution Setup

### Environment Verification

Run these checks before starting:

```bash
# Node.js (requires >= 20.0.0)
node -v  # Expected: v24.12.0

# npm (requires >= 10.0.0)
npm -v   # Expected: 11.6.2

# Git user configured
git config user.name
git config user.email

# Projects directory
ls ~/Claude/Projects
```

### GitHub Access

The PRD requires creating a GitHub repository. Verify access:

```bash
# Test GitHub API access (replace with your method)
curl -s -H "Authorization: token $(cat ~/.github-pat 2>/dev/null || echo '')" \
  https://api.github.com/user | jq -r '.login // "Auth needed"'
```

If auth fails, you'll need to:
1. Create a PAT at https://github.com/settings/tokens
2. Save to `~/.github-pat` or configure git credential helper

---

## Session 1: Pre-flight + TDD

### Objective
Complete Phases 1-2, create 53+ tests, verify they fail

### Start Command

```
cd ~/Claude/Jarvis
claude
```

### Initial Prompt

```
Execute PRD-V1 Session 1.

Reference: projects/project-aion/plans/prd-variants/PRD-V1-session-continuity.md
Base PRD: projects/project-aion/plans/one-shot-prd-v2.md

This is Session 1 of 3. Complete:
- Phase 1: Pre-flight verification
- Phase 2: TDD setup (project scaffold + 53 tests)

Project location: ~/Claude/Projects/aion-hello-console-v1-session

At end of Phase 2:
1. Verify tests FAIL (TDD setup correct)
2. Run /checkpoint
3. Report checkpoint location and contents
4. Then run /clear

Do NOT start Phase 3 (Implementation) - that's Session 2.
```

### Session 1 Verification

Before `/checkpoint`, confirm:
- [ ] Pre-flight checklist complete
- [ ] Project scaffolded at `~/Claude/Projects/aion-hello-console-v1-session`
- [ ] package.json, vitest.config.js, playwright.config.js exist
- [ ] 53+ tests written (23 unit, 9 integration, 21 E2E)
- [ ] `npm test` shows tests FAIL (not implemented yet)

### End Session 1

```
/checkpoint
```

Then after checkpoint confirmed:

```
/clear
```

---

## Session 2: Implementation + Validation

### Objective
Complete Phases 3-4, all tests pass, manual verification

### Resume

After `/clear`, the session-start hook should detect the checkpoint.
Jarvis should acknowledge context restoration.

### Verification Prompt (if needed)

```
Continue PRD-V1 Session 2.

You should have restored from checkpoint. Confirm:
- Current phase: Phase 3 (Implementation)
- Tests written: 53+
- Tests status: FAILING (not implemented)

Complete:
- Phase 3: Implementation (transform.js, app.js, index.html, index.js)
- Phase 4: Validation (all tests pass, manual verification)

At end of Phase 4:
1. Verify all 53+ tests PASS
2. Run /checkpoint
3. Report checkpoint contents
4. Then run /clear

Do NOT start Phase 5 (Documentation) - that's Session 3.
```

### Session 2 Verification

Before `/checkpoint`, confirm:
- [ ] Checkpoint loaded correctly from Session 1
- [ ] Implementation complete (all source files)
- [ ] `npm test` shows 53+ tests PASS
- [ ] `npm run test:e2e` shows E2E tests PASS
- [ ] Manual browser verification works

### End Session 2

```
/checkpoint
```

Then:

```
/clear
```

---

## Session 3: Documentation + Delivery

### Objective
Complete Phases 5-7, GitHub delivery, reports

### Resume

After `/clear`, checkpoint should restore Phase 4 completion state.

### Verification Prompt (if needed)

```
Continue PRD-V1 Session 3.

You should have restored from checkpoint. Confirm:
- Current phase: Phase 5 (Documentation)
- Tests: 53+ PASSING
- Implementation: Complete

Complete:
- Phase 5: Documentation (README.md, ARCHITECTURE.md)
- Phase 6: Delivery (git init, GitHub repo, push, tag)
- Phase 7: Reporting (run report, analysis report)

Target repository: CannonCoPilot/aion-hello-console-v1-session

Generate all required reports at completion.
```

### Session 3 Verification

At completion, confirm:
- [ ] Checkpoint loaded correctly from Session 2
- [ ] README.md and ARCHITECTURE.md created
- [ ] GitHub repo exists at expected URL
- [ ] Code pushed with v1.0.0 tag
- [ ] Run report generated
- [ ] AC-01 analysis report generated

---

## Reporting Back to Base Session

After each session, report results to the orchestration session (Terminal 1):

### Session 1 Report Template

```
PRD-V1 Session 1 Complete

Checkpoint: [location]
Tests Written: [count]
Tests Failing: [count] (expected)
Key Files: [list]
Issues: [any blockers]
```

### Session 2 Report Template

```
PRD-V1 Session 2 Complete

Checkpoint Restored: [yes/no]
Resume Accuracy: [correct phase?]
Tests Passing: [count]
Manual Verification: [pass/fail]
Issues: [any blockers]
```

### Session 3 Report Template

```
PRD-V1 Session 3 Complete

Checkpoint Restored: [yes/no]
GitHub Repo: [URL]
Release Tag: [v1.0.0]
Reports Generated: [list]
Final Test Count: [count]
Issues: [any blockers]
```

---

## Troubleshooting

### Checkpoint Not Found

If checkpoint doesn't restore:
1. Check `.claude/context/.soft-restart-checkpoint.md` exists
2. Fall back to `session-state.md` for context
3. Report to base session for investigation

### GitHub Push Fails

If GitHub authentication fails:
1. Document the specific error
2. Try alternative auth method (PAT, SSH)
3. If blocked, complete everything else and report

### Tests Flaky

If tests intermittently fail:
1. Run 3 times to confirm
2. Document which tests are flaky
3. Fix before proceeding

---

*PRD-V1 Execution Guide — Use in Terminal 2*
