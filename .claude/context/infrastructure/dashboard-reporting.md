# Dashboard and Reporting Specification

**ID**: PR-13.4
**Version**: 1.0.0
**Status**: implementing
**Created**: 2026-01-16
**Last Modified**: 2026-01-16

---

## Purpose

Provide visibility into autonomous behavior through real-time status displays, historical trend reports, and alert notifications. The dashboard serves as the primary interface for monitoring Jarvis health and effectiveness.

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                  DASHBOARD & REPORTING ARCHITECTURE                  │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  DATA FEEDS                                                          │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐   │
│  │ Telemetry   │ │ Benchmarks  │ │  Scores     │ │ Regression  │   │
│  │ (PR-13.1)   │ │ (PR-13.2)   │ │ (PR-13.3)   │ │ (PR-13.5)   │   │
│  └──────┬──────┘ └──────┬──────┘ └──────┬──────┘ └──────┬──────┘   │
│         │               │               │               │           │
│         └───────────────┴───────────────┴───────────────┘           │
│                                   │                                  │
│                                   ▼                                  │
│                        ┌─────────────────────┐                      │
│                        │  DATA AGGREGATOR    │                      │
│                        │                     │                      │
│                        │  • Real-time feed   │                      │
│                        │  • Historical query │                      │
│                        │  • Alert filtering  │                      │
│                        └──────────┬──────────┘                      │
│                                   │                                  │
│              ┌────────────────────┼────────────────────┐            │
│              │                    │                    │            │
│              ▼                    ▼                    ▼            │
│       ┌─────────────┐     ┌─────────────┐     ┌─────────────┐      │
│       │  Real-Time  │     │  Reports    │     │   Alerts    │      │
│       │  Dashboard  │     │  Generator  │     │   Manager   │      │
│       └──────┬──────┘     └──────┬──────┘     └──────┬──────┘      │
│              │                   │                   │              │
│              ▼                   ▼                   ▼              │
│       ┌─────────────┐     ┌─────────────┐     ┌─────────────┐      │
│       │  /status    │     │  Markdown   │     │  Notify     │      │
│       │  Command    │     │  Files      │     │  User       │      │
│       └─────────────┘     └─────────────┘     └─────────────┘      │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Dashboard Views

### 1. Real-Time Status (/status)

Quick health check for current session.

```
┌─────────────────────────────────────────────────────────────────────┐
│                    JARVIS STATUS                                     │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  Session: session_2026-01-16_002                                     │
│  Duration: 2h 15m                                                    │
│  Context: ████████████████████░░░░░░░░░░  52%                       │
│                                                                      │
│  ACTIVE COMPONENTS                                                   │
│  ┌────────────────────────────────────────────────────────────────┐ │
│  │  [●] AC-02 Wiggum Loop    Running (iteration 8)                │ │
│  │  [●] AC-04 JICM           Monitoring (healthy)                 │ │
│  │  [○] AC-05 Reflection     Idle                                 │ │
│  │  [○] AC-06 Evolution      Idle (2 pending proposals)           │ │
│  └────────────────────────────────────────────────────────────────┘ │
│                                                                      │
│  RECENT EVENTS (last 5 minutes)                                      │
│  • 14:32 - AC-02: Task "Update documentation" started               │
│  • 14:30 - AC-04: Context check passed (52%)                        │
│  • 14:28 - AC-02: Iteration 7 completed                             │
│                                                                      │
│  ALERTS                                                              │
│  • None                                                              │
│                                                                      │
│  SCORES (current session)                                            │
│  Efficiency: 91  |  Effectiveness: 84  |  Overall: 87 (B)           │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### 2. Component Detail (/status --component=AC-02)

Deep dive into specific component.

```
┌─────────────────────────────────────────────────────────────────────┐
│                    AC-02 WIGGUM LOOP STATUS                          │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  Status: RUNNING                                                     │
│  Current Task: Update documentation                                  │
│  Iteration: 8 / max 50                                               │
│  Started: 14:15:30                                                   │
│  Duration: 16m 30s                                                   │
│                                                                      │
│  TODOS                                                               │
│  [✓] Research existing patterns                                     │
│  [✓] Draft initial content                                          │
│  [▶] Write detailed sections                                        │
│  [ ] Review and refine                                               │
│  [ ] Update references                                               │
│                                                                      │
│  METRICS (this run)                                                  │
│  ┌────────────────────────────────────────────────────────────────┐ │
│  │  Iterations:      8                                             │ │
│  │  Todos completed: 2/5                                           │ │
│  │  Drift events:    0                                             │ │
│  │  Context used:    +12%                                          │ │
│  │  Estimated:       10 more iterations                            │ │
│  └────────────────────────────────────────────────────────────────┘ │
│                                                                      │
│  SCORE                                                               │
│  Current: 85 (B)  |  7-day avg: 88  |  Trend: stable               │
│                                                                      │
│  RECENT HISTORY                                                      │
│  • 14:30 - Iteration 7: Todo 2 completed                            │
│  • 14:25 - Iteration 6: Writing in progress                         │
│  • 14:20 - Iteration 5: Research complete                           │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### 3. Health Overview (/health)

Overall system health summary.

```
┌─────────────────────────────────────────────────────────────────────┐
│                    JARVIS HEALTH REPORT                              │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  Overall Health: GOOD (87)  ↑ +2.5 from last week                   │
│                                                                      │
│  COMPONENT HEALTH                                                    │
│  ┌────────────────────────────────────────────────────────────────┐ │
│  │  Component           Score  Trend   Status                      │ │
│  │  ─────────────────────────────────────────────                  │ │
│  │  AC-01 Self-Launch     92    ↑      Excellent                   │ │
│  │  AC-02 Wiggum Loop     88    →      Good                        │ │
│  │  AC-03 Milestone Rev   85    ↑      Good                        │ │
│  │  AC-04 JICM            95    →      Excellent                   │ │
│  │  AC-05 Self-Reflect    78    ↓      Review needed              │ │
│  │  AC-06 Self-Evolution  82    →      Good                        │ │
│  │  AC-07 R&D Cycles      75    ↓      Review needed ⚠            │ │
│  │  AC-08 Maintenance     90    ↑      Excellent                   │ │
│  │  AC-09 Session Compl   94    →      Excellent                   │ │
│  └────────────────────────────────────────────────────────────────┘ │
│                                                                      │
│  ALERTS (2)                                                          │
│  ⚠ AC-07 score declined 8% this week                                │
│  ⚠ AC-05 has 3 pending corrections unprocessed                      │
│                                                                      │
│  RECOMMENDATIONS                                                     │
│  1. Review R&D research agenda - may need refresh                   │
│  2. Run /self-improve --focus=reflection to process backlog         │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Reports

### 1. Session Summary Report

Generated at session end.

```markdown
# Session Summary — 2026-01-16

**Session ID**: session_2026-01-16_002
**Duration**: 2 hours 45 minutes
**Version**: 2.0.0

## Accomplishments
- Completed PR-12.8 Maintenance Workflows
- Completed PR-12.9 Session Completion
- Started PR-12.10 Self-Improvement Command

## Component Activity

| Component | Activations | Duration | Score |
|-----------|-------------|----------|-------|
| AC-01 | 1 | 8s | 92 |
| AC-02 | 3 | 2h 10m | 88 |
| AC-04 | 12 checks | - | 95 |
| AC-09 | 1 | 45s | 94 |

## Context Usage
- Peak: 68%
- Average: 52%
- Checkpoints: 0
- Clears: 0

## Scores
- Efficiency: 91
- Effectiveness: 86
- Overall: 87 (B)

## Next Session
Continue with PR-12.10 Self-Improvement Command

---
*Generated by Jarvis Dashboard*
```

### 2. Weekly Health Report

Generated weekly.

```markdown
# Weekly Health Report — Week 3, 2026

**Period**: 2026-01-13 to 2026-01-19
**Sessions**: 12
**Total Duration**: 28 hours

## Executive Summary

Overall health improved from 84 to 87 (+3.6%).
AC-07 R&D requires attention (declining trend).

## Score Trends

| Component | Start | End | Change |
|-----------|-------|-----|--------|
| AC-01 | 90 | 92 | +2.2% |
| AC-02 | 86 | 88 | +2.3% |
| AC-03 | 82 | 85 | +3.7% |
| AC-04 | 94 | 95 | +1.1% |
| AC-05 | 82 | 78 | -4.9% |
| AC-06 | 80 | 82 | +2.5% |
| AC-07 | 82 | 75 | -8.5% |
| AC-08 | 87 | 90 | +3.4% |
| AC-09 | 93 | 94 | +1.1% |

## Key Events
- PR-12 completed (10 sub-PRs)
- 5 evolution proposals implemented
- 2 rollbacks (both low-risk)

## Recommendations
1. **AC-07 R&D**: Score declined 8.5%. Review research agenda.
2. **AC-05 Reflection**: Declining trend. Check data sources.

## Alerts This Week
- 2 score warnings
- 0 critical alerts
- 0 regressions detected

---
*Generated by Jarvis Dashboard*
```

### 3. Evolution Report

Generated after /self-improve.

```markdown
# Self-Improvement Report — 2026-01-16

**Duration**: 27 minutes
**Phases**: 4/4 complete

## Phase Results

### Self-Reflection (AC-05)
- Corrections reviewed: 5
- Patterns identified: 2
- Proposals generated: 3

### Maintenance (AC-08)
- Health issues: 0
- Stale files: 8
- Organization issues: 1

### R&D Cycles (AC-07)
- Topics researched: 2
- Discoveries: 1
- Recommendations: 1 ADOPT, 0 ADAPT, 1 DEFER

### Self-Evolution (AC-06)
- Proposals triaged: 6
- Low-risk implemented: 2
- Queued for approval: 4

## Changes Made
1. Updated context-budget-management.md (low-risk, auto-approved)
2. Fixed broken link in session-state.md (low-risk, auto-approved)

## Pending Approvals

| ID | Title | Source | Risk |
|----|-------|--------|------|
| evol-001 | Add file usage tracking | AC-07 | Medium |
| evol-002 | Consolidate patterns | AC-08 | Medium |
| evol-003 | New reflection sources | AC-05 | Medium |
| evol-004 | Update JICM thresholds | AC-08 | Medium |

## Next Steps
Run `/evolve --approve` to review pending proposals.

---
*Generated by Jarvis Dashboard*
```

---

## Alert System

### Alert Levels

| Level | Threshold | Notification | Action |
|-------|-----------|--------------|--------|
| Info | - | Log only | None |
| Warning | Score < 70 | Dashboard + log | Review recommended |
| Alert | Score < 60 | User notification | Action required |
| Critical | Score < 50 | Prominent display | Immediate attention |

### Alert Format

```json
{
  "id": "alert-2026-01-16-001",
  "level": "warning",
  "timestamp": "2026-01-16T18:00:00.000Z",
  "component": "AC-07",
  "title": "R&D score declining",
  "message": "AC-07 score dropped from 82 to 75 (-8.5%) over 7 days",
  "recommendation": "Review research agenda and consider manual /research run",
  "acknowledged": false
}
```

### Alert Display

```
┌─────────────────────────────────────────────────────────────────────┐
│  ⚠ WARNING: AC-07 R&D Cycles                                        │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  Score declined 8.5% this week (82 → 75)                            │
│                                                                      │
│  Possible causes:                                                    │
│  • Research agenda empty or stale                                   │
│  • External discovery sources unreachable                           │
│  • Low-value findings                                               │
│                                                                      │
│  Recommendation:                                                     │
│  Run /research to refresh research agenda and trigger R&D cycle     │
│                                                                      │
│  [Acknowledge]  [Snooze 24h]  [Investigate]                         │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Commands

### `/status` Command

```
Usage: /status [options]

Options:
  --component=<id>   Show specific component status
  --events           Show recent events
  --alerts           Show active alerts only
  --json             Output as JSON

Examples:
  /status                    # Quick overview
  /status --component=ac02   # AC-02 detail
  /status --alerts           # Alerts only
```

### `/health` Command

```
Usage: /health [options]

Options:
  --detail           Show detailed breakdown
  --recommendations  Show improvement recommendations
  --export           Export to markdown file

Examples:
  /health                    # Quick summary
  /health --detail           # Full breakdown
  /health --recommendations  # With suggestions
```

### `/report` Command

```
Usage: /report <type> [options]

Types:
  session            Current/last session summary
  daily              Today's aggregate
  weekly             Last 7 days
  monthly            Last 30 days
  evolution          Last self-improvement run

Options:
  --date=<date>      Specific date (YYYY-MM-DD)
  --export           Save to file

Examples:
  /report session
  /report weekly
  /report evolution --export
```

---

## Report Storage

### File Locations

```
.claude/reports/
├── sessions/
│   ├── session-2026-01-16-001.md
│   └── session-2026-01-16-002.md
├── daily/
│   ├── daily-2026-01-16.md
│   └── daily-2026-01-15.md
├── weekly/
│   └── weekly-2026-W03.md
├── monthly/
│   └── monthly-2026-01.md
├── evolution/
│   └── evolution-2026-01-16.md
└── alerts/
    └── alerts.json
```

---

## Configuration

### dashboard-config.yaml

```yaml
dashboard:
  # Enable/disable
  enabled: true

  # Real-time refresh
  refresh_interval_ms: 5000

  # Display options
  display:
    show_scores: true
    show_trends: true
    show_events: true
    max_events: 10

  # Alerts
  alerts:
    enabled: true
    warning_threshold: 70
    alert_threshold: 60
    critical_threshold: 50

  # Reports
  reports:
    auto_generate_session: true
    auto_generate_weekly: true
    export_path: .claude/reports/

  # Notifications
  notifications:
    warning: log_only
    alert: user_notify
    critical: prominent_display
```

---

## Implementation Files

| File | Purpose | Status |
|------|---------|--------|
| `.claude/hooks/dashboard-aggregator.js` | Data aggregation | planned |
| `.claude/hooks/alert-manager.js` | Alert handling | planned |
| `.claude/hooks/report-generator.js` | Report creation | planned |
| `.claude/commands/status.md` | Status command | planned |
| `.claude/commands/health.md` | Health command | planned |
| `.claude/commands/report.md` | Report command | planned |
| `.claude/config/dashboard-config.yaml` | Configuration | planned |

---

## Validation Checklist

- [ ] Real-time status working
- [ ] Component detail view working
- [ ] Health overview working
- [ ] Session reports generating
- [ ] Weekly reports generating
- [ ] Alert system functional
- [ ] Commands operational
- [ ] Export to markdown working
- [ ] Integration with telemetry/scores working

---

*Dashboard and Reporting — PR-13.4 Specification*
