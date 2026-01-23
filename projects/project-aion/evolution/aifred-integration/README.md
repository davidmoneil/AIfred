# AIfred Integration

**Purpose**: All work related to syncing with and porting from the AIfred baseline.

**Baseline**: AIfred by David O'Neil (read-only upstream reference)

---

## Contents

| File | Purpose |
|------|---------|
| `chronicle.md` | Master progress document — captures reasoning and approach |
| `roadmap.md` | Integration milestones, sessions, exit criteria |
| `recommendations.md` | Analysis and integration recommendations |
| `port-log.md` | Record of adopt/adapt/reject decisions |
| `sync-reports/` | Historical sync analysis documents |

## Key Principles

1. **AIfred baseline is read-only** — Never edit the baseline repo
2. **Port, don't copy** — Adapt for Jarvis context
3. **Document reasoning** — Chronicle captures "why", not just "what"
4. **Track decisions** — port-log.md records every adopt/adapt/reject

## Workflow

1. Run `/sync-aifred-baseline` to analyze upstream changes
2. Review recommendations
3. Port approved changes with adaptations
4. Update chronicle with session work
5. Update roadmap checkboxes

---

*Project Aion — Jarvis Development*
