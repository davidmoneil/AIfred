# Decomposition & Reconstruction Pipeline Design v3.1
## Context Token Overhead Reduction + Capability Transformation

**Version**: 4.0 (GitHub repos + doc alignment + terminology fixes)
**Date**: 2026-02-08
**Status**: Plan — awaiting approval
**Supersedes**: clever-dazzling-breeze.md (v2.0), mcp-decision-map.md (v1.0)

---

## Table of Contents

1. [Context & Goals](#part-1-context--goals)
2. [Core Paradigm: Decompose Everything](#part-2-core-paradigm)
3. [Architecture: Manifest + Search Hybrid](#part-3-architecture)
4. [MCP Decomposition Pipeline](#part-4-mcp-decomposition-pipeline)
5. [Plugin-to-Skill Pipeline](#part-5-plugin-to-skill-pipeline)
6. [Skill-to-Skill Optimization Pipeline](#part-6-skill-optimization-pipeline)
7. [Complete MCP Re-Review](#part-7-complete-mcp-re-review)
8. [New MCP & Skill Evaluation](#part-8-new-mcp--skill-evaluation)
9. [Context Token Overhead Interventions](#part-9-context-token-interventions)
10. [Token Measurement Methodology](#part-10-token-measurement)
11. [GPT5.2 Best Practices Integration](#part-11-gpt52-best-practices)
12. [Architectural Revision Plan](#part-12-architectural-revision)
13. [Jarvis_To_Do_Notes Rewrite](#part-13-to-do-notes-rewrite)
14. [Implementation Phases](#part-14-implementation-phases)
15. [Verification Plan](#part-15-verification)

---

## Part 1: Context & Goals

### What We've Done

MCP decomposition (18 → 5 MCPs) is complete. Four skills replace former MCPs:
- `filesystem-ops` replaces `mcp__filesystem` (15 tools)
- `git-ops` shadows `mcp__git` (auto-provisioned)
- `web-fetch` shadows `mcp__fetch` (auto-provisioned)
- `weather` replaces embedded curl block

### What This Plan Addresses

A **systematic pipeline** for transforming ALL external tool dependencies into lean, built-in equivalents — and reducing context token overhead simultaneously.

### Goals

```
┌─────────────────────────────────────────────────────────────────┐
│                        DESIGN GOALS                             │
├──────────────────────────────┬──────────────────────────────────┤
│ G1: Reduce preloaded tokens  │ Slim always-on context overhead │
│ G2: Decompose & reconstruct  │ Transform MCPs → native skills  │
│ G3: Atomize tool options     │ Smaller, composable capabilities │
│ G4: Creative combinations    │ Novel tool pairings via manifest │
│ G5: Deterministic discovery  │ Reliable skill/pattern loading  │
│ G6: Pipeline repeatability   │ Standardized conversion process │
│ G7: Aggressive reconstruction│ ONLY retain if server required  │
└──────────────────────────────┴──────────────────────────────────┘
```

---

## Part 2: Core Paradigm

### The Decomposition-First Principle

**There is no condition in which we prefer to retain an MCP "as-is" EXCEPT when
the MCP tools and functions REQUIRE or DEPEND ON actually SERVING an MCP process.**

```
┌─────────────────────────────────────────────────────────────────────┐
│                  DECOMPOSITION-FIRST PARADIGM                       │
│                                                                     │
│  "Unique capabilities should ESPECIALLY be decomposed and           │
│   reconstructed as native skills — not retained as MCP overhead."   │
│                                                                     │
│  The value of decomposition is in RECONSTRUCTING unique capabilities│
│  using built-in tools in novel, creative, and efficient ways.       │
│  The WORST reason to keep an MCP is "it does something unique."     │
│  That's the BEST reason to reconstruct it natively.                 │
│                                                                     │
│  Only retain MCPs that are literally server-dependent:              │
│  - Persistent stateful connections (WebSocket, browser instance)    │
│  - Long-running infrastructure (database engine, embedding service) │
│  - Cannot be replicated by scripts + built-in tools                 │
└─────────────────────────────────────────────────────────────────────┘
```

### Revised Decision Tree: MCP Evaluation

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
│       ├── Can the capability be replicated via scripts + built-ins?
│       │   └── YES → DECOMPOSE: skill + script
│       ├── Does it REQUIRE a persistent server process?
│       │   ├── Stateful connection (WebSocket, browser) → RETAIN MCP
│       │   ├── Long-running service (DB engine) → RETAIN MCP
│       │   └── Stateless request/response → DECOMPOSE
│       └── Can we talk to the infrastructure directly?
│           └── YES → DECOMPOSE: skill + direct API/CLI access
│
└── No unique capability?
    └── REMOVE entirely (no skill needed)
```

### Revised Decision Tree: Plugin Evaluation

```
For each plugin:
├── Does it wrap built-in tools?
│   └── YES → DECOMPOSE: extract into skill
│
├── Does it provide unique prompt patterns?
│   └── YES → EXTRACT pattern into skill card
│
├── Does it orchestrate workflows?
│   └── YES → EXTRACT into command or workflow file
│
├── Does it provide hooks/automation?
│   └── YES → PORT to .claude/hooks/ if valuable
│
├── Does it REQUIRE plugin packaging format?
│   │   (e.g., stop hooks with `continue` field, plugin-only APIs)
│   ├── YES → RETAIN plugin
│   └── NO → DECOMPOSE into skills + hooks + commands
│
└── No unique capability?
    └── REMOVE entirely
```

### The Reproducibility Principle

```
┌─────────────────────────────────────────────────────────────────────┐
│                   REPRODUCIBILITY PRINCIPLE                          │
│                                                                     │
│  "We don't do ad hoc around here."                                  │
│                                                                     │
│  Reproducibility = the repeated administration of a treatment       │
│  across a sample of multiple subjects. Variation in protocols       │
│  and methods must be kept to a minimum.                             │
│                                                                     │
│  WRONG: "We can just use Bash(curl) for Supabase" → ad hoc         │
│         → different curl flags each time → different error handling  │
│         → inconsistent response parsing → unreliable                │
│                                                                     │
│  RIGHT: Build a `database-ops` skill with tested, versioned,        │
│         documented patterns for each database backend.              │
│         Same interface. Same error handling. Same results.           │
│                                                                     │
│  COROLLARY: "Can be done with Bash" is NOT a reason to skip         │
│  building a skill. It's a description of HOW to build the skill.    │
│  The skill IS the standardized protocol.                            │
│                                                                     │
│  REFACTORING: When decomposing, evaluate the quality of source      │
│  code. Refactor during reconstruction — improve, don't just copy.   │
└─────────────────────────────────────────────────────────────────────┘
```

### Swiss-Army-Knife Pattern

```
Instead of:                           Build:
  perplexity-search skill             research-ops skill
  brave-search skill                    ├── perplexity (API key, deep)
  duckduckgo-search skill              ├── brave (API key, local)
  arxiv-search skill                    ├── duckduckgo (free, global)
  wikipedia-search skill                ├── arxiv (academic papers)
                                        ├── wikipedia (encyclopedia)
                                        └── websearch (built-in, default)

Instead of:                           Build:
  mongodb-ops skill                   database-ops skill
  supabase-ops skill                    ├── chroma (vectors, default)
  sqlite-ops skill                      ├── supabase (postgres/REST)
  chroma-ops skill                      ├── mongodb (documents)
                                        ├── sqlite (local/embedded)
                                        └── neo4j (graph, for Graphiti)

Instead of:                           Build:
  obsidian-vault skill                knowledge-ops skill
  memory-ops skill                      ├── memory (Knowledge Graph JSON)
  local-rag-ops skill                   ├── obsidian (vault markdown)
  lotus-wisdom skill                    ├── local-rag (vector search)
                                        ├── chroma (vector DB)
                                        └── lotus (contemplative patterns)
```

### Key Terminology

| Term | Definition |
|------|-----------|
| **Decomposition** | Taking apart an MCP/plugin to understand its constituent capabilities |
| **Reconstruction** | Rebuilding those capabilities as dedicated, tested, reusable native skills |
| **Refactoring** | Improving code quality during reconstruction — not just copy-pasting |
| **Shadowing** | A skill that redirects away from an auto-provisioned MCP |
| **Server-dependent** | Requires a persistent running process (not just a script invocation) |
| **SKIP** | Tool has NO unique value — nothing worth reconstructing. Not decomposed. |
| **Swiss-army-knife** | One unified skill covering multiple related backends/APIs |
| **Ad hoc** | FORBIDDEN. Improvised Bash commands instead of standardized skill protocols |

---

## Part 3: Architecture — Manifest + Search Hybrid

### Comparison

```
┌─────────────────────────────────────────────────────────────────────┐
│                   DISCOVERY MECHANISM COMPARISON                     │
├───────────────────────┬─────────────────────┬───────────────────────┤
│                       │ MANIFEST/ROUTER     │ TOOLSEARCH-LIKE       │
│                       │ (Static Index)      │ (Dynamic Search)      │
├───────────────────────┼─────────────────────┼───────────────────────┤
│ Discovery             │ Deterministic       │ Probabilistic         │
│ Token cost (idle)     │ ~400-800 tok (YAML) │ ~30 tok/entry listing │
│ Token cost (activate) │ ~200-300 tok (load) │ ~300 tok (full def)   │
│ Maintenance           │ Must update manifest│ Auto-discovers new    │
│ Reliability           │ 100% if maintained  │ ~90% (search quality) │
│ Novel combinations    │ Only what's listed  │ Can discover unexpected│
│ Architectural fit     │ Nous (knowledge)    │ Pneuma (capability)   │
│ Speed                 │ O(1) lookup         │ O(n) search           │
│ Stale risk            │ High (manual)       │ None (always current) │
└───────────────────────┴─────────────────────┴───────────────────────┘
```

### Recommendation: Hybrid — Manifest as Router, Search as Fallback

```
                        ┌─────────────┐
                        │  Task Need  │
                        └──────┬──────┘
                               │
                    ┌──────────▼──────────┐
                    │ Check Manifest      │ ← Fast path (Nous)
                    │ (capability-map.yaml)│
                    └──────────┬──────────┘
                          ┌────┴────┐
                     Found│         │Not Found
                          ▼         ▼
                    ┌──────────┐ ┌──────────────┐
                    │ Load by  │ │ Search       │ ← Discovery (Pneuma)
                    │ exact ID │ │ Glob/Grep    │
                    │          │ │ or ToolSearch │
                    └────┬─────┘ │ for MCPs     │
                         │       └──────┬───────┘
                         │         ┌────┴────┐
                         │    Found│         │Not Found
                         │         ▼         ▼
                         │   ┌──────────┐ ┌──────────┐
                         │   │ Load &   │ │ Report   │
                         │   │ register │ │ gap to   │
                         │   │ manifest │ │ user     │
                         │   └────┬─────┘ └──────────┘
                         │        │
                         ▼        ▼
                    ┌─────────────────┐
                    │ Execute module  │
                    └─────────────────┘
```

**Why both**: The manifest provides deterministic "System 1" lookup — Jarvis knows what it can do. Search provides "System 2" fallback for novel needs. The manifest self-heals: when search finds something new, it gets registered.

### Aion Architecture Integration

```
┌─────────────────────────────────────────────────────────┐
│                    AION ARCHITECTURE                     │
│                                                         │
│  NOUS (Knowledge)          PNEUMA (Capabilities)        │
│  .claude/context/          .claude/                     │
│  ┌─────────────────┐       ┌─────────────────┐         │
│  │ capability-map   │──────▶│ skills/          │         │
│  │   .yaml          │       │ agents/          │         │
│  │ (THE MAP)        │       │ commands/        │         │
│  │                  │       │ hooks/           │         │
│  │ patterns/        │       │ scripts/         │         │
│  │ components/      │       │ (THE TERRITORY)  │         │
│  └─────────────────┘       └─────────────────┘         │
│          │                          │                   │
│          │    ┌─────────────┐       │                   │
│          └───▶│ ENNOIA      │◀──────┘                   │
│               │ (Scheduler) │                           │
│               │ Uses map to │                           │
│               │ route tasks │                           │
│               └─────────────┘                           │
│                                                         │
│  SOMA (Infrastructure)                                  │
│  /Jarvis/                                              │
│  ┌─────────────────┐                                   │
│  │ docker/          │                                   │
│  │ scripts/         │                                   │
│  │ projects/        │                                   │
│  └─────────────────┘                                   │
└─────────────────────────────────────────────────────────┘
```

### Manifest: `capability-map.yaml` (DONE — 221 lines)

Located at `.claude/context/psyche/capability-map.yaml`. Contains:
- 19 skills with `when:` routing rules
- 12 agents with descriptions
- 4 key patterns, 4 workflows, 9 autonomic components
- MCP-to-Skill pipeline reference block

---

## Part 4: MCP Decomposition Pipeline

### 9-Step Pipeline

```
┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐
│ DISCOVER │───▶│ ANALYZE  │───▶│ MAP      │───▶│ BUILD    │───▶│ VALIDATE │
│          │    │          │    │          │    │          │    │          │
│ Inventory│    │ Each tool│    │ Tool →   │    │ Skill    │    │ 1 test   │
│ all tools│    │ built-in │    │ built-in │    │ ≤300 tok │    │ per tool │
│ via      │    │ equiv?   │    │ mapping  │    │ Format   │    │ built-in │
│ ToolSearch    │ Script?  │    │ table    │    │ Std v2.0 │    │ only     │
└──────────┘    └──────────┘    └──────────┘    └──────────┘    └────┬─────┘
                                                                     │
┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐         │
│ DOCUMENT │◀───│ MEASURE  │◀───│ REMOVE   │◀───│ REGISTER │◀────────┘
│          │    │          │    │          │    │          │
│ Update   │    │ Token    │    │ claude   │    │ Add to   │
│ registry │    │ delta    │    │ mcp rm   │    │ manifest │
│ & docs   │    │ precise  │    │ <name>   │    │ .yaml    │
└──────────┘    └──────────┘    └──────────┘    └──────────┘
```

### Step Details

| Step | Action | Method |
|------|--------|--------|
| 1. DISCOVER | Inventory the MCP | `ToolSearch "+<mcp-name>"` — record tool count, names, schemas |
| 2. ANALYZE | Evaluate each tool | Apply Decomposition-First decision tree (Part 2) |
| 3. MAP | Create mapping table | `\| MCP Tool \| Built-in \| Reconstruction Notes \|` |
| 4. BUILD | Create skill file | Skill File Format Standard v2.0 (≤300 tokens) |
| 5. VALIDATE | Test each mapping | 1 test per tool, built-ins only |
| 6. REGISTER | Add to manifest | Entry in `capability-map.yaml` with `replaces:` |
| 7. REMOVE | Delete MCP | `claude mcp remove <name>` |
| 8. MEASURE | Token delta | `cache_creation_input_tokens` comparison |
| 9. DOCUMENT | Update registry | Status, date, validation results |

### Analysis Template

```
## MCP: <name>

### Tool Inventory
| # | Tool | Parameters | Description |
|---|------|-----------|-------------|

### Decomposition Analysis
| Tool | Server-Dependent? | Built-in Equivalent | Reconstruction |
|------|--------------------|--------------------|----|
| tool_a | No | Read | Direct |
| tool_b | No | Bash(curl) | Script wrapper |
| tool_c | YES — persistent connection | RETAIN | Cannot replicate |

### Verdict: DECOMPOSE / RETAIN (with justification)
```

---

## Part 5: Plugin-to-Skill Pipeline

### Key Difference from MCP Pipeline

Plugins inject **text** (prompts, skills, commands), not **tool schemas**.
Plugin overhead = skill listing tokens, not tool definition tokens.
Decomposition = extracting valuable prompt patterns + workflows.

### 7-Step Pipeline

```
┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐
│ DISCOVER │───▶│ ASSESS   │───▶│ EXTRACT  │───▶│ BUILD    │
│          │    │          │    │          │    │          │
│ List     │    │ What     │    │ Core     │    │ Compile  │
│ skills,  │    │ does it  │    │ patterns │    │ to skill │
│ commands,│    │ provide  │    │ + logic  │    │ card     │
│ hooks    │    │ we lack? │    │ to docs  │    │ ≤300 tok │
└──────────┘    └──────────┘    └──────────┘    └────┬─────┘
                                                     │
┌──────────┐    ┌──────────┐    ┌──────────┐         │
│ DOCUMENT │◀───│ DISABLE  │◀───│ VALIDATE │◀────────┘
│          │    │          │    │          │
│ Update   │    │ Disable  │    │ Test     │
│ manifest │    │ plugin   │    │ skill    │
│ + index  │    │ if fully │    │ replaces │
│          │    │ replaced │    │ plugin   │
└──────────┘    └──────────┘    └──────────┘
```

### Assessment Criteria (Revised)

```
Plugin provides:
├── Tool wrappers (calls Read/Write/Bash)
│   └── DECOMPOSE: skill covers this
│
├── Unique prompt patterns
│   └── EXTRACT into skill (the BEST reason to decompose)
│
├── Workflow orchestration
│   └── EXTRACT into command or workflow file
│
├── Hooks/automation
│   └── PORT to .claude/hooks/ if valuable
│
├── Requires plugin packaging format?
│   ├── Stop hooks with `continue` field → May need plugin format
│   ├── Plugin-only lifecycle APIs → May need plugin format
│   └── Otherwise → DECOMPOSE
│
└── No unique capability
    └── REMOVE entirely
```

### Plugin Landscape (Research Findings)

**Claude Code Plugin Architecture**:
- Plugins inject text via stop hooks, skills, commands
- Stop hooks support `continue` field for workflow control
- Plugin skills appear in skill listings (token overhead per skill)
- Plugins can be decomposed into: skills + hooks + commands

**Notable Plugins Evaluated**:
| Plugin | Type | Verdict |
|--------|------|---------|
| Ralph Wiggum | Workflow pattern | Already decomposed → `ralph-loop` skill |
| Orchestration | Multi-phase workflow | Already decomposed → `orchestration:*` commands |
| Commits | Git summary | Already decomposed → `commits:*` commands |
| Output Styles | Response formatting | Active plugin (uses stop hooks) |

---

## Part 6: Skill-to-Skill Optimization Pipeline

### Skill File Format Standard v2.0

**Budget**: ≤300 tokens per skill file (hard limit)

```
SKILL FILE FORMAT STANDARD v2.0
────────────────────────────────────────

Required Header (YAML frontmatter):
  ---
  name: <id>
  version: <semver>
  description: <one line, ≤ 15 words>
  replaces: <what this replaces, if any>
  ---

Body (imperative, no prose):
  ## Quick Reference
  | Need | Tool | Example |
  (max 10 rows)

  ## Tool Mapping (if replacing MCP/plugin)
  | Old | New | Notes |
  (only if applicable)

  ## Selection Rules (decision tree)
  ```
  Need X?
  ├── Case A → Tool 1
  └── Case B → Tool 2
  ```

FORBIDDEN:
  - Narrative paragraphs (no prose)
  - Duplicated safety language (reference CLAUDE.md)
  - Examples > 2 lines
  - Sections > 15 lines
  - Token count > 300

DEDUPLICATION:
  - Safety → CLAUDE.md guardrails
  - Credentials → credential-store.md
  - Git patterns → git-ops skill
```

### Optimization Pipeline

```
For each existing skill:
1. COUNT tokens (wc -w × 1.3 ≈ tokens)
2. If > 300 tokens:
   a. Remove prose → imperative tables
   b. Remove duplicated safety language
   c. Remove examples > 2 lines
   d. Reference external files instead of inlining
3. VALIDATE skill still functions correctly
4. UPDATE capability-map.yaml if `when:` changed
```

---

## Part 7: Complete MCP Re-Review

### Current MCP Inventory (5 Active)

Applying the **Decomposition-First Paradigm** to ALL retained MCPs:

### 7.1 Memory (Auto-provisioned)

```
MCP: memory (mcp__mcp-gateway__*)
Tools: 9 (create_entities, create_relations, add_observations,
        delete_entities, delete_relations, delete_observations,
        read_graph, search_nodes, open_nodes)
Server Type: Auto-provisioned by Claude Code runtime
```

**Analysis**:
| Tool | Server-Dependent? | Alternative |
|------|-------------------|-------------|
| create_entities | No — JSON file write | Bash(jq) + Write |
| create_relations | No — JSON file write | Bash(jq) + Write |
| add_observations | No — JSON file write | Bash(jq) + Write |
| delete_* | No — JSON file manipulation | Bash(jq) + Write |
| read_graph | No — JSON file read | Read + Bash(jq) |
| search_nodes | No — JSON search | Grep + Bash(jq) |
| open_nodes | No — JSON lookup | Read + Bash(jq) |

**Verdict**: DECOMPOSABLE in theory. Memory MCP stores data as JSON at
`~/.claude/memory/memory.json`. All operations are file read/write + JSON manipulation.
However: auto-provisioned by Claude Code runtime — cannot remove via config.
**Action**: Create `memory-ops` skill that wraps Bash(jq) + Read/Write on the JSON file.
Shadow the auto-provisioned MCP. Add friction in settings (deny permissions like we did
with fetch). This gives us the same data persistence without MCP tool overhead.

**Priority**: Medium — memory tools are deferred via ToolSearch, low idle cost.

### 7.2 Local-RAG (Retained)

```
MCP: local-rag (npx -y mcp-local-rag)
Tools: 6 (ingest_file, ingest_data, query_documents,
        list_files, delete_file, status)
Server Type: npm, project-configured (.mcp.json)
```

**Analysis**:
| Tool | Server-Dependent? | Alternative |
|------|-------------------|-------------|
| ingest_file | YES — embedding model | Requires running embedding service |
| ingest_data | YES — embedding model | Requires running embedding service |
| query_documents | YES — vector similarity | Requires vector DB + embeddings |
| list_files | No | Glob or Bash(ls) on data dir |
| delete_file | No | Bash(rm) on data dir |
| status | No | Bash(curl) health check |

**Verdict**: RETAIN — requires persistent embedding service for vector operations.
Embeddings + similarity search cannot be replicated by scripts alone without running
an embedding model. The MCP wraps a running inference service.

**Action**: Keep in `.mcp.json`. Deferred via ToolSearch (near-zero idle cost).
Consider: if/when user stands up dedicated embedding service, evaluate whether
direct API access via skill + curl is more efficient than MCP wrapper.

### 7.3 Playwright (Retained)

```
MCP: playwright (npx -y @playwright/mcp@latest)
Tools: ~20 (navigate, click, fill, screenshot, evaluate, etc.)
Server Type: npm, project-configured
```

**Analysis**:
| Tool Category | Server-Dependent? | Alternative |
|--------------|-------------------|-------------|
| Browser lifecycle | YES — persistent browser | Bash(npx playwright) launches new each time |
| Page navigation | YES — stateful session | Each script invocation loses state |
| DOM interaction | YES — live browser instance | Cannot replicate without running browser |
| Screenshots | Partially — browser needed | Bash(npx playwright screenshot) per-invocation |
| JavaScript eval | YES — live page context | Cannot replicate statelessly |

**Verdict**: RETAIN — requires persistent browser instance with stateful session.
Browser automation fundamentally needs a running browser process. Each Playwright tool
call operates on the SAME browser session (cookies, localStorage, navigation history).
A script-per-invocation approach loses all state between calls.

**Action**: Keep. Deferred via ToolSearch (zero idle cost). This is the canonical
example of a server-dependent MCP — the browser IS the server.

### 7.4 Fetch (Auto-provisioned)

```
MCP: fetch (mcp__mcp-gateway__fetch / uvx mcp-server-fetch)
Tools: 1 (fetch)
Server Type: Auto-provisioned by Claude Code runtime
```

**Analysis**:
| Tool | Server-Dependent? | Alternative |
|------|-------------------|-------------|
| fetch | No — HTTP GET | WebFetch (built-in), Bash(curl) |

**Verdict**: FULLY DECOMPOSED. Already shadowed by `web-fetch` skill.
Auto-provisioned — cannot remove, but permission denied in settings.

**Action**: DONE. Shadow continues via skill. Permission already removed.

### 7.5 Git (Auto-provisioned)

```
MCP: git (mcp__git__* / uvx mcp-server-git)
Tools: ~14 (status, log, diff, commit, branch, etc.)
Server Type: Auto-provisioned by Claude Code runtime
```

**Analysis**:
| Tool | Server-Dependent? | Alternative |
|------|-------------------|-------------|
| All git ops | No — CLI wrappers | Bash(git *) — identical functionality |

**Verdict**: FULLY DECOMPOSED. Already shadowed by `git-ops` skill.
Auto-provisioned — cannot remove, but skill redirects to Bash(git).

**Action**: DONE. Shadow continues via skill.

### Previously Removed MCPs — Reinstated for Reconstruction

### 7.6 Desktop Commander — SKIP (No reconstruction needed)

```
Research: 26 tools, 9 potentially unique (REPL, async search, Excel, PDF)
Missing: clipboard, screenshot, file watching
```
All capabilities already covered by existing skills (xlsx, pdf) and built-ins
(tmux, background Bash). Nothing unique worth reconstructing.
**Verdict**: SKIP — no unique value to capture.

### 7.7 Context7 — RECONSTRUCT into `research-ops`

**Original**: API wrapper calling Context7's proprietary doc backend for library docs.
**What's valuable**: Version-specific library documentation pulls — getting the RIGHT
docs for the RIGHT version of a library, pre-processed for LLM consumption.

**Reconstruction Plan**:
```
Target: `research-ops` skill (swiss-army-knife for research)
Context7 contributes:
  ├── Pattern: version-pinned doc fetching
  ├── Combine with: local-rag for caching fetched docs
  ├── Workflow: fetch docs → ingest to vector DB → query locally
  └── Compare: Context7 pull vs WebFetch on same library
      → Measure quality difference, document findings
```
**Action**: Install Context7 MCP → study API patterns → reconstruct doc-fetching
logic into `research-ops` skill → uninstall MCP. Combine with local-rag for
persistent caching of fetched documentation.

### 7.8 arXiv — RECONSTRUCT into `research-ops`

**Original**: API wrapper + local caching for arXiv paper search/retrieval.
**What's valuable**: Structured paper search with category filters, date ranges,
author filtering. Local caching prevents re-fetching.

**Reconstruction Plan**:
```
Target: `research-ops` skill (academic research subsection)
arXiv contributes:
  ├── Dedicated script: scripts/arxiv-fetch.sh
  │   ├── Search: curl arXiv API with structured query params
  │   ├── Download: fetch PDF + metadata
  │   ├── Cache: .claude/cache/arxiv/<paper-id>/
  │   └── Index: update local search index
  ├── Skill section: standardized arXiv query patterns
  └── Integration: feed results to local-rag for semantic search
```

### 7.9 Brave Search — RECONSTRUCT into `research-ops`

**Original**: API wrapper calling Brave Search API (user has API key).
**What's valuable**: Local search, video search, news with freshness filtering,
AI-powered summaries. Different result quality from built-in WebSearch.

**Reconstruction Plan**:
```
Target: `research-ops` skill (web search subsection)
Brave contributes:
  ├── Dedicated script: scripts/brave-search.sh
  │   ├── Web search with filtering
  │   ├── Local/business search
  │   ├── News with freshness params
  │   └── Video discovery
  ├── API key: credentials.yaml → search.brave_api_key
  └── Use case: when WebSearch insufficient or for local results
```

### 7.10 Wikipedia — RECONSTRUCT into `research-ops`

**Original**: API wrapper for Wikipedia search, retrieval, fact extraction.
**What's valuable**: Structured section access, NLP fact extraction, multi-language.

**Reconstruction Plan**:
```
Target: `research-ops` skill (encyclopedia subsection)
Wikipedia contributes:
  ├── Dedicated script: scripts/wikipedia-fetch.sh
  │   ├── Search: MediaWiki API query
  │   ├── Sections: structured section retrieval
  │   ├── Facts: key fact extraction patterns
  │   └── Multi-lang: language parameter support
  └── Fallback: WebFetch for simple article access
```

### 7.11 Perplexity — RECONSTRUCT into `research-ops` (USER OVERRIDE: REBUILD)

**Original**: API wrapper with 4 models (search, ask, research, reason).
**What's valuable**: AI-augmented search with citations, deep research mode (30-40s),
reasoning chains. User has PAID API key — use it.

**Reconstruction Plan**:
```
Target: `research-ops` skill (AI-augmented search subsection)
Perplexity contributes:
  ├── Dedicated script: scripts/perplexity-query.sh
  │   ├── Search: sonar model (quick results)
  │   ├── Ask: sonar-pro (conversational, cited)
  │   ├── Deep research: sonar-deep-research (comprehensive)
  │   └── Reason: sonar-reasoning-pro (step-by-step logic)
  ├── API key: credentials.yaml → search.perplexity_api_key
  ├── Use case: grounding, comparing results, deep research
  └── Integration: optional tool for deep-research agent
```
**Priority**: HIGH — paid API key, unique AI-augmented research capability.

### 7.12 GPT Researcher — RECONSTRUCT into `research-ops` (USER OVERRIDE: REBUILD)

**Original**: Autonomous multi-source research with source validation.
**What's valuable**: Quality-over-quantity source filtering, autonomous exploration,
integrated report generation. User has PAID API key — use it.

**Reconstruction Plan**:
```
Target: `research-ops` skill (autonomous research subsection)
GPT Researcher contributes:
  ├── Pattern: multi-source validation workflow
  ├── Integration: enhance deep-research agent with GPTR backend
  ├── Script: scripts/gpt-researcher.sh (API wrapper)
  ├── API key: credentials.yaml → search.gptresearcher_api_key
  └── Use case: deep, comprehensive research with source quality scoring
```
**Priority**: HIGH — paid API key, complements Perplexity for different research depth.

### 7.13 Lotus Wisdom — RECONSTRUCT into `knowledge-ops` (USER OVERRIDE: REBUILD)

**Original**: Contemplative reasoning framework — Socratic, dialectical patterns.
**What's valuable**: Structured metacognitive patterns for self-reflection. Will become
part of Jarvis memory-ops and self-improvement cycles (AC-05/06).

**Reconstruction Plan**:
```
Target: `knowledge-ops` skill (contemplative patterns subsection)
Lotus Wisdom contributes:
  ├── Prompt patterns: begin, upaya, direct, gradual, sudden,
  │   recognize, transform, integrate, examine, reflect, verify,
  │   open, engage, express, meditate
  ├── Integration: /reflect and /self-improve commands
  ├── State tracking: via memory graph (knowledge-ops)
  └── Use case: structured self-reflection in AC-05/06 cycles
```
**Priority**: MEDIUM — valuable for self-evolution framework.

### 7.14 Chroma — RECONSTRUCT into `database-ops` (USER OVERRIDE: REBUILD)

**Original**: Vector database client for ChromaDB.
**What's valuable**: User wants Chroma as DEFAULT vector DB for ALL vector use cases.
Dedicated reusable tools, not ad-hoc curl commands.

**Reconstruction Plan**:
```
Target: `database-ops` skill (vector DB subsection, Chroma = default)
Chroma contributes:
  ├── Dedicated script: scripts/chroma-ops.py
  │   ├── Collection management (create, list, delete)
  │   ├── Document ingestion (add, update, delete)
  │   ├── Semantic search (query with embedding)
  │   ├── Metadata filtering
  │   └── Batch operations
  ├── Architecture: Chroma server (Docker) ← database-ops skill
  ├── Embedding: configurable provider (local or API)
  └── Use case: ALL vectorized DB needs go through Chroma
```
**Priority**: HIGH — designated default vector DB. Requires Docker setup for Chroma server.

### 7.15 Sequential Thinking — SKIP

**Original**: Structured step-by-step reasoning prompts.
Claude reasons natively. No unique value to capture.
**Verdict**: SKIP — nothing to reconstruct.

### Summary: MCP Retention Matrix (v3.1 — corrected)

```
┌──────────────────────────────────────────────────────────────────────────┐
│                    MCP RETENTION MATRIX (v3.1)                           │
├──────────────────┬────────────┬──────────────────┬──────────────────────┤
│ MCP              │ Status     │ Server-Dependent?│ Action               │
├──────────────────┼────────────┼──────────────────┼──────────────────────┤
│ memory           │ SHADOW     │ No (JSON file)   │ → knowledge-ops      │
│ local-rag        │ RETAIN     │ YES (embeddings) │ Keep + integrate     │
│ playwright       │ RETAIN     │ YES (browser)    │ Keep, deferred       │
│ fetch            │ SHADOWED   │ No (HTTP GET)    │ DONE                 │
│ git              │ SHADOWED   │ No (CLI wrapper) │ DONE                 │
│ filesystem       │ REMOVED    │ No (file ops)    │ → filesystem-ops ✅  │
│ desktop-commander│ SKIP       │ No (all covered) │ No unique value      │
│ context7         │ RECONSTRUCT│ No (API wrapper) │ → research-ops       │
│ arxiv            │ RECONSTRUCT│ No (API + cache) │ → research-ops       │
│ brave-search     │ RECONSTRUCT│ No (API wrapper) │ → research-ops       │
│ wikipedia        │ RECONSTRUCT│ No (API wrapper) │ → research-ops       │
│ perplexity       │ RECONSTRUCT│ No (API wrapper) │ → research-ops (PAID)│
│ gptresearcher    │ RECONSTRUCT│ No (hybrid)      │ → research-ops (PAID)│
│ lotus-wisdom     │ RECONSTRUCT│ No (prompts)     │ → knowledge-ops      │
│ chroma           │ RECONSTRUCT│ YES (vector DB)  │ → database-ops (DFLT)│
│ seq-thinking     │ SKIP       │ No (prompts)     │ No unique value      │
│ datetime         │ SKIP       │ No               │ Already Bash(date)   │
│ github           │ SKIP       │ No               │ Already Bash(gh)     │
├──────────────────┼────────────┼──────────────────┼──────────────────────┤
│ RETAINED         │ 2          │ local-rag,       │ Server-dependent     │
│                  │            │ playwright       │                      │
│ SHADOWED         │ 3          │ memory,fetch,git │ Auto-provisioned     │
│ RECONSTRUCTING   │ 8          │ See above        │ → 3 swiss-army skills│
│ SKIP             │ 5          │ See above        │ No value to capture  │
└──────────────────┴────────────┴──────────────────┴──────────────────────┘
```

### Target Swiss-Army-Knife Skills

```
8 MCPs being reconstructed → 3 unified skills:

┌─────────────────────────────────────────────────────────────┐
│ research-ops                                                 │
│ ├── context7 (version-pinned doc fetching)                  │
│ ├── arxiv (academic paper search + cache)                   │
│ ├── brave-search (paid API, local/video/news)               │
│ ├── wikipedia (encyclopedia, facts, multi-lang)             │
│ ├── perplexity (AI-augmented search, PAID key)              │
│ ├── gptresearcher (autonomous deep research, PAID key)      │
│ └── websearch/webfetch (built-in, default fallback)         │
├─────────────────────────────────────────────────────────────┤
│ knowledge-ops                                                │
│ ├── memory (Knowledge Graph JSON, shadows auto MCP)         │
│ ├── lotus-wisdom (contemplative reflection patterns)        │
│ ├── obsidian (vault markdown access — USER OVERRIDE)        │
│ ├── local-rag (vector search, retained MCP integration)     │
│ └── chroma (vector DB access — routed via database-ops)     │
├─────────────────────────────────────────────────────────────┤
│ database-ops                                                 │
│ ├── chroma (vectors, DEFAULT for all vector use cases)      │
│ ├── supabase (PostgreSQL/REST, paid credentials)            │
│ ├── mongodb (document store)                                │
│ ├── sqlite (local/embedded)                                 │
│ ├── neo4j (graph, for Graphiti integration)                 │
│ └── n8n (workflow automation DB — USER OVERRIDE)            │
└─────────────────────────────────────────────────────────────┘
```

---

## Part 8: New MCP & Skill Evaluation

### 8.1 MCPs from Jarvis_To_Do_Notes (Research Findings)

Applying Decomposition-First to all 19 unevaluated MCPs:

#### Thought/Memory
| MCP | Assessment | Verdict |
|-----|-----------|---------|
| Cognee (cognee-mcp) | RAG pipeline with knowledge graph | EVALUATE — if server-dependent for embeddings, may retain alongside local-rag. If API wrapper, decompose. |
| Graphiti (graphiti-mcp) | GraphRAG on Neo4j | RETAIN IF Neo4j running — requires persistent graph DB. Otherwise decompose to skill + Neo4j CLI. |

#### System/Web Autonomy
| MCP | Assessment | Verdict |
|-----|-----------|---------|
| DuckDuckGo | API wrapper — instant answers + search | DECOMPOSE: `Bash(curl)` or WebSearch |
| Puppeteer | Browser automation | SKIP — Playwright already retained for this |

#### Dev/Code
| MCP | Assessment | Verdict |
|-----|-----------|---------|
| Semgrep | Static analysis API | DECOMPOSE: `Bash(semgrep ...)` — CLI tool, no server needed |
| Notion | Notion API wrapper | DECOMPOSE: skill + `Bash(curl)` + API key. Stateless API. |
| Obsidian | Local vault file access | RECONSTRUCT → `knowledge-ops` (USER OVERRIDE: native skills for Obsidian integration) |
| TaskMaster | Task management for Claude | SKIP: TodoWrite + agents already cover this, no unique value |
| n8n | Workflow automation API | RECONSTRUCT → `n8n-ops` skill (USER OVERRIDE: full n8n capability, Mac Studio incoming) |
| Repomix | Repo context packaging | DECOMPOSE: Glob + Read + Write for context assembly |

#### Information/Grounding
(All previously evaluated — see Part 7 re-review)

#### UI Dev
| MCP | Assessment | Verdict |
|-----|-----------|---------|
| ChromeDevTools | Chrome DevTools Protocol | SKIP — Playwright covers browser automation |
| BrowserStack | Cross-browser testing API | DECOMPOSE: skill + `Bash(curl)` + API key |
| MagicUI | UI component library | DECOMPOSE: WebFetch on component docs + skill patterns |

#### Communications
| MCP | Assessment | Verdict |
|-----|-----------|---------|
| Slack | Slack API wrapper | DECOMPOSE: skill + `Bash(curl)` + API token. All Slack ops are REST API calls. |

#### Databases — ALL → `database-ops` swiss-army-knife skill
| MCP | Assessment | Verdict |
|-----|-----------|---------|
| MongoDB | MongoDB client | RECONSTRUCT → `database-ops` (mongosh CLI + scripts, standardized interface) |
| Supabase | Supabase API wrapper | RECONSTRUCT → `database-ops` (REST API + supabase CLI, paid credentials) |
| SQLite-bun | SQLite via Bun runtime | RECONSTRUCT → `database-ops` (sqlite3 CLI, standardized interface) |
| MindsDB | ML model serving API | RECONSTRUCT → `database-ops` (REST API for federated queries when MindsDB running) |

#### Docs
| MCP | Assessment | Verdict |
|-----|-----------|---------|
| Markdownify | HTML-to-Markdown conversion | DECOMPOSE: WebFetch already converts HTML to markdown. Redundant. |
| GoogleDrive | Google Drive API | DECOMPOSE: skill + `Bash(curl)` + OAuth. Wait for user billing decision. |
| GoogleMaps | Google Maps API | DECOMPOSE: skill + `Bash(curl)` + API key. Wait for user billing decision. |
| Alpha Vantage | Financial data API | DECOMPOSE: skill + `Bash(curl)` + API key. Pure REST API. |

### Summary: New MCP Verdicts (v3.1 — corrected)

```
┌────────────────────────────────────────────────────────────────────────┐
│                 NEW MCP EVALUATION SUMMARY (v3.1)                      │
├──────────────┬────────────┬────────────────────────────────────────────┤
│ Category     │ Count      │ Breakdown                                  │
├──────────────┼────────────┼────────────────────────────────────────────┤
│ RECONSTRUCT  │ 10         │ DuckDuckGo → research-ops                  │
│ (build skill)│            │ Semgrep → code-security                    │
│              │            │ Obsidian → knowledge-ops (USER OVERRIDE)   │
│              │            │ n8n → n8n-ops (USER OVERRIDE)              │
│              │            │ Repomix → codebase-ops                     │
│              │            │ MongoDB → database-ops                     │
│              │            │ Supabase → database-ops                    │
│              │            │ SQLite-bun → database-ops                  │
│              │            │ MindsDB → database-ops                     │
│              │            │ Alpha Vantage → financial-data (if needed) │
├──────────────┼────────────┼────────────────────────────────────────────┤
│ RETAIN       │ 2          │ Graphiti (if Neo4j running)                │
│              │            │ Cognee (if embeddings server running)      │
├──────────────┼────────────┼────────────────────────────────────────────┤
│ SKIP         │ 7          │ Puppeteer (Playwright covers),             │
│ (no value)   │            │ ChromeDevTools (Playwright covers),        │
│              │            │ TaskMaster (TodoWrite covers),             │
│              │            │ Notion (no workspace), BrowserStack (no    │
│              │            │ subscription), MagicUI (WebFetch ok),      │
│              │            │ Markdownify (WebFetch converts already)    │
├──────────────┼────────────┼────────────────────────────────────────────┤
│ DEFER        │ 3          │ Slack (no workspace yet),                  │
│ (revisit)    │            │ GoogleDrive (billing decision pending),    │
│              │            │ GoogleMaps (billing decision pending)      │
└──────────────┴────────────┴────────────────────────────────────────────┘
```

### 8.2 Skills from Anthropic + Community (Research Findings)

**Anthropic Official Skills** (github.com/anthropics/skills):

The Anthropic Agent Skills format defines:
- SKILL.md with YAML frontmatter (~100 tokens metadata)
- Progressive disclosure: metadata at startup, body on activation, resources on demand
- Cross-agent compatible format

**Already Integrated** (via earlier skill creation):
- docx, xlsx, pdf, pptx — document skills
- skill-creator — meta-skill for creating skills

**Evaluate for Integration**:
| Skill | Source | Assessment |
|-------|--------|-----------|
| file-organizer | ComposioHQ | EVALUATE — may overlap with filesystem-ops |
| image-enhancer | ComposioHQ | INTEGRATE — unique image processing capability |
| artifacts-builder | ComposioHQ | EVALUATE — depends on artifact use case |
| changelog-generator | ComposioHQ | INTEGRATE — useful for release management |
| content-research-writer | ComposioHQ | EVALUATE — may overlap with deep-research agent |
| article-extractor | tapestry | INTEGRATE — clean article extraction |
| youtube-transcript | tapestry | INTEGRATE — unique capability |
| markdown-to-epub | smerchek | INTEGRATE — new document format |
| video-downloader | ComposioHQ | EVALUATE — utility, may not fit project scope |
| webapp-testing | ComposioHQ | EVALUATE — may overlap with Playwright + code-tester |
| csv-data-summarizer | coffeefuelbump | INTEGRATE — data analysis skill |
| developer-growth-analysis | ComposioHQ | INTEGRATE — crucial for self-evolution (AC-05/06) |

### 8.3 GitHub Repos Evaluation (15 repos — Decomposition Assessment)

These repos were researched in the marketplace evaluation. Each is assessed through the
Decomposition-First lens: can the valuable capability be reconstructed natively?

```
┌──────────────────────────────────────────────────────────────────────────────┐
│              GITHUB REPOS — DECOMPOSITION ASSESSMENT (15 repos)              │
├──────────────────┬──────────┬──────────────────────────────────────────────┤
│ Repo             │ Verdict  │ Reconstruction Plan                          │
├──────────────────┼──────────┼──────────────────────────────────────────────┤
│ TIER 1: INSTALL & RECONSTRUCT                                               │
├──────────────────┼──────────┼──────────────────────────────────────────────┤
│ Serena           │ DECOMPOSE│ MCP only → add, study API patterns,          │
│ (oraios/serena)  │          │ reconstruct as code-ops skill. LSP-based     │
│                  │          │ code intelligence = high value.              │
├──────────────────┼──────────┼──────────────────────────────────────────────┤
│ Vizro            │ INSTALL  │ Python package. `pip install vizro`.          │
│ (mckinsey/vizro) │          │ Dashboard creation. High value, keep as      │
│                  │          │ library — no MCP needed, skill wraps import. │
├──────────────────┼──────────┼──────────────────────────────────────────────┤
│ ElevenLabs       │ DECOMPOSE│ MCP only → add, decompose to audio-ops skill│
│ (elevenlabs-mcp) │          │ with Bash(curl) API wrapper + API key.       │
├──────────────────┼──────────┼──────────────────────────────────────────────┤
│ Claude-Code-Docs │ INSTALL  │ Install → add skills/commands directly.      │
│ (ericbuess)      │          │ Documentation reference — minimal overhead.  │
├──────────────────┼──────────┼──────────────────────────────────────────────┤
│ TIER 2: DECOMPOSE (Extract Patterns)                                        │
├──────────────────┼──────────┼──────────────────────────────────────────────┤
│ Deep Research    │ STUDY    │ npm + localhost UI. Study the dashboard       │
│ (u14app)         │          │ pattern — useful for future Jarvis UI.       │
│                  │          │ Reconstruct research workflow as skill.       │
├──────────────────┼──────────┼──────────────────────────────────────────────┤
│ Get-Shit-Done    │ INSTALL  │ npm install. Productivity methodology        │
│ (glittercowboy)  │          │ wrapper. Prefer running as CLI tool.         │
├──────────────────┼──────────┼──────────────────────────────────────────────┤
│ TIER 3: INFRASTRUCTURE (Setup Required)                                     │
├──────────────────┼──────────┼──────────────────────────────────────────────┤
│ Archon           │ DEFER    │ Full package + localhost dashboard + UI.      │
│ (coleam00)       │          │ Much larger than MCP. Install when ready     │
│                  │          │ for agent framework evaluation.              │
├──────────────────┼──────────┼──────────────────────────────────────────────┤
│ Cua              │ INSTALL  │ High value computer-use automation.           │
│ (trycua)         │          │ Package install when ready for evaluation.   │
├──────────────────┼──────────┼──────────────────────────────────────────────┤
│ Next-AI-Draw-IO  │ INSTALL  │ Local install. High value for architecture   │
│ (dayuanjiang)    │          │ diagrams and visual planning.                │
├──────────────────┼──────────┼──────────────────────────────────────────────┤
│ TIER 4: CONDITIONAL                                                         │
├──────────────────┼──────────┼──────────────────────────────────────────────┤
│ BioRxiv          │ DECOMPOSE│ MCP only. Niche academic use. Add then       │
│ (deepsense.ai)   │          │ decompose to research-ops (biology papers).  │
├──────────────────┼──────────┼──────────────────────────────────────────────┤
│ GhidraMCP+Ghidra │ INSTALL  │ MCP + Ghidra package. High value for         │
│ (lauriewired)    │          │ reverse engineering. Requires Ghidra install.│
├──────────────────┼──────────┼──────────────────────────────────────────────┤
│ Claude-Context   │ DECOMPOSE│ Idea: point at local embeddings + vector DB. │
│ (zilliztech)     │          │ Reconstruct with Chroma/local-rag backend.   │
├──────────────────┼──────────┼──────────────────────────────────────────────┤
│ UltraRAG         │ STUDY    │ Localhost dashboard RAG system. High value    │
│ (openbmb)        │          │ but significant install. Study architecture. │
├──────────────────┼──────────┼──────────────────────────────────────────────┤
│ TIER 5: STRATEGIC/LOW PRIORITY                                              │
├──────────────────┼──────────┼──────────────────────────────────────────────┤
│ TrendRadar       │ DEFER    │ In Chinese. Needs translation review.        │
│ (sansan0)        │          │ Low priority until assessed.                 │
├──────────────────┼──────────┼──────────────────────────────────────────────┤
│ Claude-Flow      │ DEFER    │ Full package + MCP. Lower priority than      │
│ (ruvnet)         │          │ Archon/Serena for multi-agent patterns.      │
└──────────────────┴──────────┴──────────────────────────────────────────────┘
```

### 8.4 Recommendation Triage (Unimplemented — Prioritized)

All items from evaluation that haven't been started yet, ordered by value:

```
IMMEDIATE (next 1-2 sessions):
  1. Run Intervention 5 (Skill Listing Impact Test) — gates all skill optimization work
  2. Apply Format Standard v2.0 to 4 MCP-replacement skills (Intervention 4)
  3. Build memory-ops shadow skill (Intervention 7)
  4. Install claude-code-docs (Tier 1, minimal overhead)

SHORT-TERM (next 3-5 sessions):
  5. Build research-ops swiss-army-knife skill
     └── Reconstruct: Perplexity, GPTResearcher, Context7, arXiv, Brave, Wikipedia
  6. Build knowledge-ops swiss-army-knife skill
     └── Reconstruct: Memory shadow, Lotus Wisdom, Obsidian integration
  7. Build database-ops swiss-army-knife skill
     └── Reconstruct: Chroma (default), SQLite, MongoDB, Supabase, Neo4j
  8. Install Vizro (pip install) + create visualization skill wrapper
  9. Install Serena MCP → decompose → code-ops skill

MEDIUM-TERM (next 5-10 sessions):
  10. Build n8n-ops skill (USER OVERRIDE — Mac Studio setup)
  11. Build code-security skill (Semgrep CLI wrapper)
  12. Install Cua, Next-AI-Draw-IO when infrastructure ready
  13. Evaluate ElevenLabs → audio-ops skill
  14. Evaluate community skills (developer-growth-analysis, youtube-transcript, etc.)
  15. Phase 7: Architectural revision (dead MCP reference scan + cleanup)

DEFERRED (blocked on external):
  16. GoogleDrive, GoogleMaps (billing decision)
  17. Slack (no workspace)
  18. Graphiti, Cognee (Neo4j + embeddings server setup)
  19. Archon, UltraRAG, Deep Research (localhost dashboard study)
```

---

## Part 9: Context Token Overhead Interventions

### Status of 6 Interventions

```
┌───────────────────────────────────────────────────────────────────┐
│                INTERVENTION STATUS (6 total)                       │
├───┬──────────────────────────┬────────┬──────────┬────────────────┤
│ # │ Intervention             │ Status │ Savings  │ Phase          │
├───┼──────────────────────────┼────────┼──────────┼────────────────┤
│ 1 │ CLAUDE.md split          │ DONE   │ ~1,500   │ Phase 2 ✅     │
│   │ 171→79 lines (54% cut)   │        │ tokens   │                │
├───┼──────────────────────────┼────────┼──────────┼────────────────┤
│ 2 │ SessionStart hook trim   │ DONE   │ ~650     │ Phase 2 ✅     │
│   │ 683→624 lines            │        │ tokens   │                │
├───┼──────────────────────────┼────────┼──────────┼────────────────┤
│ 3 │ MEMORY.md restructure    │ DONE   │ ~1,900   │ Phase 2 ✅     │
│   │ 202→24 lines (88% cut)   │        │ tokens   │                │
├───┼──────────────────────────┼────────┼──────────┼────────────────┤
│ 4 │ Skill File Format Std    │ TODO   │ ~800     │ Phase 3        │
│   │ ≤300 tok per skill       │        │ tokens   │                │
├───┼──────────────────────────┼────────┼──────────┼────────────────┤
│ 5 │ Skill Listing Impact Test│ TODO   │ ???      │ Phase 1 (exp.) │
│   │ Does slim skill = slim   │        │          │                │
│   │ listing in system prompt?│        │          │                │
├───┼──────────────────────────┼────────┼──────────┼────────────────┤
│ 6 │ Manifest/Router          │ DONE   │ ~1,200   │ Phase 4 ✅     │
│   │ capability-map.yaml      │        │ tokens   │                │
├───┼──────────────────────────┼────────┼──────────┼────────────────┤
│   │ TOTAL IMPLEMENTED        │        │ ~5,250   │                │
│   │ TOTAL REMAINING          │        │ ~800+    │                │
│   │ + MCP removal (18→5)     │ DONE   │ ~5,700   │ Prior session  │
│   │ GRAND TOTAL              │        │ ~11,750+ │                │
└───┴──────────────────────────┴────────┴──────────┴────────────────┘
```

### Intervention 4: Skill File Format Standard (TODO)

**Current state**: Skill files range 800-3,000 tokens. Many are prose-heavy.
**Target**: ≤300 tokens each.
**Method**: Apply Format Standard v2.0 (Part 6) to all 19 skills.
**Priority skills** (most-loaded, highest ROI):
1. filesystem-ops (replaces 15 MCP tools — likely verbose)
2. git-ops (replaces 12 MCP tools)
3. session-management (loaded at session start)
4. context-management (loaded at JICM triggers)

### Intervention 5: Skill Listing Impact Test (TODO)

**Hypothesis**: Claude Code's skill listing block in the system prompt mirrors skill
file descriptions. If we slim descriptions, listings shrink too.

**Experiment Protocol**:
```
1. Record current skill listing (system prompt excerpt)
2. Rename one skill's description to 5 words
3. Restart session (or /clear)
4. Compare skill listing — did token count change?

IF YES → Implement Format Standard across all 20 skills (high ROI)
IF NO  → Listings are Claude Code-internal, focus elsewhere
```

### New Intervention 7: Memory MCP Shadowing

**Action**: Build `memory-ops` skill that wraps direct JSON file operations
on `~/.claude/memory/memory.json`, shadowing the auto-provisioned memory MCP.
**Savings**: Eliminates 9 deferred tool definitions (~270 tokens).
**Complexity**: Medium — need jq patterns for graph operations.

---

## Part 10: Token Measurement Methodology

### Precise Measurement Protocol

```
SOURCE: ~/.claude/logs/statusline-input.json

KEY FIELDS:
  cache_creation_input_tokens  → Fixed overhead (system prompt + tools + docs)
  cache_read_input_tokens      → Cached content (conversation history)
  input_tokens                 → New per-turn content
  output_tokens                → Model output
  context_window_size          → Total capacity (200,000)

BASELINE MEASUREMENT:
┌─────────────────────────────────────────────────────────────────┐
│ 1. Start fresh session (or /clear)                              │
│ 2. Send minimal first message ("hello")                        │
│ 3. Read statusline-input.json immediately                      │
│ 4. Record: cache_creation = BASELINE FIXED OVERHEAD             │
│ 5. This captures: system prompt + tools + CLAUDE.md + MEMORY.md│
│    + skill listings + hook output + MCP deferred list          │
│                                                                 │
│ 6. Make intervention (e.g., slim a skill file)                 │
│ 7. Restart session (/clear or new terminal)                    │
│ 8. Repeat steps 2-4                                            │
│ 9. Delta = intervention savings                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Current Baseline

```
From this session's statusline-input.json:
  cache_creation_input_tokens: 18,929
  cache_read_input_tokens:     41,520
  context_window_size:         200,000
  used_percentage:             ~30% at session start
```

### Token Tool Schema Capture

For more precise tool-level measurement, capture the actual JSON payload:

```bash
# Capture API request payload (if available in debug logs)
claude --debug --verbose 2>&1 | grep -A1 '"tools"' > /tmp/tool-schemas.json

# Or estimate from tool definitions
# Each tool definition ≈ 150-400 tokens depending on parameter count
# 21 built-in tools × ~300 avg ≈ 6,300 tokens (immutable)
# Deferred MCP tools: ~30 tokens per listing entry
# 28 deferred tools × 30 = ~840 tokens
```

### What We Can Control

```
IMMUTABLE (~16,000-18,000 tokens):
  Claude Code system instructions   ~10,000
  Built-in tool definitions (21)    ~6,300
  Deferred tool listing header      ~200

CONTROLLABLE (~3,000-5,000 tokens):
  CLAUDE.md                         ~600  (was ~2,100, saved ~1,500)
  MEMORY.md                         ~300  (was ~2,400, saved ~2,100)
  Skill listings                    ~2,000 (TEST if reducible — Int. 5)
  MCP deferred list                 ~840  (reduced from ~1,300)
  Hook output                       ~150  (was ~800, saved ~650)
  Git/session context               ~300

TOTAL CONTROLLABLE SAVINGS SO FAR: ~4,250 tokens
```

---

## Part 11: GPT5.2 Best Practices Integration

### What GPT5.2 Got Right (Incorporated)

| # | Recommendation | Status | Implementation |
|---|---------------|--------|----------------|
| 1 | "Treat .claude/ like a runtime" | DONE | Manifest + module pattern |
| 2 | "Agent-runbook style" | PARTIAL | Format Standard v2.0 defined, not yet applied to all skills |
| 3 | "Global safety in policies only" | DONE | CLAUDE.md guardrails = single source |
| 4 | "Micro-prompt budgets ≤200-300 tok" | DEFINED | Hard budget in Format Standard, enforcement pending |
| 5 | "Index + retrieval strategy" | DONE | capability-map.yaml + progressive disclosure |
| 6 | "Two-tier memory" | DONE | MEMORY.md = hot index, topic files = cold storage |
| 7 | "Results cache for expensive outputs" | PARTIAL | .compressed-context-ready.md exists |
| 8 | "Verify prompt caching" | CONFIRMED | 18.9K creation, 41.5K reads — caching works |

### Combined Best Practices Registry

```
MCP DECOMPOSITION (BP-01 through BP-05):
  BP-01: One test per mapped tool (no gaps)
  BP-02: Skill file ≤ 300 tokens (hard budget)
  BP-03: Measure before AND after removal (precise)
  BP-04: Register in manifest immediately (no orphans)
  BP-05: Any removed MCP can return via `claude mcp add` (reversible)

PLUGIN DECOMPOSITION (BP-06 through BP-09):
  BP-06: Extract prompt patterns, not just tool mappings
  BP-07: Assess unique capabilities before decomposing
  BP-08: Plugin hooks → port to .claude/hooks/ if valuable
  BP-09: Plugin skills → compile to Format Standard v2.0

CONTEXT REDUCTION (BP-10 through BP-14):
  BP-10: Always-on content ≤ 1,000 tokens total (CLAUDE.md + MEMORY.md)
  BP-11: Reference, don't repeat (link to files, don't inline)
  BP-12: Measure via cache_creation_input_tokens (precise, not estimated)
  BP-13: Test changes via restart comparison (not mid-session)
  BP-14: Safety/guardrails always stay in CLAUDE.md (never moved to on-demand)

DECOMPOSITION-FIRST (BP-15 through BP-18):
  BP-15: Default verdict is RECONSTRUCT, not RETAIN or SKIP
  BP-16: "Unique capability" = best reason TO reconstruct natively
  BP-17: Only RETAIN if server process is literally required
  BP-18: Even retained MCPs should be re-evaluated periodically

REPRODUCIBILITY (BP-19 through BP-23):
  BP-19: NEVER use ad-hoc Bash(curl) as a "solution" — build a skill
  BP-20: Swiss-army-knife pattern: group related backends into one skill
  BP-21: Each skill = standardized protocol (same interface, same error handling)
  BP-22: Refactor during reconstruction — improve quality, don't just copy
  BP-23: "Can be done with Bash" describes HOW to build the skill, not a reason to skip

TAXONOMY (BP-24 through BP-26):
  BP-24: RECONSTRUCT = take apart + rebuild as tested reusable native skill
  BP-25: SKIP = nothing unique, nothing worth capturing — no action needed
  BP-26: DEFER = potentially valuable but blocked by external dependency
```

---

## Part 12: Architectural Revision Plan

### Dead References After Decomposition

When MCPs are decomposed, references throughout the codebase become stale.
This revision plan identifies and updates all affected locations.

```
AFFECTED FILES — MCP REFERENCES TO UPDATE:
┌─────────────────────────────────────────────────────────────────┐
│ File                                    │ Issue                  │
├─────────────────────────────────────────┼────────────────────────┤
│ .claude/settings.json                   │ Remove stale MCP       │
│                                         │ permissions for removed│
│                                         │ MCPs                   │
├─────────────────────────────────────────┼────────────────────────┤
│ .claude/context/components/AC-*.md      │ May reference MCP tools│
│                                         │ that no longer exist   │
├─────────────────────────────────────────┼────────────────────────┤
│ .claude/context/patterns/*.md           │ May reference old MCP  │
│                                         │ loading tiers          │
├─────────────────────────────────────────┼────────────────────────┤
│ .claude/context/psyche/*-map.md         │ May list MCPs in       │
│                                         │ capability inventories │
├─────────────────────────────────────────┼────────────────────────┤
│ .claude/context/integrations/*.md       │ Capability matrix may  │
│                                         │ reference removed MCPs │
├─────────────────────────────────────────┼────────────────────────┤
│ .claude/skills/*/SKILL.md               │ May mention MCP tools  │
│                                         │ in replacement context │
├─────────────────────────────────────────┼────────────────────────┤
│ .claude/context/troubleshooting/*.md    │ MCP troubleshooting    │
│                                         │ docs for removed MCPs  │
├─────────────────────────────────────────┼────────────────────────┤
│ .claude/context/designs/*.md            │ Design docs may ref    │
│                                         │ old MCP architecture   │
└─────────────────────────────────────────┴────────────────────────┘
```

### Revision Protocol

```
1. SCAN: Grep -r "mcp__" and "MCP" across .claude/ directory
2. CLASSIFY: Each reference as:
   ├── Historical (in registry, lessons, archived) → KEEP with [ARCHIVED] tag
   ├── Active instruction → UPDATE to reference skill/built-in
   ├── Stale permission → REMOVE from settings.json
   └── Dead link → REMOVE or redirect
3. UPDATE: Each active reference
4. VERIFY: No broken references remain
```

---

## Part 13: Jarvis_To_Do_Notes Rewrite

### Current State

The file at `projects/project-aion/ideas/Jarvis_To_Do_Notes` is 169 lines of
semi-structured notes covering MCPs, skills, plugins, environment setup, GitHub
workflow, Aion philosophy, evolutionary principles, and reference projects.

### Proposed Rewrite

**New name**: `projects/project-aion/ideas/development-roadmap.md`

**Structure**:
```markdown
# Jarvis Development Roadmap
## Project Aion — Capability Expansion & Evolution

### 1. MCP & Skill Integration
   (Evaluated MCPs with verdicts, organized by category)

### 2. Environment & Prerequisites
   (Setup requirements, permissions, virtual environments)

### 3. GitHub & Version Control
   (Branch strategy, push patterns, baseline sync)

### 4. Aion Philosophy
   (Flavors: Jarvis/Jeeves/Wallace, evolution principles)

### 5. Self-Evolution Framework
   (Hooks, reflection, benchmarking, version tracking)

### 6. Reference Projects
   (Organized list with brief descriptions and status)

### 7. Anthropic Resources
   (Official skills, plugins, output styles, best practices)
```

**Action**: Rewrite as clean markdown with:
- All MCP entries annotated with decomposition verdicts
- URLs preserved and categorized
- Cross-references to capability-map.yaml and mcp-decomposition-registry.md
- Remove redundant items already implemented
- Flag items still pending

---

## Part 14: Implementation Phases

```
┌─────────────────────────────────────────────────────────────────────┐
│                    IMPLEMENTATION PHASES                              │
├───────┬──────────────────────────────────────────────┬──────────────┤
│ Phase │ Work                                         │ Duration     │
├───────┼──────────────────────────────────────────────┼──────────────┤
│   1   │ MEASURE (research, no code changes)          │ 1 session    │
│       │ ├── Run token measurement protocol           │              │
│       │ ├── Test skill listing impact (Intervention 5)│             │
│       │ ├── Record precise baselines                 │              │
│       │ └── Capture tool schema JSON if possible     │              │
├───────┼──────────────────────────────────────────────┼──────────────┤
│   2   │ SLIM (low-risk reductions)                   │ ✅ DONE      │
│       │ ├── CLAUDE.md split (171→79 lines)           │              │
│       │ ├── SessionStart hook trim                   │              │
│       │ ├── MEMORY.md restructure (202→24 lines)     │              │
│       │ └── Re-measure after each                    │              │
├───────┼──────────────────────────────────────────────┼──────────────┤
│   3   │ STANDARDIZE (skill format)                   │ 1-2 sessions │
│       │ ├── Apply Format Standard v2.0 to 4 MCP-     │              │
│       │ │   replacement skills                       │              │
│       │ ├── Apply to 3-5 most-used skills            │              │
│       │ ├── Build memory-ops shadow skill            │              │
│       │ └── Re-measure                               │              │
├───────┼──────────────────────────────────────────────┼──────────────┤
│   4   │ MANIFEST (architectural)                     │ ✅ DONE      │
│       │ ├── capability-map.yaml created              │              │
│       │ ├── Routing rules added                      │              │
│       │ └── CLAUDE.md references manifest            │              │
├───────┼──────────────────────────────────────────────┼──────────────┤
│   5   │ PIPELINE DOCS (formalization)                │ ✅ DONE      │
│       │ ├── mcp-decomposition-registry.md updated    │              │
│       │ ├── mcp-loading-strategy.md simplified       │              │
│       │ └── Decision trees formalized                │              │
├───────┼──────────────────────────────────────────────┼──────────────┤
│   6   │ RECONSTRUCT (new skills from decomposition)  │ 2-3 sessions │
│       │ ├── memory-ops skill (shadow memory MCP)     │              │
│       │ ├── Evaluate: Cognee, n8n, MongoDB, MindsDB  │              │
│       │ ├── Build skills for high-value decomposed   │              │
│       │ │   MCPs (perplexity-search, arxiv-search,   │              │
│       │ │   etc.) as needed                          │              │
│       │ └── Integrate community skills               │              │
├───────┼──────────────────────────────────────────────┼──────────────┤
│   7   │ ARCHITECTURAL REVISION                       │ 1 session    │
│       │ ├── Scan all .claude/ for dead MCP refs      │              │
│       │ ├── Update active instructions               │              │
│       │ ├── Clean stale permissions                  │              │
│       │ ├── Rewrite Jarvis_To_Do_Notes as roadmap.md │              │
│       │ └── Update decision trees to v3.0 paradigm   │              │
├───────┼──────────────────────────────────────────────┼──────────────┤
│   8   │ ONGOING PIPELINE                             │ Continuous   │
│       │ ├── Apply pipeline to any new MCP/plugin     │              │
│       │ ├── Periodic re-evaluation of retained MCPs  │              │
│       │ └── Integrate new Anthropic skills as released│             │
└───────┴──────────────────────────────────────────────┴──────────────┘
```

---

## Part 15: Verification Plan

### Phase Gates

| Phase | Gate Criteria | Measurement |
|-------|-------------|-------------|
| 1 | Precise token baselines recorded | statusline JSON captured |
| 2 | ≥3,000 tokens saved | ✅ ~4,050 saved |
| 3 | ≥7 skill files at ≤300 tokens | Count conforming skills |
| 4 | Manifest created and referenced | ✅ capability-map.yaml exists |
| 5 | Pipeline documented with decision trees | ✅ Registry v3.0 |
| 6 | memory-ops skill functional | Test all 9 graph operations |
| 7 | Zero dead MCP references in active docs | Grep verification |

### Projected Savings Summary

```
┌──────────────────────────────────┬──────────┬──────────┐
│ Intervention                     │ Savings  │ Status   │
├──────────────────────────────────┼──────────┼──────────┤
│ MCP removal (18 → 5)            │ ~5,700   │ ✅ DONE   │
│ CLAUDE.md split                  │ ~1,500   │ ✅ DONE   │
│ SessionStart hook trim           │ ~650     │ ✅ DONE   │
│ MEMORY.md restructure            │ ~1,900   │ ✅ DONE   │
│ Skill format optimization        │ ~800     │ TODO     │
│ Manifest/router                  │ ~1,200   │ ✅ DONE   │
│ Memory MCP shadow                │ ~270     │ TODO     │
├──────────────────────────────────┼──────────┼──────────┤
│ TOTAL PROJECTED                  │ ~12,020  │          │
│ (~6.0% of 200K context window)   │          │          │
└──────────────────────────────────┴──────────┴──────────┘

Additional benefits:
  - 13 fewer MCP server processes
  - Deterministic skill routing via manifest
  - Standardized pipeline for future conversions
  - Prompt caching reduces per-turn cost by ~90%
  - Decomposition-first paradigm prevents future bloat
```

---

## Critical Files

| File | Action | Phase |
|------|--------|-------|
| `CLAUDE.md` | Slimmed to ~79 lines | ✅ Done |
| `.claude/hooks/session-start.sh` | Trimmed output | ✅ Done |
| `memory/MEMORY.md` | Restructured + 4 topic files | ✅ Done |
| `.claude/context/psyche/capability-map.yaml` | Created (221 lines) | ✅ Done |
| `.claude/context/reference/mcp-decomposition-registry.md` | Updated w/ pipelines | ✅ Done |
| `.claude/context/patterns/mcp-loading-strategy.md` | Simplified (66 lines) | ✅ Done |
| `.claude/skills/*/SKILL.md` | Reformat to Standard v2.0 | Phase 3 |
| `.claude/skills/memory-ops/SKILL.md` | Create (shadow memory MCP) | Phase 6 |
| `projects/project-aion/ideas/development-roadmap.md` | Rewrite To Do Notes | Phase 7 |
| `.claude/context/reference/mcp-decomposition-registry.md` | Update decision trees to v3.0 | Phase 7 |
| All `.claude/` files with MCP references | Scan + update | Phase 7 |

---

*Decomposition & Reconstruction Pipeline Design v4.0 — 2026-02-08*
*Paradigm: Decompose Everything. Reconstruct Natively. Only Retain Server-Dependent MCPs.*
