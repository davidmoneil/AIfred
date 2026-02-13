---
description: Resume work on an orchestration after a session break
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

# Parallel-Dev: Resume Execution

Resume a paused execution, continuing from where it left off.

## Arguments

- `<plan-name>` - Name of the paused plan to resume

## Process

### 1. Validate and Load State

```bash
PLAN_NAME="$ARGUMENTS"
PLAN_SLUG=$(echo "$PLAN_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')
EXEC_DIR=".claude/parallel-dev/executions/${PLAN_SLUG}"
STATE_FILE="$EXEC_DIR/state.yaml"
TASKS_FILE=".claude/parallel-dev/plans/${PLAN_SLUG}-tasks.yaml"

if [ ! -f "$STATE_FILE" ]; then
    echo "No execution found for: $PLAN_NAME"
    echo ""
    echo "To start fresh: /parallel-dev:start $PLAN_NAME"
    exit 1
fi

STATUS=$(grep "^status:" "$STATE_FILE" | cut -d: -f2 | xargs)
```

### 2. Check Resumable Status

```bash
case "$STATUS" in
    paused)
        echo "Resuming paused execution..."
        ;;
    executing)
        echo "Execution appears to be running"
        echo "Check status: /parallel-dev:status $PLAN_NAME"
        exit 1
        ;;
    completed)
        echo "Execution already completed"
        echo "To re-run: First delete execution directory"
        exit 0
        ;;
    failed|abandoned)
        echo "Execution was $STATUS"
        echo "Review errors and decide:"
        echo "  1. Fix issues and resume"
        echo "  2. Abandon and start fresh"
        # Allow resume after confirmation
        ;;
esac
```

### 3. Restore Context

Read execution state to understand:
- Current progress
- Active phase
- Completed tasks
- Any recorded errors
- Worktree location

### 4. Verify Worktree

```bash
WORKTREE=$(grep "worktree:" "$STATE_FILE" | head -1 | cut -d: -f2 | xargs)

if [ ! -d "$WORKTREE" ]; then
    echo "Worktree not found: $WORKTREE"
    echo "Recreating..."
    # Recreate worktree from branch
fi

# Verify branch exists
BRANCH=$(grep "branch:" "$STATE_FILE" | head -1 | cut -d: -f2 | xargs)
git branch --list "$BRANCH" > /dev/null || {
    echo "Branch not found: $BRANCH"
    exit 1
}
```

### 5. Reconcile State

Check for any orphaned work from before pause:

```bash
# Check if any tasks were marked in_progress but agents are gone
IN_PROGRESS=$(grep -c "status: in_progress" "$TASKS_FILE" || echo "0")

if [ "$IN_PROGRESS" -gt 0 ]; then
    echo "Found $IN_PROGRESS tasks marked in_progress"
    echo "These may have been interrupted. Options:"
    echo "  1. Reset to pending (recommended)"
    echo "  2. Keep as in_progress (if work was saved)"
fi
```

### 6. Reset Interrupted Tasks

For tasks marked `in_progress` without active agents:
- Check if any commits exist for the task
- If yes: May be partially complete, review needed
- If no: Reset to `pending` for reassignment

### 7. Update State

```bash
TIMESTAMP=$(date -Iseconds)

# Update status (portable: temp file + mv)
tmp=$(mktemp); sed 's/^status:.*/status: executing/' "$STATE_FILE" > "$tmp" && mv "$tmp" "$STATE_FILE"

# Add resume timestamp
tmp=$(mktemp); sed "s/resumed_at:.*/resumed_at: $TIMESTAMP/" "$STATE_FILE" > "$tmp" && mv "$tmp" "$STATE_FILE"

# Log event
echo "- timestamp: $TIMESTAMP" >> "$EXEC_DIR/log.jsonl"
echo "  event: resumed" >> "$EXEC_DIR/log.jsonl"
```

### 8. Display Resume Summary

```
===================================================================
 RESUMING EXECUTION: {plan-name}
===================================================================

Progress: 45% (9/20 tasks)
Paused for: 2h 15m

Current Phase: Phase 2 - Core Implementation
  Completed: 4/8 tasks
  Ready to start: 2 tasks
  Blocked: 2 tasks

Worktree: {worktree-path}
Branch: feature/auth-system

-------------------------------------------------------------------

Resuming execution loop...

Ready tasks:
  T2.5 - OAuth providers
  T2.6 - Session management

Spawning agents...
  Agent-1 starting T2.5
  Agent-2 starting T2.6

===================================================================
```

### 9. Continue Execution Loop

Resume the same execution loop as `/parallel-dev:start`:
1. Get ready tasks
2. Spawn agents
3. Track progress
4. Handle completions
5. Continue until done or paused

## Resume After Errors

If resuming after a failed task:

1. **Review the error**: Check `state.yaml` errors section
2. **Fix if possible**: Manual intervention in worktree
3. **Reset task status**: Edit tasks file to set `pending`
4. **Resume**: This command will pick up the fixed task

## Context Recovery

When resuming in a new session:
- Read plan file for overall vision
- Read tasks file for current state
- Read state.yaml for execution context
- No need to re-ask questions (all captured in plan)

## Output

Updates:
- `state.yaml` status to `executing`
- Adds resume timestamp
- Logs resume event

Creates:
- New agent assignments for ready tasks

## Related Commands

- `/parallel-dev:status <name>` - View detailed progress
- `/parallel-dev:pause <name>` - Pause again if needed
