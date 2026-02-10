# EVO-2026-02-010: Watcher Startup Recovery + Emergency Interrupt

**Priority**: HIGH
**Component**: AC-04 (JICM) / jarvis-watcher.sh
**Filed**: 2026-02-10
**Status**: PROPOSED
**Origin**: Live failure observed — watcher entered standdown with valid checkpoint on disk, never triggered /clear

---

## Problem Statement

Two gaps in the JICM watcher v5.8.3 cause context management failures:

### Gap 1: No Startup Recovery Check

When the watcher starts (or restarts), it initializes in `monitoring` state. Section 1.5 (compression completion → /clear) only executes when state is `compression_triggered`. This means:

- If a prior compression cycle completed successfully (signal file + checkpoint exist), but the watcher was in standdown or restarted, the completed compression is **never consumed**.
- The valid checkpoint sits on disk while the watcher re-triggers compression from scratch.
- Observed: compression agent completed after 167s, wrote `.compression-done.signal`, but watcher had already hit 300s failsafe → standdown. On restart, signal file was ignored because state was `monitoring`, not `compression_triggered`.

**Fix**: Add a startup recovery check (Section 0.5 or early in the main loop):

```
On startup / first poll cycle:
  IF .compression-done.signal EXISTS
  AND .compressed-context-ready.md EXISTS
  AND .in-progress-ready.md EXISTS
  THEN:
    Log "Recovery: found completed compression from prior cycle"
    Skip directly to /clear flow (Section 1.5 logic)
    Clean up signal files after /clear
```

All three files should be present to confirm the checkpoint is complete and ready:
- `.compression-done.signal` — proves compression agent finished
- `.compressed-context-ready.md` — the compressed context checkpoint
- `.in-progress-ready.md` — Jarvis's own work-state dump (highest signal for resume)

### Gap 2: No Emergency ESC Interrupt at Critical Context Levels

If JICM compression fails entirely (standdown, agent crash, rate limit) and context continues growing past the lockout ceiling (~78.5%), there is no last-resort mechanism to forcibly reclaim context. The native Claude Code auto-compact eventually triggers, but this is uncontrolled and doesn't use Jarvis's structured checkpoint system.

**Proposed mechanism**: Monitor the Claude Code statusline for the critical warning:

```
"Context low (5% remaining) · Run /compact to compact & continue"
```

When this string appears in the statusline (detectable via the same TUI polling the watcher already does), the watcher should:

1. Send ESC key via tmux to interrupt any in-progress operation:
   ```bash
   tmux send-keys -t jarvis:0 Escape
   sleep 0.5
   ```
2. Immediately send `/compact` to trigger the native compaction:
   ```bash
   tmux send-keys -t jarvis:0 "/compact" Enter
   ```

This is a **last-resort circuit breaker** — it fires only when:
- Context is at ~95% (5% remaining per statusline)
- JICM has already failed or is in standdown
- Native auto-compact hasn't triggered yet

The ESC interrupt is safe because:
- It only cancels the current generation (not destructive)
- /compact is a built-in Claude Code command (always available)
- The watcher already has tmux send-keys capability
- This prevents the worst case: context exhaustion causing session death

**Implementation notes**:
- The statusline polling already exists in the watcher (token count extraction)
- Add a string match for "Context low" or "5% remaining" in the statusline content
- This should fire ONCE per session (add a flag to prevent loops)
- Should NOT fire if watcher is already handling a compression cycle normally
- Consider a threshold configurable via `.jicm-config` (e.g., `emergency_interrupt_pct: 95`)

---

## Affected Files

- `.claude/scripts/jarvis-watcher.sh` — main implementation
- `.claude/context/designs/jicm-v5-design-addendum.md` — design documentation
- `.claude/test/benchmarks/benchmark-suite.yaml` — add recovery benchmark

## Dependencies

- None — can be implemented independently

## Risk Assessment

| Risk | Severity | Mitigation |
|------|----------|------------|
| ESC interrupt during destructive operation | LOW | ESC only cancels generation, not file ops |
| Recovery check consumes stale checkpoint | MEDIUM | Validate signal timestamp (< 1 hour old) |
| Interrupt loop (ESC + /compact repeating) | MEDIUM | One-shot flag per session |

## Priority Justification

This failure mode was observed in production: the watcher entered standdown with a valid checkpoint on disk, context climbed to 85%, and no recovery path existed. The user had to manually diagnose and clear state files. This should be fully autonomous.

---

*Filed by Jarvis — EVO-2026-02-010*
