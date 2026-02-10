# Current Priorities

Active tasks and priorities for Project Aion (Jarvis Archon).

**Last Updated**: 2026-02-09
**Version**: v5.9.0

---

## Recently Completed (This Session)

### Stream 1: research-ops v2.1.0 — Native MCP Capability Reconstruction (2026-02-09)

**8 scripts created** in `.claude/skills/research-ops/scripts/`:
- `_common.sh` — shared utilities (credential extraction, HTTP helpers, error handling)
- `search-brave.sh` — Brave Search API (web/news/video/image, freshness filters)
- `search-arxiv.sh` — arXiv paper search (category/author/sort, xmllint parsing)
- `fetch-wikipedia.sh` — Wikipedia REST API (multi-lang, summary/full/search modes)
- `search-perplexity.sh` — Perplexity AI (4 sonar models, dynamic timeout, citations)
- `fetch-context7.sh` — Context7 workflow doc (PARTIAL, requires local-rag MCP)
- `deep-research-gpt.sh` — GPTResearcher workflow doc (BLOCKED, API key TBD)
- `test-all.sh` — validation suite (12/12 pass with real API calls)

**Results**: ~3,100 token savings/session (91% reduction), zero startup overhead, parallel execution enabled.
**Deep analysis**: Capability regressions limited to power-user features (Brave local search, arXiv PDF download, Wikipedia coordinates/fact extraction).

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

### Master Wiggum Loop Iteration 3 — 4 Tasks (2026-02-08)
**Commit**: 1e34159

- current-priorities.md rewritten for v5.9.0
- Pattern count 39→48 in 3 files
- capability-matrix.md → capability-map.yaml stale references fixed
- Psyche topology counts corrected (skills 11→22, hooks 14→28, agents 14→12)

### Master Wiggum Loop Iteration 4 — 3 Tasks (2026-02-08)
**Commit**: eb29b7b

- Capability-map.yaml verification: 21/22 skills, 12/12 agents — all consistent
- Session state updated through Iteration 4

### Master Wiggum Loop Iteration 5 (final) — 2 Tasks (2026-02-08)
**Commit**: 9f24a4e

- CLAUDE.md root-of-trust: pattern count 41→48, capability-matrix→capability-map.yaml

### Post-Loop Polish (2026-02-08)
**Commits**: 9eaf2ad, a14ed12, 6ed47ea

- Stray context-snapshot.md moved to context-management/references/
- Session reflection report (AC-05)
- MEMORY.md + restructuring-lessons.md
- All 3 topology maps (nous, pneuma, soma) aligned with v5.9.0

### X-ops Skill Consolidation (2026-02-08)
**Commit**: c618123

- 4 Swiss-Army-Knife router skills: doc-ops, self-ops, mcp-ops, autonom-ops
- capability-map.yaml: 21→10 discoverable skills
- 26 total skill dirs (10 discoverable + 15 absorbed subordinates + 1 example)

---

## Stream 0 Completed Work (2026-02-09)

All 3 Wiggum Loops + code reviews complete. Bulk replacement re-executed successfully.

- C1-C5 critical fixes (capability-map.yaml, plugin-decompose, mcp-validation)
- Count harmonization: patterns 51, skills 28, commands 40, hooks 28, agents 13
- Index updates: skills/_index.md (+6 entries), knowledge-ops pattern count
- README updates: commands/README.md, hooks/README.md
- Bulk replacement: capability-matrix.md → capability-map.yaml in 19 operational files (26 substitutions)
- Glossary: "Capability Matrix" → "Capability Map", path corrected
- Deprecation header added to capability-matrix-update-workflow.md
- Code reviews: 3 loops, all findings addressed
- **Status**: COMPLETE — needs commit + push

---

## Up Next

### Tool Reconstruction Backlog
**Status**: 43 items, major progress across all tiers
- P1: 6/8 DONE (remaining: GPTResearcher + Chroma/db-ops — both blocked)
- P2: 7 high-value MCPs (Serena DEFERRED — stability issues)
- P3: **5/5 RESEARCHED** (omc patterns + supabase-agent-skills completed, 6 patterns identified)
- P4: 4/6 x-ops consolidations DONE (self-ops, doc-ops, mcp-ops, autonom-ops)
- P5: 5 future (infrastructure needed)
- **Hook optimization**: Matchers added, ~70% fewer processes per tool call
- Backlog: `.claude/context/reference/tool-reconstruction-backlog.md`

### Phase 6 / Roadmap II Phase A — COMPLETE (2026-02-09)
**Status**: All PR-12 sub-PRs COMPLETE, PR-13 COMPLETE, PR-14 COMPLETE
**Commit**: 5b38374 (32 files, +3874/-78)
- PR-12.1-12.10: ALL COMPLETE — all 9 Hippocrenae ACs active
- PR-13: Monitoring — telemetry-dashboard.sh + benchmark-suite.yaml (10 benchmarks)
- PR-14: SOTA Catalog — 55 entries, 9 categories
- **Residual**: AC-06/07 scaffolded (specs+scripts, not execution-wired), failure_modes_tested=false on 06/07/08
- **Verified**: 5-agent parallel audit confirmed all deliverables
- **Roadmap II**: `.claude/plans/roadmap-ii.md` — Phase A section updated with carry-forward table

### Roadmap II Phase B — Stream 2 Implementation (~15-20 hrs)
- B.1: claude-code-docs install — **DONE** (CannonCoPilot fork, Jarvis-integrated, /docs command, session-start sync)
- B.2: Deep Research Pattern Decomposition — **DONE** (research-plan.sh + research-synthesize.sh, v2.2.0)
- B.3: Hook Consolidation — **DONE** (34→23 hooks, commit c75f201)
- B.4: Context Engineering JICM Integration — **DONE** (watcher v5.8.3 + Phases 1-4: anchored summarization, file-system-as-memory, observation masking, poisoning detection)
- B.5: Skill-Level Model Routing — **DONE** (26 SKILL.md + 23 capability-map entries, all validated)
- B.6: Automatic Skill Learning — **DONE** (reflect Phase 2.5, evolve Step 2.5, 2 YAML files)
- B.7: AC-10 Ulfhedthnar — NOT STARTED (~6-8 hrs)
- **Status**: 6/7 COMPLETE (B.1-B.6 all done), B.7 remaining
- **Next**: B.7 AC-10 Ulfhedthnar (~6-8 hrs)
- **Plan**: `.claude/plans/roadmap-ii.md` Phase B section

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
