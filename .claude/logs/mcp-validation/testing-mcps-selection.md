# Testing MCPs Selection for Validation Harness

**Date**: 2026-01-08
**Purpose**: Document MCPs selected to test the validation harness on fresh installs

---

## Selection Criteria

1. Multiple tools (to test tool inventory phase)
2. Variety of configuration complexity (API key vs no key)
3. Immediate utility to Jarvis workflows
4. From PR-8 Stage 1 backlog (prioritized)

---

## Selected Testing MCPs

### 1. DuckDuckGo MCP (Primary Test)

**Repository**: https://github.com/nickclyde/duckduckgo-mcp-server
**Tools**: 2
**Configuration**: None (no API key)
**Stage**: 1 (Priority)

| Tool | Purpose |
|------|---------|
| search | Web search via DuckDuckGo |
| fetch_content | Extract webpage content |

**Why Selected**:
- Simplest installation (no API key)
- Tests basic harness workflow
- Stage 1 priority in roadmap
- Overlap test with existing Fetch MCP

**Expected Tier**: 2 (Task-Scoped)

---

### 2. Brave Search MCP (Complex Test)

**Repository**: https://github.com/modelcontextprotocol/servers/tree/main/src/brave-search
**Tools**: 6
**Configuration**: API key required (BRAVE_API_KEY)
**Stage**: 1 (Priority)

| Tool | Purpose |
|------|---------|
| brave_web_search | General web search |
| brave_local_search | Local business search |
| brave_video_search | Video search |
| brave_image_search | Image search |
| brave_news_search | News search |
| brave_summarizer | Content summarization |

**Why Selected**:
- Tests API key configuration validation
- Multiple specialized tools (tests inventory phase)
- Tests external service dependency handling
- Higher utility than DuckDuckGo (more tools)

**Expected Tier**: 2 (Task-Scoped)

---

### 3. arXiv MCP (Research Utility Test)

**Repository**: https://github.com/kelvingao/mcp-arxiv-server
**Tools**: 4
**Configuration**: None (no API key)
**Stage**: Not in original backlog (bonus)

| Tool | Purpose |
|------|---------|
| search_papers | Search arXiv papers |
| download_paper | Download paper PDF |
| list_papers | List papers from search |
| read_paper | Read paper content |

**Why Selected**:
- Tests research/documentation workflow utility
- Different domain than web search
- Tests PDF handling capability
- Useful for deep-research agent workflows

**Expected Tier**: 3 (Triggered) or 2 (Task-Scoped)

---

## Test Sequence

```
1. DuckDuckGo MCP  → Baseline harness test (simple)
2. Brave Search MCP → API key config test (complex)
3. arXiv MCP       → Domain-specific utility test
```

## Success Criteria

For each MCP:
- [ ] Installation completes without errors
- [ ] All tools discovered and inventoried
- [ ] At least one tool passes functional test
- [ ] Token cost measured
- [ ] Tier recommendation generated
- [ ] Validation log created
- [ ] Capability matrix updated (if validated)

---

## Installation Commands (For Reference)

```bash
# DuckDuckGo MCP
npx -y @smithery/cli install @nickclyde/duckduckgo-mcp-server --client claude

# Brave Search MCP
# Requires BRAVE_API_KEY environment variable
claude mcp add brave-search npx -y @anthropic/mcp-brave-search

# arXiv MCP
claude mcp add arxiv npx -y mcp-arxiv-server
```

---

*Testing MCPs Selection - PR-8.4 Validation Harness*
