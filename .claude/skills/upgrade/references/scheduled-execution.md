# Upgrade: Scheduled/Headless Execution

The upgrade discovery workflow can run autonomously on a schedule.

## Quick Start

```bash
# Test the scheduled job (dry run)
~/.claude/jobs/claude-scheduled.sh upgrade-discover --dry-run

# Run discovery headlessly
~/.claude/jobs/claude-scheduled.sh upgrade-discover --verbose

# View output
cat ~/.claude/logs/scheduled/upgrade-discover-*.json | tail -1 | jq '.result'
```

## Cron Schedule

```bash
# Weekly discovery - Sunday 6:00 AM
0 6 * * 0 $CLAUDE_PROJECT_DIR/.claude/jobs/claude-scheduled.sh upgrade-discover
```

## How It Works

1. **Wrapper script** (`claude-scheduled.sh`) configures environment and permissions
2. **Claude Code CLI** runs with `-p` flag (non-interactive mode)
3. **Permission tier** limits to "analyze" (read + write data files)
4. **Output** is captured as JSON and logged
5. **Discoveries** are written to `pending-upgrades.json`
6. **Next session** shows pending discoveries via session-start hook

## Permission Tier: Analyze

The scheduled job uses the "analyze" tier which allows:
- Reading files (baselines, config, existing data)
- Fetching external sources (GitHub, docs, blogs)
- Writing to data files (pending-upgrades.json)

It does NOT allow:
- Editing code files
- Git commits
- Implementing upgrades

Implementation still requires interactive approval.

## Monitoring

```bash
# Check recent runs
ls -la ~/.claude/logs/scheduled/upgrade-discover-*.log

# View costs
grep "Cost:" ~/.claude/logs/scheduled/upgrade-discover-*.log

# Check for alerts
cat ~/.claude/logs/scheduled/alerts.log
```

See @.claude/context/patterns/autonomous-execution-pattern.md for full documentation.
