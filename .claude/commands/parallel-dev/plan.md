---
description: Start guided planning session for autonomous development
argument-hint: <plan-name>
allowed-tools:
  - Read
  - Write
  - Bash
  - Glob
  - Grep
  - AskUserQuestion
  - Task
model: opus
---

# Parallel-Dev: Plan

Start a guided planning session that gathers all requirements upfront, enabling autonomous execution afterward.

## Philosophy

> "Ask all questions now, work autonomously later."

This command implements the **5-Phase Discipline**:
1. **Brainstorm** - Think deeper than comfortable
2. **Document** - Write specs with nothing left to interpretation
3. **Plan** - Architect with explicit technical decisions
4. **Execute** - Build exactly what was specified (later phases)
5. **Track** - Maintain transparent progress (later phases)

## Arguments

- `<plan-name>` - Unique name for this plan (kebab-case recommended)

## Process

### 1. Initialize Planning Session

```bash
PLAN_NAME="$ARGUMENTS"

if [ -z "$PLAN_NAME" ]; then
    echo "Plan name required"
    echo "Usage: /parallel-dev:plan <plan-name>"
    exit 1
fi

# Slugify
PLAN_SLUG=$(echo "$PLAN_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd '[:alnum:]-')

# Check if plan exists
PLAN_FILE=".claude/parallel-dev/plans/${PLAN_SLUG}.md"
if [ -f "$PLAN_FILE" ]; then
    echo "Plan '$PLAN_SLUG' already exists"
    echo "Use: /parallel-dev:plan-edit $PLAN_SLUG"
    exit 1
fi

# Ensure directory exists
mkdir -p .claude/parallel-dev/plans
```

### 2. Determine Project Type

Use AskUserQuestion to identify the type of project:

```
Question: What type of project is this?

Options:
1. Web Application (Full-stack with frontend + backend)
2. API Service (Backend only, REST or GraphQL)
3. CLI Tool (Command-line application)
4. Library/Package (Reusable code for other projects)
5. Automation/Script (Workflow automation, data processing)
6. Other (Custom project type)
```

Store the answer to customize subsequent questions.

### 3. Vision & Goals (Phase: Brainstorm)

Ask questions to understand the core purpose:

```
## Vision Questions

1. "In one sentence, what problem does this solve?"
   -> Captures core purpose

2. "Who is the target user? Describe them briefly."
   -> Identifies audience

3. "What does success look like? List 2-3 measurable outcomes."
   -> Defines success criteria

4. "Why now? What's driving the need for this?"
   -> Understands urgency/context
```

**Important**: Push for specificity. Vague answers lead to vague implementations.

### 4. Features & Scope (Phase: Document)

Ask questions to define boundaries:

```
## Feature Questions

1. "List the must-have features for the first version (MVP)."
   -> Core functionality

2. "For each must-have, what makes it 'done'? (acceptance criteria)"
   -> Testable requirements

3. "What features are nice-to-have but not essential?"
   -> Future roadmap

4. "What is explicitly OUT of scope? What won't we build?"
   -> Clear boundaries (prevents scope creep)
```

### 5. Technical Decisions (Phase: Plan)

Based on project type, ask relevant technical questions:

#### For Web Applications:
```
1. "Frontend: React, Vue, Svelte, or other?"
2. "Backend: Node.js, Python, Go, or other?"
3. "Database: PostgreSQL, MongoDB, SQLite, or other?"
4. "Styling: Tailwind, CSS Modules, styled-components?"
5. "Authentication: OAuth, JWT, sessions?"
6. "Deployment: Docker, serverless, traditional hosting?"
```

#### For API Services:
```
1. "Framework: Express, FastAPI, Gin, or other?"
2. "Database and ORM preference?"
3. "API style: REST, GraphQL, or gRPC?"
4. "Authentication method?"
```

#### For CLI Tools:
```
1. "Language: Python, Node.js, Go, Rust?"
2. "Distribution: npm, pip, binary, or other?"
3. "Configuration: files, env vars, flags?"
```

### 6. Constraints & Requirements

Ask about non-functional requirements:

```
## Constraint Questions

1. "Any performance requirements? (response time, throughput)"
   -> Performance constraints

2. "Any security requirements? (auth, encryption, compliance)"
   -> Security constraints

3. "What browsers/platforms must be supported?"
   -> Compatibility requirements

4. "Timeline: hard deadline or flexible?"
   -> Schedule constraints

5. "Any existing code or systems to integrate with?"
   -> Integration requirements
```

### 7. Risks & Concerns

Ask about potential issues:

```
## Risk Questions

1. "What could go wrong? What are you worried about?"
   -> Known risks

2. "Any technical areas where you're uncertain?"
   -> Areas needing research

3. "What would make this project fail?"
   -> Critical dependencies
```

### 8. Final Clarifications

Before generating the plan:

```
"Based on what you've told me, here's my understanding:

[Summary of key points]

1. Is this accurate?
2. Anything I missed or misunderstood?
3. Any final additions?"
```

### 9. Generate Plan Document

Create the plan file from template with gathered information:

```bash
TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)

# Read template and substitute values
# Write to .claude/parallel-dev/plans/${PLAN_SLUG}.md
```

The plan should include:
- All answers organized by section
- Specific acceptance criteria for each feature
- Technical decisions with rationale
- Identified risks with mitigations
- Questions log (what was asked and answered)

### 10. Display Summary & Next Steps

```
===================================================================
 PLAN CREATED: $PLAN_NAME
===================================================================

File: .claude/parallel-dev/plans/$PLAN_SLUG.md

Summary:
  Type: Web Application
  Features: 5 must-have, 3 nice-to-have
  Stack: React + Node.js + PostgreSQL
  Timeline: Flexible

Next Steps:
  1. Review the plan: /parallel-dev:plan-show $PLAN_SLUG
  2. Edit if needed: /parallel-dev:plan-edit $PLAN_SLUG
  3. When ready, decompose into tasks (Phase 3)
  4. Then start execution (Phase 4)

Ready to proceed? Say "decompose" to break into tasks.
===================================================================
```

## Question Templates by Project Type

### Web Application
- Frontend framework preference
- Backend language/framework
- Database type
- Authentication method
- Styling approach
- Responsive/mobile requirements
- SEO requirements

### API Service
- API style (REST/GraphQL/gRPC)
- Rate limiting needs
- Versioning strategy
- Documentation approach
- Client SDK needs

### CLI Tool
- Target platforms
- Installation method
- Configuration approach
- Interactive vs non-interactive
- Output formats

### Library/Package
- Target language/runtime
- Dependency philosophy
- Versioning strategy
- Documentation needs
- Testing requirements

## Autonomous Mode

After planning is complete, Claude should be able to:
1. Execute the plan without further questions
2. Make reasonable decisions within defined constraints
3. Only ask if something truly contradicts the plan

The plan document becomes the **source of truth** for all subsequent work.

## Output

Creates:
- `.claude/parallel-dev/plans/{plan-slug}.md` - The plan document
- Updates registry with plan reference

## Related Commands

- `/parallel-dev:plan-show` - View plan details
- `/parallel-dev:plan-edit` - Modify existing plan
- `/parallel-dev:plan-list` - List all plans
- `/parallel-dev:decompose` - Break plan into tasks (Phase 3)
