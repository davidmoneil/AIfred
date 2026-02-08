# Current Priorities

Active tasks and priorities for Project Aion (Jarvis Archon).

**Last Updated**: 2026-02-08
**Version**: v5.9.0

---

## In Progress

### Master Wiggum Loop — Iterations 3-5 (2026-02-08)
**Status**: IN PROGRESS — Iteration 3 active
**Branch**: Project_Aion
**Commits**: c2a8159 (Iteration 2), 4ac6cc5 (Iteration 1)

Verification, tightening, and polish iterations:
- [ ] IT3: Update current-priorities.md (this file)
- [ ] IT3: Fix inconsistencies from verification agents
- [ ] IT3: Tighten psyche topology counts
- [ ] IT3: Commit Iteration 3
- [ ] IT4-5: Further refinement passes

---

## Recently Completed (This Session)

### Lean Core v5.9.0 + MCP Decomposition (2026-02-07/08)

**MCP Decomposition** (13 removed, 5 retained):
- Retained: memory, local-rag, fetch, git, playwright
- 4 replacement skills: filesystem-ops, git-ops, web-fetch, weather
- 14/14 functional tests passed, registry v5.0
- 9,750 tokens saved from tool definitions

**Lean Core Architecture**:
- Manifest router: capability-map.yaml (single authoritative selection guide)
- Pipeline design v4.0 (Decomposition-First paradigm)
- Marketplace research (45 marketplaces, 400+ skills inventoried)

### Master Wiggum Loop Iteration 1 — 14 Tasks (2026-02-08)
**Commit**: 4ac6cc5

| Task | Deliverable |
|------|-------------|
| Registry v5.0 | Complete rewrite, x-ops architecture |
| research-ops v2.0 | 14 backends (+Tavily, Serper, SerpAPI, Firecrawl, ScraperAPI, Perplexity) |
| context-management v4.0 | JICM v5.8.2 aligned (65/73/78.5% thresholds) |
| knowledge-ops v2.0 | 4-tier memory hierarchy |
| Marketplace inventory | 45 marketplaces, 10 functional groups |
| x-ops consolidation design | 22→12 skills (swiss-army-knife pattern) |
| Skill descriptions CSV | 22 skills cataloged, Progressive Disclosure |
| Psyche maps v2 | capability-map.yaml updated, _index.md aligned |
| Self-constitution review | v1.1.0-draft, thresholds/memory annotated |
| Pattern cross-reference | 48 patterns audited, 5 added to manifest |
| Agent refactoring | 12 agents, unified frontmatter, README updated |
| Workflow/Integrations | 3 deprecation notices, READMEs updated |
| Tool-reconstruction backlog | 43 prioritized items across 5 tiers |
| SOTA/auto-MCP research | Cannot unload auto-provisioned MCPs |

### Master Wiggum Loop Iteration 2 — 5 Tasks (2026-02-08)
**Commit**: c2a8159

| Task | Deliverable |
|------|-------------|
| Session state update | Full milestone history |
| Orphaned patterns | 6 patterns cross-referenced |
| Self-knowledge files | strengths, weaknesses, patterns-observed |
| Memory KG storage | 6 entities, 6 relations |
| Quality review | 3 key skills verified (research-ops, knowledge-ops, context-management) |

---

## Up Next

### x-ops Skill Consolidation
**Status**: Designed — awaiting implementation

Consolidate 22 skills → 12 unified x-ops skills:
- Planned: self-ops, doc-ops, mcp-ops, autonom-ops, db-ops, web-ops
- Future: code-ops, flow-ops, data-sci-ops
- Design: `.claude/context/reference/mcp-decomposition-registry.md`

### Tool Reconstruction Backlog
**Status**: 43 items prioritized across 5 tiers
- P1: 8 in-progress reconstructions (complete current x-ops)
- P2: 7 high-value MCPs to install
- P3: 5 marketplace extractions
- P4: 6 x-ops consolidations
- P5: 5 future (infrastructure needed)
- Backlog: `.claude/context/reference/tool-reconstruction-backlog.md`

### Phase 6: Autonomy, Self-Evolution & Benchmark Gates
**Status**: Design Complete — Ready for Implementation
**Design**: `projects/project-aion/designs/current/phase-6-autonomy-design.md`

---

## Backlog

See `projects/project-aion/roadmap.md` for full roadmap.

### Deferred Items
- AC-02/AC-03 remediation workflow integration
- Hippocrenae documentation (from Autopoietic Paradigm v2.0.0)
- Auto-restart after rate-limit pattern
- Self-constitution directory restructuring (aspirational)

---

## Notes

**Branch**: All work on `Project_Aion` branch (origin/Project_Aion)
**Baseline**: `main` branch is read-only AIfred baseline at `2ea4e8b`
**MCPs**: 5 active (memory, local-rag, fetch, git, playwright)

---

*Project Aion — Jarvis Development Priorities*
