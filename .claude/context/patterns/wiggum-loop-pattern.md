# Wiggum Loop Pattern

**Version**: 1.0.0
**Created**: 2026-01-16
**Component**: AC-02 Wiggum Loop
**PR**: PR-12.2

---

## Overview

The Wiggum Loop is a multi-pass verification pattern that ensures work quality through iterative refinement. Named after the Ralph Wiggum technique, it adds layers of reflective reasoning, self-checking, and revisionary correction to everything Jarvis produces.

### Core Principle

**Wiggum Loop is DEFAULT behavior.** Every task runs through multi-pass verification unless explicitly disabled with keywords like "quick", "rough", or "simple".

---

## 1. Default Behavior

### Always Active

The Wiggum Loop is the standard mode of operation:

- "Keep going until done" is IMPLICIT — never needs stating
- There is ALWAYS in-progress work (startup procedure counts)
- Loop continues across `/clear` cycles via state persistence
- Loop resumes on session restart via checkpoint

### Disable Only With Explicit Keywords

| Keyword Phrase | Effect |
|----------------|--------|
| "quick solution" | Single-pass only |
| "rough pass" | Single-pass only |
| "first pass" | Single-pass only |
| "simple sketch" | Single-pass only |
| "just a draft" | Single-pass only |
| "quick fix" | Single-pass only |
| "rough draft" | Single-pass only |

### Detection Logic

```javascript
// Pseudocode for suppression detection
function shouldSuppressWiggum(userMessage) {
  const suppressionPhrases = [
    'quick solution', 'rough pass', 'first pass',
    'simple sketch', 'just a draft', 'quick fix', 'rough draft'
  ];

  const lowerMessage = userMessage.toLowerCase();
  return suppressionPhrases.some(phrase => lowerMessage.includes(phrase));
}
```

---

## 2. Loop Structure

### Six-Step Iteration

```
┌─────────────────────────────────────────────────────────────┐
│                    WIGGUM LOOP ITERATION                     │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  1. EXECUTE                                          │    │
│  │     └── Perform work on current task/todo            │    │
│  │     └── Use TodoWrite to track sub-tasks             │    │
│  │     └── Make incremental progress                    │    │
│  └─────────────────────────────────────────────────────┘    │
│                           │                                  │
│                           ▼                                  │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  2. CHECK                                            │    │
│  │     └── Verify work meets requirements               │    │
│  │     └── Run tests if applicable                      │    │
│  │     └── Validate output format/content               │    │
│  └─────────────────────────────────────────────────────┘    │
│                           │                                  │
│                           ▼                                  │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  3. REVIEW                                           │    │
│  │     └── Self-review for quality/completeness         │    │
│  │     └── Would this pass code review?                 │    │
│  │     └── Any edge cases missed?                       │    │
│  └─────────────────────────────────────────────────────┘    │
│                           │                                  │
│                           ▼                                  │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  4. DRIFT CHECK                                      │    │
│  │     └── Still aligned with original task?            │    │
│  │     └── Compare current work to request              │    │
│  │     └── If drifted → realign, don't exit             │    │
│  └─────────────────────────────────────────────────────┘    │
│                           │                                  │
│                           ▼                                  │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  5. CONTEXT CHECK                                    │    │
│  │     └── JICM status: near threshold?                 │    │
│  │     └── If high → checkpoint → /clear → resume       │    │
│  │     └── If OK → continue                             │    │
│  └─────────────────────────────────────────────────────┘    │
│                           │                                  │
│                           ▼                                  │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  6. CONTINUE or COMPLETE                             │    │
│  │     └── More work needed? → Loop to step 1           │    │
│  │     └── All done AND verified? → Exit loop           │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### Pass Naming

| Pass | Focus |
|------|-------|
| Pass 1 | Initial implementation |
| Pass 2 | Verification and fixes |
| Pass 3 | Edge cases and polish |
| Pass 4+ | Refinement (if needed) |

---

## 3. Loop State Persistence

### State File Location

```
.claude/state/components/AC-02-wiggum.json
```

### State Schema

```json
{
  "$schema": "wiggum-state-v1",
  "component_id": "AC-02",
  "version": "1.0.0",
  "status": "active",
  "last_updated": "2026-01-16T14:30:00.000Z",

  "current_loop": {
    "task_id": "uuid-v4",
    "task_description": "Implement PR-12.2 Wiggum Loop",
    "started_at": "2026-01-16T14:00:00.000Z",
    "current_pass": 2,
    "max_passes": 5,
    "suppressed": false,
    "suppression_reason": null
  },

  "passes": [
    {
      "pass_number": 1,
      "started_at": "2026-01-16T14:00:00.000Z",
      "completed_at": "2026-01-16T14:15:00.000Z",
      "issues_found": 3,
      "issues_fixed": 3,
      "drift_detected": false,
      "context_checkpoint": false
    },
    {
      "pass_number": 2,
      "started_at": "2026-01-16T14:15:00.000Z",
      "completed_at": null,
      "issues_found": 1,
      "issues_fixed": 0,
      "drift_detected": false,
      "context_checkpoint": false
    }
  ],

  "todos": {
    "total": 5,
    "completed": 3,
    "in_progress": 1,
    "pending": 1
  },

  "metrics": {
    "total_token_cost": 25000,
    "total_duration_ms": 900000,
    "avg_pass_duration_ms": 450000
  },

  "history": {
    "last_completed_task": "2026-01-16T13:00:00.000Z",
    "total_tasks_completed": 15,
    "avg_passes_per_task": 2.3
  }
}
```

### State Status Values

| Status | Description |
|--------|-------------|
| `idle` | No active loop |
| `active` | Loop in progress |
| `paused` | Paused for JICM checkpoint |
| `completed` | Task finished successfully |
| `suppressed` | Skipped due to quick/rough |
| `aborted` | Stopped due to error |

---

## 4. Stopping Conditions

### Valid Stop Conditions

Only these conditions end the Wiggum Loop:

1. **All work complete AND verified**
   - All todos marked complete
   - Self-review passed
   - No remaining issues

2. **User explicit interrupt**
   - Ctrl+C signal
   - User types "stop", "cancel", "abort"

3. **Safety gate triggered**
   - Destructive operation blocked
   - Policy violation detected
   - Max iterations reached

### NOT Stop Conditions

These continue the loop, not end it:

| Condition | Response |
|-----------|----------|
| "Blocker encountered" | Investigate → attempt resolution → report |
| "Context exhaustion" | Checkpoint → /clear → resume loop |
| "Scope drift" | Realign with task aims → continue |
| "Idle/timeout" | Switch to R&D/Maintenance/Reflection |
| "Uncertain about approach" | Try approach → evaluate → iterate |

---

## 5. JICM Integration

### Pause Points

The Wiggum Loop integrates with JICM (AC-04) for context management:

```
┌─────────────────────────────────────────────────────────────┐
│                    JICM PAUSE POINT                          │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  During Step 5 (Context Check):                              │
│                                                              │
│  1. Query JICM for context status                            │
│  2. If below threshold (< 80%) → continue                    │
│  3. If near threshold (80-90%) → checkpoint, continue        │
│  4. If at threshold (> 90%) → checkpoint → /clear → resume   │
│                                                              │
│  Key: JICM is a PAUSE point, not an INTERRUPT                │
│  - Loop state is saved                                       │
│  - /clear executed                                           │
│  - Loop RESUMES on restart                                   │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### Context Checkpoint Content

When creating a checkpoint for context exhaustion:

```markdown
## Wiggum Loop Checkpoint

**Task**: [original task description]
**Current Pass**: [pass number]
**Todos Status**: [X completed, Y in progress, Z pending]

### Completed Work
- [list of completed items]

### In Progress
- [current work item]

### Remaining
- [pending items]

## Next Steps After Restart
1. Resume Wiggum Loop at pass [N]
2. Continue with [current todo]
3. Complete remaining [Z] items
```

---

## 6. Drift Detection

### What is Drift?

Drift occurs when work diverges from the original task request:
- Adding features not requested
- Solving a different problem
- Over-engineering the solution
- Missing the core requirement

### Drift Check Process

```
┌─────────────────────────────────────────────────────────────┐
│                    DRIFT DETECTION                           │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  1. COMPARE                                                  │
│     └── Original task: "[user's request]"                    │
│     └── Current work: "[what we're doing now]"               │
│                                                              │
│  2. EVALUATE                                                 │
│     └── Is current work directly serving the request?        │
│     └── Are we adding unnecessary complexity?                │
│     └── Have we changed the goal?                            │
│                                                              │
│  3. RESPOND                                                  │
│     └── If aligned → continue                                │
│     └── If drifted → realign, don't exit                     │
│                                                              │
│  REALIGNMENT (if drifted):                                   │
│     └── Acknowledge drift                                    │
│     └── Identify what caused it                              │
│     └── Refocus on original request                          │
│     └── Continue loop with corrected direction               │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## 7. Safety Mechanisms

### Iteration Limits

| Setting | Default | Purpose |
|---------|---------|---------|
| `max_passes` | 5 | Prevent infinite loops |
| `checkpoint_interval` | 360 min | Time-based save |
| `max_duration` | None | No time limit by default |

### When Max Iterations Reached

```
1. Save current state
2. Log warning: "Max iterations (5) reached"
3. Present work completed so far
4. Ask user: "Continue with more passes or accept current state?"
```

### Destructive Operation Gates

All destructive operations require confirmation:
- File deletion
- Database modifications
- External API calls with side effects
- Git force operations

---

## 8. Integration with TodoWrite

### Todo Management

The Wiggum Loop uses TodoWrite for progress tracking:

```javascript
// At loop start
TodoWrite([
  { content: "Step 1: ...", status: "in_progress", activeForm: "Working on step 1" },
  { content: "Step 2: ...", status: "pending", activeForm: "Working on step 2" },
  { content: "Step 3: ...", status: "pending", activeForm: "Working on step 3" }
]);

// During execution
// Mark complete as work progresses

// At loop end
// All todos should be "completed"
```

### Completion Verification

Before exiting loop, verify:

1. All todos are "completed" (not just "in_progress")
2. No pending items remain
3. Self-review confirms quality
4. Original task requirements are met

---

## 9. Examples

### Normal Operation (Default)

```
User: "Add error handling to the API endpoints"

[Wiggum Loop activates automatically]

Pass 1: Implement error handling
- Add try/catch blocks
- Create error response format
- Update 3 endpoints

Pass 2: Verify implementation
- Review code for edge cases
- Found: missing validation errors
- Fixed: added validation handling

Pass 3: Final review
- All requirements met
- No issues found
- Tests pass

[Loop completes - 3 passes]
```

### Suppressed Operation (Quick Mode)

```
User: "Just do a quick fix for that typo"

[Wiggum Loop suppressed - "quick" detected]

Single pass:
- Fixed typo
- Done

[No multi-pass verification]
```

### Context Exhaustion (JICM Pause)

```
User: "Implement the full authentication system"

Pass 1: Start implementation
- Basic auth flow
- Token generation

[Context at 85% - checkpoint created]

Pass 2: Continue
- Token validation
- Session management

[Context at 92% - JICM triggers]
[Checkpoint saved]
[/clear executed]
[Session restarts]
[Loop resumes at pass 3]

Pass 3: Complete implementation
- Logout flow
- Tests
- Documentation

[Loop completes]
```

---

## 10. Metrics

| Metric | Target | Alert |
|--------|--------|-------|
| Average passes | 2-3 | > 5 |
| Early termination rate | > 80% | < 50% |
| Drift detection rate | < 10% | > 25% |
| Suppression rate | < 20% | > 40% |

---

*Wiggum Loop Pattern — Jarvis Phase 6 PR-12.2*
