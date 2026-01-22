# Skills Index

Comprehensive workflow guides that consolidate related commands, hooks, and patterns.

**Last Updated**: 2026-01-21
**Total Skills**: 7

---

## Active Skills

| Skill | Purpose | Type | Tools/ |
|-------|---------|------|--------|
| **session-management** | Session lifecycle (start, track, checkpoint, exit) | Core | No |
| **project-lifecycle** | Project creation, registration, consolidation | Infrastructure | No |
| **infrastructure-ops** | Health checks, container discovery, monitoring | Infrastructure | No |
| **parallel-dev** | Autonomous parallel development (planning, execution, validation, merge) | Development | Yes |
| **upgrade** | Self-improvement system (discover, analyze, propose, implement) | Maintenance | No |
| **structured-planning** | Guided conversational planning (new designs, reviews, features) | Planning | Yes |
| **_template** | Code Before Prompts reference implementation | Reference | Yes |

---

## Skill Categories

### Core Workflows
- **session-management** - Essential session operations

### Infrastructure Management
- **project-lifecycle** - Project setup and management
- **infrastructure-ops** - Service monitoring and health

### Development Workflows
- **parallel-dev** - Advanced parallel development
- **structured-planning** - Planning and design

### System Maintenance
- **upgrade** - Self-improvement and discovery

### Reference
- **_template** - Teaching template for skill development

---

## Code Before Prompts Pattern

Skills with `tools/` directories follow the Code Before Prompts pattern:
- Deterministic operations in TypeScript
- AI handles intelligence and decision-making
- All tools use `execFileSync` for safety

**Skills with tools/**:
- parallel-dev
- structured-planning
- _template

**Next to convert**:
- session-management (planned)
- upgrade (evaluate)

---

## Skill Structure

```
.claude/skills/<name>/
├── SKILL.md              # Main documentation
├── config.json           # Configuration (optional)
├── tools/                # TypeScript deterministic code
│   ├── index.ts          # CLI entry point
│   ├── types.ts          # Type definitions
│   └── operations.ts     # Core operations
├── templates/            # Document templates
└── workflows/            # Workflow diagrams (optional)
```

---

## When to Use Skills vs Commands vs Agents

```
Need to do ONE thing?
  └─ Use a Command (e.g., /checkpoint)

Need guidance across MULTIPLE steps?
  └─ Reference a Skill (e.g., session-management)

Need autonomous COMPLEX task execution?
  └─ Invoke an Agent (e.g., /agent memory-bank-synchronizer)
```

---

*AIfred Skills v2.0 - Major sync from AIProjects (2026-01-21)*
