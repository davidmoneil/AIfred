# MCP Decision Map

Consolidated guide for selecting which MCP(s) to load for a given task.

**Version**: 1.0.0
**Layer**: Nous (reference)
**Consolidates**: capability-matrix.md, mcp-loading-strategy.md, context-budget-management.md, mcp-design-patterns.md

---

## Quick Decision Tree

```
What type of task?
│
├─► File operations ──────────► filesystem MCP (Tier 2)
│
├─► Git operations ───────────► git MCP (Tier 1, always loaded)
│
├─► Store decisions ──────────► memory MCP (Tier 1, always loaded)
│
├─► Web research ─────────────► WebSearch tool (built-in) + WebFetch
│
├─► Deep web reading ─────────► fetch MCP (Tier 2)
│
├─► RAG / embeddings ─────────► local-rag MCP (Tier 2)
│
├─► Specialized API ──────────► Check available Tier 3 MCPs
│
└─► Unknown ──────────────────► Start with built-in tools
```

---

## MCP Tiers

### Tier 1: Always Loaded

| MCP | Purpose | Budget Impact |
|-----|---------|---------------|
| **memory** | Store decisions, entities, relationships | Low |
| **git** | Version control operations | Low |

These are essential and always available. No loading decision needed.

### Tier 2: Task-Loaded

| MCP | Load When | Budget Impact |
|-----|-----------|---------------|
| **filesystem** | File manipulation beyond Read/Write tools | Medium |
| **fetch** | Deep web content extraction | Medium |
| **local-rag** | Semantic search, embeddings | Medium-High |

Load at task start if you know you'll need them.

### Tier 3: On-Demand

Load only when specifically required. Check `mcp-installation.md` for available MCPs.

---

## Task → MCP Mapping

### Research Tasks

| Task | Primary MCP | Secondary | Notes |
|------|-------------|-----------|-------|
| Quick fact lookup | WebSearch (built-in) | — | No MCP needed |
| Deep article reading | fetch | — | For parsing complex pages |
| Multi-source synthesis | WebSearch + fetch | memory | Store key findings |
| Codebase research | — | — | Use Explore agent instead |
| Technical docs | WebFetch (built-in) | — | Usually sufficient |

### File Operations

| Task | Primary MCP | Secondary | Notes |
|------|-------------|-----------|-------|
| Read file | Read tool (built-in) | — | No MCP needed |
| Edit file | Edit tool (built-in) | — | No MCP needed |
| Write file | Write tool (built-in) | — | No MCP needed |
| Complex file ops | filesystem | — | Move, copy, directory tree |
| File search | Glob/Grep (built-in) | — | No MCP needed |
| Binary file handling | filesystem | — | For non-text files |

### Git Operations

| Task | MCP | Notes |
|------|-----|-------|
| Status, diff, log | git (Tier 1) | Always available |
| Commit, add, reset | git (Tier 1) | Always available |
| Branch operations | git (Tier 1) | Always available |
| Complex git | Bash + git CLI | For edge cases |

### Memory & State

| Task | MCP | Notes |
|------|-----|-------|
| Store decision | memory (Tier 1) | Always available |
| Query entities | memory (Tier 1) | Always available |
| Session state | session-state.md | File-based, no MCP |

### Semantic Search

| Task | Primary MCP | Notes |
|------|-------------|-------|
| Embed documents | local-rag | Higher token cost |
| Query embeddings | local-rag | Higher token cost |
| Simple text search | Grep (built-in) | Prefer for exact matches |

---

## Loading Strategy

### Start of Session

1. Tier 1 MCPs auto-loaded (memory, git)
2. Assess task requirements
3. Load Tier 2 MCPs if task type known
4. Defer Tier 3 until specifically needed

### During Session

- Load MCPs before task, not during
- Batch-load related MCPs together
- Unload heavy MCPs when done (if supported)

### Context Budget Awareness

| Context Level | MCP Strategy |
|---------------|--------------|
| < 50% | Load freely |
| 50-70% | Load only essential |
| > 70% | Avoid new loads, consider checkpoint |

---

## When NOT to Load MCPs

| Scenario | Alternative |
|----------|-------------|
| Reading files | Built-in Read tool |
| Simple edits | Built-in Edit tool |
| Pattern search | Built-in Grep tool |
| File finding | Built-in Glob tool |
| Quick web lookup | Built-in WebSearch |
| Git basics | Built-in Bash + git CLI |

**Rule**: Prefer built-in tools over MCPs for simple operations.

---

## Common Combinations

### Research Session
```
Load: fetch (for deep reading)
Use: WebSearch (built-in) + memory (always loaded)
```

### Development Session
```
Load: (usually none beyond Tier 1)
Use: Read/Edit/Write (built-in) + git (Tier 1)
```

### File Organization
```
Load: filesystem (for complex operations)
Use: Glob/Grep (built-in) for searching
```

### RAG/Semantic Work
```
Load: local-rag
Use: For embedding and semantic queries
```

---

## Troubleshooting MCP Issues

| Problem | Solution |
|---------|----------|
| MCP not responding | Check `/tooling-health`, restart if needed |
| MCP returns errors | Check MCP logs, verify configuration |
| Too many MCPs loaded | Checkpoint and restart with fewer |
| MCP missing | Check `mcp-installation.md` for setup |

---

## Reference Links

- Full capability matrix: `integrations/capability-matrix.md`
- MCP installation: `integrations/mcp-installation.md`
- Context budget: `patterns/context-budget-management.md`
- MCP patterns: `patterns/mcp-design-patterns.md`

---

*Jarvis — Nous Layer (Reference)*
