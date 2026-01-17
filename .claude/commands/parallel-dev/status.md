---
description: Show current orchestration progress with visual task tree
argument-hint: [execution-name]
allowed-tools:
  - Read
  - Bash
  - Glob
---

# Parallel-Dev: Status

Display overall parallel-dev status including worktrees, executions, and progress.

## Process

### 1. Check Initialization

```bash
REGISTRY=".claude/parallel-dev/registry.json"

if [ ! -f "$REGISTRY" ]; then
    echo "Parallel-dev not initialized"
    echo ""
    echo "Run: /parallel-dev:init"
    exit 0
fi
```

### 2. Get Current Context

```bash
PROJECT=$(jq -r '.project // "unknown"' "$REGISTRY")
```

### 3. Display Overview

```
===================================================================
 PARALLEL-DEV STATUS: $PROJECT
===================================================================
```

### 4. Worktrees Section

```bash
WORKTREE_COUNT=$(jq '.worktrees | length' "$REGISTRY")
ACTIVE_COUNT=$(jq '[.worktrees[] | select(.status == "active")] | length' "$REGISTRY")

echo "WORKTREES: $ACTIVE_COUNT active / $WORKTREE_COUNT total"
echo ""

if [ "$WORKTREE_COUNT" -gt 0 ]; then
    jq -r '.worktrees[] | "\(.branch) -> \(.worktreePath)"' "$REGISTRY"
else
    echo "  (none)"
fi
```

### 5. Executions Section

```bash
EXEC_DIR=".claude/parallel-dev/executions"
if [ -d "$EXEC_DIR" ]; then
    EXEC_COUNT=$(ls -d "$EXEC_DIR"/*/ 2>/dev/null | wc -l)
else
    EXEC_COUNT=0
fi

echo ""
echo "EXECUTIONS: $EXEC_COUNT"
echo ""

if [ "$EXEC_COUNT" -gt 0 ]; then
    for exec_path in "$EXEC_DIR"/*/; do
        if [ -f "$exec_path/state.yaml" ]; then
            EXEC_NAME=$(basename "$exec_path")
            EXEC_STATUS=$(grep "^status:" "$exec_path/state.yaml" | cut -d: -f2 | xargs)

            # Get progress
            TASKS_COMPLETE=$(grep "tasks_complete:" "$exec_path/state.yaml" | cut -d: -f2 | xargs)
            TASKS_TOTAL=$(grep "tasks_total:" "$exec_path/state.yaml" | cut -d: -f2 | xargs)

            if [ -n "$TASKS_TOTAL" ] && [ "$TASKS_TOTAL" -gt 0 ]; then
                PERCENT=$((TASKS_COMPLETE * 100 / TASKS_TOTAL))
                echo "  $EXEC_NAME [$EXEC_STATUS]"
                echo "     Progress: $TASKS_COMPLETE/$TASKS_TOTAL ($PERCENT%)"
            else
                echo "  $EXEC_NAME [$EXEC_STATUS]"
            fi
        fi
    done
else
    echo "  (none)"
fi
```

### 6. Plans Section

```bash
PLANS_DIR=".claude/parallel-dev/plans"
if [ -d "$PLANS_DIR" ]; then
    PLAN_COUNT=$(ls "$PLANS_DIR"/*.md 2>/dev/null | wc -l)
else
    PLAN_COUNT=0
fi

echo ""
echo "PLANS: $PLAN_COUNT"
echo ""

if [ "$PLAN_COUNT" -gt 0 ]; then
    for plan in "$PLANS_DIR"/*.md; do
        NAME=$(basename "$plan" .md)
        STATUS=$(grep -m1 "^status:" "$plan" 2>/dev/null | cut -d: -f2 | xargs)
        echo "  $NAME [$STATUS]"
    done
else
    echo "  (none)"
fi
```

### 7. Resource Usage

```bash
PORTS_ALLOCATED=$(jq '.portPool.allocated | length' "$REGISTRY")
PORTS_TOTAL=$((8199 - 8100 + 1))

echo ""
echo "RESOURCES"
echo "  Ports: $PORTS_ALLOCATED / $PORTS_TOTAL allocated"

if [ "$PORTS_ALLOCATED" -gt 0 ]; then
    PORTS=$(jq -r '.portPool.allocated | join(", ")' "$REGISTRY")
    echo "  In use: $PORTS"
fi
```

### 8. Quick Commands

```bash
echo ""
echo "==================================================================="
echo "QUICK COMMANDS"
echo ""
echo "  Worktrees:"
echo "    /parallel-dev:worktree-create <branch>  Create worktree"
echo "    /parallel-dev:worktree-list             List worktrees"
echo "    /parallel-dev:worktree-cleanup <slug>   Remove worktree"
echo ""
echo "  Planning:"
echo "    /parallel-dev:plan <name>               Start planning session"
echo "    /parallel-dev:plan-show <name>          View plan details"
echo "    /parallel-dev:plan-list                 List all plans"
echo "    /parallel-dev:plan-edit <name>          Edit plan"
echo ""
echo "  Tasks:"
echo "    /parallel-dev:decompose <name>          Break plan into tasks"
echo ""
echo "  Execution:"
echo "    /parallel-dev:start <name>              Start parallel execution"
echo "    /parallel-dev:pause <name>              Pause execution"
echo "    /parallel-dev:resume <name>             Resume execution"
echo ""
echo "  Validation & Merge:"
echo "    /parallel-dev:validate <name>           Run QA validation"
echo "    /parallel-dev:conflicts <name>          Check for merge conflicts"
echo "    /parallel-dev:merge <name>              Merge to main branch"
echo "==================================================================="
```

## Arguments

- `[execution-name]` - Show detailed status for specific execution
- `--json` - Output as JSON
- `--brief` - One-line summary only

## Brief Output (--brief)

```
parallel-dev: 2 worktrees, 0 executions, 1 plan | ports: 4/100
```
