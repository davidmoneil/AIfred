# /context-loss

Document when Claude forgets context after compaction. Builds evidence for improving compaction-essentials.md.

## Usage

```
/context-loss "description of what was forgotten"
```

## Examples

```
/context-loss "forgot that Archon has three layers: Nous, Pneuma, Soma"
/context-loss "didn't follow Wiggum Loop - skipped review step"
/context-loss "forgot to use Memory MCP for cross-session knowledge"
/context-loss "lost track of current milestone (M3)"
/context-loss "forgot paths-registry.yaml for project locations"
```

## Workflow

When invoked:

1. **Log the report** to `.claude/logs/context-loss-reports.jsonl`:
   ```json
   {
     "timestamp": "2026-01-23T10:30:00Z",
     "forgotten": "description from user",
     "category": "archon|wiggum|mcp|paths|patterns|orchestration|other",
     "session_id": "CLAUDE_SESSION_ID value"
   }
   ```

2. **Acknowledge** the report was captured

3. **Check for patterns** - if same category reported 3+ times:
   - Suggest adding to `compaction-essentials.md`
   - Show count of similar reports

4. **Re-orient** - briefly restate the forgotten context so Claude has it again

## Categories

| Category | What It Covers |
|----------|----------------|
| `archon` | Archon architecture (Nous/Pneuma/Soma layers) |
| `wiggum` | Wiggum Loop workflow (Execute-Check-Review-Drift-Context) |
| `mcp` | MCP tool usage preferences |
| `paths` | File locations, project structure |
| `patterns` | Design patterns, standards |
| `orchestration` | Task orchestration, AC components |
| `other` | Anything else |

## Log Location

`.claude/logs/context-loss-reports.jsonl`

## Review Process

Periodically review logs to identify:
- Frequently forgotten context -> add to compaction-essentials.md
- One-off losses -> may not need action
- Pattern changes -> update essentials when workflows evolve

## Related

- `.claude/context/compaction-essentials.md` - Core context preserved after compaction
- `/context-analyze` - Weekly context usage analysis

---

## Instructions for Claude

When user runs `/context-loss "<description>"`:

1. Read the description of what was forgotten

2. Infer the category from the description:
   - `archon` - Mentions layers, Nous, Pneuma, Soma, topology
   - `wiggum` - Mentions loop, review step, drift check, iteration
   - `mcp` - Mentions MCP, Memory, Git, Filesystem tools
   - `paths` - Mentions file locations, directories, registry
   - `patterns` - Mentions patterns, standards, conventions
   - `orchestration` - Mentions AC components, tasks, milestones
   - `other` - Default if unclear

3. Log to `.claude/logs/context-loss-reports.jsonl` (append JSONL):
   ```json
   {
     "timestamp": "ISO 8601 timestamp",
     "forgotten": "<description>",
     "category": "<inferred category>",
     "session_id": "<CLAUDE_SESSION_ID or 'unknown'>"
   }
   ```

4. Read existing logs and count occurrences of this category

5. Emit telemetry event (if telemetry-emitter available):
   ```javascript
   telemetry.emit('AC-04', 'context_loss_reported', {
     category: '<category>',
     similar_count: <count>
   });
   ```

6. Respond with:
   ```
   Logged context loss: "<description>"
   Category: <category>
   Similar reports: <count>

   [If count >= 3]
   This category has been reported multiple times. Consider adding to compaction-essentials.md.

   [Re-orientation]
   For reference: <brief restatement of the forgotten context with correct information>
   ```

7. If count >= 3 and item is NOT in compaction-essentials.md, offer to add it.
