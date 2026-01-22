# /maintain — Maintenance Workflows Command

**Purpose**: Trigger AC-08 Maintenance cycle for codebase hygiene.

**Usage**: `/maintain [--scope jarvis|project|all] [--task <task>] [--dry-run]`

---

## Overview

The `/maintain` command triggers Jarvis' maintenance workflows, performing cleanup, freshness audits, health checks, and organization review.

## Options

| Option | Values | Default | Description |
|--------|--------|---------|-------------|
| `--scope` | jarvis, project, all | all | Scope of maintenance |
| `--task` | cleanup, freshness, health, organization, optimization | all | Specific task only |
| `--dry-run` | flag | false | Show what would be done |
| `--quick` | flag | false | Health checks only |

## Maintenance Tasks

### 1. Cleanup
- Log file rotation (>7 days)
- Temp file removal
- Orphan artifact detection
- Git housekeeping (gc, prune)

### 2. Freshness Audit
- Documentation staleness (>30 days unchanged)
- Dependency freshness
- Pattern applicability check
- Stale references detection

### 3. Health Checks
- Hook validation (all hooks execute)
- Settings schema validation
- MCP connectivity
- Git status check

### 4. Organization Review
- Jarvis structure validation
- Project structure validation
- Reference link validation
- Duplicate detection

### 5. Optimization Analysis
- Context usage patterns
- Duplicate content detection
- Consolidation opportunities
- Generates proposals for AC-06

## Examples

```bash
# Full maintenance cycle
/maintain

# Jarvis codebase only
/maintain --scope jarvis

# Active project only
/maintain --scope project

# Only run health checks
/maintain --task health

# Only run cleanup
/maintain --task cleanup

# See what would be done
/maintain --dry-run

# Quick health check (session start)
/maintain --quick
```

## Session Boundary Integration

### At Session Start
Automatically runs:
- Health checks (hooks, settings, MCPs)
- Quick status report

### At Session End
Automatically runs:
- Log rotation
- Temp cleanup
- Git status summary

## Output

### MANDATORY: Create Report File

**ALWAYS create a report file at completion.** This is not optional.

```bash
# Ensure directory exists
mkdir -p .claude/reports/maintenance

# Create report file
# Write to: .claude/reports/maintenance/maintenance-YYYY-MM-DD.md
```

**If multiple maintenance runs same day**: Use suffix `-N` (e.g., `maintenance-2026-01-22-2.md`)

### Report Location
`.claude/reports/maintenance/maintenance-YYYY-MM-DD.md`

### Report Format
```markdown
# Maintenance Report — [Date]

## Summary
- Tasks run: X
- Issues found: Y
- Actions proposed: Z

## Cleanup Results
[Files rotated, temps removed, orphans detected]

## Freshness Audit
[Stale files flagged, freshness status]

## Health Check Results
[Hook status, settings validation, MCP connectivity]

## Organization Review
[Structure issues, duplicate detection]

## Optimization Proposals
[Consolidation opportunities → evolution queue]

## Recommended Actions
[Manual actions needed]
```

### Side Effects
- Log files rotated
- Temp files removed (with approval)
- Health status updated
- Optimization proposals queued

## Safety: Non-Destructive Default

Maintenance is **non-destructive by default**:
- File deletion requires user approval
- Cleanup proposes, doesn't execute
- Git operations are read-only (except gc)

## Integration

- **AC-05**: Freshness findings may trigger reflection
- **AC-06**: Optimization proposals queued for evolution
- **AC-07**: Stale patterns flagged for R&D review
- **AC-01**: Health checks at session start
- **AC-09**: Cleanup at session end

---

*Part of Jarvis Phase 6 Autonomic System (AC-08)*
