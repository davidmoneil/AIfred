# Search API Research Notes

**Created**: 2026-01-09
**Purpose**: Reference for future web search MCP options

---

## Current Recommended Search Options

| Option | Type | Cost | Reliability |
|--------|------|------|-------------|
| **Native WebSearch** | Built-in | Free | High |
| **Brave Search MCP** | API | Free tier available | High |
| **arXiv MCP** | API | Free | High (academic) |

---

## Google Custom Search API

**Status**: Available, stable for 2026

### Setup Requirements
1. Create project in Google Cloud Console
2. Enable "Custom Search API"
3. Create Programmable Search Engine (get Search Engine ID)
4. Generate API key

### Free Tier Limits
- **Daily Queries**: 100 free per day (~3,000/month)
- **Excess Usage**: $5 per 1,000 queries
- **Max**: 10,000 queries/day on basic tier
- **Results**: Limited to 10 per page (may need multiple queries)

### MCP Servers Available
- `gradusnikov/google-search-mcp-server` — Dedicated Google Custom Search
- `zoharbabin/google-research-mcp` — Advanced version with YouTube scraping + AI synthesis
- `google/mcp` — Official Google templates for Workspace/Cloud integrations

### Special Features
- Vision tools and reverse image search capabilities
- Well-documented API
- Stable long-term support

### Jarvis Status
- **API Key**: Available (unrestricted access key in Google Cloud Console)
- **Implementation**: Not yet configured

---

## Bing Search (Grounding with Bing Search)

**Status**: Replaced standard API (retired August 11, 2025)

### Important Changes
- Standard Bing Search API retired August 11, 2025
- Replaced by "Grounding with Bing Search" in Azure AI Foundry
- Designed specifically for AI agent integration

### Setup Requirements
1. Azure AI Foundry account (formerly Azure Cognitive Services)
2. Create "Grounding with Bing Search" resource
3. Owner/Contributor role in subscription
4. **Paid Azure subscription required** (no free credit/sponsored accounts)

### Free Tier Limits
- **Monthly Transactions**: 1,000 free
- **Rate Limit**: 1 transaction per second
- **Paid Pricing**: $14 per 1,000 transactions (as of Jan 1, 2026)

### Key Differences from Standard API
- AI-managed execution (model decides when to search)
- Built-in citations/hyperlinks (legally required)
- Two modes:
  - **Grounding with Bing Search**: Full public web access
  - **Grounding with Bing Custom Search**: Limited to specific domains

### MCP Servers Available
- `leehanchung/bing-search-mcp` — Community Python implementation
- `yokingma/one-search-mcp` — Multi-engine (includes Bing)
- Official PulseMCP Mirror — Standardized community version

### Implementation Notes
- Requires Azure AI Project Client SDK
- Only specific Azure OpenAI models support native grounding
- Must display citations exactly as provided by Microsoft
- Does NOT work behind VPNs or private endpoints

### Jarvis Status
- **API Key**: Not configured (requires Azure AI Foundry setup)
- **Complexity**: Higher than Google (Azure setup required)
- **Priority**: Lower (Google recommended for high-frequency research)

---

## OneSearch MCP (Multi-Engine)

**Package**: `yokingma/one-search-mcp`

### Features
- Multiple engines: SearXNG, Firecrawl, Tavily, DuckDuckGo, Bing
- **Local browser fallback** (puppeteer-core) — no API keys needed
- Tools: `one_search`, `one_scrape`, `one_map`

### Installation
```bash
npx -y @smithery/cli install @yokingma/one-search --client claude
# OR manual:
claude mcp add one-search -- npx -y one-search-mcp
```

### Configuration
- `SEARCH_PROVIDER=local` — Uses actual browser automation
- `SEARCH_PROVIDER=duckduckgo|bing|tavily|searxng`
- `SEARCH_API_KEY` — For Tavily/Bing

### Jarvis Status
- **Not installed** (candidate for future testing)

---

## Comparison Summary

| Feature | Google | Bing (Grounding) | OneSearch |
|---------|--------|------------------|-----------|
| Free Quota | 100/day (~3K/mo) | 1K/month | Unlimited (local) |
| Daily Rate | 100 | ~33 | Unlimited |
| Setup Ease | Medium (GCP) | High (Azure) | Low |
| API Key | Available | Not configured | Optional |
| Best For | High-frequency | AI grounding | Fallback/scraping |

---

## Recommendations

1. **Primary**: Native WebSearch + Brave Search MCP (current)
2. **Academic**: arXiv MCP (current)
3. **Future**: Google Custom Search API (when higher volume needed)
4. **Fallback**: OneSearch MCP with local browser (if APIs fail)

---

*Research compiled 2026-01-09 for PR-8.4 MCP Validation*
