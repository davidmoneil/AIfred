# Brainstorm: Testing & Validation Cadence

*Created: 2026-01-05*
*Status: Brainstorm / Analysis*
*Triggered by: Pre-PR-5 checkpoint question*

---

## Problem Statement

Before embarking on PR-5 through PR-14 (heavy tooling expansion), we should validate that PR-1 through PR-4 are working correctly. However, **we don't have established testing checkpoints** in the development process.

### Current State Analysis

**What validation infrastructure exists:**

| PR | Validation Artifact | Status |
|----|-------------------|--------|
| PR-1 | None formal | Tested ad-hoc during implementation |
| PR-2 | `pr2-validation.md` | Documented but marked "Ready to test", not "Tested" |
| PR-3 | `/sync-aifred-baseline` | Validated manually (2026-01-05) with test file |
| PR-4 | `/setup-readiness` | Created but not run against clean environment |

**What the roadmap says about validation:**

Each PR in `Project_Aion.md` has a "Validation" section specifying:
- Smoke tests
- Health checks
- Demo outcomes
- Pass/fail criteria

However, there's **no defined cadence** for when to run these validations.

---

## Gap Analysis

### Missing: Testing Checkpoints

The roadmap defines WHAT to test but not WHEN:

| Checkpoint | Currently Defined? | Needed? |
|------------|-------------------|---------|
| After each PR | No | Yes — regression prevention |
| Before phase transition | No | Yes — gate for major milestones |
| After setup changes | Partial (readiness report) | Yes — more comprehensive |
| Before version bump | No | Yes — release quality gate |
| Periodic regression | No | Maybe — catch drift |

### Missing: Test Execution Tracking

We have validation documents but no record of:
- When tests were last run
- What passed/failed
- Who ran them (manual vs automated)
- Environment conditions

### Missing: Clean Environment Testing

All testing has been in the active Jarvis workspace. We haven't validated:
- Fresh clone setup
- `/setup` from scratch
- Preflight on new machine

---

## Proposed Testing Cadence

### Checkpoint 1: Post-PR Validation

**When**: After each PR completion, before version bump

**What**:
1. Run `/setup-readiness` — environment still valid?
2. Run PR-specific validation tests (from PR's validation section)
3. Document results in validation log

**Artifact**: `docs/project-aion/validation-log.md`

### Checkpoint 2: Phase Gate Validation

**When**: Before major phase transitions (PR-4→PR-5, PR-10→PR-11)

**What**:
1. Full `/setup-readiness` run
2. All prior PR validations (regression check)
3. Demo scenario execution (from roadmap Section 6)
4. Document in phase gate report

**Artifact**: `docs/project-aion/phase-gate-{N}.md`

### Checkpoint 3: Clean Environment Validation

**When**: At least once per phase (or after significant setup changes)

**What**:
1. Clone Jarvis to fresh directory
2. Run `/setup` from Phase 0A
3. Verify all phases complete
4. Run `/setup-readiness`
5. Document any issues

**Artifact**: `docs/project-aion/clean-env-test-{date}.md`

---

## Immediate Recommendation: Pre-PR-5 Validation

Before starting PR-5, we should:

### 1. Run `/setup-readiness` Now

```bash
# Execute the readiness report
/setup-readiness
```

Verify: FULLY READY or READY (with warnings)

### 2. Review PR-2 Validation Document

File: `docs/project-aion/pr2-validation.md`

Execute the smoke tests (or mark as deferred if not needed now):
- Test 1: Register local project
- Test 2: Register from GitHub URL
- Test 3: Create new project
- Test 4: Path policy compliance ✅
- Test 5: AIfred baseline exclusion ✅

### 3. Validate PR-3 Sync Workflow

Already done (2026-01-05), but confirm port-log is current:
```bash
cat .claude/context/upstream/port-log.md
```

### 4. Create Phase Gate Document

Create: `docs/project-aion/phase-1-4-gate.md`

Document:
- All validation results
- Any known issues or tech debt
- Readiness statement for PR-5

---

## Future Enhancements

### Automated Validation (PR-13+)

PR-13 (Benchmark Demos) will establish:
- Automated test runners
- Scoring systems
- Regression detection

Until then, validation is **manual but documented**.

### Integration with /end-session

Consider adding validation prompt to `/end-session`:
- "Run quick validation before committing? [Y/n]"
- Tier 1 check (2 seconds) by default

### Jeeves Periodic Validation

When Jeeves (always-on Archon) is implemented:
- Weekly full validation run
- Alert on regressions
- Maintain validation history

---

## Questions for User

1. **How thorough should pre-PR-5 validation be?**
   - Quick: Run `/setup-readiness` only
   - Standard: Run readiness + PR-2 smoke tests
   - Thorough: All of the above + clean environment test

2. **Should we create a formal validation log?**
   - Yes: Track all validation runs
   - No: Just document major checkpoints

3. **Is clean environment testing needed before PR-5?**
   - Yes: Clone to new directory, run full setup
   - No: Current workspace validation sufficient

---

## Action Items

- [ ] Run `/setup-readiness` and document results
- [ ] Decide validation depth for pre-PR-5 gate
- [ ] Create `phase-1-4-gate.md` document
- [ ] Consider adding validation prompt to `/end-session`
- [ ] Add testing cadence to CLAUDE.md or pattern doc

---

*Brainstorm: Testing & Validation Cadence — Pre-PR-5 Checkpoint*
