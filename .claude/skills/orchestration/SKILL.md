---
name: orchestration
version: 1.0.0
description: Task orchestration for complex multi-phase work with dependency tracking
category: workflow
tags: [orchestration, planning, task-management, multi-phase]
created: 2026-01-22
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

---

## Workflow

### 1. Planning Phase

```bash
/orchestration:plan "Implement user authentication with OAuth, JWT, and RBAC"
```

Creates `.claude/orchestration/YYYY-MM-DD-slug.yaml` with phases, tasks, dependencies, and done criteria.

### 2. Execution Phase

```bash
/orchestration:status        # Check what to work on next
/orchestration:commit T-001  # Link commit after completing task
```

### 3. Resume After Break

```bash
/orchestration:resume
```

---

## YAML Schema

```yaml
name: Task Name
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
        done_criteria: "User model with required fields"
```

---

## Auto-Detection

The `orchestration-detector` hook analyzes prompts for complexity:

| Score | Response | Example |
|-------|----------|---------|
| < 4 | Nothing | "Fix the typo in README" |
| 4-8 | Suggest | "Add user authentication" |
| >= 9 | Auto-invoke | "Build full auth system with OAuth, JWT, RBAC" |

---

## Integration Points

| Integration | How It Works |
|-------------|--------------|
| Structured Planning | `/plan` can output to orchestration format |
| Parallel Dev | `/parallel-dev:decompose` uses similar structure |
| Session Management | `/orchestration:resume` integrates with session-state.md |
| Git | `/orchestration:commit` links commits to task IDs |

---

## Related

- [Structured Planning](../structured-planning/SKILL.md)
- [Parallel Dev](../parallel-dev/SKILL.md)
- [Session Management](../session-management/SKILL.md)
- [Orchestration README](../../orchestration/README.md)
