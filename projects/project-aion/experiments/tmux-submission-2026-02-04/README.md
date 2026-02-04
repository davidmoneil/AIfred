# tmux Submission Methods Experiment

**Date**: 2026-02-04
**Status**: Complete
**Classification**: JICM v5 Infrastructure Research

## Purpose

Determine which tmux `send-keys` patterns successfully submit prompts to Claude Code's Ink-based TUI.

## Key Finding

**CR/Enter must be sent as a separate tmux command**, not embedded in the same `-l` (literal) string as the prompt text.

```bash
# ✅ CORRECT
send-keys -l "text"
send-keys C-m

# ❌ WRONG
send-keys -l "text"$'\r'
```

## Contents

| File | Description |
|------|-------------|
| `experiment-report.md` | Full experiment report with methodology and analysis |
| `test-submission-methods.sh` | Phase 1 script - tests 7 submission methods |
| `test-submission-hypothesis.sh` | Phase 2 script - tests 6 hypotheses |
| `adhoc-hypothesis-test.sh` | Self-injection test (demonstrates failure) |
| `jicm-submission-test-results.txt` | Phase 1 results data |

## Impact

This research validated the jarvis-watcher.sh architecture and informed updates to:
- JICM v5 design documents
- Idle-hands retry strategy
- Lesson documentation (PAT-005)

---

*Archived from `.claude/scripts/` for methodology preservation*
