# AC-01 Self-Launch Protocol — Autonomic Component Specification

**Component ID**: AC-01
**Version**: 1.0.0
**Status**: active
**Created**: 2026-01-16
**Last Modified**: 2026-01-16
**PR**: PR-12.1

---

## 1. Identity

### Purpose
Automatically initialize Jarvis at Claude Code startup with environmental awareness, congenial greeting, and full context loading, then proceed autonomously through session startup WITHOUT additional user prompting.

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

1. **Autonomy is Default**: Proceed through startup without waiting for prompts
2. **Never Just Wait**: Always have a next action; if blocked, investigate first
3. **Congenial Presence**: Greet appropriately for time/conditions
4. **Transparency**: Log all startup actions to diagnostic file

---

## 2. Triggers

### Activation Conditions
| Trigger Type | Condition | Priority |
|--------------|-----------|----------|
| **Automatic** | Claude Code session start | high |
| **Automatic** | Session resume | high |
| **Event-Based** | `/clear` command | medium |
| **Event-Based** | Compact operation | low |

### Trigger Implementation
```
Hook: session-start.sh
Event source: Claude Code lifecycle events
Detection logic:
  - startup: New Claude Code session
  - resume: Return to existing session
  - clear: /clear command executed
  - compact: Context compaction triggered
```

### Suppression Conditions
| Condition | Behavior |
|-----------|----------|
| `JARVIS_DISABLE_AC01=true` | Skip entire protocol |
| `JARVIS_QUICK_MODE=true` | Skip greeting, minimal output |
| `JARVIS_MANUAL_MODE=true` | Skip autonomous initiation |

---

## 3. Inputs

### Required Inputs
| Input | Source | Format | Purpose |
|-------|--------|--------|---------|
| `source` | Hook input JSON | string | Trigger type (startup/resume/clear/compact) |
| `session_id` | Hook input JSON | string | Session identifier for logging |

### Optional Inputs
| Input | Source | Default | Purpose |
|-------|--------|---------|---------|
| Current time | DateTime MCP | System time | Time-of-day greeting |
| Weather data | WebSearch | None | Environmental context |
| Checkpoint file | `.claude/context/.soft-restart-checkpoint.md` | None | Resume context |
| Session state | `.claude/context/session-state.md` | Empty | Previous work status |

### Context Requirements

- [x] CLAUDE.md (essential links)
- [x] session-state.md (current work status)
- [x] current-priorities.md (task backlog)
- [ ] Project-specific context (loaded in Phase B)

---

## 4. Outputs

### Primary Outputs
| Output | Destination | Format | Consumers |
|--------|-------------|--------|-----------|
| Greeting message | stdout (systemMessage) | Text | User |
| Context summary | stdout (additionalContext) | Text | Claude |
| Startup diagnostics | `.claude/logs/session-start-diagnostic.log` | Text | Debug |
| Environment data | `.claude/state/components/AC-01-launch.json` | JSON | AC-02, AC-04 |

### Side Effects
| Effect | Description | Reversible |
|--------|-------------|------------|
| Watcher launch | Start auto-clear watcher process | Yes (kill) |
| MCP suggestions | Display enable/disable recommendations | N/A |
| Context injection | Add additionalContext for auto-resume | N/A |

### State Changes
| State | Location | Change Type |
|-------|----------|-------------|
| Component state | `.claude/state/components/AC-01-launch.json` | create/update |
| Startup log | `.claude/logs/session-start-diagnostic.log` | append |

---

## 5. Dependencies

### System Dependencies
| Dependency | Type | Failure Behavior |
|------------|------|------------------|
| None | — | Self-Launch is the entry point |

### MCP Dependencies
| MCP Server | Tools Used | Required |
|------------|------------|----------|
| DateTime | `get_current_datetime` | No (fallback to system time) |
| Memory | `search_nodes` | No (skip context recall) |

### File Dependencies
| File | Purpose | Create if Missing |
|------|---------|-------------------|
| `.claude/context/session-state.md` | Previous work status | No (use defaults) |
| `.claude/context/.soft-restart-checkpoint.md` | Resume context | No (skip resume) |
| `.claude/logs/` | Diagnostic output | Yes |
| `.claude/state/components/` | State storage | Yes |

---

## 6. Consumers

### Downstream Systems
| Consumer | Relationship | Data Consumed |
|----------|--------------|---------------|
| AC-02 Wiggum Loop | triggers | Pending work status |
| AC-03 Milestone Review | triggers | Completed milestone flag |
| AC-04 JICM | reads | Initial context estimate |

### User Visibility
| Aspect | Visible to User |
|--------|-----------------|
| Execution start | Yes (greeting) |
| Progress updates | No (background) |
| Completion notice | Yes (briefing) |
| Error reports | Yes (if blocking) |

### Integration Points

```
Session Start
     │
     ▼
┌─────────────────┐
│   AC-01         │
│   Self-Launch   │
└────────┬────────┘
         │
    ┌────┴────┬─────────┐
    │         │         │
    ▼         ▼         ▼
┌───────┐ ┌───────┐ ┌───────┐
│ AC-02 │ │ AC-03 │ │ AC-04 │
│Wiggum │ │Review │ │ JICM  │
└───────┘ └───────┘ └───────┘
```

---

## 7. Gates

### Approval Checkpoints
| Gate ID | Trigger | Risk Level | Auto-Approve |
|---------|---------|------------|--------------|
| G-01 | External API call (weather) | Low | Yes |

### Risk Classification
| Action Type | Risk Level | Gate Requirement |
|-------------|------------|------------------|
| Read context files | Low | None |
| DateTime MCP call | Low | None |
| Weather API call | Low | Auto-approve |
| Launch watcher process | Low | None |
| Display greeting | Low | None |

### Gate Implementation
```
No blocking gates required.
All Self-Launch operations are read-only or informational.
Weather check failure degrades gracefully (skip weather mention).
```

---

## 8. Metrics

### Performance Metrics
| Metric | Unit | Target | Alert Threshold |
|--------|------|--------|-----------------|
| Execution time | ms | < 2000 | > 5000 |
| Token cost | tokens | < 500 | > 2000 |
| Success rate | % | 100% | < 95% |

### Component-Specific Metrics
| Metric | Description | Measurement |
|--------|-------------|-------------|
| `greeting_generated` | Whether greeting was displayed | boolean |
| `weather_fetched` | Whether weather was retrieved | boolean |
| `checkpoint_loaded` | Whether resume checkpoint used | boolean |
| `auto_continue_triggered` | Whether autonomous work began | boolean |
| `context_files_loaded` | Number of context files read | integer |
| `baseline_check_duration` | Time for AIfred sync check | float |

### Storage
| Metric Type | Storage Location | Retention |
|-------------|------------------|-----------|
| Per-execution | `.claude/metrics/AC-01-launch.jsonl` | 30 days |
| Aggregated | `.claude/metrics/aggregates/daily/` | 1 year |

### Emission Format
```jsonl
{"timestamp": "2026-01-16T14:30:00.000Z", "component": "AC-01", "metric": "execution_time", "value": 1250, "unit": "ms"}
{"timestamp": "2026-01-16T14:30:00.000Z", "component": "AC-01", "metric": "greeting_generated", "value": true, "unit": "boolean"}
```

---

## 9. Failure Modes

### Known Failure Scenarios
| Failure | Cause | Detection | Recovery |
|---------|-------|-----------|----------|
| DateTime MCP unavailable | MCP not loaded | Tool call error | Use system time |
| Weather fetch timeout | Network issue | Timeout | Skip weather mention |
| Checkpoint file corrupt | Bad JSON/encoding | Parse error | Skip resume, log warning |
| Context file missing | First run or deleted | File not found | Use defaults |

### Graceful Degradation
| Degradation Level | Trigger | Behavior |
|-------------------|---------|----------|
| Partial | DateTime MCP fails | Use system time, continue |
| Partial | Weather fetch fails | Skip weather, continue greeting |
| Partial | Checkpoint corrupt | Skip auto-resume, notify user |
| Minimal | Context files missing | Basic greeting only |

### Error Reporting
| Error Type | Notification | Log Location |
|------------|--------------|--------------|
| Recoverable | Silent (log only) | session-start-diagnostic.log |
| Non-recoverable | User message | session-start-diagnostic.log |

### Rollback Procedures
1. Self-Launch has no persistent side effects requiring rollback
2. If watcher fails to launch, log error and continue
3. User can always interrupt and restart session

---

## Implementation Notes

### Current Implementation
| Artifact | Path | Status |
|----------|------|--------|
| Main hook | `.claude/hooks/session-start.sh` | ✅ active |
| Pattern document | `.claude/context/patterns/startup-protocol.md` | ✅ complete |
| State file | `.claude/state/components/AC-01-launch.json` | ✅ created by hook |
| Checklist | `.claude/context/patterns/session-start-checklist.md` | ✅ complete |
| Persona | `.claude/context/psyche/jarvis-identity.md` | ✅ referenced |
| Skill | `.claude/skills/session-management/SKILL.md` | ✅ integrated |

### Phase A: Greeting & Orientation
1. Check DateTime MCP for current time
2. Determine time-of-day greeting (morning/afternoon/evening)
3. Optionally fetch weather via WebSearch
4. Display congenial greeting to user
5. Transition message: "One moment while I review..."

### Phase B: System Review (Background)
1. Read CLAUDE.md essential links
2. Load session-state.md
3. Load current-priorities.md
4. Check for checkpoint file
5. Check AIfred baseline for updates
6. Validate environment (git status, hooks)

### Phase C: User Briefing
1. Present baseline status if updates
2. Summarize recent work and options
3. Note any concerns
4. Autonomous initiation based on state:
   - PR pending → suggest Wiggum Loop
   - Milestone complete → suggest Review
   - Idle → offer R&D/Maintenance

### Open Questions
- [ ] Weather API preference (WebSearch vs dedicated MCP?)
- [ ] Location awareness (defer to future PR?)

### Design Decisions Log
| Date | Decision | Rationale |
|------|----------|-----------|
| 2026-01-16 | Use DateTime MCP for time | More reliable than shell parsing |
| 2026-01-16 | Weather is optional | Graceful degradation if unavailable |
| 2026-01-16 | Keep shell hook, add JS helper | Shell for speed, JS for logic |

---

## Validation Checklist

Before marking this component as "active":

- [x] All 9 specification sections completed
- [x] Triggers tested (startup, resume, clear, compact)
- [x] Inputs/outputs validated
- [x] Dependencies verified available (DateTime MCP optional, shell fallback works)
- [x] Gates implemented (none required)
- [x] Metrics emission working (telemetry-emitter.js integrated)
- [x] Failure modes tested (MCP unavailable, network timeout - graceful degradation confirmed)
- [x] Integration with consumers verified (AC-02 state file, AC-04 context estimate)
- [x] Documentation updated (startup-protocol.md complete)

---

*AC-01 Self-Launch Protocol — Jarvis Phase 6 PR-12.1*
