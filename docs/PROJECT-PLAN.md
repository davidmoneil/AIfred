# AIfred Project Plan

**Version**: 1.1.0
**Created**: 2025-12-24
**Updated**: 2026-02-12
**Status**: Active
**Versioning**: [docs/VERSIONING.md](VERSIONING.md) (Major.Minor.Patch)

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
├── Initialize Beads task management
├── Configure CLAUDE.md
└── Set up settings.json (allow/deny lists)

Phase 4: Docker & MCP Integration
├── Install Docker if needed (automated)
├── Deploy MCP Gateway (Memory MCP core)
├── Configure based on outcomes from Phase 2
├── Verify connectivity
└── Seed initial memory entities

Phase 5: Hooks & Automation
├── Install core hooks (including beads-actor.sh)
├── Configure session management
├── Set up Headless Claude dispatcher (cron)
├── Configure scheduled jobs (registry.yaml)
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
├── .beads/                         # Beads task management
│   ├── config.yaml.template        # Label conventions template
│   └── .gitignore                  # Ignore runtime DB files
├── .claude/
│   ├── CLAUDE.md                   # Core instructions
│   ├── settings.json               # Permissions (generated from profiles)
│   ├── settings.local.json         # User overrides (gitignored)
│   ├── context/                    # Knowledge base
│   │   ├── _index.md              # Context navigation
│   │   ├── session-state.md       # Session continuity
│   │   ├── systems/               # Infrastructure docs
│   │   ├── projects/              # Project context
│   │   ├── workflows/             # Workflow definitions
│   │   ├── patterns/              # Design patterns
│   │   ├── standards/             # Coding standards
│   │   └── integrations/          # Tool integrations
│   ├── commands/                   # Slash commands (49)
│   ├── agents/                     # Agent definitions
│   ├── hooks/                      # Automation hooks (38)
│   │   ├── beads-actor.sh         # Session provenance for Beads
│   │   └── *.js                   # JS hooks (audit, security, workflow)
│   ├── skills/                     # Workflow skills (8)
│   ├── jobs/                       # Headless Claude job system
│   │   ├── dispatcher.sh          # Master scheduler (cron entry point)
│   │   ├── executor.sh            # Per-job execution engine
│   │   ├── registry.yaml          # Job definitions and schedules
│   │   ├── personas/              # Safety tiers
│   │   │   ├── investigator/      # Read-only observer
│   │   │   ├── analyst/           # Research + write reports
│   │   │   └── troubleshooter/    # Diagnose + safe fixes
│   │   ├── lib/                   # Support libraries
│   │   │   ├── msgbus.sh          # Append-only message bus
│   │   │   ├── msg-relay.sh       # DND-aware delivery relay
│   │   │   ├── send-telegram.sh   # Telegram notifications
│   │   │   ├── dashboard.sh       # Observability dashboard
│   │   │   └── cost-report.sh     # Cost aggregation
│   │   └── state/                 # Runtime state (gitignored)
│   ├── orchestration/              # Task orchestration configs
│   ├── logs/
│   │   └── .gitkeep
│   └── archive/
│       └── setup/                  # Setup moves here when complete
├── profiles/                       # Environment profile definitions (YAML)
│   ├── general.yaml               # Base layer (always active)
│   ├── homelab.yaml               # Docker, NAS, monitoring
│   ├── development.yaml           # Code projects, CI/CD
│   └── production.yaml            # Security hardening
├── knowledge/
│   ├── docs/                      # User-facing documentation
│   ├── notes/                     # Session and research notes
│   └── templates/                 # Document templates
├── external-sources/               # Created by setup
├── paths-registry.yaml             # Created by setup
├── setup-phases/                   # Setup workflow definitions
│   ├── 00-prerequisites.md        # Dependency checks
│   ├── 01-system-discovery.md
│   ├── 02-purpose-interview.md
│   ├── 03-foundation-setup.md
│   ├── 04-mcp-integration.md
│   ├── 05-hooks-automation.md
│   ├── 06-agent-deployment.md
│   └── 07-finalization.md
├── scripts/                        # CLI automation scripts (16+)
│   ├── beads-aliases.sh           # Beads shell aliases
│   ├── profile-loader.js          # Profile → settings generator
│   └── ...
├── docs/                           # Architecture docs and images
└── README.md
```

### 2. Core Hooks (Always Installed via `general` profile)

| Hook | Purpose |
|------|---------|
| `audit-logger.js` | Log all tool executions |
| `session-tracker.js` | Track session lifecycle |
| `session-exit-enforcer.js` | Remind about exit procedures |
| `secret-scanner.js` | Prevent credential commits |
| `credential-guard.js` | Block credential exposure |
| `branch-protection.js` | Protect main/master branches |
| `skill-router.js` | Auto-load skill context for commands |
| `mcp-enforcer.js` | Validate MCP server availability |
| `beads-actor.sh` | Session provenance for Beads tasks |
| `document-guard.js` | 4-tier file protection |

### 3. Optional Hooks (Profile-Driven)

| Hook | Profile | Purpose |
|------|---------|---------|
| `docker-health-check.js` | homelab | Verify container health post-changes |
| `compose-validator.js` | homelab | Validate compose files before deploy |
| `docker-validator.js` | homelab | Docker operation validation |
| `port-conflict-detector.js` | homelab | Detect port conflicts |
| `restart-loop-detector.js` | homelab | Detect container restart loops |
| `orchestration-detector.js` | development | Auto-detect complex tasks |
| `planning-mode-detector.js` | development | Detect planning intent |
| `project-detector.js` | development | Auto-register new projects |
| `doc-sync-trigger.js` | development | Track code changes for doc sync |

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

## Scheduled Jobs

### Headless Claude (AI-Powered)

Single cron entry runs the dispatcher every 5 minutes:

```bash
*/5 * * * * /path/to/aifred/.claude/jobs/dispatcher.sh >> .claude/logs/headless/dispatcher.log 2>&1
```

The dispatcher handles all job scheduling via `registry.yaml`. Template jobs included:

| Job | Persona | Engine | Schedule | Purpose |
|-----|---------|--------|----------|---------|
| `health-summary` | investigator | claude-code | Every 12h | Infrastructure health check |
| `doc-sync-check` | investigator | claude-code | Weekly Sun 6am | Check for stale documentation |
| `ollama-test` | investigator | ollama | On-demand | Template for local AI jobs |

### Legacy Scripts (Deterministic)

| Job | Schedule | Purpose |
|-----|----------|---------|
| `memory-prune.sh` | Manual/Weekly | Archive inactive Memory MCP entities |
| `context-staleness.sh` | Manual/Weekly | Find outdated context files |

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

### Phase 1: Foundation -- COMPLETE (v2.0.0, 2026-01-21)
- [x] Create project structure
- [x] Build core CLAUDE.md
- [x] Create settings.json template
- [x] Write setup phases 1-7
- [x] 18 design patterns, 26 hooks, 7 skills, 16 CLI scripts
- [x] Initial commit and push

### Phase 2: Setup Engine -- COMPLETE (v2.0.0)
- [x] Complete all 7 setup phases
- [x] System discovery scripts
- [x] Purpose interview prompts
- [x] Docker installation script

### Phase 3: MCP Integration -- COMPLETE (v2.0.0)
- [x] MCP Gateway docker-compose
- [x] Memory MCP configuration
- [x] Entity metadata tracking
- [x] Pruning automation

### Phase 4: Hooks & Agents -- COMPLETE (v2.1.0, 2026-02-05)
- [x] 27 core + optional hooks
- [x] 3 starter agents (docker-deployer, service-troubleshooter, deep-research)
- [x] Agent templates
- [x] Skill routing, planning detection, orchestration detection

### Phase 5: Environment Profiles -- COMPLETE (v2.2.0, 2026-02-05)
- [x] Composable YAML profile system (4 layers)
- [x] Profile loader (zero-dependency Node.js)
- [x] Profile-driven hook activation
- [x] Dual CLI support (Claude Code + OpenCode)

### Phase 6: Document Protection -- COMPLETE (v2.3.0, 2026-02-08)
- [x] Document Guard V1: 4-tier file protection
- [x] Document Guard V2: Semantic validation via Ollama
- [x] Feature registry for discoverability
- [x] Override mechanism for approved exceptions

### Phase 7: Beads + Headless Claude -- COMPLETE (v2.4.0, 2026-02-12)
- [x] Beads task management as required dependency
- [x] Beads actor hook for session provenance
- [x] Beads shell aliases and config template
- [x] Setup wizard integration (prerequisites + foundation phase)
- [x] Headless Claude job system (dispatcher + executor)
- [x] 3 personas (investigator, analyst, troubleshooter) as safety tiers
- [x] Ollama engine routing for $0 local jobs
- [x] Message bus with Telegram notifications and DND
- [x] Observability dashboard with cost tracking
- [x] Prometheus metrics integration
- [x] 3 template jobs (health-summary, doc-sync-check, ollama-test)
- [x] Full sanitization of all personal references

### Phase 8: Distribution & Growth (Current)
- [x] Stay Current update system (component registry + manifests)
- [ ] Architecture diagrams and visual documentation
- [ ] "Introducing AIfred" blog post
- [ ] Community feedback and iteration
- [ ] Test on fresh system (clean install validation)

---

*Updated: 2026-02-12*
