# Agent Selection Pattern

**Version**: 2.0 | **Updated**: 2026-01-09 | **PR Reference**: PR-9.1

Quick reference for choosing between agents, subagents, skills, and direct tools.

---

## Quick Decision

```
Task Received
    │
    ├─ Simple (1-3 ops)? ───────► SELF-EXECUTE with direct tools
    │
    ├─ Has a skill? ────────────► USE SKILL (/docx, /xlsx, etc.)
    │
    ├─ Code exploration? ───────► EXPLORE subagent
    │
    ├─ Architecture planning? ──► PLAN subagent
    │
    ├─ Feature development? ────► feature-dev:* plugin agents
    │
    ├─ Domain expertise needed? ► CUSTOM AGENT
    │
    └─ Context isolation needed? ► SUBAGENT (any type)
```

---

## Decision Matrix

| Criteria | Direct Tool | Skill | Subagent | Custom Agent |
|----------|-------------|-------|----------|--------------|
| **Steps** | 1-2 | 1-5 | 3-10 | 5+ complex |
| **Context** | Same | Same | Isolated | Isolated |
| **Learning** | No | No | No | Yes (Memory MCP) |
| **Persistence** | No | No | No | Results files |
| **Best For** | Simple queries | Quick operations | Exploration/planning | Recurring workflows |

---

## Built-in Subagents

Automatically available via Task tool:

| Subagent | Purpose | Trigger |
|----------|---------|---------|
| **Explore** | Fast codebase navigation | Finding files, understanding code |
| **Plan** | Software architecture | Designing implementation |
| **general-purpose** | Multi-step research | Complex questions |
| **claude-code-guide** | Documentation lookup | Claude Code/SDK questions |

---

## Plugin Agents

### feature-dev (Feature Development)

| Agent | Purpose | Phase |
|-------|---------|-------|
| `feature-dev:code-architect` | Design features | Before implementation |
| `feature-dev:code-explorer` | Analyze existing code | Understanding |
| `feature-dev:code-reviewer` | Review code quality | After changes |

### Other Plugins

| Agent | Purpose |
|-------|---------|
| `hookify:conversation-analyzer` | Find patterns for hooks |
| `pr-review-toolkit:*` | Thorough PR review |
| `project-plan-validator` | Validate infrastructure plans |

---

## Custom Agents

Located in `.claude/agents/`:

| Agent | Purpose | Invoke |
|-------|---------|--------|
| **deep-research** | Multi-source research with citations | `/agent deep-research "topic"` |
| **service-troubleshooter** | Systematic issue diagnosis | `/agent service-troubleshooter "issue"` |
| **docker-deployer** | Guided Docker deployment | `/agent docker-deployer "service"` |
| **memory-bank-synchronizer** | Sync docs with code | `/agent memory-bank-synchronizer` |

---

## When to Create New Agents

Create a custom agent when:
1. Task repeats **3+ times** with similar pattern
2. Benefits from **Memory MCP** learning
3. Requires **5+ complex steps**
4. Produces **reusable output** files
5. Needs **context isolation**

Template: `.claude/agents/_template-agent.md`

---

## MCP-Agent Pairing

| Task Domain | Recommended Agent | Supporting MCPs |
|-------------|-------------------|-----------------|
| Deep research | deep-research | perplexity, gptresearcher, arxiv |
| Docker work | docker-deployer | desktop-commander |
| Service issues | service-troubleshooter | — |
| Code exploration | Explore subagent | filesystem, git |
| Planning | Plan subagent | memory |

---

## Research Agent Routing

```
Research Task
    │
    ├─ Quick lookup ────────► perplexity_search or WebSearch (no agent)
    │
    ├─ Medium depth ────────► perplexity_research (no agent)
    │
    └─ Comprehensive ───────► /agent deep-research "topic"
                               (uses gptresearcher + perplexity + WebSearch)
```

---

## Integration with PARC

During **Assess** phase:
1. Check if skill exists → Use skill
2. Check if custom agent matches → Use agent
3. Check if subagent fits → Delegate
4. Fall back to direct tools

---

## Related Documentation

- @selection-intelligence-guide.md — Quick selection reference
- @capability-map.yaml — Full task-to-tool mapping
- @mcp-loading-strategy.md — MCP tier management

---

*Agent Selection Pattern v2.0 — 2026-01-09*
