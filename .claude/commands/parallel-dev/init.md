---
description: Initialize parallel-dev for the current project
allowed-tools:
  - Read
  - Write
  - Bash
  - Glob
---

# Parallel-Dev: Initialize

Set up parallel-dev infrastructure for a project.

## When to Use

- First time using parallel-dev with a project
- After cloning a project that uses parallel-dev
- To reset the registry

## Process

### 1. Verify Git Repository

```bash
git rev-parse --show-toplevel 2>/dev/null || echo "ERROR: Not a git repository"
```

If not a git repo, abort with instructions.

### 2. Get Project Info

```bash
# Project name from git remote or directory
PROJECT=$(basename $(git remote get-url origin 2>/dev/null | sed 's/\.git$//') 2>/dev/null || basename $(pwd))
REPO_ROOT=$(git rev-parse --show-toplevel)
```

### 3. Load Configuration

Read worktree base from config:

```bash
CONFIG_FILE=".claude/skills/parallel-dev/config.json"
WORKTREE_BASE=$(jq -r '.worktreeBase // "~/tmp/worktrees"' "$CONFIG_FILE" 2>/dev/null || echo "~/tmp/worktrees")
WORKTREE_BASE="${WORKTREE_BASE/#\~/$HOME}"
```

### 4. Create Directory Structure

Ensure these exist:
- `.claude/parallel-dev/` - Base directory
- `.claude/parallel-dev/plans/` - Development plans
- `.claude/parallel-dev/executions/` - Execution tracking

```bash
mkdir -p .claude/parallel-dev/{plans,executions}
```

### 5. Initialize Registry

If `.claude/parallel-dev/registry.json` doesn't exist or is invalid, create:

```json
{
  "version": "1.0",
  "project": "<project-name>",
  "created": "<timestamp>",
  "executions": [],
  "worktrees": [],
  "portPool": {
    "start": 8100,
    "end": 8199,
    "allocated": []
  }
}
```

### 6. Create Worktree Base Directory

```bash
mkdir -p "$WORKTREE_BASE/$PROJECT"
```

### 7. Add to .gitignore

Ensure these are in `.gitignore`:
- `.claude/parallel-dev/executions/` - Ephemeral execution state

```bash
# Check and add if missing
if ! grep -q "parallel-dev/executions" .gitignore 2>/dev/null; then
    echo "# Parallel-dev execution state (ephemeral)" >> .gitignore
    echo ".claude/parallel-dev/executions/" >> .gitignore
fi
```

### 8. Check Dependencies

Verify available:
- `git worktree` - For isolation
- `jq` - For registry manipulation
- `tmux` - For terminal sessions (optional for SSH)

```bash
command -v git >/dev/null && echo "git available"
command -v jq >/dev/null && echo "jq available" || echo "jq not found (optional)"
command -v tmux >/dev/null && echo "tmux available" || echo "tmux not found (needed for SSH parallel)"
```

### 9. Display Summary

```
Parallel-dev initialized for: <project>

Directory structure:
  .claude/parallel-dev/
  ├── registry.json    Created
  ├── plans/           Ready
  └── executions/      Ready

Worktree base: $WORKTREE_BASE/<project>/

Quick Reference:
  /parallel-dev:worktree-create <branch>  - Create worktree
  /parallel-dev:worktree-list             - List worktrees
  /parallel-dev:status                    - Show status

Full documentation: /parallel-dev
```

## Idempotency

Running init multiple times is safe:
- Directories only created if missing
- Registry only reset if `--reset` flag provided
- Existing worktrees preserved

## Arguments

- `--reset` - Force reset the registry (preserves worktrees)

## Output

Confirms initialization with:
1. Project name detected
2. Directories created/verified
3. Registry status
4. Quick reference commands
