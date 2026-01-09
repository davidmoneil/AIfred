# Orchestration System

Task decomposition and tracking for complex, multi-phase work.

## Quick Reference

| Command | Purpose |
|---------|---------|
| `/orchestration:plan "<task>"` | Break down complex task into phases/tasks |
| `/orchestration:status` | Show progress tree for active orchestrations |
| `/orchestration:resume` | Restore context after session break |
| `/orchestration:commit <task-id>` | Link git commit to specific task |

## How It Works

1. **Detection**: The `orchestration-detector.js` hook analyzes requests
   - Score < 4: Simple task, proceed normally
   - Score 4-8: Suggest orchestration
   - Score >= 9: Auto-invoke orchestration

2. **Planning**: Creates YAML file with phases and atomic tasks

3. **Execution**: Work through tasks, linking commits

4. **Completion**: Archive when done

## Directory Structure

```
.claude/orchestration/
├── _template.yaml           # Template for new orchestrations
├── README.md                # This file
├── 2026-01-03-auth-system.yaml  # Active orchestrations
└── archive/                 # Completed orchestrations
```

## YAML Format

See `_template.yaml` for full structure. Key fields:

- `status`: active | paused | completed | abandoned
- `phases[].status`: pending | in_progress | completed | blocked
- `tasks[].status`: pending | in_progress | completed | blocked
- `tasks[].depends_on`: Array of task IDs that must complete first
- `tasks[].commits`: Git commits linked to this task

## Integration Points

- **current-priorities.md**: Orchestrations link via `priority_link`
- **session-state.md**: Active orchestration shown in current task
- **TodoWrite**: Orchestration creates session todos
- **Memory MCP**: Patterns stored for reuse
- **Git**: Commits linked to tasks via `/orchestration:commit`
