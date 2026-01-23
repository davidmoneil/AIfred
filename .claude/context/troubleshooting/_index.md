# Troubleshooting Index

Quick navigation to solutions by problem type.

**Version**: 1.0.0
**Layer**: Nous (problem-solution navigation)

---

## Problem Categories

### MCP Issues

| Problem | Quick Fix | Details |
|---------|-----------|---------|
| MCP not loading | Run `/tooling-health` | Check configuration |
| MCP returning errors | Check MCP logs in `.claude/logs/` | May need restart |
| MCP timeout | Increase timeout, check network | See mcp-design-patterns.md |
| MCP conflicts | Check `overlap-analysis.md` | Tool precedence rules |

**Diagnostic command**: `/tooling-health`

---

### Hook Issues

| Problem | Quick Fix | Details |
|---------|-----------|---------|
| Hook not firing | Check hook registration in settings.json | Verify event name |
| Hook blocking | Read hook's block message | Adjust action or hook config |
| Hook error | Check `.claude/logs/` | Debug hook code |
| Hook import error | See `hookify-import-fix.md` | Common import issues |

**Diagnostic command**: `/hooks`

---

### Context Issues

| Problem | Quick Fix | Details |
|---------|-----------|---------|
| Context exhaustion | Run `/checkpoint` then `/clear` | See jicm-pattern.md |
| Context approaching limit | Proactive checkpoint | Watch status line tokens |
| Lost context after clear | Check `session-state.md` | Restore from checkpoint |
| Context compression failed | Manual checkpoint | Use simple checkpoint fallback |

**Pattern**: `patterns/jicm-pattern.md`

---

### Agent Issues

| Problem | Quick Fix | Details |
|---------|-----------|---------|
| Agent not found | Check `.claude/agents/` | Verify agent file exists |
| Agent YAML error | Validate YAML frontmatter | See agent-format-migration.md |
| Agent timeout | Increase max_turns | Some tasks need more iterations |
| Agent wrong model | Specify model parameter | Override default model |

**Docs**: `.claude/agents/README.md`

---

### Git Issues

| Problem | Quick Fix | Details |
|---------|-----------|---------|
| Commit failed | Check hook output | Pre-commit hooks may block |
| Push rejected | Pull first, resolve conflicts | Check branch protection |
| Detached HEAD | `git checkout <branch>` | Reattach to branch |
| Merge conflicts | Resolve manually | Use careful edit |

**Safety**: Never force push to main/master

---

### Session Issues

| Problem | Quick Fix | Details |
|---------|-----------|---------|
| Session state stale | Read `session-state.md` manually | May need manual update |
| Priorities outdated | Update `current-priorities.md` | After completing work |
| Lost work context | Check Memory MCP entities | Decisions should be stored |
| Can't resume | Review session-state.md | Follow pickup instructions |

**Pattern**: `workflows/session-exit.md`

---

### Skill Issues

| Problem | Quick Fix | Details |
|---------|-----------|---------|
| Skill not found | Check `/` prefix usage | Use Skill tool |
| Skill error | Check SKILL.md in skill directory | Verify skill definition |
| Skill dependencies | Install required tools | Check skill requirements |

**Docs**: `.claude/skills/_index.md`

---

### Command Issues

| Problem | Quick Fix | Details |
|---------|-----------|---------|
| Command not recognized | Check spelling, `/` prefix | Use Skill tool for skills |
| Command blocked | Check hook configuration | Permission issue |
| Command timeout | Task may be complex | Consider breaking down |

**Reference**: `reference/commands-quick-ref.md`

---

## Specific Problem Documents

| Document | Problem Solved |
|----------|---------------|
| `agent-format-migration.md` | Agent YAML frontmatter issues |
| `hookify-import-fix.md` | Hookify import resolution |
| `mcp-validation-harness.md` | MCP testing and validation |

---

## Diagnostic Commands

| Command | Purpose |
|---------|---------|
| `/tooling-health` | Validate MCPs, plugins, skills |
| `/status` | Check autonomic system status |
| `/doctor` | Run system diagnostics |
| `/hooks` | List registered hooks |
| `/bashes` | Check background processes |

---

## Self-Diagnosis Checklist

When something goes wrong:

1. **Check logs**: `.claude/logs/` for recent errors
2. **Check state**: `session-state.md` for current work status
3. **Run diagnostics**: `/tooling-health` or `/doctor`
4. **Check patterns**: Relevant pattern in `patterns/`
5. **Search lessons**: `lessons/` for similar past issues
6. **Memory check**: Query Memory MCP for stored decisions

---

## Escalation Path

If self-diagnosis fails:

1. Document the problem clearly
2. Note reproduction steps
3. Check if related to recent changes
4. Consider reverting recent changes
5. Ask user for guidance if blocked

---

*Jarvis — Nous Layer (Troubleshooting Navigation)*
