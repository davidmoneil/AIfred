# JICM Compression Reliability Analysis

**Date**: 2026-02-12
**Source**: Wiggum Loop 1 watcher log analysis + code review
**JICM Version**: v6.1.0
**Watcher Log**: `.claude/logs/jicm-watcher.log`

---

## Observed Failure Rate

**Session**: 2026-02-12 (UTC 19:03 - 20:36)
**Cycles Attempted**: 5
**Succeeded**: 1 (Cycle 1)
**Failed**: 4 (Cycles 2-5)
**Success Rate**: 20%

| Cycle | UTC Start | Trigger % | Outcome | Duration | Failure Mode |
|-------|-----------|-----------|---------|----------|--------------|
| 1 | 19:10:18 | 55% | SUCCESS | 274s | — |
| 2 | 19:45:40 | 56% | FAIL | ~40s | Signal present, checkpoint missing |
| 3 | 19:56:23 | 57% | TIMEOUT | 302s | No signal within 300s |
| 4 | 20:11:28 | 58% | TIMEOUT | 302s | No signal within 300s |
| 5 | 20:26:33 | 62% | TIMEOUT | 302s | No signal within 300s |

---

## Root Cause Analysis

### Bug 1: Stale `.compression-in-progress` Flag (Primary Cause of Cycles 3-5)

**The Pipeline**:
1. Watcher injects `[JICM-COMPRESS] Run /intelligent-compress NOW...` into W0
2. W0 executes `/intelligent-compress` command
3. Command Step 1: Checks `.compression-in-progress` flag — **if exists, STOPS immediately**
4. Command Step 2: Creates `.compression-in-progress` flag
5. Command Step 4: Spawns compression-agent Task (background)
6. Agent writes checkpoint + signal

**The Bug**: The flag created in Step 4 is NEVER cleaned up:
- The compression agent doesn't clean it (by design — agent is minimal)
- The `/intelligent-compress` command doesn't clean it (by design — "watcher handles cleanup")
- The jicm-watcher.sh (v6.1) **never references `.compression-in-progress`**
- The OLD jarvis-watcher.sh (v5) DID clean it, but v6.1 didn't carry over that logic

**Result**: Cycle 1 creates the flag → Cycles 2-5 find it → `/intelligent-compress` says "already in progress" → no agent spawns → 300s timeout.

**Fix Applied**: `do_compress()` now removes `.compression-in-progress` before spawning. Timeout handler also removes it.

### Bug 2: Stale `.compression-done.signal` (Cause of Cycle 2)

**The Pipeline**:
1. `do_compress()` spawns agent → returns to main loop
2. Main loop polls for `.compression-done.signal`
3. When found → calls `do_clear()`
4. `do_clear()` removes signal → checks checkpoint → sends /clear

**The Bug**: `do_compress()` did NOT clean up stale signal files before spawning. If a signal file lingered from a previous cycle (late background agent write, incomplete cleanup), the main loop would detect it immediately — before the new agent even started.

**Evidence**: Cycle 2 signal detected 5 seconds after spawn prompt. Compression agents take 30-190 seconds. The signal was stale from Cycle 1.

**Fix Applied**: `do_compress()` now removes both signal and in-progress flag as its first step.

---

## Fixes Applied

### In `jicm-watcher.sh`:

**1. `do_compress()` — Step 0 cleanup (before export)**:
```bash
# Step 0: Clean up stale artifacts from prior cycles
rm -f "$COMPRESSION_SIGNAL"
rm -f "$PROJECT_DIR/.claude/context/.compression-in-progress"
```

**2. `do_clear()` — cleanup includes in-progress flag**:
```bash
rm -f "$COMPRESSION_SIGNAL"
rm -f "$PROJECT_DIR/.claude/context/.compression-in-progress"
```

**3. Timeout handler — cleanup includes in-progress flag**:
```bash
rm -f "$COMPRESSION_SIGNAL"
rm -f "$PROJECT_DIR/.claude/context/.compression-in-progress"
```

### In `restart-watcher.sh`:

**4. Fixed `local` keyword outside function (line 85)**:
```bash
# Before: local waited=0   ← crashes with set -e in bash 3.2
# After:  waited=0          ← works at script scope
```

---

## Remaining Risks

### 1. Compression Agent Timeout Margin
- **COMPRESS_TIMEOUT**: 300s (5 minutes)
- **Agent declared timeout**: 5 minutes (advisory only)
- **Observed successful cycle time**: 191s (Cycle 1)
- **Risk**: Agent reading large chat exports or many files could legitimately need >300s
- **Recommendation**: Consider increasing to 420s (7 minutes) to provide margin

### 2. No Heartbeat / Progress Feedback
- Watcher has zero visibility into agent progress
- Only knows "not started" → "done" (signal file appears)
- Can't distinguish "agent running slowly" from "agent failed silently"
- **Recommendation**: Add a `.compression-heartbeat` file updated every 60s by agent

### 3. Indirect Spawn Chain Adds Latency
- Path: Watcher → tmux → W0 (parse prompt) → Skill dispatch → Task spawn → Agent
- Each step adds 1-5s latency, eating into the 300s budget
- W0 may be slow to process if at high context %
- **Recommendation**: Consider tracking spawn-to-first-read latency

### 4. Chat Export Growing Per Cycle
- Each failed cycle adds more context to W0 (the JICM-COMPRESS prompt itself)
- Context % increases: 55% → 56% → 57% → 58% → 62%
- Later cycles have more to export, taking more time
- **Recommendation**: The fixes above should prevent the cascade entirely

---

## Verification Plan

These fixes should be verified in Wiggum Loop 2 (T02: Full JICM cycle):
1. Restart watcher with `--threshold 15`
2. Send large file reads to W0 to fill context
3. Observe JICM cycle trigger
4. Verify cycle completes successfully (no stale artifact issues)
5. Optionally trigger a second cycle to verify multi-cycle reliability

---

*Analysis generated 2026-02-12 by Jarvis-dev*
