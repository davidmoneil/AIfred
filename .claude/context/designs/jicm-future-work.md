# JICM & Watcher Future Work

**Created**: 2026-02-06
**Baseline**: JICM v5.6.2 (commit `22c8778`)
**Status**: Active planning document

---

## 1. Critical Fixes (Do Before Returning to Other Work)

These are issues discovered during the v5.6.2 critical analysis that should be resolved first.

### 1.1 CRIT-01: `check_idle_hands()` crash on unknown mode

**Effort**: 1 line
**Risk**: Low (safe change)
**Description**: The `*` fallback case in `check_idle_hands()` returns 1, which under `set -e` kills the watcher when called outside a conditional. Change to `return 0`.

### 1.2 CRIT-03: Launcher AUTOCOMPACT override too high

**Effort**: 1 line
**Risk**: Low
**Description**: `launch-jarvis-tmux.sh` sets `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE=95`, which is above the 78.5% lockout ceiling. Change to 70 to match `claude-code-env.sh`.

### 1.3 CRIT-04: `.compression-in-progress` not cleaned on startup

**Effort**: 2 lines
**Risk**: Low
**Description**: Add `rm -f` for `.compression-in-progress` in `session-start.sh`'s startup/clear cleanup block alongside the existing `.compaction-in-progress` cleanup.

### 1.4 HIGH-05: Emergency compact fires during active compression

**Effort**: 1 condition
**Risk**: Low
**Description**: Add `JICM_STATE != "compression_triggered"` to the emergency compact guard at line 1594.

---

## 2. Near-Term Improvements (Next 1-2 Sessions)

### 2.1 Atomic signal file writes

**Effort**: Small refactor (~20 lines)
**Description**: Replace `echo "$timestamp" > "$signal_file"` with `echo "$timestamp" > "${signal_file}.tmp" && mv "${signal_file}.tmp" "$signal_file"`. Prevents partial-read race conditions that can cause duplicate `/clear` (CRIT-02).

### 2.2 Non-blocking idle-hands

**Effort**: Medium refactor (~80 lines)
**Description**: Refactor `idle_hands_jicm_resume()` and `idle_hands_session_start()` from blocking inner loops (4-5 min) to state-machine checks (one attempt per main-loop iteration). This eliminates the monitoring blind spot during idle-hands protocols. Design approach:
- Add `IDLE_HANDS_STATE` variable (idle, attempting, succeeded, failed)
- Add `IDLE_HANDS_CYCLE` counter
- Check and advance one step per main-loop iteration
- Main loop continues monitoring between attempts

### 2.3 tmux session loss detection

**Effort**: Small (~10 lines)
**Description**: If tmux session is not found for N consecutive checks (e.g., 5), log a clear error and exit instead of looping forever with "Waiting for context data..." Add a heartbeat-style "session alive" check.

### 2.4 Standdown auto-recovery

**Effort**: Small (~5 lines)
**Description**: On fresh watcher startup, check for and delete `.jicm-standdown` file. The watcher should start clean.

---

## 3. Infrastructure Cleanup (Documentation Debt Session)

### 3.1 Archive stale agents and hooks

| File | Action |
|------|--------|
| `context-compressor.md` | Move to `.claude/agents/archive/` |
| `context-accumulator.js` | Move to `.claude/hooks/archive/` |

### 3.2 Remove dead signal file references

| Signal File | Referenced By | Action |
|-------------|---------------|--------|
| `.dump-requested.signal` | watcher cleanup | Remove from cleanup functions |
| `.jicm-agent-spawn-signal` | session-start.sh | Remove creation code (lines 186-206) |
| `.continuation-verified.signal` | autonomy-config.yaml | Remove from config |
| `.clear-pending` | stop-auto-clear.sh, session-start.sh | Update or remove hook |
| `.auto-clear-signal` | stop-auto-clear.sh | Update or remove hook |

### 3.3 Remove legacy code paths

| Location | Lines | Description |
|----------|-------|-------------|
| `session-start.sh` | 514-574 | v2 legacy compression handler |
| `session-start.sh` | 186-206 | JICM agent spawn signal (Solution C, unused) |
| `autonomy-config.yaml` | 135-152 | v4 executor layer references |

### 3.4 Update or retire `stop-auto-clear.sh`

The hook checks v2/v3 signal files. Either update to check v5 signals (`.clear-sent.signal`) or remove entirely since the watcher now manages `/clear` coordination.

### 3.5 Remove `.in-progress-ready.md` references

No component creates this file. Remove references from:
- `session-start.sh` (lines 415, 434-436)
- Watcher resume prompts
- `send_prompt_by_type()` RESUME prompt

---

## 4. Documentation Updates Required

### 4.1 CRITICAL: AC-04-jicm.md rewrite (v3 -> v5.6.2)

The component spec is 3 major versions behind. Needs full rewrite covering:
- Single-threshold architecture (65% trigger, 73% emergency, 78.5% lockout)
- Two-mechanism resume (hook injection + idle-hands monitor)
- Event-driven state machine (monitoring <-> compression_triggered <-> cleared)
- Signal file lifecycle
- Bash 3.2 compatibility requirements

### 4.2 HIGH: automated-context-management.md update (v3 -> v5.6.2)

Pattern document references 80% threshold, v3 watcher, and MCP tier system. Needs update to reflect v5 architecture, signal files, and idle-hands system.

### 4.3 MEDIUM: jicm-v5-design-addendum.md additions

Add:
- Emergency threshold (73%) and lockout ceiling (78.5%) in Section 2.2
- Concrete environment variable values in Appendix A
- Mark jicm_resume mode as "IMPLEMENTED" (not future)

### 4.4 MEDIUM: jicm-v5-implementation-plan.md status update

Mark testing as complete (2026-02-06). Add v5.6.1/v5.6.2 fixes to known issues section.

### 4.5 LOW: jicm-v6-enhancements.md baseline update

Note v5.6.2 baseline. Mark items already implemented (haiku model, critical state detection).

---

## 5. Architecture Considerations for v6+

### 5.1 Event-driven idle-hands (from HIGH-03/04)

The current blocking inner loops are the biggest architectural weakness. A v6 design should treat idle-hands as a state within the main loop, not a sub-loop. This aligns with the existing state machine pattern.

### 5.2 Robust token extraction

Current regex-based extraction (HIGH-06, MED-05) is fragile. Options:
- **Preferred**: Parse the statusline JSON directly if Claude Code exposes it via a known file path
- **Alternative**: Tighter regex anchoring (require specific statusline formatting context)
- **Fallback**: Multiple extraction methods with voting (already partially implemented)

### 5.3 Watchdog for the watcher

The watcher itself can crash (CRIT-01) or enter standdown (MED-08) with no notification. Consider:
- A lightweight cron job that checks `.watcher-pid` and `.watcher-status`
- Sends a notification (system notification, tmux alert) if watcher is dead or in standdown

### 5.4 Compression agent timeout enforcement

The watcher waits 300 seconds for `.compression-done.signal`. But the compression agent has no enforced timeout -- it runs until done or Claude's internal timeout kills it. Consider adding a signal file with a timestamp so the watcher can track elapsed compression time and take action earlier.

---

## 6. Lessons Learned from the v5.6.x Sprint

### 6.1 Bash 3.2 is a minefield with `set -e`

**Lesson**: Any function that might return non-zero and is called via `$()` or outside a conditional will kill the script. We found and fixed this pattern 3 times (detect_critical_state, is_claude_busy, check_idle_hands). There may be more.
**Mitigation**: Establish a convention that ALL functions return 0. Use output strings for status. Run a sweep for any remaining `return 1` statements.

### 6.2 tmux send-keys is inherently racy

**Lesson**: There is no atomic "type and submit" operation. Between `send-keys -l "text"` and `send-keys C-m`, the state can change. Between the idle check and the send, the state can change. This is fundamental to the architecture.
**Mitigation**: `wait_for_idle_brief()` helps but doesn't eliminate the race. Accept this as a known limitation and design around it (idempotent commands, dedup checks).

### 6.3 Multi-line `-l` strings corrupt terminal input

**Lesson**: `tmux send-keys -l` with embedded newlines injects literal newlines into the input buffer. Claude Code's TUI treats each newline as Enter, causing premature submission.
**Mitigation**: ALL `-l` strings must be single-line. This is documented but should be enforced with a lint check in CI.

### 6.4 The lockout ceiling is invisible

**Lesson**: Claude Code's internal lockout at ~78.5% is not documented in Claude Code's public docs. We discovered it empirically when `/compact` started failing. Any threshold-based system must account for this ceiling.
**Mitigation**: Documented in MEMORY.md and this document. All thresholds now have 5%+ headroom below lockout.

### 6.5 Signal file lifecycle is complex and error-prone

**Lesson**: With 19 signal files across 5+ components, tracking creation/deletion/persistence becomes a coordination problem. Stale files from crashes cause unexpected behavior in subsequent sessions.
**Mitigation**: Startup cleanup should be comprehensive. Consider a single "signal file directory" with a cleanup-all-on-startup policy, rather than scattered individual cleanups.

---

*Document maintained as part of JICM v5.6.2+ planning*
