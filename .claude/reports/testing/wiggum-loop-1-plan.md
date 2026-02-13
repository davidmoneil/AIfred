# Wiggum Loop 1 — Foundational Control & JICM Baseline

## Test Plan

### Phase A: Control Reliability (Tests 11-15)

**T11: Reliable prompt submission**
- Send 5 different prompts using split pattern (text → sleep 0.5 → Enter)
- Verify each prompt gets a response
- Pass: 5/5 responses received

**T12: Escape key interrupt**
- Send a long-running prompt to W0 (e.g., "Read every file in .claude/context/ and summarize each one")
- Wait 3s, then send ESC
- Capture output, verify response was interrupted
- Pass: Processing stopped, W0 returns to prompt

**T13: Slash command injection**
- Send `/status` to W0 via tmux send-keys
- Wait for response
- Capture output, verify status information appears
- Pass: Status output visible in capture

**T14: Multi-line prompt**
- Not testing yet — deferred to Loop 2 (risky, known tmux corruption issue)

**T15: W0 exit and relaunch**
- Deferred to Loop 3 — needs careful planning to not lose test state

### Phase B: Infrastructure Health (Tests 1, 4-7)

**T01: JICM state baseline**
- Read .jicm-state via watch-jicm.sh
- Verify state=WATCHING, version=6.1.0, threshold=55
- Pass: All fields valid

**T04: Session-start hook**
- Read AC-01 state file
- Verify started timestamp is today
- Pass: Timestamp is 2026-02-12

**T05: Command IPC**
- Write `/status` to .command-signal
- Wait 5s, verify file consumed
- Wait 10s, capture W0 output for status response
- Pass: Signal consumed AND status output visible

**T06: Ennoia recommendation**
- Read .ennoia-recommendation
- Verify non-empty and contains valid recommendation type
- Pass: File exists with valid content

**T07: Virgil dashboard state**
- Check .virgil-tasks.json and .virgil-agents.json exist
- Verify JSON is valid
- Pass: Files exist with valid JSON (may be empty arrays)

### Phase C: JICM Testing (Tests 2, 3, 8)

**T02: JICM full cycle** (DEFERRED to Loop 2 — needs low threshold + context filling)

**T03: JICM exit-mode signal**
- Touch .jicm-exit-mode.signal
- Wait 2 poll cycles (10s)
- Read watcher log for "exit protocol active" message
- Remove signal
- Pass: Log contains suppression message

**T08: Context growth tracking**
- Send 3 large file reads to W0
- After each, poll JICM state for context %
- Record: prompt sent, context % after, tokens after
- Pass: Context % increases monotonically

### Phase D: Resilience (Tests 9, 10)

**T09: Empty prompt recovery**
- Send empty Enter to W0
- Verify W0 doesn't crash (still responds to next prompt)
- Pass: W0 accepts next prompt normally

**T10: Session state consistency**
- Deferred to after more W0 activity (need meaningful state to check)

## Execution Order

1. T11 (reliable submission) — MUST pass first, everything depends on this
2. T01 (JICM baseline) — read-only, safe
3. T04 (AC-01 state) — read-only, safe
4. T06, T07 (Ennoia, Virgil) — read-only, safe
5. T13 (slash command) — low risk
6. T09 (empty prompt) — low risk
7. T03 (exit-mode signal) — our new feature
8. T08 (context growth) — sends multiple prompts to W0
9. T05 (command IPC) — needs W0 idle
10. T12 (ESC interrupt) — moderate risk
