# Git Worktree Shell Functions Pattern

**Created**: 2026-01-03
**Status**: Active
**Source**: Design Pattern Integration from claude-code-research

---

## Overview

Git worktrees allow working on multiple branches simultaneously in separate directories. These shell functions provide **quick workflow shortcuts** for creating, switching, and managing worktrees when using Claude Code.

This pattern complements the existing `worktree-manager.js` hook which handles **tracking and warnings**.

---

## How It Works

### Division of Responsibility

| Component | Responsibility |
|-----------|----------------|
| **Shell functions** (user installs) | Create, switch, delete worktrees |
| **worktree-manager.js** (hook) | Track state, warn about cross-worktree access |
| **session-start.js** (hook) | Inject worktree context on startup |

### Workflow

```
User runs: clx feature-auth
                ↓
Shell function: git worktree add ../feature-auth -b feature-auth main
                ↓
Shell function: cd ../feature-auth && claude --model sonnet
                ↓
Hook (session-start.js): Detects worktree, injects branch context
                ↓
Hook (worktree-manager.js): Tracks state, warns if accessing other worktrees
```

---

## Shell Functions

Add these to your `~/.bashrc` or `~/.zshrc`:

```bash
# ============================================
# Claude Code Worktree Functions
# Created: 2026-01-03
# Source: AIfred design pattern integration
# ============================================

# clx - Create worktree and launch Claude Code
# Usage: clx <branch-name> [base-branch]
# Example: clx feature-auth main
clx() {
    local branch="${1:-worktree-$(date +%Y%m%d-%H%M%S)}"
    local base="${2:-main}"

    if [ -z "$1" ]; then
        echo "Usage: clx <branch-name> [base-branch]"
        echo "  branch-name: Name for new branch (required)"
        echo "  base-branch: Branch to create from (default: main)"
        return 1
    fi

    # Create worktree with new branch from base
    git worktree add "../$branch" -b "$branch" "$base" && \
    cd "../$branch" && \
    echo "✅ Created worktree: $branch (from $base)" && \
    echo "📍 Location: $(pwd)" && \
    claude --model sonnet
}

# cx - Switch to existing worktree and launch Claude Code
# Usage: cx <worktree-name>
# Example: cx feature-auth
cx() {
    if [ -z "$1" ]; then
        echo "Usage: cx <worktree-name>"
        echo "Available worktrees:"
        git worktree list
        return 1
    fi

    if [ -d "../$1" ]; then
        cd "../$1" && \
        echo "📍 Switched to worktree: $(git branch --show-current)" && \
        claude
    else
        echo "❌ Worktree not found: $1"
        echo "Available worktrees:"
        git worktree list
        return 1
    fi
}

# cxl - List all worktrees
# Usage: cxl
alias cxl='git worktree list'

# cxd - Delete worktree (with confirmation)
# Usage: cxd <worktree-name>
cxd() {
    local wt="$1"

    if [ -z "$wt" ]; then
        echo "Usage: cxd <worktree-name>"
        echo "Available worktrees:"
        git worktree list
        return 1
    fi

    # Check if worktree exists
    if ! git worktree list | grep -q "/$wt "; then
        echo "❌ Worktree not found: $wt"
        git worktree list
        return 1
    fi

    # Confirm deletion
    read -p "Delete worktree '$wt' and branch? [y/N] " confirm
    if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
        git worktree remove "../$wt" && \
        echo "✅ Removed worktree: $wt"

        # Optionally delete the branch too
        read -p "Also delete branch '$wt'? [y/N] " del_branch
        if [ "$del_branch" = "y" ] || [ "$del_branch" = "Y" ]; then
            git branch -d "$wt" 2>/dev/null || \
            git branch -D "$wt" && \
            echo "✅ Deleted branch: $wt"
        fi
    else
        echo "Cancelled"
    fi
}

# cxp - Prune dead worktrees
# Usage: cxp
alias cxp='git worktree prune -v && echo "✅ Pruned dead worktrees"'

# cxs - Show worktree status (integrates with Claude hook)
# Usage: cxs
cxs() {
    echo "=== Git Worktrees ==="
    git worktree list
    echo ""

    # Show Claude hook state if available
    local state_file=".claude/logs/.worktree-state.json"
    if [ -f "$state_file" ]; then
        echo "=== Claude Worktree State ==="
        cat "$state_file" | jq -r '"Current: \(.current.branch) (\(.current.toplevel))"' 2>/dev/null
        cat "$state_file" | jq -r '"Last updated: \(.timestamp)"' 2>/dev/null
    fi
}
```

---

## Quick Reference

| Command | Purpose | Example |
|---------|---------|---------|
| `clx <branch> [base]` | Create worktree, launch Claude | `clx feature-auth main` |
| `cx <worktree>` | Switch to worktree, launch Claude | `cx feature-auth` |
| `cxl` | List all worktrees | `cxl` |
| `cxd <worktree>` | Delete worktree (with confirm) | `cxd feature-auth` |
| `cxp` | Prune dead worktrees | `cxp` |
| `cxs` | Show worktree + Claude state | `cxs` |

---

## Integration with Hooks

### worktree-manager.js (PostToolUse)

The hook automatically:
1. **Detects worktree** on every file operation
2. **Saves state** to `.claude/logs/.worktree-state.json`
3. **Warns** if you try to access files in a different worktree

State file format:
```json
{
  "timestamp": "2026-01-03T14:30:00Z",
  "current": {
    "isWorktree": true,
    "toplevel": "/home/user/Code/project-feature-auth",
    "branch": "feature-auth",
    "mainRepo": "/home/user/Code/project"
  },
  "allWorktrees": [
    { "path": "/home/user/Code/project", "branch": "main" },
    { "path": "/home/user/Code/project-feature-auth", "branch": "feature-auth" }
  ]
}
```

### session-start.js (SessionStart)

When Claude Code starts in a worktree:
1. Hook detects worktree context
2. Injects branch information into session
3. Notes other available worktrees

---

## Use Cases

### Parallel Feature Development

```bash
# In main repo
clx feature-auth      # Creates ../feature-auth worktree, launches Claude
# Work on auth feature...

# In another terminal
clx feature-logging   # Creates ../feature-logging worktree, launches Claude
# Work on logging feature...

# Check all worktrees
cxl
```

### Code Review in Isolation

```bash
# Create worktree for PR review (don't modify main)
clx pr-review-123 origin/pr-123

# Review code with Claude
# Delete when done
cxd pr-review-123
```

### Hotfix While Feature Work In Progress

```bash
# Working on feature branch
# Need to do urgent hotfix on main

clx hotfix-urgent main   # New worktree from main
# Fix issue, commit, push
cxd hotfix-urgent        # Clean up

# Back to feature work in original terminal
```

---

## Installation

1. **Copy shell functions** to `~/.bashrc` or `~/.zshrc`
2. **Reload shell**: `source ~/.bashrc`
3. **Verify**: Run `cxl` to list worktrees

**Note**: The `worktree-manager.js` hook is already installed in AIfred. The shell functions are optional convenience wrappers.

---

## Troubleshooting

### "fatal: not a git repository"
You must be inside a git repository to use worktree commands.

### Worktree directory already exists
```bash
# If ../branch-name exists but isn't a worktree
rm -rf ../branch-name
git worktree prune
clx branch-name
```

### Branch already exists
```bash
# Use existing branch instead of creating new
git worktree add ../existing-branch existing-branch
```

### Cross-worktree warning from hook
This is intentional - the hook warns when you're editing files that belong to a different worktree. Usually you want to switch to that worktree first:
```bash
cx other-worktree
```

---

## Related Documentation

- @.claude/hooks/worktree-manager.js - Hook source code
- @.claude/hooks/session-start.js - Session startup hook
- @.claude/logs/.worktree-state.json - Runtime state file

---

**Maintained by**: Claude Code
