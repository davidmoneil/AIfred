# Ennoia — Aion Script for Session Orchestration & Idle-Time Work

**Date**: 2026-02-07
**Status**: Design Brainstorm (Wiggum loop, exit gate 10:15 MST)
**Author**: Jarvis (brainstorm session, user-present)

---

## 1. Literary Foundation

**Source**: Ennoia (ἔννοια) — in Gnostic cosmology, the "First Thought" or "Divine Intent." Ennoia is the first emanation of the divine mind, the original purposeful awareness before any action is taken. She represents *knowing what to do* before doing it.

**Parallel to Jarvis Aion Scripts**:
- **Watcher** = *Reflex* — monitors threats, reacts to danger (context exhaustion)
- **Virgil** = *Perception* — observes the landscape, presents what's visible
- **Ennoia** = *Intent* — determines purpose, decides what to do next

**Key principle**: Ennoia answers the question: *"I'm awake — what should I be doing?"* This is fundamentally different from Watcher's question (*"Am I in danger?"*) and Virgil's (*"What am I looking at?"*).

---

## 2. The Delineation Problem

### Current Entanglement

```
session-start.sh (hook)
├── Greeting & orientation (Ennoia's domain)
├── Context loading (Ennoia's domain)
├── Weather, AIfred baseline (Ennoia's domain)
├── Environment validation (Ennoia's domain)
├── Session options (Ennoia's domain)
├── JICM debounce (Watcher's domain)
├── JICM context restoration (Watcher's domain)
├── Idle-hands flag creation (Watcher's domain)
└── MCP suggestions (Ennoia's domain)

jarvis-watcher.sh
├── Context monitoring (Watcher's domain)
├── Compression orchestration (Watcher's domain)
├── idle_hands_jicm_resume() (Watcher's domain — resume after compression)
├── idle_hands_session_start() (ENTANGLED — mechanics=Watcher, intent=Ennoia)
├── Emergency recovery (Watcher's domain)
└── (no idle-time work scheduling — gap)

/maintain, /reflect, /research, /evolve, /self-improve
├── All manual-trigger commands
├── All have "idle detection" in specs (~30 min)
├── NO actual scheduler exists
└── NO automatic triggering implemented
```

### Proposed Clean Separation

| Concern | Owner | Responsibility |
|---------|-------|----------------|
| **Context safety** | Watcher | Monitor tokens, trigger compression, emergency recovery |
| **Wake-up mechanics** | Watcher | Keystroke injection, idle detection, TUI interaction |
| **Session intent** | Ennoia | What to work on, what maintenance to run, briefing |
| **Navigation awareness** | Virgil | File activity, codebase orientation, breadcrumbs |

**The handoff**: Watcher wakes Jarvis up (mechanics). Ennoia tells Jarvis what to do (intent). Session-start.sh becomes a thin dispatcher that calls both.

---

## 3. What Ennoia Owns

### 3.1 Session Start Protocol ("Awake and Arise")

When a genuinely new session begins (startup, resume after long gap):

1. **Orientation** — Time of day, date, weather, environment status
2. **Context Loading** — Read session-state.md, current-priorities.md
3. **Assessment** — What was I working on? What's pending? What's stale?
4. **Intent Formation** — Decide: continue work, start new task, or do maintenance
5. **Briefing** — Present findings and recommendation to user (or auto-proceed)

This is Phase A + B + C of AC-01, cleanly separated from JICM mechanics.

### 3.2 JICM Resume Protocol ("Resume Work")

When Jarvis wakes after context compression (NOT a new session):

1. **State Restoration** — Read compressed context, in-progress work
2. **Continuity Check** — Verify: what was I doing? pick up where I left off
3. **Brief Acknowledgment** — "Context restored. Continuing with [task]."

This is a minimal, fast path — no greeting, no weather, no maintenance assessment.

### 3.3 Idle-Time Work Scheduler ("What to Do When Nothing's Happening")

When Jarvis is awake but no user-directed task is active:

| Priority | Condition | Action | Duration |
|----------|-----------|--------|----------|
| 1 | Unpushed commits | Prompt user or auto-push (if configured) | 1 min |
| 2 | Stale session-state.md (>2h) | Update session-state.md | 2 min |
| 3 | Uncommitted changes | Suggest commit | 1 min |
| 4 | /reflect due (no reflection today) | Run /reflect | 10 min |
| 5 | /maintain due (>7 days since last) | Run /maintain | 15 min |
| 6 | Evolution queue (>3 low-risk items) | Run /evolve (low-risk only) | 10 min |
| 7 | Research backlog items | Run /research | 15 min |
| 8 | Record-keeping (logs, metrics) | Clean up, archive | 5 min |

**Idle detection**: Ennoia determines *what* to do. Watcher determines *when* to inject it (via existing idle-hands mechanics).

### 3.4 Inter-Session Continuity

Track across sessions:
- Last /reflect date → trigger if >1 day
- Last /maintain date → trigger if >7 days
- Last commit push → flag if >2 unpushed
- Session count since last /self-improve → trigger if >5

---

## 4. Architecture

```
DATA SOURCES                    PROCESSING                  OUTPUT
session-state.md ──┐
current-priorities ┤
watcher-status ────┤
idle-hands flag ───┼─→ ennoia.sh (bash)  ──→ tmux pane (jarvis:3)
maintenance-log ───┤   - 30s poll cycle       Session briefing
evolution-queue ───┤   - priority scheduler   Idle-work queue
AC-01 launch.json ─┤   - inter-session        Maintenance status
reflection-log ────┘     tracking             Dashboard display
```

### Process Model

Unlike session-start.sh (which runs once as a hook), Ennoia runs continuously alongside Watcher and Virgil. It:

1. **On session start**: Renders the full briefing dashboard
2. **During work**: Shows current intent, pending maintenance, session age
3. **On idle detection**: Evaluates priority queue, signals Watcher with recommended action
4. **On JICM resume**: Shows minimal restore status
5. **Between sessions**: Persists scheduler state for next session

### Signal File Coordination

```
Ennoia writes:
  .claude/context/.ennoia-recommendation     # Recommended idle-time action
  .claude/context/.ennoia-status              # Current state (YAML)

Watcher reads:
  .ennoia-recommendation                     # If idle-hands triggers, use this action

Session-start.sh:
  Becomes thin dispatcher → writes session source to .ennoia-trigger
  Ennoia reads trigger → renders appropriate briefing
```

---

## 5. The "Resume" vs "Arise" Delineation

This is the core design challenge. Clear, principled separation:

### "Resume Work" (Watcher's Domain)
**Trigger**: JICM compression cycle completes, /clear sent
**Context**: Mid-session, active work interrupted by compression
**Goal**: Get back to the exact task as fast as possible
**Behavior**: Read compressed context → continue immediately
**Latency target**: < 5 seconds to first action
**Dashboard**: Not needed (Watcher shows compression status)

### "Awake and Arise" (Ennoia's Domain)
**Trigger**: New session (startup), resume after long gap, --fresh flag
**Context**: Fresh start, need full orientation
**Goal**: Assess world state, decide what to do, present options
**Behavior**: Greeting → context load → assessment → briefing → action
**Latency target**: < 30 seconds to briefing complete
**Dashboard**: Full Ennoia dashboard with briefing, maintenance queue, session plan

### Gray Zone: --continue After Detach
When user detaches tmux and re-attaches hours later, `--continue` fires a `resume` event. Is this "resume work" or "awake and arise"?

**Resolution**: Time-based. If gap > 30 minutes since last activity, treat as "arise" (full briefing). If gap < 30 minutes, treat as "resume" (quick restore).

```bash
# Ennoia's gap detection
last_activity=$(stat -f %m "$SESSION_STATE_FILE" 2>/dev/null || echo 0)
now=$(date +%s)
gap=$(( now - last_activity ))

if [[ $gap -gt 1800 ]]; then
    mode="arise"    # Full briefing
else
    mode="resume"   # Quick restore
fi
```

---

## 6. Dashboard Layout (Mockup)

### Full Briefing Mode ("Arise")
```
╔══════════════════════════════════════════════════════╗
║  ENNOIA — Session Orchestrator         10:05 MST    ║
║  Good morning │ Saturday, Feb 7 │ 28°F, Clear       ║
╠══════════════════════════════════════════════════════╣
║                                                      ║
║  SESSION INTENT                                      ║
║  → Continue: MCP decomposition (session-state.md)    ║
║  → Pending: 2 commits unpushed to remote             ║
║  → Branch: Project_Aion (clean working tree)         ║
║                                                      ║
╠══════════════════════════════════════════════════════╣
║                                                      ║
║  MAINTENANCE QUEUE                                   ║
║  ▪ /reflect — due (last: never this session)         ║
║  ▪ /maintain — due in 3 days (last: Feb 4)           ║
║  ▪ /evolve — 2 low-risk proposals queued             ║
║  ▪ /research — RD-001 idle detection backlogged      ║
║                                                      ║
╠══════════════════════════════════════════════════════╣
║                                                      ║
║  SESSION OPTIONS                                     ║
║  1. Continue previous work                           ║
║  2. Review priorities backlog                        ║
║  3. Start new task                                   ║
║  4. Run health check (/tooling-health)               ║
║  5. Self-improvement (/reflect)                      ║
║  6. Maintenance (/maintain)                          ║
║                                                      ║
╠══════════════════════════════════════════════════════╣
║  Session: 0m │ Mode: arise │ Context: 18% (36K)     ║
║  Last session: Feb 7 07:16 UTC │ 5 compressions     ║
╚══════════════════════════════════════════════════════╝
```

### Steady-State Mode (During Work)
```
╔══════════════════════════════════════════════════════╗
║  ENNOIA — Session Orchestrator         10:12 MST    ║
╠══════════════════════════════════════════════════════╣
║                                                      ║
║  CURRENT INTENT: Brainstorming Ennoia Aion Script    ║
║  Session: 10m │ Active task: #6                      ║
║                                                      ║
║  MAINTENANCE QUEUE                                   ║
║  ▪ /reflect — due (idle trigger: 30m)                ║
║  ▪ 2 low-risk proposals (idle trigger: 45m)          ║
║                                                      ║
║  NEXT IDLE ACTION: /reflect (in 20m if idle)         ║
║                                                      ║
╠══════════════════════════════════════════════════════╣
║  Context: 38% │ Commits: 2 unpushed │ Branch: Aion  ║
╚══════════════════════════════════════════════════════╝
```

### Resume Mode (Post-JICM)
```
╔══════════════════════════════════════════════════════╗
║  ENNOIA — Resuming                     10:15 MST    ║
╠══════════════════════════════════════════════════════╣
║  Mode: resume │ Compression #5 complete              ║
║  Restoring: compressed-context + in-progress work    ║
║  → Continue: [task from compressed context]          ║
╚══════════════════════════════════════════════════════╝
```

---

## 7. Idle-Time Work Scheduler

### The Priority Queue

Ennoia maintains a priority-ordered queue of maintenance actions. Each action has:
- **Priority**: 1 (highest) to 8 (lowest)
- **Condition**: When should this trigger?
- **Cooldown**: Minimum time between triggers
- **Duration estimate**: How long will this take?
- **Impact**: Low (safe to auto-run) or Medium (ask first)

```bash
# Scheduler state file: .claude/context/.ennoia-scheduler
last_reflect: 2026-02-06T22:00:00Z
last_maintain: 2026-02-04T15:00:00Z
last_evolve: 2026-02-05T10:00:00Z
last_research: 2026-02-03T14:00:00Z
last_push: 2026-02-07T07:16:11Z
session_count_since_improve: 3
idle_minutes: 0
```

### Idle Detection Integration

Ennoia doesn't detect idle itself — it reads from Watcher (which already has `detect_idle_state()`). The coordination:

1. Watcher detects idle (no spinner, prompt visible, no activity for N minutes)
2. Watcher checks `.ennoia-recommendation` file
3. If recommendation exists, Watcher injects the recommended command
4. If no recommendation, Watcher does nothing (existing behavior)

This keeps Watcher as the mechanic (keystroke injection) and Ennoia as the brain (what to inject).

### Scheduler Logic (Pseudocode)

```bash
evaluate_idle_queue() {
    local idle_min=$1
    local now=$(date +%s)

    # Priority 1: Unpushed commits (always flag)
    local unpushed=$(git log --oneline origin/Project_Aion..HEAD 2>/dev/null | wc -l | tr -d ' ')
    if [[ $unpushed -gt 0 ]]; then
        echo "push" # Signal, not command — Ennoia flags it, user decides
        return 0
    fi

    # Priority 2: Stale session-state (>2h)
    local state_age=$(( now - $(stat -f %m "$SESSION_STATE_FILE" 2>/dev/null || echo 0) ))
    if [[ $state_age -gt 7200 ]]; then
        echo "update-state"
        return 0
    fi

    # Priority 3: /reflect due (>24h since last, idle >15m)
    if [[ $idle_min -ge 15 ]]; then
        local last_reflect=$(parse_epoch ".ennoia-scheduler" "last_reflect")
        if [[ $(( now - last_reflect )) -gt 86400 ]]; then
            echo "/reflect"
            return 0
        fi
    fi

    # Priority 4: /maintain due (>7d since last, idle >20m)
    if [[ $idle_min -ge 20 ]]; then
        local last_maintain=$(parse_epoch ".ennoia-scheduler" "last_maintain")
        if [[ $(( now - last_maintain )) -gt 604800 ]]; then
            echo "/maintain"
            return 0
        fi
    fi

    # Priority 5: /evolve (low-risk proposals queued, idle >25m)
    if [[ $idle_min -ge 25 ]]; then
        local queue_count=$(wc -l < ".claude/context/evolution-queue.yaml" 2>/dev/null || echo 0)
        if [[ $queue_count -gt 3 ]]; then
            echo "/evolve"
            return 0
        fi
    fi

    # Priority 6: /research (backlog items, idle >30m)
    if [[ $idle_min -ge 30 ]]; then
        echo "/research"
        return 0
    fi

    echo ""  # Nothing to do
    return 0
}
```

### Escalating Idle Thresholds

The scheduler uses escalating thresholds — more disruptive actions require longer idle periods:

```
0-5 min idle:   Nothing (user might be thinking)
5-15 min idle:  Flag unpushed commits, stale state (passive — dashboard only)
15-20 min idle: Suggest /reflect (low-impact, read-only analysis)
20-25 min idle: Suggest /maintain (medium-impact, may modify files)
25-30 min idle: Suggest /evolve (medium-impact, modifies code)
30+ min idle:   Suggest /research (low-impact, discovery only)
```

The key insight: **passive actions (flagging)** trigger early. **Active actions (running commands)** require progressively longer idle periods, giving the user time to return before Jarvis starts self-modifying.

---

## 8. Session-Start.sh Refactoring Vision

### Current: Monolithic 683-line hook
Everything in one file: greeting, JICM debounce, context restoration, weather, env checks, idle-hands flags.

### Proposed: Thin Dispatcher + Ennoia

```bash
# session-start.sh (refactored — ~100 lines)
# Responsibilities: JICM debounce, context restoration mechanics, flag creation
# Everything else delegated to Ennoia

SOURCE=$(echo "$INPUT" | jq -r '.source // "unknown"')

case "$SOURCE" in
    clear)
        # JICM debounce check (Watcher's domain)
        handle_jicm_debounce
        # If JICM v5 context files exist, inject them (Watcher's domain)
        handle_jicm_restoration
        ;;
    startup|resume)
        # Write trigger for Ennoia
        write_ennoia_trigger "$SOURCE"
        # Inject minimal context (Ennoia renders the rest)
        inject_session_context "$SOURCE"
        ;;
    compact)
        # Minimal — no action needed
        echo "{}"
        ;;
esac
```

Ennoia then reads the trigger file and renders the full briefing. The hook stays focused on *mechanics* (context injection, flags). Ennoia handles *intent* (briefing, scheduling, options).

### Migration Path
1. **v0.1**: Ennoia as dashboard only (reads existing hook output)
2. **v0.2**: Ennoia scheduler (idle-time work queue)
3. **v0.3**: Session-start.sh refactored to thin dispatcher
4. **v1.0**: Ennoia fully owns session intent, hook is pure mechanics

---

## 9. The Three Modes of Ennoia

| Mode | Trigger | Duration | Display |
|------|---------|----------|---------|
| **Arise** | New session, --fresh, gap >30m | First 2 min | Full briefing dashboard |
| **Attend** | Active work in progress | Continuous | Compact status + maintenance queue |
| **Idle** | No user activity for 5+ min | Until activity resumes | Scheduler queue + countdown to next action |

### Mode Transitions
```
                    ┌──────────────────────┐
                    │                      │
    session start ──▶  ARISE (briefing)  ──▶  ATTEND (working)
                    │                      │      │        ▲
                    └──────────────────────┘      │        │
                                                  ▼        │
                                           IDLE (schedule) ─┘
                                                  │
                                                  ▼
                                           (run maintenance)
                                                  │
                                                  ▼
                                           ATTEND (working)
```

---

## 10. Inter-Session Memory

Ennoia needs to persist state across sessions (unlike Watcher, which resets each time):

```yaml
# .claude/context/.ennoia-state (persistent)
version: 1
session_count: 47
total_compressions: 23
last_session_end: 2026-02-07T07:16:11Z

maintenance:
  last_reflect: 2026-02-06T22:00:00Z
  last_maintain: 2026-02-04T15:00:00Z
  last_evolve: 2026-02-05T10:00:00Z
  last_research: 2026-02-03T14:00:00Z
  last_self_improve: 2026-02-02T10:00:00Z

scheduler:
  pending_actions: []
  deferred_actions:
    - { action: "/reflect", reason: "session ended before completion", date: "2026-02-06" }
  auto_approved:
    - /reflect
    - /maintain
  requires_approval:
    - /evolve
    - /research
    - /self-improve

session_patterns:
  avg_session_duration: 4.2h
  avg_compressions_per_session: 4.8
  most_common_first_action: "continue_previous"
  peak_hours: [8, 9, 10, 14, 15]
```

This enables Ennoia to make *informed* scheduling decisions:
- "You usually do 4-5 compressions per session, so expect ~3 more"
- "You haven't reflected in 2 days — would you like to run /reflect?"
- "Last 3 sessions started with 'continue previous' — auto-selecting"

---

## 11. Integration with Other Aion Scripts

### Ennoia ↔ Watcher
| Direction | Data | Mechanism |
|-----------|------|-----------|
| Watcher → Ennoia | Token count, state, idle detection | `.watcher-status` file |
| Ennoia → Watcher | Recommended idle action | `.ennoia-recommendation` file |
| Watcher → Ennoia | Compression events | `.watcher-status` state changes |
| Ennoia → Watcher | (none — Ennoia never commands Watcher) | — |

### Ennoia ↔ Virgil
| Direction | Data | Mechanism |
|-----------|------|-----------|
| Ennoia → Virgil | Current intent, active task | `.ennoia-status` file |
| Virgil → Ennoia | (none — Virgil is display-only) | — |

### tmux Layout (with all Aion Scripts)
```
Window 0: Claude Code (main session)
Window 1: Watcher (context guardian)
Window 2: Virgil (codebase guide)
Window 3: Ennoia (session orchestrator)
```

Or as split panes:
```
┌──────────────────────────────────────────────┐
│                                              │
│              Claude Code (0)                 │
│                                              │
├──────────────┬───────────────┬───────────────┤
│ Watcher (1)  │ Virgil (2)    │ Ennoia (3)    │
└──────────────┴───────────────┴───────────────┘
```

---

## 12. The Aion Scripts Trinity — Unified Vision

| Script | Greek Root | Role | Question Answered | Audience |
|--------|-----------|------|-------------------|----------|
| **Watcher** | *Phylax* (guard) | Context guardian | "Am I safe?" | System |
| **Virgil** | *Hodegos* (guide) | Codebase navigator | "What am I looking at?" | User |
| **Ennoia** | *Ennoia* (intent) | Session orchestrator | "What should I do?" | Jarvis + User |

Future Aion Scripts:
- **Beatrice** — Session sage / quality reviewer ("Is this good enough?")
- **State-of-Mind (AC-10)** — Shared archive layer feeding all scripts

---

## 13. Handling the Session Options Timer

Currently, the Watcher has a `session_options` idle-hands mode (v5.8.1) that implements a 60-second countdown for `--continue` sessions, auto-selecting Option 1.

With Ennoia, this becomes cleaner:

1. Session-start.sh fires → Ennoia enters **Arise** mode
2. Ennoia renders the session options dashboard (options 1-6)
3. Ennoia writes `.ennoia-recommendation` with the default action
4. If `--continue`: recommendation = "1" (continue work), timer starts
5. If `--fresh`: recommendation = empty (wait for user), no timer
6. Watcher reads recommendation → after 60s idle, injects it

The timer logic stays in Watcher (it owns keystroke injection). The *decision* of what to auto-select comes from Ennoia.

---

## 14. Maintenance Workflow Consolidation

### Current State: 5 Separate Commands
Each command is independently triggered, independently logged, independently tracked. No unified view of "what maintenance has been done."

### Proposed: Ennoia Maintenance Dashboard Section

Ennoia tracks ALL maintenance actions and presents a unified view:

```
MAINTENANCE STATUS
┌──────────────┬───────────────┬──────────┬──────────┐
│ Action       │ Last Run      │ Status   │ Next Due │
├──────────────┼───────────────┼──────────┼──────────┤
│ /reflect     │ Feb 6 22:00   │ ● done   │ Today    │
│ /maintain    │ Feb 4 15:00   │ ● done   │ Feb 11   │
│ /evolve      │ Feb 5 10:00   │ ◐ 2 queued│ On idle │
│ /research    │ Feb 3 14:00   │ ○ stale  │ Overdue  │
│ /self-improve│ Feb 2 10:00   │ ○ stale  │ 5+ sess  │
└──────────────┴───────────────┴──────────┴──────────┘
```

Status indicators:
- `●` — Recently completed, on schedule
- `◐` — Has pending items (proposals, queue)
- `○` — Overdue or stale

### Auto-Scheduling Logic

Instead of requiring manual `/self-improve` invocations, Ennoia automatically schedules maintenance during idle periods:

```
Idle detected (15 min) → Ennoia evaluates queue →
  If /reflect due:    Signal Watcher → inject "/reflect"
  If /maintain due:   Signal Watcher → inject "/maintain"
  If /evolve ready:   Signal Watcher → inject "/evolve --low-risk-only"
  If nothing due:     Dashboard shows "All maintenance current ✓"
```

This is the "always improving" behavior the autonomic components were designed for, but never had the infrastructure to actually trigger.

---

## 15. Record-Keeping & Project Awareness

Ennoia also handles routine record-keeping:

### Session Journal
```yaml
# .claude/logs/session-journal.yaml (append-only)
- session_id: "2026-02-07-0700"
  started: "2026-02-07T07:00:00Z"
  ended: null  # Updated by /end-session
  type: continue
  compressions: 5
  commits: ["62cb798", "ca4bdef"]
  tasks_completed: ["M1", "M2", "M3", "M4", "M5"]
  maintenance_run: ["/reflect"]
  key_files: ["jarvis-watcher.sh", "session-start.sh", "CLAUDE.md"]
  notes: "MCP decomposition + session start redesign (v5.8.1)"
```

### Project Context Awareness
Ennoia knows which project is active and adjusts:
- **Jarvis project**: Self-improvement commands available, full autonomic suite
- **Other project**: Focus on project-specific tasks, limit self-improvement to reflection
- **No project**: Offer to create new project or select existing

---

## 16. v0.1 Implementation Skeleton

```bash
#!/usr/bin/env bash
# ennoia.sh — Session Orchestrator Aion Script v0.1
# Runs in tmux jarvis:3, 30s refresh cycle
# Read-only (except .ennoia-status), no keystroke injection

set -euo pipefail

PROJECT_DIR="${JARVIS_PROJECT_DIR:-/Users/aircannon/Claude/Jarvis}"
SESSION_STATE="$PROJECT_DIR/.claude/context/session-state.md"
PRIORITIES="$PROJECT_DIR/.claude/context/current-priorities.md"
WATCHER_STATUS="$PROJECT_DIR/.claude/context/.watcher-status"
ENNOIA_STATE="$PROJECT_DIR/.claude/context/.ennoia-state"
ENNOIA_STATUS="$PROJECT_DIR/.claude/context/.ennoia-status"
ENNOIA_RECOMMENDATION="$PROJECT_DIR/.claude/context/.ennoia-recommendation"
SCHEDULER="$PROJECT_DIR/.claude/context/.ennoia-scheduler"
REFRESH=30

# Initialize state if first run
init_state() {
    if [[ ! -f "$ENNOIA_STATE" ]]; then
        cat > "$ENNOIA_STATE" <<EOF
version: 1
session_count: 1
last_session_end: null
maintenance:
  last_reflect: null
  last_maintain: null
  last_evolve: null
  last_research: null
EOF
    fi
}

# Determine mode: arise, attend, or idle
detect_mode() {
    local state watcher_state
    watcher_state=$(awk '/^state:/{print $2}' "$WATCHER_STATUS" 2>/dev/null)

    # If watcher just cleared → resume mode (brief)
    if [[ "$watcher_state" == "cleared" ]]; then
        echo "resume"
        return 0
    fi

    # Check if session just started (uptime < 2 min)
    local start_time
    start_time=$(stat -f %m "$ENNOIA_STATUS" 2>/dev/null || echo 0)
    local now=$(date +%s)
    local uptime=$(( now - start_time ))
    if [[ $uptime -lt 120 ]]; then
        echo "arise"
        return 0
    fi

    # Check idle (no file-access.json updates for 5+ min)
    local fa_mtime
    fa_mtime=$(stat -f %m "$PROJECT_DIR/.claude/logs/file-access.json" 2>/dev/null || echo 0)
    local idle_seconds=$(( now - fa_mtime ))
    if [[ $idle_seconds -gt 300 ]]; then
        echo "idle"
        return 0
    fi

    echo "attend"
    return 0
}

# Get session intent from session-state.md
get_intent() {
    grep "Current Work" "$SESSION_STATE" 2>/dev/null | head -1 | sed 's/.*: //'
}

# Get maintenance status
get_maintenance_status() {
    # Simplified: check file modification times as proxy for last run
    local reflect_log="$PROJECT_DIR/.claude/reports/reflections"
    local maintain_log="$PROJECT_DIR/.claude/reports/maintenance"

    local now=$(date +%s)
    local reflect_age="never"
    local maintain_age="never"

    if [[ -d "$reflect_log" ]]; then
        local latest=$(ls -t "$reflect_log"/*.md 2>/dev/null | head -1)
        if [[ -n "$latest" ]]; then
            local mtime=$(stat -f %m "$latest")
            local days=$(( (now - mtime) / 86400 ))
            reflect_age="${days}d ago"
        fi
    fi

    if [[ -d "$maintain_log" ]]; then
        local latest=$(ls -t "$maintain_log"/*.md 2>/dev/null | head -1)
        if [[ -n "$latest" ]]; then
            local mtime=$(stat -f %m "$latest")
            local days=$(( (now - mtime) / 86400 ))
            maintain_age="${days}d ago"
        fi
    fi

    echo "reflect:$reflect_age maintain:$maintain_age"
}

# Render dashboard
render() {
    local mode=$(detect_mode)
    local cols=$(tput cols 2>/dev/null || echo 55)

    tput cup 0 0 2>/dev/null
    tput ed 2>/dev/null

    # Header
    printf '\e[1;35m ENNOIA\e[0m — Session Orchestrator'
    printf '%*s\n' $((cols - 35)) "$(date '+%H:%M %Z')"
    printf '%.0s─' $(seq 1 "$cols"); echo

    case "$mode" in
        arise)
            echo -e "\n\e[1m  SESSION INTENT\e[0m"
            echo "  → $(get_intent)"
            local unpushed=$(git -C "$PROJECT_DIR" log --oneline origin/Project_Aion..HEAD 2>/dev/null | wc -l | tr -d ' ')
            [[ $unpushed -gt 0 ]] && echo "  → $unpushed commits unpushed"
            local branch=$(git -C "$PROJECT_DIR" branch --show-current 2>/dev/null)
            echo "  → Branch: ${branch:-unknown}"

            echo -e "\n\e[1m  MAINTENANCE QUEUE\e[0m"
            local maint=$(get_maintenance_status)
            echo "  ▪ /reflect — last: $(echo "$maint" | grep -o 'reflect:[^ ]*' | cut -d: -f2)"
            echo "  ▪ /maintain — last: $(echo "$maint" | grep -o 'maintain:[^ ]*' | cut -d: -f2)"
            ;;

        attend)
            echo -e "\n  CURRENT: $(get_intent)"
            local pct=$(awk '/^percentage:/{print $2}' "$WATCHER_STATUS" 2>/dev/null)
            echo "  Context: ${pct:-?}"
            ;;

        idle)
            echo -e "\n\e[33m  IDLE\e[0m — Evaluating maintenance queue..."
            local maint=$(get_maintenance_status)
            echo "  ▪ /reflect — last: $(echo "$maint" | grep -o 'reflect:[^ ]*' | cut -d: -f2)"
            echo "  ▪ /maintain — last: $(echo "$maint" | grep -o 'maintain:[^ ]*' | cut -d: -f2)"
            ;;

        resume)
            echo -e "\n  Resuming after context compression..."
            echo "  Reading compressed context..."
            ;;
    esac

    # Footer
    printf '\n%.0s─' $(seq 1 "$cols"); echo
    local tokens=$(awk '/^tokens:/{print $2}' "$WATCHER_STATUS" 2>/dev/null)
    local pct=$(awk '/^percentage:/{print $2}' "$WATCHER_STATUS" 2>/dev/null)
    printf '  Mode: %s │ Context: %s (%s)\n' "$mode" "${pct:-?}" "${tokens:-?}"

    # Update status file
    cat > "$ENNOIA_STATUS" <<EOF
timestamp: $(date -u +%Y-%m-%dT%H:%M:%SZ)
mode: $mode
intent: $(get_intent)
EOF
}

# Main loop
init_state
while true; do
    render 2>/dev/null || true
    sleep "$REFRESH"
done
```

**Estimated**: ~150 lines bash. Dashboard-focused for v0.1, scheduler deferred to v0.2.

---

## 17. Evolution Roadmap

| Version | Features | Scope |
|---------|----------|-------|
| **v0.1** | Dashboard: mode detection, intent display, maintenance status | Display only |
| **v0.2** | Idle scheduler: priority queue, .ennoia-recommendation signal | + Signal files |
| **v0.3** | Session-start.sh refactoring: thin dispatcher + Ennoia intent | + Hook changes |
| **v0.4** | Inter-session memory: .ennoia-state persistence, session journal | + State files |
| **v1.0** | Full orchestration: auto-maintenance, session patterns, project awareness | Full system |

### v0.1 Acceptance Criteria
1. Dashboard renders in tmux pane (arise/attend/idle/resume modes)
2. Reads session-state.md for current intent
3. Shows maintenance queue with last-run dates
4. Shows git status (unpushed commits, branch)
5. Reads .watcher-status for context metrics
6. 30s refresh cycle, fixed layout (no scrolling)
7. No keystroke injection, no file modification (except .ennoia-status)

---

## 18. Open Questions for User

1. **Auto-approval**: Should Ennoia auto-run /reflect and /maintain during idle, or always ask first?
2. **Idle threshold**: 15 minutes for /reflect, 30 minutes for /research — reasonable?
3. **Session-start.sh**: Refactor to thin dispatcher (v0.3) or keep monolithic?
4. **tmux layout**: Window 3 or split pane with Watcher/Virgil?
5. **Project awareness**: Jarvis-specific from v0.1, or project-agnostic?

---

## 19. Critical Design Insight: The Intent Layer

What makes Ennoia fundamentally different from a task scheduler or cron job:

**Ennoia understands *context*.** A cron job runs /maintain every Tuesday. Ennoia runs /maintain when:
- It hasn't been run in >7 days AND
- The user is idle for >20 minutes AND
- Context is below 50% (enough room for maintenance output) AND
- No active task is in progress AND
- The last compression wasn't within the last 10 minutes (stability)

This is **contextual scheduling** — the same action triggers at different times depending on the state of the system. This is what makes it an Aion Script rather than a cron job.

---

## 20. Brainstorm Evolution Summary
- Iterations 1-2: Current state map, entanglement analysis, delineation problem
- Iteration 3: Clean separation — Watcher=mechanics, Ennoia=intent, session-start=dispatcher
- Iteration 4: Dashboard mockups (arise/attend/idle/resume modes)
- Iteration 5: Idle-time scheduler with escalating thresholds
- Iteration 6: Session-start.sh refactoring vision (683→~100 lines)
- Iteration 7: Inter-session memory, session journal, project awareness
- Iteration 8: Integration with Watcher/Virgil, signal file coordination
- Iteration 9: v0.1 implementation skeleton (~150 lines)
- Iteration 10: Self-review — contextual scheduling insight, gap analysis
- Iteration 11: Evolution roadmap, acceptance criteria

---

## 21. Safety: "While You Were Away" + Reversibility

### The "Do No Harm" Principle for Idle-Time Work

If Ennoia auto-triggers actions during idle, the user must never return to surprises. Safety mechanisms:

1. **Read-only actions first**: /reflect and /research are read-only (produce reports, don't modify code). These are safest for auto-triggering.
2. **Git stash before /evolve**: Before any code-modifying action, create `git stash push -m "ennoia-pre-evolve-$(date +%s)"`. If user disapproves, `git stash pop` reverses everything.
3. **Audit log**: Every idle-triggered action logged to `.claude/logs/ennoia-idle-actions.log`
4. **"While You Were Away" summary**: When user returns, dashboard shows what Ennoia did:

```
WHILE YOU WERE AWAY (32 min idle)
▪ /reflect completed — 3 new insights documented
▪ session-state.md updated (staleness fix)
▪ No code changes made
▪ Stash: ennoia-pre-evolve-1739005200 (reversible)
```

5. **Approval tiers**:
   - **Auto-approve**: /reflect, /maintain (read-only analysis, cleanup)
   - **Ask first**: /evolve, /self-improve (code modification)
   - **Never auto**: /research with external API calls (cost implications)

### Gradual Migration Path

Session-start.sh is critical infrastructure. Ennoia must prove itself before the hook is refactored:

| Phase | session-start.sh | Ennoia |
|-------|-----------------|--------|
| **v0.1** | Unchanged (683 lines) | Reads existing output, dashboard only |
| **v0.2** | Unchanged | Adds scheduler, writes .ennoia-recommendation |
| **v0.3** | Extract greeting/weather/env to Ennoia helper | Ennoia renders briefing |
| **v0.4** | Thin dispatcher (~100 lines) | Owns session intent fully |
| **v1.0** | Pure mechanics (JICM debounce, flags) | Full session orchestration |

Each phase can be validated independently. Rollback = remove Ennoia and session-start.sh works exactly as before.

---

## 22. The Timer Handoff Pattern

The `--continue` 60-second auto-select timer (v5.8.1 design) cleanly splits between Ennoia and Watcher:

```
Ennoia:                          Watcher:
┌─────────────────────┐          ┌─────────────────────┐
│ Evaluate: --continue │          │ Read .ennoia-rec    │
│ Default action: "1"  │──write──▶│ Idle detected?      │
│ Timer: 60s           │          │ Timer expired?      │
│ Display countdown    │          │ → Inject keystroke  │
└─────────────────────┘          └─────────────────────┘
```

Ennoia decides *what* and *when*. Watcher executes *how* (keystroke injection).

---

## 23. "Ennoia's Notebook" — The Intent Journal

A lightweight append-only log that captures every intent decision:

```
2026-02-07T10:05:00Z | ARISE | intent=continue_previous | options_presented=6
2026-02-07T10:05:30Z | ATTEND | intent=brainstorm_ennoia | task=#6
2026-02-07T10:35:00Z | IDLE | detected=5min | evaluating_queue
2026-02-07T10:50:00Z | IDLE | action=/reflect | trigger=overdue_24h
2026-02-07T11:05:00Z | ATTEND | user_returned | away_summary_shown
```

This feeds into State-of-Mind (AC-10) — the intent journal is a record of *why* Jarvis did things, not just *what* it did (which file-access.json captures).

---

## 24. Comparison: All Four Aion Scripts

| Aspect | Watcher | Virgil | Ennoia | Beatrice (future) |
|--------|---------|--------|--------|-------------------|
| Question | "Am I safe?" | "What am I looking at?" | "What should I do?" | "Is this good enough?" |
| Domain | Context safety | Codebase navigation | Session orchestration | Quality assessment |
| Actions | Sends commands | Display only | Writes recommendations | Display + reports |
| Audience | System (Jarvis) | User (human) | Both | Both |
| Poll cycle | 5s (fast) | 15s (medium) | 30s (slow) | On-demand |
| Criticality | System-critical | QoL | Operational | QoL |
| Failure mode | Context lockout | Stale dashboard | No auto-maintenance | No quality checks |
| Data source | TUI pane content | file-access.json | session-state + scheduler | Code analysis |

---

## 20. Brainstorm Evolution Summary (Updated)
- Iterations 1-2: Current state map, entanglement analysis, delineation problem
- Iteration 3: Clean separation — Watcher=mechanics, Ennoia=intent, session-start=dispatcher
- Iteration 4: Dashboard mockups (arise/attend/idle/resume modes)
- Iteration 5: Idle-time scheduler with escalating thresholds
- Iteration 6: Session-start.sh refactoring vision (683→~100 lines)
- Iteration 7: Inter-session memory, session journal, project awareness
- Iteration 8: Integration with Watcher/Virgil, signal file coordination
- Iteration 9: v0.1 implementation skeleton (~150 lines)
- Iteration 10: Self-review — contextual scheduling insight, gap analysis
- Iteration 11: Evolution roadmap, acceptance criteria, open questions
- Iteration 12: Safety — "While You Were Away" summary, reversibility, approval tiers
- Iteration 13: Timer handoff pattern (Ennoia decides, Watcher executes)
- Iteration 14: Intent journal for State-of-Mind, full Aion Script comparison table

---

---

## 25. Beyond Scheduling: Intent as Contextual Awareness

A deeper insight emerged in later iterations. Ennoia isn't just a scheduler — it's an **intent layer** that understands *momentum, rhythm, and balance*.

### The Difference
| System | Logic | Example |
|--------|-------|---------|
| Cron job | "7 days since last run" | Run /maintain every Tuesday |
| Scheduler | "7 days + idle > 20m" | Run /maintain when idle and overdue |
| **Ennoia** | "3 sessions of rapid building, 400 new lines, no reflection" | "Extended building phase. A /reflect would help consolidate learnings." |

Ennoia tracks:
- **Momentum**: How many consecutive work sessions without pause?
- **Velocity**: Token burn rate, files created/modified per hour, commit frequency
- **Balance**: Ratio of building vs reviewing vs maintaining
- **Rhythm**: Time-of-day patterns (user tends to review in afternoons)

This contextual awareness is the difference between a tool and a collaborator. A v1.0+ feature, but the architecture should support it from v0.1 (by collecting data in .ennoia-state).

### Work/Review/Maintain Balance (v1.0 Vision)
```
SESSION BALANCE
  Build:   ████████████████░░░░  80%
  Review:  ██░░░░░░░░░░░░░░░░░░  10%
  Maintain:██░░░░░░░░░░░░░░░░░░  10%

  Ennoia suggests: Session has been build-heavy.
  Consider: /reflect or /code-review before continuing.
```

---

## 26. Project-Aware Maintenance

Ennoia handles maintenance for BOTH Jarvis and the active project:

### Jarvis Maintenance (Self-Improvement)
| Action | Trigger | Impact |
|--------|---------|--------|
| /reflect | >24h since last | Analyze corrections, generate insights |
| /maintain | >7d since last | Cleanup logs, validate hooks, freshness audit |
| /evolve | >3 low-risk proposals queued | Implement queued improvements |
| /research | Backlog items exist | Discover new tools/patterns |

### Project Maintenance (Active Project)
| Action | Trigger | Impact |
|--------|---------|--------|
| Run tests | >2h since last test run | Catch regressions |
| Dependency check | >7d since last check | Flag outdated packages |
| TODO/FIXME scan | Session start | Surface technical debt |
| Doc freshness | >14d since doc update | Flag stale documentation |
| Coverage check | After significant code changes | Identify untested code |

### Selection Logic
```bash
get_project_type() {
    # Detect project characteristics
    if [[ -f "package.json" ]]; then echo "node"
    elif [[ -f "requirements.txt" ]] || [[ -f "pyproject.toml" ]]; then echo "python"
    elif [[ -f "Cargo.toml" ]]; then echo "rust"
    elif [[ -f "go.mod" ]]; then echo "go"
    elif [[ -f "CLAUDE.md" ]] && grep -q "Jarvis" "CLAUDE.md" 2>/dev/null; then echo "jarvis"
    else echo "generic"
    fi
}
```

For Jarvis projects: full autonomic suite (AC-05 through AC-08).
For other projects: project-specific checks + generic git hygiene.

---

## 20. Brainstorm Evolution Summary (Final)
- Iterations 1-2: Current state map, entanglement analysis, delineation problem
- Iteration 3: Clean separation — Watcher=mechanics, Ennoia=intent, session-start=dispatcher
- Iteration 4: Dashboard mockups (arise/attend/idle/resume modes)
- Iteration 5: Idle-time scheduler with escalating thresholds
- Iteration 6: Session-start.sh refactoring vision (683→~100 lines)
- Iteration 7: Inter-session memory, session journal, project awareness
- Iteration 8: Integration with Watcher/Virgil, signal file coordination
- Iteration 9: v0.1 implementation skeleton (~150 lines)
- Iteration 10: Self-review — contextual scheduling insight, gap analysis
- Iteration 11: Evolution roadmap, acceptance criteria, open questions
- Iteration 12: Safety — "While You Were Away" summary, reversibility, approval tiers
- Iteration 13: Timer handoff pattern (Ennoia decides, Watcher executes)
- Iteration 14: Intent journal for State-of-Mind, full Aion Script comparison table
- Iteration 15: Deeper question — intent as contextual awareness, not just scheduling
- Iteration 16: Rhythm of work — momentum, velocity, balance tracking
- Iteration 17: Project-aware maintenance — Jarvis vs active project actions

---

---

## 27. Critical Review — What Would Break This?

### Race Conditions
**Problem**: Ennoia writes `.ennoia-recommendation` while Watcher reads it.
**Fix**: Atomic write — `echo "action" > .ennoia-recommendation.tmp && mv .ennoia-recommendation.tmp .ennoia-recommendation`. Already used for signal files in Watcher.

### Session Start Latency
**Problem**: 30s poll means the arise briefing could appear 30s after session start.
**Fix**: Ennoia watches for `.ennoia-trigger` file (created by session-start.sh) using `inotifywait` or a tight 1s poll loop during trigger detection. Falls back to 30s polling in steady state.

### Screen Real Estate
**Problem**: Four tmux panes (Claude + Watcher + Virgil + Ennoia) is cramped on a laptop.
**Solutions**:
- **Option A**: Ennoia shares a pane with Virgil (split horizontally)
- **Option B**: Ennoia appears as a full-screen popup at session start, then shrinks to a single status line
- **Option C**: Ennoia renders to Virgil's dashboard (Virgil gets an "intent" section from Ennoia's status file)
- **Recommendation**: Option C for v0.1 (Virgil consumes .ennoia-status). Separate pane for v0.2+ when the scheduler needs its own space.

### False Idle Detection
**Problem**: User reading output ≠ user away. Injecting /reflect while user is reading is jarring.
**Fix**: Higher thresholds (30+ min), visible countdown: "Running /reflect in 5m unless interrupted." The countdown is visible in both Ennoia's dashboard and Virgil's "Virgil Says" recommendation.

### /code-review as Idle Action
The user mentioned /code-review explicitly. This fits naturally into the maintenance queue:

| Priority | Idle Threshold | Action | Condition |
|----------|---------------|--------|-----------|
| 2.5 | 10 min | Code review | >3 files modified since last commit |

Auto-triggering a code-review agent on uncommitted changes during idle is low-risk (read-only analysis) and high-value (catches issues before commit). This should be in the v0.2 scheduler.

---

## 28. Alternative: Ennoia as a Virgil Section (v0.1 Pragmatic)

Instead of a fourth tmux pane, Ennoia v0.1 could be a section *within* Virgil's dashboard:

```
╔═══════════════════════════════════════════════════════╗
║  VIRGIL — Codebase Guide                 10:12 MST   ║
╠═══════════════════════════════════════════════════════╣
║                                                       ║
║  ACTIVE FILES (last 10 min)                           ║
║  ...                                                  ║
║                                                       ║
║  CHANGES (uncommitted)                                ║
║  ...                                                  ║
║                                                       ║
║  ┌─ ENNOIA ─────────────────────────────────────────┐ ║
║  │  Intent: Brainstorming Ennoia design              │ ║
║  │  Maintenance: /reflect due │ /maintain in 3d     │ ║
║  │  Next idle action: /reflect (in 20m if idle)     │ ║
║  └──────────────────────────────────────────────────┘ ║
║                                                       ║
║  ☞ Virgil says: 2 commits unpushed to remote.         ║
╚═══════════════════════════════════════════════════════╝
```

This gives Ennoia visibility without consuming another pane. The scheduler still runs as a separate process (writing .ennoia-status), but rendering is delegated to Virgil.

**Pros**: No extra pane, immediate integration
**Cons**: Less room for Ennoia's full dashboard, entangles Virgil and Ennoia

This could be the v0.1 approach, with a dedicated pane at v0.3 when the scheduler is mature enough to justify the real estate.

---

## 20. Brainstorm Evolution Summary (Final)
- Iterations 1-2: Current state map, entanglement analysis, delineation problem
- Iteration 3: Clean separation — Watcher=mechanics, Ennoia=intent, session-start=dispatcher
- Iteration 4: Dashboard mockups (arise/attend/idle/resume modes)
- Iteration 5: Idle-time scheduler with escalating thresholds
- Iteration 6: Session-start.sh refactoring vision (683→~100 lines)
- Iteration 7: Inter-session memory, session journal, project awareness
- Iteration 8: Integration with Watcher/Virgil, signal file coordination
- Iteration 9: v0.1 implementation skeleton (~150 lines)
- Iteration 10: Self-review — contextual scheduling insight, gap analysis
- Iteration 11: Evolution roadmap, acceptance criteria, open questions
- Iteration 12: Safety — "While You Were Away" summary, reversibility, approval tiers
- Iteration 13: Timer handoff pattern (Ennoia decides, Watcher executes)
- Iteration 14: Intent journal for State-of-Mind, full Aion Script comparison table
- Iteration 15: Deeper question — intent as contextual awareness, not just scheduling
- Iteration 16: Rhythm of work — momentum, velocity, balance tracking
- Iteration 17: Project-aware maintenance — Jarvis vs active project actions
- Iteration 18: Critical review — race conditions, latency, screen real estate
- Iteration 19: Alternative v0.1 — Ennoia as a section within Virgil's dashboard
- Iteration 20: /code-review as idle action, countdown visibility, final gap analysis

---

---

## 29. Full Lifecycle Integration Map

Clean data flow — no circular dependencies:

```
SESSION LIFECYCLE

  launch-jarvis-tmux.sh
  ├── Starts Claude Code (window 0)
  ├── Starts Watcher (window 1)
  ├── Starts Virgil (window 2)
  └── Starts Ennoia (window 3, or embedded in Virgil)

  session-start.sh (hook, fires in Claude process)
  ├── JICM debounce + context restoration → Watcher domain
  ├── Writes .ennoia-trigger → Ennoia domain
  ├── Creates .idle-hands-active → Watcher + Ennoia bridge
  └── Returns additionalContext → Claude consumes

  Watcher (continuous, window 1)
  ├── Monitors context % → triggers compression
  ├── Detects idle → reads .ennoia-recommendation
  ├── Injects keystrokes when needed
  └── Writes: .watcher-status, jarvis-watcher.log

  Virgil (continuous, window 2)
  ├── Reads: file-access.json, git status
  ├── Reads: .watcher-status, .ennoia-status
  └── Writes: display only (no files except own status)

  Ennoia (continuous, window 3 or Virgil section)
  ├── Reads: session-state, priorities, .watcher-status
  ├── Evaluates maintenance queue
  ├── Writes: .ennoia-status, .ennoia-recommendation, .ennoia-state
  └── Logs: ennoia-intent-journal.log
```

Data flows: session-start.sh → Ennoia ↔ status files ← Watcher/Virgil.
No circular dependencies. Each script reads shared files but only writes its own.

---

## 30. Plan File Tracking (User-Mentioned /plan)

The user mentioned `/plan` as an idle-time workflow. Ennoia tracks plan file status:

```
PLAN STATUS
  Active: transient-tumbling-allen.md (3 items remaining)
  Stale:  virgil-angel-script-design.md (no updates in 2h)
  New:    watcher-aion-script-redesign.md (created today)
```

During idle, Ennoia could suggest:
- "Plan file has 3 uncompleted items — continue work?"
- "No active plan — would you like to plan the next milestone?"
- "Plan completed — run /review-milestone?"

---

## 20. Brainstorm Evolution Summary (Final)
- Iterations 1-2: Current state map, entanglement analysis
- Iteration 3: Clean separation — Watcher=mechanics, Ennoia=intent
- Iteration 4: Dashboard mockups (4 modes)
- Iteration 5: Idle-time scheduler with escalating thresholds
- Iteration 6: Session-start.sh refactoring vision
- Iterations 7-8: Inter-session memory, signal coordination
- Iteration 9: v0.1 implementation skeleton
- Iterations 10-11: Contextual scheduling insight, roadmap
- Iterations 12-13: Safety, timer handoff, approval tiers
- Iteration 14: Intent journal, Aion Script comparison
- Iterations 15-16: Intent as awareness (not scheduling), work rhythm
- Iteration 17: Project-aware maintenance (Jarvis + active project)
- Iterations 18-19: Critical review, Ennoia-in-Virgil alternative
- Iteration 20: /code-review as idle action
- Iteration 21: Nomenclature validation (Gnostic Ennoia = First Thought)
- Iteration 22: /plan tracking as idle workflow
- Iteration 23: Full lifecycle integration map — clean data flow

---

---

## 31. The "Nudge" vs "Action" Spectrum

A key design insight: Ennoia delivers value even without the scheduler. The dashboard alone is a **nudge** — showing overdue maintenance creates awareness without forcing action.

| Level | Mechanism | Example | Version |
|-------|-----------|---------|---------|
| **Visibility** | Dashboard display | "/reflect — ○ overdue (2d ago)" | v0.1 |
| **Nudge** | Status symbol + color | Red `○` means overdue, green `●` means current | v0.1 |
| **Suggestion** | "Virgil Says" integration | "Consider /reflect — no reflection in 2 days" | v0.2 |
| **Countdown** | Idle timer visible | "Running /reflect in 5m unless interrupted" | v0.2 |
| **Action** | Auto-trigger via Watcher | Inject /reflect command after 30m idle | v0.3 |

Each level builds on the previous. v0.1 delivers value (nudge) with zero risk (display-only, no actions).

### Absolute Minimum v0.1 (~80 lines)
```bash
# Just read + display, nothing else:
# 1. session-state.md → current intent
# 2. git status → unpushed/uncommitted
# 3. .watcher-status → context level
# 4. Report directories → last /reflect, /maintain dates
# 5. Fixed dashboard, 30s refresh
```

This is the "honest" v0.1 — and the nudge alone has value because *visibility creates action*.

---

---

## 32. Context-Aware Scheduling — The Token Budget Constraint

Maintenance commands consume context tokens. Ennoia must factor this in:

```
Context < 30%:   Post-clear, maximum headroom → allow short maintenance (/reflect ~5K)
Context 30-50%:  Comfortable → allow medium maintenance (/maintain ~10K)
Context 50-65%:  Approaching threshold → flag but don't auto-trigger
Context > 65%:   Compression imminent → no auto-maintenance
```

This prevents the ironic scenario of auto-triggering /reflect that consumes 10K tokens, pushing context to 75%, triggering compression, losing the reflection output. Ennoia is context-aware precisely because it reads `.watcher-status` every cycle.

### Optimal Maintenance Window
The best time for auto-maintenance is immediately after a successful compression cycle:
- Context just dropped to ~18-20%
- ~130K tokens of headroom available
- User hasn't resumed yet (brief window)
- /reflect or /maintain fit comfortably

Ennoia detects this window via `.watcher-status` state transitions:
```
monitoring at 71% → compression_triggered → cleared → monitoring at 18%
                                                       ^^^ MAINTENANCE WINDOW
```

---

## 33. Concrete Scenario Traces

### Scenario A: Fresh session (--fresh)
```
session-start.sh → .ennoia-trigger (source=startup, type=fresh)
Ennoia → ARISE mode → full briefing dashboard
Ennoia → .ennoia-recommendation = "" (no auto-select for fresh)
Watcher → .idle-hands-active → monitors → no timeout (fresh waits for user)
User selects option → Claude starts → Ennoia → ATTEND mode
```

### Scenario B: Continue session (--continue)
```
session-start.sh → .ennoia-trigger (source=startup, type=continue)
Ennoia → ARISE mode → briefing with "continuing previous work" default
Ennoia → .ennoia-recommendation = "1" (auto-select continue)
Watcher → .idle-hands-active → 60s countdown → injects "1"
Claude continues → Ennoia → ATTEND mode
```

### Scenario C: JICM compression
```
Watcher → compression done → /clear → .watcher-status=cleared
session-start.sh → injects compressed context + .idle-hands-active
Ennoia → detects cleared state → RESUME mode (minimal dashboard)
Watcher → idle detection → injects resume prompt
Claude resumes → Ennoia → ATTEND mode
```

### Scenario D: Idle maintenance trigger
```
Ennoia in ATTEND mode → file-access.json stale for 20 min
Ennoia → IDLE mode → evaluates queue → /reflect due, context at 35%
Ennoia → .ennoia-recommendation = "/reflect" → dashboard shows countdown
Watcher → reads recommendation → detects idle → injects "/reflect"
Claude runs /reflect → Ennoia → ATTEND mode
Ennoia → updates .ennoia-state (last_reflect = now)
Dashboard → "While you were away: /reflect completed"
```

---

## 20. Brainstorm Evolution Summary (Final)
- Iterations 1-3: Current state map, entanglement analysis, clean separation principle
- Iterations 4-6: Dashboard mockups, scheduler, session-start refactoring vision
- Iterations 7-9: Inter-session memory, integration, v0.1 skeleton
- Iterations 10-11: Contextual scheduling insight, roadmap, acceptance criteria
- Iterations 12-14: Safety (reversibility, approval tiers), timer handoff, intent journal
- Iterations 15-17: Intent as awareness, work rhythm, project-aware maintenance
- Iterations 18-20: Critical review, Ennoia-in-Virgil alternative, /code-review
- Iterations 21-23: Nomenclature, /plan tracking, full lifecycle map
- Iterations 24-25: Minimal v0.1, nudge vs action spectrum
- Iterations 26-27: Concrete scenario traces, context-aware scheduling (token budget constraint)

---

*Brainstorm produced over 27 Wiggum loop iterations, 2026-02-07 10:02-10:15 MST.*
