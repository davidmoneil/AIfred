# Self-Corrections Log

**Purpose**: Track corrections Jarvis identifies and applies without user prompting.

**Format**: Each entry documents a self-identified error and its correction.

---

## 2026

### February

### 2026-02-08 — Hook Matcher Regex Substring Matching

**What I Did Wrong**: Used bare `"Write"` as hook matcher regex, which matched `"TodoWrite"` as a substring — causing write-related hooks to fire unnecessarily on TodoWrite tool calls.

**How I Noticed**: During post-implementation review of hook matcher optimization, realized that regex `Write` would match anywhere in the tool name string.

**Correction Applied**: Anchored all matchers with `^` and `$` where needed: `^Write$|^Edit$` instead of `Write|Edit`. For prefix matches (like `^Bash` matching `Bash` but not `FlashBash`), used `^` anchor without `$`.

**Prevention**: Hook matchers are regex — always anchor with `^` for tool name matching. Use `$` for exact matches, omit `$` only for intentional prefix matching.

**Related**: `.claude/settings.json` hook configuration, MEMORY.md

---

### 2026-02-08 — AC-03 State File Drift from Spec

**What I Did Wrong**: Never updated the AC-03 state JSON (`AC-03-review.json`) after successfully testing the milestone review on PR-12.4 (2026-02-06). State showed `triggers_tested: false` while the spec checklist correctly showed `triggers_tested: true`.

**How I Noticed**: During Phase 6 readiness assessment, compared state files against spec files and found contradictions.

**Correction Applied**: Synced AC-03 state file with spec evidence. Status: `implementing` → `active`, version: `1.0.0` → `1.2.0`, all tested fields updated.

**Prevention**: State files should be updated at the same time as spec validation checklists. Consider adding a post-review hook that prompts for state file update.

**Related**: AC-03 Milestone Review, `.claude/state/components/AC-03-review.json`

---

### 2026-02-06 — tmux send-keys Multi-Line String Corruption

**What I Did Wrong**: Used multi-line strings with `tmux send-keys -l`, which injected literal newlines into the TUI input buffer, causing partial command submission.

**How I Noticed**: `/clear` command was sitting in the input buffer with embedded newlines instead of executing.

**Correction Applied**: All `-l` strings must be single-line. Canonical pattern: `send-keys -l 'single line'` + `sleep 0.1` + `send-keys C-m`.

**Prevention**: Never use multi-line strings with tmux `-l` flag. Condense to single-line with em dashes or semicolons.

**Related**: jarvis-watcher.sh v5.6.1, MEMORY.md

---

### 2026-02-06 — tmux Command Delivery During Active Generation

**What I Did Wrong**: Sent commands via `tmux send-keys` while Claude Code was actively generating a response — commands were lost.

**How I Noticed**: Watcher-sent `/clear` and `/compact` commands disappeared without effect.

**Correction Applied**: Added `wait_for_idle_brief(30)` — polls `is_claude_busy()` every 2s, max 30s wait before sending.

**Prevention**: Always check if TUI is idle before injecting commands via tmux.

**Related**: jarvis-watcher.sh v5.6.1, MEMORY.md

---

### 2026-02-05 — Claude Code Lockout Ceiling at 78.5%

**What I Did Wrong**: Set JICM threshold at 80%, above Claude Code's internal lockout ceiling where it refuses ALL operations including /compact.

**How I Noticed**: "Context limit reached" at ~79%, `/compact` failed with "Conversation too long".

**Correction Applied**: Lockout% = (200K - 15K - 28K) / 200K = 78.5%. All thresholds set below this: JICM at 55%, emergency at 73%.

**Prevention**: Calculate lockout ceiling first: `1 - (output_reserve + compact_buffer) / context_window`.

**Related**: jarvis-watcher.sh v5.5.0, MEMORY.md

---

### 2026-02-05 — TUI Token Extraction Pane Buffer Bug

**What I Did Wrong**: Searched entire tmux pane buffer (including scroll history) for token count patterns, matching stale output from old commands.

**How I Noticed**: Log showed "Data inconsistency detected: 181417 tokens at 2%" — old token count from bash output, not current statusline.

**Correction Applied**: Restrict search to last 3 lines of pane (`tail -3` before grep) to capture only the statusline area.

**Prevention**: When parsing TUI content, always restrict to relevant area before pattern matching.

**Related**: jarvis-watcher.sh v5.4.3, MEMORY.md

---

### 2026-02-05 — Bash 3.2 `set -e` Exit on Command Substitution

**What I Did Wrong**: `detect_critical_state()` returned non-zero, causing `set -e` to kill the script when called via `result=$(detect_critical_state)`.

**How I Noticed**: Watcher crashed after first iteration with no error message.

**Correction Applied**: All functions called via `$(...)` must always `return 0`. Use output string to indicate status.

**Prevention**: In bash 3.2 (macOS default), command substitution triggers `set -e` on non-zero return. Always return 0 from functions used in `$(...)`.

**Related**: jarvis-watcher.sh v5.3.2, MEMORY.md

---

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
