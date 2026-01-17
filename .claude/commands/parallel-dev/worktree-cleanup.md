---
description: Remove worktree(s) and release allocated resources
argument-hint: <branch-slug> [--delete-branch] [--all-orphaned]
allowed-tools:
  - Read
  - Write
  - Bash
  - AskUserQuestion
---

# Parallel-Dev: Cleanup Worktree

Remove a worktree, release allocated ports, and optionally delete the branch.

## Arguments

- `<branch-slug>` - Slugified branch name (e.g., `feature-auth`)
- `--delete-branch` - Also delete the git branch (local and remote)
- `--all-orphaned` - Clean up all orphaned worktree entries
- `--force` - Skip confirmation prompts

## Process

### 1. Validate Arguments

```bash
BRANCH_SLUG="$ARGUMENTS"
DELETE_BRANCH=false
ALL_ORPHANED=false
FORCE=false

# Parse flags from arguments
[[ "$ARGUMENTS" == *"--delete-branch"* ]] && DELETE_BRANCH=true
[[ "$ARGUMENTS" == *"--all-orphaned"* ]] && ALL_ORPHANED=true
[[ "$ARGUMENTS" == *"--force"* ]] && FORCE=true

# Extract branch slug (first non-flag argument)
BRANCH_SLUG=$(echo "$ARGUMENTS" | sed 's/--[^ ]*//g' | xargs | cut -d' ' -f1)
```

### 2. Handle All-Orphaned Mode

If `--all-orphaned` flag:

```bash
if [ "$ALL_ORPHANED" = true ]; then
    REGISTRY=".claude/parallel-dev/registry.json"
    # Find orphaned entries
    ORPHANED=$(jq -r '.worktrees[] | select(.status == "orphaned") | .branchSlug' "$REGISTRY")

    if [ -z "$ORPHANED" ]; then
        echo "No orphaned worktrees found."
        exit 0
    fi

    echo "Found orphaned worktrees:"
    echo "$ORPHANED"

    # Clean each one
    for slug in $ORPHANED; do
        # Remove from registry
        # Release ports
    done

    echo "Cleaned up all orphaned entries"
    exit 0
fi
```

### 3. Find Worktree in Registry

```bash
REGISTRY=".claude/parallel-dev/registry.json"

if [ ! -f "$REGISTRY" ]; then
    echo "Parallel-dev not initialized. Run: /parallel-dev:init"
    exit 1
fi

# Find entry
ENTRY=$(jq ".worktrees[] | select(.branchSlug == \"$BRANCH_SLUG\")" "$REGISTRY")

if [ -z "$ENTRY" ] || [ "$ENTRY" = "null" ]; then
    echo "Worktree not found in registry: $BRANCH_SLUG"
    echo "Available worktrees:"
    jq -r '.worktrees[].branchSlug' "$REGISTRY"
    exit 1
fi

# Extract details
WORKTREE_PATH=$(echo "$ENTRY" | jq -r '.worktreePath')
BRANCH=$(echo "$ENTRY" | jq -r '.branch')
PORTS=$(echo "$ENTRY" | jq -r '.ports[]' 2>/dev/null)
REPO_PATH=$(echo "$ENTRY" | jq -r '.repoPath')
```

### 4. Safety Checks

```bash
# Check for uncommitted changes in worktree
if [ -d "$WORKTREE_PATH" ]; then
    CHANGES=$(cd "$WORKTREE_PATH" && git status --porcelain 2>/dev/null)
    if [ -n "$CHANGES" ]; then
        echo "Worktree has uncommitted changes:"
        echo "$CHANGES" | head -5

        if [ "$FORCE" != true ]; then
            # Use AskUserQuestion tool to confirm
            echo "Proceed anyway? (changes will be lost)"
            # If not confirmed, exit
        fi
    fi
fi

# Check if branch has unmerged commits
if git log main..$BRANCH --oneline 2>/dev/null | head -1 | grep -q '.'; then
    echo "Branch has unmerged commits"
    if [ "$FORCE" != true ]; then
        echo "Consider merging before cleanup"
    fi
fi
```

### 5. Kill Processes on Ports

```bash
for PORT in $PORTS; do
    if [ -n "$PORT" ] && [ "$PORT" != "null" ]; then
        PID=$(lsof -ti:"$PORT" 2>/dev/null)
        if [ -n "$PID" ]; then
            echo "Stopping process on port $PORT (PID: $PID)"
            kill -9 $PID 2>/dev/null || true
        fi
    fi
done
```

### 6. Remove Worktree

```bash
if [ -d "$WORKTREE_PATH" ]; then
    # Change to repo root first
    cd "$REPO_PATH" 2>/dev/null || cd "$(git rev-parse --show-toplevel)"

    # Remove worktree
    git worktree remove "$WORKTREE_PATH" --force 2>/dev/null || {
        echo "git worktree remove failed, removing directory manually"
        rm -rf "$WORKTREE_PATH"
    }

    # Prune worktree list
    git worktree prune

    echo "Removed worktree directory"
else
    echo "Worktree directory already removed"
fi
```

### 7. Update Registry

```bash
TMP=$(mktemp)

# Remove worktree entry
jq "del(.worktrees[] | select(.branchSlug == \"$BRANCH_SLUG\"))" "$REGISTRY" > "$TMP"
mv "$TMP" "$REGISTRY"

# Release ports from pool
for PORT in $PORTS; do
    if [ -n "$PORT" ] && [ "$PORT" != "null" ]; then
        TMP=$(mktemp)
        jq ".portPool.allocated = (.portPool.allocated | map(select(. != $PORT)))" \
            "$REGISTRY" > "$TMP"
        mv "$TMP" "$REGISTRY"
    fi
done

echo "Updated registry"
```

### 8. Delete Branch (Optional)

```bash
if [ "$DELETE_BRANCH" = true ]; then
    # Delete local branch
    git branch -d "$BRANCH" 2>/dev/null || git branch -D "$BRANCH"
    echo "Deleted local branch: $BRANCH"

    # Delete remote branch (if exists)
    if git ls-remote --heads origin "$BRANCH" | grep -q "$BRANCH"; then
        git push origin --delete "$BRANCH" 2>/dev/null && \
            echo "Deleted remote branch: $BRANCH"
    fi
fi
```

### 9. Display Summary

```
Worktree Cleanup Complete

Removed:
  - Worktree: $WORKTREE_PATH
  - Registry entry: $BRANCH_SLUG
  - Ports released: $PORTS

$( [ "$DELETE_BRANCH" = true ] && echo "Branch deleted: $BRANCH" )

Remaining worktrees: $(jq '.worktrees | length' "$REGISTRY")
```

## Examples

```bash
# Basic cleanup (keeps branch)
/parallel-dev:worktree-cleanup feature-auth

# Cleanup and delete branch
/parallel-dev:worktree-cleanup feature-auth --delete-branch

# Clean all orphaned entries
/parallel-dev:worktree-cleanup --all-orphaned

# Force cleanup (no prompts)
/parallel-dev:worktree-cleanup feature-auth --force --delete-branch
```

## Related

- `/parallel-dev:worktree-list` - List worktrees first
