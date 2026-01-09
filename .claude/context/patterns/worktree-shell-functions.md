# Git Worktree Shell Functions Pattern

**Created**: 2026-01-03
**Updated**: 2026-01-09 (Jarvis/Project_Aion adaptation)
**Status**: Active
**Source**: AIfred baseline 2ea4e8b (adapted)

---

## Overview

Git worktrees allow working on multiple branches simultaneously in separate directories. These shell functions provide **quick workflow shortcuts** for creating, switching, and managing worktrees when using Claude Code.

This pattern complements the existing `worktree-manager.js` hook which handles **tracking and warnings**.

---

## Project Aion Note: Branching from Branches

**IMPORTANT**: Jarvis uses `Project_Aion` as its main development branch, NOT `main`.

Worktrees support **branching from ANY branch**, not just `main`:

```bash
# Branch from Project_Aion (Jarvis development branch)
clx feature-auth Project_Aion

# This creates:
# - New worktree at ../feature-auth/
# - New branch 'feature-auth' FROM Project_Aion
# - Merges go back TO Project_Aion (not main)

# When done, merge to Project_Aion (not main):
git checkout Project_Aion
git merge feature-auth
git branch -d feature-auth  # cleanup
```

The worktree system is **completely flexible** — you specify the base branch, and all operations stay within that lineage.

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
User runs: clx feature-auth Project_Aion
                ↓
Shell function: git worktree add ../feature-auth -b feature-auth Project_Aion
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
# Claude Code Worktree Functions (Jarvis/Project Aion)
# ============================================

# clx - Create worktree and launch Claude Code
# Usage: clx <branch-name> [base-branch]
# Example: clx feature-auth Project_Aion
# NOTE: For Jarvis work, use Project_Aion as base (not main)
clx() {
    local branch="${1:-worktree-$(date +%Y%m%d-%H%M%S)}"
    local base="${2:-Project_Aion}"  # Default to Project_Aion for Jarvis

    if [ -z "$1" ]; then
        echo "Usage: clx <branch-name> [base-branch]"
        echo "  branch-name: Name for new branch (required)"
        echo "  base-branch: Branch to create from (default: Project_Aion)"
        echo ""
        echo "Examples:"
        echo "  clx feature-auth              # Branch from Project_Aion"
        echo "  clx hotfix-urgent main        # Branch from main (rare)"
        return 1
    fi

    # Create worktree with new branch from base
    git worktree add "../$branch" -b "$branch" "$base" && \
    cd "../$branch" && \
    echo "✅ Created worktree: $branch (from $base)" && \
    echo "📍 Location: $(pwd)" && \
    echo "⚠️  Merges should go back to: $base" && \
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
| `clx <branch> [base]` | Create worktree, launch Claude | `clx feature-auth Project_Aion` |
| `cx <worktree>` | Switch to worktree, launch Claude | `cx feature-auth` |
| `cxl` | List all worktrees | `cxl` |
| `cxd <worktree>` | Delete worktree (with confirm) | `cxd feature-auth` |
| `cxp` | Prune dead worktrees | `cxp` |
| `cxs` | Show worktree + Claude state | `cxs` |

---

## Use Cases for Jarvis/Project Aion

### Feature Development on Project_Aion

```bash
# Start new feature (branches from Project_Aion by default)
clx pr-10-feature-xyz

# Work on feature with Claude...

# When done, merge back to Project_Aion
git checkout Project_Aion
git merge pr-10-feature-xyz
git push origin Project_Aion

# Cleanup
cxd pr-10-feature-xyz
```

### Parallel Feature Development

```bash
# In main repo
clx pr-10-feature-a    # Creates ../pr-10-feature-a worktree
# Work on feature A...

# In another terminal
clx pr-10-feature-b    # Creates ../pr-10-feature-b worktree
# Work on feature B...

# Check all worktrees
cxl
```

### Code Review in Isolation

```bash
# Create worktree for PR review (don't modify working branch)
clx pr-review-123 origin/some-pr-branch

# Review code with Claude
# Delete when done
cxd pr-review-123
```

### Hotfix While Feature Work In Progress

```bash
# Working on pr-10-feature branch
# Need to do urgent hotfix on Project_Aion

clx hotfix-urgent Project_Aion   # New worktree from Project_Aion
# Fix issue, commit, push
cxd hotfix-urgent                # Clean up

# Back to feature work in original terminal
```

---

## Merge Strategy

**IMPORTANT**: Always merge to the branch you branched FROM:

| Scenario | Base Branch | Merge To |
|----------|-------------|----------|
| Jarvis feature | `Project_Aion` | `Project_Aion` |
| AIfred baseline fix | `main` | `main` (but see constraint below) |
| Hotfix | whatever you branched from | same branch |

**AIfred Constraint**: AIfred baseline at `/Users/aircannon/Claude/AIfred` is **READ-ONLY**. Only `git fetch` and `git pull` are allowed — never create worktrees there.

---

## Installation

1. **Copy shell functions** to `~/.bashrc` or `~/.zshrc`
2. **Reload shell**: `source ~/.zshrc`
3. **Verify**: Run `cxl` to list worktrees

**Note**: The `worktree-manager.js` hook handles tracking. The shell functions are optional convenience wrappers.

---

## Troubleshooting

### "fatal: not a git repository"
You must be inside a git repository to use worktree commands.

### Worktree directory already exists
```bash
# If ../branch-name exists but isn't a worktree
rm -rf ../branch-name
git worktree prune
clx branch-name Project_Aion
```

### Branch already exists
```bash
# Use existing branch instead of creating new
git worktree add ../existing-branch existing-branch
```

### Cross-worktree warning from hook
This is intentional - the hook warns when you're editing files that belong to a different worktree. Switch to that worktree first:
```bash
cx other-worktree
```

---

## Related Documentation

- @.claude/hooks/worktree-manager.js - Hook source code
- @.claude/hooks/session-start.js - Session startup hook
- @.claude/context/patterns/cross-project-commit-tracking.md - Multi-repo commit tracking

---

*Worktree Shell Functions Pattern v1.1*
*Adapted for Jarvis/Project_Aion workflow*
