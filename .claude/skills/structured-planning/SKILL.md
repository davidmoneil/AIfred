---
name: structured-planning
version: 1.0.0
description: Guided conversational planning with dynamic depth for new designs, system reviews, and feature development
category: workflow
tags: [planning, design, requirements, specification, orchestration]
created: 2026-01-19
context: shared
model: opus
---

# Structured Planning Skill

Industry-standard planning workflows that guide you through proper specification before implementation - with dynamic question depth based on complexity.

---

## Overview

This skill provides **guided, conversational planning** for three task types:

| Mode | When to Use | Output |
|------|-------------|--------|
| **New Design** | Building from scratch | Complete spec + orchestration plan |
| **System Review** | Improving existing system | Review findings + improvement plan |
| **Feature Planning** | Adding to existing project | Feature spec + orchestration plan |

**Key Behaviors**:
- **Auto-detects mode** from your request (you confirm or override)
- **Dynamic depth** - questions deepen when your answers indicate complexity
- **Full documentation** - creates specs that become your source of truth
- **Orchestration handoff** - planning feeds directly into `/orchestration:*` commands

---

## When to Use This Skill

### Ideal Use Cases

| Scenario | Mode | Example |
|----------|------|---------|
| Starting a new project | New Design | "I want to build a habit tracking app" |
| New significant feature | New Design | "Build a complete authentication system" |
| Reviewing what exists | System Review | "Review my current voice system" |
| Improving architecture | System Review | "Audit the API for improvements" |
| Adding a feature | Feature Planning | "Add dark mode to the dashboard" |
| Extending capability | Feature Planning | "Integrate Stripe payments" |

### Trigger Phrases

The system auto-detects planning needs from phrases like:
- "I want to build/create/design..."
- "Let's plan out..."
- "I need to add a feature for..."
- "Review/audit/assess my..."
- "Improve/optimize the existing..."

### When NOT to Use

| Scenario | Use Instead |
|----------|-------------|
| Quick bug fix | Direct editing |
| Simple config change | Edit tool |
| Research question | Explore agent |
| Already have clear spec | `/orchestration:plan` directly |

---

## Quick Actions

| Need | Action | Command |
|------|--------|---------|
| Start planning (auto-detect mode) | Guided planning session | `/plan "description"` |
| New design explicitly | Full design workflow | `/plan:new "description"` |
| System review explicitly | Review workflow | `/plan:review "system name"` |
| Feature planning explicitly | Lighter workflow | `/plan:feature "feature"` |

---

## Complete Workflow

```
┌─────────────────────────────────────────────────────────────────┐
│                   STRUCTURED PLANNING WORKFLOW                   │
├─────────────────────────────────────────────────────────────────┤
│  PHASE 1: MODE DETECTION                                         │
│  └─ System analyzes request                                      │
│     ├─ Suggests: New Design / System Review / Feature            │
│     └─ You confirm or override                                   │
├─────────────────────────────────────────────────────────────────┤
│  PHASE 2: DISCOVERY                                              │
│  └─ Conversational question flow                                 │
│     ├─ Vision & Goals (what, why, for whom)                      │
│     ├─ Scope & Features (must-have, nice-to-have, out-of-scope)  │
│     ├─ Technical Considerations (stack, constraints, integrations)│
│     └─ Dynamic depth: deeper questions when complexity detected  │
├─────────────────────────────────────────────────────────────────┤
│  PHASE 3: SPECIFICATION                                          │
│  └─ Generate documentation                                       │
│     ├─ Draft summary for review                                  │
│     ├─ Iterate based on feedback                                 │
│     └─ Create: .claude/planning/specs/YYYY-MM-DD-{name}.md       │
├─────────────────────────────────────────────────────────────────┤
│  PHASE 4: ORCHESTRATION HANDOFF                                  │
│  └─ Generate execution plan                                      │
│     ├─ Convert spec acceptance criteria to tasks                 │
│     ├─ Create: .claude/orchestration/YYYY-MM-DD-{name}.yaml      │
│     └─ Ready for /orchestration:status, :resume, :commit         │
└─────────────────────────────────────────────────────────────────┘
```

---

## Components Reference

### Commands

| Command | Purpose | Model |
|---------|---------|-------|
| `/plan` | Main entry point, auto-detects mode | Opus |
| `/plan:new` | Explicit new design mode | Opus |
| `/plan:review` | Explicit system review mode | Opus |
| `/plan:feature` | Explicit feature planning mode | Sonnet |

### Templates

| Template | Purpose |
|----------|---------|
| `question-bank.yaml` | Questions organized by mode/category/depth |
| `new-design-spec.md` | Full specification template |
| `system-review-spec.md` | Review findings template |
| `feature-plan-spec.md` | Lighter feature template |

### Deterministic Tools

Following the **Code Before Prompts** pattern, this skill includes TypeScript tools for routine operations.

```bash
cd .claude/skills/structured-planning

# Show planning status
npx tsx tools/index.ts status

# Create spec from template
npx tsx tools/index.ts create new "My Project"
npx tsx tools/index.ts create review "System Name"
npx tsx tools/index.ts create feature "Feature Name"

# List existing specs
npx tsx tools/index.ts list

# Validate spec completeness
npx tsx tools/index.ts validate .claude/planning/specs/2026-01-21-my-project.md

# Archive completed spec
npx tsx tools/index.ts archive .claude/planning/specs/2026-01-21-my-project.md
```

| Tool Command | Purpose |
|--------------|---------|
| `status` | Show planning overview (counts, recent specs) |
| `create <mode> <name>` | Create spec from template |
| `list [mode]` | List existing specs with status |
| `validate <path>` | Check spec has required sections |
| `archive <path>` | Move spec to archive directory |

### Output Locations

| Artifact | Location |
|----------|----------|
| Specifications | `.claude/planning/specs/YYYY-MM-DD-{name}.md` |
| Review Findings | `.claude/planning/reviews/YYYY-MM-DD-{name}-review.md` |
| Orchestration | `.claude/orchestration/YYYY-MM-DD-{name}.yaml` |
| Archive | `.claude/planning/archive/` |

---

## Dynamic Depth System

Questions deepen automatically when your answers indicate complexity:

### Complexity Signals

| Signal | Example | Effect |
|--------|---------|--------|
| Uncertainty | "I'm not sure", "maybe", "depends" | Ask clarifying questions |
| Multiple stakeholders | "Several teams will use it" | Ask about coordination |
| Integration needs | "Connects to external API" | Ask about boundaries |
| Scale concerns | "Thousands of users" | Ask about performance |
| Security mentions | "Sensitive data" | Ask about compliance |

### Depth Control

- **Default**: Auto-calibrates based on your answers
- **Quick mode**: `/plan --depth=minimal` skips extended questions
- **Thorough mode**: `/plan --depth=comprehensive` asks everything
- **Manual**: Say "that's enough detail" to move on

---

## Detailed Workflows

### New Design Mode

**Purpose**: Full specification for building something from scratch

**Question Categories**:
1. **Vision**: Problem, users, success criteria
2. **Scope**: Features (must-have, nice-to-have, out-of-scope)
3. **Technical**: Stack, architecture, integrations
4. **Constraints**: Timeline, performance, security
5. **Risks**: What could go wrong, mitigations

**Output**: Complete design specification with orchestration plan

### System Review Mode

**Purpose**: Assess existing system and create improvement plan

**Question Categories**:
1. **Current State**: What exists, what works well
2. **Pain Points**: Issues, technical debt, friction
3. **Desired State**: Goals, target architecture
4. **Gap Analysis**: What needs to change
5. **Prioritization**: Quick wins vs strategic changes

**Output**: Review findings document with improvement orchestration

### Feature Planning Mode

**Purpose**: Lighter workflow for adding to existing projects

**Question Categories**:
1. **Feature Scope**: What capability, for whom
2. **Integration**: How it fits with existing code
3. **Acceptance**: How we know it's done

**Output**: Feature specification with orchestration tasks

---

## Integration Points

### With Orchestration System

Planning creates orchestration automatically:

```yaml
# Generated orchestration includes:
spec_file: ".claude/planning/specs/2026-01-19-habit-tracker.md"
planning_mode: "new_design"

# Use standard orchestration commands:
/orchestration:status   # See progress
/orchestration:resume   # Continue work
/orchestration:commit   # Link commits to tasks
```

### With Project Lifecycle

For new projects:
1. `/plan:new` creates specification
2. `/new-code-project` creates the project
3. Orchestration tracks implementation

### With Memory MCP

Planning decisions stored for future reference:
- `Decision: {project} Architecture` with rationale
- `Pattern: {pattern}` for reusable patterns

---

## Example Session

```
User: I want to build a habit tracking application

Claude: I'll help you plan this. Based on your request, I'm suggesting
**New Design** mode for a full planning workflow.

[Confirms mode]

Let me start with some questions about your vision...

**What specific problem are you trying to solve?**
- Who struggles with habits today?
- What makes existing solutions inadequate?

User: People forget to do their habits and lose motivation. Most apps
are too complicated with too many features.

Claude: I notice you mentioned simplicity as important. Let me dig
deeper on the scope...

**What are the absolute must-have features for launch?**

User: Just habit creation, daily check-in, and a streak counter.
Maybe notifications but I'm not sure about that.

Claude: You mentioned uncertainty about notifications. Let me clarify...

**What's your concern about notifications?**
- Technical complexity?
- User experience?
- Platform support?

[Continues with dynamic depth based on answers...]

[After discovery complete:]

Here's your design specification draft:

## Habit Tracker - Design Specification
### Vision: Simple daily habit tracking focused on streaks...

Does this capture your intent? Any adjustments needed?

User: Looks good, let's proceed.

Claude: Created specification at `.claude/planning/specs/2026-01-19-habit-tracker.md`
Created orchestration at `.claude/orchestration/2026-01-19-habit-tracker.yaml`

Run `/orchestration:status` to see your implementation plan.
```

---

## Troubleshooting

### Common Issues

| Issue | Solution |
|-------|----------|
| Questions too shallow | Use `--depth=comprehensive` flag |
| Questions too detailed | Say "that's enough detail" or use `--depth=minimal` |
| Wrong mode detected | Override with explicit `/plan:new`, `:review`, or `:feature` |
| Spec doesn't match intent | Request revision before approval |

### Getting Help

- Review example sessions: `.claude/skills/structured-planning/examples/`
- Check question bank: `.claude/skills/structured-planning/templates/question-bank.yaml`

---

## Related Documentation

- [Orchestration System](@.claude/orchestration/README.md) - Execution tracking after planning
- [PARC Pattern](@.claude/context/patterns/prompt-design-review.md) - Quick design review (lighter than full planning)
- [Parallel Dev Skill](@.claude/skills/parallel-dev/SKILL.md) - Autonomous implementation after planning
