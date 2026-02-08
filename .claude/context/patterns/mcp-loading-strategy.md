# MCP Loading Strategy Pattern

**Created**: 2026-01-02
**Updated**: 2026-02-07 (v3.0 — Post-Decomposition)
**Version**: 3.0
**Status**: Active
**Applies To**: Jarvis, all Claude Code projects

---

## Overview

Post-decomposition (v5.9.0), only 5 MCPs remain. Tier 2/3 MCPs have been phagocytosed into built-in skills or removed entirely. The loading strategy is now simple: all MCPs are always-on or deferred.

## Active MCPs (5 total)

| MCP | Type | Token Cost | Purpose |
|-----|------|-----------|---------|
| memory | Active | ~1.8K | Persistent knowledge graph (9 tools) |
| local-rag | Deferred | ~0 idle | Vector DB/embeddings (6 tools) |
| playwright | Deferred | ~0 idle | Browser automation |
| fetch | Auto-provisioned | ~0 idle | Web content (shadowed by web-fetch skill) |
| git | Auto-provisioned | ~0 idle | Git operations (shadowed by git-ops skill) |

**Total idle cost**: ~1.8K tokens (memory only; all others deferred via ToolSearch)

## Skill Replacements

Skills redirect to built-in tools, making MCPs unnecessary:

| Former MCP | Skill | Tools Used |
|-----------|-------|-----------|
| filesystem (15 tools) | `filesystem-ops` | Read, Write, Edit, Glob, Grep, Bash |
| git (12 tools) | `git-ops` | Bash(git *) |
| fetch (1 tool) | `web-fetch` | WebFetch, WebSearch, Bash(curl) |
| weather (curl) | `weather` | Bash(curl wttr.in) |

## Loading Deferred MCP Tools

When a deferred MCP tool is needed, use ToolSearch:
```
ToolSearch "+<mcp-name>"          # Find tools from specific MCP
ToolSearch "select:<tool_name>"   # Load specific tool by name
```

## Re-Adding Removed MCPs

Any removed MCP can be restored:
```bash
claude mcp add <name> -- npx -y <package>
# Then /clear or restart session
```

See `.claude/context/reference/mcp-decomposition-registry.md` for full removal history and re-add commands.

## Pipeline for New MCPs

Before adding a new MCP, follow the MCP-to-Skill Pipeline:
1. Can built-in tools cover the use case?
2. If yes → create skill, skip MCP
3. If no (unique capability) → add MCP, register in capability-map.yaml
4. Measure token impact via statusline-input.json

---

*MCP Loading Strategy Pattern v3.0 — Post-Decomposition (2026-02-07)*
