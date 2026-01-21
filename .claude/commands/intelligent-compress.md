---
description: Intelligent context compression using Claude model to analyze and compress conversation context
allowed-tools: Read, Write, Task, Bash, TodoWrite
---

# Intelligent Compress

**EXECUTE THESE STEPS IN ORDER:**

## Step 1: Check for In-Progress Compression

```bash
if [ -f ".claude/context/.compression-in-progress" ]; then
    echo "Compression already in progress, aborting"
fi
```

If file exists, STOP and say "Compression already in progress."

## Step 2: Create In-Progress Flag

```bash
echo "$(date -u +%Y-%m-%dT%H:%M:%SZ)" > .claude/context/.compression-in-progress
```

## Step 3: Spawn Context-Compressor Agent

Use the Task tool with these EXACT parameters:

```
subagent_type: context-compressor
model: haiku
prompt: |
  Compress the current conversation context for session continuity.

  **Mode**: default (target 15-20% of original)

  You have access to the full conversation history. Analyze it and:

  1. PRESERVE: Current task, decisions made, file paths, todos, blockers
  2. SUMMARIZE: Tool outputs → brief results only
  3. DROP: Verbose file contents, resolved issues, redundant info

  Write the compressed context to: .claude/context/.compressed-context.md

  Use the format specified in your agent instructions.
  Return a brief summary of what was preserved.
```

Wait for the agent to complete and return.

## Step 4: Verify and Signal

After agent returns:

1. Verify `.claude/context/.compressed-context.md` exists
2. Remove in-progress flag:
   ```bash
   rm -f .claude/context/.compression-in-progress
   ```
3. Signal readiness for /clear:
   ```bash
   echo "compressed" > .claude/context/.clear-ready-signal
   ```

## Step 5: Confirm to User

Say: "Compression complete. Watcher will send /clear shortly. Context will be restored on restart."

---

## Reference Information

### How It Works

Unlike `/compact` (generic summarization) or `/smart-compact` (simple checkpoint), this command uses Claude to **intelligently analyze and compress** the full conversation context.

### Flow

```
┌─────────────────────────────────────────────────────────────┐
│ 1. Read compression config from autonomy-config.yaml        │
│ 2. Spawn context-compressor agent (haiku by default)        │
│    - Agent receives full conversation context               │
│    - Agent analyzes what to preserve/summarize/drop         │
│    - Agent writes compressed context to temp file           │
│ 3. Signal readiness for /clear                              │
│ 4. Watcher sends /clear                                     │
│ 5. Post-clear hook injects compressed context               │
└─────────────────────────────────────────────────────────────┘
```

## Detailed Execution Steps

### Step 1: Read Configuration

```bash
# Check if compression is already in progress
if [ -f ".claude/context/.compression-in-progress" ]; then
    echo "Compression already in progress, aborting"
    exit 0
fi
```

Read settings from `.claude/config/autonomy-config.yaml` under `components.AC-04-jicm.settings.compression`:
- `model`: haiku | sonnet | opus
- `mode`: aggressive | default | conservative
- `target_percent`: specific percentage if set
- `output_file`: where to write compressed context

### Step 2: Create In-Progress Flag

```bash
echo "$(date -u +%Y-%m-%dT%H:%M:%SZ)" > .claude/context/.compression-in-progress
```

### Step 3: Spawn Context-Compressor Agent

Use the Task tool to spawn the agent:

```
Task tool:
  subagent_type: context-compressor
  model: [from config, default haiku]
  prompt: |
    Compress the current conversation context.

    **Compression Mode**: [mode from config or args]
    **Target**: [percentage based on mode]

    Instructions:
    1. Analyze the full conversation context (you have access to it)
    2. Identify: critical decisions, active work, pending todos, blockers
    3. Summarize: tool outputs, file contents, verbose explanations
    4. Drop: redundant info, resolved issues, superseded decisions
    5. Write compressed context to: .claude/context/.compressed-context.md
    6. Return a brief summary of what was preserved

    The compressed context must be self-contained - the next session
    should be able to continue work without additional context.
```

### Step 4: Verify Output

After agent returns:
- Check that `.claude/context/.compressed-context.md` exists
- Verify it has content (not empty)
- Log compression metrics if available

### Step 5: Signal Ready for Clear

```bash
# Remove in-progress flag
rm -f .claude/context/.compression-in-progress

# Signal the watcher that compression is complete
echo "compressed" > .claude/context/.clear-ready-signal
```

### Step 6: Wait for Watcher

The watcher will detect `.clear-ready-signal` and send `/clear` to the Claude Code window.

## Compression Priorities

### ALWAYS Preserve
- Current task and status (from todos)
- Technical decisions made this session
- File paths modified or referenced
- User preferences expressed
- Blockers or errors encountered

### Summarize
- Tool call results → outcomes only
- File contents → 1-line relevance summary
- Long explanations → key points

### Drop
- Full file contents (they're on disk)
- Verbose command outputs
- Resolved issues
- Superseded decisions

## Post-Clear Injection

The session-start hook will:
1. Detect `.claude/context/.compressed-context.md`
2. Read its contents
3. Inject via `additionalContext` in the hook response
4. Delete the file after injection

This ensures the next session starts with the compressed context.

## Output Format

```
━━━ Intelligent Compression ━━━

Configuration:
  Model: haiku
  Mode: default (15-20%)

Spawning context-compressor agent...

[Agent output summary]

Compression complete:
  Output: .claude/context/.compressed-context.md
  Original: ~[X]K tokens (estimated)
  Compressed: ~[Y]K tokens (estimated)
  Ratio: [Z]%

Signaling watcher for /clear...

Next: Watcher will send /clear in ~3 seconds.
      Compressed context will be injected on restart.
```

## Error Handling

If compression fails:
- Remove in-progress flag
- Log error
- Fall back to `/smart-compact` (simple checkpoint)
- Continue with /clear anyway

## Configuration

Settings in `.claude/config/autonomy-config.yaml`:

```yaml
components:
  AC-04-jicm:
    settings:
      compression:
        model: haiku           # haiku|sonnet|opus
        mode: default          # aggressive|default|conservative
        target_percent: null   # Override mode with specific %
        output_file: .claude/context/.compressed-context.md
        auto_inject: true      # Inject post-clear
```

## Related

- @.claude/agents/context-compressor.md — Agent definition
- @.claude/commands/smart-compact.md — Simple checkpoint (fallback)
- @.claude/context/patterns/automated-context-management.md
- @.claude/hooks/session-start.sh — Post-clear injection

---

*JICM v2: Intelligent Context Compression*
*Created: 2026-01-20*
