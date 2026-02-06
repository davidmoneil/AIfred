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
- **Container Discovery**: Document and track Docker containers
- **System Diagnostics**: Health validation

**Value**: Unified approach to infrastructure monitoring with consistent status reporting and issue tracking.

---

## Quick Actions

| Need | Action | Reference |
|------|--------|---------|
| Check Docker health | `/health-report` | @.claude/commands/health-report.md |
| Discover new container | Manual inspection | See workflow below |
| Troubleshoot service | `/agent service-troubleshooter` | @.claude/agents/service-troubleshooter.md |
| Query task metrics | `/metrics <command>` | @.claude/commands/metrics.md |

---

## Infrastructure Monitoring Workflow

```
INFRASTRUCTURE MONITORING
=========================

QUICK CHECK (single service)
  docker inspect <container>
    - Container running status
    - Recent logs (docker logs)
    - Configuration verification
    - Issue storage (Memory MCP if problems found)

FULL CHECK (regular)
  /health-report
    - Docker container status
    - System resource usage
    - Service connectivity
    - Generate report with pass/warn/fail counts

DISCOVERY (new containers)
  docker inspect <name>
    - Container inspection
    - Configuration discovery
    - Documentation creation
    - Registry update (paths-registry.yaml)
```

---

## Tool Priority

**Always use MCP tools first, fallback to bash if MCP fails.**

### Docker Operations
1. MCP tools if Docker MCP is configured
2. Fallback: `docker ps`, `docker logs`, `docker inspect`

### SSH Operations (for remote checks)
1. `mcp__ssh__runRemoteCommand` if SSH MCP is configured
2. Fallback: `ssh <host> "<command>"`

---

## Health Status Reporting

Use consistent severity indicators across all checks:

| Indicator | Meaning |
|-----------|---------|
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
  name: "Issue: my-service Restart Loop",
  entityType: "Infrastructure Issue",
  observations: [
    "Date: 2026-01-16",
    "Status: Container restarting every 5 seconds",
    "Symptom: Permission denied error",
    "Severity: High"
  ]
}])

mcp__mcp-gateway__create_relations([{
  from: "Issue: my-service Restart Loop",
  to: "my-service",
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

### Quick Docker Check

```
1. docker ps                    # Check container status
2. docker logs <name> --tail 50 # Check recent logs
3. Review any warnings/errors
4. Add critical issues to priorities if found
```

### Full Health Check

```
1. /health-report               # Run comprehensive check
2. Review pass/warn/fail counts
3. Address any HIGH or CRITICAL items immediately
4. Create orchestration for complex fixes if needed
5. Update session-state.md with health summary
```

### New Container Discovery

```
1. docker inspect <name>        # Inspect container
2. Document in paths-registry.yaml
3. Create context file if complex service
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

### Docker not responding?
- Check Docker daemon: `systemctl status docker`
- Check socket permissions
- Try: `docker info`

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
- @.claude/commands/health-report.md - Health check

### Agents
- @.claude/agents/service-troubleshooter.md - Systematic service diagnosis
- @.claude/agents/docker-deployer.md - Guided Docker deployment

### Patterns
- @.claude/context/patterns/memory-storage-pattern.md - Memory MCP patterns
