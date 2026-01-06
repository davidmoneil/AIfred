# Current Priorities

Active tasks and priorities for Project Aion (Jarvis Archon).

**Last Updated**: 2026-01-06

---

## In Progress

*No active PRs — PR-5 complete, ready for PR-6*

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
- [ ] Enable Memory MCP in Docker Desktop

---

## This Month

### PR-6: Plugins Expansion (Next)
- [ ] Install and evaluate official Claude Code plugins
- [ ] Adopt/adapt/reject decisions for each
- [ ] Overlap/conflict analysis vs existing agents/hooks

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

### 2026-01-06
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
