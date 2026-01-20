# PRD Stress Variants

**Created**: 2026-01-20
**Purpose**: Comprehensive Autonomic Systems Testing Protocol

---

## Overview

These 6 PRD variants are based on the One-Shot PRD v2.0 (Aion Hello Console), each modified to stress-test specific autonomic components.

## Variant Summary

| Variant | Target | Focus | Duration |
|---------|--------|-------|----------|
| PRD-V1 | AC-01 | Session Continuity | 45-60 min |
| PRD-V2 | AC-02 | Wiggum Depth | 45-60 min |
| PRD-V3 | AC-03 | Review Depth | 60-90 min |
| PRD-V4 | AC-04 | Context Exhaustion | 60-90 min |
| PRD-V5 | AC-05/06 | Self-Improvement | 60-90 min |
| PRD-V6 | All | Full Integration | 60-90 min |

---

## Execution Order

Recommended execution order for comprehensive testing:

### Session 2 (Phase 3, Part 1)
1. **PRD-V1** — Session Continuity
2. **PRD-V2** — Wiggum Depth
3. **PRD-V3** — Review Depth

### Session 3 (Phase 3, Part 2)
4. **PRD-V4** — Context Exhaustion
5. **PRD-V5** — Self-Improvement
6. **PRD-V6** — Full Integration

---

## Per-Variant Details

### PRD-V1: Session Continuity
- **File**: `PRD-V1-session-continuity.md`
- **Target**: AC-01 Self-Launch Protocol
- **Key Tests**: Checkpoint creation, checkpoint loading, context preservation
- **Forced Breaks**: 3 (after Phase 2, 4, 6)

### PRD-V2: Wiggum Depth
- **File**: `PRD-V2-wiggum-depth.md`
- **Target**: AC-02 Wiggum Loop
- **Key Tests**: 35+ iterations, blocker investigation, drift detection
- **Intentional Blockers**: 5 planted

### PRD-V3: Review Depth
- **File**: `PRD-V3-review-depth.md`
- **Target**: AC-03 Milestone Review
- **Key Tests**: 3 milestone reviews, dual-agent review, remediation trigger
- **Deliverables**: 34 tracked

### PRD-V4: Context Exhaustion
- **File**: `PRD-V4-context-exhaustion.md`
- **Target**: AC-04 JICM Context Management
- **Key Tests**: All 4 thresholds, MCP disable, liftover accuracy
- **Files to Read**: 20+

### PRD-V5: Self-Improvement
- **File**: `PRD-V5-self-improvement.md`
- **Target**: AC-05 Self-Reflection, AC-06 Self-Evolution
- **Key Tests**: Correction capture, pattern identification, evolution rollback
- **Intentional Mistakes**: 4 planted

### PRD-V6: Full Integration
- **File**: `PRD-V6-full-integration.md`
- **Target**: All 9 autonomic components
- **Key Tests**: Full telemetry, cross-component interactions
- **Baseline Comparison**: Demo A (2026-01-18)

---

## Metrics Collection

Each variant should capture:
1. Duration
2. Wiggum iterations
3. Test pass rate
4. Component-specific metrics (per variant)
5. Issues encountered

Store results in:
`projects/project-aion/reports/prd-variant-results-YYYY-MM-DD.md`

---

## Related Files

- Base PRD: `../one-shot-prd-v2.md`
- Test Protocol: `.claude/scripts/test-protocol-runner.js`
- Baseline: `.claude/metrics/baselines/pre-test-2026-01-20.json`

---

*PRD Stress Variants — Autonomic Systems Testing*
