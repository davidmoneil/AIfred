# Current Priorities

Active tasks and priorities for Project Aion (Jarvis Archon).

**Last Updated**: 2026-01-05

---

## In Progress

### PR-3: Upstream Sync Workflow
- [ ] Create `/sync-aifred-baseline` command
- [ ] Implement diff report generation
- [ ] Create adopt/adapt/reject classification
- [ ] Build port log tracking
- [ ] Integrate baseline diff into session-start pattern

---

## This Week

- [ ] Complete PR-3 upstream sync workflow
- [ ] Enable Memory MCP in Docker Desktop
- [ ] Start PR-4 setup preflight improvements

---

## This Month

### PR-4: Setup Preflight + Guardrails
- [ ] Add prereqs & environment checks to `/setup`
- [ ] Implement permission allowlists
- [ ] Create setup readiness report

### PR-5: Core Tooling Baseline
- [ ] Install/enable default MCP servers
- [ ] Create capability matrix
- [ ] Perform overlap/conflict analysis

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
