# Archon Maintenance Workflow

A systematic workflow for maintaining Jarvis's organizational health, performing large-scale integrations, and correcting Neuro drift and layer boundary degradation.

**Version**: 1.0.0
**Created**: 2026-01-22
**Derived From**: AIfred Integration & Organization Architecture experience

---

## Purpose

This workflow serves two primary use cases:

1. **Large Integration Efforts**: When porting significant functionality from external sources (like AIfred), this workflow ensures the receiving structure is ready and the integration is traceable.

2. **Routine Maintenance**: Periodic review to correct organizational drift, clean Neuro pathways (cross-references), and maintain layer boundary integrity.

---

## When to Use This Workflow

### Trigger Conditions

| Condition | Action |
|-----------|--------|
| Starting integration of 5+ components | Full workflow |
| Noticed files in wrong layer | Focused maintenance (Phase 1-2) |
| Cross-references breaking | Neuro repair (Phase 3) |
| README files outdated | Documentation refresh (Phase 4) |
| Quarterly maintenance | Full workflow (light touch) |
| Before major version bump | Full workflow |

### Symptoms of Neuro Drift

- Files placed in wrong layer (project work in Nous, identity files in Soma)
- `@` references pointing to moved/deleted files
- README files with outdated "What Belongs Here" sections
- Orphaned files (no references to/from them)
- Duplicated information across layers
- Unclear where new content should go

---

## Workflow Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                    ARCHON MAINTENANCE WORKFLOW                       │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  Phase 1: Assessment (1-2 hours)                                    │
│  └─► Analyze current state, identify problems                        │
│                          │                                           │
│                          ▼                                           │
│  Phase 2: Decision (30 min)                                         │
│  └─► Decide: quick fix, focused maintenance, or full restructure    │
│                          │                                           │
│                          ▼                                           │
│  Phase 3: Neuro Repair (1-4 hours)                                  │
│  └─► Fix cross-references, update paths, verify links               │
│                          │                                           │
│                          ▼                                           │
│  Phase 4: Layer Boundary Enforcement (1-3 hours)                    │
│  └─► Move misplaced files, update READMEs, clean boundaries         │
│                          │                                           │
│                          ▼                                           │
│  Phase 5: Documentation Refresh (1-2 hours)                         │
│  └─► Update indices, refresh topology maps, sync glossary           │
│                          │                                           │
│                          ▼                                           │
│  Phase 6: Integration (if applicable) (variable)                    │
│  └─► Port external components into prepared structure               │
│                          │                                           │
│                          ▼                                           │
│  Phase 7: Verification & Closure (1 hour)                           │
│  └─► Verify no breakage, commit, update session state               │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Phase 1: Assessment

**Objective**: Understand current organizational health before taking action.

**Duration**: 1-2 hours

### Step 1.1: Layer Boundary Audit

Check each layer for boundary violations:

```bash
# Files in Nous that might belong elsewhere
ls -la .claude/context/ | grep -v "^d"  # Top-level files (should be limited)

# Project work that crept into Nous
grep -r "project-aion" .claude/context/ --include="*.md" | head -20

# Identity files in wrong places
find .claude/ -name "*identity*" -o -name "*persona*"
```

**Expected Result**:
- Nous top-level: Only `_index.md`, `session-state.md`, `current-priorities.md`, `configuration-summary.md`
- No project-specific work in Nous (should be in Soma/projects/)
- Identity files only in Pneuma root

### Step 1.2: Neuro Integrity Check

Verify cross-references are valid:

```bash
# Find all @ references
grep -roh "@[a-zA-Z0-9_./-]*" .claude/ --include="*.md" | sort | uniq -c | sort -rn | head -30

# Check for broken references (files that don't exist)
# Manual verification of top references
```

**Signs of Neuro Degradation**:
- References to old paths (e.g., `context/upstream/` after moves)
- References to deleted files
- Circular or redundant references

### Step 1.3: README Freshness Check

Audit README files for accuracy:

```bash
# Find all READMEs
find .claude/ -name "README.md" | wc -l
find projects/ -name "README.md" | wc -l

# Check for outdated layer terminology
grep -r "Mind Layer\|Spirit Layer\|Body Layer" .claude/ projects/
```

**Expected**: All READMEs use Nous/Pneuma/Soma terminology

### Step 1.4: Create Findings Document

If issues found, create a findings document:

**Location**: `projects/project-aion/progress/YYYY-MM-DD-maintenance-findings.md`

**Template**:
```markdown
# Maintenance Findings — YYYY-MM-DD

**Session**: Archon Maintenance Review
**Status**: Assessment Complete

## Problems Identified

### Problem 1: [Name]
- **Location**: [where]
- **Severity**: [Critical/High/Medium/Low]
- **Description**: [what's wrong]
- **Recommended Fix**: [how to fix]

### Problem 2: ...

## Summary

| Severity | Count |
|----------|-------|
| Critical | X |
| High | X |
| Medium | X |
| Low | X |

## Recommendation

[ ] Quick fix (< 1 hour)
[ ] Focused maintenance (2-4 hours)
[ ] Full restructure (4+ hours)
```

---

## Phase 2: Decision

**Objective**: Determine the appropriate level of intervention.

**Duration**: 30 minutes

### Decision Matrix

| Findings | Action | Effort |
|----------|--------|--------|
| No critical issues, few mediums | Quick fix | < 1 hour |
| Multiple high issues, localized | Focused maintenance | 2-4 hours |
| Structural problems, widespread | Full restructure | 4+ hours |
| Pre-integration assessment | Full workflow | Variable |

### Decision Checklist

Before proceeding, answer:

1. **Is there an upcoming integration?** If yes, lean toward full maintenance first.
2. **Are layer boundaries mostly intact?** If yes, skip Phase 4.
3. **Are cross-references mostly valid?** If yes, skip Phase 3.
4. **Are READMEs mostly current?** If yes, skip Phase 5.

### Document Decision

Update findings document with decision and rationale.

---

## Phase 3: Neuro Repair

**Objective**: Fix the navigation substrate — cross-references, links, and pathways.

**Duration**: 1-4 hours (depending on scope)

### Step 3.1: Inventory All References

```bash
# Extract all file references
grep -roh "@\.claude[a-zA-Z0-9_./-]*" .claude/ --include="*.md" > /tmp/refs.txt
grep -roh "@projects[a-zA-Z0-9_./-]*" .claude/ --include="*.md" >> /tmp/refs.txt

# Sort and count
sort /tmp/refs.txt | uniq -c | sort -rn | head -50
```

### Step 3.2: Verify Each High-Frequency Reference

For top 20 references, verify the target exists:

```bash
# Example verification
ls -la .claude/context/patterns/wiggum-loop-pattern.md
```

### Step 3.3: Fix Broken References

For each broken reference:

1. Identify correct new path
2. Use grep to find all files containing the broken reference
3. Update each file with correct path
4. Verify fix

**Pattern**:
```bash
# Find files with broken reference
grep -r "old/path/file.md" .claude/ --include="*.md"

# Update each file (use Edit tool or sed)
```

### Step 3.4: Update Index Files

After reference fixes, update navigation indices:

- `.claude/context/_index.md`
- `.claude/context/patterns/_index.md`
- `.claude/context/psyche/_index.md`
- `.claude/CLAUDE.md` (essential links section)

### Step 3.5: Verify Neuro Integrity

```bash
# Re-run integrity check
grep -r "old/path" .claude/ --include="*.md"  # Should return empty
```

---

## Phase 4: Layer Boundary Enforcement

**Objective**: Ensure files are in the correct layer and boundaries are respected.

**Duration**: 1-3 hours

### Step 4.1: Review Archon Architecture

Reference the canonical layer definitions:

| Layer | Location | Contains |
|-------|----------|----------|
| **Nous** | `.claude/context/` | Knowledge, patterns, state, memory |
| **Pneuma** | `.claude/` | Capabilities, persona, tools, scripts |
| **Soma** | `/Jarvis/` | Infrastructure, interfaces, projects |

### Step 4.2: Identify Misplaced Files

Common violations:

| Violation | Example | Fix |
|-----------|---------|-----|
| Project work in Nous | `context/upstream/sync-report.md` | Move to `projects/project-aion/` |
| Identity in Soma | `jarvis-identity.md` in root | Move to `.claude/` |
| State in Nous | `context/evolution-queue.yaml` | Move to `.claude/state/queues/` |
| Centralized templates | `context/templates/` | Distribute to subdirectories |

### Step 4.3: Execute Moves

For each misplaced file:

1. Identify correct destination
2. Create destination directory if needed
3. Move file: `git mv old/path new/path`
4. Update all references (from Phase 3 pattern)
5. Update README in source directory (remove from "What Belongs Here")
6. Update README in destination (add to "What Belongs Here")

### Step 4.4: Enforce Top-Level Restrictions

**Nous top-level** should only contain:
- `_index.md`
- `session-state.md`
- `current-priorities.md`
- `configuration-summary.md`

**Pneuma top-level** should only contain:
- `CLAUDE.md` (primary identity, < 150 lines)
- `jarvis-identity.md`
- `settings.json`
- `planning-tracker.yaml`

Everything else goes in subdirectories.

### Step 4.5: Verify Layer Boundaries

```bash
# Check Nous top-level
ls .claude/context/*.md | wc -l  # Should be 3-4

# Check Pneuma top-level
ls .claude/*.md | wc -l  # Should be 2-3
ls .claude/*.yaml | wc -l  # Should be 1-2
```

---

## Phase 5: Documentation Refresh

**Objective**: Update documentation to reflect current state.

**Duration**: 1-2 hours

### Step 5.1: Update READMEs

For each directory with changes:

1. Read current README
2. Verify "What Belongs Here" is accurate
3. Verify "What Does NOT Belong Here" is accurate
4. Verify layer tag is correct (Nous/Pneuma/Soma)
5. Update footer timestamp

### Step 5.2: Refresh Topology Maps (Psyche)

Update:
- `.claude/context/psyche/_index.md` — Master topology
- `.claude/context/psyche/nous-map.md` — If Nous changed
- `.claude/context/psyche/pneuma-map.md` — If Pneuma changed
- `.claude/context/psyche/soma-map.md` — If Soma changed

### Step 5.3: Sync Glossary

Check if new terms need to be added to `.claude/context/reference/glossary.md`:
- New component names
- New pattern names
- New directory purposes

### Step 5.4: Update Pattern Index

If patterns were added, moved, or deprecated:

1. Update `.claude/context/patterns/_index.md`
2. Update pattern count
3. Verify all patterns listed exist

### Step 5.5: Update CLAUDE.md

If significant changes:

1. Check Essential Links table
2. Verify Archon Architecture section is current
3. Update version number if warranted
4. Update footer timestamp

---

## Phase 6: Integration (If Applicable)

**Objective**: Port external components into the prepared structure.

**Duration**: Variable (1-2 hours per milestone)

### Integration Protocol

For each component to integrate:

#### Step 6.1: Pre-Integration

1. Read source component
2. Identify required adaptations
3. Determine destination in Archon Architecture
4. Verify destination exists

#### Step 6.2: Port

1. Copy source to destination
2. Apply Jarvis-specific adaptations
3. Update any hardcoded paths
4. Add Jarvis exclusions if needed

#### Step 6.3: Configure

1. Register in appropriate config (settings.json, etc.)
2. Update any dependency references
3. Test basic functionality

#### Step 6.4: Document

1. Add entry to integration chronicle
2. Document adaptations and why
3. Note any technical debt created

#### Step 6.5: Commit

```bash
git add <files>
git commit -m "feat: Port <component> from <source> (M<milestone>-S<session>)"
```

### Chronicle Entry Template

```markdown
### Milestone X: [Name] — [Date]

**Status**: Complete

#### Deliverables
- [File 1]: [purpose]
- [File 2]: [purpose]

#### Methodology
[How it was approached]

#### Key Adaptations
- [Adaptation 1]: [why needed]

#### Learnings
- [Pattern discovered]

#### Watch Items
- [Technical debt or risks]
```

---

## Phase 7: Verification & Closure

**Objective**: Ensure no breakage and document completion.

**Duration**: 1 hour

### Step 7.1: Reference Verification

```bash
# Verify no broken references remain
grep -r "old/path\|FIXME\|TODO.*reference" .claude/ --include="*.md"
```

### Step 7.2: Tooling Health Check

```bash
# Run tooling health
/tooling-health
```

### Step 7.3: Planning Tracker Update

Update `.claude/planning-tracker.yaml`:
- Mark completed documents
- Update `last_updated` timestamps
- Add any new planning documents

### Step 7.4: Session State Update

Update `.claude/context/session-state.md`:
- Current work status
- Session summary with accomplishments
- Files modified/created
- Commit references

### Step 7.5: Final Commit

```bash
git add -A
git commit -m "$(cat <<'EOF'
maint: Archon maintenance workflow execution

- [Summary of changes]
- [Phases completed]
- [Key outcomes]

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
EOF
)"
```

### Step 7.6: Post-Maintenance Reflection

Consider:
- What caused the drift we fixed?
- Are there prevention mechanisms we could add?
- Should any findings become new patterns?

Document insights in `.claude/context/lessons/` if significant.

---

## Routine Maintenance Schedule

### Weekly (5 minutes)
- Quick scan of `session-state.md` for staleness
- Verify `current-priorities.md` reflects actual work

### Monthly (30 minutes)
- Phase 1 Assessment (light)
- Fix any obvious Neuro breaks
- Update planning tracker

### Quarterly (2-4 hours)
- Full Phase 1-5 workflow
- README freshness review
- Topology map verification
- Glossary sync

### Before Major Integration
- Full workflow (all phases)
- Create integration chronicle
- Establish milestone structure

---

## Checklists

### Quick Maintenance Checklist

- [ ] Run layer boundary audit
- [ ] Check for broken references
- [ ] Fix any critical issues
- [ ] Update session state
- [ ] Commit changes

### Full Maintenance Checklist

- [ ] Phase 1: Complete assessment, create findings
- [ ] Phase 2: Document decision and rationale
- [ ] Phase 3: Fix all broken references
- [ ] Phase 4: Move misplaced files, enforce boundaries
- [ ] Phase 5: Update READMEs, indices, glossary
- [ ] Phase 6: Complete integration (if applicable)
- [ ] Phase 7: Verify, commit, document

### Integration Milestone Checklist

- [ ] Source component analyzed
- [ ] Adaptations identified
- [ ] Destination prepared
- [ ] Component ported
- [ ] Configuration updated
- [ ] Tests passed
- [ ] Chronicle entry added
- [ ] Committed with milestone reference

---

## Appendix: Key Lessons from AIfred Integration

### Lesson 1: Organization Precedes Integration

> When undertaking integration work at scale, assess the receiving system's organizational readiness first. If structural issues exist, fix them BEFORE integrating.

**Why**: Integrating into chaos creates more chaos. Clean foundation enables clean integration.

### Lesson 2: Dual-Track Documentation

Maintain two documentation tracks:
- **Chronicle**: Why decisions were made (reasoning, learnings)
- **Progress**: What was accomplished (metrics, status)

**Why**: Code shows what; chronicle shows why.

### Lesson 3: Signal-Based Over State-Polling

For cross-layer communication, prefer explicit signals over detecting state absence.

**Why**: "Absence of activity" is hard to detect reliably; explicit signals are unambiguous.

### Lesson 4: Terminology Matters

Invest in precise vocabulary early (glossary). Greek terminology (Nous/Pneuma/Soma) provides clarity that English approximations lack.

**Why**: Clear names enable clear thinking and communication.

### Lesson 5: Session-Sized Milestones

Keep milestones to 1.5-2 hour sessions with clear exit criteria.

**Why**: Natural checkpoints, clean context, resumable work.

---

*Jarvis — Nous Layer (Workflows)*
