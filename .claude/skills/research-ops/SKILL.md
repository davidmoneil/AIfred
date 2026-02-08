---
name: research-ops
version: 1.0.0
description: >
  Multi-source research — web, academic, financial, AI-augmented.
  Use when: research, search, papers, citations, deep research, grounding.
replaces: brave-search, arxiv, wikipedia, context7, perplexity, gptresearcher MCPs
---

## Quick Reference

| Backend | Command | Key Path |
|---------|---------|----------|
| Web search (default) | `WebSearch("query")` | None (built-in) |
| Web page fetch | `WebFetch(url, prompt)` | None (built-in) |
| Brave Search | `curl -s -H "X-Subscription-Token: $KEY" "https://api.search.brave.com/res/v1/web/search?q=QUERY"` | `.search.brave` |
| arXiv papers | `curl -s "http://export.arxiv.org/api/query?search_query=QUERY&max_results=5"` | None (public) |
| Wikipedia | `curl -s "https://en.wikipedia.org/api/rest_v1/page/summary/TITLE"` | None (public) |
| PubMed | `curl -s "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?db=pubmed&term=QUERY&retmode=json&api_key=$KEY"` | `.research.ncbi_pubmed` |
| Context7 (lib docs) | `ToolSearch "+local-rag"` then query | `.rag.context7` |
| Alpha Vantage | `curl -s "https://www.alphavantage.co/query?function=FUNC&symbol=SYM&apikey=$KEY"` | `.research.alpha_vantage` |
| Octagon DeepSearch | API endpoint (see docs) | `.research.octagon_deepsearch` |

## Selection Rules

```
Research needed?
├── Quick web search → WebSearch (always first)
├── Known URL → WebFetch(url, prompt)
├── Academic papers → arXiv (CS/ML/physics) or PubMed (bio/med)
├── Encyclopedia facts → Wikipedia REST API
├── Local/news search → Brave Search API
├── Financial data → Alpha Vantage API
├── Library docs → Context7 via local-rag
├── Deep research → deep-research agent (Task tool)
└── Multi-source validation → Combine 2+ backends
```

## Credential Pattern

```bash
KEY=$(yq -r '.search.brave' .claude/secrets/credentials.yaml | head -1 | tr -d '[:space:]')
```

Pending backends: Perplexity (sonar models), GPTResearcher (autonomous). Keys not yet provisioned.
