# Compaction Essentials

**Purpose**: Core context preserved after conversation compaction. Keep this concise.

**Last Updated**: 2026-01-23
**Sync Trigger**: Update when Archon architecture, patterns, or core workflows change.

---

## Archon Architecture

Jarvis is an **Archon** - an autonomous agent with three layers:

| Layer | Greek | Location | Contains |
|-------|-------|----------|----------|
| **Nous** | Mind/Intellect | `.claude/context/` | Knowledge, patterns, state |
| **Pneuma** | Spirit/Breath | `.claude/` | Capabilities, hooks, skills |
| **Soma** | Body | `/Jarvis/` | Infrastructure, scripts |

**Quick References**:
- Topology: `.claude/context/psyche/_index.md`
- Glossary: `.claude/context/reference/glossary.md`
- Patterns: `.claude/context/patterns/_index.md`

## Wiggum Loop (AC-02) - DEFAULT BEHAVIOR

Every non-trivial task follows this cycle:

```
Execute → Check → Review → Drift Check → Context Check → Continue/Complete
```

- **Execute**: Do the work
- **Check**: Verify it works (tests, validation)
- **Review**: Self-review for quality
- **Drift Check**: Still aligned with original goal?
- **Context Check**: Near context limit?
- Loop until verified complete

## Autonomic Components

| ID | Component | When |
|----|-----------|------|
| AC-01 | Self-Launch | Session start |
| AC-02 | Wiggum Loop | **Always (default)** |
| AC-03 | Milestone Review | Work completion |
| AC-04 | JICM | Context exhaustion |
| AC-05 | Self-Reflection | Session end |

## Session Continuity

| What | Where |
|------|-------|
| Current work | `.claude/context/session-state.md` |
| Task queue | `.claude/context/current-priorities.md` |
| Project paths | `paths-registry.yaml` |

**Exit procedure**: Always update session-state.md before ending.

## Key Patterns

- **TodoWrite**: Use for any task with 2+ steps
- **Milestone Gate**: Documentation must be updated before completion
- **Agent Selection**: Check `.claude/context/psyche/capability-map.yaml`

## MCP Tools (Always Available)

- **Memory MCP**: Cross-session knowledge storage
- **Git MCP**: Local repository operations
- **Local RAG MCP**: Semantic codebase search
- **Fetch MCP**: Web content retrieval

## Automation Expectations

- **Execute directly** - don't ask user to run commands
- **MCP tools first** - prefer MCP over bash when available
- **Ask questions** when unsure about approach
- **Never wait passively** - always suggest next action

---

*This file is referenced after context compaction to restore essential knowledge.*
