# Cross-Project Commit Tracking Pattern

**Created**: 2026-01-06
**Status**: Active
**Source**: Design Pattern Integration - parallel session management

---

## Overview

Tracks git commits across multiple projects during a Claude Code session, providing visibility into work spread across your infrastructure.

**Problem**: Claude Code sessions often touch multiple repositories, making it hard to track what was committed where.

**Solution**: A PostToolUse hook captures all commits and logs them to a central file, with slash commands to view status and push.

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                 CROSS-PROJECT COMMIT TRACKING                        │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  Claude Code Session                                                │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │  Makes commits to multiple repos:                              │  │
│  │                                                                │  │
│  │  ~/Projects         → git commit (local)                       │  │
│  │  ~/Docker           → git -C ~/Docker commit                   │  │
│  │  ~/Code/my-app      → git -C ~/Code/my-app commit              │  │
│  └───────────────────────────────────────────────────────────────┘  │
│                              │                                       │
│                              ▼                                       │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │          cross-project-commit-tracker.js (PostToolUse)         │  │
│  │                                                                │  │
│  │  1. Detects git commit operations                              │  │
│  │  2. Extracts repo path from command                            │  │
│  │  3. Maps path to known project (from PROJECT_MAPPINGS)         │  │
│  │  4. Gets commit details (hash, message, branch, author)        │  │
│  │  5. Appends to tracking file                                   │  │
│  └───────────────────────────────────────────────────────────────┘  │
│                              │                                       │
│                              ▼                                       │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │        .claude/logs/cross-project-commits.json                 │  │
│  │                                                                │  │
│  │  {                                                             │  │
│  │    "sessions": {                                               │  │
│  │      "2026-01-06_My-Session": {                               │  │
│  │        "projects": {                                           │  │
│  │          "MainProject": { "commits": [...] },                  │  │
│  │          "my-app": { "commits": [...] }                        │  │
│  │        }                                                       │  │
│  │      }                                                         │  │
│  │    }                                                           │  │
│  │  }                                                             │  │
│  └───────────────────────────────────────────────────────────────┘  │
│                              │                                       │
│                              ▼                                       │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │                    /commits:status                             │  │
│  │                                                                │  │
│  │  Shows formatted view of commits per project                   │  │
│  │  with type badges, branch info, and relative times            │  │
│  └───────────────────────────────────────────────────────────────┘  │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Components

### 1. Hook: cross-project-commit-tracker.js

**Location**: `.claude/hooks/cross-project-commit-tracker.js`
**Event**: PostToolUse

**Detects**:
- `git commit` via Bash
- `git -C <path> commit` for remote path commits
- `mcp__git__git_commit` via Git MCP

**Project Mappings** (customize for your setup):
```javascript
const PROJECT_MAPPINGS = [
  { pathPattern: /^\/home\/user\/Projects/, name: 'Projects', github: 'my-projects', type: 'hub' },
  { pathPattern: /^\/home\/user\/Docker/, name: 'Docker', github: null, type: 'infrastructure' },
  { pathPattern: /^\/home\/user\/Code\/([^/]+)/, name: null, github: null, type: 'code' }, // Auto-detect
];
```

### 2. Commands

**Location**: `.claude/commands/commits/`

| Command | Usage | Purpose |
|---------|-------|---------|
| `/commits:status` | Show commits per project | `--all`, `--project` filters |
| `/commits:summary` | Generate markdown | `--output <file>` for session notes |
| `/commits:push-all` | Push unpushed commits | `--dry-run`, `--project` filters |

### 3. Tracking File

**Location**: `.claude/logs/cross-project-commits.json`

**Structure**:
```json
{
  "version": 1,
  "createdAt": "2026-01-06T10:00:00Z",
  "lastUpdated": "2026-01-06T15:30:00Z",
  "sessions": {
    "2026-01-06_My-Session": {
      "date": "2026-01-06",
      "sessionName": "My Session",
      "startedAt": "2026-01-06T10:00:00Z",
      "lastActivity": "2026-01-06T15:30:00Z",
      "projects": {
        "MainProject": {
          "github": "my-repo",
          "type": "hub",
          "path": "/home/user/Projects",
          "commits": [
            {
              "hash": "abc123def456...",
              "shortHash": "abc123d",
              "message": "Update session state",
              "branch": "main",
              "author": { "name": "User", "email": "..." },
              "timestamp": "2026-01-06T10:30:00Z"
            }
          ]
        }
      }
    }
  }
}
```

---

## Project Types

| Type | Badge | Examples |
|------|-------|----------|
| hub | `[hub]` | Main projects directory |
| infrastructure | `[infra]` | Docker configs |
| code | `[code]` | ~/Code/* projects |
| creative | `[creative]` | Creative projects |
| research | `[research]` | Research initiatives |
| unknown | `[?]` | Unregistered projects |

---

## Quick View (Without Command)

```bash
# Latest session commits
cat .claude/logs/cross-project-commits.json | jq '.sessions | to_entries | .[-1].value'

# All commits from today
cat .claude/logs/cross-project-commits.json | jq '.sessions | to_entries | map(select(.key | startswith("2026-01-06")))'

# Count commits per project
cat .claude/logs/cross-project-commits.json | jq '.sessions[].projects | to_entries | map({key: .key, count: (.value.commits | length)})'
```

---

## Integration Points

### With Session Management
- Uses `.claude/logs/.current-session` for session name
- Groups commits by session for session notes

### With Worktree Pattern
- Complements `worktree-manager.js` for single-repo branches
- This pattern handles multi-repo tracking

### With Session Exit
- `/commits:status` useful before session exit to verify work
- `/commits:summary` generates markdown for session notes

---

## Related Documentation

- @.claude/hooks/cross-project-commit-tracker.js - Hook implementation
- @.claude/commands/commits/README.md - Command group docs
- @.claude/context/patterns/worktree-shell-functions.md - Worktree pattern
