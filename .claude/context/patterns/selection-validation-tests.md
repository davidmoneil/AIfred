# Selection Validation Test Cases

**Version**: 1.0 | **PR Reference**: PR-9.4 | **Created**: 2026-01-09

Documented test cases for validating selection intelligence accuracy.

---

## Test Case Summary

| ID | Category | Input | Expected | Priority |
|----|----------|-------|----------|----------|
| SEL-01 | File Search | Find package.json files | Glob | High |
| SEL-02 | Code Understanding | What files handle auth? | Explore subagent | High |
| SEL-03 | Document Creation | Create a Word document | docx skill | High |
| SEL-04 | Research | Research Docker networking | deep-research agent | High |
| SEL-05 | Quick Lookup | Quick fact: capital of France | WebSearch | Medium |
| SEL-06 | Deep Research | Comprehensive analysis of X | gptresearcher | Medium |
| SEL-07 | Browser | Navigate to example.com | Playwright MCP | Medium |
| SEL-08 | Browser NL | Fill out the login form | browser-automation | Medium |
| SEL-09 | Git Workflow | Push changes to GitHub | engineering-workflow | Low |
| SEL-10 | PR Review | Review this PR thoroughly | pr-review-toolkit | Low |

---

## Detailed Test Cases

### SEL-01: File Pattern Search

**Input**: "Find package.json files"

**Expected Selection**: `Glob` tool

**Rationale**:
- Specific file pattern search → Glob is the optimal built-in
- NOT Explore subagent (overhead not justified for simple pattern)
- NOT Bash find (Glob is preferred per tool selection rules)

**Validation Criteria**:
- ✅ Uses Glob tool directly
- ❌ Uses Explore subagent (over-engineering)
- ❌ Uses Bash find command (anti-pattern)

---

### SEL-02: Code Understanding

**Input**: "What files handle auth?"

**Expected Selection**: `Explore` subagent via Task tool

**Rationale**:
- Open-ended code exploration question
- May require multiple search iterations
- Benefits from context isolation

**Validation Criteria**:
- ✅ Delegates to Explore subagent
- ❌ Runs multiple Grep/Glob directly (context bloat)
- ⚠️ Single targeted Grep acceptable if confident

---

### SEL-03: Document Creation

**Input**: "Create a Word document"

**Expected Selection**: `docx` skill

**Rationale**:
- Document creation triggers skill
- Skill provides proper formatting workflow
- Better than manual Write tool

**Validation Criteria**:
- ✅ Invokes docx skill via Skill tool
- ❌ Writes .docx manually (incorrect format)
- ❌ Creates plain text file

---

### SEL-04: Custom Agent Research

**Input**: "Research Docker networking"

**Expected Selection**: `/agent deep-research` custom agent

**Rationale**:
- "Research" keyword suggests depth
- Custom agent provides structured output
- Results persist in file (cross-session reference)

**Validation Criteria**:
- ✅ Uses deep-research custom agent
- ⚠️ Uses perplexity_research (acceptable for medium depth)
- ❌ Uses WebSearch only (insufficient depth)

---

### SEL-05: Quick Fact Lookup

**Input**: "Quick fact: capital of France"

**Expected Selection**: `WebSearch` (built-in)

**Rationale**:
- Simple factual question
- Built-in WebSearch is sufficient
- No MCP overhead needed

**Validation Criteria**:
- ✅ Uses WebSearch built-in
- ⚠️ Uses perplexity_search (acceptable, slight overhead)
- ❌ Uses gptresearcher (over-engineering)

---

### SEL-06: Comprehensive Research

**Input**: "Comprehensive analysis of microservices vs monolith"

**Expected Selection**: `gptresearcher_deep_research` OR `/agent deep-research`

**Rationale**:
- "Comprehensive analysis" signals deep research
- 16+ sources expected
- Either gptresearcher or custom agent appropriate

**Validation Criteria**:
- ✅ Uses gptresearcher_deep_research
- ✅ Uses deep-research custom agent
- ❌ Uses perplexity_search only (insufficient)
- ❌ Uses WebSearch only (insufficient)

---

### SEL-07: Browser Navigation

**Input**: "Navigate to example.com and take a screenshot"

**Expected Selection**: `Playwright MCP` tools

**Rationale**:
- Programmatic browser task
- Screenshot requires browser automation
- Deterministic operation

**Validation Criteria**:
- ✅ Uses Playwright MCP (browser_navigate, browser_take_screenshot)
- ⚠️ Uses browser-automation plugin (acceptable)
- ❌ Uses WebFetch (cannot screenshot)

---

### SEL-08: Natural Language Browser Task

**Input**: "Fill out the login form with test credentials"

**Expected Selection**: `browser-automation` plugin

**Rationale**:
- Natural language browser instruction
- Form filling benefits from NL interpretation
- browser-automation handles NL → actions

**Validation Criteria**:
- ✅ Uses browser-automation plugin
- ⚠️ Uses Playwright MCP (acceptable, more verbose)
- ❌ Uses WebFetch (cannot interact with forms)

---

### SEL-09: Git Workflow

**Input**: "Push changes to GitHub"

**Expected Selection**: `Bash(git push)` or engineering-workflow skill

**Rationale**:
- Simple git operation
- Bash is sufficient for push
- Skill provides guardrails

**Validation Criteria**:
- ✅ Uses Bash with git push
- ✅ Uses engineering-workflow skill
- ⚠️ Uses Git MCP (acceptable, slight overhead)
- ❌ Refuses (should handle simple git)

---

### SEL-10: PR Review

**Input**: "Review this PR thoroughly"

**Expected Selection**: `pr-review-toolkit` plugin

**Rationale**:
- "Thoroughly" signals comprehensive review
- Plugin provides structured review workflow
- Better than manual review

**Validation Criteria**:
- ✅ Uses pr-review-toolkit plugin
- ⚠️ Manual review with structure (acceptable)
- ❌ Simple "looks good" (insufficient for "thoroughly")

---

## Validation Procedure

### Manual Validation

1. Start fresh Claude Code session
2. For each test case:
   - Input the prompt exactly as specified
   - Record which tool/agent/skill was selected
   - Compare against expected selection
   - Mark as Pass/Fail/Acceptable

### Automated Validation (Future)

Use `/validate-selection` command to run through test cases with audit logging.

---

## Scoring

| Result | Score |
|--------|-------|
| ✅ Expected selection | 1.0 |
| ⚠️ Acceptable alternative | 0.5 |
| ❌ Wrong selection | 0.0 |

**Target Accuracy**: 80%+ (8/10 test cases with ✅ or ⚠️)

---

## Audit Log Format

Selection decisions are logged to `.claude/logs/selection-audit.jsonl`:

```json
{
  "timestamp": "2026-01-09T12:00:00Z",
  "input": "Find package.json files",
  "selection": "Glob",
  "alternatives_considered": ["Explore", "Bash(find)"],
  "rationale": "Specific file pattern search",
  "test_case": "SEL-01",
  "result": "pass"
}
```

---

## Related Documentation

- @selection-intelligence-guide.md — Quick selection reference
- @agent-selection-pattern.md — Agent decision details
- @capability-map.yaml — Tool selection matrix

---

*Selection Validation Test Cases v1.0 — PR-9.4 (2026-01-09)*
