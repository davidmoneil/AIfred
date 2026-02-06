---
description: Query Task Metrics
argument-hint: [summary|by-agent|by-session|recent|top-tokens|cost] [args]
skill: infrastructure-ops
allowed-tools:
  - Bash(npx tsx:*)
  - Read
---

# Task Metrics

Query performance metrics for all Task tool (agent/subagent) executions.

## Usage

Run the metrics query tool with the requested command:

```bash
npx tsx .claude/skills/infrastructure-ops/tools/metrics-query.ts $ARGUMENTS
```

## Commands

| Command | Description |
|---------|-------------|
| `summary` | Total executions, tokens, tools, success rate, unique agents |
| `by-agent [name]` | Stats grouped by agent, or detail for one agent |
| `by-session [name]` | Stats for current or named session |
| `recent [count]` | Last N executions with details (default 10) |
| `top-tokens [limit]` | Agents ranked by total token usage |
| `cost [input] [output]` | Estimate API cost (default $3/$15 per MTok) |

## Examples

- `/metrics summary` - Overview of all metrics
- `/metrics by-agent Plan` - Detail view for Plan subagent
- `/metrics recent 20` - Last 20 agent executions
- `/metrics cost` - Estimate total API cost

## Data Source

Metrics are collected automatically by the `metrics-collector.js` SubagentStop hook.
Data is stored in `.claude/logs/task-metrics.jsonl`.

## What Gets Tracked

Every Task tool execution captures:
- Agent name and type (builtin-subagent, custom-agent, feature-dev, etc.)
- Token usage and tool use count (when available in `<usage>` tags)
- Duration, success/failure, result size
- Session name for grouping

Present the output to the user and highlight any notable patterns.
