# Parallel-Dev: Detailed Workflows

## Planning a Feature

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

## Executing with Parallel Agents

**What happens when you run `/parallel-dev:start auth-system`**:

1. **Creates worktree**: Isolated git worktree at `~/tmp/worktrees/{project}/auth-system`
2. **Creates branch**: `feature/auth-system`
3. **Initializes execution state**: Tracks progress in `state.yaml`
4. **Identifies ready tasks**: Tasks with no unmet dependencies
5. **Spawns agents** (up to 3 parallel):
   ```
   Agent 1 → T1.1: Database schema (stream: database)
   Agent 2 → T1.2: Environment config (stream: infra)
   Agent 3 → T1.3: Project scaffolding (stream: core)
   ```
6. **Coordinates completion**:
   - When Agent 1 completes T1.1, dependent tasks (T2.1, T2.2) become ready
   - Agent 1 gets assigned next ready task
   - Progress updates in real-time
7. **Continues until all tasks complete**

## Validating Before Merge

**What happens when you run `/parallel-dev:validate auth-system`**:

1. **Detects project type** (JavaScript, Python, Go, Rust)
2. **Runs Static Analysis**: Linting, type checking, format checking
3. **Runs Tests**: Unit tests with coverage, integration tests
4. **Verifies Build**: Production build succeeds, bundle size check
5. **Reviews Acceptance Criteria**: Validator agent checks each criterion
6. **Generates Report** with pass/fail status

**Auto-fix mode**: `/parallel-dev:validate auth-system --fix` attempts to fix formatting and simple lint issues automatically.

## Example Session

```bash
User: "I want to build user authentication for my Express app"
Claude: "I'll help you plan this. Let me ask some questions..."
[Questions about OAuth vs password, JWT expiry, roles, etc.]
User: [Answers questions]
Claude: "Plan created at .claude/parallel-dev/plans/auth-system.md"

/parallel-dev:plan-show auth-system
/parallel-dev:plan-edit auth-system --approve
/parallel-dev:decompose auth-system
/parallel-dev:start auth-system
/parallel-dev:status
/parallel-dev:validate auth-system
/parallel-dev:merge auth-system
```
