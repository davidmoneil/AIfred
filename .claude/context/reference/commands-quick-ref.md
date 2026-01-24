# Commands & Skills Quick Reference

**Version**: 2.0.0
**Status**: Active (on-demand reference)
**Updated**: 2026-01-23 (Skills Migration)

---

## Session Commands

| Command | Purpose |
|---------|---------|
| `/setup` | Initial configuration wizard |
| `/setup-readiness` | Verify setup complete |
| `/end-session` | Clean exit with commit |
| `/checkpoint` | Save state for restart |

**Skill**: `session-management` — comprehensive session lifecycle guidance

---

## Context Management

| Command | Purpose |
|---------|---------|
| `/context` | Show usage breakdown (native) |
| `/context-budget` | Detailed category analysis |
| `/context-checkpoint` | Full checkpoint with MCP logic |
| `/smart-compact` | JICM manual trigger |
| `/context-analyze` | Weekly usage patterns |
| `/context-loss` | Report forgotten context |
| `/autocompact-threshold` | Set JICM threshold |

**Skill**: `context-management` — JICM orchestration and guidance

---

## Self-Improvement

| Command | Purpose |
|---------|---------|
| `/self-improve` | Full improvement cycle |
| `/reflect` | AC-05 Self-Reflection |
| `/evolve` | AC-06 Self-Evolution |
| `/research` | AC-07 R&D Cycles |
| `/maintain` | AC-08 Maintenance |

**Skill**: `self-improvement` — AC-05/06/07/08 orchestration

---

## Validation

| Command | Purpose |
|---------|---------|
| `/tooling-health` | Validate MCPs, plugins, hooks, skills |
| `/health-report` | Infrastructure health aggregation |
| `/validate-selection` | Selection intelligence audit |
| `/design-review` | PARC pattern check |

**Skill**: `validation` — comprehensive system validation

---

## Native Commands (Claude Code)

These are native Claude Code commands (no Jarvis override):

| Command | Purpose |
|---------|---------|
| `/help` | Claude Code help |
| `/status` | Session settings |
| `/clear` | Clear context |
| `/compact` | Compact history |
| `/config` | View/edit configuration |
| `/export` | Export conversation |
| `/rename` | Rename conversation |
| `/resume` | Resume previous |
| `/stats` | Conversation statistics |
| `/todos` | Show todo list |
| `/usage` | API usage stats |
| `/doctor` | Diagnostics |
| `/hooks` | List hooks |
| `/cost` | Cost information |

**Skill**: `autonomous-commands` — execute native commands via signal-based automation

---

## Design & Planning

| Command | Purpose |
|---------|---------|
| `/design-review` | PARC pattern check |
| `/plan` | Enter plan mode (native) |

---

## Upstream Sync

| Command | Purpose |
|---------|---------|
| `/sync-aifred-baseline` | Analyze upstream changes |

---

## Utilities

| Command | Purpose |
|---------|---------|
| `/jarvis` | Quick command menu |
| `/agent` | Launch specialized agent |

---

## Skills Reference

| Skill | Trigger Phrases |
|-------|-----------------|
| `session-management` | "session", "checkpoint", "end session" |
| `context-management` | "context budget", "JICM", "smart compact" |
| `self-improvement` | "self-improve", "reflect", "evolve" |
| `validation` | "tooling health", "validate", "design review" |
| `autonomous-commands` | "run /status autonomously", "signal command" |
| `ralph-loop` | "ralph loop", "iterative development" |
| `jarvis-status` | "jarvis status", "AC component status" |

Full skills list: `.claude/skills/_index.md`

---

*Commands & Skills Quick Reference v2.0.0*
