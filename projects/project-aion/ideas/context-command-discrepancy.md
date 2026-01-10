# Context Command Discrepancy Investigation

**Created**: 2026-01-09
**Status**: Observation — needs investigation
**Priority**: Medium

---

## Observed Discrepancy

During PR-10 planning session, significant mismatch between context reporting sources:

| Source | Reported | Percentage |
|--------|----------|------------|
| Terminal progress bar | **139k tokens** | ~70% used, 10% until autocompact |
| `/context` command | 26k tokens | 13% |
| JICM heuristic | 31k tokens | 15.6% |

---

## Key Observation

The `/context` command breakdown showed:

```
System prompt:    2.9k  (1.4%)
System tools:    15.2k  (7.6%)
MCP tools:        6.1k  (3.0%)
Custom agents:     130  (0.1%)
Memory files:     1.1k  (0.5%)
Skills:           986   (0.5%)
Free space:      129k  (64.3%)
Autocompact buffer: 45k (22.5%)
```

**Missing**: No "messages" or "conversation" category shown.

---

## User Report

User indicates that `/context` **previously** included a "messages" category in its breakdown, and the total used to match the terminal progress bar display.

This suggests a **recent change** in Claude Code behavior where:
- `/context` no longer reports conversation/message tokens
- Only "static" context (tools, system prompt, etc.) is shown
- Terminal progress bar still shows true total usage

---

## Impact

1. **JICM heuristic** (context-accumulator.js) significantly underestimates true usage
2. **Context budget reports** based on `/context` output are misleading
3. **Autocompact warnings** may come as surprise if relying on `/context` data

---

## Questions to Investigate

1. When did `/context` change to exclude messages?
2. Is this a bug or intentional change in Claude Code?
3. Is there an alternative API/command to get true token usage?
4. Should JICM apply a multiplier to compensate?

---

## Workaround

For now, trust the **terminal progress bar** over `/context` for true usage assessment.

---

*Logged for future investigation — PR-10 session 2026-01-09*
