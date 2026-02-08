---
name: research-ops
version: 2.0.0
description: >
  Multi-source research — web, academic, financial, AI-augmented, scraping.
  Use when: research, search, papers, citations, deep research, grounding, scrape, crawl.
replaces: brave-search, arxiv, wikipedia, context7, perplexity, gptresearcher MCPs
---

## Quick Reference

| Backend | Command | Key Path |
|---------|---------|----------|
| Web search (default) | `WebSearch("query")` | None (built-in) |
| Web page fetch | `WebFetch(url, prompt)` | None (built-in) |
| Brave Search | `curl -s -H "X-Subscription-Token: $KEY" "https://api.search.brave.com/res/v1/web/search?q=QUERY"` | `.search.brave` |
| Tavily Search | `curl -s -X POST "https://api.tavily.com/search" -H "Content-Type: application/json" -d '{"api_key":"$KEY","query":"QUERY","search_depth":"advanced"}'` | `.search.tavily` |
| Serper (Google SERP) | `curl -s -X POST "https://google.serper.dev/search" -H "X-API-KEY: $KEY" -d '{"q":"QUERY"}'` | `.search.serper` |
| SerpAPI | `curl -s "https://serpapi.com/search.json?q=QUERY&api_key=$KEY"` | `.search.serpapi` |
| Perplexity (AI search) | `curl -s -X POST "https://api.perplexity.ai/chat/completions" -H "Authorization: Bearer $KEY" -d '{"model":"sonar","messages":[{"role":"user","content":"QUERY"}]}'` | `.llm.perplexity` |
| arXiv papers | `curl -s "https://export.arxiv.org/api/query?search_query=QUERY&max_results=5"` | None (public) |
| Wikipedia | `curl -s "https://en.wikipedia.org/api/rest_v1/page/summary/TITLE"` | None (public) |
| PubMed | `curl -s "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?db=pubmed&term=QUERY&retmode=json&api_key=$KEY"` | `.research.ncbi_pubmed` |
| Firecrawl (scrape) | `curl -s -X POST "https://api.firecrawl.dev/v1/scrape" -H "Authorization: Bearer $KEY" -d '{"url":"URL"}'` | `.search.firecrawl` |
| ScraperAPI | `curl -s "https://api.scraperapi.com?api_key=$KEY&url=URL"` | `.search.scraper_api` |
| Alpha Vantage | `curl -s "https://www.alphavantage.co/query?function=FUNC&symbol=SYM&apikey=$KEY"` | `.research.alpha_vantage` |
| Context7 (lib docs) | `ToolSearch "+local-rag"` then query | `.rag.context7` |
| Octagon DeepSearch | API endpoint (see docs) | `.research.octagon_deepsearch` |

## Selection Rules

```
Research needed?
├── Quick web search → WebSearch (always first, free)
├── Known URL → WebFetch(url, prompt)
├── Structured SERP → Serper or SerpAPI (Google results as JSON)
├── AI-augmented search → Perplexity sonar (citations + synthesis)
├── Deep/advanced search → Tavily (search_depth: advanced)
├── Academic papers → arXiv (CS/ML/physics) or PubMed (bio/med)
├── Encyclopedia facts → Wikipedia REST API
├── Local/news/video → Brave Search API (freshness filters)
├── Financial data → Alpha Vantage API
├── Library docs → Context7 via local-rag
├── Scrape full page → Firecrawl (JS-rendered) or ScraperAPI (proxy)
├── Deep research → deep-research agent (Task tool)
└── Multi-source validation → Combine 2+ backends
```

## Credential Pattern

```bash
KEY=$(yq -r '.search.brave' .claude/secrets/credentials.yaml | head -1 | tr -d '[:space:]')
# Perplexity is under .llm (LLM API, not search):
PPLX=$(yq -r '.llm.perplexity' .claude/secrets/credentials.yaml | head -1 | tr -d '[:space:]')
```

## Perplexity Models

| Model | Use Case |
|-------|----------|
| `sonar` | Quick factual search with citations |
| `sonar-pro` | Complex multi-step research |
| `sonar-reasoning` | Analysis requiring chain-of-thought |
| `sonar-deep-research` | Autonomous deep investigation (slow, thorough) |

**Validated 2026-02-08**: arXiv, Wikipedia, Brave, Perplexity all tested OK.
Pending: GPTResearcher (autonomous multi-source). Key not yet provisioned.
