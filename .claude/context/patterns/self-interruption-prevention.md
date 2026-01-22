# Self-Interruption Prevention Pattern

**Created**: 2026-01-21
**Status**: Active Design Principle

## Problem

When Jarvis uses the autonomous command signal system, there's a risk of **self-interruption** — blocking on verification or waiting for command execution, which defeats the purpose of autonomous operation.

## Anti-Pattern (What NOT to do)

```
1. Send signal for /context
2. Check watcher status ← WRONG
3. Verify signal file exists ← WRONG
4. Wait for execution ← WRONG
5. Check output ← WRONG
```

This pattern causes Jarvis to "get stuck" waiting for a manual prompt, breaking the autonomous flow.

## Correct Pattern: Fire-and-Forget

```
1. Send signal for /context
2. Inform user briefly: "Signal sent for /context."
3. CONTINUE with other work immediately (auto-resume)
```

## Key Principles

### 1. Trust the Watcher
The watcher process is designed to be reliable. Once a signal is sent, trust that it will be executed. Don't verify.

### 2. Asynchronous by Design
The signal system is inherently asynchronous. Commands execute outside Jarvis's direct control. Embrace this — it's a feature, not a limitation.

### 3. Auto-Resume
After sending any autonomous signal, immediately continue with other work. Never block waiting for results.

### 4. No Verification Loops
Avoid any pattern that checks:
- Watcher status
- Signal file existence
- Command output
- Execution completion

### 5. Brief Acknowledgment Only
The only user communication needed is a brief confirmation that the signal was sent. No elaboration, no waiting.

## Implementation

All `auto-*` commands in `.claude/commands/` follow this pattern:

1. **Direct execution** (not `source`): `.claude/scripts/signal-helper.sh <command>`
2. **Brief inform**: "Signal sent for /<command>."
3. **Continue**: "**Continue with any other pending work** — do not wait"

## Related Files

- `.claude/scripts/signal-helper.sh` — Signal creation library
- `.claude/scripts/jarvis-watcher.sh` — Watcher that executes signals
- `.claude/commands/auto-*.md` — All autonomous command skills

## See Also

- Wiggum Loop pattern (autonomous iteration)
- JICM workflow (context compression)
