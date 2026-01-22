---
description: Save session state for MCP-required restart (preserves context for continuation)
argument-hint: [--mcp <name>] [reason]
allowed-tools:
  - Bash(~/Scripts/checkpoint.sh:*)
---

# /checkpoint - Session Checkpoint

Save current session state to enable seamless continuation after MCP enable/restart.

## Quick Reference

```bash
# Simple checkpoint
~/Scripts/checkpoint.sh "Reason for checkpoint"

# With MCP that needs enabling
~/Scripts/checkpoint.sh --mcp n8n-mcp "Need workflow automation"
```

## Execution

**Parse arguments from**: $ARGUMENTS

Run the CLI script:

```bash
~/Scripts/checkpoint.sh $ARGUMENTS
```

## When to Use

- An On-Demand MCP is needed but not currently enabled
- User needs to restart Claude Code to enable an MCP
- Preserving current work context across the restart

## On-Demand MCP Reference

| MCP | Token Cost | Enable Command |
|-----|------------|----------------|
| n8n-MCP | ~28k | `claude mcp add n8n-mcp` |
| GitHub MCP | ~15k | `claude mcp add github` |
| SSH MCP | ~5k | `claude mcp add ssh` |
| Prometheus MCP | ~8k | `claude mcp add prometheus` |
| Grafana MCP | ~10k | `claude mcp add grafana` |

## Script Details

**Location**: `~/Scripts/checkpoint.sh`
**Updates**: `.claude/context/session-state.md`
**Exit Codes**:
- 0: Success
- 1: Invalid arguments
- 2: Failed to update session state

## Important Notes

- On-Demand MCPs are **auto-disabled at session end** (per MCP Loading Strategy pattern)
- The enabled MCP only lasts for the next session
- No manual cleanup needed - session exit handles it

## Related

- @.claude/context/patterns/mcp-loading-strategy.md - Full pattern documentation
- @.claude/context/session-state.md - Session state file
- @.claude/context/workflows/session-exit-procedure.md - Exit procedure with MCP auto-disable
