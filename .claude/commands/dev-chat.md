# /dev-chat — Browse Saved Dev Session Exports

Browse and read previously exported W5:Jarvis-dev conversation transcripts.

## Instructions for Claude

When the user runs `/dev-chat`:

1. **List available exports**:
   ```bash
   ls -lhS /Users/aircannon/Claude/Jarvis/.claude/exports/dev/export_dev_chat_*.txt 2>/dev/null
   ```
   If no exports exist, tell the user: "No dev chat exports found. Use `/export-dev` to create one."

2. **Build selection menu** — use AskUserQuestion with up to 4 most recent exports:
   - Parse each filename to extract the datetime: `export_dev_chat_YYYYMMDD-HHMMSS.txt`
   - Format as human-readable: "Feb 12, 2026 at 14:15 (45 KB, 892 lines)"
   - Sort by most recent first
   - If more than 4 exports exist, show the 4 most recent and note how many older ones exist

   Example AskUserQuestion:
   ```
   question: "Which dev chat export would you like to review?"
   options:
     - "Feb 12, 2026 at 14:15 (45 KB)" → most recent
     - "Feb 12, 2026 at 12:03 (112 KB)" → second
     - "Feb 11, 2026 at 22:30 (28 KB)" → third
     - "Show all exports" → list everything
   ```

3. **Display the selected export**:
   - Read the file using the Read tool
   - If the file exceeds 500 lines, ask: "This export is [N] lines. Show the full file, last 200 lines, or a summary?"
   - For "summary": show the first 20 lines and last 50 lines with a "[... N lines omitted ...]" marker

4. **If user selects "Show all exports"**:
   - List all exports with date, size, and line count
   - Let the user pick from the full list using another AskUserQuestion

## Notes

- Export directory: `.claude/exports/dev/`
- Files are created by `/export-dev`
- Exports are plain text (ANSI codes stripped)
