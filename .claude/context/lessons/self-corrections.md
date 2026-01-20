# Self-Corrections Log

**Purpose**: Track corrections Jarvis identifies and applies without user prompting.

**Format**: Each entry documents a self-identified error and its correction.

---

## 2026

### January

### 2026-01-20 — PRD-V5 Self-Improvement Validation (4 Corrections)

**Context**: PRD-V5 AC-05/06 stress test with intentional mistakes planted for validation.

#### Correction 1: Missing Edge Case Test

**What I Did Wrong**: Did not include empty string test for slugify function in unit tests.

**How I Noticed**: Self-review of test file revealed comment indicating missing edge case.

**Correction Applied**: Added test case:
```javascript
it('handles empty string', () => {
  expect(slugify('')).toBe('');
});
```

**Prevention**: Systematically test all edge cases: empty string, null, undefined, single char, special chars.

#### Correction 2: Inefficient Algorithm

**What I Did Wrong**: Implemented O(n) space complexity wordCount with unnecessary double-split.

**How I Noticed**: Code review during self-reflection identified redundant operations.

**Correction Applied**: Simplified to single-pass implementation:
```javascript
export function wordCount(text) {
  if (!text || !text.trim()) return 0;
  return text.trim().split(/\s+/).length;
}
```

**Prevention**: Review algorithmic complexity during implementation. Avoid chained operations that create intermediate structures.

#### Correction 3: Wrong Error Message

**What I Did Wrong**: API returned "Invalid input" instead of "Unknown operation" for invalid operation parameter.

**How I Noticed**: Integration test failure - expected error message to contain "operation".

**Correction Applied**: Fixed error message:
```javascript
return res.status(400).json({
  error: `Unknown operation: ${operation}. Valid: ${Object.keys(transformFunctions).join(', ')}`
});
```

**Prevention**: Error messages should be specific about what failed, not generic.

#### Correction 4: Incomplete Documentation

**What I Did Wrong**: README missing response format examples and error codes.

**How I Noticed**: Documentation review revealed incomplete API documentation.

**Correction Applied**: Added complete API documentation with request/response examples and error codes.

**Prevention**: Documentation checklist: endpoints, parameters, response formats, error codes, examples.

**Related**: PRD-V5, AC-05 Self-Reflection, AC-06 Self-Evolution

---

### 2026-01-18 — Weather API Header Requirements

**What I Did Wrong**: Initial wttr.in weather integration used HTTP without User-Agent header, causing JSON endpoint to return null.

**How I Noticed**: Weather fetch test returned null; curl debugging revealed the JSON endpoint requires HTTPS and curl-like User-Agent.

**Correction Applied**: Updated startup-greeting.js to use HTTPS with proper headers:
```javascript
headers: {
  'User-Agent': 'curl/7.79.1',
  'Accept': 'application/json'
}
```

**Prevention**: When integrating external APIs, always test with curl first to establish baseline behavior, then mirror those headers in programmatic requests.

**Related**: `evo-2026-01-017`, `.claude/scripts/startup-greeting.js`

---

### 2026-01-17 — Empty Array Iteration Bug in plugin-decompose.sh

**What I Did Wrong**: In the --scan-redundancy feature of plugin-decompose.sh, iterated over `${plugin_functions[@]}` without checking if the array was empty first, causing "unbound variable" errors.

**How I Noticed**: During blind development (Phase 3 of RLE-001), the --scan-redundancy test failed with a bash error when the plugin had no functions to compare.

**Correction Applied**: Added array length check before iteration:
```bash
if [[ ${#plugin_functions[@]} -gt 0 ]]; then
    for func in "${plugin_functions[@]}"; do
        # ... iteration code
    done
else
    print_info "No functions to compare"
fi
```

**Prevention**: Always check array length before iterating in bash scripts, especially when array contents are dynamically generated.

**Related**: `projects/project-aion/reports/ralph-loop-experiment/RESEARCH-REPORT.md`

---

## Template

```markdown
### [Date] — [Brief Description]

**What I Did Wrong**: [Describe the initial error]

**How I Noticed**: [What triggered the recognition]

**Correction Applied**: [What I changed]

**Prevention**: [How to avoid this in future]

**Related**: [Link to lesson/pattern if applicable]
```

---

*Self-corrections feed into AC-05 Self-Reflection for pattern analysis.*
