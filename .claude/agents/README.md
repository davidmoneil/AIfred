# Agents

**Purpose**: Custom agent definitions, memory, and execution state.

**Layer**: Spirit (capabilities)

---

## Structure

| Directory | Contents |
|-----------|----------|
| `*.md` | Agent definition files |
| `_template-agent.md` | Template for new agents |
| `_archive/` | Archived agent definitions |
| `memory/` | Agent learning storage |
| `results/` | Agent output storage |
| `sessions/` | Agent session tracking |

## Available Agents

| Agent | Purpose |
|-------|---------|
| `code-analyzer` | Pre-implementation analysis |
| `code-implementer` | Code writing with git workflow |
| `code-review` | Technical quality review |
| `code-tester` | Testing + Playwright automation |
| `context-compressor` | Intelligent context compression |
| `deep-research` | Multi-source research |
| `docker-deployer` | Docker deployment |
| `memory-bank-synchronizer` | Doc sync |
| `project-manager` | Progress review |
| `service-troubleshooter` | Issue diagnosis |

## Creating New Agents

1. Copy `_template-agent.md`
2. Fill in YAML frontmatter
3. Define agent behavior
4. Test agent invocation

## Memory System

Agents store learnings in `memory/<agent-name>/learnings.json`.
These persist across sessions and inform future behavior.

---

*Jarvis — Spirit Layer (Capabilities)*
