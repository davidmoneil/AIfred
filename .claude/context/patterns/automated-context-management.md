# Automated Context Management Pattern

**Created**: 2026-01-07
**PR Reference**: PR-8.3.1
**Status**: Active — Ready for Testing
**Version**: 2.0 (Zero-Action Automation)

---

## Overview

Jarvis implements a **zero-user-action** context management system that automatically:
1. Detects when context approaches threshold
2. Creates checkpoints with work state
3. Disables non-essential MCPs
4. Clears conversation via external watcher
5. Resumes work automatically

This pattern eliminates the need for manual intervention when context limits are reached.

---

## Key Discovery (2026-01-07)

**`disabledMcpServers` Array**: MCP disabled state is stored in `~/.claude.json`:

```json
{
  "projects": {
    "/Users/aircannon/Claude/Jarvis": {
      "mcpServers": { /* registered MCPs */ },
      "disabledMcpServers": ["context7", "github", "sequential-thinking"]
    }
  }
}
```

- **To disable**: Add MCP name to array
- **To enable**: Remove MCP name from array
- **Effect**: Changes apply after `/clear` (no full restart needed)

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           JARVIS SESSION                                 │
│                                                                          │
│  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐     │
│  │  SessionStart   │    │   PreCompact    │    │      Stop       │     │
│  │     Hook        │    │     Hook        │    │     Hook        │     │
│  └────────┬────────┘    └────────┬────────┘    └────────┬────────┘     │
│           │                      │                      │               │
│           ▼                      ▼                      ▼               │
│  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐     │
│  │ Launch watcher  │    │ Create ckpt     │    │ Block stop if   │     │
│  │ Load checkpoint │    │ Disable MCPs    │    │ checkpoint new  │     │
│  │ Auto-resume     │    │ Write signal    │    │                 │     │
│  └─────────────────┘    └─────────────────┘    └─────────────────┘     │
│                                  │                                      │
└──────────────────────────────────│──────────────────────────────────────┘
                                   │
                                   ▼ Signal File
┌─────────────────────────────────────────────────────────────────────────┐
│                      AUTO-CLEAR WATCHER                                  │
│                    (Separate Terminal Window)                            │
│                                                                          │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │  Monitors: .claude/context/.auto-clear-signal                    │   │
│  │  On detect: Wait 3s → Send /clear keystroke to Claude window     │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Components

### 1. SessionStart Hook (`.claude/hooks/session-start.sh`)

**Triggers on**: startup, resume, clear, compact

**Functions**:
- Launches auto-clear watcher on startup/resume (avoids duplicates)
- Detects checkpoint file after `/clear`
- Loads checkpoint content into session
- Injects `additionalContext` for auto-resume (no "continue" needed)

```bash
# Launch watcher on startup
if [[ "$SOURCE" == "startup" ]] || [[ "$SOURCE" == "resume" ]]; then
    "$CLAUDE_PROJECT_DIR/.claude/scripts/launch-watcher.sh" &
fi

# Auto-resume with additionalContext
jq -n --arg ctx "AUTO-RESUME: Continue working on tasks..." '{
    "hookSpecificOutput": {
        "additionalContext": $ctx
    }
}'
```

### 2. PreCompact Hook (`.claude/hooks/pre-compact.sh`)

**Triggers on**: Context approaching threshold (before autocompaction)

**Functions**:
- Creates checkpoint file with work state
- Disables Tier 2 MCPs (github, context7, sequential-thinking)
- Writes signal file for watcher

```bash
# Create checkpoint
cat > "$CHECKPOINT_FILE" << 'CHECKPOINT'
# Auto-Generated Context Checkpoint
...
CHECKPOINT

# Disable MCPs
"$CLAUDE_PROJECT_DIR/.claude/scripts/disable-mcps.sh" github context7 sequential-thinking

# Signal watcher
echo "$TIMESTAMP" > "$SIGNAL_FILE"
```

### 3. Stop Hook (`.claude/hooks/stop-auto-clear.sh`)

**Triggers on**: Claude tries to stop (end turn)

**Functions**:
- Detects if checkpoint was recently created
- Blocks stop if checkpoint exists but signal file doesn't
- Instructs Claude to signal clear via `autonomous-commands` skill

```bash
# Block and instruct clear
jq -n '{
    "decision": "block",
    "reason": "Signal /clear via autonomous-commands skill"
}'
```

### 4. Auto-Clear Watcher (`.claude/scripts/auto-clear-watcher.sh`)

**Runs in**: Separate Terminal window (auto-launched)

**Functions**:
- Monitors for `.auto-clear-signal` file
- Sends `/clear` keystroke to Claude window via AppleScript (macOS) or xdotool (Linux)
- Targets Claude window (avoids watcher window by checking title)

```applescript
-- Find Claude window (not watcher)
repeat with w in windows
    if custom title of w does not contain "Watcher" then
        set frontmost of targetWindow to true
    end if
end repeat
-- Send keystrokes
keystroke "/clear"
keystroke return
```

### 5. Launch Watcher (`.claude/scripts/launch-watcher.sh`)

**Called by**: SessionStart hook

**Functions**:
- Checks if watcher already running (PID file)
- Opens new Terminal window with watcher
- Records PID for cleanup

### 6. MCP Control Scripts

| Script | Purpose |
|--------|---------|
| `disable-mcps.sh` | Adds MCPs to `disabledMcpServers` array |
| `enable-mcps.sh` | Removes MCPs from array (supports `--all`) |
| `list-mcp-status.sh` | Shows registered vs disabled MCPs |
| `stop-watcher.sh` | Stops watcher process |

### 7. Signal Clear via Skill

**Invokable by**: Claude via `autonomous-commands` skill

**Functions**:
- Creates signal file for watcher via `signal_command()`
- Used when manual checkpoint triggers clear sequence

**Note**: The `/trigger-clear` command has been replaced by the `autonomous-commands` skill which uses `signal-helper.sh` to create signals.

---

## Data Flow

### Signal Files

| File | Purpose | Created By | Consumed By |
|------|---------|------------|-------------|
| `.soft-restart-checkpoint.md` | Work state, next steps | PreCompact / context-checkpoint | SessionStart |
| `.auto-clear-signal` | Trigger for watcher | PreCompact / autonomous-commands skill | Watcher |
| `.watcher-pid` | Watcher process ID | Watcher / launch-watcher | launch-watcher |

### MCP Configuration

| Location | Field | Purpose |
|----------|-------|---------|
| `~/.claude.json` | `projects[path].disabledMcpServers[]` | MCPs to skip on load |

---

## Automation Flow

### Scenario 1: Context Threshold (Fully Automatic)

```
1. [AUTO] Context approaches limit
2. [AUTO] PreCompact hook fires
3. [AUTO] → Creates checkpoint file
4. [AUTO] → Disables Tier 2 MCPs
5. [AUTO] → Writes signal file
6. [AUTO] Watcher detects signal (within 2s)
7. [AUTO] → Waits 3s for Claude to finish
8. [AUTO] → Sends /clear to Claude window
9. [AUTO] /clear executes
10. [AUTO] SessionStart hook fires
11. [AUTO] → Loads checkpoint
12. [AUTO] → Injects auto-resume context
13. [AUTO] Claude continues work on todo list
```

### Scenario 2: Manual Checkpoint

```
1. [USER] Runs /context-checkpoint
2. [AUTO] Claude creates checkpoint, disables MCPs
3. [AUTO] Stop hook detects checkpoint, blocks
4. [AUTO] Stop hook tells Claude to signal /clear via autonomous-commands skill
5. [AUTO] Claude uses autonomous-commands skill to create signal file
6. [AUTO] Signal file created
7. [AUTO] Watcher sends /clear
8. [AUTO] SessionStart auto-resumes
```

---

## Configuration

### Settings (`settings.json`)

```json
{
  "hooks": {
    "SessionStart": [{ "command": ".claude/hooks/session-start.sh" }],
    "PreCompact": [{ "command": ".claude/hooks/pre-compact.sh" }],
    "Stop": [{ "command": ".claude/hooks/stop-auto-clear.sh" }]
  }
}
```

### MCP Tiers

| Tier | MCPs | Auto-Disabled on Checkpoint? |
|------|------|------------------------------|
| 1 (Always-On) | memory, filesystem, fetch | Never |
| 2 (Task-Scoped) | github, git, context7, sequential-thinking | Yes |
| 3 (Triggered) | playwright | Only via specific commands |

---

## Testing Checklist

### Pre-Test Setup

1. Ensure all scripts are executable:
   ```bash
   chmod +x .claude/hooks/*.sh
   chmod +x .claude/scripts/*.sh
   ```

2. Start fresh session:
   ```bash
   cd /Users/aircannon/Claude/Jarvis
   claude
   ```

3. Verify watcher launched (new Terminal window should open)

### Test 1: Watcher Auto-Launch

- [ ] Start `claude` in Jarvis directory
- [ ] New Terminal window opens with "JARVIS AUTO-CLEAR WATCHER"
- [ ] Watcher shows "Status: ACTIVE"

### Test 2: Manual Context Checkpoint

- [ ] Run `/context-checkpoint`
- [ ] Checkpoint file created
- [ ] MCPs disabled (check with `.claude/scripts/list-mcp-status.sh`)
- [ ] Watcher detects signal, sends /clear
- [ ] Session clears and reloads
- [ ] Claude auto-resumes work

### Test 3: Token Savings

- [ ] Before checkpoint: Run `/context` to note MCP token count
- [ ] After /clear: Run `/context` again
- [ ] Verify MCP tokens reduced (~16K → ~7K)

### Test 4: Watcher Recovery

- [ ] Close watcher window manually
- [ ] Run `/clear` in Claude session
- [ ] Watcher should re-launch automatically

---

## Troubleshooting

### Watcher Not Launching

```bash
# Check if launch script is executable
ls -la .claude/scripts/launch-watcher.sh

# Check logs
cat .claude/logs/watcher-launcher.log

# Manual launch
.claude/scripts/launch-watcher.sh
```

### Watcher Not Sending /clear

```bash
# Check if signal file exists
ls -la .claude/context/.auto-clear-signal

# Check watcher PID
cat .claude/context/.watcher-pid
ps -p $(cat .claude/context/.watcher-pid)

# Check macOS accessibility permissions for Terminal
# System Preferences → Security & Privacy → Privacy → Accessibility
```

### MCPs Not Disabling

```bash
# Check disabledMcpServers array
jq '.projects["/Users/aircannon/Claude/Jarvis"].disabledMcpServers' ~/.claude.json

# Manual disable
.claude/scripts/disable-mcps.sh github context7 sequential-thinking

# Verify
.claude/scripts/list-mcp-status.sh
```

### Checkpoint Not Loading

```bash
# Check checkpoint file exists
ls -la .claude/context/.soft-restart-checkpoint.md
cat .claude/context/.soft-restart-checkpoint.md

# Check SessionStart hook logs
cat .claude/logs/session-start-diagnostic.log
```

---

## Token Savings

| Scenario | MCPs Disabled | Est. Savings |
|----------|---------------|--------------|
| Documentation work | github, sequential-thinking | ~20K |
| Quick fixes | github, context7, sequential-thinking | ~28K |
| Maximum reduction | all Tier 2 | ~32K |

**Validated (2026-01-07)**: 16.2K → 7.4K MCP tokens (54% reduction)

---

## Key Insights

1. **`disabledMcpServers` Array**: MCPs can be disabled without uninstalling

2. **`/clear` Respects Config Changes**: Reloads config, applying changes without full restart

3. **`additionalContext` in SessionStart**: Injects context that tells Claude to auto-continue

4. **Stop Hook with `decision: block`**: Prevents Claude from stopping, injects prompts (Ralph Wiggum pattern)

5. **External Watcher Pattern**: Bridges Claude's world and CLI commands via keystroke automation

---

## Limitations

1. **Cannot auto-trigger `/clear` from within Claude**: Built-in CLI command requires external mechanism (watcher)

2. **Watcher requires Terminal app access**: macOS needs Accessibility permissions for AppleScript

3. **Plugin-bundled MCPs cannot be disabled**: Playwright MCPs (from document-skills) don't respond to `disabledMcpServers`

---

## Files Reference

| File | Purpose |
|------|---------|
| `.claude/hooks/session-start.sh` | Launch watcher, load checkpoint, auto-resume |
| `.claude/hooks/pre-compact.sh` | Auto-checkpoint on context threshold |
| `.claude/hooks/stop-auto-clear.sh` | Block stop, trigger clear sequence |
| `.claude/scripts/launch-watcher.sh` | Open watcher in new Terminal |
| `.claude/scripts/auto-clear-watcher.sh` | Monitor signals, send /clear |
| `.claude/scripts/disable-mcps.sh` | Disable MCPs |
| `.claude/scripts/enable-mcps.sh` | Enable MCPs |
| `.claude/scripts/list-mcp-status.sh` | Show MCP state |
| `.claude/scripts/stop-watcher.sh` | Stop watcher process |
| `.claude/commands/context-checkpoint.md` | Manual checkpoint command |
| `.claude/skills/autonomous-commands/SKILL.md` | Signal commands (replaces trigger-clear.md) |

---

## Related Documentation

- `.claude/context/patterns/context-budget-management.md` — MCP tier strategy
- `.claude/reports/mcp-workflow-test-findings.md` — Initial test results
- `.claude/reports/context-checkpoint-test-procedure.md` — Test procedure

---

*Automated Context Management Pattern v2.0*
*PR-8.3.1 — Zero-Action Context Management*
*Created: 2026-01-07*
