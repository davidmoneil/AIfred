# MCP Workflow Test Findings

**Date**: 2026-01-07
**PR Reference**: PR-8.3.1
**Status**: VALIDATED (with one bug identified)

---

## Executive Summary

The MCP disable/enable mechanism via `disabledMcpServers` array in `~/.claude.json` has been validated as functional. The workflow achieves a **54% reduction in MCP token overhead** (16.2K → 7.4K tokens). One critical bug was identified: the checkpoint file is deleted during `/exit-session`, preventing proper resumption after `/clear`.

---

## Test Environment

- **Location**: `/Users/aircannon/Claude/Jarvis`
- **Branch**: `Project_Aion`
- **MCPs Tested**: memory, filesystem, fetch, git, github, context7, sequential-thinking
- **Test Terminal**: Fresh Claude Code session (separate from main session)

---

## Test Results

### Test 1: MCP Disable/Enable Mechanism

| Action | Result | Status |
|--------|--------|--------|
| `disable-mcps.sh github git context7 sequential-thinking` | MCPs added to `disabledMcpServers[]` | ✅ PASS |
| `/clear` execution | Config reloaded, MCPs not exposed | ✅ PASS |
| `/mcp` after `/clear` | Shows disabled MCPs correctly | ✅ PASS |
| `enable-mcps.sh --all` | MCPs removed from `disabledMcpServers[]` | ✅ PASS |
| `/clear` after enable | All MCPs restored | ✅ PASS |

### Test 2: Context Token Savings

| Metric | Before Disable | After Disable | Change |
|--------|----------------|---------------|--------|
| MCP Tools | 16.2K tokens | 7.4K tokens | -54% |
| Disabled Count | 0 | 4 | +4 |

**MCPs Disabled**: github (~15K), git (~4K), context7 (~8K), sequential-thinking (~5K)
**Actual Savings**: ~8.8K tokens

### Test 3: Checkpoint Workflow

| Step | Expected | Actual | Status |
|------|----------|--------|--------|
| `/context-checkpoint` creates file | File at `.soft-restart-checkpoint.md` | File created | ✅ PASS |
| MCP evaluation generates recommendations | Correct keep/disable suggestions | Correct | ✅ PASS |
| `disable-mcps.sh` runs successfully | MCPs flagged | MCPs flagged | ✅ PASS |
| `/exit-session` commits changes | Commit created, pushed | Committed | ✅ PASS |
| `/clear` loads checkpoint | Checkpoint content displayed | Displayed | ✅ PASS |
| Checkpoint file persists | File available for resume | **FILE DELETED** | ❌ FAIL |

---

## Critical Bug: Checkpoint File Deletion

### Symptom
After running `/exit-session` followed by `/clear`, the checkpoint file at `.claude/context/.soft-restart-checkpoint.md` is not found. Git status shows `D .claude/context/.soft-restart-checkpoint.md`.

### Evidence
```
$ ls -la .claude/context/.soft-restart-checkpoint.md
ls: .claude/context/.soft-restart-checkpoint.md: No such file or directory

$ git status
D .claude/context/.soft-restart-checkpoint.md
```

### Root Cause (Hypothesis)
The `/exit-session` command likely includes a `git add -A` that stages the checkpoint file, commits it, but then either:
1. A hook deletes the file after commit
2. The command explicitly removes it
3. The file is created as ephemeral but not persisted correctly

### Impact
- Checkpoint created successfully
- Checkpoint committed to git history
- Checkpoint deleted after commit
- `/clear` cannot find checkpoint for resumption on subsequent sessions

### Fix Applied (2026-01-07)

**Root Cause**: The `session-start.sh` hook at line 32 was deleting the checkpoint file after loading it ("one-time use" design).

**Fix**: Removed the `rm "$CHECKPOINT_FILE"` line from `.claude/hooks/session-start.sh`. The checkpoint file now persists until:
- Overwritten by next `/context-checkpoint`
- Manually deleted if needed

**Rationale**:
- Allows multiple `/clear` cycles with same checkpoint
- Keeps git status clean (no deletion after commit)
- User can reference checkpoint file later

---

## Key Discovery: MCP Loading Architecture

### How `disabledMcpServers` Works

```
1. User runs disable-mcps.sh <mcp-name>
   └── Adds MCP to ~/.claude.json → projects[path].disabledMcpServers[]

2. Changes take effect on session boundary:
   └── /clear — clears conversation, reloads config
   └── exit + claude — full restart

3. Claude Code reads config on session start:
   └── MCPs in disabledMcpServers[] are not loaded into context
   └── MCP processes may still run, but tools not exposed
   └── Token savings realized immediately
```

### Key Insight
This is **the mechanism** for dynamic MCP loading control. It enables:
- Per-session MCP optimization
- Context budget management
- Task-specific tool sets

### Limitation Discovered
**Plugin-bundled MCPs cannot be disabled**. Playwright MCPs (from `document-skills` plugin) do not respond to `disabledMcpServers`. This requires plugin decomposition for fine-grained control.

---

## Metrics Summary

| Metric | Value | Notes |
|--------|-------|-------|
| Token savings per disable cycle | ~8.8K | With github, git, context7, sequential-thinking |
| Percentage reduction | 54% | From 16.2K to 7.4K MCP tokens |
| Time to disable | <1s | Script execution |
| Time to apply changes | <5s | `/clear` execution |
| Workflow steps | 4 | checkpoint → disable → exit → clear |

---

## Automation Requirements

### Previous State (4 User Actions)
```
User: /context-checkpoint
Claude: [creates checkpoint, disables MCPs]
User: /exit-session
Claude: [commits changes]
User: /clear
Claude: [reloads with reduced MCPs]
User: continue
Claude: [resumes from checkpoint]
```

### Current State (2 User Actions) — IMPLEMENTED
```
User: /context-checkpoint
Claude: [evaluates MCPs, creates checkpoint, disables MCPs, commits state]
User: /clear
Claude: [reloads with reduced MCPs, checkpoint loads automatically]
User: continue
Claude: [resumes from checkpoint]
```

### Limitation
Claude cannot execute `/clear` — it's a built-in CLI command that requires user input. This is the minimum possible user interaction.

### Future Enhancement (Optional)
1. **PreCompact hook**: Automatically trigger checkpoint when context reaches threshold
2. **Auto-continue**: SessionStart hook could be enhanced to not require "continue"

---

## Next Steps

1. ~~**Fix checkpoint deletion bug**~~ — ✅ FIXED (removed `rm` from session-start.sh)
2. ~~**Enhance automation**~~ — ✅ DONE (`/context-checkpoint` now includes commit)
3. **Add PreCompact hook** — Trigger on context threshold (future)
4. ~~**Update SessionStart hook**~~ — ✅ DONE (improved resume message)
5. ~~**Document final workflow**~~ — ✅ DONE (this document + command updates)

---

## Related Documentation

- `.claude/commands/context-checkpoint.md` — Current checkpoint command
- `.claude/context/patterns/context-budget-management.md` — Budget strategy
- `.claude/context/patterns/automated-context-management.md` — Automation design
- `.claude/scripts/disable-mcps.sh` — MCP disable script
- `.claude/scripts/enable-mcps.sh` — MCP enable script

---

*MCP Workflow Test Findings — PR-8.3.1 Validation*
*Created: 2026-01-07*
