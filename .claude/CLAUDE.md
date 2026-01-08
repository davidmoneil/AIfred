# Jarvis — Project Aion Master Archon

**Version**: 1.8.4 | **Baseline**: AIfred commit `af66364`

Master Archon for infrastructure, development, and self-improvement. AIfred baseline is **read-only**.

## Quick Start

- **First time?** Run `/setup`
- **Returning?** Check @.claude/context/session-state.md

---

## Essential Links

| Category | Primary | Secondary |
|----------|---------|-----------|
| **Session** | @.claude/context/session-state.md | @.claude/skills/session-management/SKILL.md |
| **Tasks** | @.claude/context/projects/current-priorities.md | @paths-registry.yaml |
| **Tooling** | @.claude/context/integrations/capability-matrix.md | @.claude/context/patterns/context-budget-management.md |
| **Roadmap** | @projects/project-aion/roadmap.md | @CHANGELOG.md |
| **Index** | @.claude/context/_index.md | — |

---

## Core Principles

1. **Context-First**: Check `.claude/context/` before advising
2. **Document Discoveries**: Update context files with new learnings
3. **Hub, Not Container**: Code lives in `projects_root`, Jarvis just tracks
4. **Baseline Read-Only**: Never edit AIfred repo — only pull for sync
5. **Memory for Decisions**: Details in context files, decisions in Memory MCP

---

## Key Commands

| Command | Purpose |
|---------|---------|
| `/setup` | Initial configuration |
| `/end-session` | Clean exit with commit |
| `/checkpoint` | Save state for MCP restart |
| `/tooling-health` | Validate MCPs/plugins/skills |
| `/design-review` | PARC pattern check |
| `/sync-aifred-baseline` | Analyze upstream changes |

---

## Quick Selection

**Tool Selection**: @.claude/context/integrations/capability-matrix.md
**Agent/Skill Choice**: @.claude/context/patterns/agent-selection-pattern.md
**MCP Loading**: @.claude/context/patterns/context-budget-management.md

### Agents

| Agent | Purpose |
|-------|---------|
| `docker-deployer` | Docker deployment |
| `service-troubleshooter` | Issue diagnosis |
| `deep-research` | Multi-source research |
| `memory-bank-synchronizer` | Doc sync |

### High-Value Plugins

| Plugin | Use Case |
|--------|----------|
| `feature-dev` | Complex features (7-phase) |
| `pr-review-toolkit` | Thorough PR review |
| `ralph-wiggum` | Autonomous iteration |
| `hookify` | Create prevention hooks |

---

## Session Workflow

**Start**: Check session-state.md → Check baseline updates → Continue work
**During**: Use TodoWrite → Update context → Store decisions in Memory
**End**: Run `/end-session`

Full: @.claude/context/patterns/session-start-checklist.md

---

## Response Style

- Concise and practical
- Reference context files
- Ask rather than assume
- Propose slash commands for repeated tasks

---

## Project Status

**Setup**: Configured 2026-01-03 | **Mode**: Full Automation
**Installed**: 18 hooks, 4 agents, 16 plugins

Full details: @.claude/context/configuration-summary.md

---

## Detailed Reference

For full documentation on any topic:
- **Full CLAUDE.md**: @.claude/CLAUDE-full-reference.md
- **All patterns**: @.claude/context/patterns/
- **All standards**: @.claude/context/standards/
- **All integrations**: @.claude/context/integrations/

---

*Jarvis v1.8.4 — Updated 2026-01-09*
