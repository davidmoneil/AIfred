# Project Reporting Pattern

**Version**: 1.0.0
**Created**: 2026-01-18
**Source**: Validated in Demo A (Aion Hello Console)

---

## Purpose

Standardizes project completion reporting to ensure consistent, insightful documentation of:
- Summary metrics and deliverables
- System utilization and performance assessment
- Findings and issues encountered
- Lessons learned and recommendations

This pattern ensures every completed project generates actionable insights for continuous improvement.

---

## When to Apply

Apply this pattern when:
- Completing any project work (features, fixes, research)
- Finishing autonomous benchmark tasks
- Closing PRs or milestones
- Ending significant implementation phases

**Minimum threshold**: Projects with 3+ phases or 2+ hours of work.

---

## Report Structure

### 1. Run Report

The **Run Report** documents execution details for the specific project run.

**Required Sections**:

```markdown
# [Project Name] Run Report

**Execution Date**: YYYY-MM-DD
**Execution ID**: [unique-identifier]
**Status**: [COMPLETE | PARTIAL | BLOCKED]

---

## Executive Summary
[1-3 sentences describing what was accomplished]

---

## Execution Details

| Metric | Value |
|--------|-------|
| **Start Time** | [timestamp] |
| **End Time** | [timestamp] |
| **Duration** | [time] |
| **Technology Stack** | [tech choices] |
| **Repository** | [path or URL] |
| **Delivery Status** | [status] |

---

## Deliverables

### Artifacts Created
[List of files, directories, commits, tags]

### Test Results
| Test Type | Count | Passed | Failed |
|-----------|-------|--------|--------|
| Unit Tests | N | N | 0 |
| Integration Tests | N | N | 0 |
| E2E Tests | N | N | 0 |
| **Total** | **N** | **N** | **0** |

---

## Requirements Checklist

### [Category 1]
| Requirement | Status |
|-------------|--------|
| [requirement] | ✅ Pass / ⚠️ Partial / ❌ Fail |

### [Category 2]
...

---

## Issues Encountered

### [Issue Title]
**Issue**: [description]
**Root Cause**: [analysis]
**Impact**: [what was affected]
**Resolution**: [how resolved or workaround]

---

## Recommendations
1. [recommendation with rationale]
2. [recommendation with rationale]

---

*Run Report Generated: [date]*
```

---

### 2. Performance Analysis Report

The **Performance Analysis Report** assesses how well the system (Jarvis/autonomic) performed.

**Required Sections**:

```markdown
# [Project Name] Performance Analysis

**Analysis Date**: YYYY-MM-DD
**Benchmark**: [project name]
**Purpose**: [why this analysis matters]

---

## Executive Summary
[Key findings in 2-3 sentences]

---

## System Utilization Assessment

### Autonomic System Alignment

| System | Design Expectation | Actual Behavior | Alignment |
|--------|-------------------|-----------------|-----------|
| AC-01 Self-Launch | [expected] | [actual] | [%] |
| AC-02 Wiggum Loop | [expected] | [actual] | [%] |
| ... | ... | ... | ... |

### Iteration Statistics
| Metric | Value |
|--------|-------|
| Total Wiggum Loop Iterations | N |
| Self-Reviews Performed | N |
| Corrections Made | N |
| Context Checkpoints | N |

---

## Key Findings

### What Worked Well
1. [finding with evidence]
2. [finding with evidence]

### Areas for Improvement
1. [finding with recommendation]
2. [finding with recommendation]

---

## Comparison: Design vs Reality

| Design Element | Implementation Reality | Gap Analysis |
|----------------|----------------------|--------------|
| [element] | [actual] | [gap if any] |

---

## Recommendations

### Immediate
1. [action item]

### Future
1. [consideration]

---

## Conclusion
[Summary assessment and overall score if applicable]

---

*Performance Analysis Report — [date]*
```

---

## Metrics to Always Capture

### Execution Metrics
| Metric | Description | How to Capture |
|--------|-------------|----------------|
| Duration | Total execution time | Start/end timestamps |
| Phase Count | Number of distinct phases | TodoWrite entries |
| Iteration Count | Wiggum Loop passes | Count verification cycles |
| Test Pass Rate | Tests passed / total | Test suite results |
| Requirements Met | Requirements met / total | PRD checklist |

### Quality Metrics
| Metric | Description | Target |
|--------|-------------|--------|
| First-Pass Success | Work accepted without revision | >80% |
| Self-Correction Rate | Errors caught before user | Track in loop |
| Blocker Resolution | Blockers investigated vs stopped | 100% investigated |

### System Metrics
| Metric | Description | Source |
|--------|-------------|--------|
| Autonomic Alignment | Match to Phase 6 design | Manual assessment |
| Context Efficiency | Tokens used vs available | JICM tracking |
| Tool Selection Accuracy | Right tool first try | Selection audit |

---

## Report Location Convention

Store reports in consistent locations:

```
projects/[project-name]/reports/
├── [project]-run-report-YYYY-MM-DD.md
├── [project]-performance-analysis-YYYY-MM-DD.md
└── [project]-lessons-learned-YYYY-MM-DD.md  (optional)
```

For Jarvis internal projects:
```
projects/project-aion/reports/
├── demo-a-run-report-2026-01-18.md
├── demo-a-autonomic-analysis-2026-01-18.md
```

---

## Quick Reference Checklist

Before marking a project complete, verify:

### Run Report
- [ ] Executive summary written
- [ ] All deliverables listed
- [ ] Test results documented
- [ ] Requirements checklist completed
- [ ] Issues documented with root cause
- [ ] Recommendations provided

### Performance Analysis
- [ ] System utilization assessed
- [ ] Iteration metrics captured
- [ ] What worked well documented
- [ ] Improvement areas identified
- [ ] Design vs reality comparison
- [ ] Conclusion written

### Metadata
- [ ] Reports saved to correct location
- [ ] Session state updated
- [ ] Memory MCP entities created (if significant findings)

---

## Integration with Other Patterns

### AC-02 Wiggum Loop
- Report generation is final Wiggum Loop step
- Don't mark complete until reports generated

### AC-03 Milestone Review
- Reports serve as Level 2 (Progress) review evidence
- Include report links in review documentation

### AC-05 Self-Reflection
- Performance analysis feeds reflection cycles
- Improvement areas become evolution candidates

### AC-09 Session Completion
- Generate reports before `/end-session`
- Include report summary in session state

---

## Example: Demo A Reports

### Run Report Highlights
```markdown
| Metric | Value |
|--------|-------|
| Duration | ~15 minutes |
| Test Pass Rate | 100% (32/32) |
| PRD Requirements | 96% (26/27) |
| Wiggum Iterations | 24 |
```

### Performance Analysis Highlights
```markdown
| System | Alignment |
|--------|-----------|
| AC-01 Self-Launch | 100% |
| AC-02 Wiggum Loop | 100% |
| AC-03 Milestone Review | 100% |
| Overall Score | 92% |
```

---

## Automation Opportunities

Future enhancements:
1. Auto-generate report skeleton from TodoWrite history
2. Capture iteration counts via hook instrumentation
3. Pre-fill metrics from test output parsing
4. Create `/project-report` command for guided generation

---

*Project Reporting Pattern — Validated Demo A 2026-01-18*
