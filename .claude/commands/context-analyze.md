---
name: context-analyze
description: Analyze Claude Code context usage and suggest optimizations
usage: /context-analyze [--no-reduce]
allowed-tools:
  - Bash($CLAUDE_PROJECT_DIR/scripts/weekly-context-analysis.sh:*)
  - Bash(JARVIS_DIR=* scripts/weekly-context-analysis.sh:*)
---

# /context-analyze - Context Usage Analysis

Analyzes Claude Code context usage patterns and suggests optimizations.

## Quick Reference

```bash
# Full analysis (no auto-reduction by default)
JARVIS_DIR="$CLAUDE_PROJECT_DIR" scripts/weekly-context-analysis.sh

# Explicit no-reduce mode
CONTEXT_REDUCE=false JARVIS_DIR="$CLAUDE_PROJECT_DIR" scripts/weekly-context-analysis.sh
```

## Execution

**Parse arguments from**: $ARGUMENTS

Run the analysis script:

```bash
JARVIS_DIR="$CLAUDE_PROJECT_DIR" CONTEXT_REDUCE=false scripts/weekly-context-analysis.sh $ARGUMENTS
```

## What It Analyzes

1. **Session Statistics** - Tool usage from telemetry and selection logs
2. **File Size Analysis** - CLAUDE.md and context/ files
3. **Git Churn** - Frequently modified files (last 30 days)
4. **Auto-Archive** - Old logs (>30 days to archive, >365 days deleted)
5. **Recommendations** - Actionable optimization suggestions

## Log Sources (Jarvis)

The script reads from multiple Jarvis log files:

| Log File | Purpose |
|----------|---------|
| `telemetry/events-*.jsonl` | AC component events |
| `selection-audit.jsonl` | Tool/agent selections |
| `session-events.jsonl` | Session lifecycle |

## Output

Reports are saved to: `.claude/logs/reports/context-analysis-YYYY-MM-DD.md`

Report includes:
- Context file sizes and growth
- Session statistics from logs
- Git churn analysis (files modified 20%+ in 30 days)
- Stale file detection (not modified in 90+ days)
- Optimization recommendations

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `JARVIS_DIR` | `$CLAUDE_PROJECT_DIR` | Project root directory |
| `CONTEXT_REDUCE` | false | Auto-reduction disabled (Ollama not configured) |

## Scheduled Run

Can be run manually or scheduled via cron (weekly recommended).

## Script Details

**Location**: `scripts/weekly-context-analysis.sh`
**Reports**: `.claude/logs/reports/`
**Archives**: `.claude/logs/archive/`

## Related

- `/context-loss` - Report forgotten context after compaction
- `/context-budget` - View current context usage breakdown
- `compaction-essentials.md` - Essential context preserved after compaction
