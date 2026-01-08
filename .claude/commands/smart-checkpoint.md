---
description: "[DEPRECATED] Use /checkpoint instead — Single workflow for context management"
allowed-tools: Read, Write, Edit, Bash(git:*), Bash(claude mcp:*)
---

# Smart Checkpoint (DEPRECATED)

> **DEPRECATED 2026-01-07**: This command has been superseded by `/checkpoint`.
> The two-path approach (Option A/B) is no longer needed.
> MCP changes are now made via `disabledMcpServers`, not `claude mcp remove`.

## Redirect

Run `/checkpoint` instead. It provides:
1. MCP evaluation based on next steps
2. Checkpoint file creation
3. MCP disable via `.claude/scripts/disable-mcps.sh`
4. Single workflow: `/checkpoint` → `/exit-session` → `/clear`

**Validated 2026-01-07**: `/clear` respects `disabledMcpServers` changes.

---

## Legacy Documentation (for reference)

Automated context management: evaluate MCPs, save state, adjust config, restart with lean load.

## When to Use

- Context approaching threshold (80%+)
- PreCompact warning received
- Before long-running tasks that may bloat context
- Proactive context optimization

## Workflow

### Phase 1: Context Assessment

First, assess current context state:

```bash
# Check current MCP configuration
claude mcp list
```

Note which Tier 2 MCPs are currently active.

### Phase 2: MCP Evaluation

Analyze next steps to determine which MCPs are critical:

**Read these files:**
1. `.claude/context/session-state.md` — "Next Session Pickup" section
2. `.claude/context/projects/current-priorities.md` — immediate priorities

**Keyword → MCP Mapping:**

| Keyword in Next Steps | Required MCP |
|-----------------------|--------------|
| PR, pull request, issue, review | github |
| research, documentation, docs, library | context7 |
| design, architecture, planning, complex | sequential-thinking |
| schedule, timestamp, timezone | time |

**Decision Matrix:**

| MCP | Keep If | Drop If |
|-----|---------|---------|
| github | PR/issue work in next steps | No GitHub work planned |
| context7 | Research/docs lookup needed | Research phase complete |
| sequential-thinking | Complex planning ahead | Implementation phase |
| time | Time-sensitive operations | No scheduling needed |

### Phase 3: Generate Recommendation

Based on analysis, produce:

```markdown
## MCP Evaluation Results

**Next Steps Analysis:**
- [quote key next steps from session-state.md]

**MCP Recommendation:**
| MCP | Action | Reason |
|-----|--------|--------|
| github | KEEP | PR-8.4 work continues |
| context7 | DROP | Research phase complete |
| sequential-thinking | DROP | No complex planning ahead |
| time | DROP | No scheduling needed |

**Estimated Token Savings:** ~[X]K tokens
```

### Phase 4: Soft Exit (No Push)

Execute soft exit procedure:

1. **Update session-state.md:**

```yaml
## Current Work Status

**Status**: checkpoint (smart-checkpoint)

**Checkpoint Info:**
- Type: smart-checkpoint
- Reason: context optimization
- Timestamp: [current datetime]

**MCP Recommendation:**
- Keep: [list]
- Drop: [list]

**Work Summary:**
- [what was accomplished this session]

**Next Steps After Restart:**
- [immediate next steps]
```

2. **Git commit (no push):**

```bash
git add -A
git commit -m "Smart checkpoint: context optimization

MCPs dropped: [list]
MCPs preserved: [list]
Next: [brief next step]

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>"
```

### Phase 5: MCP Config Adjustment

Remove non-critical Tier 2 MCPs:

```bash
# Example removals (based on evaluation)
claude mcp remove time -s local
claude mcp remove context7 -s local
claude mcp remove sequential-thinking -s local
# github kept if PR work continues
```

**Important:** These changes take effect on NEXT session start, not immediately.

### Phase 6: Create Checkpoint File

Create the soft restart checkpoint file:

```bash
# Write checkpoint to .claude/context/.soft-restart-checkpoint.md
```

Include:
- What we were doing (summary)
- Next steps after restart
- MCP state (kept/dropped)
- Any critical context needed to continue

### Phase 7: Soft Restart via /clear

Output restart options:

```
╔══════════════════════════════════════════════════════════════╗
║              SMART CHECKPOINT COMPLETE                        ║
╚══════════════════════════════════════════════════════════════╝

✅ Session state saved
✅ Changes committed (not pushed)
✅ MCP config optimized
✅ Checkpoint file created

MCPs Adjusted:
- KEPT: memory, filesystem, fetch, git, github
- DROPPED: time, context7, sequential-thinking

Estimated Token Savings: ~16K tokens (conversation) + ~16K (MCPs on hard restart)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

RESTART OPTIONS:

Option A — Soft Restart (clears conversation only):
  1. Run: /clear
  2. Session-start hook will load checkpoint automatically
  3. Say "continue" to resume work

Option B — Hard Restart (also reduces MCP load):
  1. Type: exit (or Ctrl+C)
  2. Run: claude
  3. Session starts with reduced MCPs (~16K more tokens saved)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

💡 Soft restart clears conversation context but keeps MCP schemas loaded.
💡 Hard restart fully resets everything including MCP load.
💡 Choose based on how much context you need to free.
```

## MCP Quick Reference

### Tier 1: Always Keep (~27-34K)
| MCP | Tokens | Never Remove |
|-----|--------|--------------|
| memory | ~8-15K | Core knowledge |
| filesystem | ~8K | File operations |
| fetch | ~5K | Web retrieval |
| git | ~6K | Git operations |

### Tier 2: Evaluate (~35K total if all loaded)
| MCP | Tokens | Evaluation Criteria |
|-----|--------|---------------------|
| github | ~15K | PR/issue work |
| context7 | ~8K | Research/docs |
| sequential-thinking | ~5K | Complex planning |
| time | ~3K | Scheduling |
| duckduckgo | ~4K | Web search |

## Re-adding MCPs Later

If you need a dropped MCP in the new session:

```bash
# Re-add individual MCPs as needed
claude mcp add time -s local -- uvx mcp-server-time
claude mcp add context7 -s local -- npx -y @upstash/context7-mcp --api-key <key>
claude mcp add sequential-thinking -s local -- npx -y @modelcontextprotocol/server-sequential-thinking
```

Then run `/checkpoint` to enable it.

## Related

- @.claude/context/patterns/automated-context-management.md
- @.claude/context/patterns/context-budget-management.md
- @.claude/commands/checkpoint.md
- @.claude/commands/end-session.md

---

*Smart Checkpoint — Automated Context Management*
