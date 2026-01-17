# AC-07 R&D Cycles — Autonomic Component Specification

**Component ID**: AC-07
**Version**: 1.0.0
**Status**: implementing
**Created**: 2026-01-16
**Last Modified**: 2026-01-16
**PR**: PR-12.7

---

## 1. Identity

### Purpose
Conduct research on external innovations (new MCPs, plugins, SOTA patterns) AND internal efficiency (token usage, file organization). R&D Cycles discover opportunities for improvement that feed into Self-Evolution, maintaining Jarvis's awareness of the broader ecosystem while optimizing internal operations.

### Scope
| Dimension | Applies |
|-----------|---------|
| Jarvis Codebase | Yes |
| Active Project | No |
| All Sessions | Yes |

**Scope Note**: R&D operates on the **Jarvis codebase ONLY** for improvements. External research informs Jarvis capabilities but changes only apply to Jarvis itself.

### Tier Classification
- [ ] **Tier 1**: Active Work (user-facing, direct task contribution)
- [x] **Tier 2**: Self-Improvement (Jarvis-only, background operation)

### Design Principles

1. **Dual Focus**: Both external (new tools) AND internal (token efficiency)
2. **High Adoption Bar**: New tools must justify their complexity and context cost
3. **Require-Approval**: R&D proposals always require user approval before implementation
4. **Evidence-Based**: Recommendations backed by concrete analysis
5. **Bloat Prevention**: Default to DEFER/REJECT unless clear value demonstrated

---

## 2. Triggers

### Activation Conditions
| Trigger Type | Condition | Priority |
|--------------|-----------|----------|
| **Manual** | User requests `/research` | high |
| **Manual** | User requests `/self-improve --focus=research` | high |
| **Scheduled** | Downtime detector (~30 min idle) | low |
| **Threshold** | Research agenda backlog > 10 items | medium |
| **Scheduled** | Monthly MCP/plugin scan | low |
| **Event-Based** | New Anthropic release announced | medium |

### Trigger Implementation
```
R&D trigger logic:
  - /research command → immediate execution
  - /self-improve → runs as part of cycle
  - Downtime detected → autonomous R&D
  - Monthly schedule → scan for new tools

Priority handling:
  - User-triggered: full research cycle
  - Downtime-triggered: internal efficiency focus
  - Scheduled: external discovery focus
```

### Suppression Conditions
| Condition | Behavior |
|-----------|----------|
| `JARVIS_DISABLE_AC07=true` | Skip all R&D |
| `JARVIS_QUICK_MODE=true` | Skip R&D |
| Active PR work in progress | Defer until PR complete |
| High context usage (>70%) | Defer (R&D is context-heavy) |

---

## 3. Inputs

### Required Inputs
| Input | Source | Format | Purpose |
|-------|--------|--------|---------|
| Research agenda | `.claude/state/queues/research-agenda.yaml` | YAML | Topics to research |
| Autonomy config | `.claude/config/autonomy-config.yaml` | YAML | Settings |

### Optional Inputs
| Input | Source | Default | Purpose |
|-------|--------|---------|---------|
| SOTA catalog | `projects/project-aion/sota-catalog/` | None | Reference projects |
| File usage log | `.claude/logs/file-usage.jsonl` | None | Internal efficiency |
| MCP registry | awesome-mcp lists | Web | External discovery |
| Plugin registry | claude-code-plugins | Web | External discovery |
| Memory MCP | Prior research | None | Avoid re-research |

### Context Requirements

- [x] Research agenda exists (may be empty)
- [x] Web access available (for external research)
- [ ] SOTA catalog (PR-14, optional)
- [ ] File usage tracking (optional)

---

## 4. Outputs

### Primary Outputs
| Output | Destination | Format | Consumers |
|--------|-------------|--------|-----------|
| Research report | `.claude/reports/research/` | Markdown | User, AC-06 |
| Evolution proposals | `evolution-queue.yaml` | YAML | AC-06 |
| Catalog updates | `sota-catalog/` | Markdown | Future R&D |
| Efficiency proposals | `evolution-queue.yaml` | YAML | AC-06 |
| Memory entities | Memory MCP | Entities | Cross-session |

### Side Effects
| Effect | Description | Reversible |
|--------|-------------|------------|
| Research reports | New files created | Yes (delete) |
| Catalog updates | SOTA catalog expanded | Yes (edit) |
| Evolution proposals | Queue additions | Yes (remove) |
| Agenda updates | Items marked researched | Yes (edit) |

### State Changes
| State | Location | Change Type |
|-------|----------|-------------|
| R&D state | `.claude/state/components/AC-07-rd.json` | create/update |
| Research agenda | `.claude/state/queues/research-agenda.yaml` | update |
| Evolution queue | `evolution-queue.yaml` | append |
| SOTA catalog | `sota-catalog/` | update |

---

## 5. Dependencies

### System Dependencies
| Dependency | Type | Failure Behavior |
|------------|------|------------------|
| AC-06 Self-Evolution | soft | Proposals queued but not processed |
| PR-14 SOTA Catalog | soft | Skip catalog updates |
| Web access | soft | Skip external research |
| deep-research agent | soft | Use basic research instead |

### MCP Dependencies
| MCP Server | Tools Used | Required |
|------------|------------|----------|
| Fetch | fetch | No (skip web research) |
| Memory | create_entities, search_nodes | No (skip persistence) |

### File Dependencies
| File | Purpose | Create if Missing |
|------|---------|-------------------|
| `.claude/state/queues/research-agenda.yaml` | Research topics | Yes (empty) |
| `.claude/reports/research/` | Report storage | Yes (directory) |
| `projects/project-aion/sota-catalog/` | Reference catalog | No (skip updates) |

---

## 6. Consumers

### Downstream Systems
| Consumer | Relationship | Data Consumed |
|----------|--------------|---------------|
| AC-06 Self-Evolution | reads | Evolution proposals |
| AC-05 Self-Reflection | may read | Research patterns |
| PR-14 SOTA Catalog | updated | New entries |
| User | reads | Research reports |

### User Visibility
| Aspect | Visible to User |
|--------|-----------------|
| R&D start | Yes (if manual or significant findings) |
| Progress | Minimal (summary at end) |
| Report output | Yes (full report presented) |
| Proposals generated | Yes (listed, require approval) |

### Integration Points

```
┌─────────────────────────────────────────────────────────────────────┐
│                    R&D CYCLES INTEGRATION                            │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  RESEARCH SOURCES                                                    │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐     │
│  │  External       │  │  Internal       │  │  User           │     │
│  │  (MCP, plugins, │  │  (file usage,   │  │  (requested     │     │
│  │   SOTA)         │  │   efficiency)   │  │   topics)       │     │
│  └────────┬────────┘  └────────┬────────┘  └────────┬────────┘     │
│           │                    │                    │               │
│           └────────────────────┼────────────────────┘               │
│                                │                                     │
│                                ▼                                     │
│                    ┌─────────────────────┐                          │
│                    │  Research Agenda    │                          │
│                    └──────────┬──────────┘                          │
│                               │                                      │
│                               ▼                                      │
│                    ┌─────────────────────┐                          │
│                    │      AC-07          │                          │
│                    │    R&D Cycles       │                          │
│                    │  (5-step process)   │                          │
│                    └──────────┬──────────┘                          │
│                               │                                      │
│              ┌────────────────┼────────────────┐                    │
│              │                │                │                    │
│              ▼                ▼                ▼                    │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐     │
│  │  Research       │  │  Evolution      │  │  SOTA           │     │
│  │  Reports        │  │  Proposals      │  │  Catalog        │     │
│  │                 │  │  (require-      │  │  Updates        │     │
│  │                 │  │   approval)     │  │                 │     │
│  └─────────────────┘  └────────┬────────┘  └─────────────────┘     │
│                                │                                     │
│                                ▼                                     │
│                    ┌─────────────────────┐                          │
│                    │      AC-06          │                          │
│                    │   Self-Evolution    │                          │
│                    │  (requires approval)│                          │
│                    └─────────────────────┘                          │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 7. Gates

### Approval Checkpoints
| Gate ID | Trigger | Risk Level | Auto-Approve |
|---------|---------|------------|--------------|
| G-01 | Start research | Low | Yes |
| G-02 | Generate report | Low | Yes |
| G-03 | Update SOTA catalog | Low | Yes |
| G-04 | Create evolution proposal | Low | Yes (queued only) |
| G-05 | Implement R&D discovery | Medium+ | No (always require approval) |

### Risk Classification
| Action Type | Risk Level | Gate Requirement |
|-------------|------------|------------------|
| Web research | Low | None |
| Internal analysis | Low | None |
| Report generation | Low | None |
| Catalog update | Low | None |
| Evolution proposal | Low | None (proposal only) |
| Implementation | Medium+ | Always require approval |

### Gate Implementation
```
R&D itself is low-risk (research and reporting).
The key gate is that ALL R&D-sourced evolution proposals
require explicit user approval before implementation.

This ensures Jarvis never auto-integrates external
discoveries without human review.
```

---

## 8. Metrics

### Performance Metrics
| Metric | Unit | Target | Alert Threshold |
|--------|------|--------|-----------------|
| Research time | minutes | < 30 | > 60 |
| Token cost | tokens | < 20000 | > 40000 |
| Discovery rate | items/cycle | 1-5 | 0 (no findings) |

### Component-Specific Metrics
| Metric | Description | Measurement |
|--------|-------------|-------------|
| `topics_researched` | Items from agenda processed | integer |
| `external_discoveries` | New MCP/plugin/tool found | integer |
| `internal_findings` | Efficiency issues identified | integer |
| `proposals_generated` | Evolution proposals created | integer |
| `adopt_recommendations` | Items marked ADOPT | integer |
| `adapt_recommendations` | Items marked ADAPT | integer |
| `defer_recommendations` | Items marked DEFER | integer |
| `reject_recommendations` | Items marked REJECT | integer |
| `catalog_updates` | SOTA entries added/updated | integer |

### Storage
| Metric Type | Storage Location | Retention |
|-------------|------------------|-----------|
| Per-cycle | `.claude/metrics/AC-07-rd.jsonl` | 30 days |
| Aggregated | `.claude/metrics/aggregates/daily/` | 1 year |

### Emission Format
```jsonl
{"timestamp": "2026-01-16T18:00:00.000Z", "component": "AC-07", "metric": "topics_researched", "value": 5, "unit": "count"}
{"timestamp": "2026-01-16T18:00:00.000Z", "component": "AC-07", "metric": "adopt_recommendations", "value": 1, "unit": "count"}
```

---

## 9. Failure Modes

### Known Failure Scenarios
| Failure | Cause | Detection | Recovery |
|---------|-------|-----------|----------|
| Web access unavailable | Network issue | Fetch fails | Skip external, do internal |
| Agenda empty | Nothing to research | Check count | Generate default topics |
| Research too broad | Poor scope | Token spike | Narrow focus, checkpoint |
| Deep-research unavailable | Agent missing | Spawn fails | Use basic research |

### Graceful Degradation
| Degradation Level | Trigger | Behavior |
|-------------------|---------|----------|
| Full | All systems operational | Full external + internal R&D |
| Partial | No web access | Internal efficiency only |
| Partial | No deep-research agent | Basic research |
| Partial | No SOTA catalog | Skip catalog updates |
| Minimal | Agenda empty | Generate default topics |

### Error Reporting
| Error Type | Notification | Log Location |
|------------|--------------|--------------|
| Web failure | Warning | rd-cycles.log |
| Research incomplete | User notification | rd-cycles.log |
| Token spike | Alert + checkpoint | rd-cycles.log |

### Rollback Procedures
1. Research reports can be deleted
2. Catalog updates can be reverted
3. Evolution proposals can be removed from queue
4. Memory entities can be deleted

---

## Implementation Notes

### Current Implementation
| Artifact | Path | Status |
|----------|------|--------|
| Component spec | `.claude/context/components/AC-07-rd-cycles.md` | exists |
| Pattern document | `.claude/context/patterns/rd-cycles-pattern.md` | exists |
| Research agenda | `.claude/state/queues/research-agenda.yaml` | exists |
| Research command | `.claude/commands/research.md` | exists |
| State file | `.claude/state/components/AC-07-rd.json` | exists |
| Reports directory | `.claude/reports/research/` | exists |
| File usage tracker | `.claude/hooks/file-usage-tracker.js` | optional |

### Dual Research Focus

```
┌─────────────────────────────────────────────────────────────────────┐
│                    DUAL RESEARCH FOCUS                               │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  EXTERNAL RESEARCH                                                   │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │  Sources:                                                      │  │
│  │  • awesome-mcp lists (monthly scan)                            │  │
│  │  • claude-code-plugins registry                                │  │
│  │  • Anthropic announcements                                     │  │
│  │  • SOTA catalog (PR-14)                                        │  │
│  │  • User-suggested topics                                       │  │
│  │                                                                │  │
│  │  Questions:                                                    │  │
│  │  • What new tools are available?                               │  │
│  │  • Do they solve a Jarvis problem?                             │  │
│  │  • Is the complexity justified?                                │  │
│  │  • What's the context cost?                                    │  │
│  └───────────────────────────────────────────────────────────────┘  │
│                                                                      │
│  INTERNAL RESEARCH                                                   │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │  Focus: Token Efficiency                                       │  │
│  │                                                                │  │
│  │  Track:                                                        │  │
│  │  • Which .claude files are loaded each session                 │  │
│  │  • High-use vs low-use files                                   │  │
│  │  • Redundant instructions across files                         │  │
│  │  • Important patterns that go unused                           │  │
│  │                                                                │  │
│  │  Goal: Lean, linked, layered scope                             │  │
│  │  • Lean: No bloat, every file earns its tokens                 │  │
│  │  • Linked: Reference rather than duplicate                     │  │
│  │  • Layered: Load what's needed, defer the rest                 │  │
│  └───────────────────────────────────────────────────────────────┘  │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### Five-Step Research Process

```
1. DISCOVERY
   └── Scan source lists for new entries
   └── Fetch README/documentation
   └── Extract capabilities and requirements

2. RELEVANCE FILTERING
   └── Does it solve a Jarvis problem?
   └── Does it overlap with existing tools?
   └── Is the complexity justified?

3. DEEP ANALYSIS (for relevant items)
   └── Use deep-research agent
   └── Identify specific use cases
   └── Assess integration effort

4. CLASSIFICATION
   └── ADOPT: High value, low risk → implement
   └── ADAPT: High value, needs modification → plan
   └── DEFER: Potential value, wait for stability
   └── REJECT: Low value or high risk → skip

5. PROPOSAL GENERATION
   └── For ADOPT/ADAPT items, create evolution proposal
   └── Flag as "require-approval"
   └── Link to source documentation
   └── Define integration steps
```

### Open Questions
- [ ] File usage tracker implementation?
- [ ] Monthly scan scheduling mechanism?
- [ ] Integration with PR-14 catalog?

### Design Decisions Log
| Date | Decision | Rationale |
|------|----------|-----------|
| 2026-01-16 | Dual focus (external + internal) | Both contribute to improvement |
| 2026-01-16 | R&D proposals require approval | External discoveries need review |
| 2026-01-16 | High adoption bar | Prevent bloat |
| 2026-01-16 | Default to DEFER/REJECT | Conservative approach |

---

## Validation Checklist

Before marking this component as "active":

- [x] All 9 specification sections completed
- [ ] Triggers tested (manual, downtime, scheduled)
- [ ] Inputs/outputs validated
- [x] Dependencies verified (web access, deep-research)
- [ ] Gates implemented (proposals require approval)
- [ ] Metrics emission working (waiting for PR-13 telemetry)
- [ ] Failure modes tested (no web, no agent)
- [ ] Integration with consumers verified (AC-06 receives proposals)
- [x] Documentation updated

---

*AC-07 R&D Cycles — Jarvis Phase 6 PR-12.7*
