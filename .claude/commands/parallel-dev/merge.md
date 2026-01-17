---
description: Merge completed work to main branch
argument-hint: <plan-name> [--resolve] [--no-cleanup]
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

# Parallel-Dev: Merge

Merge completed and validated work back to the main branch with optional conflict resolution and automatic cleanup.

## Arguments

- `<plan-name>` - Name of the plan to merge
- `--resolve` - Attempt AI-assisted conflict resolution
- `--no-cleanup` - Keep worktree after merge (default: cleanup)
- `--squash` - Squash all commits into one
- `--no-push` - Don't push to remote after merge

## Prerequisites

- Execution must be `completed` or have passed validation
- Validation should have passed (warning if not)
- Clean working directory in worktree

## Process

### 1. Validate Prerequisites

```bash
PLAN_NAME="$ARGUMENTS"
PLAN_SLUG=$(echo "$PLAN_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')
EXEC_DIR=".claude/parallel-dev/executions/${PLAN_SLUG}"
STATE_FILE="$EXEC_DIR/state.yaml"
PLAN_FILE=".claude/parallel-dev/plans/${PLAN_SLUG}.md"

if [ ! -f "$STATE_FILE" ]; then
    echo "No execution found for: $PLAN_NAME"
    exit 1
fi

# Check execution status
EXEC_STATUS=$(grep "^status:" "$STATE_FILE" | cut -d: -f2 | xargs)
if [ "$EXEC_STATUS" != "completed" ] && [ "$EXEC_STATUS" != "paused" ]; then
    echo "Execution status is '$EXEC_STATUS'"
    echo "Recommend completing execution first"
fi

# Check validation
VALIDATED=$(grep "validation_passed:" "$STATE_FILE" | cut -d: -f2 | xargs)
if [ "$VALIDATED" != "true" ]; then
    echo "Validation not passed"
    echo "Run: /parallel-dev:validate $PLAN_NAME"
    echo ""
    echo "Continue anyway? (may have quality issues)"
fi

WORKTREE=$(grep "worktree:" "$STATE_FILE" | head -1 | cut -d: -f2- | xargs)
BRANCH=$(grep "branch:" "$STATE_FILE" | head -1 | cut -d: -f2 | xargs)
BASE_BRANCH=$(grep "base_branch:" "$STATE_FILE" | head -1 | cut -d: -f2 | xargs)
BASE_BRANCH=${BASE_BRANCH:-main}
```

### 2. Pre-Merge Check

```bash
cd "$WORKTREE"

# Ensure clean working directory
if [ -n "$(git status --porcelain)" ]; then
    echo "Uncommitted changes in worktree"
    echo "Please commit or stash changes first"
    exit 1
fi

# Fetch latest
git fetch origin "$BASE_BRANCH"
```

### 3. Check for Conflicts

```bash
echo "Checking for conflicts..."

# Try merge without committing
git merge --no-commit --no-ff "origin/$BASE_BRANCH" 2>&1
MERGE_EXIT=$?

if [ $MERGE_EXIT -ne 0 ]; then
    git merge --abort
    echo "Conflicts detected"

    if [ "$RESOLVE_FLAG" = "true" ]; then
        echo "Attempting AI-assisted resolution..."
    else
        echo "Run: /parallel-dev:conflicts $PLAN_NAME"
        echo "Or: /parallel-dev:merge $PLAN_NAME --resolve"
        exit 1
    fi
else
    git merge --abort
    echo "No conflicts - clean merge possible"
fi
```

### 4. AI-Assisted Conflict Resolution (--resolve)

If conflicts exist and `--resolve` flag provided:

Spawn a Task agent to:
1. Read each conflicting file
2. Understand the intent of both changes
3. Propose a merged solution
4. Apply the resolution
5. Stage the resolved files

Resolution strategy:
- **Additive changes**: Keep both additions
- **Modified same lines**: Analyze intent, propose merge
- **Version conflicts**: Use newer/compatible version
- **Incompatible changes**: Flag for manual review

### 5. Perform Merge

#### Standard Merge

```bash
cd "$(git rev-parse --show-toplevel)"  # Back to main repo

echo "Merging $BRANCH into $BASE_BRANCH..."

git checkout "$BASE_BRANCH"
git pull origin "$BASE_BRANCH"
git merge --no-ff "$BRANCH" -m "Merge $BRANCH: $PLAN_NAME

Parallel-dev execution completed.
Tasks: $(grep -c 'status: completed' "$TASKS_FILE") completed
Validation: passed

Co-Authored-By: Claude <noreply@anthropic.com>"
```

#### Squash Merge (--squash)

```bash
git checkout "$BASE_BRANCH"
git pull origin "$BASE_BRANCH"
git merge --squash "$BRANCH"
git commit -m "feat: $PLAN_NAME

Squashed commits from parallel-dev execution.

Co-Authored-By: Claude <noreply@anthropic.com>"
```

### 6. Post-Merge Validation

```bash
echo "Running post-merge validation..."

# Quick sanity checks
npm run lint 2>/dev/null || echo "Lint check skipped"
npm run build 2>/dev/null || echo "Build check skipped"
npm test 2>/dev/null || echo "Test check skipped"

if [ $? -eq 0 ]; then
    echo "Post-merge validation passed"
else
    echo "Post-merge issues detected"
    echo "Review and fix before pushing"
fi
```

### 7. Push to Remote

```bash
if [ "$NO_PUSH" != "true" ]; then
    echo "Pushing to remote..."
    git push origin "$BASE_BRANCH"
    echo "Pushed to origin/$BASE_BRANCH"
fi
```

### 8. Cleanup

Unless `--no-cleanup` specified:

```bash
echo "Cleaning up..."

# Remove worktree
git worktree remove "$WORKTREE" --force

# Delete feature branch
git branch -d "$BRANCH"

# Update registry
# Remove worktree entry from registry.json

# Archive execution
mv "$EXEC_DIR" ".claude/parallel-dev/archive/"

echo "Cleanup complete"
```

### 9. Final Report

```
===================================================================
 MERGE COMPLETE: {plan-name}
===================================================================

Merged: {branch} -> {base-branch}
Commits: {N} commits merged
Tasks completed: {M}/{M}

Post-merge validation: passed

Cleanup:
  Worktree removed
  Feature branch deleted
  Execution archived

-------------------------------------------------------------------

Summary:
  The {plan-name} feature has been successfully merged
  into {base-branch} and pushed to origin.

  All artifacts have been cleaned up.

  Execution archived to:
    .claude/parallel-dev/archive/{plan-slug}/

===================================================================
```

## Merge Strategies

| Strategy | Use When |
|----------|----------|
| `--no-ff` (default) | Preserve commit history |
| `--squash` | Clean single commit |
| `--resolve` | Conflicts exist |

## Post-Merge Updates

After successful merge:
1. Update plan status to `merged`
2. Archive execution directory
3. Remove worktree
4. Delete feature branch (local and remote)
5. Update registry

## Rollback

If merge causes issues:

```bash
# Undo local merge (before push)
git reset --hard HEAD~1

# Undo pushed merge
git revert -m 1 HEAD
git push origin main
```

## Output

Creates:
- Merge commit on base branch
- Archived execution at `.claude/parallel-dev/archive/{plan-name}/`

Removes:
- Worktree directory
- Feature branch
- Active execution directory

## Related Commands

- `/parallel-dev:conflicts <name>` - Preview conflicts
- `/parallel-dev:validate <name>` - Run validation before merge
- `/parallel-dev:status <name>` - View execution status
