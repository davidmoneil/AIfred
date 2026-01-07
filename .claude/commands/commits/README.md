# Cross-Project Commit Commands

Commands for tracking and managing commits across multiple projects during Claude Code sessions.

## Commands

| Command | Description |
|---------|-------------|
| `/commits:status` | Show commits per project for current session |
| `/commits:summary` | Generate markdown summary for session notes |
| `/commits:push-all` | Push all unpushed commits across projects |

## How It Works

The `cross-project-commit-tracker.js` hook automatically detects git commits (via Bash or MCP git tools) and logs them to `.claude/logs/cross-project-commits.json`.

## Setup

1. Ensure the hook is registered in `.claude/settings.json`:
   ```json
   {
     "hooks": {
       "PostToolUse": ["hooks/cross-project-commit-tracker.js"]
     }
   }
   ```

2. Customize `PROJECT_MAPPINGS` in the hook to match your project structure

3. Optionally set session name:
   ```bash
   echo "My Session Name" > .claude/logs/.current-session
   ```

## Data Format

Commits are stored in JSON format:

```json
{
  "sessions": {
    "2026-01-06_My-Session": {
      "date": "2026-01-06",
      "sessionName": "My Session",
      "projects": {
        "project-name": {
          "github": "repo-name",
          "type": "code",
          "commits": [
            {
              "shortHash": "abc1234",
              "message": "Commit message",
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

## Use Cases

- **Session end review**: See all work done across projects
- **Push verification**: Ensure all commits are pushed before ending
- **Documentation**: Generate commit summaries for session notes
- **Team handoff**: Share session activity summary
