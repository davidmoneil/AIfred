# Milestone Review Pattern

**Version**: 1.1.0
**Created**: 2026-01-16
**Validated**: 2026-01-20 (PRD-V3: 100% issue detection rate)
**Component**: AC-03 Milestone Review
**PR**: PR-12.3

---

## Validation Results (PRD-V3)

| Metric | Result |
|--------|--------|
| Issues Planted | 3 (empty string tests, typo, missing LICENSE) |
| Issues Detected | 3 (100% detection rate) |
| Remediations Triggered | 3 |
| Final Quality Ratings | All 5/5 after remediation |
| Milestone Reviews | 3/3 completed with formal reports |

**Key Success Factors**:
1. Explicit STOP directive at boundaries prevented skipping reviews
2. Deliverable checklist ensured comprehensive coverage
3. Rating threshold (>= 4) enforced quality gates
4. Formal report generation created audit trail

---

## Overview

The Milestone Review Pattern defines how Jarvis independently evaluates completed work to ensure quality, completeness, and alignment with project objectives. It uses a two-level review process combining technical analysis with progress assessment.

### Core Principle

**Review is NOT implementation.** The reviewer (agents) should not be the same entity that did the work. This separation provides objective evaluation and catches issues that tunnel-vision from implementation might miss.

---

## 1. Two-Level Review Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                    MILESTONE REVIEW ARCHITECTURE                     │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │  LEVEL 1: TECHNICAL REVIEW (code-review agent)                 │  │
│  │                                                                 │  │
│  │  Focus: Code quality, implementation correctness, testing      │  │
│  │                                                                 │  │
│  │  Inputs:                                                        │  │
│  │    - Changed files from PR/milestone                           │  │
│  │    - Test results                                              │  │
│  │    - Tooling health output                                     │  │
│  │                                                                 │  │
│  │  Outputs:                                                       │  │
│  │    - Technical findings (issues, warnings, notes)              │  │
│  │    - Code quality score                                        │  │
│  │    - Test coverage assessment                                  │  │
│  │    - Remediation items (if any)                                │  │
│  └───────────────────────────────────────────────────────────────┘  │
│                              │                                       │
│                              ▼                                       │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │  LEVEL 2: PROGRESS REVIEW (project-manager agent)              │  │
│  │                                                                 │  │
│  │  Focus: Roadmap alignment, documentation, completeness         │  │
│  │                                                                 │  │
│  │  Inputs:                                                        │  │
│  │    - Level 1 technical report                                  │  │
│  │    - Roadmap deliverables for this PR                          │  │
│  │    - CHANGELOG.md                                              │  │
│  │    - VERSION file                                              │  │
│  │                                                                 │  │
│  │  Outputs:                                                       │  │
│  │    - Progress assessment                                       │  │
│  │    - Documentation completeness                                │  │
│  │    - Roadmap status recommendation                             │  │
│  │    - Next priorities suggestion                                │  │
│  └───────────────────────────────────────────────────────────────┘  │
│                              │                                       │
│                              ▼                                       │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │  FINAL VERDICT                                                  │  │
│  │                                                                 │  │
│  │  Combines both levels into:                                    │  │
│  │    - Overall approval status                                   │  │
│  │    - Consolidated findings                                     │  │
│  │    - Action items                                              │  │
│  └───────────────────────────────────────────────────────────────┘  │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 2. Level 1: Technical Review

### Agent Configuration

```yaml
agent: code-review
model: sonnet  # Balance speed and quality
thoroughness: standard  # quick | standard | thorough
```

### Review Checklist

#### 2.1 File Verification
- [ ] All expected files exist
- [ ] No unexpected files created
- [ ] File locations follow project conventions
- [ ] No secrets or credentials committed

#### 2.2 Code Quality
- [ ] Code follows project style guidelines
- [ ] No obvious bugs or errors
- [ ] Error handling is appropriate
- [ ] Edge cases considered
- [ ] No code duplication (DRY)

#### 2.3 Testing
- [ ] Tests exist for new functionality
- [ ] Tests pass
- [ ] Coverage is adequate
- [ ] No flaky tests introduced

#### 2.4 Tooling Validation
```bash
# Run if applicable
/tooling-health
/validate-selection
```

### Technical Findings Format

```json
{
  "level": 1,
  "reviewer": "code-review",
  "timestamp": "2026-01-16T14:30:00.000Z",
  "milestone": "PR-12.3",
  "findings": [
    {
      "severity": "warning",
      "category": "code_quality",
      "file": "path/to/file.ts",
      "line": 42,
      "message": "Function exceeds recommended complexity",
      "remediation": "Consider breaking into smaller functions"
    }
  ],
  "scores": {
    "code_quality": 8,
    "test_coverage": 7,
    "documentation": 9
  },
  "verdict": "pass_with_notes"
}
```

### Severity Levels

| Severity | Description | Blocks Release |
|----------|-------------|----------------|
| `critical` | Security issue, data loss risk | Yes |
| `error` | Functionality broken | Yes |
| `warning` | Quality concern, should fix | No |
| `note` | Suggestion, optional improvement | No |

---

## 3. Level 2: Progress Review

### Agent Configuration

```yaml
agent: project-manager
model: sonnet
focus: progress_alignment
```

### Review Checklist

#### 3.1 Roadmap Alignment
- [ ] All PR deliverables completed
- [ ] Work matches roadmap description
- [ ] No scope creep (unplanned additions)
- [ ] Dependencies satisfied

#### 3.2 Documentation
- [ ] CHANGELOG.md updated
- [ ] VERSION bumped (if release)
- [ ] README updated (if applicable)
- [ ] API docs updated (if applicable)

#### 3.3 Process Compliance
- [ ] Commits follow conventions
- [ ] PR description adequate
- [ ] Related issues linked

#### 3.4 Progress Assessment
- [ ] Milestone advances project goals
- [ ] No regressions introduced
- [ ] Ready for next phase

### Progress Findings Format

```json
{
  "level": 2,
  "reviewer": "project-manager",
  "timestamp": "2026-01-16T14:35:00.000Z",
  "milestone": "PR-12.3",
  "roadmap_status": {
    "deliverables_expected": 4,
    "deliverables_complete": 4,
    "deliverables_partial": 0,
    "deliverables_missing": 0
  },
  "documentation": {
    "changelog_updated": true,
    "version_bumped": false,
    "docs_complete": true
  },
  "findings": [
    {
      "category": "process",
      "message": "Consider adding entry to CHANGELOG.md",
      "severity": "note"
    }
  ],
  "next_priorities": [
    "PR-12.4: AC-04 JICM Implementation"
  ],
  "verdict": "approved"
}
```

---

## 4. Review Workflow

### 4.1 Trigger Detection

```
┌─────────────────────────────────────────────────────────────────────┐
│                    REVIEW TRIGGER DETECTION                          │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  AC-02 Wiggum Loop completes task                                   │
│           │                                                          │
│           ▼                                                          │
│  Is completed task a PR/milestone?                                  │
│           │                                                          │
│      ┌────┴────┐                                                    │
│      │         │                                                    │
│     Yes        No                                                   │
│      │         │                                                    │
│      ▼         ▼                                                    │
│  Prompt user   No review                                            │
│  for review    prompt                                               │
│      │                                                              │
│      ▼                                                              │
│  "Review recommended for PR-12.3.                                   │
│   Any notes before I proceed?"                                      │
│      │                                                              │
│      ▼                                                              │
│  User approves → Launch full review                                 │
│  User declines → Defer until requested                              │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### 4.2 Review Execution

```
1. USER PROMPT
   └── "Review recommended. Any notes?"
   └── User: "yes" / "yes, check X carefully" / "later"

2. LEVEL 1 LAUNCH
   └── Spawn code-review agent
   └── Pass: changed files, test results, criteria
   └── Collect: technical findings

3. LEVEL 2 LAUNCH
   └── Spawn project-manager agent
   └── Pass: Level 1 report, roadmap, changelog
   └── Collect: progress findings

4. VERDICT SYNTHESIS
   └── Combine findings from both levels
   └── Calculate overall status
   └── Generate report

5. OUTCOME HANDLING
   └── If approved → update roadmap, version
   └── If conditional → note caveats
   └── If rejected → trigger remediation
```

### 4.3 Large Scope Handling

For milestones with many deliverables (>10 files or >5 features):

```
┌─────────────────────────────────────────────────────────────────────┐
│                    SEGMENTED REVIEW                                  │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  1. INVENTORY                                                        │
│     └── List all deliverables                                       │
│     └── Group by category/feature                                   │
│                                                                      │
│  2. SEGMENT                                                          │
│     └── Create review segments (3-5 items each)                     │
│     └── Order by dependency                                         │
│                                                                      │
│  3. REVIEW PER SEGMENT                                              │
│     └── Level 1 for segment                                         │
│     └── Accumulate findings                                         │
│     └── Context check between segments                              │
│                                                                      │
│  4. AGGREGATE                                                        │
│     └── Combine all segment findings                                │
│     └── Level 2 on full scope                                       │
│     └── Final verdict                                               │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 5. Default Review Criteria

### When No Criteria File Exists

```yaml
# .claude/review-criteria/defaults.yaml
version: 1.0.0

technical:
  required:
    - files_exist: true
    - no_syntax_errors: true
    - tests_pass: true
  recommended:
    - test_coverage_min: 60
    - no_warnings: true
    - docs_updated: true

progress:
  required:
    - deliverables_complete: true
    - changelog_updated: true
  recommended:
    - version_bumped: true
    - no_scope_creep: true

thresholds:
  min_score_for_pass: 7
  critical_issues_allowed: 0
  error_issues_allowed: 0
  warning_issues_allowed: 5
```

### PR-Specific Criteria

```yaml
# .claude/review-criteria/PR-12.3.yaml
version: 1.0.0
pr: PR-12.3
description: Independent Milestone Review

deliverables:
  - path: .claude/context/components/AC-03-milestone-review.md
    type: component_spec
    validation:
      - has_all_9_sections: true
      - follows_template: true

  - path: .claude/context/patterns/milestone-review-pattern.md
    type: pattern_doc
    validation:
      - describes_workflow: true
      - has_examples: true

custom_checks:
  - name: two_level_review_defined
    description: Both code-review and project-manager levels specified
    check: grep -q "Level 1.*Level 2" components/AC-03*.md

acceptance:
  - All component spec sections complete
  - Pattern document comprehensive
  - Integration with AC-02 defined
```

---

## 6. Report Generation

### Report Template

```markdown
# Milestone Review Report: [PR-ID]

**Date**: [timestamp]
**Reviewer**: Jarvis AC-03
**Duration**: [X minutes]

---

## Summary

| Aspect | Status |
|--------|--------|
| Technical Review | [pass/conditional/fail] |
| Progress Review | [pass/conditional/fail] |
| **Overall** | **[APPROVED/CONDITIONAL/REJECTED]** |

---

## Technical Findings (Level 1)

### Critical Issues
[None / List]

### Errors
[None / List]

### Warnings
[List with recommendations]

### Notes
[Optional improvements]

### Scores
- Code Quality: X/10
- Test Coverage: X/10
- Documentation: X/10

---

## Progress Findings (Level 2)

### Deliverables
| Expected | Complete | Status |
|----------|----------|--------|
| [item] | [yes/partial/no] | [emoji] |

### Documentation
- CHANGELOG: [updated/needs update]
- VERSION: [bumped/needs bump]

### Roadmap Status
[Ready to mark complete / Needs work]

---

## Action Items

### Required Before Release
1. [if any]

### Recommended
1. [if any]

---

## Next Steps

[Based on review outcome]

---

*Generated by Jarvis AC-03 Milestone Review*
```

### Report Storage

```
.claude/reports/reviews/
├── PR-12.3-review-2026-01-16.md
├── PR-12.2-review-2026-01-15.md
└── ...
```

---

## 7. Outcome Handling

### Approved

```
1. Update roadmap.md
   └── Mark PR as complete
   └── Add completion date

2. Version bump (if release milestone)
   └── Update VERSION file
   └── Add CHANGELOG entry

3. Memory entry
   └── Create milestone_completed entity
   └── Link to review findings

4. Notify user
   └── "PR-12.3 review passed. Roadmap updated."
```

### Conditional

```
1. Document caveats
   └── Note in review report
   └── Add to roadmap entry

2. Do NOT block
   └── Work can proceed
   └── Issues tracked for future

3. Notify user
   └── "PR-12.3 approved with notes: [caveats]"
```

### Rejected

```
1. Generate remediation todos
   └── Convert critical/error issues to todos
   └── Prioritize by severity

2. Trigger AC-02 Wiggum Loop
   └── Pass remediation todos
   └── Loop will fix issues

3. Hold roadmap update
   └── PR remains incomplete
   └── Re-review after remediation

4. Notify user
   └── "PR-12.3 needs work. [X] issues found. Remediation started."
```

---

## 8. Integration Points

### With AC-02 Wiggum Loop

```
AC-02 completes PR work
        │
        ▼
AC-03 detects completion, prompts review
        │
        ▼
Review executes
        │
        ├── If pass → roadmap update
        │
        └── If fail → AC-02 remediation loop
                │
                ▼
        AC-03 re-review after remediation
```

### With AC-05 Self-Reflection

```
Review findings feed into reflection:
- Quality patterns over time
- Common issue types
- Review efficiency metrics
```

### With Memory MCP

```
Store in Memory:
- Review outcomes
- Recurring issue patterns
- Quality trends
```

---

## 9. Examples

### Successful Review

```
User has just completed PR-12.3 implementation via Wiggum Loop.

Jarvis: "Review recommended for PR-12.3 (Milestone Review).
        Any notes before I proceed?"

User: "yes, especially check the two-level review is properly defined"

[AC-03 activates]

Level 1 (code-review agent):
- Verified AC-03 component spec exists
- Checked all 9 sections present
- No syntax errors
- Pattern document comprehensive
- Score: 9/10

Level 2 (project-manager agent):
- All 4 deliverables complete
- CHANGELOG needs update
- Roadmap alignment: good
- Next priority: PR-12.4

Verdict: CONDITIONAL (minor: changelog)

Jarvis: "PR-12.3 review complete.
        Status: Approved with note
        - Add CHANGELOG entry for AC-03
        Roadmap updated. Proceeding to PR-12.4?"
```

### Review with Remediation

```
User: "review PR-12.4"

[AC-03 activates]

Level 1 findings:
- ERROR: JICM state file schema incomplete
- WARNING: Missing edge case handling

Level 2 findings:
- Deliverable 3/4 complete (partial)

Verdict: REJECTED

Jarvis: "PR-12.4 review complete.
        Status: Needs work
        - 1 error: JICM state schema incomplete
        - 1 warning: Missing edge case handling

        Starting remediation..."

[AC-02 Wiggum Loop activates with remediation todos]
[After fixes]

Jarvis: "Remediation complete. Re-running review..."

[AC-03 re-review]

Verdict: APPROVED

Jarvis: "PR-12.4 re-review passed. Roadmap updated."
```

---

## 10. Metrics

| Metric | Target | Alert Threshold |
|--------|--------|-----------------|
| Review time | < 15 min | > 30 min |
| First-pass approval rate | > 80% | < 60% |
| Remediation success rate | > 95% | < 85% |
| False positive rate | < 5% | > 15% |

---

## 11. Reliable Activation

### Trigger Phrases

Jarvis should activate milestone review when:

| Phrase | Activation |
|--------|------------|
| "Execute PRD" / "Run PRD" | PRDs have natural milestones |
| "Build [feature] with reviews" | Explicit review request |
| "Quality gates at each phase" | Direct activation |
| "Review before proceeding" | Checkpoint trigger |
| "Stop and review at M[N]" | Specific milestone |

### Making Reviews Mandatory

To ensure reviews aren't skipped, structure PRDs/tasks with:

1. **Explicit STOP directives**:
   ```markdown
   After M1 Deliverables → STOP for Review
   After M2 Deliverables → STOP for Review
   ```

2. **Deliverable checklists** (enables comprehensive review):
   ```markdown
   | # | Deliverable | Verification |
   |---|-------------|--------------|
   | 1 | package.json | File exists |
   | 2 | tests pass | npm test |
   ```

3. **Review reports as deliverables** (forces report generation):
   ```markdown
   | 12 | **Milestone 1 Review Report** | Generated |
   ```

4. **PROCEED/REMEDIATE decision gate**:
   ```markdown
   Decision:
   - [ ] PROCEED if ratings >= 4
   - [ ] REMEDIATE if ratings < 4
   ```

### Injection into CLAUDE.md

Add to task instructions when milestone reviews are needed:

```markdown
## Quality Gates

This task requires AC-03 Milestone Reviews at phase boundaries:
- After Phase [X]: STOP → Review → PROCEED/REMEDIATE
- After Phase [Y]: STOP → Review → PROCEED/REMEDIATE
- After Phase [Z]: STOP → Final Review → Complete

Reference: @.claude/context/patterns/milestone-review-pattern.md
```

### Integration with Wiggum Loop

Milestone reviews and Wiggum Loop work together:

```
┌─────────────────────────────────────────────────────────────┐
│  WITHIN Milestone: AC-02 Wiggum Loop (micro-iteration)     │
│    Execute → Check → Review → Continue                      │
├─────────────────────────────────────────────────────────────┤
│  AT Milestone Boundary: AC-03 Review (macro-gate)          │
│    STOP → Technical Review → Progress Review → Decision    │
└─────────────────────────────────────────────────────────────┘
```

---

*Milestone Review Pattern — Jarvis Phase 6 PR-12.3 (Validated PRD-V3 2026-01-20)*
