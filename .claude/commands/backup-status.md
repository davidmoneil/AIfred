---
name: backup-status
description: Show status of Restic backup system
usage: /backup-status [--list N] [--stats] [--check]
allowed-tools:
  - Bash(~/Scripts/backup-status.sh:*)
---

# /backup-status - Backup System Status

Show the status of the Restic backup system including latest snapshots, age, and health.

## Quick Reference

```bash
# Quick status
~/Scripts/backup-status.sh

# List last 10 snapshots
~/Scripts/backup-status.sh --list 10

# Include repository statistics
~/Scripts/backup-status.sh --stats

# Verify integrity
~/Scripts/backup-status.sh --check

# JSON output
~/Scripts/backup-status.sh --json
```

## Execution

**Parse arguments from**: $ARGUMENTS

Run the CLI script:

```bash
~/Scripts/backup-status.sh $ARGUMENTS
```

## Usage Examples

```
/backup-status              # Quick status
/backup-status --list 10    # Last 10 snapshots
/backup-status --stats      # Repository stats
/backup-status --check      # Verify integrity
/backup-status --json       # JSON for automation
```

## Output Example

```
═══════════════════════════════════════════════════
              BACKUP STATUS
═══════════════════════════════════════════════════

Repository: sftp:BackupServer:/path/to/backups

✓ Backups healthy

Latest Snapshot:
  ID:   a1b2c3d4
  Time: 2026-01-20T03:00:00Z
  Age:  16 hours

Total Snapshots: 45

─── Recent Snapshots (last 5) ───

ID        Time                 Host     Tags
───────────────────────────────────────────
a1b2c3d4  2026-01-20 03:00    MyServer
b2c3d4e5  2026-01-19 03:00    MyServer
...

═══════════════════════════════════════════════════
Next scheduled: Mon 2026-01-21 03:00:00
Manual backup: ~/Scripts/restic-backup.sh
```

## CLI Options

| Option | Description |
|--------|-------------|
| `-l, --list N` | List last N snapshots (default: 5) |
| `-s, --stats` | Show repository statistics |
| `-c, --check` | Verify repository integrity |
| `-j, --json` | JSON output |
| `-q, --quiet` | Minimal output (just status) |

## Script Details

**Location**: `~/Scripts/backup-status.sh`
**Repository**: `sftp:BackupServer:/path/to/backups`
**Exit Codes**:
- 0: Backups healthy
- 1: Configuration issue
- 2: Backup overdue (>48h)
- 3: Repository issue

## Related

- `~/Scripts/restic-backup.sh` - Manual backup
- `~/Scripts/restic-restore.sh` - Restore from backup
- `~/Scripts/restic-status.sh` - Alternative status script
