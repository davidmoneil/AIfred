# Component Interaction Protocol

**Version**: 1.0.0
**Created**: 2026-01-16
**Status**: Active
**PR**: PR-11.2

---

## Overview

This document defines how autonomic components communicate with each other. All nine autonomic systems must follow these standards for inter-component communication.

### Communication Mechanisms

| Mechanism | Use Case | Latency | Persistence |
|-----------|----------|---------|-------------|
| **Event Files** | State transitions, triggers | Immediate | Session |
| **State Files** | Shared data, checkpoints | Immediate | Persistent |
| **Memory MCP** | Decisions, patterns, cross-session | Async | Permanent |
| **Direct Invocation** | Synchronous calls | Immediate | None |

---

## 1. Event Naming Conventions

### Event Identifier Format

```
ac.<component>.<action>.<qualifier>
```

**Components**:
- `ac.launch` — System 1: Self-Launch Protocol
- `ac.wiggum` — System 2: Wiggum Loop
- `ac.review` — System 3: Milestone Review
- `ac.jicm` — System 4: Context Management
- `ac.reflect` — System 5: Self-Reflection
- `ac.evolve` — System 6: Self-Evolution
- `ac.rnd` — System 7: R&D Cycles
- `ac.maintain` — System 8: Maintenance
- `ac.session` — System 9: Session Completion

**Actions** (Standard Set):
- `start` — Component activation began
- `complete` — Component finished successfully
- `fail` — Component encountered error
- `pause` — Component suspended (resumable)
- `resume` — Component resuming from pause
- `yield` — Component yielding to higher priority
- `request` — Component requesting action from another
- `approve` — Gate approval granted
- `reject` — Gate approval denied
- `queue` — Item added to processing queue

**Qualifiers** (Optional):
- `.<iteration>` — Loop iteration number (e.g., `.pass1`, `.pass2`)
- `.<target>` — Target of action (e.g., `.jarvis`, `.project`)
- `.<level>` — Risk or priority level (e.g., `.low`, `.high`)

### Event Examples

```
ac.launch.start                    # Self-Launch began
ac.launch.complete                 # Self-Launch finished
ac.wiggum.start.pass1              # Wiggum Loop pass 1 started
ac.wiggum.complete.pass3           # Wiggum Loop completed on pass 3
ac.wiggum.yield.jicm               # Wiggum yielding to JICM
ac.jicm.start                      # Context management triggered
ac.jicm.complete.checkpoint        # JICM completed with checkpoint
ac.review.request.approval         # Milestone review requesting approval
ac.review.approve                  # Review approved
ac.evolve.queue.low                # Low-risk item queued for evolution
ac.evolve.approve.high             # High-risk evolution approved
ac.session.start                   # Session completion initiated
ac.session.complete                # Session ended cleanly
```

---

## 2. Event File Format

### Location

```
.claude/events/
├── current.jsonl          # Active session events (append-only)
├── archive/               # Previous session events
│   └── YYYY-MM-DD-HHMMSS.jsonl
└── .schema.json           # Event schema definition
```

### Event Schema

```jsonl
{
  "id": "uuid-v4",
  "timestamp": "2026-01-16T14:30:00.000Z",
  "event": "ac.wiggum.complete.pass2",
  "source": "AC-02",
  "target": "AC-03",
  "data": {
    "duration_ms": 45000,
    "token_cost": 12500,
    "result": "success",
    "details": {}
  },
  "correlation_id": "session-uuid"
}
```

### Field Definitions

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | string | Yes | Unique event identifier (UUID v4) |
| `timestamp` | string | Yes | ISO 8601 timestamp with milliseconds |
| `event` | string | Yes | Event identifier (see naming conventions) |
| `source` | string | Yes | Component ID that emitted event (AC-01 to AC-09) |
| `target` | string | No | Intended recipient component, if directed |
| `data` | object | No | Event-specific payload |
| `correlation_id` | string | Yes | Session or workflow correlation ID |

### Standard Data Fields

```jsonl
{
  "data": {
    "duration_ms": 45000,      // Execution time
    "token_cost": 12500,       // Tokens consumed
    "result": "success",       // success | failure | partial
    "error": null,             // Error object if failed
    "details": {},             // Component-specific data
    "metrics": {}              // Performance metrics
  }
}
```

---

## 3. State File Formats

### State File Location

```
.claude/state/
├── components/
│   ├── AC-01-launch.json      # Self-Launch state
│   ├── AC-02-wiggum.json      # Wiggum Loop state
│   ├── AC-03-review.json      # Milestone Review state
│   ├── AC-04-jicm.json        # JICM state
│   ├── AC-05-reflect.json     # Self-Reflection state
│   ├── AC-06-evolve.json      # Self-Evolution state
│   ├── AC-07-rnd.json         # R&D Cycles state
│   ├── AC-08-maintain.json    # Maintenance state
│   └── AC-09-session.json     # Session Completion state
├── queues/
│   ├── approval-queue.json    # Items awaiting approval
│   ├── evolution-queue.json   # Proposed changes queue
│   └── maintenance-queue.json # Maintenance tasks queue
└── shared/
    ├── session-context.json   # Current session context
    ├── active-work.json       # Current work item
    └── downtime-tracker.json  # Idle time tracking
```

### Component State Schema

```json
{
  "$schema": "component-state-v1",
  "component_id": "AC-02",
  "component_name": "Wiggum Loop",
  "version": "1.0.0",
  "status": "active",
  "last_updated": "2026-01-16T14:30:00.000Z",
  "current": {
    "iteration": 2,
    "phase": "verification",
    "started_at": "2026-01-16T14:25:00.000Z"
  },
  "history": {
    "last_run": "2026-01-16T14:00:00.000Z",
    "total_runs": 47,
    "success_rate": 0.94
  },
  "config": {
    "max_iterations": 5,
    "timeout_ms": 300000
  },
  "checksum": "sha256:abc123..."
}
```

### Status Values

| Status | Description |
|--------|-------------|
| `idle` | Component not active, ready to trigger |
| `active` | Component currently executing |
| `paused` | Component suspended, can resume |
| `blocked` | Component waiting on dependency |
| `complete` | Component finished successfully |
| `failed` | Component encountered unrecoverable error |
| `disabled` | Component manually disabled |

### Queue Schema

```json
{
  "$schema": "queue-v1",
  "queue_name": "approval-queue",
  "created": "2026-01-16T10:00:00.000Z",
  "last_modified": "2026-01-16T14:30:00.000Z",
  "items": [
    {
      "id": "uuid-v4",
      "added": "2026-01-16T14:30:00.000Z",
      "source": "AC-06",
      "risk_level": "medium",
      "description": "Update error handling pattern in hooks",
      "payload": {},
      "status": "pending",
      "expires": "2026-01-17T14:30:00.000Z"
    }
  ]
}
```

---

## 4. Memory MCP Integration

### Entity Types

| Entity Type | Purpose | Created By |
|-------------|---------|------------|
| `decision` | Architectural/design decisions | All components |
| `pattern` | Discovered patterns/best practices | AC-05 Reflection |
| `problem` | Problems encountered and solutions | AC-05 Reflection |
| `evolution` | Applied self-modifications | AC-06 Evolution |
| `discovery` | External research findings | AC-07 R&D |
| `metric` | Aggregated performance metrics | AC-04 JICM |

### Entity Naming Convention

```
jarvis.<type>.<category>.<identifier>
```

**Examples**:
```
jarvis.decision.architecture.event-format-v1
jarvis.pattern.error-handling.graceful-degradation
jarvis.problem.mcp.connection-timeout
jarvis.evolution.hooks.session-start-v2
jarvis.discovery.tools.new-mcp-server
jarvis.metric.session.2026-01-16
```

### Relation Types

| Relation | From | To | Description |
|----------|------|-----|-------------|
| `triggers` | Component | Component | A activates B |
| `depends_on` | Component | Component | A requires B |
| `produces` | Component | Entity | A creates entity |
| `consumes` | Component | Entity | A uses entity |
| `supersedes` | Entity | Entity | A replaces B |
| `relates_to` | Entity | Entity | A is related to B |

---

## 5. Error Propagation Patterns

### Error Classification

| Level | Description | Propagation | Example |
|-------|-------------|-------------|---------|
| `recoverable` | Can retry or work around | Log, retry | Network timeout |
| `degraded` | Can continue with reduced capability | Log, notify | MCP unavailable |
| `blocking` | Cannot proceed until resolved | Log, escalate | Missing dependency |
| `fatal` | Component cannot function | Log, abort, notify | Corrupt state file |

### Error Event Format

```jsonl
{
  "event": "ac.wiggum.fail",
  "data": {
    "error": {
      "code": "WIGGUM_TIMEOUT",
      "level": "recoverable",
      "message": "Verification pass exceeded timeout",
      "details": {
        "pass": 2,
        "timeout_ms": 300000,
        "elapsed_ms": 305000
      },
      "recovery": {
        "action": "retry",
        "delay_ms": 5000,
        "max_attempts": 3,
        "attempt": 1
      },
      "stack": "..."
    }
  }
}
```

### Error Propagation Rules

1. **Recoverable Errors**: Handle locally, retry up to 3 times
2. **Degraded Errors**: Log, notify consumers, continue with fallback
3. **Blocking Errors**: Escalate to dependent components, pause execution
4. **Fatal Errors**: Emit `fail` event, abort component, notify all consumers

### Error Handling Flow

```
┌─────────────────┐
│  Error Occurs   │
└────────┬────────┘
         │
         ▼
┌─────────────────┐     ┌─────────────────┐
│  Recoverable?   │──▶  │  Retry (max 3)  │
└────────┬────────┘     └────────┬────────┘
         │ No                    │ Failed
         ▼                       ▼
┌─────────────────┐     ┌─────────────────┐
│   Degradable?   │──▶  │  Use Fallback   │
└────────┬────────┘     └────────┬────────┘
         │ No                    │ Failed
         ▼                       ▼
┌─────────────────┐     ┌─────────────────┐
│   Blocking?     │──▶  │  Escalate/Pause │
└────────┬────────┘     └────────┬────────┘
         │ No                    │ Unresolved
         ▼                       ▼
┌─────────────────┐     ┌─────────────────┐
│  Fatal: Abort   │     │  User Notify    │
└─────────────────┘     └─────────────────┘
```

### Consumer Notification

When a component fails, all registered consumers receive notification:

```jsonl
{
  "event": "ac.wiggum.fail.notify",
  "source": "AC-02",
  "target": "AC-03",
  "data": {
    "upstream_error": "WIGGUM_TIMEOUT",
    "impact": "review_delayed",
    "recommendation": "wait_for_retry"
  }
}
```

---

## 6. Direct Invocation Protocol

### Synchronous Calls

Components may directly invoke each other for synchronous operations:

```javascript
// Pseudocode for direct invocation
const result = await invoke("AC-04", "checkpoint", {
  reason: "context_threshold",
  preserve: ["current_work", "decisions"]
});
```

### Invocation Request Schema

```json
{
  "invoker": "AC-02",
  "target": "AC-04",
  "action": "checkpoint",
  "params": {},
  "timeout_ms": 30000,
  "correlation_id": "session-uuid"
}
```

### Invocation Response Schema

```json
{
  "invoker": "AC-02",
  "target": "AC-04",
  "action": "checkpoint",
  "status": "success",
  "result": {},
  "duration_ms": 2500,
  "correlation_id": "session-uuid"
}
```

---

## 7. Cross-Tier Communication

### Tier 1 → Tier 2 (Downtime Trigger)

When Tier 1 detects idle time, it triggers Tier 2:

```jsonl
{"event": "ac.downtime.detected", "data": {"idle_ms": 1800000}}
{"event": "ac.reflect.start", "source": "AC-05", "data": {"trigger": "downtime"}}
{"event": "ac.rnd.start", "source": "AC-07", "data": {"trigger": "downtime"}}
```

### Tier 2 → Tier 1 (Evolution Impact)

When Tier 2 makes changes affecting Tier 1:

```jsonl
{"event": "ac.evolve.complete", "data": {"changes": ["session-start.sh"]}}
{"event": "ac.launch.invalidate", "target": "AC-01", "data": {"reason": "dependency_changed"}}
```

### Priority Resolution

When multiple components compete:

| Priority | Component | Reason |
|----------|-----------|--------|
| 1 (highest) | JICM | Context preservation critical |
| 2 | Session Completion | User-requested, takes precedence |
| 3 | Wiggum Loop | Active work in progress |
| 4 | Milestone Review | Quality gate |
| 5 | Self-Launch | Startup sequence |
| 6 | Maintenance | Background task |
| 7 | Reflection | Background analysis |
| 8 | R&D | Background research |
| 9 (lowest) | Evolution | Requires approval anyway |

---

## 8. Implementation Checklist

### Required Files

- [ ] `.claude/events/current.jsonl` — Event log
- [ ] `.claude/events/.schema.json` — Event schema
- [ ] `.claude/state/components/` — Component state files
- [ ] `.claude/state/queues/` — Queue files
- [ ] `.claude/state/shared/` — Shared state files

### Component Requirements

Each component must:

- [ ] Emit `start` event when activating
- [ ] Emit `complete` or `fail` event when finishing
- [ ] Update state file on status changes
- [ ] Handle errors according to propagation rules
- [ ] Respect priority when yielding
- [ ] Support pause/resume for interruptible operations

### Validation

- [ ] Event names follow naming convention
- [ ] State files have valid checksums
- [ ] Queue items have expiration times
- [ ] Memory MCP entities follow naming convention
- [ ] Error events include recovery information

---

*Component Interaction Protocol — Jarvis Phase 6 PR-11.2*
