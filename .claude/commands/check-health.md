---
description: Run Infrastructure Health Check
argument-hint: [section]
skill: infrastructure-ops
allowed-tools:
  - Bash(scripts/weekly-health-check.sh:*)
  - Bash(docker:*)
  - Read
---

# /check-health - Run Infrastructure Health Check

Run the infrastructure health check for immediate system validation.

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
scripts/weekly-health-check.sh --section ${1:-all}
```

After running, report the summary:
- Number of passed/warned/failed checks
- Overall health score
- Any critical issues requiring attention
- Location of the full report

## Quick Commands

```bash
# Full check (interactive)
scripts/weekly-health-check.sh

# Quick docker check
scripts/weekly-health-check.sh --section docker

# Check backup status
scripts/weekly-health-check.sh --section backup

# JSON output for automation
scripts/weekly-health-check.sh --json --quiet
```

## Related

- `/check-service <name>` - Deep dive on individual service
- Pattern: @.claude/context/patterns/capability-layering-pattern.md
