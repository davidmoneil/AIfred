# Fresh Context Execution Pattern

**Status**: Active
**Created**: 2026-01-22
**Source**: snarktank/ralph (6.7k stars)
**Implementation**: `scripts/fresh-context-loop.sh`

## Overview

The Fresh Context Pattern solves **context pollution** in long Claude sessions by executing each task in a completely new Claude instance. Memory persists only through git commits and task file updates.

**Core Insight**: For autonomous "fire and forget" work, context from previous tasks often *hurts* more than it helps. Starting fresh ensures consistent, predictable behavior.

## When to Use

| Use Fresh Context | Use Normal Session |
|-------------------|-------------------|
| Many similar tasks | Building on previous reasoning |
| Long-running autonomy | Interactive guidance needed |
| Consistency matters | Context accumulation helps |
| Independent tasks | Tasks share state |
| Quality > speed | Speed > isolation |

## Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                    FRESH CONTEXT ARCHITECTURE                       │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌─────────────────┐                                                │
│  │  TASK SOURCE    │  Orchestration YAML or inline task list        │
│  │  (.yaml file)   │                                                │
│  └────────┬────────┘                                                │
│           │                                                         │
│           ▼                                                         │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │  LOOP CONTROLLER (fresh-context-loop.sh)                    │   │
│  │  - Read task list                                            │   │
│  │  - Find next pending task                                    │   │
│  │  - Spawn Claude instance                                     │   │
│  │  - Check completion                                          │   │
│  │  - Update task status                                        │   │
│  │  - Repeat or exit                                            │   │
│  └─────────────────────────────────────────────────────────────┘   │
│           │                                                         │
│           │ For each task:                                          │
│           ▼                                                         │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │  FRESH CLAUDE INSTANCE                                       │   │
│  │  - Receives ONLY this task's prompt                          │   │
│  │  - Has access to: codebase, CLAUDE.md, settings.json         │   │
│  │  - Does NOT have: previous task context, conversation        │   │
│  │  - Executes → Commits → Reports → Exits                      │   │
│  └─────────────────────────────────────────────────────────────┘   │
│           │                                                         │
│           ▼                                                         │
│  ┌─────────────────┐                                                │
│  │  PERSISTENCE    │  Git commits + YAML status updates             │
│  │  (git + files)  │  (This is how tasks "remember" each other)    │
│  └─────────────────┘                                                │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

## Key Components

### 1. Task Source

Standard orchestration YAML format:

```yaml
phases:
  - name: "Implementation"
    tasks:
      - id: "T1.1"
        description: "Add input validation to login form"
        done_criteria: "Tests pass, validation errors display"
        status: pending
        commits: []
```

Or inline tasks:

```bash
--tasks "Task 1 description|Task 2 description|Task 3 description"
```

### 2. Loop Controller

`scripts/fresh-context-loop.sh` manages the iteration:

1. Parse task source
2. Find first `pending` or `in_progress` task
3. Build task-specific prompt
4. Execute `claude -p "$prompt" --no-session-persistence`
5. Check result (COMPLETED / BLOCKED / FAILED)
6. Update task status
7. Loop until done or max iterations

### 3. Task Prompt Template

Each task receives a structured prompt:

```
FRESH CONTEXT EXECUTION MODE

You are executing a single task from a larger orchestration.
Focus ONLY on this task. After completion, commit your changes and exit.

## Your Task
<description>

## Done Criteria
<done_criteria>

## Instructions
1. Read any files needed to understand context
2. Implement the change
3. Verify it meets the done criteria
4. Commit with message format: "[fresh-context] <task-id> - <summary>"
5. Report completion status

## Important
- This is a FRESH context - you have no memory of previous tasks
- Do NOT try to do more than this one task
- On success, state "TASK COMPLETED"
- On failure/blocked, state "TASK BLOCKED: <reason>"
```

### 4. Persistence Layer

Memory between tasks persists ONLY via:

- **Git commits**: Each task commits its changes
- **Task file updates**: Status updated in YAML
- **Codebase state**: Previous tasks' changes are visible in files

This is intentionally minimal - tasks should be self-contained.

## Configuration

| Parameter | Default | Description |
|-----------|---------|-------------|
| `max_iterations` | 10 | Maximum loop cycles |
| `max_turns` | 15 | Claude turns per task |
| `fail_threshold` | 3 | Skip after N failures |
| `max_budget` | $5.00 | Per-task cost limit |

## Task Design Guidelines

### Good Tasks for Fresh Context

```yaml
# Self-contained, clear criteria
- id: "T1.1"
  description: "Add email validation regex to registration form"
  done_criteria: "Invalid emails show error, valid emails accepted"

# Testable, atomic
- id: "T2.1"
  description: "Write unit tests for UserService.create()"
  done_criteria: "Tests cover happy path and 3 error cases"
```

### Bad Tasks for Fresh Context

```yaml
# Requires previous context
- description: "Continue implementing the auth system"
  # Bad: What was done before? Where did we leave off?

# Too vague
- description: "Improve the codebase"
  # Bad: No clear done criteria, too broad

# Depends on conversation state
- description: "Apply the changes we discussed"
  # Bad: Fresh context has no conversation history
```

## Error Handling

| Outcome | Behavior |
|---------|----------|
| COMPLETED | Mark done, record commit, next task |
| BLOCKED | Mark blocked, skip, next task |
| FAILED (1-2x) | Retry on next iteration |
| FAILED (3x) | Mark failed, skip, next task |
| Max iterations | Exit with warning |

## Integration Points

| System | Integration |
|--------|-------------|
| **Orchestration** | Uses orchestration YAML as task source |
| **Parallel-Dev** | Can run in worktrees for isolation |
| **Git** | Each task creates a commit (rollback points) |
| **Autonomous Execution** | Shares patterns with scheduled Claude execution |

## Comparison: Fresh vs Accumulated Context

```
FRESH CONTEXT                    ACCUMULATED CONTEXT
┌──────────────┐                 ┌──────────────┐
│   Task 1     │                 │   Task 1     │
│ [Context: A] │                 │ [Context: A] │
└──────────────┘                 └──────┬───────┘
       ↓                                │
┌──────────────┐                 ┌──────▼───────┐
│   Task 2     │                 │   Task 2     │
│ [Context: B] │ ← Fresh         │ [Context: AB]│ ← Accumulated
└──────────────┘                 └──────┬───────┘
       ↓                                │
┌──────────────┐                 ┌──────▼───────┐
│   Task 3     │                 │   Task 3     │
│ [Context: C] │ ← Fresh         │[Context: ABC]│ ← Growing
└──────────────┘                 └──────────────┘

Pros:                            Pros:
- Consistent behavior            - Builds on reasoning
- No pollution                   - Faster (no restart)
- Easy rollback                  - Can reference prior work
- Predictable cost               - Interactive guidance

Cons:                            Cons:
- Startup overhead               - Context pollution
- Can't reference prior          - Inconsistent behavior
- Only file-based memory         - Harder to rollback
```

## Best Practices

1. **Design atomic tasks**: Each task should be completable in isolation
2. **Clear done criteria**: Claude needs to know when to stop
3. **Commit-friendly changes**: Tasks should produce committable units
4. **Test before running**: Use `--dry-run` to preview
5. **Monitor progress**: Check YAML file for status updates
6. **Review commits**: Each task's commit shows what changed

## Related

- @.claude/orchestration/README.md - Task decomposition
- @.claude/context/patterns/autonomous-execution-pattern.md - Scheduled execution
- @scripts/fresh-context-loop.sh - Implementation
