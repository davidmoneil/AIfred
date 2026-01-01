# AIfred Jobs

Automation scripts for maintenance and monitoring tasks.

---

## Available Scripts

| Script | Purpose | Schedule |
|--------|---------|----------|
| `memory-prune.sh` | Archive stale Memory MCP entities | Weekly |
| `context-staleness.sh` | Find outdated context files | Weekly |

---

## memory-prune.sh

Identifies Memory MCP entities not accessed in 90+ days and archives them.

**Usage**:
```bash
./memory-prune.sh              # Dry run - show what would be archived
./memory-prune.sh --execute    # Actually archive stale entities
./memory-prune.sh --days 60    # Custom retention period
```

**How It Works**:
1. Reads `.claude/agents/memory/entity-metadata.json` (populated by memory-maintenance.js hook)
2. Identifies entities not accessed within retention period
3. Archives entity list to `.claude/archive/memory/YYYY-MM-archive.json`
4. Reports which entities need manual deletion via Claude session

**Output**:
- Archive file: `.claude/archive/memory/YYYY-MM-archive.json`
- Log file: `.claude/jobs/logs/memory-prune.log`

---

## context-staleness.sh

Finds context files that haven't been modified recently and may need review.

**Usage**:
```bash
./context-staleness.sh              # Default 90-day threshold
./context-staleness.sh --days 60    # Custom threshold
```

**What It Checks**:
- File modification dates
- Cross-reference validity (@ links)
- Age-based severity classification

**Output Categories**:
- `[X]` >180 days: Consider archiving
- `[!]` >120 days: Review for accuracy
- `[~]` >90 days: Quick relevance check

**Log file**: `.claude/jobs/logs/context-staleness.log`

---

## Scheduling

### Manual (Recommended Initially)

Run scripts manually until you understand your system's patterns:
```bash
cd /path/to/project
./.claude/jobs/memory-prune.sh
./.claude/jobs/context-staleness.sh
```

### Automated (After Stabilization)

Add to crontab for weekly runs:
```bash
# Edit crontab
crontab -e

# Add weekly job (Mondays at 9am)
0 9 * * 1 /path/to/project/.claude/jobs/memory-prune.sh >> /path/to/project/.claude/jobs/logs/memory-prune.log 2>&1
0 9 * * 1 /path/to/project/.claude/jobs/context-staleness.sh >> /path/to/project/.claude/jobs/logs/context-staleness.log 2>&1
```

---

## Logs

All scripts log to `.claude/jobs/logs/`:
- `memory-prune.log` - Memory pruning history
- `context-staleness.log` - Staleness check history

Logs are gitignored by default.

---

## Creating New Jobs

1. Create script in `.claude/jobs/`
2. Follow the existing pattern (argument parsing, logging, colors)
3. Use severity levels from `standards/severity-status-system.md`
4. Add entry to this README
5. Consider adding systemd timer for scheduling

---

*AIfred Jobs v1.0*
