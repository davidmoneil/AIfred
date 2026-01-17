# Current Priorities

Active tasks and priorities for Project Aion (Jarvis Archon).

**Last Updated**: 2026-01-16

---

## Recently Completed

### RLE-001: Ralph Loop Comparison Experiment (2026-01-17)
**Status**: ✅ Complete — Research Documentation Created

**Objective**: Compare tool construction using Official vs Native Ralph Loop systems

**Phases Completed**:
- [x] Phase 1: Build Decompose-Official using Official Ralph Loop
- [x] Phase 2: Integrate ralph-loop natively, seal official artifacts
- [x] Phase 3: Build Decompose-Native blind (using native ralph-loop)
- [x] Phase 4: Formal validation suite (11/11 tests PASS)
- [x] Phase 5: Integration test with example-plugin
- [x] Phase 6: Comparison analysis

**Key Findings**:
- Native Ralph Loop enables agent self-invocation (Official cannot)
- 24.3% code reduction in blind build (1375 vs 1817 lines)
- Feature parity achieved: 9/9 features, 100% test pass rate
- Bug discovered and fixed during blind development

**Deliverables**:
- `.claude/scripts/plugin-decompose.sh` — Decompose tool (1151 lines)
- `projects/project-aion/reports/ralph-loop-experiment/` — Research documentation
- `.claude/commands/ralph-loop.md` — Native Ralph Loop command

---

### PR-10: Jarvis Persona + Project Organization + Setup Upgrade (v2.0.0)
**Status**: ✅ Complete (2026-01-13) — **Phase 5 Complete**

- [x] PR-10.1: Persona Implementation — `jarvis-identity.md`, CLAUDE.md updated
- [x] PR-10.2: Reports Reorganization — PR reports moved to `projects/project-aion/reports/`
- [x] PR-10.3: Directory Cleanup — `knowledge/` phased out, `commands/` consolidated
- [x] PR-10.4: Documentation + Organization Cleanup
- [x] PR-10.5: Setup Upgrade — 4 guardrail hooks registered, auto-install scripts created
- [x] PR-10.6: Validation & Release → v2.0.0

**Key Deliverables**:
- 4 guardrail hooks (workspace-guard, dangerous-op-guard, secret-scanner, permission-gate)
- setup-mcps.sh, setup-plugins.sh auto-install scripts
- 14 registered hooks (up from 10)

### PR-9: Selection Intelligence (v1.9.5)
**Status**: ✅ Complete (2026-01-09)

- [x] PR-9.0: Component Extraction — 6 skills from document-skills
- [x] PR-9.1: Selection Framework — selection-intelligence-guide.md
- [x] PR-9.2: Research Tool Routing — Context-lifecycle aware
- [x] PR-9.3: Deselection Intelligence — 65+ keywords, MCP tracking
- [x] PR-9.4: Selection Validation — 90% accuracy (exceeded 80% target)
- [x] PR-9.5: Documentation Consolidation

**Key Deliverables**: selection-intelligence-guide.md, selection-validation-tests.md, selection-audit.js

---

## Up Next

### Phase 6: Autonomy, Self-Evolution & Benchmark Gates (PR-11 → PR-14)
**Status**: ✅ Design Phase Complete — All Specifications Created

**Design Document**: `projects/project-aion/ideas/phase-6-autonomy-design.md`

**Eight Autonomic Systems** (to be implemented):
1. Self-Launch Protocol — Initialize with full context awareness
2. Wiggum Loop Integration — Drive work to completion
3. Independent Milestone Review — Quality gate for PR completion
4. Enhanced Context Management (JICM v2) — Resource optimization
5. Self-Reflection Cycles — Learn from experience
6. Self-Evolution Cycles — Safe self-modification
7. R&D Cycles — External innovation discovery
8. Maintenance Workflows — Codebase hygiene
9. Session Completion — Clean handoff

**Restructured PRs**:
| PR | Description | Sub-PRs |
|----|-------------|---------|
| PR-11 | Autonomic Component Framework | 6 (11.1-11.6) |
| PR-12 | Autonomic Component Implementation | 9 (12.1-12.9) |
| PR-13 | Monitoring, Benchmarking, Scoring | 5 (13.1-13.5) |
| PR-14 | Open-Source Catalog & SOTA | 5 (14.1-14.5) |

**Progress**:
- [x] PR-11.1: Component Specification Standard ✅ (2026-01-16)
- [x] PR-11.2: Component Interaction Protocol ✅ (2026-01-16)
- [x] PR-11.3: Metrics Collection Standard ✅ (2026-01-16)
- [x] PR-11.4: Gate Pattern Standard ✅ (2026-01-16)
- [x] PR-11.5: Override and Disable Pattern ✅ (2026-01-16)
- [x] PR-11.6: Testing Framework ✅ (2026-01-16)

**PR-11 COMPLETE** — All 6 sub-PRs finished

**PR-12 Progress**:
- [x] PR-12.1: Self-Launch System ✅ (2026-01-16)
- [x] PR-12.2: Wiggum Loop Integration ✅ (2026-01-16)
- [x] PR-12.3: Independent Milestone Review ✅ (2026-01-16)
- [x] PR-12.4: JICM Enhanced Context Management ✅ (2026-01-16)
- [x] PR-12.5: Self-Reflection Cycles ✅ (2026-01-16)
- [x] PR-12.6: Self-Evolution Cycles ✅ (2026-01-16)
- [x] PR-12.7: R&D Cycles ✅ (2026-01-16)
- [x] PR-12.8: Maintenance Workflows ✅ (2026-01-16)
- [x] PR-12.9: Session Completion System ✅ (2026-01-16)
- [x] PR-12.10: Self-Improvement Command ✅ (2026-01-16)

**PR-12 COMPLETE** — All 10 sub-PRs finished

**PR-13 Progress**:
- [x] PR-13.1: Telemetry System ✅ (2026-01-16)
- [x] PR-13.2: Benchmark Suite ✅ (2026-01-16)
- [x] PR-13.3: Scoring Framework ✅ (2026-01-16)
- [x] PR-13.4: Dashboard and Reporting ✅ (2026-01-16)
- [x] PR-13.5: Regression Detection ✅ (2026-01-16)

**PR-13 COMPLETE** — All 5 sub-PRs finished

**PR-14 Progress**:
- [x] PR-14.1: Catalog Structure ✅ (2026-01-16)
- [x] PR-14.2: Initial Population ✅ (2026-01-16)
- [x] PR-14.3: Comparison Framework ✅ (2026-01-16)
- [x] PR-14.4: Adoption/Adaptation Pipeline ✅ (2026-01-16)
- [x] PR-14.5: Scheduled Research Integration ✅ (2026-01-16)

**PR-14 COMPLETE** — All 5 sub-PRs finished

**PHASE 6 DESIGN COMPLETE** — All specifications (PR-11 through PR-14) created

See `projects/project-aion/roadmap.md` for full Phase 6 scope.

---

## In Progress

### PR-5 Extended: Tooling Implementation
**Status**: ✅ Complete (v1.5.1) — All issues resolved

Per `.claude/reports/tooling-health-2026-01-06-v4.md`:
- [x] Fix GitHub MCP authentication (PAT via local server)
- [x] Install Context7 MCP (documentation provider)
- [x] Agent format migration (4 agents to YAML frontmatter)
- [x] Remove legacy plugins (stale entries cleaned)
- [x] 16 plugins installed (user-scope)
- [x] 18/18 hooks validated

**Deferred to PR-6/PR-7**:
- [ ] Feature trials (happy, voicemode)
- [ ] Extended plugin evaluation

---

## Validation Backlog

> **Important**: These items require real-world validation when conditions are met.

### PR-3 Validation: `/sync-aifred-baseline` Command
**Status**: ✅ Complete (2026-01-05)

Validation performed by pushing a test file to AIfred baseline and running sync workflow.

**Results**:
- [x] Diff report correctly identifies changed files
- [x] Classification suggestions are reasonable (REJECT for test artifact)
- [x] Port log updates properly after decisions
- [x] Report format is clear and actionable

**Artifacts**:
- Test file: AIfred `.claude/context/patterns/sync-validation-test.md`
- Sync report: `.claude/context/upstream/sync-report-2026-01-05-validation.md`
- Port log entry: 2026-01-05 REJECT documented

---

## This Week

- [x] Complete PR-3 upstream sync workflow ✅ Released as v1.2.0
- [x] Validate `/sync-aifred-baseline` ✅ Verified 2026-01-05
- [x] Complete PR-4 setup preflight + guardrails ✅ Released as v1.3.0
- [x] Option C thorough validation ✅ FULLY READY 2026-01-06
- [x] Setup UX improvements ✅ 5 fixes committed 2026-01-06
- [x] PR-5: Core Tooling Baseline ✅ Released as v1.5.0
- [x] Stage 1 MCPs installed (6/7 connected, GitHub needs OAuth)
- [x] Tooling Health Assessment ✅ Comprehensive report created
- [x] PR-5 Implementation ✅ All issues resolved (v1.5.1)
  - GitHub MCP: PAT auth configured
  - Context7 MCP: Installed with API key
  - Agents: Migrated to Claude Code format
  - Plugins: Legacy entries removed
- [ ] Enable Memory MCP in Docker Desktop

---

## This Month

### PR-8: MCP Expansion + Context Budget (In Progress)

**Completed (v1.8.0)**:
- [x] PR-8.1: Context Budget Optimization (CLAUDE.md 78% reduction, /context-budget)
- [x] PR-8.2: MCP Loading Tiers (3-tier design: Always-On/Task-Scoped/Triggered)
- [x] PR-8.3: Dynamic Loading Protocol — **KEY DISCOVERY MADE**

**KEY DISCOVERY (2026-01-07): disabledMcpServers Array**
- [x] MCP disabled state stored in `~/.claude.json` → `projects.<path>.disabledMcpServers[]`
- [x] Can programmatically disable/enable MCPs with `jq` commands
- [x] Changes take effect on next session start (exit + claude, or /clear)
- [x] Disable ≠ Uninstall — MCPs remain registered, just skipped at load
- [x] Documentation updated across 4 files

**PR-8.3.1 Implementation**: ✅ **COMPLETE + FULLY AUTOMATED**
- [x] Create `.claude/scripts/disable-mcps.sh`
- [x] Create `.claude/scripts/enable-mcps.sh`
- [x] Create `.claude/scripts/list-mcp-status.sh`
- [x] Create `/context-checkpoint` command with MCP evaluation
- [x] Test full workflow: checkpoint → disable → /clear → resume
- [x] Context reduced from ~16.2K to ~7.4K MCP tokens (54% reduction)
- [x] **Bug Fix**: Checkpoint file deletion in session-start.sh hook
- [x] **Zero-Action Automation** (2026-01-07):
  - [x] Auto-clear watcher (external AppleScript keystroke automation)
  - [x] Stop hook with decision:block (Ralph Wiggum pattern)
  - [x] SessionStart watcher auto-launch
  - [x] PreCompact hook for automatic checkpointing
  - [x] additionalContext injection for auto-resume
  - [x] Full end-to-end validation: checkpoint → auto-clear → auto-resume
- [x] **Documentation**: `.claude/context/patterns/automated-context-management.md`

**PR-8.4 MCP Validation Harness** (COMPLETE — 2026-01-09):
- [x] Design 5-phase validation harness pattern
- [x] Create validation script (validate-mcp-installation.sh)
- [x] Validate design MCPs (Git, Memory, Filesystem) - all Tier 1
- [x] Select testing MCPs (DuckDuckGo, Brave Search, arXiv)
- [x] Create /validate-mcp skill
- [x] Update mcp-installation.md with validated token costs
- [x] Install DuckDuckGo MCP — **FAIL** (bot detection, both npm & uvx)
- [x] Install Brave Search MCP (with API key)
- [x] Install arXiv MCP (uvx)
- [x] Research DDG alternatives (OneSearch MCP recommended)
- [x] **Discovery #7 Confirmed**: "Connected" ≠ "Tools Available" (resolved by restart)
- [x] **Brave Search PASS** — Web search functional, local search rate limited
- [x] **arXiv PASS** — Full workflow: search → download → read
- [x] **DuckDuckGo REMOVED** — Bot detection unreliable
- [x] Standardize validation workflow

**PR-8.5 MCP Expansion — Batch Installation** (2026-01-08):
- [x] DateTime MCP installed and **VALIDATED** ✅
- [x] DesktopCommander MCP installed and **VALIDATED** ✅
- [x] Lotus Wisdom MCP installed and **VALIDATED** ✅
- [x] Wikipedia MCP installed and **VALIDATED** ✅
- [x] Chroma MCP installed and **VALIDATED** ✅
- [x] Perplexity MCP installed with API key (needs restart for tools)
- [x] Playwright MCP installed (needs restart for tools)
- [x] Database MCPs (PostgreSQL, MySQL) added to backlog
- [x] GPTresearcher MCP installed (Python 3.13 venv + API keys configured)
- [x] **Perplexity VALIDATED** ✅ — search, ask, research, reason all working
- [x] **Playwright VALIDATED** ✅ — navigate, snapshot, click, close all working
- [x] **GPTresearcher VALIDATED** ✅ — quick_search, deep_research, get_sources all working

### PR-9: Selection Intelligence — COMPLETE ✅ (v1.9.5)
- [x] PR-9.0: Plugin Decomposition — 6 skills extracted
- [x] PR-9.0.1: Post-restart skill validation — All 6 skills validated
- [x] PR-9.1: Selection Framework — `selection-intelligence-guide.md` created
- [x] PR-9.2: Research Tool Routing — Context-lifecycle aware, 7 decision branches
- [x] PR-9.3: Deselection Intelligence — 65+ keywords, MCP usage tracking
- [x] PR-9.4: Selection Validation — **90% accuracy** (exceeded 80% target)
- [x] PR-9.5: Documentation Consolidation — All docs updated

**Key Deliverables**: selection-intelligence-guide.md, selection-validation-tests.md, selection-audit.js

### Future PR Ideas (from brainstorms)
- [ ] **PR-9b: Tool Conformity** — Normalize external tool behaviors to Jarvis patterns
- [ ] **PR-10b: Setup Regression Testing** — Periodic re-validation after tool additions

---

## Backlog

See `projects/Project_Aion.md` for full roadmap (PR-6 through PR-14):
- PR-6: Plugins Expansion
- PR-7: Skills Inventory
- PR-8: MCP Expansion
- PR-9: Selection Intelligence
- PR-10: Setup Upgrade
- PR-11: Autonomy & Permission Reduction
- PR-12: Self-Evolution Loop
- PR-13: Benchmark Demos
- PR-14: SOTA Research & Comparison

### Future Enhancements
- [ ] **Auto-restart after rate-limit**: Design pattern for automatic session continuation
  after API rate-limit pauses (checkpoint state → wait → resume workflow)

---

## Completed

### 2026-01-07
- [x] **PR-7 Skills Inventory** (Complete — v1.7.0)
  - Evaluated 64+ skills (16 official + 39 plugin + 9 project)
  - 11 ADOPT, 5 ADAPT, 0 REJECT for official skills
  - Created skills selection guide with decision trees
  - Added 5 overlap categories (11-15)
  - Updated capability matrix v1.3

- [x] **PR-6 Plugins Expansion** (Complete — v1.6.0)
  - Evaluated 17 plugins (13 ADOPT, 4 ADAPT, 0 REJECT)
  - Added browser-automation plugin evaluation
  - Created overlap analysis with 10 conflict categories
  - Updated capability matrix with plugin selection rules
  - Created 3 workflow templates for future tooling expansion
  - Documented Playwright MCP for PR-8
  - Designed PR-15 toolset expansion automation system
  - Added validation scenarios for all adopted plugins

### 2026-01-06
- [x] **PR-5 Tooling Implementation** (Complete — v1.5.1)
  - Fixed GitHub MCP authentication (PAT via local server)
  - Installed Context7 MCP with API key (8 MCPs total)
  - Migrated 4 agents to Claude Code YAML frontmatter format
  - Removed legacy project-scope plugins (19 → 16)
  - Created troubleshooting docs (hookify-import-fix, agent-format-migration)
  - Generated tooling health reports v2, v3, v4

- [x] **PR-5 Tooling Health Assessment** (Complete)
  - Ran `/tooling-health` command
  - Created comprehensive report (`.claude/reports/tooling-health-2026-01-06.md`)
  - MCP tool inventory: 38 tools across 6 servers
  - Plugin categorization: 14 PR-5 targets, 10 future, 12 excluded
  - Command list: 8 project + 50+ built-in with stoppage hooks
  - Custom agents analysis and unification proposal
  - Feature expansion trials defined (happy, voicemode)
  - Added anthropic-agent-skills marketplace

- [x] **PR-5: Core Tooling Baseline** (Complete — v1.5.0)
  - Created capability matrix (task → tool selection)
  - Created overlap analysis (9 categories, conflict resolution)
  - Created MCP installation guide (7 Stage 1 servers)
  - Created `/tooling-health` command
  - Installed Stage 1 MCPs (6/7 connected)
  - Research: 7 MCPs, 13 plugins, 16 skills, 5 subagents documented

- [x] **AIfred Baseline Sync** (v1.4.0) — Skills system, lifecycle hooks
- [x] **Option C Thorough Validation** — Setup passed (17/17 FULLY READY)
- [x] **Setup UX Improvements** — 5 fixes from validation feedback
  - Projects root default → `~/Claude/Projects`
  - Created `scripts/setup-readiness.sh` and `scripts/validate-hooks.sh`
  - Refactored Phase 4 MCP (optional, clearer options)
  - Added Phase 6 agent selection interview
- [x] **Project Structure Reorganization** — BEHAVIOR vs EVOLUTION separation
  - `docs/project-aion/` → `projects/project-aion/`
  - Ideas consolidated under `projects/project-aion/ideas/`

### 2026-01-05
- [x] **PR-4: Setup Preflight + Guardrails** (Complete — v1.3.0)
  - **PR-4a** (v1.2.1): Guardrail hooks (workspace-guard, dangerous-op-guard, permission-gate)
  - **PR-4b** (v1.2.2): Preflight system (workspace-allowlist.yaml, 00-preflight.md)
  - **PR-4c** (v1.3.0): Readiness report (setup-readiness.md, setup-validation pattern)
  - Created ideas directory with brainstorms for future PRs
  - Moved plan file from `~/.claude/plans/` to conformant location

- [x] **PR-3: Upstream Sync Workflow** (Complete — v1.2.0)
  - Created `/sync-aifred-baseline` command with adopt/adapt/reject classification
  - Established port log tracking at `.claude/context/upstream/port-log.md`
  - Integrated baseline diff check into session-start pattern
  - Note: Full workflow validation pending upstream changes

- [x] **PR-1: Archon Identity + Versioning + Baseline Discipline** (Complete)
  - Established Project Aion terminology (Jarvis, Jeeves, Wallace)
  - Updated AIfred baseline to `dc0e8ac`
  - Created session-start-checklist, workspace-path-policy, branching-strategy patterns
  - Established VERSION, CHANGELOG.md, bump-version.sh
  - Archived PROJECT-PLAN.md
  - Created `Project_Aion` branch, pushed to origin

- [x] **PR-2: Workspace & Project Summaries** (Complete)
  - Created Project Summary template (`knowledge/templates/project-summary.md`)
  - Refined `/register-project` command with path policy compliance
  - Refined `/create-project` command with path policy compliance
  - Fixed `paths-registry.yaml` project paths
  - Added `jarvis` and `aifred_baseline` sections to registry
  - Created validation/smoke test document
  - One-Shot PRD template created (`docs/project-aion/one-shot-prd.md`)

- [x] **Release v1.1.0 — Milestone-Based Versioning** (Complete)
  - Designed milestone-based versioning tied to PR/roadmap lifecycle
  - PATCH for validation, MINOR for PR completion, MAJOR for phase completion
  - Updated versioning-policy.md with decision tree and PR-to-version mapping
  - Updated Project_Aion.md roadmap with version milestones per phase
  - Integrated version bump check into `/end-session` workflow
  - Bumped version 1.0.0 → 1.1.0 for PR-2 completion
  - Updated all version references across 9 documentation files

### 2026-01-03
- [x] AIfred initial setup (all 8 phases)
- [x] Node.js v24 LTS installed via nvm
- [x] 8 hooks installed and validated
- [x] 3 agents deployed with memory initialized

---

## Notes

**Branch**: All work on `Project_Aion` branch (origin/Project_Aion)
**Baseline**: `main` branch is read-only AIfred baseline

Development workflow:
1. Check session-start-checklist.md at session start
2. Work on current priorities
3. Commit to Project_Aion branch
4. Run /end-session when done

---

*Project Aion — Jarvis Development Priorities*
