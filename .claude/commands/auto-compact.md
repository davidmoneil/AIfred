---
description: Autonomously execute /compact via signal-based watcher
allowed-tools: Bash(.claude/scripts/*)
---

# Auto Compact

Trigger the built-in `/compact` command autonomously via the signal-based watcher.

## Usage

When the user asks to "compact context", "reduce tokens", "summarize conversation", or similar:

### Step 1: Extract Instructions (if provided)

If the user specifies what to focus on during compaction, extract those instructions.

Examples:
- "compact focusing on the code changes" → instructions: "Focus on code changes"
- "compact and keep the error discussion" → instructions: "Preserve error discussion"
- "just compact" → instructions: "" (empty)

### Step 2: Create Signal

```bash
source .claude/scripts/signal-helper.sh && signal_compact "INSTRUCTIONS_HERE"
```

Replace `INSTRUCTIONS_HERE` with extracted instructions, or leave empty quotes for default behavior.

### Step 3: Inform User

```
Signal sent for /compact. The watcher will execute it in ~2 seconds.

The conversation will be compacted, preserving key context.
```

## Prerequisites

- Watcher must be running (check with `watcher_status`)
- If not running, inform user to use: `.claude/scripts/launch-jarvis-tmux.sh`

## Example

User: "Please compact the context, focusing on recent code changes"

Response:
1. Run: `source .claude/scripts/signal-helper.sh && signal_compact "Focus on recent code changes"`
2. Say: "Signal sent for /compact with focus on recent code changes. Executing momentarily."
