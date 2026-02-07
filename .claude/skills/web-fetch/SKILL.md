---
name: web-fetch
version: 1.0.0
description: Web content retrieval using built-in WebFetch and WebSearch instead of fetch MCP
category: infrastructure
tags: [web, fetch, search, url, api, built-in]
created: 2026-02-07
replaces: mcp__fetch, mcp__mcp-gateway__fetch
---

# Web Fetch Skill

Maps fetch MCP tools to built-in equivalents. Use `WebFetch` for known URLs, `WebSearch` for queries, and `Bash(curl)` for APIs.

---

## Quick Reference

| Need | Built-in Tool | Example |
|------|--------------|---------|
| Fetch web page | `WebFetch` | `WebFetch(url, "extract main content")` |
| Search the web | `WebSearch` | `WebSearch("query terms")` |
| API call (JSON) | `Bash(curl)` | `Bash("curl -s https://api.example.com/data")` |
| Download file | `Bash(curl -o)` | `Bash("curl -sL -o file.zip URL")` |
| Authenticated URL | Check for specialized MCP | Use `ToolSearch` first |

---

## Tool Mapping (MCP → Built-in)

| MCP Tool | Built-in Replacement | Notes |
|----------|---------------------|-------|
| `mcp__fetch__fetch` | `WebFetch` | HTML→markdown + AI processing |
| `mcp__mcp-gateway__fetch` | `WebFetch` | Same capability |

---

## Selection Rules

```
Need web content?
├── Known URL (web page) → WebFetch(url, prompt)
│   └── Returns markdown + AI-processed response
├── Search query → WebSearch("query")
│   └── Returns search results with links
├── API endpoint (JSON) → Bash(curl -s URL | jq)
│   └── Full control over headers, auth, parsing
├── Authenticated service → ToolSearch first
│   └── Check for specialized MCP (Google, Jira, etc.)
└── Download binary → Bash(curl -sL -o file URL)
```

---

## WebFetch Details

- Converts HTML to markdown automatically
- Processes content with AI model using your prompt
- 15-minute cache for repeated requests
- HTTP auto-upgraded to HTTPS
- For GitHub URLs, prefer `gh` CLI instead

**Prompt tips**: Be specific about what you want extracted.
- Good: "Extract the API authentication section and list all endpoints"
- Bad: "Tell me about this page"

---

## WebSearch Details

- Returns search results with titles, snippets, and URLs
- Include the current year in queries for recent information
- Supports domain filtering (allowed/blocked domains)
- Always cite sources in responses

---

## Bash(curl) for APIs

For REST API calls with full control:

```bash
# GET with JSON parsing
curl -s "https://api.example.com/data" | jq '.results[]'

# POST with body
curl -s -X POST -H "Content-Type: application/json" \
  -d '{"key": "value"}' "https://api.example.com/endpoint"

# With auth header
curl -s -H "Authorization: Bearer $TOKEN" "https://api.example.com/secure"
```

Pre-allowed in settings: `Bash(curl:*)`, `Bash(wget:*)`

---

*Replaces: mcp-server-fetch + mcp__mcp-gateway__fetch — Phagocytosed 2026-02-07*
