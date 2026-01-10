# Logs Directory

**Purpose**: Active operational logs written by hooks and workflows

---

## Status

**Location**: Stays in `.claude/` (hooks actively write here)
**Context Loading**: Cold storage — consult only when debugging

---

## Log Files

| File | Purpose | Writer |
|------|---------|--------|
| `audit.jsonl` | All tool executions | `audit-logger.js` |
| `agent-activity.jsonl` | Agent completions | `subagent-stop.js` |
| `corrections.jsonl` | User corrections captured | `self-correction-capture.js` |
| `selection-audit.jsonl` | Tool selection decisions | Selection hooks |
| `orchestration-detections.jsonl` | Complex task detections | `orchestration-detector.js` |
| `context-estimate.json` | Current context token estimate | `context-accumulator.js` |
| `session-start-diagnostic.log` | Session startup logs | `session-start.js` |
| `watcher-launcher.log` | Auto-clear watcher status | Watcher script |

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
