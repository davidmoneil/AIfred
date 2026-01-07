# PR-8.3.1: Hook Validation & Automated Context Management Roadmap

**Created**: 2026-01-07
**Status**: IN PROGRESS
**Goal**: Validate hooks work, then build automated MCP disable → exit → clear → restart workflow

---

## Executive Summary

### Current State (BROKEN)

| Component | Expected | Actual |
|-----------|----------|--------|
| 18 JavaScript hooks | Executing | **NOT EXECUTING** - wrong format |
| 1 Shell hook (session-start.sh) | Executing + displaying | Executing (logged), **NOT DISPLAYING** |
| Automated context management | Functional | **NOT BUILT** |

### Critical Discoveries

1. **JavaScript hooks are non-functional**: Claude Code requires JSON registration + shell commands, NOT `module.exports` JS
2. **HOOK OUTPUT REQUIRES JSON FORMAT**: Plain text stdout is IGNORED. Hooks must output JSON with `systemMessage` field for text to appear in system reminders
3. **MCP changes require restart**: Confirmed - can't dynamically unload mid-session
4. **Manual workflow works**: User confirmed disable MCP → /clear → restart DOES prevent MCP loading
5. **Hookify plugin proves hooks work**: Python hooks in hookify plugin execute correctly because they output proper JSON format

### Hook Output Format (2026-01-07 Discovery)

Claude Code expects hooks to output JSON to stdout:

```json
// For messages (appears in system reminders)
{"systemMessage": "Your message here"}

// For blocking PreToolUse/PostToolUse
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny"
  },
  "systemMessage": "Reason for blocking"
}

// For no action (allow operation, no message)
{}
```

**Plain text output is silently ignored!** This explains why session-start.sh banner wasn't appearing.

### Target State

Fully automated workflow:
1. Detect high context usage (hook or manual trigger)
2. Select MCPs to disable based on next steps
3. Flag MCPs, update config
4. Exit session cleanly with checkpoint
5. /clear or restart
6. SessionStart hook loads checkpoint WITHOUT flagged MCPs

---

## Phase 1: Hook System Validation

### Test 1.1: Hook Output Visibility

**Hypothesis**: Hook stdout appears in system reminders, not inline text

**Test A - Simplest possible hook**:
```bash
# Create: .claude/hooks/echo-test.sh
#!/bin/bash
echo "ECHO TEST HOOK FIRED"
exit 0
```

Register in settings.json, restart, check:
- Does "ECHO TEST HOOK FIRED" appear anywhere?
- System reminders? Inline? Logs?

**Test B - JSON output format**:
```bash
# Test if Claude Code expects JSON output
#!/bin/bash
echo '{"message": "Test hook JSON output"}'
exit 0
```

**Test C - Different exit codes**:
```bash
#!/bin/bash
echo "Testing exit code 1"
exit 1  # Does non-zero block anything?
```

**Evidence needed**:
- [ ] Confirm hook executes (check log file)
- [ ] Determine where output appears (if anywhere)
- [ ] Test exit code behavior

### Test 1.2: Hook Event Types

Test each event type with minimal shell hook:

| Event | Test Hook | Expected Trigger |
|-------|-----------|------------------|
| SessionStart | session-start-test.sh | On claude launch, /clear |
| UserPromptSubmit | prompt-test.sh | Every user message |
| PreToolUse | pre-tool-test.sh | Before each tool call |
| PostToolUse | post-tool-test.sh | After each tool call |
| Stop | stop-test.sh | Session end |
| PreCompact | compact-test.sh | Before autocompaction |

**Validation criteria**:
- [ ] Hook executes (log file written)
- [ ] Correct input received (JSON parsed correctly)
- [ ] Output appears to user (or documented where it goes)

### Test 1.3: Hook Blocking Capability

**Hypothesis**: Hooks can block operations via exit code or special output

**Test A - Exit code blocking**:
```bash
#!/bin/bash
# PreToolUse hook that blocks
echo "BLOCKING THIS OPERATION"
exit 1
```

**Test B - JSON blocking format** (if Claude Code uses structured output):
```bash
#!/bin/bash
echo '{"block": true, "message": "Blocked by test hook"}'
exit 0
```

**Questions to answer**:
- [ ] Can PreToolUse hooks block operations?
- [ ] What's the blocking mechanism (exit code? JSON field?)
- [ ] How does blocked message appear to Claude?

---

## Phase 2: Hook Migration Strategy

### Priority 1: Session Management (Required for Context Automation)

| Hook | Current | Migration Priority | Notes |
|------|---------|-------------------|-------|
| session-start.js → session-start.sh | ✅ Done | CRITICAL | Already migrated, output issue |
| pre-compact.js → pre-compact.sh | Pending | CRITICAL | Needed for auto-trigger |
| session-stop.js → session-stop.sh | Pending | HIGH | Clean exit notification |

### Priority 2: Guardrails (Security)

| Hook | Current | Migration Priority | Notes |
|------|---------|-------------------|-------|
| workspace-guard.js | Not registered | HIGH | Blocks AIfred baseline writes |
| dangerous-op-guard.js | Not registered | HIGH | Blocks rm -rf, force push |
| secret-scanner.js | Not registered | MEDIUM | Blocks secret commits |

### Priority 3: Observability

| Hook | Current | Migration Priority | Notes |
|------|---------|-------------------|-------|
| audit-logger.js | Not registered | LOW | Tool execution logging |
| session-tracker.js | Not registered | LOW | Session lifecycle |

### Migration Template

```bash
#!/bin/bash
# Hook: <name>
# Event: <event-type>
# Purpose: <description>

# Read JSON input from stdin
INPUT=$(cat)

# Parse relevant fields
TOOL=$(echo "$INPUT" | jq -r '.tool // "unknown"')
PARAMS=$(echo "$INPUT" | jq -r '.parameters // {}')

# Hook logic here
# ...

# Log for debugging
LOG_DIR="$CLAUDE_PROJECT_DIR/.claude/logs"
mkdir -p "$LOG_DIR"
echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) | <hook-name> | tool=$TOOL" >> "$LOG_DIR/hook-debug.log"

# Output for user (if supported)
echo "Hook executed: <name>"

# Exit: 0 = proceed, non-zero = block (hypothesis)
exit 0
```

---

## Phase 3: Automated Context Management Workflow

### Architecture

```
┌──────────────────────────────────────────────────────────────────────┐
│                      TRIGGER DETECTION                                │
├──────────────────────────────────────────────────────────────────────┤
│  1. PreCompact hook (autocompaction imminent)                        │
│  2. /smart-checkpoint command (manual trigger)                        │
│  3. /context-budget showing CRITICAL (>100%)                         │
└──────────────────────────────────────────────────────────────────────┘
                                 │
                                 ▼
┌──────────────────────────────────────────────────────────────────────┐
│                      MCP EVALUATION                                   │
├──────────────────────────────────────────────────────────────────────┤
│  Input: session-state.md "Next Steps", current-priorities.md         │
│  Output: { keep: ['github'], drop: ['time', 'context7'] }            │
│                                                                       │
│  Logic:                                                               │
│  - Parse next steps for keywords (PR, research, design, etc.)        │
│  - Map keywords to required MCPs                                      │
│  - Everything not required → drop                                     │
└──────────────────────────────────────────────────────────────────────┘
                                 │
                                 ▼
┌──────────────────────────────────────────────────────────────────────┐
│                      CONFIG MODIFICATION                              │
├──────────────────────────────────────────────────────────────────────┤
│  1. Write drop list to flag file: .claude/context/.mcp-drop-list     │
│  2. Run MCP removal commands:                                         │
│     claude mcp remove <name> -s local                                │
│  3. Create checkpoint file with context                              │
└──────────────────────────────────────────────────────────────────────┘
                                 │
                                 ▼
┌──────────────────────────────────────────────────────────────────────┐
│                      SESSION EXIT                                     │
├──────────────────────────────────────────────────────────────────────┤
│  Two paths:                                                           │
│                                                                       │
│  Path A (Soft - /clear only):                                        │
│  - Checkpoint created                                                 │
│  - User runs /clear                                                   │
│  - SessionStart hook loads checkpoint                                 │
│  - MCPs STILL LOADED (same process)                                  │
│                                                                       │
│  Path B (Hard - exit + claude):                                      │
│  - Checkpoint created                                                 │
│  - MCP config modified                                                │
│  - User runs exit (or script does it)                                │
│  - User runs claude (or script does it)                              │
│  - SessionStart hook loads checkpoint                                 │
│  - MCPs REDUCED per config                                           │
└──────────────────────────────────────────────────────────────────────┘
                                 │
                                 ▼
┌──────────────────────────────────────────────────────────────────────┐
│                      SESSION RESUME                                   │
├──────────────────────────────────────────────────────────────────────┤
│  SessionStart hook:                                                   │
│  1. Check for checkpoint file                                         │
│  2. If found: display context, delete file                           │
│  3. User says "continue" to resume                                    │
│  4. Context budget now within healthy range                          │
└──────────────────────────────────────────────────────────────────────┘
```

### Key Technical Questions

| Question | Possible Answers | Test to Determine |
|----------|------------------|-------------------|
| Can hooks run shell commands? | Yes (shell scripts) / No | Test with `claude mcp remove` in hook |
| Can hooks trigger exit? | Yes (exit command) / No (process isolation) | Test exit command in hook |
| Can hooks run /clear? | Unlikely (interactive command) | Test if possible |
| Can we auto-restart claude? | osascript/terminal automation | Test macOS script |
| Does /clear reload settings.json? | Yes / No | Modify settings, /clear, check |

### Critical Path Issue: Automation Gap

**Problem**: Even if hooks work perfectly, there's a gap between:
- Hook detecting "context critical"
- Claude actually exiting and restarting

**Options**:

1. **User-assisted** (Current): Hook warns, user manually runs exit/restart
2. **Hook-triggered exit**: Hook runs `exit` command (may not work from hook)
3. **External watchdog**: Separate process monitors context, triggers restart
4. **Terminal automation**: osascript sends keystrokes to terminal

---

## Phase 4: Test Plan (TDD Approach)

### Test Suite 1: Hook Fundamentals

```
TEST 1.1.1: echo-test.sh fires on SessionStart
  Given: Hook registered in settings.json
  When: Claude session starts
  Then: Log file contains entry, output visible somewhere

TEST 1.1.2: Hook receives correct JSON input
  Given: UserPromptSubmit hook registered
  When: User sends "hello"
  Then: Hook receives JSON with prompt field containing "hello"

TEST 1.1.3: Hook can block PreToolUse
  Given: PreToolUse hook that exits 1 for Read tool
  When: Claude attempts to Read a file
  Then: Read is blocked (or we learn blocking doesn't work)

TEST 1.1.4: Hook output appears to user
  Given: Hook that echoes "USER VISIBLE MESSAGE"
  When: Hook fires
  Then: User sees message (determine where: system reminder, inline, etc.)
```

### Test Suite 2: MCP Config Changes

```
TEST 2.1.1: Settings.json reload on /clear
  Given: MCP "time" in config
  When: Remove time from settings.json, run /clear
  Then: time tools still available (same process) OR unavailable (config reloaded)

TEST 2.1.2: MCP removal via claude command
  Given: MCP "time" loaded
  When: Run `claude mcp remove time -s local` from hook
  Then: Command executes, config updated (verify via `claude mcp list`)

TEST 2.1.3: MCP state after hard restart
  Given: MCP "time" removed from config
  When: Exit and restart claude
  Then: time tools unavailable, context reduced
```

### Test Suite 3: End-to-End Workflow

```
TEST 3.1.1: Checkpoint file created and loaded
  Given: /soft-restart creates checkpoint
  When: /clear runs, SessionStart hook fires
  Then: Checkpoint content displayed, file deleted

TEST 3.1.2: MCP drop list respected
  Given: .mcp-drop-list contains "time,context7"
  When: Hard restart (exit + claude)
  Then: time and context7 not loaded

TEST 3.1.3: Context budget reduced after workflow
  Given: Context at 85%
  When: Run full workflow with MCP reduction
  Then: Context at <70% (measured or estimated)
```

---

## Phase 5: Potential Issues & Solutions

### Issue 1: Hook Output Not Visible

**Symptoms**: Hook executes (logged) but output not shown to user

**Possible causes**:
1. Output goes to system reminders (not inline)
2. Output requires specific format (JSON?)
3. Output suppressed by Claude Code
4. Output only shown on certain events

**Solutions to test**:
- [ ] Try different output formats (plain text, JSON, markdown)
- [ ] Check if `message` field in JSON output works
- [ ] Test if stderr vs stdout matters
- [ ] Check Claude Code docs for hook output format

### Issue 2: Cannot Block Operations

**Symptoms**: PreToolUse hook fires but operation proceeds anyway

**Possible causes**:
1. Blocking requires specific exit code
2. Blocking requires JSON response format
3. Event type doesn't support blocking
4. Claude Code ignores hook return values

**Solutions to test**:
- [ ] Test exit codes 0, 1, 2
- [ ] Test JSON `{"block": true}` format
- [ ] Test on different event types
- [ ] Research Claude Code hook documentation

### Issue 3: Cannot Modify MCP Config from Hook

**Symptoms**: `claude mcp remove` in hook doesn't work

**Possible causes**:
1. Hook runs in restricted environment
2. claude CLI not in path
3. Permission issues
4. Wrong working directory

**Solutions to test**:
- [ ] Use absolute path to claude CLI
- [ ] Set explicit working directory
- [ ] Test with simpler file write first
- [ ] Check hook execution environment

### Issue 4: Cannot Trigger Exit/Restart

**Symptoms**: Hook cannot cause Claude to exit

**Possible causes**:
1. Process isolation (hook is subprocess)
2. exit command only exits hook, not parent
3. No IPC mechanism to signal parent

**Solutions to test**:
- [ ] Create flag file that user monitors
- [ ] Use macOS notification that user must acknowledge
- [ ] External watchdog process
- [ ] Accept user-assisted exit as MVP

### Issue 5: /clear Doesn't Reload Config

**Symptoms**: /clear runs but MCP changes not reflected

**Possible causes**:
1. /clear only clears conversation, not config
2. MCPs loaded at process start only
3. Hot reload not supported

**Solutions to test**:
- [ ] Modify settings.json, /clear, test MCP availability
- [ ] If confirmed: /clear insufficient, must use hard restart

---

## Immediate Next Steps

### Step 1: Create Minimal Test Hook (5 min)

```bash
# .claude/hooks/minimal-test.sh
#!/bin/bash
echo "MINIMAL TEST HOOK - $(date)" >> /tmp/hook-test.log
echo "TEST OUTPUT VISIBLE?"
exit 0
```

### Step 2: Register and Test (5 min)

Add to settings.json under appropriate event, restart, verify:
- Log file created
- Output visibility

### Step 3: Document Findings (5 min)

Update this document with actual results vs expected.

### Step 4: Iterate Based on Findings

If hooks work → proceed to migration
If hooks don't work → debug or find alternative approach

---

## Success Criteria

### MVP (Minimum Viable Product)

- [ ] At least one hook demonstrably working with visible output
- [ ] PreCompact hook warns user of high context
- [ ] SessionStart hook loads checkpoint after /clear
- [ ] User can manually run workflow (hook-assisted, not fully automated)

### Full Solution

- [ ] All critical hooks migrated and functional
- [ ] Automated MCP evaluation and config modification
- [ ] Seamless restart workflow (minimal user intervention)
- [ ] Context budget stays below 80% through automation

---

## Validated Components (2026-01-07)

### Component Test Results

| Component | Test | Result |
|-----------|------|--------|
| MCP config modification | `claude mcp remove/add` | ✅ Works |
| Batch MCP removal | Remove time, context7, sequential-thinking | ✅ Works |
| MCP re-addition with args | API keys, paths preserved | ✅ Works |
| Checkpoint file creation | Write to `.soft-restart-checkpoint.md` | ✅ Works |
| Checkpoint JSON output | session-start.sh reads and outputs JSON | ✅ Works |
| Checkpoint one-time use | File deleted after read | ✅ Works |
| Workflow script | `mcp-unload-workflow.sh` | ✅ Works |

### Workflow Script Usage

```bash
# Location: .claude/scripts/mcp-unload-workflow.sh

# Modes:
./mcp-unload-workflow.sh tier1-only "checkpoint content"    # Drop all Tier 2
./mcp-unload-workflow.sh keep-github "checkpoint content"   # Keep github only
./mcp-unload-workflow.sh keep-context7 "checkpoint content" # Keep context7 only
```

### Complete Workflow Sequence

```
STEP 1: TRIGGER
├── Automatic: PreCompact hook detects high context
└── Manual: User runs /smart-checkpoint or sees /context-budget CRITICAL

STEP 2: CHECKPOINT CREATION
├── Claude gathers current work state
├── Claude writes checkpoint file: .claude/context/.soft-restart-checkpoint.md
└── Content includes: current work, next steps, MCP recommendations

STEP 3: MCP CONFIG MODIFICATION
├── Run: .claude/scripts/mcp-unload-workflow.sh [mode] "[checkpoint]"
├── Script removes Tier 2 MCPs from config
└── Config file updated: ~/.claude.json

STEP 4: SESSION EXIT (User Action Required)
├── Option A (Soft): /clear
│   └── MCPs remain loaded (same process)
│   └── Only clears conversation
└── Option B (Hard): exit + claude
    └── MCPs unloaded (new process)
    └── Full context reduction

STEP 5: SESSION RESUME
├── SessionStart hook fires
├── Hook checks for checkpoint file
├── Hook outputs JSON with checkpoint content
├── User sees checkpoint in system reminders
└── User says "continue" to resume
```

### Remaining Gap: Automation of Step 4

**Problem**: We cannot automatically trigger exit/restart from within Claude.

**Current state**: User must manually:
- Type `exit` (or Ctrl+C)
- Type `claude`

**Potential solutions to investigate**:
1. Terminal automation (osascript on macOS)
2. External watchdog process
3. Accept manual step as MVP

---

## Related Documentation

- `.claude/reports/mcp-load-unload-test-procedure.md` - MCP behavior findings
- `.claude/context/patterns/context-budget-management.md` - Budget allocation
- `.claude/context/patterns/automated-context-management.md` - Workflow design
- `.claude/hooks/README.md` - Hook inventory (needs update after findings)
- `.claude/scripts/mcp-unload-workflow.sh` - Workflow automation script

---

*PR-8.3.1 Hook Validation Roadmap — Test-Oriented Development*
*Created: 2026-01-07*
*Updated: 2026-01-07 — Component testing complete*
