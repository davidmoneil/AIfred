---
argument-hint: "<task-description>"
description: Decompose a complex task into phases and atomic subtasks with dependencies
allowed-tools:
  - Read
  - Write
  - Glob
  - Grep
  - TodoWrite
  - mcp__mcp-gateway__create_entities
  - mcp__mcp-gateway__create_relations
  - mcp__mcp-gateway__search_nodes
model: sonnet
---

# Task Orchestration: Plan

Decompose a complex task into manageable phases and atomic subtasks.

## When This Runs

- **Manual**: User runs `/orchestration:plan "task description"`
- **Suggested**: Hook detected moderate complexity (score 4-8), user confirmed
- **Automatic**: Hook detected high complexity (score >= 9)

## Process

### 1. Understand the Task

Read and analyze:
- The task description provided as argument
- `current-priorities.md` for related priorities
- `session-state.md` for any existing context
- Similar past orchestrations in `.claude/orchestration/archive/`

### 2. Check for Existing Patterns

Search Memory MCP for similar task patterns:
```
search_nodes("TaskPattern:")
```

If found, use as starting template and adapt.

### 3. Decompose into Phases (with Milestone Reviews)

Break the task into 2-5 phases:
- Each phase is a logical grouping of work
- Phases should be completable in 1-3 sessions
- Later phases can be blocked by earlier ones
- Name phases descriptively: "Phase 1: Foundation", "Phase 2: Core Implementation"

**Milestone Review Gates (AC-03)**:

If the task involves **code, testing, or deliverables**, organize phases into milestones with review gates:

```
Milestone 1 (Phases 1-2) → REVIEW → Milestone 2 (Phases 3-4) → REVIEW → Milestone 3 (Phases 5-7) → FINAL REVIEW
```

Detection criteria for milestone reviews:
- Building an application/feature/system
- Includes testing (unit, integration, E2E)
- Has explicit quality requirements
- Multi-phase implementation work

When milestone reviews apply, add to each milestone boundary:
- `review_gate: true` in the YAML
- Deliverables checklist for the milestone
- Reference: `@.claude/context/patterns/milestone-review-pattern.md`

### 4. Create Atomic Tasks

For each phase, create tasks:
- Each task: 1-4 hours of focused work
- Must have clear "done" criteria (testable/verifiable)
- Include dependencies on other tasks
- Use hierarchical IDs: T1.1, T1.2, T2.1, etc.

### 5. Create Orchestration File

Generate YAML file at `.claude/orchestration/YYYY-MM-DD-<slug>.yaml`:

```yaml
name: "Descriptive Task Name"
created: "2026-01-03"
priority_link: "current-priorities.md#<anchor>"
status: active
complexity_score: <score from hook or 0 if manual>
trigger_mode: <manual|suggested|automatic>
milestone_reviews: true  # Set to true for code/testing work

summary: |
  Brief description of goal and approach.

milestones:
  - name: "Milestone 1: Foundation"
    phases: [1, 2]
    review_gate: true
    deliverables:
      - "package.json and configs"
      - "Tests written (failing TDD)"
      - "Milestone 1 Review Report"

  - name: "Milestone 2: Core Implementation"
    phases: [3, 4]
    review_gate: true
    deliverables:
      - "Implementation complete"
      - "All tests passing"
      - "Milestone 2 Review Report"

  - name: "Milestone 3: Completion"
    phases: [5, 6, 7]
    review_gate: true  # Final review
    deliverables:
      - "Documentation complete"
      - "Deployed/delivered"
      - "Final Review Report"

phases:
  - name: "Phase 1: Foundation"
    milestone: 1
    status: pending
    blocked_by: null
    tasks:
      - id: "T1.1"
        description: "Clear task description"
        done_criteria: "Specific acceptance criteria"
        estimated_hours: 2
        status: pending
        depends_on: []
        commits: []
        notes: ""

  # After Phase 2 completes → Milestone 1 Review Gate
  # STOP: Technical Review + Progress Review
  # PROCEED if ratings >= 4, else REMEDIATE
```

**For non-code tasks** (research, documentation, etc.), omit `milestone_reviews` and `milestones` sections.

### 6. Calculate Totals

Sum `estimated_hours` across all tasks and set in `metadata.total_estimated_hours`.

### 7. Store Pattern (if novel)

If this task type hasn't been seen before, store in Memory MCP:

```javascript
create_entities([{
  name: "TaskPattern: <type>",
  entityType: "TaskPattern",
  observations: [
    "created_at: <timestamp>",
    "phases: <phase structure>",
    "typical_hours: <total>",
    "key_tasks: <common tasks>"
  ]
}]);
```

### 8. Update Session State

Add to `session-state.md`:
```markdown
**Current Orchestration**: <name>
**File**: `.claude/orchestration/<filename>.yaml`
**Progress**: 0% (0/<total> tasks)
```

### 9. Create Initial Todos

Use TodoWrite to create entries for Phase 1 tasks.

### 10. Display Task Tree

Show the created structure:

**Without milestone reviews:**
```
📋 <Task Name> (0% complete)
├── ⏳ Phase 1: Foundation
│   ├── ⏳ T1.1: <description> (2h)
│   └── ⏳ T1.2: <description> (1h)
├── 🔒 Phase 2: Implementation (blocked by Phase 1)
│   └── ⏳ T2.1: <description> (3h)
└── 🔒 Phase 3: Testing (blocked by Phase 2)
    └── ⏳ T3.1: <description> (2h)

Total estimated: Xh across Y tasks
Next available: T1.1 (<description>)
```

**With milestone reviews (code/testing work):**
```
📋 <Task Name> (0% complete) [Milestone Reviews: ON]
│
├── 🎯 MILESTONE 1: Foundation
│   ├── ⏳ Phase 1: Setup
│   │   ├── ⏳ T1.1: <description> (2h)
│   │   └── ⏳ T1.2: <description> (1h)
│   └── ⏳ Phase 2: TDD
│       └── ⏳ T2.1: <description> (3h)
│   └── 🔍 M1 REVIEW GATE → Technical + Progress → PROCEED/REMEDIATE
│
├── 🎯 MILESTONE 2: Core (blocked by M1 Review)
│   ├── 🔒 Phase 3: Implementation
│   │   └── ⏳ T3.1: <description> (3h)
│   └── 🔒 Phase 4: Validation
│       └── ⏳ T4.1: <description> (2h)
│   └── 🔍 M2 REVIEW GATE → Technical + Progress → PROCEED/REMEDIATE
│
└── 🎯 MILESTONE 3: Completion (blocked by M2 Review)
    ├── 🔒 Phase 5-7: Docs & Delivery
    │   └── ⏳ T5.1: <description> (2h)
    └── 🔍 FINAL REVIEW GATE → Complete

Total estimated: Xh across Y tasks, 3 milestones, 3 review gates
Next available: T1.1 (<description>)
```

### 11. Milestone Review Execution (if applicable)

When `milestone_reviews: true`, execution follows this pattern:

```
┌─────────────────────────────────────────────────────────────────┐
│  MILESTONE-GATED EXECUTION FLOW                                  │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  Phase 1 → Phase 2 → STOP: M1 Review → [Remediate] → PROCEED   │
│                              ↓                                   │
│  Phase 3 → Phase 4 → STOP: M2 Review → [Remediate] → PROCEED   │
│                              ↓                                   │
│  Phase 5-7 → STOP: M3 Final Review → Complete                   │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

At each milestone boundary:
1. **STOP** — Do not proceed to next milestone
2. **Technical Review** — Code quality assessment (1-5 rating)
3. **Progress Review** — PRD/requirements alignment (1-5 rating)
4. **Generate Report** — `PRD-XX-M[N]-review-YYYY-MM-DD.md`
5. **Decision** — PROCEED if ratings >= 4, else REMEDIATE

Reference: `@.claude/context/patterns/milestone-review-pattern.md`

## Output

After completion, display:
1. Task tree (as above)
2. File location
3. First task to work on
4. Milestone review gates (if applicable)
5. Suggestion to begin: "Run `/orchestration:status` anytime to check progress"
