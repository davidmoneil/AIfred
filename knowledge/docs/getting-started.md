# Getting Started with AIfred

Your AIfred environment was configured on 2026-01-01.

## Your Configuration

- **Automation Level**: Full Automation (runs without asking)
- **Focus Areas**: All (Home Lab, Development, System Admin, Learning & Documentation)
- **Memory**: File-based context (using `.claude/context/` files)
- **Session Mode**: Automated (commits changes automatically)
- **Docker**: Not installed (MCP Gateway features unavailable)

## First Steps

✅ Setup complete! You're ready to use AIfred

### 2. Understand the Structure

```
AIfred/
├── .claude/
│   ├── CLAUDE.md         # Core instructions
│   ├── context/          # Knowledge base
│   ├── commands/         # Slash commands
│   ├── agents/           # AI agents
│   └── hooks/            # Automation
├── knowledge/            # Documentation
├── external-sources/     # Symlinks to external data
└── paths-registry.yaml   # Path source of truth
```

### 3. Learn Key Commands

| Command | Purpose |
|---------|---------|
| `/setup` | Initial configuration |
| `/end-session` | Clean session exit |
| `/discover <service>` | Document a service |
| `/health-check` | System verification |

---

## Daily Workflow

### Starting Work

1. Open terminal in AIfred directory
2. Run `claude`
3. Check session-state.md for context
4. Continue where you left off

### During Work

- Let Claude track tasks with TodoWrite
- Ask Claude to document discoveries
- Use agents for complex tasks

### Ending Work

Run `/end-session` to:
- Update session state
- Commit changes
- Prepare for next session

---

## Key Concepts

### Context Files

Located in `.claude/context/`, these contain:
- System documentation
- Workflows and procedures
- Project status

Claude reads these to understand your infrastructure.

### Memory MCP

If enabled, stores:
- Decisions and why you made them
- Relationships between systems
- Lessons learned

Persists across sessions.

### Agents

Specialized helpers for complex tasks:
- **docker-deployer**: Deploy services safely
- **service-troubleshooter**: Diagnose problems
- **deep-research**: Research topics thoroughly

---

## Common Tasks

### Documenting a New Service

```
/discover my-service
```

This will:
1. Inspect the container
2. Create documentation
3. Update paths-registry.yaml

### Troubleshooting

```
Ask: "n8n is returning errors"
```

Claude will:
1. Check container status
2. Review logs
3. Diagnose the issue
4. Suggest fixes

### Learning Something New

```
Ask: "Research best practices for Docker networking"
```

Claude will:
1. Search for information
2. Compile findings
3. Provide recommendations

---

## Customization

### Add a Command

Create `.claude/commands/my-command.md`:

```markdown
---
description: What this does
---

Your prompt here...
```

### Add an Agent

Copy `.claude/agents/_template-agent.md` and customize.

### Adjust Permissions

Edit `.claude/settings.json` to allow/deny operations.

---

## Need Help?

- Check `.claude/context/_index.md` for documentation
- Review the README.md
- Ask Claude directly!

---

*Welcome to AIfred - let's build something great.*
