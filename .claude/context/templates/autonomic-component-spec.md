# [Component Name] — Autonomic Component Specification

> **Template**: Copy when specifying a new autonomic system component.
> Reference: `projects/project-aion/ideas/phase-6-autonomy-design.md`

**Component ID**: `AC-[number]` (e.g., AC-01 for Self-Launch)
**Version**: 1.0.0
**Status**: [design | implementing | active | deprecated]
**Created**: [YYYY-MM-DD]
**Last Modified**: [YYYY-MM-DD]

---

## 1. Identity

### Purpose
[One-sentence description of what this component does and WHY it exists.]

### Scope
| Dimension | Applies |
|-----------|---------|
| Jarvis Codebase | [Yes/No] |
| Active Project | [Yes/No] |
| All Sessions | [Yes/No] |

### Tier Classification
- [ ] **Tier 1**: Active Work (user-facing, direct task contribution)
- [ ] **Tier 2**: Self-Improvement (Jarvis-only, background operation)

### Design Principles
[List 2-4 core principles that guide this component's behavior.]

1. [Principle 1]
2. [Principle 2]
3. [Principle 3]

---

## 2. Triggers

### Activation Conditions
| Trigger Type | Condition | Priority |
|--------------|-----------|----------|
| **Automatic** | [e.g., session start, idle timeout] | [high/medium/low] |
| **Event-Based** | [e.g., another component completes] | [high/medium/low] |
| **Scheduled** | [e.g., every N minutes/hours] | [high/medium/low] |
| **Manual** | [e.g., user command, explicit invocation] | [high/medium/low] |

### Trigger Implementation
```
[Describe how triggers are detected]
- Hook name: [session-start.sh | PreCompact | etc.]
- Event source: [file watch | MCP | timer | etc.]
- Detection logic: [brief description]
```

### Suppression Conditions
[When should this component NOT activate even if triggers fire?]

| Condition | Behavior |
|-----------|----------|
| [e.g., explicit "quick" request] | [skip/defer/abort] |
| [e.g., rate limit active] | [skip/defer/abort] |

---

## 3. Inputs

### Required Inputs
| Input | Source | Format | Purpose |
|-------|--------|--------|---------|
| [input name] | [file/MCP/event/context] | [JSON/MD/text] | [why needed] |

### Optional Inputs
| Input | Source | Default | Purpose |
|-------|--------|---------|---------|
| [input name] | [file/MCP/event/context] | [default value] | [why useful] |

### Context Requirements
[What context must be loaded before this component operates?]

- [ ] CLAUDE.md
- [ ] session-state.md
- [ ] current-priorities.md
- [ ] [other context files]

---

## 4. Outputs

### Primary Outputs
| Output | Destination | Format | Consumers |
|--------|-------------|--------|-----------|
| [output name] | [file/MCP/event] | [JSON/MD/text] | [who uses this] |

### Side Effects
| Effect | Description | Reversible |
|--------|-------------|------------|
| [e.g., file creation] | [what happens] | [Yes/No] |
| [e.g., MCP call] | [what happens] | [Yes/No] |
| [e.g., git commit] | [what happens] | [Yes/No] |

### State Changes
[What state files or Memory MCP entities are modified?]

| State | Location | Change Type |
|-------|----------|-------------|
| [state name] | [path or MCP entity] | [create/update/delete] |

---

## 5. Dependencies

### System Dependencies
| Dependency | Type | Failure Behavior |
|------------|------|------------------|
| [component name] | [hard/soft] | [abort/degrade/skip] |

- **Hard**: Component cannot function without this dependency
- **Soft**: Component can operate with reduced capability

### MCP Dependencies
| MCP Server | Tools Used | Required |
|------------|------------|----------|
| [server name] | [tool1, tool2] | [Yes/No] |

### File Dependencies
| File | Purpose | Create if Missing |
|------|---------|-------------------|
| [path] | [why needed] | [Yes/No] |

---

## 6. Consumers

### Downstream Systems
| Consumer | Relationship | Data Consumed |
|----------|--------------|---------------|
| [component name] | [triggers/reads/subscribes] | [what data] |

### User Visibility
| Aspect | Visible to User |
|--------|-----------------|
| Execution start | [Yes/No/Optional] |
| Progress updates | [Yes/No/Optional] |
| Completion notice | [Yes/No/Optional] |
| Error reports | [Yes/No/Optional] |

### Integration Points
[Where does this component connect with the broader Jarvis system?]

```
[ASCII diagram or bullet list showing integration]
```

---

## 7. Gates

### Approval Checkpoints
| Gate ID | Trigger | Risk Level | Auto-Approve |
|---------|---------|------------|--------------|
| [G-01] | [when checked] | [low/medium/high] | [Yes/No] |

### Risk Classification
| Action Type | Risk Level | Gate Requirement |
|-------------|------------|------------------|
| Read-only operations | Low | None |
| Jarvis-internal writes | Low | Auto-approve |
| Project code modifications | Medium | Queue for approval |
| External API calls | Medium | Queue for approval |
| Destructive operations | High | Explicit user consent |

### Gate Implementation
```
[Describe how gates are enforced]
- Approval queue location: [path or MCP]
- Notification mechanism: [how user is informed]
- Timeout behavior: [what happens if no response]
```

---

## 8. Metrics

### Performance Metrics
| Metric | Unit | Target | Alert Threshold |
|--------|------|--------|-----------------|
| Execution time | seconds | [target] | [threshold] |
| Token cost | tokens | [target] | [threshold] |
| Success rate | percentage | [target] | [threshold] |

### Business Metrics
| Metric | Description | Measurement |
|--------|-------------|-------------|
| [metric name] | [what it measures] | [how measured] |

### Storage
| Metric Type | Storage Location | Retention |
|-------------|------------------|-----------|
| Per-execution | [JSONL path or MCP] | [duration] |
| Aggregated | [path or MCP] | [duration] |

### Emission Format
```jsonl
{"timestamp": "ISO8601", "component": "AC-XX", "metric": "name", "value": N, "unit": "string"}
```

---

## 9. Failure Modes

### Known Failure Scenarios
| Failure | Cause | Detection | Recovery |
|---------|-------|-----------|----------|
| [failure name] | [what causes it] | [how detected] | [recovery action] |

### Graceful Degradation
[How does this component behave when it can't fully operate?]

| Degradation Level | Trigger | Behavior |
|-------------------|---------|----------|
| Partial | [condition] | [what happens] |
| Minimal | [condition] | [what happens] |
| Abort | [condition] | [what happens] |

### Error Reporting
| Error Type | Notification | Log Location |
|------------|--------------|--------------|
| Recoverable | [silent/log/user] | [path] |
| Non-recoverable | [silent/log/user] | [path] |

### Rollback Procedures
[If this component makes changes, how are they reversed if needed?]

1. [Step 1]
2. [Step 2]
3. [Step 3]

---

## Implementation Notes

### Current Implementation
[Link to actual implementation files, if they exist]

| Artifact | Path | Status |
|----------|------|--------|
| Main script | [path] | [exists/planned] |
| Hook integration | [path] | [exists/planned] |
| Pattern document | [path] | [exists/planned] |

### Open Questions
- [ ] [Question 1]
- [ ] [Question 2]

### Design Decisions Log
| Date | Decision | Rationale |
|------|----------|-----------|
| [date] | [what was decided] | [why] |

---

## Validation Checklist

Before marking this component as "active":

- [ ] All 9 specification sections completed
- [ ] Triggers tested and documented
- [ ] Inputs/outputs validated
- [ ] Dependencies verified available
- [ ] Gates implemented and tested
- [ ] Metrics emission working
- [ ] Failure modes tested
- [ ] Integration with consumers verified
- [ ] Documentation updated

---

*Autonomic Component Specification — Jarvis Phase 6*
