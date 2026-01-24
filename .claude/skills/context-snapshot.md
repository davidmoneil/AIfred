---
description: Read captured context window data (statusline-based, no TUI scraping)
allowed-tools: Read, Bash
---

# Context Snapshot

Read the current context window status from the statusline capture file.

**Why this exists**: The `/context` slash command renders to an ephemeral TUI region and is NOT captured in `<local-command-stdout>` when triggered programmatically. This skill bypasses that limitation by reading data that Claude Code already captures via the status line.

## Quick Usage

```bash
# Get context percentage and tokens
cat ~/.claude/logs/statusline-input.json | jq '{
  used: .context_window.used_percentage,
  remaining: .context_window.remaining_percentage,
  total_tokens: (.context_window.total_input_tokens + .context_window.total_output_tokens),
  cost: .cost.total_cost_usd
}'
```

## Available Data

The existing `jarvis-statusline.sh` captures the full Claude Code status input to:
**`~/.claude/logs/statusline-input.json`**

This file contains:
- `context_window.used_percentage` - Current usage %
- `context_window.remaining_percentage` - Remaining %
- `context_window.total_input_tokens` - Total input tokens
- `context_window.total_output_tokens` - Total output tokens
- `context_window.current_usage` - Latest API call details
- `cost.total_cost_usd` - Session cost
- `transcript_path` - Path to session transcript
- And more

## Example Output

```json
{
  "used": 91,
  "remaining": 9,
  "total_tokens": 461993,
  "cost": 30.25
}
```

## Integration with JICM

For JICM (Just-In-Case Memory) threshold checks:
```bash
USED=$(cat ~/.claude/logs/statusline-input.json | jq -r '.context_window.used_percentage')
if [ "$USED" -ge 70 ]; then
    echo "JICM threshold reached: ${USED}%"
fi
```

## Data Freshness

The status line updates every 300ms during activity. The file is always current with the last status line render.

## Why Not /context?

When `/context` is injected via tmux/watcher:
1. Command executes (UI flickers)
2. Output renders to **ephemeral TUI region** (not scrollback)
3. Output is **NOT added to conversation transcript**
4. Output is **NOT available in `<local-command-stdout>`**

This skill reads the **same data** that `/context` would show, but from a file that's reliably captured.
