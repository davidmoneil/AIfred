---
name: docker-restart
description: Weekly Docker restart with health verification
usage: /docker-restart [--dry-run] [--skip-restart] [--verbose]
allowed-tools:
  - Bash(scripts/weekly-docker-restart.sh:*)
---

# /docker-restart - Docker Restart with Health Verification

Restarts Docker daemon and verifies all services come back up healthy.

## Quick Reference

```bash
# Full restart with verification
scripts/weekly-docker-restart.sh

# Check what would happen (dry-run)
scripts/weekly-docker-restart.sh --dry-run

# Skip the actual restart, just verify services
scripts/weekly-docker-restart.sh --skip-restart
```

## Execution

**Parse arguments from**: $ARGUMENTS

Run the CLI script:

```bash
scripts/weekly-docker-restart.sh $ARGUMENTS
```

## What It Does

1. **Pre-restart checks** - Records current container states
2. **Stops Docker** - Graceful shutdown of all containers
3. **Restarts Docker daemon** - Cleans up resources
4. **Starts compose stacks** - In dependency order
5. **Health verification** - Waits for all services to be healthy
6. **Sends notification** - Reports success/failure via webhook

## Services Verified

| Service | Health Endpoint |
|---------|-----------------|
| n8n | `http://localhost:5678/healthz` |
| Loki | `http://localhost:3100/ready` |
| Prometheus | `http://localhost:9090/-/healthy` |
| Neo4j | `http://localhost:7474` |
| PostgreSQL | Container health check |

## Compose Stacks (Start Order)

1. n8n stack
2. logging stack
3. mcp stack
4. caddy (reverse proxy)

## Scheduled Run

The script runs automatically via cron:

```
0 3 * * 0 $AIFRED_HOME/scripts/weekly-docker-restart.sh
```

(Every Sunday at 3 AM)

## Log Location

Logs are stored in: `~/logs/weekly-restart/`

## Script Details

**Location**: `scripts/weekly-docker-restart.sh`
**Timeout**: 120 seconds for service verification
**Notification**: Webhook to n8n for success/failure alerts
