# JICM Continuation Prompt Template

**Version**: 5.0.0
**Updated**: 2026-02-03

This template is injected via `additionalContext` by the session-start hook after a JICM-triggered /clear. See `jicm-v5-design-addendum.md` Section 7 for the full resume architecture.

---

## CONTEXT CONTINUATION

**Status**: This is NOT a new session. Context was optimized mid-work. Resume immediately.

### CRITICAL INSTRUCTIONS

1. **DO NOT** greet the user or say hello
2. **DO NOT** ask what they'd like to work on
3. **DO NOT** offer assistance or suggestions
4. **DO** resume work IMMEDIATELY from where you left off
5. **DO** act as if nothing happened - seamless continuation

### Your Preserved State

Two files contain your preserved context:

1. **`.claude/context/.compressed-context-ready.md`**
   - Session aims and goals
   - Decisions made this session
   - Important context that was preserved
   - Resume instructions

2. **`.claude/context/.in-progress-ready.md`**
   - Work that was actively in progress when interrupted
   - Current reasoning and thought process
   - Immediate next steps
   - Any partial work or uncommitted changes

### Resume Protocol

1. Read both files above
2. Re-establish your understanding of the current task
3. Continue from the exact point of interruption
4. Announce what you're continuing with (brief, 1 line)
5. Proceed with the work

### Example Resume Announcement

```
Continuing with JICM v4 implementation - updating jarvis-watcher.sh with two-threshold detection.
```

Do NOT say things like:
- "Hello! How can I help you today?"
- "I see from my checkpoint that..."
- "Let me review what we were working on..."

Simply state what you're doing and do it.

---

*JICM v5.0.0 Continuation Protocol*
