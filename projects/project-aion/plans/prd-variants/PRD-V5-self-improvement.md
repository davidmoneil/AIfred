# PRD-V5: AC-05/06 Self-Improvement Stress Test

**Based on**: One-Shot PRD v2.0
**Target Systems**: AC-05 Self-Reflection, AC-06 Self-Evolution
**Focus**: Intentional mistakes, reflection cycle, evolution

---

## Stress Modifications

### Intentional Mistakes

Insert these mistakes to trigger self-correction:

| Phase | Mistake | Expected Correction |
|-------|---------|---------------------|
| Phase 2 | Missing test edge case | Add during review |
| Phase 3 | Inefficient algorithm | Optimize on detection |
| Phase 4 | Incorrect error message | Fix in self-review |
| Phase 5 | Incomplete documentation | Enhance before delivery |

### Correction Capture

Each correction must be logged to:
- `corrections.md` (if user-corrected)
- `self-corrections.md` (if self-corrected)

---

## AC-05 Self-Reflection Requirements

### Correction Capture Format

```markdown
## [Date] - [Category]

**Issue**: [What went wrong]
**Root Cause**: [Why it happened]
**Correction**: [What was done]
**Prevention**: [How to avoid in future]
```

### Pattern Identification

If same issue occurs 2+ times, create pattern file:
- `.claude/context/lessons/patterns/[pattern-name].md`

### Proposal Generation

After significant corrections, generate:
- Evolution queue entry with improvement proposal
- Risk level assessment
- Implementation approach

---

## AC-06 Self-Evolution Requirements

### Proposal Triage

| Risk Level | Auto-approve | Example |
|------------|--------------|---------|
| Low | Yes | Add comment, fix typo |
| Medium | Ask | Add new test case |
| High | Require explicit | Modify hook behavior |

### Evolution Workflow

1. **Proposal Created** (from AC-05)
2. **Risk Assessed** (low/medium/high)
3. **Branch Created** (`evolution/proposal-name`)
4. **Implementation** (isolated)
5. **Validation** (tests pass)
6. **Merge or Rollback**

### Rollback Testing

Force at least one evolution to fail:
- Intentionally break a test
- Verify rollback executes cleanly
- Confirm no residual changes

---

## Test Metrics

| Metric | Target |
|--------|--------|
| Mistakes planted | 4 |
| Self-corrections | >= 2 |
| User corrections | >= 1 |
| Patterns identified | >= 1 |
| Proposals generated | >= 2 |
| Evolutions attempted | >= 1 |
| Rollbacks tested | 1 |

---

## Reflection Cycle

### End of Each Phase

1. Review what was done
2. Identify any issues
3. Log corrections (self or user)
4. Consider patterns
5. Generate proposals if significant

### Reflection Report Format

```markdown
## Phase [N] Reflection

### What Went Well
- [list]

### What Could Improve
- [list]

### Corrections Made
- [list with links to correction logs]

### Proposals Generated
- [list with links to evolution queue]
```

---

## Evolution Queue Format

```yaml
proposals:
  - id: EVO-2026-XX-XX-001
    title: "Add edge case for empty input"
    source: self-reflection
    risk_level: low
    requires_approval: false
    status: pending
    created: 2026-XX-XX

  - id: EVO-2026-XX-XX-002
    title: "Improve error handling pattern"
    source: user-correction
    risk_level: medium
    requires_approval: true
    status: pending
    created: 2026-XX-XX
```

---

## Validation Points

| Test ID | Check | Pass Criteria |
|---------|-------|---------------|
| V5-01 | Correction captured | corrections.md updated |
| V5-02 | Self-correction logged | self-corrections.md updated |
| V5-03 | Pattern identified | patterns/ file created |
| V5-04 | Proposal generated | evolution-queue.yaml entry |
| V5-05 | Low-risk auto-approve | No prompt |
| V5-06 | High-risk gate | Explicit approval |
| V5-07 | Branch created | evolution/ branch exists |
| V5-08 | Rollback clean | No residual changes |

---

## Mistake Injection Details

### Mistake 1: Missing Edge Case (Phase 2)
```javascript
// Missing test for empty string input
// Should catch in self-review
test('slugify handles empty string', () => {
  expect(slugify('')).toBe('');  // MISSING
});
```

### Mistake 2: Inefficient Algorithm (Phase 3)
```javascript
// O(n^2) when O(n) is possible
function wordCount(text) {
  // Inefficient: splits twice
  return text.split(' ').filter(w => w).join(' ').split(' ').length;
}
```

### Mistake 3: Wrong Error Message (Phase 4)
```javascript
// Incorrect error type
throw new Error('Invalid input');  // Should be 'Unknown operation'
```

### Mistake 4: Missing API Docs (Phase 5)
```markdown
## API Documentation

<!-- Missing: Response format examples -->
<!-- Missing: Error codes -->
```

---

## Success Criteria

- All 4 mistakes caught (self or user)
- Correction logs populated
- At least 1 pattern identified
- Evolution queue has proposals
- 1 evolution attempted
- 1 rollback tested successfully

---

*PRD-V5 — Self-Improvement Stress Test*
