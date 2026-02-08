---
name: web-fetch
version: 2.0.0
description: Web content retrieval using WebFetch, WebSearch, and curl
replaces: mcp__fetch, mcp__mcp-gateway__fetch
---

## Quick Reference

| Need | Tool | Notes |
|------|------|-------|
| Fetch web page | `WebFetch(url, prompt)` | HTML→markdown + AI processing |
| Search the web | `WebSearch("query")` | Include current year in queries |
| API call (JSON) | `Bash(curl -s URL \| jq)` | Full control, pre-allowed |
| Download file | `Bash(curl -sL -o file URL)` | Binary downloads |
| Authenticated URL | `ToolSearch` first | Check for specialized MCP |
| GitHub content | `Bash(gh ...)` | Prefer gh CLI for GitHub |

## Selection Rules

```
Need web content?
├── Known URL → WebFetch(url, prompt)
├── Search query → WebSearch("query")
├── REST API → Bash(curl -s URL | jq)
├── Authenticated → ToolSearch for specialized MCP
└── Download binary → Bash(curl -sL -o file URL)
```
