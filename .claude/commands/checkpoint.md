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

## Arguments

- `$ARGUMENTS` - Optional: MCP name and reason for checkpoint

## Checkpoint Procedure

### 1. Update Session State

Update `.claude/context/session-state.md` with:

```yaml
status: checkpoint
checkpoint_reason: MCP required - $ARGUMENTS
checkpoint_timestamp: [current datetime]
mcp_required: [mcp-name]
```

Include in the session state:
- What we were working on (summary)
- Current progress/findings
- Immediate next steps after restart
- Any context needed to continue

### 2. Provide Enable Instructions

For the MCP that needs to be enabled:

```bash
# Enable MCP for next session
claude mcp add [mcp-name]

# Then restart Claude Code
# After restart, the session-state.md will have continuation context
```

### 3. Output to User

Provide a clear summary:

```
## Checkpoint Saved

**Reason**: [why MCP is needed]
**MCP Required**: [mcp-name]

### To Continue:
1. Run: `claude mcp add [mcp-name]`
2. Restart Claude Code
3. Session will resume from checkpoint

### Current State Saved:
- [summary of work in progress]
- [next steps after restart]
```

## On-Demand MCP Reference

| MCP | Token Cost | Enable Command |
|-----|------------|----------------|
| n8n-MCP | ~28k | `claude mcp add n8n-mcp` |
| GitHub MCP | ~15k | `claude mcp add github` |
| SSH MCP | ~5k | `claude mcp add ssh` |
| Prometheus MCP | ~8k | `claude mcp add prometheus` |
| Grafana MCP | ~10k | `claude mcp add grafana` |

## Important Notes

- On-Demand MCPs are **auto-disabled at session end** (per MCP Loading Strategy pattern)
- The enabled MCP only lasts for the next session
- No manual cleanup needed - session exit handles it

## Related

- @.claude/context/patterns/mcp-loading-strategy.md - Full pattern documentation
- @.claude/context/session-state.md - Session state file
- @.claude/context/workflows/session-exit-procedure.md - Exit procedure with MCP auto-disable
