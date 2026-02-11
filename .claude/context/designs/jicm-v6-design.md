# JICM v6 Ground-Up Design — Stop-and-Wait Architecture

**Date**: 2026-02-11
**Status**: Design Specification
**Paradigm**: Simplicity, Precision, Responsiveness, Accuracy, Stability

---

## 1. System Overview

JICM v6 is a **stop-and-wait** context compression system. When context reaches a configurable threshold, Jarvis is halted, context is compressed by a background agent, /clear is sent, and Jarvis is restored from compressed context.

**Key Simplification**: Jarvis does NOT continue working during compression. This eliminates race conditions, interrupt sequences, and the need for `.in-progress-ready.md`.

### 1.1 Components

| Component | File | Role |
|-----------|------|------|
| **JICM Watcher** | `.claude/scripts/jicm-watcher.sh` | Monitor, halt, compress, clear, restore |
| **Session-Start Hook** | `.claude/hooks/session-start.sh` | Inject compressed context on /clear |
| **Compression Agent** | `.claude/agents/compression-agent.md` | Claude model-powered context compression |
| **Launch Script** | `.claude/scripts/launch-jarvis-tmux.sh` | tmux session setup (modified) |

**Total: 4 components.** Down from 7.

### 1.2 Signal Files (Minimal Set)

| Signal | Writer | Reader | Lifecycle |
|--------|--------|--------|-----------|
| `.jicm-state` | Watcher | Session-start hook, Ennoia | Continuous (current state + metadata) |
| `.compressed-context-ready.md` | Compression agent | Session-start hook | Created by agent → consumed after restore |
| `.compression-done.signal` | Compression agent | Watcher | Created by agent → deleted by watcher |

**Total: 3 signal files.** Down from 15.

The `.jicm-state` file replaces `.watcher-status`, `.watcher-pid`, `.idle-hands-active`, `.clear-sent.signal`, `.jicm-complete.signal`, `.jicm-config`, and `.jicm-standdown` — all consolidated into one state file.

---

## 2. State Machine

```
          ┌──────────┐
          │ WATCHING  │ ◀─────────────────────────────┐
          └────┬──────┘                               │
               │ pct >= threshold                      │
               ▼                                       │
          ┌──────────┐                                 │
          │ HALTING   │ (send ESC + HALT prompt)       │
          └────┬──────┘                                │
               │ Jarvis confirmed idle                 │
               ▼                                       │
          ┌──────────┐                                 │
          │COMPRESSING│ (spawn agent, wait for done)   │
          └────┬──────┘                                │
               │ .compression-done.signal exists       │
               ▼                                       │
          ┌──────────┐                                 │
          │ CLEARING  │ (send /clear, wait for drop)   │
          └────┬──────┘                                │
               │ pct < 10% (clear confirmed)           │
               ▼                                       │
          ┌──────────┐                                 │
          │ RESTORING │ (send resume prompt, verify)   │
          └────┬──────┘                                │
               │ Jarvis confirmed active               │
               └──────────────────────────────────────┘
```

**5 states, linear progression, no emergency branches.** If any state gets stuck, a single timeout handler resets to WATCHING and lets native /compact handle it.

### 2.1 State Transitions

| From | To | Trigger | Timeout |
|------|----|---------|---------|
| WATCHING | HALTING | `pct >= threshold` | — |
| HALTING | COMPRESSING | Jarvis idle confirmed | 60s → reset to WATCHING |
| COMPRESSING | CLEARING | `.compression-done.signal` exists | 300s → reset to WATCHING |
| CLEARING | RESTORING | `pct < 10%` | 60s → retry /clear once, then reset |
| RESTORING | WATCHING | Jarvis active (spinner/response) | 120s → send native /compact fallback |

### 2.2 Universal Failsafe

Any state stuck beyond its timeout resets to WATCHING with a 10-minute cooldown. Native Claude Code auto-compact at ~85% provides the safety net. **The system never panics — it gracefully degrades to letting the platform handle it.**

---

## 3. Prompt Injection Sequences

### 3.1 HALT Sequence (WATCHING → HALTING)

```bash
# Step 1: Cancel any pending input
send_keys Escape
sleep 0.3

# Step 2: Send halt instruction
send_keys -l "STOP. Context at ${PCT}%. Compression starting. HALT all work. Do NOT continue interrupted tasks."
send_keys C-m
```

### 3.2 COMPRESS Sequence (HALTING → COMPRESSING)

```bash
# Wait for idle confirmation (Jarvis has stopped)
wait_for_idle 60

# Step 1: Export context
send_keys Escape
send_keys -l "/export .claude/context/export_chat.txt"
send_keys C-m
sleep 5

# Step 2: Spawn compression agent
send_keys Escape
send_keys -l "Spawn compression agent NOW: Use Task tool with subagent_type='compression-agent', model='sonnet', run_in_background=true, prompt='Compress current conversation context for JICM v6. Target 5K-15K tokens. Write checkpoint to .claude/context/.compressed-context-ready.md and signal to .claude/context/.compression-done.signal'. After spawning, say only COMPRESSION_SPAWNED."
send_keys C-m
```

### 3.3 CLEAR Sequence (COMPRESSING → CLEARING)

```bash
# Compression agent has finished
send_keys Escape
send_keys -l "/clear"
send_keys C-m
```

### 3.4 RESTORE Sequence (CLEARING → RESTORING)

The session-start hook handles context injection via `additionalContext`. The watcher sends the resume prompt:

```bash
# Wait for TUI to show fresh session
sleep 3

send_keys -l "[JICM-RESUME] Context compressed and cleared. Read .claude/context/.compressed-context-ready.md and .claude/context/session-state.md — resume work immediately. Do NOT greet."
send_keys C-m
```

### 3.5 Retry Logic for RESTORING

If Jarvis doesn't respond within 15s:
```bash
# Retry 1: Same prompt
send_keys -l "[JICM-RESUME] Read .claude/context/.compressed-context-ready.md — continue work."
send_keys C-m

# Retry 2 (after 15s): Minimal
send_keys -l "[JICM-RESUME] Continue."
send_keys C-m

# Retry 3 (after 15s): Just submit
send_keys C-m
```

Max 8 retries (2 minutes). After that, leave Jarvis at prompt — user intervention needed.

---

## 4. Dashboard Design

The watcher displays a live dashboard in its tmux window:

```
╔═══════════════════════════════════════════════════════╗
║  JICM v6 WATCHER                    ● WATCHING       ║
╠═══════════════════════════════════════════════════════╣
║                                                       ║
║  Context: ████████░░░░░░░░░░░░  42%  84,000 tokens   ║
║  Threshold: 55%     Lockout: ~78%                     ║
║                                                       ║
║  Session: 2h 14m    Compressions: 0    Errors: 0      ║
║  Last poll: 12:34:56    Interval: 5s                  ║
║                                                       ║
║  ── Recent Activity ──                                ║
║  12:34:51  ● 42% (84000 tokens) [tui_pct]            ║
║  12:34:46  ● 41% (82000 tokens) [tui_pct]            ║
║  12:34:41  ● 41% (82000 tokens) [tui_pct] ♡          ║
║                                                       ║
╚═══════════════════════════════════════════════════════╝
```

State-specific displays:
- **WATCHING**: Green dot, progress bar, token count
- **HALTING**: Yellow dot, "Halting Jarvis..."
- **COMPRESSING**: Yellow pulse, "Compression agent running... (42s)"
- **CLEARING**: Blue dot, "Sending /clear..."
- **RESTORING**: Cyan dot, "Restoring context... (attempt 1/8)"

---

## 5. Session-Start Hook Integration

The session-start hook is simplified. On `/clear`:

```bash
# Check if JICM state file indicates compression was done
JICM_STATE_FILE="$CLAUDE_PROJECT_DIR/.claude/context/.jicm-state"
COMPRESSED_FILE="$CLAUDE_PROJECT_DIR/.claude/context/.compressed-context-ready.md"

if [[ -f "$JICM_STATE_FILE" ]] && grep -q "state: clearing\|state: restoring" "$JICM_STATE_FILE"; then
    # JICM-initiated /clear — inject compressed context
    if [[ -f "$COMPRESSED_FILE" ]]; then
        COMPRESSED_CONTENT=$(cat "$COMPRESSED_FILE")
        # Return via additionalContext
    fi
fi
```

**No `.idle-hands-active` flag needed.** The watcher handles resume directly. The hook just injects context.

---

## 6. Error Handling Philosophy

**Fail towards forced continuation of work.**

| Error | Response | Rationale |
|-------|----------|-----------|
| Compression agent crashes | Reset to WATCHING, native /compact handles | Agent will be spawned again next threshold hit |
| /clear doesn't reduce context | Retry once, then reset to WATCHING | Native auto-compact at ~85% is the safety net |
| Jarvis doesn't respond to restore | 8 retries over 2min, then leave at prompt | User will see the prompt and can type |
| Watcher script crashes | Auto-restart via tmux respawn | `respawn-on` tmux option or wrapper loop |
| tmux session lost | Watcher exits cleanly | No tmux = no Claude Code = nothing to monitor |
| State file corrupted | Delete and recreate in WATCHING state | State file is ephemeral, not precious |

---

## 7. Configuration

```bash
# Defaults (configurable via CLI args)
JICM_THRESHOLD=55       # Compression trigger percentage
POLL_INTERVAL=5          # Seconds between context checks
HALT_TIMEOUT=60          # Max seconds to wait for Jarvis to halt
COMPRESS_TIMEOUT=300     # Max seconds to wait for compression agent
CLEAR_TIMEOUT=60         # Max seconds to wait for /clear to take effect
RESTORE_TIMEOUT=120      # Max seconds of restore retries
RESTORE_RETRY_DELAY=15   # Seconds between restore retries
COOLDOWN_PERIOD=600      # Seconds to suppress re-trigger after failsafe
```

---

## 8. File Structure

```
.claude/scripts/
  jicm-watcher.sh        # NEW: Ground-up JICM watcher (~500 lines)
  launch-jarvis-tmux.sh   # MODIFIED: Launch new watcher instead of old

.claude/hooks/
  session-start.sh        # MODIFIED: Simplified JICM detection

.claude/agents/
  compression-agent.md    # EXISTING: Unchanged

.claude/context/
  .jicm-state             # NEW: Unified state file
  .compressed-context-ready.md   # EXISTING: Compressed context
  .compression-done.signal       # EXISTING: Agent completion signal

.claude/context/designs/
  jicm-v6-design.md              # This file
  jicm-v6-critical-analysis.md   # Critical analysis

.claude/logs/
  jicm-watcher.log        # Watcher log
  jicm/archive/            # Archived compressed contexts
```

---

*JICM v6 Ground-Up Design — Stop-and-Wait Architecture*
*Created: 2026-02-11*
