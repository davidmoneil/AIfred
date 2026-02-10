# F.1 Ennoia MVP — Implementation Plan

## Context

Ennoia is the "intent" layer of the Aion Trinity. Currently, all wake-up prompt text is hardcoded in the Watcher's `send_prompt_by_type()` function. This creates a design flaw: the Watcher (safety/mechanics) also owns the decision of WHAT to tell Jarvis when it wakes up. Ennoia should own intent; Watcher should own mechanics.

**Goal**: Upgrade ennoia.sh v0.1 (display-only) to v0.2 (writes `.ennoia-recommendation` signal file). Modify Watcher to read this file for RESUME-variant prompts, with graceful fallback to hardcoded text if Ennoia is down.

**Version arc**: Watcher v5.8.4 → v5.8.5, Ennoia v0.1 → v0.2

---

## Architecture

```
ENNOIA (30s cycle)                    WATCHER (5s cycle)
┌─────────────────────┐               ┌─────────────────────┐
│ detect_mode()       │               │ idle_hands monitor   │
│ get_current_work()  │               │ submit_with_variant()│
│ get_next_priority() │               │ send_prompt_by_type()│
│ write_recommendation│──writes──▶    │   ├─ read_ennoia_rec │
│   .ennoia-recommend │  (atomic)     │   │  (RESUME only)   │
│   ation             │               │   └─ fallback:       │
└─────────────────────┘               │      hardcoded text  │
                                      └─────────────────────┘
Ennoia crash → no file → Watcher uses hardcoded (JICM unaffected)
```

---

## Implementation Steps

### Step 1: ennoia.sh — Add context extraction helpers

**File**: `/Users/aircannon/Claude/Jarvis/.claude/scripts/ennoia.sh`
**Insert after**: `get_intent()` (line 82)

Add two new functions:
- `get_current_work()` — extracts Status line from `session-state.md`, truncates to 80 chars
- `get_next_priority()` — extracts first actionable item from `current-priorities.md`, truncates to 60 chars

Both return 0 on all paths (bash 3.2 `set -e` safety).

### Step 2: ennoia.sh — Add `write_recommendation()`

**File**: `/Users/aircannon/Claude/Jarvis/.claude/scripts/ennoia.sh`
**Insert after**: Step 1 functions

Core function that generates mode-appropriate prompt text:
- **arise**: `[SESSION-START] New session. Current: {work}. Next: {priority}. Read session-state.md + current-priorities.md, begin work. Do NOT just greet.`
- **resume**: `[JICM-RESUME] Context compressed and cleared. Read .compressed-context-ready.md, .in-progress-ready.md, and session-state.md — resume work immediately. Do NOT greet.`
- **attend/idle**: No recommendation (return 0, no file written)

Atomic write: `echo > .tmp` then `mv .tmp .ennoia-recommendation`

### Step 3: ennoia.sh — Wire into main loop + update status

**File**: `/Users/aircannon/Claude/Jarvis/.claude/scripts/ennoia.sh`
**Modify**: `render()` function

- Call `write_recommendation "$mode"` after the mode case block
- Update `.ennoia-status` to include `version: 0.2` and `recommendation_active: true/false`
- Add `REC: ready` indicator to dashboard footer
- Update header comment to v0.2

### Step 4: jarvis-watcher.sh — Add `read_ennoia_recommendation()`

**File**: `/Users/aircannon/Claude/Jarvis/.claude/scripts/jarvis-watcher.sh`

Add path constant `ENNOIA_RECOMMENDATION` in config section (~line 214).

Add reader function (~line 945, before `detect_idle_state()`):
- Checks file existence → returns empty if absent
- Checks staleness (>120s) → deletes stale, returns empty
- Validates format (must start with `[`) → returns empty if invalid
- Reads first line, deletes file (single-use consumption), returns text
- All paths return 0, echo result on stdout

### Step 5: jarvis-watcher.sh — Modify `send_prompt_by_type()`

**File**: `/Users/aircannon/Claude/Jarvis/.claude/scripts/jarvis-watcher.sh`
**Modify**: `send_prompt_by_type()` (lines 1107-1138)

Add at top of function, before `case` statement:
```
if prompt_type == "RESUME":
    read Ennoia recommendation
    if found: use it, return
    else: fall through to existing case statement
```

**Only RESUME variant checks Ennoia.** SIMPLE and MINIMAL (retry variants) always use hardcoded text for reliability.

Emergency paths (`handle_critical_state`) are unaffected — they call `send_text()` directly, never go through `send_prompt_by_type()`.

### Step 6: launch-jarvis-tmux.sh — Add Ennoia window

**File**: `/Users/aircannon/Claude/Jarvis/.claude/scripts/launch-jarvis-tmux.sh`
**Insert after**: line 154 (after Watcher window creation)

- Add Window 2 "Ennoia" with `new-window -d`
- Add `automatic-rename off` for window :2
- Update window listing (echo) and keyboard shortcuts help
- Guard with `-x` check (only launch if script is executable)

### Step 7: capability-map.yaml — Register Ennoia

**File**: `/Users/aircannon/Claude/Jarvis/.claude/context/psyche/capability-map.yaml`
**Insert after**: line 261 (after ac.10-ulfhedthnar, before compositions)

```yaml
  - id: aion.ennoia
    version: "0.2"
    when: "Session orchestration — intent-driven wake-up, session briefing"
    status: active
    script: .claude/scripts/ennoia.sh
    signal_files: [".ennoia-recommendation", ".ennoia-status"]
    consumed_by: "jarvis-watcher.sh send_prompt_by_type()"
    note: "Aion Trinity: Ennoia=intent, Watcher=mechanics, Virgil=navigation"
```

### Step 8: Version bumps and changelog

- Watcher: v5.8.4 → v5.8.5, add changelog entry
- Ennoia: v0.1 → v0.2, update header comment

---

## Critical Files

| File | Change Type | Lines |
|------|------------|-------|
| `.claude/scripts/ennoia.sh` | Major (add functions, wire) | +90 |
| `.claude/scripts/jarvis-watcher.sh` | Minor (add reader, modify 1 func) | +35 |
| `.claude/scripts/launch-jarvis-tmux.sh` | Minor (add window) | +12 |
| `.claude/context/psyche/capability-map.yaml` | Minor (add entry) | +8 |

---

## NOT in MVP scope (deferred)

- session-start.sh refactoring → v0.3
- Idle-time work scheduler → Phase J
- Auto-maintenance triggering → Phase J
- JICM dump prompt ownership → stays in Watcher (fixed template)
- Countdown timers → Phase J

---

## Verification

1. **Ennoia standalone**: Start ennoia.sh, wait 35s, verify `.ennoia-recommendation` exists with `[SESSION-START]` prefix
2. **Atomic write**: Verify no `.ennoia-recommendation.tmp` lingering
3. **Watcher integration**: Create fake recommendation, check Watcher log for "Using Ennoia recommendation"
4. **Graceful degradation**: Remove `.ennoia-recommendation`, verify Watcher falls back to hardcoded
5. **Staleness**: Touch file with old mtime, verify Watcher ignores and deletes
6. **Full JICM cycle**: Compress → /clear → resume with Ennoia running (check watcher log)
7. **tmux launcher**: Run `launch-jarvis-tmux.sh --fresh`, verify 3 windows listed

---

## Implementation Order

1. ennoia.sh changes (Steps 1-3) — self-contained, no dependencies
2. Watcher changes (Steps 4-5, 8) — minimal, additive reader
3. Launcher changes (Step 6) — wiring
4. Capability map (Step 7) — registration
5. Verification (V1-V7) — progressive unit → integration

At every intermediate state the system works: updated Ennoia writes files that nobody reads yet; updated Watcher reads files that don't exist yet and falls back to hardcoded.
