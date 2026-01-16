# AC-06 Self-Evolution — Autonomic Component Specification

**Component ID**: AC-06
**Version**: 1.0.0
**Status**: implementing
**Created**: 2026-01-16
**Last Modified**: 2026-01-16
**PR**: PR-12.6

---

## 1. Identity

### Purpose
Safely implement self-modifications based on reflection insights, R&D discoveries, and user requests. Self-Evolution is the engine that transforms improvement proposals into actual changes, with appropriate gates, validation, and rollback capability.

### Scope
| Dimension | Applies |
|-----------|---------|
| Jarvis Codebase | Yes |
| Active Project | No |
| All Sessions | Yes |

**Scope Note**: Self-Evolution operates on the **Jarvis codebase ONLY**. It never modifies external projects or the AIfred baseline (read-only rule).

### Tier Classification
- [ ] **Tier 1**: Active Work (user-facing, direct task contribution)
- [x] **Tier 2**: Self-Improvement (Jarvis-only, background operation)

### Design Principles

1. **Self-Directed**: Jarvis decides when to launch evolution (downtime, backlog, user request)
2. **Controlled Change**: All changes managed, validated, and reversible
3. **Risk-Based Gates**: Low risk auto-approves, higher risk requires user approval
4. **Validation-First**: Nothing ships without passing validation
5. **Branch-Based**: All changes in branch, merge only after validation

---

## 2. Triggers

### Activation Conditions
| Trigger Type | Condition | Priority |
|--------------|-----------|----------|
| **Manual** | User requests "improve yourself" or `/evolve` | high |
| **Manual** | User requests `/self-improve` | high |
| **Threshold** | Reflection proposal backlog > 5 items | medium |
| **Scheduled** | Downtime detector (~30 min idle) | low |
| **Event-Based** | R&D cycle produces ADOPT proposal | medium |
| **Event-Based** | Benchmark regression detected | high |

### Trigger Implementation
```
Evolution trigger logic:
  - /evolve command → immediate execution
  - /self-improve → runs as part of cycle
  - Backlog > 5 proposals → prompt user for approval
  - Downtime detected → autonomous evolution (low-risk only)
  - R&D ADOPT → queue with require-approval flag

Priority handling:
  - User-triggered: full pipeline
  - Downtime-triggered: low-risk only, notify on completion
  - Backlog-triggered: user approval before proceeding
```

### Suppression Conditions
| Condition | Behavior |
|-----------|----------|
| `JARVIS_DISABLE_AC06=true` | Skip all evolution |
| `JARVIS_QUICK_MODE=true` | Skip evolution |
| No proposals in queue | Nothing to evolve |
| All proposals require approval | Wait for user |
| Rate limit reached | Defer until next session |

---

## 3. Inputs

### Required Inputs
| Input | Source | Format | Purpose |
|-------|--------|--------|---------|
| Evolution queue | `.claude/state/queues/evolution-queue.yaml` | YAML | Proposals to process |
| Autonomy config | `.claude/config/autonomy-config.yaml` | YAML | Settings and limits |

### Optional Inputs
| Input | Source | Default | Purpose |
|-------|--------|---------|---------|
| Benchmark baseline | `.claude/benchmarks/baseline.json` | None | Regression detection |
| Reflection proposals | AC-05 | Queued | New proposals |
| R&D discoveries | AC-07 | Queued | External improvements |
| User requests | User input | None | Direct requests |
| Maintenance findings | AC-08 | Queued | Hygiene proposals |

### Context Requirements

- [x] Evolution queue exists
- [x] Git repository initialized
- [x] Autonomy config exists
- [ ] Benchmark baseline (optional, for validation)

---

## 4. Outputs

### Primary Outputs
| Output | Destination | Format | Consumers |
|--------|-------------|--------|-----------|
| Implemented changes | Git commits | Code/docs | Codebase |
| Evolution log | `.claude/logs/evolution.jsonl` | JSONL | Metrics, audit |
| Updated queue | evolution-queue.yaml | YAML | Next cycle |
| Evolution report | `.claude/reports/evolutions/` | Markdown | User |
| Version bump | VERSION, CHANGELOG | Text | Release |

### Side Effects
| Effect | Description | Reversible |
|--------|-------------|------------|
| File modifications | Changes to Jarvis codebase | Yes (git revert) |
| Git commits | New commits on branch | Yes (git reset) |
| Version bump | VERSION file updated | Yes (git revert) |
| CHANGELOG update | New entries added | Yes (git revert) |

### State Changes
| State | Location | Change Type |
|-------|----------|-------------|
| Evolution state | `.claude/state/components/AC-06-evolution.json` | create/update |
| Evolution queue | `.claude/state/queues/evolution-queue.yaml` | update |
| Git branch | Repository | create/merge/delete |

---

## 5. Dependencies

### System Dependencies
| Dependency | Type | Failure Behavior |
|------------|------|------------------|
| AC-05 Self-Reflection | soft | No reflection proposals |
| AC-07 R&D Cycles | soft | No R&D proposals |
| PR-13 Benchmarks | soft | Skip validation comparison |
| Git | hard | Cannot proceed without git |

### MCP Dependencies
| MCP Server | Tools Used | Required |
|------------|------------|----------|
| Git | git_add, git_commit, git_create_branch, git_checkout | Yes |
| Memory | create_entities, add_observations | No (skip persistence) |

### File Dependencies
| File | Purpose | Create if Missing |
|------|---------|-------------------|
| `.claude/state/queues/evolution-queue.yaml` | Proposal queue | Yes (empty) |
| `.claude/config/autonomy-config.yaml` | Settings | No (use defaults) |
| `.claude/benchmarks/baseline.json` | Validation baseline | No (skip validation) |

---

## 6. Consumers

### Downstream Systems
| Consumer | Relationship | Data Consumed |
|----------|--------------|---------------|
| AC-03 Milestone Review | may review | Evolution changes |
| AC-05 Self-Reflection | may reflect on | Evolution outcomes |
| User | reads | Evolution reports |
| Git history | stores | All changes |

### User Visibility
| Aspect | Visible to User |
|--------|-----------------|
| Evolution start | Yes (if user-triggered or approval needed) |
| Progress | Yes (major steps) |
| Completion | Yes (report presented) |
| Approval requests | Yes (high-risk proposals) |

### Integration Points

```
┌─────────────────────────────────────────────────────────────────────┐
│                    SELF-EVOLUTION INTEGRATION                        │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  PROPOSAL SOURCES                                                    │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐     │
│  │  AC-05          │  │  AC-07          │  │  AC-08          │     │
│  │  Reflection     │  │  R&D Cycles     │  │  Maintenance    │     │
│  └────────┬────────┘  └────────┬────────┘  └────────┬────────┘     │
│           │                    │                    │               │
│           └────────────────────┼────────────────────┘               │
│                                │                                     │
│                                ▼                                     │
│                    ┌─────────────────────┐                          │
│                    │  Evolution Queue    │                          │
│                    │  (evolution-queue   │                          │
│                    │   .yaml)            │                          │
│                    └──────────┬──────────┘                          │
│                               │                                      │
│                               ▼                                      │
│                    ┌─────────────────────┐                          │
│                    │      AC-06          │                          │
│                    │   Self-Evolution    │                          │
│                    │   (7-step pipeline) │                          │
│                    └──────────┬──────────┘                          │
│                               │                                      │
│              ┌────────────────┼────────────────┐                    │
│              │                │                │                    │
│              ▼                ▼                ▼                    │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐     │
│  │  Git Commits    │  │  VERSION/       │  │  Evolution      │     │
│  │  (changes)      │  │  CHANGELOG      │  │  Report         │     │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘     │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 7. Gates

### Approval Checkpoints
| Gate ID | Trigger | Risk Level | Auto-Approve |
|---------|---------|------------|--------------|
| G-01 | Triage proposal | Low | Yes |
| G-02 | Design phase | Low | Yes |
| G-03 | Implementation (low risk) | Low | Yes (notify) |
| G-04 | Implementation (medium risk) | Medium | Yes (notify, proceed unless veto) |
| G-05 | Implementation (high risk) | High | No (require approval) |
| G-06 | R&D-sourced proposal | Medium | No (always require approval) |
| G-07 | Merge to main branch | Medium | Yes (after validation) |
| G-08 | Version bump | Low | Yes |

### Risk Classification
| Action Type | Risk Level | Gate Requirement |
|-------------|------------|------------------|
| Documentation update | Low | Auto-approve, notify |
| New pattern file | Low | Auto-approve, notify |
| Hook modification | Medium | Notify, proceed unless veto |
| Workflow change | Medium | Notify, proceed unless veto |
| Core system change | High | Require explicit approval |
| Multiple file edits (>5) | High | Require explicit approval |
| R&D-sourced change | Medium+ | Always require approval |

### Gate Implementation
```
Risk-based approval flow:

LOW RISK (documentation, patterns):
  → Auto-approve
  → Notify user: "Implementing: [title]"
  → Proceed immediately

MEDIUM RISK (hooks, workflows):
  → Notify user: "Proceeding with: [title] unless you object"
  → Wait 10 seconds for veto
  → Proceed if no veto

HIGH RISK (core changes, multi-file):
  → Request approval: "Approve evolution: [title]? [details]"
  → Wait for explicit yes
  → Proceed only with approval

R&D-SOURCED (any risk level):
  → Always request approval
  → Flag as "require-approval" in queue
```

---

## 8. Metrics

### Performance Metrics
| Metric | Unit | Target | Alert Threshold |
|--------|------|--------|-----------------|
| Evolution time | minutes | < 30 | > 60 |
| Success rate | % | > 90% | < 70% |
| Rollback rate | % | < 10% | > 25% |
| Proposals processed | count/session | 1-5 | > 10 |

### Component-Specific Metrics
| Metric | Description | Measurement |
|--------|-------------|-------------|
| `proposals_triaged` | Proposals evaluated | integer |
| `proposals_approved` | Passed approval gate | integer |
| `proposals_rejected` | Failed approval/validation | integer |
| `implementations_started` | Started implementation | integer |
| `implementations_completed` | Successfully completed | integer |
| `validations_passed` | Passed benchmark validation | integer |
| `validations_failed` | Failed validation | integer |
| `rollbacks_performed` | Changes reverted | integer |
| `version_bumps` | VERSION file updates | integer |
| `risk_level_distribution` | Low/medium/high counts | object |

### Storage
| Metric Type | Storage Location | Retention |
|-------------|------------------|-----------|
| Per-evolution | `.claude/logs/evolution.jsonl` | 90 days |
| Per-session | `.claude/metrics/AC-06-evolution.jsonl` | 30 days |
| Aggregated | `.claude/metrics/aggregates/daily/` | 1 year |

### Emission Format
```jsonl
{"timestamp": "2026-01-16T18:00:00.000Z", "component": "AC-06", "metric": "implementations_completed", "value": 3, "unit": "count"}
{"timestamp": "2026-01-16T18:00:00.000Z", "component": "AC-06", "metric": "rollbacks_performed", "value": 0, "unit": "count"}
```

---

## 9. Failure Modes

### Known Failure Scenarios
| Failure | Cause | Detection | Recovery |
|---------|-------|-----------|----------|
| Git conflict | Concurrent changes | Merge failure | Abort, manual resolution |
| Validation failure | Benchmark regression | Test comparison | Rollback changes |
| Implementation error | Bug in evolution | Runtime error | Rollback, log failure |
| Queue corruption | Bad YAML | Parse error | Reset to backup |
| Rate limit hit | Too many evolutions | Counter check | Defer to next session |

### Graceful Degradation
| Degradation Level | Trigger | Behavior |
|-------------------|---------|----------|
| Full | All systems operational | Full pipeline |
| Partial | No benchmark baseline | Skip validation comparison |
| Partial | Memory MCP unavailable | Skip persistence |
| Minimal | Git issues | Abort safely, preserve state |
| Abort | Critical failure | Rollback all, alert user |

### Error Reporting
| Error Type | Notification | Log Location |
|------------|--------------|--------------|
| Validation failure | User notification | evolution.jsonl |
| Implementation error | User alert | evolution.jsonl |
| Rollback performed | User notification | evolution.jsonl |
| Rate limit | Debug log | evolution.jsonl |

### Rollback Procedures
1. **Automatic**: If validation fails, auto-rollback changes
2. **Git-based**: `git revert` or `git reset` to undo commits
3. **Branch cleanup**: Delete evolution branch if abandoned
4. **Queue update**: Mark proposal as "failed" with reason
5. **Learning**: Add failure to reflection data for AC-05

---

## Implementation Notes

### Current Implementation
| Artifact | Path | Status |
|----------|------|--------|
| Component spec | `.claude/context/components/AC-06-self-evolution.md` | this file |
| Pattern document | `.claude/context/patterns/self-evolution-pattern.md` | planned |
| Evolution queue | `.claude/state/queues/evolution-queue.yaml` | planned |
| Evolution command | `.claude/commands/evolve.md` | planned |
| Downtime detector | `.claude/hooks/downtime-detector.js` | planned |

### Seven-Step Evolution Pipeline

```
┌─────────────────────────────────────────────────────────────────────┐
│                    EVOLUTION PIPELINE                                │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  STEP 1: PROPOSAL TRIAGE                                             │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │  • Evaluate impact (low/medium/high)                           │  │
│  │  • Assess risk (safe/moderate/dangerous)                       │  │
│  │  • Check alignment with roadmap                                │  │
│  │  • Prioritize queue                                            │  │
│  │  Output: Prioritized proposal list                             │  │
│  └───────────────────────────────────────────────────────────────┘  │
│                               │                                      │
│                               ▼                                      │
│  STEP 2: DESIGN PHASE                                                │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │  • Draft implementation plan                                   │  │
│  │  • Identify files to change                                    │  │
│  │  • Define validation criteria                                  │  │
│  │  • Estimate complexity                                         │  │
│  │  Output: Implementation design                                 │  │
│  └───────────────────────────────────────────────────────────────┘  │
│                               │                                      │
│                               ▼                                      │
│  STEP 3: APPROVAL GATE                                               │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │  • Low risk → auto-approve (notify user)                       │  │
│  │  • Medium risk → notify, proceed unless veto                   │  │
│  │  • High risk → require explicit user approval                  │  │
│  │  • R&D-sourced → always require approval                       │  │
│  │  Output: Approval status                                       │  │
│  └───────────────────────────────────────────────────────────────┘  │
│                               │                                      │
│                               ▼                                      │
│  STEP 4: IMPLEMENTATION                                              │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │  • Create git branch: evolution/EVO-YYYY-MM-NNN                │  │
│  │  • Implement changes per design                                │  │
│  │  • Run basic tests if applicable                               │  │
│  │  Output: Changes on branch                                     │  │
│  └───────────────────────────────────────────────────────────────┘  │
│                               │                                      │
│                               ▼                                      │
│  STEP 5: VALIDATION                                                  │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │  • Execute PR-13 benchmarks (if available)                     │  │
│  │  • Compare before/after metrics                                │  │
│  │  • Check for regressions                                       │  │
│  │  • Run /tooling-health                                         │  │
│  │  Output: Validation result (pass/fail)                         │  │
│  └───────────────────────────────────────────────────────────────┘  │
│                               │                                      │
│              ┌────────────────┴────────────────┐                    │
│              │                                 │                    │
│         PASS ▼                            FAIL ▼                    │
│  STEP 6: RELEASE                    STEP 7: ROLLBACK                │
│  ┌───────────────────────┐    ┌───────────────────────┐            │
│  │  • Merge to main      │    │  • Revert changes     │            │
│  │  • Version bump       │    │  • Log failure reason │            │
│  │  • Update CHANGELOG   │    │  • Update proposal    │            │
│  │  • Push to origin     │    │  • Add to reflection  │            │
│  │  • Delete branch      │    │  • Delete branch      │            │
│  └───────────────────────┘    └───────────────────────┘            │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### Safety Mechanisms

| Mechanism | Purpose |
|-----------|---------|
| **AIfred baseline read-only** | Never modify baseline repo |
| **Branch-based changes** | All work in evolution/ branch |
| **Validation required** | Merge only after tests pass |
| **Rollback capability** | Any change can be undone |
| **Rate limiting** | Max N evolutions per session |
| **Human gate** | High-impact requires approval |
| **Audit trail** | All evolutions logged |

### Open Questions
- [ ] Downtime detector implementation details?
- [ ] Rate limit per session (default: 5)?
- [ ] Benchmark integration specifics?

### Design Decisions Log
| Date | Decision | Rationale |
|------|----------|-----------|
| 2026-01-16 | Self-directed triggers | Jarvis decides when to evolve |
| 2026-01-16 | R&D always requires approval | External discoveries need review |
| 2026-01-16 | Branch-based workflow | Safe isolation of changes |
| 2026-01-16 | Seven-step pipeline | Comprehensive validation |

---

## Validation Checklist

Before marking this component as "active":

- [ ] All 9 specification sections completed
- [ ] Triggers tested (manual, downtime, backlog)
- [ ] Inputs/outputs validated
- [ ] Dependencies verified (git available)
- [ ] Gates implemented (risk-based approval)
- [ ] Metrics emission working
- [ ] Failure modes tested (validation failure, rollback)
- [ ] Integration with consumers verified (proposals flow through)
- [ ] Documentation updated

---

*AC-06 Self-Evolution — Jarvis Phase 6 PR-12.6*
