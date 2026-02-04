---
description: Intelligent context compression using Claude model to analyze and compress conversation context
allowed-tools: Read, Write, Task, Bash, TodoWrite
---

# Intelligent Compress (JICM v5)

**EXECUTE THESE STEPS IN ORDER:**

## Step 1: Check for In-Progress Compression

```bash
if [ -f ".claude/context/.compression-in-progress" ]; then
    echo "Compression already in progress, aborting"
fi
```

If file exists, STOP and say "Compression already in progress."

## Step 2: Create In-Progress Flag and Update Session Files

First, create the flag:
```bash
echo "$(date -u +%Y-%m-%dT%H:%M:%SZ)" > .claude/context/.compression-in-progress
```

**CRITICAL**: Before spawning the agent, update these files with current work state:

1. **session-state.md** - Update with current task status:
   - Read `.claude/context/session-state.md`
   - Update "Current Work" section with what you're working on RIGHT NOW
   - Update "Status" to reflect current state
   - Write back the file

2. **current-priorities.md** - Mark completed items:
   - Read `.claude/context/current-priorities.md`
   - Check off any completed priorities
   - Update "Next Step" if applicable
   - Write back the file

3. **Check todos** - If any todos are in_progress, note them in session-state

These updates ensure the compression agent has accurate information to preserve.

## Step 3: Spawn Compression Agent

Use the Task tool with these EXACT parameters:

```
subagent_type: compression-agent
model: sonnet
run_in_background: true
prompt: |
  Compress the current conversation context for JICM v5 continuation.

  **Compression Target**: 10,000 - 30,000 tokens
  **Threshold Trigger**: 50% context usage

  You have access to the full conversation history. Your task:

  1. Read session transcript from ~/.claude/projects/.../[session-id].jsonl
  2. Read foundation docs: CLAUDE.md, jarvis-identity.md, compaction-essentials.md
  3. Read session state: session-state.md, current-priorities.md (READ-ONLY)
  4. PRESERVE: Current task, decisions made, file paths, todos, blockers
  5. SUMMARIZE: Tool outputs, resolved issues, multi-step workflow progress
  6. DROP: File contents, verbose outputs, MCP schemas, exploration dead-ends

  Write compressed context to: .claude/context/.compressed-context-ready.md
  Write completion signal to: .claude/context/.compression-done.signal

  Target: 10K-30K tokens. Self-contained for seamless continuation.
  See compression-agent.md for full protocol.
```

**IMPORTANT**: Use `run_in_background: true` so Jarvis can continue working while compression runs.

## Step 4: Verify and Signal

After agent returns (check `.compression-done.signal`):

1. Verify `.claude/context/.compressed-context-ready.md` exists
2. Remove in-progress flag:
   ```bash
   rm -f .claude/context/.compression-in-progress
   ```
3. The signal file is already created by the agent

## Step 5: Confirm to User

Say: "Compression complete (JICM v5). The watcher will send /clear shortly, then inject the compressed context for seamless continuation. Target: 10K-30K tokens."

---

## Reference Information

### JICM v5 Flow

```
┌─────────────────────────────────────────────────────────────┐
│ 1. /intelligent-compress triggered (manual or watcher)      │
│ 2. Spawn compression-agent (background, sonnet)             │
│    - Agent reads transcript + foundation docs + state       │
│    - Agent compresses to 10K-30K tokens                     │
│    - Agent writes .compressed-context-ready.md              │
│    - Agent writes .compression-done.signal                  │
│ 3. Watcher detects signal → sends /clear                    │
│ 4. session-start.sh hook:                                   │
│    - Injects context via additionalContext                  │
│    - Creates .idle-hands-active flag                        │
│ 5. Idle-hands monitor (Mechanism 2):                        │
│    - Cycles through submission methods                      │
│    - Wakes Jarvis if idle                                   │
│ 6. Jarvis resumes work seamlessly                           │
└─────────────────────────────────────────────────────────────┘
```

### Data Sources (v5)

**Transcript Sources** (ephemeral):
- `~/.claude/projects/-Users-aircannon-Claude-Jarvis/[session-id].jsonl`
- `~/.claude/projects/.../subagents/*.jsonl`
- `.claude/context/.context-captured*.txt`

**Foundation Docs** (durable):
- `.claude/CLAUDE.md`
- `.claude/jarvis-identity.md`
- `.claude/context/compaction-essentials.md`

**Session State** (durable, READ-ONLY):
- `.claude/context/session-state.md`
- `.claude/context/current-priorities.md`

### Compression Priorities

**ALWAYS Preserve**:
- Current task and status
- Technical decisions (with rationale)
- File paths modified
- Active errors/blockers
- User preferences

**Summarize**:
- Tool results → outcomes only
- File contents → 1-line summary
- Long explanations → key points

**Drop**:
- Full file contents
- Verbose command outputs
- Resolved issues
- MCP schemas
- Exploration dead-ends

### Configuration

Settings in `.claude/config/autonomy-config.yaml`:

```yaml
components:
  AC-04-jicm:
    version: 5.0.0
    settings:
      threshold: 50              # Single trigger threshold
      compression:
        model: sonnet            # haiku|sonnet|opus
        target_min: 10000        # Minimum tokens
        target_max: 30000        # Maximum tokens
        output_file: .claude/context/.compressed-context-ready.md
        auto_inject: true
```

## Related

- @.claude/agents/compression-agent.md — Agent specification (v5)
- @.claude/context/designs/jicm-v5-design-addendum.md — Authoritative v5 spec
- @.claude/context/designs/jicm-v5-resume-mechanisms.md — Resume mechanism details
- @.claude/hooks/session-start.sh — Post-clear injection + idle-hands flag
- @.claude/scripts/jarvis-watcher.sh — Context monitoring + idle-hands monitor

---

*JICM v5: Two-Mechanism Resume Architecture*
*Created: 2026-01-20 | Updated: 2026-02-03*
