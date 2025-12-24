# AIfred Project Plan

**Version**: 1.0
**Created**: 2025-12-24
**Status**: In Development

---

## Vision

AIfred is a **Claude Code starter kit** for personal AI infrastructure. It provides battle-tested design patterns, automated setup, and a framework for building an intelligent assistant that understands your systems.

**Target Users**: Home lab enthusiasts who want to accelerate their Claude Code setup with proven patterns. Both newcomers learning best practices and experienced users wanting a solid foundation.

---

## Core Principles

1. **Outcome-Focused Setup**: Ask about what users want to accomplish, not technical specifics
2. **Progressive Automation**: Start automated, let users dial back if needed
3. **Pattern-Driven**: Enforce consistent, repeatable patterns that work
4. **Context-Efficient**: Minimize token usage through smart memory and context management
5. **Self-Documenting**: The system documents itself as it grows

---

## The /setup Command

The heart of AIfred is a comprehensive, multi-phase setup process that transforms a blank slate into a fully-configured AI assistant.

### Setup Phases

```
Phase 1: System Discovery
├── Detect OS, hardware, network
├── Find existing Docker installation
├── Scan for running services
├── Identify storage/NAS mounts
└── Network service discovery (optional)

Phase 2: Purpose Interview
├── "What will you use this for?"
├── Automation preferences (full/guided/manual)
├── Primary focus areas (infrastructure/development/both)
├── Existing tools to integrate
└── Security/privacy preferences

Phase 3: Foundation Setup
├── Create directory structure
├── Initialize paths-registry.yaml
├── Set up knowledge base templates
├── Configure CLAUDE.md
└── Set up settings.json (allow/deny lists)

Phase 4: Docker & MCP Integration
├── Install Docker if needed (automated)
├── Deploy MCP Gateway (Memory MCP core)
├── Configure based on outcomes from Phase 2
├── Verify connectivity
└── Seed initial memory entities

Phase 5: Hooks & Automation
├── Install core hooks
├── Configure session management
├── Set up cron jobs (log rotation, pruning)
├── Create end-session workflow
└── Configure permission prompting levels

Phase 6: Agent Deployment
├── Deploy starter agents based on focus areas
├── Initialize agent memory
├── Create agent templates
└── Set up results/sessions directories

Phase 7: Finalization
├── Generate summary documentation
├── Move setup artifacts to archive
├── Verify all systems operational
├── Create "next steps" guide
└── Optional: Push to user's GitHub
```

### Post-Setup Cleanup

When setup completes, the `/setup-phases/` directory is moved to `.claude/archive/setup/` so it doesn't pollute the working context.

---

## Core Components

### 1. Directory Structure

```
AIfred/
├── .claude/
│   ├── CLAUDE.md                 # Core instructions
│   ├── settings.json             # Permissions
│   ├── settings.local.json       # User overrides (gitignored)
│   ├── context/
│   │   ├── _index.md             # Context navigation
│   │   ├── session-state.md      # Session continuity
│   │   ├── systems/              # Infrastructure docs
│   │   │   └── _template.md
│   │   ├── projects/
│   │   │   └── current-priorities.md
│   │   ├── workflows/
│   │   │   ├── session-exit.md
│   │   │   └── _template.md
│   │   └── integrations/
│   │       └── memory-usage.md
│   ├── commands/
│   │   ├── setup.md              # THE setup command
│   │   ├── end-session.md        # Session management
│   │   ├── discover.md           # Service discovery
│   │   ├── health-check.md       # System health
│   │   └── README.md
│   ├── agents/
│   │   ├── _template-agent.md
│   │   ├── docker-deployer.md
│   │   ├── service-troubleshooter.md
│   │   ├── deep-research.md
│   │   ├── memory/
│   │   ├── sessions/
│   │   └── results/
│   ├── hooks/
│   │   ├── README.md
│   │   ├── audit-logger.js
│   │   ├── session-tracker.js
│   │   ├── session-exit-enforcer.js
│   │   ├── docker-health-check.js
│   │   ├── secret-scanner.js
│   │   ├── context-reminder.js
│   │   └── memory-maintenance.js   # NEW
│   ├── jobs/
│   │   ├── log-rotation.sh
│   │   ├── memory-prune.sh
│   │   └── README.md
│   ├── logs/
│   │   └── .gitkeep
│   └── archive/
│       └── setup/                  # Setup moves here when complete
├── knowledge/
│   ├── docs/
│   │   ├── getting-started.md
│   │   ├── patterns.md
│   │   └── automation-guide.md
│   ├── notes/
│   └── templates/
├── external-sources/               # Created by setup
├── paths-registry.yaml             # Created by setup
├── setup-phases/                   # Setup workflow definitions
│   ├── 01-system-discovery.md
│   ├── 02-purpose-interview.md
│   ├── 03-foundation-setup.md
│   ├── 04-mcp-integration.md
│   ├── 05-hooks-automation.md
│   ├── 06-agent-deployment.md
│   └── 07-finalization.md
├── docker/                         # MCP Gateway stack
│   └── mcp-gateway/
│       └── docker-compose.yml
├── scripts/
│   └── install-docker.sh
└── README.md
```

### 2. Core Hooks (Always Installed)

| Hook | Purpose |
|------|---------|
| `audit-logger.js` | Log all tool executions |
| `session-tracker.js` | Track session lifecycle |
| `session-exit-enforcer.js` | Remind about exit procedures |
| `docker-health-check.js` | Verify container health post-changes |
| `secret-scanner.js` | Prevent credential commits |
| `context-reminder.js` | Prompt for documentation updates |
| `memory-maintenance.js` | Track entity access for pruning |

### 3. Optional Hooks (Based on Setup Answers)

| Hook | When Installed |
|------|----------------|
| `compose-validator.js` | Docker focus |
| `port-conflict-detector.js` | Docker focus |
| `network-validator.js` | Docker focus |
| `branch-protection.js` | Development focus |
| `code-style-enforcer.js` | Development focus |
| `mcp-enforcer.js` | When MCP installed |

### 4. Starter Agents

**docker-deployer**: Deploys and configures Docker services
- Reads compose files
- Validates before deploy
- Verifies health post-deploy
- Documents new services

**service-troubleshooter**: Diagnoses infrastructure issues
- 6-phase diagnostic tree
- Log analysis
- Pattern matching from past issues
- Memory-enabled learning

**deep-research**: In-depth topic investigation
- Web search integration
- Source gathering
- Comprehensive reports
- Citation tracking

### 5. Memory MCP Strategy

**What to Store**:
- Decisions and rationale
- System relationships
- Temporal events (installs, migrations, incidents)
- Lessons learned
- Configuration patterns

**What NOT to Store**:
- Detailed documentation (use context files)
- Secrets/credentials
- Temporary states
- Information already in files

**Metadata Tracking** (NEW):
```json
{
  "entity": "Entity Name",
  "created": "2025-12-24",
  "last_accessed": "2025-12-24",
  "access_count": 5,
  "last_updated": "2025-12-24"
}
```

**Pruning Strategy**:
- After 90 days without access, move to "cold storage" context file
- Entity metadata stored in `.claude/agents/memory/entity-metadata.json`
- Weekly cron job checks access patterns
- Entities are soft-removed (archived, not deleted)

---

## Automation Levels

Users choose during setup:

### Level 1: Full Automation
- All safe operations run without prompting
- Session exit automated
- Memory updates automatic
- Agents run autonomously

### Level 2: Guided Automation
- Major changes require confirmation
- Session exit shows checklist
- Memory updates prompted
- Agents report before acting

### Level 3: Manual Control
- Most operations prompt
- Session exit is reminder only
- Memory updates manual
- Agents wait for approval

---

## Cron Jobs

| Job | Schedule | Purpose |
|-----|----------|---------|
| `log-rotation.sh` | Daily 2 AM | Rotate audit.jsonl, archive after 90 days |
| `memory-prune.sh` | Weekly Sunday 3 AM | Archive inactive entities, update metadata |
| `session-cleanup.sh` | Weekly | Remove agent sessions older than 90 days |

---

## Template Repository vs Claude Skill

**Template Repository** (Recommended):
- User clones repo
- Runs `/setup` to customize
- Full control over files
- Easy to fork and modify
- Standard git workflow

**Claude Skill** (Alternative):
- Installed via `/install-skill AIfred`
- Self-contained package
- Less transparent (files hidden)
- Harder to customize
- Would need skill infrastructure

**Recommendation**: Start as template repo. Consider skill packaging later for simpler distribution.

---

## Success Metrics

A successful AIfred installation has:

1. **Functional session management** - End sessions cleanly, pick up where left off
2. **Working memory** - Decisions and learnings persisted
3. **Discovery capability** - Can find and document new services
4. **Automated maintenance** - Logs rotate, memory prunes without intervention
5. **Documented infrastructure** - Context files for discovered systems
6. **Trusted automation** - Permission levels match user comfort

---

## Development Phases

### Phase 1: Foundation (Current Session)
- [x] Create project structure
- [ ] Build core CLAUDE.md
- [ ] Create settings.json template
- [ ] Write setup phases 1-3
- [ ] Initial commit and push

### Phase 2: Setup Engine
- [ ] Complete all 7 setup phases
- [ ] System discovery scripts
- [ ] Purpose interview prompts
- [ ] Docker installation script

### Phase 3: MCP Integration
- [ ] MCP Gateway docker-compose
- [ ] Memory MCP configuration
- [ ] Entity metadata tracking
- [ ] Pruning automation

### Phase 4: Hooks & Agents
- [ ] All 7 core hooks
- [ ] 3 starter agents
- [ ] Agent templates
- [ ] Memory initialization

### Phase 5: Polish
- [ ] Comprehensive documentation
- [ ] Test on fresh system
- [ ] User feedback integration
- [ ] Release v1.0

---

## Open Questions

1. **Network scanning**: How aggressive should discovery be? (security implications)
2. **Windows support**: Focus Linux-first or support Windows from start?
3. **Cloud providers**: Include AWS/GCP/Azure discovery or keep local-only?

---

*This plan will evolve as we build. Updated: 2025-12-24*
