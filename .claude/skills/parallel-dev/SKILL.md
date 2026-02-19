---
name: parallel-dev
version: 1.0.0
description: Autonomous parallel development with rigorous planning, execution, and validation
category: development
tags: [autonomous, parallel, planning, execution, validation, agents, worktrees]
created: 2026-01-17
updated: 2026-02-18
context: fork
agent: general-purpose
model: opus
---

# Parallel Development Skill

Build applications and features autonomously with rigorous planning, parallel agent execution, QA validation, and merge coordination - minimal user interaction after initial requirements gathering.

## Overview

This skill provides **end-to-end autonomous development** by:
- **Planning**: Guided requirement gathering with all questions upfront
- **Decomposition**: Breaking plans into parallelizable tasks
- **Execution**: Multiple agents working simultaneously in isolated worktrees
- **Validation**: Automated QA checks (lint, test, build, acceptance criteria)
- **Merge**: Conflict detection, resolution, and cleanup

## When to Use

| Scenario | Example |
|----------|---------|
| Building a new feature | "Build user authentication with OAuth" |
| Starting a full application | "Create a REST API for inventory management" |
| Developing multiple features | "Add shopping cart, checkout, and payment" |
| Parallel work streams | "Implement database, API, and frontend simultaneously" |

**Not for**: Quick bug fixes, single file changes, research/exploration, simple refactors.

## Quick Actions

| Need | Command |
|------|---------|
| Start planning | `/parallel-dev:plan <name>` |
| View plan | `/parallel-dev:plan-show <name>` |
| List plans | `/parallel-dev:plan-list` |
| Approve plan | `/parallel-dev:plan-edit <name> --approve` |
| Decompose | `/parallel-dev:decompose <name>` |
| Start execution | `/parallel-dev:start <name>` |
| Check progress | `/parallel-dev:status` |
| Pause | `/parallel-dev:pause <name>` |
| Resume | `/parallel-dev:resume <name>` |
| Validate | `/parallel-dev:validate <name>` |
| Check conflicts | `/parallel-dev:conflicts <name>` |
| Merge | `/parallel-dev:merge <name>` |

## Workflow

```
PHASE 1: PLANNING         /parallel-dev:plan <name>
  Questions -> Vision, Features, Technical, Constraints -> Plan file

PHASE 2: APPROVAL          /parallel-dev:plan-show + plan-edit --approve
  Review plan -> Adjust if needed -> Approve

PHASE 3: DECOMPOSITION     /parallel-dev:decompose <name>
  Break into phases -> Create tasks with dependencies -> Identify parallelization

PHASE 4: EXECUTION          /parallel-dev:start <name>
  Create worktree -> Spawn parallel agents (up to 3) -> Track progress

PHASE 5: VALIDATION         /parallel-dev:validate <name>
  Static analysis -> Tests -> Build -> Acceptance criteria -> Report

PHASE 6: MERGE             /parallel-dev:merge <name>
  Conflict check -> Merge -> Post-merge validation -> Cleanup
```

## Agents

| Agent | Purpose | Phase |
|-------|---------|-------|
| `parallel-dev-implementer` | Code implementation | Execution |
| `parallel-dev-tester` | Test writing | Execution |
| `parallel-dev-documenter` | Documentation | Execution |
| `parallel-dev-validator` | QA validation | Validation |

## References

- @references/detailed-workflows.md — Step-by-step planning, execution, and validation procedures
- @references/configuration.md — Config JSON, file locations, templates, integration points, safety guidelines
- @references/troubleshooting.md — Common issues and solutions

## Related

- @.claude/commands/parallel-dev/README.md — Command reference
- @.claude/context/patterns/agent-selection-pattern.md — When to use agents
- @.claude/orchestration/README.md — Task orchestration patterns
