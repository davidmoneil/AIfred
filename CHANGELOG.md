# Changelog

All notable changes to Jarvis (Project Aion Master Archon) will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/),
and this project adheres to [Semantic Versioning](https://semver.org/).

---

## [Unreleased]

---

## [2.1.1] - 2026-01-18

**Implementation Sprint: Evolution Queue**

Implemented 9 evolution proposals from R&D cycle, adding significant startup enhancements and new hooks.

### Added

- **Setup Hook** (evo-2026-01-022) — Directory validation, required files check, auto-create missing directories
- **Context Injector Hook** (evo-2026-01-023) — PreToolUse additionalContext injection for tool guidance
- **Startup Greeting Helper** (evo-2026-01-020) — Node.js weather and time-of-day greeting generator
- **Local RAG MCP** (evo-2026-01-028) — Semantic code search with local Transformers.js embeddings
- **Weather Integration** (evo-2026-01-017) — wttr.in weather in startup greeting
- **AIfred Sync Check** (evo-2026-01-018) — Baseline sync status in session-start.sh
- **Environment Validation** (evo-2026-01-019) — Git status, branch, hooks validation at startup
- **/rename Integration** (evo-2026-01-026) — Session naming in checkpoint workflow

### Changed

- `settings.json`: Added `mcpToolSearch: "auto:15"` (evo-2026-01-024)
- `settings.json`: Registered Setup and PreToolUse context-injector hooks
- `session-start.sh`: Weather, AIfred sync, environment validation sections
- `checkpoint.md`: Session naming best practices with /rename

### Files Created

- `.claude/hooks/setup-hook.sh`
- `.claude/hooks/context-injector.js`
- `.claude/scripts/startup-greeting.js`
- `.claude/reports/reflections/reflection-2026-01-18.md`
- `.claude/reports/maintenance/maintenance-2026-01-18.md`

### Documentation

- Updated `mcp-installation.md` with Local RAG MCP documentation
- Updated `evolution-queue.yaml`: 10 proposals completed
- Updated `lessons/corrections.md`: wttr.in header requirement
- Updated `lessons/self-corrections.md`: Weather API fix

---

## [2.1.0] - 2026-01-16

**Phase 6 Autonomy Design Complete**

All specifications for Phase 6 (Autonomy, Self-Evolution & Benchmark Gates) created.

### Added

#### PR-11: Autonomic Component Framework (6 sub-PRs)
- **Component Specification Standard** — 9-section template for all autonomic components
- **Component Interaction Protocol** — Event-driven communication patterns
- **Metrics Collection Standard** — Telemetry schema and storage patterns
- **Gate Pattern Standard** — Risk-based approval checkpoints
- **Override and Disable Pattern** — Emergency stop and configuration
- **Testing Framework** — Isolation testing and validation harness

#### PR-12: Autonomic Component Implementation (10 sub-PRs)
- **AC-01 Self-Launch** — Environmental awareness, greeting, autonomous startup
- **AC-02 Wiggum Loop** — Default-on iterative work driver
- **AC-03 Milestone Review** — Two-level review (technical + project)
- **AC-04 JICM** — Enhanced context management with liftover
- **AC-05 Self-Reflection** — Lessons directory, pattern detection
- **AC-06 Self-Evolution** — Safe self-modification with gates
- **AC-07 R&D Cycles** — External discovery and token efficiency
- **AC-08 Maintenance** — Dual-scope hygiene workflows
- **AC-09 Session Completion** — User-prompted clean handoff
- **/self-improve Command** — Orchestrates Systems 5-8

#### PR-13: Monitoring, Benchmarking, Scoring (5 sub-PRs)
- **Telemetry System** — Event collection, JSONL storage, Memory MCP integration
- **Benchmark Suite** — Component, E2E, performance, quality benchmarks
- **Scoring Framework** — 0-100 component scores, session composites, trends
- **Dashboard & Reporting** — /status, /health, session/weekly/evolution reports
- **Regression Detection** — Baseline comparison, evolution gates

#### PR-14: Open-Source Catalog & SOTA Reference (5 sub-PRs)
- **Catalog Structure** — YAML schema, categories, evaluation criteria
- **Initial Population** — 50+ item inventory, templates, workflow
- **Comparison Framework** — Gap analysis, opportunity identification
- **Adoption Pipeline** — 4-stage workflow, decision matrix
- **Research Scheduler** — Scheduled tasks, queue management

### Files Created

**Components** (`.claude/context/components/`):
- AC-01 through AC-09 specification documents

**Patterns** (`.claude/context/patterns/`):
- startup-protocol.md, wiggum-loop-pattern.md, milestone-review-pattern.md
- jicm-pattern.md, self-reflection-pattern.md, self-evolution-pattern.md
- rd-cycles-pattern.md, maintenance-pattern.md, session-completion-pattern.md
- self-improvement-pattern.md

**Standards** (`.claude/context/standards/`):
- metrics-collection-standard.md, gate-pattern-standard.md

**Infrastructure** (`.claude/context/infrastructure/`):
- telemetry-system.md, benchmark-suite.md, scoring-framework.md
- dashboard-reporting.md, regression-detection.md
- sota-catalog-structure.md, sota-catalog-population.md
- sota-comparison-framework.md, sota-adoption-pipeline.md
- sota-research-scheduler.md

**Commands** (`.claude/commands/`):
- self-improve.md

**Configuration** (`.claude/config/`):
- autonomy-config.yaml

### Summary

| PR | Sub-PRs | Focus |
|----|---------|-------|
| PR-11 | 6 | Autonomic Component Framework |
| PR-12 | 10 | Autonomic Component Implementation |
| PR-13 | 5 | Monitoring, Benchmarking, Scoring |
| PR-14 | 5 | Open-Source Catalog & SOTA Reference |

**Total**: 26 sub-PRs, 40+ specification documents

---

## [2.0.0] - 2026-01-13

**MAJOR RELEASE: Phase 5 Tooling Complete**

PR-10 Complete — Jarvis Persona, Project Organization, and Setup Upgrade.

### Added

#### PR-10.1: Jarvis Persona Implementation
- **`jarvis-identity.md`** — Full persona specification:
  - Identity: Calm, precise, safety-conscious orchestrator
  - Address: "sir" for formal/important, nothing for casual
  - Tone: Professional, understated, technically precise
  - Safety: Prefer reversible actions, confirm destructive ops
- **CLAUDE.md Persona section** — Quick-reference persona traits
- **Session-start checklist** — Automatic persona adoption

#### PR-10.2: Reports Reorganization
- **`projects/project-aion/reports/`** — PR-specific reports moved
- **Classification rule**: PR reports → project-aion, operational reports → .claude/reports/

#### PR-10.3: Directory Cleanup
- **`knowledge/` phased out** — Contents redistributed:
  - Templates → `.claude/context/templates/`
  - Research notes → `projects/project-aion/ideas/`
  - Test outputs → `docs/archive/`
- **Root `commands/` consolidated** → `.claude/commands/`
- **Two conceptual spaces** established:
  - Jarvis Ecosystem (`.claude/`) — Runtime, operational
  - Project Aion (`projects/project-aion/`) — Development artifacts

#### PR-10.4: Documentation + Organization Cleanup
- **OpenCode artifacts removed** — AGENTS.md, opencode.json, .opencode/
- **CLAUDE-full-reference.md split** — Focused reference docs in `.claude/context/reference/`
- **Reports moved** — from .claude/ to docs/reports/
- **OOXML schemas consolidated** — 47 duplicate files removed
- **`/jarvis` command menu** — Quick access to common commands
- **Configuration summary rewritten** — Complete rewrite of outdated file

#### PR-10.5: Setup Upgrade
- **4 critical guardrail hooks registered**:
  - `workspace-guard.js` — Blocks writes to AIfred baseline
  - `dangerous-op-guard.js` — Blocks destructive commands (rm -rf, mkfs, force push main)
  - `secret-scanner.js` — Scans for secrets before git commits
  - `permission-gate.js` — Soft-gates policy-crossing operations
- **Auto-install scripts**:
  - `setup-mcps.sh` — Auto-install Stage 1 (Tier 1) MCPs
  - `setup-plugins.sh` — Auto-install core plugins
- **12 superseded hooks archived** — Moved to `.claude/hooks/archive/`
- **Setup wizard updated** — Phases 4 and 5 reference auto-install scripts

### Changed

- **settings.json** — Added PreToolUse hook section with 3 guardrail hooks
- **settings.json** — Added permission-gate.js to UserPromptSubmit hooks
- **setup.md** — Updated to v2.0 with PR-10.5 auto-install references
- **Hook count** — 10 → 14 registered hooks

### Fixed

- **Guardrail hooks not executing** — Added stdin/stdout JSON wrapper to:
  - `workspace-guard.js`
  - `dangerous-op-guard.js`
  - `secret-scanner.js`
- **Hook format** — All JS hooks now use proper Claude Code stdin/stdout pattern

### Hooks Summary (14 Registered)

| Event | Hooks |
|-------|-------|
| SessionStart | session-start.sh |
| PreCompact | pre-compact.sh |
| Stop | stop-auto-clear.sh |
| PreToolUse | workspace-guard.js, dangerous-op-guard.js, secret-scanner.js |
| UserPromptSubmit | minimal-test.sh, orchestration-detector.js, self-correction-capture.js, permission-gate.js |
| PostToolUse | context-accumulator.js, cross-project-commit-tracker.js, selection-audit.js |
| SubagentStop | subagent-stop.js |

### Phase 5 Complete

This release marks the completion of **Phase 5: Tooling Baseline & Incremental Expansion**.

| PR | Description | Status |
|----|-------------|--------|
| PR-5 | Core Tooling Baseline | ✅ Complete |
| PR-6 | Plugins Expansion | ✅ Complete |
| PR-7 | Skills Inventory | ✅ Complete |
| PR-8 | MCP Expansion + Context Budget | ✅ Complete |
| PR-9 | Selection Intelligence | ✅ Complete |
| PR-10 | Persona + Organization + Setup | ✅ **Complete** |

**Next Phase**: Phase 6 — Autonomy, Self-Evolution, Benchmark Gates (PR-11 → PR-14)

---

## [1.9.5] - 2026-01-09

**PR-9.5: Documentation Consolidation — PR-9 COMPLETE**

### Changed

#### Documentation Updates
- **`capability-matrix.md`** v1.5 — Added PR-9 Selection Intelligence Integration section
- **`overlap-analysis.md`** v1.2 — Updated header with PR-9 references
- **`mcp-loading-strategy.md`** v2.2 — Added selection integration references
- **`_index.md`** — Added PR-9 patterns to Active Patterns, Recent Updates section

### PR-9 Final Summary

| Sub-PR | Description | Status |
|--------|-------------|--------|
| PR-9.0 | Component Extraction | ✅ Complete |
| PR-9.1 | Selection Framework | ✅ Complete |
| PR-9.2 | Research Tool Routing | ✅ Complete |
| PR-9.3 | Deselection Intelligence | ✅ Complete |
| PR-9.4 | Selection Validation | ✅ Complete (90% accuracy) |
| PR-9.5 | Documentation Consolidation | ✅ Complete |

**All PR-9 validation criteria met.**

---

## [1.9.4] - 2026-01-09

**PR-9.4: Selection Validation (Quality Assurance)**

### Added

#### Selection Validation Framework
- **`selection-validation-tests.md`** — 10 documented test cases with:
  - Input prompts, expected selections, rationale
  - Validation criteria (pass/acceptable/fail)
  - Scoring system (80%+ target accuracy)

#### /validate-selection Command
- **Audit Mode**: Review recent selection decisions from logs
- **Test Mode**: Run through 10 test cases and score results
- **Report Mode**: Generate comprehensive validation report

#### Selection Audit Logging
- **`selection-audit.js`** — PostToolUse hook that logs:
  - Task delegations (subagents)
  - Skill invocations
  - MCP tool selections
  - Research tool selections
- Logs to `.claude/logs/selection-audit.jsonl` in JSONL format

### Changed

- **`settings.json`** — Added selection-audit.js to PostToolUse hooks
- **`CLAUDE.md`** — Version 1.9.3 → 1.9.4

### Files Added

- `.claude/context/patterns/selection-validation-tests.md`
- `.claude/commands/validate-selection.md`
- `.claude/hooks/selection-audit.js`

---

## [1.9.3] - 2026-01-09

**PR-9.2 & PR-9.3: Research Tool Routing + Deselection Intelligence**

### Added

#### PR-9.2: Research Tool Routing (Context-Lifecycle Aware)
- **Research decision flowchart** in `mcp-design-patterns.md` with 7 decision branches
- **Context-Aware Research Selection** table with token impact ratings
- **Agent delegation patterns** with context headroom checks (50%/70% thresholds)
- **Research tool contingencies** — 4 documented recovery scenarios
- **Research MCP Loading Protocol** — session start/mid-session/cleanup
- **Context Lifecycle Tracking** section:
  - Agent context compression triggers
  - JICM metrics and monitoring commands
  - Session restart contingencies
  - Context lifecycle log analysis command

#### PR-9.3: Deselection Intelligence Enhancements
- **Expanded keyword mappings** — 35 → 65+ keywords in `suggest-mcps.sh`
- **Task-specific patterns** — "implement", "feature", "deploy", "bug", "fix"
- **Research tool routing keywords** — Aligned with PR-9.2 decision tree
- **MCP usage tracking** — `context-accumulator.js` logs MCP tool calls to `mcp-usage.json`
- **`--usage` mode** — `suggest-mcps.sh --usage` shows:
  - MCPs used this session with call counts
  - Last used timestamps
  - Unused MCPs as disable candidates

### Changed

- **`mcp-design-patterns.md`** — v1.1 → v1.2 with PR-9.2 additions
- **`context-accumulator.js`** — Added `trackMcpUsage()` function for PR-9.3
- **`CLAUDE.md`** — Version 1.9.1 → 1.9.3

### Files Modified

- `.claude/context/patterns/mcp-design-patterns.md` (Research Tool Routing + Context Lifecycle)
- `.claude/scripts/suggest-mcps.sh` (65+ keywords, --usage mode)
- `.claude/hooks/context-accumulator.js` (MCP usage tracking)

---

## [1.9.1] - 2026-01-09

**PR-9.1: Selection Intelligence Framework Complete**

### Added

#### Selection Framework Documentation
- **`selection-intelligence-guide.md`** — Lean quick reference (~2K tokens) with:
  - Quick Selection Matrix (task → first choice)
  - Research Tool Routing flowchart
  - Agent Selection decision tree
  - MCP Loading Tiers reference
  - Conflict Resolution table
  - Fallback Chains

### Changed

#### Documents Updated
- **`agent-selection-pattern.md`** — Updated to v2.0:
  - Decision flowchart with all tool modalities
  - MCP-Agent pairing table
  - Research agent routing
  - Plugin agents reference (feature-dev, hookify, pr-review-toolkit)
- **`CLAUDE.md`** — Quick Selection section enhanced:
  - Added Decision Shortcuts table
  - Referenced new selection-intelligence-guide.md

### Fixed

#### Critical: JS Hooks Not Executing
- **5 JS hooks** were silently failing due to missing stdin/stdout handling
- Hooks used `module.exports = {handler}` but Claude Code requires stdin/stdout JSON
- **Fix**: Added `if (require.main === module)` wrapper to all JS hooks
- **Affected hooks**:
  - `context-accumulator.js` (JICM)
  - `orchestration-detector.js`
  - `cross-project-commit-tracker.js`
  - `subagent-stop.js`
  - `self-correction-capture.js`
- **Result**: JICM now functional, context tracking active

### Validated

#### PR-9.0.1 Skill Validation
- All 6 extracted skills tested: docx, xlsx, pdf, pptx, mcp-builder, skill-creator
- Skills load correctly via `/skill-name` invocation
- YAML frontmatter properly formatted
- Independent of original plugin

---

## [1.9.0] - 2026-01-09

**PR-9 / AIfred Sync: Major Infrastructure Expansion** — Orchestration, Agents, JICM

### Added

#### New Agents (3)
- **`code-analyzer`** — Pre-implementation codebase analysis
- **`code-implementer`** — Code writing with full git workflow
- **`code-tester`** — Testing + Playwright automation

#### Orchestration Framework (6 files)
- **`.claude/orchestration/`** — Task decomposition system
- **`/orchestration:plan`** — Decompose complex tasks into phases
- **`/orchestration:status`** — Show progress tree
- **`/orchestration:resume`** — Cross-session continuity
- **`/orchestration:commit`** — Link commits to tasks

#### JICM — Jarvis Intelligent Context Management
- **`context-accumulator.js`** — PostToolUse hook tracks context consumption
- **`subagent-stop.js`** (enhanced) — Post-agent checkpoint trigger at 75%
- **`session-start.js`** (enhanced) — JICM state reset on /clear
- **`/smart-compact`** — Manual context checkpoint trigger
- Thresholds: 50% warning, 75% auto-trigger
- Loop prevention via state flags and excluded paths

#### Cross-Project Commit Tracking
- **`cross-project-commit-tracker.js`** — PostToolUse hook for multi-repo tracking
- **`/commits:status`** — View commits per project
- **`/commits:summary`** — Generate session summary
- Tracking stored in `.claude/logs/cross-project-commits.json`

#### Orchestration Detection
- **`orchestration-detector.js`** — UserPromptSubmit complexity scoring
- Tiered response: Score <4 skip, 4-8 suggest, ≥9 auto-invoke
- MCP tier detection (Tier 3 warnings for browser tasks)
- Skill routing (suggests relevant skills based on prompt)

#### Agent Launcher
- **`/agent`** command — Launch agents with model selection
- Model flags: `--sonnet` (default), `--opus`, `--haiku`
- Dual memory: learnings.json + Memory MCP integration
- Example: `/agent --opus deep-research "topic"`

#### Documentation
- **`lessons/corrections.md`** — Self-improvement documentation structure
- **`worktree-shell-functions.md`** — Git worktree user shell functions (Project_Aion adapted)
- **`hook-consolidation-assessment.md`** — Shell vs JS hook analysis
- **`cross-project-commit-tracking.md`** — Pattern documentation
- **`sync-report-2026-01-09.md`** — Full AIfred sync report
- **`adhoc-assessment-2026-01-09.md`** — Key discoveries and implications

### Changed

#### Commands Updated
- **`/end-session`** — Added Step 0 (context prep) and Step 9 (multi-repo push)
- **`/sync-aifred-baseline`** — Mandatory dual-report generation (formal + ad-hoc)

#### Hooks Registered (settings.json)
- UserPromptSubmit: `orchestration-detector.js`, `self-correction-capture.js`
- PostToolUse: `context-accumulator.js`, `cross-project-commit-tracker.js`
- SubagentStop: `subagent-stop.js`

#### paths-registry.yaml
- AIfred baseline updated: af66364 → 2ea4e8b
- Last sync: 2026-01-09

### Key Discoveries
- PreCompact cannot prevent autocompact (notification-only event)
- Memory systems are NOT redundant (Memory MCP, learnings.json, corrections.md)
- Git worktrees support branching from branches (not just main)
- Jarvis hooks more advanced than AIfred in several areas

### Statistics
- **ADOPT**: 14 items from AIfred baseline
- **ADAPT**: 7 items with Jarvis customization
- **Total agents**: 4 → 7
- **Total hooks registered**: 4 → 9

---

## [1.8.5] - 2026-01-09

**PR-9.0: Plugin Decomposition** — Extract and refactor plugin skills for on-demand loading

### Added

#### Extracted Skills (6 total, ~65.5K tokens on-demand)
- **docx** (~12.5K) — Word document creation, editing, tracked changes
- **xlsx** (~2.6K) — Spreadsheet creation with formulas and formatting
- **pdf** (~8.3K) — PDF creation, forms, merge/split operations
- **pptx** (~14K) — PowerPoint presentations with speaker notes
- **mcp-builder** (~23K) — MCP server development guide
- **skill-creator** (~5.1K) — Claude Code skill development guide

#### Tooling
- **`.claude/scripts/extract-skill.sh`** — Automated skill extraction from plugin cache
  - Lists available skills: `--list <marketplace> <plugin>`
  - Extracts to Jarvis: `<marketplace> <plugin> <skill>`
  - Reports token estimates and file counts

#### Documentation
- **`.claude/reports/pr-9.0-decomposition-report.md`** — Full decomposition analysis
  - Overlap matrices (document skills, development skills, cross-category)
  - Capability matrix updates
  - Validation test plan for post-restart testing

### Changed
- **`plugin-decomposition-pattern.md`** v2.0 → v3.0
  - ALWAYS decompose policy (decompose or REJECT, never keep bundled)
  - Progressive Disclosure Architecture compatibility requirements
  - 11-field YAML frontmatter standard
  - Tool-Use Validation Framework with checklist
  - Selection Guidance section requirements

### Token Impact
- **Before**: Plugin bundles loaded ~86K tokens (document-skills + example-skills)
- **After**: Individual skills load 2.6K-23K on-demand
- **Savings**: Up to 96% reduction per task (86K → 2.6K for xlsx-only task)

---

## [1.8.4] - 2026-01-09

**PR-8.5: MCP Initialization Protocol** — Automated MCP lifecycle management

### Added

#### MCP Initialization Protocol
- **`.claude/scripts/suggest-mcps.sh`** — Keyword-to-MCP mapping (30+ rules)
  - Analyzes "Next Step" in session-state.md
  - Suggests enable/disable actions
  - JSON mode for hook integration
- **Session-start hook integration** — Auto-suggests MCPs on startup/resume
- **Session-exit protocol** — MCP state capture and prediction

#### Documentation Updates
- **`mcp-loading-strategy.md` v2.1** — Full protocol flow diagram, scripts table
- **`mcp-design-patterns.md` v1.1** — MCP Session Lifecycle section
- **`session-exit.md` v2.0** — Step 2 "MCP State Capture" with scripts
- **`session-state.md`** — MCP State template (Tier 1/2/3 + predictions)

### Changed
- `session-start.sh` now calls `suggest-mcps.sh` and outputs recommendations
- Context index updated with protocol implementation entry

---

## [1.8.3] - 2026-01-09

**PR-8.5: MCP Expansion — Batch Installation** — 10 new MCPs validated

### Added

#### New MCPs Installed & Validated
- **DateTime MCP** — Timezone-aware time operations (~1K tokens, Tier 2)
- **DesktopCommander MCP** — File operations, process management (~8K tokens, Tier 2)
- **Lotus Wisdom MCP** — Contemplative reasoning framework (~2K tokens, Tier 3)
- **Wikipedia MCP** — Article search and retrieval (~2K tokens, Tier 2)
- **Chroma MCP** — Vector database operations (~4K tokens, Tier 2)
- **Perplexity MCP** — AI-powered search with citations (~3K tokens, Tier 2)
- **Playwright MCP** — Browser automation (~6K tokens, Tier 3)
- **GPTresearcher MCP** — Deep web research (~5K tokens, Tier 2)
- **Brave Search MCP** — Web search API (~3K tokens, Tier 2)
- **arXiv MCP** — Academic paper search & download (~2K tokens, Tier 2)

#### Documentation
- **`.claude/logs/mcp-validation/batch-validation-20260108.md`** — Comprehensive validation log
- **Search API Research**: `.claude/context/integrations/search-api-research.md`
- **Database MCPs** added to roadmap backlog: PostgreSQL, MySQL

### Key Discoveries
- **Discovery #7**: "Connected" ≠ "Tools Available" — MCPs require session restart
- **Discovery #8**: Perplexity `strip_thinking=true` parameter saves context tokens
- **Discovery #9**: GPTresearcher requires Python 3.13+ venv
- **Discovery #10**: Playwright accessibility snapshots more efficient than screenshots
- **Discovery #11**: Research MCP complementarity — Perplexity (fast) vs GPTresearcher (deep)

### Removed
- **DuckDuckGo MCP** — Bot detection made it unreliable

---

## [1.8.2] - 2026-01-09

**PR-8.4: MCP Validation Harness** — Systematic validation of MCP installations

### Added

#### MCP Validation Harness Pattern
- **`.claude/context/patterns/mcp-validation-harness.md`** — 5-phase validation framework
  - Phase 1: Installation Verification
  - Phase 2: Configuration Audit
  - Phase 3: Tool Inventory
  - Phase 4: Functional Testing
  - Phase 5: Tier Recommendation
  - Lessons learned from validation testing

#### Validation Infrastructure
- **`.claude/scripts/validate-mcp-installation.sh`** — Installation check script
- **`.claude/skills/mcp-validation/SKILL.md`** — `/validate-mcp` command

#### Validation Logs
- **`.claude/logs/mcp-validation/git-20260108.md`** — Git MCP: PASS, Tier 1
- **`.claude/logs/mcp-validation/memory-20260108.md`** — Memory MCP: PASS, Tier 1
- **`.claude/logs/mcp-validation/filesystem-20260108.md`** — Filesystem MCP: PASS, Tier 1
- **`.claude/logs/mcp-validation/duckduckgo-20260108.md`** — DuckDuckGo MCP: FAIL (bot detection)
- **`.claude/logs/mcp-validation/arxiv-20260109.md`** — arXiv MCP: PARTIAL (Phase 4 pending)
- **`.claude/logs/mcp-validation/brave-search-deferred.md`** — Brave Search: DEFERRED (requires API key)

### Changed

#### Updated Token Cost Estimates
- Git MCP: ~2.5K (was ~6K)
- Memory MCP: ~1.8K (was ~8-15K)
- Filesystem MCP: ~2.8K (was ~8K)
- Updated `mcp-installation.md` with accurate measurements

### Key Discoveries

1. **Mid-Session Installation**: MCPs installed mid-session require restart for tools to appear
2. **External Service Reliability**: DuckDuckGo bot detection blocks MCP requests
3. **Package Naming**: Documentation often references non-existent packages; always verify
4. **API Key Gating**: Flag missing prerequisites early in Phase 2

---

## [1.8.1] - 2026-01-07

**PR-8.3.1: Zero-Action Context Management** — Fully automated checkpoint/clear/resume workflow

### Added

#### Automated Context Management System
- **`.claude/context/patterns/automated-context-management.md`** — Comprehensive documentation
  - Architecture diagram showing hooks/watcher interaction
  - Signal file patterns and data flow
  - Testing checklist and troubleshooting guide

#### Auto-Clear Watcher
- **`.claude/scripts/auto-clear-watcher.sh`** — External keystroke automation
  - Monitors for signal file (`.auto-clear-signal`)
  - Sends `/clear` keystroke via AppleScript (macOS) or xdotool (Linux)
  - Targets Claude window, avoids watcher window
- **`.claude/scripts/launch-watcher.sh`** — Launches watcher in new Terminal window
- **`.claude/scripts/stop-watcher.sh`** — Stops watcher process

#### New Hooks
- **`.claude/hooks/pre-compact.sh`** — Auto-checkpoint on context threshold
  - Creates checkpoint before autocompaction
  - Disables Tier 2 MCPs
  - Writes signal file for watcher
- **`.claude/hooks/stop-auto-clear.sh`** — Stop hook for clear sequence
  - Blocks Claude from stopping after checkpoint
  - Instructs to run `/trigger-clear`
  - Uses `.clear-pending` marker to prevent loop

#### New Commands
- **`.claude/commands/trigger-clear.md`** — Signal watcher to send `/clear`
  - Creates signal file + pending marker
  - Invokable by Claude via Skill tool

### Changed

#### SessionStart Hook Enhanced
- Auto-launches watcher on startup/resume
- Cleans up `.clear-pending` marker
- `additionalContext` injection for auto-resume without "continue" prompt

#### Key Discovery: `disabledMcpServers` Array
- MCP disabled state stored in `~/.claude.json` → `projects.<path>.disabledMcpServers[]`
- Can programmatically disable/enable MCPs via `jq` manipulation
- `/clear` applies changes without full restart

### Technical Notes

**External Watcher Pattern**: Claude cannot programmatically execute `/clear` (built-in CLI command).
Solution: External watcher script sends keystrokes via AppleScript/xdotool.

**Stop Hook Pattern**: Inspired by Ralph Wiggum plugin's `decision: block` mechanism.
Prevents Claude from ending turn, injects prompt via `reason` field.

---

## [1.8.0] - 2026-01-07

**PR-8.1: Context Budget Optimization** — Reduce context window overhead and establish management patterns

### Added

#### Context Budget Management Pattern
- **`.claude/context/patterns/context-budget-management.md`** — Core optimization pattern
  - MCP Loading Tiers (revised 3-tier system)
  - Token budget allocation targets
  - Unload evaluation points
  - Emergency procedures for context overflow

#### Plugin Decomposition Pattern
- **`.claude/context/patterns/plugin-decomposition-pattern.md`** — Skill extraction workflow
  - Discovery: plugins are simple markdown structures, NOT compiled
  - Extraction workflow for high-value skills
  - Customization patterns for Jarvis ecosystem

#### Context Budget Command
- **`.claude/commands/context-budget.md`** — New `/context-budget` command
  - Categorizes token usage by type (Conversation, MCPs, Plugins, etc.)
  - Status levels: HEALTHY (<80%), WARNING (80-100%), CRITICAL (>100%)
  - MCP tier reference included
  - Recommendations for optimization

### Changed

#### CLAUDE.md Refactoring
- Archived original to `.claude/CLAUDE-full-reference.md` (510 lines, ~5K tokens)
- Created slim quick-reference version (113 lines, ~1K tokens)
- **78% size reduction** — ~4K tokens saved per session

#### MCP Loading Tiers (Revised)
- **Tier 1 — Always-On** (~27-34K tokens): Memory, Filesystem, Fetch, Git
- **Tier 2 — Task-Scoped** (agent-managed): Time, GitHub, Context7, Sequential Thinking, DuckDuckGo
- **Tier 3 — Triggered** (blacklisted from agent selection): Playwright, BrowserStack, Slack, Google Drive/Maps

#### Tooling Health Command
- Added Context Budget to Executive Summary table
- Now reports token usage and budget status

#### Context Index Updates
- Added context-budget-management.md pattern
- Added plugin-decomposition-pattern.md pattern

### Technical Summary

| Optimization | Token Savings |
|--------------|---------------|
| CLAUDE.md refactoring | ~4K tokens |
| Tier-based MCP loading | Variable (up to ~50K when unloading Task-Scoped) |
| Future skill extraction | ~10K+ potential |

### Key Decisions

| Component | Decision | Rationale |
|-----------|----------|-----------|
| Move Time to Tier 2 | ACCEPTED | Only needed for specific timestamp operations |
| Create Triggered tier | ACCEPTED | Blacklist high-cost MCPs from agent selection |
| Accept plugin bundle overhead | ACCEPTED | Cannot remove individual skills without losing valuable core |
| Plugin decomposition feasibility | HIGH | Skills are extractable markdown files |

---

## [1.7.0] - 2026-01-07

**PR-7: Skills Inventory** — Evaluate and document all skills

### Added

#### Skills Evaluation Report
- **`.claude/reports/pr-7-skills-evaluation.md`** — Comprehensive evaluation of 64+ skills
  - 16 Official Anthropic skills (11 ADOPT, 5 ADAPT)
  - 39 Plugin-provided skills (inherit PR-6 decisions)
  - 9 Project skills/commands (all KEEP)
  - Validation scenarios for each skill

#### Skills Overlap Analysis
- **`.claude/reports/pr-7-skills-overlap-analysis.md`** — 5 new overlap categories
  - Category 11: Document Generation
  - Category 12: Visual/Creative Design
  - Category 13: Development Skills
  - Category 14: Testing & QA
  - Category 15: Communication & Documentation

#### Skills Selection Guide
- **`.claude/context/integrations/skills-selection-guide.md`** — Quick reference
  - Selection matrix by output type and task type
  - Decision trees for common scenarios
  - Tier 1/2/3 skill recommendations for Jarvis workflows
  - Skill + MCP combination recommendations

### Changed

#### Capability Matrix Updates
- Added comprehensive Skills section (v1.3)
- Document skills (docx, pdf, pptx, xlsx, doc-coauthoring)
- Creative/visual skills (algorithmic-art, canvas-design, etc.)
- Development skills (mcp-builder, skill-creator, webapp-testing)
- Reference to skills-selection-guide.md

#### CLAUDE.md Updates
- Added skills quick links in Tooling section
- Updated version to 1.7.0

#### Context Index Updates
- Added skills-selection-guide.md to integrations

### Technical Summary

| Category | ADOPT | ADAPT | REJECT |
|----------|-------|-------|--------|
| Official Anthropic Skills | 11 | 5 | 0 |
| Plugin-Provided Skills | — | — | — (inherit PR-6) |
| Project Skills | 9 (KEEP) | — | — |

### Key Skill Decisions

| Skill | Decision | Rationale |
|-------|----------|-----------|
| docx/pdf/pptx/xlsx | ADOPT | Production-tested document creation |
| algorithmic-art | ADOPT | Unique creative capability |
| mcp-builder | ADOPT | Essential for PR-8 MCP expansion |
| canvas-design | ADAPT | Use for custom graphics beyond templates |
| frontend-design | ADAPT | Use via plugin invocation |
| webapp-testing | ADAPT | Use with Playwright MCP |
| skill-creator | ADAPT | Use for standalone skills |

---

## [1.6.0] - 2026-01-07

**PR-6: Plugins Expansion** — Evaluate and document all installed plugins

### Added

#### Plugin Evaluation Framework
- **`.claude/reports/pr-6-plugin-evaluation.md`** — Comprehensive evaluation of 17 plugins
  - Decision framework: ADOPT / ADAPT / REJECT
  - Risk assessment (LOW / MEDIUM / HIGH)
  - Overlap analysis per plugin
  - Selection rules for overlapping tools
  - Validation scenarios for each adopted plugin

#### Overlap Analysis
- **`.claude/reports/pr-6-overlap-analysis.md`** — 10 overlap categories identified
  - Category 10: Browser Automation (browser-automation vs Playwright MCP)
  - Selection rules for each category
  - Risk notes for higher-risk tools

#### Workflow Templates
- **`.claude/context/templates/tooling-evaluation-workflow.md`** — Repeatable process for evaluating new tools
- **`.claude/context/templates/overlap-analysis-workflow.md`** — Template for detecting and resolving tool conflicts
- **`.claude/context/templates/capability-matrix-update-workflow.md`** — Template for updating capability matrix

#### PR-15 Design (Future)
- **`projects/project-aion/ideas/toolset-expansion-automation.md`** — Automated toolset expansion system
  - Repository catalog system
  - Deep code review workflow
  - Self-directed discovery proposal
  - 30+ reference repositories cataloged

### Changed

#### Capability Matrix Updates
- Added Browser Automation Operations section
- Added plugin selection rules throughout
- Added browser-automation to plugin tables

#### MCP Installation Guide
- Documented Playwright MCP for PR-8 with proper installation command
- Added tools list and validation steps
- Added overlap notes with browser-automation

#### CLAUDE.md Updates
- Added Plugins section with high-value plugins table
- Added Quick Selection Guide for common tasks
- Added Output Styles documentation (mutually exclusive)
- Updated version to 1.6.0

### Technical Summary

| Category | Decision | Count |
|----------|----------|-------|
| ADOPT | Unique value, low risk | 13 |
| ADAPT | Value with conditions | 4 |
| REJECT | Redundant/problematic | 0 |

### Plugin Decisions

| Plugin | Decision | Rationale |
|--------|----------|-----------|
| agent-sdk-dev | ADOPT | Unique Agent SDK capability |
| browser-automation | ADAPT | NL browser automation (higher risk) |
| code-review | ADAPT | Keep as quick review alternative |
| explanatory-output-style | ADAPT | Mutually exclusive with learning |
| feature-dev | ADOPT | Comprehensive feature workflow |
| frontend-design | ADOPT | Unique UI quality guidance |
| hookify | ADOPT | Unique hook creation |
| learning-output-style | ADAPT | Mutually exclusive with explanatory |
| plugin-dev | ADOPT | Plugin development toolkit |
| pr-review-toolkit | ADOPT | Most comprehensive review |
| ralph-wiggum | ADOPT | Enables autonomous loops |
| security-guidance | ADOPT | Defense in depth |
| code-operations-skills | ADOPT | Bulk operations |
| engineering-workflow-skills | ADOPT | Conversational workflows |
| productivity-skills | ADOPT | Project bootstrapping |
| visual-documentation-skills | ADOPT | Visual artifacts |
| document-skills | ADOPT | Office documents |

---

## [1.5.1] - 2026-01-06

**PR-5 Implementation Phase** — Resolved all tooling health issues

### Fixed

#### GitHub MCP Authentication
- Removed failed SSE remote config (`https://api.githubcopilot.com/mcp/`)
- Added local server with PAT authentication: `@modelcontextprotocol/server-github`
- GitHub tools now fully operational

#### Context7 MCP Installation
- Installed `@upstash/context7-mcp` documentation provider
- Added API key configuration to environment
- Updated MCP installation guide with Context7 section
- Total MCP count: 8 (7 Stage 1 + Context7)

### Changed

#### Agent Format Migration
- Migrated 4 custom agents to Claude Code YAML frontmatter format:
  - `docker-deployer` — Docker service deployment
  - `service-troubleshooter` — Infrastructure diagnosis
  - `deep-research` — Technical research with citations
  - `memory-bank-synchronizer` — Documentation sync
- Backup of original format preserved in `.claude/agents/archive/`
- Updated CLAUDE.md with new invocation pattern (`/agent-name`)

#### Plugin Cleanup
- Removed stale project-scope plugin entries pointing to old path
- Cleaned plugin cache directory
- Plugin count: 19 → 16 (all user-scope, no duplicates)

### Added

#### Troubleshooting Documentation
- **`hookify-import-fix.md`** — Symlink workaround for Python import error
- **`agent-format-migration.md`** — Comprehensive migration guide with YAML schema

#### Tooling Health Reports
- **v2** — Initial assessment with smoke tests
- **v3** — Standardized template with hook validation
- **v4** — Final post-remediation report (all issues resolved)

### Technical Summary

| Category | Before (v3) | After (v4) |
|----------|-------------|------------|
| MCP Servers | 6/7 (86%) | 8/8 (100%) |
| GitHub MCP | ❌ Failed | ✅ Connected |
| Plugins | 19 (2 stale) | 16 (clean) |
| Agents | Not recognized | 4/4 migrated |
| Hooks | 18/18 | 18/18 |

---

## [1.5.0] - 2026-01-06

**PR-5: Core Tooling Baseline** — Establish minimal, reliable default toolbox

### Added

#### Capability Matrix
- **`.claude/context/integrations/capability-matrix.md`** — Task → tool selection matrix
  - File operations, git operations, web/research, GitHub, code exploration
  - Development workflows, document generation, infrastructure
  - Decision tree for tool selection
  - Loading strategy summary (Always-On vs On-Demand)

#### Overlap Analysis
- **`.claude/context/integrations/overlap-analysis.md`** — Tool overlap & conflict resolution
  - Identified 9 overlap categories with resolution rules
  - Selection priority for each category
  - Hard rules and soft rules for conflict prevention
  - Monitoring and adjustment guidelines

#### MCP Installation Guide
- **`.claude/context/integrations/mcp-installation.md`** — Stage 1 MCP installation
  - 7 Stage 1 servers: Memory, Filesystem, Fetch, Time, Git, Sequential Thinking, GitHub
  - Installation commands, validation procedures, token costs
  - Bulk installation script
  - Prerequisites check

#### Tooling Health Command
- **`.claude/commands/tooling-health.md`** — `/tooling-health` command
  - Validates MCP servers, plugins, skills, built-in tools, subagents
  - Reports Stage 1 baseline coverage
  - Provides installation recommendations

### Updated
- **CLAUDE.md** — Added Tooling quick links section, `/tooling-health` command
- **`.claude/context/_index.md`** — Added integrations documentation

### Research Findings

Official Anthropic tooling inventory:
- **7 Core MCP Servers** (modelcontextprotocol/servers)
- **13 Official Claude Code Plugins** (anthropics/claude-code/plugins)
- **16 Official Skills** (anthropics/skills)
- **5 Built-in Subagents** (Explore, Plan, claude-code-guide, general-purpose, statusline-setup)

---

## [1.4.0] - 2026-01-06

**Skills System & Lifecycle Hooks** — Full compliance with AIfred baseline af66364

### Added

#### Skills System

New abstraction layer for multi-step workflow guidance:

- **`.claude/skills/_index.md`** — Skills directory index
  - Documents Skills vs Commands vs Agents decision guide
  - Directory structure and frontmatter conventions

- **`.claude/skills/session-management/SKILL.md`** — Session lifecycle skill
  - Comprehensive session management: start, during, checkpoint, end
  - Visual workflow diagram
  - Component references: hooks, commands, state files
  - Integration points with Memory MCP, doc sync, guardrails

- **`.claude/skills/session-management/examples/typical-session.md`** — Usage walkthrough
  - Multi-session feature development example
  - Demonstrates checkpoint, doc sync, and proper exit

#### Lifecycle Hooks (6 new hooks)

- **`session-start.js`** (SessionStart) — Auto-load context on startup
  - Injects session-state.md, current-priorities.md
  - Shows git branch and status
  - Checks AIfred baseline for updates

- **`session-stop.js`** (Stop) — Desktop notification on exit
  - macOS: Uses osascript
  - Linux: Uses notify-send
  - Different notifications for success/error/cancel

- **`self-correction-capture.js`** (UserPromptSubmit) — Capture corrections as lessons
  - Detects patterns: "No, actually...", "That's wrong", etc.
  - Severity levels: HIGH, MEDIUM, LOW
  - Logs to `.claude/logs/corrections.jsonl`

- **`subagent-stop.js`** (SubagentStop) — Agent completion handling
  - Logs to `.claude/logs/agent-activity.jsonl`
  - Detects HIGH/CRITICAL issues in output
  - Agent-specific follow-up suggestions

- **`pre-compact.js`** (PreCompact) — Preserve context before compaction
  - Extracts key sections from session-state.md
  - Logs to `.claude/logs/compaction-history.jsonl`
  - Ensures critical context survives compaction

- **`worktree-manager.js`** (PostToolUse) — Git worktree tracking
  - Detects worktree vs main repo
  - Warns about cross-worktree file access
  - Logs state to `.claude/logs/.worktree-state.json`

#### Documentation Synchronization

- **`doc-sync-trigger.js`** (PostToolUse) — Track code changes
  - Monitors Write/Edit on significant files
  - After 5+ changes in 24 hours, suggests sync
  - 4-hour cooldown between suggestions
  - State persists to `.claude/logs/.doc-sync-state.json`

- **`memory-bank-synchronizer`** agent — Sync documentation with code
  - Maintains consistency between code, docs, and Memory graph
  - CRITICAL preservation rules: never delete user content
  - Safe updates: code examples, paths, counts, versions
  - Results to `.claude/agents/results/memory-bank-synchronizer/`

### Changed

#### CLAUDE.md Enhancements

- Added **Skills System** section with available skills and decision guide
- Added **Documentation Synchronization** section
- Added `memory-bank-synchronizer` to agents list
- Updated hooks table (now 18 hooks)
- Added session-management skill to Quick Links
- Updated version to 1.4.0
- Updated baseline reference to `af66364`

#### hooks/README.md Overhaul

- Reorganized into categories: Lifecycle, Guardrail, Security, Observability, Documentation, Utility
- Added detailed descriptions for all 6 new lifecycle hooks
- Added Documentation Sync Trigger section
- Updated hook count to 18
- Added new log file locations

### Technical Summary

| Category | Before | After |
|----------|--------|-------|
| Total hooks | 11 | 18 |
| Total agents | 3 | 4 |
| Skills | 0 | 1 |
| Hook types | 4 | 8 |

### Port Classification

From AIfred baseline `af66364`:

| Classification | Count | Items |
|----------------|-------|-------|
| ADOPT | 2 | doc-sync-trigger.js, agent results .gitkeep |
| ADAPT | 10 | memory-bank-synchronizer, skills/*, hooks/README.md, CLAUDE.md |
| IMPLEMENT | 6 | session-start, session-stop, self-correction-capture, subagent-stop, pre-compact, worktree-manager |

---

## [1.3.1] - 2026-01-06

**Validation & UX Improvements** — Post-v1.3.0 thorough validation with fixes

### Added

#### Validation Scripts
- **`scripts/setup-readiness.sh`** — Standalone readiness report script
  - Accepts optional JARVIS_PATH argument for testing
  - Clean terminal output (no raw bash shown to user)
  - Proper exit codes (0=ready, 1=degraded, 2=not ready)
- **`scripts/validate-hooks.sh`** — Hook syntax validation script
  - Clean pass/fail output per hook
  - No confusing intermediate errors
  - Shows actual error messages on failure

#### Setup UX Improvements Brainstorm
- **`projects/project-aion/ideas/setup-ux-improvements.md`**
  - Documents UX issues found during Option C validation
  - Tracks fixes applied and remaining items

### Changed

#### Phase 1: System Discovery
- Updated projects_root detection to recommend `~/Claude/Projects` as default
- Added clear explanation of the recommended location

#### Phase 2: Purpose Interview
- Changed project management question to present `~/Claude/Projects` as recommended default
- Added follow-up options for existing projects in other locations

#### Phase 4: MCP Integration (Major Refactor)
- Made MCP entirely **optional** (Jarvis works without it)
- Added three clear options: Skip / Docker Desktop MCP / Manual configuration
- Removed incorrect mcp-gateway docker-compose.yml (was treating stdio server as daemon)
- Added `docker/mcp-gateway/README.md` explaining actual architecture
- Clarified Docker Desktop MCP vs Docker CLI requirements

#### Phase 5: Hooks & Automation
- Updated to use `scripts/validate-hooks.sh` for validation

#### Phase 6: Agent Deployment
- Added agent selection interview section
- Users can now choose: Install all / Select specific / Skip
- Default remains "install all core agents"

### Reorganized

#### Project Structure (BEHAVIOR vs EVOLUTION separation)
- Moved `docs/project-aion/` → `projects/project-aion/`
- Moved `Project_Aion.md` → `projects/project-aion/roadmap.md`
- Moved `.claude/context/ideas/` → `projects/project-aion/ideas/`
- Established clear separation:
  - `.claude/context/` = BEHAVIOR (how Jarvis operates)
  - `projects/project-aion/` = EVOLUTION (how Jarvis improves)

### Validation

**Option C Thorough Validation** completed successfully:
- Fresh clone to `/tmp/jarvis-validation-test/`
- Full `/setup` run from Phase 0A
- Result: **17/17 checks passed, FULLY READY**

---

## [1.3.0] - 2026-01-05

**PR-4 Complete: Setup Preflight + Guardrails** — Three-layer validation system

### Added

#### Setup Readiness Command (PR-4c)

- **`/setup-readiness`** (`.claude/commands/setup-readiness.md`)
  - Post-setup validation command generating deterministic readiness report
  - Checks: environment, structure, components, tools
  - Status levels: FULLY READY, READY (warnings), DEGRADED, NOT READY
  - Severity ratings: Critical, High, Medium, Low
  - Exit codes for automation (0=ready, 1=degraded, 2=not ready)

#### Setup Validation Pattern

- **`setup-validation.md`** (`.claude/context/patterns/`)
  - Documents three-layer validation approach: Preflight → Readiness → Health
  - Defines validation tiers: Quick (2s), Standard (10s), Deep (60s)
  - Troubleshooting guidance for common failures
  - Integration points with session start, health check, end session

#### Ideas Directory

- **`.claude/context/ideas/`** — New brainstorm/planning space
  - `tool-conformity-pattern.md`: External tool behavior normalization (future PR-9b)
  - `setup-regression-testing.md`: Periodic re-validation after tool additions (future PR-10b)

#### PR-4 Plan Archive

- **`docs/project-aion/plans/`** — Conformant location for implementation plans
  - Moved `wild-mapping-rose.md` from `~/.claude/plans/` to `pr-4-implementation-plan.md`
  - Establishes convention for plan file storage within Jarvis workspace

### Changed

#### Setup Command Updates

- **`setup.md`**: Enhanced phase descriptions
  - Phase numbers now 0A-7 (was 0-7)
  - Added PR references (PR-4a, PR-4b, PR-4c)
  - Added final verification step calling `/setup-readiness`
  - Updated wizard version to 1.3

#### Finalization Phase Updates

- **`07-finalization.md`**: Added readiness verification step
  - Step 6: Verify Readiness (before git commit)
  - Updated cleanup checklist to include readiness check
  - Renumbered subsequent steps (7-8)

#### CLAUDE.md Updates

- Added **Guardrails (PR-4a)** section documenting protection hooks
- Added **Setup Validation (PR-4)** section with three-layer validation overview
- Added `/setup-readiness` to Available Commands
- Updated version references to 1.3.0

#### Context Index Updates

- Added Ideas section to context index
- Added Project Aion Plans section
- Updated Recent Updates with PR-4c changes

### PR-4 Summary

PR-4 implements a complete setup validation system:

| Sub-PR | Version | What |
|--------|---------|------|
| PR-4a | v1.2.1 | Guardrail hooks (workspace-guard, dangerous-op-guard, permission-gate) |
| PR-4b | v1.2.2 | Preflight system (workspace-allowlist.yaml, 00-preflight.md) |
| PR-4c | v1.3.0 | Readiness report (setup-readiness.md, setup-validation pattern) |

The three layers work together:
1. **Preflight** (pre-setup): Validates workspace boundaries
2. **Readiness** (post-setup): Confirms all components installed
3. **Health** (ongoing): Detects regression and drift

---

## [1.2.2] - 2026-01-05

**PR-4b: Preflight System** — Second sub-PR of Setup Preflight + Guardrails

### Added

#### Workspace Allowlist Configuration

- **`workspace-allowlist.yaml`** (`.claude/config/`)
  - Declarative workspace boundary definitions
  - Used by guardrail hooks for access control
  - Sections: core_workspaces, readonly_workspaces, project_workspaces, forbidden_paths, warn_paths
  - Configurable hook error behavior (block/warn/allow)
  - Support for user overrides with explicit confirmation

#### Environment Preflight Phase

- **`00-preflight.md`** (`.claude/archive/setup-phases/`)
  - New Phase 0A: Environment preflight checks
  - Validates workspace configuration before `/setup` proceeds
  - Checks: workspace isolation, forbidden paths, required structure, git status
  - Produces deterministic PASS/FAIL with actionable guidance
  - Executable bash script included for automation

### Changed

- **`00-prerequisites.md`**: Renamed from Phase 0 to Phase 0B
  - Now runs after preflight passes
  - Updated header, footer, and references
  - Changed "AIfred" references to "Jarvis"

### Technical Notes

- Preflight checks are **blocking** — setup cannot proceed until all required checks pass
- Recommended checks produce warnings but don't block
- Allowlist config is read by `workspace-guard.js` hook (from PR-4a)
- Phase numbering now 0A-7 (was 0-7), total 8 phases

---

## [1.2.1] - 2026-01-05

**PR-4a: Guardrail Hooks** — First sub-PR of Setup Preflight + Guardrails

### Added

#### Guardrail Hooks

Three new hooks implementing workspace protection and safety guardrails:

- **`workspace-guard.js`** (PreToolUse)
  - Blocks Write/Edit operations to AIfred baseline (always)
  - Blocks operations to forbidden system paths (`/`, `/etc`, `/usr`, `~/.ssh`, etc.)
  - Warns on operations outside Jarvis workspace
  - Fail-open behavior: logs warning but allows on config errors

- **`dangerous-op-guard.js`** (PreToolUse)
  - Blocks destructive patterns: `rm -rf /`, `sudo rm -rf`, `mkfs`, disk `dd`, fork bombs
  - Blocks force push to main/master branches
  - Warns on `rm -r`, `git reset --hard`, `git clean -fd`
  - Fail-open behavior: logs warning but allows on pattern errors

- **`permission-gate.js`** (UserPromptSubmit)
  - Soft-gates policy-crossing operations with system reminders
  - Detects: AIfred baseline mentions, force push, mass deletion, protected branches, credentials
  - Formalizes the "ad-hoc permission check" pattern from PR-3 validation
  - Suggests using AskUserQuestion for explicit confirmation

#### Settings Protection

- Added AIfred baseline to `settings.json` deny patterns:
  - `Write(/Users/aircannon/Claude/AIfred/**)`
  - `Edit(/Users/aircannon/Claude/AIfred/**)`

### Changed

- Updated hooks README with guardrail hook documentation
- Renamed hooks README from "AIfred Hooks" to "Jarvis Hooks"
- Reorganized hook table into categories: Guardrail, Security, Observability

### Technical Notes

- All guardrail hooks use **fail-open** pattern (prioritize availability)
- Multi-layer baseline protection: hooks + settings.json deny patterns
- PR-4a is the first of three sub-PRs for PR-4 (Setup Preflight + Guardrails)
- PR-4b will add preflight system, PR-4c will add readiness report

---

## [1.2.0] - 2026-01-05

**PR-3: Upstream Sync Workflow** — Controlled porting from AIfred baseline

### Added

#### `/sync-aifred-baseline` Command
- Analyze AIfred baseline changes for controlled porting to Jarvis
- **Dry-run mode** (default): Report only, no changes applied
- **Full mode**: Generate patches and offer to apply with review
- Structured adopt/adapt/reject/defer classification system
- Location: `.claude/commands/sync-aifred-baseline.md`

#### Port Log Tracking
- Audit trail for all porting decisions at `.claude/context/upstream/port-log.md`
- Tracks: baseline commit, Jarvis commit, classification, rationale, modifications
- Initial fork from `dc0e8ac` documented

#### Sync Report Format
- Standardized reports at `.claude/context/upstream/sync-report-*.md`
- Includes: summary counts, detailed analysis per file, recommended actions
- First report generated for validation (no upstream changes at time of release)

#### Session-Start Integration
- Enhanced `session-start-checklist.md` with sync workflow reference
- Quick check for new changes since last sync point
- Links to `/sync-aifred-baseline` for deeper analysis

#### Registry Updates
- Extended `paths-registry.yaml` with sync tracking fields:
  - `last_synced_commit`: Commit hash Jarvis last synced from
  - `last_sync_date`: When sync occurred
  - `sync_command`: Reference to the sync command
  - `port_log`: Path to port log file

### Changed
- **Milestone-Based Versioning**: Version bumps now tied to PR/roadmap lifecycle
  - PATCH for validation/benchmarks, MINOR for PR completion, MAJOR for phase completion

### Validation Status

> **Note**: This release establishes the upstream sync infrastructure. Full workflow
> validation requires upstream changes to exist in the AIfred baseline. The command
> structure, report format, and tracking systems have been validated with a "no changes"
> scenario. Real-world validation will occur when David O'Neil pushes updates to the
> AIfred baseline `main` branch.
>
> **Action Required**: Run `/sync-aifred-baseline` when baseline updates are detected
> to validate the full adopt/adapt/reject workflow.

---

## [1.1.0] - 2026-01-05

### Added

#### Branching Strategy
- Established `Project_Aion` branch for all Archon development
  - `.claude/context/patterns/branching-strategy.md`
  - `main` branch remains read-only baseline
  - All commits/pushes go to `Project_Aion` branch

#### PR-2: Workspace & Project Summaries (Complete)
- **Project Summary Template**: Standardized template for tracking projects
  - `knowledge/templates/project-summary.md`
  - Distinct from project-context.md (summary vs detailed notes)
- **Refined /register-project Command**: Updated for workspace-path-policy compliance
  - Supports both local paths and GitHub URLs
  - Creates summary in `Jarvis/projects/`
  - Documents path policy and special cases
- **Refined /create-project Command**: Updated for workspace-path-policy compliance
  - Creates projects at `/Users/aircannon/Claude/<name>/`
  - Initializes with `.claude/CLAUDE.md`
  - Supports `--github` flag for repo creation
- **Updated paths-registry.yaml**: Fixed project paths
  - `projects_root` now correctly points to `/Users/aircannon/Claude`
  - Added `summaries_path` for clarity
  - Added `jarvis` section with version info
  - Added `aifred_baseline` section for read-only tracking
- **PR-2 Validation Document**: Smoke tests for project registration
  - `docs/project-aion/pr2-validation.md`

---

## [1.0.0] - 2026-01-05

### Added

#### PR-1.A/B: Archon Identity
- **Project Aion Identity**: Established Archon terminology and identity documentation
  - Jarvis as master Archon (dev + infrastructure + Archon builder)
  - Jeeves as always-on Archon (concept stage)
  - Wallace as creative writer Archon (concept stage)
- **Upstream Relationship**: Documented AIfred baseline as read-only reference
  - Derived from AIfred baseline commit `dc0e8ac` (2026-01-03)
  - Controlled porting workflow: pull → diff → propose → apply

#### PR-1.C: Baseline Update
- Updated AIfred baseline mirror to latest commit `dc0e8ac`

#### PR-1.D: Session Start Pattern
- **Session Start Checklist**: New pattern requiring baseline update check at session start
  - `.claude/context/patterns/session-start-checklist.md`
  - Integrated into CLAUDE.md Session Management section

#### PR-1.E: Workspace Path Policy
- **Workspace Path Policy**: Canonical locations for all projects and docs
  - `.claude/context/patterns/workspace-path-policy.md`
  - Projects root: `/Users/aircannon/Claude/<ProjectName>/`
  - Project Aion docs: `docs/project-aion/`
  - Jarvis summaries: `projects/`

#### PR-1.F/G: Versioning
- **Versioning Policy**: Semantic versioning with lineage tracking
  - MAJOR.MINOR.PATCH scheme
  - Patch bumps for benchmarks/tests
  - Minor bumps for features
  - Major bumps for breaking changes
- **Changelog Convention**: Keep a Changelog format
- **Version Tracking**: VERSION file and documentation references
- **Version Bump Script**: `scripts/bump-version.sh` for automation

#### PR-1.H: Archive Pattern
- **Archive System**: Pattern for archiving obsolete documentation
  - `docs/archive/` directory created
  - `docs/archive/archive-log.md` for tracking
  - Archived `PROJECT-PLAN.md` (superseded by Project Aion roadmap)

#### PR-2 (Partial): One-Shot PRD
- **One-Shot PRD Template**: Minimal end-to-end deliverable spec for autonomy benchmarking
  - `docs/project-aion/one-shot-prd.md`
  - Aion Hello Console specification

### Foundation (Inherited from AIfred baseline)
- Session management with `/end-session`
- Audit logging via hooks
- Custom agents: docker-deployer, service-troubleshooter, deep-research
- MCP integration framework
- Project registration system
- PARC, DDLA, COSA workflow patterns

---

## Lineage

| Property | Value |
|----------|-------|
| **Archon** | Jarvis (Master) |
| **Derived From** | [AIfred baseline](https://github.com/davidmoneil/AIfred) by David O'Neil |
| **Baseline Commit** | `dc0e8ac` (2026-01-03) |
| **Divergence** | Project Aion follows independent development track |

---

*Jarvis — Project Aion Master Archon*
