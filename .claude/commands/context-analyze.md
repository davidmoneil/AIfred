---
name: context-analyze
description: Analyze Claude Code context usage and suggest optimizations
usage: /context-analyze [--test] [--no-reduce]
allowed-tools:
  - Bash(~/AIProjects/Scripts/weekly-context-analysis.sh:*)
  - Bash(~/Scripts/weekly-context-analysis.sh:*)
---

# /context-analyze - Context Usage Analysis

Analyzes Claude Code context usage patterns and suggests optimizations.

## Quick Reference

```bash
# Full analysis with auto-reduction
~/AIProjects/Scripts/weekly-context-analysis.sh

# Test Ollama connection
~/AIProjects/Scripts/weekly-context-analysis.sh --test

# Run without auto-reduction
CONTEXT_REDUCE=false ~/AIProjects/Scripts/weekly-context-analysis.sh
```

## Execution

**Parse arguments from**: $ARGUMENTS

Run the CLI script:

```bash
~/AIProjects/Scripts/weekly-context-analysis.sh $ARGUMENTS
```

## What It Analyzes

1. **Session Statistics** - Tool usage from audit logs
2. **File Size Analysis** - CLAUDE.md and context/ files
3. **Git Churn** - Frequently modified files
4. **Auto-Archive** - Old logs (>365 days)
5. **Auto-Reduce** - Large context files using Ollama

## Auto-Reduction

When `CONTEXT_REDUCE=true` (default):
- Files exceeding `REDUCE_THRESHOLD` (5000 tokens) are summarized
- Uses local Ollama model for summarization
- Creates backup before modification
- Preserves structure, reduces verbosity

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `CONTEXT_REDUCE` | true | Enable auto-reduction |
| `REDUCE_THRESHOLD` | 5000 | Token threshold for reduction |
| `REDUCE_MAX_SIZE` | 50000 | Skip files larger than this |
| `OLLAMA_MODEL` | qwen2.5:32b | Model for summarization |

## Recommended Ollama Models

1. `llama3.1:8b` - Best instruction following
2. `mistral:7b-instruct` - Fast and reliable
3. `qwen2.5:7b-instruct` - Good balance
4. `phi3:medium` - Efficient, smaller context

## Output

Reports are saved to: `.claude/logs/reports/context-analysis-YYYY-MM-DD.md`

Report includes:
- Context file sizes and growth
- Session statistics
- Git churn analysis
- Optimization recommendations
- Auto-reduction results (if enabled)

## Scheduled Run

The script runs automatically via cron (weekly).

## Script Details

**Location**: `~/AIProjects/Scripts/weekly-context-analysis.sh`
**Reports**: `.claude/logs/reports/`
**Backups**: `.claude/logs/backups/` (before auto-reduction)
