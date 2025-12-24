# Phase 5: Hooks & Automation

**Purpose**: Install automation hooks and configure cron jobs.

---

## Core Hooks (Always Installed)

These hooks are essential for AIfred operation:

| Hook | Purpose |
|------|---------|
| `audit-logger.js` | Log all tool executions |
| `session-tracker.js` | Track session lifecycle |
| `session-exit-enforcer.js` | Remind about exit procedures |
| `secret-scanner.js` | Prevent credential commits |
| `context-reminder.js` | Prompt for documentation |

### Installation

Copy hooks from `.claude/hooks/` templates to active hooks.

Verify each hook:
```bash
node -c .claude/hooks/audit-logger.js
```

---

## Optional Hooks (Based on Focus Areas)

### Infrastructure Focus
- `docker-health-check.js` - Verify container health
- `compose-validator.js` - Validate compose files
- `port-conflict-detector.js` - Check for port conflicts

### Development Focus
- `branch-protection.js` - Protect main branches
- `amend-validator.js` - Validate commit amends

### Memory Enabled
- `memory-maintenance.js` - Track entity access

---

## Cron Jobs

### Log Rotation

Create `.claude/jobs/log-rotation.sh`:

```bash
#!/bin/bash
# AIfred Log Rotation
# Runs daily at 2 AM

LOG_DIR="$HOME/Code/AIfred/.claude/logs"
ARCHIVE_DIR="$LOG_DIR/archive"
RETENTION_DAYS=90

mkdir -p "$ARCHIVE_DIR"

# Rotate audit.jsonl
if [ -f "$LOG_DIR/audit.jsonl" ]; then
    DATE=$(date +%Y%m%d)
    mv "$LOG_DIR/audit.jsonl" "$ARCHIVE_DIR/audit-$DATE.jsonl"
    gzip "$ARCHIVE_DIR/audit-$DATE.jsonl"
fi

# Clean old archives
find "$ARCHIVE_DIR" -name "*.gz" -mtime +$RETENTION_DAYS -delete

echo "Log rotation complete: $(date)"
```

### Memory Pruning

Create `.claude/jobs/memory-prune.sh`:

```bash
#!/bin/bash
# AIfred Memory Pruning
# Runs weekly on Sunday at 3 AM

METADATA_FILE="$HOME/Code/AIfred/.claude/agents/memory/entity-metadata.json"
ARCHIVE_DIR="$HOME/Code/AIfred/.claude/archive/memory"
PRUNE_DAYS=90

mkdir -p "$ARCHIVE_DIR"

# This script identifies entities to prune
# Actual pruning requires Memory MCP interaction
# which must be done during a Claude session

echo "Memory prune check: $(date)"
echo "Review .claude/agents/memory/prune-candidates.json for entities to archive"
```

### Session Cleanup

Create `.claude/jobs/session-cleanup.sh`:

```bash
#!/bin/bash
# AIfred Session Cleanup
# Runs weekly

SESSIONS_DIR="$HOME/Code/AIfred/.claude/agents/sessions"
RETENTION_DAYS=90

find "$SESSIONS_DIR" -name "*.md" -mtime +$RETENTION_DAYS -delete

echo "Session cleanup complete: $(date)"
```

---

## Cron Installation

Add to crontab:

```bash
# AIfred Automation Jobs
0 2 * * * $HOME/Code/AIfred/.claude/jobs/log-rotation.sh >> $HOME/Code/AIfred/.claude/logs/cron.log 2>&1
0 3 * * 0 $HOME/Code/AIfred/.claude/jobs/memory-prune.sh >> $HOME/Code/AIfred/.claude/logs/cron.log 2>&1
0 4 * * 0 $HOME/Code/AIfred/.claude/jobs/session-cleanup.sh >> $HOME/Code/AIfred/.claude/logs/cron.log 2>&1
```

Installation command:
```bash
(crontab -l 2>/dev/null; echo "# AIfred jobs - see .claude/jobs/") | crontab -
```

---

## Permission Configuration

Based on automation level from Phase 2:

### Full Automation
- Expand allow list to include write operations
- Minimize prompts for routine tasks

### Guided Automation
- Default settings.json is appropriate
- Major operations still prompt

### Manual Control
- Reduce allow list
- Add more operations to prompt

Update `.claude/settings.json` accordingly.

---

## Validation

- [ ] Core hooks installed and verified
- [ ] Optional hooks installed based on focus
- [ ] Cron jobs created
- [ ] Crontab updated
- [ ] Permissions configured per automation level

---

*Phase 5 of 7 - Hooks & Automation*
