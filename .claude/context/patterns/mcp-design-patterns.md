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

## PR-9.2: Research Tool Routing (Context-Lifecycle Aware)

### Decision Flowchart

```
Research Task Received
        │
        ├── Q1: Is this a quick fact check?
        │   └── YES → WebSearch (built-in) or perplexity_search
        │             • No MCP load required for WebSearch
        │             • Perplexity needs Tier 2 enable
        │
        ├── Q2: Current events or news?
        │   └── YES → brave_web_search
        │             • Tier 2 MCP, check if enabled
        │             • Fresh web index
        │
        ├── Q3: Need citations for Q&A?
        │   └── YES → perplexity_ask
        │             • Medium depth, fast response
        │             • Returns inline citations
        │
        ├── Q4: Academic paper search?
        │   └── YES → arxiv_search + download_paper
        │             • Tier 2 MCP
        │             • Full paper workflow
        │
        ├── Q5: Reference/encyclopedia?
        │   └── YES → wikipedia_search
        │             • Clean markdown output
        │             • Tier 2 MCP
        │
        ├── Q6: Multi-source synthesis (4-8 sources)?
        │   └── YES → perplexity_research (strip_thinking=true)
        │             • Medium time, deep results
        │             • Use strip_thinking for token efficiency
        │
        └── Q7: Comprehensive research (16+ sources)?
            └── YES → Consider delegation decision:
                      │
                      ├── Context headroom > 50%?
                      │   └── /agent deep-research "topic"
                      │       • Custom agent, isolated context
                      │       • Uses gptresearcher + perplexity + WebSearch
                      │       • Results stored in file
                      │
                      └── Context headroom < 50%?
                          └── gptresearcher_deep_research directly
                              • Avoid agent overhead
                              • OR: /checkpoint first, then agent
```

### Context-Aware Research Selection

| Research Depth | Tool | MCP Tier | Token Cost | Context Impact |
|----------------|------|----------|------------|----------------|
| Quick fact | WebSearch | Built-in | ~0 | Minimal |
| Quick fact | perplexity_search | 2 | ~3K | Low |
| Current events | brave_web_search | 2 | ~3K | Low |
| Q&A | perplexity_ask | 2 | ~3K | Low-Medium |
| Reference | wikipedia_search | 2 | ~2K | Low |
| Academic | arxiv_search | 2 | ~2K | Low |
| Multi-source | perplexity_research | 2 | ~3K | Medium (large results) |
| Comprehensive | gptresearcher | 2 | ~5K | **High** (16+ source output) |
| Comprehensive | deep-research agent | N/A | Isolated | **Isolated** |

### Research Tool Context Lifecycle Integration

#### Before Research: Check Context State

```
Pre-Research Checklist:
1. Check context estimate: cat .claude/logs/context-estimate.json
2. If percentage > 50%:
   - Quick research: Proceed directly
   - Deep research: Consider agent delegation
   - Comprehensive: /checkpoint first OR use agent
3. If Tier 2 MCPs needed but disabled:
   - Run: .claude/scripts/enable-mcps.sh perplexity brave-search
   - Run: /clear to load MCPs
```

#### During Research: Monitor Impact

Research tools vary in output size:

| Tool | Typical Output Size | Context Impact |
|------|---------------------|----------------|
| WebSearch | 1-2K tokens | Low |
| perplexity_search | 2-3K tokens | Low |
| perplexity_ask | 3-5K tokens | Medium |
| perplexity_research | 5-10K tokens | **High** |
| gptresearcher_deep_research | 10-20K tokens | **Very High** |
| arxiv download + convert | 20-50K tokens per paper | **Extreme** |

**Context Protection Strategies**:

1. **Use `strip_thinking=true`** for perplexity_research/reason
2. **Limit arxiv downloads** to 1-2 papers per session
3. **Delegate comprehensive research** to agents (isolated context)
4. **Store research results** in files, not conversation

#### After Research: Record and Manage

```
Post-Research Actions:
1. Store key findings in Memory MCP (decisions only)
2. Write detailed results to context file if valuable
3. If context > 60%: Consider checkpoint
4. Update session-state.md with research summary
```

### Agent Research Delegation

When to delegate research to `/agent deep-research`:

| Condition | Direct Tool | Agent Delegation |
|-----------|-------------|------------------|
| Context < 50% | ✅ Proceed | Optional |
| Context 50-70% | ⚠️ Caution | ✅ Recommended |
| Context > 70% | ❌ Checkpoint first | ✅ Required |
| 16+ sources needed | ❌ Too much context | ✅ Required |
| Cross-session reference | ❌ Lost on clear | ✅ Results file persists |

**Agent Delegation Pattern**:

```
/agent deep-research "Comprehensive analysis of Docker networking"

Benefits:
- Isolated context (doesn't bloat main session)
- Results written to file (persists across /clear)
- Uses multiple tools: gptresearcher, perplexity, WebSearch
- Structured output with citations
```

### Research Tool Contingencies

#### Contingency 1: Research Triggers Context Warning

```
Scenario: perplexity_research returns 15K tokens, pushing context to 55%

Response:
1. JICM context-accumulator.js detects 55% (warning threshold)
2. Warning logged but no action (threshold is 75%)
3. Continue work, but avoid additional large research

Prevention:
- Use perplexity_ask instead of perplexity_research for medium needs
- Delegate to agent for comprehensive research
```

#### Contingency 2: Agent Research Completes, Need Results in Main Session

```
Scenario: deep-research agent wrote results to file, need key points

Response:
1. Agent returns with file path
2. Read SUMMARY section only (not full results)
3. Store key decisions in Memory MCP
4. Reference file path for details

Pattern:
- Read .claude/agent-outputs/deep-research-<timestamp>.md
- Extract: Summary, Key Findings, Recommendations
- Skip: Full source analysis, raw data
```

#### Contingency 3: Multiple Research Tasks in Single Session

```
Scenario: User requests 3 different research topics

Response:
1. First topic: Direct tools (perplexity_search/research)
2. Check context after first topic
3. If context > 50%: Delegate remaining to agents
4. If context < 50%: Continue with direct tools

Tracking:
- Log each research task to session-state.md
- Track cumulative token impact
- Checkpoint before third research if context high
```

#### Contingency 4: Research During Orchestrated Task

```
Scenario: Orchestration phase requires research

Response:
1. Check phase definition for research scope
2. If phase is "Research": Use agents (context isolation)
3. If phase is "Implementation" with incidental research:
   - Quick facts: Direct tools
   - Deep dive: Delegate or defer to research phase

Orchestration Integration:
- /orchestration:plan should identify research phases
- Research phases auto-delegate to agents
- Track in .claude/orchestration/task-<id>/phase-research.md
```

### Research MCP Loading Protocol

```
Session Start with Research Planned:
1. session-start.sh detects "research" in Next Step
2. Suggests: enable=[brave-search, perplexity, arxiv]
3. User runs: .claude/scripts/enable-mcps.sh brave-search perplexity arxiv && /clear
4. MCPs loaded, research tools available

Mid-Session Research Need:
1. Check if needed MCP is enabled: .claude/scripts/list-mcp-status.sh
2. If disabled: /checkpoint → enable → /clear → resume
3. If enabled: Use directly

Post-Research MCP Cleanup:
1. If research complete and MCPs not needed:
   - .claude/scripts/disable-mcps.sh perplexity gptresearcher arxiv
   - Changes apply on next /clear
```

### Research Validation Scenarios (PR-9.2 Acceptance)

| Scenario | Input | Expected | Token Impact |
|----------|-------|----------|--------------|
| Quick fact | "Capital of France?" | WebSearch → "Paris" | <1K |
| Current event | "Latest Docker release?" | brave_web_search → version | <3K |
| Q&A with cite | "What is RAG?" | perplexity_ask → definition + citations | 3-5K |
| Academic | "Transformer architecture papers" | arxiv_search → paper list | <3K |
| Reference | "What is Kubernetes?" | wikipedia_search → article | 3-5K |
| Multi-source | "Compare Redis vs Memcached" | perplexity_research → comparison | 5-10K |
| Comprehensive | "Docker networking best practices" | /agent deep-research → file | Isolated |

---

## Context Lifecycle Tracking (PR-9.2 Extension)

### Agent Context Compression Triggers

Agents and subagents can trigger context compression through several mechanisms:

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    AGENT CONTEXT IMPACT TRACKING                         │
│                                                                          │
│  Agent/Subagent Execution                                                │
│         │                                                                │
│         ├── PostToolUse hook (context-accumulator.js)                   │
│         │   └── Tracks: tool calls, estimated tokens                    │
│         │                                                                │
│         ├── SubagentStop hook (subagent-stop.js)                        │
│         │   └── Checks: context % after agent completion                │
│         │   └── Triggers: checkpoint if > 75%                           │
│         │                                                                │
│         └── Logs to: .claude/logs/context-estimate.json                 │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### Tracking Records

#### context-estimate.json Structure

```json
{
  "sessionStart": "2026-01-09T19:32:03.286Z",
  "totalTokens": 30014,
  "toolCalls": 25,
  "lastUpdate": "2026-01-09T21:45:12.000Z",
  "percentage": 15.0,
  "triggerHistory": [
    { "timestamp": "2026-01-09T20:30:00Z", "type": "warning", "percentage": 52 },
    { "timestamp": "2026-01-09T21:15:00Z", "type": "checkpoint", "percentage": 76 }
  ]
}
```

#### Session Restart Records

Session restarts (via /clear or autocompact) are tracked in:

```
.claude/logs/session-start-diagnostic.log

Format:
TIMESTAMP | SessionStart | source=<source> | session=<session_id>
TIMESTAMP | PreCompact | Auto-checkpoint triggered
TIMESTAMP | JICM | Auto-triggered at <percentage>% estimated
```

### Context Monitoring Effectiveness

#### JICM (Jarvis Intelligent Context Management) Metrics

| Metric | Source | Purpose |
|--------|--------|---------|
| Token estimate | context-accumulator.js | Track running total |
| Tool calls | context-accumulator.js | Correlate tools to tokens |
| Warning triggers | context-accumulator.js | 50% threshold hits |
| Checkpoint triggers | context-accumulator.js | 75% threshold hits |
| Agent completions | subagent-stop.js | Post-agent context check |
| Session sources | session-start.sh | startup/resume/clear/compact |

#### Effectiveness Monitoring Commands

```bash
# View current context estimate
cat .claude/logs/context-estimate.json

# View trigger history
jq '.triggerHistory' .claude/logs/context-estimate.json

# View session restart log
tail -20 .claude/logs/session-start-diagnostic.log

# View JICM trigger log
cat .claude/logs/jicm-triggers.log
```

### Manual vs Auto-Triggered Compression

| Trigger | Mechanism | When | User Action |
|---------|-----------|------|-------------|
| **Manual** | `/checkpoint` command | User decides | /checkpoint → /clear |
| **Manual** | `/smart-compact` command | User decides | /smart-compact → /clear |
| **Auto Warning** | context-accumulator.js | 50% threshold | None (warning only) |
| **Auto Checkpoint** | context-accumulator.js | 75% threshold | None (auto-clear via watcher) |
| **Auto Compact** | Claude Code built-in | ~100% actual | Context summarized (lossy) |

### Agent-Specific Context Tracking

#### Subagent Context Impact

| Subagent | Typical Context Impact | Tracking Location |
|----------|------------------------|-------------------|
| Explore | Low (returns summary) | subagent-stop.js |
| Plan | Medium (detailed plan) | subagent-stop.js |
| general-purpose | Variable | subagent-stop.js |
| feature-dev:* | High (blueprints) | subagent-stop.js |

#### Custom Agent Context Impact

| Custom Agent | Context Impact | Result Storage |
|--------------|----------------|----------------|
| deep-research | **Isolated** | `.claude/agent-outputs/` |
| docker-deployer | **Isolated** | `.claude/agent-outputs/` |
| service-troubleshooter | **Isolated** | `.claude/agent-outputs/` |
| memory-bank-synchronizer | **Isolated** | Direct file updates |

**Key Insight**: Custom agents with `/agent` command run in isolated context — they don't impact main session context. Results are returned as summaries.

### Session State Restart Contingencies

#### Contingency: Unexpected /clear

```
Scenario: User runs /clear without checkpoint

Recovery:
1. SessionStart hook checks for checkpoint file
2. If no checkpoint: "No checkpoint found - starting fresh"
3. User manually recovers from:
   - session-state.md (last known work)
   - Memory MCP (stored decisions)
   - TodoWrite state (incomplete tasks)
```

#### Contingency: Auto-Compact Before JICM Triggers

```
Scenario: Claude Code autocompact runs before JICM 75% threshold

Root Cause: JICM estimates may undercount actual tokens

Recovery:
1. Context already summarized (lossy)
2. Check session-state.md for work state
3. Check Memory MCP for decisions
4. Future: Tune JICM token estimation

Prevention:
- Use conservative thresholds (currently 50%/75%)
- Checkpoint frequently during heavy tool usage
```

#### Contingency: Watcher Fails to Send /clear

```
Scenario: Auto-clear watcher doesn't send /clear

Diagnosis:
1. Check watcher running: cat .claude/context/.watcher-pid
2. Check signal file exists: ls .claude/context/.auto-clear-signal
3. Check macOS accessibility permissions

Recovery:
1. Manual /clear
2. SessionStart loads checkpoint automatically
3. Restart watcher: .claude/scripts/launch-watcher.sh
```

### Context Lifecycle Log Analysis

```bash
# Full session lifecycle view
echo "=== SESSION STARTS ===" && \
grep "SessionStart" .claude/logs/session-start-diagnostic.log | tail -10 && \
echo "=== JICM TRIGGERS ===" && \
cat .claude/logs/jicm-triggers.log 2>/dev/null || echo "No JICM triggers" && \
echo "=== CURRENT ESTIMATE ===" && \
cat .claude/logs/context-estimate.json 2>/dev/null || echo "No estimate file"
```

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
- @.claude/context/integrations/capability-map.yaml - Tool selection
- @.claude/context/workflows/session-exit.md - Exit procedure

---

*MCP Design Patterns v1.2 — PR-9.2 Research Tool Routing + Context Lifecycle (2026-01-09)*
