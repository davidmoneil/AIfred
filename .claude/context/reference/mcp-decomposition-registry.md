# MCP Decomposition Registry

**Purpose**: Master tracking of all MCP servers analyzed and/or phagocytosed into skills.
**Created**: 2026-02-07
**Updated**: 2026-02-07 (v2.0 — actual removal completed)

---

## Discovery Summary (M1)

### MCP Process Inventory (Pre-Decomposition)

| MCP Server | Process Type | Config Location | Original Status |
|-----------|-------------|-----------------|--------|
| `filesystem` | npm (npx) | `.claude.json` (project) | Removed — 15 deferred tools |
| `local-rag` | npm (npx) | `.mcp.json` (project root) | RETAINED — dormant, deferred |
| `memory` | npm (npx) | Auto-provisioned by Claude Code | RETAINED — unique capability |
| `fetch` | Python (uvx) | Auto-provisioned by Claude Code | Auto-provisioned — shadowed by skill |
| `git` | Python (uvx) | Auto-provisioned by Claude Code | Auto-provisioned — shadowed by skill |
| `weather` | curl (embedded) | `session-start.sh` lines 83-107 | Skill-ified — was never an MCP |
| `github` | npm (npx) | `.claude.json` (project) | Removed — use `gh` CLI |
| `context7` | npm (npx) | `.claude.json` (project) | Removed — rarely used |
| `sequential-thinking` | npm (npx) | `.claude.json` (project) | Removed — Claude thinks natively |
| `arxiv` | Python (uvx) | `.claude.json` (project) | Removed — use WebFetch |
| `brave-search` | npm (npx) | `.claude.json` (project) | Removed — WebSearch built-in |
| `datetime` | npm (npx) | `.claude.json` (project) | Removed — use `Bash(date)` |
| `lotus-wisdom` | npm (npx) | `.claude.json` (project) | Removed — novelty |
| `chroma` | Python (uvx) | `.claude.json` (project) | Removed — dormant |
| `desktop-commander` | npm (npx) | `.claude.json` (project) | Removed — Bash covers all ops |
| `wikipedia` | npm (npx) | `.claude.json` (project) | Removed — use WebFetch |
| `playwright` | npm (npx) | `.claude.json` (project) | RETAINED — unique browser automation |
| `perplexity` | npm (npx) | `.claude.json` (project) | Removed — WebSearch sufficient |
| `gptresearcher` | Python | `.claude.json` (project) | Removed — deep-research agent |

### Key Finding: Config Storage

MCPs added via `claude mcp add` are stored in `/Users/aircannon/.claude.json` (project-specific section), NOT in the project's `.mcp.json`. The `.mcp.json` file only contains MCPs added by manual file editing.

### Auto-Provisioned MCP Architecture

Claude Code auto-provisions git, fetch, and memory servers. They appear in the tool namespace as `mcp__mcp-gateway__*` (memory/fetch) and `mcp__git__*`. These are NOT configured via `.mcp.json` or `.claude.json` — they're built into Claude Code's runtime.

**Implication**: Cannot "remove" auto-provisioned MCPs via config deletion. Instead:
- Create skills that redirect to built-in tools (preferred path)
- MCPs still load as deferred tools but won't be invoked if skills guide correctly
- Removed `mcp__mcp-gateway__fetch` permission from project settings (creates friction)

### Permission Entries (Project Settings)

From `.claude/settings.json`:
```
"mcp__mcp-gateway__read_graph"    → Memory (RETAINED)
"mcp__mcp-gateway__search_nodes"  → Memory (RETAINED)
"mcp__mcp-gateway__open_nodes"    → Memory (RETAINED)
"mcp__mcp-gateway__fetch"         → REMOVED (2026-02-07)
```

---

## Decomposition Status

### Phagocytosed (Skill Replacements)

| MCP | Status | Replacement | Skill File |
|-----|--------|-------------|-----------|
| `filesystem` | REMOVED | `filesystem-ops` skill | `.claude/skills/filesystem-ops/SKILL.md` |
| `git` | SHADOWED (auto-provisioned) | `git-ops` skill | `.claude/skills/git-ops/SKILL.md` |
| `fetch` | SHADOWED (auto-provisioned) | `web-fetch` skill | `.claude/skills/web-fetch/SKILL.md` |
| `weather` (curl) | SKILL-IFIED | `weather` skill | `.claude/skills/weather/SKILL.md` |

### Retained

| MCP | Status | Rationale |
|-----|--------|-----------|
| `memory` | RETAINED | Unique knowledge graph — no built-in equivalent, used by hooks |
| `local-rag` | RETAINED (dormant) | Unique vector DB/embeddings — deferred, near-zero cost |
| `playwright` | RETAINED (deferred) | Unique browser automation — no built-in equivalent |

### Removed (Tier 2 — No Skill Needed)

| MCP | Removed Date | Built-in Alternative |
|-----|-------------|---------------------|
| `github` | 2026-02-07 | `Bash(gh pr/issue/api ...)` |
| `context7` | 2026-02-07 | WebFetch on documentation sites |
| `sequential-thinking` | 2026-02-07 | Claude's native reasoning |
| `arxiv` | 2026-02-07 | `WebFetch("https://arxiv.org/...")` |
| `brave-search` | 2026-02-07 | `WebSearch` (built-in) |
| `datetime` | 2026-02-07 | `Bash("date ...")` |
| `lotus-wisdom` | 2026-02-07 | Not needed (novelty MCP) |
| `chroma` | 2026-02-07 | local-rag covers vector search needs |
| `desktop-commander` | 2026-02-07 | `Bash` covers all operations |
| `wikipedia` | 2026-02-07 | `WebFetch("https://en.wikipedia.org/...")` |
| `perplexity` | 2026-02-07 | `WebSearch` (built-in) |
| `gptresearcher` | 2026-02-07 | `deep-research` agent |

---

## Functional Validation (2026-02-07)

14/14 tests passed using built-in tools only:
- filesystem-ops: Read, Glob, Grep, Write, Bash(ls), Bash(mkdir), Bash(stat) — all pass
- git-ops: Bash(git status/log/diff/branch) — all pass
- web-fetch: WebFetch, WebSearch — all pass
- weather: Bash(curl wttr.in) — pass (service availability is external)

---

## Empirical Measurement

### Baseline (Pre-Removal)
- **MCPs connected**: 18
- **Deferred tools listed**: 43 (from 5 MCPs: filesystem, git, local-rag, memory, fetch)
- **Tier 2/3 MCPs**: 0 deferred tools (connected but tools not loaded via ToolSearch)
- **Note**: With `mcpToolSearch: "auto:15"`, Tool Search already reduces overhead by ~85%

### Post-Removal
- **MCPs connected**: 5 (memory, local-rag, fetch, git, playwright)
- **Deferred tools**: 28 (removed 15 filesystem tools; git/local-rag/memory/fetch unchanged)
- **Token delta**: Pending restart measurement (changes take effect on next session)

### External Reference Data
- Without Tool Search: ~55K tokens for 58 tools (industry measurement)
- With Tool Search: ~8.7K tokens for 50+ tools (85% reduction)
- Source: [Medium - Claude Code MCP Context Bloat](https://medium.com/@joe.njenga/claude-code-just-cut-mcp-context-bloat-by-46-9-51k-tokens-down-to-8-5k-with-new-tool-search-ddf9e905f734)

---

## Post-Removal State (2026-02-07)

### Active MCPs (5 total)

```
local-rag:  npx -y mcp-local-rag                                    ✓ Connected (RETAINED)
memory:     npx -y @modelcontextprotocol/server-memory               ✓ Connected (RETAINED)
fetch:      uvx mcp-server-fetch                                     ✓ Connected (AUTO-PROVISIONED)
git:        uvx mcp-server-git --repository /path                    ✓ Connected (AUTO-PROVISIONED)
playwright: npx -y @playwright/mcp@latest                            ✓ Connected (RETAINED)
```

### Re-Adding Removed MCPs

Any removed MCP can be restored in seconds:
```bash
claude mcp add <name> -- npx -y <package>
# Then /clear or restart session
```

---

## MCP-to-Skill Pipeline Protocol (v2.0)

Formalized 9-step pipeline for converting MCP tools into built-in skill equivalents.

### Step-by-Step

| Step | Action | Detail |
|------|--------|--------|
| 1. DISCOVER | Inventory MCP | `ToolSearch "+<mcp-name>"` — record tool count, names, schemas |
| 2. ANALYZE | Check built-in equivalents | Each tool → Read/Write/Edit/Glob/Grep/Bash/WebFetch/WebSearch? |
| 3. MAP | Create mapping table | `| MCP Tool | Built-in | Notes |` for each tool |
| 4. BUILD | Create skill file | Follow Skill File Format Standard (≤300 tokens, imperative, tables) |
| 5. VALIDATE | Test each mapped tool | 1 test per tool using ONLY built-ins |
| 6. REGISTER | Add to manifest | Entry in `capability-map.yaml` with `replaces:` field |
| 7. REMOVE | Delete MCP | `claude mcp remove <name>` |
| 8. MEASURE | Token delta | Compare `cache_creation_input_tokens` in statusline-input.json |
| 9. DOCUMENT | Update this registry | Record status, date, validation results |

### Decision Rules (v3.0 — Decomposition-First)

```
For each MCP tool:
├── Is it an API wrapper? (calls external HTTP API)
│   └── YES → DECOMPOSE: skill + Bash(curl) or WebFetch
│
├── Is it a prompt/workflow pattern?
│   └── YES → DECOMPOSE: extract pattern into skill file
│
├── Does it wrap built-in tools? (Read/Write/Bash/etc.)
│   └── YES → DECOMPOSE: skill redirects to built-ins
│
├── Does it provide unique capability?
│   └── YES → ESPECIALLY DECOMPOSE & RECONSTRUCT
│       ├── Replicable via scripts + built-ins? → DECOMPOSE
│       ├── Requires persistent server process?
│       │   ├── Stateful connection (WebSocket, browser) → RETAIN
│       │   ├── Long-running service (DB engine, embeddings) → RETAIN
│       │   └── Stateless request/response → DECOMPOSE
│       └── Can talk to infrastructure directly? → DECOMPOSE
│
└── No unique capability? → REMOVE entirely

PARADIGM: Default verdict is DECOMPOSE. "Unique capability" is the
BEST reason to reconstruct natively, not a reason to retain.
Only RETAIN when a persistent server process is literally required.
```

### Best Practices (BP-01 through BP-05)

- **BP-01**: One test per mapped tool (no validation gaps)
- **BP-02**: Skill file ≤ 300 tokens (hard budget)
- **BP-03**: Measure before AND after removal (precise methodology)
- **BP-04**: Register in manifest immediately (no orphan skills)
- **BP-05**: Any removed MCP can return via `claude mcp add` (reversible)

## Plugin-to-Skill Pipeline Protocol

Plugins differ from MCPs: they inject prompts/skills/commands (text), not tool definitions (schemas).

### Assessment (v3.0 — Decomposition-First)

```
Plugin provides:
├── Tool wrappers (calls Read/Write/Bash) → DECOMPOSE (skill covers this)
├── Unique prompt patterns → EXTRACT into skill (the BEST reason to decompose)
├── Workflow orchestration → EXTRACT into command/workflow
├── Hooks/automation → PORT to .claude/hooks/ if valuable
├── Requires plugin packaging format?
│   ├── Stop hooks with `continue` field → May need plugin format
│   └── Plugin-only lifecycle APIs → May need plugin format
└── No unique capability → REMOVE entirely

PARADIGM: Default is DECOMPOSE. Only retain plugin if it literally
requires the plugin packaging format (e.g., stop hooks with `continue`).
```

### Steps

| Step | Action |
|------|--------|
| 1. DISCOVER | List plugin skills, commands, hooks |
| 2. ASSESS | What does it provide that we lack? |
| 3. EXTRACT | Core logic + patterns into runbook format |
| 4. BUILD | Compile into skill card (Format Standard v2.0) |
| 5. VALIDATE | Test skill replaces plugin functionality |
| 6. DISABLE | Disable plugin if fully replaced |
| 7. DOCUMENT | Update manifest + this registry |

### Best Practices (BP-06 through BP-09)

- **BP-06**: Extract prompt patterns, not just tool mappings
- **BP-07**: Assess unique capabilities before decomposing
- **BP-08**: Plugin hooks → port to .claude/hooks/ if valuable
- **BP-09**: Plugin skills → compile to Format Standard v2.0

---

*MCP Decomposition Registry v3.1 — Decomposition-First Paradigm (2026-02-07)*
*See also: .claude/plans/pipeline-design-v3.md for full pipeline design*
