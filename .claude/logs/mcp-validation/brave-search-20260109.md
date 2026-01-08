# Brave Search MCP Validation Results

**Date**: 2026-01-09
**Status**: INSTALLED (Phase 4 pending restart)
**Tier Recommendation**: Tier 2 (Task-Scoped)

## Phase 1: Installation Verification

- [x] MCP registered in Claude (`brave-search` in mcp list)
- [x] Server connected: `npx -y @modelcontextprotocol/server-brave-search`
- [x] API key configured via `-e BRAVE_API_KEY=xxx`
- [x] No startup errors

## Phase 2: Configuration Audit

- [x] API key required: BRAVE_API_KEY
- [x] API key configured in MCP definition
- [x] No additional environment variables needed

**Configuration**:
```json
{
  "type": "stdio",
  "command": "npx",
  "args": ["-y", "@modelcontextprotocol/server-brave-search"],
  "env": {
    "BRAVE_API_KEY": "BSAoZko4YP0Iv_SY4LooTZMPrJk9vmn"
  }
}
```

**API Key Source**: `.claude/config/credentials.local.yaml`

## Phase 3: Tool Inventory

Expected tools (from official ModelContextProtocol repo):

| Tool | Purpose | Parameters |
|------|---------|------------|
| `brave_web_search` | General web search | query, count |
| `brave_local_search` | Local business search | query, location |

**Tool Count**: 2 (expected)
**Token Cost Estimate**: ~3K tokens

### Key Advantages Over DuckDuckGo
- API-based (not scraping) - no bot detection issues
- Official Anthropic-maintained server
- Rate limits enforced by API key, not bot detection
- More reliable for automation workflows

## Phase 4: Functional Tests

**Status**: BLOCKED - Tools Not Loaded

Despite MCP showing "Connected" in `claude mcp list`, Brave Search tools are NOT available in the session tool list.

### Discovery (2026-01-09)

**Observation**: Session has DuckDuckGo tools (`mcp__duckduckgo__duckduckgo_web_search`) but NOT Brave Search tools (`brave_web_search`, `brave_local_search`).

**Verified MCPs Connected**:
- `claude mcp list` shows: `brave-search: npx -y @modelcontextprotocol/server-brave-search - ✓ Connected`

**Tools Actually Available in Session**:
- Memory (9 tools) ✓
- Playwright (many tools) ✓
- Fetch (1 tool) ✓
- Git (12 tools) ✓
- Filesystem (13+ tools) ✓
- DuckDuckGo (1 tool) ✓
- Brave Search (0 tools) ✗
- arXiv (0 tools) ✗
- GitHub (0 tools) ✗
- Context7 (0 tools) ✗
- Sequential Thinking (0 tools) ✗

**Hypothesis**: Claude Code may have tool loading limits or prioritization. Some MCPs "connect" but don't inject tools into session.

### Planned Tests (When Tools Available)

1. **brave_web_search**: Query "Claude Code" → Expect formatted results
2. **brave_local_search**: Query local business → Expect structured results

## Phase 5: Tier Recommendation

**Recommended Tier**: Tier 2 (Task-Scoped)

**Justification**:
- API-based = reliable for automation
- Moderate token cost (~3K)
- Requires API key management
- Use when reliable web search needed
- Preferred over DuckDuckGo for critical workflows

## Overlap Analysis

| Capability | Brave Search | Alternative | Preference |
|------------|--------------|-------------|------------|
| Web search | brave_web_search | WebSearch (native) | Brave (API-based, reliable) |
| Web search | brave_web_search | DuckDuckGo MCP | **Brave** (no bot detection) |
| Local search | brave_local_search | None | Brave (unique capability) |

**Verdict**: Brave Search MCP should be the **primary MCP-based search** when external search is required. Native WebSearch is still preferred for general use, but Brave provides structured, reliable results for automation.

---

*Validated by MCP Validation Harness - PR-8.4*
*Functional testing: PENDING*
