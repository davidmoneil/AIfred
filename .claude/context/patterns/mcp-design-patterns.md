# MCP Design Patterns

**Created**: 2026-01-09
**PR Reference**: PR-8.5 MCP Expansion
**Status**: Active

---

## Purpose

This document provides specific design patterns and best practices for each validated MCP, derived from the comprehensive MCP validation process. Use this guide to:
1. Select the right MCP for a task
2. Use MCP tools effectively
3. Avoid common pitfalls
4. Optimize context usage

---

## Quick Reference

| MCP | Tier | Tokens | Primary Use Case | Key Pattern |
|-----|------|--------|------------------|-------------|
| memory | 1 | ~1.8K | Persistent decisions | Entity-first storage |
| filesystem | 1 | ~2.8K | External file access | Workspace-aware selection |
| fetch | 1 | ~0.5K | Web content | Chunk large pages |
| git | 1 | ~2.5K | Repository operations | Bash-first for simple ops |
| github | 2 | ~5K | Platform automation | CLI for simple, MCP for complex |
| context7 | 2 | ~2K | Library documentation | Resolve-then-query |
| sequential-thinking | 2 | ~1K | Complex reasoning | Problem decomposition |
| brave-search | 2 | ~3K | Web search | API-based reliability |
| arxiv | 2 | ~2K | Academic papers | Full workflow pattern |
| datetime | 2 | ~1K | Timezone operations | IANA timezone codes |
| wikipedia | 2 | ~2K | Reference lookups | Search-then-read |
| chroma | 2 | ~4K | Vector storage | Collection lifecycle |
| desktop-commander | 2 | ~8K | System operations | Process management |
| perplexity | 2 | ~3K | AI-powered search | Strip thinking tags |
| gptresearcher | 2 | ~3K | Deep research | Research-then-report |
| playwright | 3 | ~6K | Browser automation | Snapshot over screenshot |
| lotus-wisdom | 3 | ~2K | Contemplative reasoning | Specialized use only |

---

## Tier 1: Always-On MCPs

### Memory MCP

**Pattern: Entity-First Storage**

Store decisions, not details. Use for relationships and cross-session recall.

```
GOOD: Create entity "Decision: Use Redis for caching"
      with observation "Chosen over Memcached for persistence"
      related to "Project: User Service"

BAD:  Store entire configuration file content
      Store step-by-step implementation details
```

**Best Practices**:
- Create entities for decisions, milestones, and relationships
- Use observations for rationale and context
- Use relations to connect related decisions
- Query with `search_nodes` for keyword matches
- Use `open_nodes` for specific entity retrieval

**Anti-Patterns**:
- Storing detailed procedures (use context files instead)
- Creating entities without relations (orphan nodes)
- Duplicating information already in context files

---

### Filesystem MCP

**Pattern: Workspace-Aware Selection**

```
Inside Jarvis workspace → Use built-in Read/Write/Edit
Outside workspace → Use Filesystem MCP
```

**Best Practices**:
- Use for accessing files outside the allowed workspace
- Prefer built-in tools for workspace files (better integration)
- Check `list_allowed_directories` before operations
- Use `directory_tree` for structure overview

**Key Tools**:
| Tool | When to Use |
|------|-------------|
| `read_text_file` | Reading external files |
| `read_multiple_files` | Batch reading |
| `search_files` | Finding files by pattern |
| `directory_tree` | Understanding structure |

---

### Fetch MCP

**Pattern: Chunked Reading**

For large web pages, use pagination parameters.

```
First request:  fetch(url, max_length=5000, start_index=0)
Second request: fetch(url, max_length=5000, start_index=5000)
```

**Best Practices**:
- Set `max_length` to control response size
- Use `start_index` for pagination on large pages
- Set `raw=true` only when HTML structure matters
- Prefer `WebFetch` built-in for simple content retrieval

**When to Use Fetch MCP vs WebFetch**:
| Scenario | Tool |
|----------|------|
| Simple page content | WebFetch (built-in) |
| Large page (chunked) | Fetch MCP |
| Raw HTML needed | Fetch MCP with `raw=true` |
| Content + analysis prompt | WebFetch (has prompt param) |

---

### Git MCP

**Pattern: Bash-First for Simple Operations**

```
Simple status/log/diff → Bash(git)
Complex multi-step automation → Git MCP
Natural language workflows → engineering-workflow-skills
```

**Best Practices**:
- Use Bash for quick git commands
- Use Git MCP when chaining multiple operations programmatically
- Git MCP provides structured output better for parsing

**Tool Selection**:
| Task | Recommended |
|------|-------------|
| `git status` | Bash(git status) |
| `git log -5` | Bash(git log) |
| Multi-file staging + commit | Git MCP or /commit plugin |
| Branch operations | Git MCP `git_create_branch` |

---

## Tier 2: Task-Scoped MCPs

### GitHub MCP

**Pattern: CLI for Simple, MCP for Complex**

```
View issues → gh issue list
Create PR → gh pr create
Complex workflows → GitHub MCP
Security scanning → GitHub MCP (exclusive feature)
```

**Best Practices**:
- Use `gh` CLI for quick operations
- Use GitHub MCP for multi-step automation
- GitHub MCP required for code_security features
- PAT authentication via GITHUB_PERSONAL_ACCESS_TOKEN env var

**Discovery #7 Impact**: May not load when 15+ MCPs active. Reduce MCP count if needed.

---

### Context7 MCP

**Pattern: Resolve-Then-Query**

Always resolve library ID before querying documentation.

```
Step 1: resolve-library-id("react hooks")
        → Returns: /facebook/react, /vercel/swr, etc.

Step 2: get-library-docs("/facebook/react", topic="useState")
        → Returns version-specific documentation
```

**Best Practices**:
- Always resolve library ID first (prevents hallucination)
- Specify version when querying if known
- Use for up-to-date library documentation
- ~20,000 indexed libraries available

**Anti-Pattern**: Querying without resolving first may return wrong library's docs.

---

### Sequential Thinking MCP

**Pattern: Problem Decomposition**

Use for complex, multi-step reasoning that benefits from explicit thought chains.

```
Good use: "Analyze tradeoffs of microservices vs monolith for this codebase"
          → Generates structured thought chain

Poor use: "What is 2+2?"
          → Overhead not justified
```

**Best Practices**:
- Use for architectural decisions
- Use for complex debugging scenarios
- Produces structured, revisable reasoning
- Single tool: `sequentialthinking`

---

### Brave Search MCP

**Pattern: API-Based Reliability**

Preferred over scraping-based search MCPs due to reliability.

```
brave_web_search(query, count=10)
→ Returns structured results with titles, URLs, descriptions
```

**Best Practices**:
- Requires BRAVE_API_KEY environment variable
- Free tier has rate limits (use sparingly)
- Returns structured JSON results
- More reliable than scraping-based alternatives

**Why Brave over DuckDuckGo**: DuckDuckGo bot detection blocks automated requests. Brave uses official API.

---

### arXiv MCP

**Pattern: Full Workflow**

```
1. search_papers(query, categories, max_results)
   → Get paper IDs and abstracts

2. download_paper(paper_id)
   → Download PDF to local storage

3. convert_pdf_to_text(paper_id) [if available]
   → Convert to readable text

4. Read converted text or use PDF reader
```

**Best Practices**:
- Always search first to get paper IDs
- Categories use arXiv codes: cs.AI, cs.MA, etc.
- `list_papers` has HTTP 400 bug (non-critical)
- Good for academic research workflows

---

### DateTime MCP

**Pattern: IANA Timezone Codes**

```
get_current_datetime(timezone="America/Los_Angeles")
→ Returns ISO 8601 formatted datetime
```

**Best Practices**:
- Use IANA timezone codes (America/New_York, Europe/London)
- Single tool, simple usage
- Use Bash(date) for simple timestamps without timezone needs

---

### Wikipedia MCP

**Pattern: Search-Then-Read**

```
1. search(query, limit=10)
   → Returns article titles and snippets

2. get_article(title)
   → Returns full article in clean markdown
```

**Best Practices**:
- Search returns ranked results with snippets
- Full article retrieval returns clean markdown
- Good for reference lookups and background research

---

### Chroma MCP

**Pattern: Collection Lifecycle**

```
1. chroma_create_collection(name, embedding_function="default")
2. chroma_add_documents(collection, documents, ids, metadatas)
3. chroma_query_documents(collection, query_texts, n_results)
4. chroma_delete_collection(name)  // Cleanup when done
```

**Best Practices**:
- Always create collection before adding documents
- Use semantic queries, not keyword matching
- Distance scores: lower = more similar
- Clean up test collections after use
- Supports metadata filtering with `where` parameter

**Embedding Functions**: default, cohere, openai, jina, voyageai, ollama, roboflow

---

### Desktop Commander MCP

**Pattern: Process Management**

For long-running operations, use process management tools.

```
1. start_process(command, timeout_ms)
   → Returns PID

2. interact_with_process(pid, input)
   → Send commands to running process

3. read_process_output(pid)
   → Get output from process

4. force_terminate(pid)
   → Stop process when done
```

**Best Practices**:
- 30+ tools available, use specific tools over generic
- `list_directory` with depth parameter for recursive listing
- `start_search` for streaming file/content search
- Prefer specific tools: `read_file` over `execute_command` with cat

**Key Tools**:
| Tool | Purpose |
|------|---------|
| `read_file` | Read files with pagination |
| `list_directory` | Directory listing with depth |
| `start_search` | Streaming file/content search |
| `start_process` | Run commands with management |

---

### Perplexity MCP

**Pattern: Strip Thinking Tags**

**Discovery #8**: Use `strip_thinking=true` for context efficiency.

```
perplexity_research(query, strip_thinking=true)
→ Returns answer without <think> reasoning tags
→ Same quality, fewer tokens
```

**Tool Comparison**:
| Tool | Speed | Depth | Best For |
|------|-------|-------|----------|
| `perplexity_search` | Fast | Shallow | Quick facts |
| `perplexity_ask` | Fast | Medium | Q&A with citations |
| `perplexity_research` | Medium | Deep | Multi-source synthesis |
| `perplexity_reason` | Slow | Very Deep | Complex reasoning |

**Best Practices**:
- Always use `strip_thinking=true` for research/reason tools
- Use `perplexity_search` for quick lookups
- Use `perplexity_research` for comprehensive answers
- Returns citations with answers

---

### GPTresearcher MCP

**Pattern: Research-Then-Report**

```
1. deep_research(query)
   → Returns research_id + initial context

2. get_research_context(research_id)
   → Get full research context

3. write_report(research_id, custom_prompt)
   → Generate formatted report

4. get_research_sources(research_id)
   → List all sources used
```

**Discovery #9**: Requires Python 3.13+ venv.

**Installation Note**:
```bash
# Create venv with Python 3.13
uv venv --python 3.13 /path/to/.venv
source /path/to/.venv/bin/activate
pip install gpt-researcher

# MCP command must use venv Python
/path/to/.venv/bin/python server.py
```

**Best Practices**:
- Use `quick_search` for fast results (9+ sources typical)
- Use `deep_research` for comprehensive research (16+ sources)
- Research ID persists for follow-up queries
- Requires OpenAI API key and Tavily API key

---

## Tier 3: On-Demand MCPs

### Playwright MCP

**Pattern: Snapshot Over Screenshot**

**Discovery #10**: Accessibility snapshots are more efficient than screenshots.

```
1. browser_navigate(url)
2. browser_snapshot()  // Returns YAML accessibility tree
3. browser_click(ref="e6")  // Click by ref from snapshot
4. browser_close()
```

**Accessibility Snapshot Format**:
```yaml
- heading "Page Title" [ref=e1]
- button "Login" [ref=e6]
- textbox "Email" [ref=e7]
```

**Best Practices**:
- Use `browser_snapshot` for navigation (not screenshots)
- Elements have refs like `[ref=e6]` for interaction
- Use `browser_take_screenshot` only for visual verification
- Always `browser_close` when done

**When to Use Playwright vs browser-automation**:
| Task | Tool |
|------|------|
| QA test scripts | Playwright MCP |
| Deterministic automation | Playwright MCP |
| Natural language browsing | browser-automation plugin |
| Form filling (NL) | browser-automation plugin |

---

### Lotus Wisdom MCP

**Pattern: Specialized Contemplative Reasoning**

Use only for tasks benefiting from contemplative/philosophical reasoning framework.

```
lotuswisdom(query, mode="begin")
→ Returns structured contemplative response
```

**Best Practices**:
- Niche use case - philosophical/contemplative reasoning
- Not for general development tasks
- Single tool: `lotuswisdom`

---

## Critical Discoveries

### Discovery #7: "Connected" ≠ "Tools Available"

When 15+ MCPs are active, some tools won't load due to context limits.

**Symptoms**: `claude mcp list` shows "Connected" but tools not in session.

**Solution**:
- Limit to 10-12 MCPs per session
- Use batch validation approach for testing
- Prioritize MCPs based on task type

### Discovery #11: Research MCP Complementarity

| Tool | Speed | Depth | Sources |
|------|-------|-------|---------|
| `perplexity_search` | Fast | Shallow | AI-curated |
| `brave_web_search` | Fast | Shallow | Web index |
| `gptresearcher_quick_search` | Fast | Shallow | 9+ sources |
| `perplexity_research` | Medium | Deep | Multi-source |
| `gptresearcher_deep_research` | Slow | Very Deep | 16+ sources |

**Selection Guide**:
- Quick fact check → `perplexity_search` or `brave_web_search`
- Current events → `brave_web_search`
- Comprehensive answer → `perplexity_research`
- Academic depth → `gptresearcher_deep_research`

---

## MCP Session Lifecycle (PR-8.5 Protocol)

### Overview

MCPs are managed across session boundaries using the MCP Initialization Protocol. This ensures context-efficient loading based on planned work.

### Lifecycle Flow

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  SESSION END    │────▶│  SESSION GAP    │────▶│  SESSION START  │
│                 │     │                 │     │                 │
│  1. Update      │     │  (User decides  │     │  1. Hook reads  │
│     session-    │     │   on MCPs)      │     │     Next Step   │
│     state.md    │     │                 │     │                 │
│  2. Capture     │     │                 │     │  2. Suggests    │
│     MCP state   │     │                 │     │     MCPs        │
│  3. Predict     │     │                 │     │                 │
│     next needs  │     │                 │     │  3. User        │
│  4. Disable     │     │                 │     │     enables     │
│     unused      │     │                 │     │     + /clear    │
└─────────────────┘     └─────────────────┘     └─────────────────┘
```

### Keyword-Based MCP Selection

The `suggest-mcps.sh` script analyzes "Next Step" in session-state.md:

| Keyword Category | MCPs Suggested |
|------------------|----------------|
| GitHub/PR work | github |
| Research tasks | brave-search, perplexity, gptresearcher |
| Documentation | context7, wikipedia |
| Academic work | arxiv |
| Complex design | sequential-thinking |
| Browser automation | playwright (Tier 3 warning) |
| System operations | desktop-commander |
| Vector/semantic | chroma |
| Time-sensitive | datetime |

### Exit Checklist Integration

At session end (per session-exit.md):

1. **Update "Next Step"** — Describe planned next work
2. **Run suggest-mcps.sh** — Get predictions
3. **Update MCP State section** — Document current + predicted
4. **Disable unneeded MCPs** — Clean for next session

### Consistent Invocation Patterns

| Phase | Tool/Script | Purpose |
|-------|-------------|---------|
| Session End | `.claude/scripts/suggest-mcps.sh` | Capture state |
| Session End | `.claude/scripts/disable-mcps.sh` | Clean up |
| Session Start | `session-start.sh` hook | Auto-suggest |
| Session Start | `.claude/scripts/enable-mcps.sh` | Enable recommended |

### Best Practice: MCP State Documentation

Always maintain MCP state in session-state.md:

```markdown
### MCP State (PR-8.5 Protocol)

**Current Session**:
- **Tier 1**: memory, filesystem, fetch, git
- **Tier 2 (Enabled)**: github, context7
- **Tier 3**: (none)

**Next Session Prediction**:
- Keywords: research, documentation
- Suggested: brave-search, perplexity, context7, wikipedia
```

---

## Related Documentation

- @.claude/context/patterns/mcp-loading-strategy.md - Full loading protocol
- @.claude/context/patterns/mcp-validation-harness.md - Validation process
- @.claude/context/patterns/context-budget-management.md - Token budgets
- @.claude/context/integrations/mcp-installation.md - Installation guide
- @.claude/context/integrations/capability-matrix.md - Tool selection
- @.claude/context/workflows/session-exit.md - Exit procedure

---

*MCP Design Patterns v1.1 — PR-8.5 MCP Init Protocol (2026-01-09)*
