---
description: Jarvis Intelligent Context Management - manual compaction trigger
allowed-tools: Read, Write, Edit, Bash
---

# Smart Compact

Jarvis Intelligent Context Management (JICM) - manual compaction trigger.

**Purpose**: Proactive context management when auto-compact is OFF.

## Usage

```
/smart-compact              # Assess context and recommend action
/smart-compact --force      # Create checkpoint immediately (skip assessment)
/smart-compact --full       # Full automation: checkpoint + disable MCPs + clear
```

## What It Does

### Assessment Mode (default)

1. **Read context estimate** from `.claude/logs/context-estimate.json`
2. **Run /context** to get actual percentage
3. **Compare** estimate vs actual
4. **Recommend** action based on actual percentage

### Force Mode (--force)

1. **Skip assessment** — create checkpoint immediately
2. **Update session-state.md** with current work
3. **Show next steps**

### Full Mode (--full)

1. **Create checkpoint** with work state
2. **Disable Tier 2 MCPs** (github, context7, sequential-thinking)
3. **Signal auto-clear watcher** to send /clear
4. **Context resets** and SessionStart loads checkpoint

## Assessment

First, check the context estimate:

```bash
cat .claude/logs/context-estimate.json 2>/dev/null || echo '{"totalTokens": 30000, "percentage": 15}'
```

Then run Claude Code's `/context` command to get actual token count.

Compare:
- If actual < 50%: "Context healthy, no action needed"
- If actual 50-74%: "Context moderate, checkpoint recommended before heavy work"
- If actual >= 75%: "Threshold exceeded — run /smart-compact --full"

## Checkpoint Creation

When creating a checkpoint:

1. **Extract from session-state.md**:
   - Current task/status
   - Any blockers
   - Next steps

2. **Write checkpoint file** at `.claude/context/.soft-restart-checkpoint.md`:

```markdown
# Manual Smart Compact Checkpoint

**Created**: [timestamp]
**Reason**: /smart-compact [mode]
**Actual Context**: [percentage]%

## Work State
[Extracted from session-state.md]

## Next Steps After Restart
1. Review session-state.md for current work status
2. Check current-priorities.md for next tasks
3. Continue from where you left off

## MCPs to Re-enable (if --full)
- [List any disabled MCPs]
```

## MCP Reduction (--full mode)

Disable Tier 2 MCPs to reduce context on restart:

```bash
.claude/scripts/disable-mcps.sh github context7 sequential-thinking
```

This reduces context by ~20-30K tokens.

## Clear Signal (--full mode)

Signal the jarvis-watcher:

```bash
echo "$(date -u +%Y-%m-%dT%H:%M:%SZ)" > .claude/context/.auto-clear-signal
```

The jarvis-watcher.sh will detect this and send `/clear` to the Claude Code window.

## Post-Clear Flow

After `/clear`:
1. SessionStart hook fires
2. Detects checkpoint file
3. Loads checkpoint context
4. Deletes checkpoint file
5. Resets context-estimate.json to baseline
6. Clears .compaction-in-progress flag
7. Claude continues from checkpoint

## Output Format

```
Smart Compact Assessment
━━━━━━━━━━━━━━━━━━━━━━━━

📊 Estimated: ~[X]% ([Y]K tokens)
📊 Actual: [Z]% ([W]K tokens)

Status: [HEALTHY|WARNING|CRITICAL]

Recommendation:
- [Action based on status]

[If --full was triggered or recommended:]

Checkpoint created: .claude/context/.soft-restart-checkpoint.md
MCPs disabled: github, context7, sequential-thinking
Clear signal sent to watcher

Next: Watcher will send /clear in ~3 seconds
```

## Loop Prevention

This command includes safeguards:

1. **Check .compaction-in-progress** — if exists, abort (already handling)
2. **Set flag before actions** — prevents re-triggering
3. **SessionStart clears flag** — after /clear completes
4. **Excluded from accumulator** — checkpoint writes don't add to estimate

## Related Documentation

- @.claude/context/patterns/automated-context-management.md
- @.claude/context/patterns/context-budget-management.md
- @.claude/context/designs/jicm-architecture-solutions.md
- @.claude/scripts/jarvis-watcher.sh (v3: statusline JSON API)
- @.claude/hooks/precompact-analyzer.js (preservation manifest)
- @.claude/agents/context-compressor.md (AI-powered compression)

---

*JICM: Jarvis Intelligent Context Management*
*Created: 2026-01-09 | Updated: 2026-01-23 (v3.0.0)*
