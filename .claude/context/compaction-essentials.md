# Compaction Essentials

**Purpose**: Core context preserved after conversation compaction. Keep this concise.

**Last Updated**: 2026-01-16
**Sync Trigger**: Update when design patterns, paths, or core workflows change.

---

## Project Structure

| What | Where |
|------|-------|
| Code projects | `projects_root/<project>/` (from paths-registry.yaml) |
| AIfred | Hub/orchestrator (not code container) |
| Context/docs | `.claude/context/` |
| Registration | `paths-registry.yaml` |

## Automation Expectations

- **Execute commands directly** - don't ask user to run them
- **MCP tools first** - prefer MCP over bash for Docker, Git, filesystem operations
- **Solve once, document** - update context files when learning new patterns
- **Ask questions** when unsure about paths, preferences, or approach

## Key Patterns

- **PARC**: Prompt -> Assess -> Relate -> Create (design review before implementation)
- **Severity System**: `[X] CRITICAL`, `[!] HIGH`, `[~] MEDIUM`, `[-] LOW`
- **Agent Selection**: Check `.claude/context/patterns/agent-selection-pattern.md`
- **Memory Storage**: Bi-temporal timestamps for MCP Memory entities

## MCP Tools (When Available)

- **Docker MCP**: Container management (if configured)
- **Git MCP**: Local repository operations
- **Filesystem MCP**: Cross-directory file ops
- **MCP Gateway**: Browser automation, Memory, Fetch
- **GitHub MCP**: Remote repo operations

## Session Continuity

- **Session state**: `.claude/context/session-state.md`
- **Priorities**: `.claude/context/projects/current-priorities.md`
- **Exit procedure**: Always update session-state.md before ending

## Quick References

- Paths: `paths-registry.yaml`
- Patterns: `.claude/context/patterns/`
- Standards: `.claude/context/standards/`

---

*This file is auto-injected after context compaction via pre-compact.js hook.*
