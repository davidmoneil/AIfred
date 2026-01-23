# Learning: Any Document with Checkboxes is a Tracking Document

**Date**: 2026-01-23
**Category**: patterns
**Tags**: #planning #tracking #documentation #enforcement
**Confidence**: high

## Context

During M3 completion, two documents were not updated despite having active checkboxes:
1. `.claude/plans/proud-noodling-lovelace.md` - Session plan file without completion status
2. `recommendations.md` - Marked "SUPERSEDED" but still had active implementation roadmap checkboxes

The planning-tracker.yaml only tracked "obvious" planning documents, missing:
- Ephemeral session plans in `.claude/plans/`
- Superseded documents that still have tracking checkboxes

## Insight

**Pattern**: If a document contains `- [ ]` unchecked checkboxes, it is a tracking document — regardless of:
- Its stated status ("SUPERSEDED", "DRAFT", etc.)
- Its location (ephemeral plans, archive, etc.)
- Its primary purpose (recommendations, analysis, etc.)

**Implication**: The planning-tracker.yaml should track:
1. All documents with checklists, not just "planning" docs
2. Session plans that should show completion status
3. Legacy/superseded docs that still have active checklists

## Application

1. **Scan for checkboxes**: Use `grep -l '\- \[ \]'` to find untracked tracking docs
2. **Update tracker**: Add new categories to planning-tracker.yaml:
   - `session_plans`: `.claude/plans/*.md`
   - `legacy_with_checklists`: Any superseded doc with active checkboxes
3. **Mark completion**: Session plans should include status line (✅ COMPLETE / 🔄 IN PROGRESS)
4. **Archive properly**: Move completed plans to archive with all checkboxes marked

## Related

- `.claude/planning-tracker.yaml` v2.1.0
- Milestone Documentation Enforcement System (2026-01-23)

---

*Captured via /capture learning*
