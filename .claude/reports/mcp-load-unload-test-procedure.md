# MCP Load/Unload Test Procedure

**Created**: 2026-01-07
**Purpose**: Validate MCP loading and unloading mechanics before building PR-8.4 validation harness
**Status**: COMPLETE

---

## Test Objectives

1. **Configuration**: Can we add/remove MCPs via CLI commands?
2. **Runtime Effect**: Does change take effect immediately or require restart?
3. **Tool Availability**: Are MCP tools available/unavailable as expected?
4. **Process Management**: Are MCP processes spawned/terminated correctly?
5. **Re-addition**: Can removed MCPs be re-added cleanly?

---

## Current MCP Inventory

### Tier 1: Always-On (Core)

| MCP | Command | Package | Remove Command |
|-----|---------|---------|----------------|
| memory | npx | @modelcontextprotocol/server-memory | `claude mcp remove memory -s local` |
| filesystem | npx | @modelcontextprotocol/server-filesystem | `claude mcp remove filesystem -s local` |
| fetch | uvx | mcp-server-fetch | `claude mcp remove fetch -s local` |
| git | uvx | mcp-server-git | `claude mcp remove git -s local` |

### Tier 2: Task-Scoped

| MCP | Command | Package | Remove Command |
|-----|---------|---------|----------------|
| time | uvx | mcp-server-time | `claude mcp remove time -s local` |
| github | npx | @modelcontextprotocol/server-github | `claude mcp remove github -s local` |
| context7 | npx | @upstash/context7-mcp | `claude mcp remove context7 -s local` |
| sequential-thinking | npx | @modelcontextprotocol/server-sequential-thinking | `claude mcp remove sequential-thinking -s local` |

### Tier 3: Triggered (Plugin-managed)

| MCP | Type | Status |
|-----|------|--------|
| plugin:playwright:playwright | stdio | ✓ Connected |
| plugin:gitlab:gitlab | HTTP | ✗ Failed |

---

## Test Procedure

### Test 1: Remove a Tier 2 MCP (time)

**Rationale**: Time MCP is low-risk, small token cost, easy to verify.

**Steps**:
1. Verify current status: `claude mcp list | grep time`
2. Test tool before removal: `mcp__time__get_current_time`
3. Remove MCP: `claude mcp remove time -s local`
4. Verify removal: `claude mcp list | grep time`
5. Check if tools still work (expect failure)
6. Check for running processes: `ps aux | grep mcp-server-time`

**Re-add**:
```bash
claude mcp add time -s local -- uvx mcp-server-time
```

### Test 2: Remove a Tier 2 MCP (sequential-thinking)

**Rationale**: Higher token cost, different package ecosystem (npx).

**Steps**:
1. Verify current status: `claude mcp get sequential-thinking`
2. Note tool: `mcp__sequential-thinking__sequentialthinking`
3. Remove MCP: `claude mcp remove sequential-thinking -s local`
4. Verify removal: `claude mcp list`
5. Check process: `ps aux | grep sequential-thinking`

**Re-add**:
```bash
claude mcp add sequential-thinking -s local -- npx -y @modelcontextprotocol/server-sequential-thinking
```

### Test 3: Remove and Re-add Context7 (API key handling)

**Rationale**: Tests re-addition with environment variables/API keys.

**Steps**:
1. Document current config: `claude mcp get context7`
2. Remove: `claude mcp remove context7 -s local`
3. Verify tools unavailable
4. Re-add with API key:
```bash
claude mcp add context7 -s local -- npx -y @upstash/context7-mcp --api-key <key>
```
5. Verify tools available again

### Test 4: Tier 1 MCP (filesystem) - Caution

**Rationale**: Tests core infrastructure MCP. Higher risk.

**Steps**:
1. Document filesystem config including paths
2. Remove: `claude mcp remove filesystem -s local`
3. Verify MCP filesystem tools fail
4. Re-add with correct paths:
```bash
claude mcp add filesystem -s local -- npx -y @modelcontextprotocol/server-filesystem /Users/aircannon/Claude/Jarvis /Users/aircannon/Claude
```

---

## Verification Methods

### 1. Configuration Verification
```bash
claude mcp list          # Full list with status
claude mcp get <name>    # Detailed config
```

### 2. Process Verification
```bash
ps aux | grep -E "(mcp-server|@modelcontextprotocol)"
```

### 3. Tool Availability
- Attempt to invoke MCP tool
- Check for error: "Tool not found" or similar

### 4. Context Window Impact
- **Note**: Cannot directly measure from CLI
- **Proxy**: Count tools available before/after
- **Future**: Integrate with `/context-budget` command

---

## Expected vs Actual Outcomes

| Action | Expected | **Actual** |
|--------|----------|------------|
| `claude mcp remove <name>` | Config removed, tools unavailable | Config removed, **tools STILL WORK** |
| `claude mcp add <name>` | Config added, tools available | Config added, tools available |
| Restart requirement | YES - MCPs load at session start | **CONFIRMED** - Required for removal to take effect |
| Process termination | Automatic on session end | **Processes persist** until session end |
| Tool calls to removed MCP | Error or undefined behavior | **Tools continue working** in current session |

---

## Test Results

### Test 1: Time MCP (uvx)
- [x] Removal successful - config removed from `.claude.json`
- [x] Tools **STILL WORK** after removal (unexpected)
- [x] Process persists: PID 31903 still running
- [x] Re-addition successful
- [x] Tools available after re-addition
- **Notes**: First confirmation that MCP removal is config-only, not runtime

### Test 2: Sequential-Thinking MCP (npx)
- [x] Removal successful
- [x] Tools **STILL WORK** after removal
- [x] Process persists: PID 31957 still running
- [x] Re-addition successful
- **Notes**: Confirms pattern holds for npx-based MCPs

### Test 3: Context7 MCP (npx with API key)
- [x] Removal successful
- [x] Tools **STILL WORK** after removal
- [x] Process persists: PIDs 31958, 31971 still running
- [x] Re-addition with API key successful
- **Notes**: API key passed via `--api-key` argument is visible in config (security consideration)

### Test 4: Filesystem MCP (npx with paths - Tier 1)
- [x] Removal successful
- [x] Tools **STILL WORK** after removal
- [x] Process persists: PIDs 31899, 31922 still running
- [x] Re-addition with paths successful
- **Notes**: Even Tier 1 core MCPs follow same pattern

---

## Findings for PR-8.4

### Critical Discovery: MCP Removal is CONFIG-ONLY

**MCP changes via CLI do NOT affect runtime behavior in the current session.**

### Detailed Findings

1. **Runtime vs Restart Behavior**:
   - `claude mcp remove` updates config file only
   - Tools remain fully functional in current session
   - MCP processes continue running until session ends
   - **Session restart required** for removal to take effect
   - **Implication**: Cannot dynamically unload MCPs to free context budget mid-session

2. **Process Management**:
   - MCP processes spawned at session start
   - Processes persist throughout entire session regardless of config changes
   - Both npx and uvx MCPs follow identical behavior
   - Process termination only occurs when Claude Code session ends

3. **Error Handling**:
   - No errors when using tools from "removed" MCPs
   - Config changes silently accepted without runtime effect
   - No warning that restart is required

4. **Re-addition Complexity**:
   - Simple MCPs: `claude mcp add <name> -s local -- <runner> <package>`
   - With API keys: Pass via `--api-key <key>` argument
   - With paths: Pass as trailing positional arguments
   - All re-additions successful in testing

5. **Token Budget Implications**:
   - **Cannot free context budget mid-session** by removing MCPs
   - Context optimization requires planning at session start
   - PR-8.4 validation harness should focus on:
     - Pre-session MCP selection
     - Recommendations for next session
     - `/checkpoint` workflow for MCP changes

### Impact on PR-8.4 and PR-9.2

| Feature | Impact |
|---------|--------|
| PR-8.4 Validation Harness | Must validate config changes, not runtime effect |
| PR-9.2 Deselection Intelligence | Recommendations apply to NEXT session, not current |
| `/context-budget` command | Should indicate "changes require restart" |
| Dynamic loading | **NOT POSSIBLE** without session restart |

### Recommended Workflow

1. Before session: Review MCP needs, adjust config
2. Start session: MCPs load per config
3. During session: Track usage, note recommendations
4. End session: `/end-session` saves recommendations
5. Next session: Apply recommended MCP changes

---

## Smart Checkpoint Implementation (2026-01-07)

Based on these findings, we implemented an automated context management workflow:

### Components Created

1. **`/smart-checkpoint` command** (`.claude/commands/smart-checkpoint.md`)
   - Intelligent MCP evaluation based on next steps
   - Soft-exit with commit (no push)
   - MCP config adjustment
   - Restart instructions

2. **Enhanced `pre-compact.js` hook**
   - Now suggests `/smart-checkpoint` before autocompaction
   - Better than losing context to compaction

3. **MCP Config Scripts** (`.claude/scripts/`)
   - `adjust-mcp-config.sh` — Remove non-essential Tier 2 MCPs
   - `restore-mcp-config.sh` — Re-add Tier 2 MCPs as needed

4. **Automated Context Management Pattern** (`.claude/context/patterns/automated-context-management.md`)
   - Full workflow documentation
   - Architecture diagram
   - Integration points

### Test Results

```bash
# Test: adjust-mcp-config.sh keep-github
# Result: Successfully removed time, context7, sequential-thinking
# GitHub preserved for ongoing PR work

# Test: restore-mcp-config.sh all
# Result: All Tier 2 MCPs restored to config
```

### Estimated Token Savings

| Mode | MCPs Dropped | Token Savings |
|------|--------------|---------------|
| tier1-only | time, github, context7, sequential-thinking | ~31K |
| keep-github | time, context7, sequential-thinking | ~16K |
| keep-context7 | time, github, sequential-thinking | ~23K |

---

*MCP Load/Unload Test Procedure — Pre-PR-8.4 Validation*
*Updated: 2026-01-07 — Smart Checkpoint Implementation*
