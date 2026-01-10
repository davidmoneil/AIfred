# Context Management Inconsistency Assessment

**Created**: 2026-01-07
**Purpose**: Identify and resolve inconsistencies in MCP context management documentation
**Status**: ASSESSMENT COMPLETE — Needs consolidation

---

## Problem Summary

Multiple overlapping commands, two-path workflows, and deprecated approaches are scattered across documentation. This creates confusion and maintenance burden.

---

## Issue 1: Three Overlapping Commands

| Command | File | Purpose | Problems |
|---------|------|---------|----------|
| `/checkpoint` | `.claude/commands/checkpoint.md` | Simple state save for MCP enable | Uses `claude mcp add` |
| `/smart-checkpoint` | `.claude/commands/smart-checkpoint.md` | Intelligent MCP evaluation + two-path | Uses `claude mcp remove`, has Option A/B |
| `/soft-restart` | `.claude/commands/soft-restart.md` | Two-path restart system | Uses `claude mcp remove`, has Path A/B |

**Recommendation**: Consolidate to ONE command (`/checkpoint`) with intelligent MCP evaluation. Remove `/smart-checkpoint` and `/soft-restart` or redirect them to `/checkpoint`.

---

## Issue 2: Two-Path Workflow (Option A/B, Path A/B)

Both `/smart-checkpoint` and `/soft-restart` offer two paths:
- **Path A (Soft)**: `/clear` only — keeps MCPs loaded
- **Path B (Hard)**: `exit` + `claude` — reduces MCP load

**Problems**:
1. Adds complexity without clear benefit
2. Path B relies on user manually typing `exit` then `claude`
3. Cannot automate `exit` from within Claude
4. Creates confusion about which path to use

**Recommendation**: SINGLE workflow using `/clear` only. MCP reduction happens via `disabledMcpServers` array, which takes effect even with `/clear` (as discovered).

---

## Issue 3: `exit` + `claude` in Workflows

Files referencing `exit` + `claude` as part of the workflow:

| File | Line(s) | Context |
|------|---------|---------|
| `.claude/commands/soft-restart.md` | 175-176 | Path B instructions |
| `.claude/commands/smart-checkpoint.md` | 177-178 | Option B instructions |
| `.claude/context/patterns/context-budget-management.md` | 303 | Hard restart instructions |
| `.claude/reports/pr-8.3.1-hook-validation-roadmap.md` | 256, 270 | Test procedures |
| `.claude/reports/mcp-load-unload-test-procedure.md` | 238, 264 | Script output messages |

**Recommendation**: Remove ALL `exit` + `claude` references from workflow documentation. The workflow should be:
1. Run `/checkpoint` (creates checkpoint, disables MCPs)
2. Run `/exit-session` (commits changes)
3. Run `/clear` (restarts with reduced MCPs)

---

## Issue 4: `claude mcp remove` (Deprecated Approach)

Files using `claude mcp remove` instead of `disabledMcpServers`:

| File | Line(s) | Context |
|------|---------|---------|
| `.claude/commands/smart-checkpoint.md` | 125-127 | Phase 5 MCP removal |
| `.claude/commands/soft-restart.md` | 122-124 | Phase 5 MCP removal |
| `.claude/context/patterns/context-budget-management.md` | 255, 258 | MCP reduction |
| `.claude/context/patterns/mcp-loading-strategy.md` | 246 | MCP removal |
| `.claude/context/integrations/mcp-installation.md` | 360, 423 | MCP management |
| `.claude/context/workflows/session-exit.md` | 74 | Session exit workflow |

**Recommendation**: Replace ALL `claude mcp remove` with `disable-mcps.sh` script (uses `disabledMcpServers` array).

---

## Issue 5: Inconsistent Documentation References

Files referencing `/checkpoint` when they might mean `/smart-checkpoint`:
- `.claude/reports/mcp-load-unload-test-procedure.md`

Files referencing both:
- `.claude/context/patterns/automated-context-management.md`
- `.claude/reports/pr-8.3.1-hook-validation-roadmap.md`

**Recommendation**: After consolidation, update all references to use the single canonical command name.

---

## Consolidated Workflow (Proposed)

```
┌─────────────────────────────────────────────────────────────────┐
│ ONE WORKFLOW — NO OPTIONS                                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│ 1. TRIGGER                                                       │
│    - Manual: /checkpoint                                        │
│    - Manual: User sees /context-budget warning                   │
│                                                                  │
│ 2. /checkpoint COMMAND                                           │
│    - Evaluates next steps for MCP requirements                  │
│    - Creates checkpoint file                                     │
│    - Runs disable-mcps.sh for unneeded MCPs                     │
│    - Updates session-state.md                                    │
│                                                                  │
│ 3. /exit-session                                                 │
│    - Commits checkpoint and session state                        │
│    - Displays: "Run /clear to resume"                           │
│                                                                  │
│ 4. /clear                                                        │
│    - Clears conversation                                         │
│    - SessionStart hook fires                                     │
│    - Hook loads checkpoint                                       │
│    - Disabled MCPs not loaded (disabledMcpServers respected)    │
│                                                                  │
│ 5. User says "continue"                                          │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## Files Requiring Updates

### Commands to Modify/Remove

| Action | File | Change |
|--------|------|--------|
| MODIFY | `.claude/commands/checkpoint.md` | Add MCP evaluation, use disable-mcps.sh |
| REMOVE or REDIRECT | `.claude/commands/smart-checkpoint.md` | Consolidate into /checkpoint |
| REMOVE or REDIRECT | `.claude/commands/soft-restart.md` | Consolidate into /checkpoint |

### Documentation to Update

| File | Change |
|------|--------|
| `.claude/reports/pr-8.3.1-hook-validation-roadmap.md` | Remove exit+claude from tests |
| `.claude/reports/mcp-load-unload-test-procedure.md` | Remove exit+claude from tests/scripts |
| `.claude/context/patterns/automated-context-management.md` | Single workflow, no paths |
| `.claude/context/patterns/context-budget-management.md` | Replace `claude mcp remove` |
| `.claude/context/patterns/mcp-loading-strategy.md` | Replace `claude mcp remove` |
| `.claude/context/integrations/mcp-installation.md` | Replace `claude mcp remove` |
| `.claude/context/workflows/session-exit.md` | Replace `claude mcp remove` |
| `projects/project-aion/roadmap.md` | Update workflow description |
| `.claude/context/projects/current-priorities.md` | Already updated |

---

## Revised Test Plan

### Test 1: Verify disabledMcpServers Works with /clear

**Hypothesis**: Adding to `disabledMcpServers` + `/clear` will exclude MCPs (no exit required).

**Steps**:
1. Run: `jq '.projects["/Users/aircannon/Claude/Jarvis"].disabledMcpServers' ~/.claude.json`
   - Note current state
2. Run disable-mcps.sh to add `git` to disabled list
3. Verify config changed: `jq ... ~/.claude.json`
4. Run `/clear`
5. Check `/mcp` — is `git` absent?

**Expected**: git MCP not loaded after /clear.

**If Fails**: We need exit+claude. Document this as required.

### Test 2: Full Workflow (Checkpoint → Disable → Exit-Session → Clear)

**Steps**:
1. Run `/checkpoint` (or enhanced version)
2. Verify checkpoint file created
3. Verify disabledMcpServers updated
4. Run `/exit-session`
5. Run `/clear`
6. Verify checkpoint content appears
7. Verify disabled MCPs not loaded
8. Say "continue" — work resumes

### Test 3: Re-enable MCPs

**Steps**:
1. Run enable-mcps.sh to restore `git`
2. Run `/exit-session`
3. Run `/clear`
4. Verify git MCP restored

---

## Critical Question to Resolve First

**Does `/clear` cause MCP changes to take effect?**

Current evidence suggests YES (user confirmed this works), but we should verify before finalizing the workflow.

If `/clear` does NOT reload MCPs, then we need `exit` + `claude`. But based on user's manual testing, `/clear` should work.

---

## Action Items

1. [ ] Create `disable-mcps.sh` and `enable-mcps.sh` scripts
2. [ ] Run Test 1 to verify /clear respects disabledMcpServers
3. [ ] If Test 1 passes: Update all documentation to single workflow
4. [ ] If Test 1 fails: Document that exit+claude is required (unfortunate but necessary)
5. [ ] Consolidate commands
6. [ ] Update all files listed above

---

*Context Management Inconsistency Assessment*
*Created: 2026-01-07*
