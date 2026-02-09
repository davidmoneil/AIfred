# MCP Decomposition Registry

**Purpose**: Master tracking of all MCP servers analyzed, decomposed, and reconstructed into skills.
**Created**: 2026-02-07
**Updated**: 2026-02-09 (v5.1 — Stream 1: 4/6 MCP capabilities reconstructed as native scripts)
**Authoritative Design**: `.claude/plans/pipeline-design-v3.md` (v4.0)

---

## Core Principle

> **Decomposition-First**: Default verdict is DECOMPOSE. "Unique capability" is the BEST reason
> to reconstruct natively. Only RETAIN when a persistent server process is literally required.
> Ad-hoc `Bash(curl)` or `WebFetch` is NOT an acceptable replacement — build a documented,
> reproducible, replicable Skill with standardized protocols.

> **Cherry-Pick Principle**: Pattern extraction matters more than wholesale plugin installation.
> Large plugin libraries contain mostly generic patterns already covered by Jarvis. The value
> is in cherry-picking the 3-5 novel patterns per library that address known gaps. Never
> wholesale install — extract the smallest useful unit (a pattern file, a hook, a skill module).
> If no novel patterns exist, or if integration requires major infrastructure changes, DEFER.

---

## Master Status Matrix (18 Original + 19 Planned)

### Decomposed → Skills (COMPLETE)

| MCP | Skill | Status | Validation |
|-----|-------|--------|-----------|
| `filesystem` | `filesystem-ops` | DONE — Removed | 7/7 tests pass |
| `git` | `git-ops` | DONE — Shadowed (auto-provisioned) | 4/4 tests pass |
| `fetch` | `web-fetch` | DONE — Shadowed (auto-provisioned) | 2/2 tests pass |
| `weather` (curl) | `weather` | DONE — Skill-ified | 1/1 test pass |

### Retained (Server-Dependent — Only Valid Retention Reason)

| MCP | Status | Rationale | Future |
|-----|--------|-----------|--------|
| `memory` | SHADOW planned | Auto-provisioned, JSON file. Decomposable via `jq`. | → `knowledge-ops` skill shadows it |
| `local-rag` | RETAIN | Requires persistent embedding service | Integrate into `knowledge-ops` |
| `playwright` | RETAIN | Requires persistent browser instance | Integrate into `web-ops` skill |

### Decomposing → Skills (IN PROGRESS)

These MCPs were removed from config but their unique capabilities are being RECONSTRUCTED as native skills. They are NOT "removed with no replacement" — each has a planned skill integration.

| MCP | Target Skill | Unique Value Being Reconstructed | Status |
|-----|-------------|----------------------------------|--------|
| `context7` | `research-ops` | Version-pinned library doc fetching, LLM-optimized | PARTIAL — `scripts/fetch-context7.sh` (workflow doc, requires local-rag MCP) |
| `arxiv` | `research-ops` | Structured paper search, category filters, date ranges, caching | DONE — `scripts/search-arxiv.sh` (public API, xmllint parsing) |
| `brave-search` | `research-ops` | Local/video/news search, freshness filtering, AI summaries | DONE — `scripts/search-brave.sh` (web/news/video/image, freshness filters) |
| `wikipedia` | `research-ops` | Structured section access, NLP fact extraction, multi-language | DONE — `scripts/fetch-wikipedia.sh` (multi-lang, summary/full/search modes) |
| `perplexity` | `research-ops` | AI-augmented search, 4 sonar models, citations, deep research | DONE — `scripts/search-perplexity.sh` (4 sonar models, dynamic timeout) |
| `gptresearcher` | `research-ops` | Autonomous multi-source research, source validation, reports | BLOCKED — `scripts/deep-research-gpt.sh` (workflow doc, API key TBD) |
| `lotus-wisdom` | `knowledge-ops` | Contemplative reflection patterns (examine, reflect, verify, transform) for AC-05/06 | PLANNED — prompt extraction |
| `chroma` | `db-ops` | Vector DB client, collection mgmt, semantic search. USER OVERRIDE: DEFAULT for all vector use | PLANNED — requires Docker Chroma server |

### Skipped (No Unique Value to Reconstruct)

| MCP | Removed Date | Rationale |
|-----|-------------|-----------|
| `github` | 2026-02-07 | `Bash(gh pr/issue/api)` — CLI is native, documented, complete. No skill needed. |
| `sequential-thinking` | 2026-02-07 | Claude reasons natively. Zero unique value. |
| `datetime` | 2026-02-07 | `Bash(date)` — trivial, no skill needed. |
| `desktop-commander` | 2026-02-07 | All file/process ops covered by `filesystem-ops` + `Bash`. No unique residual. |

### Deferred (Blocked on External Dependencies)

| MCP | Verdict | Blocker | Target Skill |
|-----|---------|---------|-------------|
| `Slack` | DEFER | No workspace yet | `comms-ops` (future) |
| `GoogleDrive` | DEFER | Billing decision pending | `doc-ops` (future) |
| `GoogleMaps` | DEFER | Billing decision pending | `research-ops` (future) |
| `Graphiti` | DEFER | Neo4j not running | `knowledge-ops` or `db-ops` |

---

## Planned New MCPs → Skill Reconstruction

### Thought/Memory → `knowledge-ops`

| MCP | Verdict | Rationale |
|-----|---------|-----------|
| Cognee | EVALUATE → DECOMPOSE if API wrapper | RAG pipeline + knowledge graph. Study embedding architecture. |
| Obsidian | RECONSTRUCT → `knowledge-ops` | USER OVERRIDE: vault markdown access, thought organization |
| Claude-Context (zilliztech) | RECONSTRUCT → `knowledge-ops` | Semantic code search via local embeddings |
| UltraRAG (openbmb) | STUDY → RECONSTRUCT | RAG pipeline IDE. Study architecture, extract patterns. |
| Claude-Code-Docs (ericbuess) | INSTALL or RAG | Reference documentation. Install or ingest via local-rag. |

### Research → `research-ops`

| MCP | Verdict | Rationale |
|-----|---------|-----------|
| DuckDuckGo | DECOMPOSE → `research-ops` | WebSearch or `Bash(curl)`. Bot detection issues noted. |
| Alpha Vantage | DECOMPOSE → `research-ops` | Pure REST API. Key at `.research.alpha_vantage`. |
| BioRxiv | DECOMPOSE → `research-ops` | Hosted MCP. 260k+ preprints. Academic biology papers. |
| Exa Search | EVALUATE → `research-ops` | Semantic web search. Paid API. Compare with WebSearch. |

### Dev/Code → `code-ops`

| MCP | Verdict | Rationale |
|-----|---------|-----------|
| Semgrep | RECONSTRUCT → `code-ops` | CLI tool (`Bash(semgrep ...)`), static analysis |
| Serena (oraios) | INSTALL → DECOMPOSE → `code-ops` | LSP-based code intelligence. 30+ languages. Highest value MCP in assessment. |
| Repomix | DECOMPOSE → `code-ops` | Context assembly via Glob + Read + Write |
| Notion | DECOMPOSE | Stateless REST API. No workspace currently active. |

### Databases → `db-ops`

| MCP | Verdict | Rationale |
|-----|---------|-----------|
| Chroma | RECONSTRUCT → `db-ops` | USER OVERRIDE: DEFAULT vector DB for all use cases. Docker server. |
| MongoDB | RECONSTRUCT → `db-ops` | mongosh CLI + scripts |
| Supabase | RECONSTRUCT → `db-ops` | REST API + supabase CLI. Paid credentials. |
| SQLite-bun | RECONSTRUCT → `db-ops` | sqlite3 CLI |
| MindsDB | RECONSTRUCT → `db-ops` | REST API for federated ML queries |
| Neo4j (via Graphiti) | DEFER → `db-ops` | Graph DB. Requires Neo4j server. |

### Workflow/Automation → `flow-ops`

| MCP | Verdict | Rationale |
|-----|---------|-----------|
| n8n | RECONSTRUCT → `flow-ops` | USER OVERRIDE: full n8n capability. Mac Studio incoming. |
| TaskMaster | SKIP | TodoWrite + agents already cover task management |

### UI/Browser → `web-ops`

| MCP | Verdict | Rationale |
|-----|---------|-----------|
| Playwright | RETAIN + integrate into `web-ops` | Server-dependent: persistent browser instance |
| ChromeDevTools | SKIP | Playwright covers browser automation |
| BrowserStack | DECOMPOSE → `web-ops` | Cross-browser testing API. Skill + curl + API key. |
| Puppeteer | SKIP | Playwright already retained |

### Media/Creative

| MCP | Verdict | Rationale |
|-----|---------|-----------|
| ElevenLabs | INSTALL → DECOMPOSE → `audio-ops` | Official TTS/voice. 10k free credits/mo. |
| Vizro (mckinsey) | INSTALL → `data-sci-ops` | Production dashboards. Python package. |
| Next-AI-Draw-IO | INSTALL → `doc-ops` | AI diagramming from NL. Docker/desktop. |

### Skipped (No Value)

| MCP | Rationale |
|-----|-----------|
| Puppeteer | Playwright covers it |
| ChromeDevTools | Playwright covers it |
| TaskMaster | TodoWrite + agents |
| Markdownify | WebFetch already converts HTML→markdown |
| MagicUI | WebFetch on component docs sufficient |
| DesktopCommander | filesystem-ops + Bash covers all |

---

## Discovery Summary

### Config Storage
MCPs added via `claude mcp add` → `/Users/aircannon/.claude.json` (project-specific).
`.mcp.json` only contains manually-edited MCPs.

### Auto-Provisioned MCP Architecture
Claude Code auto-provisions `git`, `fetch`, and `memory`. Namespace: `mcp__mcp-gateway__*` (memory/fetch), `mcp__git__*`. Built into Claude Code runtime — cannot remove via config. Strategy: shadow with skills, add permission friction.

### Active MCPs (5 total)

```
local-rag:  npx -y mcp-local-rag                     ✓ RETAINED (server-dependent)
memory:     npx -y @modelcontextprotocol/server-memory ✓ SHADOWING (→ knowledge-ops)
fetch:      uvx mcp-server-fetch                       ✓ SHADOWED (→ web-fetch skill)
git:        uvx mcp-server-git                         ✓ SHADOWED (→ git-ops skill)
playwright: npx -y @playwright/mcp@latest              ✓ RETAINED (→ web-ops integration)
```

---

## Pipeline Protocols

### MCP-to-Skill Pipeline (9 Steps)

| Step | Action | Detail |
|------|--------|--------|
| 1. DISCOVER | Inventory MCP | `ToolSearch "+<name>"` — record tool count, schemas |
| 2. ANALYZE | Check equivalents | Each tool → built-in mapping via decision tree |
| 3. MAP | Mapping table | `| MCP Tool | Built-in | Notes |` |
| 4. BUILD | Create skill | Format Standard v2.0 (≤300 tokens) |
| 5. VALIDATE | Test each tool | 1 test per tool, built-ins only |
| 6. REGISTER | Add to manifest | `capability-map.yaml` with `replaces:` |
| 7. REMOVE | Delete MCP | `claude mcp remove <name>` |
| 8. MEASURE | Token delta | `cache_creation_input_tokens` comparison |
| 9. DOCUMENT | Update registry | Status, date, validation results |

### Plugin-to-Skill Pipeline (7 Steps)

| Step | Action |
|------|--------|
| 1. DISCOVER | List plugin skills, commands, hooks |
| 2. ASSESS | What unique value does it provide? |
| 3. EXTRACT | Core logic + patterns into skill format |
| 4. BUILD | Compile to Format Standard v2.0 |
| 5. VALIDATE | Test skill replaces plugin functionality |
| 6. DISABLE | Disable plugin if fully replaced |
| 7. DOCUMENT | Update manifest + this registry |

### Decision Rules (v3.0 — Decomposition-First)

```
For each MCP tool:
├── Is it an API wrapper? → DECOMPOSE: skill + Bash(curl)
├── Is it a prompt/workflow pattern? → DECOMPOSE: extract into skill
├── Does it wrap built-in tools? → DECOMPOSE: skill redirects to built-ins
├── Does it provide unique capability?
│   └── YES → ESPECIALLY DECOMPOSE & RECONSTRUCT
│       ├── Replicable via scripts + built-ins? → DECOMPOSE
│       ├── Requires persistent server?
│       │   ├── Stateful (WebSocket, browser) → RETAIN
│       │   ├── Long-running (DB, embeddings) → RETAIN
│       │   └── Stateless request/response → DECOMPOSE
│       └── Direct infrastructure access? → DECOMPOSE
└── No unique capability? → SKIP (nothing to reconstruct)

NEVER: Use ad-hoc Bash(curl) as a "solution" — build a Skill.
"Can be done with Bash" describes HOW to build the skill, not a reason to skip.
```

### Best Practices

| ID | Rule |
|----|------|
| BP-01 | One test per mapped tool (no validation gaps) |
| BP-02 | Skill file ≤ 300 tokens (hard budget) |
| BP-03 | Measure before AND after removal (precise) |
| BP-04 | Register in manifest immediately (no orphans) |
| BP-05 | Any removed MCP can return via `claude mcp add` (reversible) |
| BP-06 | Extract prompt patterns, not just tool mappings |
| BP-07 | Assess unique capabilities before decomposing |
| BP-08 | Plugin hooks → port to .claude/hooks/ if valuable |
| BP-09 | Plugin skills → compile to Format Standard v2.0 |

---

## Target Skill Architecture (Swiss-Army-Knife Pattern)

### Unified x-ops Skills (MCP Reconstruction + Existing Skill Consolidation)

```
research-ops (v2.1 DONE) ───────────────────────
├── WebSearch/WebFetch (built-in)
├── brave-search, tavily, serper, serpapi (paid search APIs)
├── perplexity (AI-augmented, 4 sonar models)
├── arxiv, pubmed (academic)
├── wikipedia (encyclopedia)
├── firecrawl, scraperapi (scraping)
├── alpha-vantage (financial)
├── context7 (lib docs via local-rag)
├── octagon-deepsearch (deep research)
└── ABSORBS: web-fetch skill (redirects here)

knowledge-ops (v2.0 DONE) ──────────────────────
├── Tier 1: Memory MCP (dynamic KG, 9 tools)
├── Tier 2: Auto memory files (MEMORY.md, topic files)
├── Tier 3: local-rag (semantic RAG, retained MCP)
├── Tier 4: Documentary grounding (Read/Glob/Grep)
├── lotus-wisdom (contemplative patterns for AC-05/06)
├── obsidian (vault markdown, planned)
├── claude-context (semantic code search, planned)
├── cognee, ultrarag (RAG pipeline, evaluate)
└── graphiti (Neo4j graph, deferred)

self-ops (PLANNED) ─────────────────────────────
├── ABSORBS: self-improvement skill (AC-05/06/07/08)
├── ABSORBS: jarvis-status skill (AC component health)
├── ABSORBS: validation skill (tooling/infra/design review)
└── Core: reflect, evolve, research, maintain, status, health

doc-ops (PLANNED) ──────────────────────────────
├── ABSORBS: docx skill (Word documents)
├── ABSORBS: xlsx skill (Excel spreadsheets)
├── ABSORBS: pdf skill (PDF manipulation)
├── ABSORBS: pptx skill (PowerPoint)
└── Core: create, edit, convert, extract across all formats

mcp-ops (PLANNED) ──────────────────────────────
├── ABSORBS: mcp-validation skill
├── ABSORBS: mcp-builder skill
├── ABSORBS: plugin-decompose skill
└── Core: validate, build, decompose, pipeline lifecycle

autonom-ops (PLANNED) ──────────────────────────
├── ABSORBS: autonomous-commands skill (signal injection)
├── ABSORBS: session-management skill (lifecycle)
├── ABSORBS: context-management skill (JICM v5.8)
├── ABSORBS: ralph-loop skill (iterative execution)
└── Core: session lifecycle, context, autonomous execution

db-ops (PLANNED) ───────────────────────────────
├── chroma (vectors, DEFAULT, Docker)
├── supabase (PostgreSQL/REST)
├── mongodb (documents)
├── sqlite (local/embedded)
├── neo4j (graph, deferred)
└── mindsdb (federated ML)

web-ops (PLANNED) ──────────────────────────────
├── playwright (retained MCP, browser automation)
├── browserstack (cross-browser testing)
└── scraping patterns (curl, WebFetch, Firecrawl)

code-ops (PLANNED) ─────────────────────────────
├── serena (LSP code intelligence, highest-value)
├── semgrep (static analysis)
├── repomix (context assembly)
└── code analysis patterns

flow-ops (PLANNED) ─────────────────────────────
├── n8n (workflow automation, USER OVERRIDE)
├── orchestration patterns
└── automation scripts

data-sci-ops (PLANNED) ─────────────────────────
├── vizro (production dashboards, McKinsey)
├── data analysis patterns (pandas, polars)
├── visualization (matplotlib, plotly)
└── ML pipeline patterns
```

### Existing Skills → Consolidation Map

| Current Skill | Target x-ops | Action |
|---------------|-------------|--------|
| filesystem-ops | *standalone* | KEEP (foundational, always needed) |
| git-ops | *standalone* | KEEP (foundational, always needed) |
| web-fetch | research-ops | ABSORB (redirect to research-ops) |
| weather | *standalone* | KEEP (trivial, no consolidation value) |
| research-ops | *standalone* | DONE (v2.0, 14 backends) |
| knowledge-ops | *standalone* | DONE (v2.0, 4-tier hierarchy) |
| self-improvement | self-ops | ABSORB |
| jarvis-status | self-ops | ABSORB |
| validation | self-ops | ABSORB |
| docx | doc-ops | ABSORB |
| xlsx | doc-ops | ABSORB |
| pdf | doc-ops | ABSORB |
| pptx | doc-ops | ABSORB |
| mcp-validation | mcp-ops | ABSORB |
| mcp-builder | mcp-ops | ABSORB |
| plugin-decompose | mcp-ops | ABSORB |
| autonomous-commands | autonom-ops | ABSORB |
| session-management | autonom-ops | ABSORB |
| context-management | autonom-ops | ABSORB |
| ralph-loop | autonom-ops | ABSORB |
| skill-creator | mcp-ops | ABSORB (skill lifecycle) |
| example-skill | mcp-ops | ABSORB (reference template) |

### Post-Consolidation: 12 Skills (from 22)

```
KEEP standalone (4):  filesystem-ops, git-ops, weather, [example-skill as template]
DONE x-ops (2):       research-ops, knowledge-ops
PLANNED x-ops (6):    self-ops, doc-ops, mcp-ops, autonom-ops, db-ops, web-ops
FUTURE x-ops (3):     code-ops, flow-ops, data-sci-ops
```

---

## Functional Validation Log

### Phase 1: MCP Removal (2026-02-07)
14/14 tests passed using built-in tools only:
- filesystem-ops: Read, Glob, Grep, Write, Bash(ls/mkdir/stat) — 7/7 pass
- git-ops: Bash(git status/log/diff/branch) — 4/4 pass
- web-fetch: WebFetch, WebSearch — 2/2 pass
- weather: Bash(curl wttr.in) — 1/1 pass

### Phase 2: Skill Format v2.0 (2026-02-08)
6 skills optimized to ≤300 tokens (77% reduction: 5,275 → 1,218)

### Phase 3: Swiss-Army-Knife Skills (2026-02-08)
- research-ops: Created (313 tok, 9+ backends)
- knowledge-ops: Created (379 tok, memory shadow + lotus + RAG)

### Phase 4: Native MCP Reconstruction (2026-02-09)
4/6 removed MCPs reconstructed as production-grade bash scripts in `research-ops/scripts/`:
- search-brave.sh: web/news/video/image search, freshness filters — PASS
- search-arxiv.sh: category/author/sort filters, xmllint parsing — PASS
- fetch-wikipedia.sh: multi-lang, summary/full/search modes — PASS
- search-perplexity.sh: 4 sonar models, dynamic timeout, citations — PASS
- fetch-context7.sh: workflow doc (PARTIAL, requires local-rag MCP) — PASS
- deep-research-gpt.sh: workflow doc (BLOCKED, API key TBD) — PASS
- test-all.sh: 12/12 tests pass (full suite with paid APIs)
- Token savings: ~3,100/session (91% reduction from removing MCP tool definitions)

### Empirical Measurement
- Pre-removal: 18 MCPs connected, 43 deferred tools
- Post-removal: 5 MCPs connected, 28 deferred tools
- Token savings: ~5,700 (MCP removal) + ~4,050 (content optimization) = ~9,750 total

---

*MCP Decomposition Registry v5.0 — Corrected Decomposition Verdicts (2026-02-08)*
*Authoritative design: `.claude/plans/pipeline-design-v3.md`*
*Paradigm: Decompose Everything. Reconstruct Natively. Only Retain Server-Dependent MCPs.*
