---
name: system-utilities
version: 1.0.0
description: Core system utilities for file operations, git sync, priority maintenance, and conversation archival
category: maintenance
tags: [utilities, system-ops, cli-backed]
created: 2026-02-05
updated: 2026-02-05
context: shared
---

# System Utilities Skill

Core system utilities that don't fit into domain-specific skills. These are CLI-backed commands for common operations.

---

## Overview

| Aspect | Description |
|--------|-------------|
| Purpose | Provide CLI-backed utilities for system operations |
| Pattern | Type 1: CLI-Backed (Deterministic) |
| When to Use | File linking, git sync, priority maintenance, history archival |

---

## Quick Actions

| Need | Command | Script |
|------|---------|--------|
| Link external source | `/link-external <path> [name]` | `scripts/link-external.sh` |
| Sync git to remote | `/sync-git [project]` | `scripts/sync-git.sh` |
| Check priority health | `/update-priorities review` | `scripts/priority-cleanup.sh` |
| Archive old conversations | Run directly | `scripts/claude-history-archiver.sh` |

---

## Commands

### `/link-external`

Create a symlink in `external-sources/` with documentation.

```bash
# Link a Docker compose file
/link-external ~/docker/my-service/docker-compose.yml my-service-compose

# Link with auto-generated name
/link-external /etc/nginx/nginx.conf
```

**Script**: `scripts/link-external.sh`
**Output**: Creates symlink + updates paths-registry.yaml

---

### `/sync-git`

Sync repository to GitHub with automatic commit.

```bash
# Sync current project
/sync-git

# Sync specific project
/sync-git my-project
```

**Script**: `scripts/sync-git.sh`
**Output**: Commits unpushed changes, pushes to origin

---

## Maintenance Scripts

### Priority Cleanup

Detects issues with current-priorities.md and suggests cleanup.

```bash
# Check for issues
./scripts/priority-cleanup.sh

# Preview what would be done
./scripts/priority-cleanup.sh --dry-run

# Verbose output
./scripts/priority-cleanup.sh --verbose

# Force Claude review even if no issues
./scripts/priority-cleanup.sh --force-claude
```

**Detects**: Oversized file, stale items, completed items in wrong sections, old dates
**Action**: Reports issues and suggests Claude review for cleanup

---

### Conversation History Archiver

Archives old/large Claude conversation files with keyword-rich filenames.

```bash
# Show current status
./scripts/claude-history-archiver.sh --status

# Preview what would be archived
./scripts/claude-history-archiver.sh --dry-run

# Archive eligible files
./scripts/claude-history-archiver.sh --archive
```

**Policy** (configurable via environment):
- `ARCHIVE_AGE_DAYS`: Archive files older than N days (default: 7)
- `ARCHIVE_SIZE_MB`: Archive files larger than N MB (default: 5)
- `MIN_AGE_DAYS`: Never archive files younger than N days (default: 1)

**Output**: Moves old JSONL files to `~/.claude/archive/conversations/` with descriptive filenames

---

## Related

- [Infrastructure Operations](../infrastructure-ops/SKILL.md) - For health checks and troubleshooting
- [Session Management](../session-management/SKILL.md) - For session utilities
- [Capability Layering Pattern](../../context/patterns/capability-layering-pattern.md) - CLI-first design
