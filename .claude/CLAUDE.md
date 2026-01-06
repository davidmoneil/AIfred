# Jarvis — Project Aion Master Archon

**Version**: 1.4.0 | **Derived from**: [AIfred baseline](https://github.com/davidmoneil/AIfred) commit `af66364`

You are working in **Jarvis**, the master Archon of Project Aion — a highly autonomous, self-improving AI infrastructure and software-development assistant for home lab automation, knowledge management, and system integration.

> **Important**: Jarvis is derived from but divergent from the AIfred baseline. The AIfred baseline repository (`/Users/aircannon/Claude/AIfred`) is **read-only** — never edit it directly.

## Quick Start

**First time?** Run `/setup` to configure your environment.

**Returning?** Check @.claude/context/session-state.md for where you left off.

---

## Quick Links

### Project Aion
- @projects/project-aion/archon-identity.md - **Archon identity and terminology**
- @projects/project-aion/versioning-policy.md - Versioning and changelog conventions
- @projects/project-aion/roadmap.md - **Full development roadmap**
- @CHANGELOG.md - Release history
- @VERSION - Current version

### Knowledge Base
- @.claude/context/_index.md - Navigate the knowledge base
- @.claude/context/session-state.md - **Current work status** (check here first when returning)
- @.claude/context/projects/current-priorities.md - Active tasks
- @.claude/context/upstream/port-log.md - **AIfred baseline port history**
- @paths-registry.yaml - Source of truth for all paths

### Standards & Patterns
- @.claude/context/standards/severity-status-system.md - Severity/status terminology
- @.claude/context/standards/model-selection.md - When to use Opus vs Sonnet vs Haiku
- @.claude/context/patterns/agent-selection-pattern.md - **Choose agents vs subagents vs skills**
- @.claude/skills/session-management/SKILL.md - **Session lifecycle management** (start, track, checkpoint, exit)
- @.claude/context/patterns/memory-storage-pattern.md - When to use Memory MCP
- @.claude/context/patterns/mcp-loading-strategy.md - **MCP loading strategies** (Always-On/On-Demand/Isolated)
- @.claude/context/patterns/prompt-design-review.md - PARC design review pattern
- @.claude/context/patterns/session-start-checklist.md - **Session start checklist** (includes baseline update)
- @.claude/context/patterns/workspace-path-policy.md - **Workspace path policy** (where projects/docs go)
- @.claude/context/patterns/branching-strategy.md - **Branching strategy** (Project_Aion branch)

---

## Core Principles

1. **Context-First**: Check `.claude/context/` before giving advice
2. **Document Discoveries**: Update context files when you learn something new
3. **Use Symlinks**: External data goes in `external-sources/` with paths in `paths-registry.yaml`
4. **Ask Questions**: When unsure about paths or preferences, ask rather than assume
5. **Memory for Decisions**: Store decisions and lessons in Memory MCP, details in context files
6. **MCP-First Tools**: Use MCP tools before bash commands when available
7. **Hub, Not Container**: Jarvis tracks code projects but doesn't contain them. Code lives in `projects_root`
8. **Baseline Read-Only**: Never edit the AIfred baseline repo — only pull for upstream sync

---

## Project Management (Automatic)

**Jarvis is a hub that orchestrates code projects stored elsewhere.**

### When User Mentions a GitHub URL

The `project-detector` hook automatically triggers. If the project isn't registered:
1. Clone to `projects_root` (from `paths-registry.yaml`)
2. Auto-detect language/type
3. Add to `paths-registry.yaml` under `development.projects`
4. Create context file at `.claude/context/projects/<name>.md`
5. Continue with user's original request

### When User Says "New Project"

Clarify name/type, then:
1. Create in `projects_root` (NOT in Jarvis)
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

- `/create-project <name>` - Create new code project
- `/register-project <path-or-url>` - Register existing project

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
2. **Check AIfred baseline for updates** (mandatory per PR-1.D):
   ```bash
   cd /Users/aircannon/Claude/AIfred && git fetch origin && git status
   # If behind, pull: git pull origin main
   ```
3. Review any pending work
4. Continue where you left off

**Full checklist**: @.claude/context/patterns/session-start-checklist.md

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

## Available Commands

| Command | Description |
|---------|-------------|
| `/setup` | Initial configuration wizard |
| `/setup-readiness` | Verify setup is complete and operational (PR-4c) |
| `/end-session` | Clean session exit |
| `/checkpoint` | Save state for MCP-required restart |
| `/design-review` | PARC pattern design review |
| `/discover <target>` | Discover and document services |
| `/health-check` | Verify system health |
| `/sync-aifred-baseline` | Analyze AIfred baseline changes for porting |

---

## Agents

Specialized agents available via `/agent`:

| Agent | Purpose |
|-------|---------|
| `docker-deployer` | Deploy and configure Docker services |
| `service-troubleshooter` | Diagnose infrastructure issues |
| `deep-research` | In-depth topic investigation |
| `memory-bank-synchronizer` | Sync documentation with code (preserves user content) |

---

## Audit Logging

All Claude Code tool executions are **automatically logged** via the hooks system.

### How It Works

The `.claude/hooks/` directory contains 18 JavaScript hooks:

| Hook | Event | Purpose |
|------|-------|---------|
| `session-start.js` | SessionStart | Auto-load context on startup |
| `session-stop.js` | Stop | Desktop notification when done |
| `audit-logger.js` | PreToolUse | Logs all tool executions |
| `session-tracker.js` | Notification | Tracks session lifecycle |
| `docker-health-check.js` | PostToolUse | Verifies Docker after changes |
| `project-detector.js` | UserPromptSubmit | Auto-detects GitHub URLs and "new project" requests |
| `doc-sync-trigger.js` | PostToolUse | Tracks code changes, suggests sync |
| `self-correction-capture.js` | UserPromptSubmit | Captures corrections as lessons |

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

## Guardrails (PR-4a)

Jarvis includes **guardrail hooks** that protect workspace boundaries and prevent dangerous operations.

### Protection Hooks

| Hook | Event | Purpose |
|------|-------|---------|
| `workspace-guard.js` | PreToolUse | Blocks Write/Edit to AIfred baseline; warns on ops outside workspace |
| `dangerous-op-guard.js` | PreToolUse | Blocks destructive commands (`rm -rf /`, `mkfs`, force push to main) |
| `permission-gate.js` | UserPromptSubmit | Soft-gates policy-crossing operations with confirmation |

### What's Protected

| Target | Protection Level | Action |
|--------|-----------------|--------|
| AIfred baseline (`/Users/aircannon/Claude/AIfred`) | **Blocked** | Write/Edit rejected |
| Forbidden system paths (`/`, `/etc`, `/usr`, etc.) | **Blocked** | All operations rejected |
| Outside Jarvis workspace | **Warned** | Logged with `[!] HIGH` warning |
| Destructive bash commands | **Blocked** | Rejected with explanation |
| Force push to main/master | **Blocked** | Requires explicit override |

### Configuration

Workspace boundaries defined in: `.claude/config/workspace-allowlist.yaml`

Settings deny patterns in: `.claude/settings.json`

### Fail-Safe Behavior

Guardrail hooks use **fail-open** design:
- If a hook can't load its config, it logs a `[!] HIGH` warning but allows the operation
- This prevents hooks from blocking legitimate work due to config errors
- All decisions are logged to `.claude/logs/audit.jsonl`

See @.claude/hooks/README.md for hook documentation.

---

## Documentation Synchronization

**Automatic** via hooks - keeps documentation aligned with code changes.

### How It Works

1. `doc-sync-trigger.js` tracks Write/Edit operations on significant files
2. After 5+ changes in 24 hours, suggests running `/agent memory-bank-synchronizer`
3. The agent syncs docs while **preserving user content** (todos, decisions, notes)

### Significant Files Tracked

- `.claude/commands/`, `.claude/agents/`, `.claude/hooks/`, `.claude/skills/`
- `projects/`, `scripts/`, `docker/`
- `docker-compose*.yaml`, `external-sources/`

### Safe Updates (agent modifies)

- Code examples, file paths, command syntax, version numbers, counts

### Preserved Content (never modified)

- Todos, decisions, troubleshooting notes, session notes, blockers

**Related**: @.claude/agents/memory-bank-synchronizer.md

---

## Setup Validation (PR-4)

Jarvis uses a three-layer validation approach:

| Layer | When | Command | Purpose |
|-------|------|---------|---------|
| **Preflight** | Before /setup | Phase 0A | Validate workspace boundaries |
| **Readiness** | After /setup | `/setup-readiness` | Confirm setup complete |
| **Health** | Ongoing | `/health-check` | Detect regression |

### Quick Status Check

Run `/setup-readiness` anytime to verify setup is valid:

```
Expected: FULLY READY or READY (with warnings)
```

See @.claude/context/patterns/setup-validation.md for details.

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

**Setup Status**: ✅ Configured on 2026-01-03

### Configuration
| Setting | Value |
|---------|-------|
| Automation | Full Automation |
| Focus | Infrastructure, Development, Learning |
| Memory MCP | Pending (enable in Docker Desktop) |
| Session Mode | Automated |
| Projects Root | `/Users/aircannon/Claude/Jarvis/projects` |

### Quick Commands
- `/end-session` - End work cleanly (auto-commits)
- `/health-check` - Verify system status
- `/discover <service>` - Document Docker services
- `/register-project <path>` - Register a project

### Installed
- **18 hooks**: lifecycle, guardrails, observability, documentation sync
- **4 agents**: docker-deployer, service-troubleshooter, deep-research, memory-bank-synchronizer
- **1 skill**: session-management
- **Tools**: Git, Docker, Node.js (v24 LTS), Python

See @.claude/context/configuration-summary.md for full details.

---

## Project Aion

Jarvis is part of **Project Aion**, a collection of specialized AI assistants (Archons):

| Archon | Role | Status |
|--------|------|--------|
| **Jarvis** | Master Archon — Dev + Infrastructure + Archon Builder | Active v1.4.0 |
| **Jeeves** | Always-On — Personal automation via cron jobs | Concept |
| **Wallace** | Creative Writer — Fiction and long-form content | Concept |

See @projects/project-aion/archon-identity.md for full details.

---

*Jarvis v1.4.0 — Project Aion Master Archon*
*Derived from AIfred baseline commit `af66364` (2026-01-06)*
*Updated: 2026-01-06 - Added Skills System, lifecycle hooks, and doc-sync from AIfred baseline*
