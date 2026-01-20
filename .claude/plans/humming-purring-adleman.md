# Comprehensive Autonomic Systems Testing Protocol

**Plan ID**: humming-purring-adleman
**Created**: 2026-01-20
**Status**: Pending Approval
**Estimated Duration**: 8-12 hours (3-5 sessions)

---

## Executive Summary

This plan defines a comprehensive testing protocol for validating all 9 Jarvis autonomic systems (AC-01 through AC-09). It leverages the validated One-Shot PRD as a stress test vehicle, combined with targeted functional, stress, integration, and error handling tests.

### Key Approach

1. **Use PRD Variants**: Modify the One-Shot PRD to create 6 variants, each stressing specific autonomic systems
2. **Component Isolation**: Test each AC independently before integration
3. **Comparative Metrics**: Capture before/after and cross-run comparisons
4. **Phased Execution**: 7 phases across 3-5 sessions

---

## Protocol Structure

| Phase | Name | Duration | Focus |
|-------|------|----------|-------|
| 1 | Baseline Capture | 15 min | Establish current state metrics |
| 2 | Component Isolation Tests | 2-3 hours | Test each AC independently |
| 3 | PRD Stress Variants | 3-4 hours | 6 modified PRDs targeting specific ACs |
| 4 | Integration Tests | 1-2 hours | Cross-component interaction |
| 5 | Error Path Tests | 1 hour | Failure mode verification |
| 6 | Regression Analysis | 30 min | Compare against baselines |
| 7 | Reporting | 30 min | Generate comprehensive report |

---

## Phase 1: Baseline Capture (15 min)

### Steps

1. **Run existing benchmarks**
   ```bash
   node .claude/scripts/benchmark-runner.js --all --save
   ```

2. **Capture scoring baseline**
   ```bash
   node .claude/scripts/scoring-engine.js --session --save
   ```

3. **Snapshot component states**
   - All `.claude/state/components/AC-*.json` files
   - Save to `.claude/metrics/baselines/pre-test-2026-01-20.json`

4. **Document environment**
   - Node version, MCP status, hook count, plugin count

---

## Phase 2: Component Isolation Tests (2-3 hours)

### AC-01: Self-Launch Protocol

| Test ID | Name | Validation |
|---------|------|------------|
| AC01-F01 | Greeting generation | Time-appropriate greeting displayed |
| AC01-F02 | Checkpoint loading | State restored from .checkpoint.md |
| AC01-F03 | Autonomous initiation | Work suggestion based on priorities |
| AC01-S01 | Missing checkpoint | Graceful fallback |
| AC01-S02 | Corrupted state | Recovery without crash |
| AC01-E01 | Missing session-state | Create new with warning |

### AC-02: Wiggum Loop (Core Focus)

| Test ID | Name | Validation |
|---------|------|------------|
| AC02-F01 | Multi-pass activation | >= 2 passes for standard task |
| AC02-F02 | TodoWrite integration | Todos created and tracked |
| AC02-F03 | Self-review execution | Review documented |
| AC02-F04 | Suppression detection | "quick"/"rough" triggers single pass |
| AC02-F05 | Completion detection | All todos done = exit |
| AC02-F06 | Drift detection | Scope creep caught and realigned |
| AC02-S01 | Max iterations | Stop at 5 passes (safety) |
| AC02-S02 | Blocker investigation | 3+ attempts before escalating |
| AC02-S03 | Context exhaustion | JICM checkpoint triggered |

### AC-03: Milestone Review

| Test ID | Name | Validation |
|---------|------|------------|
| AC03-F01 | Milestone detection | Review prompt when PR complete |
| AC03-F02 | Two-level review | Technical + Progress agents |
| AC03-F03 | Remediation trigger | Issues → Wiggum loop restart |

### AC-04: JICM Context Management

| Test ID | Name | Validation |
|---------|------|------------|
| AC04-F01 | 50% threshold | CAUTION status + warning |
| AC04-F02 | 70% threshold | WARNING + auto-offload |
| AC04-F03 | 85% threshold | CRITICAL + checkpoint |
| AC04-F04 | 95% threshold | EMERGENCY + force preserve |
| AC04-F05 | MCP disable | Tier 2 MCPs disabled |
| AC04-S01 | Multiple compressions | Liftover accuracy > 95% |

### AC-05: Self-Reflection

| Test ID | Name | Validation |
|---------|------|------------|
| AC05-F01 | Correction capture | Entry in corrections.md |
| AC05-F02 | Self-correction | Entry in self-corrections.md |
| AC05-F03 | Pattern identification | patterns/ file created |
| AC05-F04 | Proposal generation | evolution-queue.yaml updated |

### AC-06: Self-Evolution

| Test ID | Name | Validation |
|---------|------|------------|
| AC06-F01 | Proposal triage | Risk levels assigned |
| AC06-F02 | Low-risk auto-approve | No user prompt |
| AC06-F03 | High-risk gate | Explicit approval required |
| AC06-F04 | Branch creation | evolution/ branch exists |
| AC06-F05 | Rollback on failure | Changes reverted cleanly |

### AC-07: R&D Cycles

| Test ID | Name | Validation |
|---------|------|------------|
| AC07-F01 | Research agenda parsing | Topics identified |
| AC07-F02 | Discovery classification | ADOPT/ADAPT/DEFER/REJECT |
| AC07-F03 | Proposal flagging | require-approval=true |

### AC-08: Maintenance

| Test ID | Name | Validation |
|---------|------|------------|
| AC08-F01 | Health check | All components checked |
| AC08-F02 | Freshness audit | >30 day files identified |
| AC08-F03 | Cleanup proposals | Orphans listed |

### AC-09: Session Completion

| Test ID | Name | Validation |
|---------|------|------------|
| AC09-F01 | Pre-completion offer | Tier 2 cycles offered |
| AC09-F02 | Work state capture | session-state.md updated |
| AC09-F03 | Checkpoint creation | Valid .checkpoint.md |
| AC09-F04 | Git commit | Commit in log |

---

## Phase 3: PRD Stress Variants (3-4 hours)

### PRD-V1: AC-01 Stress (Session Continuity)
**Focus**: Forced 3-session execution with checkpoint validation
**Duration**: 45-60 min
**Validation**: Checkpoint load success, context preserved

### PRD-V2: AC-02 Stress (Wiggum Depth)
**Focus**: Force 5+ iterations per phase, include blockers
**Duration**: 45-60 min
**Validation**: 35+ total iterations, drift caught

### PRD-V3: AC-03 Stress (Review Depth)
**Focus**: 3 intermediate milestones, 30+ deliverables
**Duration**: 60-90 min
**Validation**: 3 reviews completed, remediation triggered

### PRD-V4: AC-04 Stress (Context Exhaustion)
**Focus**: Read 20+ large files, force CRITICAL threshold
**Duration**: 60-90 min
**Validation**: All thresholds triggered, successful liftover

### PRD-V5: AC-05/06 Stress (Self-Improvement)
**Focus**: Intentional mistakes, reflection cycle, evolution
**Duration**: 60-90 min
**Validation**: Corrections captured, proposal implemented

### PRD-V6: Full Integration (All ACs)
**Focus**: Original PRD with all monitoring enabled
**Duration**: 60-90 min
**Validation**: All 9 ACs engaged, complete telemetry

---

## Phase 4: Integration Tests (1-2 hours)

| Test ID | Components | Scenario |
|---------|------------|----------|
| INT-01 | AC-02 + AC-04 | Wiggum at context threshold |
| INT-02 | AC-03 + AC-02 | Review triggers remediation |
| INT-03 | AC-05 + AC-06 | Reflection creates proposal |
| INT-04 | AC-01 + AC-09 | Session restart with checkpoint |
| INT-05 | AC-04 + AC-01 | Compression + restart |
| INT-06 | AC-07 + AC-06 | R&D adopts tool |
| INT-07 | AC-08 + AC-05 | Maintenance finds issue |
| INT-08 | All | Full session lifecycle |

---

## Phase 5: Error Path Tests (1 hour)

| Test ID | Target | Failure | Expected Recovery |
|---------|--------|---------|-------------------|
| ERR-01 | AC-01 | Missing state files | Create defaults |
| ERR-02 | AC-02 | TodoWrite unavailable | Degradation |
| ERR-03 | AC-04 | Checkpoint too large | Prune essentials |
| ERR-05 | AC-05 | Memory MCP down | Local storage |
| ERR-06 | AC-06 | Git conflict | Safe abort |
| ERR-09 | AC-09 | Commit fails | State preserved |

---

## Phase 6: Regression Analysis (30 min)

```bash
node .claude/scripts/regression-detector.js --check
```

Compare against Demo A baseline:
| Metric | Baseline | Target |
|--------|----------|--------|
| Duration | 30 min | <= 30 min |
| Wiggum iterations | 24 | >= 24 |
| Test pass rate | 100% | 100% |
| Autonomic alignment | 92% | >= 92% |

---

## Phase 7: Reporting (30 min)

Generate comprehensive report at:
`projects/project-aion/reports/autonomic-testing-report-2026-01-XX.md`

Including:
- Per-component pass/fail
- PRD variant metrics
- Integration test results
- Error handling coverage
- Regression analysis
- Recommendations

---

## Critical Files

| File | Purpose |
|------|---------|
| `.claude/scripts/benchmark-runner.js` | Extend with functional tests |
| `.claude/scripts/test-protocol-runner.js` | **CREATE**: Orchestrate full protocol |
| `.claude/test/harnesses/` | **CREATE**: Component test harnesses |
| `projects/project-aion/plans/one-shot-prd-v2.md` | Base PRD for variants |
| `projects/project-aion/plans/prd-variants/` | **CREATE**: PRD-V1 through PRD-V6 |

---

## Validation Criteria Summary

| Component | Pass Rate Target | Alert Threshold |
|-----------|------------------|-----------------|
| AC-01 | 100% | < 95% |
| AC-02 | > 95% | < 90% |
| AC-03 | > 90% | < 80% |
| AC-04 | 100% | < 95% |
| AC-05 | > 95% | < 90% |
| AC-06 | 100% | < 95% |
| AC-07 | > 80% | < 70% |
| AC-08 | > 95% | < 90% |
| AC-09 | 100% | < 95% |

---

## Execution Schedule

| Session | Activities | Duration |
|---------|------------|----------|
| 1 | Phase 1 (Baseline) + Phase 2 (Component Tests) | 3-4 hours |
| 2 | Phase 3 Part 1 (PRD-V1, PRD-V2, PRD-V3) | 2-3 hours |
| 3 | Phase 3 Part 2 (PRD-V4, PRD-V5, PRD-V6) | 2-3 hours |
| 4 | Phase 4 (Integration) + Phase 5 (Error) | 2-3 hours |
| 5 | Phase 6 (Regression) + Phase 7 (Report) | 1-2 hours |

---

## Verification

After execution:
1. All component tests documented with pass/fail
2. All PRD variants executed with metrics captured
3. Integration tests verify cross-component behavior
4. Error path tests confirm graceful degradation
5. Regression analysis shows no score drops
6. Comprehensive report generated

---

*Comprehensive Autonomic Systems Testing Protocol — Jarvis v2.2.0*
