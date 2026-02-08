# Marketplace Plugin Evaluation Report
## Claude Code Plugin Ecosystem Assessment

**Version**: 1.0
**Date**: 2026-02-08
**Author**: Jarvis (Autonomous Archon)
**Source**: 42 marketplace directories + 16 GitHub repos
**Total Items Assessed**: 500+ plugins/skills/agents

---

## Executive Summary

Assessment of 42 installed Claude Code marketplace directories revealed a rich but noisy ecosystem. Of 500+ discoverable items, approximately 30 merit serious evaluation, with 8-10 offering immediate value for the Jarvis/Aion architecture.

**Key finding**: The highest-value items fall into two categories:
1. **MCP servers** providing unique infrastructure (Serena, ElevenLabs, BioRxiv) — retain as MCPs
2. **Skill libraries** with extractable patterns (ai-research-skills, context-engineering, night-market) — decompose into native skills

---

## Tier 1: Immediate Value (Install/Integrate Now)

### Already Installed & Active

| Plugin | Source | Items | Assessment | Action |
|--------|--------|-------|------------|--------|
| **superpowers** | obra | 20+ skills | HIGH VALUE — TDD, debugging, verification skills actively used | **KEEP** |
| **superpowers-marketplace** | obra | 3 plugins | Distribution channel for superpowers | **KEEP** |

### Recommended for Installation

| Plugin | Source | Items | Assessment | Action |
|--------|--------|-------|------------|--------|
| **context-engineering-marketplace** | Community | 11 skills | Directly relevant to JICM + Aion. Context compression, multi-agent patterns, memory systems. | **EVALUATE → EXTRACT** |
| **claude-night-market** | athola | 16 plugins, 126 skills | Richest single source. TDD (imbue), OAuth (leyline), war-room decisions (attune). | **SELECTIVE INSTALL** |
| **obsidian-skills** | Community | Vault skills | USER OVERRIDE — native Obsidian integration for knowledge-ops. | **INSTALL** |
| **n8n-mcp-skills** | Community | 7 skills | USER OVERRIDE — expert n8n workflow patterns for n8n-ops. | **INSTALL** |
| **repomix** | Community | CLI + skills | Tree-sitter compression, codebase packing. Useful for codebase-ops. | **EVALUATE** |

---

## Tier 2: High Value, Selective Extraction

### Large Skill Libraries (Extract, Don't Wholesale)

| Plugin | Source | Items | Assessment | Action |
|--------|--------|-------|------------|--------|
| **ai-research-skills** | Orchestra | 83 skills / 20 categories | Comprehensive AI research. Architecture, fine-tuning, training, safety. Volume too high for wholesale install. | **CHERRY-PICK 5-10** |
| **claude-scientific-skills** | K-Dense | 140 skills | Biology, chemistry, physics, medicine. Massive but niche — install categories on-demand. | **ON-DEMAND** |
| **everything-claude-code** | affaan-m | 15+ agents, 30+ skills | Hackathon-winning configs. PM2 multi-agent orchestration. Study agent patterns. | **STUDY → EXTRACT** |

### Agent Orchestration (Study Patterns)

| Plugin | Source | Items | Assessment | Action |
|--------|--------|-------|------------|--------|
| **omc (oh-my-claudecode)** | Yeachan Heo | 28 agents, 37 skills, 31 hooks | Most sophisticated orchestration. LSP/AST tools, execution modes. May conflict with Aion patterns. | **STUDY ONLY** |
| **agent-browser** | vercel-labs | Multi-agent + LSP | Similar to omc but lighter. 15 custom tools. | **STUDY ONLY** |

---

## Tier 3: Specialized Tools (As-Needed)

### Development Workflow

| Plugin | Source | Type | Assessment | Action |
|--------|--------|------|------------|--------|
| **taskmaster** | Eyal Toledano | MCP (44 tools) | AI task management. Overlap with TodoWrite + our task system. | **SKIP** (redundant) |
| **planning-with-files** | OthmanAdi | Plugin | Manus-style markdown planning. 14 IDE support. Already have similar patterns. | **DEFER** |
| **claude-hud** | jarrodwatts | Status plugin | Context/tool/agent HUD. Interesting for monitoring but adds overhead. | **EVALUATE** |
| **Mixedbread-Grep (mgrep)** | Mixedbread | Semantic search | Replace pattern grep with semantic search. High potential for code discovery. | **EVALUATE** |
| **chrome-devtools-plugins** | Google | MCP | Browser debugging/automation. Complement to Playwright. | **INSTALL IF WEB DEV** |

### Business/Platform

| Plugin | Source | Type | Assessment | Action |
|--------|--------|------|------------|--------|
| **supabase-agent-skills** | Supabase official | Skills | Best practices for database-ops skill. PostgreSQL patterns. | **EXTRACT for db-ops** |
| **stripe** | Stripe official | MCP + toolkit | Payment integration. | **DEFER** (until needed) |
| **exa-mcp-server** | Exa AI | HTTP MCP | Semantic web search. Paid API. Compare with WebSearch. | **EVALUATE** |
| **browser-tools** | vercel-labs | Stagehand | NL browser automation. Complement to Playwright. | **EVALUATE** |

---

## Tier 4: Low Priority / Skip

### Discovery Platforms (Reference Only)

| Plugin | Source | Assessment | Action |
|--------|--------|------------|--------|
| **buildwithclaude** | davepoon | Discovery platform, 117 agents. Catalog value, not direct use. | **REFERENCE** |
| **cc-marketplace** | ananddtyagi | Community plugins. Basic doc gen + code review. | **SKIP** |
| **claude-plugins-official** | Anthropic | Official directory structure. Reference for plugin creation. | **REFERENCE** |
| **claude-code-templates** | aitmpl | 100+ templates. Web UI catalog. Not directly installable. | **REFERENCE** |

### Redundant or Low-Value

| Plugin | Source | Assessment | Action |
|--------|--------|------------|--------|
| **prompts.chat** | f | Social prompt platform. Full Next.js app. Not relevant to agent ops. | **SKIP** |
| **langroid** | langroid | Framework docs. Orchestration patterns only. No skills. | **SKIP** |
| **voltagent-subagents** | VoltAgent | 127 subagents. Volume without quality assessment. | **SKIP** |
| **prp-marketplace** | Wirasm | PRP workflow automation. Minimal content. | **SKIP** |
| **claude-workflow** | CloudAI-X | Generic workflow plugin. Nothing unique. | **SKIP** |
| **ykdojo** | ykdojo | Community tips. No formal skills. | **SKIP** |
| **danielrosehill** | danielrosehill | Docs only. No installable content. | **SKIP** |
| **mhattingpete-claude-skills** | mhattingpete | Community skills. Minimal. | **SKIP** |
| **thedotmack** | thedotmack | MCP config. Minimal content. | **SKIP** |
| **claude-canvas** | Community | Canvas/artifact management. Niche. | **SKIP** |
| **ui-ux-pro-max-skill** | Community | UI/UX design skill. Niche. | **DEFER** |
| **daymade-skills** | daymade | 30+ skills. GitHub ops, doc conversion. Generic. | **SKIP** |
| **claude-code-workflows** | Community | Dev workflow suite. Overlap with night-market. | **SKIP** |
| **awesome-claude-skills** | Community | Curated list. Discovery, not direct use. | **REFERENCE** |

---

## GitHub Repos Assessment (P0-EXT)

### Install Immediately

| Repo | Verdict | Key Finding |
|------|---------|-------------|
| **oraios/serena** | INSTALL & KEEP | Semantic code ops via LSP. 30+ languages. Token efficiency force multiplier. V/E=4.5 |
| **mckinsey/vizro** | INSTALL (hybrid) | Production dashboards. vizro-mcp for LLM-assisted creation. V/E=2.67 |
| **elevenlabs/elevenlabs-mcp** | INSTALL & KEEP | Official TTS/voice. 10k free credits/mo. V/E=3.5 |
| **ericbuess/claude-code-docs** | INSTALL & KEEP | Reference implementation for custom slash commands. Optimal as-is. |

### Decompose (Install → Study → Rebuild → Uninstall)

| Repo | Verdict | Key Finding |
|------|---------|-------------|
| **u14app/deep-research** | DECOMPOSE | Multi-round research workflow. Question gen, search synthesis, knowledge graphs. 2-3 week process. |
| **glittercowboy/get-shit-done** | EXTRACT PATTERNS | STATE.md + phase gates valuable. Conflicts with AC-02 autonomous loop. Selective extraction only. |

### Keep as Infrastructure

| Repo | Verdict | Key Finding |
|------|---------|-------------|
| **coleam00/archon** | KEEP (Docker) | Localhost UI for knowledge base + MCP building. High UI value. |
| **trycua/cua** | KEEP (unique) | VM/sandbox capabilities. Not replicable. Python 3.12 required. |
| **dayuanjiang/next-ai-draw-io** | KEEP (Docker/desktop) | AI diagramming from NL. MCP preview feature incoming. |

### Conditional

| Repo | Verdict | Key Finding |
|------|---------|-------------|
| **deepsense.ai/biorxiv** | IF RESEARCH | Hosted MCP. 260k+ preprints. 15 min install, zero local overhead. |
| **lauriewired/ghidramcp** + **NSA/ghidra** | IF RE WORK | Reverse engineering. Cannot decompose. Requires Ghidra install. |
| **zilliztech/claude-context** | COMPARE | Semantic code search. Test vs existing local-rag MCP. |
| **openbmb/ultrarag** | IF RAG FOCUS | RAG pipeline IDE with visual builder. Docker (port 5050). |

### Strategic/Low Priority

| Repo | Verdict | Key Finding |
|------|---------|-------------|
| **ruvnet/claude-flow** | STRATEGIC ONLY | Overlaps Jarvis mission. Extract WASM Booster + token optimizer patterns. V/E=0.8 |
| **sansan0/trendradar** | LOW | Chinese docs. High maintenance. Simpler RSS alternatives exist. V/E=0.86 |

---

## Recommended Action Plan

### Phase 1: Quick Wins (This Session)
1. Install `claude-code-docs` (10 min, curl one-liner)
2. Evaluate `context-engineering-marketplace` skills (11 skills, directly relevant to JICM)
3. Install `obsidian-skills` + `n8n-mcp-skills` (user overrides)

### Phase 2: MCP Installations (Next Session)
4. Install Serena MCP (30 min, highest value tool in entire assessment)
5. Install Vizro core + vizro-mcp (1 hr)
6. Install ElevenLabs MCP (20 min)

### Phase 3: Deep Decomposition (Next 2-3 Weeks)
7. Deep Research: install → study → rebuild as research-ops skills → uninstall
8. Get-Shit-Done: install → extract STATE.md + phase gates → uninstall
9. night-market: selective plugin install (imbue, attune, sanctum)

### Phase 4: Infrastructure (When Ready)
10. Archon Docker deployment (Mac Studio incoming)
11. Next-ai-draw-io Docker (architecture diagrams)
12. BioRxiv MCP (if research needs arise)

---

## Key Insights

1. **The ecosystem is 90% noise, 10% signal.** Of 500+ items across 42 marketplaces, ~30 merit evaluation and ~10 provide genuine value.

2. **MCP servers beat plugins for unique functionality.** Serena, ElevenLabs, BioRxiv — these provide capabilities that can't be replicated with prompt engineering.

3. **Large skill libraries need cherry-picking, not wholesale install.** 83 AI research skills and 140 scientific skills sound impressive but would drown the system. Select 5-10 from each.

4. **Night-market is the single richest plugin source.** 126 skills, 114 commands, 41 agents — but needs careful selective installation to avoid overhead.

5. **Orchestration tools (omc, claude-flow, agent-browser) are study material, not integration targets.** They overlap with Jarvis's own orchestration patterns. Learn from them, don't install.

6. **Decomposition-first paradigm validated.** Deep Research and Get-Shit-Done are textbook cases: install temporarily, extract the valuable patterns, rebuild as native skills, uninstall.

---

*Marketplace Evaluation Report v1.0 — 2026-02-08*
*Based on: 42 marketplaces inventoried, 16 GitHub repos researched, 500+ items assessed*
*Agents: a50cc01 (inventory), a563618 (repos batch 1), a254b61 (repos batch 2)*
