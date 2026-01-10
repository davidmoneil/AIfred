# OpenCode Removal Archive

**Date**: 2026-01-09
**PR**: PR-10 (Organization Cleanup)
**Reason**: OpenCode CLI support deprecated in favor of Claude Code only

---

## Archived Items

### Root Files
| File | Original Location | Notes |
|------|-------------------|-------|
| `AGENTS.md` | `/Jarvis/AGENTS.md` | OpenCode equivalent of CLAUDE.md |
| `opencode.json` | `/Jarvis/opencode.json` | OpenCode configuration file |

### .opencode/ Directory
| File | Path | Notes |
|------|------|-------|
| `agent/deep-research.md` | `.opencode/agent/` | Duplicate of `.claude/agents/deep-research.md` |
| `agent/docker-deployer.md` | `.opencode/agent/` | Duplicate of `.claude/agents/docker-deployer.md` |
| `agent/service-troubleshooter.md` | `.opencode/agent/` | Duplicate of `.claude/agents/service-troubleshooter.md` |
| `command/discover.md` | `.opencode/command/` | Duplicate of `.claude/commands/` |
| `command/end-session.md` | `.opencode/command/` | Duplicate of `.claude/commands/end-session.md` |
| `command/setup.md` | `.opencode/command/` | Duplicate of `.claude/commands/setup.md` |

---

## What Was OpenCode?

OpenCode was an alternative CLI for working with AI assistants. Jarvis initially supported dual-CLI (Claude Code + OpenCode) to maintain flexibility.

As of v1.9.5, Claude Code is the exclusive supported CLI:
- Hooks system fully integrated
- MCP servers configured via `.mcp.json`
- All commands available via `.claude/commands/`
- All agents available via `.claude/agents/`

---

## Migration Notes

Any useful content from `AGENTS.md` has been preserved:
- Core principles → `.claude/CLAUDE.md`
- Persona elements → `.claude/persona/jarvis-identity.md`
- Session workflow → `.claude/context/patterns/session-start-checklist.md`

---

*Archived as part of PR-10 Organization Cleanup*
