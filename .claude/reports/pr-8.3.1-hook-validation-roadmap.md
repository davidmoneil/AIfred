# PR-8.3.1: Automated Context Management — Revised Implementation Strategy

**Created**: 2026-01-07
**Revised**: 2026-01-07 (Major revision based on disabledMcpServers discovery)
**Status**: READY FOR IMPLEMENTATION
**Goal**: Automate MCP disable → exit-session → /clear → restart workflow triggered by context threshold

---

## Executive Summary

### Key Discovery (2026-01-07)

**MCP disabled state is stored in `~/.claude.json`** under:
```json
"projects": {
  "/Users/aircannon/Claude/Jarvis": {
    "disabledMcpServers": ["context7", "github", "git", ...],
    "mcpServers": { ... }
  }
}
```

This means we can:
1. **Programmatically disable MCPs** by modifying this array with `jq`
2. **Effect takes place on next session start** (after exit or /clear)
3. **MCPs remain available** - just disabled, can re-enable anytime
4. **No uninstall required** - disabled ≠ removed from settings

### Abandoned Approaches

| Approach | Why Abandoned |
|----------|---------------|
| `claude mcp remove` | Uninstalls MCP entirely, requires re-add with args/keys |
| Auto-exit from hooks | Process isolation prevents hooks from killing parent |
| Hard restart automation | Unnecessary complexity; user can type `exit` |

### Validated Approach

```
TRIGGER → CHECKPOINT → DISABLE MCPs → EXIT-SESSION → /CLEAR → RESUME
```

1. **Trigger**: Context threshold (hook or manual /checkpoint)
2. **Checkpoint**: Save state to `.soft-restart-checkpoint.md`
3. **Disable MCPs**: Modify `disabledMcpServers` array in `~/.claude.json`
4. **Exit Session**: Run /exit-session (commits, saves state)
5. **Clear**: User runs /clear (triggers SessionStart hook)
6. **Resume**: Hook loads checkpoint, MCPs reduced, continue work

---

## Implementation Plan

### Phase 1: MCP Disable Script (Ready)

Create script to modify `~/.claude.json`:

```bash
#!/bin/bash
# .claude/scripts/disable-mcps.sh
# Usage: disable-mcps.sh <server-name> [server-name...]

PROJECT_PATH="/Users/aircannon/Claude/Jarvis"
CONFIG_FILE="$HOME/.claude.json"

for SERVER in "$@"; do
  # Add to disabledMcpServers if not already present
  jq --arg path "$PROJECT_PATH" --arg server "$SERVER" '
    .projects[$path].disabledMcpServers |= (. + [$server] | unique)
  ' "$CONFIG_FILE" > "$CONFIG_FILE.tmp" && mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
  echo "Disabled: $SERVER"
done
```

**Enable script**:
```bash
#!/bin/bash
# .claude/scripts/enable-mcps.sh
# Usage: enable-mcps.sh <server-name> [server-name...]

PROJECT_PATH="/Users/aircannon/Claude/Jarvis"
CONFIG_FILE="$HOME/.claude.json"

for SERVER in "$@"; do
  # Remove from disabledMcpServers
  jq --arg path "$PROJECT_PATH" --arg server "$SERVER" '
    .projects[$path].disabledMcpServers |= (. - [$server])
  ' "$CONFIG_FILE" > "$CONFIG_FILE.tmp" && mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
  echo "Enabled: $SERVER"
done
```

### Phase 2: Enhanced /checkpoint Command

Update `/checkpoint` command to:
1. Create checkpoint file with current work state
2. Evaluate next steps for required MCPs
3. Run disable script for non-essential Tier 2/3 MCPs
4. Provide clear "run /exit-session then /clear" instructions

```markdown
---
description: Save session state with optional MCP optimization for restart
---

# Checkpoint Command

1. Capture current work context
2. Evaluate MCP needs based on next steps
3. OPTIONALLY disable non-essential MCPs (user choice)
4. Create checkpoint file
5. Instruct user: "Run /exit-session, then /clear to resume with reduced context"
```

### Phase 3: SessionStart Hook Enhancement

The `session-start.sh` hook should:
1. Check for `.soft-restart-checkpoint.md`
2. If found: output checkpoint content as JSON systemMessage
3. Delete checkpoint file after reading (one-time use)

```bash
#!/bin/bash
# .claude/hooks/session-start.sh

CHECKPOINT_FILE="$CLAUDE_PROJECT_DIR/.claude/context/.soft-restart-checkpoint.md"

if [ -f "$CHECKPOINT_FILE" ]; then
  CONTENT=$(cat "$CHECKPOINT_FILE" | jq -Rs .)
  rm "$CHECKPOINT_FILE"
  echo "{\"systemMessage\": \"Checkpoint loaded:\\n$CONTENT\"}"
else
  echo "{}"
fi
```

### Phase 4: Context Threshold Hook (Optional)

A `PreCompact` or `UserPromptSubmit` hook that monitors context:

```bash
#!/bin/bash
# .claude/hooks/context-monitor.sh
# Check if context is approaching threshold and warn user

# This would require reading context stats from somewhere
# For MVP: rely on manual /context-budget checks
echo "{}"
```

---

## MCP Tier Classification

### Tier 1: Never Disable
| MCP | Reason |
|-----|--------|
| memory | Core knowledge persistence |
| filesystem | File operations |
| fetch | Web fetching |

### Tier 2: Task-Dependent (Disable When Not Needed)
| MCP | Keep If | Token Cost |
|-----|---------|------------|
| github | PR/issue work | ~15K |
| git | Active git operations | ~4K |
| context7 | Documentation research | ~8K |
| sequential-thinking | Complex planning | ~5K |

### Tier 3: Plugin-Managed (Already Isolated)
| MCP | Status |
|-----|--------|
| plugin:playwright:playwright | Only loads when plugin active |
| plugin:gitlab:gitlab | Only loads when plugin active |

---

## Workflow Sequence

```
┌─────────────────────────────────────────────────────────────────┐
│ STEP 1: TRIGGER                                                   │
├─────────────────────────────────────────────────────────────────┤
│ Options:                                                          │
│ - Manual: /checkpoint or /smart-checkpoint                       │
│ - Automatic: PreCompact hook warns, user confirms                │
│ - Proactive: /context-budget shows CRITICAL, user acts           │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│ STEP 2: CHECKPOINT CREATION                                       │
├─────────────────────────────────────────────────────────────────┤
│ Claude (or command):                                              │
│ 1. Gathers current work state                                    │
│ 2. Evaluates next steps for MCP requirements                     │
│ 3. Writes: .claude/context/.soft-restart-checkpoint.md           │
│ 4. Updates: session-state.md with checkpoint info                │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│ STEP 3: MCP DISABLE (OPTIONAL)                                    │
├─────────────────────────────────────────────────────────────────┤
│ If user approves MCP reduction:                                   │
│   .claude/scripts/disable-mcps.sh git context7 sequential-thinking│
│                                                                   │
│ Modifies: ~/.claude.json → disabledMcpServers array              │
│ Effect: MCPs will not load on next session start                  │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│ STEP 4: EXIT SESSION                                              │
├─────────────────────────────────────────────────────────────────┤
│ User runs: /exit-session                                          │
│ - Commits changes (session-state.md, checkpoint)                 │
│ - Displays: "Run /clear to restart with checkpoint"              │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│ STEP 5: CLEAR AND RESUME                                          │
├─────────────────────────────────────────────────────────────────┤
│ User runs: /clear                                                 │
│                                                                   │
│ SessionStart hook fires:                                          │
│ - Detects checkpoint file                                         │
│ - Outputs checkpoint content as system message                   │
│ - Deletes checkpoint file                                         │
│                                                                   │
│ User sees checkpoint context, says "continue" to resume          │
│ MCPs: Reduced (disabled ones not loaded)                          │
│ Context: Fresh (only checkpoint + CLAUDE.md + system)            │
└─────────────────────────────────────────────────────────────────┘
```

---

## Testing Plan

> **VALIDATED 2026-01-07**: `/clear` respects `disabledMcpServers`. Single workflow confirmed.

### Test 1: MCP Disable Script ✅ PASSED

```bash
# Before
/mcp  # Shows all MCPs

# Action
.claude/scripts/disable-mcps.sh fetch

# Verify config changed
jq '.projects["/Users/aircannon/Claude/Jarvis"].disabledMcpServers' ~/.claude.json
# Expected: fetch in array

# After /clear
/clear
/mcp  # fetch shows as "disabled"
```

### Test 2: MCP Enable Script ✅ PASSED

```bash
# Action
.claude/scripts/enable-mcps.sh fetch

# After /clear
/clear
/mcp  # fetch shows as "connected"
```

### Test 3: Full Workflow (Pending)

1. Run /checkpoint with MCP reduction
2. Verify checkpoint file created
3. Verify disabledMcpServers updated
4. Run /exit-session
5. Run /clear
6. Verify checkpoint content appears in system message
7. Verify checkpoint file deleted
8. Verify disabled MCPs not in /mcp list
9. Run /context-budget to confirm reduced usage

### Test 4: Re-enable After Work Complete (Pending)

1. Complete work that needed reduced MCPs
2. Run /exit-session
3. Run enable-mcps.sh to restore full set
4. Run /clear
5. Verify MCPs restored

---

## Files Created/Updated

### Scripts Created ✅

| File | Purpose | Status |
|------|---------|--------|
| `.claude/scripts/disable-mcps.sh` | Disable MCPs by modifying config | ✅ Created |
| `.claude/scripts/enable-mcps.sh` | Enable MCPs by modifying config | ✅ Created |
| `.claude/scripts/list-mcp-status.sh` | Show MCP status | ✅ Created |

### Files to Update

| File | Change |
|------|--------|
| `.claude/commands/checkpoint.md` | Add MCP evaluation + disable option |
| `.claude/commands/smart-checkpoint.md` | Remove or redirect to /checkpoint |
| `.claude/commands/soft-restart.md` | Remove or redirect to /checkpoint |
| `.claude/context/patterns/automated-context-management.md` | Single workflow, no paths |

---

## Success Criteria

### MVP (Minimum Viable Product)

- [x] disable-mcps.sh works and modifies config correctly ✅
- [x] enable-mcps.sh works and restores MCPs ✅
- [x] /clear respects disabledMcpServers ✅
- [ ] SessionStart hook loads checkpoint after /clear
- [ ] Full workflow achieves 20%+ context reduction

### Full Solution

- [ ] /checkpoint command integrates MCP evaluation
- [ ] Tier 2 MCPs automatically disabled based on next steps
- [ ] Context budget stays below 80% through automation
- [ ] User intervention limited to: approve MCP changes, run /exit-session, run /clear

---

## Related Documentation

- `.claude/context/patterns/automated-context-management.md`
- `.claude/context/patterns/context-budget-management.md`
- `.claude/reports/mcp-load-unload-test-procedure.md`
- `~/.claude.json` (config file with disabledMcpServers)

---

*PR-8.3.1 Revised Implementation Strategy*
*Discovery: disabledMcpServers array in ~/.claude.json*
*Updated: 2026-01-07*
