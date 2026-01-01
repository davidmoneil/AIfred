# Model Selection Standard

**Last Updated**: 2026-01-01
**Status**: Active

## Quick Reference

| Task Complexity | Model | Command |
|-----------------|-------|---------|
| Architecture, multi-system debugging | Opus | `/model opus` |
| General development (default) | Sonnet | `/model sonnet` |
| Quick lookups, status checks | Haiku | `/model haiku` |
| Unknown/mixed complexity | Auto | `/model opusplan` |

## Trigger Phrases

Switch to **Opus** when you think:
- "This is tricky..."
- "Need to reason through the architecture..."
- "Multiple systems or files involved..."
- "Design decision with trade-offs..."

Switch to **Haiku** for:
- "Just check if..."
- "What's the status of..."
- "Simple find/replace..."
- "Quick git operation..."

Stay on **Sonnet** for:
- Most daily development work
- Single-file edits
- Routine refactoring
- Documentation updates

## Hybrid Mode: `opusplan`

Use `/model opusplan` when task complexity is uncertain:
- Opus activates during planning/reasoning phases
- Auto-switches to Sonnet for execution
- Best of both without manual toggling

## Session Workflow Example

```bash
# Start session (default Sonnet)
claude

# Complex architecture task comes up
/model opus
# ... design work ...

# Back to implementation
/model sonnet
# ... coding ...

# Quick status check
/model haiku
# ... simple query ...
```

## Notes

- Model switches are instant and unlimited per session
- Context carries over between switches
- Check current model: `/status`
- Cost scales: Haiku < Sonnet < Opus

## Related

- @.claude/context/standards/severity-status-system.md - Task classification
