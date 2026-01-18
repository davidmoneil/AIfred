# Lessons from Corrections

**Created**: 2026-01-09
**Purpose**: Document lessons learned from user corrections to improve future behavior
**Integration**: self-correction-capture.js hook → Memory MCP → this file

---

## How This File Works

1. **Hook captures**: `self-correction-capture.js` detects user corrections
2. **Memory stores**: Correction entities created in Memory MCP
3. **Periodic sync**: Significant lessons documented here
4. **Session load**: This file is available for reference during sessions

---

## Correction Categories

### Architecture Decisions

*Lessons about system design and patterns*

| Date | Correction | Lesson |
|------|------------|--------|
| 2026-01-09 | Memory systems are NOT redundant | Memory MCP, learnings.json, and corrections.md serve different purposes - don't assume overlap |

### Workflow Preferences

*Lessons about how the user prefers to work*

| Date | Correction | Lesson |
|------|------------|--------|
| 2026-01-09 | AIfred sync is mandatory early work | Always run /sync-aifred-baseline at session start unless explicitly overridden |
| 2026-01-09 | DEFER not REJECT | Use "DEFER" instead of "REJECT" for low-priority items - they may be implemented later |

### Technical Constraints

*Lessons about system limitations*

| Date | Correction | Lesson |
|------|------------|--------|
| 2026-01-09 | PreCompact cannot prevent autocompact | PreCompact is notification-only; implement proactive context management instead |
| 2026-01-09 | AIfred baseline is READ-ONLY | Never edit, commit, branch, or configure AIfred repo - only git fetch/pull |
| 2026-01-09 | JS hooks require stdin/stdout | Claude Code hooks use JSON stdin/stdout, not `module.exports = {handler}`. Add `if (require.main === module)` wrapper to read stdin and output JSON. |
| 2026-01-18 | wttr.in JSON requires curl headers | External APIs may require specific User-Agent headers; test with curl first, then mirror headers in code |

### Communication Style

*Lessons about how to communicate*

| Date | Correction | Lesson |
|------|------------|--------|
| — | — | — |

---

## Integration Pattern

```
User correction detected
        │
        ▼
self-correction-capture.js hook
        │
        ├─► Memory MCP entity created
        │   (immediate storage)
        │
        └─► Periodic: Document here
            (human-readable reference)
```

---

## Related Documentation

- @.claude/hooks/self-correction-capture.js - Correction detection hook
- @.claude/context/patterns/memory-storage-pattern.md - Memory MCP patterns

---

*Lessons log — Updated by sync or manual review*
