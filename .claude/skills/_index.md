# Skills Directory

Skills are comprehensive workflow guides that consolidate related commands, hooks, and patterns.
Unlike commands (single actions), skills provide end-to-end guidance for complex workflows.

**Created**: 2026-01-06
**Last Updated**: 2026-02-07
**Source**: AIfred baseline af66364 (ported from AIProjects)

---

## Available Skills

| Skill | Description | Related Commands |
|-------|-------------|------------------|
| [session-management](session-management/SKILL.md) | Session lifecycle management | /checkpoint, /end-session |
| [autonomous-commands](autonomous-commands/SKILL.md) | Execute native Claude Code commands via signal-based automation | N/A (replaces 17 deleted auto-* commands) |
| [mcp-validation](mcp-validation/SKILL.md) | Validate MCP installation and configuration | /validate-mcp |
| [plugin-decompose](plugin-decompose/SKILL.md) | Decompose plugins for analysis | /plugin-decompose |
| [docx](docx/SKILL.md) | Word document creation and editing | N/A |
| [xlsx](xlsx/SKILL.md) | Excel spreadsheet operations | N/A |
| [pdf](pdf/SKILL.md) | PDF manipulation and forms | N/A |
| [pptx](pptx/SKILL.md) | PowerPoint presentation creation | N/A |
| [mcp-builder](mcp-builder/SKILL.md) | Create MCP servers | N/A |
| [skill-creator](skill-creator/SKILL.md) | Create new skills | N/A |
| [example-skill](example-skill/SKILL.md) | Skill template reference | N/A |
| [ralph-loop](ralph-loop/SKILL.md) | Iterative development via Ralph Wiggum technique | /ralph-loop, /cancel-ralph |
| [jarvis-status](jarvis-status/SKILL.md) | Jarvis autonomic system status (AC-01 through AC-09) | N/A (replaces old /status) |
| [context-management](context-management/SKILL.md) | JICM context monitoring, analysis, and optimization | /context-budget, /context-checkpoint, /smart-compact |
| [self-improvement](self-improvement/SKILL.md) | AC-05/06/07/08 orchestration for continuous improvement | /self-improve, /reflect, /evolve, /research, /maintain |
| [validation](validation/SKILL.md) | Tooling, infrastructure, and design validation | /tooling-health, /health-report, /validate-selection, /design-review |
| [filesystem-ops](filesystem-ops/SKILL.md) | File/directory operations via built-in tools (replaces filesystem MCP) | N/A |
| [git-ops](git-ops/SKILL.md) | Git operations via Bash commands (replaces git MCP) | N/A |
| [web-fetch](web-fetch/SKILL.md) | Web content retrieval via WebFetch/WebSearch (replaces fetch MCP) | N/A |
| [weather](weather/SKILL.md) | Weather information via wttr.in API | N/A |

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
---
```

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
