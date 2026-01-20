# PRD-V1: AC-01 Session Continuity Stress Test

**Based on**: One-Shot PRD v2.0
**Target System**: AC-01 Self-Launch Protocol
**Focus**: Forced 3-session execution with checkpoint validation

---

## Stress Modifications

### Forced Session Breaks

This variant requires **mandatory session breaks** at specific points:

1. **Break 1**: After Phase 2 (TDD Setup) - Run `/checkpoint`
2. **Break 2**: After Phase 4 (Validation) - Run `/checkpoint`
3. **Break 3**: After Phase 6 (Delivery) - Complete normally

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

---

## Test Metrics

| Metric | Target |
|--------|--------|
| Checkpoint create success | 100% (3/3) |
| Checkpoint load success | 100% (2/2) |
| Context preservation | > 95% |
| Resume accuracy | 100% |

---

## Execution Checklist

### Session 1 (Pre-flight + TDD)
- [ ] AC-01 greeting verified
- [ ] Pre-flight checks complete
- [ ] Project scaffolding done
- [ ] Tests written (53+)
- [ ] **MANDATORY**: Run `/checkpoint`
- [ ] Document checkpoint contents

### Session 2 (Implementation + Validation)
- [ ] AC-01 checkpoint load verified
- [ ] Resume from correct position
- [ ] Implementation complete
- [ ] All tests pass
- [ ] **MANDATORY**: Run `/checkpoint`
- [ ] Document checkpoint contents

### Session 3 (Documentation + Delivery)
- [ ] AC-01 checkpoint load verified
- [ ] Resume from correct position
- [ ] Documentation complete
- [ ] Delivery complete
- [ ] Reports generated
- [ ] No checkpoint needed (completion)

---

## Validation Points

### AC-01 Specific Checks

| Test ID | Check | Pass Criteria |
|---------|-------|---------------|
| V1-01 | Greeting on session 1 | Time-appropriate, persona correct |
| V1-02 | Checkpoint creation 1 | Valid .checkpoint.md |
| V1-03 | Greeting on session 2 | Acknowledges checkpoint |
| V1-04 | Context restoration 2 | Phase 2 state restored |
| V1-05 | Checkpoint creation 2 | Valid, smaller than #1 |
| V1-06 | Greeting on session 3 | Acknowledges checkpoint |
| V1-07 | Context restoration 3 | Phase 4 state restored |
| V1-08 | Clean completion | All phases complete |

---

## Error Scenarios to Test

| Scenario | Expected Behavior |
|----------|-------------------|
| Missing .checkpoint.md | Create fresh, warn user |
| Corrupted checkpoint | Fallback to session-state.md |
| session-state.md also missing | Create defaults, full restart |
| Stale checkpoint (>24h) | Warn, offer fresh start |

---

## Success Criteria

- All 8 validation points pass
- No work duplicated across sessions
- Context preserved > 95%
- Total duration within 1.5x normal

---

*PRD-V1 — Session Continuity Stress Test*
