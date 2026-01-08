# Brave Search MCP Validation - Deferred

**Date**: 2026-01-09
**Status**: DEFERRED (API key required)
**Tier Recommendation**: Tier 2 (Task-Scoped) — Expected

## Reason for Deferral

Brave Search MCP requires `BRAVE_API_KEY` environment variable.
No API key currently configured.

## Phase 1: Prerequisites Check

- [ ] BRAVE_API_KEY environment variable set
- [ ] Brave Search API account created (https://brave.com/search/api/)

## Expected Configuration

```bash
# Set API key
export BRAVE_API_KEY="your-api-key-here"

# Install MCP
claude mcp add brave-search -- npx -y @anthropic/mcp-brave-search
```

## Expected Tools (from documentation)

| Tool | Purpose |
|------|---------|
| brave_web_search | General web search |
| brave_local_search | Local business search |
| brave_video_search | Video search |
| brave_image_search | Image search |
| brave_news_search | News search |
| brave_summarizer | Content summarization |

**Tool Count**: 6
**Token Cost Estimate**: ~3K tokens

## Harness Validation Notes

**Discovery**: API key validation is a critical Phase 2 step:
- MCPs with required API keys should be flagged during installation
- Harness should check env vars before proceeding to Phase 3+
- Deferral is appropriate response to missing prerequisites

## Action Items

1. Obtain Brave Search API key
2. Configure BRAVE_API_KEY environment variable
3. Run full validation harness

---

*Validation deferred by MCP Validation Harness - PR-8.4*
