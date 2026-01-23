# AC-09 Session Completion — Autonomic Component Specification

**Component ID**: AC-09
**Version**: 1.0.0
**Status**: active
**Created**: 2026-01-16
**Last Modified**: 2026-01-16
**PR**: PR-12.9

---

## 1. Identity

### Purpose
Ensure clean, complete handoff between sessions with full state preservation, memory persistence, and documentation of work accomplished. Session Completion is the only component that formally ends a session, and it is USER-PROMPTED ONLY—context exhaustion, work completion, and idle time do NOT end sessions.

### Scope
| Dimension | Applies |
|-----------|---------|
| Jarvis Codebase | Yes |
| Active Project | Yes |
| All Sessions | Yes |

**Scope Note**: Session Completion applies to ALL sessions and ALL project spaces. It is the formal exit point that ensures no work is lost and the next session can seamlessly continue.

### Tier Classification
- [x] **Tier 1**: Active Work (user-facing, direct task contribution)
- [ ] **Tier 2**: Self-Improvement (Jarvis-only, background operation)

### Design Principles

1. **User-Prompted Only**: Sessions end ONLY when user explicitly requests
2. **No Lost Work**: State is ALWAYS preserved before exit
3. **Pre-Completion Offer**: Before ending, offer to run Tier 2 cycles
4. **Clean Handoff**: Next session has everything needed to continue
5. **Consistent Format**: Session summaries follow standard template

---

## 2. Triggers

### Activation Conditions
| Trigger Type | Condition | Priority |
|--------------|-----------|----------|
| **Manual** | User runs `/end-session` | high |
| **Manual** | User explicitly requests "end session" | high |
| **Manual** | User says "goodbye", "done for now", etc. | medium |

### NOT Trigger Conditions
These explicitly DO NOT end sessions:

| Condition | Actual Behavior |
|-----------|-----------------|
| Context exhaustion | AC-04 JICM handles; work continues |
| Wiggum Loop completes | Check for more work; offer Tier 2 cycles |
| Idle timeout (~30 min) | Trigger R&D/Maintenance/Reflection |
| Error or blocker | Investigate via Wiggum Loop; report with assessment |
| Rate limiting | Checkpoint and wait; resume when available |

### Trigger Implementation
```
Session Completion trigger logic:
  - /end-session command → immediate completion protocol
  - Explicit "end session" request → completion protocol
  - Departure phrases → confirm, then completion protocol

The key principle: ONLY user intent ends sessions.
Everything else triggers continuation or productive use of time.
```

### Suppression Conditions
| Condition | Behavior |
|-----------|----------|
| `JARVIS_DISABLE_AC09=true` | Skip pre-completion offer (proceed directly) |
| Active destructive operation | Block until operation complete |
| Uncommitted critical changes | Warn and offer to commit first |

---

## 3. Inputs

### Required Inputs
| Input | Source | Format | Purpose |
|-------|--------|--------|---------|
| Session state | `.claude/context/session-state.md` | Markdown | Current work status |
| Todo list | TodoWrite state | Array | Pending tasks |
| Git status | `git status` | Text | Uncommitted changes |

### Optional Inputs
| Input | Source | Default | Purpose |
|-------|--------|---------|---------|
| Current priorities | `current-priorities.md` | None | PR status |
| Conversation history | Context window | None | Summary generation |
| Memory MCP | Pending writes | None | Persistence |
| Checkpoint state | `.claude/context/.checkpoint.md` | None | Continue signal |
| Autonomy config | `autonomy-config.yaml` | Defaults | Settings |

### Context Requirements

- [x] Session state file accessible
- [x] Git repository available
- [ ] Memory MCP connected (optional, for persistence)
- [ ] Watcher process running (optional, for shutdown)

---

## 4. Outputs

### Primary Outputs
| Output | Destination | Format | Consumers |
|--------|-------------|--------|-----------|
| Session summary | `.claude/reports/sessions/session-YYYY-MM-DD.md` | Markdown | User, next session |
| Updated session-state | `.claude/context/session-state.md` | Markdown | Next session |
| Updated priorities | `current-priorities.md` | Markdown | Next session |
| Git commit | Repository | Commit | Version control |
| Memory entities | Memory MCP | Entities | Cross-session recall |
| Checkpoint file | `.claude/context/.checkpoint.md` | Markdown | Session start |

### Side Effects
| Effect | Description | Reversible |
|--------|-------------|------------|
| Git commit | Session work committed | Yes (revert) |
| Git push | Changes pushed to remote | Limited |
| Watcher shutdown | Auto-clear watcher stopped | Yes (restart) |
| Temp cleanup | Transient files removed | No |
| Log rotation | Session logs archived | Yes (unarchive) |

### State Changes
| State | Location | Change Type |
|-------|----------|-------------|
| Session state | `.claude/context/session-state.md` | update |
| Current priorities | `current-priorities.md` | update |
| Checkpoint | `.claude/context/.checkpoint.md` | create |
| Session summary | `.claude/reports/sessions/` | create |
| Memory MCP | Session entity | create |

---

## 5. Dependencies

### System Dependencies
| Dependency | Type | Failure Behavior |
|------------|------|------------------|
| Git | soft | Skip commit/push, warn user |
| File system | hard | Cannot complete session |
| AC-05 Self-Reflection | soft | Skip pre-completion offer |
| AC-06 Self-Evolution | soft | Skip pre-completion offer |
| AC-07 R&D Cycles | soft | Skip pre-completion offer |
| AC-08 Maintenance | soft | Skip pre-completion offer |

### MCP Dependencies
| MCP Server | Tools Used | Required |
|------------|------------|----------|
| Memory | create_entities, add_observations | No (skip persistence) |
| Git | git_status, git_commit, git_push | No (use native) |

### File Dependencies
| File | Purpose | Create if Missing |
|------|---------|-------------------|
| `.claude/context/session-state.md` | Work status | Yes (minimal) |
| `.claude/context/current-priorities.md` | PR tracking | No (warn) |
| `.claude/reports/sessions/` | Summary storage | Yes (directory) |
| `.claude/context/.checkpoint.md` | Continuation | Yes |

---

## 6. Consumers

### Downstream Systems
| Consumer | Relationship | Data Consumed |
|----------|--------------|---------------|
| AC-01 Self-Launch | reads | Checkpoint, session state |
| Next session | reads | All outputs |
| User | reads | Session summary |
| Memory MCP | stores | Session entities |

### User Visibility
| Aspect | Visible to User |
|--------|-----------------|
| Pre-completion offer | Yes (interactive) |
| Completion progress | Yes (step-by-step) |
| Session summary | Yes (displayed) |
| Git operations | Yes (commit message shown) |
| Warnings | Yes (if issues found) |

### Integration Points

```
┌─────────────────────────────────────────────────────────────────────┐
│                    SESSION COMPLETION INTEGRATION                    │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  TRIGGER                                                             │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │  User: /end-session                                          │    │
│  │       OR "end session"                                       │    │
│  │       OR departure phrase                                    │    │
│  └──────────────────────────┬──────────────────────────────────┘    │
│                              │                                       │
│                              ▼                                       │
│  PRE-COMPLETION OFFER                                                │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │  "Before ending, can I do anything useful?"                  │    │
│  │                                                              │    │
│  │  [ ] AC-05 Self-Reflection                                   │    │
│  │  [ ] AC-06 Self-Evolution                                    │    │
│  │  [ ] AC-07 R&D Cycles                                        │    │
│  │  [ ] AC-08 Maintenance                                       │    │
│  │  [ ] Skip and end session                                    │    │
│  └──────────────────────────┬──────────────────────────────────┘    │
│                              │                                       │
│              ┌───────────────┴───────────────┐                      │
│              │                               │                      │
│              ▼                               ▼                      │
│  ┌─────────────────┐             ┌─────────────────┐               │
│  │  Run Selected   │             │  Proceed to     │               │
│  │  Tier 2 Cycles  │             │  Completion     │               │
│  └────────┬────────┘             └────────┬────────┘               │
│           │                               │                         │
│           └───────────────┬───────────────┘                         │
│                           │                                          │
│                           ▼                                          │
│  COMPLETION PROTOCOL (7 Steps)                                       │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │  1. Work State Capture                                       │    │
│  │  2. Memory Persistence                                       │    │
│  │  3. Context File Updates                                     │    │
│  │  4. Chat History Preservation                                │    │
│  │  5. Git Operations                                           │    │
│  │  6. Handoff Preparation                                      │    │
│  │  7. Cleanup                                                  │    │
│  └──────────────────────────┬──────────────────────────────────┘    │
│                              │                                       │
│                              ▼                                       │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │  SESSION SUMMARY                                             │    │
│  │  • What was accomplished                                     │    │
│  │  • What was blocked                                          │    │
│  │  • What decisions were made                                  │    │
│  │  • What's next                                               │    │
│  │  • Context/token statistics                                  │    │
│  └─────────────────────────────────────────────────────────────┘    │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 7. Gates

### Approval Checkpoints
| Gate ID | Trigger | Risk Level | Auto-Approve |
|---------|---------|------------|--------------|
| G-01 | Start completion | Low | Yes |
| G-02 | Pre-completion offer | Low | Yes (show options) |
| G-03 | Run Tier 2 cycles | Low | Yes (if selected) |
| G-04 | Update files | Low | Yes |
| G-05 | Git commit | Low | Yes |
| G-06 | Git push | Medium | Configurable |
| G-07 | Watcher shutdown | Low | Yes |
| G-08 | Cleanup temps | Low | Yes |

### Risk Classification
| Action Type | Risk Level | Gate Requirement |
|-------------|------------|------------------|
| State capture | Low | None |
| File updates | Low | None |
| Git commit | Low | None |
| Git push | Medium | Configurable (default: auto) |
| Memory writes | Low | None |
| Cleanup | Low | None |

### Gate Implementation
```
Session Completion is mostly low-risk (preserving work).
The only configurable gate is git push:

autonomy-config.yaml:
  session_completion:
    auto_push: true  # or false to require confirmation

All other operations proceed automatically to ensure
clean session handoff.
```

---

## 8. Metrics

### Performance Metrics
| Metric | Unit | Target | Alert Threshold |
|--------|------|--------|-----------------|
| Completion time | seconds | < 60 | > 120 |
| Files updated | count | varies | N/A |
| Commit success | boolean | true | false |

### Component-Specific Metrics
| Metric | Description | Measurement |
|--------|-------------|-------------|
| `sessions_completed` | Total sessions ended | integer |
| `pre_completion_offers` | Tier 2 cycles offered | integer |
| `tier2_cycles_run` | Cycles run before exit | integer |
| `commits_created` | Git commits made | integer |
| `pushes_completed` | Git pushes made | integer |
| `memory_entities_created` | Memory MCP writes | integer |
| `summaries_generated` | Session reports | integer |
| `handoff_quality_score` | Completeness (0-100) | integer |

### Storage
| Metric Type | Storage Location | Retention |
|-------------|------------------|-----------|
| Per-session | `.claude/metrics/AC-09-sessions.jsonl` | 90 days |
| Aggregated | `.claude/metrics/aggregates/daily/` | 1 year |

### Emission Format
```jsonl
{"timestamp": "2026-01-16T22:00:00.000Z", "component": "AC-09", "metric": "sessions_completed", "value": 1, "unit": "count"}
{"timestamp": "2026-01-16T22:00:00.000Z", "component": "AC-09", "metric": "handoff_quality_score", "value": 95, "unit": "percent"}
```

---

## 9. Failure Modes

### Known Failure Scenarios
| Failure | Cause | Detection | Recovery |
|---------|-------|-----------|----------|
| Git unavailable | Not a repo | Git error | Skip commit, preserve state locally |
| Memory MCP down | Server issue | Connection error | Skip persistence, note in summary |
| File write fails | Permissions | OS error | Warn user, log location |
| Push fails | Network/auth | Git error | Commit locally, note for next session |
| Watcher not running | Never started | Process check | Skip shutdown |

### Graceful Degradation
| Degradation Level | Trigger | Behavior |
|-------------------|---------|----------|
| Full | All systems operational | Complete protocol with all features |
| Partial | Git unavailable | Skip commit/push, preserve state in files |
| Partial | Memory MCP down | Skip persistence, log locally |
| Partial | Network issues | Commit locally, defer push |
| Minimal | File system issues | Display summary, user saves manually |

### Error Reporting
| Error Type | Notification | Log Location |
|------------|--------------|--------------|
| Git failure | Warning + local save | session-completion.log |
| MCP failure | Info (non-critical) | session-completion.log |
| File write error | Error + fallback | session-completion.log |
| Push failure | Warning + instructions | session-completion.log |

### Rollback Procedures
1. Git commit: `git reset HEAD~1` (before push)
2. File updates: Restore from git
3. Memory entities: Delete via Memory MCP
4. Cleanup: Cannot rollback (low impact)

---

## Implementation Notes

### Current Implementation
| Artifact | Path | Status |
|----------|------|--------|
| Component spec | `.claude/context/components/AC-09-session-completion.md` | exists |
| Pattern document | `.claude/context/patterns/session-completion-pattern.md` | exists |
| End-session command | `.claude/commands/end-session.md` | exists |
| State file | `.claude/state/components/AC-09-session.json` | exists |
| Session summary template | `.claude/context/templates/session-summary.md` | optional |

### Seven-Step Completion Protocol

```
┌─────────────────────────────────────────────────────────────────────┐
│                    COMPLETION PROTOCOL (7 STEPS)                     │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  STEP 1: WORK STATE CAPTURE                                         │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │  • Update session-state.md with current status                │  │
│  │  • Capture pending TodoWrite tasks                            │  │
│  │  • Document blockers and their investigation status           │  │
│  │  • Record key decisions made during session                   │  │
│  │  • Note files modified and their purpose                      │  │
│  └───────────────────────────────────────────────────────────────┘  │
│                                                                      │
│  STEP 2: MEMORY PERSISTENCE                                         │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │  • Flush pending Memory MCP writes                            │  │
│  │  • Create session summary entity                              │  │
│  │  • Link to related entities (projects, PRs)                   │  │
│  │  • Update corrections.md / self-corrections.md if needed      │  │
│  └───────────────────────────────────────────────────────────────┘  │
│                                                                      │
│  STEP 3: CONTEXT FILE UPDATES                                       │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │  • Update current-priorities.md with PR progress              │  │
│  │  • Update any modified pattern files                          │  │
│  │  • Refresh configuration files if changed                     │  │
│  │  • Update roadmap.md if milestones changed                    │  │
│  └───────────────────────────────────────────────────────────────┘  │
│                                                                      │
│  STEP 4: CHAT HISTORY PRESERVATION                                  │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │  • Store conversation context for next session                │  │
│  │  • Location: easily discoverable at session start             │  │
│  │  • Format: rich enough for full context recovery              │  │
│  │  • Reference: session summary with key pointers               │  │
│  └───────────────────────────────────────────────────────────────┘  │
│                                                                      │
│  STEP 5: GIT OPERATIONS                                             │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │  • Stage relevant changes (git add)                           │  │
│  │  • Create session commit with descriptive message             │  │
│  │  • Push to origin (if auto_push enabled)                      │  │
│  │  • Handle multi-repo if applicable                            │  │
│  └───────────────────────────────────────────────────────────────┘  │
│                                                                      │
│  STEP 6: HANDOFF PREPARATION                                        │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │  • Create checkpoint file (.checkpoint.md)                    │  │
│  │  • Document "Next Session" instructions                       │  │
│  │  • Configure MCPs for next session (Tier suggestions)         │  │
│  │  • Set session-state.md "Next Step" field                     │  │
│  └───────────────────────────────────────────────────────────────┘  │
│                                                                      │
│  STEP 7: CLEANUP                                                    │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │  • Clear transient files (.claude/context/.*)                 │  │
│  │  • Stop auto-clear watcher if running                         │  │
│  │  • Log session statistics (duration, tokens, commits)         │  │
│  │  • Archive session logs if configured                         │  │
│  └───────────────────────────────────────────────────────────────┘  │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### Pre-Completion Offer

```
Before ending the session, Jarvis offers:

"Before we wrap up, would you like me to run any of these
while you're away?"

[ ] Self-Reflection — Review session learnings
[ ] Self-Evolution — Implement queued improvements
[ ] R&D Cycles — Research new tools/patterns
[ ] Maintenance — Cleanup and health checks
[ ] None — Proceed to end session

If user selects cycles:
1. Run selected Tier 2 components
2. Wait for completion (may take time)
3. Then proceed to completion protocol

If user declines:
1. Proceed directly to completion protocol
```

### Open Questions
- [ ] Chat history storage format and location?
- [ ] Multi-repo push coordination?
- [ ] Session summary retention policy?

### Design Decisions Log
| Date | Decision | Rationale |
|------|----------|-----------|
| 2026-01-16 | User-prompted only | Preserve user control over session lifecycle |
| 2026-01-16 | Pre-completion offer | Maximize productive use of session end |
| 2026-01-16 | Seven-step protocol | Comprehensive handoff ensures continuity |
| 2026-01-16 | Graceful degradation | Session completion must succeed even with failures |

---

## Validation Checklist

Before marking this component as "active":

- [x] All 9 specification sections completed
- [ ] Triggers tested (manual command, phrase detection)
- [ ] Inputs/outputs validated
- [x] Dependencies verified (git, file system)
- [ ] Gates implemented (configurable push)
- [x] Metrics emission working (telemetry-emitter.js integrated)
- [ ] Failure modes tested (no git, no MCP)
- [ ] Integration with consumers verified (AC-01 reads checkpoint)
- [x] Documentation updated

---

*AC-09 Session Completion — Jarvis Phase 6 PR-12.9*
