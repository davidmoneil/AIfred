# JICM v5 Architecture Clarifications

**Date**: 2026-02-01
**Status**: HISTORICAL REFERENCE — See `jicm-v5-design-addendum.md` for authoritative spec
**Purpose**: Captured clarifications from architectural review session

> **Note**: This document captures the design conversation. Some clarifications were further refined during synthesis into the v5 addendum. For current specifications, always refer to `jicm-v5-design-addendum.md`.

---

## Clarification #1: Agent vs Jarvis Identity

**Issue**: Conflation of "compression agent" (spawned subagent) with "Jarvis" (main agent).

**Resolution**:
- **Jarvis** (me) = The main agent in Claude Code, works with user, needs CONTINUE signals, writes `.in-progress-ready.md`, gets cleared and must resume
- **Compression Agent** = Spawned subagent, runs in background, does NOT need CONTINUE signals, writes `.compressed-context-ready.md`, finishes and terminates

**Corrected Flow**:
1. `/intelligent-compress` executes (by Jarvis)
2. Jarvis spawns compression agent (background)
3. **Jarvis receives CONTINUE signal** → keeps working
4. Compression agent finishes → writes `.compressed-context-ready.md`
5. Watcher detects completion → **INTERRUPTS Jarvis**
6. **Jarvis dumps current state** → `.in-progress-ready.md`
7. `/clear` sent → **Jarvis is cleared**
8. sessionRestart injects context → **Jarvis resumes work**

---

## Clarification #2: File Deletion Timing

**Issue**: Confusion between `/clear` (clears context window) and "clean up files" (deletes signal files).

**Resolution**:
- `/clear` clears Jarvis's **context window** (memory), NOT files on disk
- Files persist through `/clear` so sessionRestart can read them
- Files are only deleted AFTER successful context injection and work resumption

**Correct Sequence**:
1. Files CREATED (`.compressed-context-ready.md`, `.in-progress-ready.md`)
2. `/clear` sent → clears context window, files UNTOUCHED
3. sessionRestart READS files → injects content
4. Jarvis resumes work
5. THEN delete files (one-time use, prevents stale files)

---

## Clarification #3: /clear Is Not a Trigger, No Greeting Logic Needed

**Issue**: Wrong framing of "skip greeting if JICM-triggered clear."

**Resolution**:
- `/clear` is something that GETS triggered, not a trigger itself
- Greetings don't get invoked after `/clear`, ever — no "skip" logic needed
- After context injection, Jarvis provides **status update** (not greeting) and **immediately continues work**
- NO pausing, NO "How can I help?", NO awaiting instructions

**Post-/clear Behavior**:
1. Context injected
2. CONTINUE signal received
3. Brief status: "Context restored. Continuing [task]..."
4. IMMEDIATELY resume in-progress work

**Distinction**:
- **Session Start** (user launches Claude): Greeting, AIfred sync, await instructions
- **JICM Restart** (post-/clear mid-session): NO greeting, inject context, status update, immediately continue

---

## Clarification #4: Don't Hook on /clear Itself

**Issue**: Designing systems that listen for `/clear` as a trigger.

**Resolution**:
- `/clear` is a native command — user should be able to use it with no bells and whistles
- Don't distinguish "user-triggered /clear" vs "JICM-generated /clear"
- JICM uses **signal files** to indicate it orchestrated the workflow

**Correct Design**:
- JICM creates signal files BEFORE sending `/clear`
- Post-clear hook checks for signal files:
  - If present → inject context, CONTINUE
  - If NOT present → do nothing (native `/clear`)

**Principle**: Signal files are the trigger, not `/clear` itself.

---

## Clarification #5: Context Window Usage, Not Context Compression

**Issue**: Wrong terminology — "watcher detects context compression threshold."

**Resolution**:
- Watcher monitors **context window USAGE** (how full the context window is)
- When USAGE hits threshold, it triggers `/intelligent-compress`
- **Compression** is what happens AFTER threshold detected

**Sequence**:
1. Watcher monitors context window USAGE
2. Usage hits threshold (50% — updated from original 70%)
3. Watcher triggers `/intelligent-compress`
4. COMPRESSION begins

> **v5 Addendum Update**: Threshold was simplified to single 50% trigger during synthesis.

---

## Clarification #6: Unified Entry Point via /intelligent-compress

**Confirmed Alignment**:
- Watcher threshold trigger sends `/intelligent-compress` (not spawn agent directly)
- Everything downstream flows from `/intelligent-compress`
- Whether triggered by watcher OR manually by user → same workflow

**Benefit**: One flow to build, test, and maintain. User can trust manual invocation behaves identically to automatic.

---

## Clarification #7: Transparent, Not Invisible

**Issue**: Described JICM as "invisible" / "user shouldn't notice."

**Resolution**: Transparency ≠ invisibility

**JICM Should Be**:
| Characteristic | Meaning |
|----------------|---------|
| **Autonomic** | Happens on its own when conditions arise |
| **Automatic** | Jarvis ends in actively working state, not idle |
| **Light-weight** | Not heavy or disruptive |
| **Informative** | Tell user what's happening and why |
| **Seamless** | Pick right back up without idling/waiting/questioning |

**Example Good Behavior**:
```
"Context window at 72%, sir. Initiating compression..."
[compression happens, /clear, context restored]
"Context restored. Continuing with the watcher refactoring..."
[immediately resumes work]
```

User KNOWS it happened. User is INFORMED. But user didn't have to DO anything.

---

## Clarification #8: Native Commands Should Remain Native

**Issue**: session-start.sh overloaded with handling for "clear" and "compact" sources.

**Resolution**: This actually SIMPLIFIES the architecture.

| SOURCE | What Should Happen |
|--------|-------------------|
| startup | TRUE Session start → full sessionStart protocol |
| resume | Abbreviated Session start |
| clear | Check for JICM signal files: If present → inject; If NOT → do NOTHING |
| compact | Do NOTHING. Let native auto-compact work as designed. |

**Principle**: We're not "handling" native commands. We check if JICM left signal files.

**Reduces Strain**:
- sessionStart handles: `startup`, `resume` (true Session boundaries)
- sessionRestart (JICM) handles: presence of signal files after any clear
- Native commands: `/clear`, `/compact`, `/auto-compact` — left alone

---

## Clarification #9: JICM Doesn't Update Session State Files

**Issue**: Listed updating `session-state.md` and `current-priorities.md` as part of JICM.

**Resolution**:
- Those files are for **Session boundaries** (sessionEnd updates, sessionStart reads)
- JICM creates its **own** temporary files for context restoration

**File Responsibility**:

| File | Domain | Purpose |
|------|--------|---------|
| `session-state.md` | sessionEnd | Project status documentation |
| `current-priorities.md` | sessionEnd | Task backlog |
| `.compressed-context-ready.md` | JICM | Condensed context window content |
| `.in-progress-ready.md` | JICM | Addendum — very recent work |

**Principle**: JICM leaves session documentation files alone.

---

## Clarification #10: Autonomic sessionStart Trigger

**Issue**: Never successfully caused Jarvis to autonomically begin sessionStart without user prompting (e.g., ".").

**The Problem**:
- session-start.sh hook CAN inject context
- Hook CANNOT force Jarvis to generate a response
- Hook fires → context staged → Jarvis sits idle waiting for input

**Proposed Solution**:
1. User launches Claude Code
2. session-start.sh fires, prepares context
3. Watcher detects fresh session via tmux pane parsing
4. Watcher sends "sessionStart" via tmux send-keys
5. Jarvis receives prompt + injected context
6. Jarvis executes sessionStart protocol

**Detection Distinction**:
| State | tmux Pane Contains |
|-------|-------------------|
| Fresh Session | Claude Code banner, version — NO command traces |
| Post-/clear | Banner + `❯ /clear` + `⎿ (no content)` |

**Trigger Phrase**: Use `"sessionStart"` — recognized by Jarvis AND available for hooks.

---

## Clarification #11: What Files Does /intelligent-compress Create?

**Resolution**: `/intelligent-compress` ORCHESTRATES creation, doesn't directly create:

| File | Created By | Contains | When |
|------|------------|----------|------|
| `.compressed-context-ready.md` | Compression Agent (subagent) | Intelligently condensed context | After agent finishes |
| `.in-progress-ready.md` | Jarvis (NOT subagent) | Very recent work during compression | After interrupt |

**Relationship**: `.in-progress-ready.md` is an **addendum** to `.compressed-context-ready.md`.
- Compression agent captures "historical" context
- Jarvis captures "what I did while you were compressing"

---

## Clarification #12: Files Must NOT Be Deleted at /clear

**Confirmed**: When watcher sends `/clear`:
- `.compressed-context-ready.md` → EXISTS ✓ (DO NOT DELETE)
- `.in-progress-ready.md` → EXISTS ✓ (DO NOT DELETE)
- `.compression-done.signal` → Can delete (job done)
- `.clear-sent.signal` → CREATE NOW (timestamp marker)

**Deletion Timing**:
- Files persist through `/clear`
- Files persist through sessionRestart reading them
- Files persist through content injection
- Files persist through Jarvis resuming work
- Files deleted only AFTER work resumption CONFIRMED

---

## Clarification #13: /clear Is NOT the Trigger for sessionRestart

**Confirmed**: sessionRestart triggers on **signal files**, not `/clear`.

| Scenario | Signal Files? | Result |
|----------|--------------|--------|
| User manually runs `/clear` | No | Native behavior, nothing special |
| JICM sends `/clear` | Yes | sessionRestart injects context, Jarvis resumes |

**Principle**: `/clear` remains simple native command. Signal files determine what happens next.

---

## Clarification #14: What Files Are Cleaned in "Clean Up Signal Files"?

**Issue**: Need precision on which files are cleaned and when, to avoid premature removal or leaving stale files.

**Resolution**: All signal files are DELETED (removed from disk) — they are one-time use.

**Signal Files and Cleanup Timing**:

| File | Created By | Delete When |
|------|------------|-------------|
| `.compression-done.signal` | Compression Agent | After context injection, before Jarvis resumes |
| `.compressed-context-ready.md` | Compression Agent | After Jarvis confirmed working |
| `.in-progress-ready.md` | Jarvis | After Jarvis confirmed working |
| `.clear-sent.signal` | Watcher | After Jarvis confirmed working |
| `.continuation-injected.signal` | sessionRestart | After Jarvis confirmed working |
| `.jicm-complete.signal` | sessionRestart | After Jarvis confirmed working (marks end) |

**Principle**: Only delete AFTER the file's purpose is fulfilled. Context files deleted LAST, only after Jarvis is confirmed actively working.

**Result**: Clean slate for next JICM cycle. Leaving files would cause false positives in future cycles.

---

## Clarification #15: Idle Monitoring — Critical for Resume Signals

**Issue**: Need multiple "flavors" of idle monitoring for different purposes, with distinct detection criteria to avoid cross-triggering.

**Resolution**: Idle detection evolved into a unified **mode-based idle-hands system** where a single mechanism handles multiple scenarios.

> **v5 Addendum Update**: The "three flavors" architecture was refined into a unified idle-hands mode system. Fresh session detection remains separate (watcher main loop), while other scenarios use the `.idle-hands-active` flag with different modes.

**Mode-Based Idle-Hands System** (from v5 addendum):

| Mode | Trigger | Behavior |
|------|---------|----------|
| `jicm_resume` | Post-/clear + JICM signals | Aggressive wake attempts until Jarvis working |
| `long_idle` | 60+ min no activity (future) | Trigger /maintenance → /reflect → /evolve |
| `workflow_chain` | Post-workflow complete (future) | Start next workflow in chain |
| `unsubmitted_text` | Text in buffer (future) | Send Enter to submit |

**Fresh Session Detection** (separate from idle-hands):
- **Trigger**: New Claude Code session started
- **Detection**: tmux pane shows banner WITHOUT command traces
- **Action**: Send "sessionStart" prompt
- **Goal**: Jarvis autonomically begins greeting/AIfred sync flow

**Key Principle**: The `.idle-hands-active` flag file controls mode-specific behavior. Fresh session detection runs in watcher main loop separately.

---

## Clarification #16: session-state.md and current-priorities.md NOT Needed for JICM

**Issue**: Had /intelligent-compress updating session-state.md and current-priorities.md, but these are sessionEnd's responsibility.

**Resolution**: JICM does NOT touch session documentation files. Complete separation.

**Session Documentation Files** (sessionEnd's domain):
- `session-state.md` → "What is the project status?"
- `current-priorities.md` → "What's on the task backlog?"
- Updated by: sessionEnd
- Read by: sessionStart (at NEW Session boundaries)

**JICM Context Files** (JICM's domain):
- `.compressed-context-ready.md` → Condensed context window content
- `.in-progress-ready.md` → Very recent work addendum
- Created by: JICM workflow (agent + Jarvis)
- Read by: sessionRestart (post-/clear)

**Corrected /intelligent-compress Flow**:

| Step | Action | Files Touched |
|------|--------|---------------|
| 1 | Spawn compression agent | None yet |
| 2 | Send CONTINUE signal to Jarvis | None |
| 3 | Agent compresses context | Creates `.compressed-context-ready.md` |
| 4 | Interrupt Jarvis | None |
| 5 | Jarvis dumps recent work | Creates `.in-progress-ready.md` |
| 6 | Send /clear | Creates `.clear-sent.signal` |

**Principle**: Session documentation is for Session boundaries. JICM preserves live working memory.

---

## Clarification #17: Direct Context Window Content to Compression Agent

**Issue**: Previous assumption that compression agent needed session-state.md. Actually, agent should read REAL context content.

**Resolution**: Multiple options for getting actual context window content to the compression agent.

**Option A: Pass via Prompt**
- When spawning agent, include context summary directly in the prompt
- Limitation: May hit prompt size limits for large contexts

**Option B: Agent Reads Log Files Directly**
1. Get session ID from `~/.claude/statsig/statsig.session_id.*` or `~/.claude/history.jsonl`
2. Read context from `~/.claude/projects/-Users-aircannon-Claude-Jarvis/[session-id].jsonl`
3. Parse JSONL for messages, tool calls, reasoning
4. Compress and write to `.compressed-context-ready.md`

**Option C: Use Existing Context Capture Scripts**
- `.claude/hooks/update-context-cache.js` already reads session transcript
- `.claude/context/.context-captured.txt` may have usable content

**Known Context Content Locations**:
- `~/.claude/projects/-Users-aircannon-Claude-Jarvis/[session-id].jsonl` — Chat responses
- `~/.claude/projects/.../subagents/agent-*.jsonl` — Subagent logs
- `~/.claude/debug/[session-id].txt` — Debug logs
- `~/.claude/history.jsonl` — Session history with encrypted IDs
- `~/.claude/tasks/[session-id]/` — Task lists
- `.claude/context/.context-captured*.txt` — Context captures

**Key Insight**: Compression agent works from ACTUAL context content, not session documentation. This is the real source of truth.

**To revisit during implementation and testing.**

---

## Clarification #18: Fallback Behavior When Files Missing

**Issue**: I proposed "proceed anyway with warning" if files missing. User rejects this — philosophy is "do it right or die trying."

**Resolution**: NO "proceed anyway" fallbacks. Circle back and retry.

**Correct Approach**:

| Missing File | Cause | Response |
|--------------|-------|----------|
| `.compressed-context-ready.md` | Agent timeout/crashed/didn't write | Re-spawn agent or retry |
| `.in-progress-ready.md` | Interrupt didn't reach Jarvis | Re-send interrupt prompt |

**ONLY when BOTH files exist → proceed to /clear**

**Retry Strategy**:
- Retry the failed step, not skip it
- Multiple retry attempts allowed
- No arbitrary limits ("circle back indefinitely")
- If truly stuck, surface problem to user rather than silently fail

**Principle**: JICM is a pipeline. Each stage must complete successfully before the next begins. No shortcuts. "Do or die."

---

## Clarification #19: Continuation Prompt Formatting

**Issue**: Continuation prompts must be bulletproof to guarantee Jarvis exits idle state.

**Resolution**: Perfect formatting with proper termination and clear directives.

**Prompt Requirements**:
1. Properly terminated (newline/carriage return/ENTER)
2. Actually submits to Claude Code (not just buffer)
3. Clear, unambiguous instructions
4. References context files explicitly
5. Directs immediate work resumption

**tmux send-keys Formatting**:
```bash
# Send text
tmux send-keys -t "$TMUX_TARGET" -l "JICM CONTEXT RESTORED - RESUME WORK

Read these files and continue your interrupted task:
1. .claude/context/.compressed-context-ready.md
2. .claude/context/.in-progress-ready.md

Do NOT greet. Do NOT ask questions. Resume work immediately."

# Ensure submission (belt and suspenders)
sleep 0.1
tmux send-keys -t "$TMUX_TARGET" Enter
tmux send-keys -t "$TMUX_TARGET" C-m
```

**Prompt Content Elements**:
| Element | Purpose |
|---------|---------|
| Clear header | "JICM CONTEXT RESTORED" — signals system-initiated |
| File paths | Explicit paths to both context files |
| Directive | "Resume work immediately" — no ambiguity |
| Anti-patterns | "Do NOT greet. Do NOT ask questions." |

**Multiple Attempts**: If first doesn't activate, try simplified prompts.

---

## Clarification #20: Multiple Resume Signal Mechanisms

**Issue**: Resume is the most critical part. Need independent mechanisms working together like defibrillator paddles.

> **v5 Addendum Update**: Architecture was refined from three mechanisms to TWO mechanisms. Guardian Agent was removed (subagents can't monitor main agent effectively). The two-mechanism system coordinates Hook injection (reliable context delivery) with Idle-hands monitor (active wake attempts).

**Resolution**: Two coordinated mechanisms.

**Mechanism 1: Session-Start Hook Injection**
- **What**: Inject context via Claude Code's hook system (`additionalContext`)
- **When**: Immediately when `/clear` triggers session-start hook
- **Reliability**: HIGH — `additionalContext` injection always works
- **Actions**:
  1. Detect JICM signals (`.clear-sent.signal` exists)
  2. Read and inject context files
  3. Create `.idle-hands-active` flag for Mechanism 2
- **Key Insight**: Hook can inject context but CANNOT force Jarvis to respond

**Mechanism 2: Idle-Hands Monitor (JICM Resume Mode)**
- **What**: Actively attempt prompt submission using multiple methods
- **When**: Triggered by `.idle-hands-active` flag with `mode: jicm_resume`
- **Reliability**: Iterative — tries 7 submission method variants until success
- **Actions**:
  1. Monitor for `.idle-hands-active` flag
  2. Check tmux pane for idle state
  3. Cycle through submission method variants (C-m, literal CR, literal LF, etc.)
  4. Detect success via pane content change
  5. Clean up on success, keep trying on failure

**Coordination**:
| Mechanism | Trigger | Role |
|-----------|---------|------|
| Hook Injection | SOURCE=clear + JICM signals | Reliable context delivery |
| Idle-Hands Monitor | `.idle-hands-active` flag | Active wake attempts |

**Principle**: Two mechanisms, coordinated via flag file. No single point of failure.

---

## Clarification #21: No Standdown for Resume System

**Issue**: I proposed standdown after 3 failures. User rejects — resume is like a defibrillator, keep going until success.

**Resolution**: JICM resume has NO standdown. Keep trying indefinitely.

**JICM Resume Behavior**:
- **Gated by**: JICM signal files present + idle state detected
- **Action**: Send resume prompts via all three mechanisms
- **Termination**: ONLY when Jarvis confirmed actively working
- **No timeout, no standdown, no giving up**

**Future: Idle-Hands Transition**:

After JICM resume succeeds:
- JICM signal files cleaned up
- JICM resume flavor ENDS

Later, if Jarvis idle for extended period (60+ min):
- Different "idle-hands" flavor activates
- Triggers: maintenance, reflection, research, brainstorming
- This is NOT JICM — separate idle-utilization system

**Distinction**:
| System | Trigger | Goal | Standdown? |
|--------|---------|------|------------|
| JICM Resume | Post-/clear + signals | Reawaken Jarvis | **NO** |
| Idle-Hands (future) | Extended idle (60+ min) | Background tasks | Yes |

**Principle**: JICM resume never gives up. Defibrillator, not suggestion.

---

## Clarification #22: JICM Doesn't Need Session Documentation Files (Final)

**Issue**: Confirming that JICM should NOT rely on session-state.md or current-priorities.md.

**Resolution**: Complete separation. JICM works from actual context content, not documentation.

**Session Documentation Files** (sessionStart/sessionEnd domain):
- `session-state.md` → Project status documentation
- `current-priorities.md` → Task backlog
- Updated by: sessionEnd
- Read by: sessionStart (NEW Session orientation)
- **JICM interaction: NONE**

**JICM Context Content** (from Claude Code logs):
- `~/.claude/projects/.../[session-id].jsonl` — Conversation
- `~/.claude/tasks/[session-id]/` — Task state
- `.claude/context/.context-captured.txt` — If available
- Subagent logs, debug logs, etc.

**JICM Data Flow**:
| Stage | Source | Output |
|-------|--------|--------|
| Compression | Claude Code logs (real context) | `.compressed-context-ready.md` |
| In-Progress Dump | Jarvis's current state | `.in-progress-ready.md` |
| Context Injection | Both files above | Fresh context window |

**Key Insight**:
- `session-state.md` = "What is this project about?" (ORIENTATION)
- Context window content = "What was I thinking/doing?" (MEMORY)
- JICM restores MEMORY. sessionStart provides ORIENTATION.

**No session-state.md. No current-priorities.md. Just real context content.**

---

## Summary

All 22 clarifications addressed and aligned. Key principles established:

1. **Identity**: Jarvis (main agent) vs compression agent (subagent) — clear separation
2. **Files**: Context files persist through /clear, deleted only after confirmed resume
3. **No greeting**: Post-/clear is status update + immediate work, never greeting
4. **Signal files trigger**: Not /clear itself — preserves native command behavior
5. **Unified entry**: Threshold → /intelligent-compress → same flow as manual
6. **Transparent, not invisible**: Informative, light-weight, seamless
7. **Native commands untouched**: /clear, /compact work as designed
8. **No session docs in JICM**: Uses real context content from Claude Code logs (READ, not WRITE)
9. **Mode-based idle-hands**: Unified system with modes (jicm_resume, long_idle, etc.)
10. **No fallbacks**: Circle back and retry, "do or die"
11. **Bulletproof prompts**: Proper formatting, multiple submission method variants
12. **Two resume mechanisms**: Hook injection + Idle-hands monitor (refined from three)
13. **No standdown**: JICM resume keeps trying until success
14. **Single 50% threshold**: Simplified from original 70%/80% dual threshold
15. **10k-30k compression target**: Aim for this token range in compressed output

---

**Status**: HISTORICAL REFERENCE — Synthesized into `jicm-v5-design-addendum.md`

*JICM v5 Clarifications — Finalized 2026-02-01 | Updated 2026-02-03*
