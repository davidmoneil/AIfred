# PRD-V1: AC-01 Session Continuity Stress Test

**Based on**: One-Shot PRD v2.0
**Target System**: AC-01 Self-Launch Protocol
**Focus**: Forced 3-session execution with checkpoint validation

---

## Deliverable Requirements

**THIS VARIANT MUST PRODUCE A WORKING APPLICATION**

### Application: aion-hello-console-v1

Build the Aion Hello Console application as defined in One-Shot PRD v2, with:

| Attribute | Value |
|-----------|-------|
| **Name** | aion-hello-console-v1-session |
| **Type** | Web application (Node.js + Express) |
| **Repository** | `CannonCoPilot/aion-hello-console-v1-session` |
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

## Stress Modifications: Session Continuity

### Forced Session Breaks

This variant requires **mandatory session breaks** at specific points:

| Break | After Phase | Action | Verification |
|-------|-------------|--------|--------------|
| **Break 1** | Phase 2 (TDD Setup) | Run `/checkpoint`, then `/clear` | Checkpoint validated |
| **Break 2** | Phase 4 (Validation) | Run `/checkpoint`, then `/clear` | Work resumes correctly |
| **Break 3** | Phase 7 (Delivery) | Complete normally | Full delivery |

### Checkpoint Requirements

At each checkpoint, verify:
- [ ] `.checkpoint.md` created with valid content
- [ ] `session-state.md` updated with current position
- [ ] All todos preserved in checkpoint
- [ ] Context estimation captured

### Session Resume Validation

On each resume, verify:
- [ ] Greeting displays correctly (time-appropriate)
- [ ] Checkpoint loaded and acknowledged
- [ ] Work continues from correct phase
- [ ] No redundant work performed
- [ ] No lost context or todos

---

## Execution Protocol

### Session 1: Pre-flight + TDD (Phases 1-2)

**Start**:
1. Normal AC-01 startup greeting
2. Load One-Shot PRD v2 as primary guidance
3. Begin Phase 1 (Pre-flight)

**Work**:
- Complete Phase 1: Pre-flight verification
- Complete Phase 2: TDD setup (project scaffold + tests)
- Verify tests fail before implementation

**End**:
1. **MANDATORY**: Run `/checkpoint`
2. Document checkpoint contents
3. Run `/clear` to simulate session end
4. Record: checkpoint file location, todos state, current progress

**Verification (Session 1)**:
- [ ] Pre-flight checklist complete
- [ ] 53+ tests written
- [ ] Tests fail (TDD setup correct)
- [ ] Checkpoint created with full context

---

### Session 2: Implementation + Validation (Phases 3-4)

**Resume**:
1. AC-01 checkpoint load verified
2. Greeting acknowledges context restoration
3. Work resumes from Phase 3

**Work**:
- Complete Phase 3: Implementation (transform, API, UI)
- Complete Phase 4: Validation (all tests pass)
- Manual verification in browser

**End**:
1. **MANDATORY**: Run `/checkpoint`
2. Document checkpoint contents
3. Run `/clear` to simulate session end
4. Record: todos completed, tests passing, any blockers

**Verification (Session 2)**:
- [ ] Checkpoint loaded correctly
- [ ] Resume from correct position (Phase 3)
- [ ] All tests now pass (53+)
- [ ] Manual verification successful
- [ ] Second checkpoint created

---

### Session 3: Documentation + Delivery (Phases 5-7)

**Resume**:
1. AC-01 checkpoint load verified
2. Greeting acknowledges context restoration
3. Work resumes from Phase 5

**Work**:
- Complete Phase 5: Documentation (README, ARCHITECTURE)
- Complete Phase 6: Delivery (git init, GitHub repo, push)
- Complete Phase 7: Reporting

**End**:
1. Generate run report
2. Generate analysis report
3. Clean session exit (no checkpoint needed)

**Verification (Session 3)**:
- [ ] Checkpoint loaded correctly
- [ ] Resume from correct position (Phase 5)
- [ ] Documentation complete
- [ ] GitHub repository created
- [ ] Code pushed with release tag
- [ ] Reports generated

---

## Evaluation Criteria

### Deliverable Evaluation (50%)

| Criterion | Weight | Pass Criteria |
|-----------|--------|---------------|
| Tests pass | 15% | 53+ tests, 100% pass rate |
| App runs | 10% | `npm start` works, UI accessible |
| Functionality | 10% | All 4 operations work correctly |
| Documentation | 10% | README + ARCHITECTURE complete |
| GitHub delivery | 5% | Repo exists, code pushed, tagged |

### AC-01 Stress Evaluation (50%)

| Criterion | Weight | Pass Criteria |
|-----------|--------|---------------|
| Checkpoint create (x2) | 15% | Both checkpoints valid |
| Checkpoint restore (x2) | 15% | Both resumes successful |
| Context preservation | 10% | > 95% essential context preserved |
| Greeting correctness | 5% | Time-appropriate, persona correct |
| No duplicate work | 5% | Work continues, not restarts |

---

## Test Metrics

| Metric | Target |
|--------|--------|
| Sessions required | 3 |
| Checkpoint create success | 100% (2/2) |
| Checkpoint load success | 100% (2/2) |
| Context preservation | > 95% |
| Resume accuracy | 100% |
| Final test count | 53+ |
| Final test pass rate | 100% |

---

## Error Scenarios

| Scenario | Expected Behavior |
|----------|-------------------|
| Missing .checkpoint.md | Create fresh, warn user |
| Corrupted checkpoint | Fallback to session-state.md |
| session-state.md also missing | Create defaults, full restart |
| Stale checkpoint (>24h) | Warn, offer fresh start |

---

## Validation Points

### AC-01 Specific Checks

| Test ID | Check | Pass Criteria |
|---------|-------|---------------|
| V1-01 | Greeting on session 1 | Time-appropriate, persona correct |
| V1-02 | Checkpoint creation 1 | Valid .checkpoint.md |
| V1-03 | Greeting on session 2 | Acknowledges checkpoint |
| V1-04 | Context restoration 2 | Phase 2 state restored |
| V1-05 | Checkpoint creation 2 | Valid, complete context |
| V1-06 | Greeting on session 3 | Acknowledges checkpoint |
| V1-07 | Context restoration 3 | Phase 4 state restored |
| V1-08 | Clean completion | All phases complete |

### Deliverable Checks

| Test ID | Check | Pass Criteria |
|---------|-------|---------------|
| D1-01 | Unit tests | 23+ pass |
| D1-02 | Integration tests | 9+ pass |
| D1-03 | E2E tests | 21+ pass |
| D1-04 | Manual verification | All operations work |
| D1-05 | README complete | All sections present |
| D1-06 | GitHub repo | Exists and accessible |
| D1-07 | Release tag | v1.0.0 exists |

---

## Success Criteria

### Overall Pass Requirements

1. **Deliverable Complete**: Working aion-hello-console app deployed to GitHub
2. **AC-01 Validated**: All 8 validation points pass
3. **No Work Loss**: Context preserved across all breaks
4. **Quality Met**: 53+ tests, 100% pass rate

### Final Score Calculation

```
Final Score = (Deliverable Score × 0.5) + (AC-01 Score × 0.5)

Deliverable Score = Σ(criterion_passed × weight) / total_weight × 100
AC-01 Score = Σ(criterion_passed × weight) / total_weight × 100
```

---

## Reports to Generate

1. **Run Report**: `projects/project-aion/reports/PRD-V1-run-report-YYYY-MM-DD.md`
   - Execution timeline across 3 sessions
   - Test results per session
   - Checkpoint details

2. **Deliverable Report**: `projects/project-aion/reports/PRD-V1-deliverable-report-YYYY-MM-DD.md`
   - Application functionality verification
   - Code quality assessment
   - GitHub delivery confirmation

3. **AC-01 Analysis**: `projects/project-aion/reports/PRD-V1-ac01-analysis-YYYY-MM-DD.md`
   - Checkpoint behavior analysis
   - Context preservation metrics
   - Greeting correctness evaluation

---

*PRD-V1 — Session Continuity Stress Test with Deliverable Generation*
*Produces: Working aion-hello-console-v1-session application*
