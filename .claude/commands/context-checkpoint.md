---
description: Automated context management — evaluate MCPs, save state, reduce context, prepare for /clear
allowed-tools: Read, Write, Edit, Bash(git:*), Bash(.claude/scripts/*)
---

# Context Checkpoint (Automated)

Fully automated context management: single command that evaluates MCPs, creates checkpoint, disables unneeded MCPs, commits state, and prepares for `/clear`.

**After running this command**: User only needs to type `/clear` to resume with reduced context.

## When to Use

- Context approaching threshold (80%+)
- `/context-budget` shows WARNING or CRITICAL
- Before long-running tasks that may bloat context
- Proactive context optimization
- PreCompact warning received

## Automated Workflow

```
/context-checkpoint  →  /clear  →  auto-resume
      ↓                    ↓            ↓
   (Claude)           (User types)  (Automatic)
```

**User actions required**: Just `/clear` after checkpoint completes.

## Procedure (Fully Automated)

### Phase 1: Assess Current State

Check context and MCP status:

```bash
# Current MCPs
.claude/scripts/list-mcp-status.sh
```

Read context state from session files.

### Phase 2: Gather Work Context

Read and summarize:
1. `.claude/context/session-state.md` — Current work status
2. `.claude/context/current-priorities.md` — Immediate priorities
3. Current conversation work — What was accomplished

### Phase 3: MCP Evaluation

Analyze next steps to determine which MCPs are needed:

**Keyword → MCP Mapping:**

| Keyword in Next Steps | Required MCP |
|-----------------------|--------------|
| PR, pull request, issue, review | github |
| research, documentation, docs | context7 |
| design, architecture, planning | sequential-thinking |
| schedule, timestamp, timezone | time |
| git commit, push, branch | git |

**Decision Matrix:**

| MCP | Keep If | Disable If |
|-----|---------|------------|
| memory | Always keep | Never disable |
| filesystem | Always keep | Never disable |
| fetch | Always keep | Never disable |
| github | PR/issue work planned | No GitHub work |
| git | Git operations needed | Just reading/editing |
| context7 | Research/docs needed | Research complete |
| sequential-thinking | Complex planning | Implementation phase |

### Phase 4: Create Checkpoint File

Write checkpoint to `.claude/context/.soft-restart-checkpoint.md`:

```markdown
# Context Checkpoint

**Created**: [timestamp]
**Reason**: Context optimization

## Work Summary

[What was accomplished this session - be specific]

## Next Steps After Restart

1. [Immediate next step]
2. [Follow-up tasks]

## Critical Context

[Decisions, discoveries, blockers that must be preserved]

## MCP State

| MCP | Action | Reason |
|-----|--------|--------|
| memory | KEEP | Tier 1 |
| filesystem | KEEP | Tier 1 |
| fetch | KEEP | Tier 1 |
| github | [KEEP/DISABLED] | [reason] |
| git | [KEEP/DISABLED] | [reason] |
| context7 | [KEEP/DISABLED] | [reason] |
| sequential-thinking | [KEEP/DISABLED] | [reason] |
```

### Phase 5: Disable MCPs

Run the disable script for MCPs not needed:

```bash
.claude/scripts/disable-mcps.sh <mcp-names>
```

Example:
```bash
.claude/scripts/disable-mcps.sh github context7 sequential-thinking
```

**Note**: Changes take effect after `/clear`.

### Phase 6: Update Session State

Update `.claude/context/session-state.md`:

```yaml
## Current Work Status

**Status**: checkpoint (context-checkpoint)

**Checkpoint Info:**
- Type: context-checkpoint
- Reason: context optimization
- Timestamp: [datetime]
- MCPs Disabled: [list]

**Work Summary:**
- [from checkpoint]

**Next Steps After Restart:**
- [from checkpoint]
```

### Phase 7: Git Commit

```bash
git add -A
git commit -m "Context checkpoint: context optimization

MCPs disabled: [list]
Next: [brief next step]

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>"
```

### Phase 8: Output Instructions

```
╔══════════════════════════════════════════════════════════════╗
║              CONTEXT CHECKPOINT COMPLETE                      ║
╚══════════════════════════════════════════════════════════════╝

✅ Checkpoint saved: .claude/context/.soft-restart-checkpoint.md
✅ Session state updated
✅ MCPs disabled: [list]
✅ Changes committed

Estimated Token Savings: ~[X]K (MCP reduction)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

NEXT STEP (Just one!):

  Type: /clear

  ➜ Session restarts with reduced MCPs
  ➜ Checkpoint loads automatically
  ➜ Resume from where you left off

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## MCP Token Reference

### Tier 1: Never Disable (~21K)
| MCP | ~Tokens |
|-----|---------|
| memory | ~8K |
| filesystem | ~8K |
| fetch | ~5K |

### Tier 2: Disable When Not Needed
| MCP | ~Tokens | Savings |
|-----|---------|---------|
| github | ~15K | High |
| git | ~4K | Medium |
| context7 | ~8K | Medium |
| sequential-thinking | ~5K | Medium |

## Re-enabling MCPs Later

After completing work that needed reduced MCPs:

```bash
# Enable specific MCPs
.claude/scripts/enable-mcps.sh github git

# Or enable all
.claude/scripts/enable-mcps.sh --all

# Then /clear to load them
```

## Key Discovery (2026-01-07)

`/clear` respects `disabledMcpServers` changes:
- Disabling via script adds to `~/.claude.json` → `disabledMcpServers[]`
- `/clear` reloads config and skips disabled MCPs
- No need to `exit` + `claude` — `/clear` is sufficient

## Related

- `/checkpoint` — Simple state save (no MCP logic)
- `/context-budget` — Check current context usage
- `/end-session` — Full session exit (use when NOT checkpointing)
- @.claude/context/patterns/context-budget-management.md

---

*Context Checkpoint — Automated Context Management*
*Created: 2026-01-07*
*Validated: /clear respects disabledMcpServers*
