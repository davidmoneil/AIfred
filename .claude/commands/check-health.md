---
description: Run Infrastructure Health Check
argument-hint: [section]
skill: infrastructure-ops
allowed-tools:
  - Bash(~/Scripts/weekly-health-check.sh:*)
  - Bash(docker:*)
  - Read
---

# /check-health - Run Infrastructure Health Check

Run the weekly infrastructure health check manually for immediate system validation.

## Usage

```
/check-health [section]
```

**Sections** (optional):
- `all` - Full health check (default)
- `backup` - Backup systems only
- `docker` - Docker containers only
- `credentials` - API and credential tests
- `logging` - Logging stack health
- `network` - Network and SSH connectivity
- `storage` - Storage and certificates
- `security` - Security audit

## Execution

Run the health check script with the specified section:

```bash
~/Scripts/weekly-health-check.sh --section ${1:-all}
```

After running, report the summary:
- Number of passed/warned/failed checks
- Overall health score
- Any critical issues requiring attention
- Location of the full report

## Quick Commands

```bash
# Full check (interactive)
~/Scripts/weekly-health-check.sh

# Quick docker check
~/Scripts/weekly-health-check.sh --section docker

# Check backup status
~/Scripts/weekly-health-check.sh --section backup

# JSON output for automation
~/Scripts/weekly-health-check.sh --json --quiet
```

## Related

- Documentation: @.claude/context/systems/weekly-health-check.md
- Systemd timer: `systemctl --user status weekly-health-check.timer`
- Reports: `~/logs/weekly-health/`
