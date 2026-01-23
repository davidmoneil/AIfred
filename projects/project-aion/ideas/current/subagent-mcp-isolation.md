# Brainstorm: Subagent MCP Isolation for Context Management

**Created**: 2026-01-08
**Status**: Research Complete — Limited Utility
**Related**: PR-8.3 Context Management, PR-9 Selection Intelligence

---

## The Question

Can subagents be used for context management by:
1. Having the parent agent run with minimal MCPs (Tier 1 only)
2. Spawning a subagent with additional MCPs for specific work
3. Reclaiming MCP context when the subagent completes

## Research Findings

### Subagent MCP Inheritance

| Aspect | Finding |
|--------|---------|
| **MCP Inheritance** | YES — Subagents inherit parent's MCP configuration |
| **MCP Isolation** | NO — Cannot spawn subagent with different MCPs |
| **Context Clearing** | YES — Subagent's local context cleared on completion |
| **MCP Tokens Reclaimed** | PARTIAL — Conversation context reclaimed, MCPs stay loaded |

### Key Insight

Subagents **inherit** MCPs, they don't **enable** them. If GitHub MCP is disabled in the parent session, subagents also can't use it. There's no mechanism to spawn a subagent with a temporarily-enabled MCP.

### What IS Reclaimed

When a subagent completes:
- ✅ Subagent's conversation context
- ✅ Subagent's tool call history
- ✅ Subagent's working memory

### What IS NOT Reclaimed

- ❌ MCP server connections (stay active)
- ❌ MCP tool definitions (still in parent context)
- ❌ Session-level MCP token overhead

---

## Architecture Implications

### Current Tier 3 Pattern (What Works)

```
┌─────────────────────────────────────────┐
│            PARENT SESSION               │
│  MCPs: memory, filesystem, fetch        │
│  (~7K tokens)                           │
│                                         │
│    ┌──────────────────────────────┐    │
│    │  Task: "run playwright test" │    │
│    │  → Spawns isolated process   │    │
│    │  → Playwright MCP loads      │    │
│    │  → Test runs                 │    │
│    │  → Process terminates        │    │
│    │  → Context reclaimed         │    │
│    └──────────────────────────────┘    │
│                                         │
│  Parent context: UNCHANGED              │
└─────────────────────────────────────────┘
```

**This works** for Playwright and similar "isolated process" MCPs.

### Hypothetical Subagent MCP Loading (Does NOT Work)

```
┌─────────────────────────────────────────┐
│            PARENT SESSION               │
│  MCPs: memory, filesystem, fetch        │
│  (~7K tokens)                           │
│                                         │
│    ┌──────────────────────────────┐    │
│    │  Task: "check GitHub PRs"    │    │
│    │  → Subagent inherits MCPs    │    │
│    │  → GitHub MCP NOT available  │ ❌ │
│    │  → (was disabled in parent)  │    │
│    └──────────────────────────────┘    │
│                                         │
└─────────────────────────────────────────┘
```

**This doesn't work** because subagents can't enable disabled MCPs.

---

## Alternative Approaches

### 1. Pre-Session MCP Selection (Current PR-8.3.1)

Before starting work, select MCPs based on planned tasks:
- Documentation work → Disable GitHub, Context7
- PR review work → Keep GitHub, Disable Sequential-Thinking
- Research → Keep Context7, Disable GitHub

**Status**: ✅ Implemented via `/context-checkpoint`

### 2. Tier 3 Isolated Process Pattern

For MCPs that support isolated processes:
- Playwright MCP spawns per-invocation
- Process terminates after task
- Zero persistent context overhead

**Applicable MCPs**: Playwright, possibly BrowserStack
**Not Applicable**: GitHub, Context7, Memory (stateful)

### 3. Multi-Session Workflow

```
Session 1: Research phase
  MCPs: context7, sequential-thinking
  → Complete research
  → /context-checkpoint

Session 2: Implementation phase
  MCPs: git, filesystem
  → Implement based on research notes
  → /context-checkpoint

Session 3: PR/Review phase
  MCPs: github, git
  → Create PR, respond to reviews
```

**Status**: ✅ Supported by current automation

---

## Conclusion

**Subagent MCP isolation is NOT a viable context management strategy** because:
1. Subagents inherit, not enable, MCPs
2. MCP tool definitions stay loaded regardless of subagent lifecycle
3. Only conversation context is reclaimed, not MCP overhead

**Better approaches**:
1. Pre-session MCP selection (PR-8.3.1) ✅
2. Tier 3 isolated process for applicable MCPs
3. Multi-session workflows with checkpoints

---

## Future Considerations

If Claude Code adds subagent-specific MCP configuration, this pattern could become viable. Watch for:
- Task tool `mcps` parameter
- Agent definition `requiredMcps` field
- Session-scoped MCP loading hooks

---

*Brainstorm Document — Project Aion Ideas*
