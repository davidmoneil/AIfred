---
argument-hint: "<task-description>"
description: Decompose a complex task into phases and atomic subtasks with dependencies
allowed-tools:
  - Read
  - Write
  - Glob
  - Grep
  - TodoWrite
  - mcp__mcp-gateway__create_entities
  - mcp__mcp-gateway__create_relations
  - mcp__mcp-gateway__search_nodes
model: sonnet
---

# Task Orchestration: Plan

Decompose a complex task into manageable phases and atomic subtasks.

## When This Runs

- **Manual**: User runs `/orchestration:plan "task description"`
- **Suggested**: Hook detected moderate complexity (score 4-8), user confirmed
- **Automatic**: Hook detected high complexity (score >= 9)

## Process

### 1. Understand the Task

Read and analyze:
- The task description provided as argument
- `current-priorities.md` for related priorities
- `session-state.md` for any existing context
- Similar past orchestrations in `.claude/orchestration/archive/`

### 2. Check for Existing Patterns

Search Memory MCP for similar task patterns:
```
search_nodes("TaskPattern:")
```

If found, use as starting template and adapt.

### 3. Decompose into Phases

Break the task into 2-5 phases:
- Each phase is a logical grouping of work
- Phases should be completable in 1-3 sessions
- Later phases can be blocked by earlier ones
- Name phases descriptively: "Phase 1: Foundation", "Phase 2: Core Implementation"

### 4. Create Atomic Tasks

For each phase, create tasks:
- Each task: 1-4 hours of focused work
- Must have clear "done" criteria (testable/verifiable)
- Include dependencies on other tasks
- Use hierarchical IDs: T1.1, T1.2, T2.1, etc.

### 5. Create Orchestration File

Generate YAML file at `.claude/orchestration/YYYY-MM-DD-<slug>.yaml`:

```yaml
name: "Descriptive Task Name"
created: "2026-01-03"
priority_link: "current-priorities.md#<anchor>"
status: active
complexity_score: <score from hook or 0 if manual>
trigger_mode: <manual|suggested|automatic>

summary: |
  Brief description of goal and approach.

phases:
  - name: "Phase 1: Foundation"
    status: pending
    blocked_by: null
    tasks:
      - id: "T1.1"
        description: "Clear task description"
        done_criteria: "Specific acceptance criteria"
        estimated_hours: 2
        status: pending
        depends_on: []
        commits: []
        notes: ""
```

### 6. Calculate Totals

Sum `estimated_hours` across all tasks and set in `metadata.total_estimated_hours`.

### 7. Store Pattern (if novel)

If this task type hasn't been seen before, store in Memory MCP:

```javascript
create_entities([{
  name: "TaskPattern: <type>",
  entityType: "TaskPattern",
  observations: [
    "created_at: <timestamp>",
    "phases: <phase structure>",
    "typical_hours: <total>",
    "key_tasks: <common tasks>"
  ]
}]);
```

### 8. Update Session State

Add to `session-state.md`:
```markdown
**Current Orchestration**: <name>
**File**: `.claude/orchestration/<filename>.yaml`
**Progress**: 0% (0/<total> tasks)
```

### 9. Create Initial Todos

Use TodoWrite to create entries for Phase 1 tasks.

### 10. Display Task Tree

Show the created structure:

```
📋 <Task Name> (0% complete)
├── ⏳ Phase 1: Foundation
│   ├── ⏳ T1.1: <description> (2h)
│   └── ⏳ T1.2: <description> (1h)
├── 🔒 Phase 2: Implementation (blocked by Phase 1)
│   └── ⏳ T2.1: <description> (3h)
└── 🔒 Phase 3: Testing (blocked by Phase 2)
    └── ⏳ T3.1: <description> (2h)

Total estimated: Xh across Y tasks
Next available: T1.1 (<description>)
```

## Output

After completion, display:
1. Task tree (as above)
2. File location
3. First task to work on
4. Suggestion to begin: "Run `/orchestration:status` anytime to check progress"
