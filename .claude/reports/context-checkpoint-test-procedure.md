# Context Checkpoint Test Procedure

**Created**: 2026-01-07
**Purpose**: Validate the full MCP unload workflow in an experimental environment
**Status**: READY FOR TESTING

---

## Pre-Test Setup

### Terminal Setup

1. Open a **NEW terminal window** (not the main session)
2. Navigate to Jarvis:
   ```bash
   cd /Users/aircannon/Claude/Jarvis
   ```
3. Start Claude Code:
   ```bash
   claude
   ```

### Verify Starting State

Before testing, verify the environment:

```bash
# In the new Claude session, run:
/mcp
```

Note which MCPs are currently enabled/disabled.

```bash
# Check current disabled list (outside Claude or via Bash tool):
jq '.projects["/Users/aircannon/Claude/Jarvis"].disabledMcpServers' ~/.claude.json
```

---

## Test 1: Basic MCP Disable/Enable (Already Validated ✅)

This was validated earlier. Skip if already confirmed.

---

## Test 2: Full /context-checkpoint Workflow

### Step 2.1: Run Context Checkpoint

In the test terminal, tell Claude:

```
Run /context-checkpoint

For testing, use these simulated next steps:
- "Update documentation files"
- "Review test results"

When evaluating MCPs, recommend disabling: github, git, context7, sequential-thinking
(Keep only Tier 1: memory, filesystem, fetch)
```

### Step 2.2: Verify Checkpoint File Created

After Claude completes the command:

```bash
# Check checkpoint file exists
ls -la .claude/context/.soft-restart-checkpoint.md

# View contents
cat .claude/context/.soft-restart-checkpoint.md
```

**Expected**: File exists with work summary, next steps, MCP state.

### Step 2.3: Verify MCPs Disabled

```bash
# Check disabledMcpServers array
jq '.projects["/Users/aircannon/Claude/Jarvis"].disabledMcpServers' ~/.claude.json
```

**Expected**: github, git, context7, sequential-thinking in the array.

### Step 2.4: Run /exit-session

Tell Claude:
```
Run /exit-session
```

**Expected**:
- Git commit created
- Message: "Run /clear to resume"

### Step 2.5: Run /clear

```
/clear
```

**Expected**:
- Conversation clears
- SessionStart hook fires
- Checkpoint content displayed (if hook is working)
- Disabled MCPs not loaded

### Step 2.6: Verify MCPs After /clear

```
/mcp
```

**Expected**:
- memory: connected
- filesystem: connected
- fetch: connected
- github: disabled
- git: disabled
- context7: disabled
- sequential-thinking: disabled

### Step 2.7: Verify Checkpoint Loaded

If SessionStart hook is working, you should see checkpoint context in the session start message.

If not visible, check if file was consumed:
```bash
ls -la .claude/context/.soft-restart-checkpoint.md
```

**Expected**: File deleted (consumed by hook) OR file still exists (hook not loading it).

### Step 2.8: Say "continue"

```
continue
```

Claude should have context about what was being worked on.

---

## Test 3: Re-enable MCPs

### Step 3.1: Enable MCPs

```bash
.claude/scripts/enable-mcps.sh github git context7 sequential-thinking
```

Or:
```bash
.claude/scripts/enable-mcps.sh --all
```

### Step 3.2: Verify Config Changed

```bash
jq '.projects["/Users/aircannon/Claude/Jarvis"].disabledMcpServers' ~/.claude.json
```

**Expected**: Array should be smaller or empty.

### Step 3.3: Run /clear Again

```
/clear
```

### Step 3.4: Verify MCPs Restored

```
/mcp
```

**Expected**: Previously disabled MCPs now show as "connected".

---

## Test 4: Context Budget Impact

### Step 4.1: Check Context Before

```
/context
```

Note the "MCP tools" token count.

### Step 4.2: Disable Multiple MCPs

```bash
.claude/scripts/disable-mcps.sh github git context7 sequential-thinking
```

### Step 4.3: Run /clear

```
/clear
```

### Step 4.4: Check Context After

```
/context
```

**Expected**: MCP tools token count reduced by ~25-30K tokens.

---

## Test Results Template

Copy and fill out after testing:

```markdown
## Test Results — [DATE]

### Test 2: Full Workflow
- [ ] 2.1 /context-checkpoint ran successfully
- [ ] 2.2 Checkpoint file created
- [ ] 2.3 MCPs added to disabledMcpServers
- [ ] 2.4 /exit-session committed changes
- [ ] 2.5 /clear executed
- [ ] 2.6 Disabled MCPs not loaded after /clear
- [ ] 2.7 Checkpoint loaded by hook: YES / NO / PARTIAL
- [ ] 2.8 "continue" worked with context

### Test 3: Re-enable
- [ ] 3.1 enable-mcps.sh worked
- [ ] 3.2 Config updated
- [ ] 3.4 MCPs restored after /clear

### Test 4: Context Impact
- [ ] Before: MCP tools = ___ tokens
- [ ] After: MCP tools = ___ tokens
- [ ] Savings: ___ tokens (___%)

### Issues Found
- [ ] Issue 1: ...
- [ ] Issue 2: ...

### Notes
...
```

---

## Cleanup After Testing

After completing tests, restore full MCP access:

```bash
.claude/scripts/enable-mcps.sh --all
```

Then in the test terminal:
```
/clear
```

You can then close the test terminal.

---

## Known Limitations

1. **Checkpoint Loading**: The SessionStart hook may not be fully configured to load checkpoint content. This is a separate enhancement.

2. **Git State**: Tests create commits. These are on the current branch (Project_Aion).

3. **Config File**: Tests modify `~/.claude.json`. Changes affect all Jarvis sessions.

---

## Success Criteria

The workflow is validated if:
- [x] Scripts modify disabledMcpServers correctly ✅ (validated)
- [x] /clear respects disabledMcpServers ✅ (validated)
- [x] /context-checkpoint creates proper checkpoint file ✅ (validated)
- [x] Git commits checkpoint ✅ (validated)
- [x] SessionStart hook loads checkpoint ✅ (validated)
- [x] Context reduction measurable via /context ✅ (16.2K → 7.4K = 54% reduction)
- [x] Checkpoint file persists after /clear ✅ (fixed - removed `rm` from hook)

---

*Context Checkpoint Test Procedure*
*Created: 2026-01-07*
