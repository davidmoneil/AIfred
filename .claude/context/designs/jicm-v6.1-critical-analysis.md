# JICM v6.1 Critical Analysis — Enhancement Audit

**Date**: 2026-02-11
**Status**: Pre-Wiggum-Loop Analysis
**Scope**: 8 enhancement areas identified from operator review of v6.0

---

## 1. Executive Summary

JICM v6.0 (113 tests, 940 lines) established the stop-and-wait architecture. The operator has identified 8 areas requiring enhancement, 2 marked HIGH PRIORITY. This analysis examines each area in detail, identifies failure modes, and maps dependencies for the Wiggum Loop.

### Enhancement Priority Matrix

| # | Area | Priority | Risk | Complexity | Lines Est. |
|---|------|----------|------|-----------|------------|
| E1 | Idle detection overhaul | CRITICAL | HIGH | HIGH | +200 |
| E2 | Token extraction refinement | LOW | LOW | LOW | +/-20 |
| E3 | Compression agent prompt v6 | MEDIUM | MEDIUM | MEDIUM | +80 (agent.md) |
| E4 | Session-start vs restart | MEDIUM | MEDIUM | MEDIUM | +/-40 (hook) |
| E5 | Metrics/telemetry | HIGH | LOW | MEDIUM | +120 |
| E6 | v5 watcher removal | HIGH | HIGH | HIGH | -2002 (removal) |
| E7 | /compact hook cleanup | LOW | LOW | LOW | +/-30 |
| E8 | Session-state de-prioritization | LOW | LOW | LOW | +/-15 |

---

## 2. E1: Idle Detection Overhaul (CRITICAL)

### 2.1 Current Problem

The v6.0 `check_busy_state()` function (lines 278-301) relies on:
1. **Spinner character matching**: `[⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏◐◓◑◒]`
2. **Prompt character matching**: `❯\s*$|>\s*$`

**Failure modes identified by operator:**
- CC team actively modifies spinner characters between minor versions
- "Computing...", "Cogitating..." etc. rotate dynamically — not reliable
- `✻ Baked for Nm Ns` stays on screen after work completes → false positive risk
- Spinner chars `●` may or may not be present depending on CC version
- Spinner/prompt patterns persist on screen after state change → stale detection

### 2.2 Operator-Identified Stable Pattern

The **only reliable** idle indicator observed to be stable across CC versions:

```
  ⎿  Interrupted · What should Claude do instead?

────────────────────────────────────────────────────
❯
────────────────────────────────────────────────────
```

This pattern appears when ESC is sent. It is **triggered** (not passive) — the watcher sends ESC, then checks for this pattern.

### 2.3 Active Detection (Pattern Break)

When Jarvis resumes (text submitted), the screen changes to:

```
  ⎿  Interrupted · What should Claude do instead?

❯ [submitted text]

● [Activity text]... (Ns · ↑ N tokens)

────────────────────────────────────────────────────
```

The key change: **content appears between the "Interrupted" line and the separator bar**. The separator bar (`────`) moves down on screen.

### 2.4 Proposed Architecture

```
1. ASSUME: Jarvis State = ACTIVE (default)
2. Send ESC (trigger interrupt)
3. Capture pane → look for IDLE PATTERN:
     "Interrupted · What should Claude do instead?"
     followed by separator bar (─── line)
     with NOTHING between them except ❯ prompt
4. If pattern matches → Set Jarvis State = IDLE
5. After sending prompt/command → monitor for PATTERN BREAK:
     Content appears between "Interrupted" and separator
     OR separator position changes
6. If pattern breaks → Set Jarvis State = ACTIVE
7. REPEAT
```

**Critical insight**: This is a **triggered** idle system, not a **passive** poll. The ESC keystroke creates a deterministic screen state that can be reliably parsed.

### 2.5 Functions to Modify

| Function | Current | New |
|----------|---------|-----|
| `check_busy_state()` | Spinner grep | Triggered pattern match |
| `wait_for_idle()` | Polls check_busy_state | ESC + pattern confirmation |
| `check_jarvis_active()` | Spinner + keyword grep | Pattern break detection |
| NEW: `trigger_idle_check()` | — | Send ESC, capture, match idle pattern |
| NEW: `detect_activity()` | — | Monitor for pattern break after prompt send |

### 2.6 Impact on State Machine

- **WATCHING → HALTING gate**: `trigger_idle_check()` confirms idle BEFORE sending halt prompt
- **RESTORING → WATCHING gate**: `detect_activity()` confirms Jarvis is processing AFTER resume prompt

These are the two most critical state transitions. Getting idle/active detection right is foundational.

### 2.7 Risks

- **ESC during active work**: Could interrupt Jarvis mid-response. Mitigation: Only send ESC when context % is at threshold (already about to halt anyway).
- **Pattern format change**: CC team could change "Interrupted" text. Mitigation: Hook-based version change detection (operator noted this as acceptable).
- **Timing**: ESC → screen update → capture may need settling time. ~0.5s recommended.

---

## 3. E2: Token Extraction Refinement (LOW PRIORITY)

### 3.1 Current Problem

`get_token_count()` uses `grep -oE '[0-9,]+ tokens'` on last 5 lines. The operator notes the token count display `"162745 tokens"` is ALWAYS on the lower right edge, in range 0 < N < 200000.

### 3.2 Current Code Analysis

```bash
# Current (line 385): searches last 5 lines
tokens=$(echo "$pane" | tail -5 | grep -oE '[0-9,]+ tokens' | tail -1 | grep -oE '[0-9,]+' | tr -d ',')
```

### 3.3 Proposed Refinement

The status line format observed: `162188 tokens` (always lower-right). The current implementation already handles this correctly. The `tail -5` restriction is appropriate since the status line is always at the bottom.

**One improvement**: Add range validation (0 < N < 200000) to reject false matches from conversation content.

### 3.4 Changes Required

Minimal — add range check to existing extraction:
```bash
if [[ -n "$tokens" ]] && [[ "$tokens" -gt 0 ]] && [[ "$tokens" -lt 200001 ]]; then
```

---

## 4. E3: Compression Agent Prompt v6 (MEDIUM)

### 4.1 Current Problem

The compression agent prompt (compression-agent.md, 332 lines) is v5.8. Enhancement requests:
1. **Ensure reading core files**: CLAUDE.md, Psyche files, indexes, READMEs
2. **Use /export text**: Read export for chat history
3. **Use /context output**: Portion of chat history
4. **Reduce Skill and MCP content**: These bloat context
5. **Mask old tool output**: Aggressively compress tool call results

### 4.2 Analysis

The current agent prompt already covers:
- ✅ Foundation docs (CLAUDE.md, identity, compaction-essentials)
- ✅ Chat export reading
- ✅ Observation masking for tool outputs
- ⚠️ Missing: Explicit Psyche file reading (capability-map, prompts.yaml)
- ⚠️ Missing: Index file reading (patterns/_index.md, agents/README.md, skills/_index.md)
- ❌ Missing: Skill/MCP content reduction directive
- ❌ Missing: /context output usage
- ⚠️ Version still says "v5.8" — should be "v6.1"

### 4.3 Changes Required

1. Add Psyche files to Priority 1 (capability-map.yaml, prompts.yaml)
2. Add index files to Priority 1 (patterns/_index.md, agents/README.md, commands/README.md, skills/_index.md)
3. Add explicit "Skill/MCP Reduction" directive: compress skill descriptions to name+trigger only
4. Add /context usage: "If available, read output of /context command for chat summary"
5. Update version to v6.1
6. Strengthen tool output masking: "Skill and MCP schemas → name only, discard full schema"

---

## 5. E4: Session-Start vs Session-Restart (MEDIUM)

### 5.1 Current Problem

The session-start hook treats ALL /clear events the same. The operator wants differentiation:

**Session Start** (fresh session, no JICM):
- Read CLAUDE.md
- Read Psyche files
- Read index files
- Read session-state.md (as a brief, NOT compressed context)

**Session Restart** (JICM /clear):
- Read compressed context checkpoint (primary)
- Read CLAUDE.md
- Read Psyche files
- Do NOT prioritize session-state.md (it's stale during active work)

### 5.2 Current Code Path

In session-start.sh, the v6 path (lines 350-408):
- Detects state=CLEARING or RESTORING
- Loads compressed context
- Also loads session-state.md "Current Work" section
- Injects both into additionalContext

### 5.3 Changes Required

1. Remove session-state.md reading from v6 path (line 371-374)
2. Add CLAUDE.md content to v6 injection (summary, not full content)
3. Add Psyche file references to v6 injection
4. Keep session-start.md reading for fresh session starts only
5. Update restore prompt to NOT mention session-state.md

In jicm-watcher.sh, the restore prompt (line 586):
```bash
# CURRENT: references session-state.md
'[JICM-RESUME] Context compressed and cleared. Read .claude/context/.compressed-context-ready.md and .claude/context/session-state.md then resume work immediately.'

# NEW: references only compressed context + CLAUDE.md + Psyche
'[JICM-RESUME] Context compressed and cleared. Read .claude/context/.compressed-context-ready.md then CLAUDE.md then resume work immediately. Do NOT greet. Do NOT ask what to work on.'
```

---

## 6. E5: Metrics/Telemetry (HIGH PRIORITY)

### 6.1 Current Problem

No metrics captured for JICM cycle performance. Need:
- **Compression time**: How long the compression agent takes
- **Accuracy to target**: % reduction achieved vs 5K-15K target
- **Success rates**: Cycles completed vs failed
- **Retry counts**: How many retries per restore

### 6.2 Proposed Metrics Structure

```yaml
# Written to .claude/logs/telemetry/jicm-metrics.jsonl (append)
{
  "timestamp": "2026-02-11T12:00:00Z",
  "event": "jicm_cycle_complete",
  "cycle_number": 1,
  "compression_time_s": 45,
  "start_pct": 62,
  "start_tokens": 124000,
  "end_tokens": 8000,
  "target_tokens_min": 5000,
  "target_tokens_max": 15000,
  "within_target": true,
  "compression_ratio": "15.5:1",
  "halt_time_s": 8,
  "clear_time_s": 5,
  "restore_time_s": 12,
  "restore_retries": 0,
  "total_cycle_time_s": 70,
  "outcome": "success",
  "error_count": 0
}
```

### 6.3 Implementation Points

New variables in watcher:
- `CYCLE_START_TIME` — set when transitioning to HALTING
- `COMPRESS_START_TIME` — set when transitioning to COMPRESSING
- `CLEAR_START_TIME` — set when transitioning to CLEARING
- `RESTORE_START_TIME` — set when transitioning to RESTORING

New function: `emit_cycle_metrics()` — called on RESTORING → WATCHING transition (success) or any failsafe → WATCHING transition (failure).

Telemetry file: `$PROJECT_DIR/.claude/logs/telemetry/jicm-metrics.jsonl`

### 6.4 Dashboard Enhancement

Show last cycle metrics in dashboard:
```
║  Last cycle: 70s total (compress: 45s, clear: 5s, restore: 12s)  ║
```

---

## 7. E6: v5 Watcher Removal (HIGH PRIORITY)

### 7.1 Current State

`jarvis-watcher.sh` is 2002 lines. It is the v5 watcher. With v6 complete, it should be removed.

### 7.2 Dependency Audit

Files referencing `jarvis-watcher.sh` (from grep, excluding logs/archives/plans/reports/context):

**Active code dependencies (MUST rewire):**
| File | Nature | Action |
|------|--------|--------|
| `.claude/scripts/launch-jarvis-tmux.sh` | Fallback path | Already has v6 preference; remove v5 fallback |
| `.claude/hooks/session-start.sh` | v5 code path (lines 410+) | Remove entire v5 section |
| `.claude/scripts/housekeep.sh` | Phase 1 references | Update to reference jicm-watcher.sh |
| `.claude/context/psyche/capability-map.yaml` | watcher component | Update script path |
| `.claude/skills/context-management/SKILL.md` | Watcher references | Update |
| `.claude/skills/autonom-ops/SKILL.md` | Watcher references | Update |
| `.claude/skills/autonomous-commands/SKILL.md` | Watcher references | Update |
| `.claude/hooks/README.md` | Documentation | Update |
| `.claude/scripts/README.md` | Documentation | Update |
| `.claude/agents/jicm-agent.md` | Agent prompt | Update |
| `.claude/scripts/launch-watcher.sh` | Standalone launcher | Remove or redirect |
| `.claude/scripts/stop-watcher.sh` | Stop script | Update PID path |
| `.claude/scripts/signal-helper.sh` | Signal file helper | Assess if still needed |
| `.claude/state/components/AC-04-jicm.json` | State tracking | Update |
| `.claude/context/components/AC-04-jicm.md` | Component docs | Update |
| `.claude/commands/housekeep.md` | Reference | Update |

**Documentation/historical (leave as-is):**
- Plans, proposals, reports, reflections, archived logs — historical references stay.

### 7.3 Signal Files to Remove

v5 signal files that v6 no longer uses:
| Signal File | v5 Purpose | v6 Status |
|-------------|------------|-----------|
| `.watcher-status` | Watcher state | REPLACED by `.jicm-state` (v6 writes compat copy) |
| `.watcher-pid` | PID tracking | REPLACED by `.jicm-watcher.pid` |
| `.idle-hands-active` | Idle mode flag | ELIMINATED |
| `.clear-sent.signal` | Clear tracking | ELIMINATED |
| `.jicm-complete.signal` | Cycle complete | ELIMINATED |
| `.jicm-config` | Config file | ELIMINATED (CLI args) |
| `.jicm-standdown` | Standdown flag | ELIMINATED |
| `.continuation-injected` | Injection tracking | ELIMINATED |
| `.in-progress-ready.md` | Pre-clear summary | ELIMINATED |
| `.compression-in-progress` | Compression flag | HANDLED by state file |

### 7.4 Removal Strategy

1. **Phase A**: Remove v5 code paths from session-start.sh
2. **Phase B**: Remove v5 fallback from launch script
3. **Phase C**: Update all skill/agent/command references
4. **Phase D**: Update documentation and component files
5. **Phase E**: Remove `.claude/scripts/jarvis-watcher.sh`
6. **Phase F**: Remove auxiliary scripts (launch-watcher.sh, stop-watcher.sh, signal-helper.sh)
7. **Phase G**: Remove `.watcher-status` compat write from v6 watcher (once nothing reads it)

### 7.5 Risk: Backward Compatibility Write

The v6 watcher currently writes `.watcher-status` in v5-compatible format (lines 195-218). After v5 removal:
- Ennoia reads `.watcher-status` → Update to read `.jicm-state`
- `context-health-monitor.js` reads `.watcher-status` → Update
- `context-injector.js` reads `.watcher-status` → Check if still used

Once all consumers are updated, the compat write can be removed from v6 watcher.

---

## 8. E7: /compact Hook Cleanup (LOW)

### 8.1 Current State

Two pre-compact hooks fire:
1. `pre-compact.sh` (73 lines) — Creates checkpoint, outputs warning message
2. `precompact-analyzer.js` (286 lines) — Generates preservation manifest

### 8.2 Analysis

- `pre-compact.sh` references "JICM's proactive threshold was missed" — this is v5 language
- `precompact-analyzer.js` references "JICM v3.0.0 Solution B" in its header — very outdated
- The preservation manifest is useful: it tells the compression agent what to prioritize
- Both hooks are backup defense — they fire when native /compact triggers (JICM missed)

### 8.3 Changes Required

1. Update `pre-compact.sh` message to reference JICM v6
2. Update `precompact-analyzer.js` header to reference v6
3. Consider: Should pre-compact.sh trigger JICM v6 cycle instead of just warning?
   - Probably not — if /compact fires, JICM's threshold was too low or watcher was down
   - Better to checkpoint and let native compact handle it
4. Remove references to "Tier 2 MCPs" (already removed)

---

## 9. E8: Session-State De-prioritization (LOW)

### 9.1 Operator Directive

"De-prioritize the session-state file for mid-session context restoration. Create session-state and current-priorities at session end for new sessions if context restoration is wanted. Read only the compressed context, CLAUDE.md, Psyche files at context restore."

### 9.2 Changes Required

1. In v6 session-start hook: Remove session-state.md injection for JICM restarts
2. In compression agent: De-prioritize session-state from Priority 4 to optional
3. In restore prompt: Remove session-state.md reference
4. Session-state.md continues to be created/updated at session boundaries (AC-01/AC-09)

---

## 10. Keystroke Patterns Reference

### 10.1 Canonical tmux send-keys (validated 2026-02-04)

```bash
# Text: always via -l flag, always single-line
"$TMUX_BIN" send-keys -t "$TARGET" -l "text here"

# Submit: ALWAYS separate call
"$TMUX_BIN" send-keys -t "$TARGET" C-m

# Escape: cancel/interrupt
"$TMUX_BIN" send-keys -t "$TARGET" Escape
```

### 10.2 Idle Detection Keystroke Sequence

```bash
# 1. Send ESC to trigger interrupt
"$TMUX_BIN" send-keys -t "$TARGET" Escape
sleep 0.5

# 2. Capture pane
PANE=$("$TMUX_BIN" capture-pane -t "$TARGET" -p)

# 3. Match idle pattern
# Look for "Interrupted · What should Claude do instead?"
# followed by separator bar with only ❯ prompt between
```

### 10.3 Prompt Submission Sequence

```bash
# 1. Clear any pending input
"$TMUX_BIN" send-keys -t "$TARGET" Escape
sleep 0.2

# 2. Send prompt text
"$TMUX_BIN" send-keys -t "$TARGET" -l "[JICM-HALT] ..."
sleep 0.1

# 3. Submit
"$TMUX_BIN" send-keys -t "$TARGET" C-m
```

---

## 11. Wiggum Loop Cycle Plan

| Cycle | Focus Area | Deliverables |
|-------|-----------|-------------|
| 1-2 | E1: Idle detection — trigger_idle_check() | New function, tests |
| 3-4 | E1: Idle detection — detect_activity() + wiring | Pattern break detection, state gate wiring |
| 5-6 | E1: Idle detection — integration + wait_for_idle rewrite | Full idle system, simulation tests |
| 7 | E2: Token extraction range validation | Refinement, tests |
| 8-9 | E3: Compression agent prompt v6 | Updated agent.md, tests |
| 10-11 | E4: Session-start/restart differentiation | Hook changes, restore prompt, tests |
| 12-13 | E5: Metrics/telemetry | emit_cycle_metrics(), dashboard, tests |
| 14-15 | E6: v5 removal Phase A-C | Code path removal, reference updates |
| 16-17 | E6: v5 removal Phase D-G + compat write removal | Full removal, doc updates |
| 18 | E7+E8: /compact cleanup + session-state de-prioritization | Hook updates |
| 19 | Full test suite run + live-fire validation | All tests passing |
| 20 | Documentation + summary report | Final docs |

---

*JICM v6.1 Critical Analysis — Enhancement Audit*
*8 areas, 2 HIGH PRIORITY, 1 CRITICAL (idle detection)*
*Created: 2026-02-11*
