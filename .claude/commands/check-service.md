---
argument-hint: <service-name>
description: Health check for infrastructure service
skill: infrastructure-ops
allowed-tools:
  - Bash(scripts/check-service.sh:*)
  - Bash(docker:*)
  - Read
---

# /check-service

Health check a Docker service using `check-service.sh`.

## Usage

```
/check-service <service-name>
```

## Execution

Run the check script:

```bash
scripts/check-service.sh $ARGUMENTS
```

Report the results to the user.

## Options

Pass through to script:

| Flag | Description |
|------|-------------|
| `-l, --logs N` | Show last N log lines (default: 20) |
| `-f, --full` | Full inspection (docker inspect) |
| `-j, --json` | JSON output |
| `-q, --quiet` | Minimal output |

## Examples

```bash
/check-service n8n
/check-service grafana --logs 50
/check-service caddy --full
```

## Script Location

`scripts/check-service.sh`

## Related

- Script: @scripts/check-service.sh
- `/check-health` - Full infrastructure health check
- Pattern: @.claude/context/patterns/capability-layering-pattern.md
