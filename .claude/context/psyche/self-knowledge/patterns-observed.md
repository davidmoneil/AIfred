# Self-Knowledge: Patterns Observed

**Purpose**: Recurring behavioral patterns across sessions — both productive and counterproductive.
**Updated**: 2026-02-08

---

## Productive Patterns

### Audit-Then-Fix Cycle
When given a cleanup task, naturally produces a comprehensive audit first, then applies targeted fixes. This prevents partial fixes and ensures nothing is missed.
- *Example*: Pattern cross-reference audit → 48 patterns categorized → 6 orphaned fixed → 3 mandatory gaps in capability-map.yaml discovered and filled.

### Swiss-Army-Knife Consolidation
Gravitates toward consolidating many small tools into unified "x-ops" skills. Reduces cognitive overhead and context budget. Consistently produces lean, table-driven reference docs.
- *Example*: 6 research MCPs → research-ops v2.0 (14 backends, 67 lines). 2 memory MCPs → knowledge-ops v2.0 (4 tiers, 102 lines).

### Progressive Disclosure in Practice
Naturally structures information in 3 layers: summary (metadata) → working doc (SKILL.md) → deep reference (references/). This aligns with the skill architecture's design intent.

### Commit-at-Milestone Discipline
Groups related changes into logical commits at milestone boundaries rather than committing after every file change. Produces clean git history with meaningful messages.

### Background Agent Delegation
Effectively identifies audit/research tasks suitable for background agents, keeping the main context free for implementation work.

## Counterproductive Patterns

### Scope Creep via "While I'm Here"
When fixing one issue in a file, tendency to notice and fix adjacent issues — leading to larger diffs than planned. Each fix is individually correct but collectively increases review burden.
- *Mitigation*: Stick to the task scope. Note adjacent issues in backlog rather than fixing inline.

### Aspirational Documentation
Creates forward-looking sections ("Future Integrations", "Planned") that become stale. These sections promise capabilities not yet delivered.
- *Mitigation*: Mark aspirational content with explicit status tags. Prefer backlog items over in-doc promises.

### Symmetric Completion Bias
When creating a set of N items, strong drive to complete all N even when diminishing returns set in. Will spend equal effort on item 14 as item 1.
- *Mitigation*: Apply Pareto: do the high-value 80% first, defer the long tail.

### Verbose Commit Messages
Commit messages sometimes exceed useful length, listing every file changed. A concise summary of the *why* is more valuable than a manifest of *what*.

---

## Session-Specific Observations (2026-02-08)

- Multi-context-window sessions work well when state is committed between windows
- 14 tasks in one iteration is achievable but leaves no margin — 10 is safer
- Orphaned patterns accumulate faster than expected after architectural changes
- Agent format divergence happens naturally — periodic unification needed
- The Decomposition-First paradigm produced clean results: 13 MCPs removed, 4 skills created, no regressions

---

*Self-Knowledge: Patterns Observed — v1.0.0*
