# Phase 5: Hooks & Automation

**Purpose**: Install automation hooks and configure scheduled jobs.

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

Hooks are pre-installed in `.claude/hooks/`.

Validate all hooks:
```bash
./scripts/validate-hooks.sh
```

This validates JavaScript syntax for all hooks and shows clean pass/fail output.

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

## Automation Scripts

AIfred includes battle-tested scripts in `scripts/` that you should customize during setup:

### 1. Weekly Context Analysis (`weekly-context-analysis.sh`)

**Purpose**: Analyzes and optimizes context usage to prevent token bloat.

**Features**:
- Session statistics from audit logs
- File size analysis for context files
- Git churn analysis (frequently modified files)
- Auto-archive old logs (>30 days → archive, >365 days → delete)
- **Auto-reduce large context files using Ollama** (optional)
- Memory graph analysis placeholder

**Configuration**:
```bash
# Environment variables
CONTEXT_REDUCE=true          # Enable auto-reduction
REDUCE_THRESHOLD=5000        # Token threshold (default: 5000)
OLLAMA_MODEL=qwen2.5:32b     # Model for summarization
```

**Customization Required**:
- Update `PROJECT_DIR` to your AIfred installation path
- Configure Ollama model based on your setup
- Adjust thresholds for your token budget

---

### 2. Weekly Health Check (`weekly-health-check.sh`)

**Purpose**: Comprehensive infrastructure validation with detailed reporting.

**Checks Performed**:
- **Backups**: Restic snapshots, service-specific backups
- **Docker**: Container health, critical services, stability
- **Credentials**: API endpoints, database connectivity
- **Logging**: Loki/Promtail/Grafana stack health
- **Network**: SSH, NFS mounts, reverse proxy
- **Storage**: Disk usage, certificates, log retention
- **Security**: Auth failures, Docker security, permissions

**Output**:
- Text report with color-coded results
- JSON report for automation/dashboards
- Loki integration for log aggregation

**Usage**:
```bash
./weekly-health-check.sh              # Full check
./weekly-health-check.sh --json       # JSON output
./weekly-health-check.sh --section docker  # Single section
```

**Customization Required**:
- Update `CRITICAL_SERVICES` array for your containers
- Configure IP addresses for your infrastructure
- Adjust thresholds (backup age, disk warning levels)

---

### 3. Weekly Docker Restart (`weekly-docker-restart.sh`)

**Purpose**: Scheduled Docker container restarts to prevent memory leaks and ensure freshness.

**Features**:
- Pre-restart health snapshot
- Container restart with dependency ordering
- Post-restart health verification
- n8n webhook notification support
- Automatic retry for failed restarts

**Uses systemd timer** (more reliable than cron for long-running operations).

**Customization Required**:
- Update `DOCKER_COMPOSE_DIR` to your compose file location
- Configure webhook URL for notifications

---

### 4. Update Priorities Health (`update-priorities-health.sh`)

**Purpose**: Automatically updates priority documentation based on health check findings.

Called by `weekly-health-check.sh` to sync health status with project priorities.

**Customization Required**:
- Update path to your priorities file

---

## Scheduled Jobs Configuration

### Option A: Cron (Simple)

Add to crontab (`crontab -e`):

```bash
# ========================================
# AIFRED AUTOMATION (Sundays)
# ========================================

# 3:00 AM - Weekly Docker restart (if using cron instead of systemd)
# 0 3 * * 0 $HOME/Code/AIfred/scripts/weekly-docker-restart.sh >> $HOME/Code/AIfred/.claude/logs/cron.log 2>&1

# 5:00 AM - Weekly health check
0 5 * * 0 $HOME/Code/AIfred/scripts/weekly-health-check.sh >> $HOME/Code/AIfred/.claude/logs/cron.log 2>&1

# 6:00 AM - Weekly context analysis
0 6 * * 0 $HOME/Code/AIfred/scripts/weekly-context-analysis.sh >> $HOME/Code/AIfred/.claude/logs/cron.log 2>&1
```

### Option B: Systemd Timer (Recommended for Docker Restart)

Systemd timers are more reliable for operations that interact with Docker:

**Installation**:
```bash
# Copy unit files
sudo cp scripts/systemd/weekly-docker-restart.service /etc/systemd/system/
sudo cp scripts/systemd/weekly-docker-restart.timer /etc/systemd/system/

# Edit paths in service file to match your installation
sudo nano /etc/systemd/system/weekly-docker-restart.service

# Enable and start
sudo systemctl daemon-reload
sudo systemctl enable weekly-docker-restart.timer
sudo systemctl start weekly-docker-restart.timer

# Verify
systemctl status weekly-docker-restart.timer
```

---

## Log Rotation

The `weekly-context-analysis.sh` handles log archiving:
- Logs >30 days → moved to `archive/`
- Logs >365 days → deleted

For additional log rotation, create `.claude/jobs/log-rotation.sh`:

```bash
#!/bin/bash
# AIfred Log Rotation - Daily 2 AM

LOG_DIR="$HOME/Code/AIfred/.claude/logs"
ARCHIVE_DIR="$LOG_DIR/archive"
RETENTION_DAYS=90

mkdir -p "$ARCHIVE_DIR"

# Rotate audit.jsonl if over 10MB
if [ -f "$LOG_DIR/audit.jsonl" ]; then
    SIZE=$(stat -f%z "$LOG_DIR/audit.jsonl" 2>/dev/null || stat -c%s "$LOG_DIR/audit.jsonl" 2>/dev/null)
    if [ "$SIZE" -gt 10485760 ]; then
        DATE=$(date +%Y%m%d)
        mv "$LOG_DIR/audit.jsonl" "$ARCHIVE_DIR/audit-$DATE.jsonl"
        gzip "$ARCHIVE_DIR/audit-$DATE.jsonl"
    fi
fi

# Clean old archives
find "$ARCHIVE_DIR" -name "*.gz" -mtime +$RETENTION_DAYS -delete
```

---

## Session Cleanup

Create `.claude/jobs/session-cleanup.sh`:

```bash
#!/bin/bash
# AIfred Session Cleanup - Weekly

SESSIONS_DIR="$HOME/Code/AIfred/.claude/agents/sessions"
RETENTION_DAYS=90

find "$SESSIONS_DIR" -name "*.md" -mtime +$RETENTION_DAYS -delete
echo "Session cleanup complete: $(date)"
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

## First-Run Customization Checklist

When setting up for a new environment:

- [ ] Update `PROJECT_DIR` in all scripts
- [ ] Update `DOCKER_COMPOSE_DIR` for your Docker setup
- [ ] Configure `CRITICAL_SERVICES` array in health check
- [ ] Set infrastructure IP addresses in health check
- [ ] Configure Ollama model (or set `CONTEXT_REDUCE=false`)
- [ ] Configure webhook URL for notifications (or remove)
- [ ] Choose cron vs systemd for Docker restart
- [ ] Test each script manually before scheduling

---

## Validation

- [ ] Core hooks installed and verified
- [ ] Optional hooks installed based on focus
- [ ] Scripts customized for environment
- [ ] Scheduled jobs configured (cron or systemd)
- [ ] Scripts tested manually
- [ ] Permissions configured per automation level

---

*Phase 5 of 7 - Hooks & Automation*
