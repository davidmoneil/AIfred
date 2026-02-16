# Memory MCP Storage Pattern

**Last Updated**: 2026-01-03
**Status**: Active

## Overview

This document extracts the **Memory MCP storage decision pattern** used across slash commands. This pattern determines when to store findings in the knowledge graph vs. just reporting them.

---

## Temporal Tracking

All Memory MCP entities should include timestamps for lifecycle tracking and stale detection.

### Required Timestamps

| Field | Format | Purpose |
|-------|--------|---------|
| `created_at` | ISO 8601 | When entity was first created |
| `updated_at` | ISO 8601 | When content was last modified |

### Why Timestamps Matter

The `memory-maintenance.js` hook tracks **access patterns** (when we read/search entities), but that's different from **content timestamps** (when entity content was created/modified).

| What | Hook Tracks | Observation Timestamps |
|------|-------------|----------------------|
| When first seen | `first_seen` (hook metadata) | `created_at` (in observations) |
| When last used | `last_accessed` (hook metadata) | - |
| When content changed | - | `updated_at` (in observations) |

Together, these enable:
- **Stale detection**: Old `updated_at` + not accessed = truly stale
- **Change tracking**: Compare `updated_at` across related entities
- **Temporal queries**: "What decisions were made this month?"

### Storage Pattern with Timestamps

```javascript
// When CREATING entities
await mcp__mcp_gateway__create_entities({
  entities: [{
    name: "Decision: Use PostgreSQL for auth",
    entityType: "Decision",
    observations: [
      "created_at: 2026-01-03T14:30:00Z",
      "updated_at: 2026-01-03T14:30:00Z",
      "Chose PostgreSQL over SQLite for concurrent access",
      "Trade-off: More complexity, better scalability"
    ]
  }]
});

// When UPDATING entities (adding observations)
await mcp__mcp_gateway__add_observations({
  observations: [{
    entityName: "Decision: Use PostgreSQL for auth",
    contents: [
      "updated_at: 2026-01-03T16:45:00Z",
      "Added: Connection pooling configuration"
    ]
  }]
});
```

### Timestamp Conventions

1. **Always use ISO 8601 format**: `YYYY-MM-DDTHH:mm:ssZ`
2. **created_at is immutable**: Set once, never change
3. **updated_at changes with content**: Update whenever adding observations
4. **Use UTC (Z suffix)**: Avoids timezone confusion

### Query Patterns

**Find recent decisions** (last 30 days):
```
Search for observations containing "updated_at: 2026-01"
Then filter results for Decision entities
```

**Find stale entities** (for archival):
```
Compare memory-maintenance.js metadata (last_accessed)
with observation timestamps (updated_at)
If both are old (>90 days), entity is truly stale
```

**Change tracking**:
```
Search for "updated_at: 2026-01-03" to find all entities
modified on a specific date
```

### Integration with memory-maintenance.js

The hook stores access metadata in `.claude/agents/memory/entity-metadata.json`:

```json
{
  "entities": {
    "Decision: Use PostgreSQL": {
      "first_seen": "2026-01-03T14:30:00Z",    // Hook tracking
      "last_accessed": "2026-01-03T16:45:00Z", // Hook tracking
      "access_count": 5,
      "access_types": { "read": 3, "update": 2 }
    }
  }
}
```

Combined with observation timestamps:
- **Active entity**: Recent `last_accessed` (hook) + recent `updated_at` (observation)
- **Read-only entity**: Recent `last_accessed` + old `updated_at` (referenced but not changed)
- **Stale entity**: Old `last_accessed` + old `updated_at` (prune candidate)

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
```
Entity: "[Type]: [Name]"
Properties:
  - date: YYYY-MM-DD
  - [key properties]
Relationships:
  - [relationship] -> [related entity]
```

**Example - Healthy [X]** (no storage):
[Brief description of when NOT to store]

**Example - [X] with Issues** (store):
[Code block showing what to store]
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

All entity types below include required temporal fields (`created_at`, `updated_at`).

### Issue Entities

```
Entity: "Issue: [Service] [Problem]"
Observations:
  - created_at: YYYY-MM-DDTHH:mm:ssZ
  - updated_at: YYYY-MM-DDTHH:mm:ssZ
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
Observations:
  - created_at: YYYY-MM-DDTHH:mm:ssZ
  - updated_at: YYYY-MM-DDTHH:mm:ssZ
  - problem: "What went wrong"
  - solution: "How to fix it"
  - pattern: "General rule to follow"
Relationships:
  - applies_to -> [Service/Tool]
```

### Decision Entities

```
Entity: "Decision: [Topic]"
Observations:
  - created_at: YYYY-MM-DDTHH:mm:ssZ
  - updated_at: YYYY-MM-DDTHH:mm:ssZ
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
Observations:
  - created_at: YYYY-MM-DDTHH:mm:ssZ
  - updated_at: YYYY-MM-DDTHH:mm:ssZ
  - action: "What happened"
  - reason: "Why it happened"
  - location: "Where (if applicable)"
Relationships:
  - affected -> [Systems]
```

---

## Implementation Examples

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

**Example - Healthy n8n** (no storage):
> n8n is running healthy with normal resource usage.
> No Memory MCP storage needed.

**Example - n8n with Issues** (store):
```
Entity: "Issue: n8n OOM Crash"
Observations:
  - created_at: 2025-12-31T10:30:00Z
  - updated_at: 2025-12-31T11:45:00Z
  - symptom: "Container killed with exit code 137"
  - root_cause: "Memory limit exceeded during workflow"
  - resolution: "Increased memory limit to 2GB"
  - status: resolved
Relationships:
  - affects -> n8n
```
```

### /discover-docker Pattern

```markdown
## Memory MCP Storage

**Store**:
- New container and its network relationships
- Dependencies on other services
- Non-obvious configuration choices

**Storage Pattern**:
```
Entity: "[container-name]"
Observations:
  - created_at: YYYY-MM-DDTHH:mm:ssZ
  - updated_at: YYYY-MM-DDTHH:mm:ssZ
  - image: [image:tag]
  - ports: [exposed ports]
  - status: running | stopped
Relationships:
  - uses_network -> [network-name]
  - depends_on -> [other-container]
  - stores_data_in -> [volume/path]
```
```

---

## Commands Using This Pattern

The following slash commands implement Memory MCP storage:

| Command | Stores When |
|---------|-------------|
| `/check-service` | Issues found |
| `/discover-docker` | New container documented |
| `/ssh-connect` | Connection issues or alerts |
| `/check-health` | Failures or critical warnings |
| `/check-gateway` | Gateway issues |
| `/code` | New patterns learned |

---

## Integration with Workflow Template

The workflow template (`_template-workflow.md`) includes this pattern in lines 158-206. New workflows should follow this template.

---

## Related Documentation

- @.claude/context/integrations/memory-mcp-usage.md - Comprehensive Memory guidelines
- @.claude/context/workflows/_template-workflow.md - Workflow template with pattern
- @knowledge/reference/mcp/memory-mcp.md - Memory MCP technical reference

---

**Maintained by**: Claude Code
