# AIfred

**Your Personal AI Infrastructure Starter Kit**

AIfred provides battle-tested design patterns, automated setup, and a framework for building an intelligent assistant that understands your systems. Works with **Claude Code** and **OpenCode**.

## What's New in v2.1.0 (2026-02-05)

Enhanced hooks, patterns, and automation from AIProjects sync:

- **6 New Hooks** - skill-router, planning-mode-detector, priority-validator, compose-validator, context-usage-tracker, index-sync
- **3 New Patterns** - fresh-context execution, secret management (SOPS + age), external tool evaluation
- **3 New Scripts** - fresh-context-loop.sh, priority-cleanup.sh, claude-history-archiver.sh
- **2 New Skills** - system-utilities, orchestration (enhanced with fresh-context)
- **Fresh Context Execution** - Run orchestration tasks in isolated Claude instances to avoid context pollution
- **Secret Management** - SOPS + age encryption pattern for Docker secrets (security by default)
- **Hook Format Update** - All hooks now use stdin/stdout command format with matcher-based registration

### v2.0 (2026-01-21)

Major sync from AIProjects implementing "Scripts over LLM" philosophy:

- **18 Design Patterns** - Including capability-layering, code-before-prompts, autonomous-execution
- **26 Hooks** - Pattern detection, security (branch-protection, credential-guard), LSP guidance
- **7 Skills** - upgrade, structured-planning, parallel-dev, session-management, and more
- **16 CLI Scripts** - Deterministic operations (checkpoint, sync-git, discover-docker, etc.)
- **TELOS Framework** - Strategic goal alignment system
- **Pattern Detection** - Audit logger tracks which patterns are being used

---

## Quick Start

### With Claude Code
```bash
git clone https://github.com/davidmoneil/AIfred.git
cd AIfred
claude
/setup
```

### With OpenCode
```bash
git clone https://github.com/davidmoneil/AIfred.git
cd AIfred
opencode
/init    # Generate initial context
/setup   # Run configuration wizard
```

The `/setup` command guides you through configuration, adapting to your goals and preferences.

---

## Dual CLI Support

AIfred supports both **Claude Code** (Anthropic) and **OpenCode** (open source):

| Feature | Claude Code | OpenCode |
|---------|-------------|----------|
| Instructions | `.claude/CLAUDE.md` | `AGENTS.md` |
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

## What You Get

### Intelligent Memory
- Persistent knowledge graph that remembers decisions, relationships, and lessons learned
- Smart pruning that archives inactive knowledge without losing it
- Access tracking to understand what information matters most

### Session Management
- Clean session handoffs with `/end-session`
- Automatic state tracking so you can pick up where you left off
- Session notes for complex work

### Infrastructure Awareness
- Auto-discovery of Docker services
- System documentation that writes itself
- Paths registry for external resources

### Automation Hooks (Claude Code)
- Audit logging for all operations
- Security scanning before commits
- Health checks after Docker changes
- Documentation reminders
- **Skill routing** - Auto-loads parent skill context for slash commands
- **Planning detection** - Suggests structured planning for complex requests
- **Context tracking** - Monitors token usage (important for non-Max users)
- **Compose validation** - Validates docker-compose files before execution

### Specialized Agents
- **docker-deployer**: Safely deploy and configure services
- **service-troubleshooter**: Diagnose issues with learned patterns
- **deep-research**: In-depth investigation with citations

### Skills (Comprehensive Workflows)
- **session-management**: End-to-end session lifecycle (start, track, checkpoint, exit)
- **project-lifecycle**: Project creation, registration, and consolidation
- **infrastructure-ops**: Health checks, container discovery, monitoring
- **parallel-dev**: Autonomous parallel development with planning, execution, validation, and merge
- **system-utilities**: Core CLI utilities (git sync, priority cleanup, history archival)
- **orchestration**: Task orchestration with fresh-context execution mode

---

## Design Patterns

AIfred is built on proven patterns from real-world usage:

### DDLA: Discover → Document → Link → Automate
When you find something new, AIfred helps you discover it, document it, link it to your knowledge base, and automate interactions with it.

### COSA: Capture → Organize → Structure → Automate
For new information: capture it quickly, organize into the right location, structure it properly, then automate if it repeats.

### Session Continuity
Every session leaves a trail. `session-state.md` tracks what you were doing, and `/end-session` ensures clean handoffs.

### Memory vs Context
- **Memory MCP**: Decisions, relationships, temporal events, lessons learned
- **Context Files**: Detailed documentation, procedures, reference material

---

## Directory Structure

```
AIfred/
├── AGENTS.md               # OpenCode instructions
├── opencode.json           # OpenCode configuration
├── .opencode/
│   ├── agent/              # OpenCode agent definitions
│   └── command/            # OpenCode slash commands
├── .claude/
│   ├── CLAUDE.md           # Claude Code instructions
│   ├── settings.json       # Claude Code permissions
│   ├── context/            # Knowledge base (shared)
│   ├── commands/           # Claude Code slash commands
│   ├── agents/             # Claude Code agents
│   ├── hooks/              # Automation hooks
│   ├── jobs/               # Cron jobs
│   └── logs/               # Audit logs
├── knowledge/              # Documentation (shared)
├── external-sources/       # Symlinks to external data (shared)
├── paths-registry.yaml     # Source of truth for paths (shared)
└── setup-phases/           # Setup wizard definitions
```

---

## Requirements

- **AI CLI**: Claude Code or OpenCode
- **Git**: For version control
- **Docker** (optional): For MCP servers and service management
- **Linux/macOS**: Primary support (Windows experimental)

---

## Configuration

### Automation Levels

During setup, you choose your automation level:

| Level | Description |
|-------|-------------|
| **Full** | Everything runs without prompting |
| **Guided** | Major changes need confirmation |
| **Manual** | Most operations prompt for approval |

### MCP Integration

AIfred works best with the Memory MCP for persistent knowledge. During setup, you can enable:

- **Memory MCP**: Knowledge graph storage (recommended)
- **Docker MCP**: Container management
- **Filesystem MCP**: Cross-directory access
- **Browser MCP**: Web automation (Playwright)

---

## Commands

| Command | Description |
|---------|-------------|
| `/setup` | Run the setup wizard |
| `/end-session` | Clean session exit with documentation |
| `/discover <target>` | Discover and document services |
| `/health` | System health verification |

---

## Agents

Use agents via `@agent-name` (OpenCode) or Task tool (Claude Code):

| Agent | Purpose |
|-------|---------|
| `docker-deployer` | Deploy and configure Docker services |
| `service-troubleshooter` | Diagnose infrastructure issues |
| `deep-research` | In-depth topic investigation |

---

## Customization

After setup, customize by:

### Claude Code
1. Edit `.claude/CLAUDE.md` for project-specific instructions
2. Add commands in `.claude/commands/`
3. Create agents in `.claude/agents/`
4. Configure hooks as needed

### OpenCode
1. Edit `AGENTS.md` for project-specific instructions
2. Add commands in `.opencode/command/`
3. Create agents in `.opencode/agent/`
4. Configure MCP servers in `opencode.json`

---

## Contributing

AIfred is designed to be forked and customized. If you build something useful, consider contributing back:

1. Fork the repository
2. Create a feature branch
3. Submit a pull request

---

## License

MIT License - See LICENSE file for details.

---

## Acknowledgments

Built on patterns developed for personal AI infrastructure management. Inspired by the need for repeatable, maintainable AI assistant configurations.

---

*AIfred v2.1.0 - Because your AI assistant should understand your infrastructure.*
