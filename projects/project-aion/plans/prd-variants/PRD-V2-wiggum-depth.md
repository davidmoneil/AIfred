# PRD-V2: AC-02 Wiggum Depth Stress Test

**Based on**: One-Shot PRD v2.0
**Target System**: AC-02 Wiggum Loop
**Focus**: Force 5+ iterations per phase, include blockers

---

## Stress Modifications

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
| Delivery | GitHub rate limit | Wait, retry |

---

## Test Metrics

| Metric | Target |
|--------|--------|
| Total iterations | >= 35 |
| Iterations per blocker | >= 3 |
| Drift detections | >= 1 |
| Suppression ignored | 0 (none requested) |

---

## TodoWrite Requirements

For each phase, todos must:
- Be created before work starts
- Track individual sub-tasks
- Mark complete immediately on finish
- Never batch completions

### Expected Todo Pattern

```
Phase 2 Example:
- [ ] Create package.json
- [ ] Create vitest.config.js
- [ ] Create playwright.config.js
- [ ] Write unit tests
- [ ] Write integration tests
- [ ] Write E2E tests
- [ ] Verify tests fail
```

---

## Iteration Tracking

### Phase 1 (Pre-flight)
| Pass | Action | Outcome |
|------|--------|---------|
| 1 | Initial checks | Blocker encountered |
| 2 | Investigate blocker | Resolution found |
| 3 | Verify resolution | Confirmed |

### Phase 2 (TDD)
| Pass | Action | Outcome |
|------|--------|---------|
| 1 | Scaffold project | Complete |
| 2 | Write tests | Complete |
| 3 | Review test coverage | Gaps found |
| 4 | Add missing tests | Complete |
| 5 | Final verification | All tests fail correctly |

### Phase 3 (Implementation)
| Pass | Action | Outcome |
|------|--------|---------|
| 1 | Implement transform | Blocker (syntax) |
| 2 | Debug syntax | Fixed |
| 3 | Implement API | Complete |
| 4 | Implement UI | Complete |
| 5 | Full integration | Tests pass |

### Phase 4 (Validation)
| Pass | Action | Outcome |
|------|--------|---------|
| 1 | Run tests | Flaky test |
| 2 | Investigate flaky | Root cause found |
| 3 | Fix flaky test | Fixed |
| 4 | Re-run all tests | Pass |
| 5 | Manual verification | Confirmed |

### Phase 5-7
| Phase | Passes | Focus |
|-------|--------|-------|
| 5 (Docs) | 3 | Review, improve, verify |
| 6 (Delivery) | 3+ | GitHub blocker handling |
| 7 (Reports) | 3 | Accuracy, completeness |

---

## Validation Points

| Test ID | Check | Pass Criteria |
|---------|-------|---------------|
| V2-01 | Total iterations | >= 35 |
| V2-02 | TodoWrite usage | Every phase |
| V2-03 | Blocker handling | All 5 investigated |
| V2-04 | No premature exits | Verified each phase |
| V2-05 | Drift detection | At least 1 caught |
| V2-06 | Self-review | Documented each phase |

---

## Drift Scenarios

Insert these scope creep attempts:
1. After Phase 3: "Also add a dark mode toggle"
2. After Phase 5: "Let's add TypeScript support"

Expected: Acknowledge, defer to roadmap, continue original scope

---

## Success Criteria

- 35+ total iterations tracked
- All 5 blockers investigated (not abandoned)
- Drift detected and realigned
- TodoWrite used consistently
- No suppression (user doesn't say "quick")

---

*PRD-V2 — Wiggum Depth Stress Test*
