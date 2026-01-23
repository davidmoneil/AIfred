# Pneuma Layer Topology

Detailed map of the Pneuma (capabilities) layer — `/.claude/`.

**Version**: 1.0.0

---

## Layer Overview

Pneuma is what Jarvis CAN DO — capabilities and character that enable action.

```
/.claude/
├── CLAUDE.md                 # Primary identity and behavior
├── CLAUDE-full-reference.md  # Extended reference
├── jarvis-identity.md        # Persona specification
├── settings.json             # Hook and project configuration
├── planning-tracker.yaml     # Active planning docs registry
│
├── context/                  # → Nous layer (see nous-map.md)
│
├── agents/                   # Custom agent definitions (14)
├── commands/                 # Slash commands (30+)
├── skills/                   # On-demand skills (11)
├── hooks/                    # Event automation (14)
├── scripts/                  # Session scripts (~20)
├── plugins/                  # Plugin definitions
│
├── state/                    # Runtime state files
├── config/                   # Configuration files
├── secrets/                  # Credentials (gitignored)
│
├── metrics/                  # Performance telemetry
├── reports/                  # Self-improvement outputs
├── logs/                     # Operational logs
│
├── test/                     # Test harnesses
├── review-criteria/          # PR review standards
├── legal/                    # Attribution, licenses
└── archive/                  # Historical capabilities
```

---

## Capability Directories

### agents/ — Custom Agent Definitions

| Agent | Purpose | Model |
|-------|---------|-------|
| code-analyzer | Pre-implementation analysis | Default |
| code-implementer | Code writing with git | Default |
| code-review | Technical quality review | Default |
| code-tester | Testing + Playwright | Default |
| context-compressor | Context compression | Haiku |
| deep-research | Multi-source research | Default |
| docker-deployer | Docker deployment | Default |
| memory-bank-synchronizer | Doc sync | Default |
| project-manager | Progress review | Default |
| service-troubleshooter | Issue diagnosis | Default |

**Structure**:
```
agents/
├── <agent>.md          # Agent definition
├── _template-agent.md  # Template for new agents
├── _archive/           # Archived agents
├── memory/             # Agent learning storage
├── results/            # Agent output storage
└── sessions/           # Agent session tracking
```

### commands/ — Slash Commands

| Category | Commands |
|----------|----------|
| Session | setup, end-session, checkpoint |
| Self-Improvement | reflect, evolve, research, maintain |
| Validation | tooling-health, design-review, validate-selection |
| Autonomous | auto-* (17 wrappers) |
| Orchestration | orchestration/plan, status, resume |

**Structure**:
```
commands/
├── <command>.md        # Command definition
├── commits/            # Commit-related commands
└── orchestration/      # Orchestration commands
```

### skills/ — On-Demand Skills

| Skill | Purpose |
|-------|---------|
| docx | Word document manipulation |
| xlsx | Spreadsheet with formulas |
| pdf | PDF manipulation |
| pptx | PowerPoint presentations |
| mcp-builder | MCP server development |
| mcp-validation | MCP testing |
| skill-creator | Skill development |
| session-management | Session lifecycle |
| autonomous-commands | Auto-* wrapper |

**Structure**:
```
skills/
├── <skill>/
│   ├── SKILL.md        # Skill definition
│   ├── scripts/        # Supporting scripts
│   ├── templates/      # Templates
│   └── reference/      # Reference docs
└── _shared/            # Shared resources
```

### hooks/ — Event Automation

| Category | Hooks |
|----------|-------|
| Security | credential-guard, branch-protection, amend-validator |
| Docker | docker-health-monitor, docker-restart-loop-detector, docker-post-op-health |
| Session | session-start-hook, user-prompt-submit |
| Context | auto-command-watcher |

**Registered in**: `settings.json`

### scripts/ — Session Scripts

| Category | Scripts |
|----------|---------|
| MCP Management | mcp-enable.sh, mcp-disable.sh, mcp-status.sh |
| Signal Automation | signal-command.sh, auto-command-watcher.sh |
| Context | context-checkpoint.sh, restore-context.sh |
| Benchmarking | benchmark-runner.js, scoring-engine.js |

---

## State & Configuration

### state/ — Runtime State

```
state/
├── components/         # AC state files (JSON)
│   ├── AC-01-launch.json
│   ├── AC-02-wiggum.json
│   └── ...
└── queues/             # Task queues (YAML)
    ├── evolution-queue.yaml
    └── research-agenda.yaml
```

### config/ — Configuration

| File | Purpose |
|------|---------|
| autonomy-config.yaml | Autonomy settings |
| workspace-allowlist.yaml | Allowed paths |

### Telemetry (metrics/, reports/, logs/)

```
metrics/
├── baselines/          # Performance baselines
├── benchmarks/         # Benchmark results
├── scores/             # Session scores
└── aggregates/         # Aggregated metrics

reports/
├── reflections/        # AC-05 outputs
├── maintenance/        # AC-08 outputs
├── evolutions/         # AC-06 outputs
├── research/           # AC-07 outputs
└── reviews/            # AC-03 outputs

logs/
├── mcp-validation/     # MCP logs
├── jarvis-watcher.log  # Watcher logs
└── ...
```

---

## Key Files (Identity)

| File | Purpose |
|------|---------|
| CLAUDE.md | Primary behavior definition |
| jarvis-identity.md | Full persona specification |
| settings.json | Hook registration, project config |

---

## Neuro Connections (From Pneuma)

### To Nous

```
agents/ ◄──────────────── patterns/agent-selection-pattern
commands/ ◄────────────── context/reference/commands-quick-ref
skills/ ◄──────────────── integrations/skills-selection-guide
hooks/ ◄───────────────── patterns/hook-design-patterns
state/ ◄───────────────── components/AC-* (state management)
```

### To Soma

```
scripts/ ──────────────► /Jarvis/scripts/ (system scripts)
reports/ ──────────────► projects/project-aion/reports/
config/ ───────────────► /Jarvis/docker/ (docker config)
```

### Internal (Within Pneuma)

```
CLAUDE.md ─────────────► agents/, commands/, skills/
hooks/ ────────────────► scripts/ (hook implementations)
state/ ────────────────► reports/ (state→report flow)
```

---

## Capability Counts

| Type | Count |
|------|-------|
| Agents | 14 active |
| Commands | 30+ |
| Skills | 11 |
| Hooks | 14 registered |
| Scripts | ~20 session scripts |

---

*Jarvis — Pneuma Layer Topology*
