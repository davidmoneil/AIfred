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

## Fresh Context Execution

For long-running or repetitive orchestrations, tasks can be executed in **fresh Claude instances** to avoid context pollution.

### When to Use Fresh Context

| Use Fresh Context | Use Normal Session |
|-------------------|-------------------|
| Many similar tasks | Building on previous reasoning |
| Long-running autonomy | Interactive guidance needed |
| Consistency matters | Context accumulation helps |
| Independent tasks | Tasks share state |

### How It Works

```bash
# Execute orchestration tasks with fresh context
./scripts/fresh-context-loop.sh .claude/orchestration/my-feature.yaml

# Or with inline tasks
./scripts/fresh-context-loop.sh --tasks "Task 1|Task 2|Task 3"

# Dry run to preview
./scripts/fresh-context-loop.sh --dry-run .claude/orchestration/my-feature.yaml
```

Each task runs in a completely new Claude instance:
1. Loop controller reads next pending task from YAML
2. Spawns fresh Claude with ONLY that task's prompt
3. Claude executes, commits changes, reports status
4. Controller updates YAML and moves to next task

Memory between tasks persists only via git commits and YAML status updates.

### Configuration

| Parameter | Default | Flag |
|-----------|---------|------|
| Max iterations | 10 | `-m N` |
| Max turns per task | 15 | `-t N` |
| Fail threshold | 3 | `-f N` |

See `scripts/fresh-context-loop.sh --help` for full options.

**Pattern documentation**: `.claude/context/patterns/fresh-context-pattern.md`

## Integration Points

- **current-priorities.md**: Orchestrations link via `priority_link`
- **session-state.md**: Active orchestration shown in current task
- **TodoWrite**: Orchestration creates session todos
- **Memory MCP**: Patterns stored for reuse
- **Git**: Commits linked to tasks via `/orchestration:commit`
- **Fresh Context**: Tasks can run in isolated Claude instances via `fresh-context-loop.sh`
