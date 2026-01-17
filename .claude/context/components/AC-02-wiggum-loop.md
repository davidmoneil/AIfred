# AC-02 Wiggum Loop — Autonomic Component Specification

**Component ID**: AC-02
**Version**: 1.0.0
**Status**: active
**Created**: 2026-01-16
**Last Modified**: 2026-01-17
**PR**: PR-12.2 (Implementation Complete)

---

## 1. Identity

### Purpose
Add multiple layers of reflective reasoning, self-checking, and revisionary correction to everything Jarvis produces. **Wiggum Loop is the DEFAULT behavior** — multi-pass verification runs automatically unless explicitly disabled with keywords like "quick", "rough", or "simple".

### Scope
| Dimension | Applies |
|-----------|---------|
| Jarvis Codebase | Yes |
| Active Project | Yes |
| All Sessions | Yes |

### Tier Classification
- [x] **Tier 1**: Active Work (user-facing, direct task contribution)
- [ ] **Tier 2**: Self-Improvement (Jarvis-only, background operation)

### Design Principles

1. **Default ON**: Wiggum Loop is the standard mode; explicit language required to disable
2. **Completion = Verified**: Not just "todos done" but "todos done AND reviewed AND sufficient"
3. **Never Just Stop**: Context exhaustion, blockers, drift all trigger continuation, not exit
4. **Progress Visibility**: TodoWrite provides continuous progress tracking

---

## 2. Triggers

### Activation Conditions
| Trigger Type | Condition | Priority |
|--------------|-----------|----------|
| **Automatic** | Task assigned (DEFAULT behavior) | high |
| **Event-Based** | Self-Launch detects pending work | high |
| **Event-Based** | Milestone Review requests remediation | high |
| **Event-Based** | JICM checkpoint → clear → resume | high |
| **Manual** | `/ralph-wiggum:ralph-loop` | medium |

### Trigger Implementation
```
Detection logic:
  - DEFAULT: Always active when work is in progress
  - Task assignment triggers loop automatically
  - Loop persists across /clear cycles via loop-state.json
  - Checkpoint restoration re-enters loop
```

### Suppression Conditions
| Condition | Behavior |
|-----------|----------|
| User says "quick", "rough", "simple", "draft", "first pass" | Single-pass only |
| `JARVIS_DISABLE_AC02=true` | Skip entirely |
| `JARVIS_QUICK_MODE=true` | Single-pass only |
| `wiggum.default_active=false` in config | Opt-in mode |

### Suppression Keywords (Exact Phrases)
- "quick solution"
- "rough pass"
- "first pass"
- "simple sketch"
- "just a draft"
- "quick fix"
- "rough draft"

---

## 3. Inputs

### Required Inputs
| Input | Source | Format | Purpose |
|-------|--------|--------|---------|
| Current task | User message / session-state | Text | What to work on |
| Todo list | TodoWrite state | Array | Progress tracking |

### Optional Inputs
| Input | Source | Default | Purpose |
|-------|--------|---------|---------|
| Loop state | `.claude/state/components/AC-02-wiggum.json` | Fresh start | Resume from previous |
| Max iterations | autonomy-config.yaml | 5 | Safety limit |
| Checkpoint interval | autonomy-config.yaml | 360 min | Time-based save |

### Context Requirements

- [x] Current task description
- [x] TodoWrite state (in-progress todos)
- [ ] JICM context threshold (for pause points)
- [ ] Previous loop state (if resuming)

---

## 4. Outputs

### Primary Outputs
| Output | Destination | Format | Consumers |
|--------|-------------|--------|-----------|
| Completed work | Files, stdout | Various | User |
| Loop state | `.claude/state/components/AC-02-wiggum.json` | JSON | AC-02 (resume) |
| Progress updates | TodoWrite | Array | User visibility |
| Completion event | Event log | JSONL | AC-03 Review |

### Side Effects
| Effect | Description | Reversible |
|--------|-------------|------------|
| File modifications | Code/docs changed per task | Via git |
| Todo updates | TodoWrite reflects progress | Yes |
| State persistence | Loop state saved | Yes (delete) |

### State Changes
| State | Location | Change Type |
|-------|----------|-------------|
| Loop state | `.claude/state/components/AC-02-wiggum.json` | create/update |
| Todo list | Claude internal | update |
| Event log | `.claude/events/current.jsonl` | append |

---

## 5. Dependencies

### System Dependencies
| Dependency | Type | Failure Behavior |
|------------|------|------------------|
| AC-04 JICM | soft | Degrade (no pause points) |
| TodoWrite | hard | Cannot track progress |

### MCP Dependencies
| MCP Server | Tools Used | Required |
|------------|------------|----------|
| None | — | — |

### File Dependencies
| File | Purpose | Create if Missing |
|------|---------|-------------------|
| `.claude/state/components/AC-02-wiggum.json` | Loop persistence | Yes |
| `.claude/events/current.jsonl` | Event logging | Yes |

---

## 6. Consumers

### Downstream Systems
| Consumer | Relationship | Data Consumed |
|----------|--------------|---------------|
| AC-03 Milestone Review | triggers | Loop completion event |
| AC-04 JICM | reads | Context usage estimate |
| AC-05 Reflection | reads | Loop metrics for analysis |

### User Visibility
| Aspect | Visible to User |
|--------|-----------------|
| Execution start | No (implicit) |
| Progress updates | Yes (via TodoWrite) |
| Completion notice | Yes (task done message) |
| Error reports | Yes (if blocking) |

### Integration Points

```
┌─────────────────┐
│   AC-01         │
│   Self-Launch   │
└────────┬────────┘
         │ triggers if work pending
         ▼
┌─────────────────┐     ┌─────────────────┐
│   AC-02         │◄───►│   AC-04         │
│   Wiggum Loop   │     │   JICM          │
└────────┬────────┘     └─────────────────┘
         │ pause points
         │ on completion
         ▼
┌─────────────────┐
│   AC-03         │
│   Review        │
└─────────────────┘
```

---

## 7. Gates

### Approval Checkpoints
| Gate ID | Trigger | Risk Level | Auto-Approve |
|---------|---------|------------|--------------|
| G-01 | Code modification | Medium | Yes (tracked in git) |
| G-02 | Destructive operation | High | No (requires confirmation) |

### Risk Classification
| Action Type | Risk Level | Gate Requirement |
|-------------|------------|------------------|
| Read/analyze code | Low | None |
| Write new files | Medium | Auto-approve (git tracked) |
| Modify existing files | Medium | Auto-approve (git tracked) |
| Delete files | High | Require confirmation |
| External API calls | Medium | Auto-approve |

### Gate Implementation
```
Wiggum Loop inherits standard gate behavior from PR-11.4.
All code modifications are git-tracked for rollback.
Destructive operations always require explicit user confirmation.
```

---

## 8. Metrics

### Performance Metrics
| Metric | Unit | Target | Alert Threshold |
|--------|------|--------|-----------------|
| Passes per task | count | 2-3 | > 5 |
| Time per pass | minutes | < 30 | > 60 |
| Token cost per task | tokens | < 50000 | > 100000 |

### Component-Specific Metrics
| Metric | Description | Measurement |
|--------|-------------|-------------|
| `pass_count` | Number of verification passes | integer |
| `issues_found` | Issues discovered per pass | integer |
| `issues_fixed` | Issues resolved per pass | integer |
| `early_termination` | Stopped before max passes | boolean |
| `suppressed` | Skipped due to quick/rough | boolean |
| `drift_detected` | Scope drift occurred | boolean |
| `drift_realigned` | Successfully realigned | boolean |

### Storage
| Metric Type | Storage Location | Retention |
|-------------|------------------|-----------|
| Per-execution | `.claude/metrics/AC-02-wiggum.jsonl` | 30 days |
| Aggregated | `.claude/metrics/aggregates/daily/` | 1 year |

### Emission Format
```jsonl
{"timestamp": "2026-01-16T14:30:00.000Z", "component": "AC-02", "metric": "pass_count", "value": 2, "unit": "count"}
{"timestamp": "2026-01-16T14:30:00.000Z", "component": "AC-02", "metric": "issues_found", "value": 3, "unit": "count"}
```

---

## 9. Failure Modes

### Known Failure Scenarios
| Failure | Cause | Detection | Recovery |
|---------|-------|-----------|----------|
| Infinite loop | Never reaches completion | Max iteration check | Force complete, log warning |
| Context exhaustion | Large task | JICM threshold | Checkpoint, /clear, resume |
| Scope drift | Work diverges from task | Drift detector | Realign, continue |
| Blocker encountered | External dependency | Error detection | Investigate, attempt resolution |

### Graceful Degradation
| Degradation Level | Trigger | Behavior |
|-------------------|---------|----------|
| Partial | JICM unavailable | Continue without pause points |
| Partial | Drift detector fails | Log warning, continue |
| Minimal | Max iterations reached | Complete with warning |
| Abort | Critical error | Save state, notify user |

### Error Reporting
| Error Type | Notification | Log Location |
|------------|--------------|--------------|
| Recoverable | Silent (log only) | session-start-diagnostic.log |
| Non-recoverable | User message | session-start-diagnostic.log |

### Rollback Procedures
1. All code changes are git-tracked
2. `git diff` shows all modifications
3. `git checkout .` reverts all changes
4. Loop state can be deleted to force fresh start

---

## Implementation Notes

### Current Implementation
| Artifact | Path | Status |
|----------|------|--------|
| Setup script | `.claude/scripts/ralph-setup.sh` | **active** |
| Stop hook | `.claude/hooks/ralph-stop-hook.sh` | **active** |
| Tracker hook | `.claude/hooks/wiggum-loop-tracker.js` | **active** |
| Command | `.claude/commands/ralph-loop.md` | **active** |
| Cancel command | `.claude/commands/cancel-ralph.md` | **active** |
| State file | `.claude/ralph-loop.local.md` | runtime (gitignored) |
| AC-02 state | `.claude/state/components/AC-02-wiggum.json` | **active** |
| Event log | `.claude/logs/wiggum-loop.log` | **active** |
| Pattern document | `.claude/context/patterns/wiggum-loop-pattern.md` | **active** |

### Architecture
```
┌────────────────────────────────────────────────────────────────────┐
│                    AC-02 RALPH LOOP SYSTEM                          │
├────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  /ralph-loop command                                                │
│       │                                                             │
│       ▼                                                             │
│  ┌─────────────────┐     ┌──────────────────┐     ┌─────────────┐  │
│  │  ralph-setup.sh │────▶│ ralph-loop.local │◀────│ stop-hook   │  │
│  │  (entry point)  │     │ .md (state file) │     │ (intercept) │  │
│  └─────────────────┘     └────────┬─────────┘     └──────┬──────┘  │
│                                   │                      │         │
│                                   ▼                      ▼         │
│                    ┌──────────────────────────┐                    │
│                    │ AC-02-wiggum.json (state)│                    │
│                    │ wiggum-loop.log (events) │                    │
│                    └──────────────────────────┘                    │
│                                                                     │
└────────────────────────────────────────────────────────────────────┘
```

### How It Works

1. **`/ralph-loop "prompt"` starts the loop**
   - Creates `ralph-loop.local.md` with harness prompt and config
   - Initializes `AC-02-wiggum.json` with active state
   - Logs `loop_start` event

2. **Stop hook intercepts exit attempts**
   - Reads state file frontmatter
   - Checks for `<promise>TEXT</promise>` in assistant output
   - If not complete: returns `{decision: "block", reason: prompt}`
   - If complete: removes state file, updates AC-02 state

3. **Loop continues until**
   - Completion promise detected in output
   - Max iterations reached
   - Manual cancellation via `/cancel-ralph`

### Loop Structure (6 Steps)

```
┌─────────────────────────────────────────────────────────┐
│                    WIGGUM LOOP ITERATION                 │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  1. EXECUTE — Perform work on current task/todo          │
│     └── Use TodoWrite to track sub-tasks                 │
│                                                          │
│  2. CHECK — Verify work meets requirements               │
│     └── Run tests, validate output, check constraints    │
│                                                          │
│  3. REVIEW — Self-review for quality/completeness        │
│     └── Would this pass code review? Any edge cases?     │
│                                                          │
│  4. DRIFT CHECK — Still aligned with original task?      │
│     └── Compare current work to original request         │
│                                                          │
│  5. CONTEXT CHECK — JICM status, near threshold?         │
│     └── If high → checkpoint → /clear → resume           │
│                                                          │
│  6. CONTINUE or COMPLETE                                 │
│     └── More work? → Loop back to step 1                 │
│     └── All done AND verified? → Exit loop               │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

### Stopping Conditions (Very Limited)

**Valid Stop Conditions**:
1. All todos complete AND reviewed AND verified sufficient
2. User sends explicit interrupt (Ctrl+C)
3. Safety gate triggered (destructive op, policy crossing)

**NOT Stop Conditions** (Continue Loop):
- "Blocker encountered" → Investigate first, then report
- "Context exhaustion" → Checkpoint, /clear, resume
- "Scope drift" → Realign with task aims, continue
- "Idle/timeout" → Switch to R&D/Maintenance/Reflection

### Open Questions
- [x] ~~Integration point with existing ralph-wiggum skill?~~ **Resolved**: Decomposed official plugin into native Jarvis components
- [x] ~~JICM pause point detection mechanism?~~ **Resolved**: JICM not integrated with Ralph Loop (each iteration is fresh context)

### Design Decisions Log
| Date | Decision | Rationale |
|------|----------|-----------|
| 2026-01-16 | Default ON | Autonomy-first design principle |
| 2026-01-16 | Explicit keywords to disable | Clear, unambiguous suppression |
| 2026-01-16 | 6-step iteration structure | Comprehensive verification |
| 2026-01-17 | Decompose official ralph-loop plugin | Customizable, observable implementation |
| 2026-01-17 | No JICM integration | Each Ralph iteration is fresh context anyway |
| 2026-01-17 | Harness prompt for validation | More flexible than TodoWrite tracking |
| 2026-01-17 | State file format compatible with official | Allows side-by-side testing |

---

## Validation Checklist

Before marking this component as "active":

- [x] All 9 specification sections completed
- [x] Triggers tested (`/ralph-loop` command, stop hook intercept)
- [x] Inputs/outputs validated (state files created and updated)
- [x] Dependencies verified (stop hook registered in settings.json)
- [x] Gates implemented (destructive ops handled by existing guardrail hooks)
- [x] Metrics emission working (AC-02-wiggum.json updated, wiggum-loop.log written)
- [x] Failure modes tested (max iterations termination, promise detection)
- [x] Integration with consumers verified (AC-03 Review pattern exists)
- [x] Documentation updated (component spec and pattern updated)

### Validation Test Results (2026-01-17)
| Test | Result |
|------|--------|
| Setup script creates state | ✅ PASS |
| Stop hook increments iteration | ✅ PASS |
| Completion promise detection | ✅ PASS |
| Max iterations termination | ✅ PASS |
| AC-02 state file updated | ✅ PASS |
| Log emission | ✅ PASS |

---

*AC-02 Wiggum Loop — Jarvis Phase 6 PR-12.2*
