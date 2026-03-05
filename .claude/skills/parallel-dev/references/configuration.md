# Parallel-Dev: Configuration & Integration

## Configuration

`.claude/skills/parallel-dev/config.json`:

```json
{
  "worktreeBase": "~/tmp/worktrees",
  "registryPath": ".claude/parallel-dev/registry.json",
  "plansPath": ".claude/parallel-dev/plans",
  "executionsPath": ".claude/parallel-dev/executions",
  "maxParallelAgents": 3,
  "staleThresholdMinutes": 30,
  "autoCleanupWorktrees": true,
  "portPool": { "start": 8100, "end": 8199 },
  "portsPerWorktree": 2,
  "defaultValidation": ["lint", "typecheck", "test", "build"],
  "terminal": "tmux",
  "agentModel": "sonnet",
  "planningModel": "opus"
}
```

| Setting | Default | Description |
|---------|---------|-------------|
| `maxParallelAgents` | 3 | Maximum concurrent agents |
| `staleThresholdMinutes` | 30 | When to check on stale agents |
| `autoCleanupWorktrees` | true | Remove worktrees after merge |
| `agentModel` | sonnet | Model for implementation agents |
| `planningModel` | opus | Model for planning (needs reasoning) |

## Agents

| Agent | Purpose | Spawned During |
|-------|---------|----------------|
| `parallel-dev-implementer` | Code implementation | Execution phase |
| `parallel-dev-tester` | Test writing | Execution phase |
| `parallel-dev-documenter` | Documentation | Execution phase |
| `parallel-dev-validator` | QA validation | Validation phase |

## File Locations

| File | Purpose |
|------|---------|
| `.claude/parallel-dev/registry.json` | Active worktrees and port allocation |
| `.claude/parallel-dev/plans/{name}.md` | Development plans (PRD-style) |
| `.claude/parallel-dev/plans/{name}-tasks.yaml` | Task decomposition |
| `.claude/parallel-dev/executions/{name}/state.yaml` | Execution tracking |
| `.claude/parallel-dev/executions/{name}/validation.yaml` | Validation results |
| `.claude/parallel-dev/archive/` | Completed executions |
| `~/tmp/worktrees/{project}/{name}/` | Isolated worktree storage |

## Templates

| Template | Purpose |
|----------|---------|
| `templates/plan-template.md` | PRD-style plan structure |
| `templates/tasks-template.yaml` | Task decomposition schema |
| `templates/execution-state.yaml` | Execution tracking schema |
| `templates/validation-config.yaml` | Validation pipeline config |
| `templates/validation-report.md` | Human-readable report |

## Integration Points

| Component | How Parallel-Dev Uses It |
|-----------|--------------------------|
| Git worktrees | Isolation pattern from `worktree-shell-functions.md` |
| Orchestration system | Task decomposition patterns |
| Custom agents | Specialized execution agents |
| Session management | State tracking across sessions |
| Memory MCP | Plans stored for reference, lessons learned |

## Safety Guidelines

1. **Worktree Isolation**: Never modifies main branch directly
2. **Frequent Commits**: Small, atomic commits per task
3. **Validation Required**: Must pass QA before merge
4. **User Code Preserved**: Never overwrites without confirmation
5. **Cleanup on Completion**: Removes worktrees, releases ports
6. **State Persistence**: Survives session interruption
