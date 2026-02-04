# Experiment Report: tmux Submission Methods for Claude Code TUI

**Date**: 2026-02-04
**Experimenters**: Jarvis (Claude Opus 4.5) + Human Operator
**Purpose**: Determine which tmux send-keys patterns successfully submit prompts to Claude Code's Ink-based TUI
**Context**: JICM v5 implementation requires reliable keystroke injection for post-/clear resume

---

## Executive Summary

We conducted systematic testing of tmux `send-keys` submission methods to understand why some patterns work while others fail. The key finding is that **CR/Enter must be sent as a separate tmux command, not embedded in the same `-l` (literal) string as the prompt text**.

### Key Findings

1. **Working Methods**: `C-m`, `Enter`, `-l $'\r'` (as separate call)
2. **Failed Methods**: `-l $'\n'`, `-l $'\r\n'`, `Escape C-m`, `C-m C-m`
3. **Critical Discovery**: Embedding CR in text string causes failure
4. **External Execution Requirement**: Self-injection from within Claude Code fails

---

## Background

### Problem Statement

Claude Code uses **Ink** (React for CLIs), which puts stdin in **raw mode**. This changes how input is processed:
- Normal shell: Enter = submit line
- Ink raw mode: Enter = keypress event that app must interpret

The JICM (Jarvis Intelligent Context Management) system needs to inject prompts into Claude Code via tmux `send-keys` to resume work after context compression/clear cycles.

### Prior Art

Initial testing on 2026-02-03 identified that some methods work while others don't, but didn't explain why.

---

## Phase 1: Initial Method Testing (2026-02-03)

### Methodology

Test script (`test-submission-methods.sh`) sends test text followed by each submission method, then asks operator to verify if prompt was submitted.

### Methods Tested

| # | Method | tmux Command | Result |
|---|--------|--------------|--------|
| 1 | Standard C-m | `send-keys C-m` | ✅ SUCCESS |
| 2 | Literal CR | `send-keys -l $'\r'` | ✅ SUCCESS |
| 3 | Literal LF | `send-keys -l $'\n'` | ❌ FAILED |
| 4 | Literal CRLF | `send-keys -l $'\r\n'` | ❌ FAILED |
| 5 | Enter key | `send-keys Enter` | ✅ SUCCESS |
| 6 | Escape + C-m | `send-keys Escape C-m` | ❌ FAILED |
| 7 | Double C-m | `send-keys C-m C-m` | ❌ FAILED |

### Observations

- CR-based methods work: C-m, literal CR, Enter
- LF-based methods fail: literal LF, CRLF
- Multi-step methods fail: Escape+Enter, Double Enter
- Ad hoc Bash script (run from within Claude Code) FAILED
- Test script (run from external terminal) SUCCEEDED

### Hypothesis Generated

The difference between ad hoc script failure and test script success might be in:
1. How text and CR are combined (single vs separate calls)
2. Timing between text send and submit send
3. Execution context (internal vs external)

---

## Phase 2: Hypothesis Testing (2026-02-04)

### Methodology

Created `test-submission-hypothesis.sh` to test specific hypotheses about why patterns succeed or fail.

### Hypotheses

| ID | Hypothesis | Pattern | tmux Command |
|----|------------|---------|--------------|
| A | Separate calls with sleep | text → sleep 0.2s → C-m | `send-keys -l "text"` + `sleep 0.2` + `send-keys C-m` |
| B | Combined literal | text + CR in single `-l` | `send-keys -l "text"$'\r'` |
| C | Combined args | text + immediate C-m | `send-keys -l "text"` + `send-keys C-m` (no sleep) |
| D | Variable with CR | `-l "$VAR"` where VAR has `\r` | `TEXT="text"$'\r'; send-keys -l "$TEXT"` |
| E | No sleep | text → C-m (immediate) | `send-keys -l "text"` + `send-keys C-m` |
| F | Enter key name | Use Enter instead of C-m | `send-keys -l "text"` + `send-keys Enter` |

### Results

| Hypothesis | Result | Analysis |
|------------|--------|----------|
| A | ✅ WORKS | Separate calls pattern confirmed |
| B | ❌ FAILS | Embedded CR treated as literal character |
| C | ✅ WORKS | Immediate submit works (no sleep needed) |
| D | ❌ FAILS | Variable embedding doesn't help |
| E | ✅ WORKS | Confirms sleep is unnecessary |
| F | ✅ WORKS | Enter key name equivalent to C-m |

### Root Cause Identified

**The `-l` flag makes everything literal**

When you use `send-keys -l "text"$'\r'`, tmux treats the entire string as literal text to be typed. The CR byte (`\r`) is sent as a character, not as a key event. Claude Code's Ink TUI sees it as "part of the text" rather than "submit signal."

The submit trigger MUST be a **key event** (`C-m` or `Enter`), sent as a **separate send-keys call**.

---

## Phase 3: Self-Injection Testing (2026-02-04)

### Methodology

Attempted to run ad hoc submission script from within Claude Code's Bash tool.

### Result

**FAILED** with exit code 137 (SIGKILL/interrupt) and multiple `UserPromptSubmit` hook events fired unexpectedly.

### Root Cause

When Claude Code executes a Bash command that sends `tmux send-keys` to its own session:

1. **Input State Collision**: Ink TUI is in "busy" state processing Bash command
2. **Event Loop Interference**: Keystrokes queue while event loop is blocked
3. **Timing Race Conditions**: Script-side sleeps don't affect tmux event delivery

### Implication

**Prompt injection ONLY works from external processes**

| Context | Result |
|---------|--------|
| External terminal → Claude Code | ✅ Works |
| jarvis-watcher.sh (background) → Claude Code | ✅ Works |
| Bash tool in Claude Code → Same session | ❌ Fails |

---

## Conclusions

### Canonical Submission Pattern

```bash
# ✅ CORRECT: Separate calls, key event for submit
"$TMUX_BIN" send-keys -t "$TMUX_TARGET" -l "prompt text"
"$TMUX_BIN" send-keys -t "$TMUX_TARGET" C-m   # or Enter

# ❌ WRONG: CR embedded in literal
"$TMUX_BIN" send-keys -t "$TMUX_TARGET" -l "prompt text"$'\r'
```

### Design Implications for JICM

1. **jarvis-watcher.sh architecture validated**: External daemon pattern is correct
2. **idle-hands retry strategy updated**: Only use working methods (C-m, Enter, standalone CR)
3. **Self-injection impossible**: No workaround for in-session submission; must use external processes

### Optional Parameters

- **Sleep between text and submit**: OPTIONAL (both with and without work)
- **Submission method**: C-m preferred, Enter and `-l $'\r'` as fallbacks

---

## Artifacts

### Test Scripts (Methodology)

| File | Purpose |
|------|---------|
| `test-submission-methods.sh` | Initial 7-method testing |
| `test-submission-hypothesis.sh` | 6-hypothesis deep dive |
| `adhoc-hypothesis-test.sh` | Self-injection test (demonstrates failure) |

### Results Files

| File | Purpose |
|------|---------|
| `/tmp/jicm-submission-test-results.txt` | Phase 1 results |
| `/tmp/jicm-hypothesis-test-results.txt` | Phase 2 results |

### Documentation Updated

| Document | Changes |
|----------|---------|
| `jicm-v5-design-addendum.md` | Added Section 10 (External Execution Requirement) |
| `jicm-v5-resume-mechanisms.md` | Updated submission method matrix and patterns |
| `lessons/tmux-self-injection-limitation.md` | Full lesson created |
| `patterns/command-signal-protocol.md` | Added Critical Constraint section |
| `lessons/index.md` | Added PAT-005 |

---

## Future Work

1. **Test with different terminal emulators**: Verify findings hold across iTerm2, Terminal.app, Alacritty
2. **Investigate pexpect/expect**: Alternative to tmux send-keys if needed
3. **Claude Code input API**: Check if future versions expose an input API

---

*Experiment completed: 2026-02-04*
*Classification: JICM v5 Infrastructure Research*
