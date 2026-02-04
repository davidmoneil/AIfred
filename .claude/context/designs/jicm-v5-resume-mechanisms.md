# JICM v5 Resume Mechanisms — Deep Technical Redesign

**Date**: 2026-02-03
**Status**: Design Specification (supports jicm-v5-design-addendum.md)
**Purpose**: Solve the post-/clear "wake" problem with Ink-based TUI
**Authority**: This document provides implementation details for Section 7 of the v5 addendum

---

## Problem Statement

Claude Code uses **Ink** (React for CLIs), which puts stdin in **raw mode**. This fundamentally changes how input is processed:

| Normal Shell | Ink Raw Mode |
|--------------|--------------|
| Line discipline handles editing | App manages its own buffer |
| Enter = submit line | Enter = keypress event app must interpret |
| Kernel does CR↔LF translation | App sees raw bytes |
| `stty` settings apply | App toggles raw mode itself |

**The Core Issue**: Our `tmux send-keys C-m` may be delivering bytes that Ink doesn't interpret as "submit."

### Possible Failure Modes

1. **CR vs LF mismatch**: Enter arrives as `\r` but app checks for `\n` (or vice versa)
2. **Multi-line mode**: Enter = newline, submit = different chord (Ctrl+Enter, etc.)
3. **Bracketed paste**: tmux send-keys treated differently than typed input
4. **TTY state corruption**: After /clear, terminal state may be different

---

## Two-Mechanism Architecture

### Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                      POST-/CLEAR SEQUENCE                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  /clear sent                                                     │
│       │                                                          │
│       ▼                                                          │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │ MECHANISM 1: Session-Start Hook Injection                   ││
│  │   • Fires on SOURCE=clear                                   ││
│  │   • Checks for JICM signal files                            ││
│  │   • Injects context via additionalContext                   ││
│  │   • Creates .idle-hands-active flag                         ││
│  │   • Returns resume prompt in output (if supported)          ││
│  └─────────────────────────────────────────────────────────────┘│
│       │                                                          │
│       │ Flag created: .idle-hands-active                        │
│       ▼                                                          │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │ MECHANISM 2: Idle-Hands Monitor (v1 — JICM Resume Mode)     ││
│  │   • Monitors: .idle-hands-active + tmux pane idle state     ││
│  │   • Cycles through submission method variants               ││
│  │   • Detects success via pane content change                 ││
│  │   • Cleans up on success, keeps trying on failure           ││
│  └─────────────────────────────────────────────────────────────┘│
│       │                                                          │
│       ▼                                                          │
│  Jarvis Active (cleanup + resume normal monitoring)              │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## Mechanism 1: Session-Start Hook Injection

### Purpose

Inject context into Jarvis's fresh context window via Claude Code's hook system. This is the **reliable** part — `additionalContext` always works.

### What It Does

1. **Detects JICM context**: Checks for `.clear-sent.signal` and context files
2. **Injects context**: Reads `.compressed-context-ready.md` and `.in-progress-ready.md`, returns via `additionalContext`
3. **Sets idle-hands flag**: Creates `.idle-hands-active` with metadata
4. **Does NOT rely on prompt submission**: Hook can inject but cannot force response

### Flag File Specification

**File**: `.claude/context/.idle-hands-active`

```yaml
mode: jicm_resume
created: 2026-02-03T15:30:00Z
context_files:
  - .compressed-context-ready.md
  - .in-progress-ready.md
submission_attempts: 0
last_attempt: null
success: false
```

### Compression Agent Data Sources

The compression agent assembles context from multiple sources (see jicm-v5-design-addendum.md Section 8 for full details):

**Transcript Sources** (ephemeral):
- `~/.claude/projects/.../[session-id].jsonl` — main conversation
- `~/.claude/projects/.../subagents/*.jsonl` — subagent logs
- `.claude/context/.context-captured*.txt` — pre-processed captures

**Foundation Docs** (durable):
- `.claude/CLAUDE.md` — project instructions
- `.claude/jarvis-identity.md` — identity and tone
- `.claude/context/compaction-essentials.md` — must-preserve items

**Session State** (durable, read-only):
- `.claude/context/session-state.md` — current work status
- `.claude/context/current-priorities.md` — task backlog

The agent scans all sources, keeps what matters, consolidates, organizes, clarifies, and simplifies. **Target output: 10k-30k tokens** (see addendum Section 8.5).

### Hook Implementation (session-start.sh changes)

```bash
# In handle_jicm_resume() function:

# After injecting context...
create_idle_hands_flag() {
    cat > "$PROJECT_DIR/.claude/context/.idle-hands-active" << EOF
mode: jicm_resume
created: $(date -u +%Y-%m-%dT%H:%M:%SZ)
context_files:
  - .compressed-context-ready.md
  - .in-progress-ready.md
submission_attempts: 0
last_attempt: null
success: false
EOF
    log "Created .idle-hands-active flag for Mechanism 2"
}
```

---

## Mechanism 2: Idle-Hands Monitor (v1)

### Purpose

Actively attempt to submit prompts to wake Jarvis, using multiple submission method variants to overcome Ink raw-mode challenges.

### Monitoring (Detection)

**Trigger Conditions** (ALL must be true):
1. `.idle-hands-active` file exists
2. File contains `mode: jicm_resume`
3. tmux pane shows idle state (prompt visible, no spinner)

**Idle State Detection** (tmux pane parsing):
```bash
detect_idle_state() {
    local pane_content
    pane_content=$("$TMUX_BIN" capture-pane -t "$TMUX_TARGET" -p)

    # Active indicators (NOT idle)
    if echo "$pane_content" | grep -qE '⠋|⠙|⠹|⠸|⠼|⠴|⠦|⠧|⠇|⠏'; then
        return 1  # Spinner = working
    fi

    # Check for prompt without recent output
    # Claude Code prompt typically ends with "❯ " or similar
    if echo "$pane_content" | tail -5 | grep -qE '❯\s*$|>\s*$'; then
        # Prompt visible, check if there's recent substantive output
        local last_lines=$(echo "$pane_content" | tail -10)
        if echo "$last_lines" | grep -qE 'Context restored|Continuing|Reading|Writing'; then
            return 1  # Jarvis responded = not idle
        fi
        return 0  # Idle
    fi

    return 1  # Unknown state, assume not idle
}
```

### Submission Methods (The Critical Part)

**CRITICAL CONSTRAINT (validated 2026-02-04)**: Submission MUST be a **separate tmux send-keys call** from the prompt text. Embedding CR/LF in the same `-l` string as the text causes the CR to be treated as a literal character, not a submission trigger.

See: `lessons/tmux-self-injection-limitation.md` for full analysis.

#### Validated Method Matrix

| # | Method | tmux Command | Status | Notes |
|---|--------|--------------|--------|-------|
| 1 | Standard C-m | `send-keys C-m` | **✅ WORKS** | Primary method |
| 2 | Enter key | `send-keys Enter` | **✅ WORKS** | Alternate method |
| 3 | Literal CR (separate) | `send-keys -l $'\r'` | **✅ WORKS** | When sent as own call |
| 4 | Literal LF | `send-keys -l $'\n'` | ❌ FAILS | |
| 5 | Literal CRLF | `send-keys -l $'\r\n'` | ❌ FAILS | |
| 6 | Escape + Enter | `send-keys Escape C-m` | ❌ FAILS | |
| 7 | Double Enter | `send-keys C-m C-m` | ❌ FAILS | |

#### Failed Patterns (DO NOT USE)

| Pattern | tmux Command | Why It Fails |
|---------|--------------|--------------|
| Embedded CR in text | `send-keys -l "text"$'\r'` | CR treated as literal char |
| Variable with CR | `TEXT="prompt"$'\r'; send-keys -l "$TEXT"` | Same issue |

#### Canonical Pattern (ALWAYS USE)

```bash
# Step 1: Send text (literal)
"$TMUX_BIN" send-keys -t "$TMUX_TARGET" -l "prompt text"

# Step 2: Send submit as SEPARATE call (key event)
"$TMUX_BIN" send-keys -t "$TMUX_TARGET" C-m   # or Enter
```

#### Prompt Text Variants

| # | Prompt | Purpose |
|---|--------|---------|
| A | Full resume prompt | Detailed instructions with file paths |
| B | Simple continue | "Continue your work." |
| C | Minimal trigger | "." |

#### Submission Cycle (Updated 2026-02-04)

Only validated working methods are used. The cycle tries different method+prompt combinations on retry.

```bash
# ONLY validated working methods
SUBMISSION_METHODS=(
    "C-m"      # 1: Primary - Standard Enter (key event)
    "Enter"    # 2: Alternate - tmux Enter key name
    "-l_CR"    # 3: Fallback - Literal CR as separate call
)

SUBMISSION_PROMPTS=(
    "RESUME"   # A: Full resume prompt with file paths
    "SIMPLE"   # B: Simple directive
    "MINIMAL"  # C: Minimal dot
)

VARIANT_INDEX=0

submit_with_variant() {
    local variant=$VARIANT_INDEX
    local method_idx=$((variant % ${#SUBMISSION_METHODS[@]}))
    local prompt_idx=$((variant / ${#SUBMISSION_METHODS[@]} % ${#SUBMISSION_PROMPTS[@]}))
    local prompt_type="${SUBMISSION_PROMPTS[$prompt_idx]}"

    log "Attempting submission: method=$((method_idx + 1)) prompt=$prompt_type"

    # STEP 1: Send prompt text (always send text, never empty)
    case "$prompt_type" in
        RESUME) "$TMUX_BIN" send-keys -t "$TMUX_TARGET" -l "$FULL_RESUME_PROMPT" ;;
        SIMPLE) "$TMUX_BIN" send-keys -t "$TMUX_TARGET" -l "Continue your work." ;;
        MINIMAL) "$TMUX_BIN" send-keys -t "$TMUX_TARGET" -l "." ;;
    esac

    sleep 0.1  # Brief pause (optional but safe)

    # STEP 2: Send submit as SEPARATE call (CRITICAL)
    case $method_idx in
        0) "$TMUX_BIN" send-keys -t "$TMUX_TARGET" C-m ;;
        1) "$TMUX_BIN" send-keys -t "$TMUX_TARGET" Enter ;;
        2) "$TMUX_BIN" send-keys -t "$TMUX_TARGET" -l $'\r' ;;  # Separate call = works
    esac

    # Advance to next variant for next attempt
    VARIANT_INDEX=$(( (VARIANT_INDEX + 1) % (${#SUBMISSION_METHODS[@]} * ${#SUBMISSION_PROMPTS[@]}) ))
}
```

**Note**: The sleep between text and submit is OPTIONAL. Testing confirmed both with-sleep and without-sleep patterns work. The critical factor is that submit is a SEPARATE send-keys call.

### Prompt Text Content

```bash
FULL_RESUME_PROMPT='JICM CONTEXT RESTORED

Your context was compressed and cleared. Resume your work:
1. Read .claude/context/.compressed-context-ready.md
2. Read .claude/context/.in-progress-ready.md

Continue immediately. Do not greet or ask questions.'
```

### Success Detection

```bash
detect_submission_success() {
    sleep 3  # Give Claude Code time to process

    local pane_content
    pane_content=$("$TMUX_BIN" capture-pane -t "$TMUX_TARGET" -p)

    # Check for active work indicators
    # Spinner
    if echo "$pane_content" | grep -qE '⠋|⠙|⠹|⠸|⠼|⠴|⠦|⠧|⠇|⠏'; then
        return 0  # Success - Jarvis is working
    fi

    # Response text indicating wake-up
    if echo "$pane_content" | grep -qiE 'context restored|continuing|reading|understood|resuming'; then
        return 0  # Success - Jarvis responded
    fi

    # Token count increasing (if we can detect)
    # This would require parsing statusline output

    return 1  # Not yet successful
}
```

### Main Loop

```bash
idle_hands_jicm_resume() {
    local flag_file="$PROJECT_DIR/.claude/context/.idle-hands-active"
    local max_cycles=50       # ~10 minutes of attempts (50 * 12s)
    local cycle_delay=12      # Seconds between attempts
    local cycle=0

    while [[ $cycle -lt $max_cycles ]]; do
        # Check if flag still exists (might be cleaned up on success)
        if [[ ! -f "$flag_file" ]]; then
            log "IDLE-HANDS: Flag removed, assuming success"
            return 0
        fi

        # Check if already successful
        if grep -q "success: true" "$flag_file" 2>/dev/null; then
            log "IDLE-HANDS: Already marked successful"
            cleanup_jicm_files
            return 0
        fi

        # Check idle state
        if detect_idle_state; then
            log "IDLE-HANDS: Jarvis idle, attempting submission (cycle $cycle)"

            # Update attempt count in flag file
            update_flag_attempts "$flag_file" $cycle

            # Try submission
            submit_with_variant

            # Check if it worked
            if detect_submission_success; then
                log "IDLE-HANDS: SUCCESS - Jarvis is awake!"
                mark_flag_success "$flag_file"
                cleanup_jicm_files
                return 0
            fi
        else
            log "IDLE-HANDS: Jarvis appears active, checking..."
            if detect_submission_success; then
                log "IDLE-HANDS: Confirmed active"
                mark_flag_success "$flag_file"
                cleanup_jicm_files
                return 0
            fi
        fi

        ((cycle++))
        sleep $cycle_delay
    done

    log "IDLE-HANDS: Max cycles reached without success"
    # Don't remove flag - leave for debugging
    return 1
}
```

---

## Idle-Hands Mode Architecture

The `.idle-hands-active` flag supports multiple modes. The mode determines behavior.

### Mode System

```bash
# In watcher main loop:
IDLE_HANDS_FLAG="$PROJECT_DIR/.claude/context/.idle-hands-active"

check_idle_hands() {
    if [[ ! -f "$IDLE_HANDS_FLAG" ]]; then
        return 1  # No flag, idle-hands not active
    fi

    local mode
    mode=$(grep "^mode:" "$IDLE_HANDS_FLAG" | cut -d: -f2 | tr -d ' ')

    case "$mode" in
        jicm_resume)
            idle_hands_jicm_resume
            ;;
        long_idle)
            idle_hands_background_tasks  # Future
            ;;
        workflow_chain)
            idle_hands_next_workflow     # Future
            ;;
        unsubmitted_text)
            idle_hands_submit_buffer     # Future
            ;;
        *)
            log "IDLE-HANDS: Unknown mode '$mode'"
            ;;
    esac
}
```

### Available Modes

| Mode | Status | Trigger | Behavior |
|------|--------|---------|----------|
| `jicm_resume` | **Implemented** | Post-/clear + JICM signals | Aggressive wake attempts |
| `long_idle` | Future | 60+ min no activity | Trigger /maintenance → /reflect → /evolve |
| `workflow_chain` | Future | Post-workflow complete | Trigger next workflow in chain |
| `unsubmitted_text` | Future | Text in buffer | Send Enter to submit |

### Mode Lifecycle

```
┌─────────────────────────────────────────────────────────────┐
│ 1. Something creates .idle-hands-active with mode: X        │
│    (hook, watcher, or workflow completion)                  │
├─────────────────────────────────────────────────────────────┤
│ 2. Watcher detects flag, reads mode                         │
├─────────────────────────────────────────────────────────────┤
│ 3. Mode handler runs (e.g., idle_hands_jicm_resume)         │
│    - Monitors for idle state                                │
│    - Takes mode-specific action                             │
│    - Detects success                                        │
├─────────────────────────────────────────────────────────────┤
│ 4. On success: Handler marks flag success=true, cleans up   │
│    On continued failure: Handler keeps trying               │
└─────────────────────────────────────────────────────────────┘
```

---

## Technical Deep Dive: Solving the Submit Problem

### Investigation Steps

Before implementing, we should empirically test which submission method works:

#### Test Script

```bash
#!/bin/bash
# test-submission-methods.sh
# Run this while Claude Code is at an idle prompt

TMUX_TARGET="jarvis:0"
TMUX_BIN="$HOME/bin/tmux"

methods=(
    "C-m"
    "-l \$'\\r'"
    "-l \$'\\n'"
    "-l \$'\\r\\n'"
    "Enter"
)

for method in "${methods[@]}"; do
    echo "Testing: send-keys $method"

    # Send test text
    $TMUX_BIN send-keys -t "$TMUX_TARGET" -l "test-$method"
    sleep 0.5

    # Try submission method
    eval "$TMUX_BIN send-keys -t '$TMUX_TARGET' $method"

    sleep 3
    echo "Check if prompt was submitted..."
    read -p "Did it work? (y/n): " result

    if [[ "$result" == "y" ]]; then
        echo "SUCCESS: Method '$method' works!"
        exit 0
    fi

    echo "---"
    sleep 2
done

echo "No method worked automatically"
```

### Alternative: PTY-Level Injection

If tmux send-keys proves unreliable, consider `expect` or `script`:

```bash
# Using expect (if installed)
expect << 'EOF'
spawn -noecho cat
send "test prompt\r"
EOF

# Or using Python's pexpect
python3 << 'EOF'
import pexpect
child = pexpect.spawn('claude')
child.sendline('test prompt')
EOF
```

### Alternative: Claude Code Input Config

Check if Claude Code has input settings:

```bash
# Possible config locations
~/.claude/config.json
~/.claude/settings.json
~/.config/claude/config.json

# Look for settings like:
# "inputMode": "singleLine" vs "multiLine"
# "submitOnEnter": true/false
# "submitKey": "Enter" vs "Ctrl+Enter"
```

---

## Implementation Checklist

### Phase 1: Hook Changes (Mechanism 1)

- [ ] Modify `session-start.sh` to create `.idle-hands-active` flag
- [ ] Add flag file format with mode, timestamps, attempt tracking
- [ ] Ensure context injection still works via `additionalContext`

### Phase 2: Watcher Changes (Mechanism 2)

- [ ] Add idle-hands monitoring loop to watcher
- [ ] Implement `detect_idle_state()` function
- [ ] Implement submission method variants
- [ ] Implement `detect_submission_success()` function
- [ ] Add flag file management (read/update/cleanup)

### Phase 3: Testing

- [ ] Run test script to determine which submission method works
- [ ] Test full JICM cycle with new mechanisms
- [ ] Verify cleanup happens correctly on success
- [ ] Test failure modes and recovery

### Phase 4: Documentation

- [ ] Update jicm-v5-design-addendum.md with final mechanism design
- [ ] Document which submission method works (for future reference)
- [ ] Add troubleshooting guide for submission failures

---

## Appendix: tmux send-keys Reference

### Key Representations

| Key | tmux | Hex Bytes | Notes |
|-----|------|-----------|-------|
| Enter | `Enter` | varies | tmux interprets |
| Ctrl+M | `C-m` | `0x0D` (CR) | Same as Enter on most systems |
| Literal CR | `-l $'\r'` | `0x0D` | Bypass tmux interpretation |
| Literal LF | `-l $'\n'` | `0x0A` | Unix newline |
| Literal CRLF | `-l $'\r\n'` | `0x0D 0x0A` | DOS newline |
| Escape | `Escape` | `0x1B` | Clear pending modes |

### The `-l` Flag

`-l` (literal) tells tmux to send the exact characters without interpretation:
- Without `-l`: `send-keys C-m` sends Ctrl+M key event
- With `-l`: `send-keys -l "C-m"` sends literal "C-m" text

For raw bytes, use shell quoting: `send-keys -l $'\r'`

---

**Document Status**: Implementation complete, submission methods fully validated
**See Also**:
- `jicm-v5-design-addendum.md` (authoritative specification, Section 10)
- `lessons/tmux-self-injection-limitation.md` (external execution requirement)

---

## Verified Submission Methods (Full Test Results)

### Initial Testing (2026-02-03)

Method 1 (`C-m`), Method 2 (`-l $'\r'`), and Method 5 (`Enter`) confirmed working.
Methods 3 (`-l $'\n'`), 4 (`-l $'\r\n'`), 6 (`Escape C-m`), 7 (`C-m C-m`) confirmed FAILED.

### Hypothesis Testing (2026-02-04)

Additional testing to understand WHY some patterns fail:

| Hypothesis | Pattern | Result |
|------------|---------|--------|
| A | Separate calls (text → sleep → C-m) | ✅ WORKS |
| B | Combined literal (`-l "text"$'\r'`) | ❌ FAILS |
| C | Combined args (text → immediate C-m) | ✅ WORKS |
| D | Variable with CR (`-l "$VAR"` where VAR has `\r`) | ❌ FAILS |
| E | No sleep (text → C-m immediate) | ✅ WORKS |
| F | Enter key name | ✅ WORKS |

### Root Cause

The `-l` flag makes everything literal. When CR is embedded in the same `-l` argument as text, it's treated as a typed character, not a submission trigger. The submit signal MUST be a separate tmux key event.

### Canonical Pattern

```bash
# ✅ CORRECT: Separate calls, key event for submit
"$TMUX_BIN" send-keys -t "$TMUX_TARGET" -l "prompt text"
"$TMUX_BIN" send-keys -t "$TMUX_TARGET" C-m   # or Enter

# ❌ WRONG: CR embedded in literal
"$TMUX_BIN" send-keys -t "$TMUX_TARGET" -l "prompt text"$'\r'
```

### External Execution Requirement

**CRITICAL**: Prompt injection ONLY works from external processes. Attempting to run `tmux send-keys` from within Claude Code (via Bash tool) to the same Claude Code session causes unpredictable failures due to TUI event loop blocking.

Valid external sources:
- `jarvis-watcher.sh` (background daemon)
- External terminal
- Fire-and-forget detached scripts (`nohup script.sh &`)

Invalid self-referential sources:
- Bash tool within Claude Code session

See `lessons/tmux-self-injection-limitation.md` for full analysis.

---

*JICM v5 Resume Mechanisms — Created 2026-02-03 | Fully Validated 2026-02-04*
