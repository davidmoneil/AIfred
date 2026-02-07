# JICM v5 Design Addendum

**Date**: 2026-02-01
**Status**: Design Specification (Pre-Implementation)
**Source**: Synthesized from jicm-v5-clarifications.md (22 clarifications)
**Purpose**: Comprehensive technical specification for JICM v5 implementation

---

## Executive Summary

JICM (Jarvis Intelligent Context Management) is a **mid-session context preservation and restoration system**. It is NOT a session boundary system. This distinction is fundamental to the architecture.

**Core Mission**: When Claude Code's context window approaches capacity, JICM compresses the conversation context, triggers a `/clear`, and automatically restores Jarvis to an active working state — all without user intervention.

**Design Philosophy**: "Do or die" — no fallbacks, no silent failures, no giving up. Each stage completes successfully or retries until success.

**Key Architectural Insight**: The session-start hook can inject context but CANNOT force Jarvis to respond. Therefore, JICM requires BOTH context injection (via hook) AND prompt injection (via watcher) to complete the resume cycle.

---

## Table of Contents

1. [Identity Architecture](#1-identity-architecture)
2. [Trigger System](#2-trigger-system)
3. [File Lifecycle](#3-file-lifecycle)
4. [Separation of Concerns](#4-separation-of-concerns)
5. [User Experience](#5-user-experience)
6. [Idle Detection System](#6-idle-detection-system)
7. [Resume Architecture](#7-resume-architecture)
8. [Data Sources](#8-data-sources)
9. [Complete Flow Specification](#9-complete-flow-specification)

---

## 1. Identity Architecture

### 1.1 The Two Agents

JICM involves two distinct agents with separate responsibilities. Conflating them causes architectural errors.

| Agent | Identity | Context | Lifecycle | Needs CONTINUE Signals |
|-------|----------|---------|-----------|------------------------|
| **Jarvis** | Main agent | In Claude Code window | Persists across session, cleared by `/clear` | **YES** — must be prompted to work |
| **Compression Agent** | Spawned subagent | Isolated subprocess | Spawns, executes, terminates | **NO** — runs to completion |

### 1.2 Jarvis (Main Agent)

**Definition**: The primary Claude Code agent that interacts with the user, executes commands, and maintains working state.

**Characteristics**:
- Lives in the Claude Code terminal window
- Context window fills over time
- Must receive prompts/signals to begin or resume work
- Subject to `/clear` — context window is wiped
- Needs to be "reawakened" after `/clear`
- Creates: `.in-progress-ready.md` (when interrupted)

**Key Insight**: Jarvis is the patient, not the doctor. JICM operates ON Jarvis, not BY Jarvis (except for the initial trigger).

### 1.3 Compression Agent (Subagent)

**Definition**: A specialized subagent spawned to perform context compression. Runs in isolation, writes output file, terminates.

**Characteristics**:
- Spawned via Task tool with `subagent_type: context-compressor`
- Receives conversation context as input
- Runs independently of Jarvis (background)
- Does NOT need CONTINUE signals — executes to completion
- Creates: `.compressed-context-ready.md`
- Terminates when done — does not persist

**Key Insight**: The compression agent is fire-and-forget. Spawn it, let it work, wait for its output file.

### 1.4 Responsibility Matrix

| Responsibility | Jarvis | Compression Agent | Watcher |
|----------------|--------|-------------------|---------|
| Trigger `/intelligent-compress` | ✓ (executes) | | ✓ (sends command) |
| Spawn compression agent | ✓ | | |
| Compress context | | ✓ | |
| Create `.compressed-context-ready.md` | | ✓ | |
| Continue working during compression | ✓ | | |
| Create `.in-progress-ready.md` | ✓ (when interrupted) | | |
| Detect compression complete | | | ✓ |
| Send `/clear` | | | ✓ |
| Send CONTINUE/resume prompts | | | ✓ |
| Resume work | ✓ | | |
| Clean up signal files | | | ✓ (after confirmed resume) |

---

## 2. Trigger System

### 2.1 Fundamental Principle

**Signal files are the triggers, NOT `/clear`.**

`/clear` is a native Claude Code command. Users should be able to use it at any time with no side effects. JICM never hooks on `/clear` itself — it uses signal files to indicate that JICM orchestrated the workflow.

### 2.2 Context Window Usage Threshold

**Terminology Correction**: The watcher monitors **context window USAGE** (how full the context window is), not "context compression threshold."

| Term | Correct Usage |
|------|---------------|
| Context window USAGE | How much of the context window is filled |
| Threshold | Percentage of usage that triggers action |
| Compression | What happens AFTER threshold detected |

**Detection Mechanism**: Watcher polls context usage percentage via parsing the Claude Code status line or token count estimation from context cache.

**Single Threshold**:

| Setting | Default | Purpose |
|---------|---------|---------|
| Threshold | **50%** | Trigger `/intelligent-compress` |

**Rationale**: A 50% threshold provides ample room for compression to complete before context becomes critically full. This gives the compression agent time to work without racing against context exhaustion.

### 2.3 Unified Entry Point

All JICM compression flows enter via `/intelligent-compress`. This creates a single flow to build, test, and maintain.

| Trigger Source | Entry Point | Behavior |
|----------------|-------------|----------|
| Watcher (threshold) | `/intelligent-compress` | Identical |
| User (manual) | `/intelligent-compress` | Identical |

**Benefit**: User can trust that manual invocation behaves identically to automatic triggering. One flow, one test surface.

### 2.4 Signal Files as State Machine

JICM uses signal files to communicate state between components. Each file represents a state transition.

```
[Threshold Hit]
      │
      ▼
┌─────────────────────┐
│ .compression-done   │ ◀── Created by: Compression Agent (when finished)
│      .signal        │     Indicates: Context is compressed and ready
└─────────────────────┘
      │
      ▼
┌─────────────────────┐
│ .clear-sent         │ ◀── Created by: Watcher (when sending /clear)
│      .signal        │     Indicates: /clear command was sent
└─────────────────────┘
      │
      ▼
┌─────────────────────┐
│ .continuation       │ ◀── Created by: sessionRestart hook
│ -injected.signal    │     Indicates: Context was injected
└─────────────────────┘
      │
      ▼
┌─────────────────────┐
│ .jicm-complete      │ ◀── Created by: sessionRestart hook
│      .signal        │     Indicates: JICM cycle complete, cleanup pending
└─────────────────────┘
```

### 2.5 What `/clear` Does NOT Trigger

| Action | Triggered by `/clear`? |
|--------|------------------------|
| Context injection | **NO** — triggered by signal files |
| Greeting | **NO** — never after `/clear` |
| sessionStart protocol | **NO** — `/clear` is mid-session |
| File deletion | **NO** — files persist through `/clear` |

---

## 3. File Lifecycle

### 3.1 File Categories

JICM uses two categories of files with different purposes:

**Context Files** (contain data for restoration):
- `.compressed-context-ready.md` — Intelligently condensed context window content
- `.in-progress-ready.md` — Addendum with very recent work during compression

**Signal Files** (indicate state transitions):
- `.compression-done.signal` — Compression agent finished
- `.clear-sent.signal` — Watcher sent `/clear`
- `.continuation-injected.signal` — Context was injected
- `.jicm-complete.signal` — Cycle complete, ready for cleanup

### 3.2 Complete File Specification

| File | Full Path | Created By | Contains | Deleted When |
|------|-----------|------------|----------|--------------|
| `.compressed-context-ready.md` | `.claude/context/` | Compression Agent | Condensed context | After Jarvis confirmed working |
| `.in-progress-ready.md` | `.claude/context/` | Jarvis | Recent work addendum | After Jarvis confirmed working |
| `.compression-done.signal` | `.claude/context/` | Compression Agent | Timestamp | After context injection |
| `.clear-sent.signal` | `.claude/context/` | Watcher | Timestamp | After Jarvis confirmed working |
| `.continuation-injected.signal` | `.claude/context/` | session-start hook | Timestamp | After Jarvis confirmed working |
| `.jicm-complete.signal` | `.claude/context/` | Watcher | Timestamp | After cleanup complete |
| `.jicm-in-progress.lock` | `.claude/context/` | Watcher | Timestamp + state | After JICM cycle complete |
| `.idle-hands-active` | `.claude/context/` | session-start hook | Mode, timestamps, attempts | After Jarvis confirmed working |

### 3.3 File Persistence Rules

**Critical Principle**: Files PERSIST through `/clear`. The `/clear` command clears Jarvis's CONTEXT WINDOW (memory), NOT files on disk.

**Correct Sequence**:
```
1. Files CREATED (context files + signal files)
2. /clear sent → clears context window, files UNTOUCHED
3. sessionRestart READS files → injects content
4. Jarvis resumes work
5. THEN delete files (one-time use, prevents stale files)
```

**Why This Matters**: If files were deleted at `/clear`, there would be nothing to inject for context restoration. The files must survive `/clear` to serve their purpose.

### 3.4 Deletion Timing Specification

| Phase | Files That Can Be Deleted |
|-------|---------------------------|
| Immediately after `/clear` | NONE |
| After context injection | `.compression-done.signal` only |
| After Jarvis confirmed working | ALL remaining files |

**"Confirmed Working" Definition**: Jarvis is actively generating output, spinner visible, or has completed a substantive response. NOT just a prompt visible.

### 3.5 Relationship Between Context Files

`.in-progress-ready.md` is an **addendum** to `.compressed-context-ready.md`:

| File | Contains | Timeframe |
|------|----------|-----------|
| `.compressed-context-ready.md` | Historical context, decisions, work | Everything up to compression start |
| `.in-progress-ready.md` | Work done while compression ran | Compression duration only |

**Why Two Files**: Compression takes time. Jarvis continues working during compression. The addendum captures that gap.

---

## 4. Separation of Concerns

### 4.1 Session Boundaries vs JICM Restarts

This is the most critical architectural distinction. These are DIFFERENT systems with DIFFERENT purposes.

| Aspect | Session Boundaries | JICM Restarts |
|--------|-------------------|---------------|
| **When** | User starts/ends Claude Code | Mid-session, context threshold |
| **Trigger** | sessionStart/sessionEnd hooks | Signal files present after `/clear` |
| **Purpose** | Orientation to project | Restore working memory |
| **Files Used** | `session-state.md`, `current-priorities.md` | `.compressed-context-ready.md`, `.in-progress-ready.md` |
| **Greeting** | Yes (sessionStart) | **Never** |
| **AIfred Sync** | Yes (sessionStart) | **Never** |
| **Await Instructions** | Yes (sessionStart) | **Never** |
| **Post-Action** | Ready for user direction | Immediately resume work |

### 4.2 What JICM Does NOT Update

JICM does not WRITE to session documentation files (that's sessionEnd's job):

| File | Domain | JICM Interaction |
|------|--------|------------------|
| `session-state.md` | sessionEnd | **READ only** (compression agent) |
| `current-priorities.md` | sessionEnd | **READ only** (compression agent) |
| `memory/` directory | sessionEnd | **NONE** |

**Clarification**: The compression agent READS session docs to understand current work context, but never WRITES to them. Reading ≠ Writing. Session documentation updates remain sessionEnd's responsibility.

**Rationale**: Session documentation files describe "what is this project about?" (ORIENTATION). JICM preserves "what was I thinking/doing?" (MEMORY). The compression agent reads both to build a complete picture.

### 4.3 Native Commands Remain Native

| Command | JICM Behavior |
|---------|---------------|
| `/clear` | Do nothing special — check for signal files |
| `/compact` | Do nothing — let native auto-compact work |
| `/auto-compact` | Do nothing — native behavior |

**Implementation**: sessionStart hook checks for JICM signal files:
- If present → inject context, send CONTINUE
- If NOT present → do nothing (native behavior)

This preserves the user's ability to use native commands without JICM interference.

### 4.4 Hook Source Handling

The session-start hook receives a `SOURCE` parameter. JICM simplifies handling:

| SOURCE | Interpretation | Action |
|--------|----------------|--------|
| `startup` | True session start | Full sessionStart protocol |
| `resume` | Abbreviated session start | Abbreviated sessionStart |
| `clear` | Check signal files | If JICM signals: inject context; else: nothing |
| `compact` | Native behavior | **Nothing** — let auto-compact work |

### 4.5 Terminology: sessionStart vs sessionRestart

These terms have specific meanings:

| Term | Meaning | When |
|------|---------|------|
| **sessionStart** | True session beginning protocol | User launches Claude Code |
| **sessionRestart** | JICM context restoration | Post-/clear when JICM signals present |
| **session-start hook** | The hook file (`.claude/hooks/session-start.sh`) | Fires on all session starts |

The **session-start hook** handles BOTH sessionStart and sessionRestart by checking for JICM signal files:
- No signals → sessionStart protocol (greeting, AIfred sync, etc.)
- JICM signals present → sessionRestart protocol (inject context, no greeting)

---

## 5. User Experience

### 5.1 Transparent, Not Invisible

**Incorrect framing**: "JICM should be invisible — user shouldn't notice."

**Correct framing**: JICM should be **transparent** — user knows what's happening but doesn't need to do anything.

| Characteristic | Meaning |
|----------------|---------|
| **Autonomic** | Happens on its own when conditions arise |
| **Automatic** | Jarvis ends in actively working state, not idle |
| **Light-weight** | Not heavy or disruptive |
| **Informative** | Tell user what's happening and why |
| **Seamless** | Pick right back up without idling/waiting/questioning |

### 5.2 Informative Messaging

**Pre-compression**:
```
"Context window at 50%, sir. Initiating compression..."
```

**Post-restoration**:
```
"Context restored. Continuing with the watcher refactoring..."
[immediately resumes work]
```

**What user experiences**:
1. Sees notification that compression is happening
2. Brief pause
3. Sees context restored message
4. Jarvis immediately continues previous work

User KNOWS it happened. User is INFORMED. User didn't have to DO anything.

### 5.3 Post-/clear Behavior

**There is NO greeting after `/clear`. Ever.**

| Scenario | Post-/clear Behavior |
|----------|---------------------|
| JICM-triggered `/clear` | Status update, immediately continue work |
| User-triggered `/clear` | Native behavior (fresh prompt) |

**JICM Post-/clear Sequence**:
1. Hook injects context from files (via `additionalContext`)
2. Watcher sends resume prompt (via tmux send-keys)
3. Jarvis outputs: "Context restored. Continuing [task]..."
4. Jarvis IMMEDIATELY resumes in-progress work

**Prohibited behaviors**:
- ❌ Greeting ("Good morning, sir...")
- ❌ Pausing ("How can I help?")
- ❌ Awaiting instructions
- ❌ Asking questions about what to do next

---

## 6. Idle-Hands System

### 6.1 Overview

**Idle-hands** is a unified monitoring subsystem in the watcher that detects idle states and takes appropriate action. It uses a **mode-based architecture** where different modes handle different idle scenarios.

```
┌─────────────────────────────────────────────────────────────┐
│                    IDLE-HANDS SYSTEM                         │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌─────────────────────────────────────────────────────┐    │
│  │ Mode Selector (based on .idle-hands-active flag)    │    │
│  └─────────────────────────────────────────────────────┘    │
│           │                                                  │
│     ┌─────┴─────┬──────────────┬──────────────┐             │
│     ▼           ▼              ▼              ▼             │
│  ┌──────┐  ┌──────────┐  ┌───────────┐  ┌──────────┐       │
│  │jicm_ │  │long_     │  │workflow_  │  │unsubmit- │       │
│  │resume│  │idle      │  │chain      │  │ted_text  │       │
│  │      │  │(future)  │  │(future)   │  │(future)  │       │
│  └──────┘  └──────────┘  └───────────┘  └──────────┘       │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### 6.2 Relationship to Session Detection

**Important Distinction**: Idle-hands is SEPARATE from fresh session detection.

| System | Trigger | Purpose |
|--------|---------|---------|
| **Fresh Session Detection** | User launches Claude Code | Trigger sessionStart protocol |
| **Idle-Hands** | Flag file + idle state | Handle various idle scenarios |

Fresh session detection looks for Claude Code banner without command traces. It triggers the sessionStart greeting/AIfred sync flow. This is NOT part of idle-hands.

### 6.3 The `.idle-hands-active` Flag

Idle-hands activates when this flag file exists:

**File**: `.claude/context/.idle-hands-active`

```yaml
mode: jicm_resume              # Which mode to run
created: 2026-02-03T15:30:00Z  # When flag was created
context_files:                  # Mode-specific data
  - .compressed-context-ready.md
  - .in-progress-ready.md
submission_attempts: 0          # Tracking for retries
last_attempt: null
success: false
```

The **mode** field determines behavior:

| Mode | Trigger | Behavior |
|------|---------|----------|
| `jicm_resume` | Post-/clear + JICM context injection | Aggressive prompt submission until Jarvis wakes |
| `long_idle` | 60+ min no activity (future) | Trigger /maintenance → /reflect → /evolve |
| `workflow_chain` | Post-workflow complete (future) | Start next workflow in chain |
| `unsubmitted_text` | Text in buffer not submitted (future) | Send Enter to submit |

### 6.4 Mode: jicm_resume (Current Implementation)

**Purpose**: Wake Jarvis after JICM sends `/clear`

**Activation**:
- Created by session-start hook when it detects JICM signals
- Hook injects context, then creates flag for idle-hands to take over

**Behavior**:
1. Poll tmux pane for idle state (12-second intervals)
2. When idle detected, try submission method variant
3. Check for success (spinner or response text)
4. Cycle through method variants until success
5. Clean up flag and signal files on success

**Gating**: Only runs when flag exists with `mode: jicm_resume`

**Details**: See Section 7 (Resume Architecture) for submission method variants

### 6.4.1 Submission Pattern Requirements (ALL MODES)

**CRITICAL**: All idle-hands modes that submit prompts MUST adhere to the validated submission patterns. See Section 10 and `lessons/tmux-self-injection-limitation.md`.

**Canonical Pattern** (use for ALL modes):
```bash
# Step 1: Send text via literal flag
"$TMUX_BIN" send-keys -t "$TMUX_TARGET" -l "prompt text"

# Step 2: Send submit as SEPARATE call (key event)
"$TMUX_BIN" send-keys -t "$TMUX_TARGET" C-m   # or Enter
```

**NEVER embed CR/LF in the text string**:
```bash
# ❌ WRONG - CR treated as literal character, not submission
"$TMUX_BIN" send-keys -t "$TMUX_TARGET" -l "prompt text"$'\r'
```

### 6.4.2 Retry Strategy Variations

When a submission attempt fails, modes can employ variations:

| Variation | Description | Use Case |
|-----------|-------------|----------|
| **Method cycling** | Alternate between C-m, Enter, `-l $'\r'` | Handle edge cases |
| **Prompt escalation** | Full → Simple → Minimal | Reduce complexity on retry |
| **Timer escalation** | Increase delay between attempts | Back off if session busy |
| **Timer reduction** | Decrease delay for urgency | Aggressive wake-up |

**Current jicm_resume strategy**:
- 3 methods × 3 prompts = 9 variants
- 12-second base interval
- Max 50 cycles (~10 minutes)

**Possible future enhancements**:
- Exponential backoff on repeated failures
- Alternate C-m/Enter on consecutive attempts
- Adaptive timing based on time-of-day

### 6.5 Mode: long_idle (Future)

**Purpose**: Utilize extended idle time for background tasks

**Planned Activation**:
- Watcher detects 60+ minutes of no activity
- No JICM signals present
- Creates flag with `mode: long_idle`

**Planned Behavior**:
- Trigger /maintenance workflow
- After completion, trigger /reflect
- After completion, trigger /evolve
- Self-improvement cycle runs autonomously

**Submission Pattern**: MUST use canonical pattern (Section 6.4.1)
- Consider longer intervals between workflow triggers (e.g., 30s)
- Use SIMPLE or MINIMAL prompts to avoid overwhelming context

### 6.6 Mode: workflow_chain (Future)

**Purpose**: Chain workflows together without user intervention

**Planned Activation**:
- Workflow (maintenance/reflect/evolve) completes
- Previous workflow sets flag with next workflow in chain

**Planned Behavior**:
- Detect workflow completion
- Send prompt to start next workflow
- Continue until chain complete

**Submission Pattern**: MUST use canonical pattern (Section 6.4.1)
- Use descriptive prompts that name the next workflow
- Consider short delay after workflow completion before next trigger

### 6.7 Mode: unsubmitted_text (Future)

**Purpose**: Submit text that was typed but not sent

**Planned Activation**:
- Watcher detects text in input buffer
- Extended idle with unsubmitted content

**Planned Behavior**:
- Send Enter to submit the buffered text
- Single attempt, then clear mode

**Submission Pattern**: Simple — just send `C-m` or `Enter` (no text needed)
- No prompt text required (text already in buffer)
- Single submission method sufficient

### 6.8 Idle State Detection

All modes share the same idle detection logic:

```bash
detect_idle_state() {
    local pane_content
    pane_content=$("$TMUX_BIN" capture-pane -t "$TMUX_TARGET" -p)

    # Active indicators = NOT idle
    if echo "$pane_content" | grep -qE '⠋|⠙|⠹|⠸|⠼|⠴|⠦|⠧|⠇|⠏'; then
        return 1  # Spinner visible = working
    fi

    # Prompt visible without recent substantive output = idle
    if echo "$pane_content" | tail -5 | grep -qE '❯\s*$|>\s*$'; then
        local recent=$(echo "$pane_content" | tail -10)
        if echo "$recent" | grep -qE 'Context restored|Continuing|Reading|Writing'; then
            return 1  # Recent response = not idle
        fi
        return 0  # Idle
    fi

    return 1  # Unknown state, assume not idle
}
```

### 6.9 Fresh Session Detection (Separate System)

**Not part of idle-hands**, but documented here for completeness.

**Purpose**: Detect when user launches Claude Code and trigger sessionStart.

| Aspect | Specification |
|--------|---------------|
| **Trigger** | New Claude Code session started |
| **Detection** | tmux pane shows banner WITHOUT command traces |
| **Action** | Send "sessionStart" prompt |
| **Goal** | Jarvis autonomically begins greeting/AIfred sync |
| **Gating** | No `.idle-hands-active` flag, no JICM signals |

**tmux Detection Pattern**:
```
Claude Code banner visible
Version string visible
NO `❯ /clear` in pane history
NO command traces
```

This runs in the watcher's main loop, separate from the idle-hands mode system.

---

## 7. Resume Architecture

### 7.1 Design Philosophy

Resume is the most critical part of JICM. It's the difference between successful context restoration and a stalled session.

**Philosophy**: "Defibrillator, not suggestion." Keep trying until Jarvis is working.

**No standdown. No timeout. No giving up.**

### 7.2 The Ink/Raw-Mode Challenge

Claude Code uses **Ink** (React for CLIs), which puts stdin in **raw mode**. This fundamentally changes input handling:

| Normal Shell | Ink Raw Mode |
|--------------|--------------|
| Enter = submit line | Enter = keypress event app must interpret |
| Kernel does CR↔LF translation | App sees raw bytes |
| `stty` settings apply | App manages its own buffer |

**Implication**: `tmux send-keys C-m` may not reliably "submit" — we need multiple submission method variants.

### 7.3 Two-Mechanism System

JICM resume uses TWO coordinated mechanisms:

#### Mechanism 1: Session-Start Hook Injection

**What**: Inject context via Claude Code's hook system (`additionalContext`)
**When**: Immediately when `/clear` triggers session-start hook
**Reliability**: HIGH — `additionalContext` injection always works

**Actions**:
1. Detect JICM signals (`.clear-sent.signal` exists)
2. Read and inject `.compressed-context-ready.md` and `.in-progress-ready.md`
3. Create `.idle-hands-active` flag file for Mechanism 2
4. Return resume prompt in hook output (if supported)

**Key Insight**: Hook can inject context but CANNOT force Jarvis to respond. That's why we need Mechanism 2.

#### Mechanism 2: Idle-Hands Monitor (JICM Resume Mode)

**What**: Actively attempt prompt submission using multiple methods
**When**: Triggered by `.idle-hands-active` flag with `mode: jicm_resume`
**Reliability**: Iterative — tries multiple submission variants until success

**Actions**:
1. Monitor for `.idle-hands-active` flag
2. Check tmux pane for idle state (prompt visible, no spinner)
3. Cycle through submission method variants
4. Detect success via pane content change
5. Clean up on success, keep trying on failure

### 7.4 Submission Method Variants

Because Ink raw mode may interpret Enter/CR/LF differently, we try multiple methods:

| # | Method | tmux Command | Rationale |
|---|--------|--------------|-----------|
| 1 | Standard C-m | `send-keys C-m` | Traditional "Enter" |
| 2 | Literal CR | `send-keys -l $'\r'` | Raw carriage return byte |
| 3 | Literal LF | `send-keys -l $'\n'` | Raw linefeed byte |
| 4 | Literal CRLF | `send-keys -l $'\r\n'` | Windows-style line ending |
| 5 | Enter key | `send-keys Enter` | tmux's Enter key name |
| 6 | Escape + Enter | `send-keys Escape C-m` | Clear pending state first |
| 7 | Double Enter | `send-keys C-m C-m` | In case first is consumed |

**Prompt Text Variants** (combined with methods above):

| # | Prompt | Content |
|---|--------|---------|
| A | Full | Detailed resume instructions with file paths |
| B | Simple | "Continue your work." |
| C | Minimal | "." |
| D | Empty | Just submit (test for buffered text) |

The idle-hands monitor cycles through method+prompt combinations until one succeeds.

**Detailed specification**: See `jicm-v5-resume-mechanisms.md`

### 7.5 Mechanism Coordination

```
┌──────────────────────────────────────────────────────────────┐
│ /clear sent                                                   │
│      │                                                        │
│      ▼                                                        │
│ ┌────────────────────────────────────────────────────────┐   │
│ │ Mechanism 1: Hook injects context + creates flag       │   │
│ └────────────────────────────────────────────────────────┘   │
│      │                                                        │
│      │ .idle-hands-active flag created                       │
│      ▼                                                        │
│ ┌────────────────────────────────────────────────────────┐   │
│ │ Mechanism 2: Idle-hands polls + tries submit variants  │   │
│ │   • Cycle through 7 submit methods × 4 prompt variants │   │
│ │   • 12 second intervals                                 │   │
│ │   • Detect success via pane content                     │   │
│ └────────────────────────────────────────────────────────┘   │
│      │                                                        │
│      ▼ Success detected                                      │
│ ┌────────────────────────────────────────────────────────┐   │
│ │ Cleanup: Remove flag + signal files                     │   │
│ └────────────────────────────────────────────────────────┘   │
└──────────────────────────────────────────────────────────────┘
```

### 7.6 Detecting "Jarvis Actively Working"

The watcher must verify Jarvis has resumed before cleanup. Detection methods:

**Primary: tmux Pane Content Analysis**
```bash
detect_submission_success() {
    local pane_content
    pane_content=$("$TMUX_BIN" capture-pane -t "$TMUX_TARGET" -p)

    # Check for spinner (active processing)
    if echo "$pane_content" | grep -qE '⠋|⠙|⠹|⠸|⠼|⠴|⠦|⠧|⠇|⠏'; then
        return 0  # Success - Jarvis is working
    fi

    # Check for response text indicating wake-up
    if echo "$pane_content" | grep -qiE 'context restored|continuing|reading|understood|resuming'; then
        return 0  # Success - Jarvis responded
    fi

    return 1  # Not yet successful
}

detect_idle_state() {
    local pane_content
    pane_content=$("$TMUX_BIN" capture-pane -t "$TMUX_TARGET" -p)

    # Active indicators = NOT idle
    if echo "$pane_content" | grep -qE '⠋|⠙|⠹|⠸|⠼|⠴|⠦|⠧|⠇|⠏'; then
        return 1  # Spinner = working
    fi

    # Check for prompt without recent output
    if echo "$pane_content" | tail -5 | grep -qE '❯\s*$|>\s*$'; then
        return 0  # Idle - prompt visible, no activity
    fi

    return 1  # Unknown state, assume not idle
}
```

**Negative Indicators** (Jarvis NOT working):
- Only `❯` prompt visible with no recent output
- `⎿ (no content)` visible after `/clear`
- No change in pane content between checks

### 7.7 Continuation Prompt Specification

Prompts must be "bulletproof" — guaranteed to activate Jarvis.

**Requirements**:
1. Properly terminated (newline/carriage return/ENTER)
2. Actually submits to Claude Code (not just buffer)
3. Clear, unambiguous instructions
4. References context files explicitly
5. Directs immediate work resumption
6. Includes anti-patterns (what NOT to do)

**Template**:
```
JICM CONTEXT RESTORED - RESUME WORK

Read these files and continue your interrupted task:
1. .claude/context/.compressed-context-ready.md
2. .claude/context/.in-progress-ready.md

Do NOT greet. Do NOT ask questions. Resume work immediately.
```

**Prompt Elements**:
| Element | Purpose |
|---------|---------|
| Clear header | "JICM CONTEXT RESTORED" — signals system-initiated |
| File paths | Explicit paths to both context files |
| Directive | "Resume work immediately" — no ambiguity |
| Anti-patterns | "Do NOT greet. Do NOT ask questions." |

### 7.8 No Standdown Policy

**JICM resume has NO standdown. Keep trying indefinitely.**

| Aspect | Specification |
|--------|---------------|
| Gated by | JICM signal files present + idle state detected |
| Action | Send resume prompts via idle-hands mechanism |
| Termination | ONLY when Jarvis confirmed actively working |
| Timeout | **None** |
| Max attempts | **None** |
| Giving up | **Never** |

### 7.9 Interrupt Mechanism (Pre-/clear)

Before sending `/clear`, the watcher must get Jarvis to dump in-progress state. This is the INTERRUPT phase.

**Interrupt Prompt Template**:
```
JICM INTERRUPT - CONTEXT CLEAR IMMINENT

Compression is complete. Write your current work state NOW:

1. Write to .claude/context/.in-progress-ready.md:
   - What you were just working on
   - Any uncommitted decisions or partial work
   - Next steps you were about to take

2. After writing, respond with: "READY FOR CLEAR"

Do this immediately. /clear follows in 5 seconds.
```

**Interrupt Verification**:
- Watcher waits for `.in-progress-ready.md` to exist
- Watcher may also look for "READY FOR CLEAR" in tmux pane
- If neither after 30 seconds, retry interrupt prompt
- Only proceed to `/clear` when file exists

**Why This Matters**: The compression agent captures historical context, but Jarvis may have done significant work DURING compression. The interrupt captures that gap.

### 7.10 No Fallbacks Policy

**"Do or die" — no "proceed anyway" fallbacks.**

| Missing File | Response |
|--------------|----------|
| `.compressed-context-ready.md` | Re-spawn compression agent, retry |
| `.in-progress-ready.md` | Re-send interrupt prompt, retry |

**ONLY when BOTH files exist → proceed to `/clear`**

**Retry Strategy**:
- Retry the failed step, not skip it
- Multiple retry attempts allowed
- No arbitrary limits on attempts
- If truly stuck, surface problem to user rather than silently fail

### 7.11 Circuit Breakers and Safety Limits

While JICM doesn't "give up," it needs bounds to prevent runaway behavior:

**Time-Based Circuit Breaker**:
| Phase | Max Duration | If Exceeded |
|-------|--------------|-------------|
| Compression | 5 minutes | Log warning, continue waiting |
| Interrupt | 2 minutes | Retry interrupt, alert after 3 retries |
| Resume | 5 minutes | Alert user, keep trying in background |

**Overlap Prevention**:
- Lock file (`.jicm-in-progress.lock`) prevents concurrent JICM cycles
- Lock includes timestamp; stale locks (>10 min) are forcibly removed
- If lock exists, new threshold trigger is ignored

**Stuck State Detection**:
```bash
# If same state for >5 minutes, something is wrong
if [[ "$current_state" == "$last_state" ]] && [[ $state_age -gt 300 ]]; then
    log "JICM appears stuck in $current_state state"
    # Alert user but continue trying
fi
```

**User Alert Mechanism**:
- After extended stall, watcher writes to `.claude/context/.jicm-alert.md`
- Jarvis's next response will see this and can inform user
- Alternative: Desktop notification via `osascript` on macOS

---

## 8. Data Sources

### 8.1 Principle: Comprehensive Context Assembly

The compression agent assembles context from **multiple sources** — both ephemeral (conversation transcript) and durable (project documentation). The agent is instructed to scan all provided locations and intelligently consolidate what matters for continued work.

**Key Insight**: Claude Code's context window is assembled on-demand from multiple sources. There is no single "context file." The compression agent must reconstruct what matters from:
- Conversation transcript (JSONL logs)
- Project instructions (CLAUDE.md, identity)
- Session state (current work, priorities)
- Context captures (if available)

### 8.2 Source Categories

#### Category A: Conversation Transcript (Ephemeral)

| Location | Contains | Priority |
|----------|----------|----------|
| `~/.claude/projects/-Users-aircannon-Claude-Jarvis/[session-id].jsonl` | Main conversation | **HIGH** |
| `~/.claude/projects/.../subagents/agent-*.jsonl` | Subagent conversations | MEDIUM |
| `~/.claude/tasks/[session-id]/` | Task state, checklists | MEDIUM |
| `.claude/context/.context-captured*.txt` | Pre-processed captures | HIGH (if available) |

#### Category B: Project Foundation (Durable)

| Location | Contains | Priority |
|----------|----------|----------|
| `CLAUDE.md` (project root) | Project instructions, persona | **HIGH** |
| `.claude/jarvis-identity.md` | Identity, tone, safety posture | **HIGH** |
| `.claude/context/compaction-essentials.md` | Essential context to preserve | **HIGH** |

#### Category C: Session Documentation (Durable)

| Location | Contains | Priority |
|----------|----------|----------|
| `.claude/context/session-state.md` | Current work status | MEDIUM |
| `.claude/context/current-priorities.md` | Task backlog | MEDIUM |

**Note on Session Docs**: While JICM doesn't UPDATE these files (that's sessionEnd's job), the compression agent READS them to understand current work context. Reading ≠ Writing.

### 8.3 Combined Approach

The compression agent uses **both** transcript parsing AND documentation review:

```
┌─────────────────────────────────────────────────────────────────┐
│              COMPRESSION AGENT DATA ASSEMBLY                     │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │ Step 1: Conversation Transcript                          │    │
│  │   • Read session JSONL (main conversation)               │    │
│  │   • Merge subagent JSONLs if relevant                    │    │
│  │   • Parse: user messages, assistant messages, tool calls │    │
│  │   • Extract: decisions, work done, errors, blockers      │    │
│  └─────────────────────────────────────────────────────────┘    │
│                           +                                      │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │ Step 2: Context Captures                                 │    │
│  │   • Read .context-captured.txt (if exists)              │    │
│  │   • Already processed, may be more usable than JSONL    │    │
│  └─────────────────────────────────────────────────────────┘    │
│                           +                                      │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │ Step 3: Project Foundation                               │    │
│  │   • Read CLAUDE.md (instructions, persona)               │    │
│  │   • Read jarvis-identity.md (identity, tone)             │    │
│  │   • Read compaction-essentials.md (must-preserve items)  │    │
│  └─────────────────────────────────────────────────────────┘    │
│                           +                                      │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │ Step 4: Session State                                    │    │
│  │   • Read session-state.md (current work status)          │    │
│  │   • Read current-priorities.md (task backlog)            │    │
│  └─────────────────────────────────────────────────────────┘    │
│                           ↓                                      │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │ Step 5: Intelligent Compression                          │    │
│  │   • Keep: decisions, current task, file paths, blockers  │    │
│  │   • Consolidate: related work, repeated patterns         │    │
│  │   • Clarify: ambiguous references, implicit context      │    │
│  │   • Simplify: verbose outputs, redundant explanations    │    │
│  │   • Output: .compressed-context-ready.md                 │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### 8.4 Agent Instructions

The compression agent definition should instruct:

1. **Scan all provided locations** — don't assume one source is authoritative
2. **Be smart about importance** — prioritize what matters for continued work
3. **Consolidate** — merge related information from multiple sources
4. **Organize** — structure output for easy consumption by post-/clear Jarvis
5. **Clarify** — resolve ambiguous references, make implicit context explicit
6. **Simplify** — remove verbosity while preserving meaning
7. **Target token range** — aim for compressed output between 10k-30k tokens

### 8.5 Compression Target

| Setting | Default | Range |
|---------|---------|-------|
| Target tokens | 10,000 - 30,000 | Configurable |

**Rationale**:
- **Minimum 10k**: Enough to preserve meaningful context, decisions, and current work
- **Maximum 30k**: Leaves substantial headroom (~170k tokens) for new work after restoration
- Agent should aim for the lower end when possible, but expand if context is genuinely complex

### 8.6 Files to Pass to Compression Agent

When spawning the compression agent, provide these file paths:

```yaml
transcript_sources:
  - ~/.claude/projects/-Users-aircannon-Claude-Jarvis/[session-id].jsonl
  - ~/.claude/projects/-Users-aircannon-Claude-Jarvis/subagents/*.jsonl
  - .claude/context/.context-captured.txt
  - .claude/context/.context-captured-escaped.txt

foundation_docs:
  - CLAUDE.md  # project root (canonical)
  - .claude/jarvis-identity.md
  - .claude/context/compaction-essentials.md

session_state:
  - .claude/context/session-state.md
  - .claude/context/current-priorities.md
```

### 8.7 JSONL Parsing Notes

When reading JSONL files:
- Open read-only (file may be actively written)
- Tolerate partial last line (in-progress write)
- Extract: user messages, assistant messages, tool results
- The exact prompt sent to Claude isn't perfectly reconstructable, but key content is

**Useful command to find all context-bearing files**:
```bash
find ~/.claude -maxdepth 4 -type f \( -name "*.json" -o -name "*.jsonl" -o -name "*.txt" \) -print
```

### 8.8 Tool Requirements

The compression agent needs these tools granted:
- `Read` — to read all source files
- `Write` — to write `.compressed-context-ready.md`
- `Glob` — to find session files and subagent logs
- `Bash` — optionally, for find/ls commands to discover files

---

## 9. Complete Flow Specification

### 9.1 End-to-End Flow

```
┌────────────────────────────────────────────────────────────────────┐
│ PHASE 1: THRESHOLD DETECTION                                       │
├────────────────────────────────────────────────────────────────────┤
│ 1. Watcher monitors context window USAGE                           │
│ 2. Usage hits threshold (50%)                                      │
│ 3. Watcher sends `/intelligent-compress` to Claude Code            │
└────────────────────────────────────────────────────────────────────┘
                                   │
                                   ▼
┌────────────────────────────────────────────────────────────────────┐
│ PHASE 2: COMPRESSION                                               │
├────────────────────────────────────────────────────────────────────┤
│ 4. Jarvis executes /intelligent-compress                           │
│ 5. Jarvis spawns compression agent (run_in_background: true)       │
│ 6. Task tool returns immediately → Jarvis continues other work     │
│ 7. Compression agent reads context, compresses                     │
│ 8. Compression agent writes .compressed-context-ready.md           │
│ 9. Compression agent creates .compression-done.signal              │
│ 10. Compression agent terminates                                   │
└────────────────────────────────────────────────────────────────────┘
                                   │
                                   ▼
┌────────────────────────────────────────────────────────────────────┐
│ PHASE 3: INTERRUPT                                                 │
├────────────────────────────────────────────────────────────────────┤
│ 11. Watcher detects .compression-done.signal                       │
│ 12. Watcher sends INTERRUPT prompt via tmux send-keys              │
│ 13. Jarvis receives prompt, writes .in-progress-ready.md           │
│ 14. Jarvis responds "READY FOR CLEAR"                              │
│ 15. Watcher verifies .in-progress-ready.md exists                  │
└────────────────────────────────────────────────────────────────────┘
                                   │
                                   ▼
┌────────────────────────────────────────────────────────────────────┐
│ PHASE 4: CLEAR                                                     │
├────────────────────────────────────────────────────────────────────┤
│ 16. Watcher creates .clear-sent.signal                             │
│ 17. Watcher sends /clear to Claude Code via tmux                   │
│ 18. Jarvis's context window is WIPED                               │
│ 19. Files on disk are UNTOUCHED                                    │
└────────────────────────────────────────────────────────────────────┘
                                   │
                                   ▼
┌────────────────────────────────────────────────────────────────────┐
│ PHASE 5: INJECTION                                                 │
├────────────────────────────────────────────────────────────────────┤
│ 20. session-start hook fires (SOURCE=clear)                        │
│ 21. Hook detects JICM signal files (.clear-sent.signal)            │
│ 22. Hook reads .compressed-context-ready.md                        │
│ 23. Hook reads .in-progress-ready.md                               │
│ 24. Hook injects content via additionalContext                     │
│ 25. Hook creates .continuation-injected.signal                     │
└────────────────────────────────────────────────────────────────────┘
                                   │
                                   ▼
┌────────────────────────────────────────────────────────────────────┐
│ PHASE 6: RESUME                                                    │
├────────────────────────────────────────────────────────────────────┤
│ 26. Watcher sends initial resume prompt via tmux                   │
│ 27. If no response: escalating prompts (10s intervals)             │
│ 28. Idle detection polling as backstop (15s intervals)             │
│ 29. Jarvis receives prompt + injected context                      │
│ 30. Jarvis outputs: "Context restored. Continuing [task]..."       │
│ 31. Jarvis IMMEDIATELY resumes interrupted work                    │
└────────────────────────────────────────────────────────────────────┘
                                   │
                                   ▼
┌────────────────────────────────────────────────────────────────────┐
│ PHASE 7: CLEANUP                                                   │
├────────────────────────────────────────────────────────────────────┤
│ 32. Watcher confirms Jarvis actively working (spinner/output)      │
│ 33. Watcher creates .jicm-complete.signal                          │
│ 34. Watcher deletes all signal files                               │
│ 35. Watcher deletes context files                                  │
│ 36. Removes .jicm-in-progress.lock                                 │
│ 37. Clean slate for next JICM cycle                                │
└────────────────────────────────────────────────────────────────────┘
```

### 9.2 State Machine Diagram

```
                    ┌──────────────┐
                    │   NORMAL     │
                    │  OPERATION   │
                    └──────────────┘
                           │
                    Context hits 50%
                           │
                           ▼
                    ┌──────────────┐
                    │  COMPRESSING │
                    └──────────────┘
                           │
              .compression-done.signal created
                           │
                           ▼
                    ┌──────────────┐
                    │ INTERRUPTING │
                    └──────────────┘
                           │
              .in-progress-ready.md created
                           │
                           ▼
                    ┌──────────────┐
                    │   CLEARING   │
                    └──────────────┘
                           │
                    /clear sent
                           │
                           ▼
                    ┌──────────────┐
                    │  INJECTING   │
                    └──────────────┘
                           │
              Context injected into Jarvis
                           │
                           ▼
                    ┌──────────────┐
                    │   RESUMING   │◀──────────────────┐
                    └──────────────┘                   │
                           │                          │
              ┌────────────┴────────────┐             │
              │                         │             │
         Jarvis working          Jarvis idle          │
              │                         │             │
              ▼                         └─────────────┘
       ┌──────────────┐                 (retry resume)
       │  CLEANING UP │
       └──────────────┘
              │
       Delete all files
              │
              ▼
       ┌──────────────┐
       │   NORMAL     │
       │  OPERATION   │
       └──────────────┘
```

### 9.3 Validation Checkpoints

| Phase | Success Criteria | Failure Response |
|-------|------------------|------------------|
| Compression | `.compressed-context-ready.md` exists, non-empty | Re-spawn agent |
| Interrupt | `.in-progress-ready.md` exists | Re-send interrupt |
| Clear | `/clear` command sent | Retry send |
| Injection | Content in Jarvis context | Re-inject |
| Resume | Jarvis actively working | Retry prompts (no limit) |
| Cleanup | All files deleted | Retry delete |

---

## 10. External Execution Requirement

### 10.1 The Self-Injection Constraint

**Critical Architecture Constraint**: Jarvis CANNOT reliably inject prompts into its own tmux session from within a Bash tool call. All prompt injection MUST come from an external process.

### 10.2 Why Self-Injection Fails

When Claude Code executes a Bash command that sends `tmux send-keys` to its own session, three compounding issues cause failure:

| Issue | Explanation |
|-------|-------------|
| **Input State Collision** | Ink TUI is in "busy" state processing Bash command; input handling becomes non-deterministic |
| **Event Loop Interference** | Keystrokes queue while event loop is blocked; processed in unexpected order when control returns |
| **Timing Race Conditions** | Script-side sleeps occur in child process, not in tmux event delivery; keystrokes arrive in rapid succession |

**Observed Symptoms**:
- Multiple `UserPromptSubmit` hook events fire unexpectedly
- Text appears in buffer but doesn't submit
- Process exits with signal 137 (SIGKILL)
- Unpredictable keystroke ordering

### 10.3 Correct Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│ INCORRECT: Self-referential (FAILS)                              │
│                                                                  │
│  Claude Code → Bash Tool → tmux send-keys → Same Claude Code    │
│                    ↑                              ↓              │
│                    └──── BLOCKED waiting for ────┘              │
│                                                                  │
├─────────────────────────────────────────────────────────────────┤
│ CORRECT: External execution (WORKS)                              │
│                                                                  │
│  jarvis-watcher.sh ──────► tmux send-keys ──────► Claude Code   │
│  (background daemon)                               (idle prompt) │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### 10.4 Implications for JICM Components

| Component | Self-Injection? | Why It Works |
|-----------|-----------------|--------------|
| **jarvis-watcher.sh** | NO — External | Background daemon, not Claude Code child |
| **session-start hook** | NO — Hook system | Runs before Claude Code responds, uses `additionalContext` |
| **Bash tool in Claude** | YES — Self-referential | **CANNOT WORK** for prompt injection |

### 10.5 Fire-and-Forget Workaround

If Jarvis needs to trigger deferred prompt injection from within a session, it must spawn a **detached external process**:

```bash
# Spawn detached script that outlives the Bash tool call
nohup /path/to/deferred-injection.sh &>/dev/null &
disown
# Bash tool returns immediately
# Detached script waits, then sends keystrokes to idle Claude Code
```

**Use Cases**:
- Triggering watcher actions
- Scheduling future injections
- Signal file creation (watcher picks up and acts)

### 10.6 Design Validation

This constraint was validated on 2026-02-04:

| Test | Context | Result |
|------|---------|--------|
| test-submission-methods.sh | External terminal | ✅ Works |
| Ad hoc Bash script | Within Claude Code | ❌ Fails |
| jarvis-watcher.sh | Background daemon | ✅ Works (design basis) |

**Full lesson documented**: `.claude/context/lessons/tmux-self-injection-limitation.md`

---

## Appendix A: Configuration Reference

### A.1 Environment Variables

| Variable | Default | Purpose |
|----------|---------|---------|
| `JARVIS_WATCHER_THRESHOLD` | 50 | Context usage percentage to trigger JICM |
| `JARVIS_WATCHER_INTERVAL` | 30 | Seconds between checks |
| `JICM_TARGET_TOKENS_MIN` | 10000 | Minimum compressed output tokens |
| `JICM_TARGET_TOKENS_MAX` | 30000 | Maximum compressed output tokens |
| `TMUX_SESSION` | jarvis | tmux session name |
| `TMUX_BIN` | ~/bin/tmux | Path to tmux binary |

### A.2 File Paths

| File | Path |
|------|------|
| Compressed context | `.claude/context/.compressed-context-ready.md` |
| In-progress addendum | `.claude/context/.in-progress-ready.md` |
| All signal files | `.claude/context/.*signal` |
| JICM lock file | `.claude/context/.jicm-in-progress.lock` |
| Idle-hands flag | `.claude/context/.idle-hands-active` |
| Watcher script | `.claude/scripts/jarvis-watcher.sh` |
| Launcher script | `.claude/scripts/launch-watcher.sh` |
| Config file | `.claude/config/autonomy-config.yaml` |
| Context capture | `.claude/context/.context-captured.txt` |

---

## Appendix B: Glossary

| Term | Definition |
|------|------------|
| **Context window** | Claude's working memory, limited capacity |
| **Context USAGE** | How much of the context window is filled |
| **Compression** | Intelligently condensing context content |
| **Signal file** | File indicating state transition (not data) |
| **Context file** | File containing data for restoration |
| **Lock file** | Prevents concurrent JICM cycles |
| **sessionStart** | True session beginning (user launches Claude) |
| **sessionRestart** | JICM resumption (post-/clear mid-session) |
| **session-start hook** | Hook file that handles both sessionStart and sessionRestart |
| **Jarvis** | Main Claude Code agent |
| **Compression Agent** | Spawned subagent for compression |
| **Watcher** | Background process monitoring context |
| **Threshold** | Context usage % that triggers compression (default 50%) |
| **Interrupt prompt** | Prompt sent to make Jarvis dump state before /clear |
| **Resume prompt** | Prompt sent to reawaken Jarvis after /clear |
| **Ink** | React-based CLI framework used by Claude Code |
| **Raw mode** | Terminal mode where app receives individual keypresses |
| **Idle-hands** | Watcher subsystem for detecting and responding to idle states |
| **Submission variant** | Combination of submission method + prompt text |

---

## Appendix C: Anti-Patterns

### What JICM Should NEVER Do

| Anti-Pattern | Why It's Wrong |
|--------------|----------------|
| Hook on `/clear` itself | Breaks native command behavior |
| Update `session-state.md` | That's sessionEnd's job |
| Greet after `/clear` | This is mid-session, not new session |
| Ask "How can I help?" | JICM ends with active work, not idle |
| Give up after N attempts | "Do or die" — no standdown |
| Delete files at `/clear` | Files needed for context restoration |
| Proceed if files missing | Must retry, not skip |
| Treat resume as optional | Resume IS the point of JICM |
| Leave lock file on success | Blocks future JICM cycles |
| Start JICM when lock exists | Causes overlapping cycles |
| **Self-inject via Bash tool** | **Fails due to TUI event loop blocking** |
| Run test scripts within Claude | Self-referential loop causes unpredictable failures |

---

**Document Status**: Complete specification for JICM v5 implementation
**Revision**: 1.4 — Added Section 10 (External Execution Requirement), new anti-patterns
**Next Steps**: Implementation planning, component refactoring
**Dependencies**:
- jarvis-watcher.sh
- session-start.sh
- intelligent-compress.md
- context-compressor.md
- **jicm-v5-resume-mechanisms.md** (detailed submission handling)
- **lessons/tmux-self-injection-limitation.md** (critical constraint documentation)

*JICM v5 Design Addendum — Created 2026-02-01 | Revised 2026-02-04*
