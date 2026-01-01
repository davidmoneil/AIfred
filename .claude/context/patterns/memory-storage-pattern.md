# Memory MCP Storage Pattern

**Last Updated**: 2026-01-01
**Status**: Active

## Overview

This document defines the **Memory MCP storage decision pattern** - when to store findings in the knowledge graph vs. just reporting them.

---

## The Pattern

### Template Structure

Every command that may store to Memory MCP should include this section:

```markdown
## Memory MCP Storage (When Issues Found)

**Only store in Memory MCP if**:
- [Condition 1 - e.g., "Issues or anomalies detected"]
- [Condition 2 - e.g., "New patterns discovered"]
- [Condition 3 - e.g., "Resolution of problems"]

**Do NOT store if**:
- [Condition - e.g., "Routine healthy state"]
- [Condition - e.g., "Information already documented"]

**Storage Pattern**:
Entity: "[Type]: [Name]"
Properties:
  - date: YYYY-MM-DD
  - [key properties]
Relationships:
  - [relationship] -> [related entity]
```

---

## Decision Matrix

### When to Store

| Scenario | Store? | Entity Type | Example |
|----------|--------|-------------|---------|
| Service down or failing | YES | `Issue: [Name]` | Container crash with logs |
| New dependency discovered | YES | Relationship | postgres-mcp → depends_on → n8n |
| Configuration that solved a problem | YES | `Lesson: [Topic]` | URL encoding fix |
| Major infrastructure decision | YES | `Decision: [Topic]` | Chose Option 3 for security |
| Significant state change | YES | `Event: [Name]` | Archon stack archived |

### When NOT to Store

| Scenario | Why Not |
|----------|---------|
| Healthy routine check | Noise - clutters memory |
| Information already in docs | Duplication - maintain in one place |
| Temporary states | Transient - will be outdated |
| Obvious facts | Self-evident - adds no value |
| Secrets/credentials | Security risk |

---

## Entity Types Reference

### Issue Entities

```
Entity: "Issue: [Service] [Problem]"
Properties:
  - date: YYYY-MM-DD
  - symptom: "What was observed"
  - root_cause: "Why it happened" (if known)
  - resolution: "How it was fixed" (if resolved)
  - status: open | investigating | resolved
Relationships:
  - affects -> [Service Entity]
  - resolved_on -> YYYY-MM-DD (if resolved)
```

### Lesson Entities

```
Entity: "Lesson: [Topic]"
Properties:
  - date: YYYY-MM-DD
  - problem: "What went wrong"
  - solution: "How to fix it"
  - pattern: "General rule to follow"
Relationships:
  - applies_to -> [Service/Tool]
```

### Decision Entities

```
Entity: "Decision: [Topic]"
Properties:
  - date: YYYY-MM-DD
  - chosen: "What was selected"
  - rejected: "What was not selected"
  - reasoning: "Why this choice"
Relationships:
  - impacts -> [Affected Systems]
  - documented_in -> [File Path]
```

### Event Entities

```
Entity: "Event: [Name]"
Properties:
  - date: YYYY-MM-DD
  - action: "What happened"
  - reason: "Why it happened"
  - location: "Where (if applicable)"
Relationships:
  - affected -> [Systems]
```

---

## Implementation Example

### /check-service Pattern

```markdown
## Memory MCP Storage (When Issues Found)

**Only store if**:
- Container is unhealthy or stopped unexpectedly
- Persistent errors found in logs
- Resource issues (memory/CPU) detected

**Do NOT store if**:
- Service is healthy and running normally
- Expected maintenance downtime

**Example - Healthy service** (no storage):
> Service is running healthy with normal resource usage.
> No Memory MCP storage needed.

**Example - Service with Issues** (store):
Entity: "Issue: n8n OOM Crash"
Properties:
  - date: 2026-01-01
  - symptom: "Container killed with exit code 137"
  - root_cause: "Memory limit exceeded during workflow"
  - resolution: "Increased memory limit to 2GB"
Relationships:
  - affects -> n8n
  - resolved_on -> 2026-01-01
```

---

## Related Documentation

- @.claude/context/integrations/memory-usage.md - Comprehensive Memory guidelines

---

**Maintained by**: Claude Code
