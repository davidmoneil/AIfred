# AC-04 JICM — Autonomic Component Specification

**Component ID**: AC-04
**Version**: 2.0.0
**Status**: active
**Created**: 2026-01-16
**Last Modified**: 2026-01-21
**PR**: PR-12.4, JICM v2 Refactoring

---

## 1. Identity

### Purpose
Jarvis Intelligent Context Management (JICM) monitors and manages the context window to prevent auto-compression, preserve essential information, and ensure seamless continuation of work across compression boundaries. JICM triggers **continuation**, not session completion.

### Scope
| Dimension | Applies |
|-----------|---------|
| Jarvis Codebase | Yes |
| Active Project | Yes |
| All Sessions | Yes |

**Special Scope Note**: JICM applies to ALL agents — Orchestrator (main Jarvis), subagents, and custom agents.

### Tier Classification
- [x] **Tier 1**: Active Work (user-facing, direct task contribution)
- [ ] **Tier 2**: Self-Improvement (Jarvis-only, background operation)

### Design Principles

1. **Continuation, Not Exit**: Context exhaustion triggers work CONTINUATION, not session end
2. **Liftover**: Seamless context transfer across compression boundary
3. **Preserve Essentials**: Keep what matters; cut what doesn't
4. **Universal Application**: All agents (Orchestrator + subagents + custom) use JICM
5. **Efficiency Focus**: Minimize overhead; don't over-engineer

---

## 2. Triggers

### Activation Conditions
| Trigger Type | Condition | Priority |
|--------------|-----------|----------|
| **Threshold-Based** | Context usage > 50% | low (CAUTION) |
| **Threshold-Based** | Context usage > 70% | medium (WARNING) |
| **Threshold-Based** | Context usage > 85% | high (CRITICAL) |
| **Threshold-Based** | Context usage > 95% | critical (EMERGENCY) |
| **Manual** | User requests `/context-budget` | medium |
| **Event-Based** | Wiggum Loop step 5 (Context Check) | medium |
| **Scheduled** | Every N tool calls (~10-20) | low |

### Trigger Implementation (JICM v2)
```
Monitoring strategy:
  - jarvis-watcher.sh polls tmux status line every 30s
  - Writes token count to context-estimate.json
  - Idle detection before triggering (wait_for_idle)
  - Single threshold at 80% triggers intelligent compression

Threshold actions (v2 simplified):
  80%  TRIGGER   → Wait for idle → /intelligent-compress → /clear → resume
  99%  OVERRIDE  → Native auto-compact (delayed via CLAUDE_AUTOCOMPACT_PCT_OVERRIDE)

Note: context-accumulator.js REMOVED in v2. Watcher handles all monitoring.
```

### Suppression Conditions
| Condition | Behavior |
|-----------|----------|
| `JARVIS_DISABLE_AC04=true` | Skip JICM monitoring (dangerous) |
| `JARVIS_JICM_THRESHOLD=N` | Override default thresholds |
| Quick/single-operation tasks | Reduced monitoring frequency |

---

## 3. Inputs

### Required Inputs
| Input | Source | Format | Purpose |
|-------|--------|--------|---------|
| Context usage estimate | context-estimate.json | JSON | Current consumption |
| Session state | session-state.md | Markdown | Work context |
| Todo list | TodoWrite state | Array | Task tracking |
| Active work description | Wiggum Loop state | JSON | What to preserve |

### Optional Inputs
| Input | Source | Default | Purpose |
|-------|--------|---------|---------|
| MCP status | list-mcp-status.sh | All enabled | Disable candidates |
| File read log | context-accumulator.js | None | Content consumption |
| User preferences | autonomy-config.yaml | Defaults | Threshold overrides |

### Context Requirements

- [x] context-estimate.json (real-time usage tracking)
- [x] session-state.md (work context)
- [x] Wiggum Loop state (if active)
- [ ] MCP disable scripts (for offloading)

---

## 4. Outputs

### Primary Outputs
| Output | Destination | Format | Consumers |
|--------|-------------|--------|-----------|
| Checkpoint file | `.claude/context/.checkpoint.md` | Markdown | Self-Launch (AC-01) |
| Context status | Console/log | Text | User, Jarvis |
| MCP disable commands | Shell scripts | Bash | Session restart |
| Archive reference | `.claude/archives/` | JSON | Future sessions |

### Side Effects
| Effect | Description | Reversible |
|--------|-------------|------------|
| MCP disabling | Reduces loaded tools | Yes (enable scripts) |
| Checkpoint creation | Preserves state | Yes (delete) |
| Context compression | Reduces conversation | No (archived) |
| Clear trigger | Sends /clear signal | No (new session) |

### State Changes
| State | Location | Change Type |
|-------|----------|-------------|
| Context estimate | `.claude/logs/context-estimate.json` | update |
| JICM state | `.claude/state/components/AC-04-jicm.json` | create/update |
| Checkpoint | `.claude/context/.checkpoint.md` | create |
| MCP config | `~/.claude.json` | update |

---

## 5. Dependencies

### System Dependencies
| Dependency | Type | Failure Behavior |
|------------|------|------------------|
| context-accumulator.js | soft | Reduced accuracy, continue |
| AC-02 Wiggum Loop | soft | No context check step |
| MCP disable scripts | soft | Manual MCP management |
| Auto-clear watcher | soft | Manual /clear required |

### MCP Dependencies
| MCP Server | Tools Used | Required |
|------------|------------|----------|
| None | — | JICM cannot depend on MCPs |

**Note**: JICM must NOT depend on MCPs because it may need to disable them.

### File Dependencies
| File | Purpose | Create if Missing |
|------|---------|-------------------|
| `.claude/logs/context-estimate.json` | Usage tracking | Yes (empty object) |
| `.claude/scripts/disable-mcps.sh` | MCP management | No (warn) |
| `.claude/scripts/enable-mcps.sh` | MCP restoration | No (warn) |

---

## 6. Consumers

### Downstream Systems
| Consumer | Relationship | Data Consumed |
|----------|--------------|---------------|
| AC-01 Self-Launch | reads | Checkpoint file |
| AC-02 Wiggum Loop | queries | Context status |
| AC-09 Session Completion | reads | Context statistics |
| User | reads | Dashboard output |

### User Visibility
| Aspect | Visible to User |
|--------|-----------------|
| CAUTION warnings | Yes (console message) |
| WARNING actions | Yes (notification) |
| CRITICAL checkpoint | Yes (confirmation) |
| Dashboard output | Yes (/context-budget) |

### Integration Points

```
┌─────────────────────────────────────────────────────────────────────┐
│                    JICM INTEGRATION                                  │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ┌─────────────────┐     queries      ┌─────────────────┐           │
│  │  AC-02          │──────────────────│  AC-04          │           │
│  │  Wiggum Loop    │                  │  JICM           │           │
│  │  (Step 5)       │◄─────────────────│  (Status)       │           │
│  └─────────────────┘     returns      └────────┬────────┘           │
│                                                │                     │
│                                    if CRITICAL │                     │
│                                                ▼                     │
│                                       ┌─────────────────┐           │
│                                       │  Checkpoint     │           │
│                                       │  + /clear       │           │
│                                       └────────┬────────┘           │
│                                                │                     │
│                                                ▼                     │
│                                       ┌─────────────────┐           │
│                                       │  AC-01          │           │
│                                       │  Self-Launch    │           │
│                                       │  (Resumes work) │           │
│                                       └─────────────────┘           │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 7. Gates

### Approval Checkpoints
| Gate ID | Trigger | Risk Level | Auto-Approve |
|---------|---------|------------|--------------|
| G-01 | MCP disable | Low | Yes (notify) |
| G-02 | Create checkpoint | Low | Yes |
| G-03 | Trigger /clear | Medium | Yes (after checkpoint) |
| G-04 | Archive conversation | Low | Yes |

### Risk Classification
| Action Type | Risk Level | Gate Requirement |
|-------------|------------|------------------|
| Status query | Low | None |
| Warning message | Low | None |
| MCP disable | Low | Auto-approve |
| Checkpoint creation | Low | Auto-approve |
| Trigger /clear | Medium | Auto after checkpoint |
| Emergency compress | High | Confirm essentials preserved |

### Gate Implementation
```
JICM actions are low-medium risk and generally auto-approved.
The key gate is ensuring checkpoint is complete before /clear.
Emergency compression at >95% may require quick user confirmation
that essential state is preserved.
```

---

## 8. Metrics

### Performance Metrics
| Metric | Unit | Target | Alert Threshold |
|--------|------|--------|-----------------|
| Monitoring overhead | tokens | < 100/check | > 500 |
| Checkpoint time | seconds | < 5 | > 30 |
| Compression success rate | % | 100% | < 95% |
| Liftover accuracy | % | > 95% | < 80% |

### Component-Specific Metrics
| Metric | Description | Measurement |
|--------|-------------|-------------|
| `context_level` | Current usage percentage | float |
| `threshold_status` | HEALTHY/CAUTION/WARNING/CRITICAL/EMERGENCY | enum |
| `checkpoints_created` | Number of checkpoints this session | integer |
| `mcps_disabled` | MCPs disabled for efficiency | integer |
| `compression_events` | Times /clear was triggered | integer |
| `liftover_success` | Work resumed after compression | boolean |
| `tokens_preserved` | Essential tokens in checkpoint | integer |
| `tokens_cut` | Tokens removed by compression | integer |

### Storage
| Metric Type | Storage Location | Retention |
|-------------|------------------|-----------|
| Per-check | `.claude/logs/context-estimate.json` | Session |
| Per-session | `.claude/metrics/AC-04-jicm.jsonl` | 30 days |
| Aggregated | `.claude/metrics/aggregates/daily/` | 1 year |

### Emission Format
```jsonl
{"timestamp": "2026-01-16T14:30:00.000Z", "component": "AC-04", "metric": "context_level", "value": 72.5, "unit": "percent"}
{"timestamp": "2026-01-16T14:30:00.000Z", "component": "AC-04", "metric": "threshold_status", "value": "WARNING", "unit": "enum"}
```

---

## 9. Failure Modes

### Known Failure Scenarios
| Failure | Cause | Detection | Recovery |
|---------|-------|-----------|----------|
| Tracking unavailable | Hook not running | No estimate file | Continue with reduced accuracy |
| Checkpoint too large | Too much state | File size check | Prune to essentials |
| /clear fails | Watcher not running | No response | Manual /clear instruction |
| Liftover incomplete | Checkpoint missing data | Work not resumed | User provides context |
| MCP disable fails | Script error | Exit code | Manual MCP management |

### Graceful Degradation
| Degradation Level | Trigger | Behavior |
|-------------------|---------|----------|
| Full | All systems operational | Full monitoring + automation |
| Partial | Tracking unavailable | Warn user, manual checkpoints |
| Partial | Watcher unavailable | Manual /clear required |
| Minimal | Multiple failures | Basic status, user-driven |

### Error Reporting
| Error Type | Notification | Log Location |
|------------|--------------|--------------|
| Warning | Console message | session-start-diagnostic.log |
| Action failure | User notification | jicm-errors.log |
| Critical | Immediate alert | Console + log |

### Rollback Procedures
1. MCP disable can be undone with enable scripts
2. Checkpoints can be deleted if corrupted
3. Archive files can be removed
4. Thresholds can be adjusted in config

---

## Implementation Notes

### Current Implementation (JICM v2)
| Artifact | Path | Status |
|----------|------|--------|
| Component spec | `.claude/context/components/AC-04-jicm.md` | exists |
| Jarvis watcher | `.claude/scripts/jarvis-watcher.sh` | **primary monitor** |
| Intelligent compress | `.claude/commands/intelligent-compress.md` | exists |
| Context compressor agent | `.claude/agents/context-compressor.md` | exists (opus) |
| Context management skill | `.claude/skills/context-management/SKILL.md` | exists |
| Context estimate log | `.claude/logs/context-estimate.json` | written by watcher |
| Launch script | `.claude/scripts/launch-jarvis-tmux.sh` | env vars set |
| Session-start hook | `.claude/hooks/session-start.sh` | restores context |
| Autonomy config | `.claude/config/autonomy-config.yaml` | 80% threshold |

**REMOVED in v2:**
| Artifact | Path | Reason |
|----------|------|--------|
| ~~Context accumulator~~ | `.claude/hooks/context-accumulator.js` | Watcher handles monitoring |

**Environment Variables (set by launch script):**
- `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE=99` — Delay native auto-compact
- `CLAUDE_CODE_MAX_OUTPUT_TOKENS=20000` — Reserve output tokens
- `ENABLE_TOOL_SEARCH=true` — Reduce MCP context usage

### Preservation vs Cutting

#### What to PRESERVE (Critical Information)
```
1. TodoWrite task list and current status
2. Key decisions made during session
3. Blockers and their investigation status
4. Current work context and aims
5. Files modified and their purpose
6. Wiggum Loop pass number and findings
7. Important user instructions
8. Error context if debugging
```

#### What to CUT (Junk Text)
```
1. Raw tool-call outputs → summarize instead
2. Full code text → reference file paths instead
3. Long recursive self-talk → condense to conclusions
4. Verbose file contents → summarize or checkpoint
5. Redundant explanations
6. Superseded investigation paths
7. Detailed MCP tool schemas (can reload)
```

### Checkpoint Strategies

#### Option A: Rich Checkpoint
- Information-dense checkpoint file
- Contains all essential context for full resumption
- Larger file size, but self-contained
- Best for complex work with many dependencies

#### Option B: Lean + Archive Reference
- Lean checkpoint with key pointers
- Full uncompressed context stored in archive file
- Smaller checkpoint, requires archive lookup
- Best for simpler continuations

### Open Questions
- [ ] JICM Agent implementation details?
- [ ] Archive file format and retention?
- [ ] Integration with auto-clear watcher timing?

### Design Decisions Log
| Date | Decision | Rationale |
|------|----------|-----------|
| 2026-01-16 | Continuation, not exit | Work should persist across compression |
| 2026-01-16 | No MCP dependencies | JICM may need to disable MCPs |
| 2026-01-16 | Tiered thresholds | Progressive response to context growth |
| 2026-01-21 | Remove context-accumulator.js | Watcher handles monitoring; accumulator was redundant |
| 2026-01-21 | Single 80% threshold | Simplify: one trigger point, graceful completion before |
| 2026-01-21 | Idle detection before trigger | Don't interrupt Claude mid-response |
| 2026-01-21 | Opus model for compression | Higher quality context preservation |
| 2026-01-21 | /context baseline via skill | Informed decisions on what to drop |
| 2026-01-21 | Learnings always preserved | Resolved issues contain valuable lessons |
| 2026-01-21 | Signal-based compaction via skill | autonomous-commands skill handles /compact signal |
| 2026-01-23 | Commands migrated to skills | /jicm-compact, /auto-* commands deleted; functionality in skills |

---

## Validation Checklist

Before marking this component as "active":

- [x] All 9 specification sections completed
- [ ] Triggers tested (threshold detection, manual command)
- [ ] Inputs/outputs validated
- [x] Dependencies verified (scripts exist)
- [ ] Gates implemented (checkpoint before /clear)
- [x] Metrics emission working (telemetry-emitter.js integrated)
- [ ] Failure modes tested (no tracking, no watcher)
- [ ] Integration with consumers verified (AC-01 resume, AC-02 queries)
- [x] Documentation updated

---

*AC-04 JICM — Jarvis Phase 6 PR-12.4*
