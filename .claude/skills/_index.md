# Skills Directory

Skills are comprehensive workflow guides that consolidate related commands, hooks, and patterns.
Unlike commands (single actions), skills provide end-to-end guidance for complex workflows.

**Created**: 2026-01-05
**Last Updated**: 2026-01-16
**Ported from**: AIProjects

---

## Available Skills

| Skill | Description | Related Commands |
|-------|-------------|------------------|
| [session-management](session-management/SKILL.md) | Session lifecycle management | /checkpoint, /end-session |
| [project-lifecycle](project-lifecycle/SKILL.md) | Project creation, registration, consolidation | /create-project, /register-project |
| [infrastructure-ops](infrastructure-ops/SKILL.md) | Health checks, container discovery, monitoring | /health-report, /agent service-troubleshooter |
| [parallel-dev](parallel-dev/SKILL.md) | Autonomous parallel development | /parallel-dev:plan, /parallel-dev:start, /parallel-dev:validate, /parallel-dev:merge |

---

## Skills vs Commands vs Agents

| Type | Scope | When to Use | Example |
|------|-------|-------------|---------|
| **Skills** | Multi-step workflow | Need guidance across a workflow | Session lifecycle |
| **Commands** | Single action | Execute one specific task | /checkpoint |
| **Agents** | Autonomous execution | Complex task needing independent context | memory-bank-synchronizer |

### Decision Guide

```
Need to do ONE thing?
  └─ Use a Command (e.g., /checkpoint)

Need guidance across MULTIPLE steps?
  └─ Reference a Skill (e.g., session-management)

Need autonomous COMPLEX task execution?
  └─ Invoke an Agent (e.g., /agent memory-bank-synchronizer)
```

---

## Directory Structure

Each skill follows this structure:

```
.claude/skills/<skill-name>/
├── SKILL.md           # Main skill definition (required)
└── examples/          # Usage examples (optional)
    └── *.md
```

### Skill Frontmatter

```yaml
---
name: skill-name
version: 1.0.0
description: One-line description
category: workflow | infrastructure | development
tags: [tag1, tag2]
created: YYYY-MM-DD
context: fork | shared    # Execution isolation (optional)
agent: agent-name         # Associated agent (optional)
allowed-tools:            # Tool restrictions (optional)
  - Read
  - Write
  - Bash(pattern:*)
  - mcp__service__operation
---
```

### Extended Fields

| Field | Purpose |
|-------|---------|
| `context: fork` | Indicates skill can fork context (isolated execution) |
| `agent` | Links skill to autonomous agent for guided execution |
| `allowed-tools` | YAML array restricting which tools skill can invoke |

---

## Creating New Skills

When to create a skill:
1. Workflow spans multiple commands/hooks
2. Users frequently ask "how do I do X end-to-end?"
3. Related commands benefit from unified documentation

Skill checklist:
- [ ] Clear purpose and scope
- [ ] Quick actions table (need → action)
- [ ] Visual workflow diagram
- [ ] Component references (commands, hooks, patterns)
- [ ] Detailed step-by-step workflows
- [ ] Integration points with other systems

---

## Related Documentation

- @.claude/commands/ - Slash commands (single actions)
- @.claude/agents/ - Custom agents (autonomous execution)
- @.claude/context/patterns/agent-selection-pattern.md - When to use each type
