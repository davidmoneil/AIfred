# Parallel Development Commands

Autonomous parallel development with rigorous planning, execution, and validation.

**Skill Documentation**: @.claude/skills/parallel-dev/SKILL.md
**Roadmap**: @.claude/skills/parallel-dev/ROADMAP.md

## Available Commands

### Core Commands
| Command | Description |
|---------|-------------|
| `/parallel-dev` | Show status and quick reference |
| `/parallel-dev:init` | Initialize parallel-dev for current project |
| `/parallel-dev:status` | Show execution status |

### Worktree Management (Phase 1)
| Command | Description |
|---------|-------------|
| `/parallel-dev:worktree-create <branch>` | Create isolated worktree |
| `/parallel-dev:worktree-list` | List all worktrees |
| `/parallel-dev:worktree-cleanup [branch]` | Remove worktree(s) |

### Planning (Phase 2)
| Command | Description |
|---------|-------------|
| `/parallel-dev:plan <name>` | Start guided planning session |
| `/parallel-dev:plan-show <name>` | Display plan details with visual summary |
| `/parallel-dev:plan-list` | List all plans with status |
| `/parallel-dev:plan-edit <name>` | Edit existing plan (sections, features, approval) |

### Task Decomposition (Phase 3)
| Command | Description |
|---------|-------------|
| `/parallel-dev:decompose <name>` | Break approved plan into parallelizable tasks |

### Execution (Phase 4)
| Command | Description |
|---------|-------------|
| `/parallel-dev:start <name>` | Begin autonomous parallel execution |
| `/parallel-dev:pause <name>` | Pause execution gracefully |
| `/parallel-dev:resume <name>` | Resume paused execution |

### Validation (Phase 5)
| Command | Description |
|---------|-------------|
| `/parallel-dev:validate <name>` | Run QA validation (lint, test, build, criteria) |

### Merge (Phase 6)
| Command | Description |
|---------|-------------|
| `/parallel-dev:conflicts <name>` | Check for merge conflicts |
| `/parallel-dev:merge <name>` | Merge to main with cleanup |

## Quick Start

### Basic Worktree Workflow
```bash
# Initialize for a project
/parallel-dev:init

# Create worktree for feature work
/parallel-dev:worktree-create feature-auth

# Check status
/parallel-dev:status

# When done, cleanup
/parallel-dev:worktree-cleanup feature-auth
```

### Planning Workflow (Autonomous Development)
```bash
# Start guided planning session
/parallel-dev:plan my-feature

# [Answer questions about vision, features, tech stack]
# Claude asks all questions upfront, then works autonomously

# Review the generated plan
/parallel-dev:plan-show my-feature

# Edit if needed
/parallel-dev:plan-edit my-feature --section features

# Approve when ready
/parallel-dev:plan-edit my-feature --approve

# List all plans
/parallel-dev:plan-list

# Break plan into executable tasks
/parallel-dev:decompose my-feature

# Start parallel execution
/parallel-dev:start my-feature

# [Agents work autonomously on tasks]
# Monitor progress with /parallel-dev:status

# Validate before merge
/parallel-dev:validate my-feature

# Check for conflicts
/parallel-dev:conflicts my-feature

# Merge to main (with automatic cleanup)
/parallel-dev:merge my-feature
```

## Configuration

Configuration is stored in `.claude/skills/parallel-dev/config.json`:

| Setting | Default | Description |
|---------|---------|-------------|
| `worktreeBase` | `~/tmp/worktrees` | Base path for worktrees |
| `maxParallelAgents` | 5 | Max concurrent agents |
| `portPool.start` | 8100 | First port for allocation |
| `portPool.end` | 8199 | Last port for allocation |

## Registry Location

Active worktrees and executions tracked in:
`.claude/parallel-dev/registry.json`

## Related Documentation

- @.claude/skills/parallel-dev/SKILL.md - Full skill documentation
- @.claude/skills/parallel-dev/ROADMAP.md - Implementation roadmap
- @.claude/context/patterns/worktree-shell-functions.md - Worktree patterns
