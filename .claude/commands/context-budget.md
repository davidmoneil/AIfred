---
description: Display current context usage by category and recommend optimizations
---

# Context Budget Analysis

Display current context usage by category and recommend optimizations.

## Usage

Run `/context-budget` to analyze current context consumption.

## Analysis Steps

### 1. Run Built-in /context Command

Execute Claude Code's `/context` command to get raw context data.

### 2. Categorize Token Usage

Parse the output and categorize into:

| Category | Description | Target % |
|----------|-------------|----------|
| **Conversation** | Messages and responses | 50% |
| **System Prompt** | CLAUDE.md + instructions | 10% |
| **Tier 1 MCPs** | Always-On (Memory, Filesystem, Fetch, Git) | 15% |
| **Tier 2 MCPs** | Task-Scoped (loaded for current task) | 10% |
| **Plugins/Skills** | Bundled skill definitions | 10% |
| **Buffer** | Safety margin | 5% |

### 3. Assess Budget Status

| Status | Condition | Action |
|--------|-----------|--------|
| **HEALTHY** | <80% usage | Continue normally |
| **WARNING** | 80-100% usage | Consider unloading Tier 2 MCPs |
| **CRITICAL** | >100% usage | Immediate optimization needed |

### 4. Generate Recommendations

Based on analysis, recommend:

**If over budget:**
- [ ] Unload unused Tier 2 MCPs
- [ ] Run `/checkpoint` and restart with fewer MCPs
- [ ] Consider session break to reset context

**If approaching limit:**
- [ ] Complete current subtask before loading more MCPs
- [ ] Defer non-essential operations
- [ ] Update session-state.md with checkpoint

### 5. Report Format

```markdown
## Context Budget Report

**Status**: [HEALTHY|WARNING|CRITICAL]
**Usage**: X/200K tokens (Y%)

### Breakdown
| Category | Tokens | % | Notes |
|----------|--------|---|-------|
| Conversation | ... | ... | ... |
| ...

### Loaded Tier 2 MCPs
- [MCP Name] - [tokens] - [last used: ...]

### Recommendations
1. ...
2. ...

### Unload Evaluation
MCPs that can be unloaded:
- [ ] [MCP] - task complete, no further need
```

---

## MCP Tier Reference

### Tier 1 — Always-On (~27-34K)
- Memory, Filesystem, Fetch, Git

### Tier 2 — Task-Scoped (Agent-Managed)
- Time, GitHub, Context7, Sequential Thinking, DuckDuckGo
- Load as needed, unload when task complete

### Tier 3 — Triggered (Blacklisted from Agent Selection)
- Playwright, BrowserStack, Slack, Google Drive/Maps
- Only invoked by specific hooks/commands

---

## Related Documentation

- @.claude/context/patterns/context-budget-management.md
- @.claude/context/patterns/mcp-loading-strategy.md

---

*PR-8: Context Budget Management*
