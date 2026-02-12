# /export-dev — Export Dev Session Chat

Export the current W5:Jarvis-dev conversation to a timestamped file for later review.

Captures the full tmux scrollback buffer of the current pane and saves it as clean text.

## Instructions for Claude

When the user runs `/export-dev`:

1. **Create export directory** (if missing):
   ```bash
   mkdir -p /Users/aircannon/Claude/Jarvis/.claude/exports/dev
   ```

2. **Generate timestamped filename**:
   ```bash
   EXPORT_FILE="/Users/aircannon/Claude/Jarvis/.claude/exports/dev/export_dev_chat_$(date +%Y%m%d-%H%M%S).txt"
   ```

3. **Capture the current pane's full scrollback** via tmux:
   ```bash
   $HOME/bin/tmux capture-pane -p -S - -E - | sed 's/\x1b\[[0-9;]*m//g' > "$EXPORT_FILE"
   ```
   - `-S -` = from start of scrollback buffer
   - `-E -` = to end of scrollback buffer
   - `-p` = print to stdout (instead of paste buffer)
   - `sed` strips ANSI color codes for clean text

4. **Report result**:
   - Print the file path and size
   - Print the line count
   - Confirm success

5. **Prune old exports** — keep the 30 most recent, remove older ones:
   ```bash
   ls -t /Users/aircannon/Claude/Jarvis/.claude/exports/dev/export_dev_chat_*.txt | tail -n +31 | xargs rm -f 2>/dev/null
   ```

## Example Output

```
Exported dev chat to:
  /Users/aircannon/Claude/Jarvis/.claude/exports/dev/export_dev_chat_20260212-141530.txt
  Size: 45.2 KB | Lines: 892
  (30 exports retained, 0 pruned)
```

## Notes

- This captures terminal scrollback, not the raw .jsonl session file
- Scrollback depth depends on tmux `history-limit` (currently 10,000 lines)
- For very long sessions, early content may be truncated by the scrollback buffer
- Run periodically during long sessions to preserve full history
- Browse saved exports with `/dev-chat`
