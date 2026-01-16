# /context-loss

Document when Claude forgets context after compaction. Builds evidence for improving compaction-essentials.md.

## Usage

```
/context-loss "description of what was forgotten"
```

## Examples

```
/context-loss "forgot that projects live in projects_root"
/context-loss "asked me to run docker command instead of executing"
/context-loss "didn't use MCP tools for git operations"
/context-loss "forgot PARC pattern before implementation"
```

## Workflow

When invoked:

1. **Log the report** to `.claude/logs/context-loss-reports.jsonl`:
   ```json
   {
     "timestamp": "2026-01-16T10:30:00Z",
     "forgotten": "description from user",
     "session": "current session name",
     "conversationLength": "estimated turns since compaction"
   }
   ```

2. **Acknowledge** the report was captured

3. **Check for patterns** - if same type of loss reported 3+ times:
   - Suggest adding to `compaction-essentials.md`
   - Show count of similar reports

4. **Re-orient** - briefly restate the forgotten context so Claude has it again

## Log Location

`.claude/logs/context-loss-reports.jsonl`

## Review Process

Periodically review logs to identify:
- Frequently forgotten context -> add to compaction-essentials.md
- One-off losses -> may not need action
- Pattern changes -> update essentials when workflows evolve

## Related

- `.claude/context/compaction-essentials.md` - Core context preserved after compaction
- `.claude/hooks/pre-compact.js` - Hook that injects preserved context

---

## Instructions for Claude

When user runs `/context-loss "<description>"`:

1. Read the description of what was forgotten

2. Log to `.claude/logs/context-loss-reports.jsonl`:
   ```javascript
   {
     "timestamp": new Date().toISOString(),
     "forgotten": "<description>",
     "category": "<infer: paths|automation|patterns|mcp|other>",
     "session": "<from .claude/logs/.current-session or 'unknown'>"
   }
   ```

3. Read existing logs and count occurrences of similar category

4. Respond with:
   ```
   Logged context loss: "<description>"
   Category: <category>
   Similar reports: <count>

   [If count >= 3]
   This has been reported multiple times. Consider adding to compaction-essentials.md.

   [Re-orientation]
   For reference: <brief restatement of the forgotten context>
   ```

5. If the forgotten item is NOT in compaction-essentials.md and count >= 3, offer to add it.
