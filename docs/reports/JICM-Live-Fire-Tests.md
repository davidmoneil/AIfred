# JICM Live-Fire Test Scenarios (Revised)

**Date**: 2026-01-20 (Updated after Q9-Q21 analysis)
**Purpose**: Ad hoc testing procedures for validating JICM in a second Claude Code terminal

---

## Important Notes from Investigation

1. **Estimation is inaccurate** - JICM estimates will likely be lower than actual context usage
2. **Each terminal has separate context** - But shares the same context-estimate.json file
3. **Watcher must be running** - Check first before any tests
4. **PreCompact and JICM are coupled** - Both write to signal file (to be fixed)

---

## Prerequisites

Before running tests, ensure:

1. You have two Terminal windows open
2. One running Claude Code (the "Primary" session)
3. One available for running test commands (the "Test" terminal)

---

## Test 1: Verify Watcher Is Running

**Purpose**: Confirm the watcher process launched on session start

### Steps (Test Terminal):

```bash
# Check if watcher is running
pgrep -f "auto-clear-watcher.sh"

# Check PID file
cat /Users/aircannon/Claude/Jarvis/.claude/context/.watcher-pid

# Check watcher log
tail -20 /Users/aircannon/Claude/Jarvis/.claude/logs/watcher-launcher.log
```

### Expected Results:
- PID returned from pgrep
- PID file contains matching process ID
- Log shows "Watcher launched" entry

### If Watcher Not Running:
```bash
# Manual launch
CLAUDE_PROJECT_DIR=/Users/aircannon/Claude/Jarvis /Users/aircannon/Claude/Jarvis/.claude/scripts/launch-watcher.sh
```

---

## Test 2: Verify Context Accumulator Tracking

**Purpose**: Confirm token estimation is working (even if inaccurate)

### Steps (Test Terminal):

```bash
# Check current context estimate
cat /Users/aircannon/Claude/Jarvis/.claude/logs/context-estimate.json | jq .

# Watch file in real-time (leave running)
watch -n 1 "cat /Users/aircannon/Claude/Jarvis/.claude/logs/context-estimate.json | jq ."
```

### Steps (Primary Claude Session):
Run a few tool calls:
1. Ask Claude to read a file
2. Ask Claude to search with Grep
3. Ask Claude to run a Bash command

### Expected Results:
- `totalTokens` increases after each tool call
- `toolCalls` counter increments
- `percentage` updates accordingly

### NEW: Compare with Actual Context
After test, run `/context` in Primary session and compare:
- If actual >> estimated, the accumulator is undercounting
- This is expected behavior per investigation findings

---

## Test 3: Estimate vs Reality Check

**Purpose**: Quantify the gap between JICM estimates and actual context

### Steps (Primary Claude Session):
1. Run `/context` and note the actual percentage
2. Note the output format

### Steps (Test Terminal):
```bash
# Check JICM estimate
cat /Users/aircannon/Claude/Jarvis/.claude/logs/context-estimate.json | jq '.percentage'
```

### Document the Gap:
```
Actual (from /context): ____%
Estimated (from JICM): ____%
Gap: ____% (actual - estimated)
```

### Expected Finding:
Actual will likely be 20-40% higher than estimated because JICM doesn't count:
- Claude's responses
- System prompt
- MCP schema overhead

---

## Test 4: Simulate JICM Threshold Trigger

**Purpose**: Test checkpoint creation when estimate exceeds threshold

### Steps (Test Terminal):

```bash
# Set context estimate to threshold level (65% recommended)
cat > /Users/aircannon/Claude/Jarvis/.claude/logs/context-estimate.json << 'EOF'
{
  "sessionStart": "2026-01-20T20:00:00.000Z",
  "totalTokens": 135000,
  "toolCalls": 200,
  "lastUpdate": "2026-01-20T21:00:00.000Z",
  "percentage": 67.5
}
EOF

# Watch for checkpoint file creation
watch -n 1 "ls -la /Users/aircannon/Claude/Jarvis/.claude/context/.soft-restart-checkpoint.md 2>/dev/null || echo 'No checkpoint'"
```

### Steps (Primary Claude Session):
Run any tool call (e.g., read a file)

### Expected Results:
- Checkpoint file created at `.claude/context/.soft-restart-checkpoint.md`
- Signal file created at `.claude/context/.auto-clear-signal`
- Compaction flag set at `.claude/context/.compaction-in-progress`
- Watcher detects signal and sends /clear

### Verification:
```bash
# Check all JICM state files
echo "=== Checkpoint ===" && head -20 /Users/aircannon/Claude/Jarvis/.claude/context/.soft-restart-checkpoint.md
echo "=== Signal ===" && cat /Users/aircannon/Claude/Jarvis/.claude/context/.auto-clear-signal 2>/dev/null || echo "No signal"
echo "=== Flag ===" && cat /Users/aircannon/Claude/Jarvis/.claude/context/.compaction-in-progress 2>/dev/null || echo "No flag"
```

---

## Test 5: PreCompact Hook (Native Auto-Compact Trigger)

**Purpose**: Test that PreCompact creates checkpoint when native auto-compact fires

**NOTE**: This test requires hitting actual context limit, which is slow. Consider simulation.

### Simulation (Test Terminal):

```bash
# Simulate PreCompact hook firing
echo '{}' | CLAUDE_PROJECT_DIR=/Users/aircannon/Claude/Jarvis /Users/aircannon/Claude/Jarvis/.claude/hooks/pre-compact.sh
```

### Expected Results:
- Checkpoint created
- Tier 2 MCPs disabled
- Signal file created (ISSUE: this couples with JICM)

### Verify Coupling Issue:
```bash
# After running, check if signal was created
ls -la /Users/aircannon/Claude/Jarvis/.claude/context/.auto-clear-signal
# If exists, this demonstrates the coupling issue identified in Q10
```

---

## Test 6: Session Start Liftover

**Purpose**: Test that checkpoint is loaded after /clear

### Setup (Test Terminal):
```bash
# Create a checkpoint manually
cat > /Users/aircannon/Claude/Jarvis/.claude/context/.soft-restart-checkpoint.md << 'EOF'
# Manual Test Checkpoint

**Created**: 2026-01-20T21:00:00.000Z
**Reason**: Manual live-fire test

## Work State

Testing JICM liftover mechanism. Previous task was "JICM Investigation".

## Current Task

Continue JICM testing after liftover.

## MANDATORY ACTION

You MUST acknowledge this checkpoint was loaded successfully.

EOF
```

### Steps (Primary Claude Session):
1. Run `/clear`
2. Observe greeting

### Expected Results:
- SessionStart hook detects checkpoint
- Provides context restoration protocol
- Claude acknowledges "Context restored"
- Claude references checkpoint content

### Cleanup:
```bash
rm -f /Users/aircannon/Claude/Jarvis/.claude/context/.soft-restart-checkpoint.md
```

---

## Test 7: MCP Disable/Enable Scripts

**Purpose**: Verify MCP management works

### Steps (Test Terminal):

```bash
# Check current disabled MCPs
jq -r '.projects["/Users/aircannon/Claude/Jarvis"].disabledMcpServers // []' ~/.claude.json

# Disable test MCPs
/Users/aircannon/Claude/Jarvis/.claude/scripts/disable-mcps.sh github context7 sequential-thinking

# Verify disabled
jq -r '.projects["/Users/aircannon/Claude/Jarvis"].disabledMcpServers // []' ~/.claude.json

# Re-enable
/Users/aircannon/Claude/Jarvis/.claude/scripts/enable-mcps.sh github context7 sequential-thinking

# Verify re-enabled
jq -r '.projects["/Users/aircannon/Claude/Jarvis"].disabledMcpServers // []' ~/.claude.json
```

### Expected Results:
- Scripts modify ~/.claude.json correctly
- disabledMcpServers array is updated

---

## Test 8: Subagent Context Isolation

**Purpose**: Verify subagent tool calls don't inflate main session estimate

### Setup (Test Terminal):
```bash
# Note current estimate
cat /Users/aircannon/Claude/Jarvis/.claude/logs/context-estimate.json | jq '.toolCalls, .totalTokens'
```

### Steps (Primary Claude Session):
Ask Claude to spawn a subagent with heavy tool usage:
```
Use the Explore subagent to find all TypeScript files in the .claude directory
```

### Check After (Test Terminal):
```bash
# Check estimate again
cat /Users/aircannon/Claude/Jarvis/.claude/logs/context-estimate.json | jq '.toolCalls, .totalTokens'
```

### Expected Results:
- Tool calls from subagent may or may not be tracked (depends on hook behavior)
- If tracked, this could be problematic (subagent context is isolated)
- **Key finding**: Only the Task tool call itself should count, not subagent's internal tools

---

## Test 9: Full JICM Cycle (End-to-End)

**Purpose**: Test complete cycle from accumulation to liftover

**CAUTION**: This test will clear your active session!

### Preparation:
1. Ensure watcher is running
2. Have specific work in progress to verify liftover

### Steps (Test Terminal):

```bash
# 1. Verify watcher
pgrep -f "auto-clear-watcher.sh" || echo "START WATCHER FIRST"

# 2. Set estimate to trigger level
cat > /Users/aircannon/Claude/Jarvis/.claude/logs/context-estimate.json << 'EOF'
{
  "sessionStart": "2026-01-20T20:00:00.000Z",
  "totalTokens": 170000,
  "toolCalls": 350,
  "lastUpdate": "2026-01-20T21:00:00.000Z",
  "percentage": 85.0
}
EOF

# 3. Monitor watcher terminal for "SIGNAL DETECTED"
```

### Steps (Primary Claude Session):
1. Note what you're currently working on
2. Run any tool call to trigger the accumulator
3. Wait for watcher to detect and send /clear
4. Observe liftover

### Expected Flow:
1. Tool call triggers context-accumulator.js
2. 85% > threshold → Checkpoint created
3. Signal file written
4. Watcher detects (within 2s)
5. Watcher waits 3s
6. Watcher sends /clear
7. Context cleared
8. SessionStart fires
9. Checkpoint loaded
10. Claude resumes with checkpoint context

### Document Results:
- Did checkpoint get created? Y/N
- Did watcher detect signal? Y/N
- Did /clear get sent? Y/N
- Did liftover occur? Y/N
- Did Claude resume work context? Y/N

---

## Monitoring Commands Reference

```bash
# Real-time context monitoring
watch -n 1 "cat /Users/aircannon/Claude/Jarvis/.claude/logs/context-estimate.json | jq ."

# Watch for checkpoint
watch -n 1 "ls -la /Users/aircannon/Claude/Jarvis/.claude/context/.soft-restart-checkpoint.md 2>/dev/null"

# Watch session-start log
tail -f /Users/aircannon/Claude/Jarvis/.claude/logs/session-start-diagnostic.log

# Watch watcher log
tail -f /Users/aircannon/Claude/Jarvis/.claude/logs/watcher-launcher.log

# Watch JICM triggers log
tail -f /Users/aircannon/Claude/Jarvis/.claude/logs/jicm-triggers.log 2>/dev/null

# Full JICM state check
echo "=== Context Estimate ===" && cat /Users/aircannon/Claude/Jarvis/.claude/logs/context-estimate.json | jq .
echo "=== Checkpoint ===" && head -10 /Users/aircannon/Claude/Jarvis/.claude/context/.soft-restart-checkpoint.md 2>/dev/null || echo "None"
echo "=== Signal ===" && cat /Users/aircannon/Claude/Jarvis/.claude/context/.auto-clear-signal 2>/dev/null || echo "None"
echo "=== Flag ===" && cat /Users/aircannon/Claude/Jarvis/.claude/context/.compaction-in-progress 2>/dev/null || echo "None"
echo "=== Watcher PID ===" && cat /Users/aircannon/Claude/Jarvis/.claude/context/.watcher-pid 2>/dev/null || echo "None"
```

---

## Cleanup After Testing

```bash
# Reset context estimate to baseline
cat > /Users/aircannon/Claude/Jarvis/.claude/logs/context-estimate.json << 'EOF'
{
  "sessionStart": "2026-01-20T21:00:00.000Z",
  "totalTokens": 30000,
  "toolCalls": 0,
  "lastUpdate": "2026-01-20T21:00:00.000Z",
  "percentage": 15.0
}
EOF

# Remove JICM state files
rm -f /Users/aircannon/Claude/Jarvis/.claude/context/.soft-restart-checkpoint.md
rm -f /Users/aircannon/Claude/Jarvis/.claude/context/.auto-clear-signal
rm -f /Users/aircannon/Claude/Jarvis/.claude/context/.compaction-in-progress

# Re-enable any disabled MCPs
/Users/aircannon/Claude/Jarvis/.claude/scripts/enable-mcps.sh github context7 sequential-thinking

# Stop watcher (if desired)
/Users/aircannon/Claude/Jarvis/.claude/scripts/stop-watcher.sh
```

---

## Test Results Template

After running tests, fill in:

| Test | Expected | Actual | Pass/Fail | Notes |
|------|----------|--------|-----------|-------|
| T1: Watcher running | PID found | | | |
| T2: Accumulator tracking | Tokens increase | | | |
| T3: Estimate vs Reality | Document gap | | | |
| T4: JICM trigger | Checkpoint created | | | |
| T5: PreCompact | Signal coupling observed | | | |
| T6: Liftover | Checkpoint loaded | | | |
| T7: MCP scripts | Enable/disable works | | | |
| T8: Subagent isolation | Verify context isolation | | | |
| T9: Full cycle | End-to-end success | | | |

---

## Known Issues to Observe

1. **Estimate vs Reality Gap**: Expect JICM estimates to be 20-40% lower than actual
2. **PreCompact Coupling**: Signal file created by both JICM and PreCompact
3. **Subagent-Stop JICM**: May incorrectly trigger based on subagent work
4. **Liftover Reliability**: Depends on Claude following instructions

---

*Live-fire test document for JICM validation (Revised)*
*Project Aion AC-04 Testing*
*Q9-Q21 Findings Incorporated*
