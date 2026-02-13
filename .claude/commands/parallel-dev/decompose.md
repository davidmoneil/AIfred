---
description: Break an approved plan into parallelizable tasks with dependencies
argument-hint: <plan-name>
allowed-tools:
  - Read
  - Write
  - Bash
  - Glob
  - Grep
  - Task
model: opus
---

# Parallel-Dev: Decompose

Analyze an approved plan and break it into executable tasks with dependencies, parallelization flags, and acceptance criteria.

## Arguments

- `<plan-name>` - Name of the approved plan to decompose

## Prerequisites

- Plan must exist at `.claude/parallel-dev/plans/{plan-name}.md`
- Plan status should be `approved` (warning if not, but proceed)

## Process

### 1. Load and Validate Plan

```bash
PLAN_NAME="$ARGUMENTS"
PLAN_SLUG=$(echo "$PLAN_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')
PLAN_FILE=".claude/parallel-dev/plans/${PLAN_SLUG}.md"

if [ ! -f "$PLAN_FILE" ]; then
    echo "Plan not found: $PLAN_NAME"
    exit 1
fi

# Check plan status
STATUS=$(grep -m1 "^status:" "$PLAN_FILE" | cut -d: -f2 | xargs)
if [ "$STATUS" != "approved" ]; then
    echo "Plan status is '$STATUS', not 'approved'"
    echo "Recommend: /parallel-dev:plan-edit $PLAN_NAME --approve"
    echo ""
    echo "Proceeding anyway..."
fi
```

### 2. Analyze Plan Content

Read the plan and extract:
- **Features** (must-have and nice-to-have)
- **Technical stack** (what technologies are involved)
- **Acceptance criteria** for each feature
- **Constraints** (affects task ordering)
- **Integrations** (may need specific tasks)

### 3. Identify Task Streams

Based on the technical stack and features, identify logical streams:

| Project Type | Typical Streams |
|--------------|-----------------|
| Web App | database, api, frontend, tests, infra |
| API Service | database, api, auth, tests |
| CLI Tool | core, commands, config, tests |
| Library | core, utils, types, tests, docs |

### 4. Generate Phases

Break work into logical phases:

**Phase 1: Foundation**
- Database schema / data models
- Project scaffolding
- Configuration setup
- Environment setup

**Phase 2: Core Implementation**
- Main features (from must-have list)
- Business logic
- API endpoints / UI components

**Phase 3: Integration**
- Connect components
- External integrations
- Authentication flows

**Phase 4: Testing & Polish**
- Unit tests
- Integration tests
- Error handling
- Edge cases
- Documentation

### 5. Create Tasks for Each Feature

For each must-have feature in the plan, create tasks with:
- Unique ID (T{phase}.{sequence})
- Name and description
- Done criteria
- Estimated hours
- Stream assignment
- Dependencies
- Parallel safety flag

### 6. Calculate Dependencies

For each task, determine:
1. **What it depends on** - Tasks that must complete first
2. **What it blocks** - Tasks waiting for this (auto-calculated)
3. **Parallel safety** - Can it run alongside other tasks?

**Dependency Rules**:
- Database tasks typically come before API tasks
- API tasks come before frontend tasks
- Tests can often run in parallel with implementation
- Integration tasks depend on the components being integrated

### 7. Estimate Hours

Use these guidelines:

| Task Type | Typical Hours |
|-----------|---------------|
| Simple schema/model | 1-2 |
| CRUD endpoint | 2-3 |
| Complex business logic | 4-6 |
| UI component (simple) | 2-3 |
| UI component (complex) | 4-6 |
| Integration | 3-4 |
| Test suite (per feature) | 2-4 |

### 8. Identify Parallelization Opportunities

Tasks are **parallel_safe** if:
- They work on different files
- They're in different streams
- No data dependency exists

### 9. Generate Tasks File

Write to `.claude/parallel-dev/plans/{plan-name}-tasks.yaml`:

```yaml
name: "{plan-name}"
plan_file: ".claude/parallel-dev/plans/{plan-slug}.md"
created: "{timestamp}"
status: pending

progress:
  phases_total: 4
  phases_complete: 0
  tasks_total: 15
  tasks_complete: 0
  percent: 0

phases:
  - id: "phase-1"
    name: "Foundation"
    # ... tasks
  - id: "phase-2"
    name: "Core Implementation"
    # ... tasks
  # etc.
```

### 10. Display Task Tree

Show the generated structure:

```
===================================================================
 TASK DECOMPOSITION: {plan-name}
===================================================================

Summary: 15 tasks across 4 phases (~28 hours estimated)

Phase 1: Foundation (3 tasks, ~5h)
├── T1.1: Project scaffolding (2h) [parallel_safe]
├── T1.2: Database setup (2h) [depends: T1.1]
└── T1.3: Environment config (1h) [parallel_safe]

Phase 2: Core Implementation (7 tasks, ~16h)
├── T2.1: User model (2h) [stream: database] [parallel_safe]
├── T2.2: Product model (2h) [stream: database] [parallel_safe]
├── T2.3: Auth service (4h) [stream: api] [depends: T2.1]
├── T2.4: Product API (3h) [stream: api] [depends: T2.2]
├── T2.5: User dashboard (3h) [stream: frontend] [depends: T2.3]
├── T2.6: Product listing (2h) [stream: frontend] [depends: T2.4]
└── T2.7: Cart logic (2h) [stream: api] [depends: T2.4]

Phase 3: Integration (2 tasks, ~4h)
├── T3.1: Checkout flow (2h) [depends: T2.5, T2.7]
└── T3.2: Payment integration (2h) [depends: T3.1]

Phase 4: Testing & Polish (3 tasks, ~6h)
├── T4.1: Unit tests (2h) [stream: tests] [parallel_safe]
├── T4.2: Integration tests (2h) [stream: tests] [depends: T3.2]
└── T4.3: Documentation (2h) [stream: docs] [parallel_safe]

-------------------------------------------------------------------
Parallelization Analysis:
  Max parallel tasks: 4 (in Phase 2)
  Streams: database(2), api(3), frontend(2), tests(2)
  Critical path: T1.1 -> T2.1 -> T2.3 -> T2.5 -> T3.1 -> T3.2 (~14h)

-------------------------------------------------------------------

Tasks file: .claude/parallel-dev/plans/{plan-name}-tasks.yaml

Next Steps:
  1. Review tasks: Read the YAML file for details
  2. Adjust if needed: Edit the YAML directly
  3. Start execution: /parallel-dev:start {plan-name}

===================================================================
```

### 11. Update Plan Status

Update the plan file's status to `decomposed`:

```bash
# Portable: temp file + mv (works on both GNU and BSD sed)
tmp=$(mktemp); sed 's/^status:.*/status: decomposed/' "$PLAN_FILE" > "$tmp" && mv "$tmp" "$PLAN_FILE"
```

## Task ID Convention

- `T{phase}.{sequence}` - e.g., T1.1, T2.3, T3.1
- Phase numbers match phase IDs
- Sequence is order within phase

## Stream Guidelines

| Stream | Purpose | Files Typically Touched |
|--------|---------|------------------------|
| database | Schema, models, migrations | `src/db/`, `prisma/`, `drizzle/` |
| api | Endpoints, services, middleware | `src/api/`, `src/services/` |
| frontend | Components, pages, styles | `src/components/`, `src/pages/` |
| tests | Test files | `tests/`, `__tests__/`, `*.test.*` |
| infra | Config, deployment, CI/CD | `docker/`, `.github/`, `terraform/` |
| docs | Documentation | `docs/`, `README.md` |

## Output

Creates:
- `.claude/parallel-dev/plans/{plan-name}-tasks.yaml` - Task definitions
- Updates plan status to `decomposed`

## Related Commands

- `/parallel-dev:plan-show` - View the original plan
- `/parallel-dev:start` - Begin execution with agents
- `/parallel-dev:status` - View progress
