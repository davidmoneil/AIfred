# DuckDuckGo MCP Validation Results

**Date**: 2026-01-08 (Updated 2026-01-09)
**Status**: VALIDATED WITH ISSUES
**Tier Recommendation**: Tier 3 (Triggered) — Downgraded due to reliability issues

## Phase 1: Installation Verification

- [x] MCP registered in Claude (`duckduckgo` in mcp list)
- [x] Server connected: `npx -y duckduckgo-mcp-server`
- [x] Configuration in ~/.claude.json (project scope)
- [x] No startup errors

## Phase 2: Configuration Audit

- [x] No API keys required
- [x] No environment variables needed
- [x] No external service authentication
- [x] Public DuckDuckGo API access

**Configuration**:
```json
{
  "type": "stdio",
  "command": "npx",
  "args": ["-y", "duckduckgo-mcp-server"],
  "env": {}
}
```

## Phase 3: Tool Inventory

| Tool | Purpose | Parameters | Status |
|------|---------|------------|--------|
| `duckduckgo_web_search` | DuckDuckGo web search | query (str), count (int) | Available |

**Tool Count**: 1 (actual exposed tool)
**Token Cost Estimate**: ~2K tokens

**Note**: Documentation mentions `fetch_content` but only `duckduckgo_web_search` is exposed as an MCP tool.

### Features
- Rate limiting built-in (30 searches/min, 20 fetches/min)
- LLM-friendly output formatting
- Content cleaning (removes ads, cleans URLs)
- Comprehensive error handling

## Phase 4: Functional Tests

**Status**: COMPLETED WITH FAILURES

### Test 1: duckduckgo_web_search
```
Input: query="Claude Code MCP server", count=3
Output: ERROR - "DDG detected an anomaly in the request, you are likely making requests too quickly."
Result: FAIL - Rate limited by DuckDuckGo
```

### Test 2: duckduckgo_web_search (retry after 3s delay)
```
Input: query="anthropic claude", count=3
Output: ERROR - Same rate limit error
Result: FAIL - Persistent rate limiting
```

### Critical Finding

**DuckDuckGo's bot detection is triggering on fresh requests**, not just rate-limited ones. This is a known issue with DuckDuckGo's aggressive anti-bot measures. The MCP's internal rate limiting (30/min) cannot prevent DuckDuckGo's server-side detection.

**Reliability**: LOW - Cannot guarantee successful searches even with proper delays.

## Phase 5: Tier Recommendation

**Recommended Tier**: Tier 3 (Triggered) — DOWNGRADED

**Original Assessment**: Tier 2 (Task-Scoped)

**Revised Justification**:
- ❌ Unreliable due to DuckDuckGo bot detection
- ✅ Low token cost (~2K)
- ❌ Cannot be depended on for research tasks
- ✅ No API key = easy enable/disable
- ❌ Rate limiting doesn't prevent DDG server-side blocks

**Recommendation**: Consider removal or replacement with Brave Search MCP (requires API key but more reliable).

## Overlap Analysis

| Capability | DuckDuckGo MCP | Alternative | Preference |
|------------|----------------|-------------|------------|
| Web search | duckduckgo_web_search | WebSearch (native) | **WebSearch** (reliable, no bot detection) |

**Verdict**: DuckDuckGo MCP is NOT recommended due to reliability issues. Native WebSearch tool is strongly preferred. Consider Brave Search MCP as alternative if API-based search is needed.

## Harness Validation Notes

**Discoveries from this validation**:

1. **MCPs installed mid-session require restart** for tools to appear
   - `claude mcp list` shows "Connected" immediately
   - Tools not in session until restart

2. **Documentation vs Reality gap**
   - Docs mention 2 tools (search, fetch_content)
   - Only 1 tool actually exposed (duckduckgo_web_search)

3. **External service reliability matters**
   - MCP can be "working" but external service blocks requests
   - Validation must test actual external service behavior

---

*Validated by MCP Validation Harness - PR-8.4*
*Functional testing: COMPLETE (FAIL)*
