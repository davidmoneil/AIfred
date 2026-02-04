# Lesson: tmux Self-Injection Limitation

**Date Discovered**: 2026-02-04
**Category**: Infrastructure / Signal Architecture
**Severity**: Critical (affects JICM core functionality)
**Related**: JICM v5, jarvis-watcher.sh, command-signal-protocol

---

## The Problem

When Claude Code (Jarvis) attempts to send `tmux send-keys` signals to its own tmux session from within a Bash tool call, the prompt injection **fails unpredictably**.

### Observed Behavior

| Execution Context | Result |
|-------------------|--------|
| External terminal → Claude Code session | ✅ Works reliably |
| Bash tool in Claude Code → Same session | ❌ Fails, causes corruption |

### Symptoms of Self-Injection Failure

- Multiple `UserPromptSubmit` hook events fire unexpectedly
- Text appears in buffer but doesn't submit
- Process exits with signal 137 (SIGKILL from interrupt)
- Unpredictable keystroke ordering

---

## Root Cause Analysis

### The Self-Referential Loop Problem

Claude Code's architecture creates a conflict when attempting self-injection:

```
┌─────────────────────────────────────────────────────────────────┐
│ Claude Code Process (jarvis:0)                                   │
│                                                                  │
│  ┌─────────────────────────────────────────────────────┐        │
│  │ Bash Tool Execution (child process)                  │        │
│  │                                                      │        │
│  │   tmux send-keys -t jarvis:0 "text"                 │        │
│  │   tmux send-keys -t jarvis:0 C-m                    │        │
│  │         │                                            │        │
│  │         └──────────────────┐                        │        │
│  │                            │                        │        │
│  └────────────────────────────┼────────────────────────┘        │
│                               │                                  │
│                               ▼                                  │
│  ┌─────────────────────────────────────────────────────┐        │
│  │ Ink TUI (raw mode)                                   │        │
│  │                                                      │        │
│  │   Input Handler ◀─── Keystrokes arrive while         │        │
│  │   Event Loop         Bash tool is BLOCKED waiting    │        │
│  │                      for child process to complete   │        │
│  └─────────────────────────────────────────────────────┘        │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Three Compounding Issues

1. **Input State Collision**
   - Claude Code's Ink-based TUI maintains an input buffer state
   - When keystrokes arrive via `send-keys` while the TUI is processing a Bash command, input handling becomes non-deterministic
   - The TUI may be in a "busy" state that doesn't accept input normally

2. **Event Loop Interference**
   - The `send-keys` command injects keystrokes into tmux's input queue
   - Claude Code's event loop is blocked waiting for the Bash command to complete
   - Keystrokes queue up and may be processed in unexpected order when control returns

3. **Timing Race Conditions**
   - Script sleeps between sending text and CR occur in the child process (Bash script)
   - These sleeps do NOT affect tmux event delivery timing
   - Keystrokes may arrive at the TUI in rapid succession regardless of script-side timing

---

## The Solution: External Script Execution

For Jarvis to self-inject prompts, the signal must come from an **external process** that is not a child of the Claude Code process.

### Correct Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                  │
│  jarvis-watcher.sh (background)     Claude Code (jarvis:0)      │
│  ┌─────────────────────────┐        ┌─────────────────────────┐ │
│  │                         │        │                         │ │
│  │  External Process       │        │  At Idle Prompt (❯)     │ │
│  │  Not child of Claude    │        │  TUI ready to receive   │ │
│  │                         │        │                         │ │
│  │  tmux send-keys ────────┼───────▶│  Input Handler          │ │
│  │                         │        │  Processes keystrokes   │ │
│  └─────────────────────────┘        └─────────────────────────┘ │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Implementation Pattern

**WRONG**: Running send-keys from within Claude Code
```bash
# ❌ This runs as a child process of Claude Code
# The TUI is blocked waiting for this to complete
"$TMUX_BIN" send-keys -t jarvis:0 -l "prompt text"
"$TMUX_BIN" send-keys -t jarvis:0 C-m
```

**CORRECT**: External watcher sends signals
```bash
# ✅ jarvis-watcher.sh (background daemon, not Claude Code child)
# Claude Code TUI is at idle, ready to receive
"$TMUX_BIN" send-keys -t jarvis:0 -l "prompt text"
sleep 0.2
"$TMUX_BIN" send-keys -t jarvis:0 C-m
```

**CORRECT**: Fire-and-forget script launch
```bash
# ✅ If Claude Code MUST trigger injection, spawn detached process
nohup /path/to/injection-script.sh &>/dev/null &
# Script runs independently, Claude Code Bash tool returns immediately
```

---

## Design Implications

### For JICM

1. **Watcher-based injection is correct**: The jarvis-watcher runs externally and can send signals to an idle Claude Code session
2. **TUI must be idle**: Signal injection only works when Claude Code is at the prompt, not while processing
3. **No in-session self-injection**: Claude Code cannot reliably inject prompts into itself via Bash tools

### For Future Development

1. **Signal architecture depends on external watchers**: Any autonomous prompt injection must use the watcher pattern
2. **Detached process workaround exists**: If in-session triggering is needed, spawn a detached script that outlives the Bash tool call
3. **Test scripts must run externally**: When testing tmux submission methods, run from a separate terminal, not from within Claude Code

---

## Testing Validation

### Test Results (2026-02-03/04)

| Test | Execution Context | Result |
|------|-------------------|--------|
| test-submission-methods.sh | External terminal | ✅ Methods 1,2,5 work |
| Ad hoc Bash script | Within Claude Code | ❌ Fails (exit 137) |
| jarvis-watcher.sh | Background daemon | ✅ Expected to work |

### Working Submission Methods (External Only)

1. `send-keys C-m` — Standard Enter
2. `send-keys -l $'\r'` — Literal CR
5. `send-keys Enter` — tmux Enter key name

---

## Key Takeaway

> **For Jarvis to self-inject prompts, they must be sent by an external process (like jarvis-watcher.sh), not by a Bash tool running within the Claude Code session itself.**

This is a fundamental constraint of Claude Code's Ink-based TUI architecture and cannot be worked around within the session—only by using external processes.

---

*Lesson captured: 2026-02-04*
*Related documents: jicm-v5-design-addendum.md, command-signal-protocol.md*
