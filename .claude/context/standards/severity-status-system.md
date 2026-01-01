# Severity & Status System

**Last Updated**: 2026-01-01
**Status**: Active

## Overview

This document defines the **universal severity and status system** used across all Claude Code commands, scripts, hooks, and documentation. Using consistent terminology improves searchability and reduces cognitive load.

---

## Severity Levels

Use these severity levels for issues, findings, and alerts:

| Level | Text | Symbol | Color | When to Use |
|-------|------|--------|-------|-------------|
| **Critical** | `CRITICAL` | `[X]` | Red | Immediate action required, system down or at risk |
| **High** | `HIGH` | `[!]` | Orange/Yellow | Address within 24 hours, degraded functionality |
| **Medium** | `MEDIUM` | `[~]` | Blue | Address this week, minor impact |
| **Low** | `LOW` | `[-]` | Gray | Nice to fix, no immediate impact |
| **Info** | `INFO` | `[i]` | Cyan | Informational, no action needed |

### Usage Examples

**In Reports**:
```markdown
## Findings

[X] CRITICAL: Database connection failed - immediate restart required
[!] HIGH: Disk usage at 85% - cleanup within 24h
[~] MEDIUM: 3 containers using deprecated images
[-] LOW: Log rotation not configured for service X
[i] INFO: 12 containers running, all healthy
```

**In Code/Scripts**:
```bash
log_critical "Database connection failed"
log_high "Disk usage at 85%"
log_medium "Deprecated images detected"
log_low "Log rotation not configured"
log_info "All containers healthy"
```

---

## Status Values

### Service/System Status

| Status | Meaning | Next Action |
|--------|---------|-------------|
| `RUNNING` | Service is up and responding | Monitor |
| `HEALTHY` | Running + passing health checks | None |
| `DEGRADED` | Running but with issues | Investigate |
| `STOPPED` | Intentionally stopped | None unless unexpected |
| `FAILED` | Crashed or not responding | Restart/investigate |
| `STARTING` | In startup process | Wait |
| `ARCHIVED` | Removed, kept for reference | None |

### Project/Task Status

| Status | Meaning | Next Action |
|--------|---------|-------------|
| `PLANNING` | Requirements gathering | Define scope |
| `IN_PROGRESS` | Actively being worked on | Continue |
| `BLOCKED` | Cannot proceed | Resolve blocker |
| `REVIEW` | Awaiting review/approval | Review |
| `COMPLETED` | Done and verified | Archive |
| `ON_HOLD` | Paused intentionally | Resume when ready |

### Session Status (session-state.md)

| Status | Meaning |
|--------|---------|
| `IDLE` | No active work, ready for new tasks |
| `ACTIVE` | Currently working on something |
| `BLOCKED` | Waiting for external input/resolution |

---

## Check Result Indicators

For health checks, validations, and tests:

| Result | Symbol | Text | Meaning |
|--------|--------|------|---------|
| Pass | `[PASS]` | `PASS` | Check succeeded |
| Warn | `[WARN]` | `WARN` | Check passed with concerns |
| Fail | `[FAIL]` | `FAIL` | Check failed |
| Skip | `[SKIP]` | `SKIP` | Check not applicable/skipped |

### In Scripts

```bash
pass() { log "[PASS] $1"; ((CHECKS_PASSED++)); }
warn() { log "[WARN] $1"; ((CHECKS_WARNED++)); }
fail() { log "[FAIL] $1"; ((CHECKS_FAILED++)); }
skip() { log "[SKIP] $1"; ((CHECKS_SKIPPED++)); }
```

---

## Evidence Quality (for priority validation)

| Quality | Symbol | Text | Meaning |
|---------|--------|------|---------|
| Strong | `[+++]` | `STRONG` | Git commit + system verified + documented |
| Moderate | `[++]` | `MODERATE` | Some evidence, needs verification |
| Weak | `[+]` | `WEAK` | Minimal evidence |
| None | `[?]` | `NONE` | No supporting evidence found |

---

## Why Text-Based?

1. **Searchable**: `grep "CRITICAL"` works everywhere
2. **Accessible**: No unicode/emoji rendering issues
3. **Consistent**: Same in terminal, logs, markdown, JSON
4. **Universal**: Works in all contexts (scripts, docs, hooks)

---

## Integration Points

### Slash Commands

Commands should use these patterns in output:
- `/check-service` - Uses `[PASS]/[WARN]/[FAIL]`
- `/health-check` - Uses severity levels for findings

### Hooks

Hooks should use consistent logging:
- Blocking hooks: Log `[X] CRITICAL` before blocking
- Warning hooks: Log `[!] HIGH` or `[~] MEDIUM`

### Scripts

All automation scripts should use the `pass/warn/fail/skip` pattern.

---

**Maintained by**: Claude Code
