# AIfred - AI Infrastructure Assistant

You are working in an **AIfred-configured environment** - a personal AI infrastructure hub for home lab automation, knowledge management, and system integration.

## Quick Start

**First time?** Run `/setup` to configure your environment.

**Returning?** Check @.claude/context/session-state.md for where you left off.

**Profile**: Check `.claude/config/active-profile.yaml` for current configuration, or run `/profile`.

---

## Quick Links

- @.claude/context/_index.md - Navigate the knowledge base
- @.claude/context/session-state.md - **Current work status** (check here first when returning)
- @.claude/context/compaction-essentials.md - **Core context** (survives compaction)
- @.claude/context/projects/current-priorities.md - Active tasks
- @paths-registry.yaml - Source of truth for all paths
- @.claude/context/standards/severity-status-system.md - Severity/status terminology
- @.claude/context/standards/model-selection.md - When to use Opus vs Sonnet vs Haiku
- @.claude/context/patterns/agent-selection-pattern.md - **Choose agents vs subagents vs skills**
- @.claude/skills/session-management/SKILL.md - **Session lifecycle management** (start, track, checkpoint, exit)
- @.claude/context/patterns/memory-storage-pattern.md - When to use Memory MCP
- @.claude/context/patterns/mcp-loading-strategy.md - **MCP loading strategies** (Always-On/On-Demand/Isolated)
- @.claude/context/patterns/prompt-design-review.md - PARC design review pattern
- @.claude/context/patterns/capability-layering-pattern.md - **Scripts over LLM** (Code → CLI → Prompt)
- @.claude/context/patterns/code-before-prompts-pattern.md - Deterministic code, AI for intelligence
- @.claude/context/patterns/autonomous-execution-pattern.md - Scheduled Claude jobs
- @.claude/context/patterns/fresh-context-pattern.md - Fresh context execution (no pollution)
- @.claude/context/patterns/secret-management-pattern.md - SOPS + age encryption for Docker secrets
- @.claude/context/patterns/external-tool-evaluation-pattern.md - Systematic tool evaluation
- @.claude/context/telos/TELOS.md - **Strategic goal alignment**
- @.claude/skills/upgrade/SKILL.md - Self-improvement system
- @.claude/skills/structured-planning/SKILL.md - Guided conversational planning
- @profiles/README.md - **Environment profiles** (composable layers)
- @.claude/context/patterns/environment-profile-pattern.md - Profile system design pattern

---

## Core Principles

1. **Context-First**: Check `.claude/context/` before giving advice
2. **Document Discoveries**: Update context files when you learn something new
3. **Use Symlinks**: External data goes in `external-sources/` with paths in `paths-registry.yaml`
4. **Ask Questions**: When unsure about paths or preferences, ask rather than assume
5. **Memory for Decisions**: Store decisions and lessons in Memory MCP, details in context files
6. **MCP-First Tools**: Use MCP tools before bash commands when available
7. **Hub, Not Container**: AIfred tracks code projects but doesn't contain them. Code lives in `projects_root`.
8. **Compaction Sync**: When updating design patterns, paths, or core workflows, also update `compaction-essentials.md` so context survives compression.
9. **Scripts Over LLM**: Push logic into deterministic scripts (CLI layer) - AI creates automation once, execution flows through scripts. See capability-layering-pattern.md.

---

## Project Management (Automatic)

**AIfred is a hub that orchestrates code projects stored elsewhere.**

### When User Mentions a GitHub URL

The `project-detector` hook automatically triggers. If the project isn't registered:
1. Clone to `projects_root` (from `paths-registry.yaml`)
2. Auto-detect language/type
3. Add to `paths-registry.yaml` under `development.projects`
4. Create context file at `.claude/context/projects/<name>.md`
5. Continue with user's original request

### When User Says "New Project"

Clarify name/type, then:
1. Create in `projects_root` (NOT in AIfred)
2. Initialize: git, README, `.claude/CLAUDE.md`
3. Register in `paths-registry.yaml`
4. Create context file

### Project Locations

| What | Where |
|------|-------|
| Code | `projects_root/<project>/` |
| Context/notes | `.claude/context/projects/<project>.md` |
| Registration | `paths-registry.yaml` → `development.projects` |

### Related Commands

- `/consolidate-project` - Consolidate project knowledge and create commit
- `/analyze-codebase` - Analyze a codebase and generate context documentation

---

## Core Workflow Patterns

**PARC**: Prompt → Assess → Relate → Create (design review before implementation)
**DDLA**: Discover → Document → Link → Automate
**COSA**: Capture → Organize → Structure → Automate
**Agent Selection**: Choose between custom agents, built-in subagents, skills, or direct tools

### PARC Pattern (Apply Before Significant Tasks)

Before implementing any significant task, run a quick PARC check:
1. **Prompt**: What's being asked? (parse the request)
2. **Assess**: Do existing patterns apply? (check `.claude/context/patterns/`)
3. **Relate**: How does this fit the architecture? (scope, reuse, impact)
4. **Create**: Apply patterns, document new discoveries

**Explicit invocation**: `/design-review "<task description>"`
**Full documentation**: @.claude/context/patterns/prompt-design-review.md

---

## Advanced Task Patterns

When handling complex multi-step tasks:

0. **Apply PARC first**: Quick design review - is there an existing pattern? (`/design-review`)
1. **Check for patterns first**: @.claude/context/patterns/
2. **Use structured phases**: Break tasks into Phase 1, Phase 2, etc.
3. **Classify findings**: Use severity system from @.claude/context/standards/severity-status-system.md
   - `[X] CRITICAL` - Immediate action required
   - `[!] HIGH` - Address within 24h
   - `[~] MEDIUM` - Address this week
   - `[-] LOW` - Nice to fix
4. **Store in Memory**: See @.claude/context/patterns/memory-storage-pattern.md for when to store
5. **Document once used 3x**: Create slash command or workflow doc

---

## Built-in Subagents

Claude Code includes specialized subagents that are **automatically invoked** when appropriate:

### Core Subagents
- **Explore**: Fast codebase exploration, finding files, understanding architecture
- **Plan**: Software architect for designing implementation strategies
- **claude-code-guide**: Documentation lookup for Claude Code, Agent SDK, API questions

### Feature Development (feature-dev plugin)
- **feature-dev:code-architect**: Design feature architectures with implementation blueprints
- **feature-dev:code-explorer**: Analyze existing features, trace execution paths
- **feature-dev:code-reviewer**: Review code with confidence-based issue filtering

### Other Plugins
- **hookify:conversation-analyzer**: Analyze conversations to create prevention hooks
- **agent-sdk-dev:agent-sdk-verifier-py**: Verify Python Agent SDK applications
- **agent-sdk-dev:agent-sdk-verifier-ts**: Verify TypeScript Agent SDK applications
- **project-plan-validator**: Validate project plans against infrastructure patterns

### Custom Agents (via `/agent`)
Your infrastructure-specific agents with persistent memory:
- `/agent deep-research "topic"` - Web research with multi-source validation
- `/agent service-troubleshooter "issue"` - Systematic service diagnosis
- `/agent docker-deployer "service"` - Guided Docker deployment
- `/agent memory-bank-synchronizer` - Sync docs with code changes (preserves user content)

**Decision Guide**: @.claude/context/patterns/agent-selection-pattern.md

---

## Skills System

**Skills are comprehensive workflow guides** that consolidate related commands, hooks, and patterns for end-to-end task guidance.

### Available Skills

| Skill | Purpose | Key Commands |
|-------|---------|--------------|
| [session-management](@.claude/skills/session-management/SKILL.md) | Session lifecycle management | `/checkpoint`, `/end-session` |
| [project-lifecycle](@.claude/skills/project-lifecycle/SKILL.md) | Project creation and registration | `/create-project`, `/register-project` |
| [infrastructure-ops](@.claude/skills/infrastructure-ops/SKILL.md) | Health checks and monitoring | `/health-report`, `/agent service-troubleshooter` |
| [parallel-dev](@.claude/skills/parallel-dev/SKILL.md) | Autonomous parallel development | `/parallel-dev:plan`, `/parallel-dev:start`, `/parallel-dev:validate`, `/parallel-dev:merge` |
| [system-utilities](@.claude/skills/system-utilities/SKILL.md) | Core CLI utilities | `/link-external`, `/sync-git` |
| [orchestration](@.claude/orchestration/README.md) | Task orchestration with fresh-context | `/orchestration:plan`, `/orchestration:status` |
| [upgrade](@.claude/skills/upgrade/SKILL.md) | Self-improvement and discovery | `/upgrade` |
| [structured-planning](@.claude/skills/structured-planning/SKILL.md) | Guided conversational planning | `/plan`, `/plan:new`, `/plan:review` |

### When to Use Skills vs Commands vs Agents

```
Need to do ONE thing?
  └─ Use a Command (e.g., /checkpoint)

Need guidance across MULTIPLE steps?
  └─ Reference a Skill (e.g., session-management)

Need autonomous COMPLEX task execution?
  └─ Invoke an Agent (e.g., /agent memory-bank-synchronizer)
```

**Full documentation**: @.claude/skills/_index.md

---

## Session Management

### Starting a Session
1. Check @.claude/context/session-state.md
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
- **Disable On-Demand MCPs** (returns to default OFF state)

### When You Need an Unavailable MCP
If you need tools from an On-Demand MCP that's not enabled:
1. Run `/checkpoint` to save current state
2. Provide user with enable instructions
3. User enables MCP, restarts, continues from checkpoint

See @.claude/context/patterns/mcp-loading-strategy.md for details.

---

## Memory Usage

### Store in Memory MCP
- **Decisions**: Why you chose one approach over another
- **Relationships**: Service A depends on Service B
- **Events**: When things were installed, migrated, or broke
- **Lessons**: Solutions that worked, patterns to follow

### Store in Context Files
- Detailed documentation
- Step-by-step procedures
- Configuration references
- Troubleshooting guides

### Never Store
- Secrets or credentials
- Temporary states
- Information already in files
- Obvious facts

See @.claude/context/patterns/memory-storage-pattern.md for detailed guidance.

---

## Environment Profiles

AIfred uses composable **environment profiles** that determine which hooks, permissions, patterns, and agents are active.

### Active Layers

Profiles stack: `general` (always) + selected layers (`homelab`, `development`, `production`).

Check current profile: `/profile` or `node scripts/profile-loader.js --current`

### Managing Profiles

```bash
/profile              # Show active layers
/profile list         # Show available profiles
/profile add <layer>  # Add a profile layer (requires restart)
/profile remove <x>   # Remove a profile layer (requires restart)
/profile apply        # Regenerate settings.json
```

**Full documentation**: @profiles/README.md

---

## Available Commands (48 total)

| Category | Command | Description |
|----------|---------|-------------|
| **Setup** | `/setup` | Initial configuration wizard |
| | `/profile` | Manage environment profile layers |
| **Session** | `/checkpoint` | Save state for MCP-required restart |
| | `/end-session` | Clean session exit with documentation |
| | `/context-loss` | Report forgotten context (after compaction) |
| | `/audit-log` | Query and manage audit logs |
| | `/capture` | Capture learnings, decisions, research to history |
| | `/history` | Search and browse structured history |
| **Infrastructure** | `/health-report` | Verify system and Docker health |
| | `/docker-restart` | Weekly Docker restart with health verification |
| | `/backup-status` | Show Restic backup system status |
| **Projects** | `/consolidate-project` | Consolidate project knowledge and context |
| | `/analyze-codebase` | Analyze codebase and generate context documentation |
| | `/agent` | Launch specialized agents (docker-deployer, etc.) |
| **Git** | `/sync-git` | Synchronize git across projects |
| | `/commits:push-all` | Push all unpushed commits across tracked projects |
| | `/commits:status` | Show cross-project commit status |
| | `/commits:summary` | Generate markdown summary of commits |
| **Planning** | `/design-review` | PARC pattern design review |
| | `/plan` | Guided conversational planning |
| | `/plan:new` | New design planning session |
| | `/plan:review` | System review planning session |
| | `/plan:feature` | Feature planning session |
| **Orchestration** | `/orchestration:plan` | Break complex task into phases |
| | `/orchestration:status` | Show progress tree |
| | `/orchestration:resume` | Restore context after break |
| | `/orchestration:commit` | Link commit to orchestration task |
| **Development** | `/parallel-dev:plan` | Plan autonomous parallel development |
| | `/parallel-dev:start` | Begin execution of decomposed plan |
| | `/parallel-dev:validate` | Run QA validation on completed work |
| | `/parallel-dev:merge` | Merge completed work to main |
| **Utilities** | `/link-external` | Create symlink in external-sources |
| | `/upgrade` | Self-improvement and update discovery |
| | `/telos` | Strategic goal alignment system |
| | `/metrics` | Query task metrics |
| | `/context-analyze` | Analyze context usage and suggest optimizations |

Full command list: `.claude/commands/` (includes 13 additional parallel-dev subcommands)

---

## Agents (11 total)

Specialized agents available via `/agent`:

| Agent | Purpose |
|-------|---------|
| `docker-deployer` | Deploy and configure Docker services |
| `service-troubleshooter` | Diagnose infrastructure issues |
| `deep-research` | In-depth topic investigation with citations |
| `memory-bank-synchronizer` | Sync docs with code changes (preserves user content) |
| `code-analyzer` | Analyze codebase structure and patterns |
| `code-implementer` | Write, modify, and refactor code |
| `code-tester` | Validate changes through tests and screenshots |
| `parallel-dev-implementer` | Focused implementation in parallel workflow |
| `parallel-dev-tester` | Focused testing in parallel workflow |
| `parallel-dev-documenter` | Focused documentation in parallel workflow |
| `parallel-dev-validator` | QA validation in parallel workflow |

---

## Audit Logging

All Claude Code tool executions are **automatically logged** via the hooks system.

### How It Works

The `.claude/hooks/` directory contains 38 JavaScript hooks organized by lifecycle event:

| Category | Hooks | Event |
|----------|-------|-------|
| **Session Lifecycle** | `session-start.js`, `session-tracker.js`, `session-stop.js`, `session-exit-enforcer.js`, `subagent-stop.js` | SessionStart / Stop / Notification |
| **Audit & Logging** | `audit-logger.js`, `file-access-tracker.js`, `cross-project-commit-tracker.js`, `metrics-collector.js` | PreToolUse / PostToolUse |
| **Security** | `secret-scanner.js`, `credential-guard.js`, `branch-protection.js`, `amend-validator.js` | PreToolUse |
| **Docker & Infra** | `docker-health-check.js`, `docker-validator.js`, `compose-validator.js`, `port-conflict-detector.js`, `restart-loop-detector.js`, `health-monitor.js` | PreToolUse / PostToolUse |
| **Prompt Enhancement** | `prompt-enhancer.js`, `lsp-redirector.js`, `planning-mode-detector.js`, `orchestration-detector.js`, `project-detector.js` | UserPromptSubmit / PreToolUse |
| **Workflow** | `skill-router.js`, `context-usage-tracker.js`, `priority-validator.js`, `index-sync.js`, `doc-sync-trigger.js`, `memory-maintenance.js`, `self-correction-capture.js` | Various |
| **Profile & Config** | `_profile-check.js`, `mcp-enforcer.js`, `paths-registry-sync.js`, `service-registration-detector.js`, `worktree-manager.js` | Various |
| **Context** | `pre-compact.js` | PreCompact |

### Log Format

All logs stored as JSONL in `.claude/logs/audit.jsonl`:

```json
{
  "timestamp": "2026-01-01T14:30:00.000Z",
  "session": "Infrastructure Review",
  "who": "claude",
  "type": "tool_execution",
  "tool": "Bash",
  "parameters": { "command": "docker ps" }
}
```

---

## Documentation Synchronization

**Automatic** via hooks - keeps documentation aligned with code changes.

### How It Works

1. `doc-sync-trigger.js` tracks Write/Edit operations on significant files
2. After 5+ changes in 24 hours, suggests running `/agent memory-bank-synchronizer`
3. The agent syncs docs while **preserving user content** (todos, decisions, notes)

### Significant Files Tracked

- `.claude/commands/`, `.claude/agents/`, `.claude/hooks/`, `.claude/skills/`
- `src/`, `lib/`, `scripts/`
- `docker-compose*.yaml`, `external-sources/`

### Safe Updates (agent modifies)

- Code examples, file paths, command syntax, version numbers, counts

### Preserved Content (never modified)

- Todos, decisions, troubleshooting notes, session notes, blockers

**Related**: @.claude/agents/memory-bank-synchronizer.md

---

## Response Style

- Be concise and practical
- Suggest documenting discoveries
- Ask clarifying questions about paths and preferences
- Think in reusable patterns, not one-off solutions
- Reference context files when giving advice
- Propose slash commands for repeated tasks

---

## Project Status

Check `.claude/config/active-profile.yaml` for current configuration, or run `/profile`.

If not yet configured, run `/setup` to get started.

---

*AIfred v2.2.0 - Your Personal AI Infrastructure Assistant*
*Updated: 2026-02-05 - v2.2: Environment profile system, 5 new hooks, profile-driven setup*
