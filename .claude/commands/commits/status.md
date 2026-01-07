---
name: commits:status
description: Show cross-project commit status for current session
usage: /commits:status [--all] [--project <name>]
category: workflow
created: 2026-01-06
---

# Cross-Project Commit Status

Shows commits made across all tracked projects during the current (or all) session(s).

## Usage

```
/commits:status           # Current session commits
/commits:status --all     # All sessions from today
/commits:status --project my-project  # Filter by project
```

## Output Example

```
┌─────────────────────────────────────────────────────────────┐
│ CROSS-PROJECT COMMIT STATUS                                  │
│ Session: Infrastructure Updates | 2026-01-06                │
├─────────────────────────────────────────────────────────────┤
│ Projects: 3 | Total Commits: 7                              │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│ [hub] MainProject                                   2 commits│
│ ├─ abc1234 Update session state                    (2h ago) │
│ └─ def5678 Add new hook                            (1h ago) │
│                                                              │
│ [code] api-service                                 4 commits│
│ ├─ ghi9012 Fix auth middleware               @main (45m ago)│
│ ├─ jkl3456 Add user validation              @main (40m ago) │
│ ├─ mno7890 Update tests                     @main (30m ago) │
│ └─ pqr1234 Merge feature branch             @main (15m ago) │
│                                                              │
│ [infra] Docker                                     1 commit │
│ └─ stu5678 Update compose file              @main (20m ago) │
│                                                              │
├─────────────────────────────────────────────────────────────┤
│ Not pushed: 3 commits (MainProject: 1, api-service: 2)      │
└─────────────────────────────────────────────────────────────┘
```

## Execution Steps

1. **Read tracking file**:
   ```bash
   cat .claude/logs/cross-project-commits.json
   ```

2. **Parse session data**:
   - Filter by current session name (from `.claude/logs/.current-session`)
   - Or show all sessions if `--all` flag

3. **Format output**:
   - Group by project
   - Show project type badge: `[hub]`, `[code]`, `[infra]`, `[creative]`
   - Display commit hash, message (truncated), branch, relative time

4. **Check push status** (optional enhancement):
   ```bash
   # For each project, check if commits are pushed
   git -C <project-path> log --oneline @{u}..HEAD
   ```

## Data Source

**Tracking file**: `.claude/logs/cross-project-commits.json`

```json
{
  "sessions": {
    "2026-01-06_Infrastructure-Updates": {
      "date": "2026-01-06",
      "sessionName": "Infrastructure Updates",
      "projects": {
        "MainProject": {
          "github": "my-project",
          "type": "hub",
          "commits": [
            {
              "shortHash": "abc1234",
              "message": "Update session state",
              "branch": "main",
              "timestamp": "2026-01-06T10:00:00Z"
            }
          ]
        }
      }
    }
  }
}
```

## Project Type Badges

| Type | Badge | Description |
|------|-------|-------------|
| hub | `[hub]` | Main projects hub |
| infrastructure | `[infra]` | Docker/infrastructure configs |
| code | `[code]` | ~/Code/* projects |
| creative | `[creative]` | Creative projects |
| research | `[research]` | Research initiatives |
| unknown | `[?]` | Unregistered project |

## Integration

**Related Components**:
- `cross-project-commit-tracker.js` - The hook that captures commits
- `session-start.js` - Injects session context (could add commit summary)
- `/commits:summary` - Generate commit summary for session notes

## Implementation Note

This command reads the JSON tracking file and formats it for display. The hook (`cross-project-commit-tracker.js`) does all the capture work.

For a quick view without the slash command:
```bash
cat .claude/logs/cross-project-commits.json | jq '.sessions | to_entries | .[-1].value'
```
