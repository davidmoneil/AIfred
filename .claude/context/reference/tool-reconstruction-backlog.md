# Tool Reconstruction Backlog

**Created**: 2026-02-08
**Version**: 1.0
**Sources**: `mcp-decomposition-registry.md` v5.0, `marketplace-evaluation-report.md` v1.0
**Paradigm**: Decomposition-First — reconstruct unique capabilities as native skills

---

## Backlog Overview

| Category | Items | Status |
|----------|-------|--------|
| MCP Reconstruction (in-progress) | 8 | 7/8 DONE (4 scripts + 1 partial + 2 prior) |
| New MCP → Skill (planned) | 19 | Planned (MCPs not yet installed) |
| Marketplace Extraction | 10 | 5/5 RESEARCHED (patterns identified) |
| x-ops Consolidation | 6 | 4/6 DONE (self-ops, doc-ops, mcp-ops, autonom-ops) |
| **Total actionable items** | **43** | |

---

## Priority 1: Complete In-Progress Reconstructions

These MCPs were removed but their unique capabilities need native skill integration.
Target skills already exist (research-ops v2.1, knowledge-ops v2.1).

| # | MCP | Target Skill | Status | API Key |
|---|-----|-------------|--------|---------|
| 1 | context7 | research-ops | ⚠️ PARTIAL — `scripts/fetch-context7.sh` (workflow doc, needs local-rag) | `.rag.context7` |
| 2 | arxiv | research-ops | ✅ DONE — `scripts/search-arxiv.sh` (category/author/sort, xmllint) | None (public) |
| 3 | brave-search | research-ops | ✅ DONE — `scripts/search-brave.sh` (web/news/video/image, freshness) | `.search.brave` |
| 4 | wikipedia | research-ops | ✅ DONE — `scripts/fetch-wikipedia.sh` (multi-lang, summary/full/search) | None (public) |
| 5 | perplexity | research-ops | ✅ DONE — `scripts/search-perplexity.sh` (4 sonar models, citations) | `.llm.perplexity` |
| 6 | gptresearcher | research-ops | ⏳ BLOCKED — `scripts/deep-research-gpt.sh` (workflow doc, API key TBD) | API key TBD |
| 7 | lotus-wisdom | knowledge-ops | ✅ Patterns in knowledge-ops lines 81-89 | N/A (prompt-only) |
| 8 | chroma | db-ops (NEW) | ⏳ Create db-ops skill with Docker Chroma client | N/A (local Docker) |

**Status**: 7/8 DONE (4 scripts + 1 partial + 2 prior). Remaining: #6 (GPTResearcher — blocked, API key), #8 (Chroma/db-ops — blocked, Docker).
**Stream 1 complete**: research-ops v2.1.0 with 8 scripts, 12/12 tests pass, ~3,100 token savings/session.

---

## Priority 2: Install High-Value MCPs for Decomposition

From marketplace report Tier 1 + GitHub assessment. Install → Study → Rebuild → Uninstall.

| # | Tool | Source | Target Skill | Value | Effort |
|---|------|--------|-------------|-------|--------|
| 9 | Serena | oraios/serena | code-ops | V/E=4.5 (highest) | ⏸ DEFERRED — memory leak (#944), tool decay (#340). Monitor for stability. Report: `research/serena-mcp-analysis.md` |
| 10 | Vizro + vizro-mcp | mckinsey/vizro | data-sci-ops | V/E=2.67 | 1 hr install |
| 11 | ElevenLabs MCP | elevenlabs | audio-ops | V/E=3.5 | 20 min |
| 12 | claude-code-docs | ericbuess | reference | ⏸ SKIP — not MCP, just /docs command. WebFetch covers this. 77 open issues, security bypass (#117). | N/A |
| 13 | Deep Research | u14app | research-ops | ⏸ DEFER — monolithic research() tool, ~$0.30/query. research-ops v2.1 covers 70%. Decompose planning+synthesis patterns if speed needed. | 8-12 hrs decompose |
| 14 | Obsidian skills | Community | knowledge-ops | USER OVERRIDE | 15 min install |
| 15 | n8n MCP skills | Community | flow-ops | USER OVERRIDE | 15 min install |

**Effort**: Phase 2 installs = ~2 hours. Phase 3 decomposition = 2-3 weeks.

---

## Priority 3: Marketplace Skill Extraction

Cherry-pick 5-10 skills from large libraries. Don't wholesale install.

| # | Source | Skills to Extract | Target | Status |
|---|--------|-------------------|--------|--------|
| 16 | context-engineering-marketplace (13 skills) | context-compression, context-optimization, memory-systems, context-degradation, filesystem-context | context-management, knowledge-ops | ✅ RESEARCHED — report at `.claude/context/research/context-engineering-marketplace-analysis.md` |
| 17 | claude-night-market (126 skills, 16 plugins) | imbue (TDD hooks), attune (reversibility-scored decisions), memory-palace (tiered KG), conserve (context optimization), workflow-improvement (self-optimization) | self-ops, code-ops | ✅ RESEARCHED — key patterns documented |
| 18 | ai-research-skills (83 skills) | 5-10 best architecture/safety/training skills | research-ops | ✅ RESEARCHED — report at `.claude/context/research/ai-research-skills-analysis.md`. LOW priority now (needs GPU infra). |
| 19 | omc patterns (28 agents, 37 skills) | Model tier routing, skill composition, hook consolidation | self-ops, autonom-ops | ✅ RESEARCHED — report at `.claude/context/research/omc-patterns-analysis.md`. 4 patterns extractable (model routing, skill composition, hook clusters, auto-learner). |
| 20 | supabase-agent-skills | PostgreSQL best practices | db-ops | ✅ RESEARCHED — report at `.claude/context/research/supabase-agent-skills-analysis.md`. Progressive disclosure + DB-specific sub-modules pattern. |

**Status**: 5/5 RESEARCHED. Stream 2 cherry-pick extraction in progress.
**Extracted (Stream 2)**:
- AIS (anchored iterative summarization) → compression-agent.md Step 0
- Observation masking → compression-agent.md Step 4
- Skill composition primitives → capability-map.yaml `compositions:` section (4 chains)
- Automatic learner → capability-map.yaml `compose.learn-from-session`
- Hook consolidation → `reference/hook-consolidation-plan.md` (28→17 hooks, 5 merges)
- Supabase progressive disclosure: ✅ VALIDATED — matches existing SKILL.md manifest pattern. Adopt reference file structure + impact-level tagging for future db-ops skill.
- AI-Research skills: ⏸ DEFERRED — requires GPU infrastructure (Mac Studio or cloud). LOW current priority, HIGH future value. 83 skills catalogued in research report.
- Memory-palace: ✅ DONE — organic lifecycle + pruning + capture extensions → knowledge-ops v2.1.0 (lines 91-130)

---

## Priority 4: x-ops Skill Consolidation

Merge existing skills into unified x-ops skills. See registry for full architecture.

| # | New Skill | Absorbs | Current Skills | Effort |
|---|-----------|---------|---------------|--------|
| 21 | self-ops | 3 skills | self-improvement + jarvis-status + validation | ✅ DONE (c618123) |
| 22 | doc-ops | 4 skills | docx + xlsx + pdf + pptx | ✅ DONE (c618123) |
| 23 | mcp-ops | 4 skills | mcp-validation + mcp-builder + plugin-decompose + skill-creator | ✅ DONE (c618123) |
| 24 | autonom-ops | 4 skills | autonomous-commands + session-management + context-management + ralph-loop | ✅ DONE (c618123) |
| 25 | db-ops | NEW | chroma + supabase + mongodb + sqlite + neo4j + mindsdb | 4 hrs |
| 26 | web-ops | NEW | playwright + browserstack + scraping patterns | 2 hrs |

**Total effort**: ~14.5 hours across 6 consolidations.
**Dependency**: db-ops and web-ops require MCPs/tools to be installed first.

---

## Priority 5: Future x-ops (When Infrastructure Ready)

| # | Skill | Prerequisites | Timeline |
|---|-------|---------------|----------|
| 27 | code-ops | Serena installed, semgrep available | After Mac Studio |
| 28 | flow-ops | n8n Docker running | After Mac Studio |
| 29 | data-sci-ops | Vizro installed, Python env ready | After Mac Studio |
| 30 | audio-ops | ElevenLabs MCP installed | When needed |
| 31 | comms-ops | Slack workspace created | When needed |

---

## Deferred (External Blockers)

| Item | Blocker | When |
|------|---------|------|
| Slack integration | No workspace | When created |
| GoogleDrive | Billing decision | User decision |
| GoogleMaps | Billing decision | User decision |
| Neo4j/Graphiti | Neo4j server | After Mac Studio |
| BioRxiv MCP | No research need | When biology research begins |

---

## Tracking

Each item moves through: `BACKLOG → IN PROGRESS → DONE`

Update this file when:
- An MCP is installed or removed
- A skill reconstruction is completed
- An x-ops consolidation is finished
- Marketplace skills are extracted

Cross-reference: `mcp-decomposition-registry.md` (detailed analysis), `marketplace-evaluation-report.md` (full assessment), `skill-descriptions.csv` (current skill inventory).

---

*Tool Reconstruction Backlog v1.0 — Synthesized from registry v5.0 + marketplace report v1.0*
