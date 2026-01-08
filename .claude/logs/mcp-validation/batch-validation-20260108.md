# MCP Batch Validation Log — 2026-01-08

**Session**: PR-8.5 MCP Expansion
**Validator**: Claude Opus 4.5

---

## Summary

| MCP | Status | Tier | Tools Tested | Notes |
|-----|--------|------|--------------|-------|
| DateTime | PASS | 2 | `get_current_datetime` | Timezone support working |
| DesktopCommander | PASS | 2 | `get_config`, `list_directory` | 30+ tools, rich system info |
| Lotus Wisdom | PASS | 3 | `lotuswisdom` | Contemplative reasoning framework |
| Wikipedia | PASS | 2 | `search`, `readArticle` | Full markdown article retrieval |
| Chroma | PASS | 2 | `create_collection`, `add_documents`, `query_documents` | Vector DB with semantic search |
| Perplexity | **PASS** | 2 | `search`, `ask`, `research`, `reason` | All 4 tools validated |
| Playwright | **PASS** | 3 | `navigate`, `snapshot`, `click`, `close` | Browser automation working |
| GPTresearcher | **PASS** | 2 | `quick_search`, `deep_research`, `get_sources` | Python 3.13 venv fix |

---

## Detailed Results

### 1. DateTime MCP
**Package**: `@pinkpixel/datetime-mcp`
**Status**: PASS

**Test**:
```
get_current_datetime(timezone="America/Chicago")
→ "2026-01-08T13:10:25.790-06:00"
```

**Assessment**: Simple, reliable time service. Recommended for workflows needing timestamp awareness.

---

### 2. DesktopCommander MCP
**Package**: `@wonderwhy-er/desktop-commander`
**Status**: PASS

**Test Results**:
- `get_config`: Returns full system configuration including blocked commands, shell info, Node/Python versions
- `list_directory`: Directory listing with FILE/DIR prefixes

**Features Discovered**:
- 32 blocked dangerous commands (mkfs, sudo, rm, etc.)
- Default shell: /bin/zsh
- System info: macOS darwin, arm64, Node 24.12.0, Python 3.9.6
- File read/write limits: 1000/50 lines

**Assessment**: Powerful desktop automation. Overlap with native filesystem MCP but adds process control, search, PDF creation.

---

### 3. Lotus Wisdom MCP
**Package**: `lotus-wisdom-mcp`
**Status**: PASS

**Test**: Called `lotuswisdom` with tag='begin'

**Response**: Full contemplative framework with:
- 5 wisdom domains: process_flow, skillful_means, non_dual_recognition, meta_cognitive, meditation
- 20 processing tags across domains
- Guidance for multi-step contemplative reasoning

**Assessment**: Unique MCP for reflective/philosophical reasoning. Tier 3 (specialized use cases).

---

### 4. Wikipedia MCP
**Package**: `wikipedia-mcp`
**Status**: PASS

**Test Results**:
- `search("Model Context Protocol")`: 10 results with titles, snippets, pageIds
- `readArticle(pageId=79706999)`: Full MCP Wikipedia article in markdown

**Assessment**: Excellent for factual grounding and research. Clean markdown output.

---

### 5. Chroma MCP
**Package**: `uvx chroma-mcp`
**Status**: PASS

**Test Workflow**:
1. `chroma_list_collections`: Empty (new DB)
2. `chroma_create_collection("jarvis_test")`: Created with default embeddings
3. `chroma_add_documents`: Added 3 docs with metadata
4. `chroma_query_documents("infrastructure automation tools")`: Correctly returned doc2 (Jarvis) as top match

**Assessment**: Full vector database functionality. Essential for RAG workflows.

---

### 6. Perplexity MCP
**Package**: `@perplexity-ai/mcp-server`
**Status**: **PASS** ✅

**Configuration**: API key in env (`PERPLEXITY_API_KEY`)

**Test Results**:
- `perplexity_search`: Web search with ranked results, metadata
- `perplexity_ask`: Conversational Q&A with citations
- `perplexity_reason`: Reasoning with `strip_thinking` option for context efficiency
- `perplexity_research`: Deep research with comprehensive multi-source synthesis

**Assessment**: Excellent research MCP. `strip_thinking=true` recommended for context savings.

---

### 7. Playwright MCP
**Package**: `@playwright/mcp@latest`
**Status**: **PASS** ✅

**Test Results**:
- `browser_navigate`: Navigated to example.com successfully
- `browser_snapshot`: YAML accessibility tree returned
- `browser_click`: Clicked link, navigated to IANA page
- `browser_close`: Clean tab closure

**Assessment**: Full browser automation. Tier 3 due to resource usage (~6K tokens).

---

### 8. GPTresearcher MCP
**Package**: Custom Python server (`gptr-mcp`)
**Status**: **PASS** ✅

**Resolution**: Python 3.13.11 venv (via uv) resolved dependency issues.

**Test Results**:
- `quick_search`: Fast web search (9 results in ~2s)
- `deep_research`: Comprehensive research with 16 sources, full context
- `get_research_sources`: Returns structured source list with URLs

**Configuration**:
- Location: `/Users/aircannon/Claude/gptr-mcp/`
- Env vars: `OPENAI_API_KEY`, `TAVILY_API_KEY`
- Python: `.venv/bin/python` (3.13.11)

**Assessment**: Powerful deep research. Complements Perplexity (quick) vs GPTresearcher (comprehensive).

---

## Tier Recommendations (Final)

| Tier | MCPs | Rationale |
|------|------|-----------|
| **Tier 1** (Always-On) | Memory, Filesystem, Fetch, Git | Core infrastructure (~8K total) |
| **Tier 2** (Task-Scoped) | DateTime, Wikipedia, Chroma, DesktopCommander, Perplexity, GPTresearcher, Brave, arXiv | Enable when task requires |
| **Tier 3** (Specialized) | Lotus Wisdom, Playwright | High resource or niche use cases |

---

## Validation Insights

### Key Discoveries

1. **Perplexity `strip_thinking`**: The `strip_thinking=true` parameter removes `<think>` tags from responses, significantly reducing token usage while preserving answer quality.

2. **GPTresearcher Python Version**: Requires Python 3.13+ for dependencies. Solution: Use `uv venv --python 3.13` to create isolated environment.

3. **Playwright Accessibility Snapshots**: `browser_snapshot` returns YAML accessibility tree with element refs (e.g., `[ref=e6]`). More efficient than screenshots for automation.

4. **Research MCP Complementarity**:
   - Perplexity: Fast, conversational, good for quick facts
   - GPTresearcher: Deep, comprehensive, 16+ sources synthesis
   - Brave Search: Simple web search, local business support

### Validation Harness Pattern Confirmation

The 5-phase validation pattern proved effective:
1. **Install**: `claude mcp add` with correct package
2. **Config**: API keys via `-e KEY=value`
3. **Inventory**: List tools, assess token cost
4. **Test**: Functional validation of key tools
5. **Tier**: Assign loading strategy

---

## Final Status

**10/10 MCPs validated in PR-8.5**:
- DateTime ✅
- DesktopCommander ✅
- Lotus Wisdom ✅
- Wikipedia ✅
- Chroma ✅
- Perplexity ✅
- Playwright ✅
- GPTresearcher ✅
- Brave Search ✅ (validated 2026-01-09)
- arXiv ✅ (validated 2026-01-09)

**Removed**: DuckDuckGo (bot detection unreliable)

---

*Validated: 2026-01-09 by Claude Opus 4.5*
