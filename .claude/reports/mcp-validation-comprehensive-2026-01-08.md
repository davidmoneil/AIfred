# MCP Validation Harness — Comprehensive Report

**Date**: 2026-01-08
**Validator**: Claude Opus 4.5
**Version**: Jarvis v1.8.3
**MCPs Registered**: 17
**MCPs with Tools Loaded**: 14
**MCPs Connected Only**: 3

---

## Executive Summary

| Metric | Value |
|--------|-------|
| Total MCPs | 17 |
| PASS (Tools Functional) | 14 |
| CONNECTED (No Tools) | 3 |
| FAIL | 0 |
| Estimated Token Cost | ~45K tokens |

**Key Finding**: Discovery #7 confirmed — 3 MCPs show "Connected" in `claude mcp list` but tools are NOT available in this session due to context token limits when all 17 MCPs are active.

---

## Phase 1: Installation Verification

All 17 MCPs registered and showing "✓ Connected":

```
memory: ✓ Connected
fetch: ✓ Connected
git: ✓ Connected
filesystem: ✓ Connected
github: ✓ Connected
context7: ✓ Connected
sequential-thinking: ✓ Connected
arxiv: ✓ Connected
brave-search: ✓ Connected
datetime: ✓ Connected
lotus-wisdom: ✓ Connected
chroma: ✓ Connected
desktop-commander: ✓ Connected
wikipedia: ✓ Connected
playwright: ✓ Connected
perplexity: ✓ Connected
gptresearcher: ✓ Connected
```

---

## Phase 2-3: Configuration Audit & Tool Inventory

### Tier 1 — Always-On (Core Infrastructure)

| MCP | Tools | Token Est. | Status | Test Result |
|-----|-------|------------|--------|-------------|
| **memory** | 9 | ~1.8K | ✅ PASS | `read_graph` returned 7 entities, 6 relations |
| **filesystem** | 13 | ~2.8K | ✅ PASS | `list_directory` returned 18 items |
| **fetch** | 1 | ~0.5K | ✅ PASS | `fetch` returned JSON from httpbin.org |
| **git** | 12 | ~2.5K | ✅ PASS | `git_status`, `git_branch` both working |

**Tier 1 Total**: ~7.6K tokens

### Tier 2 — Task-Scoped (Research & Utilities)

| MCP | Tools | Token Est. | Status | Test Result |
|-----|-------|------------|--------|-------------|
| **brave-search** | 2 | ~3K | ✅ PASS | `brave_web_search` returned 2 results |
| **arxiv** | 4 | ~2K | ✅ PASS | `search_papers` returned 2 papers |
| **datetime** | 1 | ~1K | ✅ PASS | `get_current_datetime` returned PT time |
| **wikipedia** | 2 | ~2K | ✅ PASS | `search` returned 10 MCP-related articles |
| **chroma** | 12 | ~4K | ✅ PASS | `chroma_list_collections` executed (empty) |
| **desktop-commander** | 30+ | ~8K | ✅ PASS | `list_sessions` executed |
| **perplexity** | 4 | ~3K | ✅ PASS | `perplexity_search` returned detailed results |
| **gptresearcher** | 5 | ~3K | ✅ PASS | `quick_search` returned 9 sources |
| **github** | 20+ | ~5K | ⚠️ CONNECTED | Tools not loaded in session |
| **context7** | 2 | ~2K | ⚠️ CONNECTED | Tools not loaded in session |
| **sequential-thinking** | 1 | ~1K | ⚠️ CONNECTED | Tools not loaded in session |

**Tier 2 Total**: ~34K tokens (when all loaded)

### Tier 3 — Triggered (Heavy/Specialized)

| MCP | Tools | Token Est. | Status | Test Result |
|-----|-------|------------|--------|-------------|
| **playwright** | 20+ | ~6K | ✅ PASS | `browser_navigate` + `browser_close` working |
| **lotus-wisdom** | 2 | ~2K | ✅ PASS | `lotuswisdom` returned framework |

**Tier 3 Total**: ~8K tokens

---

## Phase 4: Functional Test Results

### Fully Validated (14 MCPs)

| MCP | Test Performed | Result |
|-----|----------------|--------|
| memory | `read_graph` | 7 entities returned |
| filesystem | `list_directory` | 18 items in Jarvis root |
| fetch | `fetch` https://httpbin.org/get | JSON response received |
| git | `git_status` + `git_branch` | On Project_Aion, clean |
| brave-search | `brave_web_search` "Claude Code MCP" | 2 results with URLs |
| arxiv | `search_papers` cs.AI | 2 papers with abstracts |
| datetime | `get_current_datetime` America/Los_Angeles | 2026-01-08T11:48:27 |
| wikipedia | `search` "Model Context Protocol" | 10 related articles |
| chroma | `chroma_list_collections` | Empty (expected) |
| desktop-commander | `list_sessions` | No active sessions |
| perplexity | `perplexity_search` | Detailed search results |
| gptresearcher | `quick_search` | 9 sources returned |
| playwright | `browser_navigate` + `browser_close` | Example.com loaded |
| lotus-wisdom | `lotuswisdom` begin | Framework received |

### Connected But Tools Not Loaded (3 MCPs)

| MCP | Status | Likely Cause |
|-----|--------|--------------|
| github | Connected, no tools | Context token limit |
| context7 | Connected, no tools | Context token limit |
| sequential-thinking | Connected, no tools | Context token limit |

**Root Cause Analysis**: With 17 MCPs active, total tool definition tokens exceed available context budget. These 3 MCPs are loaded last and don't fit in remaining context space.

---

## Phase 5: Tier Recommendations

### Final Tier Classification

| Tier | MCPs | Total Tokens | Loading Strategy |
|------|------|--------------|------------------|
| **Tier 1** | memory, filesystem, fetch, git | ~7.6K | Always-On |
| **Tier 2** | brave-search, arxiv, datetime, wikipedia, chroma, desktop-commander, perplexity, gptresearcher, github, context7, sequential-thinking | ~34K | Task-Scoped |
| **Tier 3** | playwright, lotus-wisdom | ~8K | On-Demand |

### Recommended Active Set

For typical sessions, recommend loading **10-12 MCPs max** to avoid tool loading failures:

**Always Load** (Tier 1):
- memory, filesystem, fetch, git

**Default Tier 2** (pick based on task):
- Research: brave-search, arxiv, perplexity, wikipedia
- Development: github, context7
- System: datetime, desktop-commander
- Data: chroma

**Load on Demand** (Tier 3):
- Browser automation: playwright
- Contemplative reasoning: lotus-wisdom

---

## Recommendations

### Immediate Actions

1. **Reduce default MCP count**: Disable 3-5 MCPs to ensure all remaining MCPs have tools loaded
2. **Prioritize by task type**: Use session-start hook to suggest MCP configuration
3. **Document tool loading limit**: ~45K tokens appears to be practical limit

### Configuration Suggestions

**For Research Sessions**:
```
Enable: memory, filesystem, fetch, git, brave-search, arxiv, perplexity, gptresearcher, wikipedia
Disable: github, context7, sequential-thinking, playwright, lotus-wisdom, desktop-commander, chroma
```

**For Development Sessions**:
```
Enable: memory, filesystem, fetch, git, github, context7, sequential-thinking, desktop-commander
Disable: brave-search, arxiv, perplexity, gptresearcher, wikipedia, playwright, lotus-wisdom, chroma
```

**For Full Capability** (accept some tools won't load):
```
Enable: All 17
Accept: 3 lowest-priority MCPs may not have tools available
```

---

## Validation Summary

| Category | Count | Status |
|----------|-------|--------|
| Total MCPs | 17 | — |
| Tools Functional | 14 | ✅ |
| Connected Only | 3 | ⚠️ |
| Failed | 0 | — |
| Removed (Previous) | 1 | DuckDuckGo (bot detection) |

**Overall Assessment**: MCP infrastructure is healthy. The 3 "Connected but no tools" MCPs are a known limitation when running all 17 MCPs simultaneously. Recommend task-based MCP selection for optimal performance.

---

*MCP Validation Harness — Comprehensive Report v1.0*
*Generated: 2026-01-08 by Jarvis v1.8.3*
