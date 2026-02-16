---
name: system-utilities
version: 1.0.0
description: Core system utilities for file operations, backups, git sync, and service registration
category: infrastructure
tags: [utilities, system-ops, cli-backed]
created: 2026-01-22
updated: 2026-01-22
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
| When to Use | File linking, backup checks, git sync, service registration |

---

## Quick Actions

| Need | Command | Script |
|------|---------|--------|
| Link external source | `/link-external <path> [name]` | `~/Scripts/link-external.sh` |
| Check backup status | `/backup-status` | `~/Scripts/backup-status.sh` |
| Sync git to remote | `/sync-git [project]` | `~/Scripts/sync-git.sh` |
| Register new service | `/register-service <name>` | `~/Scripts/register-service.sh` |

---

## Commands

### `/link-external`

Create a symlink in `external-sources/` with documentation.

```bash
# Link a Docker compose file
/link-external ~/Docker/mydocker/logging/docker-compose.yml logging-compose

# Link with auto-generated name
/link-external /etc/nginx/nginx.conf
```

**Script**: `~/Scripts/link-external.sh`
**Output**: Creates symlink + updates paths-registry.yaml

---

### `/backup-status`

Show status of Restic backup system.

```bash
/backup-status
```

**Script**: `~/Scripts/backup-status.sh`
**Output**: Last backup time, repository health, any warnings

---

### `/sync-git`

Sync repository to GitHub with automatic commit.

```bash
# Sync current project
/sync-git

# Sync specific project
/sync-git voice-character-system
```

**Script**: `~/Scripts/sync-git.sh`
**Output**: Commits unpushed changes, pushes to origin

---

### `/register-service`

Register a new infrastructure service for monitoring.

```bash
/register-service homepage
```

**Script**: `~/Scripts/register-service.sh`
**Output**: Adds to services registry, creates context file

---

## Related

- [Infrastructure Operations](../infrastructure-ops/SKILL.md) - For health checks and troubleshooting
- [Session Management](../session-management/SKILL.md) - For session utilities
- [Capability Layering Pattern](../../context/patterns/capability-layering-pattern.md) - CLI-first design
