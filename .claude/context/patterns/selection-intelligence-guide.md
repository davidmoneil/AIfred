# Selection Intelligence Guide

**Version**: 1.0 | **PR Reference**: PR-9.1 | **Updated**: 2026-01-09

Quick reference for tool/agent/MCP selection. For comprehensive theory: @tool-selection-intelligence.md

---

## Quick Selection Matrix

| Task Type | First Choice | Fallback | Avoid |
|-----------|--------------|----------|-------|
| Read/write files | Built-in (Read/Write/Edit) | Filesystem MCP | Bash cat/echo |
| Search files | Glob, Grep | Explore subagent | Bash find |
| Understand code | Explore subagent | Grep + Read | — |
| Plan implementation | Plan subagent | EnterPlanMode | — |
| Git operations | Bash + Git MCP | gh CLI | — |
| GitHub PRs/Issues | GitHub MCP | gh CLI | — |
| Web page fetch | WebFetch | Fetch MCP | curl |
| Quick fact lookup | WebSearch | perplexity_search | — |
| Deep research | deep-research agent | gptresearcher | WebSearch |
| Create documents | docx/xlsx/pdf/pptx skills | Write (plain text) | — |
| Browser automation | browser-automation plugin | Playwright MCP | — |
| Docker deployment | docker-deployer agent | Bash | — |
| Troubleshooting | service-troubleshooter agent | direct diagnosis | — |

---

## Research Tool Routing

```
Research Task
    │
    ├─ Quick fact? ──────────► WebSearch or perplexity_search
    │
    ├─ Current events? ──────► brave_web_search
    │
    ├─ Q&A with citations? ──► perplexity_ask
    │
    ├─ Academic paper? ──────► arxiv_search + download
    │
    ├─ Reference article? ───► wikipedia_search
    │
    ├─ Multi-source (4-8)? ──► perplexity_research
    │
    └─ Comprehensive (16+)? ─► gptresearcher_deep_research
```

| Tool | Speed | Depth | Best For |
|------|-------|-------|----------|
| `WebSearch` | Fast | Shallow | Quick facts, built-in |
| `perplexity_search` | Fast | Shallow | AI-curated snippets |
| `brave_web_search` | Fast | Shallow | Current events |
| `perplexity_ask` | Fast | Medium | Q&A with citations |
| `wikipedia_search` | Fast | Medium | Reference lookup |
| `perplexity_research` | Medium | Deep | Multi-source synthesis |
| `arxiv_search` | Medium | Deep | Academic papers |
| `gptresearcher` | Slow | Very Deep | Comprehensive (16+ sources) |

---

## Agent Selection

### When to Delegate vs Self-Execute

| Condition | Decision |
|-----------|----------|
| 1-3 simple operations | **Self-execute** |
| Context would bloat (large file scans) | **Delegate** to subagent |
| Need procedural insight retained | **Delegate + summary** |
| Domain expertise needed | **Custom agent** |
| Code exploration | **Explore subagent** |
| Architecture planning | **Plan subagent** |

### Agent Inventory

| Agent Type | Example | Use When |
|------------|---------|----------|
| **Built-in Subagents** | Explore, Plan, general-purpose | Quick tasks, context isolation |
| **Custom Agents** | deep-research, docker-deployer | Domain expertise, structured workflow |
| **Plugin Agents** | feature-dev:code-architect | Feature development phases |

---

## MCP Loading Tiers

| Tier | MCPs | Loading |
|------|------|---------|
| **1 - Always On** | memory, filesystem, fetch, git | Never disable |
| **2 - Task Scoped** | github, context7, perplexity, brave-search, arxiv, wikipedia, chroma, datetime, gptresearcher, desktop-commander | Enable via suggest-mcps.sh |
| **3 - Heavy** | playwright, lotus-wisdom | Enable only when needed |

**Control**: `.claude/scripts/enable-mcps.sh`, `disable-mcps.sh`

---

## Skill Selection

| Category | Skills | When to Use |
|----------|--------|-------------|
| **Documents** | docx, xlsx, pdf, pptx | Creating formatted documents |
| **Development** | mcp-builder, skill-creator | Building MCPs or skills |
| **Session** | session-management | Start/end sessions |

**Trigger**: Skills auto-trigger based on YAML `when_to_use` in frontmatter.

---

## Conflict Resolution

| Conflict | Resolution |
|----------|------------|
| Bash vs built-in | Use built-in (Read, Write, Glob, Grep) |
| WebFetch vs Fetch MCP | WebFetch (built-in, converts to markdown) |
| browser-automation vs Playwright | browser-automation for NL, Playwright for deterministic |
| perplexity vs gptresearcher | perplexity fast, gptresearcher comprehensive |
| Custom agent vs subagent | Custom for domain expertise, subagent for quick tasks |

---

## Fallback Chains

```
File Operations:    Built-in → Filesystem MCP → Bash
Git Operations:     Bash(git) → Git MCP
GitHub Operations:  GitHub MCP → gh CLI → Web UI
Research:           WebSearch → perplexity → gptresearcher
Documents:          Skills → Write (plain text)
Browser:            browser-automation → Playwright → WebFetch
```

---

## Related Documentation

- @capability-map.yaml — Full task-to-tool mapping
- @agent-selection-pattern.md — Agent decision details
- @tool-selection-intelligence.md — Comprehensive theory
- @mcp-loading-strategy.md — MCP tier management

---

*Selection Intelligence Guide v1.0 — 2026-01-09*
