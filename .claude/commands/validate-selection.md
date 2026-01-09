# /validate-selection Command

Validate selection intelligence by running through documented test cases.

## Purpose

This command helps verify that tool/agent/skill selection follows documented patterns. It can run in two modes:

1. **Audit Mode** (default): Review recent selection decisions
2. **Test Mode**: Run through test cases and record results

## Usage

```
/validate-selection           # Audit mode - review recent selections
/validate-selection --test    # Test mode - run test cases
/validate-selection --report  # Generate validation report
```

## Audit Mode Instructions

When invoked without arguments, review recent tool/agent/skill selections:

1. **Read the selection audit log**:
   ```bash
   cat .claude/logs/selection-audit.jsonl 2>/dev/null | tail -20
   ```

2. **Analyze selection patterns**:
   - Check if selections match documented patterns in @selection-intelligence-guide.md
   - Identify any deviations from expected behavior
   - Note any over-engineering (using complex tools for simple tasks)
   - Note any under-engineering (using simple tools for complex tasks)

3. **Report findings**:
   - List correct selections
   - List questionable selections with rationale
   - Suggest improvements

## Test Mode Instructions

When invoked with `--test`, run through the 10 documented test cases:

### Test Cases (from @selection-validation-tests.md)

| ID | Input | Expected |
|----|-------|----------|
| SEL-01 | "Find package.json files" | Glob |
| SEL-02 | "What files handle auth?" | Explore subagent |
| SEL-03 | "Create a Word document" | docx skill |
| SEL-04 | "Research Docker networking" | deep-research agent |
| SEL-05 | "Quick fact: capital of France" | WebSearch |
| SEL-06 | "Comprehensive analysis of X" | gptresearcher |
| SEL-07 | "Navigate to example.com" | Playwright MCP |
| SEL-08 | "Fill out the login form" | browser-automation |
| SEL-09 | "Push changes to GitHub" | Bash(git) or skill |
| SEL-10 | "Review this PR thoroughly" | pr-review-toolkit |

### Test Execution

For each test case:

1. **State the test case**: "Testing SEL-XX: [input]"

2. **Declare intent**: State which tool/agent/skill you WOULD select for this input

3. **Compare to expected**: Check against the expected selection

4. **Score**:
   - ✅ Pass (exact match or documented acceptable alternative)
   - ⚠️ Acceptable (alternative that meets the need)
   - ❌ Fail (incorrect selection)

5. **Log the result** to selection-audit.jsonl

### Example Test Output

```
=== Selection Validation Test Run ===
Date: 2026-01-09

SEL-01: "Find package.json files"
  Selected: Glob
  Expected: Glob
  Result: ✅ PASS

SEL-02: "What files handle auth?"
  Selected: Explore subagent
  Expected: Explore subagent
  Result: ✅ PASS

...

=== Summary ===
Passed: 8/10 (80%)
Acceptable: 1/10 (10%)
Failed: 1/10 (10%)
Overall: PASS (90% accuracy)
```

## Report Mode Instructions

When invoked with `--report`, generate a comprehensive validation report:

1. **Read all audit logs**:
   ```bash
   cat .claude/logs/selection-audit.jsonl
   ```

2. **Calculate metrics**:
   - Total selections audited
   - Pass rate by category (file ops, research, browser, etc.)
   - Common failure patterns
   - Trend over time

3. **Generate report** to `.claude/reports/selection-validation-report.md`

## Audit Log Format

Each selection decision should be logged as JSON Lines:

```json
{"timestamp":"2026-01-09T12:00:00Z","input":"Find package.json","selection":"Glob","expected":"Glob","result":"pass","test_id":"SEL-01"}
```

## Scoring Criteria

| Score | Meaning |
|-------|---------|
| 1.0 | Exact expected selection |
| 0.5 | Acceptable alternative |
| 0.0 | Incorrect selection |

**Target**: 80%+ accuracy (8/10 test cases)

## Related Files

- @.claude/context/patterns/selection-validation-tests.md — Full test case documentation
- @.claude/context/patterns/selection-intelligence-guide.md — Selection rules
- @.claude/logs/selection-audit.jsonl — Audit log (created on first audit)

---

*PR-9.4: Selection Validation Command*
