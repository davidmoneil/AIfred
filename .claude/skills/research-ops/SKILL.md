---
name: research-ops
version: 2.1.0
description: >
  Multi-source research — web, academic, financial, AI-augmented, scraping.
  Use when: research, search, papers, citations, deep research, grounding, scrape, crawl.
replaces: brave-search, arxiv, wikipedia, context7, perplexity, gptresearcher MCPs
---

## Quick Reference

| Backend | Script / Tool | Key Path | Status |
|---------|--------------|----------|--------|
| Web search (default) | `WebSearch("query")` | None (built-in) | Active |
| Web page fetch | `WebFetch(url, prompt)` | None (built-in) | Active |
| Brave Search | `scripts/search-brave.sh "query"` | `.search.brave` | Active |
| arXiv papers | `scripts/search-arxiv.sh "query"` | None (public) | Active |
| Wikipedia | `scripts/fetch-wikipedia.sh "Title"` | None (public) | Active |
| Perplexity (AI search) | `scripts/search-perplexity.sh "query"` | `.llm.perplexity` | Active |
| Tavily Search | `curl` (see credential pattern below) | `.search.tavily` | Template |
| Serper (Google SERP) | `curl` (see credential pattern below) | `.search.serper` | Template |
| SerpAPI | `curl` (see credential pattern below) | `.search.serpapi` | Template |
| PubMed | `curl` (see credential pattern below) | `.research.ncbi_pubmed` | Template |
| Firecrawl (scrape) | `curl` (see credential pattern below) | `.search.firecrawl` | Template |
| ScraperAPI | `curl` (see credential pattern below) | `.search.scraper_api` | Template |
| Alpha Vantage | `curl` (see credential pattern below) | `.research.alpha_vantage` | Template |
| Context7 (lib docs) | `scripts/fetch-context7.sh "lib" "topic"` | `.rag.context7` | Partial |
| GPTResearcher | `scripts/deep-research-gpt.sh "question"` | TBD | Blocked |

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

## Scripts (`scripts/`)

All scripts: `--help` for usage, structured JSON output, credential extraction via `_common.sh`.

| Script | Features |
|--------|----------|
| `search-brave.sh` | `--type web\|news\|videos\|images`, `--freshness`, `--count` |
| `search-arxiv.sh` | `--max`, `--category`, `--author`, `--sort date\|relevance` |
| `fetch-wikipedia.sh` | `--lang`, `--mode summary\|full`, `--search` |
| `search-perplexity.sh` | `--model sonar\|sonar-pro\|sonar-reasoning\|sonar-deep-research` |
| `fetch-context7.sh` | Workflow doc — requires local-rag MCP |
| `deep-research-gpt.sh` | Workflow doc — blocked, key not provisioned |

## Credential Pattern

```bash
KEY=$(yq -r '.search.brave' .claude/secrets/credentials.yaml | head -1 | tr -d '[:space:]')
```

## Validation

```bash
bash scripts/test-all.sh          # Full suite (requires API keys)
bash scripts/test-all.sh --quick  # Public APIs only (arxiv, wikipedia)
```
