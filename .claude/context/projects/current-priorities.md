# Current Priorities

Active tasks and priorities for Project Aion (Jarvis Archon).

**Last Updated**: 2026-01-05

---

## In Progress

*No active PRs — PR-4 complete, ready for PR-5*

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
- [ ] Enable Memory MCP in Docker Desktop

---

## This Month

### PR-5: Core Tooling Baseline
- [ ] Install/enable default MCP servers
- [ ] Create capability matrix
- [ ] Perform overlap/conflict analysis

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
