# Metrics Collection Standard

**Version**: 1.0.0
**Created**: 2026-01-16
**Status**: Active
**PR**: PR-11.3

---

## Overview

This standard defines the metrics that all autonomic components must emit, their storage format, and aggregation patterns. Consistent metrics enable performance monitoring, optimization, and self-improvement.

---

## 1. Common Metrics

All autonomic components MUST emit these core metrics for every execution.

### 1.1 Execution Metrics

| Metric | Type | Unit | Description |
|--------|------|------|-------------|
| `execution_time` | float | milliseconds | Total execution duration |
| `start_time` | string | ISO 8601 | When execution began |
| `end_time` | string | ISO 8601 | When execution ended |
| `status` | enum | — | `success`, `failure`, `partial`, `aborted` |

### 1.2 Token Metrics

| Metric | Type | Unit | Description |
|--------|------|------|-------------|
| `token_input` | integer | tokens | Input tokens consumed |
| `token_output` | integer | tokens | Output tokens generated |
| `token_total` | integer | tokens | Total tokens (input + output) |
| `token_cost_usd` | float | USD | Estimated cost (if calculable) |

### 1.3 Resource Metrics

| Metric | Type | Unit | Description |
|--------|------|------|-------------|
| `api_calls` | integer | count | Number of API calls made |
| `tool_calls` | integer | count | Number of tool invocations |
| `file_reads` | integer | count | Files read during execution |
| `file_writes` | integer | count | Files written/modified |
| `mcp_calls` | integer | count | MCP tool invocations |

### 1.4 Quality Metrics

| Metric | Type | Unit | Description |
|--------|------|------|-------------|
| `error_count` | integer | count | Errors encountered |
| `retry_count` | integer | count | Retries performed |
| `iterations` | integer | count | Loop iterations (if applicable) |
| `gate_approvals` | integer | count | Gates passed |
| `gate_rejections` | integer | count | Gates failed |

---

## 2. Component-Specific Metrics

Beyond common metrics, each component emits specialized metrics.

### 2.1 Self-Launch (AC-01)

| Metric | Type | Description |
|--------|------|-------------|
| `context_files_loaded` | integer | Number of context files read |
| `baseline_check_duration` | float | Time for baseline sync check |
| `greeting_generated` | boolean | Whether greeting was displayed |
| `auto_continue_triggered` | boolean | Whether autonomous work began |

### 2.2 Wiggum Loop (AC-02)

| Metric | Type | Description |
|--------|------|-------------|
| `pass_count` | integer | Number of verification passes |
| `issues_found` | integer | Issues discovered per pass |
| `issues_fixed` | integer | Issues resolved per pass |
| `early_termination` | boolean | Stopped before max passes |
| `suppressed` | boolean | Skipped due to "quick/rough" |

### 2.3 Milestone Review (AC-03)

| Metric | Type | Description |
|--------|------|-------------|
| `review_depth` | enum | `quick`, `standard`, `thorough` |
| `findings_count` | integer | Issues identified |
| `approval_status` | enum | `approved`, `conditional`, `rejected` |
| `agent_escalation` | boolean | Whether PM agent was invoked |

### 2.4 JICM (AC-04)

| Metric | Type | Description |
|--------|------|-------------|
| `context_before` | integer | Context tokens before operation |
| `context_after` | integer | Context tokens after operation |
| `compression_ratio` | float | Reduction percentage |
| `checkpoint_created` | boolean | Whether checkpoint was saved |
| `continuation_triggered` | boolean | Whether work resumed |

### 2.5 Self-Reflection (AC-05)

| Metric | Type | Description |
|--------|------|-------------|
| `sessions_analyzed` | integer | Session logs reviewed |
| `patterns_discovered` | integer | New patterns identified |
| `problems_logged` | integer | Problems documented |
| `solutions_documented` | integer | Solutions recorded |

### 2.6 Self-Evolution (AC-06)

| Metric | Type | Description |
|--------|------|-------------|
| `proposals_generated` | integer | Change proposals created |
| `proposals_approved` | integer | Changes approved |
| `proposals_rejected` | integer | Changes rejected |
| `files_modified` | integer | Files changed |
| `rollbacks_needed` | integer | Changes reverted |

### 2.7 R&D Cycles (AC-07)

| Metric | Type | Description |
|--------|------|-------------|
| `sources_queried` | integer | External sources checked |
| `discoveries_made` | integer | New items found |
| `relevance_score` | float | Average relevance (0-1) |
| `queued_for_eval` | integer | Items added to eval queue |

### 2.8 Maintenance (AC-08)

| Metric | Type | Description |
|--------|------|-------------|
| `scope` | enum | `jarvis`, `project`, `both` |
| `stale_files_found` | integer | Outdated files identified |
| `files_cleaned` | integer | Files updated/removed |
| `org_issues_found` | integer | Organization problems |
| `org_issues_fixed` | integer | Organization fixes applied |

### 2.9 Session Completion (AC-09)

| Metric | Type | Description |
|--------|------|-------------|
| `session_duration` | float | Total session time (ms) |
| `tasks_completed` | integer | TODOs marked complete |
| `commits_made` | integer | Git commits in session |
| `handoff_quality` | enum | `complete`, `partial`, `minimal` |

---

## 3. Storage Format

### 3.1 Per-Execution Storage (JSONL)

Each component execution appends a metrics record to its log file.

**Location**: `.claude/metrics/<component-id>.jsonl`

**Schema**:
```jsonl
{
  "id": "uuid-v4",
  "component": "AC-02",
  "timestamp": "2026-01-16T14:30:00.000Z",
  "correlation_id": "session-uuid",
  "common": {
    "execution_time": 45000,
    "start_time": "2026-01-16T14:29:15.000Z",
    "end_time": "2026-01-16T14:30:00.000Z",
    "status": "success",
    "token_input": 8500,
    "token_output": 4000,
    "token_total": 12500,
    "token_cost_usd": 0.025,
    "api_calls": 3,
    "tool_calls": 12,
    "file_reads": 5,
    "file_writes": 2,
    "mcp_calls": 1,
    "error_count": 0,
    "retry_count": 0,
    "iterations": 2,
    "gate_approvals": 1,
    "gate_rejections": 0
  },
  "specific": {
    "pass_count": 2,
    "issues_found": 3,
    "issues_fixed": 3,
    "early_termination": true,
    "suppressed": false
  }
}
```

### 3.2 Session Aggregates

At session end, aggregate metrics are computed and stored.

**Location**: `.claude/metrics/sessions/<date>-<session-id>.json`

**Schema**:
```json
{
  "session_id": "uuid-v4",
  "date": "2026-01-16",
  "duration_ms": 3600000,
  "components": {
    "AC-01": {"executions": 1, "total_tokens": 5000, "success_rate": 1.0},
    "AC-02": {"executions": 3, "total_tokens": 35000, "success_rate": 1.0},
    "AC-04": {"executions": 2, "total_tokens": 8000, "success_rate": 1.0}
  },
  "totals": {
    "total_tokens": 48000,
    "total_cost_usd": 0.096,
    "total_tool_calls": 87,
    "total_errors": 0,
    "components_activated": 3
  }
}
```

### 3.3 Memory MCP Storage

Key metrics and trends are persisted to Memory MCP for cross-session analysis.

**Entity Type**: `jarvis.metric.<category>.<identifier>`

**Categories**:
- `daily` — Daily aggregates
- `weekly` — Weekly trends
- `component` — Per-component lifetime stats
- `anomaly` — Detected anomalies

**Example Entities**:
```
jarvis.metric.daily.2026-01-16
jarvis.metric.weekly.2026-W03
jarvis.metric.component.AC-02.lifetime
jarvis.metric.anomaly.high-token-usage.2026-01-16
```

---

## 4. Aggregation Patterns

### 4.1 Time-Based Aggregation

| Period | Computed From | Retention |
|--------|---------------|-----------|
| Per-execution | Raw metrics | 30 days |
| Per-session | Execution aggregates | 90 days |
| Daily | Session aggregates | 1 year |
| Weekly | Daily aggregates | 2 years |
| Monthly | Weekly aggregates | Indefinite |

### 4.2 Aggregation Functions

| Metric Type | Function | Output |
|-------------|----------|--------|
| Counts | SUM | Total count |
| Durations | SUM, AVG, P95 | Totals and averages |
| Rates | AVG | Mean rate |
| Booleans | COUNT(true) / COUNT(*) | Percentage |
| Enums | MODE, DISTRIBUTION | Most common, breakdown |

### 4.3 Computed Metrics

Derived metrics calculated from raw data:

| Metric | Formula | Purpose |
|--------|---------|---------|
| `tokens_per_minute` | `token_total / (execution_time / 60000)` | Throughput |
| `success_rate` | `success_count / total_executions` | Reliability |
| `cost_per_task` | `token_cost_usd / tasks_completed` | Efficiency |
| `avg_passes` | `sum(pass_count) / wiggum_executions` | Verification depth |
| `context_efficiency` | `work_tokens / total_tokens` | Overhead ratio |

### 4.4 Trend Analysis

Weekly trends computed for key metrics:

```json
{
  "metric": "token_total",
  "period": "weekly",
  "data": [
    {"week": "2026-W01", "value": 450000, "change_pct": null},
    {"week": "2026-W02", "value": 380000, "change_pct": -15.6},
    {"week": "2026-W03", "value": 420000, "change_pct": +10.5}
  ],
  "trend": "stable",
  "anomalies": []
}
```

---

## 5. Anomaly Detection

### 5.1 Threshold-Based Alerts

| Metric | Warning | Critical |
|--------|---------|----------|
| `token_total` (per execution) | > 50,000 | > 100,000 |
| `execution_time` | > 300,000 ms | > 600,000 ms |
| `error_count` (per session) | > 3 | > 10 |
| `success_rate` (daily) | < 90% | < 70% |
| `retry_count` (per execution) | > 3 | > 5 |

### 5.2 Statistical Anomalies

Detect outliers using rolling averages:

- **Z-Score Method**: Flag values > 2 standard deviations from mean
- **IQR Method**: Flag values outside 1.5 * IQR from quartiles
- **Trend Deviation**: Flag > 25% change from 7-day moving average

### 5.3 Anomaly Response

| Level | Action |
|-------|--------|
| Warning | Log to anomaly file, include in session summary |
| Critical | Log, emit event, notify user at session end |

---

## 6. File Structure

```
.claude/metrics/
├── AC-01-launch.jsonl       # Per-execution logs
├── AC-02-wiggum.jsonl
├── AC-03-review.jsonl
├── AC-04-jicm.jsonl
├── AC-05-reflect.jsonl
├── AC-06-evolve.jsonl
├── AC-07-rnd.jsonl
├── AC-08-maintain.jsonl
├── AC-09-session.jsonl
├── sessions/                 # Session aggregates
│   └── 2026-01-16-<id>.json
├── aggregates/               # Time-period aggregates
│   ├── daily/
│   │   └── 2026-01-16.json
│   ├── weekly/
│   │   └── 2026-W03.json
│   └── monthly/
│       └── 2026-01.json
└── anomalies/                # Anomaly records
    └── 2026-01-16.jsonl
```

---

## 7. Implementation Checklist

### Required for Each Component

- [ ] Emit all common metrics on every execution
- [ ] Emit component-specific metrics
- [ ] Append to JSONL log file
- [ ] Include correlation_id for session tracking
- [ ] Calculate derived metrics where applicable

### Session-Level Requirements

- [ ] Compute session aggregates at `/end-session`
- [ ] Store session summary to sessions/ directory
- [ ] Persist key metrics to Memory MCP
- [ ] Check anomaly thresholds
- [ ] Include metrics summary in session handoff

### Periodic Tasks

- [ ] Daily: Compute daily aggregates
- [ ] Weekly: Compute weekly trends
- [ ] Monthly: Compute monthly summaries
- [ ] Archive: Move old JSONL files to archive

---

## 8. Query Patterns

### Recent Component Performance

```bash
# Last 10 Wiggum Loop executions
tail -10 .claude/metrics/AC-02-wiggum.jsonl | jq '.common.token_total'
```

### Session Token Usage

```bash
# Today's session totals
jq '.totals.total_tokens' .claude/metrics/sessions/2026-01-16-*.json
```

### Weekly Trend

```bash
# This week's daily totals
jq '.totals.total_tokens' .claude/metrics/aggregates/daily/2026-01-1*.json
```

---

*Metrics Collection Standard — Jarvis Phase 6 PR-11.3*
