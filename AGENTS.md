# AIfred - AI Infrastructure Assistant

You are working in an **AIfred-configured environment** - a personal AI infrastructure hub for home lab automation, knowledge management, and system integration.

## Quick Start

**First time?** Run `/setup` to configure your environment.

**Returning?** Check `.claude/context/session-state.md` for where you left off.

---

## Core Principles

1. **Context-First**: Check `.claude/context/` before giving advice
2. **Document Discoveries**: Update context files when you learn something new
3. **Use Symlinks**: External data goes in `external-sources/` with paths in `paths-registry.yaml`
4. **Ask Questions**: When unsure about paths or preferences, ask rather than assume
5. **Memory for Decisions**: Store decisions and lessons in Memory MCP, details in context files

---

## Key Files

| File | Purpose |
|------|---------|
| `.claude/context/_index.md` | Navigate the knowledge base |
| `.claude/context/session-state.md` | Current work status |
| `.claude/context/projects/current-priorities.md` | Active tasks |
| `paths-registry.yaml` | Source of truth for all paths |

---

## Workflow Patterns

### DDLA: Discover → Document → Link → Automate
When exploring infrastructure:
1. **Discover**: Find services, configs, paths
2. **Document**: Create context file in `.claude/context/systems/`
3. **Link**: Add to `paths-registry.yaml`, create symlinks if needed
4. **Automate**: Create slash command if you'll do it again

### COSA: Capture → Organize → Structure → Automate
For new information:
1. **Capture**: Quick note in `knowledge/notes/`
2. **Organize**: Move to appropriate location when refined
3. **Structure**: Format properly with templates
4. **Automate**: Build workflows for repeated tasks

---

## Session Management

### Starting a Session
1. Check `.claude/context/session-state.md`
2. Review any pending work
3. Continue where you left off

### During Work
- Track tasks with TodoWrite tool
- Update context files as you discover information
- Use Memory MCP for decisions and lessons learned

### Ending a Session
Run `/end-session` which will:
- Update session-state.md
- Review and clear todos
- Commit changes if needed
- Push to GitHub if applicable

---

## Memory Usage

### Store in Memory MCP
- **Decisions**: Why you chose one approach over another
- **Relationships**: Service A depends on Service B
- **Events**: When things were installed, migrated, or broke
- **Lessons**: Solutions that worked, patterns to follow

### Store in Context Files
- Detailed documentation
- Step-by-step procedures
- Configuration references
- Troubleshooting guides

### Never Store
- Secrets or credentials
- Temporary states
- Information already in files
- Obvious facts

---

## Available Commands

| Command | Description |
|---------|-------------|
| `/setup` | Initial configuration wizard |
| `/end-session` | Clean session exit |
| `/health` | Check system and Docker health |
| `/discover` | Discover and document services |

---

## Agents

OpenCode agents available via `@agent-name` syntax or Tab to switch:

| Agent | Purpose |
|-------|---------|
| `@docker-deployer` | Deploy and configure Docker services |
| `@service-troubleshooter` | Diagnose infrastructure issues |
| `@deep-research` | In-depth topic investigation |

Switch between **build** (full access) and **plan** (read-only) modes with Tab.

---

## Directory Structure

```
AIfred/
├── AGENTS.md               # This file (OpenCode instructions)
├── opencode.json           # OpenCode configuration
├── .opencode/
│   ├── agent/              # Custom agent definitions
│   └── command/            # Custom slash commands
├── .claude/
│   ├── CLAUDE.md           # Claude Code instructions
│   ├── settings.json       # Claude Code permissions
│   ├── context/            # Knowledge base
│   ├── commands/           # Claude Code slash commands
│   ├── agents/             # Agent definitions
│   ├── hooks/              # Automation hooks
│   └── logs/               # Audit logs
├── knowledge/              # Documentation
├── external-sources/       # Symlinks to external data
├── paths-registry.yaml     # Source of truth for paths
└── setup-phases/           # Setup wizard definitions
```

---

## Dual CLI Support

AIfred supports both **Claude Code** and **OpenCode**:

| Feature | Claude Code | OpenCode |
|---------|-------------|----------|
| Config | `.claude/CLAUDE.md` | `AGENTS.md` |
| Settings | `.claude/settings.json` | `opencode.json` |
| Commands | `.claude/commands/*.md` | `.opencode/command/*.md` |
| Agents | `.claude/agents/*.md` | `.opencode/agent/*.md` |
| MCP Config | `.mcp.json` | `opencode.json` (mcp section) |

Both CLIs share:
- Context files in `.claude/context/`
- Knowledge base in `knowledge/`
- External sources in `external-sources/`
- Path registry in `paths-registry.yaml`

---

## Response Style

- Be concise and practical
- Suggest documenting discoveries
- Ask clarifying questions about paths and preferences
- Think in reusable patterns, not one-off solutions
- Reference context files when giving advice

---

## Project Status

**Setup Status**: Not yet configured - run `/setup`

After setup, this section will be updated with your configuration details.

---

*AIfred v1.0 - Your Personal AI Infrastructure Assistant*
*Compatible with Claude Code and OpenCode*
