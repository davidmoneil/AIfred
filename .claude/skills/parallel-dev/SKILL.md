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
+---------------------------------------------------------------------+
|                    PARALLEL-DEV WORKFLOW                             |
+---------------------------------------------------------------------+
|  PHASE 1: PLANNING                                                   |
|  +-- /parallel-dev:plan <name>                                       |
|     +-- Vision & Goals questions                                     |
|     +-- Features & Scope questions                                   |
|     +-- Technical Decisions questions                                |
|     +-- Generates: plans/{name}.md                                   |
+---------------------------------------------------------------------+
|  PHASE 2: APPROVAL                                                   |
|  +-- /parallel-dev:plan-show <name>  (review)                        |
|  +-- /parallel-dev:plan-edit <name>  (adjust if needed)              |
|  +-- /parallel-dev:plan-edit <name> --approve                        |
+---------------------------------------------------------------------+
|  PHASE 3: DECOMPOSITION                                              |
|  +-- /parallel-dev:decompose <name>                                  |
|     +-- Breaks into phases (Foundation, Core, Integration, Test)     |
|     +-- Creates tasks with dependencies                              |
|     +-- Identifies parallelization opportunities                     |
|     +-- Generates: plans/{name}-tasks.yaml                           |
+---------------------------------------------------------------------+
|  PHASE 4: EXECUTION                                                  |
|  +-- /parallel-dev:start <name>                                      |
|     +-- Creates worktree at {worktreeBase}/{project}/{name}          |
|     +-- Creates feature branch: feature/{name}                       |
|     +-- Spawns parallel agents (up to maxParallelAgents)             |
|     |   +-- Implementer agents (database, api, frontend)             |
|     |   +-- Tester agents                                            |
|     |   +-- Documenter agents                                        |
|     +-- Tracks progress in executions/{name}/state.yaml              |
|     +-- Continues until all tasks complete                           |
|                                                                      |
|  During execution:                                                   |
|  +-- /parallel-dev:status         (monitor progress)                 |
|  +-- /parallel-dev:pause <name>   (graceful pause)                   |
|  +-- /parallel-dev:resume <name>  (continue work)                    |
+---------------------------------------------------------------------+
|  PHASE 5: VALIDATION                                                 |
|  +-- /parallel-dev:validate <name>                                   |
|     +-- Static Analysis (lint, typecheck, format)                    |
|     +-- Testing (unit tests, integration tests, coverage)            |
|     +-- Build Verification (production build)                        |
|     +-- Acceptance Criteria (verify each criterion)                  |
+---------------------------------------------------------------------+
|  PHASE 6: MERGE                                                      |
|  +-- /parallel-dev:conflicts <name>  (preview conflicts)             |
|  +-- /parallel-dev:merge <name>                                      |
|     +-- Merges feature branch to main                                |
|     +-- Runs post-merge validation                                   |
|     +-- Pushes to remote                                             |
|     +-- Removes worktree                                             |
|     +-- Deletes feature branch                                       |
|     +-- Archives execution                                           |
+---------------------------------------------------------------------+
```

---

## Components Reference

### Commands

| Command | Phase | Purpose |
|---------|-------|---------|
| `/parallel-dev:init` | Setup | Initialize for current project |
| `/parallel-dev:status` | Any | Show overall status |
| `/parallel-dev:plan` | Planning | Start guided planning |
| `/parallel-dev:plan-show` | Planning | Display plan details |
| `/parallel-dev:plan-list` | Planning | List all plans |
| `/parallel-dev:plan-edit` | Planning | Edit/approve plan |
| `/parallel-dev:decompose` | Decomposition | Break into tasks |
| `/parallel-dev:start` | Execution | Begin parallel execution |
| `/parallel-dev:pause` | Execution | Pause execution |
| `/parallel-dev:resume` | Execution | Resume execution |
| `/parallel-dev:validate` | Validation | Run QA checks |
| `/parallel-dev:conflicts` | Merge | Preview conflicts |
| `/parallel-dev:merge` | Merge | Merge and cleanup |
| `/parallel-dev:worktree-create` | Infrastructure | Create worktree |
| `/parallel-dev:worktree-list` | Infrastructure | List worktrees |
| `/parallel-dev:worktree-cleanup` | Infrastructure | Remove worktrees |

### Agents

| Agent | Purpose | Spawned During |
|-------|---------|----------------|
| `parallel-dev-implementer` | Code implementation | Execution phase |
| `parallel-dev-tester` | Test writing | Execution phase |
| `parallel-dev-documenter` | Documentation | Execution phase |
| `parallel-dev-validator` | QA validation | Validation phase |

### File Locations

| File | Purpose |
|------|---------|
| `.claude/parallel-dev/registry.json` | Active worktrees and port allocation |
| `.claude/parallel-dev/plans/{name}.md` | Development plans (PRD-style) |
| `.claude/parallel-dev/plans/{name}-tasks.yaml` | Task decomposition |
| `.claude/parallel-dev/executions/{name}/state.yaml` | Execution tracking |
| `.claude/parallel-dev/executions/{name}/validation.yaml` | Validation results |
| `.claude/parallel-dev/archive/` | Completed executions |
| `{worktreeBase}/{project}/{name}/` | Isolated worktree storage |
| `.claude/skills/parallel-dev/config.json` | Skill configuration |

### Templates

| Template | Purpose |
|----------|---------|
| `templates/plan-template.md` | PRD-style plan structure |
| `templates/tasks-template.yaml` | Task decomposition schema |
| `templates/execution-state.yaml` | Execution tracking schema |
| `templates/validation-config.yaml` | Validation pipeline config |
| `templates/validation-report.md` | Human-readable report |

---

## Detailed Workflows

### Planning a Feature

**What happens when you run `/parallel-dev:plan auth-system`**:

1. Claude asks **Vision & Goals** questions:
   - What is the core purpose?
   - Who is the target user?
   - What defines success?

2. Claude asks **Features & Scope** questions:
   - What are must-have features?
   - What's explicitly out of scope?
   - What are acceptance criteria for each feature?

3. Claude asks **Technical Decisions** questions:
   - What stack/framework?
   - What patterns (REST, GraphQL, etc.)?
   - What integrations needed?

4. Claude asks **Constraints** questions:
   - Timeline expectations?
   - Performance requirements?
   - Security considerations?

5. **Claude generates the plan** at `.claude/parallel-dev/plans/auth-system.md`

**Key Point**: All questions are asked upfront. Once you answer, Claude works autonomously through the rest of the workflow.

### Executing with Parallel Agents

**What happens when you run `/parallel-dev:start auth-system`**:

1. **Creates worktree**: Isolated git worktree at `{worktreeBase}/{project}/auth-system`
2. **Creates branch**: `feature/auth-system`
3. **Initializes execution state**: Tracks progress in `state.yaml`
4. **Identifies ready tasks**: Tasks with no unmet dependencies
5. **Spawns agents** (up to configured max parallel):
   ```
   Agent 1 -> T1.1: Database schema (stream: database)
   Agent 2 -> T1.2: Environment config (stream: infra)
   Agent 3 -> T1.3: Project scaffolding (stream: core)
   ```
6. **Coordinates completion**:
   - When Agent 1 completes T1.1, dependent tasks (T2.1, T2.2) become ready
   - Agent 1 gets assigned next ready task
   - Progress updates in real-time
7. **Continues until all tasks complete**

### Validating Before Merge

**What happens when you run `/parallel-dev:validate auth-system`**:

1. **Detects project type** (JavaScript, Python, Go, Rust)
2. **Runs Static Analysis**:
   - Linting (eslint, ruff, golangci-lint)
   - Type checking (tsc, mypy)
   - Format checking (prettier, black)
3. **Runs Tests**:
   - Unit tests with coverage
   - Integration tests if present
4. **Verifies Build**:
   - Production build succeeds
   - Bundle size check
5. **Reviews Acceptance Criteria**:
   - Validator agent checks each criterion
   - Provides evidence (file:line references)
6. **Generates Report** with pass/fail status

**Auto-fix mode**: `/parallel-dev:validate auth-system --fix` attempts to fix formatting and simple lint issues automatically.

---

## Configuration

`.claude/skills/parallel-dev/config.json`:

```json
{
  "worktreeBase": "~/tmp/worktrees",
  "registryPath": ".claude/parallel-dev/registry.json",
  "plansPath": ".claude/parallel-dev/plans",
  "executionsPath": ".claude/parallel-dev/executions",
  "maxParallelAgents": 5,
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
| `worktreeBase` | `~/tmp/worktrees` | Base directory for worktrees |
| `maxParallelAgents` | 5 | Maximum concurrent agents |
| `staleThresholdMinutes` | 30 | When to check on stale agents |
| `autoCleanupWorktrees` | true | Remove worktrees after merge |
| `agentModel` | sonnet | Model for implementation agents |
| `planningModel` | opus | Model for planning (needs reasoning) |

---

## Integration Points

### With Session Management Skill

- Execution state persists across sessions
- `/parallel-dev:resume` restores context after break
- Progress tracked in `session-state.md` if active

### With Memory MCP

- Plans can be stored for reference
- Lessons learned stored for future projects
- Pattern recognition across projects

---

## Example Session

```bash
# User wants to build authentication
User: "I want to build user authentication for my Express app"

# Claude starts guided planning
Claude: "I'll help you plan this. Let me ask some questions..."
[Questions about OAuth vs password, JWT expiry, roles, etc.]

User: [Answers questions]

# Claude generates plan
Claude: "Plan created at .claude/parallel-dev/plans/auth-system.md"

# User reviews and approves
/parallel-dev:plan-show auth-system
/parallel-dev:plan-edit auth-system --approve

# Decompose into tasks
/parallel-dev:decompose auth-system
# Shows: 15 tasks across 4 phases, critical path ~12h

# Start execution
/parallel-dev:start auth-system
# Creates worktree, spawns agents, shows progress

# User can monitor
/parallel-dev:status
# Shows: 45% complete (7/15 tasks), 3 agents active

# Pause if needed
/parallel-dev:pause auth-system

# Resume later
/parallel-dev:resume auth-system

# Validate when complete
/parallel-dev:validate auth-system
# Shows: All checks passed, ready to merge

# Merge to main
/parallel-dev:merge auth-system
# Merges, cleans up worktree, archives execution
```

---

## Safety Guidelines

1. **Worktree Isolation**: Never modifies main branch directly
2. **Frequent Commits**: Small, atomic commits per task
3. **Validation Required**: Must pass QA before merge
4. **User Code Preserved**: Never overwrites without confirmation
5. **Cleanup on Completion**: Removes worktrees, releases ports
6. **State Persistence**: Survives session interruption

---

## Troubleshooting

### Plan not found?
- Check plan name matches file at `.claude/parallel-dev/plans/{name}.md`
- Use `/parallel-dev:plan-list` to see available plans

### Execution won't start?
- Ensure plan status is `approved` or `decomposed`
- Check tasks file exists: `.claude/parallel-dev/plans/{name}-tasks.yaml`
- Verify worktree base directory exists

### Agents seem stuck?
- Check `/parallel-dev:status` for details
- Use `/parallel-dev:pause` then `/parallel-dev:resume`
- Check for circular dependencies in tasks

### Validation failing?
- Review specific failures in validation report
- Use `--fix` flag to auto-fix formatting issues
- Fix failures in worktree, commit, re-validate

### Merge conflicts?
- Run `/parallel-dev:conflicts` first to preview
- Use `/parallel-dev:merge --resolve` for AI-assisted resolution
- Or resolve manually in worktree then merge

---

## Related Documentation

- @.claude/commands/parallel-dev/README.md - Command reference
- @.claude/skills/parallel-dev/ROADMAP.md - Implementation history
- @.claude/context/patterns/worktree-shell-functions.md - Worktree patterns
- @.claude/context/patterns/agent-selection-pattern.md - When to use agents
- @.claude/orchestration/README.md - Task orchestration patterns
