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
6. **MCP-First Tools**: Use MCP tools before bash commands when available
7. **Hub, Not Container**: AIfred tracks code projects but doesn't contain them. Code lives in `projects_root`.
8. **Scripts Over LLM**: Push logic into deterministic scripts (CLI layer) - AI creates automation once, execution flows through scripts.

---

## Key Files

| File | Purpose |
|------|---------|
| `.claude/context/_index.md` | Navigate the knowledge base |
| `.claude/context/session-state.md` | Current work status |
| `.claude/context/compaction-essentials.md` | Core context (survives compaction) |
| `.claude/context/projects/current-priorities.md` | Active tasks |
| `paths-registry.yaml` | Source of truth for all paths |

---

## Workflow Patterns

### DDLA: Discover -> Document -> Link -> Automate
When exploring infrastructure:
1. **Discover**: Find services, configs, paths
2. **Document**: Create context file in `.claude/context/systems/`
3. **Link**: Add to `paths-registry.yaml`, create symlinks if needed
4. **Automate**: Create slash command if you'll do it again

### COSA: Capture -> Organize -> Structure -> Automate
For new information:
1. **Capture**: Quick note in `knowledge/notes/`
2. **Organize**: Move to appropriate location when refined
3. **Structure**: Format properly with templates
4. **Automate**: Build workflows for repeated tasks

### PARC: Prompt -> Assess -> Relate -> Create
Before implementing significant tasks:
1. **Prompt**: What's being asked?
2. **Assess**: Do existing patterns apply?
3. **Relate**: How does this fit the architecture?
4. **Create**: Apply patterns, document discoveries

---

## Project Management

AIfred is a hub that orchestrates code projects stored elsewhere.

- New projects → Clone to `projects_root`, register in `paths-registry.yaml`, create context file
- GitHub URLs → Auto-detected and registered
- Project context → `.claude/context/projects/<name>.md`

---

## Environment Profiles

AIfred uses composable **environment profiles** that determine which hooks, permissions, patterns, and agents are active.

Profiles stack: `general` (always) + selected layers (`homelab`, `development`, `production`).

| Profile | What It Adds |
|---------|-------------|
| **general** | Audit logging, security hooks, session management |
| **homelab** | Docker validation, port conflict detection, health monitoring |
| **development** | Project detection, orchestration, parallel-dev, branch protection |
| **production** | Strict security, deployment gates, destructive command blocking |

See `profiles/README.md` for full documentation.

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

## Skills System

Skills are comprehensive workflow guides that bundle related commands, hooks, and patterns:

| Skill | Purpose | Key Commands |
|-------|---------|--------------|
| session-management | Session lifecycle | `/checkpoint`, `/end-session` |
| infrastructure-ops | Health checks and monitoring | `/health-report` |
| parallel-dev | Autonomous parallel development | `/parallel-dev:plan`, `/parallel-dev:start` |
| orchestration | Task orchestration with fresh-context | `/orchestration:plan`, `/orchestration:status` |
| structured-planning | Guided conversational planning | `/plan`, `/plan:new`, `/plan:review` |
| project-lifecycle | Project creation and registration | Project commands |
| system-utilities | Core CLI utilities | `/link-external`, `/sync-git` |
| upgrade | Self-improvement and discovery | `/upgrade` |

---

## Available Commands

| Category | Commands |
|----------|---------|
| **Setup** | `/setup`, `/profile` |
| **Session** | `/checkpoint`, `/end-session`, `/audit-log`, `/capture`, `/history` |
| **Infrastructure** | `/health-report`, `/docker-restart`, `/backup-status` |
| **Git** | `/sync-git`, `/commits:push-all`, `/commits:status` |
| **Planning** | `/design-review`, `/plan`, `/plan:new`, `/plan:review` |
| **Orchestration** | `/orchestration:plan`, `/orchestration:status`, `/orchestration:resume` |
| **Development** | `/parallel-dev:plan`, `/parallel-dev:start`, `/parallel-dev:validate`, `/parallel-dev:merge` |
| **Utilities** | `/link-external`, `/upgrade`, `/telos`, `/context-analyze` |

---

## Agents

OpenCode agents available via `@agent-name` syntax or Tab to switch:

| Agent | Purpose |
|-------|---------|
| `@docker-deployer` | Deploy and configure Docker services |
| `@service-troubleshooter` | Diagnose infrastructure issues |
| `@deep-research` | In-depth topic investigation |
| `@memory-bank-synchronizer` | Sync docs with code changes |
| `@code-analyzer` | Analyze codebase structure and patterns |

Switch between **build** (full access) and **plan** (read-only) modes with Tab.

---

## Memory Usage

### Store in Memory MCP
- **Decisions**: Why you chose one approach over another
- **Relationships**: Service A depends on Service B
- **Events**: When things were installed, migrated, or broke
- **Lessons**: Solutions that worked, patterns to follow

### Store in Context Files
- Detailed documentation, procedures, configuration references, troubleshooting guides

### Never Store
- Secrets or credentials, temporary states, information already in files

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

Both CLIs share context files, knowledge base, external sources, and path registry.

---

## Directory Structure

```
AIfred/
├── AGENTS.md               # This file (OpenCode instructions)
├── opencode.json           # OpenCode configuration
├── profiles/               # Environment profile definitions
│   ├── general.yaml        # Base layer (always active)
│   ├── homelab.yaml        # Docker, NAS, monitoring
│   ├── development.yaml    # Code projects, CI/CD
│   └── production.yaml     # Security hardening
├── .opencode/
│   ├── agent/              # Custom agent definitions
│   └── command/            # Custom slash commands
├── .claude/
│   ├── CLAUDE.md           # Claude Code instructions
│   ├── settings.json       # Claude Code permissions (from profiles)
│   ├── context/            # Knowledge base (37 files)
│   ├── commands/           # Slash commands (48)
│   ├── agents/             # Agent definitions (11)
│   ├── hooks/              # Automation hooks (38)
│   ├── skills/             # Workflow skills (8)
│   ├── jobs/               # Cron jobs
│   └── logs/               # Audit logs
├── scripts/                # CLI automation scripts (16+)
├── knowledge/              # Documentation and reference
├── external-sources/       # Symlinks to external data
├── paths-registry.yaml     # Source of truth for paths
└── setup-phases/           # 7-phase setup wizard
```

---

## Response Style

- Be concise and practical
- Suggest documenting discoveries
- Ask clarifying questions about paths and preferences
- Think in reusable patterns, not one-off solutions
- Reference context files when giving advice

---

## Project Status

Check `.claude/config/active-profile.yaml` for current configuration, or run `/profile`.

If not yet configured, run `/setup` to get started.

---

*AIfred v2.2.0 - Your Personal AI Infrastructure Assistant*
*Compatible with Claude Code and OpenCode*
