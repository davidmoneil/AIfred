---
name: infrastructure-ops
version: 1.0.0
description: Infrastructure health checks, container discovery, and operations monitoring
category: infrastructure
tags: [docker, health-check, monitoring, operations, diagnostics]
created: 2026-01-16
context: fork
agent: service-troubleshooter
allowed-tools:
  - Read
  - Grep
  - Glob
  - Bash(docker:*)
  - Bash(ssh:*)
  - Bash(curl:*)
  - mcp__docker-mcp__list-containers
  - mcp__docker-mcp__get-logs
  - mcp__mcp-gateway__create_entities
  - mcp__mcp-gateway__add_observations
  - mcp__mcp-gateway__create_relations
---

# Infrastructure Operations Skill

Comprehensive infrastructure health monitoring and container operations management.

---

## Overview

This skill consolidates infrastructure operations including:
- **Service Health Checks**: Validate running services and containers
- **Gateway Monitoring**: UDM Pro and network device health
- **Container Discovery**: Document and track Docker containers
- **System Diagnostics**: Weekly health validation

**Value**: Unified approach to infrastructure monitoring with consistent status reporting and issue tracking.

---

## Quick Actions

| Need | Action | Reference |
|------|--------|---------|
| Check single service | `/check-service <name>` | @.claude/commands/check-service.md |
| Check UDM Pro gateway | `/check-gateway` | @.claude/commands/check-gateway.md |
| Run full health check | `/check-health [section]` | @.claude/commands/check-health.md |
| Discover Docker container | `/discover-docker <name>` | @.claude/commands/discover-docker.md |
| Query task metrics | `/metrics <command>` | @.claude/commands/metrics.md |

---

## Infrastructure Monitoring Workflow

```
INFRASTRUCTURE MONITORING
=========================

QUICK CHECK (single service)
  /check-service <name>
    - Container running status
    - Recent logs (last 50 lines)
    - Configuration verification
    - Issue storage (Memory MCP if problems found)

NETWORK CHECK (gateway)
  /check-gateway
    - UDM Pro system status
    - Service health (unifi-core, etc.)
    - Network interface status
    - Recent issues and health assessment

FULL CHECK (weekly)
  /check-health [section]
    - all | backup | docker | credentials
    - logging | network | storage | security
    - Generate report with pass/warn/fail counts

DISCOVERY (new containers)
  /discover-docker <name>
    - Container inspection
    - Configuration discovery
    - Documentation creation
    - Registry update (paths-registry.yaml)
```

---

## Tool Priority

**Always use MCP tools first, fallback to bash if MCP fails.**

### Docker Operations
1. `mcp__docker-mcp__list-containers` - List all containers
2. `mcp__docker-mcp__get-logs` - Retrieve container logs
3. Fallback: `docker ps`, `docker logs`, `docker inspect`

### SSH Operations (for remote checks)
1. `mcp__ssh__runRemoteCommand` - Single remote command
2. `mcp__ssh__runCommandBatch` - Multiple commands
3. Fallback: `ssh <host> "<command>"`

---

## Health Status Reporting

Use consistent severity indicators across all checks:

| Indicator | Status | Meaning |
|-----------|--------|---------|
| `[X]` CRITICAL | Immediate action required |
| `[!]` HIGH | Address within 24h |
| `[~]` MEDIUM | Address this week |
| `[-]` LOW | Nice to fix |

### Thresholds

**System Load**: Normal < 2.0 | Warning 2.0-3.0 | Critical > 3.0
**Memory/Disk**: Normal < 80% | Warning 80-90% | Critical > 90%

---

## Memory MCP Storage Pattern

**Only store when issues are found.**

### Storage Pattern for Issues

```
Entity: "Issue: [Service] [Issue Type]"
EntityType: "Infrastructure Issue"
Observations:
  - Date: [date]
  - Status: [degraded/down]
  - Symptoms: [list]
  - Log errors: [key errors]
  - Severity: [blocker/high/medium/low]
Relations:
  - affects -> [service/container]
  - caused_by -> [root cause if known]
```

### Example - Container Restart Loop

```javascript
mcp__mcp-gateway__create_entities([{
  name: "Issue: postgres_secondary Restart Loop",
  entityType: "Infrastructure Issue",
  observations: [
    "Date: 2026-01-16",
    "Status: Container restarting every 5 seconds",
    "Symptom: Permission denied on /var/lib/postgresql/data",
    "Severity: High"
  ]
}])

mcp__mcp-gateway__create_relations([{
  from: "Issue: postgres_secondary Restart Loop",
  to: "postgres_secondary",
  relationType: "affects"
}])
```

---

## Integration Points

### With Session Management
- Health check results can be noted in session-state.md
- Critical issues should be added to current-priorities.md

### With Orchestration
- Large infrastructure fixes may trigger orchestration
- Use `/orchestration:plan "fix [issue]"` for complex repairs

### With Memory MCP
- Issues stored for tracking across sessions
- Patterns and lessons captured for future reference
- Use `search_nodes` to find related past issues

---

## Common Workflows

### Daily Quick Check

```
1. /check-service n8n         # Check primary automation service
2. /check-service openwebui   # Check AI interface
3. Review any warnings/errors
4. Add critical issues to priorities if found
```

### Weekly Full Health Check

```
1. /check-health all          # Run comprehensive check
2. Review pass/warn/fail counts
3. Address any HIGH or CRITICAL items immediately
4. Create orchestration for complex fixes if needed
5. Update session-state.md with health summary
```

### New Container Discovery

```
1. /discover-docker <name>    # Discover container config
2. Review generated documentation
3. Verify paths-registry.yaml updated
4. Add to monitoring rotation
```

---

## Task Metrics

Track token usage, tool counts, and performance for all Task tool (agent/subagent) executions.

**Data source**: `.claude/logs/task-metrics.jsonl` (populated by `metrics-collector.js` SubagentStop hook)

**Commands**:
- `/metrics summary` - Overview: total runs, tokens, success rate
- `/metrics by-agent [name]` - Per-agent stats or single agent detail
- `/metrics by-session [name]` - Current or named session breakdown
- `/metrics recent [count]` - Last N executions table
- `/metrics top-tokens [limit]` - Agents ranked by token consumption
- `/metrics cost` - Estimated API cost based on token usage

---

## Troubleshooting

### MCP Docker not responding?
- Verify Docker socket permissions
- Check MCP Gateway health: `/check-gateway`
- Fallback to bash: `docker ps`

### SSH connection failures?
- Verify SSH keys: `ssh-add -l`
- Check host in known_hosts
- Test manually: `ssh <host> "hostname"`

### Health check timeouts?
- Increase timeout in command
- Run individual checks separately
- Check network connectivity

---

## Related Documentation

### Commands
- @.claude/commands/check-service.md - Single service health check
- @.claude/commands/check-gateway.md - UDM Pro gateway check
- @.claude/commands/check-health.md - Full infrastructure health check
- @.claude/commands/discover-docker.md - Container discovery

### Context Files
- @.claude/context/systems/docker/ - Docker service documentation
- @.claude/context/systems/_template-service.md - Service doc template
- @.claude/context/systems/udm-pro-operations.md - UDM Pro operations

### MCP References
- @knowledge/reference/mcp/docker-mcp.md - Docker MCP usage
- @.claude/context/integrations/memory-mcp-usage.md - Memory MCP patterns

### Agents
- @.claude/agents/service-troubleshooter.md - Systematic service diagnosis
- @.claude/agents/docker-deployer.md - Guided Docker deployment
