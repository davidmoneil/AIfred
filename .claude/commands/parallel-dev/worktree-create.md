---
description: Create an isolated git worktree for parallel development
argument-hint: <branch-name> [base-branch]
allowed-tools:
  - Read
  - Write
  - Bash
  - Grep
---

# Parallel-Dev: Create Worktree

Create an isolated git worktree for parallel feature development.

## Arguments

- `<branch-name>` - Name for the new branch (required)
- `[base-branch]` - Base branch to create from (default: main)

## Process

### 1. Validate Arguments

```bash
BRANCH="$ARGUMENTS"  # First word
BASE="${2:-main}"    # Second word or default

if [ -z "$BRANCH" ]; then
    echo "Branch name required"
    echo "Usage: /parallel-dev:worktree-create <branch-name> [base-branch]"
    exit 1
fi
```

### 2. Load Configuration

```bash
CONFIG_FILE=".claude/skills/parallel-dev/config.json"
WORKTREE_BASE=$(jq -r '.worktreeBase // "~/tmp/worktrees"' "$CONFIG_FILE" 2>/dev/null || echo "~/tmp/worktrees")
WORKTREE_BASE="${WORKTREE_BASE/#\~/$HOME}"
```

### 3. Get Project Context

```bash
# Get project name
PROJECT=$(basename $(git remote get-url origin 2>/dev/null | sed 's/\.git$//') 2>/dev/null || basename $(pwd))
REPO_ROOT=$(git rev-parse --show-toplevel)

# Slugify branch name for filesystem
BRANCH_SLUG=$(echo "$BRANCH" | tr '/' '-')

# Determine worktree path
WORKTREE_PATH="$WORKTREE_BASE/$PROJECT/$BRANCH_SLUG"
```

### 4. Check Prerequisites

```bash
# Ensure we're in a git repo
git rev-parse --show-toplevel || {
    echo "Not a git repository"
    exit 1
}

# Ensure registry exists
if [ ! -f ".claude/parallel-dev/registry.json" ]; then
    echo "Parallel-dev not initialized. Run: /parallel-dev:init"
    exit 1
fi

# Check for uncommitted changes
if [ -n "$(git status --porcelain)" ]; then
    echo "Uncommitted changes detected"
    echo "Recommend: commit or stash before creating worktree"
fi

# Check if branch already exists
if git show-ref --verify --quiet "refs/heads/$BRANCH"; then
    echo "Branch '$BRANCH' exists - will use existing branch"
    NEW_BRANCH=false
else
    NEW_BRANCH=true
fi

# Check if worktree path already exists
if [ -d "$WORKTREE_PATH" ]; then
    echo "Worktree path already exists: $WORKTREE_PATH"
    echo "Run: /parallel-dev:worktree-cleanup $BRANCH_SLUG"
    exit 1
fi
```

### 5. Allocate Ports (Optional)

```bash
# Read current allocations
REGISTRY=".claude/parallel-dev/registry.json"
ALLOCATED=$(cat "$REGISTRY" | jq -r '.portPool.allocated[]' 2>/dev/null)

# Find two available ports
PORT1=""
PORT2=""
for PORT in $(seq 8100 8199); do
    if ! echo "$ALLOCATED" | grep -q "^${PORT}$"; then
        if ! lsof -i :"$PORT" &>/dev/null; then
            if [ -z "$PORT1" ]; then
                PORT1=$PORT
            elif [ -z "$PORT2" ]; then
                PORT2=$PORT
                break
            fi
        fi
    fi
done

# Default to null if ports not needed/available
PORTS_JSON="[$PORT1, $PORT2]"
[ -z "$PORT1" ] && PORTS_JSON="[]"
```

### 6. Create Worktree

```bash
# Create parent directory
mkdir -p "$WORKTREE_BASE/$PROJECT"

# Create worktree
if [ "$NEW_BRANCH" = true ]; then
    # New branch from base
    git worktree add "$WORKTREE_PATH" -b "$BRANCH" "$BASE"
else
    # Existing branch
    git worktree add "$WORKTREE_PATH" "$BRANCH"
fi

echo "Created worktree at: $WORKTREE_PATH"
```

### 7. Copy Project Resources

Copy files that aren't tracked by git but needed:

```bash
# Copy .env.example if exists
[ -f ".env.example" ] && cp .env.example "$WORKTREE_PATH/.env"

# Copy any .agents directory (if project has custom agents)
[ -d ".agents" ] && cp -r .agents "$WORKTREE_PATH/"
```

### 8. Update Registry

Add entry to `.claude/parallel-dev/registry.json`:

```bash
TMP=$(mktemp)
TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)
ID=$(uuidgen 2>/dev/null || cat /proc/sys/kernel/random/uuid)

jq --arg id "$ID" \
   --arg project "$PROJECT" \
   --arg branch "$BRANCH" \
   --arg slug "$BRANCH_SLUG" \
   --arg path "$WORKTREE_PATH" \
   --arg repo "$REPO_ROOT" \
   --arg ts "$TIMESTAMP" \
   --argjson ports "$PORTS_JSON" \
   '.worktrees += [{
     "id": $id,
     "project": $project,
     "branch": $branch,
     "branchSlug": $slug,
     "worktreePath": $path,
     "repoPath": $repo,
     "ports": $ports,
     "createdAt": $ts,
     "status": "active",
     "task": null
   }]' "$REGISTRY" > "$TMP" && mv "$TMP" "$REGISTRY"

# Update allocated ports
if [ -n "$PORT1" ]; then
    TMP=$(mktemp)
    jq ".portPool.allocated += [$PORT1, $PORT2] | .portPool.allocated |= unique" \
        "$REGISTRY" > "$TMP" && mv "$TMP" "$REGISTRY"
fi
```

### 9. Display Summary

```
Worktree Created

Branch:   $BRANCH (from $BASE)
Location: $WORKTREE_PATH
Ports:    $PORT1, $PORT2 (if allocated)

To work in this worktree:
  cd $WORKTREE_PATH

To launch Claude in worktree:
  cd $WORKTREE_PATH && claude

To cleanup when done:
  /parallel-dev:worktree-cleanup $BRANCH_SLUG
```

## Port Usage

Allocated ports can be used for:
- `PORT1` (e.g., 8100) - API/backend server
- `PORT2` (e.g., 8101) - Frontend dev server

## Output

Returns:
1. Worktree path
2. Allocated ports (if any)
3. Instructions for use
4. Cleanup command
