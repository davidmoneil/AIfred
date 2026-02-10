# Autonomic Component Orchestration Overview

How the Autonomic Components interact during Jarvis sessions.

**Version**: 1.1.0
**Layer**: Nous (component topology)

## Architecture: Hippocrenae + Ulfhedthnar

The autonomic system comprises two categories:
- **Hippocrenae** (AC-01 through AC-09): The Nine Muses — standard operational harmony
- **Ulfhedthnar** (AC-10): The Wolf-Warrior — hidden Neuros override system (dormant until barriers detected)

---

## Component Topology

```
                         ┌─────────────────────────────────────────────────────────┐
                         │                    SESSION LIFECYCLE                     │
                         └─────────────────────────────────────────────────────────┘
                                                    │
                                                    ▼
                                          ┌─────────────────┐
                                          │    AC-01        │
                                          │  Self-Launch    │
                                          │ (Session Start) │
                                          └────────┬────────┘
                                                   │
                              ┌────────────────────┼────────────────────┐
                              │                    │                    │
                              ▼                    ▼                    ▼
                    ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
                    │    AC-02        │  │    AC-06        │  │    AC-07        │
                    │  Wiggum Loop    │  │ Self-Evolution  │  │  R&D Cycles     │
                    │   (DEFAULT)     │  │  (Idle Time)    │  │  (Research)     │
                    └────────┬────────┘  └────────┬────────┘  └────────┬────────┘
                             │                    │                    │
           ┌─────────────────┼─────────────────┐  │                    │
           │                 │                 │  │                    │
           ▼                 ▼                 ▼  ▼                    ▼
  ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐
  │    AC-03        │ │    AC-04        │ │    AC-05        │ │    AC-08        │
  │Milestone Review │ │     JICM        │ │ Self-Reflection │ │  Maintenance    │
  │ (Work Complete) │ │(Context Full)   │ │  (Learnings)    │ │ (Health Checks) │
  └─────────────────┘ └─────────────────┘ └─────────────────┘ └─────────────────┘
                             │                    │
                             │                    │
                             └──────────┬─────────┘
                                        │
                                        ▼
                              ┌─────────────────┐
                              │    AC-09        │
                              │    Session      │
                              │   Completion    │
                              └─────────────────┘
```

---

## Component Flow Descriptions

### Session Start → AC-01 Self-Launch

**Trigger**: New session begins
**Actions**:
1. Load identity from `psyche/jarvis-identity.md`
2. Review `session-state.md` and `current-priorities.md`
3. Generate contextual greeting
4. Suggest or begin work autonomously

**Outputs to**: AC-02 (default work mode)

---

### Active Work → AC-02 Wiggum Loop (DEFAULT)

**Trigger**: Any non-trivial task
**Structure**:
```
Execute → Check → Review → Drift Check → Context Check → Continue/Complete
```

**Concurrent triggers**:
- **AC-03**: When milestone/significant work completes
- **AC-04**: When context approaches limit
- **AC-05**: When learnings should be captured

**Key behaviors**:
- Use TodoWrite for 2+ step tasks
- Self-review before marking complete
- Iterate until verified

---

### Milestone → AC-03 Milestone Review

**Trigger**: PR completion, significant feature, major refactor
**Actions**:
1. Load review criteria from `review-criteria/`
2. Evaluate deliverables against criteria
3. Generate review report
4. Block completion if criteria not met

**Outputs to**: Reports in `.claude/reports/reviews/`

---

### Context Full → AC-04 JICM

**Trigger**: Context approaching 70-80% capacity
**Actions**:
1. Identify critical context to preserve
2. Run context-compressor agent
3. Save checkpoint to `session-state.md`
4. Signal ready for `/clear`
5. Restore compressed context post-clear

**Outputs to**: Session continuation with reduced context

---

### Session Learning → AC-05 Self-Reflection

**Trigger**: Session end, significant events, periodic
**Actions**:
1. Analyze session corrections and events
2. Identify patterns and lessons
3. Generate reflection report
4. Propose improvements

**Outputs to**: Reports in `.claude/reports/reflections/`

---

### Idle Time → AC-06 Self-Evolution

**Trigger**: Low-priority idle time, explicit request
**Actions**:
1. Review evolution queue
2. Evaluate proposals against safety criteria
3. Implement approved changes
4. Document evolution

**Outputs to**: Code changes, reports in `.claude/reports/evolutions/`

---

### Research → AC-07 R&D Cycles

**Trigger**: Scheduled, explicit request, capability gaps
**Actions**:
1. Review research agenda
2. Explore external tools and approaches
3. Evaluate SOTA alternatives
4. Generate discovery reports

**Outputs to**: Reports in `.claude/reports/research/`

---

### Health Check → AC-08 Maintenance

**Trigger**: Scheduled, explicit request, detected issues
**Actions**:
1. Run health checks (MCPs, hooks, configs)
2. Audit file organization
3. Clean stale data
4. Generate maintenance report

**Outputs to**: Reports in `.claude/reports/maintenance/`

---

### Session End → AC-09 Session Completion

**Trigger**: User requests session end (`/end-session`)
**Actions**:
1. Update `session-state.md` with summary
2. Commit any uncommitted work
3. Update `current-priorities.md`
4. Trigger AC-05 for final reflection

**Outputs to**: Clean session exit with documentation

---

## Component Dependencies

| Component | Depends On | Triggers |
|-----------|------------|----------|
| AC-01 | None | AC-02 |
| AC-02 | AC-01 | AC-03, AC-04, AC-05 |
| AC-03 | AC-02 | Reports |
| AC-04 | AC-02 | Session continuation |
| AC-05 | AC-02, AC-09 | Lessons, proposals |
| AC-06 | AC-05 | Code changes |
| AC-07 | AC-01 | Discovery reports |
| AC-08 | AC-01 | Health reports |
| AC-09 | User request | AC-05 |
| AC-10 | Defeat signals / /unleash | Frenzy Mode, Berserker Loop |

---

## Quick Reference

**Hippocrenae (Nine Muses)**:
- **Always active**: AC-02 (Wiggum Loop is DEFAULT behavior)
- **Session bookends**: AC-01 (start) → AC-09 (end)
- **Triggered by work**: AC-03, AC-04, AC-05
- **Background/scheduled**: AC-06, AC-07, AC-08

**Ulfhedthnar (Wolf-Warrior)**:
- **AC-10**: Dormant → Activated by defeat signals → Berserker problem-solving → Dormant
- **Trigger**: "I can't" patterns, subagent cascading failure, Wiggum Loop stalls, or `/unleash`
- **Override**: Max parallel agents, approach rotation, no-quit Wiggum Berserker Loop
- **Safety**: Cannot bypass destructive confirmations, respects JICM, auto-disengages

---

*Jarvis — Nous Layer (Component Topology) — Hippocrenae + Ulfhedthnar*
