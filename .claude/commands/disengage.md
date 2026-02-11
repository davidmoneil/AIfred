---
description: Disengage Ulfhedthnar — return to normal Hippocrenae operation
allowed-tools: [Read, Write, Edit]
---

# /disengage — Ulfhedthnar Stand-Down

**Purpose**: Manually deactivate AC-10 Ulfhedthnar and return to standard operation.

**Usage**: `/disengage`

---

## Protocol

When `/disengage` is invoked:

1. **Clear signal state**: Reset `.claude/state/ulfhedthnar-signals.json`
2. **Save progress**: Archive current progress from `.claude/state/ulfhedthnar-progress.json`
3. **Update AC-10 state**: Set status back to "dormant" in `.claude/state/components/AC-10-ulfhedthnar.json`
4. **Resume JICM**: Remove `.claude/context/.jicm-sleep.signal` to restore threshold monitoring
5. **Emit telemetry**: `{ component: "AC-10", event_type: "disengage", data: { trigger: "command" } }`
6. **Generate report**: Write resolution/abandonment report to `.claude/reports/ulfhedthnar/`

## Execution Steps

### Step 1: Read current Ulfhedthnar state
```
Read .claude/state/ulfhedthnar-signals.json
Read .claude/state/ulfhedthnar-progress.json
Read .claude/state/components/AC-10-ulfhedthnar.json
```

### Step 2: Generate report
Write to `.claude/reports/ulfhedthnar/disengage-YYYY-MM-DD-HHmm.md`:
- Problem description (if any)
- Approaches tried and outcomes
- Partial solutions found
- Reason for disengagement
- Duration of override

### Step 3: Resume JICM
```bash
rm -f .claude/context/.jicm-sleep.signal
```
This restores JICM threshold monitoring after Ulfhedthnar stand-down.

### Step 4: Reset state
- Clear signals: `{ signals: [], active: false, ... }`
- Reset progress: `{ problem: null, iteration: 0, ... }`
- Set AC-10 status to "dormant"

### Step 5: Emit telemetry
```bash
echo '{"component":"AC-10","event_type":"disengage","data":{"trigger":"command"}}' | node .claude/hooks/telemetry-emitter.js
```

### Step 6: Confirm
Output: "Ulfhedthnar stands down. Returning to Hippocrenae harmony."

---

*Part of Jarvis AC-10 Ulfhedthnar — Neuros Override System*
