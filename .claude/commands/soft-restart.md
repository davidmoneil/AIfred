---
description: Intelligent session restart with checkpoint preservation and optional MCP reduction
allowed-tools: Read, Write, Edit, Bash(git:*), Bash(claude mcp:*)
---

# Soft Restart

Two-path restart system: clear conversation with checkpoint, optionally reduce MCP load.

## When to Use

- Context approaching threshold (80%+)
- PreCompact warning received
- Want to clear conversation while preserving work state
- Need to reduce MCP token load for extended work sessions

## Quick Decision

| Situation | Path | Token Savings |
|-----------|------|---------------|
| Just need fresh conversation | A (Soft) | ~16K (conversation) |
| Need significant token reduction | B (Hard) | ~16K + ~31K (MCPs) |
| Context critical, MCPs not needed | B (Hard) | Maximum |

## Workflow

### Phase 1: Capture Current State

First, capture the work state:

```bash
# Check current MCP configuration
claude mcp list
```

**Read and analyze:**
1. `.claude/context/session-state.md` — Current work status
2. `.claude/context/projects/current-priorities.md` — What's next

### Phase 2: Write Checkpoint File

Create checkpoint at `.claude/context/.soft-restart-checkpoint.md`:

```markdown
# Soft Restart Checkpoint

**Created**: [timestamp]
**Path**: [A or B]
**Reason**: [context threshold / proactive / PreCompact warning]

## Work Summary

[What was accomplished this session]

## Next Steps After Restart

1. [Immediate next step]
2. [Follow-up tasks]

## Critical Context

[Any important context that must be preserved - decisions, discoveries, blockers]

## MCP State (Path B only)

| MCP | Action | Reason |
|-----|--------|--------|
| github | KEEP | PR work continues |
| context7 | DROP | Research complete |
| ...

```

### Phase 3: Update Session State

Edit `.claude/context/session-state.md`:

```yaml
## Current Work Status

**Status**: checkpoint (soft-restart)

**Checkpoint Info:**
- Type: soft-restart
- Path: [A or B]
- Reason: [reason]
- Timestamp: [datetime]

**Next Steps After Restart:**
- [list from checkpoint]
```

### Phase 4: Git Commit

```bash
git add -A
git commit -m "Soft restart checkpoint: [reason]

Path: [A/B]
Next: [brief next step]

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>"
```

### Phase 5: Path-Specific Actions

**PATH A (Soft - Conversation Only)**

No MCP changes needed. Skip to Phase 6A.

**PATH B (Hard - With MCP Reduction)**

Evaluate and remove non-essential MCPs:

```bash
# Remove Tier 2 MCPs not needed for next steps
# (Evaluate based on checkpoint "Next Steps")

# Example removals:
claude mcp remove time -s local
claude mcp remove context7 -s local
claude mcp remove sequential-thinking -s local
# Keep github if PR work continues
```

### Phase 6: Exit Instructions

**PATH A: Soft Restart**

```
╔═══════════════════════════════════════════════════════════════════╗
║              SOFT RESTART READY (Path A)                          ║
╚═══════════════════════════════════════════════════════════════════╝

✅ Checkpoint saved: .claude/context/.soft-restart-checkpoint.md
✅ Session state updated
✅ Changes committed

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

NEXT STEPS:

  1. Run: /clear
  2. Session-start hook will load your checkpoint automatically
  3. Say "continue" to resume work

Estimated Token Savings: ~16K (conversation cleared)
Note: MCPs remain loaded (same process)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**PATH B: Hard Restart**

```
╔═══════════════════════════════════════════════════════════════════╗
║              HARD RESTART READY (Path B)                          ║
╚═══════════════════════════════════════════════════════════════════╝

✅ Checkpoint saved: .claude/context/.soft-restart-checkpoint.md
✅ Session state updated
✅ Changes committed
✅ MCP config updated (changes apply on next session)

MCPs Adjusted:
- KEPT: memory, filesystem, fetch, git, [github if needed]
- DROPPED: [time, context7, sequential-thinking, etc.]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

NEXT STEPS:

  1. Type: exit  (or press Ctrl+C)
  2. Run: claude
  3. Session-start hook will load your checkpoint automatically
  4. Say "continue" to resume work

Estimated Token Savings: ~47K total
  - Conversation: ~16K
  - MCP reduction: ~31K

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

💡 To restore MCPs later:
   claude mcp add <name> -s local -- <runner> <package>
```

## MCP Reference

### Tier 1: Never Remove (~34K total)
| MCP | ~Tokens | Purpose |
|-----|---------|---------|
| memory | ~8K | Knowledge persistence |
| filesystem | ~8K | File operations |
| fetch | ~5K | Web retrieval |
| git | ~7K | Git operations |

### Tier 2: Evaluate (~31K if all loaded)
| MCP | ~Tokens | Keep If |
|-----|---------|---------|
| github | ~15K | PR/issue work ahead |
| context7 | ~2K | Research/docs needed |
| sequential-thinking | ~2K | Complex planning |
| time | ~1.5K | Scheduling work |
| playwright | ~15K | Browser testing |

## How Checkpoint Loading Works

After `/clear` or new session start:

1. `SessionStart` hook fires
2. Hook checks for `.soft-restart-checkpoint.md`
3. If found:
   - Displays checkpoint context in session banner
   - Clears the checkpoint file (one-time use)
4. User says "continue" to resume

## Troubleshooting

**Checkpoint not loading after /clear?**
- Verify file exists: `ls -la .claude/context/.soft-restart-checkpoint.md`
- Check hook is enabled: `ls -la .claude/hooks/session-start.js`
- Hook output appears in session banner, not as assistant message

**MCPs still showing after Path B?**
- Path B requires `exit` + `claude` (not `/clear`)
- `/clear` keeps same process, MCPs stay loaded
- Run `claude mcp list` to verify config changes

## Related

- @.claude/context/patterns/automated-context-management.md
- @.claude/context/patterns/context-budget-management.md
- @.claude/commands/checkpoint.md
- @.claude/commands/smart-checkpoint.md

---

*Soft Restart — Two-Path Context Management*
