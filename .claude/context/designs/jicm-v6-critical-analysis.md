# JICM v5 Critical Analysis — Pre-Redesign Assessment

**Date**: 2026-02-11
**Purpose**: Detailed forensic analysis of the current JICM system to inform ground-up redesign
**Author**: Jarvis (Autonomous Analysis)

---

## 1. Architecture Forensics

### 1.1 Component Inventory (Current System)

The current JICM system spans **7 files** across 3 architectural layers:

| Component | File | Lines | Role |
|-----------|------|-------|------|
| Watcher | `jarvis-watcher.sh` | ~2000 | Monitoring, state machine, idle-hands, command execution |
| Session-Start Hook | `session-start.sh` | ~660 | Context injection (Mechanism 1), .idle-hands-active creation |
| Compression Agent | `compression-agent.md` | ~100 | Claude model-powered context compression |
| Compression Command | `intelligent-compress.md` | ~30 | Skill that Jarvis executes to spawn agent |
| Context Injector | `context-injector.js` | ~220 | PreToolUse hook for tool hints + budget |
| Ennoia | `ennoia.sh` | ~310 | Session orchestrator, wake-up recommendations |
| Virgil | `virgil.sh` | ~300 | Task/agent/file tracking (observational only) |

**Total: ~3,620 lines of JICM-related code across 7 files.**

### 1.2 Signal File Proliferation

The current system uses **12+ signal files** for inter-component communication:

| Signal File | Writer | Reader | Purpose |
|-------------|--------|--------|---------|
| `.compression-done.signal` | Compression agent | Watcher | Agent finished |
| `.compression-in-progress` | Watcher / `/intelligent-compress` | Watcher, session-start | Guard against double compression |
| `.clear-sent.signal` | Watcher | Watcher, session-start | Dedup /clear |
| `.continuation-injected.signal` | session-start | **NOBODY** (orphaned) | Was for verifier.js (removed) |
| `.jicm-complete.signal` | Watcher (cleanup_jicm_files) | Watcher (B2 check) | Resume confirmed |
| `.idle-hands-active` | session-start | Watcher | Resume mode trigger |
| `.in-progress-ready.md` | Jarvis (main agent) | session-start | Recent work during compression |
| `.compressed-context-ready.md` | Compression agent | session-start | Compressed context |
| `.watcher-status` | Watcher | Ennoia, context-injector, health monitor | Live status |
| `.watcher-pid` | Watcher | External scripts | Process tracking |
| `.jicm-config` | Watcher | Statusline | Dynamic threshold config |
| `.jicm-standdown` | Watcher | Watcher | Circuit breaker state |
| `.ennoia-recommendation` | Ennoia | Watcher | Context-aware prompt text |
| `.ennoia-status` | Ennoia | Virgil | Metadata |
| `.pre-clear-tokens` | Watcher | Watcher | Pre-clear token snapshot |

**Verdict: 15 signal files is excessive.** Many exist as workarounds for race conditions or legacy flows. The `.continuation-injected.signal` has NO readers (orphaned since jicm-continuation-verifier.js was unregistered). Signal file IPC is fragile — files can get stale, lost, or misinterpreted.

### 1.3 State Machine Analysis

Current state machine has **3 states** with **2 emergency paths**:

```
monitoring ─(threshold)──▶ compression_triggered ─(done signal)──▶ cleared ─(pct<30%)──▶ monitoring
     ▲                          │ (300s failsafe)                    │ (120s failsafe)         │
     └──────────────────────────┘                                    └─────────────────────────┘

Emergency paths:
  - context_exhausted (any state → cleared via emergency /clear)
  - post_clear_unhandled (cleared → monitoring via emergency restore)
```

**Problems:**
1. **Failsafe timeouts create cascading loops.** The 300s failsafe resets to `monitoring`, but pct is still above threshold, causing immediate re-trigger (v5.8.3 had to add a cooldown mechanism to fix this).
2. **State can get stuck.** If compression agent crashes silently, no `.compression-done.signal` is created. Watcher waits 300s in `compression_triggered`, then must recover via failsafe.
3. **Grace periods mask bugs.** 20-second grace periods after state transitions prevent false positives but also blind the system to real problems during that window.
4. **Two emergency handlers conflict.** `detect_critical_state()` and idle-hands both try to handle post-clear scenarios; the v5.8.2 fix added JICM_COMPLETE_SIGNAL specifically to prevent the B2 handler from firing after idle-hands already succeeded.

---

## 2. Instability History (Changelog Forensics)

The current watcher has **18 version bumps** from v5.2.0 to v5.8.5, each fixing bugs or design flaws. This is a clear indicator of systemic fragility:

| Version | Date | Category | Issue |
|---------|------|----------|-------|
| v5.2.0 | 02-05 | Race condition | Stale token counts after /clear — needed cache invalidation |
| v5.3.0 | 02-05 | Missing feature | No critical state detection at all |
| v5.3.1 | 02-05 | Crash | Missing error handling in handle_critical_state() |
| v5.3.2 | 02-05 | bash 3.2 | `set -e` exit bug in detect_critical_state() |
| v5.4.0 | 02-05 | Stale data | Stale cache loop, no heartbeat display |
| v5.4.1 | 02-05 | False positives | Duplicate resume prompts after successful restore |
| v5.4.2 | 02-05 | Design flaw | "interrupted" state handler caused runaway loop |
| v5.4.3 | 02-05 | Data bug | Token extraction matched stale scroll buffer content |
| v5.4.4 | 02-05 | Wrong fix | Attempted debounce fix (reverted) |
| v5.4.5 | 02-05 | Correct fix | State machine prevents context_exhausted re-trigger |
| v5.5.0 | 02-05 | Threshold | 80% threshold was ABOVE lockout ceiling (~78.5%) |
| v5.5.1 | 02-05 | Stale buffer | Restricted critical state checks to last 8 lines |
| v5.6.0 | 02-06 | **Major rewrite** | 19 issues across 4 categories (A1-A5, B1-B6, C1-C4, D1-D4) |
| v5.6.1 | 02-06 | Timing | Commands lost during active generation — added idle-wait |
| v5.8.1 | 02-07 | Stale flag | .compression-in-progress not cleaned after agent crash |
| v5.8.2 | 02-08 | Race conditions | 4 distinct race conditions in dump, clear, restore |
| v5.8.3 | 02-10 | Cascading failure | Failsafe timeout → infinite re-trigger loop; needed cooldown |
| v5.8.4 | 02-10 | Enhancement | Chat export before compress/clear |
| v5.8.5 | 02-10 | Enhancement | Ennoia recommendation integration |

**Pattern: 13 of 18 versions were BUG FIXES, not features.** The system was unstable from v5.2.0 through v5.8.3 (8 days of continuous bug-fixing). This speaks to fundamental architectural complexity creating emergent failure modes.

### 2.1 Root Cause Categories

| Category | Count | Examples |
|----------|-------|---------|
| **bash 3.2 / macOS** | 3 | set -e exits, stat syntax, subshell returns |
| **Stale data / race conditions** | 5 | TUI buffer, token count, cache, signal files |
| **Design flaws** | 4 | State handler loops, threshold above lockout, blocking waits |
| **Missing error handling** | 3 | Crash on startup, missing functions, no timeout |
| **Cascading failures** | 2 | Failsafe → re-trigger loop, double emergency handler |

**The #1 cause of bugs is COMPLEXITY.** Every interaction between components creates new edge cases. The parallel work model (Jarvis continues while compression runs) is responsible for most of the complexity: interrupt/dump phases, timing races, stale data, and recovery scenarios.

---

## 3. Specific Design Weaknesses

### 3.1 Parallel Work Creates Most Complexity

The current design has Jarvis continue working while the compression agent runs. This creates:

1. **The `.in-progress-ready.md` problem**: Jarvis does work during compression, so we need to capture that work separately. This requires an interrupt prompt, idle-wait, file detection, and timeout handling (~50 lines of code in section 1.5).

2. **Two context files instead of one**: `.compressed-context-ready.md` (historical) + `.in-progress-ready.md` (recent). Both must exist and be injected. If either is missing, we need retry logic.

3. **Context keeps growing during compression**: While waiting for compression, Jarvis's context continues to grow (new tool calls, responses). This can push context past the emergency threshold, requiring additional safety nets.

4. **Race conditions**: Jarvis might finish the interrupted work before the watcher sends the interrupt. Or the watcher might send the interrupt while Jarvis is mid-tool-call.

**Eliminating parallel work removes ALL of these problems.** If Jarvis stops and waits, there's no `.in-progress-ready.md` needed, no race conditions, no growing context, and only one context file.

### 3.2 Multi-Mechanism Resume Is Over-Engineered

The "Two-Mechanism Resume" system:
- **Mechanism 1**: Hook injects context via `additionalContext` JSON
- **Mechanism 2**: Watcher sends keystroke prompt via tmux

Mechanism 1 is **100% reliable** — it always works. The problem is it can't FORCE a response. Mechanism 2 exists solely because Jarvis might sit idle after getting context injected.

**Simpler approach**: After /clear, the watcher simply sends a prompt. The session-start hook injects context. Combined, these always work. The complexity of cycling through 9 submission variants (3 methods × 3 prompts) is overkill. Testing confirmed that `C-m` and `Enter` both work reliably from external processes.

### 3.3 Too Many Emergency Handlers

The system has **4 different recovery mechanisms**:
1. `idle_hands_jicm_resume()` — planned resume after /clear
2. `handle_critical_state("post_clear_unhandled")` — emergency when hooks fail
3. `handle_critical_state("context_exhausted")` — emergency /clear when locked out
4. Emergency `/compact` at 73% — raw compact to prevent lockout

These overlap and interact in complex ways. The v5.8.2 fix specifically addressed a case where idle-hands succeeded but the B2 handler ALSO fired because it didn't know idle-hands had already handled it.

### 3.4 Token Extraction Is Fragile

The current system has **6 methods** to get token counts:
1. TUI exact (`"63257 tokens"` in last 5 lines)
2. TUI abbreviated (`"63.2k"` in last 5 lines)
3. TUI percentage (`"32%"` in last 5 lines)
4. Statusline JSON (file-based)
5. JSON current_usage sum
6. Percentage estimate calculation

These cascade through fallbacks and cross-validate. All rely on parsing the visible tmux pane content, which changes format between debug/non-debug modes and different TUI layouts.

**Problem**: Parsing visible text from a TUI is inherently fragile. The format can change with Claude Code updates, window resizes, or configuration changes. The v5.4.3 bug (stale scroll buffer match) demonstrates this fragility.

### 3.5 The Watcher Does Too Many Things

The current `jarvis-watcher.sh` handles:
1. Context monitoring (token polling)
2. JICM compression triggering
3. /clear orchestration
4. Post-clear resume (idle-hands)
5. Session start wake-up
6. Command signal processing
7. Critical state detection
8. Emergency handlers
9. Chat export
10. Ennoia recommendation reading
11. Dashboard display

This violates the Single Responsibility Principle. A 2000-line bash script with this many responsibilities is difficult to test, debug, and maintain.

---

## 4. Best Principles to Carry Forward

### 4.1 What Works Well

| Principle | Why It Works |
|-----------|-------------|
| **External process for keystroke injection** | Self-injection fails due to TUI event loop blocking. External watcher works 100% of the time. |
| **Signal files for state communication** | Simple, robust, filesystem-based IPC. Just needs to be minimal. |
| **Session-start hook for context injection** | `additionalContext` is the most reliable way to inject context after /clear. |
| **Single threshold trigger** | Simpler than multi-tier warnings. One decision point. |
| **Archive, don't delete** | Moving files to archive instead of deleting preserves debugging evidence. |
| **Canonical tmux send-keys pattern** | Validated: text via `-l`, submit via separate `C-m` call. |
| **bash 3.2 return 0 pattern** | Essential for macOS compatibility with `set -e`. |

### 4.2 Canonical tmux Keystroke Patterns

**VALIDATED (from 2026-02-04 testing):**

```bash
# Pattern 1: Send text + submit (ALWAYS use this)
"$TMUX_BIN" send-keys -t "$TARGET" -l "prompt text"
"$TMUX_BIN" send-keys -t "$TARGET" C-m

# Pattern 2: Alternative submit key
"$TMUX_BIN" send-keys -t "$TARGET" -l "prompt text"
"$TMUX_BIN" send-keys -t "$TARGET" Enter

# Pattern 3: Send Escape (to cancel any pending input)
"$TMUX_BIN" send-keys -t "$TARGET" Escape

# Pattern 4: Send slash command
"$TMUX_BIN" send-keys -t "$TARGET" -l "/clear"
"$TMUX_BIN" send-keys -t "$TARGET" C-m
```

**NEVER DO:**
```bash
# ❌ Embedded CR in -l string (treated as literal, not submit)
"$TMUX_BIN" send-keys -t "$TARGET" -l "text"$'\r'

# ❌ Multi-line text in -l string (corrupts TUI input buffer)
"$TMUX_BIN" send-keys -t "$TARGET" -l "line one
line two"

# ❌ Self-injection from within Claude Code Bash tool
# (fails due to TUI event loop blocking)
```

**IDLE DETECTION (before sending):**
```bash
# Check last 5 lines for spinner characters
pane=$("$TMUX_BIN" capture-pane -t "$TARGET" -p)
if echo "$pane" | tail -5 | grep -qE '⠋|⠙|⠹|⠸|⠼|⠴|⠦|⠧|⠇|⠏'; then
    # BUSY — do not send
else
    # IDLE — safe to send
fi
```

**SUBMIT VERIFICATION (after sending):**
```bash
sleep 3  # Give time to process
pane=$("$TMUX_BIN" capture-pane -t "$TARGET" -p)
# Check for spinner (processing) or response text
if echo "$pane" | grep -qE '⠋|⠙|⠹|⠸|⠼|⠴|⠦|⠧|⠇|⠏'; then
    # SUCCESS — prompt was accepted
fi
```

---

## 5. Pitfalls to Avoid in Redesign

| Pitfall | Details | Mitigation |
|---------|---------|------------|
| **bash 3.2 `set -e` with `$()`** | Functions called via command substitution that return non-zero cause immediate script exit on macOS bash 3.2 | All functions MUST `return 0`; use `echo` for output values |
| **Multi-line tmux send-keys** | `-l` flag treats newlines literally, corrupting TUI input | ALL prompts must be single-line strings |
| **Stale tmux scroll buffer** | `capture-pane -p` returns full scroll history; old token counts/messages persist | Always restrict to `tail -N` (last 3-5 lines) |
| **Self-injection from Bash tool** | Sending keystrokes to own session while TUI is blocked fails | ALL injection from external watcher process only |
| **Failsafe → re-trigger loop** | Resetting to monitoring while pct > threshold causes immediate re-trigger | Cooldown period after failsafe fires |
| **Double emergency handler** | Multiple recovery systems don't know about each other's success | Single recovery path, or shared success signal |
| **stat syntax macOS vs Linux** | macOS uses `stat -f %m`, Linux uses `stat -c %Y` | Use `stat -f %m` (our target is macOS) |
| **Token extraction fragility** | Parsing TUI text for numbers is unreliable | Prefer percentage (simpler pattern), validate with sanity checks |
| **Grace period masking bugs** | Post-transition grace periods can hide real problems | Keep grace periods short (10s max), log when active |
| **Signal file staleness** | Files left from crashed processes can trigger wrong behavior | Always check file age; clean stale signals on startup |

---

## 6. Complexity Metrics

| Metric | Current System | Target (Redesign) |
|--------|---------------|-------------------|
| Total lines of code (watcher) | ~2000 | <600 |
| Signal files | 15 | ≤5 |
| State machine states | 3 + 2 emergency | 4 (linear, no emergency branches) |
| Token extraction methods | 6 | 1-2 |
| Resume mechanism variants | 9 (3×3) | 1-2 |
| Emergency handlers | 4 | 1 (native /compact fallback) |
| Changelog bug-fix versions | 13 | 0 (design it right) |
| Separate recovery systems | 4 | 1 |

---

## 7. Key Design Decision: Stop-and-Wait

The user's redesign directive eliminates parallel work during compression. This is the single most important simplification:

**Current (Parallel):**
```
[threshold] → [trigger compress] → [Jarvis continues working] → [agent finishes]
                                     ↓ context keeps growing
                                     ↓ need interrupt/dump
                                     ↓ race conditions
                                     → [interrupt Jarvis] → [wait for dump] → [/clear] → [restore]
```

**New (Stop-and-Wait):**
```
[threshold] → [stop Jarvis] → [export+compress] → [agent finishes] → [/clear] → [restore]
                  ↓ context frozen
                  ↓ no race conditions
                  ↓ no interrupt needed
                  ↓ single context file
```

**Benefits:**
1. No `.in-progress-ready.md` (context frozen at compression point)
2. No interrupt/dump sequence (50+ lines eliminated)
3. No race conditions (Jarvis isn't doing anything)
4. Context doesn't grow during compression (no emergency threshold races)
5. Single context file for restoration
6. Linear state machine (no branching emergency paths)

**Tradeoff:** Jarvis is unproductive during compression (~60-120s). This is acceptable because:
- Compression happens at most once per session
- 60-120s of idle time is trivial compared to hours of active work
- The alternative (parallel work) creates cascading complexity that has caused 13 bug-fix versions

---

## 8. Conclusion

The current JICM system is **functionally correct but architecturally fragile**. It works, but it took 18 versions and 13 bug fixes to get there. The root cause is the parallel work model creating combinatorial complexity in timing, state, and recovery.

The ground-up redesign should:
1. **Eliminate parallel work** (stop-and-wait during compression)
2. **Minimize signal files** (≤5, all with clear lifecycle)
3. **Single recovery path** (no overlapping emergency handlers)
4. **Simple state machine** (linear progression, one failsafe)
5. **Robust tmux patterns** (canonical send-keys, validated methods only)
6. **Crash-proof design** (auto-restart, auto-reset, fail towards continuation)
7. **Dashboard output** (informative, visually appealing)
8. **Comprehensive TDD** (test every function in isolation)

---

*JICM v5 Critical Analysis — Forensic Assessment for Ground-Up Redesign*
*Document created: 2026-02-11 00:15*
