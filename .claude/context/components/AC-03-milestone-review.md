# AC-03 Milestone Review — Autonomic Component Specification

**Component ID**: AC-03
**Version**: 1.0.0
**Status**: active
**Created**: 2026-01-16
**Last Modified**: 2026-01-16
**PR**: PR-12.3

---

## 1. Identity

### Purpose
Semi-autonomous review of completed roadmap milestones to verify deliverables, catch regressions, and ensure quality. Jarvis detects phase completion and prompts user for review; user approves when ready. Uses two-level review process: code-review agent (technical) + project-manager agent (progress/alignment).

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

1. **Semi-Autonomous**: Jarvis detects completion and prompts; user approves when ready
2. **Two-Level Review**: Technical (code-review) + Progress (project-manager)
3. **Separation of Concerns**: Reviewer agents ≠ implementer
4. **Objective Criteria**: Measurable, documented acceptance criteria

---

## 2. Triggers

### Activation Conditions
| Trigger Type | Condition | Priority |
|--------------|-----------|----------|
| **Event-Based** | Wiggum Loop completes PR/milestone | high |
| **Event-Based** | All PR todos marked complete | high |
| **Manual** | User requests `/review-milestone` | medium |
| **Manual** | User requests `/design-review` | medium |

### Trigger Implementation
```
Detection logic:
  - Monitor Wiggum Loop completion events
  - Check if completed work = PR milestone
  - If yes → prompt user: "Review recommended. Any notes?"
  - User approves → launch full review
  - User may also request review manually
```

### Suppression Conditions
| Condition | Behavior |
|-----------|----------|
| `JARVIS_DISABLE_AC03=true` | Skip review prompt |
| `JARVIS_QUICK_MODE=true` | Skip review prompt |
| User declines review | Defer until requested |
| Minor work (not PR milestone) | No review prompt |

---

## 3. Inputs

### Required Inputs
| Input | Source | Format | Purpose |
|-------|--------|--------|---------|
| Milestone/PR identifier | Completion event | String | What to review |
| Roadmap | `projects/project-aion/roadmap.md` | Markdown | Expected deliverables |
| Review criteria | `review-criteria/<PR>.yaml` | YAML | Acceptance criteria |

### Optional Inputs
| Input | Source | Default | Purpose |
|-------|--------|---------|---------|
| User notes | Prompt response | None | Additional context |
| Previous review | Memory MCP | None | Historical comparison |
| Benchmark data | PR-13 | None | Performance baseline |

### Context Requirements

- [x] Roadmap with PR deliverables
- [x] CHANGELOG.md (for version check)
- [ ] Review criteria file (if exists)
- [ ] Benchmark data (if PR-13 available)

---

## 4. Outputs

### Primary Outputs
| Output | Destination | Format | Consumers |
|--------|-------------|--------|-----------|
| Review report | `.claude/reports/reviews/` | Markdown | User |
| Review status | Event log | JSONL | AC-02 (remediation) |
| Remediation todos | TodoWrite | Array | AC-02 Wiggum |
| Memory entry | Memory MCP | Entity | AC-05 Reflection |

### Side Effects
| Effect | Description | Reversible |
|--------|-------------|------------|
| Report file creation | Review findings documented | Yes (delete) |
| Roadmap status update | PR marked complete/incomplete | Yes (edit) |
| Version bump (if pass) | VERSION file updated | Yes (git) |
| CHANGELOG update | Entry added | Yes (git) |

### State Changes
| State | Location | Change Type |
|-------|----------|-------------|
| Review state | `.claude/state/components/AC-03-review.json` | create/update |
| Event log | `.claude/events/current.jsonl` | append |
| Memory | Memory MCP | create entities |

---

## 5. Dependencies

### System Dependencies
| Dependency | Type | Failure Behavior |
|------------|------|------------------|
| AC-02 Wiggum Loop | soft | Manual trigger only |
| code-review agent | hard | Cannot complete Level 1 |
| project-manager agent | hard | Cannot complete Level 2 |

### MCP Dependencies
| MCP Server | Tools Used | Required |
|------------|------------|----------|
| Memory | create_entities, search_nodes | No (skip memory storage) |

### File Dependencies
| File | Purpose | Create if Missing |
|------|---------|-------------------|
| `projects/project-aion/roadmap.md` | PR deliverables | No (error) |
| `review-criteria/<PR>.yaml` | Acceptance criteria | Yes (use defaults) |
| `.claude/reports/reviews/` | Report storage | Yes |

---

## 6. Consumers

### Downstream Systems
| Consumer | Relationship | Data Consumed |
|----------|--------------|---------------|
| AC-02 Wiggum Loop | triggers | Remediation todos |
| AC-05 Reflection | reads | Review findings |
| AC-06 Evolution | reads | Quality patterns |
| User | reads | Review report |

### User Visibility
| Aspect | Visible to User |
|--------|-----------------|
| Execution start | Yes (prompt for approval) |
| Progress updates | Yes (during review) |
| Completion notice | Yes (report presented) |
| Error reports | Yes (always) |

### Integration Points

```
┌─────────────────┐
│   AC-02         │
│   Wiggum Loop   │
└────────┬────────┘
         │ on completion
         ▼
┌─────────────────┐
│   AC-03         │──────► User Prompt
│   Review        │        "Review recommended"
└────────┬────────┘
         │ if issues
         ▼
┌─────────────────┐
│   AC-02         │
│   (Remediation) │
└─────────────────┘
```

---

## 7. Gates

### Approval Checkpoints
| Gate ID | Trigger | Risk Level | Auto-Approve |
|---------|---------|------------|--------------|
| G-01 | Start review | Low | Yes (after user prompt) |
| G-02 | Update roadmap status | Medium | Yes (git tracked) |
| G-03 | Version bump | Medium | Yes (git tracked) |
| G-04 | Block release (major issues) | High | No (requires decision) |

### Risk Classification
| Action Type | Risk Level | Gate Requirement |
|-------------|------------|------------------|
| Read deliverables | Low | None |
| Generate report | Low | None |
| Update roadmap | Medium | Auto-approve |
| Version bump | Medium | Auto-approve |
| Block release | High | User decision |

### Gate Implementation
```
Review itself is low-risk (read-only analysis).
Status updates are medium-risk but git-tracked.
Blocking release for major issues requires user decision.
```

---

## 8. Metrics

### Performance Metrics
| Metric | Unit | Target | Alert Threshold |
|--------|------|--------|-----------------|
| Review time | minutes | < 15 | > 30 |
| Token cost | tokens | < 30000 | > 50000 |
| Pass rate | % | > 80% | < 60% |

### Component-Specific Metrics
| Metric | Description | Measurement |
|--------|-------------|-------------|
| `review_depth` | quick, standard, thorough | enum |
| `findings_count` | Issues identified | integer |
| `approval_status` | approved, conditional, rejected | enum |
| `agent_escalation` | Whether PM agent was invoked | boolean |
| `remediation_triggered` | Whether Wiggum remediation started | boolean |
| `segments_reviewed` | Number of review segments | integer |

### Storage
| Metric Type | Storage Location | Retention |
|-------------|------------------|-----------|
| Per-execution | `.claude/metrics/AC-03-review.jsonl` | 30 days |
| Aggregated | `.claude/metrics/aggregates/daily/` | 1 year |

### Emission Format
```jsonl
{"timestamp": "2026-01-16T14:30:00.000Z", "component": "AC-03", "metric": "findings_count", "value": 3, "unit": "count"}
{"timestamp": "2026-01-16T14:30:00.000Z", "component": "AC-03", "metric": "approval_status", "value": "approved", "unit": "enum"}
```

---

## 9. Failure Modes

### Known Failure Scenarios
| Failure | Cause | Detection | Recovery |
|---------|-------|-----------|----------|
| Roadmap not found | File missing | File not found | Error, cannot review |
| Agent unavailable | Agent not defined | Task spawn fails | Degrade to manual review |
| Large scope | Too many deliverables | Count check | Segment review |
| Criteria missing | No criteria file | File not found | Use default criteria |

### Graceful Degradation
| Degradation Level | Trigger | Behavior |
|-------------------|---------|----------|
| Partial | Agent unavailable | Use other agent only |
| Partial | Memory MCP unavailable | Skip memory storage |
| Minimal | Criteria missing | Use default checklist |
| Abort | Roadmap missing | Error, manual review required |

### Error Reporting
| Error Type | Notification | Log Location |
|------------|--------------|--------------|
| Recoverable | Log warning | session-start-diagnostic.log |
| Non-recoverable | User message | session-start-diagnostic.log |

### Rollback Procedures
1. Review reports can be deleted
2. Roadmap changes are git-tracked
3. Version bump can be reverted
4. Memory entries can be deleted

---

## Implementation Notes

### Current Implementation
| Artifact | Path | Status |
|----------|------|--------|
| Component spec | `.claude/context/components/AC-03-milestone-review.md` | exists |
| Pattern document | `.claude/context/patterns/milestone-review-pattern.md` | exists |
| code-review agent | `.claude/agents/code-review.md` | exists |
| project-manager agent | `.claude/agents/project-manager.md` | exists |
| Review criteria dir | `.claude/review-criteria/` | exists |
| Review criteria defaults | `.claude/review-criteria/defaults.yaml` | exists |
| Reports directory | `.claude/reports/reviews/` | exists |
| State file | `.claude/state/components/AC-03-review.json` | exists |
| Report template | `.claude/context/templates/review-report-template.md` | exists |

### Two-Level Review Process

```
┌─────────────────────────────────────────────────────────────┐
│                    TWO-LEVEL REVIEW                          │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  LEVEL 1: CODE-REVIEW AGENT (Technical Quality)              │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  1. Parse PR deliverables from roadmap.md           │    │
│  │  2. Check each file/artifact exists                 │    │
│  │  3. Verify content completeness                     │    │
│  │  4. Run /tooling-health if applicable               │    │
│  │  5. Run /validate-selection if applicable           │    │
│  │  6. Execute PR-specific validation commands         │    │
│  │  7. Generate technical findings report              │    │
│  └─────────────────────────────────────────────────────┘    │
│                           │                                  │
│                           ▼                                  │
│  LEVEL 2: PROJECT-MANAGER AGENT (Progress & Alignment)       │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  1. Review project status against roadmap           │    │
│  │  2. Check milestone alignment with project aims     │    │
│  │  3. Verify documentation completeness               │    │
│  │     - CHANGELOG.md updated                          │    │
│  │     - Version bumped appropriately                  │    │
│  │     - Related docs updated                          │    │
│  │  4. Compare against PR-13 benchmarks (if available) │    │
│  │  5. Generate progress/alignment report              │    │
│  │  6. Identify next priorities                        │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### Review Outcomes

| Outcome | Criteria | Action |
|---------|----------|--------|
| **Approved** | All criteria pass | Update roadmap, version bump |
| **Conditional** | Minor issues | Note issues, approve with caveats |
| **Rejected** | Major issues | Block release, trigger remediation |

### Resolved Questions
- [x] Default review criteria checklist? → `.claude/review-criteria/defaults.yaml` (created 2026-01-17)
- [x] Integration with existing /design-review? → Separate command, shares pattern but distinct scope (design-review is pre-implementation, milestone-review is post-implementation)

### Design Decisions Log
| Date | Decision | Rationale |
|------|----------|-----------|
| 2026-01-16 | Semi-autonomous trigger | User approval ensures readiness |
| 2026-01-16 | Two-level agents | Separation of technical vs progress |
| 2026-01-16 | Segmented large reviews | Manage context for big PRs |

---

## Validation Checklist

Before marking this component as "active":

- [x] All 9 specification sections completed
- [x] Triggers tested (manual `/review-milestone` validated 2026-02-06 on PR-12.4)
- [x] Inputs/outputs validated (live review: code-review + project-manager agents both produced structured JSON, report saved to `reports/reviews/PR-12.4-review-2026-02-06.md`)
- [x] Dependencies verified (agents defined, criteria files exist, template created)
- [x] Gates implemented (verdict rules in defaults.yaml, completion gate in milestone-completion-gate.yaml)
- [x] Metrics emission working (telemetry-emitter.js integrated)
- [ ] Failure modes tested (missing roadmap, agent failure — deferred to production use)
- [ ] Integration with consumers verified (AC-02 remediation — deferred, requires rejected verdict scenario)
- [x] Documentation updated (pattern v1.2.0, command doc, template, live report)

---

*AC-03 Milestone Review — Jarvis Phase 6 PR-12.3*
