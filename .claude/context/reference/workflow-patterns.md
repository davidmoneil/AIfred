# Workflow Patterns Reference

**Version**: 1.0
**Status**: Active (on-demand reference)

---

## Core Patterns

Jarvis uses four core workflow patterns:

### PARC: Design Review Pattern

**Purpose**: Validate approach before implementing significant tasks.

```
Prompt  → What's being asked? (parse the request)
Assess  → Do existing patterns apply? (check patterns/)
Relate  → How does this fit architecture? (scope, reuse, impact)
Create  → Apply patterns, document discoveries
```

**Invoke**: `/design-review "<task description>"`
**Full doc**: @.claude/context/patterns/prompt-design-review.md

---

### DDLA: Discovery Pattern

**Purpose**: When exploring infrastructure or unfamiliar systems.

```
Discover  → Find services, configs, paths
Document  → Create context file in systems/
Link      → Add to paths-registry.yaml, symlinks if needed
Automate  → Create slash command if repeatable
```

---

### COSA: Information Capture Pattern

**Purpose**: When capturing new information or learnings.

```
Capture   → Quick note in appropriate location
Organize  → Move to structured location when refined
Structure → Format with templates
Automate  → Build workflows for repeated tasks
```

---

### Agent Selection Pattern

**Purpose**: Choose the right execution mechanism.

```
Need ONE thing?
  └─ Use a Command (/checkpoint)

Need guidance across MULTIPLE steps?
  └─ Reference a Skill (session-management)

Need autonomous COMPLEX execution?
  └─ Invoke an Agent (/deep-research)
```

**Full doc**: @.claude/context/patterns/agent-selection-pattern.md

---

## When to Apply PARC

Apply PARC before:
- Creating new files/directories
- Implementing multi-step features
- Making architectural decisions
- Changing existing patterns

Skip PARC for:
- Simple queries
- Single-file edits
- Following established procedures

---

*Reference document — load on demand*
