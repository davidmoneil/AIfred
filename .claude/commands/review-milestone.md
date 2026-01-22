# /review-milestone Command

Run a two-level independent review of a completed milestone/PR deliverables.

## Usage

```
/review-milestone <milestone-id>
```

## Examples

```
/review-milestone PR-12.3
/review-milestone PR-11
/review-milestone Phase-5
```

## What It Does

Performs a comprehensive, independent review of milestone deliverables using a two-level review process with separate agents to ensure objectivity.

### Level 1: Technical Quality Review (code-review agent)

The `code-review` agent performs detailed technical analysis:

1. **File Verification**
   - Parse expected deliverables from `projects/project-aion/roadmap.md`
   - Verify all expected files exist
   - Check no unexpected files created
   - Validate file locations follow project conventions

2. **Code Quality Analysis**
   - Check code follows project style guidelines
   - Look for obvious bugs or errors
   - Verify error handling is appropriate
   - Check for edge cases
   - Identify code duplication

3. **Test Validation**
   - Verify tests exist for new functionality
   - Run tests if applicable
   - Assess test coverage
   - Note any flaky tests

4. **Tooling Validation** (for Jarvis PRs)
   - Run `/tooling-health` if applicable
   - Run `/validate-selection` if applicable

5. **Findings Generation**
   - Compile findings by severity (critical, error, warning, note)
   - Calculate quality scores (0-10)
   - Determine technical verdict (pass/conditional/fail)

### Level 2: Progress & Alignment Review (project-manager agent)

The `project-manager` agent reviews progress and alignment:

1. **Roadmap Alignment**
   - Verify all PR deliverables completed
   - Check work matches roadmap description
   - Identify any scope creep
   - Verify dependencies satisfied

2. **Documentation Review**
   - Check CHANGELOG.md has entry for this PR
   - Verify VERSION bumped (if release)
   - Check README updated (if applicable)
   - Verify inline documentation

3. **Process Compliance**
   - Review commit messages
   - Check PR description adequate
   - Verify related issues linked

4. **Progress Assessment**
   - Evaluate if milestone advances project goals
   - Check for regressions
   - Identify next priorities

5. **Final Verdict**
   - Combine Level 1 and Level 2 findings
   - Determine overall verdict (approved/conditional/rejected)

## Review Criteria

### Default Criteria

Located at `.claude/review-criteria/defaults.yaml`

### PR-Specific Criteria

If exists: `.claude/review-criteria/PR-XX.yaml`

PR-specific criteria override defaults for that milestone.

## Large Review Handling

For milestones with many deliverables:
- Segment review into focused chunks (max 10 files per segment)
- Review each segment with full context
- Aggregate findings at the end

## Output

### Console Summary

```markdown
## Milestone Review: PR-XX.X

### Level 1: Technical (code-review)
- **Verdict**: pass | conditional | fail
- **Files Reviewed**: N
- **Findings**: X critical, Y errors, Z warnings
- **Scores**: code_quality: 8, test_coverage: 7

### Level 2: Progress (project-manager)
- **Verdict**: approved | conditional | rejected
- **Deliverables**: N/N complete
- **Documentation**: CHANGELOG updated, VERSION n/a

### Final Verdict: APPROVED | CONDITIONAL | REJECTED

### Next Priorities
1. PR-XX.X: Description
2. ...
```

### Report File

Full report saved to: `.claude/reports/reviews/PR-XX-review-YYYY-MM-DD.json`

## Remediation Workflow

If issues found:
1. Create remediation todos with specific fixes
2. If critical/error issues: Block version bump
3. Trigger Wiggum Loop for remediation
4. Re-run review after fixes

## Triggering

### Manual
```
/review-milestone PR-12.3
```

### Semi-Automatic
When Jarvis detects major phase completion, prompts:
> "Review recommended for PR-XX. Any notes before proceeding?"

User approves to launch review.

## Separation of Concerns

- Review agents are **independent** of the implementer
- Criteria are defined **externally** (in review-criteria/)
- Pass/fail based on **measurable** criteria
- Human approval required for **borderline** cases

## Related

- @.claude/agents/code-review.md - Level 1 technical reviewer
- @.claude/agents/project-manager.md - Level 2 progress reviewer
- @.claude/review-criteria/defaults.yaml - Default review criteria
- @.claude/context/templates/review-report-template.md - Report template
- @projects/project-aion/ideas/phase-6-autonomy-design.md - System 3 specification
