---
name: parallel-dev
version: 1.0.0
description: Autonomous parallel development with rigorous planning, execution, and validation
category: development
tags: [autonomous, parallel, planning, execution, validation, agents, worktrees]
created: 2026-01-17
updated: 2026-01-17
context: fork
agent: general-purpose
model: opus
---

# Parallel Development Skill

Build applications and features autonomously with rigorous planning, parallel agent execution, QA validation, and merge coordination - minimal user interaction after initial requirements gathering.

---

## Overview

This skill provides **end-to-end autonomous development** by:
- **Planning**: Guided requirement gathering with all questions upfront
- **Decomposition**: Breaking plans into parallelizable tasks
- **Execution**: Multiple agents working simultaneously in isolated worktrees
- **Validation**: Automated QA checks (lint, test, build, acceptance criteria)
- **Merge**: Conflict detection, resolution, and cleanup

**Value**: Develop features with minimal supervision after initial planning - Claude handles the implementation, testing, and integration autonomously.

---

## When to Use This Skill

### Ideal Use Cases

| Scenario | Example |
|----------|---------|
| Building a new feature | "Build user authentication with OAuth" |
| Starting a full application | "Create a REST API for inventory management" |
| Developing multiple features | "Add shopping cart, checkout, and payment" |
| Documented project kickoff | "Build the app from this PRD" |
| Parallel work streams | "Implement database, API, and frontend simultaneously" |

### Trigger Phrases

- "build out this application"
- "develop this feature end-to-end"
- "start parallel development"
- "autonomous development of..."
- "plan and build..."
- "full development lifecycle for..."
- `/parallel-dev` (explicit invocation)

### When NOT to Use

| Scenario | Use Instead |
|----------|-------------|
| Quick bug fix | Direct editing |
| Single file change | Edit tool |
| Research/exploration | Explore agent |
| Simple refactor | feature-dev:code-architect |

---

## Quick Actions

| Need | Action | Command |
|------|--------|---------|
| Start planning a feature | Guided planning session | `/parallel-dev:plan <name>` |
| View existing plan | Display plan details | `/parallel-dev:plan-show <name>` |
| List all plans | See all plans with status | `/parallel-dev:plan-list` |
| Approve a plan | Mark ready for execution | `/parallel-dev:plan-edit <name> --approve` |
| Break plan into tasks | Generate task decomposition | `/parallel-dev:decompose <name>` |
| Start parallel execution | Begin autonomous work | `/parallel-dev:start <name>` |
| Check progress | View execution status | `/parallel-dev:status` |
| Pause execution | Gracefully pause agents | `/parallel-dev:pause <name>` |
| Resume work | Continue after break | `/parallel-dev:resume <name>` |
| Run QA validation | Lint, test, build checks | `/parallel-dev:validate <name>` |
| Check for conflicts | Preview merge issues | `/parallel-dev:conflicts <name>` |
| Merge to main | Complete and cleanup | `/parallel-dev:merge <name>` |

---

## Complete Workflow

```
┌─────────────────────────────────────────────────────────────────┐
│                    PARALLEL-DEV WORKFLOW                         │
├─────────────────────────────────────────────────────────────────┤
│  PHASE 1: PLANNING                                               │
│  └─ /parallel-dev:plan <name>                                    │
│     ├─ Vision & Goals questions                                  │
│     ├─ Features & Scope questions                                │
│     ├─ Technical Decisions questions                             │
│     └─ Generates: plans/{name}.md                                │
├─────────────────────────────────────────────────────────────────┤
│  PHASE 2: APPROVAL                                               │
│  ├─ /parallel-dev:plan-show <name>  (review)                     │
│  ├─ /parallel-dev:plan-edit <name>  (adjust if needed)           │
│  └─ /parallel-dev:plan-edit <name> --approve                     │
├─────────────────────────────────────────────────────────────────┤
│  PHASE 3: DECOMPOSITION                                          │
│  └─ /parallel-dev:decompose <name>                               │
│     ├─ Breaks into phases (Foundation, Core, Integration, Test)  │
│     ├─ Creates tasks with dependencies                           │
│     ├─ Identifies parallelization opportunities                  │
│     └─ Generates: plans/{name}-tasks.yaml                        │
├─────────────────────────────────────────────────────────────────┤
│  PHASE 4: EXECUTION                                              │
│  └─ /parallel-dev:start <name>                                   │
│     ├─ Creates worktree at ~/tmp/worktrees/{project}/{name}      │
│     ├─ Creates feature branch: feature/{name}                    │
│     ├─ Spawns parallel agents (up to 3 by default)               │
│     │   ├─ Implementer agents (database, api, frontend)          │
│     │   ├─ Tester agents                                         │
│     │   └─ Documenter agents                                     │
│     ├─ Tracks progress in executions/{name}/state.yaml           │
│     └─ Continues until all tasks complete                        │
│                                                                  │
│  During execution:                                               │
│  ├─ /parallel-dev:status         (monitor progress)              │
│  ├─ /parallel-dev:pause <name>   (graceful pause)                │
│  └─ /parallel-dev:resume <name>  (continue work)                 │
├─────────────────────────────────────────────────────────────────┤
│  PHASE 5: VALIDATION                                             │
│  └─ /parallel-dev:validate <name>                                │
│     ├─ Static Analysis (lint, typecheck, format)                 │
│     ├─ Testing (unit tests, integration tests, coverage)         │
│     ├─ Build Verification (production build)                     │
│     └─ Acceptance Criteria (verify each criterion)               │
├─────────────────────────────────────────────────────────────────┤
│  PHASE 6: MERGE                                                  │
│  ├─ /parallel-dev:conflicts <name>  (preview conflicts)          │
│  └─ /parallel-dev:merge <name>                                   │
│     ├─ Merges feature branch to main                             │
│     ├─ Runs post-merge validation                                │
│     ├─ Pushes to remote                                          │
│     ├─ Removes worktree                                          │
│     ├─ Deletes feature branch                                    │
│     └─ Archives execution                                        │
└─────────────────────────────────────────────────────────────────┘
```

---

## Reference Documentation

For detailed information, see the references/ directory:
- @references/detailed-workflows.md — Planning, execution, validation step-by-step
- @references/configuration.md — Config, agents, file locations, templates, integrations
- @references/troubleshooting.md — Common issues and solutions

## Related

- @.claude/commands/parallel-dev/README.md — Command reference
- @.claude/context/patterns/worktree-shell-functions.md — Worktree patterns
- @.claude/orchestration/README.md — Task orchestration patterns
