# Jarvis — Project Aion Master Archon

**Version 1.0.0** | Derived from [AIfred baseline](https://github.com/davidmoneil/AIfred) commit `dc0e8ac`

Jarvis is the master Archon of **Project Aion** — a highly autonomous, self-improving AI infrastructure and software-development assistant. Built on the [AIfred](https://github.com/davidmoneil/AIfred) foundation by David O'Neil, Jarvis extends it with enhanced tooling, stricter workflows, and self-evolution capabilities.

---

## What is Project Aion?

Project Aion is a collection of specialized AI assistants called **Archons**, each optimized for specific domains:

| Archon | Role | Status |
|--------|------|--------|
| **Jarvis** | Master Archon — Dev + Infrastructure + Archon Builder | Active v1.0.0 |
| **Jeeves** | Always-On — Personal automation via scheduled jobs | Concept |
| **Wallace** | Creative Writer — Fiction and long-form content | Concept |

Archons are derived from the AIfred baseline but follow a **divergent development track**. They share common ancestry but evolve independently.

> **Important**: The AIfred baseline repository is **read-only** from Project Aion's perspective. Jarvis may only pull from upstream for sync/diff — never edit it directly.

---

## Quick Start

```bash
git clone -b Project_Aion https://github.com/davidmoneil/AIfred.git Jarvis
cd Jarvis
claude
/setup
```

> **Note**: Development occurs on the `Project_Aion` branch. The `main` branch is the read-only AIfred baseline.

The `/setup` command guides you through configuration, adapting to your goals and preferences.

---

## Key Capabilities

### Jarvis-Specific

- **Archon Builder**: Create and configure new Archons (Jeeves, Wallace, etc.)
- **Upstream Sync**: Controlled porting from AIfred baseline (pull → diff → propose → apply)
- **Self-Evolution**: Reflect, propose changes, validate with benchmarks, version bump
- **Versioning**: Semantic versioning with lineage tracking
- **Auditability**: All operations logged with full traceability

### Inherited from AIfred

- **Intelligent Memory**: Persistent knowledge graph via Memory MCP
- **Session Management**: Clean handoffs with `/end-session`
- **Infrastructure Awareness**: Auto-discovery of Docker services
- **Automation Hooks**: Audit logging, security scanning, health checks
- **Specialized Agents**: docker-deployer, service-troubleshooter, deep-research

---

## Design Patterns

### PARC: Prompt → Assess → Relate → Create
Design review before implementation — check existing patterns first.

### DDLA: Discover → Document → Link → Automate
When you find something new: discover, document, link to knowledge base, automate.

### COSA: Capture → Organize → Structure → Automate
For new information: capture quickly, organize properly, structure, then automate.

---

## Directory Structure

```
Jarvis/
├── VERSION                 # Current version (1.0.0)
├── CHANGELOG.md            # Release history
├── README.md               # This file
├── AGENTS.md               # OpenCode instructions
├── docs/
│   └── project-aion/       # Project Aion documentation
│       ├── archon-identity.md    # Archon definitions
│       └── versioning-policy.md  # Versioning rules
├── .claude/
│   ├── CLAUDE.md           # Claude Code instructions
│   ├── settings.json       # Claude Code permissions
│   ├── context/            # Knowledge base
│   ├── commands/           # Slash commands
│   ├── agents/             # Agent definitions
│   ├── hooks/              # Automation hooks
│   └── logs/               # Audit logs
├── scripts/
│   └── bump-version.sh     # Version bump utility
├── knowledge/              # Documentation
├── external-sources/       # Symlinks to external data
└── paths-registry.yaml     # Source of truth for paths
```

---

## Versioning

Jarvis uses semantic versioning: `MAJOR.MINOR.PATCH`

| Bump | When |
|------|------|
| PATCH | Benchmarks, tests, docs, minor fixes |
| MINOR | New features, normal development |
| MAJOR | Breaking changes, major restructuring |

```bash
# Bump version
./scripts/bump-version.sh patch   # 1.0.0 -> 1.0.1
./scripts/bump-version.sh minor   # 1.0.0 -> 1.1.0
./scripts/bump-version.sh major   # 1.0.0 -> 2.0.0
```

See [docs/project-aion/versioning-policy.md](docs/project-aion/versioning-policy.md) for details.

---

## Commands

| Command | Description |
|---------|-------------|
| `/setup` | Initial configuration wizard |
| `/end-session` | Clean session exit with documentation |
| `/checkpoint` | Save state for MCP-required restart |
| `/design-review` | PARC pattern design review |
| `/health-check` | System health verification |

---

## Agents

| Agent | Purpose |
|-------|---------|
| `docker-deployer` | Deploy and configure Docker services |
| `service-troubleshooter` | Diagnose infrastructure issues |
| `deep-research` | In-depth topic investigation |

---

## Upstream Relationship

Jarvis periodically syncs with the AIfred baseline through a controlled process:

1. **Pull**: Fetch AIfred baseline main
2. **Diff**: Compare against Jarvis
3. **Classify**: Safe / unsafe / manual review
4. **Propose**: Generate port with rationale
5. **Apply**: After review, apply to Jarvis only

A port log tracks decisions with "adopt / adapt / reject" status.

---

## Requirements

- **Claude Code** (primary) or **OpenCode** (secondary)
- **Git**: For version control
- **Docker** (optional): For MCP servers and services
- **macOS/Linux**: Primary support

---

## License

MIT License - See LICENSE file for details.

---

## Acknowledgments

- [AIfred](https://github.com/davidmoneil/AIfred) by David O'Neil — the foundation this Archon is built upon
- Anthropic — for Claude Code and the AI tooling ecosystem

---

*Jarvis v1.0.0 — Project Aion Master Archon*
*Derived from AIfred baseline commit `dc0e8ac` (2026-01-03)*
