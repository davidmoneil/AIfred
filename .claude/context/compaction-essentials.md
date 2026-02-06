# Compaction Essentials

**Purpose**: Core context preserved after conversation compaction. Keep this concise.

**Last Updated**: 2026-02-05
**Sync Trigger**: Update when design patterns, paths, or core workflows change.

---

## Project Structure

| What | Where |
|------|-------|
| Code projects | `projects_root/<project>/` (from paths-registry.yaml) |
| AIfred | Hub/orchestrator (not code container) |
| Context/docs | `.claude/context/` |
| Registration | `paths-registry.yaml` |
| Profiles | `profiles/*.yaml` → `.claude/config/active-profile.yaml` |

## Automation Expectations

- **Execute commands directly** - don't ask user to run them
- **MCP tools first** - prefer MCP over bash for Docker, Git, filesystem operations
- **Solve once, document** - update context files when learning new patterns
- **Ask questions** when unsure about paths, preferences, or approach
- **Scripts over LLM** - push deterministic logic into CLI scripts

## Key Patterns

- **PARC**: Prompt -> Assess -> Relate -> Create (design review before implementation)
- **DDLA**: Discover -> Document -> Link -> Automate
- **COSA**: Capture -> Organize -> Structure -> Automate
- **Severity System**: `[X] CRITICAL`, `[!] HIGH`, `[~] MEDIUM`, `[-] LOW`
- **Agent Selection**: Check `.claude/context/patterns/agent-selection-pattern.md`
- **Memory Storage**: Bi-temporal timestamps for MCP Memory entities
- **Capability Layering**: Scripts for deterministic work, AI for judgment calls

## Environment Profiles (v2.2)

Composable YAML layers that shape hooks, permissions, patterns, and agents:

- **general** (always active): Audit logging, security, session management
- **homelab**: Docker validation, port conflicts, health monitoring
- **development**: Project tracking, orchestration, parallel-dev, branch protection
- **production**: Strict security, deployment gates, destructive command blocking

Manage: `/profile` command or `node scripts/profile-loader.js`
Config: `.claude/config/active-profile.yaml`

## Hooks (38 total)

Automated JavaScript hooks across all lifecycle events: session start/stop, pre/post tool use, user prompt submit, pre-compact, notifications. Key categories: security, Docker/infra, workflow routing, audit logging, profile management.

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
- Skills: `.claude/skills/` (8 workflow guides)
- Commands: `.claude/commands/` (48 slash commands)

---

*This file is auto-injected after context compaction via pre-compact.js hook.*
