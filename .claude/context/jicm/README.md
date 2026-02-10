# JICM Session Memory — File-System-as-Memory

**Purpose**: Structured file-based memory hierarchy for context management.
**Version**: B.4 Phase 2
**Pattern**: File-system-as-memory with session scoping

## Directory Structure

```
jicm/
├── README.md              ← This file
├── sessions/              ← Session-scoped (cleared at session end)
│   └── {YYYYMMDD-HHMMSS}/
│       ├── working-memory.yaml    # Current task state
│       ├── decisions.yaml         # Session decisions log
│       └── observations.yaml      # Tool output references
├── cross-session/         ← Persistent (survives sessions)
│   ├── patterns-observed.yaml     # Recurring patterns
│   ├── file-knowledge.yaml        # File purpose/ownership cache
│   └── error-solutions.yaml       # Known fixes for common errors
└── archive/               ← Compressed context archives
    └── compressed-context-{ts}.md # Kept for 20 cycles
```

## Scoping Rules

| Scope | Location | Lifecycle | Contents |
|-------|----------|-----------|----------|
| Session | `sessions/{id}/` | Created at session start, archived at session end | Working state, decisions, observations |
| Cross-session | `cross-session/` | Persistent indefinitely | Patterns, file knowledge, error solutions |
| Archive | `archive/` | Last 20 cycles retained | Compressed context checkpoints |

## Session ID Format

`YYYYMMDD-HHMMSS` (e.g., `20260210-143000`)

## Retrieval Pattern

1. Check `sessions/{current}/` for session-scoped data
2. Fall back to `cross-session/` for long-term knowledge
3. Use `grep` on YAML files for structural queries (no semantic search needed)
4. Archive contents available for historical analysis

## Integration Points

- **AC-01 (Session Start)**: Creates session directory in `sessions/`
- **AC-09 (Session End)**: Archives session data, prunes ephemeral files
- **AC-04 (JICM)**: Compression agent reads session files as Priority 2 source
- **Watcher**: Archives compressed contexts to `archive/`
