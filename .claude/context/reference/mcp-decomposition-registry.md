# MCP Decomposition Registry

**Purpose**: Master tracking of all MCP servers analyzed and/or phagocytosed into skills.
**Created**: 2026-02-07
**Updated**: 2026-02-07

---

## Discovery Summary (M1)

### MCP Process Inventory

| MCP Server | Process Type | Config Location | Status |
|-----------|-------------|-----------------|--------|
| `filesystem` | npm (npx) | `.mcp.json` lines 3-16 | Active, 15 deferred tools |
| `local-rag` | npm (npx) | `.mcp.json` lines 17-27 | Configured, 0 usage found |
| `memory` | npm (npx) | Auto-provisioned by Claude Code | Active, used by hooks |
| `fetch` | Python (uvx) | Auto-provisioned by Claude Code | Active, minimal usage |
| `git` | Python (uvx) | Auto-provisioned by Claude Code | Active, `--repository` flag |
| `weather` | curl (embedded) | `session-start.sh` lines 83-107 | Inline, not MCP |

### Auto-Provisioned MCP Architecture

Claude Code auto-provisions git, fetch, and memory servers. They appear in the tool namespace as `mcp__mcp-gateway__*` (memory/fetch) and `mcp__git__*`. These are NOT configured via `.mcp.json` or any user-editable config — they're built into Claude Code's runtime.

**Implication**: Cannot "remove" auto-provisioned MCPs via config deletion. Instead:
- Remove permission entries from `~/.claude/settings.json` (stops auto-allow)
- Create skills that redirect to built-in tools (preferred path)
- MCPs still load as deferred tools but won't be invoked if skills guide correctly

### Permission Entries (Global Settings)

From `~/.claude/settings.json`:
```
Line 68: "mcp__mcp-gateway__read_graph"    → Memory (RETAIN)
Line 69: "mcp__mcp-gateway__search_nodes"  → Memory (RETAIN)
Line 70: "mcp__mcp-gateway__open_nodes"    → Memory (RETAIN)
Line 71: "mcp__mcp-gateway__fetch"         → Fetch  (DECOMPOSE)
```

---

## Decomposition Status

| MCP | Status | Replacement | Skill File | Token Impact | Date |
|-----|--------|-------------|-----------|-------------|------|
| `filesystem` | DECOMPOSED | `filesystem-ops` skill | `.claude/skills/filesystem-ops/SKILL.md` | ~2.8K saved | 2026-02-07 |
| `git` | DECOMPOSED | `git-ops` skill | `.claude/skills/git-ops/SKILL.md` | ~2.5K saved | 2026-02-07 |
| `fetch` | DECOMPOSED | `web-fetch` skill | `.claude/skills/web-fetch/SKILL.md` | ~0.5K saved | 2026-02-07 |
| `weather` (curl) | DECOMPOSED | `weather` skill | `.claude/skills/weather/SKILL.md` | 0 (was inline) | 2026-02-07 |
| `memory` | RETAINED | Unique: knowledge graph | N/A | N/A | 2026-02-07 |
| `local-rag` | RETAINED | Unique: vector DB/embeddings (dormant) | N/A | N/A | 2026-02-07 |

### Retention Rationale

**Memory MCP** — RETAIN:
- Provides unique knowledge graph capabilities (entities, relations, observations)
- Actively used by hooks (`self-correction-capture.js`, `audit-logger.js`)
- No built-in equivalent exists
- Low token cost (~1.8K for 9 tools)

**Local-RAG MCP** — RETAIN (dormant):
- Provides server-side embeddings and vector database search
- Currently 0 invocations in codebase (dormant)
- No built-in equivalent exists
- Keep for future use; low cost since deferred-loaded

---

## Phagocytosis Workflow

For future MCP evaluations, follow this checklist:

1. **Check this registry** — already analyzed?
2. **Inventory tools** — list all MCP tools and their capabilities
3. **Map to built-ins** — can each tool be replaced by Read/Write/Edit/Glob/Grep/Bash/WebFetch/WebSearch?
4. **Unique capabilities?** — if MCP provides something no built-in can, RETAIN
5. **Create skill** — document the mapping in a SKILL.md
6. **Validate** — test each replaced tool path
7. **Remove/disable** — update configs, permissions, references
8. **Measure** — run /context before and after for token delta
9. **Update this registry** — record status, savings, date

---

*MCP Decomposition Registry v1.0 — Phagocytosis Workflow Established*
