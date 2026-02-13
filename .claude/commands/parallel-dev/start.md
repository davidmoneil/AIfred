---
description: Begin autonomous execution of a decomposed plan
argument-hint: <plan-name>
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
  - Task
model: opus
---

# Parallel-Dev: Start Execution

Begin autonomous parallel execution of a decomposed plan. This command coordinates multiple agents working on tasks simultaneously.

## Arguments

- `<plan-name>` - Name of the decomposed plan to execute

## Prerequisites

- Plan must exist at `.claude/parallel-dev/plans/{plan-name}.md`
- Tasks file must exist at `.claude/parallel-dev/plans/{plan-name}-tasks.yaml`
- Plan status should be `decomposed` (warning if not)

## Process

### 1. Validate Prerequisites

```bash
PLAN_NAME="$ARGUMENTS"
PLAN_SLUG=$(echo "$PLAN_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')
PLAN_FILE=".claude/parallel-dev/plans/${PLAN_SLUG}.md"
TASKS_FILE=".claude/parallel-dev/plans/${PLAN_SLUG}-tasks.yaml"
EXEC_DIR=".claude/parallel-dev/executions/${PLAN_SLUG}"

# Check plan exists
if [ ! -f "$PLAN_FILE" ]; then
    echo "Plan not found: $PLAN_NAME"
    echo "Run: /parallel-dev:plan $PLAN_NAME"
    exit 1
fi

# Check tasks file exists
if [ ! -f "$TASKS_FILE" ]; then
    echo "Tasks not found for: $PLAN_NAME"
    echo "Run: /parallel-dev:decompose $PLAN_NAME"
    exit 1
fi

# Check if already executing
if [ -d "$EXEC_DIR" ]; then
    STATUS=$(grep "^status:" "$EXEC_DIR/state.yaml" 2>/dev/null | cut -d: -f2 | xargs)
    if [ "$STATUS" = "executing" ]; then
        echo "Execution already in progress"
        echo "Run: /parallel-dev:status $PLAN_NAME"
        exit 1
    fi
fi
```

### 2. Load Configuration

```bash
CONFIG_FILE=".claude/skills/parallel-dev/config.json"
WORKTREE_BASE=$(jq -r '.worktreeBase // "~/tmp/worktrees"' "$CONFIG_FILE" 2>/dev/null || echo "~/tmp/worktrees")
WORKTREE_BASE="${WORKTREE_BASE/#\~/$HOME}"
MAX_AGENTS=$(jq -r '.maxParallelAgents // 3' "$CONFIG_FILE" 2>/dev/null || echo "3")
```

### 3. Create Worktree

```bash
PROJECT=$(basename $(pwd))
BRANCH="feature/${PLAN_SLUG}"
WORKTREE_PATH="$WORKTREE_BASE/$PROJECT/${PLAN_SLUG}"

# Use worktree-create logic
git worktree add -b "$BRANCH" "$WORKTREE_PATH" 2>/dev/null || \
git worktree add "$WORKTREE_PATH" "$BRANCH"

echo "Worktree created: $WORKTREE_PATH"
```

### 4. Initialize Execution State

Create execution directory and state file:

```bash
mkdir -p "$EXEC_DIR"
TIMESTAMP=$(date -Iseconds)
```

Initialize `state.yaml` from template with:
- Plan and tasks file references
- Worktree path and branch
- Initial progress counts from tasks file
- Status: `executing`

### 5. Calculate Ready Tasks

Parse tasks file to find tasks with no unmet dependencies:

```
ready_tasks = []
for task in all_tasks:
    if task.status == "pending":
        deps_met = all(
            get_task(dep_id).status == "completed"
            for dep_id in task.depends_on
        )
        if deps_met:
            ready_tasks.append(task)
```

### 6. Execution Loop

The coordinator runs in a loop:

```
while execution.status == "executing":
    1. Get list of ready tasks (dependencies met)
    2. Get available agent slots (max_parallel - active_agents)
    3. For each available slot and ready task:
       - Spawn agent via Task tool
       - Record assignment in state
       - Mark task as in_progress
    4. Check for completed agents
       - Update task status
       - Record commits
       - Update progress
    5. Check for phase completion
       - If all phase tasks done, move to next phase
    6. Check for blockers
       - If agent reports blocked, pause and notify
    7. Check for completion
       - If all tasks done, mark execution complete
    8. Brief pause before next iteration
```

### 7. Spawn Agents

For each ready task, spawn appropriate agent:

**Agent Type Selection**:

| Task Stream | Agent Type |
|-------------|------------|
| database | parallel-dev:implementer |
| api | parallel-dev:implementer |
| frontend | parallel-dev:implementer |
| tests | parallel-dev:tester |
| docs | parallel-dev:documenter |
| infra | parallel-dev:implementer |

### 8. Progress Display

Show live progress:

```
===================================================================
 EXECUTING: {plan-name}
===================================================================

Progress: 45% (9/20 tasks)

Active Agents (3/3):
  Agent-1: T2.3 - Password reset flow [database]
  Agent-2: T2.4 - Email verification [api]
  Agent-3: T2.5 - Login form component [frontend]

Ready Queue (2 tasks):
  T2.6 - Product listing API
  T2.7 - Cart logic

Recent Activity:
  14:32 T2.2 completed (commit abc1234)
  14:28 Agent-2 started T2.4
  14:15 T2.1 completed (commit def5678)

-------------------------------------------------------------------
Press Ctrl+C to pause execution
===================================================================
```

### 9. Handle Agent Completion

When an agent completes:

1. Parse agent's output (YAML format)
2. Update task status in tasks file
3. Record commits
4. Check acceptance criteria
5. Release agent slot
6. Recalculate ready tasks
7. Log event

### 10. Completion

When all tasks complete:

```bash
# Update execution state (portable: temp file + mv)
tmp=$(mktemp); sed 's/^status:.*/status: completed/' "$EXEC_DIR/state.yaml" > "$tmp" && mv "$tmp" "$EXEC_DIR/state.yaml"
echo "completed_at: $(date -Iseconds)" >> "$EXEC_DIR/state.yaml"

# Update plan status
tmp=$(mktemp); sed 's/^status:.*/status: completed/' "$PLAN_FILE" > "$tmp" && mv "$tmp" "$PLAN_FILE"
```

Display completion summary:

```
===================================================================
 EXECUTION COMPLETE: {plan-name}
===================================================================

Final Stats:
  Tasks completed: 20/20 (100%)
  Total commits: 15
  Execution time: 2h 34m

Worktree: {worktree-path}

Next Steps:
  1. Review changes: cd {worktree} && git log --oneline
  2. Run validation: /parallel-dev:validate {plan-name}
  3. Merge when ready: /parallel-dev:merge {plan-name}

===================================================================
```

## Configuration

From `.claude/skills/parallel-dev/config.json`:

| Setting | Default | Description |
|---------|---------|-------------|
| maxParallelAgents | 5 | Maximum concurrent agents |
| agentModel | sonnet | Model for implementation agents |
| staleThresholdMinutes | 30 | When to check on stale agents |

## Agent Coordination Rules

1. **No context pollution**: Agents work independently, report back concisely
2. **Dependency respect**: Never start a task before dependencies complete
3. **Stream awareness**: Prefer parallel tasks from different streams
4. **Error isolation**: One agent's failure doesn't crash others
5. **Progress persistence**: State survives session interruption

## Output

Creates:
- `.claude/parallel-dev/executions/{plan-name}/state.yaml` - Execution state
- `.claude/parallel-dev/executions/{plan-name}/log.jsonl` - Event log
- Git worktree at `{worktreeBase}/{project}/{plan-name}/`
- Feature branch `feature/{plan-name}`

Updates:
- Plan status to `executing` then `completed`
- Task statuses in tasks file
- Registry with execution reference

## Interruption Handling

If execution is interrupted (Ctrl+C, session end):
- State is preserved in `state.yaml`
- Resume with `/parallel-dev:resume {plan-name}`
- Active agent work may be lost (will be reassigned)

## Related Commands

- `/parallel-dev:status <name>` - View execution progress
- `/parallel-dev:pause <name>` - Pause execution
- `/parallel-dev:resume <name>` - Resume paused execution
- `/parallel-dev:validate <name>` - Run QA validation
