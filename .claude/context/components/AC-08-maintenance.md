# AC-08 Maintenance Workflows — Autonomic Component Specification

**Component ID**: AC-08
**Version**: 1.0.0
**Status**: active
**Created**: 2026-01-16
**Last Modified**: 2026-01-16
**PR**: PR-12.8

---

## 1. Identity

### Purpose
Perform maintenance tasks to keep the Jarvis codebase AND active project space healthy, documentation fresh, and artifacts clean. Maintenance Workflows ensure long-term codebase hygiene through automated cleanup, audits, health checks, and organization review.

### Scope
| Dimension | Applies |
|-----------|---------|
| Jarvis Codebase | Yes |
| Active Project | Yes |
| All Sessions | Yes |

**Scope Note**: Unlike Tier 2 self-improvement components (AC-05, AC-06, AC-07), Maintenance operates on BOTH the Jarvis codebase AND the active project space. This is the ONLY Tier 2 component with dual scope.

### Tier Classification
- [ ] **Tier 1**: Active Work (user-facing, direct task contribution)
- [x] **Tier 2**: Self-Improvement (Jarvis-only, background operation)

### Design Principles

1. **Dual Scope**: Maintains both Jarvis codebase AND active project health
2. **Non-Destructive**: Proposes changes, never executes destructive actions without approval
3. **Self-Directed**: Runs during idle time or by user request
4. **Auditable**: All maintenance actions logged
5. **Freshness-Focused**: Files not updated in 30+ days flagged for R&D review

---

## 2. Triggers

### Activation Conditions
| Trigger Type | Condition | Priority |
|--------------|-----------|----------|
| **Manual** | User requests `/maintain` | high |
| **Manual** | User requests `/self-improve --focus=maintenance` | high |
| **Scheduled** | Session start (health checks only) | medium |
| **Scheduled** | Session end (cleanup only) | medium |
| **Scheduled** | Downtime detector (~30 min idle) | low |
| **Scheduled** | Weekly freshness audit | low |

### Trigger Implementation
```
Maintenance trigger logic:
  - /maintain command → full maintenance cycle
  - /self-improve → runs as part of cycle
  - Session start → health checks only
  - Session end → cleanup only
  - Downtime detected → autonomous maintenance
  - Weekly schedule → freshness audits

Priority handling:
  - User-triggered: full maintenance cycle (all tasks)
  - Session start: health checks only (fast)
  - Session end: cleanup only (non-blocking)
  - Downtime-triggered: selected tasks based on last run times
  - Scheduled: specific task (freshness, optimization)
```

### Suppression Conditions
| Condition | Behavior |
|-----------|----------|
| `JARVIS_DISABLE_AC08=true` | Skip all maintenance |
| `JARVIS_QUICK_MODE=true` | Skip maintenance |
| Active PR work in progress | Defer until PR complete |
| High context usage (>70%) | Defer full cycle (allow health checks) |
| Session < 5 minutes | Skip all (too brief) |

---

## 3. Inputs

### Required Inputs
| Input | Source | Format | Purpose |
|-------|--------|--------|---------|
| Autonomy config | `.claude/config/autonomy-config.yaml` | YAML | Settings |
| Maintenance state | `.claude/state/components/AC-08-maintenance.json` | JSON | Last run times |

### Optional Inputs
| Input | Source | Default | Purpose |
|-------|--------|---------|---------|
| Project config | `projects.yaml` | None | Active project paths |
| Last maintenance log | `.claude/logs/maintenance.log` | None | Previous actions |
| File timestamps | File system | Current | Freshness detection |
| Hook directory | `.claude/hooks/` | None | Health checks |
| Settings file | `~/.claude/settings.json` | None | Schema validation |

### Context Requirements

- [x] Autonomy config exists
- [x] File system access
- [ ] Git access (optional, for housekeeping)
- [ ] MCP connectivity (optional, for health checks)

---

## 4. Outputs

### Primary Outputs
| Output | Destination | Format | Consumers |
|--------|-------------|--------|-----------|
| Maintenance log | `.claude/logs/maintenance.log` | Text | User, diagnostics |
| Health report | `.claude/reports/maintenance/health-YYYY-MM-DD.md` | Markdown | User, AC-06 |
| Freshness report | `.claude/reports/maintenance/freshness-YYYY-MM-DD.md` | Markdown | User, AC-07 |
| Organization report | `.claude/reports/maintenance/organization-YYYY-MM-DD.md` | Markdown | User |
| Optimization proposals | `evolution-queue.yaml` | YAML | AC-06 |

### Side Effects
| Effect | Description | Reversible |
|--------|-------------|------------|
| Log rotation | Old logs archived/deleted | No |
| Temp cleanup | Transient files removed | No |
| Git housekeeping | Prune/gc operations | Yes (limited) |
| Reports created | New files in reports directory | Yes (delete) |
| Proposals queued | Evolution queue additions | Yes (remove) |

### State Changes
| State | Location | Change Type |
|-------|----------|-------------|
| Maintenance state | `.claude/state/components/AC-08-maintenance.json` | create/update |
| Evolution queue | `evolution-queue.yaml` | append |
| Logs directory | `.claude/logs/` | rotate/cleanup |
| Reports directory | `.claude/reports/maintenance/` | create |

---

## 5. Dependencies

### System Dependencies
| Dependency | Type | Failure Behavior |
|------------|------|------------------|
| File system | hard | Cannot run |
| AC-06 Self-Evolution | soft | Proposals queued but not processed |
| AC-07 R&D Cycles | soft | Skip freshness→R&D handoff |
| Downtime detector | soft | Skip auto-trigger |

### MCP Dependencies
| MCP Server | Tools Used | Required |
|------------|------------|----------|
| Memory | create_entities, search_nodes | No (skip persistence) |
| Git | git_status, git_gc | No (skip git tasks) |
| Filesystem | list_directory, get_file_info | No (use native) |

### File Dependencies
| File | Purpose | Create if Missing |
|------|---------|-------------------|
| `.claude/state/components/AC-08-maintenance.json` | Track last run times | Yes |
| `.claude/logs/` | Log directory | Yes |
| `.claude/reports/maintenance/` | Report storage | Yes |
| `~/.claude/settings.json` | Hook validation | No (warn) |

---

## 6. Consumers

### Downstream Systems
| Consumer | Relationship | Data Consumed |
|----------|--------------|---------------|
| AC-06 Self-Evolution | reads | Optimization proposals |
| AC-07 R&D Cycles | reads | Freshness report |
| AC-05 Self-Reflection | may read | Health patterns |
| User | reads | All reports |

### User Visibility
| Aspect | Visible to User |
|--------|-----------------|
| Maintenance start | Yes (if manual or significant) |
| Progress | Minimal (summary at end) |
| Reports | Yes (full reports available) |
| Actions taken | Yes (logged) |
| Proposals generated | Yes (listed in report) |

### Integration Points

```
┌─────────────────────────────────────────────────────────────────────┐
│                    MAINTENANCE WORKFLOWS INTEGRATION                  │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  TRIGGER SOURCES                                                     │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐     │
│  │  User           │  │  Session        │  │  Downtime       │     │
│  │  (/maintain)    │  │  (start/end)    │  │  (~30 min idle) │     │
│  └────────┬────────┘  └────────┬────────┘  └────────┬────────┘     │
│           │                    │                    │               │
│           └────────────────────┼────────────────────┘               │
│                                │                                     │
│                                ▼                                     │
│                    ┌─────────────────────┐                          │
│                    │      AC-08          │                          │
│                    │   Maintenance       │                          │
│                    │    Workflows        │                          │
│                    └──────────┬──────────┘                          │
│                               │                                      │
│              ┌────────────────┼────────────────┐                    │
│              │                │                │                    │
│              ▼                ▼                ▼                    │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐     │
│  │  Health         │  │  Freshness      │  │  Organization   │     │
│  │  Report         │  │  Report         │  │  Report         │     │
│  │                 │  │  → AC-07 R&D    │  │                 │     │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘     │
│                                                                      │
│                    ┌─────────────────────┐                          │
│                    │  Optimization       │                          │
│                    │  Proposals          │                          │
│                    │  → AC-06 Evolution  │                          │
│                    └─────────────────────┘                          │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 7. Gates

### Approval Checkpoints
| Gate ID | Trigger | Risk Level | Auto-Approve |
|---------|---------|------------|--------------|
| G-01 | Start maintenance | Low | Yes |
| G-02 | Health check | Low | Yes |
| G-03 | Freshness audit | Low | Yes |
| G-04 | Organization review | Low | Yes |
| G-05 | Log rotation | Low | Yes |
| G-06 | Temp cleanup | Low | Yes |
| G-07 | Git housekeeping | Medium | Yes (notify) |
| G-08 | File deletion (orphans) | High | No (require approval) |
| G-09 | Structure change proposal | Medium | No (proposal only) |

### Risk Classification
| Action Type | Risk Level | Gate Requirement |
|-------------|------------|------------------|
| Read operations | Low | None |
| Report generation | Low | None |
| Log rotation | Low | None |
| Temp cleanup | Low | None |
| Git gc/prune | Medium | Notify user |
| File deletion | High | Require approval |
| Structure changes | Medium+ | Proposal only |

### Gate Implementation
```
Maintenance is mostly low-risk (read, report, rotate).
The key gates are:

1. Git housekeeping: Notify user but proceed
2. File deletion: NEVER delete files without explicit approval
3. Structure changes: Create proposals, never auto-implement

Destructive actions are logged and can be reviewed
before execution.
```

---

## 8. Metrics

### Performance Metrics
| Metric | Unit | Target | Alert Threshold |
|--------|------|--------|-----------------|
| Maintenance time | seconds | < 120 | > 300 |
| Files scanned | count | varies | N/A |
| Issues found | count | varies | > 50 (warning) |

### Component-Specific Metrics
| Metric | Description | Measurement |
|--------|-------------|-------------|
| `logs_rotated` | Log files archived | integer |
| `temps_cleaned` | Temp files removed | integer |
| `stale_files_found` | Files > 30 days old | integer |
| `health_issues` | Hook/settings problems | integer |
| `orphaned_files` | Unreferenced files | integer |
| `misplaced_files` | Files in wrong location | integer |
| `broken_links` | Invalid internal references | integer |
| `proposals_generated` | Optimization proposals | integer |
| `maintenance_runs` | Total runs (any trigger) | integer |

### Storage
| Metric Type | Storage Location | Retention |
|-------------|------------------|-----------|
| Per-run | `.claude/metrics/AC-08-maintenance.jsonl` | 30 days |
| Aggregated | `.claude/metrics/aggregates/daily/` | 1 year |

### Emission Format
```jsonl
{"timestamp": "2026-01-16T18:00:00.000Z", "component": "AC-08", "metric": "stale_files_found", "value": 12, "unit": "count"}
{"timestamp": "2026-01-16T18:00:00.000Z", "component": "AC-08", "metric": "health_issues", "value": 2, "unit": "count"}
```

---

## 9. Failure Modes

### Known Failure Scenarios
| Failure | Cause | Detection | Recovery |
|---------|-------|-----------|----------|
| File access denied | Permissions | OS error | Skip file, log warning |
| Git unavailable | Not a repo | Git error | Skip git tasks |
| Settings missing | No Claude install | File not found | Skip hook validation |
| Timeout | Large directory scan | Timer | Checkpoint, resume later |
| MCP unavailable | Server down | Connection error | Skip MCP tasks |

### Graceful Degradation
| Degradation Level | Trigger | Behavior |
|-------------------|---------|----------|
| Full | All systems operational | Complete maintenance cycle |
| Partial | Git unavailable | Skip git housekeeping |
| Partial | MCP unavailable | Skip persistence |
| Partial | Settings missing | Skip hook validation |
| Minimal | File access issues | Report errors only |

### Error Reporting
| Error Type | Notification | Log Location |
|------------|--------------|--------------|
| Access denied | Warning | maintenance.log |
| Validation failure | User notification | maintenance.log |
| Timeout | Alert + checkpoint | maintenance.log |
| Corruption detected | Alert (high priority) | maintenance.log |

### Rollback Procedures
1. Log rotation: Archived logs can be restored
2. Temp cleanup: Files are gone (low impact)
3. Reports: Can be deleted and regenerated
4. Proposals: Can be removed from queue

---

## Implementation Notes

### Current Implementation
| Artifact | Path | Status |
|----------|------|--------|
| Component spec | `.claude/context/components/AC-08-maintenance.md` | exists |
| Pattern document | `.claude/context/patterns/maintenance-pattern.md` | exists |
| Maintenance command | `.claude/commands/maintain.md` | exists |
| State file | `.claude/state/components/AC-08-maintenance.json` | exists |
| Reports directory | `.claude/reports/maintenance/` | exists |
| Health checker | `.claude/hooks/health-checker.js` | optional |
| Freshness auditor | `.claude/hooks/freshness-auditor.js` | optional |
| Organization auditor | `.claude/hooks/organization-auditor.js` | optional |

### Maintenance Task Details

```
┌─────────────────────────────────────────────────────────────────────┐
│                       MAINTENANCE TASKS                              │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  CLEANUP TASKS (Automatic)                                          │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │  • Log rotation: Archive logs > 7 days, delete > 30 days      │  │
│  │  • Temp cleanup: Remove .claude/context/.* transients         │  │
│  │  • Orphan detection: Find unreferenced files (report only)    │  │
│  │  • Git housekeeping: Prune, gc (if repository)                │  │
│  └───────────────────────────────────────────────────────────────┘  │
│                                                                      │
│  FRESHNESS AUDITS (Report)                                          │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │  Documentation Staleness:                                      │  │
│  │  • Files not updated in 30+ days → flag for R&D review        │  │
│  │  • References to outdated versions → highlight                 │  │
│  │  • Broken internal links → list for fix                       │  │
│  │                                                                │  │
│  │  Dependency Freshness:                                         │  │
│  │  • MCP server versions → compare to registry                  │  │
│  │  • Plugin versions → compare to registry                      │  │
│  │  • Node.js packages → npm outdated                            │  │
│  │                                                                │  │
│  │  Pattern Applicability:                                        │  │
│  │  • Are documented patterns still in use?                      │  │
│  │  • Do patterns match current implementation?                  │  │
│  └───────────────────────────────────────────────────────────────┘  │
│                                                                      │
│  HEALTH CHECKS (Session Start)                                      │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │  • Hook syntax validation: All JS/SH hooks parse correctly    │  │
│  │  • Settings schema validation: settings.json is valid         │  │
│  │  • MCP connectivity: Test each configured MCP                 │  │
│  │  • Git status consistency: Clean tree, correct branch         │  │
│  └───────────────────────────────────────────────────────────────┘  │
│                                                                      │
│  ORGANIZATION REVIEW (Report + Proposals)                           │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │  Jarvis Codebase:                                              │  │
│  │  • .claude/ file organization and logic                       │  │
│  │  • Hook and settings validation                               │  │
│  │  • Pattern file completeness                                  │  │
│  │  • Behavioral requirements compliance                         │  │
│  │                                                                │  │
│  │  Active Project:                                               │  │
│  │  • Project space organization per design specs                │  │
│  │  • File placement vs project design specs                     │  │
│  │  • Reference/link integrity                                   │  │
│  │  • Save location compliance                                   │  │
│  └───────────────────────────────────────────────────────────────┘  │
│                                                                      │
│  OPTIMIZATION (Proposals Only)                                      │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │  • Context usage analysis: What consumes budget?              │  │
│  │  • Duplicate detection: Similar files/patterns                │  │
│  │  • Consolidation proposals: Merge redundant content           │  │
│  └───────────────────────────────────────────────────────────────┘  │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### Scheduling Matrix

| Task | Frequency | Trigger | Automation Level |
|------|-----------|---------|------------------|
| Log rotation | Daily/Idle | Session end, idle | Fully automatic |
| Temp cleanup | Session end | Session end | Fully automatic |
| Doc freshness | Idle/Weekly | Idle, scheduled | Report, flag for R&D |
| Health checks | Session start | Session start | Warn if issues |
| Organization | Idle/Manual | /maintain, idle | Report + proposals |
| Optimization | Idle/Monthly | /maintain, scheduled | Proposals only |

### Resolved Questions
- [x] Log retention policy: 7 days archive, 30 days delete (default)
- [x] Freshness threshold: 30 days default, configurable via CLI arg to freshness-auditor.sh
- [x] Health check timeout per MCP: 10 seconds (standard)
- [x] Integration with PR-14: Deferred to PR-14 build

### Design Decisions Log
| Date | Decision | Rationale |
|------|----------|-----------|
| 2026-01-16 | Dual scope (Jarvis + project) | Only maintenance component that spans both |
| 2026-01-16 | Non-destructive default | Safe operation paramount |
| 2026-01-16 | Freshness → R&D handoff | Stale content triggers research |
| 2026-01-16 | Session triggers for quick tasks | Health at start, cleanup at end |

---

## Validation Checklist

Before marking this component as "active":

- [x] All 9 specification sections completed
- [x] Triggers tested (manual /maintain works; freshness + organization auditors verified)
- [x] Inputs/outputs validated (reports generated at `.claude/reports/maintenance/`)
- [x] Dependencies verified (file system, git)
- [x] Gates implemented (deletion requires approval; >10 files triggers confirmation)
- [x] Metrics emission working (telemetry-emitter.js integrated)
- [ ] Failure modes tested (missing files, timeout scenarios)
- [x] Integration with consumers verified (AC-06 proposals, AC-07 freshness handoff)
- [x] Documentation updated

---

*AC-08 Maintenance Workflows — Jarvis Phase 6 PR-12.8*
