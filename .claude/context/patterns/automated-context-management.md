# Automated Context Management Pattern

**Created**: 2026-01-07
**PR Reference**: PR-8.3 / PR-9.2
**Status**: READY FOR IMPLEMENTATION
**Updated**: 2026-01-07 (Revised based on disabledMcpServers discovery)

---

## Problem Statement

When context exceeds threshold (~80%), Claude Code enters degraded mode where:
- Autocompaction triggers, losing conversation nuance
- User gets "ambushed" by sudden context compression
- Manual intervention required to manage MCP load

**Key Discovery (2026-01-07)**: MCP disabled state is stored in `~/.claude.json` under `projects.<path>.disabledMcpServers[]`. This array can be modified programmatically to control which MCPs load on session start.

---

## Solution: Checkpoint + Disable + Restart

### Core Mechanism

```json
// ~/.claude.json structure
{
  "projects": {
    "/Users/aircannon/Claude/Jarvis": {
      "mcpServers": { /* registered MCPs */ },
      "disabledMcpServers": ["context7", "github", "git", ...]
    }
  }
}
```

- **To disable**: Add MCP name to `disabledMcpServers` array
- **To enable**: Remove MCP name from array
- **Effect**: Changes apply after `/clear` (validated 2026-01-07)

### Workflow

```
TRIGGER → CHECKPOINT → DISABLE MCPs → EXIT-SESSION → /CLEAR → RESUME
```

1. **Trigger**: Context threshold warning (manual or hook-based)
2. **Checkpoint**: Save work state to `.soft-restart-checkpoint.md`
3. **Disable MCPs**: Run script to modify `~/.claude.json`
4. **Exit Session**: Run /exit-session to commit and save state
5. **Clear**: User runs /clear to restart with hooks
6. **Resume**: SessionStart hook loads checkpoint, MCPs reduced

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│ STEP 1: TRIGGER                                                   │
├─────────────────────────────────────────────────────────────────┤
│ Options:                                                          │
│ - Manual: /checkpoint command                                     │
│ - Manual: /context-budget shows CRITICAL                         │
│ - Future: PreCompact hook warns user                              │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│ STEP 2: CHECKPOINT CREATION                                       │
├─────────────────────────────────────────────────────────────────┤
│ 1. Claude gathers current work state                              │
│ 2. Evaluates next steps for MCP requirements                     │
│ 3. Writes: .claude/context/.soft-restart-checkpoint.md           │
│ 4. Updates: session-state.md                                      │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│ STEP 3: MCP DISABLE (User Approves)                               │
├─────────────────────────────────────────────────────────────────┤
│ Script: .claude/scripts/disable-mcps.sh git context7             │
│                                                                   │
│ Action: Adds to disabledMcpServers array in ~/.claude.json       │
│ Effect: MCPs will not load on next session start                  │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│ STEP 4: EXIT SESSION                                              │
├─────────────────────────────────────────────────────────────────┤
│ User runs: /exit-session                                          │
│ - Commits: session-state.md, checkpoint file                     │
│ - Saves: All work state                                           │
│ - Displays: "Run /clear to resume"                                │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│ STEP 5: CLEAR AND RESUME                                          │
├─────────────────────────────────────────────────────────────────┤
│ User runs: /clear                                                 │
│                                                                   │
│ What happens:                                                     │
│ 1. Conversation cleared                                           │
│ 2. SessionStart hook fires                                        │
│ 3. Hook detects checkpoint file                                   │
│ 4. Hook outputs checkpoint as system message                     │
│ 5. Hook deletes checkpoint file (one-time use)                   │
│ 6. MCPs load per config (disabled ones excluded)                  │
│                                                                   │
│ Result:                                                           │
│ - Fresh context (only checkpoint + system)                        │
│ - Reduced MCP load                                                │
│ - User says "continue" to resume work                             │
└─────────────────────────────────────────────────────────────────┘
```

---

## Implementation Components

### 1. MCP Control Scripts

**disable-mcps.sh**:
```bash
#!/bin/bash
PROJECT_PATH="/Users/aircannon/Claude/Jarvis"
CONFIG_FILE="$HOME/.claude.json"

for SERVER in "$@"; do
  jq --arg path "$PROJECT_PATH" --arg server "$SERVER" '
    .projects[$path].disabledMcpServers |= (. + [$server] | unique)
  ' "$CONFIG_FILE" > "$CONFIG_FILE.tmp" && mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
  echo "Disabled: $SERVER"
done
```

**enable-mcps.sh**:
```bash
#!/bin/bash
PROJECT_PATH="/Users/aircannon/Claude/Jarvis"
CONFIG_FILE="$HOME/.claude.json"

for SERVER in "$@"; do
  jq --arg path "$PROJECT_PATH" --arg server "$SERVER" '
    .projects[$path].disabledMcpServers |= (. - [$server])
  ' "$CONFIG_FILE" > "$CONFIG_FILE.tmp" && mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
  echo "Enabled: $SERVER"
done
```

### 2. Enhanced /checkpoint Command

The /checkpoint command should:
1. Capture current work context
2. Evaluate next steps for MCP needs
3. Recommend MCPs to disable
4. If approved, run disable-mcps.sh
5. Create checkpoint file
6. Instruct: "Run /exit-session, then /clear"

### 3. SessionStart Hook

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

---

## MCP Tier Reference

### Tier 1: Never Disable
| MCP | Reason |
|-----|--------|
| memory | Knowledge persistence |
| filesystem | File operations |
| fetch | Web requests |

### Tier 2: Task-Dependent
| MCP | Keep If | Est. Tokens |
|-----|---------|-------------|
| github | PR/issue work planned | ~15K |
| git | Active git operations | ~4K |
| context7 | Documentation research | ~8K |
| sequential-thinking | Complex planning | ~5K |

### Tier 3: Plugin-Managed
| MCP | Format |
|-----|--------|
| Playwright | `plugin:playwright:playwright` |
| GitLab | `plugin:gitlab:gitlab` |

---

## Usage Scenarios

### Scenario 1: Proactive Checkpoint

```
User: Context is getting high, let me checkpoint

> /checkpoint

Claude: Creating checkpoint...

Current work state:
- Implementing PR-8.3.1 context management
- Updated 3 documentation files
- Next: Test disable/enable scripts

MCP Analysis:
- Required for next steps: memory, filesystem, fetch
- Not needed: github, context7, sequential-thinking, git

Recommend disabling: github, context7, sequential-thinking, git
Estimated savings: ~32K tokens

Disable these MCPs? [y/n]

User: y

Claude: Running disable-mcps.sh...
Disabled: github
Disabled: context7
Disabled: sequential-thinking
Disabled: git

Checkpoint saved to: .claude/context/.soft-restart-checkpoint.md

Next steps:
1. Run /exit-session to commit
2. Run /clear to restart with reduced context
3. Say "continue" to resume work
```

### Scenario 2: Re-enable After Work Complete

```
User: Done with documentation, need GitHub for PR

Claude: Running enable-mcps.sh github...
Enabled: github

To load GitHub MCP:
1. Run /exit-session
2. Run /clear
3. GitHub tools will be available
```

---

## Token Savings Estimates

| Scenario | MCPs Disabled | Est. Savings |
|----------|---------------|--------------|
| Documentation work | github, sequential-thinking | ~20K |
| Quick fixes | github, context7, sequential-thinking | ~28K |
| Maximum reduction | all Tier 2 | ~32K |

---

## Files

| File | Purpose |
|------|---------|
| `.claude/scripts/disable-mcps.sh` | Disable MCPs |
| `.claude/scripts/enable-mcps.sh` | Enable MCPs |
| `.claude/scripts/list-mcp-status.sh` | Show MCP state |
| `.claude/context/.soft-restart-checkpoint.md` | Checkpoint file |
| `~/.claude.json` | Config with disabledMcpServers |

---

## Related Documentation

- `.claude/reports/pr-8.3.1-hook-validation-roadmap.md` — Full implementation
- `.claude/reports/mcp-load-unload-test-procedure.md` — Testing details
- `.claude/context/patterns/context-budget-management.md` — Budget tiers

---

*Automated Context Management Pattern*
*Key mechanism: disabledMcpServers array in ~/.claude.json*
*Updated: 2026-01-07*
