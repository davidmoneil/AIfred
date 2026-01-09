# Hook Consolidation Assessment

**Created**: 2026-01-09
**PR Reference**: PR-9 / AIfred Sync ADAPT
**Status**: Assessment Complete

---

## Current State

### Registered Hooks (in settings.json — ACTIVE)

These hooks are **actually executing** because they're registered in `.claude/settings.json`:

| Event | Hook | Format | Status |
|-------|------|--------|--------|
| SessionStart | `session-start.sh` | Shell | ✅ Active |
| PreCompact | `pre-compact.sh` | Shell | ✅ Active |
| Stop | `stop-auto-clear.sh` | Shell | ✅ Active |
| UserPromptSubmit | `minimal-test.sh` | Shell | ✅ Active (test) |

### Unregistered Hooks (JavaScript — NOT EXECUTING)

These JavaScript hooks **exist but are NOT running** because Claude Code requires explicit registration in settings.json:

| File | Purpose | Should Register? |
|------|---------|------------------|
| `session-start.js` | Enhanced context loading | See analysis below |
| `pre-compact.js` | Context preservation | See analysis below |
| `session-stop.js` | Desktop notifications | Yes |
| `self-correction-capture.js` | Learn from corrections | Yes |
| `orchestration-detector.js` | Complexity detection | Yes |
| `context-accumulator.js` | JICM context tracking | Yes |
| `subagent-stop.js` | Post-agent JICM | Yes |
| `cross-project-commit-tracker.js` | Multi-repo tracking | Yes |
| Others (guards, etc.) | Various | Evaluate |

---

## Shell vs JavaScript Analysis

### session-start: Shell vs JS

| Feature | Shell (.sh) | JavaScript (.js) |
|---------|-------------|------------------|
| Checkpoint loading | ✅ Full | ✅ Full |
| MCP suggestions | ✅ External script | ✅ Inline |
| Auto-clear watcher | ✅ Launches | ❌ Not implemented |
| Git branch display | ✅ Basic | ✅ Enhanced |
| AIfred baseline check | ❌ Not implemented | ✅ Full |
| JICM reset | ❌ Not implemented | ✅ Full |
| Session source detection | ✅ jq parsing | ✅ Native |

**Verdict**: JavaScript version is more capable, but shell launches watcher.

### pre-compact: Shell vs JS

| Feature | Shell (.sh) | JavaScript (.js) |
|---------|-------------|------------------|
| Checkpoint creation | ✅ Full | ✅ Full |
| MCP disabling | ✅ External script | ❌ Not implemented |
| Signal file creation | ✅ Direct | ❌ Not implemented |
| Key info extraction | ❌ Basic | ✅ Intelligent |
| Blocker tracking | ❌ Not implemented | ✅ From session-state |

**Verdict**: Shell handles MCP disabling and signaling; JS has better parsing.

---

## Recommendation: Hybrid Approach

### Phase 1: Register Critical JS Hooks (Immediate)

Add these to settings.json under appropriate events:

```json
{
  "hooks": {
    "UserPromptSubmit": [
      { "type": "command", "command": "node $CLAUDE_PROJECT_DIR/.claude/hooks/orchestration-detector.js" },
      { "type": "command", "command": "node $CLAUDE_PROJECT_DIR/.claude/hooks/self-correction-capture.js" }
    ],
    "PostToolUse": [
      { "type": "command", "command": "node $CLAUDE_PROJECT_DIR/.claude/hooks/context-accumulator.js" },
      { "type": "command", "command": "node $CLAUDE_PROJECT_DIR/.claude/hooks/cross-project-commit-tracker.js" }
    ],
    "SubagentStop": [
      { "type": "command", "command": "node $CLAUDE_PROJECT_DIR/.claude/hooks/subagent-stop.js" }
    ],
    "Stop": [
      { "type": "command", "command": "node $CLAUDE_PROJECT_DIR/.claude/hooks/session-stop.js" }
    ]
  }
}
```

### Phase 2: Migrate Shell Unique Features to JS (Future)

Migrate these shell-only features to JS versions:
1. Auto-clear watcher launch (session-start.sh → session-start.js)
2. MCP disabling via external script (pre-compact.sh → pre-compact.js)
3. Signal file creation (pre-compact.sh → pre-compact.js)

### Phase 3: Deprecate Shell Hooks (Future)

Once JS versions have all features:
1. Remove shell hooks from settings.json
2. Archive .sh files to `.claude/hooks/archive/`
3. Update documentation

---

## Action Items for This Session

**Minimum Viable**: Register the new JS hooks in settings.json so they actually execute.

1. ✅ orchestration-detector.js — UserPromptSubmit
2. ✅ context-accumulator.js — PostToolUse
3. ✅ cross-project-commit-tracker.js — PostToolUse
4. ✅ subagent-stop.js — SubagentStop (for JICM)
5. ⏸️ session-stop.js — Stop (already have stop-auto-clear.sh)

---

## Hook Registration Format

Claude Code hooks can be:
- **Shell scripts**: Executed directly, receive env vars
- **Node scripts**: Must be invoked via `node` command
- **Any executable**: Receives JSON on stdin, returns JSON on stdout

For JavaScript hooks, use:
```json
{
  "type": "command",
  "command": "node $CLAUDE_PROJECT_DIR/.claude/hooks/hook-name.js"
}
```

---

## Future Considerations

1. **Context cost**: Each registered hook adds to context (hook definitions)
2. **Execution order**: Multiple hooks per event execute in order
3. **Error handling**: Hook failures should not block Claude operations
4. **Performance**: Keep hooks lightweight to avoid latency

---

*Hook Consolidation Assessment v1.0*
*PR-9 / AIfred Sync ADAPT #5*
