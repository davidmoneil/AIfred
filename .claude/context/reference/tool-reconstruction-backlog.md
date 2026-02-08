# Tool Reconstruction Backlog

**Created**: 2026-02-08
**Version**: 1.0
**Sources**: `mcp-decomposition-registry.md` v5.0, `marketplace-evaluation-report.md` v1.0
**Paradigm**: Decomposition-First — reconstruct unique capabilities as native skills

---

## Backlog Overview

| Category | Items | Status |
|----------|-------|--------|
| MCP Reconstruction (in-progress) | 8 | 6/8 DONE (templates + keys validated) |
| New MCP → Skill (planned) | 19 | Planned (MCPs not yet installed) |
| Marketplace Extraction | 10 | Prioritized for install/study/extract |
| x-ops Consolidation | 6 | 4/6 DONE (self-ops, doc-ops, mcp-ops, autonom-ops) |
| **Total actionable items** | **43** | |

---

## Priority 1: Complete In-Progress Reconstructions

These MCPs were removed but their unique capabilities need native skill integration.
Target skills already exist (research-ops v2.0, knowledge-ops v2.0).

| # | MCP | Target Skill | Status | API Key |
|---|-----|-------------|--------|---------|
| 1 | context7 | research-ops | ✅ Template + key exist (`.rag.context7`) | `.rag.context7` |
| 2 | arxiv | research-ops | ✅ Template exists, URL fixed (http→https) | None (public) |
| 3 | brave-search | research-ops | ✅ Template + key exist, tested OK | `.search.brave` |
| 4 | wikipedia | research-ops | ✅ Template exists, tested OK | None (public) |
| 5 | perplexity | research-ops | ✅ Template + key exist, tested OK | `.llm.perplexity` |
| 6 | gptresearcher | research-ops | ⏳ Workflow documented, needs agent impl | API key TBD |
| 7 | lotus-wisdom | knowledge-ops | ✅ Patterns in knowledge-ops lines 81-89 | N/A (prompt-only) |
| 8 | chroma | db-ops (NEW) | ⏳ Create db-ops skill with Docker Chroma client | N/A (local Docker) |

**Status**: 6/8 DONE. Remaining: #6 (GPTResearcher agent), #8 (Chroma/db-ops).
**Blocker**: #8 needs Docker Chroma running. #6 needs API key provisioning.

---

## Priority 2: Install High-Value MCPs for Decomposition

From marketplace report Tier 1 + GitHub assessment. Install → Study → Rebuild → Uninstall.

| # | Tool | Source | Target Skill | Value | Effort |
|---|------|--------|-------------|-------|--------|
| 9 | Serena | oraios/serena | code-ops | V/E=4.5 (highest) | 30 min install |
| 10 | Vizro + vizro-mcp | mckinsey/vizro | data-sci-ops | V/E=2.67 | 1 hr install |
| 11 | ElevenLabs MCP | elevenlabs | audio-ops | V/E=3.5 | 20 min |
| 12 | claude-code-docs | ericbuess | reference | Optimal as-is | 10 min |
| 13 | Deep Research | u14app | research-ops | Multi-round workflow | 2-3 weeks decompose |
| 14 | Obsidian skills | Community | knowledge-ops | USER OVERRIDE | 15 min install |
| 15 | n8n MCP skills | Community | flow-ops | USER OVERRIDE | 15 min install |

**Effort**: Phase 2 installs = ~2 hours. Phase 3 decomposition = 2-3 weeks.

---

## Priority 3: Marketplace Skill Extraction

Cherry-pick 5-10 skills from large libraries. Don't wholesale install.

| # | Source | Skills to Extract | Target |
|---|--------|-------------------|--------|
| 16 | context-engineering-marketplace (11 skills) | Context compression, memory patterns | context-management, knowledge-ops |
| 17 | claude-night-market (126 skills) | imbue (TDD), attune (decisions), sanctum (security) | self-ops, code-ops |
| 18 | ai-research-skills (83 skills) | 5-10 best architecture/safety/training skills | research-ops |
| 19 | omc patterns (28 agents, 37 skills) | LSP integration, execution modes | Study only |
| 20 | supabase-agent-skills | PostgreSQL best practices | db-ops |

**Effort**: Each extraction = ~30 min review + ~15 min integration. Total: ~5-8 hours.

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
