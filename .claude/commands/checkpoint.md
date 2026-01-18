---
description: Save session state for MCP-required restart (preserves context for continuation)
argument-hint: [mcp-name] [reason]
---

# Session Checkpoint

Save current session state to enable seamless continuation after MCP enable/restart.

## When to Use

- An On-Demand MCP is needed but not currently enabled
- User needs to restart Claude Code to enable an MCP
- Preserving current work context across the restart
- Context budget reaching warning threshold (80%+)

## Arguments

- `$ARGUMENTS` - Optional: MCP name and reason for checkpoint

## Checkpoint Procedure

### 1. Capture Current MCP State (PR-8.3)

Before saving session state, document which MCPs are currently active:

```bash
# List current MCP configuration
claude mcp list
```

Identify which Tier 2 MCPs should be preserved vs dropped:

| MCP | Status | Action |
|-----|--------|--------|
| github | Active, in-use | Preserve |
| context7 | Active, idle | Consider dropping |
| time | Not loaded | N/A |

### 2. Update Session State

Update `.claude/context/session-state.md` with:

```yaml
status: checkpoint
checkpoint_reason: MCP required - $ARGUMENTS
checkpoint_timestamp: [current datetime]
mcp_required: [mcp-name]

# PR-8.3: MCP State Preservation
active_tier2_mcps:
  - github (preserve - PR work ongoing)
  - context7 (drop - research phase complete)
recommended_tier2_for_next_session:
  - [list based on next steps]
```

Include in the session state:
- What we were working on (summary)
- Current progress/findings
- Immediate next steps after restart
- Any context needed to continue
- **Active Tier 2 MCPs and their status** (PR-8.3)

### 3. Provide Enable Instructions

For the MCP that needs to be enabled:

```bash
# Enable MCP for next session
claude mcp add [mcp-name]

# Then restart Claude Code
# After restart, the session-state.md will have continuation context
```

### 4. Name Session for Easy Recovery (evo-2026-01-026)

Before checkpointing, use `/rename` to give the session a meaningful name:

```bash
# Name the current session
/rename "feature-auth-implementation"

# Or with context
/rename "pr-123-code-review"
```

Session names enable easy recovery:
```bash
# Resume by name later
claude --resume "feature-auth-implementation"
```

### 5. Output to User

Provide a clear summary:

```
## Checkpoint Saved

**Reason**: [why MCP is needed]
**MCP Required**: [mcp-name]
**Session Name**: [name from /rename if used]

### To Continue:
1. Run: `claude mcp add [mcp-name]`
2. Restart Claude Code
3. Resume by name: `claude --resume "[session-name]"` OR
   Session will auto-resume from checkpoint file

### Current State Saved:
- [summary of work in progress]
- [next steps after restart]
- [active Tier 2 MCPs to preserve/drop]
```

## MCP Tier Reference (PR-8.3)

### Tier 1: Always-On (Loaded by default)
| MCP | Token Cost | Notes |
|-----|------------|-------|
| Memory | ~8-15K | Persistent knowledge graph |
| Filesystem | ~8K | File operations |
| Fetch | ~5K | Web content retrieval |
| Git | ~6K | Git operations |

### Tier 2: Task-Scoped (Agent-managed)
| MCP | Token Cost | Enable Command | Use Case |
|-----|------------|----------------|----------|
| Time | ~3K | `claude mcp add time` | Timestamps, timezones |
| GitHub | ~15K | `claude mcp add github` | PR/issue work |
| Context7 | ~8K | `claude mcp add context7` | Documentation lookup |
| Sequential Thinking | ~5K | `claude mcp add sequential-thinking` | Complex planning |
| DuckDuckGo | ~4K | `claude mcp add duckduckgo` | Web search |

### Tier 3: Triggered (Hook/command-invoked only)
| MCP | Token Cost | Trigger | Notes |
|-----|------------|---------|-------|
| Playwright | ~15K | `/browser-test` | Browser automation |
| BrowserStack | varies | CI/CD hooks | External service |
| Slack | varies | `/notify` | Communication |

## Important Notes

- **Tier 2 MCPs**: Agent evaluates need at task start; unloads when task complete
- **Tier 3 MCPs**: Blacklisted from agent selection; only invoked by specific triggers
- Run `/context-budget` to check current context usage before checkpoint

## Session Naming Best Practices (evo-2026-01-026)

Use `/rename` to name sessions for easy recovery:

| Pattern | Example | Use Case |
|---------|---------|----------|
| feature-* | `feature-auth-flow` | Feature development |
| pr-* | `pr-123-review` | Pull request work |
| bug-* | `bug-memory-leak` | Bug investigation |
| research-* | `research-mcp-options` | Research tasks |
| session-* | `session-2026-01-18-am` | General work sessions |

**Resume a named session**:
```bash
# List recent sessions
claude --resume

# Resume by name
claude --resume "feature-auth-flow"

# Continue most recent
claude -c
```

## Related

- @.claude/context/patterns/context-budget-management.md - MCP tier definitions
- @.claude/context/patterns/mcp-loading-strategy.md - Full loading strategy
- @.claude/context/session-state.md - Session state file
- @.claude/context/patterns/session-completion-pattern.md - Session workflow
