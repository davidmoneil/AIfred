# JICM v5.6.2 Critical Analysis Report

**Date**: 2026-02-06
**Scope**: jarvis-watcher.sh v5.6.2, session-start.sh, launch-jarvis-tmux.sh, supporting hooks/agents
**Branch**: Project_Aion (commits through `22c8778`)

---

## Executive Summary

The JICM v5.6.2 system is **functionally operational** for the normal flow (monitoring -> threshold -> compression -> clear -> restore -> resume). However, this analysis identified **2 critical**, **6 high**, **8 medium**, and **4 low** issues in the watcher core, plus **2 critical** and **5 moderate** integration issues across supporting infrastructure. The system's primary weakness is **fragility under edge conditions** -- malformed files, timing races, and long-running idle-hands protocols that create monitoring blind spots.

### Risk Assessment

| Category | Finding Count | Operational Risk |
|----------|--------------|------------------|
| Script crash on edge case | 1 CRITICAL | High -- malformed flag file kills watcher |
| Duplicate /clear cascade | 1 CRITICAL | Medium -- requires crash-during-write |
| Monitoring blind spots | 2 HIGH | Medium -- 4-5 min blind during idle-hands |
| TOCTOU race conditions | 2 HIGH | Medium -- inherent to tmux architecture |
| Safety net disabled | 1 CRITICAL (infra) | High -- AUTOCOMPACT_PCT=95 above lockout |
| Compression permanently blocked | 1 CRITICAL (infra) | High -- crash leaves .compression-in-progress |

---

## CRITICAL Issues

### CRIT-01: Malformed idle-hands flag crashes watcher via `set -e`

**Location**: `jarvis-watcher.sh` lines 1308-1314, called from line 1401
**Severity**: CRITICAL -- watcher permanently stops

`check_idle_hands()` returns 1 at line 1314 (the `*` fallback case for unknown modes). It's called bare at line 1401 -- not inside an `if` or `||`. Under `set -e`, a `return 1` from a function called outside a conditional kills the script immediately. A malformed `.idle-hands-active` file with an unrecognized mode (typo, file corruption, future code mismatch) permanently crashes the watcher with no recovery.

**Impact**: Single point of failure. Any malformed flag file kills the watcher.
**Fix**: Change `return 1` to `return 0` at line 1314, or wrap the call at line 1401 in `if check_idle_hands; then ... fi`.

### CRIT-02: Partial signal file write enables duplicate `/clear`

**Location**: `jarvis-watcher.sh` lines 1466-1484
**Severity**: CRITICAL -- double-clear cascade possible

If `.clear-sent.signal` contains a truncated timestamp (crash mid-write, disk full), `date -j -f` fails, `clear_epoch` falls back to `0`, `clear_age` becomes effectively infinite, and the dedup check is bypassed. A duplicate `/clear` is sent. The session-start hook has a 30-second debounce that partially mitigates this but does not eliminate it.

**Impact**: Potential context loss via double-clear.
**Fix**: Use atomic writes (`echo > tmpfile && mv tmpfile target`) and validate timestamp format before parsing.

### CRIT-03: `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE=95` disables safety net (Infrastructure)

**Location**: `launch-jarvis-tmux.sh` line 116
**Severity**: CRITICAL -- native auto-compact fires above lockout ceiling

The launcher sets `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE=95`, meaning native auto-compact triggers at 95%. But the lockout ceiling is ~78.5%. At 95%, Claude Code has already locked out and `/compact` fails with "Conversation too long." This effectively disables the native safety net entirely. The `claude-code-env.sh` script correctly sets 70%, but the launcher overrides it.

**Impact**: If JICM fails, there is no backup -- native auto-compact is useless.
**Fix**: Change to 70 in `launch-jarvis-tmux.sh` line 116. Update comment on line 113.

### CRIT-04: `.compression-in-progress` never cleaned on startup (Infrastructure)

**Location**: `session-start.sh` lines 150-169 (startup/clear cleanup block)
**Severity**: CRITICAL -- compression permanently blocked after crash

If `/intelligent-compress` creates `.compression-in-progress` but the compression agent crashes, the flag persists. Next invocation of `/intelligent-compress` sees the flag and refuses to run ("Compression already in progress"). The watcher's 300-second failsafe resets `JICM_STATE` to monitoring but does NOT clean up `.compression-in-progress`. `session-start.sh` only cleans up `.compaction-in-progress` (legacy), not `.compression-in-progress` (v5).

**Impact**: A single compression failure permanently blocks all future compressions.
**Fix**: Add `rm -f "$CLAUDE_PROJECT_DIR/.claude/context/.compression-in-progress"` to the startup/clear block in `session-start.sh`.

---

## HIGH Issues

### HIGH-01: `compression_triggered` state stuck for 300s if command lost

**Location**: `jarvis-watcher.sh` lines 1618-1648
**Impact**: If `/intelligent-compress` keystroke is consumed as text during generation, no `.compression-done.signal` appears. Watcher sits in `compression_triggered` for 300 seconds, during which context grows unchecked toward lockout.

### HIGH-02: TOCTOU race between idle check and command delivery

**Location**: `jarvis-watcher.sh` lines 691-716
**Impact**: `wait_for_idle_brief()` reports "idle," but between that check and `send-keys`, Claude can start generating. Injected keystrokes are consumed as text input. This is inherent to the tmux injection architecture.

### HIGH-03: `idle_hands_jicm_resume()` blocks main loop for up to 4 minutes

**Location**: `jarvis-watcher.sh` lines 1138-1196
**Impact**: 20 cycles at 12-second intervals. Main monitoring loop is completely blind -- no context monitoring, no emergency detection. If clear failed silently, context could be high with no watchdog.

### HIGH-04: `idle_hands_session_start()` blocks main loop for up to ~5 minutes

**Location**: `jarvis-watcher.sh` lines 1215-1280
**Impact**: Same as HIGH-03. Additionally, if user starts typing during this period, watcher may inject `[SESSION-START]` prompts that corrupt user input.

### HIGH-05: Emergency `/compact` fires during active compression

**Location**: `jarvis-watcher.sh` lines 1594-1600
**Impact**: Emergency compact excludes only `state == "cleared"`, not `compression_triggered`. If context hits 73% while compression agent is running, `/compact` fires, potentially invalidating the agent's work. Agent never produces `.compression-done.signal`, triggering 300-second timeout.

### HIGH-06: `get_tokens_from_tui_abbreviated()` matches non-token patterns

**Location**: `jarvis-watcher.sh` lines 360-382
**Impact**: Regex `[0-9]+\.?[0-9]*k` matches any abbreviated number in last 5 pane lines -- file sizes, progress indicators, etc. False match could suppress compression or trigger it unnecessarily.

---

## MEDIUM Issues

### MED-01: `is_claude_busy()` bypasses TUI pane cache
Lines 635-650. Makes its own `tmux capture-pane` call while other functions use cached version. Busy/idle state may disagree with cached percentage data.

### MED-02: Signal file writes are not atomic
Lines 951, 1494. All signal files use `echo >` which allows concurrent readers to see partial content. Feeds CRIT-02.

### MED-03: `detect_idle_state()` prompt regex too broad
Lines 843-852. Pattern `>\s*$` matches markdown blockquotes, shell prompts, and comparison operators. False "idle" during active work.

### MED-04: `cleanup_jicm_files()` deletes compressed context before stable resume
Lines 1102-1122. Deletes `.compressed-context-ready.md` when spinner detected, but if Claude crashes mid-response, the compressed context is gone and unrecoverable.

### MED-05: `get_percentage_from_tui()` matches any `[0-9]+%` in output
Lines 395-405. Claude outputting "85% complete" in last 5 lines would be read as 85% context usage.

### MED-06: `consecutive_inconsistencies` counter survives state transitions
Lines 1371, 1531-1548. After /clear, cache is invalidated but inconsistency counter retains pre-clear value. Two inconsistencies before clear + one after immediately triggers fallback.

### MED-07: Persistent tmux session loss not detected
Main loop. If tmux session dies, all pane captures return empty, percentages read 0, watcher loops forever printing "Waiting for context data..." with no exit or alert.

### MED-08: `.jicm-standdown` persists forever with no auto-recovery
Lines 583-597. After 3 consecutive failures, standdown file persists across restarts, reboots, and new sessions. Manual intervention required.

---

## LOW Issues

### LOW-01: Temp file `/tmp/jicm-token-method.$$` never cleaned up (line 549)
### LOW-02: Version string "5.6.0" in `update_status()` not updated (line 569)
### LOW-03: `JICM_APPROACH_OFFSET` referenced but never declared (line 623)
### LOW-04: ERR trap fires on expected non-zero returns in conditionals (line 135)

---

## Infrastructure Integration Issues

### INT-01: `context-compressor.md` writes to wrong file path (STALE)
Agent writes to `.compressed-context.md` (v2 path). Watcher reads `.compressed-context-ready.md` (v5). No active code path invokes this agent, but its existence is confusing. Should be archived.

### INT-02: `.in-progress-ready.md` never created by any component
Referenced by watcher prompts and session-start.sh but no component writes this file. Dead reference.

### INT-03: 6 dead/orphaned signal files out of 19 total
`.clear-pending`, `.auto-clear-signal`, `.dump-requested.signal`, `.jicm-agent-spawn-signal`, `.continuation-verified.signal`, `.dump-prompt.md` -- none created or read by active code.

### INT-04: `stop-auto-clear.sh` checks v2/v3 signals, not v5
Checks `.auto-clear-signal` and `.clear-pending` instead of `.clear-sent.signal`. Could block stop behavior incorrectly.

### INT-05: `autonomy-config.yaml` references v4 executor layers
`executor_layer1`, `executor_layer2`, `cascade_resumer` sections describe v4 architecture removed in v5.

---

## Documentation Debt

| Document | Claims | Reality | Action |
|----------|--------|---------|--------|
| AC-04-jicm.md | v3.0.0 | v5.6.2 | **REWRITE** |
| automated-context-management.md | v3.0.0 | v5.6.2 | **MAJOR UPDATE** |
| jicm-pattern.md | v3.0.0 (marked superseded) | v5.6.2 | OK (historical) |
| jicm-v5-design-addendum.md | v5.0.0 | v5.6.2 | **ADD** emergency thresholds, lockout |
| jicm-v5-implementation-plan.md | "Ready for Testing" | Tested 2026-02-06 | **UPDATE** status |
| jicm-v6-enhancements.md | Design phase | Some items done | **UPDATE** baseline |

---

## Top Priority Fixes (Recommended Order)

1. **CRIT-01**: One-line fix -- `return 1` to `return 0` in `check_idle_hands()` fallback
2. **CRIT-03**: One-line fix -- `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE=95` to `70` in launcher
3. **CRIT-04**: Two-line fix -- add `.compression-in-progress` cleanup in `session-start.sh`
4. **CRIT-02 + MED-02**: Atomic signal file writes (small refactor)
5. **HIGH-05**: Add `compression_triggered` exclusion to emergency compact check
6. **HIGH-03/04**: Refactor idle-hands from blocking loops to per-iteration state checks (larger effort)

---

*Report generated 2026-02-06 by Jarvis critical analysis pipeline*
