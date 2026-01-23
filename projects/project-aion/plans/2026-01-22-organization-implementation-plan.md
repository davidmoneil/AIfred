# Jarvis Organization Architecture — Implementation Plan

**Date**: 2026-01-22
**Findings Reference**: `progress/2026-01-22-organization-findings.md`
**Status**: Ready for Implementation
**Estimated Sessions**: 2-3

---

## Overview

This plan implements the organizational changes identified in the findings document, restructuring Jarvis according to the three-layer "Living Soul" architecture:

1. **Mind** (`/.claude/context/`) — Knowledge, patterns, state
2. **Spirit** (`/.claude/`) — Capabilities, persona, tools
3. **Body** (`/Jarvis/`) — Infrastructure, interfaces

---

## Phase 1: Prepare Project Aion Structure

**Goal**: Create the new directory structure before moving files.

### Task 1.1: Create New Directories

```bash
# Project Aion structure
mkdir -p projects/project-aion/designs/current
mkdir -p projects/project-aion/designs/archive
mkdir -p projects/project-aion/progress/current/sessions
mkdir -p projects/project-aion/progress/current/milestones
mkdir -p projects/project-aion/progress/archive
mkdir -p projects/project-aion/evolution/aifred-integration/sync-reports
mkdir -p projects/project-aion/evolution/self-improvement
mkdir -p projects/project-aion/analysis
mkdir -p projects/project-aion/external
mkdir -p projects/project-aion/ideas/current
mkdir -p projects/project-aion/ideas/archive
mkdir -p projects/project-aion/plans/current
mkdir -p projects/project-aion/plans/archive
mkdir -p projects/project-aion/reports/current
mkdir -p projects/project-aion/reports/archive
mkdir -p projects/project-aion/experiments/current
mkdir -p projects/project-aion/experiments/archive

# Jarvis context structure
mkdir -p .claude/context/plans
```

### Task 1.2: Create README.md for New Directories

Create brief README files explaining each new directory's purpose.

**Exit Criteria**:
- [ ] All directories created
- [ ] README.md in each major new directory

---

## Phase 2: Move AIfred Integration Work

**Goal**: Relocate all AIfred sync work from `/.claude/context/upstream/` to Project Aion.

### Task 2.1: Move Integration Documents

| Source | Destination |
|--------|-------------|
| `.claude/context/upstream/integration-chronicle.md` | `projects/project-aion/evolution/aifred-integration/chronicle.md` |
| `.claude/context/upstream/integration-roadmap-2026-01-21.md` | `projects/project-aion/evolution/aifred-integration/roadmap.md` |
| `.claude/context/upstream/integration-recommendations-2026-01-21.md` | `projects/project-aion/evolution/aifred-integration/recommendations.md` |
| `.claude/context/upstream/port-log.md` | `projects/project-aion/evolution/aifred-integration/port-log.md` |

### Task 2.2: Move Analysis Documents

| Source | Destination |
|--------|-------------|
| `.claude/context/upstream/code-comparison-2026-01-21.md` | `projects/project-aion/evolution/aifred-integration/sync-reports/` |
| `.claude/context/upstream/comprehensive-analysis-2026-01-21.md` | `projects/project-aion/evolution/aifred-integration/sync-reports/` |
| `.claude/context/upstream/adhoc-assessment-*.md` | `projects/project-aion/evolution/aifred-integration/sync-reports/` |
| `.claude/context/upstream/sync-report-*.md` | `projects/project-aion/evolution/aifred-integration/sync-reports/` |
| `.claude/context/analysis/aifred-commands-catalog.md` | `projects/project-aion/analysis/` |

### Task 2.3: Clean Up Source Directories

```bash
# Remove emptied directories
rm -rf .claude/context/upstream
rm -rf .claude/context/analysis
```

**Exit Criteria**:
- [ ] All files moved successfully
- [ ] Source directories removed
- [ ] No broken references in moved files

---

## Phase 3: Reorganize Core Identity Files

**Goal**: Establish the sacred top-level files and remove clutter.

### Task 3.1: Move Persona to Top Level

```bash
mv .claude/persona/jarvis-identity.md .claude/jarvis-identity.md
rm -rf .claude/persona  # After verifying README.md can be discarded
```

### Task 3.2: Move current-priorities.md Up

```bash
mv .claude/context/projects/current-priorities.md .claude/context/current-priorities.md
rm -rf .claude/context/projects
```

### Task 3.3: Remove Centralized Templates

```bash
# First, check if any templates need redistribution
ls -la .claude/context/templates/

# Templates to redistribute:
# - autonomic-component-spec.md → .claude/context/components/templates/
# - project-context.md → projects/project-aion/external/templates/
# - project-summary.md → projects/project-aion/external/templates/
# - capability-matrix-update-workflow.md → .claude/context/integrations/
# - overlap-analysis-workflow.md → .claude/context/integrations/
# - tooling-evaluation-workflow.md → .claude/context/integrations/

# Then remove
rm -rf .claude/context/templates
```

### Task 3.4: Merge Evolution Queue

```bash
mv .claude/evolution/evolution-queue.yaml .claude/state/queues/evolution-queue.yaml
rm -rf .claude/evolution
```

### Task 3.5: Archive Orphan Plans File

```bash
mv .claude/plans/humming-purring-adleman.md projects/project-aion/plans/archive/
rm -rf .claude/plans
```

**Exit Criteria**:
- [ ] jarvis-identity.md at .claude/ top level
- [ ] current-priorities.md at .claude/context/ top level
- [ ] templates/ removed and contents redistributed
- [ ] evolution/ merged into state/queues/
- [ ] Old plans/ archived

---

## Phase 4: Reorganize Project Aion Content

**Goal**: Apply current/archive structure and relocate design documents.

### Task 4.1: Move Phase-6 Design

```bash
mv projects/project-aion/ideas/phase-6-autonomy-design.md \
   projects/project-aion/designs/current/phase-6-autonomy-design.md
```

### Task 4.2: Organize Existing Ideas

Move exploratory ideas to `ideas/current/`, archive older ones.

### Task 4.3: Organize Existing Plans

```bash
# Keep prd-variants together
mv projects/project-aion/plans/prd-variants projects/project-aion/plans/current/
mv projects/project-aion/plans/one-shot-*.md projects/project-aion/plans/current/
# Archive older plans
mv projects/project-aion/plans/pr-*.md projects/project-aion/plans/archive/
```

### Task 4.4: Organize Existing Reports

```bash
# Recent (2026-01-20 onwards) → current/
# Older → archive/
# Create subdirectories: testing/, analysis/, experiments/
```

### Task 4.5: Move Project-Specific Orchestrations

```bash
mv .claude/orchestration/demo-a-orchestration.yaml \
   projects/project-aion/plans/archive/
mv .claude/orchestration/phase-6-implementation.yaml \
   projects/project-aion/plans/current/
mv .claude/orchestration/2026-01-20-autonomous-command-wrappers.yaml \
   projects/project-aion/progress/archive/
```

**Exit Criteria**:
- [ ] phase-6-autonomy-design.md in designs/current/
- [ ] Ideas organized with current/archive
- [ ] Plans organized with current/archive
- [ ] Reports organized with current/archive
- [ ] Orchestrations moved appropriately

---

## Phase 5: Create Planning Tracker

**Goal**: Establish the document registry for checklist hygiene.

### Task 5.1: Create Planning Tracker

Create `/.claude/planning-tracker.yaml`:

```yaml
# Planning Tracker — Active documents with checklists/exit criteria
# Jarvis maintains this as docs are created/archived
# Review at session-end and milestone completion

version: 1.0.0
last_updated: 2026-01-22

# Documents to always review at session-end
always_review:
  - path: .claude/context/session-state.md
    purpose: Update current work status
  - path: .claude/context/current-priorities.md
    purpose: Update task completion status

# Planning documents with checklists
planning:
  - path: projects/project-aion/roadmap.md
    contains: [pr-status, deliverables, acceptance-criteria]
    scope: project-aion
    review_on: [pr-completion, milestone-completion]

  - path: projects/project-aion/designs/current/phase-6-autonomy-design.md
    contains: [sub-pr-checklists, acceptance-criteria]
    scope: phase-6
    review_on: [milestone-completion]

  - path: projects/project-aion/evolution/aifred-integration/roadmap.md
    contains: [session-exit-criteria, milestone-checklists]
    scope: aifred-integration
    review_on: [session-end, milestone-completion]

# Progress documents
progress:
  - path: projects/project-aion/evolution/aifred-integration/chronicle.md
    contains: [milestone-completion]
    scope: aifred-integration
    review_on: [milestone-completion]
```

### Task 5.2: Update Session-End Workflow

Add checklist hygiene step to `/.claude/context/workflows/session-exit.md`:

```markdown
## Checklist Hygiene Step

Before completing session-end:

1. Read `.claude/planning-tracker.yaml`
2. For documents in `always_review`:
   - Update session-state.md with current status
   - Update current-priorities.md with completed tasks
3. For documents matching current work scope:
   - Check for unchecked items that may now be complete
   - Update checkboxes as appropriate
   - Note any deviations in progress docs
4. Update `last_updated` in planning-tracker.yaml
```

**Exit Criteria**:
- [ ] planning-tracker.yaml created
- [ ] session-exit.md updated with checklist hygiene step

---

## Phase 6: Update Core Documentation

**Goal**: Update CLAUDE.md and create map documents.

### Task 6.1: Update CLAUDE.md

Add mandatory pattern selection matrix:

```markdown
## Pattern Selection (MANDATORY)

Before beginning ANY significant task, consult:

| Task Type | Required Pattern |
|-----------|-----------------|
| Multi-step implementation | @patterns/wiggum-loop-pattern.md |
| Milestone completion | @patterns/milestone-review-pattern.md |
| Tool/agent selection | @patterns/selection-intelligence-guide.md |
| Context management | @patterns/jicm-pattern.md |
| Session start | @patterns/startup-protocol.md |
| Session end | @workflows/session-exit.md |

**Wiggum Loop is DEFAULT behavior.**
```

Update file references to reflect new locations.

### Task 6.2: Update patterns/_index.md

Create categorized index with selection guidance and strictness levels.

### Task 6.3: Update context/_index.md

Reflect new structure as "Map of the Mind" — navigation hub for all knowledge.

### Task 6.4: Create .claude/_index.md (Optional)

"Map of the Self" — explains the Spirit layer organization.

**Exit Criteria**:
- [ ] CLAUDE.md updated with pattern selection matrix
- [ ] patterns/_index.md reorganized
- [ ] context/_index.md updated as "Map of the Mind"
- [ ] File references updated throughout

---

## Phase 7: Verification and Cleanup

**Goal**: Verify all changes, fix broken references, commit.

### Task 7.1: Verify No Broken References

Search for references to moved files:
```bash
grep -r "context/upstream" .claude/
grep -r "context/projects/current-priorities" .claude/
grep -r "persona/" .claude/
```

Fix any found references.

### Task 7.2: Verify Directory Structure

```bash
# Confirm expected structure
find .claude/context -type d | sort
find projects/project-aion -type d | sort
ls -la .claude/*.md .claude/*.yaml
```

### Task 7.3: Run Tooling Health Check

```bash
/tooling-health
```

### Task 7.4: Commit Changes

```bash
git add -A
git commit -m "refactor: Implement Living Soul architecture for Jarvis organization

- Move AIfred integration work to projects/project-aion/evolution/
- Reorganize Project Aion with current/archive structure
- Elevate persona and current-priorities to top-level
- Create planning-tracker.yaml for checklist hygiene
- Remove centralized templates directory
- Merge evolution queue into state/queues/
- Update CLAUDE.md with mandatory pattern selection

Findings: projects/project-aion/progress/2026-01-22-organization-findings.md
Plan: projects/project-aion/plans/2026-01-22-organization-implementation-plan.md"
```

**Exit Criteria**:
- [ ] No broken references found
- [ ] Directory structure matches plan
- [ ] Tooling health passes
- [ ] Changes committed

---

## Phase 8: Documentation Consolidation

**Goal**: Capture learnings and update high-level memory files.

### Task 8.1: Update Session State

Update `.claude/context/session-state.md` with completion status.

### Task 8.2: Create Organization Pattern

Create `/.claude/context/patterns/organization-pattern.md`:
- Document the three-layer model
- Explain placement decisions
- Provide guidance for future files

### Task 8.3: Update Lessons

Add to `/.claude/context/lessons/`:
- Key decisions made
- Rationale for organization choices

### Task 8.4: Update Current Priorities

Move this task to "Recently Completed" in current-priorities.md.

**Exit Criteria**:
- [ ] Session state updated
- [ ] Organization pattern created
- [ ] Lessons documented
- [ ] Priorities updated

---

## Summary Checklist

### Directories to CREATE
- [ ] `projects/project-aion/designs/current/`
- [ ] `projects/project-aion/designs/archive/`
- [ ] `projects/project-aion/progress/current/sessions/`
- [ ] `projects/project-aion/progress/current/milestones/`
- [ ] `projects/project-aion/progress/archive/`
- [ ] `projects/project-aion/evolution/aifred-integration/sync-reports/`
- [ ] `projects/project-aion/evolution/self-improvement/`
- [ ] `projects/project-aion/analysis/`
- [ ] `projects/project-aion/external/`
- [ ] `projects/project-aion/ideas/current/`
- [ ] `projects/project-aion/ideas/archive/`
- [ ] `projects/project-aion/plans/current/`
- [ ] `projects/project-aion/plans/archive/`
- [ ] `projects/project-aion/reports/current/`
- [ ] `projects/project-aion/reports/archive/`
- [ ] `projects/project-aion/experiments/current/`
- [ ] `projects/project-aion/experiments/archive/`
- [ ] `.claude/context/plans/`

### Files to MOVE
- [ ] `.claude/context/upstream/*` → `projects/project-aion/evolution/aifred-integration/`
- [ ] `.claude/context/analysis/*` → `projects/project-aion/analysis/`
- [ ] `.claude/persona/jarvis-identity.md` → `.claude/jarvis-identity.md`
- [ ] `.claude/context/projects/current-priorities.md` → `.claude/context/current-priorities.md`
- [ ] `.claude/evolution/evolution-queue.yaml` → `.claude/state/queues/`
- [ ] `.claude/plans/humming-purring-adleman.md` → `projects/project-aion/plans/archive/`
- [ ] `projects/project-aion/ideas/phase-6-autonomy-design.md` → `designs/current/`
- [ ] `.claude/orchestration/demo-a-orchestration.yaml` → Project Aion
- [ ] `.claude/orchestration/phase-6-implementation.yaml` → Project Aion
- [ ] `.claude/orchestration/2026-01-20-autonomous-command-wrappers.yaml` → Project Aion

### Directories to REMOVE
- [ ] `.claude/context/upstream/`
- [ ] `.claude/context/analysis/`
- [ ] `.claude/context/projects/`
- [ ] `.claude/context/templates/`
- [ ] `.claude/persona/`
- [ ] `.claude/evolution/`
- [ ] `.claude/plans/`

### Files to CREATE
- [ ] `.claude/planning-tracker.yaml`
- [ ] `.claude/context/patterns/organization-pattern.md`

### Files to UPDATE
- [ ] `.claude/CLAUDE.md` — Pattern selection matrix
- [ ] `.claude/context/patterns/_index.md` — Categorized index
- [ ] `.claude/context/_index.md` — Map of the Mind
- [ ] `.claude/context/workflows/session-exit.md` — Checklist hygiene step
- [ ] `.claude/context/session-state.md` — Completion status
- [ ] `.claude/context/current-priorities.md` — Task completion

---

## Risk Mitigation

### Broken References
- Run grep searches before and after moves
- Update @ references in markdown files
- Test CLAUDE.md loads correctly

### Git History
- Use `git mv` for tracked files to preserve history
- Single commit for related changes

### Rollback Plan
- If issues found, revert commit
- Findings document preserved for re-implementation

---

*Implementation Plan — Jarvis Organization Architecture 2026-01-22*
