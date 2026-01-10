# Jarvis User Guide

**Version**: 1.9.5
**Project Aion Master Archon**

---

## Quick Start

### First Session

1. Open terminal in the Jarvis directory
2. Run `claude`
3. Run `/setup` if first time
4. Otherwise: Jarvis will check session state and continue

### Returning Sessions

Jarvis automatically:
- Loads the persona specification
- Checks session state from previous work
- Verifies AIfred baseline for updates
- Awaits your direction or continues pending work

---

## Key Commands

| Command | Purpose | When to Use |
|---------|---------|-------------|
| `/setup` | Initial configuration | First time setup |
| `/end-session` | Clean exit with commit | End of work session |
| `/checkpoint` | Save state for restart | Before MCP changes |
| `/tooling-health` | Validate MCPs/plugins/hooks | Verify system health |
| `/context-budget` | Check context usage | Monitor token consumption |
| `/design-review` | PARC pattern check | Before major implementations |

---

## Working with Jarvis

### Starting Work

Simply describe what you need:
- "Help me implement X feature"
- "Debug this issue with Y"
- "Research best practices for Z"

Jarvis will:
1. Understand the task
2. Plan the approach
3. Execute with appropriate tools
4. Track progress with todos

### During Work

Jarvis uses several systems:
- **TodoWrite** — Task tracking (visible in sidebar)
- **Context files** — Stored knowledge in `.claude/context/`
- **Memory MCP** — Persistent decisions and relationships

### Ending Work

Run `/end-session` to:
- Update session state for next time
- Commit changes to git
- Document what was accomplished

---

## Jarvis Persona

Jarvis adopts a specific communication style:

- **Tone**: Calm, professional, technically precise
- **Address**: "sir" for formal requests, nothing for casual
- **Safety**: Always prefers reversible actions, confirms destructive operations
- **Humor**: Rare, dry, never during emergencies

See `.claude/persona/jarvis-identity.md` for full specification.

---

## Project Organization

Jarvis manages two conceptual spaces:

### Jarvis Ecosystem (`.claude/`)

Runtime and operational files:
- `agents/` — Agent definitions
- `commands/` — Slash commands
- `context/` — Knowledge and patterns
- `hooks/` — Automation scripts
- `reports/` — Operational reports

### Project Aion (`projects/project-aion/`)

Development artifacts:
- `roadmap.md` — Development plan
- `plans/` — Implementation designs
- `reports/` — PR-specific deliverables
- `ideas/` — Future proposals

---

## Tools and Capabilities

### Built-in Tools

| Tool | Purpose |
|------|---------|
| Read/Write/Edit | File operations |
| Glob/Grep | File search |
| Bash | Command execution |
| WebSearch/WebFetch | Web access |
| Task | Launch specialized agents |

### MCP Servers (Always-On)

| MCP | Purpose |
|-----|---------|
| Memory | Persistent knowledge graph |
| Filesystem | File system access |
| Git | Version control |
| Fetch | Web fetching |

### Custom Agents

| Agent | Use Case |
|-------|----------|
| `docker-deployer` | Deploy Docker services |
| `service-troubleshooter` | Diagnose issues |
| `deep-research` | Multi-source research |
| `memory-bank-synchronizer` | Sync documentation |

---

## Common Tasks

### Creating a New Project

```
/create-project myproject
```

Or:
```
/register-project /path/to/existing/project
```

### Running Health Checks

```
/tooling-health
```

Reviews:
- MCP server status
- Plugin availability
- Hook validation

### Checking Context Usage

```
/context-budget
```

Shows:
- Current token consumption
- Breakdown by category
- Recommendations

---

## Troubleshooting

### High Context Usage

If context exceeds 70%:
1. Run `/smart-compact`
2. Or manually checkpoint and `/clear`

### MCP Connection Issues

1. Run `/tooling-health`
2. Check `.claude/settings.json`
3. Verify API keys in environment

### Session State Lost

1. Check `.claude/context/session-state.md`
2. Review git log for recent commits
3. Check checkpoint file if exists

---

## Getting Help

- **Context index**: `.claude/context/_index.md`
- **Patterns**: `.claude/context/patterns/`
- **CLAUDE.md**: Quick reference for Jarvis
- Ask Jarvis directly!

---

*Jarvis v1.9.5 — Project Aion User Guide*
