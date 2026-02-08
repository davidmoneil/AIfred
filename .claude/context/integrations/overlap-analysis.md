# Tool Overlap & Conflict Analysis

**Created**: 2026-01-06
**Updated**: 2026-01-09 (PR-9.5)
**Version**: 1.2
**PR Reference**: PR-5 (Core Tooling), PR-8.5 (Research MCPs), PR-9 (Selection Intelligence)
**Status**: PARTIALLY OUTDATED

> **v5.9.0 NOTE (2026-02-08)**: Most overlaps documented here have been RESOLVED
> by the MCP decomposition milestone. Filesystem MCP, Git MCP, and most research
> MCPs have been removed. Built-in tools are now the sole mechanism for file/git ops.
> The overlap analysis for remaining MCPs (memory, local-rag, playwright) is still
> valid. **Current selection guide**: `.claude/context/psyche/capability-map.yaml`.

---

## Purpose

This document identifies overlapping functionality between tools and establishes clear selection rules to prevent conflicts and redundancy.

**Related Selection Docs**:
- @selection-intelligence-guide.md — Quick selection reference
- @mcp-design-patterns.md — Research tool routing (PR-9.2)

---

## Identified Overlaps

### 1. File Operations Overlap

**Overlapping Tools**:
- Built-in: `Read`, `Write`, `Edit`, `Glob`, `Grep`
- MCP: Filesystem MCP (`read_text_file`, `write_file`, `edit_file`, `search_files`)
- Bash: `cat`, `echo >`, `sed`, `find`, `grep`

**Conflict Potential**: HIGH - Same operations available via multiple mechanisms

**Resolution Rule**:
| Scenario | Use | Rationale |
|----------|-----|-----------|
| Files inside Jarvis workspace | Built-in tools | Native integration, change tracking |
| Files outside workspace | Filesystem MCP | Controlled access with allowlist |
| Complex text processing | `Bash(sed/awk)` | When regex replacement is complex |
| Binary files | Filesystem MCP | Built-in Read works for images/PDFs |

**Selection Priority**: Built-in → Filesystem MCP → Bash

---

### 2. Git Operations Overlap

**Overlapping Tools**:
- Bash: `git status`, `git commit`, `git push`, etc.
- MCP: Git MCP (`git_status`, `git_commit`, etc.)
- Plugin: `commit-commands` (`/commit`, `/commit-push-pr`)

**Conflict Potential**: MEDIUM - Multiple ways to do same git operations

**Resolution Rule**:
| Scenario | Use | Rationale |
|----------|-----|-----------|
| Quick status/log/diff | `Bash(git)` | Simpler, no MCP overhead |
| Single commit | `Bash(git commit)` | Direct, no plugin complexity |
| Multi-file commit with message | `/commit` plugin | Auto-staging, message generation |
| Commit + push + PR | `/commit-push-pr` | End-to-end workflow |
| Automated workflows | Git MCP | When running from scripts |

**Selection Priority**: Plugin (for workflows) → Bash(git) → Git MCP

---

### 3. Web Fetching Overlap

**Overlapping Tools**:
- Built-in: `WebFetch` (converts to markdown)
- MCP: Fetch MCP (`fetch` with chunking)
- Bash: `curl`, `wget`

**Conflict Potential**: MEDIUM - Different capabilities

**Resolution Rule**:
| Scenario | Use | Rationale |
|----------|-----|-----------|
| Read web page content | `WebFetch` | Auto markdown conversion |
| Large page (chunked) | Fetch MCP | Supports `start_index`, `max_length` |
| API calls | `Bash(curl)` | Full HTTP control |
| File downloads | `Bash(wget/curl)` | Better for binary files |
| Raw HTML needed | Fetch MCP with `raw: true` | No conversion |

**Selection Priority**: WebFetch (content) → Fetch MCP (chunks/raw) → Bash (APIs/files)

---

### 4. GitHub Operations Overlap

**Overlapping Tools**:
- CLI: `gh` (GitHub CLI)
- MCP: GitHub MCP (comprehensive toolset)
- Plugin: `github` plugin (if installed)

**Conflict Potential**: MEDIUM - Feature parity varies

**Resolution Rule**:
| Scenario | Use | Rationale |
|----------|-----|-----------|
| View issues/PRs | `Bash(gh issue/pr list)` | Quick, simple |
| Create simple PR | `Bash(gh pr create)` | Single command |
| Complex PR workflows | GitHub MCP | Multi-step automation |
| Repository management | GitHub MCP | Comprehensive toolset |
| Code security scanning | GitHub MCP | MCP-exclusive feature |
| Actions/workflow triggers | GitHub MCP | Better integration |

**Selection Priority**: gh CLI (simple) → GitHub MCP (complex/automation)

---

### 5. Web Search Overlap (Updated PR-8.5)

**Overlapping Tools**:
- Built-in: `WebSearch`
- MCP: Brave Search MCP, Perplexity MCP, GPTresearcher MCP
- Custom: `deep-research` agent

**Conflict Potential**: MEDIUM - Multiple research MCPs with different strengths

**Resolution Rule**:
| Scenario | Use | Rationale |
|----------|-----|-----------|
| Quick fact check | `WebSearch` or `perplexity_search` | Built-in or AI-curated |
| Current events | `brave_web_search` | Fast web index |
| Q&A with citations | `perplexity_ask` | Returns cited answers |
| Multi-source synthesis | `perplexity_research` | Deep with citations |
| Comprehensive research | `gptresearcher_deep_research` | 16+ sources |
| Academic research | arXiv MCP | Full paper workflow |

**Selection Priority**: WebSearch (quick) → Perplexity (AI-curated) → GPTresearcher (comprehensive)

**Note**: DuckDuckGo MCP removed due to bot detection issues. Use Brave Search as API-based alternative.

---

### 5a. Research MCP Complementarity (NEW PR-8.5)

**Overlapping Tools**:
- Brave Search MCP (web search)
- Perplexity MCP (AI search, 4 tools)
- GPTresearcher MCP (deep research, 5 tools)
- arXiv MCP (academic papers)
- Wikipedia MCP (reference articles)

**Conflict Potential**: HIGH - Multiple tools for research tasks

**Resolution Matrix**:
| Tool | Speed | Depth | Sources | Best For |
|------|-------|-------|---------|----------|
| `brave_web_search` | Fast | Shallow | Web index | Current events, fallback |
| `perplexity_search` | Fast | Shallow | AI-curated | Quick facts |
| `perplexity_ask` | Fast | Medium | AI-curated | Q&A with citations |
| `perplexity_research` | Medium | Deep | Multi-source | Synthesis tasks |
| `gptresearcher_quick_search` | Fast | Shallow | 9+ sources | Alternative search |
| `gptresearcher_deep_research` | Slow | Very Deep | 16+ sources | Comprehensive research |
| arXiv MCP | Medium | Deep | Academic | Papers, citations |
| Wikipedia MCP | Fast | Medium | Wikipedia | Reference lookups |

**Selection Priority by Task**:
```
Need research?
├── Quick answer → perplexity_search or WebSearch
├── Current events → brave_web_search
├── Q&A with citations → perplexity_ask
├── Multi-source synthesis → perplexity_research
├── Comprehensive deep-dive → gptresearcher_deep_research
├── Academic papers → arXiv MCP
└── Reference lookup → Wikipedia MCP
```

**Anti-Pattern**: Don't use multiple research MCPs for same query (context waste)

---

### 6. Code Exploration Overlap

**Overlapping Tools**:
- Built-in: `Glob`, `Grep`, `Read`
- Subagent: `Explore`
- Plugin agent: `code-explorer` (feature-dev)

**Conflict Potential**: MEDIUM - When to use agents vs direct tools

**Resolution Rule**:
| Scenario | Use | Rationale |
|----------|-----|-----------|
| Find specific file | `Glob` | Fast, targeted |
| Find specific pattern | `Grep` | Immediate results |
| Read known file | `Read` | Direct access |
| Open-ended exploration | `Explore` subagent | Preserves main context |
| Feature deep-dive | `code-explorer` agent | Traces execution paths |
| Architecture understanding | `Explore` + `Plan` | Comprehensive view |

**Selection Priority**: Direct tools (targeted) → Explore (open-ended) → Plugin agents (deep analysis)

---

### 7. Code Review Overlap

**Overlapping Tools**:
- Plugin: `code-review` (5 parallel agents)
- Plugin: `pr-review-toolkit` (6 specialized agents)
- Manual: Direct Read + analysis

**Conflict Potential**: LOW - Different depths

**Resolution Rule**:
| Scenario | Use | Rationale |
|----------|-----|-----------|
| Quick review | Manual (Read + Grep) | Fast, focused |
| Standard PR review | `code-review` plugin | Confidence-based filtering |
| Comprehensive PR audit | `pr-review-toolkit` | 6 specialized perspectives |
| Security-focused review | Manual + `security-guidance` | Hook catches patterns |

**Selection Priority**: Manual (quick) → code-review (standard) → pr-review-toolkit (comprehensive)

---

### 8. Memory/Persistence Overlap

**Overlapping Tools**:
- MCP: Memory MCP (knowledge graph)
- Files: Context files in `.claude/context/`
- Custom: `memory-bank-synchronizer` agent

**Conflict Potential**: MEDIUM - What to store where

**Resolution Rule**:
| Content Type | Store In | Rationale |
|--------------|----------|-----------|
| Decisions & rationale | Memory MCP | Relationships, cross-session |
| Entity relationships | Memory MCP | Graph structure |
| Events & milestones | Memory MCP | Temporal queries |
| Detailed procedures | Context files | Human-readable, editable |
| Configuration | Context files | Version controlled |
| Troubleshooting guides | Context files | Searchable, updateable |

**Selection Priority**: Memory MCP (relationships/decisions) → Context files (details/procedures)

See @.claude/context/patterns/memory-storage-pattern.md for detailed guidance.

---

### 9. Time Operations Overlap

**Overlapping Tools**:
- MCP: Time MCP (`get_current_time`, `convert_time`)
- Bash: `date` command

**Conflict Potential**: LOW

**Resolution Rule**:
| Scenario | Use | Rationale |
|----------|-----|-----------|
| Simple timestamp | `Bash(date)` | No MCP overhead |
| Timezone conversion | Time MCP | IANA timezone support |
| Format control | `Bash(date +format)` | Full format control |
| Cross-timezone scheduling | Time MCP | Built for this |

**Selection Priority**: Bash(date) (simple) → Time MCP (timezone operations)

---

## Conflict Prevention Rules

### Hard Rules

1. **One Tool Per Operation**: Never use multiple tools for the same atomic operation
2. **No Duplicate Writes**: Never write to the same file via different mechanisms in one session
3. **MCP vs Built-in**: If built-in exists and works, prefer it over MCP
4. **Plugin vs Manual**: If plugin provides workflow, use it; don't recreate manually

### Soft Rules

1. **Token Awareness**: Consider MCP token cost when choosing
2. **Context Preservation**: Use subagents for exploration to preserve main context
3. **Consistency**: Once you choose a tool for a task type, stick with it in that session
4. **Document Choices**: When making non-obvious tool selections, explain why

---

## Deprecated/Superseded Tools

| Tool | Status | Replaced By | Migration Notes |
|------|--------|-------------|-----------------|
| MCP Gateway (legacy) | Superseded | Individual MCPs | Use Memory, Fetch separately |
| Bash(grep) for search | Discouraged | `Grep` built-in | Better integration |
| Bash(cat) for reading | Discouraged | `Read` built-in | Better permissions |

---

## Monitoring & Adjustment

### Review Triggers

Re-evaluate overlap rules when:
- New MCP server added
- New plugin installed
- Significant token cost change observed
- User reports confusion about tool selection

### Metrics to Watch

- Tool selection consistency in audit logs
- Token usage per operation type
- Error rates by tool choice
- User override frequency

---

## Related Documentation

- @.claude/context/integrations/capability-matrix.md - Full capability matrix
- @.claude/context/patterns/mcp-loading-strategy.md - MCP loading strategies
- @.claude/context/patterns/agent-selection-pattern.md - Agent selection guidance
- @.claude/context/patterns/memory-storage-pattern.md - Memory vs files

---

*PR-5 Core Tooling Baseline - Overlap Analysis v1.1 (Updated PR-8.5 2026-01-09)*
