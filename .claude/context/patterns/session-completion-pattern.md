# Session Completion Pattern

**Pattern ID**: session-completion
**Version**: 1.0.0
**Status**: implementing
**Created**: 2026-01-16
**Component**: AC-09

---

## Overview

The Session Completion pattern defines how Jarvis formally ends sessions with complete state preservation, memory persistence, and clean handoff to the next session. This pattern ensures no work is lost and the next session can seamlessly continue where this one left off.

### Core Principles

1. **User-Prompted Only**: Sessions end ONLY when user explicitly requests
2. **Pre-Completion Value**: Offer Tier 2 cycles before ending
3. **No Lost Work**: Every session ends with full state preservation
4. **Clean Handoff**: Next session has everything needed to continue
5. **Graceful Degradation**: Complete even when components fail

### What DOESN'T End Sessions

| Event | Actual Response |
|-------|-----------------|
| Context exhaustion | AC-04 JICM triggers checkpoint + clear + resume |
| Wiggum Loop completes | Check for more work; offer Tier 2 cycles |
| Idle timeout (~30 min) | Trigger R&D/Maintenance/Reflection |
| Blocker encountered | Investigate via Wiggum Loop; report findings |
| Rate limiting | Checkpoint and wait; resume when available |
| Errors | Handle gracefully; continue or report |

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                    SESSION COMPLETION ARCHITECTURE                   │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  TRIGGER DETECTION                                                   │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │                                                              │    │
│  │  /end-session          → Immediate completion               │    │
│  │  "end session"         → Immediate completion               │    │
│  │  "goodbye"             → Confirm, then completion           │    │
│  │  "done for now"        → Confirm, then completion           │    │
│  │  "that's all"          → Confirm, then completion           │    │
│  │                                                              │    │
│  └─────────────────────────────────────────────────────────────┘    │
│                                                                      │
│  PRE-COMPLETION PHASE                                                │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │                                                              │    │
│  │  Offer Tier 2 Cycles:                                        │    │
│  │  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐            │    │
│  │  │ Self-       │ │ Self-       │ │ R&D         │            │    │
│  │  │ Reflection  │ │ Evolution   │ │ Cycles      │            │    │
│  │  │ (AC-05)     │ │ (AC-06)     │ │ (AC-07)     │            │    │
│  │  └─────────────┘ └─────────────┘ └─────────────┘            │    │
│  │                                                              │    │
│  │  ┌─────────────┐ ┌─────────────────────────────┐            │    │
│  │  │ Maintenance │ │ Skip and end session        │            │    │
│  │  │ (AC-08)     │ │                             │            │    │
│  │  └─────────────┘ └─────────────────────────────┘            │    │
│  │                                                              │    │
│  └─────────────────────────────────────────────────────────────┘    │
│                                                                      │
│  COMPLETION PROTOCOL                                                 │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │                                                              │    │
│  │  Step 1: Work State Capture                                  │    │
│  │  Step 2: Memory Persistence                                  │    │
│  │  Step 3: Context File Updates                                │    │
│  │  Step 4: Chat History Preservation                           │    │
│  │  Step 5: Git Operations                                      │    │
│  │  Step 6: Handoff Preparation                                 │    │
│  │  Step 7: Cleanup                                             │    │
│  │                                                              │    │
│  └─────────────────────────────────────────────────────────────┘    │
│                                                                      │
│  OUTPUT                                                              │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │                                                              │    │
│  │  • Session Summary (displayed + saved)                       │    │
│  │  • Updated session-state.md                                  │    │
│  │  • Updated current-priorities.md                             │    │
│  │  • Git commit (and push if enabled)                          │    │
│  │  • Checkpoint file for next session                          │    │
│  │  • Memory entities for cross-session recall                  │    │
│  │                                                              │    │
│  └─────────────────────────────────────────────────────────────┘    │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Pre-Completion Offer

### Purpose

Before ending the session, offer to run Tier 2 self-improvement cycles. This maximizes the value of each session by using the ending time productively.

### Offer Format

```
Before we wrap up, would you like me to run any of these while you're away?

1. Self-Reflection (AC-05) — Review session learnings and identify patterns
2. Self-Evolution (AC-06) — Implement queued improvement proposals
3. R&D Cycles (AC-07) — Research new tools and patterns
4. Maintenance (AC-08) — Cleanup, health checks, and organization
5. Skip — Proceed directly to end session

Select options (e.g., "1,3" or "all" or "skip"):
```

### User Response Handling

| Response | Action |
|----------|--------|
| Numbers (e.g., "1,3") | Run selected cycles in order |
| "all" | Run all four cycles |
| "skip" or "none" | Proceed to completion |
| Departure phrase | Proceed to completion |

### Cycle Execution

If user selects cycles:

```
Running selected cycles before session end...

[AC-05] Self-Reflection: Scanning session for learnings...
        Found 3 patterns, 1 correction. Proposals queued.

[AC-07] R&D Cycles: Checking research agenda...
        No pending items. Skipped.

Cycles complete. Proceeding to session completion.
```

---

## Seven-Step Completion Protocol

### Step 1: Work State Capture

**Purpose**: Preserve current work status for next session.

```
┌─────────────────────────────────────────────────────────────────────┐
│                    STEP 1: WORK STATE CAPTURE                        │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  UPDATE session-state.md:                                            │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │  ## Current Work Status                                        │  │
│  │                                                                │  │
│  │  **Status**: 🟡 Active — {current work description}            │  │
│  │  **Last Completed**: {last PR/task completed}                  │  │
│  │  **Current Blocker**: {blocker or "None"}                      │  │
│  │  **Current Work**: {what's in progress}                        │  │
│  │                                                                │  │
│  │  ### Session {date} Summary                                    │  │
│  │  {brief description of work done}                              │  │
│  │                                                                │  │
│  │  **Next**: {explicit next step}                                │  │
│  └───────────────────────────────────────────────────────────────┘  │
│                                                                      │
│  CAPTURE TodoWrite State:                                            │
│  • Extract any incomplete todos                                     │
│  • Record in session-state.md under "Pending Items"                 │
│  • Note blocked items with investigation status                     │
│                                                                      │
│  DOCUMENT Key Decisions:                                             │
│  • Technical decisions made during session                          │
│  • Design choices with rationale                                    │
│  • Deferred items with reasoning                                    │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### Step 2: Memory Persistence

**Purpose**: Store session learnings in Memory MCP for cross-session recall.

```
┌─────────────────────────────────────────────────────────────────────┐
│                    STEP 2: MEMORY PERSISTENCE                        │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  CREATE Session Entity:                                              │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │  Entity: Session_2026-01-16                                    │  │
│  │  Type: session                                                 │  │
│  │  Observations:                                                 │  │
│  │  - "Completed PR-12.9 Session Completion implementation"       │  │
│  │  - "Created AC-09 component specification"                     │  │
│  │  - "Created session-completion-pattern.md"                     │  │
│  │  - "Key decision: User-prompted only for session end"          │  │
│  └───────────────────────────────────────────────────────────────┘  │
│                                                                      │
│  CREATE Relations:                                                   │
│  • Session → completed → PR-12.9                                    │
│  • Session → modified → AC-09                                       │
│  • Session → part_of → Phase_6                                      │
│                                                                      │
│  UPDATE Corrections (if any):                                        │
│  • Add to corrections.md (user corrections)                         │
│  • Add to self-corrections.md (Jarvis corrections)                  │
│                                                                      │
│  GRACEFUL DEGRADATION:                                               │
│  If Memory MCP unavailable:                                         │
│  - Log session summary locally                                      │
│  - Note "Memory MCP unavailable" in summary                         │
│  - Continue with remaining steps                                    │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### Step 3: Context File Updates

**Purpose**: Update documentation to reflect session work.

```
┌─────────────────────────────────────────────────────────────────────┐
│                    STEP 3: CONTEXT FILE UPDATES                      │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  UPDATE current-priorities.md:                                       │
│  • Mark completed PRs/tasks                                         │
│  • Update "In Progress" section                                     │
│  • Update "Next Step" pointer                                       │
│  • Add to "Completed" section if milestone reached                  │
│                                                                      │
│  UPDATE Modified Pattern Files:                                      │
│  • If patterns were revised, ensure changes saved                   │
│  • Update version numbers if applicable                             │
│  • Update "Last Modified" dates                                     │
│                                                                      │
│  UPDATE Configuration Files:                                         │
│  • autonomy-config.yaml if settings changed                         │
│  • paths-registry.yaml if paths changed                             │
│  • settings.json if hooks changed                                   │
│                                                                      │
│  UPDATE Roadmap (if milestones changed):                             │
│  • Mark completed PRs                                               │
│  • Update phase progress                                            │
│  • Note any scope changes                                           │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### Step 4: Chat History Preservation

**Purpose**: Store conversation context for recovery in next session.

```
┌─────────────────────────────────────────────────────────────────────┐
│                    STEP 4: CHAT HISTORY PRESERVATION                 │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  PRESERVATION OPTIONS:                                               │
│                                                                      │
│  Option A: Reference-Based (Default)                                 │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │  • Session summary contains key pointers                       │  │
│  │  • JSONL transcript in ~/.claude/projects/                     │  │
│  │  • Checkpoint file with context essentials                     │  │
│  │  • Next session reads checkpoint + key files                   │  │
│  └───────────────────────────────────────────────────────────────┘  │
│                                                                      │
│  Option B: Archive-Based (Full Context)                              │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │  • Full conversation archived to file                          │  │
│  │  • Location: .claude/archives/sessions/                        │  │
│  │  • Format: Compressed markdown or JSONL                        │  │
│  │  • Use case: Deep context recovery                             │  │
│  └───────────────────────────────────────────────────────────────┘  │
│                                                                      │
│  MINIMUM PRESERVED (Always):                                         │
│  • Session summary with accomplishments                             │
│  • Key decisions and rationale                                      │
│  • Blockers and their status                                        │
│  • Next steps with context                                          │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### Step 5: Git Operations

**Purpose**: Commit session work and optionally push to remote.

```
┌─────────────────────────────────────────────────────────────────────┐
│                    STEP 5: GIT OPERATIONS                            │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  STAGE Changes:                                                      │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │  git add .claude/context/                                      │  │
│  │  git add .claude/reports/                                      │  │
│  │  git add projects/                                             │  │
│  │  # Exclude: .claude/logs/, .claude/state/temp/                │  │
│  └───────────────────────────────────────────────────────────────┘  │
│                                                                      │
│  CREATE Commit:                                                      │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │  git commit -m "Session: {brief summary}                       │  │
│  │                                                                │  │
│  │  {detailed description of work done}                           │  │
│  │                                                                │  │
│  │  Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>"      │  │
│  └───────────────────────────────────────────────────────────────┘  │
│                                                                      │
│  PUSH (if auto_push enabled):                                        │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │  git push origin {current_branch}                              │  │
│  │                                                                │  │
│  │  If push fails:                                                │  │
│  │  - Log warning                                                 │  │
│  │  - Note in session summary: "Push pending"                     │  │
│  │  - Continue with remaining steps                               │  │
│  └───────────────────────────────────────────────────────────────┘  │
│                                                                      │
│  MULTI-REPO (if applicable):                                         │
│  • Check paths-registry.yaml for multiple repos                     │
│  • Stage/commit each repo with appropriate message                  │
│  • Push each if enabled                                             │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### Step 6: Handoff Preparation

**Purpose**: Prepare everything needed for seamless next session start.

```
┌─────────────────────────────────────────────────────────────────────┐
│                    STEP 6: HANDOFF PREPARATION                       │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  CREATE Checkpoint File:                                             │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │  Location: .claude/context/.checkpoint.md                      │  │
│  │                                                                │  │
│  │  Content:                                                      │  │
│  │  ---                                                           │  │
│  │  created: 2026-01-16T22:00:00.000Z                             │  │
│  │  session: Session_2026-01-16                                   │  │
│  │  status: completed                                             │  │
│  │  ---                                                           │  │
│  │                                                                │  │
│  │  ## Next Session Instructions                                  │  │
│  │                                                                │  │
│  │  **Continue with**: PR-12.10 (Self-Improvement Command)        │  │
│  │  **Context files to read**: current-priorities.md,             │  │
│  │                             session-state.md                   │  │
│  │  **MCPs suggested**: Tier 1 only (specification work)          │  │
│  │                                                                │  │
│  │  ## Session Summary                                            │  │
│  │  {brief summary of what was done}                              │  │
│  └───────────────────────────────────────────────────────────────┘  │
│                                                                      │
│  CONFIGURE MCP Suggestions:                                          │
│  • Analyze "Next Step" for keywords                                 │
│  • Suggest appropriate Tier 2 MCPs                                  │
│  • Note in checkpoint file                                          │
│                                                                      │
│  UPDATE session-state.md "Next Step":                                │
│  • Explicit, actionable next step                                   │
│  • Include PR/task reference                                        │
│  • Note any prerequisites                                           │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### Step 7: Cleanup

**Purpose**: Clean up transient files and stop background processes.

```
┌─────────────────────────────────────────────────────────────────────┐
│                    STEP 7: CLEANUP                                   │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  CLEAR Transient Files:                                              │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │  Remove:                                                       │  │
│  │  • .claude/context/.soft-restart-checkpoint.md (if exists)    │  │
│  │  • .claude/state/temp/* (temporary state)                     │  │
│  │  • .claude/cache/* (if exists)                                │  │
│  │                                                                │  │
│  │  Keep:                                                         │  │
│  │  • .claude/context/.checkpoint.md (for next session)          │  │
│  │  • .claude/logs/* (for debugging)                             │  │
│  └───────────────────────────────────────────────────────────────┘  │
│                                                                      │
│  STOP Watcher (if running):                                          │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │  Check for auto-clear watcher process                          │  │
│  │  If running: send termination signal                          │  │
│  │  Verify process stopped                                       │  │
│  └───────────────────────────────────────────────────────────────┘  │
│                                                                      │
│  LOG Session Statistics:                                             │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │  Append to .claude/logs/session-stats.jsonl:                   │  │
│  │  {                                                            │  │
│  │    "date": "2026-01-16",                                      │  │
│  │    "duration_minutes": 120,                                   │  │
│  │    "tokens_used": 150000,                                     │  │
│  │    "commits": 3,                                              │  │
│  │    "files_modified": 15,                                      │  │
│  │    "tier2_cycles_run": 1,                                     │  │
│  │    "handoff_quality": 95                                      │  │
│  │  }                                                            │  │
│  └───────────────────────────────────────────────────────────────┘  │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Session Summary Template

### Display Format

```markdown
# Session Summary — {date}

## Accomplishments
- {item 1}
- {item 2}
- {item 3}

## Key Decisions
- {decision 1}: {rationale}
- {decision 2}: {rationale}

## Files Modified
| File | Change Type |
|------|-------------|
| {path} | {created/modified/deleted} |

## Blockers
{None or list of blockers with status}

## Next Session
**Continue with**: {explicit next step}
**Context**: {files to read}
**MCPs**: {suggested tier}

## Statistics
- Duration: {X} minutes
- Tokens: {Y}K / 200K
- Commits: {N}

---
*Session ended: {timestamp}*
```

### Storage Format

**Location**: `.claude/reports/sessions/session-YYYY-MM-DD.md`

If multiple sessions on same day, append counter: `session-2026-01-16-2.md`

---

## Integration with /end-session Command

The existing `/end-session` command should be enhanced to invoke AC-09:

```markdown
# Enhanced /end-session Command

When invoked:
1. Check for pre-completion offer preference (autonomy-config.yaml)
2. Display pre-completion offer (unless disabled)
3. Run selected Tier 2 cycles (if any)
4. Execute seven-step completion protocol
5. Display session summary
6. Confirm session ended

Options:
  /end-session              # Full workflow with offer
  /end-session --quick      # Skip pre-completion offer
  /end-session --no-push    # Skip git push
  /end-session --no-commit  # Skip git operations entirely
```

---

## Configuration

### autonomy-config.yaml Settings

```yaml
session_completion:
  # Enable pre-completion offer
  pre_completion_offer: true

  # Auto-push on commit
  auto_push: true

  # Create session summary report
  create_summary: true

  # Archive full conversation
  archive_conversation: false

  # Memory MCP persistence
  memory_persistence: true

  # Cleanup transients
  cleanup_transients: true

  # Stop watcher on exit
  stop_watcher: true
```

---

## Error Handling

### Graceful Degradation Matrix

| Component | Failure | Response |
|-----------|---------|----------|
| Memory MCP | Connection failed | Log locally, continue |
| Git | Not a repo | Skip commit, preserve state |
| Git push | Network/auth error | Commit locally, note pending |
| File write | Permission denied | Warn user, show content |
| Watcher | Not running | Skip shutdown |

### Recovery Messages

```
Git push failed (network error):
  ✓ Changes committed locally
  ⚠ Push pending for next session

  To push manually: git push origin Project_Aion

Memory MCP unavailable:
  ⚠ Session summary saved locally only
  ⚠ Cross-session recall may be limited

  Memory will sync when MCP is available.
```

---

## Safety Considerations

### Pre-Exit Checks

Before proceeding with completion:

1. **Uncommitted critical changes**: Warn and offer to commit
2. **Active destructive operation**: Block until complete
3. **Unsaved user work**: Confirm before proceeding
4. **Background processes**: Ensure clean shutdown

### Cannot Skip

Even with `--quick` flag, these always run:

1. Work state capture (session-state.md update)
2. Checkpoint file creation
3. Session statistics logging

---

*Session Completion Pattern — AC-09 Implementation Guide*
