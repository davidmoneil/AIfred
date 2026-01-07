# Automated Context Management Pattern

**Created**: 2026-01-07
**PR Reference**: PR-8.4 / PR-9.2
**Status**: Active
**Updated**: 2026-01-07 (Two-path soft restart system)

---

## Problem Statement

When context exceeds threshold (~80%), Claude Code enters degraded mode where:
- Autocompaction triggers, losing conversation nuance
- User gets "ambushed" by sudden context compression
- Manual intervention required to manage MCP load

**Key Discovery (2026-01-07)**: MCP removal is CONFIG-ONLY. Tools remain functional until session restart. Therefore, context optimization requires a controlled restart workflow.

**Key Discovery (2026-01-07)**: The `/clear` command triggers `SessionStart` with `source="clear"`. This allows checkpoint loading after `/clear` without a full process restart.

---

## Solution: Two-Path Soft Restart (`/soft-restart`)

The `/soft-restart` command provides two restart paths:

| Path | Method | Token Savings | MCP Reduction |
|------|--------|---------------|---------------|
| A (Soft) | `/clear` | ~16K | No (same process) |
| B (Hard) | `exit` + `claude` | ~47K | Yes (new process) |

### Path A: Soft Restart (Conversation Only)

For when you just need fresh conversation but MCPs are fine:
1. Run `/soft-restart` → choose Path A
2. Command creates `.soft-restart-checkpoint.md`
3. Run `/clear`
4. `SessionStart` hook fires with `source="clear"`
5. Hook detects checkpoint file, loads context
6. User says "continue" to resume

### Path B: Hard Restart (With MCP Reduction)

For maximum token savings including MCP reduction:
1. Run `/soft-restart` → choose Path B
2. Command creates checkpoint AND modifies MCP config
3. Type `exit` or Ctrl+C
4. Run `claude` to start new session
5. `SessionStart` hook fires with `source="startup"`
6. Hook loads checkpoint, MCPs already reduced

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    CONTEXT THRESHOLD DETECTION                   │
├─────────────────────────────────────────────────────────────────┤
│  Triggers:                                                       │
│  1. PreCompact hook (autocompaction about to occur)             │
│  2. Manual /soft-restart command                                │
│  3. /context-budget showing WARNING/CRITICAL                    │
└─────────────────────────────────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────┐
│                    /soft-restart COMMAND                         │
├─────────────────────────────────────────────────────────────────┤
│  1. Capture current work state                                  │
│  2. Write checkpoint: .claude/context/.soft-restart-checkpoint.md│
│  3. Update session-state.md with checkpoint info                │
│  4. Git commit (no push)                                        │
│  5. User chooses Path A or Path B                               │
└─────────────────────────────────────────────────────────────────┘
                               │
              ┌────────────────┴────────────────┐
              ▼                                 ▼
┌─────────────────────────────┐ ┌─────────────────────────────────┐
│     PATH A: SOFT            │ │     PATH B: HARD                │
├─────────────────────────────┤ ├─────────────────────────────────┤
│ No MCP config changes       │ │ MCP config updated:             │
│                             │ │   claude mcp remove <tier2>    │
│ User runs: /clear           │ │                                 │
│                             │ │ User runs: exit + claude        │
│ SessionStart fires with     │ │                                 │
│   source="clear"            │ │ SessionStart fires with         │
│                             │ │   source="startup"              │
│ MCPs: Still loaded          │ │                                 │
│ Savings: ~16K               │ │ MCPs: Reduced per evaluation    │
└─────────────────────────────┘ │ Savings: ~47K                   │
              │                 └─────────────────────────────────┘
              │                                 │
              └────────────────┬────────────────┘
                               ▼
┌─────────────────────────────────────────────────────────────────┐
│                    SESSION RESUME                                │
├─────────────────────────────────────────────────────────────────┤
│  1. session-start.js checks for .soft-restart-checkpoint.md    │
│  2. If found: displays checkpoint context, clears file          │
│  3. User says "continue" to resume work                         │
│  4. Context budget now within healthy range                     │
└─────────────────────────────────────────────────────────────────┘
```

---

## Component Specifications

### 1. Enhanced PreCompact Hook (`pre-compact.js`)

Enhance existing hook to:
- Detect autocompaction trigger
- Offer smart-checkpoint option
- If accepted, run full workflow

### 2. Smart Checkpoint Command (`/smart-checkpoint`)

New command that:
- Can be run manually at any time
- Runs MCP evaluation
- Executes soft-exit
- Adjusts MCP config
- Signals restart

### 3. MCP Evaluation Logic

Reuses `session-start.js` keyword-MCP mapping:

```javascript
const WORK_TYPE_MCP_MAP = {
  'PR': ['github'],
  'research': ['context7', 'duckduckgo'],
  'design': ['sequential-thinking'],
  // ... etc
};

function evaluateMcps(nextSteps, priorities) {
  // 1. Identify keywords in next steps
  // 2. Map to required MCPs
  // 3. Return { keep: [...], drop: [...] }
}
```

### 4. MCP Config Adjuster

```bash
# Drop non-essential Tier 2 MCPs
claude mcp remove time -s local
claude mcp remove context7 -s local
claude mcp remove sequential-thinking -s local
# Keep: github (if PR work upcoming)
```

### 5. Restart Orchestration

**macOS Auto-Restart Script** (optional):
```bash
#!/bin/bash
# .claude/scripts/restart-session.sh
cd /Users/aircannon/Claude/Jarvis
osascript -e 'tell application "Terminal" to do script "cd /Users/aircannon/Claude/Jarvis && claude"'
exit 0
```

---

## MCP Tier Reference

### Tier 1: Always Keep
| MCP | Remove Command |
|-----|----------------|
| memory | Never remove |
| filesystem | Never remove |
| fetch | Never remove |
| git | Never remove |

### Tier 2: Evaluate for Next Steps
| MCP | Keep If | Remove Command |
|-----|---------|----------------|
| github | PR/issue work | `claude mcp remove github -s local` |
| context7 | Research/docs | `claude mcp remove context7 -s local` |
| sequential-thinking | Design/planning | `claude mcp remove sequential-thinking -s local` |
| time | Scheduling | `claude mcp remove time -s local` |

### Tier 3: Never Auto-Load
- Playwright, BrowserStack, Slack, etc.
- Only enabled by explicit trigger commands

---

## Integration Points

### session-state.md Structure

```yaml
## Checkpoint Info (Smart Checkpoint)

checkpoint_type: smart-checkpoint
checkpoint_reason: context threshold (85%)
checkpoint_timestamp: 2026-01-07T15:30:00Z

### MCP Recommendation
- **Keep**: github (PR-8.4 work continues)
- **Drop**: time, context7, sequential-thinking

### Next Steps After Restart
1. Continue PR-8.4 implementation
2. Test /smart-checkpoint command
```

### Hook Chain

```
PreCompact → Detect threshold → Offer smart-checkpoint
     ↓
/smart-checkpoint → MCP evaluation → Soft exit → Config adjust → Restart signal
     ↓
SessionStart → Load checkpoint context → Resume work
```

---

## Usage Scenarios

### Scenario 1: Automatic (PreCompact Trigger)

```
[System detects autocompaction imminent]
╔══════════════════════════════════════════════════════════════╗
║              CONTEXT THRESHOLD WARNING                        ║
╚══════════════════════════════════════════════════════════════╝

Context usage: ~85% (autocompaction imminent)

Recommended Action: Run /smart-checkpoint to:
1. Save current work state
2. Reduce MCP load (drop: time, context7)
3. Restart with clean context

Run /smart-checkpoint now? (y/n)
```

### Scenario 2: Manual Trigger

```bash
# User runs command proactively
> /smart-checkpoint

Evaluating MCP needs for next steps...

Next Steps Analysis:
- "Continue PR-8.4 implementation" → github needed
- "Test validation harness" → no special MCP

MCP Recommendation:
- KEEP: Tier 1 + github
- DROP: time, context7, sequential-thinking (~16K tokens saved)

Proceed with smart checkpoint? (y/n)
```

---

## Related Documentation

- @.claude/context/patterns/context-budget-management.md
- @.claude/commands/checkpoint.md
- @.claude/commands/end-session.md
- @.claude/reports/mcp-load-unload-test-procedure.md

---

*Automated Context Management Pattern — PR-8.4 / PR-9.2*
