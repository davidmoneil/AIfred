# Agents

**Purpose**: Custom agent definitions, memory, and execution state.

**Layer**: Pneuma (capabilities)

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

| Agent | Purpose | Model | Tools |
|-------|---------|-------|-------|
| `code-analyzer` | Pre-implementation codebase analysis | default | All |
| `code-implementer` | Code writing with git workflow | default | All |
| `code-review` | Technical quality review (AC-03 L1) | default | All |
| `code-tester` | Testing + Playwright automation | default | All |
| `compression-agent` | JICM v5.8 context compression | sonnet | Read, Write, Glob, Grep |
| `context-compressor` | Generic context compression (pre-JICM) | opus | Read, Write, Glob, TodoWrite |
| `deep-research` | Multi-source technical research | sonnet | Read, Grep, Glob, Bash, WebFetch, WebSearch, TodoWrite |
| `docker-deployer` | Docker service deployment | sonnet | Read, Grep, Glob, Bash, Write, Edit, TodoWrite |
| `jicm-agent` | Autonomous JICM monitoring (background) | haiku | Read, Write, Glob, Bash |
| `memory-bank-synchronizer` | Documentation sync with code | sonnet | Read, Grep, Glob, Bash, Write, Edit, TodoWrite |
| `project-manager` | Progress review (AC-03 L2) | default | All |
| `service-troubleshooter` | Infrastructure issue diagnosis | sonnet | Read, Grep, Glob, Bash, WebFetch, WebSearch, TodoWrite |

> **Note**: `compression-agent` (JICM v5.8) supersedes `context-compressor` for JICM workflows.
> The `context-compressor` remains available for non-JICM compression scenarios.

## Creating New Agents

1. Copy `_template-agent.md`
2. Fill in YAML frontmatter
3. Define agent behavior
4. Test agent invocation

**Pattern reference**: See `.claude/context/patterns/agent-invocation-pattern.md` for invocation standards.

## Memory System

Agents store learnings in `memory/<agent-name>/learnings.json`.
These persist across sessions and inform future behavior.

---

*Jarvis — Pneuma Layer (Capabilities)*
