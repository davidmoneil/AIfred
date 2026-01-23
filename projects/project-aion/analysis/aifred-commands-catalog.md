# AIfred Commands Catalog

**Source**: `/Users/aircannon/Claude/AIfred/.claude/commands/`
**Analyzed**: 2026-01-21
**Purpose**: Comprehensive catalog for Jarvis sync analysis

---

## Root Commands (17 commands)

### [agent.md]
- **Command**: /agent
- **Purpose**: Launch specialized agents with isolated context windows for independent work
- **Parameters**: `<agent-name> [args]`
- **Output**: Agent session log, results file, memory learnings JSON
- **Dependencies**: Task tool, agent definition files (.claude/agents/*.md), memory system
- **Workflow**:
  1. Parse agent name and arguments
  2. Load agent definition from `.claude/agents/<name>.md`
  3. Setup session with unique ID (YYYY-MM-DD_<name>_<timestamp>)
  4. Initialize memory if enabled (learnings.json)
  5. Build agent context with session info and memory
  6. Launch via Task tool (model selection: sonnet/opus/haiku)
  7. Display summary with links to session log and results
- **New in sync**: Compare with Jarvis agent implementation

---

### [analyze-codebase.md]
- **Command**: /analyze-codebase
- **Purpose**: Systematically analyze codebase and generate modification-ready context documentation
- **Parameters**: `<project-name> [--path <path>] [--depth quick|standard|deep] [--output <dir>]`
- **Output**:
  - `.claude/context/projects/<name>/_index.md` (quick reference)
  - `architecture.md` (Mermaid diagrams)
  - `modification-guide.md` (customization recipes)
  - `key-files.md` (file reference)
- **Dependencies**: Explore agent, Glob, Grep, Read, Write
- **Workflow**:
  1. Structure discovery via Explore agent (directory tree, entry points, dependencies)
  2. Component analysis (depth-dependent: quick/standard/deep)
  3. Documentation generation (Mermaid diagrams, guides, references)
  4. Integration (update main context file, add stats, optional commit)
- **New in sync**: YES - not in Jarvis

---

### [audit-log.md]
- **Command**: /audit-log
- **Purpose**: Manage Claude Code audit logging - configure verbosity, sessions, view logs
- **Parameters**:
  - `session "<name>"` - Set session name
  - `verbosity <minimal|standard|full>` - Set detail level
  - `status` - Show config
  - `view [options]` - View logs (via CLI script)
  - `query <pattern>` - Search logs
  - `enable/disable` - Toggle logging
- **Output**: JSONL log entries at `.claude/logs/audit.jsonl`
- **Dependencies**: CLI script `~/Scripts/audit-log-query.sh`, Python audit-logger.py
- **Workflow**:
  - Set session: Write to `.claude/logs/.current-session`
  - Set verbosity: Export env var `CLAUDE_AUDIT_VERBOSITY`
  - View: Call CLI script with filters (tool, session, date, errors)
- **New in sync**: Compare with Jarvis audit system

---

### [backup-status.md]
- **Command**: /backup-status
- **Purpose**: Show Restic backup system status, snapshots, and health
- **Parameters**: `[--list N] [--stats] [--check] [--json] [--quiet]`
- **Output**: Formatted status report with snapshot info, age, health status
- **Dependencies**: CLI script `~/Scripts/backup-status.sh`, Restic
- **Workflow**: Execute CLI script with arguments, parse output
- **New in sync**: Compare with Jarvis backup monitoring

---

### [capture.md]
- **Command**: /capture
- **Purpose**: Quickly capture learnings, decisions, sessions, research to structured history
- **Parameters**: `<type> "<title>" [--category <cat>] [--confidence <level>] [--tags <tags>]`
- **Types**:
  - `learning` - Insights/discoveries (categories: bugs, patterns, tools, workflows)
  - `decision` - Architectural/technical decisions (categories: architecture, tools, approaches)
  - `session` - End-of-session summaries
  - `research` - Research documentation (categories: technologies, approaches, references)
- **Output**: Markdown file in `.claude/history/<type>/<category>/YYYY-MM-DD-<slug>.md`
- **Dependencies**: History template files, index.md updater
- **Workflow**:
  1. Determine category (auto-detect or override)
  2. Create file from template
  3. Fill with context, insight, application notes
  4. Update `.claude/history/index.md`
- **New in sync**: YES - structured history system

---

### [checkpoint.md]
- **Command**: /checkpoint
- **Purpose**: Save session state for MCP-required restart (preserves context)
- **Parameters**: `[--mcp <name>] [reason]`
- **Output**: Updated `.claude/context/session-state.md`
- **Dependencies**: CLI script `~/Scripts/checkpoint.sh`
- **Workflow**:
  1. Run CLI script with arguments
  2. Script updates session-state.md with checkpoint reason and timestamp
  3. If --mcp flag, includes MCP to enable after restart
- **New in sync**: Compare with Jarvis checkpoint implementation

---

### [consolidate-project.md]
- **Command**: /consolidate-project
- **Purpose**: Two modes - organize project knowledge OR optimize infrastructure context
- **Parameters**: `[project-name | --infrastructure | --analyze | --all]`
- **Modes**:
  - **Project**: Organize patterns, examples, progress (default with project name)
  - **Infrastructure**: Optimize context window, reduce tokens (--infrastructure flag)
  - **Analyze**: Report findings only (--analyze flag)
- **Output**:
  - Project mode: Updated learned-patterns.md, progress.md, config.yaml
  - Infrastructure mode: Slimmed context files, extracted to knowledge/reference/
  - Both: Git commit
- **Dependencies**: CLI script `~/Scripts/consolidate-project.sh`, Read, Write, Edit, Grep, Glob
- **Workflow**:
  - **Project**: Gather data via CLI → AI analyzes patterns → Update files → Commit
  - **Infrastructure**: CLI analyzes sizes → AI identifies targets → Extract to reference → Commit
- **New in sync**: YES - complex consolidation system

---

### [context-analyze.md]
- **Command**: /context-analyze
- **Purpose**: Analyze Claude Code context usage and suggest optimizations
- **Parameters**: `[--test] [--no-reduce]`
- **Output**: Report at `.claude/logs/reports/context-analysis-YYYY-MM-DD.md`
- **Dependencies**: CLI script `~/Scripts/weekly-context-analysis.sh`, Ollama (optional for auto-reduce)
- **Workflow**:
  1. Session statistics from audit logs
  2. File size analysis (CLAUDE.md, context files)
  3. Git churn analysis (frequently modified files)
  4. Auto-archive old logs (>365 days)
  5. Optional: Auto-reduce large files via Ollama summarization
- **New in sync**: YES - automated context optimization

---

### [context-loss.md]
- **Command**: /context-loss
- **Purpose**: Document when Claude forgets context after compaction for improving essentials
- **Parameters**: `"<description of what was forgotten>"`
- **Output**: JSONL log at `.claude/logs/context-loss-reports.jsonl`
- **Dependencies**: None
- **Workflow**:
  1. Log report with timestamp, category, session
  2. Check for patterns (count similar reports)
  3. Suggest adding to compaction-essentials.md if reported 3+ times
  4. Re-orient by restating forgotten context
- **New in sync**: YES - feedback loop for compaction

---

### [design-review.md]
- **Command**: /design-review
- **Purpose**: Apply PARC pattern (Prompt-Assess-Relate-Create) to review task design before implementation
- **Parameters**: `"<task description>"`
- **Output**: Structured analysis with patterns to apply, approach, risks
- **Dependencies**: Read, Grep, Glob, Memory MCP (search_nodes, open_nodes)
- **Workflow**:
  1. **PROMPT**: Parse request, classify type, identify requirements
  2. **ASSESS**: Check patterns, workflows, Memory MCP, codebase for similar work
  3. **RELATE**: Analyze scope, reuse, impact, technical debt
  4. **CREATE**: Recommend patterns, approach, documentation plan, Memory storage plan
- **New in sync**: YES - formalized design review pattern

---

### [docker-restart.md]
- **Command**: /docker-restart
- **Purpose**: Weekly Docker restart with health verification
- **Parameters**: `[--dry-run] [--skip-restart] [--verbose]`
- **Output**: Restart log, health check results, webhook notification
- **Dependencies**: CLI script `~/Scripts/weekly-docker-restart.sh`
- **Workflow**:
  1. Pre-restart checks (record container states)
  2. Stop Docker daemon
  3. Restart Docker daemon
  4. Start compose stacks in dependency order
  5. Health verification (endpoints, timeouts)
  6. Send notification
- **New in sync**: Compare with Jarvis Docker management

---

### [end-session.md]
- **Command**: /end-session
- **Purpose**: Clean session exit with documentation and git commit
- **Parameters**: None
- **Output**: Updated session-state.md, priorities, git commit
- **Dependencies**: Read, Write, Edit, git
- **Workflow**:
  1. Check session activity (`.claude/logs/.session-activity`, git status)
  2. Update session-state.md (status, accomplishments, next steps)
  3. Review and update todos
  4. Update current-priorities.md
  5. Git commit with session summary
  6. Optional: GitHub push
  7. Clear session activity tracker
- **New in sync**: Compare with Jarvis session management

---

### [health-report.md]
- **Command**: /health-report
- **Purpose**: Generate comprehensive infrastructure health report
- **Parameters**: `[--quick] [--full]`
- **Output**: Markdown report with Docker, Memory MCP, Context, MCP servers status
- **Dependencies**: Docker, Memory MCP, context files, MCP connections
- **Workflow**:
  1. Check Docker services (status, resources, restarts)
  2. Check Memory MCP (entities, recent access, stale items)
  3. Check context health (stale files, broken refs)
  4. Check MCP connections (attempt operations)
  5. Generate report with severity classification
  6. Provide recommendations (CRITICAL/HIGH/MEDIUM/LOW)
- **New in sync**: YES - comprehensive health aggregation

---

### [history.md]
- **Command**: /history
- **Purpose**: Search and browse structured history system
- **Parameters**: Subcommands:
  - `search "<query>" [--type <type>] [--since <date>]`
  - `recent [count]`
  - `stats`
  - `show <path-or-id>`
  - `tags [tag]`
  - `category <category>`
  - `related <entry>`
- **Output**: Search results, entry details, statistics
- **Dependencies**: History files in `.claude/history/`
- **Workflow**: Parse subcommand, search/filter history entries, format output
- **New in sync**: YES - structured history browsing

---

### [link-external.md]
- **Command**: /link-external
- **Purpose**: Create symlink in external-sources/ with documentation
- **Parameters**: `<source-path> <category/link-name> [-d "description"]`
- **Output**: Symlink in external-sources/, optional paths-registry update
- **Dependencies**: CLI script `~/Scripts/link-external.sh`
- **Workflow**: Run CLI script to create symlink, suggest adding to paths-registry
- **New in sync**: Compare with Jarvis external source management

---

### [setup.md]
- **Command**: /setup
- **Purpose**: AIfred initial configuration wizard (7-phase setup)
- **Parameters**: None (interactive)
- **Output**: Fully configured AIfred installation
- **Dependencies**: Bash, Read, Write, Edit, Glob, Grep, Memory MCP
- **Workflow**:
  - **Phase 0**: Prerequisites check (Git, Docker, Node.js/Python)
  - **Phase 1**: System discovery (OS, Docker, services, network, storage)
  - **Phase 2**: Purpose interview (use cases, automation, focus areas)
  - **Phase 3**: Foundation setup (paths-registry, knowledge base, context files)
  - **Phase 4**: MCP integration (deploy Gateway, Memory, additional servers)
  - **Phase 5**: Hooks & automation (core hooks, cron jobs, permissions)
  - **Phase 6**: Agent deployment (docker-deployer, troubleshooter, deep-research)
  - **Phase 7**: Finalization (summary, archive setup, register projects, getting-started guide)
- **New in sync**: YES - comprehensive setup wizard

---

### [sync-git.md]
- **Command**: /sync-git
- **Purpose**: Sync repository to GitHub with automatic commit
- **Parameters**: `[commit-message] [-d <dir>] [-n] [-q]`
- **Output**: Git commit and push, summary report
- **Dependencies**: CLI script `~/Scripts/sync-git.sh`
- **Workflow**: Run script, auto-generate commit message if needed, detect secrets, push
- **New in sync**: Compare with Jarvis git sync

---

### [telos.md]
- **Command**: /telos
- **Purpose**: TELOS goal alignment system - strategic layer above priorities
- **Parameters**: Subcommands:
  - (default) - Show summary
  - `goals` - List all active goals
  - `domain <name>` - Show domain (technical/creative/personal)
  - `update <goal-id>` - Update goal status
  - `review [weekly|monthly|quarterly]` - Start review workflow
  - `add goal` - Add new goal (guided)
  - `link <goal> <priority>` - Link goal to priority
- **Output**: TELOS summary, goal status, domain details
- **Dependencies**: Files at `.claude/context/telos/` (TELOS.md, domains/*.md, goals/active-goals.yaml)
- **Workflow**: Read TELOS files, display/update based on subcommand
- **New in sync**: YES - strategic goal system

---

### [upgrade.md]
- **Command**: /upgrade
- **Purpose**: Self-improvement system for discovering and applying updates
- **Parameters**: Subcommands:
  - `discover` - Check sources for updates
  - `analyze` - Score pending upgrades by relevance
  - `propose [id]` - Generate implementation proposal
  - `implement <id>` - Apply upgrade
  - `status` - Show upgrade status
  - `history [count]` - Show upgrade history
  - `rollback <id>` - Rollback upgrade
  - `defer <id> "reason"` - Defer upgrade
- **Output**: Upgrade proposals, implementation logs, history
- **Dependencies**: Config at `.claude/skills/upgrade/config.yaml`, data files
- **Workflow**: Fetch from sources → Compare baselines → Score → Propose → Implement with git checkpoints
- **New in sync**: YES - self-improvement system

---

## Commits Commands (4 commands)

### [commits/README.md]
- **Purpose**: Overview of cross-project commit tracking
- **System**: Hook-based tracking (`cross-project-commit-tracker.js`)
- **Data**: `.claude/logs/cross-project-commits.json`
- **Commands**: status, summary, push-all

---

### [commits/push-all.md]
- **Command**: /commits:push-all
- **Purpose**: Push all unpushed commits across tracked projects
- **Parameters**: `[--dry-run] [--project <name>]`
- **Output**: Push summary with status per project (✅/⏭️/❌)
- **Dependencies**: Git, tracking file
- **Workflow**:
  1. Get tracked projects from commits JSON
  2. For each, check unpushed commits (`git log @{u}..HEAD`)
  3. Push if commits exist and not dry-run
  4. Report results
- **New in sync**: YES - cross-project push

---

### [commits/status.md]
- **Command**: /commits:status
- **Purpose**: Show cross-project commit status for current session
- **Parameters**: `[--all] [--project <name>]`
- **Output**: Formatted table with commits per project, grouped by type
- **Dependencies**: Tracking file `.claude/logs/cross-project-commits.json`
- **Workflow**: Read tracking file, filter by session, format with badges
- **New in sync**: YES - cross-project visibility

---

### [commits/summary.md]
- **Command**: /commits:summary
- **Purpose**: Generate markdown summary of commits for session notes
- **Parameters**: `[--session <name>] [--output <file>]`
- **Output**: Markdown summary with commits grouped by project
- **Dependencies**: Tracking file
- **Workflow**: Parse tracking JSON, format as markdown, output to terminal or file
- **New in sync**: YES - session documentation

---

## Orchestration Commands (4 commands)

### [orchestration/commit.md]
- **Command**: /orchestration:commit
- **Purpose**: Link git commit to orchestration task and update status
- **Parameters**: `<task-id> [commit-message]` (task-id can be "current")
- **Output**: Git commit with task metadata, updated orchestration YAML
- **Dependencies**: Read, Write, Edit, Bash, TodoWrite
- **Workflow**:
  1. Identify task (current or by ID)
  2. Check git status, stage changes
  3. Generate commit message (type(task-id): message format)
  4. Create commit with task/orchestration metadata
  5. Update orchestration YAML (add commit hash, update status)
  6. Check cascade effects (unblocked tasks, phase completion)
  7. Update TodoWrite
  8. Display progress update
- **New in sync**: YES - task-linked commits

---

### [orchestration/plan.md]
- **Command**: /orchestration:plan
- **Purpose**: Decompose complex task into phases and atomic subtasks
- **Parameters**: `"<task-description>"`
- **Output**: YAML file at `.claude/orchestration/YYYY-MM-DD-<slug>.yaml`
- **Dependencies**: Read, Write, Glob, Grep, TodoWrite, Memory MCP
- **Workflow**:
  1. Understand task (description, priorities, session state, past orchestrations)
  2. Check Memory MCP for similar patterns
  3. Decompose into 2-5 phases
  4. Create atomic tasks (1-4h each, clear done criteria, hierarchical IDs)
  5. Generate orchestration YAML with phases/tasks
  6. Calculate total estimated hours
  7. Store pattern in Memory MCP if novel
  8. Update session-state.md
  9. Create initial TodoWrite entries
  10. Display task tree
- **New in sync**: YES - orchestration planning

---

### [orchestration/resume.md]
- **Command**: /orchestration:resume
- **Purpose**: Restore context for continuing work on active orchestration
- **Parameters**: `[orchestration-name]`
- **Output**: Context summary with progress, in-progress tasks, next available tasks
- **Dependencies**: Read, Glob, Grep, Bash, TodoWrite, Memory MCP
- **Workflow**:
  1. Find orchestration (by name or most recent active)
  2. Load orchestration state (current phase, task statuses)
  3. Gather context (referenced files, git activity, Memory entities)
  4. Identify current position (last task, accomplishments, blockers)
  5. Restore TodoWrite state
  6. Present comprehensive resume context
  7. Update session-state.md
- **New in sync**: YES - orchestration resumption

---

### [orchestration/status.md]
- **Command**: /orchestration:status
- **Purpose**: Display current state of active orchestrations
- **Parameters**: None
- **Output**: Visual task tree with status icons and progress
- **Dependencies**: Read, Glob
- **Workflow**:
  1. Find active orchestrations (status: active or paused)
  2. For each, calculate progress (total tasks, completed, percentage)
  3. Display task tree with icons (✅ completed, 🔄 in progress, ⏳ pending, 🔒 blocked)
  4. Show summary (progress, estimated remaining, next available)
- **New in sync**: YES - orchestration visibility

---

## Parallel-Dev Commands (15+ commands)

### [parallel-dev/README.md]
- **Purpose**: Overview of autonomous parallel development system
- **Phases**: Worktrees → Planning → Decomposition → Execution → Validation → Merge
- **Commands**: 15+ commands across 6 phases
- **New in sync**: YES - entire parallel-dev system

---

### [parallel-dev/init.md]
- **Command**: /parallel-dev:init
- **Purpose**: Initialize parallel-dev for current project
- **Parameters**: `[--reset]`
- **Output**: Directory structure, registry.json, .gitignore updates
- **Dependencies**: Read, Write, Bash, Glob
- **Workflow**:
  1. Verify git repo
  2. Get project info (name, root)
  3. Load configuration (worktree base)
  4. Create directory structure (plans/, executions/)
  5. Initialize registry.json
  6. Create worktree base directory
  7. Add to .gitignore
  8. Check dependencies (git, jq, tmux)
  9. Display summary
- **New in sync**: YES

---

### [parallel-dev/start.md]
- **Command**: /parallel-dev:start
- **Purpose**: Begin autonomous parallel execution of decomposed plan
- **Parameters**: `<plan-name>`
- **Output**: Execution state YAML, event log JSONL, worktree, commits
- **Dependencies**: Read, Write, Edit, Bash, Glob, Grep, Task
- **Workflow**:
  1. Validate prerequisites (plan exists, tasks exist, not already executing)
  2. Load configuration (worktree base, max agents)
  3. Create worktree for plan
  4. Initialize execution state
  5. Calculate ready tasks (dependencies met)
  6. Execution loop:
     - Get ready tasks and available agent slots
     - Spawn agents via Task tool
     - Check completed agents
     - Update task statuses
     - Check phase completion
     - Check for blockers
     - Check for overall completion
  7. Display live progress
  8. Handle completion or interruption
- **New in sync**: YES - autonomous parallel execution

---

### [parallel-dev/status.md]
- **Command**: /parallel-dev:status
- **Purpose**: Display overall parallel-dev status
- **Parameters**: `[execution-name] [--json] [--brief]`
- **Output**: Status report with worktrees, executions, plans, resources
- **Dependencies**: Read, Bash, Glob
- **Workflow**:
  1. Check initialization (registry exists)
  2. Display worktrees (active/total)
  3. Display executions (with progress)
  4. Display plans (with status)
  5. Show resource usage (ports)
  6. Show quick commands reference
- **New in sync**: YES

---

## Plan Commands (1 command + sub-modes)

### [plan/plan.md]
- **Command**: /plan
- **Purpose**: Guided conversational planning with dynamic question depth
- **Parameters**: `[description] [--mode=<new-design|system-review|feature>] [--depth=<minimal|auto|comprehensive>]`
- **Output**:
  - Specification at `.claude/planning/specs/YYYY-MM-DD-<slug>.md`
  - Orchestration YAML at `.claude/orchestration/YYYY-MM-DD-<slug>.yaml`
- **Dependencies**: Question bank, templates, mode detection
- **Workflow**:
  1. Mode detection (if not specified) or use --mode flag
  2. Initialize session (session ID, load question bank)
  3. Discovery phase (ask questions per category, detect complexity, add extended questions)
  4. Draft specification (use mode-specific template, fill with captured info)
  5. User review and adjustments
  6. Save specification
  7. Generate orchestration (extract phases/tasks from spec)
  8. Handoff (display completion summary, next steps)
- **Modes**:
  - **new-design**: Full design specification (5 categories)
  - **system-review**: Current state assessment, improvements (focused questions)
  - **feature**: Lighter planning for features (3 categories)
- **Depth Levels**:
  - **minimal**: Base questions only
  - **auto**: Base + extended if complexity detected (default)
  - **comprehensive**: All questions regardless
- **New in sync**: YES - comprehensive planning system

---

## Summary Statistics

**Total Commands**: 47 commands
- Root-level: 17 commands
- Commits subsystem: 4 commands
- Orchestration subsystem: 4 commands
- Parallel-dev subsystem: 15+ commands
- Plan subsystem: 1 command with 3 modes

**New/Enhanced in AIfred**:
- Structured history system (capture, history)
- TELOS strategic goal system
- Upgrade/self-improvement system
- Orchestration system (plan, commit, resume, status)
- Parallel-dev system (autonomous parallel execution)
- Comprehensive planning (/plan with modes)
- Context optimization (consolidate, analyze, context-loss)
- Health reporting (health-report)
- Cross-project commit tracking

**Key Patterns**:
- CLI script delegation (many commands use ~/Scripts/*.sh)
- YAML-based state management (orchestrations, plans, tasks)
- Memory MCP integration (patterns, entities)
- Git integration (checkpoint tags, commit metadata)
- Progressive disclosure (depth levels, complexity detection)
- Agent coordination (Task tool, model selection)
- Structured data (JSONL logs, YAML state, JSON tracking)

---

*Catalog generated 2026-01-21 for Jarvis baseline sync analysis*
