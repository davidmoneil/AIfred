# Jarvis — Project Aion Master Archon

**Version 1.9.5** | Derived from [AIfred baseline](https://github.com/davidmoneil/AIfred) commit `2ea4e8b`

Jarvis is the master Archon of **Project Aion** — a highly autonomous, self-improving AI infrastructure and software-development assistant. Built on the [AIfred](https://github.com/davidmoneil/AIfred) foundation by David O'Neil, Jarvis extends it with enhanced tooling, stricter workflows, and self-evolution capabilities.

---

## Quick Start

```bash
cd Jarvis
claude
/setup    # First time only
```

For returning users, Jarvis automatically loads session state and continues from previous work.

**Full documentation**: [docs/user-guide.md](docs/user-guide.md)

---

## What is Project Aion?

Project Aion is a collection of specialized AI assistants called **Archons**, each optimized for specific domains:

| Archon | Role | Status |
|--------|------|--------|
| **Jarvis** | Master Archon — Dev + Infrastructure + Archon Builder | Active v1.9.5 |
| **Jeeves** | Always-On — Personal automation via scheduled jobs | Concept |
| **Wallace** | Creative Writer — Fiction and long-form content | Concept |

> **Important**: The AIfred baseline repository is **read-only** from Project Aion's perspective. Jarvis may only pull from upstream for sync/diff — never edit it directly.

---

## Key Capabilities

### Core Features

- **Intelligent Memory**: Persistent knowledge graph via Memory MCP
- **Session Management**: Clean handoffs with `/end-session`
- **Context Management**: Automatic checkpoint and recovery system
- **Specialized Agents**: docker-deployer, service-troubleshooter, deep-research
- **Self-Evolution**: Reflect, propose changes, validate, version bump

### Installed Components (v1.9.5)

- **18 Hooks**: Automation, security, and audit logging
- **4 Custom Agents**: Specialized task handlers
- **16 Plugins**: Extended capabilities
- **12+ MCPs**: Tiered tool servers

---

## Directory Structure

```
Jarvis/
├── .claude/                    # Jarvis Ecosystem (runtime)
│   ├── CLAUDE.md               # Quick reference
│   ├── persona/                # Jarvis identity specification
│   ├── context/                # Knowledge base and patterns
│   ├── commands/               # All slash commands
│   ├── agents/                 # Agent definitions
│   ├── hooks/                  # Automation hooks
│   ├── skills/                 # On-demand skill definitions
│   ├── reports/                # Operational reports
│   └── legal/                  # Attribution and licenses
├── projects/
│   └── project-aion/           # Development artifacts
│       ├── roadmap.md          # PR-1 through PR-14
│       ├── plans/              # Implementation designs
│       ├── reports/            # PR-specific deliverables
│       └── ideas/              # Future proposals
├── docs/
│   └── user-guide.md           # User documentation
├── scripts/                    # Utility scripts
├── VERSION                     # Current version
├── CHANGELOG.md                # Release history
└── paths-registry.yaml         # Path source of truth
```

---

## Commands

| Command | Description |
|---------|-------------|
| `/setup` | Initial configuration wizard |
| `/end-session` | Clean session exit with commit |
| `/checkpoint` | Save state for restart |
| `/tooling-health` | Validate MCPs/plugins/hooks |
| `/context-budget` | Check context usage |
| `/design-review` | PARC pattern check |

---

## Agents

| Agent | Purpose |
|-------|---------|
| `docker-deployer` | Deploy and configure Docker services |
| `service-troubleshooter` | Diagnose infrastructure issues |
| `deep-research` | Multi-source research with citations |
| `memory-bank-synchronizer` | Sync documentation with code |

---

## Design Patterns

### PARC: Prompt → Assess → Relate → Create
Design review before implementation — check existing patterns first.

### Two Conceptual Spaces
- **Jarvis Ecosystem** (`.claude/`): Runtime and operational files
- **Project Aion** (`projects/project-aion/`): Development artifacts

---

## Requirements

- **Claude Code**: Primary interface
- **Git**: Version control
- **Docker** (optional): For MCP servers
- **macOS/Linux**: Primary support

---

## License

MIT License - See LICENSE file for details.

---

## Acknowledgments

- [AIfred](https://github.com/davidmoneil/AIfred) by David O'Neil — the foundation
- Anthropic — for Claude Code and Claude
- See [.claude/legal/ATTRIBUTION.md](.claude/legal/ATTRIBUTION.md) for full credits

---

*Jarvis v1.9.5 — Project Aion Master Archon*
*Derived from AIfred baseline commit `2ea4e8b`*
