---
description: Context management with MCP evaluation and reduction — the full workflow
allowed-tools: Read, Write, Edit, Bash(git:*), Bash(.claude/scripts/*)
---

# Context Checkpoint

Full context management workflow: evaluate MCPs, create checkpoint, disable unneeded MCPs, prepare for /clear restart.

## When to Use

- Context approaching threshold (80%+)
- `/context-budget` shows WARNING or CRITICAL
- Before long-running tasks that may bloat context
- Proactive context optimization

## Workflow Overview

```
/context-checkpoint → /exit-session → /clear → resume
```

## Procedure

### Phase 1: Assess Current State

First, check context and MCP status:

1. Run `/context` to see current usage
2. Note MCP tools token count

### Phase 2: Gather Work Context

Read and summarize:
1. Current work in progress
2. What was accomplished this session
3. Immediate next steps

**Key files to check:**
- `.claude/context/session-state.md` — Current status
- `.claude/context/projects/current-priorities.md` — What's next

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

[What was accomplished this session]

## Next Steps After Restart

1. [Immediate next step]
2. [Follow-up tasks]

## Critical Context

[Any decisions, discoveries, or blockers that must be preserved]

## MCP State

| MCP | Action | Reason |
|-----|--------|--------|
| github | DISABLED | No PR work planned |
| context7 | DISABLED | Research phase complete |
| ... | ... | ... |
```

### Phase 5: Disable MCPs (If Approved)

If user approves MCP reduction, run:

```bash
.claude/scripts/disable-mcps.sh <mcp-names>
```

Example:
```bash
.claude/scripts/disable-mcps.sh github context7 sequential-thinking git
```

### Phase 6: Update Session State

Update `.claude/context/session-state.md` with:

```yaml
## Current Work Status

**Status**: checkpoint (context-checkpoint)

**Checkpoint Info:**
- Type: context-checkpoint
- Reason: context optimization
- Timestamp: [datetime]
- MCPs Disabled: [list]

**Next Steps After Restart:**
- [from checkpoint]
```

### Phase 7: Provide Instructions

Output to user:

```
╔══════════════════════════════════════════════════════════════╗
║              CONTEXT CHECKPOINT COMPLETE                      ║
╚══════════════════════════════════════════════════════════════╝

✅ Checkpoint saved: .claude/context/.soft-restart-checkpoint.md
✅ Session state updated
✅ MCPs disabled: [list]

Estimated Token Savings: ~[X]K

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

NEXT STEPS:

  1. Run: /exit-session (commits changes)
  2. Run: /clear (restarts with reduced MCPs)
  3. Say "continue" to resume work

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## MCP Token Reference

### Tier 1: Never Disable
| MCP | ~Tokens |
|-----|---------|
| memory | ~8K |
| filesystem | ~8K |
| fetch | ~5K |

### Tier 2: Disable When Not Needed
| MCP | ~Tokens | Savings When Disabled |
|-----|---------|----------------------|
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
```

Then run `/exit-session` → `/clear` to load them.

## Related

- `/checkpoint` — Simple state save (no MCP logic)
- `/context-budget` — Check current context usage
- `/exit-session` — Commit and exit cleanly
- @.claude/context/patterns/automated-context-management.md

---

*Context Checkpoint — MCP-Aware Context Management*
*Created: 2026-01-07*
*Validated: /clear respects disabledMcpServers*
