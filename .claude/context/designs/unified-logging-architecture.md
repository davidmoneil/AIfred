# Unified Logging Architecture

Design document for Jarvis event logging, telemetry, and analytics infrastructure.

**Version**: 1.0.0
**Created**: 2026-01-23
**Status**: Implemented (M2-S2.2)

---

## Overview

Jarvis uses a distributed logging architecture where multiple hooks capture events and write to specialized log files. This document defines the unified architecture that enables:

1. **Consistent event capture** across all subsystems
2. **Data-driven analysis** for self-improvement
3. **Session history** for debugging and audit
4. **Pattern detection** for behavioral optimization

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           JARVIS UNIFIED LOGGING                             │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  EVENT SOURCES (Hooks)                                                       │
│  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐          │
│  │ telemetry-       │  │ selection-       │  │ file-access-     │          │
│  │ emitter.js       │  │ audit.js         │  │ tracker.js       │          │
│  │ (AC components)  │  │ (tool choices)   │  │ (context reads)  │          │
│  └────────┬─────────┘  └────────┬─────────┘  └────────┬─────────┘          │
│           │                      │                      │                    │
│  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐          │
│  │ session-         │  │ memory-          │  │ orchestration-   │          │
│  │ tracker.js       │  │ maintenance.js   │  │ detector.js      │          │
│  │ (lifecycle)      │  │ (MCP access)     │  │ (task patterns)  │          │
│  └────────┬─────────┘  └────────┬─────────┘  └────────┬─────────┘          │
│           │                      │                      │                    │
│           ▼                      ▼                      ▼                    │
│  ┌───────────────────────────────────────────────────────────────────────┐  │
│  │                         LOG STORAGE (.claude/logs/)                    │  │
│  ├───────────────────────────────────────────────────────────────────────┤  │
│  │                                                                        │  │
│  │  JSONL Streams (append-only)          Structured State (overwrite)    │  │
│  │  ├─ telemetry/events-YYYY-MM-DD.jsonl ├─ file-access.json             │  │
│  │  ├─ selection-audit.jsonl             ├─ memory-access.json           │  │
│  │  ├─ session-events.jsonl              ├─ context-estimate.json        │  │
│  │  ├─ orchestration-detections.jsonl    │                               │  │
│  │  ├─ agent-activity.jsonl              │                               │  │
│  │  └─ corrections.jsonl                 │                               │  │
│  │                                                                        │  │
│  └───────────────────────────────────────────────────────────────────────┘  │
│                                  │                                           │
│                                  ▼                                           │
│  ┌───────────────────────────────────────────────────────────────────────┐  │
│  │                           ANALYSIS LAYER                               │  │
│  ├───────────────────────────────────────────────────────────────────────┤  │
│  │                                                                        │  │
│  │  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐    │  │
│  │  │ AC-05 Self-      │  │ AC-08 Maintenance │  │ /context-analyze │    │  │
│  │  │ Reflection       │  │ Health Checks     │  │ (periodic)       │    │  │
│  │  │ (session end)    │  │ (scheduled)       │  │                  │    │  │
│  │  └──────────────────┘  └──────────────────┘  └──────────────────┘    │  │
│  │                                                                        │  │
│  └───────────────────────────────────────────────────────────────────────┘  │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Canonical Event Schema

All JSONL log entries SHOULD conform to this base schema for unified analysis:

```typescript
interface UnifiedEvent {
  // Required fields
  timestamp: string;      // ISO 8601 format
  event_type: string;     // Categorized event type

  // Recommended fields
  source?: string;        // Hook/component that generated event
  session_id?: string;    // Claude session identifier

  // Event-specific data
  data?: Record<string, any>;

  // Optional metadata
  metadata?: {
    jarvis_version?: string;
    hook?: boolean;
    [key: string]: any;
  };
}
```

### Event Type Categories

| Category | Prefix | Examples |
|----------|--------|----------|
| Component lifecycle | `component_` | `component_start`, `component_end`, `component_error` |
| Session lifecycle | `session_` | `session_start`, `session_end`, `session_notification` |
| Tool execution | `tool_` | `tool_selected`, `tool_completed`, `tool_blocked` |
| File operations | `file_` | `file_read`, `file_write`, `file_access` |
| Memory operations | `memory_` | `memory_read`, `memory_write`, `memory_search` |
| Orchestration | `orchestration_` | `orchestration_detected`, `orchestration_started` |
| Metric | `metric` | Gauge, counter, timing measurements |

---

## Log Sources

### 1. Telemetry Emitter (`telemetry-emitter.js`)

**Purpose**: Core telemetry for AC components (AC-01 through AC-09)

**Event**: Hook and programmatic
**Output**: `logs/telemetry/events-YYYY-MM-DD.jsonl`

**Schema**:
```json
{
  "timestamp": "2026-01-23T12:00:00.000Z",
  "component": "AC-01",
  "event_type": "component_start",
  "session_id": "session-xyz",
  "data": { "phase": "greeting" },
  "metadata": { "jarvis_version": "1.9.5" }
}
```

**Usage**:
```javascript
const telemetry = require('./telemetry-emitter');
telemetry.emit('AC-01', 'component_start', { phase: 'greeting' });
telemetry.lifecycle.start('AC-02');
telemetry.metrics.timing('AC-05', 'reflection_duration', 5000);
```

---

### 2. Selection Audit (`selection-audit.js`)

**Purpose**: Track tool/agent/skill selection patterns

**Event**: PostToolUse
**Output**: `logs/selection-audit.jsonl`

**Schema**:
```json
{
  "timestamp": "2026-01-23T12:00:00.000Z",
  "tool": "Task",
  "category": "subagent",
  "context": {
    "subagent_type": "code-review",
    "description": "Review PR changes"
  }
}
```

**Tracked Tools**: Task, Skill, EnterPlanMode, mcp__*, WebSearch, WebFetch

---

### 3. File Access Tracker (`file-access-tracker.js`)

**Purpose**: Track context file read patterns for consolidation decisions

**Event**: PostToolUse (Read tool)
**Output**: `logs/file-access.json`

**Schema**:
```json
{
  "version": "1.0",
  "created": "2026-01-23T12:00:00.000Z",
  "last_updated": "2026-01-23T12:00:00.000Z",
  "files": {
    ".claude/context/patterns/_index.md": {
      "first_read": "2026-01-20T...",
      "last_read": "2026-01-23T...",
      "read_count": 47,
      "sessions": ["session-1", "session-2"],
      "daily_history": ["2026-01-20", "2026-01-21"]
    }
  },
  "sessions": {
    "session-1": {
      "started": "2026-01-23T...",
      "file_reads": 25,
      "unique_files": ["file1.md", "file2.md"]
    }
  }
}
```

**Tracked Paths**: `.claude/context/`, `.claude/commands/`, `.claude/agents/`, `.claude/skills/`, `.claude/hooks/`, `projects/project-aion/`

---

### 4. Session Tracker (`session-tracker.js`)

**Purpose**: Track session lifecycle events

**Event**: Notification
**Output**: `logs/session-events.jsonl`

**Schema**:
```json
{
  "timestamp": "2026-01-23T12:00:00.000Z",
  "who": "system",
  "type": "session_event",
  "event_type": "session_start",
  "message": "Session initialized"
}
```

---

### 5. Memory Maintenance (`memory-maintenance.js`)

**Purpose**: Track Memory MCP entity access for pruning decisions

**Event**: PostToolUse (mcp__*__open_nodes, etc.)
**Output**: `logs/memory-access.json`

**Schema**:
```json
{
  "version": "1.0",
  "created": "2026-01-23T12:00:00.000Z",
  "lastUpdated": "2026-01-23T12:00:00.000Z",
  "entities": {
    "Jarvis_Archon_Topology": {
      "firstAccessed": "2026-01-22",
      "lastAccessed": "2026-01-23",
      "accessCount": 5,
      "accessHistory": ["2026-01-22", "2026-01-23"]
    }
  },
  "toolUsage": {
    "mcp__mcp-gateway__open_nodes": {
      "count": 15,
      "lastUsed": "2026-01-23"
    }
  }
}
```

---

### 6. Orchestration Detector (`orchestration-detector.js`)

**Purpose**: Detect complex multi-step task requests

**Event**: UserPromptSubmit
**Output**: `logs/orchestration-detections.jsonl`

**Schema**:
```json
{
  "timestamp": "2026-01-23T12:00:00.000Z",
  "prompt": "Implement user authentication...",
  "score": 7,
  "action": "suggest_orchestration",
  "signals": ["multi_file", "architecture", "testing"]
}
```

---

### 7. Agent Activity (`subagent-stop.js`)

**Purpose**: Track agent completions and performance

**Event**: SubagentStop
**Output**: `logs/agent-activity.jsonl`

**Schema**:
```json
{
  "timestamp": "2026-01-23T12:00:00.000Z",
  "agent_type": "code-review",
  "duration_ms": 45000,
  "turns": 8,
  "result": "completed"
}
```

---

## Integration Points

### 1. Self-Reflection (AC-05)

At session end, AC-05 reads:
- `session-events.jsonl` — Session lifecycle
- `selection-audit.jsonl` — Tool selection patterns
- `corrections.jsonl` — User corrections
- `agent-activity.jsonl` — Agent performance

Generates insights for self-improvement proposals.

### 2. Maintenance (AC-08)

Periodic maintenance reads:
- `file-access.json` — Identify unused context files
- `memory-access.json` — Identify stale entities
- `telemetry/` — Component health trends

### 3. Context Analysis (`/context-analyze`)

Manual or scheduled analysis:
- Aggregates all log sources
- Identifies patterns and anomalies
- Generates optimization recommendations

---

## Future Consolidation

### Phase 1: Current State (Implemented)
Multiple specialized log files, each optimized for its use case.

### Phase 2: Unified Event Stream (Future)
```
All hooks → Unified events.jsonl → Analysis tools
```

Benefits:
- Single query interface
- Consistent schema
- Easier correlation

Trade-offs:
- Larger single file
- Schema migration needed

### Phase 3: Structured Analytics (Future)
```
events.jsonl → SQLite/DuckDB → Dashboards
```

Benefits:
- SQL queries
- Aggregations
- Time-series analysis

---

## Retention Policy

| Log Type | Retention | Action |
|----------|-----------|--------|
| JSONL streams | 30 days | Rotate to archive |
| Structured JSON | Indefinite | Prune stale entries |
| Telemetry daily | 90 days | Delete old files |

Archive location: `projects/project-aion/reports/archive/logs/`

---

## Best Practices

### For Hook Authors

1. **Use canonical schema** — Include timestamp, event_type, source
2. **Silent failures** — Never block tool execution on log errors
3. **Minimal data** — Log what's needed, not everything
4. **JSONL for streams** — Append-only for concurrent writes
5. **JSON for state** — Overwrite for aggregated data

### For Analysis

1. **Use jq** — `jq -c 'select(.event_type == "component_error")' events.jsonl`
2. **Correlate by session** — Join logs on session_id
3. **Time-window** — Filter by timestamp for recent events
4. **Sample for trends** — Don't process all data every time

---

## Related Documents

- `telemetry-emitter.js` — Core telemetry module
- `AC-05-self-reflection.md` — Self-reflection component
- `AC-08-maintenance.md` — Maintenance component
- `logs/README.md` — Log directory documentation

---

*Unified Logging Architecture v1.0.0 — M2-S2.2*
