# Commit 4 (Revised v2): --dev Flag + dev-ops Skill + Autonomous Testing

## Context

JICM v6.1 commits 1-3 are complete and pushed. The user needs a **testing infrastructure** where they sit in Jarvis-dev (W5) and direct it to autonomously test the primary Jarvis session (W0). The `--dev` flag adds Jarvis-dev as a window to the existing launcher. A **dev-ops Skill** wires all dev utilities into slash commands so Jarvis-dev can be directed to run tests — including "semi-automated" tests that Jarvis-dev handles by polling W0 itself.

**Key Direction**: Jarvis-dev = user's driver seat (Claude Code + Jarvis skills). W0 Jarvis = system under test. Jarvis-dev autonomously runs ALL tests against W0.

---

## Architecture

```
W0: Jarvis        — SYSTEM UNDER TEST (live Claude Code, --fresh)
W1: Watcher       — JICM v6.1, monitors W0 (existing, unchanged)
W2: Ennoia        — (existing, unchanged)
W3: Virgil        — (existing, unchanged)
W4: Commands      — Command handler, targets W0 (existing, unchanged)
W5: Jarvis-dev    — TEST DRIVER (live Claude Code, --continue, dev-ops Skill)
```

**Isolation**: Already achieved — watcher/command-handler hardcode `${TMUX_SESSION}:0`, so W5 is invisible. Hooks fire in both (acceptable). `JARVIS_SESSION_ROLE=dev` env var in W5 for optional hook differentiation.

**Testing Model**: User says `/dev-test` in W5 -> Jarvis-dev reads dev-ops Skill -> executes bash scripts via Bash tool -> polls W0 pane/state files -> validates results -> reports pass/fail. All autonomous.

---

## Cleanup (from rejected mock approach)

```bash
rm -f .claude/scripts/dev/jicm-mock-pane.sh
rm -f .claude/scripts/dev/mock-compression-agent.sh
rm -f .claude/scripts/dev/launch-jarvis-tmux-dev.sh
rm -f .claude/tests/jicm-test-scenarios.sh
git checkout .claude/tests/test-jicm-v6.sh  # revert mock-pane Group 28
```

---

## Deliverables (8 new files + 4 edits)

| # | File | Action | Lines |
|---|------|--------|-------|
| 1 | `.claude/scripts/launch-jarvis-tmux.sh` | EDIT | +25 |
| 2 | `.claude/scripts/dev/send-to-jarvis.sh` | CREATE | ~120 |
| 3 | `.claude/scripts/dev/capture-jarvis.sh` | CREATE | ~80 |
| 4 | `.claude/scripts/dev/watch-jicm.sh` | CREATE | ~100 |
| 5 | `.claude/scripts/dev/restart-watcher.sh` | CREATE | ~100 |
| 6 | `.claude/skills/dev-ops/SKILL.md` | CREATE | ~300 |
| 7 | `.claude/commands/dev-test.md` | CREATE | ~50 |
| 8 | `.claude/tests/jarvis-live-tests.sh` | CREATE | ~300 |
| 9 | `.claude/tests/test-jicm-v6.sh` | EDIT (+Group 28) | ~+60 |
| 10 | `.claude/context/psyche/capability-map.yaml` | EDIT | +8 |
| 11 | `.claude/skills/_index.md` | EDIT | +2 |

---

## Step 1: Add `--dev` to `launch-jarvis-tmux.sh`

**File**: `/Users/aircannon/Claude/Jarvis/.claude/scripts/launch-jarvis-tmux.sh`

### Changes

1. **Variable** (line 46): Add `DEV_MODE=false`
2. **Arg parsing** (line 48): Add `--dev|-d) DEV_MODE=true; shift ;;`
3. **W0 behavior change**: When `--dev`, force W0 to `--fresh` (override `FRESH_MODE=true`):

```bash
# --dev implies W0 gets --fresh
if [[ "$DEV_MODE" == "true" ]]; then
    FRESH_MODE=true
fi
```

4. **After W4 creation** (after line 192): Add Jarvis-dev window:

```bash
# W5: Jarvis-dev (second Claude session — test driver, with --continue)
if [[ "$DEV_MODE" == "true" ]]; then
    CLAUDE_ENV_DEV="ENABLE_TOOL_SEARCH=true CLAUDE_CODE_MAX_OUTPUT_TOKENS=20000 JARVIS_SESSION_ROLE=dev"
    CLAUDE_CMD_DEV="claude --dangerously-skip-permissions --verbose --continue"
    "$TMUX_BIN" new-window -t "$SESSION_NAME" -n "Jarvis-dev" -d \
        "cd '$PROJECT_DIR' && export $CLAUDE_ENV_DEV && $CLAUDE_CMD_DEV"
    "$TMUX_BIN" set-window-option -t "$SESSION_NAME:5" automatic-rename off 2>/dev/null || true
fi
```

5. **Banner** (line 208+): Add dev window to output:

```bash
[[ "$DEV_MODE" == "true" ]] && echo "  Window 5: Jarvis-dev (test driver)"
```

6. **Keyboard shortcuts help**: Add W5 reference when --dev.

**Key decisions**:
- W0: `--fresh` (clean slate for test isolation)
- W5: `--continue` (resumes Jarvis-dev with all context, skills, memory)
- W5: No `--debug` / `--debug-file` (avoids debug stream collision with W0)
- W5: Gets `JARVIS_SESSION_ROLE=dev` env var for optional hook filtering

---

## Step 2: `send-to-jarvis.sh` (~120 lines)

**Path**: `.claude/scripts/dev/send-to-jarvis.sh`
**Purpose**: Send prompt to W0 (Jarvis) via tmux send-keys, optionally wait for idle

### Interface

```
Usage: send-to-jarvis.sh "prompt text" [--wait SEC] [--escape-first]
       send-to-jarvis.sh --check-idle [--timeout SEC]

Options:
  "prompt text"       Text to send to Jarvis (W0)
  --wait SEC          Wait up to SEC seconds for idle after sending (default: 0)
  --escape-first      Send ESC before prompt (cancel pending input)
  --check-idle        Just check if W0 is idle (exit 0=idle, 1=busy)
  --timeout SEC       Timeout for idle check (default: 30)
  --target W:P        Override tmux target (default: $TMUX_SESSION:0)
  -h, --help
```

### Key Functions

- `send_escape()` — `tmux send-keys -t $TARGET Escape`
- `send_prompt(text)` — `tmux send-keys -t $TARGET -l "$text"` + `tmux send-keys -t $TARGET C-m`
- `is_idle()` — Capture pane, check last 5 lines for idle pattern (returns 0/1)
- `wait_for_idle(timeout)` — Poll `is_idle()` every 2s up to timeout
- `main()` — Parse args, validate session, send, optionally wait

### Idle Detection (reuses watcher pattern)

```bash
IDLE_PATTERN='Interrupted.*What should Claude do'
# Alternative: bare ❯ at start of last non-empty line without spinner chars
```

Poll every 2s. Exit codes: 0=idle, 1=timeout, 2=session-not-found.

---

## Step 3: `capture-jarvis.sh` (~80 lines)

**Path**: `.claude/scripts/dev/capture-jarvis.sh`
**Purpose**: Capture W0 pane output to stdout or file

### Interface

```
Usage: capture-jarvis.sh [--tail N] [--file PATH] [--grep PATTERN] [--target W:P]

Options:
  --tail N            Show only last N lines (default: all visible)
  --file PATH         Write to file instead of stdout
  --grep PATTERN      Filter output lines matching PATTERN
  --target W:P        Override tmux target (default: $TMUX_SESSION:0)
  --history N         Capture N lines of scrollback (default: visible only)
  -h, --help
```

### Implementation

Wrapper around `tmux capture-pane -t $TARGET -p [-S -N]`. Adds:
- `--tail` via `tail -n $N`
- `--grep` via `grep -E "$PATTERN"`
- `--file` via redirect
- `--history` via `capture-pane -S -$N`
- Session existence validation

---

## Step 4: `watch-jicm.sh` (~100 lines)

**Path**: `.claude/scripts/dev/watch-jicm.sh`
**Purpose**: JICM state dashboard — supports both continuous mode and one-shot mode

### Interface

```
Usage: watch-jicm.sh [--once] [--json] [--interval SEC]

Options:
  --once              Print state once and exit (for Jarvis-dev Bash calls)
  --json              Output as JSON (for programmatic parsing)
  --interval SEC      Refresh interval in continuous mode (default: 2)
  -h, --help
```

### One-Shot Mode (critical for Jarvis-dev automation)

```bash
watch-jicm.sh --once --json
# Output: {"state":"WATCHING","context_pct":42,"tokens":84000,"compressions":0,"errors":0,"sleeping":false}
```

This lets Jarvis-dev call it via `Bash` tool and parse the JSON result.

### Continuous Mode (for user terminal viewing)

```
JICM State Monitor
  State:        WATCHING
  Context:      [████████░░░░░░░░] 42%
  Tokens:       84,000 / 200,000
  Compressions: 0
  Updated:      15:42:03
```

---

## Step 5: `restart-watcher.sh` (~100 lines)

**Path**: `.claude/scripts/dev/restart-watcher.sh`
**Purpose**: Kill and restart JICM watcher with custom threshold

### Interface

```
Usage: restart-watcher.sh [--threshold PCT] [--interval SEC] [--kill-only]

Options:
  --threshold PCT     Compression trigger % (default: 55)
  --interval SEC      Poll interval (default: 5)
  --kill-only         Kill watcher without restarting
  -h, --help
```

### Implementation

1. **Kill**: Read `.jicm-watcher.pid` -> `kill $PID` -> wait 3s -> force kill if needed
2. **Clean**: Remove `.jicm-state`, `.compression-done.signal`, `.jicm-watcher.pid`
3. **Restart**: `tmux respawn-window -k -t $TMUX_SESSION:1 "cd $PROJECT_DIR && $WATCHER --threshold $N --interval $S; echo Watcher stopped.; read"`
4. **Verify**: Wait 5s, check `.jicm-watcher.pid` exists, print new PID

**Key use case**: `restart-watcher.sh --threshold 15` for fast JICM cycle testing.

---

## Step 6: `dev-ops` Skill (~300 lines)

**Path**: `.claude/skills/dev-ops/SKILL.md`
**Purpose**: Teaching Jarvis-dev how to autonomously test W0:Jarvis

This is the **core deliverable** — it gives Jarvis-dev all the knowledge to run tests.

### Frontmatter

```yaml
---
name: dev-ops
model: sonnet
version: 1.0.0
description: |
  Dev operations — autonomous testing of W0:Jarvis from W5:Jarvis-dev.
  Test infrastructure health, JICM cycles, command IPC, hooks, and state files.
  Triggers: "dev test", "test jarvis", "run tests", "dev-ops", "check jarvis"
category: development
tags: [testing, dev, jicm, tmux, automation]
created: 2026-02-11
---
```

### Skill Sections

**1. Quick Actions Table**

| Need | Action |
|------|--------|
| Run full test suite | `bash .claude/scripts/dev/../../tests/jarvis-live-tests.sh` |
| Send prompt to W0 | `bash .claude/scripts/dev/send-to-jarvis.sh "prompt" --wait 30` |
| Capture W0 output | `bash .claude/scripts/dev/capture-jarvis.sh --tail 20` |
| Check JICM state | `bash .claude/scripts/dev/watch-jicm.sh --once --json` |
| Restart watcher | `bash .claude/scripts/dev/restart-watcher.sh --threshold 15` |
| Check W0 idle | `bash .claude/scripts/dev/send-to-jarvis.sh --check-idle` |

**2. Automated Test Suite Workflow**

Step-by-step for running `jarvis-live-tests.sh`:
1. Verify W0 is idle (send-to-jarvis --check-idle)
2. Run the test runner: `bash .claude/tests/jarvis-live-tests.sh`
3. Parse output for pass/fail counts
4. Report results

**3. JICM Cycle Test Workflow (formerly "semi-automated")**

This is the key workflow where Jarvis-dev autonomously drives a full JICM cycle:

```
1. Verify prerequisites
   - W0 idle: bash .claude/scripts/dev/send-to-jarvis.sh --check-idle
   - Watcher alive: ps -p $(cat .claude/context/.jicm-watcher.pid)
   - State = WATCHING: bash .claude/scripts/dev/watch-jicm.sh --once --json

2. Lower threshold for fast cycle
   - bash .claude/scripts/dev/restart-watcher.sh --threshold 15

3. Fill W0 context (send large file reads to W0)
   - bash .claude/scripts/dev/send-to-jarvis.sh "Read the file /Users/aircannon/Claude/Jarvis/.claude/context/designs/jicm-v5-design-addendum.md and summarize it" --wait 60
   - Repeat with more files until context grows

4. Monitor state transitions (poll .jicm-state)
   - Poll every 5s: bash .claude/scripts/dev/watch-jicm.sh --once --json
   - Expected progression: WATCHING -> HALTING -> COMPRESSING -> CLEARING -> RESTORING -> WATCHING
   - Record timestamps for each transition
   - Timeout: 300s total

5. Validate cycle completion
   - State returned to WATCHING
   - context_pct < 15% (post-clear)
   - compressions count incremented
   - .compressed-context-ready.md exists

6. Restore watcher to production threshold
   - bash .claude/scripts/dev/restart-watcher.sh --threshold 55
```

**4. Command IPC Test Workflow**

Tests the signal-file IPC between command-handler and W0:

```
1. Verify W0 is idle
2. Write test signal: echo '/status' > .claude/context/.command-signal
3. Wait 5s, verify signal consumed (file removed)
4. Capture W0 output: capture-jarvis.sh --tail 30 --grep "status\|context\|session"
5. Validate response appeared
```

**5. Hook Validation Workflow**

Tests that hooks are producing expected signal files:

```
1. Check .virgil-tasks.json exists and is recent (< 300s old)
2. Check .jicm-state exists and is recent (< 30s old)
3. Check .ennoia-status exists
4. Send a prompt to W0 that triggers hooks:
   bash .claude/scripts/dev/send-to-jarvis.sh "Read CLAUDE.md" --wait 30
5. Re-check signal files are updated (timestamps changed)
```

**6. Prompt Delivery + Idle Detection Test**

```
1. bash .claude/scripts/dev/send-to-jarvis.sh "What is 2+2?" --wait 30
2. Exit code 0 = idle detected (pass)
3. capture-jarvis.sh --tail 10 --grep "4"
4. Verify "4" appears in output
```

**7. Script Reference**

| Script | Path | Purpose |
|--------|------|---------|
| send-to-jarvis.sh | `.claude/scripts/dev/send-to-jarvis.sh` | Send prompts to W0, wait for idle |
| capture-jarvis.sh | `.claude/scripts/dev/capture-jarvis.sh` | Capture W0 pane output |
| watch-jicm.sh | `.claude/scripts/dev/watch-jicm.sh` | JICM state (one-shot or continuous) |
| restart-watcher.sh | `.claude/scripts/dev/restart-watcher.sh` | Restart watcher with custom threshold |
| jarvis-live-tests.sh | `.claude/tests/jarvis-live-tests.sh` | Automated test runner |

**8. Troubleshooting**

- If W0 never goes idle: check for stuck agent, send ESC via `send-to-jarvis.sh --escape-first ""`
- If watcher won't restart: check PID file, force kill, check W1 pane
- If signals not consumed: verify command-handler running in W4

---

## Step 7: `/dev-test` Command (~50 lines)

**Path**: `.claude/commands/dev-test.md`

```yaml
---
description: Run dev-ops tests against W0:Jarvis from Jarvis-dev
argument-hint: [suite|jicm|ipc|hooks|all]
allowed-tools: [Bash, Read, Glob, Grep]
---
```

### Body

Tells Jarvis-dev to:
1. Read the dev-ops Skill (`@.claude/skills/dev-ops/SKILL.md`)
2. Based on argument, execute the appropriate workflow:
   - `all` or no arg: Run full automated test suite via `jarvis-live-tests.sh`, then JICM cycle test
   - `suite`: Just the automated test runner (`jarvis-live-tests.sh`)
   - `jicm`: JICM cycle test workflow (autonomous)
   - `ipc`: Command IPC test workflow
   - `hooks`: Hook validation workflow
3. Report results with pass/fail counts

### Usage from Jarvis-dev

```
/dev-test          # Run everything
/dev-test suite    # Just automated suite
/dev-test jicm     # JICM cycle test
/dev-test ipc      # Command signal IPC test
/dev-test hooks    # Hook validation
```

---

## Step 8: `jarvis-live-tests.sh` (~300 lines)

**Path**: `.claude/tests/jarvis-live-tests.sh`
**Purpose**: Automated test runner — can be run standalone OR by Jarvis-dev via Bash tool

### Prerequisites

- tmux session `jarvis` (or `$TMUX_SESSION`) running
- W0 (Jarvis) active
- W1 (Watcher) running

### Test Groups

**Group 1: Infrastructure Health (6 tests)**

| Test | Method | Pass Criteria |
|------|--------|---------------|
| 1.1 | `tmux has-session -t $SESSION` | Exit 0 |
| 1.2 | `tmux list-windows -t $SESSION` contains "Jarvis" | Found |
| 1.3 | `.jicm-watcher.pid` exists, `ps -p $PID` | Process alive |
| 1.4 | `.jicm-state` exists | File present |
| 1.5 | State == WATCHING | awk parse |
| 1.6 | Context % in 0-100 | awk parse, numeric check |

**Group 2: Dev Tool Validation (6 tests)**

| Test | Method | Pass Criteria |
|------|--------|---------------|
| 2.1 | `send-to-jarvis.sh -h` | Exit 0 |
| 2.2 | `capture-jarvis.sh -h` | Exit 0 |
| 2.3 | `watch-jicm.sh -h` | Exit 0 |
| 2.4 | `restart-watcher.sh -h` | Exit 0 |
| 2.5 | `capture-jarvis.sh --tail 5` | Non-empty output |
| 2.6 | `watch-jicm.sh --once --json` | Valid JSON with "state" key |

**Group 3: W0 Idle Detection (2 tests)**

| Test | Method | Pass Criteria |
|------|--------|---------------|
| 3.1 | `send-to-jarvis.sh --check-idle --timeout 10` | Exit 0 (idle) |
| 3.2 | Capture pane, grep idle pattern | Pattern found |

**Group 4: Signal File Health (3 tests)**

| Test | Method | Pass Criteria |
|------|--------|---------------|
| 4.1 | `.jicm-state` age < 30s | Recent |
| 4.2 | `.virgil-tasks.json` exists | File present |
| 4.3 | `.ennoia-status` exists | File present |

**Output Format**: Standard pass/fail with counts, compatible with Jarvis-dev parsing.

```
Group 1: Infrastructure Health
  PASS  tmux session exists
  PASS  Jarvis window exists
  PASS  Watcher PID valid
  ...

Results: 17 passed, 0 failed, 0 skipped
```

**Note**: This test runner does NOT include JICM cycle, IPC, or hook mutation tests. Those are in the dev-ops Skill workflows and run by Jarvis-dev autonomously (they require sending prompts to W0 and waiting).

---

## Step 9: Group 28 Tests in `test-jicm-v6.sh` (~12 tests)

Replace the mock-pane Group 28 with dev tool validation tests.

| Test | Validates |
|------|-----------|
| 28.1 | `send-to-jarvis.sh` exists and is executable |
| 28.2 | `capture-jarvis.sh` exists and is executable |
| 28.3 | `watch-jicm.sh` exists and is executable |
| 28.4 | `restart-watcher.sh` exists and is executable |
| 28.5 | `jarvis-live-tests.sh` exists and is executable |
| 28.6 | All 5 scripts use `set -euo pipefail` |
| 28.7 | `send-to-jarvis.sh` has `--check-idle` function |
| 28.8 | `watch-jicm.sh` has `--once` and `--json` modes |
| 28.9 | `restart-watcher.sh` references `.jicm-watcher.pid` |
| 28.10 | dev-ops Skill exists at `.claude/skills/dev-ops/SKILL.md` |
| 28.11 | `/dev-test` command exists at `.claude/commands/dev-test.md` |
| 28.12 | `launch-jarvis-tmux.sh` has `--dev` flag |

---

## Step 10: Registration Edits

### capability-map.yaml

Add under `skills:`:

```yaml
  - id: skill.dev-ops
    model: sonnet
    version: 1.0.0
    when: "Development testing — test W0:Jarvis from Jarvis-dev, JICM cycles, IPC, hooks"
    tools: [Bash, Read, Glob, Grep]
    file: .claude/skills/dev-ops/SKILL.md
```

### _index.md

Add row to main skills table:

```markdown
| [dev-ops](dev-ops/SKILL.md) | Dev testing — autonomous W0 testing from Jarvis-dev | /dev-test |
```

---

## Implementation Order

1. Cleanup: Remove 4 mock pane files, `git checkout test-jicm-v6.sh`
2. Edit `launch-jarvis-tmux.sh` — add `--dev/-d` flag
3. Create `send-to-jarvis.sh` (foundation — everything else builds on this)
4. Create `capture-jarvis.sh`
5. Create `watch-jicm.sh`
6. Create `restart-watcher.sh`
7. Create `jarvis-live-tests.sh` (automated test runner)
8. Create `dev-ops/SKILL.md` (the skill — references all scripts above)
9. Create `dev-test.md` command
10. Edit `test-jicm-v6.sh` — add Group 28
11. Edit `capability-map.yaml` — register dev-ops
12. Edit `_index.md` — add dev-ops row
13. Run unit test suite (228 existing + 12 new Group 28)
14. Commit + push

---

## Verification

### Unit tests (fast, offline)
```bash
bash .claude/tests/test-jicm-v6.sh
# Expect: 240+ passed (228 existing + 12 new Group 28), 0 failed
```

### Live verification (from Jarvis-dev W5, after launching with --dev)
```
User in W5: /dev-test suite       # Jarvis-dev runs automated test runner
User in W5: /dev-test jicm        # Jarvis-dev autonomously drives JICM cycle
User in W5: /dev-test ipc         # Jarvis-dev tests command signal IPC
User in W5: /dev-test hooks       # Jarvis-dev validates hook signal files
User in W5: /dev-test all         # Everything above
```

---

## Files Summary

| File | Action | Lines |
|------|--------|-------|
| `.claude/scripts/launch-jarvis-tmux.sh` | EDIT | +25 |
| `.claude/scripts/dev/send-to-jarvis.sh` | CREATE | ~120 |
| `.claude/scripts/dev/capture-jarvis.sh` | CREATE | ~80 |
| `.claude/scripts/dev/watch-jicm.sh` | CREATE | ~100 |
| `.claude/scripts/dev/restart-watcher.sh` | CREATE | ~100 |
| `.claude/skills/dev-ops/SKILL.md` | CREATE | ~300 |
| `.claude/commands/dev-test.md` | CREATE | ~50 |
| `.claude/tests/jarvis-live-tests.sh` | CREATE | ~300 |
| `.claude/tests/test-jicm-v6.sh` | EDIT | ~+12 (net after revert) |
| `.claude/context/psyche/capability-map.yaml` | EDIT | +8 |
| `.claude/skills/_index.md` | EDIT | +2 |
| **Total new code** | | **~1,100 lines** |
