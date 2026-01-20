# Telemetry System Specification

**ID**: PR-13.1
**Version**: 1.0.0
**Status**: implementing
**Created**: 2026-01-16
**Last Modified**: 2026-01-16

---

## Purpose

Collect, store, and query events and metrics from all autonomic components (AC-01 through AC-09) and the `/self-improve` orchestrator. The telemetry system provides the foundation for benchmarking, scoring, regression detection, and dashboard reporting.

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                      TELEMETRY SYSTEM ARCHITECTURE                   │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  EVENT SOURCES                                                       │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐       │
│  │  AC-01  │ │  AC-02  │ │  AC-03  │ │  AC-04  │ │  AC-05  │       │
│  │ Launch  │ │ Wiggum  │ │ Review  │ │  JICM   │ │ Reflect │       │
│  └────┬────┘ └────┬────┘ └────┬────┘ └────┬────┘ └────┬────┘       │
│       │          │          │          │          │                 │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐                   │
│  │  AC-06  │ │  AC-07  │ │  AC-08  │ │  AC-09  │                   │
│  │ Evolve  │ │   R&D   │ │ Maint   │ │ Session │                   │
│  └────┬────┘ └────┬────┘ └────┬────┘ └────┬────┘                   │
│       │          │          │          │                            │
│       └──────────┴──────────┴──────────┴──────────┐                │
│                                                    │                │
│                                                    ▼                │
│                               ┌─────────────────────────┐          │
│                               │    EVENT COLLECTOR      │          │
│                               │                         │          │
│                               │  • Validates events     │          │
│                               │  • Enriches metadata    │          │
│                               │  • Routes to storage    │          │
│                               └───────────┬─────────────┘          │
│                                           │                         │
│                              ┌────────────┼────────────┐           │
│                              │            │            │           │
│                              ▼            ▼            ▼           │
│                        ┌──────────┐ ┌──────────┐ ┌──────────┐     │
│                        │  JSONL   │ │  Memory  │ │  Metrics │     │
│                        │  Files   │ │   MCP    │ │  Aggs    │     │
│                        └────┬─────┘ └────┬─────┘ └────┬─────┘     │
│                             │            │            │            │
│                             └────────────┼────────────┘            │
│                                          │                         │
│                                          ▼                         │
│                               ┌─────────────────────────┐          │
│                               │     QUERY INTERFACE     │          │
│                               │                         │          │
│                               │  • Time range queries   │          │
│                               │  • Component filters    │          │
│                               │  • Aggregations         │          │
│                               │  • Trend analysis       │          │
│                               └─────────────────────────┘          │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Event Schema

### Base Event Format

All events follow this schema:

```json
{
  "timestamp": "2026-01-16T18:00:00.000Z",
  "component": "AC-01",
  "event_type": "component_start",
  "session_id": "session_2026-01-16_001",
  "data": {},
  "metadata": {
    "context_usage_percent": 45,
    "duration_ms": 1500
  }
}
```

### Required Fields

| Field | Type | Description |
|-------|------|-------------|
| `timestamp` | ISO 8601 | Event time (UTC) |
| `component` | string | Component ID (AC-01 through AC-09, orchestrator) |
| `event_type` | string | Event type (see Event Types) |
| `session_id` | string | Claude session ID from `${CLAUDE_SESSION_ID}` environment variable |

> **Note**: The `session_id` field uses Claude Code's built-in `${CLAUDE_SESSION_ID}` substitution,
> which provides a unique identifier for each session. This enables correlation across all events
> within a single session and supports session-aware skills.

### Optional Fields

| Field | Type | Description |
|-------|------|-------------|
| `data` | object | Event-specific payload |
| `metadata` | object | Context information |
| `correlation_id` | string | Links related events |
| `parent_id` | string | Parent event (for nested) |

---

## Event Types

### Component Lifecycle Events

| Event Type | Description | Components |
|------------|-------------|------------|
| `component_start` | Component activated | All |
| `component_end` | Component completed | All |
| `component_error` | Component failed | All |
| `component_skip` | Component skipped | All |

### Work Events

| Event Type | Description | Components |
|------------|-------------|------------|
| `task_start` | Task began | AC-02, AC-03 |
| `task_complete` | Task finished | AC-02, AC-03 |
| `iteration_start` | Loop iteration began | AC-02 |
| `iteration_end` | Loop iteration ended | AC-02 |
| `drift_detected` | Scope drift found | AC-02 |
| `drift_corrected` | Drift realigned | AC-02 |

### Context Events

| Event Type | Description | Components |
|------------|-------------|------------|
| `context_check` | Context level measured | AC-04 |
| `context_warning` | Threshold exceeded | AC-04 |
| `context_checkpoint` | Checkpoint created | AC-04 |
| `context_clear` | Context cleared | AC-04 |
| `context_resume` | Work resumed | AC-04 |

### Self-Improvement Events

| Event Type | Description | Components |
|------------|-------------|------------|
| `reflection_start` | Reflection began | AC-05 |
| `pattern_identified` | Pattern found | AC-05 |
| `correction_logged` | Correction recorded | AC-05 |
| `proposal_created` | Evolution proposal made | AC-05, AC-07, AC-08 |
| `evolution_start` | Evolution began | AC-06 |
| `evolution_implement` | Change implemented | AC-06 |
| `evolution_validate` | Validation ran | AC-06 |
| `evolution_rollback` | Change reverted | AC-06 |
| `research_start` | R&D began | AC-07 |
| `discovery_made` | New finding | AC-07 |
| `maintenance_start` | Maintenance began | AC-08 |
| `maintenance_action` | Action taken | AC-08 |
| `health_check` | Health status | AC-08 |

### Session Events

| Event Type | Description | Components |
|------------|-------------|------------|
| `session_start` | Session began | AC-01 |
| `session_end` | Session ended | AC-09 |
| `pre_completion_offer` | Tier 2 offered | AC-09 |
| `git_commit` | Commit created | AC-09 |
| `git_push` | Push completed | AC-09 |

---

## Storage

### Primary Storage: JSONL Files

**Location**: `.claude/logs/telemetry/`

**Structure**:
```
.claude/logs/telemetry/
├── events-2026-01-16.jsonl     # Daily event log
├── events-2026-01-15.jsonl
├── events-2026-01-14.jsonl
└── archive/                     # Compressed old logs
    ├── events-2026-01-01.jsonl.gz
    └── ...
```

**Format**: One JSON event per line (JSONL)

```jsonl
{"timestamp":"2026-01-16T08:00:00.000Z","component":"AC-01","event_type":"component_start","session_id":"session_2026-01-16_001","data":{"phase":"greeting"}}
{"timestamp":"2026-01-16T08:00:05.000Z","component":"AC-01","event_type":"component_end","session_id":"session_2026-01-16_001","data":{"duration_ms":5000}}
```

### Secondary Storage: Memory MCP

For cross-session recall:

```yaml
# Memory MCP entities
entity: Telemetry_Session_2026-01-16
type: telemetry_session
observations:
  - "AC-01 completed in 5s"
  - "AC-02 ran 15 iterations"
  - "AC-06 implemented 2 changes"
  - "Total context usage: 65%"
```

### Metrics Aggregates

**Location**: `.claude/metrics/aggregates/`

**Structure**:
```
.claude/metrics/aggregates/
├── daily/
│   ├── 2026-01-16.json
│   └── 2026-01-15.json
├── weekly/
│   └── 2026-W03.json
└── monthly/
    └── 2026-01.json
```

**Daily Aggregate Format**:
```json
{
  "date": "2026-01-16",
  "sessions": 3,
  "components": {
    "AC-01": {"starts": 3, "avg_duration_ms": 4500, "errors": 0},
    "AC-02": {"iterations": 45, "drift_corrections": 2},
    "AC-04": {"checkpoints": 5, "clears": 2},
    "AC-06": {"proposals": 8, "implementations": 3, "rollbacks": 0}
  },
  "totals": {
    "events": 156,
    "errors": 2,
    "avg_context_usage": 58
  }
}
```

---

## Retention Policy

| Data Type | Retention | Archive | Delete |
|-----------|-----------|---------|--------|
| Raw events | 30 days | Compress after 7 days | After 30 days |
| Daily aggregates | 1 year | None | After 1 year |
| Weekly aggregates | 2 years | None | After 2 years |
| Monthly aggregates | Indefinite | None | Never |
| Memory MCP | Indefinite | None | Manual only |

### Rotation Schedule

```yaml
# Rotation runs during AC-08 Maintenance
rotation:
  daily:
    compress_after_days: 7
    delete_after_days: 30

  aggregation:
    daily: end of day
    weekly: Sunday midnight
    monthly: first of month
```

---

## Collection Implementation

### Event Emitter Interface

Components emit events using a standard interface:

```javascript
// telemetry-emitter.js

// Get session ID from Claude Code environment
function getSessionId() {
  return process.env.CLAUDE_SESSION_ID || `local-${Date.now()}`;
}

function emit(component, eventType, data = {}, metadata = {}) {
  const event = {
    timestamp: new Date().toISOString(),
    component,
    event_type: eventType,
    session_id: getSessionId(),  // Uses ${CLAUDE_SESSION_ID}
    data,
    metadata: {
      ...metadata,
      context_usage_percent: getCurrentContextUsage()
    }
  };

  // Write to JSONL
  appendToLog(event);

  // Optional: Write to Memory MCP for important events
  if (isSignificantEvent(eventType)) {
    writeToMemory(event);
  }
}
```

### Component Integration

Each AC component integrates telemetry:

```javascript
// In AC-02 Wiggum Loop
telemetry.emit('AC-02', 'iteration_start', {
  iteration: currentIteration,
  todo_count: todos.length
});

// ... do work ...

telemetry.emit('AC-02', 'iteration_end', {
  iteration: currentIteration,
  todos_completed: completedCount,
  duration_ms: elapsed
});
```

---

## Query Interface

### Query Functions

```javascript
// telemetry-query.js

// Get events by time range
function getEvents(startDate, endDate, filters = {}) {
  // Returns array of events
}

// Get events by component
function getComponentEvents(component, days = 7) {
  // Returns events for specific component
}

// Get aggregates
function getDailyAggregate(date) {
  // Returns daily aggregate object
}

// Trend analysis
function getTrend(metric, days = 30) {
  // Returns time series data
}

// Component health
function getComponentHealth(component, days = 7) {
  // Returns health summary
}
```

### Query Examples

```javascript
// Get all AC-02 events from today
const wiggumEvents = await getComponentEvents('AC-02', 1);

// Get evolution success rate trend
const trend = await getTrend('AC-06.implementation_success_rate', 30);

// Get aggregate for specific day
const agg = await getDailyAggregate('2026-01-16');
```

---

## Consumers

| Consumer | Data Consumed | Purpose |
|----------|---------------|---------|
| PR-13.2 Benchmarks | Events, metrics | Measure performance |
| PR-13.3 Scoring | Aggregates | Calculate scores |
| PR-13.4 Dashboard | Real-time events | Display status |
| PR-13.5 Regression | Trends | Detect degradation |
| AC-05 Reflection | Events | Identify patterns |
| AC-06 Evolution | Metrics | Validate changes |

---

## Configuration

### telemetry-config.yaml

```yaml
telemetry:
  # Enable/disable telemetry
  enabled: true

  # Storage settings
  storage:
    primary: jsonl
    secondary: memory_mcp
    path: .claude/logs/telemetry/

  # Retention
  retention:
    raw_events_days: 30
    compress_after_days: 7

  # Collection
  collection:
    batch_size: 100
    flush_interval_ms: 5000

  # Memory MCP settings
  memory_mcp:
    enabled: true
    significant_events:
      - component_error
      - evolution_implement
      - evolution_rollback
      - session_end

  # Performance
  performance:
    async_writes: true
    max_queue_size: 1000
```

---

## Implementation Files

| File | Purpose | Status |
|------|---------|--------|
| `.claude/hooks/telemetry-emitter.js` | Event emission | planned |
| `.claude/hooks/telemetry-collector.js` | Collection logic | planned |
| `.claude/hooks/telemetry-query.js` | Query interface | planned |
| `.claude/hooks/telemetry-aggregator.js` | Aggregation logic | planned |
| `.claude/config/telemetry-config.yaml` | Configuration | planned |
| `.claude/logs/telemetry/` | Event storage | planned |
| `.claude/metrics/aggregates/` | Aggregate storage | planned |

---

## Error Handling

### Collection Errors

```javascript
// If write fails, queue for retry
try {
  appendToLog(event);
} catch (error) {
  queueForRetry(event);
  logWarning(`Telemetry write failed: ${error.message}`);
}
```

### Graceful Degradation

| Failure | Response |
|---------|----------|
| JSONL write fails | Queue in memory, retry |
| Memory MCP unavailable | Skip secondary storage |
| Disk full | Alert, stop logging non-critical |
| Query timeout | Return partial results |

---

## Validation Checklist

- [ ] Event schema validated
- [ ] All AC components emit events
- [ ] JSONL storage working
- [ ] Memory MCP integration working
- [ ] Query interface implemented
- [ ] Aggregation running
- [ ] Retention policies applied
- [ ] Error handling tested
- [ ] Performance acceptable (<10ms per event)

---

*Telemetry System — PR-13.1 Specification*
