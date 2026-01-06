# Brainstorm: Project Structure Clarity (Evolution vs Behavior)

*Created: 2026-01-05*
*Status: Brainstorm / Architecture Review*
*Triggered by: User observation of overlapping project-related directories*

---

## Problem Statement

Jarvis has multiple directories that could plausibly store project plans, PRs, ideations, and documentation. This creates confusion about **where things belong**.

More fundamentally, there's a conceptual tension:

| Concern | What It Is | Current Location |
|---------|-----------|------------------|
| **EVOLUTION** | How Jarvis improves itself (Project Aion roadmap, PRs, plans) | `projects/`, `docs/project-aion/` |
| **BEHAVIOR** | How Jarvis operates (patterns, standards, knowledge base) | `.claude/context/`, `.claude/commands/` |

These two concerns currently **share space and naming conventions**, making it unclear where new documentation should go.

---

## Current Directory Inventory

### Candidate Directories for Project/Planning Content

| Directory | Current Purpose | Current Contents |
|-----------|----------------|------------------|
| `docs/project-aion/` | Project Aion docs | archon-identity.md, versioning-policy.md, one-shot-prd.md, pr2-validation.md |
| `docs/project-aion/plans/` | PR implementation plans | pr-4-implementation-plan.md |
| `docs/archive/` | Archived docs | PROJECT-PLAN.md (obsolete) |
| `projects/` | Project summaries (per workspace-path-policy) | **Project_Aion.md** (the roadmap!) |
| `.claude/context/projects/` | Project context for Claude | current-priorities.md |
| `.claude/context/ideas/` | Brainstorms | New — idea docs |
| `knowledge/docs/` | Knowledge base docs | Empty placeholder |
| `knowledge/notes/` | Knowledge notes | Empty placeholder |
| `knowledge/templates/` | Templates | project-summary.md, project-context.md |

### The Confusion

1. **`projects/Project_Aion.md`** contains the full roadmap (38KB) — but `projects/` was intended for *external* project summaries, not Jarvis's own evolution.

2. **`.claude/context/projects/`** has `current-priorities.md` — but this is about Jarvis's evolution, which arguably belongs with Project Aion docs.

3. **`docs/project-aion/plans/`** has PR implementation plans — but PRs are part of evolution, so should this be under `projects/`?

4. **`knowledge/`** directories are largely empty and unused.

---

## Conceptual Framework: Two Distinct Domains

### Domain 1: EVOLUTION (Project Aion)

**What it covers:**
- Jarvis development roadmap
- PR definitions and implementation plans
- Version milestones
- Validation documents
- Phase gate reports
- Design decisions for Jarvis itself

**Characteristics:**
- Changes over time as Jarvis improves
- Tracks progress, history, decisions
- May be of interest to external observers
- Could eventually be a separate repo

### Domain 2: BEHAVIOR (Jarvis Runtime)

**What it covers:**
- How Jarvis responds to requests
- Patterns for common tasks
- Standards for classification, severity, etc.
- Knowledge about infrastructure
- Session management
- Tool selection rules

**Characteristics:**
- Relatively stable (patterns don't change often)
- Referenced during operation
- Internal to Jarvis (not for external visibility)
- Lives in `.claude/` namespace

---

## Proposed Clarification

### Option A: Consolidate Evolution Under `docs/project-aion/`

Move all evolution-related content to `docs/project-aion/`:

```
docs/project-aion/
├── archon-identity.md          # Identity docs
├── versioning-policy.md        # Versioning rules
├── one-shot-prd.md             # Benchmark spec
├── roadmap.md                  # MOVE FROM projects/Project_Aion.md
├── plans/
│   └── pr-4-implementation-plan.md
├── validation/
│   ├── pr2-validation.md       # MOVE from current location
│   ├── phase-1-4-gate.md       # Future
│   └── validation-log.md       # Future
└── archive/
    └── (old plans, superseded docs)
```

**Changes:**
- Move `projects/Project_Aion.md` → `docs/project-aion/roadmap.md`
- Move `pr2-validation.md` → `docs/project-aion/validation/`
- `projects/` becomes *only* for external project summaries

### Option B: Create Dedicated `evolution/` Directory

Keep evolution entirely separate:

```
evolution/                      # NEW top-level directory
├── roadmap.md                  # The master plan
├── current.md                  # Current priorities (MOVE from .claude/context/projects/)
├── plans/
│   └── pr-4-plan.md
├── validation/
│   └── ...
└── ideas/                      # MOVE from .claude/context/ideas/
    └── ...
```

**Advantage:** Crystal clear separation
**Disadvantage:** Yet another top-level directory

### Option C: Keep Status Quo, Document Conventions

Don't move files, just document clearly:

```markdown
## Directory Conventions

| Purpose | Location |
|---------|----------|
| Jarvis roadmap | `projects/Project_Aion.md` |
| PR plans | `docs/project-aion/plans/` |
| Active priorities | `.claude/context/projects/current-priorities.md` |
| Ideas/brainstorms | `.claude/context/ideas/` |
| Behavior patterns | `.claude/context/patterns/` |
```

**Advantage:** No file moves needed
**Disadvantage:** Confusion persists

---

## Recommendation: Option A (Consolidate to `docs/project-aion/`)

### Rationale

1. **`docs/project-aion/` already exists** with the right name
2. **`projects/` should be for external projects** per workspace-path-policy
3. **Validation docs belong with the roadmap** they validate
4. **Plans belong with the roadmap** they implement
5. **Consolidation reduces cognitive load**

### Proposed Migration

1. **Move roadmap**: `projects/Project_Aion.md` → `docs/project-aion/roadmap.md`
2. **Reorganize validation**: `pr2-validation.md` → `docs/project-aion/validation/pr2-validation.md`
3. **Keep ideas in `.claude/context/`**: Ideas are about both evolution AND behavior — they're a working space, not final docs
4. **Update references**: Update any `@` references in CLAUDE.md and other files

### What Stays in `.claude/context/`

| Directory | Purpose | Stays? |
|-----------|---------|--------|
| `patterns/` | Behavioral patterns | Yes — runtime behavior |
| `standards/` | Classification standards | Yes — runtime behavior |
| `projects/` | Rename to `priorities/`? | Debatable |
| `ideas/` | Working brainstorms | Yes — temporary space |
| `upstream/` | AIfred sync tracking | Yes — operational |
| `workflows/` | Operational procedures | Yes — runtime behavior |

### The `current-priorities.md` Question

Currently at `.claude/context/projects/current-priorities.md`.

Options:
- **Keep as-is**: It's about "what to work on" which is operational
- **Move to `docs/project-aion/current.md`**: It's about evolution priorities
- **Rename directory**: `.claude/context/priorities/` instead of `projects/`

**My recommendation**: Rename to `.claude/context/priorities/` for clarity. The word "projects" suggests external projects; "priorities" is unambiguous.

---

## Related: The `knowledge/` Directory

The `knowledge/` directory is largely unused:

```
knowledge/
├── docs/      # Empty
├── notes/     # Empty
├── templates/ # Has templates
```

**Options:**
1. **Use it**: Move some content there
2. **Remove it**: Delete empty directories
3. **Repurpose it**: Make it the evolution home

**Recommendation:** Leave templates, delete empty docs/notes, or repurpose for learned knowledge (future ML/RAG content).

---

## Delineation Summary

### After Proposed Changes

```
EVOLUTION (Project Aion)                  BEHAVIOR (Jarvis Runtime)
────────────────────────                  ─────────────────────────
docs/project-aion/                        .claude/
├── roadmap.md (master plan)              ├── CLAUDE.md (config)
├── archon-identity.md                    ├── commands/ (skills)
├── versioning-policy.md                  ├── agents/
├── one-shot-prd.md                       ├── hooks/
├── plans/                                ├── context/
│   └── pr-{N}-plan.md                    │   ├── patterns/
├── validation/                           │   ├── standards/
│   ├── pr{N}-validation.md               │   ├── priorities/ (was projects/)
│   └── phase-{N}-gate.md                 │   ├── ideas/ (working space)
└── archive/                              │   ├── upstream/
                                          │   └── workflows/
                                          └── config/
```

---

## Questions for User

1. **Should we migrate `projects/Project_Aion.md` to `docs/project-aion/roadmap.md`?**
   - Yes: Cleaner separation
   - No: Too much churn for marginal benefit

2. **Should we rename `.claude/context/projects/` to `.claude/context/priorities/`?**
   - Yes: Clearer intent
   - No: Keep as-is

3. **What should happen to `knowledge/docs/` and `knowledge/notes/`?**
   - Delete: Remove empty dirs
   - Keep: Future use for learned knowledge
   - Repurpose: Something else?

4. **Should ideas eventually "graduate" to `docs/project-aion/` when formalized?**
   - Yes: Clear lifecycle (idea → plan → implementation → validation)
   - No: Keep ideas separate always

---

## Action Items (If Approved)

- [ ] Move `projects/Project_Aion.md` → `docs/project-aion/roadmap.md`
- [ ] Create `docs/project-aion/validation/` directory
- [ ] Move `pr2-validation.md` to validation directory
- [ ] Rename `.claude/context/projects/` → `.claude/context/priorities/`
- [ ] Update all `@` references
- [ ] Document conventions in CLAUDE.md
- [ ] Clean up or repurpose `knowledge/` directories

---

*Brainstorm: Project Structure Clarity — Evolution vs Behavior Delineation*
