# Cross-Project Commit Tracking Pattern

**Created**: 2026-01-06
**Status**: Active
**Source**: Design Pattern Integration - parallel session management

---

## Overview

Tracks git commits across multiple projects during a Claude Code session, providing visibility into work spread across the infrastructure.

**Problem**: Claude Code sessions often touch multiple repositories (hub, myDocker, ~/Code/* projects), making it hard to track what was committed where.

**Solution**: A PostToolUse hook captures all commits and logs them to a central file, with a slash command to view the status.

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                 CROSS-PROJECT COMMIT TRACKING                        │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  Claude Code Session (running in hub)                        │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │  Makes commits to multiple repos:                              │  │
│  │                                                                │  │
│  │  $AIFRED_HOME       → git commit (local)                      │  │
│  │  ~/Docker/mydocker  → git -C ~/Docker/mydocker commit         │  │
│  │  ~/Code/grc-platform→ git -C ~/Code/grc-platform commit       │  │
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
│  │          "hub": { "commits": [...] },                   │  │
│  │          "grc-platform": { "commits": [...] }                  │  │
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

**Project Mappings**:
```javascript
const PROJECT_MAPPINGS = [
  { pathPattern: new RegExp('^' + process.cwd()), name: 'hub', github: '<your-repo>', type: 'hub' },
  { pathPattern: /^\/home\/user\/docker/, name: 'docker', github: '<docker-repo>', type: 'infrastructure' },
  // Example named projects — replace with your own
  { pathPattern: /^\/home\/user\/Code\/project-a/, name: 'project-a', github: 'project-a', type: 'code' },
  { pathPattern: /^\/home\/user\/Code\/project-b/, name: 'project-b', github: 'project-b', type: 'code' },
  // Auto-detect catchall for any other Code/* project
  { pathPattern: /^\/home\/user\/Code\/([^/]+)/, name: null, github: null, type: 'code' },
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
    "2026-01-06_Infrastructure-Updates": {
      "date": "2026-01-06",
      "sessionName": "Infrastructure Updates",
      "startedAt": "2026-01-06T10:00:00Z",
      "lastActivity": "2026-01-06T15:30:00Z",
      "projects": {
        "hub": {
          "github": "mybrain",
          "type": "hub",
          "path": "$AIFRED_HOME",
          "commits": [
            {
              "hash": "abc123def456...",
              "shortHash": "abc123d",
              "message": "Update session state",
              "branch": "main",
              "author": { "name": "David Moneil", "email": "..." },
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
| hub | `[hub]` | hub |
| infrastructure | `[infra]` | myDocker |
| code | `[code]` | grc-platform, AIfred, time-scheduler |
| creative | `[creative]` | CreativeProjects |
| research | `[research]` | claude-code-research |
| unknown | `[?]` | Unregistered ~/Code/* projects |

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
- Future: Auto-include in session summary

---

## Implementation Status

| Feature | Status | Description |
|---------|--------|-------------|
| `/commits:status` | ✅ Complete | Show commits per project |
| `/commits:summary` | ✅ Complete | Generate markdown for session notes |
| `/commits:push-all` | ✅ Complete | Push all unpushed commits |
| Session-start injection | ✅ Complete | Show commit summary from last session |
| Push status tracking | ⏳ Future | Track pushed vs unpushed in UI |

---

## Related Documentation

- @.claude/hooks/cross-project-commit-tracker.js - Hook implementation
- @.claude/commands/commits/README.md - Command group docs
- @.claude/commands/commits/status.md - Status command
- @.claude/context/patterns/worktree-shell-functions.md - Worktree pattern
- @paths-registry.yaml - Project path definitions
