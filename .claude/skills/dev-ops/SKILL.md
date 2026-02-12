---
name: dev-ops
model: sonnet
version: 1.0.0
description: |
  Dev operations — autonomous testing of W0:Jarvis from W5:Jarvis-dev.
  Test infrastructure health, JICM cycles, command IPC, hooks, and state files.
  Triggers: "dev test", "test jarvis", "run tests", "dev-ops", "check jarvis",
  "test jicm", "test hooks", "test ipc", "send to jarvis", "capture jarvis",
  "watch jicm", "restart watcher".
category: development
tags: [testing, dev, jicm, tmux, automation]
created: 2026-02-11
---

# Dev-Ops Skill — Autonomous Testing from Jarvis-dev

Test W0:Jarvis autonomously from W5:Jarvis-dev. Send prompts, capture output,
monitor JICM state, and validate infrastructure — all via bash scripts called
through the Bash tool.

---

## Overview

This skill enables Jarvis-dev (W5) to autonomously test the primary Jarvis session (W0).
All scripts live in `.claude/scripts/dev/` and are designed to be called via the Bash tool.

**Architecture**:
```
W0: Jarvis        — SYSTEM UNDER TEST (live Claude Code, --fresh)
W1: Watcher       — JICM v6.1, monitors W0
W4: Commands      — Command handler, targets W0
W5: Jarvis-dev    — TEST DRIVER (you are here)
```

**Isolation**: Watcher and command-handler hardcode `${TMUX_SESSION}:0` — W5 is invisible.

**Prerequisites**:
- Launched via `launch-jarvis-tmux.sh --dev`
- W0 (Jarvis) active and idle
- W1 (Watcher) running

---

## Quick Actions

| Need | Command |
|------|---------|
| Run full test suite | `bash .claude/tests/jarvis-live-tests.sh` |
| Send prompt to W0 | `bash .claude/scripts/dev/send-to-jarvis.sh "prompt" --wait 30` |
| Check W0 idle | `bash .claude/scripts/dev/send-to-jarvis.sh --check-idle` |
| Capture W0 output | `bash .claude/scripts/dev/capture-jarvis.sh --tail 20` |
| Check JICM state | `bash .claude/scripts/dev/watch-jicm.sh --once --json` |
| Restart watcher | `bash .claude/scripts/dev/restart-watcher.sh --threshold 15` |

---

## Script Reference

| Script | Path | Purpose |
|--------|------|---------|
| send-to-jarvis.sh | @.claude/scripts/dev/send-to-jarvis.sh | Send prompts to W0, wait for idle |
| capture-jarvis.sh | @.claude/scripts/dev/capture-jarvis.sh | Capture W0 pane output |
| watch-jicm.sh | @.claude/scripts/dev/watch-jicm.sh | JICM state (one-shot JSON or continuous) |
| restart-watcher.sh | @.claude/scripts/dev/restart-watcher.sh | Kill/restart watcher with custom threshold |
| jarvis-live-tests.sh | @.claude/tests/jarvis-live-tests.sh | Automated infrastructure test runner |

---

## Workflow 1: Automated Test Suite

Run the automated test runner that validates infrastructure health, dev tools, idle detection, and signal files — all without sending prompts to W0.

### Steps

1. **Verify W0 is idle** (prevents interfering with active work):
   ```bash
   bash .claude/scripts/dev/send-to-jarvis.sh --check-idle --timeout 10
   ```
   Exit 0 = idle. If exit 1, wait or skip.

2. **Run test suite**:
   ```bash
   bash .claude/tests/jarvis-live-tests.sh
   ```

3. **Parse output**: Look for the `Results:` line:
   - `X passed, 0 failed` = all good
   - Any `FAIL` lines = investigate

4. **Report**: Summarize pass/fail counts to user.

---

## Workflow 2: JICM Cycle Test (Autonomous)

Drive a full JICM compression cycle by lowering the threshold, filling W0's context, and monitoring state transitions. This is the primary integration test for JICM v6.1.

### Steps

1. **Verify prerequisites**:
   ```bash
   # Check W0 is idle
   bash .claude/scripts/dev/send-to-jarvis.sh --check-idle --timeout 10
   # Check watcher alive
   bash .claude/scripts/dev/watch-jicm.sh --once --json
   ```
   Verify JSON has `"state":"WATCHING"`.

2. **Lower threshold for fast cycle** (15% triggers quickly):
   ```bash
   bash .claude/scripts/dev/restart-watcher.sh --threshold 15
   ```

3. **Fill W0 context** — send large file reads to W0:
   ```bash
   bash .claude/scripts/dev/send-to-jarvis.sh "Read the file /Users/aircannon/Claude/Jarvis/.claude/context/designs/jicm-v5-design-addendum.md and provide a detailed summary of every section" --wait 90
   ```
   After W0 responds, check context % via `watch-jicm.sh --once --json`.
   If still below threshold, send another large read:
   ```bash
   bash .claude/scripts/dev/send-to-jarvis.sh "Read the file /Users/aircannon/Claude/Jarvis/.claude/context/psyche/capability-map.yaml and list every skill entry with its description" --wait 90
   ```
   Continue until `context_pct` exceeds 15%.

4. **Monitor state transitions** — poll every 5s for up to 300s:
   ```bash
   bash .claude/scripts/dev/watch-jicm.sh --once --json
   ```
   Expected progression: `WATCHING` -> `HALTING` -> `COMPRESSING` -> `CLEARING` -> `RESTORING` -> `WATCHING`

   Record each state change with timestamp. If stuck in one state for > 120s, flag as potential issue.

5. **Validate cycle completion**:
   - State returned to `WATCHING`
   - `context_pct` < 15% (post-clear reset)
   - `compressions` count incremented (was 0, now 1+)
   - Compressed context file exists:
     ```bash
     ls -la /Users/aircannon/Claude/Jarvis/.claude/context/.compressed-context-ready.md
     ```

6. **Restore production threshold**:
   ```bash
   bash .claude/scripts/dev/restart-watcher.sh --threshold 55
   ```

7. **Report**: Print transition timeline and pass/fail summary.

---

## Workflow 3: Command IPC Test

Tests the signal-file IPC between command-handler (W4) and W0:Jarvis.

### Steps

1. **Verify W0 is idle**:
   ```bash
   bash .claude/scripts/dev/send-to-jarvis.sh --check-idle --timeout 10
   ```

2. **Write test signal** (use `/status` — safe, read-only):
   ```bash
   echo '/status' > /Users/aircannon/Claude/Jarvis/.claude/context/.command-signal
   ```

3. **Wait for signal consumption** (command-handler polls every 3s):
   ```bash
   sleep 5
   ls /Users/aircannon/Claude/Jarvis/.claude/context/.command-signal 2>/dev/null && echo "STILL_EXISTS" || echo "CONSUMED"
   ```
   Pass: `CONSUMED` (file removed by command-handler).

4. **Wait for W0 response** and capture output:
   ```bash
   sleep 10
   bash .claude/scripts/dev/capture-jarvis.sh --tail 30
   ```
   Verify W0 produced output related to status.

5. **Report**: Signal consumed (pass/fail) + response detected (pass/fail).

---

## Workflow 4: Hook Validation

Tests that hooks are producing expected signal files.

### Steps

1. **Check baseline signal files exist**:
   ```bash
   # JICM state file (watcher writes every 5s)
   ls -la /Users/aircannon/Claude/Jarvis/.claude/context/.jicm-state
   # Virgil tasks (hook writes on tool calls)
   ls -la /Users/aircannon/Claude/Jarvis/.claude/context/.virgil-tasks.json 2>/dev/null
   # Ennoia status
   ls -la /Users/aircannon/Claude/Jarvis/.claude/context/.ennoia-status 2>/dev/null
   ```

2. **Record timestamps** of current signal files.

3. **Trigger hook execution** by sending a prompt to W0:
   ```bash
   bash .claude/scripts/dev/send-to-jarvis.sh "Read the first 10 lines of CLAUDE.md" --wait 30
   ```

4. **Re-check signal files** — verify timestamps updated:
   ```bash
   ls -la /Users/aircannon/Claude/Jarvis/.claude/context/.jicm-state
   ls -la /Users/aircannon/Claude/Jarvis/.claude/context/.virgil-tasks.json 2>/dev/null
   ```
   Pass: `.jicm-state` updated (watcher still running). Virgil/Ennoia files updated if hooks fired.

5. **Report**: Per-file timestamp comparison (pass = updated, fail = stale).

---

## Workflow 5: Prompt Delivery + Idle Detection

Validates the core send-to-jarvis.sh functionality.

### Steps

1. **Send a simple prompt** with idle wait:
   ```bash
   bash .claude/scripts/dev/send-to-jarvis.sh "What is 2+2? Reply with just the number." --wait 30
   ```
   Exit code 0 = idle detected within 30s (pass).

2. **Capture and verify response**:
   ```bash
   bash .claude/scripts/dev/capture-jarvis.sh --tail 10
   ```
   Look for "4" in the output.

3. **Report**: Delivery (pass if exit 0) + response validation (pass if "4" found).

---

## Troubleshooting

| Issue | Resolution |
|-------|------------|
| W0 never goes idle | Send ESC: `bash .claude/scripts/dev/send-to-jarvis.sh --escape-first ""` |
| Watcher won't restart | Check PID file, force kill, inspect W1 pane |
| Signals not consumed | Verify command-handler running: `tmux list-windows -t jarvis` should show W4 |
| JICM stuck in COMPRESSING | Check for `.compression-in-progress` flag, compression agent may have timed out |
| Tests report session not found | Verify TMUX_SESSION env var matches session name |

---

## Related

- @.claude/scripts/jicm-watcher.sh — JICM v6 watcher (system under test)
- @.claude/scripts/command-handler.sh — Command signal processor (W4)
- @.claude/context/designs/jicm-v5-design-addendum.md — JICM architecture design
- @.claude/skills/autonomous-commands/SKILL.md — Command automation (related pattern)
- @.claude/scripts/launch-jarvis-tmux.sh — Launcher with --dev flag
