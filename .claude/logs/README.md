# Logs Directory

**Purpose**: Active operational logs written by hooks and workflows
**Architecture**: See `context/designs/unified-logging-architecture.md`

---

## Status

**Location**: Stays in `.claude/` (hooks actively write here)
**Context Loading**: Cold storage — consult only when debugging

---

## Log Files

### Event Streams (JSONL - append-only)

| File | Purpose | Writer |
|------|---------|--------|
| `telemetry/events-YYYY-MM-DD.jsonl` | AC component telemetry | `telemetry-emitter.js` |
| `selection-audit.jsonl` | Tool/agent/skill selections | `selection-audit.js` |
| `session-events.jsonl` | Session lifecycle events | `session-tracker.js` |
| `orchestration-detections.jsonl` | Complex task detections | `orchestration-detector.js` |
| `agent-activity.jsonl` | Agent completions | `subagent-stop.js` |
| `corrections.jsonl` | User corrections captured | `self-correction-capture.js` |
| `context-loss-reports.jsonl` | Context forgotten after compaction | `/context-loss` command |

### Structured State (JSON - overwrite)

| File | Purpose | Writer |
|------|---------|--------|
| `file-access.json` | Context file read patterns | `file-access-tracker.js` |
| `memory-access.json` | Memory MCP entity access | `memory-maintenance.js` |
| `context-estimate.json` | Current context token estimate | `context-accumulator.js` |

### Diagnostic Logs

| File | Purpose | Writer |
|------|---------|--------|
| `session-start-diagnostic.log` | Session startup logs | `session-start.sh` |
| `watcher-launcher.log` | Auto-clear watcher status | Watcher script |
| `jarvis-watcher.log` | JICM watcher activity | `jarvis-watcher.sh` |

---

## Subdirectories

| Directory | Purpose |
|-----------|---------|
| `mcp-validation/` | MCP test run outputs |

---

## Retention Policy

- JSONL logs: Rotate monthly or when > 10MB
- Diagnostic logs: Clear on successful session start
- Validation outputs: Archive to `docs/reports/validation/` after review

---

## When to Consult

Load logs when:
- Debugging hook behavior
- Auditing past sessions
- Analyzing patterns for self-improvement
- Investigating failures

**Do NOT** include in always-on context.

---

*Operational logs — PR-10 organization*
