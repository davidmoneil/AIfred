# Patterns Index

Reusable implementation patterns extracted from recurring practices.

---

## Active Patterns

| Pattern | Purpose | Quick Reference |
|---------|---------|-----------------|
| [Agent Selection](agent-selection-pattern.md) | Choose between custom agents, built-in subagents, skills, direct tools | Simple → Direct tools; Repeating → Custom agent |
| [Memory Storage](memory-storage-pattern.md) | When/how to store in Memory MCP | Issues/decisions → Store; Routine → Skip |
| [PARC Design Review](prompt-design-review.md) | Pre-implementation pattern check | Prompt → Assess → Relate → Create |

---

## Usage

Before implementing significant tasks:

1. Check if a pattern exists for the task type
2. Apply the pattern explicitly
3. Document any new patterns discovered
4. Update pattern docs if pattern evolves

---

## Creating New Patterns

Create a pattern when:
- Same approach is used 3+ times
- Multiple commands share similar logic
- A decision framework would help consistency

Use the existing patterns as templates.

---

**Last Updated**: 2026-01-01
