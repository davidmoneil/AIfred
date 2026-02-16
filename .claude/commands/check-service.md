---
argument-hint: <service-name>
description: Health check for infrastructure service
skill: infrastructure-ops
allowed-tools:
  - Bash(~/Scripts/check-service.sh:*)
  - Bash(docker:*)
  - Read
  - mcp__mcp-gateway__create_entities
  - mcp__mcp-gateway__create_relations
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
~/Scripts/check-service.sh $ARGUMENTS
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

## Memory MCP Integration (Optional)

If issues are found, store in Memory MCP:

```javascript
// Only if service degraded/down
mcp__mcp-gateway__create_entities([{
  name: "Issue: [Service] Health Check",
  entityType: "Infrastructure Issue",
  observations: [
    "Date: [date]",
    "Status: [degraded/down]",
    "Symptoms: [from script output]"
  ]
}])
```

## Script Location

`~/Scripts/check-service.sh`

## Related

- Script: @Scripts/check-service.sh
- `/check-services` - Check all services
- Pattern: @.claude/context/patterns/capability-layering-pattern.md
