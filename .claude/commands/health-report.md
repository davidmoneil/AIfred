# /health-report Command

Generate a comprehensive infrastructure health report aggregating all system checks.

## Usage

```
/health-report
/health-report --quick    # Skip slow checks
/health-report --full     # Include all details
```

## What It Does

This command aggregates health information from multiple sources into a single report:

### 1. Docker Services
- Container status (running/stopped/unhealthy)
- Resource usage (if available)
- Recent restarts

### 2. Memory MCP
- Total entities tracked
- Recently accessed entities
- Stale entities (not accessed in 90+ days)

### 3. Context Health
- Total context files
- Stale files needing review
- Broken cross-references

### 4. MCP Servers
- Connection status for each server
- Last successful operation

## Output Format

```markdown
# Infrastructure Health Report
**Generated**: YYYY-MM-DD HH:MM

## Summary
| Category | Status | Details |
|----------|--------|---------|
| Docker | ✅ HEALTHY | 18/20 containers running |
| Memory | ⚠️ ATTENTION | 5 stale entities |
| Context | ✅ HEALTHY | All files current |
| MCP | ❌ DEGRADED | PostgreSQL MCP offline |

## Docker Services
### Running (18)
- n8n: healthy, 5d uptime
- caddy: healthy, 12d uptime
...

### Stopped (2)
- appsmith: Exited 5 weeks ago
- postgres_secondary: Restarting

## Memory MCP
- **Total Entities**: 45
- **Accessed This Week**: 12
- **Stale (>90d)**: 5 entities
  - Decision: Old Database Choice (142d)
  - ...

## Context Files
- **Total**: 28 files
- **Fresh**: 25 files
- **Stale (>90d)**: 3 files
  - systems/old-service.md (120d)
  - ...

## MCP Servers
| Server | Status | Last Check |
|--------|--------|------------|
| Docker MCP | ✅ Connected | Just now |
| Memory MCP | ✅ Connected | Just now |
| PostgreSQL MCP | ❌ Failed | Connection refused |

## Recommendations
1. [!] HIGH: Investigate PostgreSQL MCP connection
2. [~] MEDIUM: Review 3 stale context files
3. [-] LOW: Consider archiving 5 unused Memory entities
```

## Implementation

When this command is invoked, Claude will:

1. **Check Docker** (if available):
   ```bash
   docker ps --format "table {{.Names}}\t{{.Status}}\t{{.RunningFor}}"
   ```

2. **Check Memory MCP**:
   - Read `.claude/agents/memory/entity-metadata.json`
   - Calculate access statistics
   - Identify stale entities

3. **Check Context Files**:
   - Run context-staleness analysis
   - Check for broken references

4. **Check MCP Connections**:
   - Attempt simple operations on each server
   - Report connection status

5. **Generate Report**:
   - Aggregate all findings
   - Apply severity classification
   - Provide actionable recommendations

## Severity Classification

Uses the standard severity system:
- `[X] CRITICAL`: Service down, data at risk
- `[!] HIGH`: Degraded service, needs attention within 24h
- `[~] MEDIUM`: Minor issues, address this week
- `[-] LOW`: Nice to fix, no immediate impact

## Scheduling

Consider running weekly via cron:
```bash
# Add to crontab
0 9 * * 1 cd /path/to/project && claude -p "/health-report" > reports/health-$(date +%Y%m%d).md
```

## Related

- @.claude/context/standards/severity-status-system.md - Severity levels
- @.claude/jobs/memory-prune.sh - Memory pruning script
- @.claude/jobs/context-staleness.sh - Context staleness detection
