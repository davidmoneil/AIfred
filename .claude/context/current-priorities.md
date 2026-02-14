# Current Priorities

Active tasks and priorities for Project Aion (Jarvis Archon).

**Last Updated**: 2026-02-13
**Version**: v5.10.0

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
- **Residual**: AC-06/07 scaffolded (specs+scripts, not execution-wired) — failure_modes_tested now true via B.4 degradation benchmarks
- **Verified**: 5-agent parallel audit confirmed all deliverables
- **Roadmap II**: `.claude/plans/roadmap-ii.md` — Phase A section updated with carry-forward table

### Roadmap II Phase B — COMPLETE (7/7)
- B.1: claude-code-docs install — **DONE**
- B.2: Deep Research Pattern Decomposition — **DONE**
- B.3: Hook Consolidation — **DONE**
- B.4: Context Engineering JICM Integration — **DONE**
- B.5: Skill-Level Model Routing — **DONE**
- B.6: Automatic Skill Learning — **DONE**
- B.7: AC-10 Ulfhedthnar — **DONE**

### Roadmap II Phase F — Aion Quartet — COMPLETE
- F.0: AC-03 hotfix + VERSION 5.10.0 + roadmap rewrite — **DONE** (96ee40b)
- F.1: Ennoia MVP (session orchestrator) — **DONE** (02b4272, 14/14 tests, v0.2)
- F.2: Virgil MVP (codebase guide dashboard) — **DONE** (cf5cb0d, all tests pass, v0.2)
- F.3: Remaining Aion Quartet wiring — **DONE** (housekeep.sh, valedictions, cap-map, orchestration docs)
- **Status**: COMPLETE (4/4)

### JICM v6.1 Enhancement (2026-02-10/11) — COMPLETE
- 20 Wiggum Loop TDD cycles, 196 tests passing
- E1: ESC-triggered idle detection (replaces spinner polling)
- E2: Token extraction range validation
- E3: v6.1 compression agent prompt
- E4: Session-start/restart differentiation
- E5: Cycle metrics + telemetry (JSONL)
- E6: v5 watcher removal — 164 lines from session-start, 6 consumers migrated to .jicm-state
- E7: /compact hook cleanup
- E8: Session-state de-prioritization
- **Report**: `.claude/context/designs/jicm-v6.1-implementation-report.md`
- **Deferred**: jarvis-watcher.sh file deletion (still used for command signals)
- **Needs**: Commit + push

### Compression Timing Experiment 1 (2026-02-13) — COMPLETE
- 5-loop Wiggum experiment: /compact vs JICM compression timing
- 6 matched pairs (12 trials), 5 with both treatments successful
- **Result**: JICM 2.3x slower (median 313.5s vs 140s, p=0.03125, r=0.833)
- JICM compression agent = 73% of total time (optimization target)
- JICM 100% reliable vs /compact 83%
- **Report**: `.claude/reports/testing/compression-experiment-report.md`
- **Data**: `.claude/reports/testing/compression-timing-data.jsonl`

### Compression Timing Experiment 2 — Context Volume Regression (2026-02-13) — COMPLETE
- 2×2 factorial design: treatment (compact/JICM) × context level (45%/75%)
- 19 trials (4 pilot + 15 experiment), 4 blocks, early stopping invoked
- **Result 1**: Context volume has NO effect on compression time (F=1.31, p=0.277)
- **Result 2**: JICM 3.9x slower than /compact (F=122.22, p<0.001, η²=0.917 massive effect)
- **Result 3**: JICM 100% failure at ≥74% context (0/4 success) — **root cause confirmed**: emergency /compact handler (73%) preempts JICM cycle in watcher main loop; JICM ceiling is 72%
- 5 bugs found+fixed (B7-B11): cascading failure, macOS head, ceiling abort, plateau detection, /clear hardening
- **Report**: `.claude/reports/testing/compression-regression-report.md`
- **Data**: `.claude/reports/testing/compression-regression-data.jsonl`
- **Actions taken**: JICM threshold lowered to 55% (17-point margin below 72% ceiling), 72% ceiling documented in AC-04 spec

### Compression Timing Experiment 3 — Context Volume Revised (2026-02-13/14) — COMPLETE
- 2×2 factorial: treatment (compact/JICM) × context level (40% vs 70%), revised from Exp 2
- 24 trials attempted, 18 successful (6 failed due to tmux pane staleness)
- **Result 1**: Context volume has NO effect on compression time (F=2.33, p=0.149) — replicates Exp 2
- **Result 2**: /compact 3.8x faster than JICM (F=197.1, p<0.001, η²=0.934) — replicates Exps 1+2
- **Result 3**: JICM-high 4/4 SUCCESS at 67-72% context — first ever above 70%, validates 72% ceiling
- **Result 4**: JICM negative trend — faster at higher context (Spearman rho=-0.706, p=0.034)
- **Result 5**: Compression ratios scale with volume (JICM-high 3.8:1, /compact-high 2.4:1)
- **Report**: `.claude/reports/testing/experiment-3-report.md`
- **Data**: `.claude/reports/testing/compression-exp3-data.jsonl`
- **Protocol**: `.claude/reports/testing/experiment-3-protocol.md`
- **Recommendations**: Keep threshold at 55%, no volume optimization needed, consider Haiku for compress agent, investigate negative JICM trend

### Next: Phase C — Mac Studio Infrastructure (Wed Feb 12+)
- Docker container deployment
- Multi-agent orchestration infrastructure
- Blocked until Mac Studio arrives

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
