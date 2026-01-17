# Validation Report: {PLAN_NAME}

**Generated**: {TIMESTAMP}
**Status**: {STATUS}

---

## Summary

| Metric | Value |
|--------|-------|
| Total Checks | {TOTAL_CHECKS} |
| Passed | {PASSED} |
| Failed | {FAILED} |
| Warnings | {WARNINGS} |
| Skipped | {SKIPPED} |

**Ready to Merge**: {READY_TO_MERGE}

---

## Stage Results

### 1. Static Analysis

| Check | Status | Details |
|-------|--------|---------|
| Linting | {LINT_STATUS} | {LINT_DETAILS} |
| Type Check | {TYPE_STATUS} | {TYPE_DETAILS} |
| Formatting | {FORMAT_STATUS} | {FORMAT_DETAILS} |

{LINT_ISSUES}

### 2. Testing

| Check | Status | Details |
|-------|--------|---------|
| Unit Tests | {UNIT_STATUS} | {UNIT_DETAILS} |
| Integration Tests | {INT_STATUS} | {INT_DETAILS} |

**Coverage**: {COVERAGE}%

{TEST_FAILURES}

### 3. Build Verification

| Check | Status | Details |
|-------|--------|---------|
| Production Build | {BUILD_STATUS} | {BUILD_DETAILS} |
| Bundle Size | {SIZE_STATUS} | {SIZE_DETAILS} |

### 4. Acceptance Criteria

| Criterion | Verified | Evidence |
|-----------|----------|----------|
{CRITERIA_TABLE}

---

## Blockers

{BLOCKERS}

## Recommendations

{RECOMMENDATIONS}

---

## Next Steps

{NEXT_STEPS}

---

## Execution Details

- **Plan**: {PLAN_NAME}
- **Worktree**: {WORKTREE_PATH}
- **Branch**: {BRANCH_NAME}
- **Validated At**: {TIMESTAMP}
