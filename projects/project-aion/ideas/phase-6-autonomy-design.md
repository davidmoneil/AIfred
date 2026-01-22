# Phase 6: Autonomy Design Document

**Version**: 2.0 Draft
**Created**: 2026-01-13
**Revised**: 2026-01-16
**Author**: Jarvis (Deep Reflection Session)
**Status**: Design Phase — User Feedback Incorporated

---

## Executive Summary

Phase 6 transforms Jarvis from a reactive assistant into a **self-directed, self-improving system** where **autonomy is the default state**, not an opt-in feature. This document defines nine core **Autonomic Systems** that work together to achieve this vision, along with a restructured PR plan to implement them incrementally.

### The Overarching Aim

> Implement and enforce a design pattern by which Jarvis becomes more and more self-aware and self-directed while simultaneously holding itself to established standards of operation, protocol, and design decisions as a developer/system-manager.

### Core Philosophy: Autonomy as Default

**Jarvis operates autonomously by default.** User intervention is the exception, not the rule.

| Principle | Implementation |
|-----------|----------------|
| **Self-Directed by Default** | Jarvis initiates, continues, and completes work without prompting |
| **Never Just Wait** | If blocked, investigate and attempt resolution before reporting |
| **Idle Time is Productive** | Downtime triggers R&D, Maintenance, Reflection, Evolution cycles |
| **Wiggum Loop as Standard** | Multi-pass verification is default; only explicit "quick/rough" disables it |
| **Session End is User-Prompted** | Context exhaustion and idle don't end sessions—they trigger continuation |

This aim requires balancing two forces:
1. **Autonomy** — The ability to initiate, continue, and complete work without user intervention
2. **Discipline** — Adherence to established patterns, safety protocols, and quality standards

### System Scope Matrix

| System | Jarvis Codebase | Active Project | All Sessions |
|--------|-----------------|----------------|--------------|
| 1. Self-Launch | ✅ | ✅ | ✅ |
| 2. Wiggum Loop | ✅ | ✅ | ✅ |
| 3. Milestone Review | ✅ | ✅ | ✅ |
| 4. JICM | ✅ | ✅ | ✅ |
| 5. Self-Reflection | ✅ | ❌ | ✅ |
| 6. Self-Evolution | ✅ | ❌ | ✅ |
| 7. R&D Cycles | ✅ | ❌ | ✅ |
| 8. Maintenance | ✅ | ✅ | ✅ |
| 9. Session Completion | ✅ | ✅ | ✅ |

---

## Part I: The Nine Autonomic Systems

### System 1: Self-Launch Protocol

**Purpose**: Automatically initialize Jarvis at Claude Code startup with full context awareness, then proceed autonomously through session startup WITHOUT additional user prompting.

**Scope**: All sessions, all project spaces.

**Current State**:
- `session-start.sh` hook fires on startup
- Launches auto-clear watcher
- Loads checkpoint if present
- Suggests MCPs based on work type

**Autonomous Vision**:
```
┌─────────────────────────────────────────────────────────────────┐
│                    SELF-LAUNCH PROTOCOL                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  PHASE A: GREETING & ORIENTATION (Immediate, visible to user)   │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │  1. ENVIRONMENTAL AWARENESS                                │  │
│  │     ├── Check current date/time (DateTime MCP)             │  │
│  │     ├── Check weather conditions (WebSearch or API)        │  │
│  │     ├── Check location (IP geolocation - future)           │  │
│  │     └── Derive temporospatial context                      │  │
│  │                                                            │  │
│  │  2. CONGENIAL GREETING                                     │  │
│  │     ├── Greet user appropriately for time of day           │  │
│  │     ├── Note weather/conditions if relevant                │  │
│  │     ├── "Good morning, sir. Partly cloudy today."          │  │
│  │     └── Transition: "One moment while I review the         │  │
│  │         current system state and previous work."           │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                  │
│  PHASE B: SYSTEM REVIEW (Autonomous, no user prompting)         │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │  3. CORE INSTRUCTION INGESTION                             │  │
│  │     ├── Read CLAUDE.md and essential patterns              │  │
│  │     ├── Load session-state.md                              │  │
│  │     ├── Load current-priorities.md                         │  │
│  │     ├── Check for checkpoint file (auto-resume if present) │  │
│  │     └── Load project-relevant pattern files                │  │
│  │                                                            │  │
│  │  4. BASELINE SYNCHRONIZATION                               │  │
│  │     ├── git fetch on AIfred baseline                       │  │
│  │     ├── Detect upstream changes                            │  │
│  │     └── Prepare adopt/adapt/defer options if updates exist │  │
│  │                                                            │  │
│  │  5. PROJECT CONTEXT                                        │  │
│  │     ├── Identify current/most recently active project      │  │
│  │     ├── Ingest project design documentation                │  │
│  │     └── Quick review of project space organization         │  │
│  │                                                            │  │
│  │  6. ENVIRONMENT VALIDATION                                 │  │
│  │     ├── Check workspace boundaries (guardrail hooks)       │  │
│  │     ├── Verify git status (clean tree, correct branch)     │  │
│  │     └── Validate settings.json (hooks registered)          │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                  │
│  PHASE C: USER BRIEFING (Present findings, solicit direction)   │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │  7. PRESENT TO USER                                        │  │
│  │     ├── AIfred baseline status (adopt/adapt/defer options) │  │
│  │     ├── Summary of recent work and continuation options    │  │
│  │     ├── Any concerns noted about project/system state      │  │
│  │     └── Solicit instructions from user                     │  │
│  │                                                            │  │
│  │  8. AUTONOMOUS INITIATION (Default behavior)               │  │
│  │     ├── If PR work pending → invoke Wiggum Loop            │  │
│  │     ├── If milestone complete → invoke Review              │  │
│  │     ├── If idle → offer R&D/Maintenance/Reflection         │  │
│  │     └── NEVER simply "await user" - always have a plan     │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

**Key Design Decisions**:
- **Autonomy is Default**: Jarvis proceeds through startup WITHOUT waiting for prompts
- **Never Just Wait**: Always have a next action; if blocked, investigate first
- **Congenial Presence**: Jarvis greets appropriately for time/conditions
- **Transparency**: Log all startup actions to diagnostic file
- **If Blocked**: Investigate via Wiggum Loop, attempt resolution, THEN report with informed assessment

**Anti-Patterns (Explicitly Rejected)**:
- ~~"Opt-In Autonomy"~~ — Autonomy is the DEFAULT state
- ~~"Default to await user"~~ — NEVER simply wait; always investigate/attempt resolution first
- ~~"User Override patterns"~~ — Claude Code already provides interrupt capability; no need to waste instruction space

**Implementation Artifacts**:
- Enhanced `session-start.sh` (or `.js` for complexity)
- `startup-protocol.md` pattern document
- Integration with DateTime MCP for time awareness
- Future: IP geolocation for location awareness

---

### System 2: Wiggum Loop Integration

**Purpose**: Add multiple layers of reflective reasoning, self-checking, and revisionary correction to everything Jarvis produces. **Wiggum Loop is the DEFAULT behavior**, not opt-in.

**Scope**: All sessions, all project spaces.

**Current State**:
- Ralph Wiggum plugin available
- Manual invocation by user
- Stop hook blocking pattern understood

**Autonomous Vision**:
```
┌─────────────────────────────────────────────────────────────────┐
│                    WIGGUM LOOP INTEGRATION                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  DEFAULT BEHAVIOR (Always active unless explicitly disabled)    │
│  ├── Wiggum Loop is the STANDARD mode of operation              │
│  ├── "Keep going until done" is IMPLICIT - never needs stating  │
│  ├── There is ALWAYS in-progress work (startup procedure counts)│
│  └── Disable ONLY with explicit keywords:                       │
│      "quick solution", "rough pass", "first pass", "simple      │
│       sketch", "just a draft"                                   │
│                                                                  │
│  TRIGGER CONDITIONS (all invoke/continue Wiggum Loop)           │
│  ├── Self-Launch detects in-progress PR (always true for Aion)  │
│  ├── orchestration-detector.js scores task as complex           │
│  ├── Context exhaustion → checkpoint → clear → RE-TRIGGER loop  │
│  ├── Milestone Review requests remediation                      │
│  └── Any failure → investigate → attempt resolution → continue  │
│                                                                  │
│  LOOP BEHAVIOR                                                   │
│  ├── TodoWrite tracks all sub-tasks                             │
│  ├── Stop hook blocks until todos REVIEWED AND VERIFIED         │
│  ├── Context threshold → checkpoint → clear → resume loop       │
│  └── Session boundary → save state → re-enter on next session   │
│                                                                  │
│  STOPPING CONDITIONS (very limited)                              │
│  ├── All todos complete AND reviewed AND verified sufficient    │
│  ├── User sends explicit interrupt signal (Ctrl+C)              │
│  └── Safety gate triggered (destructive op, policy crossing)    │
│                                                                  │
│  NOT STOPPING CONDITIONS (these continue the loop)               │
│  ├── ❌ "Blocker encountered" → Investigate first, then report  │
│  ├── ❌ "Context exhaustion" → Checkpoint, clear, resume loop   │
│  ├── ❌ "Scope drift" → Realign with task aims, continue        │
│  └── ❌ "Idle/timeout" → Switch to R&D/Maintenance/Reflection   │
│                                                                  │
│  SAFETY MECHANISMS                                               │
│  ├── Maximum iteration count (configurable, prevent infinite)   │
│  ├── Time-based checkpoints (every 360 minutes / 6 hours)       │
│  ├── Scope drift detection → REALIGN work, don't exit           │
│  ├── JICM integration → hooks as pause points, not interruptors │
│  └── Destructive operation gates (still require confirmation)   │
│                                                                  │
│  LOOP STRUCTURE (standard iteration)                             │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │  1. EXECUTE — Perform work on current task                 │  │
│  │  2. CHECK — Verify work meets requirements                 │  │
│  │  3. REVIEW — Self-review for quality/completeness          │  │
│  │  4. DRIFT CHECK — Still aligned with original task aims?   │  │
│  │  5. CONTEXT CHECK — JICM status, near threshold?           │  │
│  │  6. CONTINUE or COMPLETE — Loop back or mark done          │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

**Key Design Decisions**:
- **Default ON**: Wiggum Loop is the standard mode; explicit language required to disable
- **Completion = Verified**: Not just "todos done" but "todos done AND reviewed AND sufficient"
- **Never Just Stop**: Context exhaustion, blockers, drift all trigger continuation, not exit
- **Progress Visibility**: TodoWrite provides continuous progress
- **Context Awareness**: JICM hooks act as pause points within the loop, not interruptors

**Anti-Patterns (Explicitly Rejected)**:
- ~~"User explicitly requests keep going"~~ — This is the DEFAULT; no request needed
- ~~"Stop on blocker"~~ — Investigate and attempt resolution first
- ~~"Stop on context exhaustion"~~ — Checkpoint, clear, resume
- ~~"Exit on scope drift"~~ — Realign and continue

**Implementation Artifacts**:
- `wiggum-integration.js` hook (enhanced Stop hook)
- `loop-state.json` for persistence across restarts
- `loop-guard.js` for safety mechanisms
- `drift-detector.js` for scope realignment

---

### System 3: Independent Milestone Review

**Purpose**: Semi-autonomous review of completed roadmap milestones to verify deliverables, catch regressions, and ensure quality. Jarvis detects phase completion and prompts user for review; user approves when ready.

**Scope**: All sessions, all project spaces.

**Autonomous Vision**:
```
┌─────────────────────────────────────────────────────────────────┐
│                  INDEPENDENT MILESTONE REVIEW                    │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  TRIGGER CONDITIONS (Semi-autonomous)                            │
│  ├── Jarvis detects major phase completion                      │
│  ├── Jarvis PROMPTS user: "Review recommended. Any notes?"      │
│  ├── User approves → Jarvis launches full review                │
│  └── User may also request review manually (/review-milestone)  │
│                                                                  │
│  NOT TRIGGER CONDITIONS                                          │
│  └── ❌ Scheduled periodic review — Other tasks handle hygiene  │
│                                                                  │
│  TWO-LEVEL REVIEW PROCESS                                        │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │  LEVEL 1: CODE-REVIEW AGENT (Technical Quality)           │  │
│  │  ├── Parse PR deliverables from roadmap.md                │  │
│  │  ├── Check each file/artifact exists                      │  │
│  │  ├── Verify content completeness                          │  │
│  │  ├── Run /tooling-health if applicable                    │  │
│  │  ├── Run /validate-selection if applicable                │  │
│  │  ├── Execute PR-specific validation commands              │  │
│  │  └── Generate technical findings report                   │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                  │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │  LEVEL 2: PROJECT-MANAGER AGENT (Progress & Alignment)    │  │
│  │  ├── Review project status against roadmap                │  │
│  │  ├── Check milestone alignment with project aims          │  │
│  │  ├── Verify documentation completeness                    │  │
│  │  │   - CHANGELOG.md updated                               │  │
│  │  │   - Version bumped appropriately                       │  │
│  │  │   - Related docs updated                               │  │
│  │  ├── Compare against PR-13 benchmarks (if available)      │  │
│  │  ├── Generate progress/alignment report                   │  │
│  │  └── Identify next priorities                             │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                  │
│  LARGE REVIEW HANDLING                                           │
│  ├── If review scope is large → break into segments             │
│  ├── Each segment reviewed with focused context                 │
│  └── Aggregate findings at end                                  │
│                                                                  │
│  INDEPENDENCE MECHANISMS                                         │
│  ├── Separate agents for review (code-review, project-manager)  │
│  ├── Criteria defined externally (not by implementer)           │
│  ├── Objective pass/fail based on measurable criteria           │
│  └── Human approval required for borderline cases               │
│                                                                  │
│  REMEDIATION PATH                                                │
│  ├── If issues found → create remediation todos                 │
│  ├── If major issues → block version bump, trigger Wiggum Loop  │
│  └── If pass → approve release, update roadmap status           │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

**Key Design Decisions**:
- **Semi-Autonomous**: Jarvis detects completion and prompts; user approves when ready
- **Two-Level Review**: Code-review agent (technical) + Project-manager agent (progress)
- **Separation of Concerns**: Reviewer agents ≠ implementer
- **Objective Criteria**: Measurable, documented acceptance criteria
- **Segmented Reviews**: Large reviews broken into focused segments

**Anti-Patterns (Explicitly Rejected)**:
- ~~"Scheduled periodic review (weekly)"~~ — Other tasks handle maintenance; review is milestone-triggered
- ~~"Check context budget impact"~~ — Review focuses on PROJECT evaluation, not self-evaluation

**Implementation Artifacts**:
- `code-review` agent definition (technical quality)
- `project-manager` agent definition (progress/alignment)
- `/review-milestone` command
- `review-criteria/` directory with per-PR criteria files
- `review-report-template.md`

---

### System 4: Context Window Management (Enhanced JICM)

**Purpose**: Manage context window "live" to prevent auto-compression. JICM triggers autonomously, completes compression, then re-triggers continuation of interrupted work. Ideally handled by a JICM Agent to avoid clogging main context.

**Scope**: All sessions, all project spaces. **ALSO applies to all subagents and custom agents.**

**Current State**:
- `context-accumulator.js` tracks token usage
- Thresholds at 50% (warn) and 75% (action)
- MCP disable/enable scripts
- Auto-clear watcher pattern

**Autonomous Vision**:
```
┌─────────────────────────────────────────────────────────────────┐
│              ENHANCED CONTEXT MANAGEMENT (JICM v2)               │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  CORE PRINCIPLES                                                 │
│  ├── JICM triggers CONTINUATION after compression, not exit     │
│  ├── JICM Agent handles compression (avoid clogging main ctx)   │
│  ├── Respect/integrate with Wiggum Loop processes               │
│  ├── Applies to ALL agents (Orchestrator, subagents, custom)    │
│  └── Preserve essentials, cut junk aggressively                 │
│                                                                  │
│  WHAT TO PRESERVE (Critical Information)                         │
│  ├── TodoWrite task list and status                             │
│  ├── Key decisions made during session                          │
│  ├── Blockers and their investigation status                    │
│  ├── Current work context and aims                              │
│  └── Files modified and their purpose                           │
│                                                                  │
│  WHAT TO CUT (Junk Text)                                         │
│  ├── Raw tool-call outputs (summarize instead)                  │
│  ├── Full code text (reference file paths instead)              │
│  ├── Long recursive self-talk (condense to conclusions)         │
│  ├── Verbose file contents (summarize or checkpoint)            │
│  └── Redundant explanations                                     │
│                                                                  │
│  INTELLIGENT OFFLOADING (Orchestrator Level)                     │
│  ├── Orchestrator reviews subagent output intelligently         │
│  ├── Decides how much task context to maintain                  │
│  ├── Delegation to subagents is primary behavior                │
│  └── No need to pre-estimate delegated agent context usage      │
│                                                                  │
│  CHECKPOINT STRATEGY (Two Options)                               │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │  OPTION A: Rich Checkpoint                                 │  │
│  │  ├── Information-dense checkpoint file                     │  │
│  │  └── Contains all essential context for full resumption    │  │
│  │                                                            │  │
│  │  OPTION B: Lean + Archive Reference                        │  │
│  │  ├── Lean checkpoint with key pointers                     │  │
│  │  └── Full uncompressed context stored in archive file      │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                  │
│  CONTEXT LIFTOVER (Critical for Continuity)                      │
│  ├── Freshly trimmed context lifts across compression gap       │
│  ├── Jarvis auto-picks up work where left off                   │
│  ├── Like Claude Code after auto-compression, but controlled    │
│  └── Store chat history/context for easy discovery next session │
│                                                                  │
│  DASHBOARD VS AUTOMATION MODES                                   │
│  ├── `/context-budget` — User-facing clean summary/dashboard    │
│  │   ├── Total tokens spent this session                        │
│  │   ├── Trend of current session context window                │
│  │   ├── Category breakdowns (MCPs, files, conversation)        │
│  │   └── Plot with JICM target limit + CC auto-compress limit   │
│  └── `jicm-status` — Automation version for Jarvis internal use │
│                                                                  │
│  THRESHOLD CONFIGURATION                                         │
│  │  Level    │ Threshold │ Action                               │
│  │ HEALTHY   │ < 50%     │ Normal operation                     │
│  │ CAUTION   │ 50-70%    │ Warn, suggest offloading             │
│  │ WARNING   │ 70-85%    │ Auto-offload, reduce MCPs            │
│  │ CRITICAL  │ 85-95%    │ Checkpoint, trigger JICM Agent       │
│  │ EMERGENCY │ > 95%     │ Force clear, preserve essentials     │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

**Key Design Decisions**:
- **Continuation, Not Exit**: JICM compression triggers work CONTINUATION, not session end
- **JICM Agent**: Dedicated agent handles compression to avoid context pollution
- **Universal Application**: ALL agents (Orchestrator + subagents + custom) use JICM
- **Liftover**: Ensure seamless context transfer across compression boundary
- **Efficiency Focus**: Don't over-engineer with per-tool-call cost estimation

**Anti-Patterns (Explicitly Rejected)**:
- ~~"Consider token cost of each tool call before execution"~~ — Creates context burden for minimal gain
- ~~"Context exhaustion triggers session completion"~~ — Triggers CONTINUATION instead

**Implementation Artifacts**:
- `jicm-agent.md` agent definition (handles compression)
- Enhanced `context-accumulator.js` (tracking)
- `/context-budget` command (user dashboard)
- `jicm-status` internal status function
- Checkpoint archive storage pattern

---

### System 5: Self-Reflection Cycles

**Purpose**: Create an organized system for storing lessons learned, problems identified, solutions proposed, and metrics—all feeding into Jarvis' own efforts to refine his codebase.

**Scope**: **Jarvis codebase ONLY** (not other project spaces). Can be triggered during any active session.

**Autonomous Vision**:
```
┌─────────────────────────────────────────────────────────────────┐
│                    SELF-REFLECTION CYCLES                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  TRIGGER POINTS                                                  │
│  ├── Session end (/end-session)                                 │
│  ├── PR completion                                               │
│  ├── Phase completion                                            │
│  ├── User request (/reflect)                                    │
│  └── Idle/downtime detection (see downtime-detector)            │
│                                                                  │
│  DATA SOURCES (Expanded)                                         │
│  ├── .claude/context/lessons/corrections.md — User corrections  │
│  ├── .claude/context/lessons/self-corrections.md — Jarvis' own  │
│  ├── .claude/agents/memory/*/learnings.json — Agent learnings   │
│  ├── selection-audit.jsonl — Tool selection patterns            │
│  ├── context-estimate.json — Context usage patterns             │
│  ├── session-state.md — Work patterns                           │
│  ├── Memory MCP — Persistent observations                       │
│  └── Git history — What was changed, when, why                  │
│                                                                  │
│  LESSONS DIRECTORY STRUCTURE (Richer than single file)          │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │  .claude/context/lessons/                                  │  │
│  │  ├── corrections.md          # User-provided corrections   │  │
│  │  ├── self-corrections.md     # Jarvis self-corrections     │  │
│  │  ├── problems/               # Problems identified         │  │
│  │  │   ├── YYYY-MM-problem-slug.md                          │  │
│  │  │   └── ...                                               │  │
│  │  ├── solutions/              # Solutions proposed/applied  │  │
│  │  │   ├── YYYY-MM-solution-slug.md                         │  │
│  │  │   └── ...                                               │  │
│  │  ├── patterns/               # Patterns discovered         │  │
│  │  │   ├── pattern-slug.md                                   │  │
│  │  │   └── ...                                               │  │
│  │  └── index.md                # Categorical/chronological   │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                  │
│  REFLECTION PROCESS (Identification → Reflection → Proposal)     │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │  1. IDENTIFICATION                                         │  │
│  │     ├── What problems occurred?                            │  │
│  │     ├── What inefficiencies were observed?                 │  │
│  │     ├── What corrections were received (user + self)?      │  │
│  │     └── What patterns emerged?                             │  │
│  │                                                            │  │
│  │  2. REFLECTION                                             │  │
│  │     ├── Why did these problems occur?                      │  │
│  │     ├── What knowledge was missing?                        │  │
│  │     ├── What approaches worked well?                       │  │
│  │     └── What sequences should be automated?                │  │
│  │                                                            │  │
│  │  3. PROPOSAL                                               │  │
│  │     ├── Specific solution with rationale                   │  │
│  │     ├── Files/patterns to modify                           │  │
│  │     ├── Risk assessment                                    │  │
│  │     └── Link to related prior solutions                    │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                  │
│  ORGANIZATION OVER TIME                                          │
│  ├── Chronological: Files dated YYYY-MM-slug.md                 │
│  ├── Categorical: Grouped by type (problem, solution, pattern)  │
│  ├── Index: Cross-referenced for discovery of prior solutions   │
│  └── Memory MCP: Persistent entities for quick recall           │
│                                                                  │
│  OUTPUT                                                          │
│  ├── Reflection report (human-readable summary)                 │
│  ├── Memory MCP entities (persistent learnings)                 │
│  ├── Evolution proposals (for Self-Evolution System)            │
│  └── Updated lessons directory files                            │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

**Key Design Decisions**:
- **Richer Structure**: Lessons directory with problems/, solutions/, patterns/ subdirectories
- **User vs Self**: Separate tracking for user corrections vs Jarvis' own corrections
- **Chronological + Categorical**: Both organization schemes for easy rediscovery
- **Evidence-Based**: All insights backed by data, not speculation
- **Actionable**: Reflections produce concrete evolution proposals

**Implementation Artifacts**:
- `reflection-engine.js` hook (scheduled + event-triggered)
- `/reflect` command for manual invocation
- `.claude/context/lessons/` directory structure
- `reflection-report-template.md`
- Integration with Memory MCP entities

---

### System 6: Self-Evolution Cycles

**Purpose**: Safely implement self-modifications based on reflection insights, with appropriate gates and rollback capability. **Self-directedness is paramount**—Jarvis decides when to launch evolution cycles.

**Scope**: **Jarvis codebase ONLY** (not other project spaces). Can be triggered during any active session.

**Autonomous Vision**:
```
┌─────────────────────────────────────────────────────────────────┐
│                    SELF-EVOLUTION CYCLES                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  TRIGGER CONDITIONS (Self-Directed)                              │
│  ├── User prompting (explicit request: "improve yourself")      │
│  ├── Reflection backlog grows too long → Jarvis requests user   │
│  │   approval to run self-evolution                             │
│  ├── DOWNTIME DETECTOR: No user input for ~30 minutes           │
│  │   → Hook triggers autonomous self-evolution                  │
│  └── Session timer check (every ~30 min from conversation log)  │
│                                                                  │
│  DOWNTIME DETECTOR MECHANISM                                     │
│  ├── Check timestamps in conversation log periodically          │
│  ├── If no user input for ~30 min and session active            │
│  ├── Hook triggers Jarvis to perform self-evolution             │
│  └── Jarvis chooses most valuable evolution proposals           │
│                                                                  │
│  INPUT SOURCES                                                   │
│  ├── Self-Reflection proposals                                  │
│  ├── R&D Cycle discoveries                                      │
│  ├── User feature requests                                      │
│  └── Benchmark regression findings                              │
│                                                                  │
│  EVOLUTION PIPELINE                                              │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │                                                          │    │
│  │  1. PROPOSAL TRIAGE                                      │    │
│  │     - Evaluate impact (low/medium/high)                  │    │
│  │     - Assess risk (safe/moderate/dangerous)              │    │
│  │     - Check alignment with roadmap                       │    │
│  │     - Prioritize queue                                   │    │
│  │                                                          │    │
│  │  2. DESIGN PHASE                                         │    │
│  │     - Draft implementation plan                          │    │
│  │     - Identify files to change                           │    │
│  │     - Define validation criteria                         │    │
│  │     - Estimate context/complexity                        │    │
│  │                                                          │    │
│  │  3. APPROVAL GATE                                        │    │
│  │     - Low risk → auto-approve (notify user)              │    │
│  │     - Medium risk → notify user, proceed unless veto     │    │
│  │     - High risk → require explicit user approval         │    │
│  │                                                          │    │
│  │  4. IMPLEMENTATION                                       │    │
│  │     - Create git branch for change                       │    │
│  │     - Implement changes                                  │    │
│  │     - Run validation tests                               │    │
│  │                                                          │    │
│  │  5. VALIDATION                                           │    │
│  │     - Execute PR-13 benchmarks                           │    │
│  │     - Compare before/after metrics                       │    │
│  │     - Check for regressions                              │    │
│  │                                                          │    │
│  │  6. RELEASE                                              │    │
│  │     - Merge to Project_Aion branch                       │    │
│  │     - Version bump (patch/minor based on impact)         │    │
│  │     - Update CHANGELOG                                   │    │
│  │     - Push to origin                                     │    │
│  │                                                          │    │
│  │  7. ROLLBACK (if validation fails)                       │    │
│  │     - Revert changes                                     │    │
│  │     - Log failure reason                                 │    │
│  │     - Update proposal with learnings                     │    │
│  │                                                          │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                  │
│  R&D PROPOSALS REQUIRE USER APPROVAL                             │
│  ├── Proposals from R&D have "require-approval" flag            │
│  ├── Never auto-implement R&D discoveries                       │
│  └── User must explicitly approve R&D-sourced evolutions        │
│                                                                  │
│  SAFETY MECHANISMS                                               │
│  ├── Never modify AIfred baseline (read-only rule)              │
│  ├── Always work in branch, merge only after validation         │
│  ├── Rollback capability for any change                         │
│  ├── Rate limiting (max N evolutions per session)               │
│  └── Human gate for high-impact changes                         │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

**Key Design Decisions**:
- **Self-Directed**: Jarvis decides when to launch evolution (downtime, backlog, user request)
- **Downtime Detector**: ~30 min idle triggers autonomous self-evolution
- **Controlled Evolution**: Change is managed, not chaotic
- **Validation-First**: Nothing ships without passing benchmarks
- **Reversibility**: Every change can be rolled back
- **Transparency**: Full audit trail of all evolutions

**Implementation Artifacts**:
- `evolution-queue.yaml` for proposal tracking
- `evolution-runner.js` for pipeline execution
- `downtime-detector.js` hook (checks for idle sessions)
- `/evolve` command for manual triggering
- Integration with PR-13 benchmark system

---

### System 7: R&D Cycles

**Purpose**: Conduct research on external projects, new tools, SOTA patterns, AND internal token efficiency of Jarvis codebase files. Self-directed: runs during idle time or by user request.

**Scope**: **Jarvis codebase ONLY** (not other project spaces). Can be triggered during any active session.

**Autonomous Vision**:
```
┌─────────────────────────────────────────────────────────────────┐
│                       R&D CYCLES                                 │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  TRIGGER CONDITIONS (Self-Directed)                              │
│  ├── DOWNTIME DETECTOR: No user input for ~30 min               │
│  │   → Hook triggers autonomous R&D                             │
│  ├── User request (/research)                                   │
│  └── Research agenda backlog check                              │
│                                                                  │
│  EXTERNAL RESEARCH AGENDA                                        │
│  ├── New MCP servers (monthly scan of awesome-mcp lists)        │
│  ├── New plugins (scan claude-code-plugins registry)            │
│  ├── SOTA projects (from PR-14 catalog)                         │
│  ├── Anthropic updates (Agent SDK, Claude Code features)        │
│  └── User-suggested topics                                      │
│                                                                  │
│  INTERNAL RESEARCH AGENDA (Token Efficiency)                     │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │  KEY R&D TRACK: .claude File Token Efficiency              │  │
│  │  ├── Goal: Lean, linked, layered scope                     │  │
│  │  ├── Track .claude file access (which files loaded)        │  │
│  │  │   - Log files read into context each session            │  │
│  │  │   - Invisible update timestamp on load OR separate log  │  │
│  │  ├── Identify high-use vs low-use codebase files           │  │
│  │  ├── Detect redundant/repeated instructions across files   │  │
│  │  ├── Detect important patterns that go unused              │  │
│  │  └── Propose revisions to file structure and content       │  │
│  │      distribution based on usage patterns                  │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                  │
│  RESEARCH PROCESS                                                │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │  1. DISCOVERY                                            │    │
│  │     - Scan source lists for new entries                  │    │
│  │     - Fetch README/documentation                         │    │
│  │     - Extract capabilities and requirements              │    │
│  │                                                          │    │
│  │  2. RELEVANCE FILTERING                                  │    │
│  │     - Does it solve a Jarvis problem?                    │    │
│  │     - Does it overlap with existing tools?               │    │
│  │     - Is the complexity justified?                       │    │
│  │                                                          │    │
│  │  3. DEEP ANALYSIS (for relevant items)                   │    │
│  │     - Use deep-research agent for thorough review        │    │
│  │     - Identify specific use cases                        │    │
│  │     - Assess integration effort                          │    │
│  │                                                          │    │
│  │  4. CLASSIFICATION                                       │    │
│  │     - ADOPT: High value, low risk → implement            │    │
│  │     - ADAPT: High value, needs modification → plan       │    │
│  │     - DEFER: Potential value, wait for stability         │    │
│  │     - REJECT: Low value or high risk → skip              │    │
│  │                                                          │    │
│  │  5. PROPOSAL GENERATION                                  │    │
│  │     - For ADOPT/ADAPT items, create evolution proposal   │    │
│  │     - Flag as "require-approval" (no auto-implement)     │    │
│  │     - Link to source documentation                       │    │
│  │     - Define integration steps                           │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                  │
│  R&D REPORT FORMAT (Required Sections)                           │
│  ├── Summary: What was researched                               │
│  ├── Pro/Con Analysis: Benefits vs drawbacks                    │
│  ├── Cost/Benefit Analysis:                                     │
│  │   ├── Missingness: What capability gap does it fill?        │
│  │   ├── Value: How valuable is that capability?                │
│  │   ├── Context Cost: Token/context budget impact              │
│  │   └── Complexity: Implementation difficulty                  │
│  └── Recommendation: ADOPT/ADAPT/DEFER/REJECT with rationale    │
│                                                                  │
│  OUTPUTS                                                         │
│  ├── Research report (findings summary + cost/benefit)          │
│  ├── PR-14 catalog updates (new entries)                        │
│  ├── Evolution proposals (flagged "require-approval")           │
│  └── Memory MCP entities (persistent knowledge)                 │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

**Key Design Decisions**:
- **Self-Directed**: Runs during idle/downtime or by user request
- **Dual Focus**: External (new tools) AND internal (token efficiency)
- **File Usage Tracking**: Know which .claude files are high-use vs unused
- **Proposals Require Approval**: R&D proposals flagged for explicit user approval
- **Bloat Prevention**: High bar for adding new tools/patterns

**Implementation Artifacts**:
- `research-agenda.yaml` for topic tracking
- `file-usage-tracker.js` hook (logs .claude file reads)
- `rd-scanner.js` for discovery automation
- `/research` command for manual invocation
- Integration with deep-research agent

---

### System 8: Maintenance Workflows

**Purpose**: Perform maintenance tasks to keep the Jarvis codebase AND active project space healthy, documentation fresh, and artifacts clean. Self-directed: runs during idle time or by user request.

**Scope**: **Jarvis codebase AND active project space.** Can be triggered during any active session.

**Autonomous Vision**:
```
┌─────────────────────────────────────────────────────────────────┐
│                   MAINTENANCE WORKFLOWS                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  TRIGGER CONDITIONS (Self-Directed)                              │
│  ├── DOWNTIME DETECTOR: No user input for ~30 min               │
│  │   → Hook triggers autonomous maintenance                     │
│  ├── User request (/maintain)                                   │
│  ├── Session end (subset of tasks)                              │
│  └── Session start (health checks)                              │
│                                                                  │
│  DUAL SCOPE: JARVIS CODEBASE + ACTIVE PROJECT                    │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │  JARVIS CODEBASE MAINTENANCE                               │  │
│  │  ├── .claude/ file organization and logic                  │  │
│  │  ├── Hook and settings validation                          │  │
│  │  ├── Pattern file freshness                                │  │
│  │  └── Behavioral requirements compliance                    │  │
│  │                                                            │  │
│  │  ACTIVE PROJECT MAINTENANCE                                │  │
│  │  ├── Project space organization                            │  │
│  │  ├── File placement vs project design specs                │  │
│  │  ├── Reference/link integrity                              │  │
│  │  └── Save location compliance                              │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                  │
│  MAINTENANCE TASKS                                               │
│  ├── CLEANUP                                                    │
│  │   ├── Log rotation (.claude/logs/ files)                    │
│  │   ├── Orphaned file detection (unreferenced files)          │
│  │   ├── Temp file cleanup (.claude/context/.* transients)     │
│  │   └── Git housekeeping (prune, gc)                          │
│  │                                                              │
│  ├── FRESHNESS AUDITS                                           │
│  │   ├── Documentation staleness check                          │
│  │   │   - Files not updated in 30+ days (flag for R&D review) │
│  │   │   - References to outdated versions                     │
│  │   │   - Broken internal links                               │
│  │   ├── Dependency freshness                                   │
│  │   │   - MCP server versions                                 │
│  │   │   - Plugin versions                                     │
│  │   │   - Node.js packages                                    │
│  │   └── Pattern applicability                                  │
│  │       - Are documented patterns still in use?               │
│  │       - Do patterns match current implementation?           │
│  │                                                              │
│  ├── HEALTH CHECKS                                              │
│  │   ├── Hook syntax validation (all JS/SH hooks)              │
│  │   ├── settings.json schema validation                       │
│  │   ├── MCP connectivity test                                 │
│  │   └── Git status consistency                                │
│  │                                                              │
│  ├── ORGANIZATION REVIEW                                        │
│  │   ├── File system logic check (Jarvis codebase)             │
│  │   ├── File system logic check (active project)              │
│  │   ├── Correct file placement per design specs               │
│  │   ├── Correct reference/link targets                        │
│  │   └── Items in correct locations                            │
│  │                                                              │
│  └── OPTIMIZATION                                               │
│      ├── Context usage analysis (what's consuming budget?)      │
│      ├── Duplicate detection (similar files/patterns)          │
│      └── Consolidation proposals                                │
│                                                                  │
│  SCHEDULING                                                      │
│  │  Task            │ Frequency     │ Automation Level          │
│  │ Log rotation     │ Daily/Idle    │ Fully automatic           │
│  │ Temp cleanup     │ Session end   │ Fully automatic           │
│  │ Doc freshness    │ Idle/Weekly   │ Report, flag for R&D      │
│  │ Health checks    │ Session start │ Warn if issues            │
│  │ Organization     │ Idle/Manual   │ Report + proposals        │
│  │ Optimization     │ Idle/Monthly  │ Proposals only            │
│                                                                  │
│  OUTPUTS                                                         │
│  ├── Maintenance log (actions taken)                            │
│  ├── Freshness report (stale items → R&D review)                │
│  ├── Health report (issues found)                               │
│  ├── Organization report (misplaced/orphaned items)             │
│  └── Optimization proposals (for evolution queue)               │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

**Key Design Decisions**:
- **Self-Directed**: Runs during idle/downtime or by user request
- **Dual Scope**: Maintains BOTH Jarvis codebase AND active project space
- **Organization Focus**: Ensures files in correct places, references valid
- **Non-Destructive**: Maintenance proposes, doesn't execute destructive actions
- **Freshness → R&D**: Files not updated in 30+ days flagged for R&D review
- **Auditable**: All actions logged

**Implementation Artifacts**:
- `maintenance-runner.sh` for task execution
- `freshness-auditor.js` for documentation checks
- `organization-auditor.js` for file placement checks
- `/maintain` command for manual invocation
- Integration with downtime-detector

---

### System 9: Session Completion

**Purpose**: Ensure clean, complete handoff between sessions. **USER-PROMPTED ONLY** — once triggered, Jarvis autonomously runs through exhaustive session-end tasks.

**Scope**: All sessions, all project spaces.

**Autonomous Vision**:
```
┌─────────────────────────────────────────────────────────────────┐
│                   SESSION COMPLETION                             │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  TRIGGER CONDITIONS (USER-PROMPTED ONLY)                         │
│  ├── User runs /end-session                                     │
│  └── User explicitly requests session end                       │
│                                                                  │
│  NOT TRIGGER CONDITIONS (These DON'T end sessions)               │
│  ├── ❌ Context exhaustion → JICM handles, work continues       │
│  ├── ❌ Wiggum Loop completes → Check for more work, offer idle │
│  └── ❌ Idle timeout → Trigger R&D/Maintenance/Reflection       │
│                                                                  │
│  PRE-COMPLETION CHECK (Before truly ending)                      │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │  Jarvis asks: "Before ending, can I do anything useful    │  │
│  │  while you're away?"                                       │  │
│  │                                                            │  │
│  │  ├── Self-Reflection cycles?                               │  │
│  │  ├── Self-Evolution cycles?                                │  │
│  │  ├── Maintenance workflows?                                │  │
│  │  ├── R&D cycles?                                           │  │
│  │  └── Anything else useful?                                 │  │
│  │                                                            │  │
│  │  User approves → Jarvis runs selected cycles               │  │
│  │  User declines → Proceed to completion                     │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                  │
│  COMPLETION PROTOCOL (Autonomous once triggered)                 │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │  1. WORK STATE CAPTURE                                   │    │
│  │     - Update session-state.md with current status        │    │
│  │     - Capture pending todos                              │    │
│  │     - Document blockers and decisions                    │    │
│  │                                                          │    │
│  │  2. MEMORY PERSISTENCE                                   │    │
│  │     - Flush pending Memory MCP writes                    │    │
│  │     - Create session summary entity                      │    │
│  │     - Update corrections.md/self-corrections.md if needed│    │
│  │                                                          │    │
│  │  3. CONTEXT FILE UPDATES                                 │    │
│  │     - Update current-priorities.md                       │    │
│  │     - Update any modified pattern files                  │    │
│  │                                                          │    │
│  │  4. CHAT HISTORY PRESERVATION                            │    │
│  │     - Store chat history/context window contents         │    │
│  │     - Location: easily discoverable at next session      │    │
│  │     - Format: rich enough for context recovery           │    │
│  │                                                          │    │
│  │  5. GIT OPERATIONS                                       │    │
│  │     - Stage relevant changes                             │    │
│  │     - Create session commit                              │    │
│  │     - Push to origin (if enabled)                        │    │
│  │                                                          │    │
│  │  6. HANDOFF PREPARATION                                  │    │
│  │     - Create checkpoint file                             │    │
│  │     - Document "Next Session" instructions               │    │
│  │     - Configure MCPs for next session                    │    │
│  │                                                          │    │
│  │  7. CLEANUP                                              │    │
│  │     - Clear transient files                              │    │
│  │     - Stop watcher if running                            │    │
│  │     - Log session statistics                             │    │
│  │                                                          │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                  │
│  SESSION SUMMARY GENERATION                                      │
│  ├── What was accomplished                                      │
│  ├── What was blocked                                           │
│  ├── What decisions were made                                   │
│  ├── What's next                                                │
│  └── Context/token statistics                                   │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

**Key Design Decisions**:
- **User-Prompted Only**: Session ends ONLY when user explicitly requests
- **Pre-Completion Offer**: Before ending, offer to run R&D/Maintenance/Reflection/Evolution
- **No Lost Work**: State is always preserved before exit
- **Chat History Storage**: Preserve for easy context recovery
- **Clean Handoff**: Next session has everything needed to continue
- **Consistent Format**: Session summaries follow standard template

**Anti-Patterns (Explicitly Rejected)**:
- ~~"Context exhaustion triggers completion"~~ — JICM handles this; work continues
- ~~"Wiggum Loop completion triggers end"~~ — Check for more work first
- ~~"Idle timeout triggers end"~~ — Use idle time productively instead

**Implementation Artifacts**:
- Enhanced `/end-session` command with pre-completion check
- `session-summary-template.md`
- Chat history storage location
- Integration with Memory MCP for persistence

---

## Part II: System Interdependencies

The nine autonomic systems form two interconnected tiers:

### Tier 1: Active Work Systems (All Sessions)

```
                    ┌─────────────────┐
                    │  Self-Launch    │
                    │  (Entry Point)  │
                    └────────┬────────┘
                             │
              ┌──────────────┼──────────────┐
              │              │              │
              ▼              ▼              ▼
     ┌─────────────┐  ┌─────────────┐  ┌─────────────┐
     │  Wiggum     │  │  Context    │  │  Milestone  │
     │  Loop       │◀▶│  Management │◀▶│  Review     │
     └──────┬──────┘  └──────┬──────┘  └──────┬──────┘
            │                │                │
            └────────────────┼────────────────┘
                             │
                             ▼
                     ┌─────────────────┐
                     │  Session        │
                     │  Completion     │
                     │ (User prompted) │
                     └─────────────────┘
```

### Tier 2: Self-Improvement Systems (Jarvis Codebase Only)

```
            ┌─────────────┐  ┌─────────────┐
            │ Reflection  │◀▶│ R&D Cycles  │
            │ Cycles      │  │             │
            └──────┬──────┘  └──────┬──────┘
            ^      │                │
            |      └───────┬────────┘
            |              │
            |              ▼
            ┌─────────────┐  ┌─────────────┐
            │Maintenance  │◀▶│Self-Evolution│
            │Workflows    │  │(Change Engine)│
            └──────┬──────┘  └──────┬──────┘
                   │                │
                   └─────────┬──────┘
                             │
                             ▼
                  ┌─────────────────┐
                  │Session Completion│
                  │ (User prompted) │
                  └─────────────────┘
```

### Cross-Tier Connections

- **Downtime Detection**: When user is idle (~30 min), Tier 1 active work triggers Tier 2 self-improvement
- **Work Completion**: When Wiggum Loop completes, check for Tier 2 work before prompting user
- **Session End**: User-prompted; offers Tier 2 work before truly ending

### Interaction Patterns

| System A | System B | Interaction |
|----------|----------|-------------|
| Self-Launch | Wiggum Loop | Launch invokes Loop if PR pending |
| Wiggum Loop | Context Mgmt | Loop yields to JICM operations (pause, not stop) |
| Wiggum Loop | Milestone Review | Loop completion triggers review (semi-autonomous) |
| Milestone Review | Self-Evolution | Failed review creates proposals |
| Reflection | Self-Evolution | Reflections feed evolution queue |
| Reflection | Maintenance | Maintenance findings trigger reflection |
| R&D Cycles | Self-Evolution | Discoveries feed evolution queue (require-approval) |
| R&D Cycles | Maintenance | Freshness audits inform R&D priorities |
| Self-Evolution | Maintenance | Evolution changes require organization review |
| Maintenance | Reflection | Organization issues create reflection data |
| ~~Context Mgmt~~ | ~~Session Complete~~ | ~~Context exhaustion triggers completion~~ **REMOVED** |
| All Systems | Session Complete | State preserved on **user-prompted** exit |
| Downtime Detector | Tier 2 Systems | Idle time triggers self-improvement work |

### Key Interdependency Principles

1. **Tier 1 is Always Active**: Active work systems run in all sessions
2. **Tier 2 is Jarvis-Scoped**: Self-improvement only touches Jarvis codebase
3. **Downtime is Productive**: Idle time triggers Tier 2 automatically
4. **Session End is User-Prompted**: Never auto-end; always offer more work

---

## Part II-B: Consolidated Self-Improvement Command

**User Request**: A single command to trigger Jarvis to run through all self-improvement cycles (Systems 5-8) as the entire purpose of a session.

### `/self-improve` Command

**Purpose**: User can invoke this to have Jarvis spend a session running self-improvement cycles without explicit user oversight.

```
┌─────────────────────────────────────────────────────────────────┐
│                   /self-improve COMMAND                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  INVOCATION                                                      │
│  └── User: "/self-improve" or "Spend time improving yourself"   │
│                                                                  │
│  EXECUTION SEQUENCE (Autonomous)                                 │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │  1. SELF-REFLECTION (System 5)                             │  │
│  │     ├── Review all data sources                            │  │
│  │     ├── Identify problems/patterns/proposals               │  │
│  │     └── Generate reflection report                         │  │
│  │                                                            │  │
│  │  2. MAINTENANCE (System 8)                                 │  │
│  │     ├── Run freshness audits                               │  │
│  │     ├── Run health checks                                  │  │
│  │     ├── Review organization (Jarvis + active project)      │  │
│  │     └── Generate maintenance report                        │  │
│  │                                                            │  │
│  │  3. R&D CYCLES (System 7)                                  │  │
│  │     ├── Check research agenda for pending items            │  │
│  │     ├── Review internal token efficiency                   │  │
│  │     ├── Discover new tools/patterns if agenda empty        │  │
│  │     └── Generate R&D report                                │  │
│  │                                                            │  │
│  │  4. SELF-EVOLUTION (System 6)                              │  │
│  │     ├── Triage all proposals (reflection + R&D + maint)    │  │
│  │     ├── Implement LOW-risk proposals (auto-approve)        │  │
│  │     ├── Queue MEDIUM/HIGH proposals for user approval      │  │
│  │     └── Generate evolution report                          │  │
│  │                                                            │  │
│  │  5. SUMMARY & APPROVAL REQUEST                             │  │
│  │     ├── Present consolidated report to user                │  │
│  │     ├── List pending proposals requiring user approval     │  │
│  │     └── Ask: Continue improving? Approve proposals?        │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                  │
│  OPTIONS                                                         │
│  ├── /self-improve --focus=reflection  (Run only System 5)      │
│  ├── /self-improve --focus=maintenance (Run only System 8)      │
│  ├── /self-improve --focus=research    (Run only System 7)      │
│  ├── /self-improve --focus=evolution   (Run only System 6)      │
│  └── /self-improve --all               (Default: all systems)   │
│                                                                  │
│  LOOP BEHAVIOR                                                   │
│  ├── Runs under Wiggum Loop (default behavior)                  │
│  ├── Context management via JICM                                │
│  └── Can run for extended periods (hours) without user input    │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

**Key Design Decisions**:
- **Single Entry Point**: One command triggers all self-improvement
- **Autonomous Execution**: Runs without user oversight until completion
- **Progressive Approval**: Low-risk auto-approved; higher-risk queued
- **Focus Options**: Can narrow to specific system if desired
- **Extended Operation**: Can run for hours autonomously

**Implementation Artifacts**:
- `/self-improve` command definition
- Integration with Wiggum Loop for multi-pass verification
- Consolidated report template
- Approval queue management

---

## Part III: Restructured PR Plan

### PR-11: Autonomic Component Framework ✅ COMPLETE

**Purpose**: Establish the generalized templates, patterns, and standards that all autonomic components must follow.

**Scope**: Foundation work — no component implementation, just architecture.

**Status**: All 6 sub-PRs completed (2026-01-16)

#### PR-11.1: Component Specification Standard ✅ COMPLETE
- Define the Autonomic Component Specification Template
- Mandatory fields: Identity, Triggers, Inputs, Outputs, Dependencies, Consumers, Gates, Metrics, Failure Modes
- Template file: `.claude/context/templates/autonomic-component-spec.md`
- **Implemented**: 2026-01-16

#### PR-11.2: Component Interaction Protocol ✅ COMPLETE
- Define how systems communicate (events, files, Memory MCP)
- Event naming conventions
- State file formats
- Error propagation patterns
- Pattern file: `.claude/context/patterns/component-interaction-protocol.md`
- **Implemented**: 2026-01-16

#### PR-11.3: Metrics Collection Standard ✅ COMPLETE
- Define common metrics all components must emit
- Token cost, execution time, success/failure
- Storage format (JSONL, Memory MCP, etc.)
- Aggregation patterns
- Standard file: `.claude/context/standards/metrics-collection-standard.md`
- **Implemented**: 2026-01-16

#### PR-11.4: Gate Pattern Standard ✅ COMPLETE
- Define approval checkpoint pattern
- Risk levels (low/medium/high) and corresponding gates
- User notification patterns
- Override mechanisms
- Standard file: `.claude/context/standards/gate-pattern-standard.md`
- **Implemented**: 2026-01-16

#### PR-11.5: Override and Disable Pattern ✅ COMPLETE
- How to disable any autonomic system
- Emergency stop mechanisms
- Per-session vs persistent configuration
- Audit logging requirements
- Pattern file: `.claude/context/patterns/override-disable-pattern.md`
- **Implemented**: 2026-01-16

#### PR-11.6: Testing Framework ✅ COMPLETE
- How to test autonomic components in isolation
- Mock patterns for dependencies
- Validation harness integration
- Regression test patterns
- Pattern file: `.claude/context/patterns/autonomic-testing-framework.md`
- **Implemented**: 2026-01-16

**Deliverables**:
- 6 pattern documents in `.claude/context/patterns/autonomy/`
- Autonomic Component Specification Template
- Testing framework skeleton

**Acceptance Criteria**:
- All patterns reviewed and approved
- Template can express all 8 planned systems
- Testing framework validates at least one mock component

---

### PR-12: Autonomic Component Implementation

**Purpose**: Implement each of the nine autonomic systems following PR-11 framework.

#### PR-12.1: Self-Launch System ✅ COMPLETE
- Enhanced session-start hook with weather/time/greeting
- DateTime MCP integration for temporal awareness
- Startup protocol (Phases A, B, C)
- Autonomy-by-default configuration
- Testing and validation
- **Artifacts**:
  - `.claude/context/components/AC-01-self-launch.md`
  - `.claude/context/patterns/startup-protocol.md`
  - `.claude/config/autonomy-config.yaml`
  - Enhanced `.claude/hooks/session-start.sh`
- **Implemented**: 2026-01-16

#### PR-12.2: Wiggum Loop Integration ✅ COMPLETE
- Loop state management (`loop-state.json`)
- Stop hook enhancement (verify completion, not just done)
- Drift detector and realignment
- Safety mechanisms (iteration limits, 6-hour checkpoints)
- JICM integration (pause points, not interrupts)
- **Artifacts**:
  - `.claude/context/components/AC-02-wiggum-loop.md`
  - `.claude/context/patterns/wiggum-loop-pattern.md`
- **Implemented**: 2026-01-16

#### PR-12.3: Independent Milestone Review
- Two-level review: `code-review` + `project-manager` agents
- Review criteria files (per-PR in `review-criteria/`)
- Large review segmentation
- Report generation
- Remediation workflow integration

#### PR-12.4: Enhanced Context Management (JICM v2)
- JICM Agent for compression handling
- Context liftover across compression boundaries
- Checkpoint strategies (Rich vs Lean+Archive)
- Dashboard (`/context-budget`) vs automation (`jicm-status`)
- Universal application (all agents)

#### PR-12.5: Self-Reflection Cycles
- Lessons directory structure (problems/, solutions/, patterns/)
- Separate corrections.md vs self-corrections.md
- Agent learnings.json integration
- Reflection engine with 3-phase process
- Chronological + categorical organization

#### PR-12.6: Self-Evolution Cycles
- Downtime detector (~30 min idle trigger)
- Evolution pipeline with risk-based gates
- Proposal queue with require-approval flags
- Rollback capability
- Integration with PR-13 benchmarks

#### PR-12.7: R&D Cycles
- Internal research track (token efficiency, file usage)
- File usage tracker hook
- External research (SOTA catalog)
- R&D report format (pro/con, cost/benefit)
- Proposal generation with require-approval flag

#### PR-12.8: Maintenance Workflows
- Dual scope: Jarvis codebase + active project
- Organization auditor (file placement, references)
- Freshness auditor (30-day stale detection)
- Health checker
- Downtime trigger integration

#### PR-12.9: Session Completion System
- User-prompted only (no auto-triggers)
- Pre-completion offer (R&D/Maintenance/Reflection/Evolution)
- Chat history preservation
- Enhanced /end-session
- State preservation and handoff

#### PR-12.10: Self-Improvement Command
- `/self-improve` command implementation
- Integration of Systems 5-8 in sequence
- Focus options (--focus=reflection, etc.)
- Consolidated report template

**Deliverables**:
- 10 sub-PRs implementing 9 systems + `/self-improve` command
- Hooks, scripts, commands for each
- Integration tests

**Acceptance Criteria**:
- Each system passes its validation tests
- Systems can run independently
- Systems interact correctly when combined

---

### PR-13: Monitoring, Benchmarking, and Scoring

**Purpose**: Create the infrastructure to measure, benchmark, and score autonomous behavior.

#### PR-13.1: Telemetry System
- Event collection from all components
- Centralized event log
- Query interface
- Retention policies

#### PR-13.2: Benchmark Suite
- End-to-end scenario definitions
- Benchmark runner
- Baseline measurement
- Comparison tooling

#### PR-13.3: Scoring Framework
- Component effectiveness metrics
- Scoring algorithms
- Threshold definitions
- Trend analysis

#### PR-13.4: Dashboard and Reporting
- Visibility into autonomous behavior
- Real-time status
- Historical trends
- Alert definitions

#### PR-13.5: Regression Detection
- Automatic regression identification
- Comparison against baselines
- Alert generation
- Integration with evolution gates

**Deliverables**:
- Telemetry infrastructure
- 10+ defined benchmarks
- Scoring system
- Reporting templates
- Regression detector

**Acceptance Criteria**:
- All PR-12 components emit telemetry
- Benchmarks can run end-to-end
- Scoring produces meaningful metrics
- Regressions are automatically detected

---

### PR-14: Open-Source Catalog and SOTA Reference

**Purpose**: Create and maintain a catalog of reference projects for R&D cycles and self-evolution.

#### PR-14.1: Catalog Structure
- Define catalog schema
- Categorization system
- Evaluation criteria
- Storage location

#### PR-14.2: Initial Population
- Populate from roadmap Section 4 references
- Add MCP server repositories
- Add plugin repositories
- Add agent framework references

#### PR-14.3: Comparison Framework
- How to compare Jarvis patterns to SOTA
- Gap analysis template
- Opportunity identification

#### PR-14.4: Adoption/Adaptation Pipeline
- Workflow for evaluating catalog items
- Integration with evolution queue
- Tracking adoption status

#### PR-14.5: Scheduled Research Integration
- Cron-like research scheduling
- Automatic catalog updates
- Stale entry detection

**Deliverables**:
- Catalog at `projects/project-aion/sota-catalog/`
- 50+ cataloged references (initial)
- Comparison framework
- Research scheduler

**Acceptance Criteria**:
- Catalog is populated and structured
- At least one comparison cycle completed
- Research scheduler operational

---

## Part IV: Design Principles

### The Autonomy-Discipline Balance

Every autonomic system must uphold:

1. **Bounded Autonomy**: Freedom within defined limits
2. **Transparent Operation**: Actions are logged and visible
3. **Reversible Changes**: Everything can be undone
4. **Human Override**: User can always interrupt
5. **Fail-Safe Defaults**: On error, fall back to safe behavior

### The Self-Improvement Loop

```
     ┌──────────────────────────────────────────────────────┐
     │                                                       │
     │    OBSERVE           REFLECT           EVOLVE        │
     │    (Telemetry)  →    (Analysis)   →    (Change)      │
     │        ↑                                    │        │
     │        │                                    │        │
     │        └────────────  VALIDATE  ←───────────┘        │
     │                      (Benchmark)                      │
     │                                                       │
     └──────────────────────────────────────────────────────┘
```

### Standards Enforcement

Autonomous operation must not compromise:

1. **AIfred Baseline Read-Only**: Never modified
2. **Workspace Boundaries**: Guardrail hooks remain active
3. **Secret Protection**: No credentials in repo/logs
4. **Destructive Op Gates**: Confirmation always required
5. **Version Control**: All changes tracked in git

---

## Part V: Implementation Sequence

### Recommended Order

1. **PR-11** (Framework) — Establishes foundation
2. **PR-12.1** (Self-Launch) — Entry point for autonomy
3. **PR-12.4** (Context Management) — Essential for all operations
4. **PR-12.9** (Session Completion) — Clean exit path
5. **PR-12.2** (Wiggum Loop) — Work driver
6. **PR-12.3** (Milestone Review) — Quality gate
7. **PR-13.1-13.2** (Telemetry, Benchmarks) — Measurement foundation
8. **PR-12.5** (Reflection) — Self-awareness
9. **PR-12.6** (Evolution) — Self-modification
10. **PR-12.7** (R&D) — External learning
11. **PR-12.8** (Maintenance) — Hygiene
12. **PR-13.3-13.5** (Scoring, Dashboard, Regression) — Complete monitoring
13. **PR-14** (Catalog) — Reference library

### Dependencies

| Component | Depends On |
|-----------|------------|
| Wiggum Loop | Context Management |
| Milestone Review | Wiggum Loop |
| Self-Evolution | Reflection, R&D, Milestone Review |
| R&D Cycles | PR-14 Catalog |
| All Scoring | Telemetry |

---

## Part VI: Risk Analysis

### Technical Risks

| Risk | Mitigation |
|------|------------|
| Infinite loops in Wiggum | Iteration limits, scope detection |
| Context exhaustion mid-evolution | Pre-check budget, offload to agents |
| Self-modification corruption | Branch-based changes, validation gates |
| Runaway automation | Rate limits, human gates, kill switch |

### Operational Risks

| Risk | Mitigation |
|------|------------|
| User loses control | Override patterns, emergency stop |
| Evolution introduces bugs | Benchmark validation, rollback |
| Bloat from R&D | High adoption bar, periodic cleanup |
| Stale documentation | Freshness audits, automatic flagging |

---

## Part VII: Auto-Resume Signal Integration for Autonomous Workflows

**Added**: 2026-01-21
**Status**: PR-12.11 Proposed

### Background

Jarvis has 17 auto-command wrappers (`.claude/commands/auto-*.md`) that enable autonomous execution of Claude Code built-in `/slash-commands` via the signal-based watcher system. These commands use a **fire-and-forget** pattern where Jarvis sends a signal and the watcher executes the command via tmux keystrokes.

However, fire-and-forget alone doesn't support **autonomous workflows** where Jarvis needs to:
1. Execute a command
2. Wait for it to complete
3. Receive the output/results
4. Continue working based on those results

The **auto-resume** feature addresses this by allowing the watcher to send a continuation message after command execution, automatically resuming Jarvis's work.

### Key Distinction: /usage vs /context

| Command | Shows | Use Case |
|---------|-------|----------|
| `/usage` | Token **BUDGET** usage (session/daily/weekly quotas) | "How much of my quota have I used?" |
| `/context` | Context **WINDOW** usage (tokens in current conversation) | "How much context space is left?" |

**For self-monitoring**, Jarvis needs BOTH:
- `/context` — To decide when JICM compression is needed
- `/usage` — To track session budget consumption

### Current Infrastructure

**Signal Helper** (`.claude/scripts/signal-helper.sh`):
```bash
# Fire-and-forget (existing)
.claude/scripts/signal-helper.sh usage

# With auto-resume (new)
.claude/scripts/signal-helper.sh with-resume /usage "" "continue" 3
```

Parameters for `with-resume`:
1. Command (e.g., `/usage`, `/context`)
2. Args (empty string if none)
3. Resume message (sent after command completes)
4. Resume delay (seconds to wait)

**Watcher Support** (`jarvis-watcher.sh`):
- Reads `auto_resume`, `resume_delay`, `resume_message` from signal JSON
- Executes command, waits delay, sends resume message

### PR-12.11: Auto-Resume Enhancement for All Auto-Commands

**Purpose**: Upgrade auto-commands to support both fire-and-forget AND auto-resume modes, enabling fully autonomous self-monitoring workflows.

**Revised**: 2026-01-21 (Expanded command list, added issues discovered)

#### Complete Native Claude Code Command List

| Command | Description | Auto-Resume Compatible | Notes |
|---------|-------------|------------------------|-------|
| `/clear` | Clears conversation history | ✅ YES | Already integrated with JICM |
| `/compact` | Compresses conversation | ✅ YES | Accepts focus parameter |
| `/context` | Visualizes context usage | ✅ YES | Core self-monitoring |
| `/cost` | Shows token/cost statistics | ✅ YES | Budget tracking |
| `/doctor` | Checks installation | ✅ YES | Diagnostics |
| `/export` | Exports conversation | ⚠️ PARTIAL | **Must pass filename** (see issues) |
| `/model` | Switches AI models | ❌ NO | Interactive menu |
| `/pr-comments` | Shows PR comments | ⚠️ PARTIAL | **GitHub access issues** (see issues) |
| `/release-notes` | Shows release notes | ✅ YES | Information |
| `/resume` | Continues previous conversation | ⚠️ PARTIAL | May need session ID |
| `/review` | Requests code review | ✅ YES | Code quality |
| `/rewind` | Returns to earlier state | ❌ NO | Interactive point selection |
| `/security-review` | Performs security review | ✅ YES | Security checks |
| `/status` | Opens settings panel | ⚠️ CONFLICT | **Conflicts with Jarvis /status** |
| `/statusline` | Sets up statusline UI | ✅ YES | One-time setup |
| `/terminal-setup` | Installs key binding | ❌ NO | One-time manual setup |
| `/todos` | Lists TODO entries | ✅ YES | Task tracking |
| `/usage` | Shows plan usage limits | ✅ YES | Budget monitoring |

**Legend**:
- ✅ YES = Fully compatible with auto-resume
- ⚠️ PARTIAL = Works but needs special handling
- ❌ NO = Interactive/manual, not suitable for auto-resume

#### PR-12.11.1: Issues Discovered (2026-01-21)

**Issue 1: /export Requires Filename**
```
Problem: /export without filename opens interactive menu
Solution: Always pass filename parameter
Pattern: .claude/scripts/signal-helper.sh with-resume /export "session-$(date +%Y%m%d-%H%M).md" "continue" 3
```

**Issue 2: /pr-comments GitHub Access**
```
Problem: Repository davidmoneil/AIfred cannot be resolved
Cause: Remote URL points to upstream baseline, not Jarvis fork
Error: GraphQL: Could not resolve to a Repository with the name 'davidmoneil/AIfred'

Solutions:
1. Update git remote to point to CannonCoPilot fork for PR operations
2. Or skip /pr-comments for Jarvis repo (no PRs against upstream)
3. Document limitation: /pr-comments only works for repos user has access to
```

**Issue 3: /status Namespace Conflict**
```
Problem: Native /status conflicts with Jarvis custom /status command
Current behavior: Jarvis /status shows autonomic system status, not settings panel

Solutions:
1. Create /auto-settings for native settings panel
2. Or rename Jarvis status to /jarvis-status
3. Document: /status shows Jarvis autonomic status, not native settings
```

**Issue 4: Interactive Commands**
```
Commands that open interactive menus are NOT compatible with auto-resume:
- /model - Model picker menu
- /rewind - Interactive point selection
- /terminal-setup - Manual iTerm2/VS Code setup

These should NOT have auto-* wrappers created.
```

#### PR-12.11.2: Commands to Implement

**Tier 1 - Core Self-Monitoring** (HIGH priority):
| Command | Auto-Command | Status | Notes |
|---------|--------------|--------|-------|
| /context | auto-context | ✅ DONE | Updated with auto-resume |
| /usage | auto-usage | ✅ DONE | Updated with auto-resume |
| /cost | auto-cost | 🔲 TODO | Budget tracking |
| /compact | auto-compact | 🔲 TODO | Context management |

**Tier 2 - Session Management** (MEDIUM priority):
| Command | Auto-Command | Status | Notes |
|---------|--------------|--------|-------|
| /doctor | auto-doctor | 🔲 TODO | Diagnostics |
| /export | auto-export | 🔲 TODO | Must pass filename |
| /todos | auto-todos | 🔲 TODO | Task tracking |
| /review | auto-review | 🔲 TODO | Code quality |
| /security-review | auto-security-review | 🔲 TODO | Security |

**Tier 3 - Information** (LOW priority):
| Command | Auto-Command | Status | Notes |
|---------|--------------|--------|-------|
| /release-notes | auto-release-notes | 🔲 TODO | Information |
| /statusline | auto-statusline | 🔲 TODO | One-time setup |

**Not Implementing** (interactive/conflicts):
| Command | Reason |
|---------|--------|
| /model | Interactive menu |
| /rewind | Interactive selection |
| /terminal-setup | Manual one-time setup |
| /status | Conflicts with Jarvis /status |
| /pr-comments | GitHub access issues |

#### PR-12.11.3: Update signal-helper.sh Whitelist

Add new commands to `SUPPORTED_COMMANDS` array:
```bash
SUPPORTED_COMMANDS=(
    # Existing
    "/compact" "/rename" "/resume" "/export" "/doctor"
    "/status" "/usage" "/cost" "/bashes" "/review"
    "/plan" "/security-review" "/stats" "/todos" "/context"
    "/hooks" "/release-notes" "/clear"
    # New additions
    "/statusline"
)
```

#### PR-12.11.4: Self-Monitoring Workflow Patterns

**Pattern A: Context Health Check**
```
1. Send /context with auto-resume
2. Watcher executes, waits 3s, sends "continue"
3. Jarvis receives context breakdown in system-reminder
4. Jarvis decides if JICM compression needed
5. Loop continues autonomously
```

**Pattern B: Budget Monitoring**
```
1. Send /usage with auto-resume
2. Watcher executes, waits 3s, sends "continue"
3. Jarvis receives budget info (session/daily/weekly quotas)
4. Jarvis logs/tracks session budget
5. Can trigger alerts if budget low
```

**Pattern C: Combined Health Dashboard**
```
1. Send /context with auto-resume
2. After resume, send /usage with auto-resume
3. After resume, aggregate both into health report
4. Store in .claude/logs/health-dashboard.json
5. Continue with work
```

**Pattern D: Export on Checkpoint**
```
1. Before JICM compression, send /export with auto-resume
2. Filename: session-YYYYMMDD-HHMM.md
3. After resume, continue with compression
4. Conversation preserved for reference
```

#### PR-12.11.5: Validation Test Suite

| Test ID | Command | Resume Message | Expected Behavior |
|---------|---------|----------------|-------------------|
| AR-01 | /context | "continue" | Context shown, Jarvis resumes |
| AR-02 | /usage | "proceed" | Budget shown, Jarvis resumes |
| AR-03 | /cost | "next" | Cost shown, Jarvis resumes |
| AR-04 | /compact | "done" | Compaction complete, Jarvis resumes |
| AR-05 | /doctor | "continue" | Diagnostics shown, Jarvis resumes |
| AR-06 | /export "test.md" | "continue" | File exported, Jarvis resumes |
| AR-07 | /todos | "continue" | Todos shown, Jarvis resumes |
| AR-08 | /review | "continue" | Review started, Jarvis resumes |
| AR-09 | Chained | Multiple | Sequential commands work |

**Acceptance Criteria**:
- [ ] All Tier 1 auto-commands document auto-resume mode
- [ ] All Tier 2 auto-commands document auto-resume mode
- [ ] signal-helper.sh whitelist updated
- [ ] Issues documented and workarounds implemented
- [ ] Self-monitoring workflows validated end-to-end
- [ ] No race conditions or missed signals

---

### PR-12.12: Agent Parse Error Fixes

**Purpose**: Fix the 11 agent files with missing required frontmatter fields.

**Discovered**: 2026-01-21 via `/doctor`

#### Agent Files to Fix

| File | Error | Fix Required |
|------|-------|--------------|
| `agents/archive/memory-bank-synchronizer.md` | Missing "description" | Add description field |
| `agents/archive/_template-agent.md` | Missing "name" | Add name field |
| `agents/archive/deep-research.md` | Missing "name" | Add name field |
| `agents/archive/docker-deployer.md` | Missing "name" | Add name field |
| `agents/archive/service-troubleshooter.md` | Missing "name" | Add name field |
| `agents/_template-agent.md` | Missing "name" | Add name field |
| `agents/project-manager.md` | Missing "name" | Add name field |
| `agents/code-review.md` | Missing "name" | Add name field |
| `agents/code-tester.md` | Missing "name" | Add name field |
| `agents/code-implementer.md` | Missing "name" | Add name field |
| `agents/code-analyzer.md` | Missing "name" | Add name field |

#### Required Frontmatter Format

```yaml
---
name: agent-name
description: Brief description of what the agent does
model: haiku  # or sonnet, opus
---
```

#### Implementation

1. Add `name` field to all 10 agents missing it
2. Add `description` field to memory-bank-synchronizer.md
3. Run `/doctor` to verify fixes
4. Consider moving archive agents to a non-parsed location

**Acceptance Criteria**:
- [ ] `/doctor` shows 0 agent parse errors
- [ ] All active agents have valid frontmatter
- [ ] Archive agents either fixed or moved to non-parsed location

---

### Use Cases Enabled by PR-12.11

1. **Autonomous Context Management**: Jarvis monitors own context, triggers JICM when needed
2. **Budget-Aware Operation**: Jarvis tracks session budget, warns user proactively
3. **Health Dashboards**: Periodic self-assessment without user intervention
4. **Workflow Checkpoints**: Check status mid-workflow, continue based on results
5. **Diagnostic Workflows**: Run /doctor autonomously during maintenance cycles
6. **Automatic Export**: Save conversation before major operations

### Implementation Notes

- Auto-resume delay should be configurable (default 3s)
- Resume messages should be contextual ("continue", "proceed", "next step", etc.)
- Failed commands should still trigger resume (with error context)
- Watcher logs should capture auto-resume events for debugging
- /export MUST always include filename parameter
- /status conflict requires namespace resolution

---

## Conclusion

This design document defines a comprehensive architecture for transforming Jarvis into a self-directed, self-improving system while maintaining operational discipline. The nine autonomic systems work together to create a continuous improvement loop that:

1. **Launches** with full context awareness
2. **Drives** work to completion autonomously
3. **Reviews** outcomes for quality
4. **Manages** resources efficiently
5. **Reflects** on experience
6. **Researches** external innovations
7. **Evolves** itself safely
8. **Maintains** codebase health
9. **Completes** sessions cleanly

The restructured PR-11 through PR-14 provides an incremental implementation path with clear dependencies and validation criteria. **PR-12.11** (Auto-Resume Enhancement) adds the critical capability for fully autonomous self-monitoring workflows.

---

*Phase 6 Autonomy Design Document v2.0*
*Created: 2026-01-13*
*Revised: 2026-01-21 (Added PR-12.11 Auto-Resume Enhancement)*
*Status: Active Development*
