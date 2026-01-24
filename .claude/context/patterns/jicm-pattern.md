# JICM Pattern — Jarvis Intelligent Context Management

**Version**: 3.0.0
**Created**: 2026-01-16
**Updated**: 2026-01-23
**Component**: AC-04 JICM
**PR**: PR-12.4, JICM v3.0.0

---

## Overview

JICM (Jarvis Intelligent Context Management) is the pattern for managing context window resources proactively to prevent auto-compression and ensure work continuity. The core principle is that context exhaustion triggers **continuation**, not session termination.

### Core Principle

**Context exhaustion is a pause point, not a stop point.** When context fills up, JICM:
1. Creates a checkpoint preserving essential state
2. Triggers a controlled /clear
3. Resumes work seamlessly in the fresh context

This is distinct from Claude Code's auto-compression, which can lose important context. JICM provides controlled, predictable context management.

---

## 1. Threshold System

### Five Context Levels

```
┌─────────────────────────────────────────────────────────────────────┐
│                    JICM THRESHOLD LEVELS                             │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  Level       │ Range    │ Status    │ Action                        │
│  ──────────────────────────────────────────────────────────────────│
│  HEALTHY     │ 0-50%    │ Green     │ Normal operation              │
│  CAUTION     │ 50-70%   │ Yellow    │ Log warning, suggest offload  │
│  WARNING     │ 70-85%   │ Orange    │ Auto-offload, reduce MCPs     │
│  CRITICAL    │ 85-95%   │ Red       │ Checkpoint, trigger clear     │
│  EMERGENCY   │ >95%     │ Critical  │ Force clear, essentials only  │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### Threshold Response Matrix

| Level | User Notification | Auto Actions | Manual Actions |
|-------|-------------------|--------------|----------------|
| HEALTHY | None | None | None needed |
| CAUTION | Console warning | Log status | Consider checkpoint |
| WARNING | "Context high" message | Disable Tier 2 MCPs, create soft checkpoint | Review context usage |
| CRITICAL | "Checkpoint recommended" | Full checkpoint, prepare /clear | Approve checkpoint |
| EMERGENCY | "Forcing checkpoint" | Immediate checkpoint + /clear | None (automatic) |

---

## 2. Monitoring Architecture (v3.0.0)

### Context Tracking — Statusline JSON API

**JICM v3.0.0** uses the official Claude Code statusline JSON API for authoritative context usage data, replacing the previous token estimation approach.

```
┌─────────────────────────────────────────────────────────────────────┐
│                    CONTEXT TRACKING ARCHITECTURE (v3)               │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │  Claude Code Statusline (Official API)                         │  │
│  │                                                                 │  │
│  │  Source: ~/.claude/logs/statusline-input.json                  │  │
│  │  Updated: Every turn by Claude Code                            │  │
│  │                                                                 │  │
│  │  {                                                              │  │
│  │    "context_window": {                                         │  │
│  │      "used_percentage": 42,        ← Authoritative             │  │
│  │      "remaining_percentage": 58,                               │  │
│  │      "context_window_size": 200000,                            │  │
│  │      "total_input_tokens": 84000,                              │  │
│  │      "total_output_tokens": 42000                              │  │
│  │    }                                                            │  │
│  │  }                                                              │  │
│  └───────────────────────────────────────────────────────────────┘  │
│                              │                                      │
│                              ▼                                      │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │  jarvis-watcher.sh (v3.0.0)                                    │  │
│  │                                                                 │  │
│  │  Polls: Every 30 seconds                                       │  │
│  │  Actions:                                                       │  │
│  │    1. Read used_percentage from statusline JSON                │  │
│  │    2. Check against 80% threshold                              │  │
│  │    3. If exceeded: trigger JICM sequence                       │  │
│  │    4. Log to context-estimate.json                             │  │
│  │                                                                 │  │
│  └───────────────────────────────────────────────────────────────┘  │
│                                                                      │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │  /context-budget Command (User Dashboard)                       │  │
│  │                                                                 │  │
│  │  Output format:                                                 │  │
│  │                                                                 │  │
│  │  ## Context Budget Status                                       │  │
│  │                                                                 │  │
│  │  **Status**: WARNING (72.5%)                                   │  │
│  │                                                                 │  │
│  │  | Category        | Tokens  | % of Total |                    │  │
│  │  |-----------------|---------|------------|                    │  │
│  │  | Conversation    | 95,000  | 47.5%      |                    │  │
│  │  | MCP Tools       | 32,000  | 16.0%      |                    │  │
│  │  | File Contents   | 18,000  | 9.0%       |                    │  │
│  │  | **Total**       | 145,000 | 72.5%      |                    │  │
│  │                                                                 │  │
│  │  **Recommendation**: Consider /checkpoint                       │  │
│  └───────────────────────────────────────────────────────────────┘  │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### Token Tracking: Actual vs Estimated

JICM uses two sources of token information:

**1. Actual Token Count (Reliable)**

The actual token count is captured from Claude Code's status line via tmux:

```bash
# .claude/scripts/capture-token-count.sh
# Output: "120916" (total tokens from status line)

# The status line shows: "120,916 tokens" at bottom of UI
```

This is accurate but only provides TOTAL tokens, not breakdown by category.

**2. Estimated Token Count (Approximate)**

The context-accumulator hook estimates tokens based on tool usage:

```javascript
// Estimation heuristics
const TOKENS_PER_CHAR = 0.25;  // ~4 chars per token average

function estimateToolCost(toolResult) {
  const resultLength = JSON.stringify(toolResult).length;
  return Math.ceil(resultLength * TOKENS_PER_CHAR);
}

// Fixed costs (approximate)
const MCP_TOOL_SCHEMA_COST = 500;   // Per tool definition
const CONVERSATION_OVERHEAD = 100;  // Per message
const FILE_READ_OVERHEAD = 50;      // Per file read
```

**IMPORTANT LIMITATION: Detailed Breakdown Not Programmatically Available**

The `/context` command in Claude Code shows a detailed breakdown by category:
- System prompt %
- Files %
- Conversation %
- Tools %

However, this breakdown is **ephemeral** - it renders as a UI overlay and does not persist in:
- Session history files
- Stats cache files
- Scrollback buffer (disappears immediately)

**What JICM CAN track:**
- Total token count (from status line)
- Estimated token accumulation per tool call
- Threshold crossings

**What JICM CANNOT track programmatically:**
- Breakdown by category (files vs conversation vs system)
- Which files contribute most to context
- MCP tool schema costs individually

**Workaround**: For detailed breakdown, users must run `/context` manually in the Claude Code UI and visually inspect the output.

---

## 3. Checkpoint System

### Checkpoint Workflow

```
┌─────────────────────────────────────────────────────────────────────┐
│                    CHECKPOINT WORKFLOW                               │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  1. DETECT THRESHOLD CROSSING                                        │
│     └── context-accumulator.js detects WARNING/CRITICAL              │
│                                                                      │
│  2. GATHER ESSENTIAL STATE                                           │
│     ├── Current todo list (TodoWrite state)                         │
│     ├── Active work description                                     │
│     ├── Key decisions made                                          │
│     ├── Blockers and status                                         │
│     ├── Files modified                                              │
│     └── Wiggum Loop state (if active)                               │
│                                                                      │
│  3. GENERATE CHECKPOINT                                              │
│     ├── Create .checkpoint.md with essential state                  │
│     └── (Optionally) Archive full context to archives/              │
│                                                                      │
│  4. PREPARE FOR CONTINUATION                                         │
│     ├── Evaluate MCPs for next session                              │
│     ├── Run disable-mcps.sh for non-essential MCPs                  │
│     └── Update session-state.md                                     │
│                                                                      │
│  5. TRIGGER /CLEAR                                                   │
│     ├── Signal auto-clear watcher                                   │
│     └── Or instruct user to run /clear                              │
│                                                                      │
│  6. RESUME (in new context)                                          │
│     ├── AC-01 Self-Launch detects checkpoint                        │
│     ├── Load checkpoint context                                     │
│     └── Continue work from checkpoint state                         │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### Checkpoint File Format

```markdown
# Context Checkpoint

**Created**: 2026-01-16T14:30:00.000Z
**Reason**: Context at WARNING threshold (72.5%)
**Session**: PR-12.4 implementation

---

## Active Work

**Task**: Implementing AC-04 JICM component
**Wiggum Pass**: 2
**Status**: Creating pattern document

### Todos
- [x] Review PR-12.4 requirements
- [x] Create AC-04 component specification
- [ ] Create jicm-pattern.md ← IN PROGRESS
- [ ] Update documentation references

---

## Key Decisions Made

1. JICM uses 5-tier threshold system (HEALTHY → EMERGENCY)
2. Checkpoint preserves essential state, cuts verbose outputs
3. No MCP dependencies (JICM must be able to disable MCPs)

---

## Blockers

None currently.

---

## Files Modified This Session

| File | Purpose |
|------|---------|
| `.claude/context/components/AC-04-jicm.md` | Component spec |
| `.claude/context/patterns/jicm-pattern.md` | Pattern doc (in progress) |

---

## Next Steps After Restart

1. Resume at "Create jicm-pattern.md" todo
2. Complete pattern document
3. Update documentation references
4. Continue to PR-12.5

---

## MCP Configuration

**Disabled for restart**: github, context7, sequential-thinking
**Keep enabled**: memory, filesystem, git, fetch

---

*Checkpoint generated by JICM (AC-04)*
```

### Checkpoint Location

```
.claude/context/.checkpoint.md      ← Active checkpoint (detected by AC-01)
.claude/archives/
  └── checkpoint-2026-01-16-143000.md  ← Archived checkpoints
```

---

## 4. Context Offloading

### MCP Offloading

When context reaches WARNING level, JICM can disable non-essential MCPs:

```
┌─────────────────────────────────────────────────────────────────────┐
│                    MCP OFFLOADING                                    │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  MCP TIERS:                                                          │
│                                                                      │
│  Tier 1 — NEVER DISABLE                                              │
│  ├── memory (persistent storage)                                    │
│  ├── filesystem (file operations)                                   │
│  ├── git (version control)                                          │
│  └── fetch (web access)                                             │
│                                                                      │
│  Tier 2 — DISABLE AT WARNING                                         │
│  ├── github (API operations)                                        │
│  ├── context7 (documentation)                                       │
│  ├── sequential-thinking (reasoning)                                │
│  ├── datetime (time queries)                                        │
│  └── desktop-commander (system ops)                                 │
│                                                                      │
│  Tier 3 — DISABLE EARLY (heavy tools)                                │
│  ├── playwright (browser automation)                                │
│  ├── chroma (vector DB)                                             │
│  └── gptresearcher (research)                                       │
│                                                                      │
│  OFFLOAD SCRIPT:                                                     │
│  $ .claude/scripts/disable-mcps.sh github context7 sequential-thinking
│                                                                      │
│  Token savings: ~15-25K tokens per session                           │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### Content Summarization

When preserving file content in checkpoints, summarize rather than copy:

```
INSTEAD OF:
  "File contents: [500 lines of code]"

USE:
  "Modified src/auth.ts:
   - Added validateToken() function (lines 45-78)
   - Updated login() to use new validation
   - 3 new imports added"
```

---

## 5. Liftover Protocol

### Context Liftover

Liftover ensures seamless continuation across the compression boundary:

```
┌─────────────────────────────────────────────────────────────────────┐
│                    LIFTOVER PROTOCOL                                 │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  BEFORE /CLEAR:                                                      │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │  Full context with:                                            │  │
│  │  - Complete conversation history                               │  │
│  │  - All tool results (raw)                                      │  │
│  │  - All file contents read                                      │  │
│  │  - All MCP tool schemas                                        │  │
│  │  Total: ~150K tokens                                           │  │
│  └───────────────────────────────────────────────────────────────┘  │
│                              │                                       │
│                    checkpoint │                                       │
│                              ▼                                       │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │  CHECKPOINT FILE (~2-5K tokens):                               │  │
│  │  - Task description                                            │  │
│  │  - Todo list with status                                       │  │
│  │  - Key decisions                                               │  │
│  │  - Blockers                                                    │  │
│  │  - Files modified (paths, not content)                         │  │
│  │  - Next steps                                                  │  │
│  └───────────────────────────────────────────────────────────────┘  │
│                              │                                       │
│                       /clear │                                       │
│                              ▼                                       │
│  AFTER RESTART:                                                      │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │  Fresh context with:                                           │  │
│  │  - Checkpoint loaded (~2-5K)                                   │  │
│  │  - Essential MCPs only (~15K)                                  │  │
│  │  - CLAUDE.md (~3K)                                             │  │
│  │  Total: ~20-25K tokens (HEALTHY)                               │  │
│  │                                                                │  │
│  │  Work continues from checkpoint state                          │  │
│  └───────────────────────────────────────────────────────────────┘  │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### Liftover Verification

After restart, verify liftover succeeded:

```javascript
// Liftover checklist
const liftoverChecks = [
  'Checkpoint file detected and loaded',
  'Todo list restored to correct state',
  'Work context understood',
  'Files can be accessed',
  'MCPs functioning (Tier 1)'
];

// If any fail, ask user for clarification
```

---

## 6. Integration with Wiggum Loop

### Context Check Step

JICM integrates with Wiggum Loop as Step 5 (Context Check):

```
┌─────────────────────────────────────────────────────────────────────┐
│                    WIGGUM LOOP STEP 5: CONTEXT CHECK                 │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  BEFORE STEP 6 (CONTINUE/COMPLETE):                                  │
│                                                                      │
│  1. Query JICM for context status                                   │
│     └── Read context-estimate.json                                  │
│                                                                      │
│  2. Evaluate threshold                                               │
│     ├── HEALTHY/CAUTION → Continue to Step 6                        │
│     ├── WARNING → Checkpoint, may continue or pause                 │
│     └── CRITICAL/EMERGENCY → Checkpoint + /clear                    │
│                                                                      │
│  3. If /clear triggered:                                             │
│     ├── Save Wiggum Loop state in checkpoint                        │
│     ├── Include pass number and findings                            │
│     └── Loop RESUMES after restart, not restarts                    │
│                                                                      │
│  KEY PRINCIPLE:                                                      │
│  Context check is a PAUSE POINT, not an INTERRUPT.                  │
│  The loop continues after compression, it doesn't stop.             │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### Loop State Preservation

```json
{
  "wiggum_state": {
    "task_id": "uuid",
    "task_description": "Implement AC-04 JICM",
    "current_pass": 2,
    "passes_completed": [
      {
        "pass": 1,
        "issues_found": 3,
        "issues_fixed": 3
      }
    ],
    "paused_at": "2026-01-16T14:30:00.000Z",
    "paused_reason": "JICM context threshold",
    "resume_at_step": 1
  }
}
```

---

## 7. Emergency Procedures

### Emergency Compression (>95%)

When context exceeds 95%, JICM must act immediately:

```
┌─────────────────────────────────────────────────────────────────────┐
│                    EMERGENCY COMPRESSION                             │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  TRIGGERED AT: >95% context usage                                    │
│                                                                      │
│  ACTIONS (Immediate, minimal user interaction):                      │
│                                                                      │
│  1. ALERT                                                            │
│     └── "Context critical. Forcing checkpoint."                     │
│                                                                      │
│  2. RAPID CHECKPOINT                                                 │
│     ├── Todo list only (essential)                                  │
│     ├── Current task description                                    │
│     ├── Key file paths (not contents)                               │
│     └── Skip verbose summaries                                      │
│                                                                      │
│  3. DISABLE ALL TIER 2+3 MCPs                                        │
│     └── Only keep: memory, filesystem, git, fetch                   │
│                                                                      │
│  4. TRIGGER /CLEAR                                                   │
│     └── Via watcher or direct instruction                           │
│                                                                      │
│  5. RESUME                                                           │
│     └── Self-Launch with minimal checkpoint                         │
│                                                                      │
│  RECOVERY:                                                           │
│  If essential context was lost, ask user:                           │
│  "Checkpoint was minimal due to emergency. Please confirm:          │
│   - Current task: [X]                                               │
│   - Todos: [list]                                                   │
│   Correct? Or provide additional context."                          │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### Manual Recovery

If automated recovery fails:

```markdown
## Manual JICM Recovery

If you see this, automated context management failed.

### Steps:
1. Check `.claude/context/.checkpoint.md` for saved state
2. If no checkpoint, check `.claude/context/session-state.md`
3. Review recent git commits for context
4. Ask user: "What were we working on?"

### Re-enable MCPs:
$ .claude/scripts/enable-mcps.sh github context7
```

---

## 8. Configuration

### autonomy-config.yaml Settings

```yaml
components:
  AC-04-jicm:
    enabled: true
    settings:
      # Threshold overrides (percent)
      threshold_caution: 50
      threshold_warning: 70
      threshold_critical: 85
      threshold_emergency: 95

      # Checkpoint options
      checkpoint_strategy: rich  # rich | lean
      archive_checkpoints: true
      archive_retention_days: 30

      # MCP management
      auto_disable_mcps: true
      tier2_mcps:
        - github
        - context7
        - sequential-thinking
      tier3_mcps:
        - playwright
        - chroma
        - gptresearcher

      # Monitoring
      check_frequency: 10  # Every N tool calls
      emit_metrics: true
```

### Environment Variables

| Variable | Default | Purpose |
|----------|---------|---------|
| `JARVIS_DISABLE_AC04` | false | Disable JICM entirely |
| `JARVIS_JICM_THRESHOLD` | 70 | Override WARNING threshold |
| `JARVIS_JICM_CHECKPOINT` | rich | Checkpoint strategy |
| `JARVIS_JICM_AUTO_CLEAR` | true | Auto-trigger /clear |

---

## 9. Metrics and Dashboards

### /context-budget Dashboard

The user-facing command shows:

```
## Context Budget Status

**Session**: 2026-01-16 14:30
**Status**: WARNING (72.5%)

### Usage Breakdown

| Category        | Tokens    | % of Budget |
|-----------------|-----------|-------------|
| Conversation    | 95,000    | 47.5%       |
| MCP Tools       | 32,000    | 16.0%       |
| File Contents   | 18,000    | 9.0%        |
| System          | 10,000    | 5.0%        |
| **Total**       | **155,000** | **72.5%** |

### Threshold Status

[=========>          ] 72.5%

HEALTHY ──── CAUTION ──── WARNING ──── CRITICAL ──── EMERGENCY
  0%          50%         70%*         85%          95%

### Recommendations

- Consider running /checkpoint to save state
- Disable non-essential MCPs with: /context-checkpoint
- Current Tier 2 MCPs: github, context7 (6 tools)

### Quick Actions

- `/checkpoint` — Save current state
- `/context-checkpoint` — Full checkpoint workflow
- `disable-mcps.sh github context7` — Manual MCP disable
```

### jicm-status (Internal)

The automation-facing status:

```json
{
  "status": "WARNING",
  "percent": 72.5,
  "tokens_used": 155000,
  "tokens_available": 59000,
  "action_required": "checkpoint_recommended",
  "mcps_disableable": ["github", "context7", "sequential-thinking"],
  "estimated_savings": 18000
}
```

---

## 10. Examples

### Normal Operation

```
Session starts at 5% context.
Work proceeds through Wiggum Loop.
At 55% (CAUTION): Log "Context at 55%, consider checkpoint later"
At 72% (WARNING):
  - Message: "Context at WARNING level"
  - Disable Tier 2 MCPs
  - Create soft checkpoint
Work continues.
At 88% (CRITICAL):
  - Message: "Context CRITICAL. Creating checkpoint."
  - Full checkpoint created
  - /clear triggered
Session restarts, work continues from checkpoint.
```

### Emergency Recovery

```
Context jumps from 80% to 97% (large file read).
EMERGENCY triggered:
  - Alert: "Context critical!"
  - Rapid checkpoint (essentials only)
  - Disable all Tier 2+3 MCPs
  - Force /clear
After restart:
  - Checkpoint loaded
  - Jarvis: "Recovered from emergency. Confirming state..."
  - Work continues
```

---

## 11. Testing

### Test Scenarios

| Scenario | Setup | Expected Result |
|----------|-------|-----------------|
| CAUTION threshold | Simulate 55% context | Warning logged |
| WARNING threshold | Simulate 75% context | MCPs disabled, checkpoint |
| CRITICAL threshold | Simulate 90% context | Full checkpoint, /clear |
| EMERGENCY | Simulate 97% context | Rapid checkpoint, force /clear |
| Liftover | Create checkpoint, restart | Work continues |
| No tracker | Remove context-accumulator | Graceful degradation |

### Validation Commands

```bash
# Check JICM state
cat .claude/logs/context-estimate.json | jq .

# Check threshold status
.claude/scripts/list-mcp-status.sh

# Manual checkpoint test
cat .claude/context/.checkpoint.md

# Verify metrics
cat .claude/metrics/AC-04-jicm.jsonl | tail -5
```

---

*JICM Pattern — Jarvis Phase 6 PR-12.4*
