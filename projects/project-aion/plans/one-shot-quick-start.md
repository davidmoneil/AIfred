# One-Shot PRD v2: Quick Start Guide

**Full Specification**: @projects/project-aion/plans/one-shot-prd-v2.md

---

## Quick Execution

To run this benchmark, simply provide this prompt:

```
Execute the Aion Hello Console benchmark from one-shot-prd-v2.md.

Work entirely autonomously using TDD methodology:
1. Pre-flight verification (including GitHub capability)
2. Write tests first (unit, integration, E2E)
3. Implement to pass tests
4. Validate all 53+ tests pass
5. Document (README, ARCHITECTURE)
6. Deliver to GitHub (CannonCoPilot/aion-hello-console-<date>)
7. Generate run report and analysis report

Track iterations, verify at each phase, investigate any blockers.
```

---

## Expected Outcomes

| Metric | Target |
|--------|--------|
| Duration | 15-30 minutes |
| Unit Tests | 23+ |
| Integration Tests | 9+ |
| E2E Tests | 21+ |
| Pass Rate | 100% |
| GitHub Delivery | Repository + v1.0.0 tag |
| Reports | Run report + Analysis report |

---

## Success Indicators

**Green Flags**:
- Pre-flight verifies GitHub CAPABILITY (not just auth)
- Tests written before implementation
- All tests pass before moving to next phase
- Code review performed
- Both reports generated

**Red Flags**:
- Skipping pre-flight verification
- Implementing before writing tests
- Moving on with failing tests
- No code review
- Missing reports

---

## Quick Validation

After execution, verify:

```bash
# Repository exists
curl -s https://api.github.com/repos/CannonCoPilot/aion-hello-console-<date> | jq .name

# Release tag exists
curl -s https://api.github.com/repos/CannonCoPilot/aion-hello-console-<date>/tags | jq .[0].name

# Reports exist
ls projects/project-aion/reports/aion-hello-console-*

# Test count (from run report)
grep "Total" projects/project-aion/reports/aion-hello-console-run-report-*.md
```

---

## Comparison

Compare results against Demo A baseline (2026-01-18):

| Metric | Demo A | This Run | Delta |
|--------|--------|----------|-------|
| Duration | 30 min | | |
| Total Tests | 53 | | |
| Pass Rate | 100% | | |
| Iterations | 35 | | |
| Issues | 2 | | |

---

## When to Use

Run this benchmark when:
- Testing new Jarvis capabilities
- Validating MCP or plugin changes
- After significant pattern updates
- Training new autonomic behaviors
- Comparing performance over time

---

*Quick Start Guide for One-Shot PRD v2*
