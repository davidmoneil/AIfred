# AIfred

[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

**A configuration framework that turns Claude Code into an AI that understands your entire environment -- not just one project at a time.**

Most Claude Code setups live inside a single project. Your AI assistant knows that one codebase, follows that one set of rules, and forgets everything when you switch to something else. AIfred sits above your projects as a central hub, carrying context about your infrastructure, your decisions, and your workflows across everything you work on.

AIfred is built on the latest Claude Code capabilities -- hooks across all lifecycle events, skills with auto-invocation, composable subagents, and the full settings hierarchy. As Claude Code evolves, AIfred evolves with it.

Fork it, run the setup wizard, pick your environment profiles, and you have a battle-tested AI assistant in minutes instead of weeks.

```bash
git clone https://github.com/your-username/AIfred.git
cd AIfred
claude    # or: opencode
/setup
```

---

## Why Does This Exist?

Claude Code out of the box is powerful but empty. You get a blank CLAUDE.md and start from scratch every time. After months of daily use managing a home lab, building projects, and automating infrastructure, clear patterns emerged:

- **The same problems keep getting solved from scratch.** Session handoffs, Docker health checks, git workflows, project discovery -- these are universal.
- **Context dies between projects.** Decisions made in one project are invisible to another. Your AI assistant has no memory of what you learned yesterday.
- **Infrastructure work is different from coding.** Every Claude Code framework out there optimizes for writing and reviewing code. Nobody built one for managing Docker services, monitoring systems, or running a home lab.

AIfred captures those patterns into a reusable, composable framework.

---

## Who Is This For?

**Home lab operators** who manage Docker services, NAS storage, monitoring stacks, and want an AI assistant that understands their infrastructure.

**Developers managing multiple projects** who want consistent workflows, session continuity, and cross-project context instead of isolated per-project CLAUDE.md files.

**Claude Code power users** who want to see what's possible with hooks, skills, agents, and profiles working together as a system -- and want a head start instead of building from scratch.

---

## What Makes It Different?

### 1. A Hub, Not a Single-Project Config

Most Claude Code customizations live inside one project directory. AIfred is designed as a central orchestration point that tracks and manages multiple projects. It maintains a path registry, creates context files for each project, and carries institutional knowledge across everything you work on. When you discover something in Project A, that knowledge is available when you're working in Project B.

### 2. Built for Infrastructure, Not Just Code

Every other Claude Code framework helps you write and review code faster. AIfred also helps you deploy Docker services, discover infrastructure, monitor health, troubleshoot systems, validate compose files, detect port conflicts, and manage a home lab. It includes infrastructure-specific hooks that no other framework has.

### 3. Composable Environment Profiles

No other project in the Claude Code ecosystem has this. You stack YAML layers -- `general + homelab`, or `general + development`, or all three -- and each layer adds specific hooks, permissions, patterns, and agents. Like Docker Compose overrides, but for your AI assistant's behavior.

### 4. An Integrated System, Not a Collection

Most projects give you a bag of 100+ commands or a set of personas. AIfred integrates hooks, commands, skills, agents, profiles, and a setup wizard where each component reinforces the others. The skill router loads context when you invoke commands. The orchestration detector breaks down complex tasks automatically. The audit logger tracks everything for observability. It's a framework, not a folder of markdown files.

---

## How It Works

AIfred layers five capabilities on top of Claude Code:

### Profiles Shape Your Environment

You choose which layers apply to your setup. Each layer activates the right hooks, permissions, and patterns:

| Profile | What It Adds |
|---------|-------------|
| **general** (always active) | Audit logging, security scanning, session management |
| **homelab** | Docker validation, port conflict detection, health monitoring |
| **development** | Project tracking, orchestration, parallel-dev, branch protection |
| **production** | Strict security, deployment gates, destructive command blocking |

```bash
# Pick your combination
node scripts/profile-loader.js --layers general,homelab,development
```

### Hooks Automate the Repetitive

27 JavaScript hooks run automatically at key moments -- before tool calls, after edits, on session start. They handle audit logging, security checks, document protection, Docker health validation, skill routing, planning detection, and documentation reminders. You don't invoke them; they just work.

### Commands Give You Shortcuts

49 slash commands for common operations: `/setup` to configure, `/checkpoint` to save state, `/discover-docker` to document services, `/sync-git` to push across projects, `/end-session` for clean handoffs.

### Skills Guide Complex Workflows

Skills are comprehensive workflow guides that bundle related commands, hooks, and patterns together. When you need session management, infrastructure ops, parallel development, or task orchestration, skills provide step-by-step guidance instead of making you remember which commands to run.

### Agents Handle Autonomous Tasks

Specialized agents work independently on complex tasks: deploying Docker services safely, troubleshooting infrastructure issues with learned patterns, or doing deep research with web sources and citations.

---

## Feature Overview

### Environment Profiles

Composable YAML layers that configure your entire AIfred installation:

```bash
/profile              # Show current layers
/profile list         # Available profiles
/profile add <layer>  # Add a layer
/profile remove <x>   # Remove a layer
```

See [`profiles/README.md`](profiles/README.md) for full documentation.

### Automation Hooks (27)

| Category | Examples |
|----------|---------|
| **Security** | Branch protection, credential guard, compose validation |
| **Document Protection** | Document guard with 4-tier protection, credential scanning, structural checks |
| **Operations** | Docker health checks, port conflict detection, restart loop detection |
| **Workflow** | Skill routing, planning detection, orchestration, context tracking |
| **Observability** | Audit logging, session tracking, documentation sync triggers |

### Slash Commands (49)

| Category | Commands |
|----------|---------|
| **Setup** | `/setup`, `/profile` |
| **Session** | `/checkpoint`, `/end-session`, `/audit-log` |
| **Infrastructure** | `/discover-docker`, `/check-health`, `/check-services` |
| **Projects** | `/register-project`, `/new-code-project`, `/consolidate-project` |
| **Git** | `/sync-git`, `/push-all-commits` |
| **Planning** | `/plan`, `/design-review`, `/orchestration:plan` |
| **Development** | `/parallel-dev:plan`, `/parallel-dev:start`, `/parallel-dev:validate` |

### Skills (8)

| Skill | Purpose |
|-------|---------|
| **session-management** | Session lifecycle: start, track, checkpoint, exit |
| **infrastructure-ops** | Health checks, container discovery, monitoring |
| **parallel-dev** | Autonomous parallel development with planning and validation |
| **orchestration** | Multi-phase task tracking with dependency management |
| **structured-planning** | Guided conversational planning for designs and features |
| **project-lifecycle** | Project creation, registration, and consolidation |
| **system-utilities** | Core CLI utilities: git sync, priority cleanup, history archival |
| **upgrade** | Self-improvement: discover and apply updates automatically |

### Agents

| Agent | Purpose |
|-------|---------|
| **docker-deployer** | Deploy and configure Docker services safely |
| **service-troubleshooter** | Diagnose infrastructure issues with learned patterns |
| **deep-research** | In-depth topic investigation with web sources and citations |

### Design Patterns (18+)

Proven patterns extracted from real daily usage:

| Pattern | What It Does |
|---------|-------------|
| **DDLA** | Discover, Document, Link, Automate -- systematic knowledge capture |
| **COSA** | Capture, Organize, Structure, Automate -- information management |
| **PARC** | Prompt, Assess, Relate, Create -- design review before implementation |
| **Capability Layering** | Scripts for deterministic work, AI for judgment calls |
| **Fresh Context Execution** | Run tasks in isolated Claude instances to avoid context pollution |
| **Autonomous Execution** | Scheduled Claude jobs via cron with permission tiers |

Plus patterns for secret management, memory storage, MCP loading strategies, cross-project tracking, and more.

### Session Continuity

Every session leaves a trail. State is tracked automatically so you can pick up where you left off, even days later. Clean handoffs with `/end-session` ensure nothing is lost between sessions.

### Intelligent Memory

Persistent knowledge graph (via Memory MCP) that remembers decisions, relationships, and lessons learned. Smart pruning archives inactive knowledge without losing it. Access tracking identifies what information matters most.

---

## Dual CLI Support

AIfred works with both **Claude Code** (Anthropic) and **OpenCode** (open source):

| Feature | Claude Code | OpenCode |
|---------|-------------|----------|
| Instructions | `.claude/CLAUDE.md` | `AGENTS.md` |
| Settings | `.claude/settings.json` | `opencode.json` |
| Commands | `.claude/commands/*.md` | `.opencode/command/*.md` |
| Agents | `.claude/agents/*.md` | `.opencode/agent/*.md` |

Both share the context files, knowledge base, path registry, and external sources.

---

## Configuration

### Automation Levels

During setup, you choose how much autonomy your AI assistant gets:

| Level | Behavior |
|-------|----------|
| **Full** | Everything runs without prompting |
| **Guided** | Major changes need confirmation |
| **Manual** | Most operations prompt for approval |

### MCP Integration

AIfred works best with MCP servers for extended capabilities:

- **Memory MCP** -- Persistent knowledge graph (recommended)
- **Docker MCP** -- Container management
- **Filesystem MCP** -- Cross-directory file access
- **Browser MCP** -- Web automation via Playwright

The setup wizard walks you through enabling the ones you need.

---

## Directory Structure

```
AIfred/
├── profiles/               # Environment profile definitions (YAML)
│   ├── general.yaml        # Base layer (always active)
│   ├── homelab.yaml        # Docker, NAS, monitoring
│   ├── development.yaml    # Code projects, CI/CD
│   └── production.yaml     # Security hardening
├── .claude/
│   ├── CLAUDE.md           # Claude Code instructions
│   ├── settings.json       # Permissions (generated from profiles)
│   ├── context/            # Knowledge base (37 files)
│   ├── commands/           # Slash commands (49)
│   ├── agents/             # Agent definitions
│   ├── hooks/              # Automation hooks (27)
│   ├── skills/             # Workflow skills (8)
│   └── orchestration/      # Task orchestration configs
├── .opencode/              # OpenCode-specific configs
├── scripts/                # CLI automation scripts (16+)
├── knowledge/              # Documentation and reference
├── external-sources/       # Symlinks to external data
├── paths-registry.yaml     # Source of truth for all paths
└── setup-phases/           # 7-phase setup wizard
```

---

## Requirements

- **Claude Code** or **OpenCode**
- **Git**
- **Node.js** (for profile loader)
- **Docker** (optional, for infrastructure features)
- **Linux/macOS** (Windows experimental)

---

## Changelog

### v2.3.0 (2026-02-08) -- Document Guard

- Document Guard V1: 4-tier file protection with pattern-based rules (critical/high/medium/low)
- 7 check types: no_write, credential scanning, key deletion, section/heading preservation, frontmatter protection, shebang preservation
- Document Guard V2: Optional semantic relevance validation via local Ollama (off by default)
- Feature registry for discoverability of configurable features
- Time-limited single-use override mechanism for approved exceptions
- Full audit logging to `.claude/logs/document-guard.jsonl`

### v2.2.0 (2026-02-05) -- Environment Profiles

- Composable YAML profile system with 4 layers
- Zero-dependency profile loader (`node scripts/profile-loader.js`)
- 5 new hooks: docker-validator, mcp-enforcer, port-conflict-detector, paths-registry-sync, service-registration-detector
- `/profile` command for managing layers
- Profile-driven setup wizard questions

### v2.1.0 (2026-02-05) -- Enhanced Automation

- 6 new hooks: skill-router, planning-mode-detector, priority-validator, compose-validator, context-usage-tracker, index-sync
- 3 new patterns: fresh-context execution, secret management (SOPS + age), external tool evaluation
- Fresh context execution for isolated task processing
- 3 new CLI scripts

### v2.0.0 (2026-01-21) -- Foundation

- 18 design patterns from real-world usage
- 26 automation hooks with matcher-based registration
- 7 skills: upgrade, structured-planning, parallel-dev, session-management, and more
- 16 CLI scripts with deterministic operations
- TELOS strategic goal alignment framework

---

## Contributing

AIfred is designed to be forked and customized. If you build something useful, consider contributing back:

1. Fork the repository
2. Create a feature branch
3. Submit a pull request

---

## Learn More

- [profiles/README.md](profiles/README.md) -- Profile system documentation
- [docs/PROJECT-PLAN.md](docs/PROJECT-PLAN.md) -- Architecture and development roadmap
- [knowledge/docs/quick-start.md](knowledge/docs/quick-start.md) -- Getting started guide

---

## License

Apache License 2.0 -- See [LICENSE](LICENSE) for details.
