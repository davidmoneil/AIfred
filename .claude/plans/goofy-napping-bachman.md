# F.2 Virgil MVP — Task List, Active Agents, Files Touched

## Context

F.1 Ennoia MVP (session orchestrator) is complete and committed (`02b4272`). Virgil v0.1 already exists as a 138-line bash dashboard showing recent files, git changes, context status, and Ennoia status. F.2 upgrades it to v0.2 by adding real-time task/agent tracking via a new PostToolUse hook, enhancing the git changes panel, and wiring Virgil into the tmux launcher.

**Goal**: Give the operator live visibility into Jarvis's active tasks, running subagents, and file modifications — all from a dedicated tmux window.

---

## Deliverables

| # | Deliverable | File |
|---|-------------|------|
| 1 | `virgil-tracker.js` hook | `.claude/hooks/virgil-tracker.js` (NEW) |
| 2 | Hook registration in settings.json | `.claude/settings.json` (EDIT) |
| 3 | virgil.sh v0.1 → v0.2 | `.claude/scripts/virgil.sh` (EDIT) |
| 4 | Virgil window in tmux launcher | `.claude/scripts/launch-jarvis-tmux.sh` (EDIT) |
| 5 | Register in capability-map.yaml | `.claude/context/psyche/capability-map.yaml` (EDIT) |

---

## Step 1: Create `virgil-tracker.js` hook

**File**: `/Users/aircannon/Claude/Jarvis/.claude/hooks/virgil-tracker.js`
**Pattern**: Follow `observation-tracker.js` — stdin JSON → process → stdout `{continue:true}`

**Behavior on PostToolUse**:
- **TaskCreate**: Read `.virgil-tasks.json`, add new task entry `{id, subject, status:"pending", activeForm, timestamp}`
- **TaskUpdate**: Read `.virgil-tasks.json`, update matching task's status/subject/activeForm
- **Task** (subagent launch): Read `.virgil-agents.json`, add agent entry `{id: tool_input.description, type: tool_input.subagent_type, description: tool_input.description, started: ISO timestamp, status:"running"}`

**Behavior on SubagentStop**:
- Read `.virgil-agents.json`, mark matching agent as completed or remove

**Stale cleanup**: On every invocation, prune entries >15 min old from both files.

**Signal file locations** (dot-prefixed, gitignored):
- `/Users/aircannon/Claude/Jarvis/.claude/context/.virgil-tasks.json`
- `/Users/aircannon/Claude/Jarvis/.claude/context/.virgil-agents.json`

**JSON schema for .virgil-tasks.json**:
```json
{
  "updated": "ISO-timestamp",
  "tasks": [
    {"id": "1", "subject": "Fix auth bug", "status": "in_progress", "activeForm": "Fixing auth bug", "timestamp": "ISO"}
  ]
}
```

**JSON schema for .virgil-agents.json**:
```json
{
  "updated": "ISO-timestamp",
  "agents": [
    {"id": "agent-abc123", "type": "Explore", "description": "Search codebase", "started": "ISO", "status": "running"}
  ]
}
```

**Key design choices**:
- Stateless: reads file, merges, writes back (no in-memory state between invocations)
- Atomic write: write to `.tmp` then rename (consistent with Ennoia pattern)
- Tool input parsing: `hookData.tool_input` contains the tool parameters (subject, taskId, subagent_type, etc.)
- `hookData.tool_output` contains the result (task object with id for TaskCreate)
- Task tool input has `description` field — use as agent display name
- Agent ID: Use combination of description hash + timestamp for uniqueness

---

## Step 2: Register hook in settings.json

**File**: `/Users/aircannon/Claude/Jarvis/.claude/settings.json`

Add to PostToolUse array:
```json
{
  "matcher": "^(Task|TaskCreate|TaskUpdate)$",
  "hooks": [
    {
      "type": "command",
      "command": "node $CLAUDE_PROJECT_DIR/.claude/hooks/virgil-tracker.js"
    }
  ]
}
```

Add to SubagentStop array (after existing entries):
```json
{
  "type": "command",
  "command": "node $CLAUDE_PROJECT_DIR/.claude/hooks/virgil-tracker.js"
}
```

**Note**: Matcher uses anchored regex per hook-matchers gotcha (`^...$` not bare strings).

---

## Step 3: Upgrade virgil.sh v0.1 → v0.2

**File**: `/Users/aircannon/Claude/Jarvis/.claude/scripts/virgil.sh`

**New signal file constants**:
```bash
VIRGIL_TASKS="$PROJECT_DIR/.claude/context/.virgil-tasks.json"
VIRGIL_AGENTS="$PROJECT_DIR/.claude/context/.virgil-agents.json"
```

**New functions**:

### `render_tasks_section()`
- Read `.virgil-tasks.json` via python3 (consistent with existing file-access.json pattern)
- Display each task with status indicator: `[x]` completed, `[>]` in_progress (+ activeForm), `[ ]` pending
- Fallback: "(no active tasks)"
- Limit display to 8 entries

### `render_agents_section()`
- Read `.virgil-agents.json` via python3
- Display each agent with type, description (truncated), elapsed time
- Flag stale entries >10 min as "(possibly stalled)"
- Fallback: "(no active agents)"

### Enhanced `get_git_changes()` → `render_files_touched()`
- Rename section from "CHANGES (uncommitted)" to "FILES TOUCHED"
- Group by operation type: M (modified), A (added), ? (untracked), D (deleted)
- Use color coding: green=added, yellow=modified, red=deleted, dim=untracked
- Keep existing `git status --short` but parse and reformat

**Updated panel order** (render function):
1. Header (VIRGIL — Codebase Guide + timestamp)
2. TASKS (new)
3. ACTIVE AGENTS (new)
4. FILES TOUCHED (enhanced CHANGES)
5. RECENT FILES (existing, last 10 min)
6. CONTEXT (existing, tokens/pct/state)
7. ENNOIA (existing, mode/intent)
8. Virgil Says (existing, heuristic)

**Version**: Update header comment to v0.2, update tmux window reference.

---

## Step 4: Add Virgil window to tmux launcher

**File**: `/Users/aircannon/Claude/Jarvis/.claude/scripts/launch-jarvis-tmux.sh`

Add Virgil as **window 3** (after Ennoia window 2):
```bash
# Launch Virgil codebase guide in a tmux window (window 3, detached)
VIRGIL_SCRIPT="$PROJECT_DIR/.claude/scripts/virgil.sh"
if [[ -x "$VIRGIL_SCRIPT" ]]; then
    echo "Launching Virgil codebase guide in tmux window..."
    "$TMUX_BIN" new-window -t "$SESSION_NAME" -n "Virgil" -d \
        "cd '$PROJECT_DIR' && '$VIRGIL_SCRIPT'; echo 'Virgil stopped.'; read"
fi
```

Update:
- Layout comment diagram: Add Window 3 Virgil
- `set-window-option` automatic-rename off for window 3
- Help text: `Window 3: Virgil`
- Keyboard shortcuts: `Ctrl+b then 0/1/2/3`

---

## Step 5: Register in capability-map.yaml

**File**: `/Users/aircannon/Claude/Jarvis/.claude/context/psyche/capability-map.yaml`

Add after `aion.ennoia` entry:
```yaml
  - id: aion.virgil
    version: "0.2"
    when: "Codebase navigation — task tracking, agent monitoring, file changes"
    status: active
    script: .claude/scripts/virgil.sh
    signal_files: [".virgil-tasks.json", ".virgil-agents.json"]
```

---

## Verification

1. **Syntax checks**:
   - `node -c .claude/hooks/virgil-tracker.js` → no syntax errors
   - `bash -n .claude/scripts/virgil.sh` → clean
   - `bash -n .claude/scripts/launch-jarvis-tmux.sh` → clean
   - `jq . .claude/settings.json` → valid JSON

2. **Hook unit tests** (pipe test data):
   - TaskCreate: `echo '{"tool_name":"TaskCreate","tool_input":{"subject":"Test task","description":"A test","activeForm":"Testing"},"tool_output":"{\"id\":\"1\"}"}' | node .claude/hooks/virgil-tracker.js`
   - Verify `.virgil-tasks.json` created with task entry
   - TaskUpdate: `echo '{"tool_name":"TaskUpdate","tool_input":{"taskId":"1","status":"completed"},"tool_output":"{}"}' | node .claude/hooks/virgil-tracker.js`
   - Verify task status updated
   - Task (agent): `echo '{"tool_name":"Task","tool_input":{"subagent_type":"Explore","description":"Search code"},"tool_output":"result"}' | node .claude/hooks/virgil-tracker.js`
   - Verify `.virgil-agents.json` created

3. **Virgil dashboard**: Run `bash .claude/scripts/virgil.sh` — verify all panels render without errors (Ctrl+C to exit after one cycle)

4. **Stale cleanup**: Create a signal file with old timestamps, run hook, verify pruned

5. **Integration**: All signal files gitignored (dot-prefixed in .claude/context/)

---

## Files Modified Summary

| File | Action | Lines (est.) |
|------|--------|-------------|
| `.claude/hooks/virgil-tracker.js` | CREATE | ~130 |
| `.claude/settings.json` | EDIT | +12 |
| `.claude/scripts/virgil.sh` | EDIT | +90 (138→~230) |
| `.claude/scripts/launch-jarvis-tmux.sh` | EDIT | +15 |
| `.claude/context/psyche/capability-map.yaml` | EDIT | +6 |
