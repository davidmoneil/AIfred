# PRD-V2: AC-02 Wiggum Depth Stress Test

**Based on**: One-Shot PRD v2.0
**Target System**: AC-02 Wiggum Loop
**Focus**: Force 5+ iterations per phase, include blockers

---

## Deliverable Requirements

**THIS VARIANT MUST PRODUCE A WORKING APPLICATION**

### Application: aion-hello-console-v2

Build the Aion Hello Console application as defined in One-Shot PRD v2, with:

| Attribute | Value |
|-----------|-------|
| **Name** | aion-hello-console-v2-wiggum |
| **Type** | Web application (Node.js + Express) |
| **Repository** | `CannonCoPilot/aion-hello-console-v2-wiggum` |
| **Expected Tests** | 50+ (unit + integration + E2E) |
| **Features** | slugify, reverse, uppercase, wordCount |

### Deliverable Checklist

At completion, verify:
- [ ] Application runs locally (`npm start`)
- [ ] All 53+ tests pass (`npm test && npm run test:e2e`)
- [ ] Repository exists on GitHub
- [ ] README.md documents usage
- [ ] ARCHITECTURE.md explains design

---

## Stress Modifications: Wiggum Depth

### Iteration Requirements

Each phase must have **minimum 3 passes**:

1. **Pass 1**: Initial implementation
2. **Pass 2**: Self-review and corrections
3. **Pass 3**: Final verification

For key phases (Implementation, Validation), require **5 passes**:

1. Initial attempt
2. Review findings
3. First correction
4. Re-verification
5. Final confirmation

### Intentional Blockers

Insert these blockers to test investigation behavior:

| Phase | Blocker | Expected Response |
|-------|---------|-------------------|
| Pre-flight | Invalid Node version message | Investigate, verify actual |
| TDD | Missing test dependency | Install, continue |
| Implementation | Syntax error in template | Debug, fix, re-run |
| Validation | Flaky test | Investigate, stabilize |
| Delivery | GitHub rate limit (simulated) | Wait, retry |

### Blocker Implementation Details

**Blocker 1 (Pre-flight)**:
- After initial Node version check, add todo: "Verify Node version meets minimum (20.0.0)"
- Run check again to confirm (simulates "was that the right version?")

**Blocker 2 (TDD)**:
- Write tests that import a utility that doesn't exist yet
- Error on first `npm test` run
- Investigate → create stub → continue

**Blocker 3 (Implementation)**:
- Intentionally include a template literal syntax error in first pass
- Test fails with confusing error
- Debug → identify issue → fix → re-test

**Blocker 4 (Validation)**:
- Write one E2E test with race condition potential
- First run may flake
- Investigate → add proper wait/assertion → stabilize

**Blocker 5 (Delivery)**:
- Check GitHub API rate limit before push
- If limited, implement exponential backoff
- If not limited, still add rate-limit handling code for resilience

---

## Execution Protocol

### Single Session Execution

Unlike PRD-V1, this test runs in a **single session** without checkpoint breaks.
The stress is on iteration depth, not session continuity.

### Phase Execution Requirements

Each phase MUST demonstrate the Wiggum Loop pattern:

```
Execute → Check → Review → Drift Check → Continue/Complete
```

**TodoWrite is MANDATORY** for every phase. Todos must:
- Be created before work starts
- Track individual sub-tasks
- Mark complete immediately on finish
- Never batch completions

---

## Phase-by-Phase Execution

### Phase 1: Pre-flight (3+ passes)

| Pass | Action | Expected Outcome |
|------|--------|------------------|
| 1 | Initial checks | Complete basic verification |
| 2 | "Wait, let me double-check Node version" | Re-verify (blocker simulation) |
| 3 | Confirm all requirements | All checks verified |

**Todos**:
```
- [ ] Verify Node.js >= 20.0.0
- [ ] Verify npm >= 10.0.0
- [ ] Verify git user configured
- [ ] Verify GitHub API access
- [ ] Double-check Node version (blocker handling)
```

### Phase 2: TDD Setup (5+ passes)

| Pass | Action | Expected Outcome |
|------|--------|------------------|
| 1 | Scaffold project | Basic structure |
| 2 | Write tests | Tests written |
| 3 | Run tests | Blocker: missing dependency |
| 4 | Fix dependency, re-run | Tests fail correctly |
| 5 | Review test coverage | Confirm 53+ tests |

**Todos**:
```
- [ ] Create package.json
- [ ] Create vitest.config.js
- [ ] Create playwright.config.js
- [ ] Write unit tests (23+)
- [ ] Write integration tests (9+)
- [ ] Write E2E tests (21+)
- [ ] Fix missing dependency (blocker)
- [ ] Verify tests fail (TDD correct)
```

### Phase 3: Implementation (5+ passes)

| Pass | Action | Expected Outcome |
|------|--------|------------------|
| 1 | Implement transform.js | Blocker: syntax error |
| 2 | Debug syntax error | Fixed |
| 3 | Implement API routes | Complete |
| 4 | Implement UI | Complete |
| 5 | Integration test | All tests pass |

**Todos**:
```
- [ ] Implement slugify function
- [ ] Implement reverse function
- [ ] Implement uppercase function
- [ ] Implement wordCount function
- [ ] Implement transform dispatcher
- [ ] Debug syntax error (blocker)
- [ ] Implement API routes
- [ ] Verify unit tests pass
- [ ] Implement UI integration
- [ ] Verify integration tests pass
```

### Phase 4: Validation (5+ passes)

| Pass | Action | Expected Outcome |
|------|--------|------------------|
| 1 | Run all tests | Blocker: flaky E2E |
| 2 | Investigate flaky test | Root cause identified |
| 3 | Fix flaky test | Test stabilized |
| 4 | Re-run all tests | 53/53 pass |
| 5 | Manual verification | UI works correctly |

**Todos**:
```
- [ ] Run unit tests
- [ ] Run integration tests
- [ ] Run E2E tests
- [ ] Investigate flaky test (blocker)
- [ ] Fix flaky test
- [ ] Re-run all tests
- [ ] Manual browser verification
- [ ] Code review checklist
```

### Phase 5: Documentation (3+ passes)

| Pass | Action | Expected Outcome |
|------|--------|------------------|
| 1 | Write README | Initial draft |
| 2 | Review, improve | Add missing sections |
| 3 | Write ARCHITECTURE | Complete |

### Phase 6: Delivery (3+ passes)

| Pass | Action | Expected Outcome |
|------|--------|------------------|
| 1 | Git init, commit | Local commit |
| 2 | Create GitHub repo | Check rate limit (blocker) |
| 3 | Push and verify | Code on GitHub |

### Phase 7: Reporting (3+ passes)

| Pass | Action | Expected Outcome |
|------|--------|------------------|
| 1 | Draft run report | Initial metrics |
| 2 | Review accuracy | Corrections made |
| 3 | Final report | Complete |

---

## Drift Scenarios

Insert these scope creep attempts during execution:

1. **After Phase 3**: Add a todo "Consider dark mode toggle" → Should: Log observation, defer to roadmap, continue original scope
2. **After Phase 5**: Think about "Adding TypeScript support" → Should: Acknowledge as future enhancement, don't implement

**Expected Behavior**: Acknowledge the drift, explicitly note "This is outside current scope", continue with original requirements.

---

## Evaluation Criteria

### Deliverable Evaluation (50%)

| Criterion | Weight | Pass Criteria |
|-----------|--------|---------------|
| Tests pass | 15% | 53+ tests, 100% pass rate |
| App runs | 10% | `npm start` works, UI accessible |
| Functionality | 10% | All 4 operations work correctly |
| Documentation | 10% | README + ARCHITECTURE complete |
| GitHub delivery | 5% | Repo exists, code pushed |

### AC-02 Stress Evaluation (50%)

| Criterion | Weight | Pass Criteria |
|-----------|--------|---------------|
| Total iterations | 15% | >= 35 total passes |
| Blocker handling | 15% | All 5 blockers investigated, resolved |
| TodoWrite usage | 10% | Todos for every phase, marked complete |
| Drift detection | 5% | At least 1 drift caught and deferred |
| No premature exits | 5% | Every phase fully completed |

---

## Test Metrics

| Metric | Target |
|--------|--------|
| Total iterations | >= 35 |
| Iterations per blocker | >= 3 |
| Drift detections | >= 1 |
| Suppression ignored | 0 (none requested) |
| TodoWrite phases | 7/7 |
| Final test count | 53+ |
| Final test pass rate | 100% |

---

## Validation Points

### AC-02 Specific Checks

| Test ID | Check | Pass Criteria |
|---------|-------|---------------|
| V2-01 | Total iterations | >= 35 tracked |
| V2-02 | TodoWrite usage | Every phase has todos |
| V2-03 | Blocker 1 (Pre-flight) | Investigated, resolved |
| V2-04 | Blocker 2 (TDD) | Investigated, resolved |
| V2-05 | Blocker 3 (Implementation) | Investigated, resolved |
| V2-06 | Blocker 4 (Validation) | Investigated, resolved |
| V2-07 | Blocker 5 (Delivery) | Investigated, resolved |
| V2-08 | Drift detection | At least 1 caught |
| V2-09 | No premature exits | All phases complete |
| V2-10 | Self-review documented | Each phase reviewed |

### Deliverable Checks

| Test ID | Check | Pass Criteria |
|---------|-------|---------------|
| D2-01 | Unit tests | 23+ pass |
| D2-02 | Integration tests | 9+ pass |
| D2-03 | E2E tests | 21+ pass |
| D2-04 | Manual verification | All operations work |
| D2-05 | README complete | All sections present |
| D2-06 | GitHub repo | Exists and accessible |

---

## Success Criteria

### Overall Pass Requirements

1. **Deliverable Complete**: Working aion-hello-console app deployed to GitHub
2. **AC-02 Validated**: All 10 validation points pass
3. **Iterations Met**: 35+ total passes tracked
4. **Blockers Handled**: All 5 blockers investigated and resolved
5. **Quality Met**: 53+ tests, 100% pass rate

### Final Score Calculation

```
Final Score = (Deliverable Score × 0.5) + (AC-02 Score × 0.5)

Deliverable Score = Σ(criterion_passed × weight) / total_weight × 100
AC-02 Score = Σ(criterion_passed × weight) / total_weight × 100
```

---

## Reports to Generate

1. **Run Report**: `projects/project-aion/reports/PRD-V2-run-report-YYYY-MM-DD.md`
   - Iteration count per phase
   - Blocker resolution details
   - Test results

2. **Deliverable Report**: `projects/project-aion/reports/PRD-V2-deliverable-report-YYYY-MM-DD.md`
   - Application functionality verification
   - Code quality assessment
   - GitHub delivery confirmation

3. **AC-02 Analysis**: `projects/project-aion/reports/PRD-V2-ac02-analysis-YYYY-MM-DD.md`
   - Wiggum Loop behavior analysis
   - Iteration depth metrics
   - Blocker handling evaluation
   - Drift detection analysis

---

*PRD-V2 — Wiggum Depth Stress Test with Deliverable Generation*
*Produces: Working aion-hello-console-v2-wiggum application*
