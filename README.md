# AIfred

**Your Personal AI Infrastructure Starter Kit for Claude Code**

AIfred provides battle-tested design patterns, automated setup, and a framework for building an intelligent assistant that understands your systems.

---

## Quick Start

```bash
# Clone the repository
git clone https://github.com/davidmoneil/AIfred.git
cd AIfred

# Start Claude Code
claude

# Run the setup wizard
/setup
```

The `/setup` command will guide you through a comprehensive configuration process, asking about your goals and preferences to create a customized AI infrastructure.

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

### Automation Hooks
- Audit logging for all operations
- Security scanning before commits
- Health checks after Docker changes
- Documentation reminders

### Specialized Agents
- **docker-deployer**: Safely deploy and configure services
- **service-troubleshooter**: Diagnose issues with learned patterns
- **deep-research**: In-depth investigation with citations

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
├── .claude/
│   ├── CLAUDE.md           # Core instructions
│   ├── settings.json       # Permission configuration
│   ├── context/            # Knowledge base
│   ├── commands/           # Slash commands
│   ├── agents/             # AI agents
│   ├── hooks/              # Automation hooks
│   ├── jobs/               # Cron jobs
│   └── logs/               # Audit logs
├── knowledge/              # Documentation
├── external-sources/       # Symlinks to external data
├── paths-registry.yaml     # Source of truth for paths
└── setup-phases/           # Setup wizard definitions
```

---

## Requirements

- **Claude Code**: Anthropic's CLI tool
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
- **Browser MCP**: Web automation

---

## Commands

| Command | Description |
|---------|-------------|
| `/setup` | Run the setup wizard |
| `/end-session` | Clean session exit with documentation |
| `/discover <target>` | Discover and document services |
| `/health-check` | System health verification |

---

## Customization

After setup, customize by:

1. **Editing CLAUDE.md**: Add project-specific instructions
2. **Creating commands**: Add your own slash commands in `.claude/commands/`
3. **Adding agents**: Create specialized agents in `.claude/agents/`
4. **Configuring hooks**: Enable/disable hooks as needed

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

*AIfred - Because your AI assistant should understand your infrastructure.*
