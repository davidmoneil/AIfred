# Tool Reconstruction Backlog
## Decomposition, Reconstruction & Integration Tracking

**Version**: 2.0
**Date**: 2026-02-08
**Related**: pipeline-design-v3.md (paradigm + pipeline definitions)
**Research**: All 16 GitHub repos assessed — agents a563618 (batch 1) + a254b61 (batch 2)

---

## Priority Tiers

| Tier | Criteria | Timeframe |
|------|----------|-----------|
| **P0** | User overrides + paid API keys + infrastructure arriving | Next 1-2 sessions |
| **P1** | High-value swiss-army-knife components | Next 3-5 sessions |
| **P2** | Valuable marketplace plugins to evaluate/decompose | Next 5-10 sessions |
| **P3** | Nice-to-have, defer until needed | Backlog |

---

## P0: User Overrides — Full Reconstruction Required

### research-ops skill (swiss-army-knife)

| # | Source | Type | Status | Notes |
|---|--------|------|--------|-------|
| 1 | Perplexity MCP | API (PAID key) | TODO | 4 models: search, ask, research, reason |
| 2 | GPT Researcher MCP | API (PAID key) | TODO | Autonomous multi-source research |
| 3 | Context7 MCP | API wrapper | TODO | Version-pinned doc fetching → compare w/ WebFetch |
| 4 | arXiv MCP | API + cache | TODO | Academic paper search + local caching |
| 5 | Brave Search MCP | API (has key) | TODO | Local/video/news search |
| 6 | Wikipedia MCP | API wrapper | TODO | Structured sections, facts, multi-lang |
| 7 | DuckDuckGo MCP | API (free) | TODO | Global fallback when WebSearch unavailable |

### knowledge-ops skill (swiss-army-knife)

| # | Source | Type | Status | Notes |
|---|--------|------|--------|-------|
| 8 | Memory MCP | Auto-provisioned | TODO | Shadow via JSON file ops (jq + Read/Write) |
| 9 | Lotus Wisdom MCP | Prompt patterns | TODO | Contemplative reflection → AC-05/06 |
| 10 | Obsidian skills | Marketplace plugin | TODO | USER OVERRIDE: native vault skills |
| 11 | local-rag MCP | Retained MCP | RETAIN | Integrate into knowledge-ops routing |

### database-ops skill (swiss-army-knife)

| # | Source | Type | Status | Notes |
|---|--------|------|--------|-------|
| 12 | Chroma MCP | Vector DB | TODO | USER OVERRIDE: DEFAULT vector DB for everything |
| 13 | Supabase MCP | PostgreSQL/REST | TODO | Paid credentials available |
| 14 | MongoDB MCP | Document store | TODO | CLI (mongosh) + scripts |
| 15 | SQLite | CLI tool | TODO | sqlite3 native, standardized interface |
| 16 | Neo4j/Graphiti | Graph DB | EVALUATE | Retain MCP if Neo4j running |

### n8n-ops skill

| # | Source | Type | Status | Notes |
|---|--------|------|--------|-------|
| 17 | n8n MCP | Workflow API | TODO | USER OVERRIDE: Mac Studio incoming |
| 18 | n8n-mcp-skills | Marketplace (7 skills) | TODO | Expert skills for n8n workflows |

---

## P1: High-Value Reconstruction

### code-security skill

| # | Source | Type | Status | Notes |
|---|--------|------|--------|-------|
| 19 | Semgrep MCP | CLI tool | TODO | AST analysis, 5000+ rules, pre-commit integration |

### codebase-ops skill

| # | Source | Type | Status | Notes |
|---|--------|------|--------|-------|
| 20 | Repomix | CLI + marketplace | TODO | Tree-sitter compression, XML packing |

### context-engineering skills (from marketplace)

| # | Source | Type | Status | Notes |
|---|--------|------|--------|-------|
| 21 | context-engineering-marketplace | 11 skills | EVALUATE | Context compression, optimization, degradation |
|    | | | | Multi-agent patterns, memory systems, tool design |
|    | | | | Directly relevant to JICM + Aion architecture |

### Existing skill optimization (Format Standard v2.0)

| # | Source | Type | Status | Notes |
|---|--------|------|--------|-------|
| 22 | filesystem-ops | Existing skill | TODO | Reformat to ≤300 tokens |
| 23 | git-ops | Existing skill | TODO | Reformat to ≤300 tokens |
| 24 | session-management | Existing skill | TODO | Reformat to ≤300 tokens |
| 25 | context-management | Existing skill | TODO | Reformat to ≤300 tokens |

---

## P2: Marketplace Plugins to Evaluate & Decompose

### High-Value Marketplace Plugins

| # | Plugin | Marketplace | Skills/Agents | Status | Notes |
|---|--------|-------------|---------------|--------|-------|
| 26 | ai-research-skills | Orchestra Research | 83 skills | EVALUATE | AI research: architectures, fine-tuning, training |
| 27 | claude-scientific-skills | K-Dense | 140 skills | EVALUATE | Biology, chemistry, physics, medicine |
| 28 | everything-claude-code | affaan-m | 15+ agents, 30+ skills | EVALUATE | Battle-tested configs from hackathon winner |
| 29 | omc (oh-my-claudecode) | Yeachan Heo | 28 agents, 37 skills | EVALUATE | Multi-agent orchestration, model routing |
| 30 | Mixedbread-Grep (mgrep) | Mixedbread | Semantic search | EVALUATE | Replace pattern grep with semantic search |
| 31 | claude-night-market | athola | 16 plugins | EVALUATE | GitHub/GitLab OAuth, TDD enforcement |
| 32 | supabase-agent-skills | Supabase official | Postgres patterns | EVALUATE | Best practices for database-ops skill |
| 33 | superpowers | obra | 20+ skills | INSTALLED | TDD, debugging, collaboration patterns |
| 34 | claude-hud | jarrodwatts | Status plugin | EVALUATE | Real-time context/tool/agent HUD |
| 35 | planning-with-files | OthmanAdi | Planning plugin | EVALUATE | Manus-style persistent markdown planning |

### Medium-Value Marketplace Plugins

| # | Plugin | Marketplace | Type | Status | Notes |
|---|--------|-------------|------|--------|-------|
| 36 | agent-browser | vercel-labs | Agent framework | EVALUATE | Multi-agent + LSP/AST integration |
| 37 | langroid | langroid | Framework docs | EVALUATE | Agent orchestration patterns |
| 38 | voltagent-subagents | VoltAgent | 127 subagents | EVALUATE | 10 categories of specialized agents |
| 39 | prp-marketplace | Wirasm | PRP workflow | EVALUATE | Product Requirement Prompt automation |
| 40 | claude-workflow | CloudAI-X | Workflow plugin | EVALUATE | Specialized agents for SW dev |
| 41 | daymade-skills | daymade | 30+ skills | EVALUATE | GitHub ops, doc conversion, diagrams |
| 42 | stripe | Stripe official | MCP + toolkit | DEFER | Payment integration (when needed) |
| 43 | exa-mcp-server | Exa AI | HTTP MCP | EVALUATE | Semantic web/code search (paid API) |
| 44 | cc-marketplace | ananddtyagi | Community plugins | EVALUATE | Documentation gen, code review |
| 45 | buildwithclaude | davepoon | Discovery platform | EVALUATE | 117 agents, 175 commands |
| 46 | prompts.chat | f | Prompt platform | DEFER | Social prompt sharing (low priority) |
| 47 | browser-tools | vercel-labs | Stagehand | EVALUATE | NL browser automation |

---

## P0-EXT: GitHub Repos — Research Complete

All 16 repos assessed by deep-research agents (a563618 batch 1, a254b61 batch 2).
Full reports: `/private/tmp/claude-501/-Users-aircannon-Claude-Jarvis/tasks/a563618.output`, `a254b61.output`

### Tier 1: Install Immediately (High Value, Low Risk)

| # | Repo | Type | Verdict | V/E Ratio | Notes |
|---|------|------|---------|-----------|-------|
| 54 | oraios/serena | MCP server | **INSTALL (keep)** | 4.5 | Semantic code ops via LSP, 30+ langs, massive token savings. DO NOT decompose. |
| 49 | mckinsey/vizro | Python + MCP | **INSTALL (hybrid)** | 2.67 | Production dashboards. Keep vizro-mcp, extract config patterns. |
| 51 | elevenlabs/elevenlabs-mcp | MCP server | **INSTALL (keep)** | 3.5 | Official TTS/voice. 10k free credits/mo. MCP + wrapper skills. |
| 62 | ericbuess/claude-code-docs | Slash command | **INSTALL (keep)** | N/A | Reference impl for custom commands. Already optimal, no decomposition. |

### Tier 2: Install → Study → Decompose → Uninstall

| # | Repo | Type | Verdict | V/E Ratio | Notes |
|---|------|------|---------|-----------|-------|
| 61 | u14app/deep-research | Next.js + MCP | **DECOMPOSE** | HIGH | Multi-round research workflow → rebuild as skills. Highest decomp value. |
| 48 | glittercowboy/get-shit-done | npm package | **EXTRACT PATTERNS** | 1.17 | STATE.md + phase gates useful. Workflow conflicts w/ AC-02. Don't wholesale install. |

### Tier 3: Infrastructure (Keep Running)

| # | Repo | Type | Verdict | V/E Ratio | Notes |
|---|------|------|---------|-----------|-------|
| 56 | coleam00/archon | Full app + UI | **KEEP INFRA** | MEDIUM | Localhost UI (3737) for knowledge base + MCP building. Docker. |
| 57 | trycua/cua | Platform + SDK | **KEEP INFRA** | MEDIUM | Unique VM/sandbox capabilities. Python 3.12. Not decomposable. |
| 53 | dayuanjiang/next-ai-draw-io | Full app | **KEEP INFRA** | 2.0 | AI diagramming. Docker or desktop. Monitor MCP preview feature. |

### Tier 4: Conditional (Depends on Needs)

| # | Repo | Type | Verdict | V/E Ratio | Notes |
|---|------|------|---------|-----------|-------|
| 50 | deepsense.ai/biorxiv/mcp | Hosted MCP | **INSTALL IF NEEDED** | 6.0 | Academic paper access. 15 min install. No local overhead. |
| 58 | lauriewired/ghidramcp | MCP + Ghidra | **INSTALL IF RE** | MEDIUM | Reverse engineering. Requires Ghidra (#63). Cannot decompose. |
| 63 | NSA/ghidra | Desktop app | **INSTALL IF RE** | MEDIUM | Binary analysis platform. Required for #58. |
| 59 | zilliztech/claude-context | MCP server | **COMPARE vs local-rag** | MEDIUM | Semantic code search. Test vs existing local-rag MCP, keep winner. |
| 60 | openbmb/ultrarag | Framework + UI | **INSTALL IF RAG FOCUS** | MEDIUM | RAG pipeline IDE (5050). Docker. Keep if building RAG regularly. |

### Tier 5: Low Priority / Strategic Only

| # | Repo | Type | Verdict | V/E Ratio | Notes |
|---|------|------|---------|-----------|-------|
| 55 | ruvnet/claude-flow | Full package + MCP | **STRATEGIC ONLY** | 0.8 | OVERLAPS with Jarvis. Extract WASM Booster + token optimizer patterns ONLY. |
| 52 | sansan0/trendradar | Multi-mode app | **LOW PRIORITY** | 0.86 | Chinese docs barrier. High maintenance. Consider simpler RSS alternatives. |

---

## Completed Work (Reference)

| # | Item | Type | Status | Skill Created |
|---|------|------|--------|---------------|
| - | filesystem MCP | Removed | DONE | filesystem-ops |
| - | fetch MCP | Shadowed | DONE | web-fetch |
| - | git MCP | Shadowed | DONE | git-ops |
| - | weather block | Extracted | DONE | weather |
| - | CLAUDE.md | Slimmed 54% | DONE | — |
| - | MEMORY.md | Restructured 88% | DONE | — |
| - | SessionStart hook | Trimmed | DONE | — |
| - | capability-map.yaml | Created | DONE | — |
| - | Pipeline docs | Formalized | DONE | — |

---

## Metrics

| Metric | Value |
|--------|-------|
| Total backlog items | 63 |
| P0 (user overrides) | 18 |
| P1 (high-value) | 7 |
| P2 (marketplace eval) | 22 |
| P0-EXT (GitHub repos) | 16 (all researched) |
| Completed | 9 |
| Swiss-army-knife skills planned | 5 (research-ops, knowledge-ops, database-ops, n8n-ops, code-security) |

### P0-EXT Research Summary

| Verdict | Count | Repos |
|---------|-------|-------|
| Install Immediately | 4 | Serena, Vizro, ElevenLabs, Claude-Code-Docs |
| Decompose (install→study→rebuild) | 2 | Deep Research, Get-Shit-Done |
| Keep as Infrastructure | 3 | Archon, Cua, Next-ai-draw-io |
| Conditional (needs-based) | 5 | BioRxiv, GhidraMCP, Ghidra, Claude-Context, UltraRAG |
| Strategic/Low Priority | 2 | Claude-Flow, TrendRadar |

### Recommended Install Order

```
Week 1: Serena MCP + Claude-Code-Docs (quick wins, 2hrs)
Week 1: Vizro core + MCP (dashboards, 3hrs)
Week 2: ElevenLabs MCP (audio, 2hrs)
Week 2: Deep Research (install→decompose, 2-3wks)
Week 3: Next-ai-draw-io Docker (diagrams, 2hrs)
Week 3: BioRxiv MCP if research-heavy (30min)
Later:  Archon, Cua, GhidraMCP (as needed)
Never:  Claude-Flow wholesale (extract patterns only)
```

---

*Tool Reconstruction Backlog v2.0 — 2026-02-08*
*See pipeline-design-v3.md for paradigm, decision trees, and pipeline protocols.*
*Research reports: a563618.output (batch 1), a254b61.output (batch 2)*
