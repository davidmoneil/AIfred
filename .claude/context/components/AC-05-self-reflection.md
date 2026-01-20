# AC-05 Self-Reflection — Autonomic Component Specification

**Component ID**: AC-05
**Version**: 1.0.0
**Status**: active
**Created**: 2026-01-16
**Last Modified**: 2026-01-16
**PR**: PR-12.5

---

## 1. Identity

### Purpose
Create an organized system for storing lessons learned, problems identified, solutions proposed, and metrics—all feeding into Jarvis' efforts to refine the codebase. Self-Reflection transforms raw experience data into actionable improvement proposals.

### Scope
| Dimension | Applies |
|-----------|---------|
| Jarvis Codebase | Yes |
| Active Project | No |
| All Sessions | Yes |

**Scope Note**: Self-Reflection operates on the **Jarvis codebase ONLY**. It does not reflect on external projects—that would be project-specific learning, not self-improvement.

### Tier Classification
- [ ] **Tier 1**: Active Work (user-facing, direct task contribution)
- [x] **Tier 2**: Self-Improvement (Jarvis-only, background operation)

### Design Principles

1. **Evidence-Based**: All insights backed by data, not speculation
2. **Actionable Output**: Reflections produce concrete evolution proposals
3. **Organized Storage**: Problems, solutions, patterns in structured directories
4. **Dual Tracking**: User corrections vs self-corrections tracked separately
5. **Cross-Session Learning**: Memory MCP provides persistence across sessions

---

## 2. Triggers

### Activation Conditions
| Trigger Type | Condition | Priority |
|--------------|-----------|----------|
| **Event-Based** | Session end (/end-session) | medium |
| **Event-Based** | PR completion | medium |
| **Event-Based** | Phase completion | high |
| **Manual** | User requests `/reflect` | high |
| **Scheduled** | Idle/downtime detection (~30 min) | low |
| **Threshold** | Corrections backlog > N entries | medium |

### Trigger Implementation
```
Reflection triggers:
  - /end-session calls reflection as pre-exit step
  - PR completion (detected by AC-03) triggers reflection
  - Downtime detector (AC-06) can invoke reflection
  - Manual /reflect command available anytime

Trigger priority:
  - User request takes precedence
  - Completion events (PR/phase) next
  - Idle/scheduled lowest priority
```

### Suppression Conditions
| Condition | Behavior |
|-----------|----------|
| `JARVIS_DISABLE_AC05=true` | Skip reflection entirely |
| `JARVIS_QUICK_MODE=true` | Skip reflection |
| Session < 5 minutes | Skip (not enough data) |
| No new corrections/data | Skip (nothing to reflect on) |

---

## 3. Inputs

### Required Inputs
| Input | Source | Format | Purpose |
|-------|--------|--------|---------|
| User corrections | `.claude/context/lessons/corrections.md` | Markdown | What user corrected |
| Self-corrections | `.claude/context/lessons/self-corrections.md` | Markdown | Self-identified fixes |
| Session state | `session-state.md` | Markdown | Work patterns |

### Optional Inputs
| Input | Source | Default | Purpose |
|-------|--------|---------|---------|
| Agent learnings | `.claude/agents/memory/*/learnings.json` | Empty | Agent discoveries |
| Selection audit | `selection-audit.jsonl` | Empty | Tool selection patterns |
| Context estimate | `context-estimate.json` | None | Resource usage patterns |
| Git history | `git log` | None | Change patterns |
| Memory MCP | `search_nodes` | None | Prior reflections |
| AC-03 review findings | Review reports | None | Quality issues |

### Context Requirements

- [x] corrections.md exists (may be empty)
- [x] self-corrections.md exists (may be empty)
- [x] session-state.md exists
- [ ] Memory MCP available (optional, degrades gracefully)

---

## 4. Outputs

### Primary Outputs
| Output | Destination | Format | Consumers |
|--------|-------------|--------|-----------|
| Reflection report | `.claude/reports/reflections/` | Markdown | User, AC-06 |
| Problem entries | `.claude/context/lessons/problems/` | Markdown | Index, AC-06 |
| Solution entries | `.claude/context/lessons/solutions/` | Markdown | Index, AC-06 |
| Pattern entries | `.claude/context/lessons/patterns/` | Markdown | Index, Context |
| Evolution proposals | `.claude/state/queues/evolution-queue.yaml` | YAML | AC-06 Evolution |
| Memory entities | Memory MCP | Entities | Cross-session recall |

### Side Effects
| Effect | Description | Reversible |
|--------|-------------|------------|
| File creation | New problem/solution/pattern entries | Yes (delete) |
| Index update | lessons/index.md updated | Yes (edit) |
| Queue update | Evolution proposals added | Yes (remove) |
| Memory writes | Entities created in Memory MCP | Yes (delete) |

### State Changes
| State | Location | Change Type |
|-------|----------|-------------|
| Reflection state | `.claude/state/components/AC-05-reflection.json` | create/update |
| Lessons index | `.claude/context/lessons/index.md` | update |
| Evolution queue | `.claude/state/queues/evolution-queue.yaml` | append |
| Memory | Memory MCP entities | create |

---

## 5. Dependencies

### System Dependencies
| Dependency | Type | Failure Behavior |
|------------|------|------------------|
| Lessons directory | hard | Create if missing |
| AC-06 Self-Evolution | soft | Proposals queued, not processed |
| AC-03 Milestone Review | soft | No review data input |

### MCP Dependencies
| MCP Server | Tools Used | Required |
|------------|------------|----------|
| Memory | create_entities, search_nodes, add_observations | No (skip persistence) |
| Git | git_log, git_diff | No (skip history analysis) |

### File Dependencies
| File | Purpose | Create if Missing |
|------|---------|-------------------|
| `.claude/context/lessons/corrections.md` | User corrections | Yes (empty) |
| `.claude/context/lessons/self-corrections.md` | Self-corrections | Yes (empty) |
| `.claude/context/lessons/index.md` | Lessons index | Yes (template) |
| `.claude/context/lessons/problems/` | Problem entries | Yes (directory) |
| `.claude/context/lessons/solutions/` | Solution entries | Yes (directory) |
| `.claude/context/lessons/patterns/` | Pattern entries | Yes (directory) |

---

## 6. Consumers

### Downstream Systems
| Consumer | Relationship | Data Consumed |
|----------|--------------|---------------|
| AC-06 Self-Evolution | reads | Evolution proposals |
| AC-07 R&D Cycles | reads | Problem patterns |
| AC-08 Maintenance | reads | Organization issues |
| User | reads | Reflection reports |

### User Visibility
| Aspect | Visible to User |
|--------|-----------------|
| Reflection start | Yes (if manual or session-end) |
| Progress | Minimal (brief status) |
| Report output | Yes (summary presented) |
| Proposals generated | Yes (listed in report) |

### Integration Points

```
┌─────────────────────────────────────────────────────────────────────┐
│                    SELF-REFLECTION INTEGRATION                       │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  DATA SOURCES                                                        │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐     │
│  │  corrections.md │  │ self-correct.md │  │  Memory MCP     │     │
│  └────────┬────────┘  └────────┬────────┘  └────────┬────────┘     │
│           │                    │                    │               │
│           └────────────────────┼────────────────────┘               │
│                                │                                     │
│                                ▼                                     │
│                    ┌─────────────────────┐                          │
│                    │      AC-05          │                          │
│                    │   Self-Reflection   │                          │
│                    └──────────┬──────────┘                          │
│                               │                                      │
│              ┌────────────────┼────────────────┐                    │
│              │                │                │                    │
│              ▼                ▼                ▼                    │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐     │
│  │  Lessons Dir    │  │ Evolution Queue │  │  Memory MCP     │     │
│  │  (problems/     │  │   (proposals)   │  │   (entities)    │     │
│  │   solutions/    │  └────────┬────────┘  └─────────────────┘     │
│  │   patterns/)    │           │                                    │
│  └─────────────────┘           ▼                                    │
│                    ┌─────────────────────┐                          │
│                    │      AC-06          │                          │
│                    │   Self-Evolution    │                          │
│                    └─────────────────────┘                          │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 7. Gates

### Approval Checkpoints
| Gate ID | Trigger | Risk Level | Auto-Approve |
|---------|---------|------------|--------------|
| G-01 | Create problem/solution files | Low | Yes |
| G-02 | Update lessons index | Low | Yes |
| G-03 | Create evolution proposal | Low | Yes (queued, not executed) |
| G-04 | Write Memory MCP entities | Low | Yes |

### Risk Classification
| Action Type | Risk Level | Gate Requirement |
|-------------|------------|------------------|
| Read data sources | Low | None |
| Create lesson entries | Low | None |
| Update index | Low | None |
| Generate proposals | Low | None (proposals require separate approval) |
| Write to Memory | Low | None |

### Gate Implementation
```
Self-Reflection is low-risk (analysis and documentation).
All outputs are read-only or create new files.
Evolution proposals are QUEUED, not executed—execution
requires separate approval in AC-06.
```

---

## 8. Metrics

### Performance Metrics
| Metric | Unit | Target | Alert Threshold |
|--------|------|--------|-----------------|
| Reflection time | minutes | < 10 | > 20 |
| Token cost | tokens | < 15000 | > 30000 |
| Insights generated | count | > 0 | = 0 after PR |

### Component-Specific Metrics
| Metric | Description | Measurement |
|--------|-------------|-------------|
| `corrections_processed` | User corrections analyzed | integer |
| `self_corrections_processed` | Self-corrections analyzed | integer |
| `problems_identified` | New problem entries created | integer |
| `solutions_proposed` | New solution entries created | integer |
| `patterns_discovered` | New pattern entries created | integer |
| `evolution_proposals` | Proposals added to queue | integer |
| `memory_entities_created` | Entities written to Memory MCP | integer |
| `reflection_depth` | quick, standard, thorough | enum |

### Storage
| Metric Type | Storage Location | Retention |
|-------------|------------------|-----------|
| Per-reflection | `.claude/metrics/AC-05-reflection.jsonl` | 30 days |
| Aggregated | `.claude/metrics/aggregates/daily/` | 1 year |

### Emission Format
```jsonl
{"timestamp": "2026-01-16T18:00:00.000Z", "component": "AC-05", "metric": "problems_identified", "value": 2, "unit": "count"}
{"timestamp": "2026-01-16T18:00:00.000Z", "component": "AC-05", "metric": "evolution_proposals", "value": 3, "unit": "count"}
```

---

## 9. Failure Modes

### Known Failure Scenarios
| Failure | Cause | Detection | Recovery |
|---------|-------|-----------|----------|
| No data to reflect | Empty corrections | Check file size | Skip reflection, log |
| Memory MCP unavailable | Server not running | Connection error | Skip persistence, continue |
| Lessons dir missing | Not created | Directory check | Create directories |
| Index corruption | Bad write | Parse error | Regenerate from entries |

### Graceful Degradation
| Degradation Level | Trigger | Behavior |
|-------------------|---------|----------|
| Full | All systems operational | Full reflection + persistence |
| Partial | Memory MCP unavailable | Local files only |
| Partial | No git history | Skip change analysis |
| Minimal | Only corrections available | Basic reflection only |
| Skip | No data at all | Log and skip |

### Error Reporting
| Error Type | Notification | Log Location |
|------------|--------------|--------------|
| No data | Debug log only | reflection.log |
| MCP error | Warning | reflection.log |
| File error | User notification | reflection.log |

### Rollback Procedures
1. Problem/solution/pattern entries can be deleted
2. Index can be regenerated from entry files
3. Memory entities can be deleted
4. Evolution proposals can be removed from queue

---

## Implementation Notes

### Current Implementation
| Artifact | Path | Status |
|----------|------|--------|
| Component spec | `.claude/context/components/AC-05-self-reflection.md` | exists |
| Pattern document | `.claude/context/patterns/self-reflection-pattern.md` | exists |
| Corrections file | `.claude/context/lessons/corrections.md` | exists |
| Self-corrections file | `.claude/context/lessons/self-corrections.md` | exists |
| Lessons index | `.claude/context/lessons/index.md` | exists |
| Lessons directories | `.claude/context/lessons/{problems,solutions,patterns}/` | exists |
| Reflection command | `.claude/commands/reflect.md` | exists |
| Evolution queue | `.claude/state/queues/evolution-queue.yaml` | exists |
| State file | `.claude/state/components/AC-05-reflection.json` | exists |
| Reports directory | `.claude/reports/reflections/` | exists |

### Lessons Directory Structure

```
.claude/context/lessons/
├── corrections.md          # User-provided corrections
├── self-corrections.md     # Jarvis self-corrections
├── index.md                # Categorical + chronological index
├── problems/               # Problems identified
│   ├── 2026-01-problem-hook-format.md
│   ├── 2026-01-problem-context-bloat.md
│   └── ...
├── solutions/              # Solutions proposed/applied
│   ├── 2026-01-solution-hook-wrapper.md
│   ├── 2026-01-solution-checkpoint-workflow.md
│   └── ...
└── patterns/               # Patterns discovered
    ├── pattern-mcp-restart.md
    ├── pattern-progressive-disclosure.md
    └── ...
```

### Three-Phase Reflection Process

```
┌─────────────────────────────────────────────────────────────────────┐
│                    THREE-PHASE REFLECTION                            │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  PHASE 1: IDENTIFICATION                                             │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │  Questions to answer:                                          │  │
│  │  • What problems occurred this session/PR?                     │  │
│  │  • What inefficiencies were observed?                          │  │
│  │  • What corrections were received (user + self)?               │  │
│  │  • What patterns emerged?                                      │  │
│  │                                                                │  │
│  │  Data sources:                                                 │  │
│  │  • corrections.md, self-corrections.md                         │  │
│  │  • selection-audit.jsonl                                       │  │
│  │  • context-estimate.json                                       │  │
│  │  • git history                                                 │  │
│  └───────────────────────────────────────────────────────────────┘  │
│                               │                                      │
│                               ▼                                      │
│  PHASE 2: REFLECTION                                                 │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │  Questions to answer:                                          │  │
│  │  • Why did these problems occur?                               │  │
│  │  • What knowledge was missing?                                 │  │
│  │  • What approaches worked well?                                │  │
│  │  • What sequences should be automated?                         │  │
│  │                                                                │  │
│  │  Analysis methods:                                             │  │
│  │  • Root cause analysis                                         │  │
│  │  • Pattern matching with prior problems                        │  │
│  │  • Success/failure comparison                                  │  │
│  └───────────────────────────────────────────────────────────────┘  │
│                               │                                      │
│                               ▼                                      │
│  PHASE 3: PROPOSAL                                                   │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │  Generate for each insight:                                    │  │
│  │  • Specific solution with rationale                            │  │
│  │  • Files/patterns to modify                                    │  │
│  │  • Risk assessment (low/medium/high)                           │  │
│  │  • Link to related prior solutions                             │  │
│  │                                                                │  │
│  │  Output:                                                       │  │
│  │  • Evolution proposals → evolution-queue.yaml                  │  │
│  │  • Lessons entries → problems/, solutions/, patterns/          │  │
│  │  • Memory entities → Memory MCP                                │  │
│  └───────────────────────────────────────────────────────────────┘  │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### Open Questions
- [ ] Integration with existing self-correction-capture.js hook?
- [ ] Reflection depth levels (quick vs thorough)?
- [ ] Memory entity schema for reflections?

### Design Decisions Log
| Date | Decision | Rationale |
|------|----------|-----------|
| 2026-01-16 | Jarvis codebase only | Self-improvement scope, not project learning |
| 2026-01-16 | Separate user vs self corrections | Different sources, different handling |
| 2026-01-16 | Three-phase process | Structured approach to insight generation |
| 2026-01-16 | Proposals queued, not executed | Separation from AC-06 execution |

---

## Validation Checklist

Before marking this component as "active":

- [x] All 9 specification sections completed
- [ ] Triggers tested (manual, session-end, PR completion)
- [ ] Inputs/outputs validated
- [x] Dependencies verified (lessons directory exists)
- [ ] Gates implemented (all low-risk, auto-approve)
- [x] Metrics emission working (telemetry-emitter.js integrated)
- [ ] Failure modes tested (no data, no Memory MCP)
- [ ] Integration with consumers verified (AC-06 reads proposals)
- [x] Documentation updated

---

*AC-05 Self-Reflection — Jarvis Phase 6 PR-12.5*
