---
name: orchestration
version: 1.0.0
description: Task orchestration for complex multi-phase work with dependency tracking
category: workflow
tags: [orchestration, planning, task-management, multi-phase]
created: 2026-01-22
updated: 2026-01-22
context: shared
model: opus
---

# Orchestration Skill

Break down complex tasks into phases and atomic subtasks with dependencies, track progress, and resume work across sessions.

---

## Overview

| Aspect | Description |
|--------|-------------|
| Purpose | Manage complex multi-phase tasks with dependency tracking |
| Pattern | Type 3: Skill-Backed (Multi-step workflow) |
| When to Use | Tasks requiring 3+ phases, cross-session continuity, or dependency ordering |
| Storage | `.claude/orchestration/*.yaml` |

---

## Quick Actions

| Need | Command | Description |
|------|---------|-------------|
| Plan a complex task | `/orchestration:plan "task"` | Break into phases and subtasks |
| Check progress | `/orchestration:status` | Show visual progress tree |
| Resume after break | `/orchestration:resume` | Restore context, continue work |
| Link commit to task | `/orchestration:commit <task-id>` | Associate git commit with task |
| Execute autonomously | `/fresh-context <yaml>` | Run tasks in fresh context mode |

---

## Workflow

### 1. Planning Phase

```bash
# Start orchestration for a complex task
/orchestration:plan "Implement user authentication with OAuth, JWT, and RBAC"
```

Creates `.claude/orchestration/YYYY-MM-DD-user-auth.yaml` with:
- Phases (numbered, sequential)
- Tasks within phases (can be parallel)
- Dependencies between tasks
- Done criteria for each task
- Estimated complexity scores

### 2. Execution Phase

Work through tasks in dependency order:

```bash
# Check what to work on next
/orchestration:status

# After completing a task, link the commit
/orchestration:commit T-001
```

### 3. Resume After Break

```bash
# Coming back after session break or context loss
/orchestration:resume

# Shows:
# - Current phase and progress
# - Next uncompleted task
# - Any blockers
# - Suggested next action
```

---

## YAML Schema

```yaml
# .claude/orchestration/YYYY-MM-DD-{slug}.yaml
name: User Authentication System
created: 2026-01-22
status: in_progress  # planned | in_progress | completed | blocked

phases:
  - id: P1
    name: Foundation
    status: completed
    tasks:
      - id: T-001
        name: Create user model
        status: completed
        commit: abc123
        done_criteria: "User model with email, password_hash fields"
      - id: T-002
        name: Add JWT utilities
        status: completed
        depends_on: []

  - id: P2
    name: API Endpoints
    status: in_progress
    tasks:
      - id: T-003
        name: POST /auth/login
        status: in_progress
        depends_on: [T-001, T-002]
        done_criteria: "Returns JWT on valid credentials"
```

---

## Integration Points

| Integration | How It Works |
|-------------|--------------|
| Structured Planning | `/plan` can output to orchestration format |
| Parallel Dev | `/parallel-dev:decompose` uses similar structure |
| Session Management | `/orchestration:resume` integrates with session-state.md |
| Git | `/orchestration:commit` links commits to task IDs |

---

## Auto-Detection

The `orchestration-detector` hook analyzes prompts for complexity:

| Score | Response | Example |
|-------|----------|---------|
| < 4 | Nothing | "Fix the typo in README" |
| 4-8 | Suggest | "Add user authentication" |
| >= 9 | Auto-invoke | "Build full auth system with OAuth, JWT, RBAC" |

**Triggers**:
- Build verbs: "implement", "create", "build", "develop"
- Scope words: "full", "complete", "comprehensive", "end-to-end"
- Multi-component: "and", "with", lists of features

---

## Commands Reference

### `/orchestration:plan`

Create a new orchestration plan.

```bash
/orchestration:plan "Build a notification system with email, SMS, and push"
```

**Output**: Creates YAML file, shows phase/task breakdown

---

### `/orchestration:status`

Show current progress with visual tree.

```bash
/orchestration:status
```

**Output**:
```
📋 User Authentication System (P2: API Endpoints)
├── P1: Foundation [████████████] 100%
│   ├── ✅ T-001: Create user model (abc123)
│   └── ✅ T-002: Add JWT utilities (def456)
├── P2: API Endpoints [████░░░░░░░░] 33%
│   ├── 🔄 T-003: POST /auth/login
│   ├── ⏳ T-004: POST /auth/register
│   └── ⏳ T-005: GET /auth/me
└── P3: OAuth Integration [░░░░░░░░░░░░] 0%

Next: T-003 - POST /auth/login
```

---

### `/orchestration:resume`

Restore context after session break.

```bash
/orchestration:resume
```

**Output**: Loads active orchestration, shows context, suggests next action

---

### `/orchestration:commit`

Link a git commit to a task.

```bash
/orchestration:commit T-003
```

**Behavior**:
1. Gets latest commit hash
2. Updates task status to `completed`
3. Records commit hash in YAML

---

## Fresh Context Execution Mode

For autonomous "fire and forget" execution where each task runs in a **fresh Claude instance** with no context pollution.

### When to Use Fresh Context

| Use Fresh Context | Use Normal Mode |
|-------------------|-----------------|
| Many similar tasks | Complex reasoning that builds |
| Long-running autonomy | Interactive development |
| Consistency matters | Context accumulation helps |
| "Fire and forget" | Need to guide/adjust |

### Quick Usage

```bash
# Execute orchestration tasks in fresh context mode
/fresh-context .claude/orchestration/my-feature.yaml

# Preview tasks before running
/fresh-context --dry-run .claude/orchestration/my-feature.yaml

# With inline tasks (no YAML needed)
/fresh-context --tasks "Task 1|Task 2|Task 3"
```

### How It Works

```
┌─────────────────┐
│  ITERATION 1    │  Fresh Claude instance
│  - Read tasks   │
│  - Execute T1   │
│  - Commit       │
│  - Exit         │
└────────┬────────┘
         ↓
┌─────────────────┐
│  ITERATION 2    │  Fresh Claude instance (NO context from T1)
│  - Read tasks   │
│  - Execute T2   │
│  - Commit       │
│  - Exit         │
└────────┬────────┘
         ↓
    ... continues ...
```

Memory persists ONLY via git commits and task file updates.

### Related Commands

| Command | Purpose |
|---------|---------|
| `/fresh-context <yaml>` | Execute in fresh context mode |
| `/orchestration:plan` | Create task decomposition first |
| `/orchestration:status` | Check progress after execution |

**Full documentation**: @.claude/commands/fresh-context.md and @.claude/context/patterns/fresh-context-pattern.md

---

## Related

- [Structured Planning](../structured-planning/SKILL.md) - For initial planning before orchestration
- [Parallel Dev](../parallel-dev/SKILL.md) - For parallel execution with worktrees
- [Session Management](../session-management/SKILL.md) - For session continuity
- [Fresh Context Pattern](../../context/patterns/fresh-context-pattern.md) - Design pattern details
- [Orchestration README](../../orchestration/README.md) - Technical documentation
