# Context Index

Central navigation for the AIfred knowledge base.

---

## Quick Access

| Need | Location |
|------|----------|
| Current work status | @.claude/context/session-state.md |
| Active tasks | @.claude/context/projects/current-priorities.md |
| All paths | @paths-registry.yaml |

---

## Knowledge Base Structure

### Systems (Infrastructure Documentation)
```
systems/
├── _template.md          # Template for new services
└── (your services here)
```

**Purpose**: Reference documentation for infrastructure. Created via `/discover` command.

### Projects (Active Initiatives)
```
projects/
└── current-priorities.md  # Active todos and priorities
```

**Purpose**: Track ongoing work and priorities.

### Workflows (Repeatable Procedures)
```
workflows/
├── session-exit.md       # End session procedure
└── _template.md          # Template for new workflows
```

**Purpose**: Step-by-step guides for recurring tasks.

### Integrations (API & Integration Guides)
```
integrations/
└── memory-usage.md       # Memory MCP guidelines
```

**Purpose**: Documentation for connecting systems.

### Learning (Background Knowledge)
```
learning/
└── (notes and insights)
```

**Purpose**: Background knowledge that informs decisions.

---

## File Lifecycle

1. **Discovery**: New findings go in `knowledge/notes/`
2. **Documentation**: Clean notes move to `knowledge/docs/`
3. **Context**: Stable, frequently-used info becomes context files
4. **Automation**: Proven processes become slash commands

---

## Maintenance

**Create a context file when**:
- You've referenced information 3+ times
- It's critical for a system or project
- It contains commands/paths you need regularly

**Update existing files when**:
- You discover new information
- A configuration changed
- You solved a problem worth documenting

**Refactor when**:
- A file exceeds 300 lines (split it)
- Multiple files duplicate info (consolidate)
- Structure doesn't match how you work

---

## Setup Status

**Run `/setup` to configure your environment and populate this knowledge base.**

After setup, discovered systems will appear in the `systems/` directory.

---

*Last Updated: Initial creation*
