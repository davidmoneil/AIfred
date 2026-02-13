# Wiggum Loops 2-10 — Test Plan

**Date**: 2026-02-12
**Prerequisite**: tmux session with W0-W5 windows active
**Dependency**: Loop 1 complete (foundational control + JICM baseline)

---

## Loop 2: JICM Cycle & Command IPC Deep Dive

### Brainstorm (15 ideas)
1. Full JICM compression cycle with low threshold (15%)
2. JICM cycle with context already near threshold
3. Re-test T05 Command IPC with split send-keys pattern
4. Command IPC with different commands (/status, /usage, /cost)
5. Command IPC concurrent signals (write while previous processing)
6. JICM sleep signal (Ulfhedthnar suppression)
7. JICM state transitions: WATCHING → HALTING → COMPRESSING → CLEARING → RESTORING → WATCHING
8. Compression agent output validation (checkpoint file contents)
9. JICM cooldown period enforcement (10min between cycles)
10. Context token count accuracy vs /context output
11. JICM watcher restart with custom threshold
12. Command whitelist enforcement (send blocked command)
13. Signal file format validation (malformed JSON)
14. Multiple rapid signals (queue behavior)
15. JICM state file atomic write verification

### Plan
**T02**: Full JICM cycle — restart watcher with `--threshold 15`, send large file reads to W0, observe full compress→clear→restore cycle
**T05-retry**: Command IPC with corrected split pattern — write signal, verify W0 shows response
**T16**: Command IPC multi-command — test /status, /usage, /cost sequentially via signals
**T17**: JICM sleep signal — touch `.jicm-sleep.signal`, verify watcher pauses, remove, verify resume
**T18**: Command whitelist enforcement — send `/settings` (blocked), verify rejection in watcher log
**T19**: Malformed signal — write invalid JSON to `.command-signal`, verify graceful handling
**T20**: Compression checkpoint validation — after T02 cycle, read `.compressed-context-ready.md` and validate structure

### Execution Order
1. T05-retry (quick validation of fix)
2. T16 (multi-command IPC)
3. T18 (whitelist enforcement)
4. T19 (malformed signal)
5. T17 (JICM sleep)
6. T02 (full JICM cycle — heavy, do last)
7. T20 (validate T02 output)

---

## Loop 3: Window Management & Cross-Window Operations

### Brainstorm
1. Send command to W1 (watcher) — verify it's running
2. Send command to W2 (Ennoia) — check state
3. Send command to W3 (Virgil) — check state
4. W4 (Commands) window interaction
5. W0 exit and relaunch (T15 from Loop 1)
6. Window respawn after crash
7. Cross-window state consistency (all windows agree on session)
8. Capture pane content from each window
9. Window existence verification (all 6 present)
10. tmux session info (creation time, activity)
11. Window reorder after loss/recreation
12. Scrollback buffer limits per window
13. Environment variable propagation across windows
14. Signal file visibility from all windows
15. PID file cross-reference (each window's process)

### Plan
**T21**: All-window health check — verify W0-W5 exist, capture 5 lines from each
**T22**: Cross-window PID audit — read PID files, verify processes alive
**T23**: W1 watcher interaction — capture pane, verify watching output
**T24**: W2 Ennoia state — capture pane, verify running
**T25**: W3 Virgil state — capture pane, verify running
**T26**: W4 Commands state — verify command-handler.sh running
**T27**: Scrollback capture depth — test `-S -10000` vs `-S -` for each window

---

## Loop 4: Hook System Validation

### Brainstorm
1. SessionStart hook fires on new session
2. PreToolUse hook fires before Bash calls
3. PostToolUse hook fires after tool completion
4. observation-tracker.js fires and appends
5. virgil-tracker.js fires and updates state
6. Hook error handling (what if hook throws?)
7. Hook execution time impact on tool calls
8. Hook matcher specificity (anchored regex)
9. Telemetry emitter hook fires
10. session-trigger.js self-launch injection
11. Hook file size (observation rotation at 500KB)
12. Multiple hooks on same event
13. Hook return value propagation
14. Hook environment (PROJECT_DIR, context vars)
15. Hook log output location

### Plan
**T28**: Observation tracker validation — send prompt to W0, read observations.yaml, verify new entry
**T29**: Telemetry emitter — read events-2026-02-12.jsonl, verify entries exist and are valid JSON
**T30**: Hook execution timing — send prompt, measure time between tool use and response
**T31**: Virgil tracker — send prompt to W0, read .virgil-tasks.json, verify update
**T32**: Observation rotation — check observations.yaml size, verify rotation logic would trigger
**T33**: Hook matcher regex — verify anchored patterns in settings.json match expected tools

---

## Loop 5: Resilience & Error Recovery

### Brainstorm
1. Kill watcher mid-cycle — does it recover?
2. Delete .jicm-state during WATCHING — does watcher recreate?
3. Corrupt .jicm-state (invalid YAML) — does watcher handle?
4. Remove PID file while watcher running
5. Send SIGTERM to watcher, verify graceful shutdown
6. Send SIGHUP to watcher — behavior?
7. Multiple watchers (start second instance) — conflict?
8. Fill context to 78.5% lockout ceiling
9. Network interruption simulation (rate limit response)
10. Disk full simulation (touch readonly file)
11. W0 crash during compression cycle
12. Signal file left orphaned (stale .compression-done.signal)
13. .command-signal file permissions (readonly)
14. Concurrent signal writers
15. Large signal file (oversized JSON)

### Plan
**T34**: Watcher graceful shutdown — send SIGTERM, verify log shows "shutting down"
**T35**: State file deletion recovery — rm .jicm-state, verify watcher recreates within 1 poll
**T36**: Stale signal cleanup — leave orphaned .compression-done.signal, restart watcher, verify cleanup
**T37**: Double watcher prevention — try starting second watcher, verify PID lock prevents it
**T38**: Corrupt state handling — write garbage to .jicm-state, observe watcher behavior
**T39**: Context ceiling approach — fill W0 context to ~75%, verify JICM escalation behavior

---

## Loop 6: Autonomic Component (AC) System

### Brainstorm
1. AC-01 launch state accuracy
2. AC-02 drift detection (does it track deviations?)
3. AC-03 remediation triggers
4. AC-04 JICM integration (already tested, cross-check)
5. AC-05 self-reflection output
6. AC-06 self-improvement cycle
7. AC-07 research integration
8. AC-08 maintenance check
9. AC-09 exit protocol (with exit-mode signal)
10. AC-10 Ulfhedthnar dormancy verification
11. AC state file format consistency
12. AC telemetry event emission
13. AC grade computation
14. Component status command output
15. AC interdependency (does AC-04 inform AC-02?)

### Plan
**T40**: AC state audit — read all 10 AC state files, verify format and timestamps
**T41**: AC telemetry audit — read today's events JSONL, verify AC events present
**T42**: AC-09 exit protocol with exit-mode signal — run /end-session, verify JICM pauses
**T43**: AC-10 dormancy — verify Ulfhedthnar state shows "dormant", no activation signals
**T44**: AC grade computation — run /jarvis-status or equivalent, capture AC grades

---

## Loop 7: Session Lifecycle

### Brainstorm
1. Session start → AC-01 fires → greeting displayed
2. Session state file updated on start
3. JICM session directory created
4. Ennoia recommendation generated on resume
5. Virgil state initialized
6. Commands handler started
7. Session checkpoint (/checkpoint)
8. Session export (/export)
9. Session end (/end-session) full protocol
10. Session resume after end
11. Context loss recovery
12. Session file sizes over time
13. Multiple sessions competing
14. Session ID tracking across restarts
15. JICM archive of previous sessions

### Plan
**T45**: Session start audit — verify AC-01 state, Ennoia status, Virgil JSON, JICM state all valid
**T46**: Export command — run /export via IPC, verify export file created
**T47**: Checkpoint command — run /checkpoint via IPC, verify state saved
**T48**: Session archive — verify JICM session archive directory structure
**T49**: Multi-session isolation — verify W5 session doesn't corrupt W0 state

---

## Loop 8: Performance & Timing

### Brainstorm
1. Prompt → response latency measurement
2. JICM poll interval accuracy (5s target)
3. Compression cycle total time
4. Context growth rate per prompt type
5. Hook execution overhead per tool call
6. Signal file consumption latency
7. Watcher CPU usage
8. Memory usage of watcher process
9. File I/O during compression
10. tmux send-keys latency
11. Idle detection accuracy
12. Cooldown timer accuracy
13. Token counting accuracy vs actual
14. Large prompt handling (>1000 chars)
15. Rapid fire prompts (stress test)

### Plan
**T50**: Prompt latency — send 5 simple prompts, measure response time (tmux activity change)
**T51**: JICM poll accuracy — check timestamps in watcher log, verify ~5s intervals
**T52**: Signal consumption latency — timestamp signal creation, log consumption, measure delta
**T53**: Context growth benchmark — send 10 varied prompts, chart context % after each
**T54**: Rapid prompt stress — send 3 prompts in quick succession (1s apart), verify all processed

---

## Loop 9: Edge Cases & Boundary Conditions

### Brainstorm
1. Unicode in prompts (emoji, CJK, RTL)
2. Very long single-line prompt (500+ chars)
3. Special characters in prompts (quotes, backslashes, pipes)
4. Empty .jicm-state file
5. .jicm-state with future timestamp
6. Context at exactly threshold (55.0%)
7. Context at 0% (fresh session)
8. Multiple exit-mode signals (idempotency)
9. Signal file with extra fields (forward compatibility)
10. Newlines in signal JSON values
11. tmux session with different name
12. Missing .claude/context/ directory
13. Read-only filesystem simulation
14. Very large observations.yaml (near rotation threshold)
15. Concurrent file writers (race conditions)

### Plan
**T55**: Unicode prompt — send emoji + CJK text to W0, verify response
**T56**: Long prompt — send 500-char prompt, verify no truncation
**T57**: Special characters — send prompt with quotes, backslashes, verify correct handling
**T58**: Threshold boundary — set threshold to current context %, verify trigger
**T59**: Idempotent exit-mode — touch signal twice, verify no double-log

---

## Loop 10: Integration & End-to-End Scenarios

### Brainstorm
1. Full session lifecycle: start → work → compress → clear → resume → end
2. Dev-ops loop: W5 sends test → W0 executes → W5 captures result
3. Autonomous command chain: signal /status → parse → signal /compact
4. JICM + AC integration: compression triggers AC-04 updates
5. Hook chain: PreToolUse → tool → PostToolUse → observation → telemetry
6. Export → dev-chat → read cycle
7. Watcher restart → verify all subsystems recover
8. Multi-window coordination: all windows report consistent state
9. Full Aion Quartet health: Ennoia + Virgil + Commands + Watcher all operational
10. Stress test: 20 rapid prompts → JICM threshold → compress → continue
11. Session persistence: exit and resume with same session ID
12. Error cascade: corrupt one file, verify system self-heals
13. Observability: all logs present, parseable, correlated
14. Recovery from failed compression (4/5 failed in Loop 1 session)
15. Comprehensive state snapshot: all files, all PIDs, all logs at one point in time

### Plan
**T60**: Full lifecycle test — complete session flow from start to end
**T61**: Dev-ops round-trip — W5 sends prompt, W0 responds, W5 captures and validates
**T62**: Aion Quartet health — all 4 subsystems operational simultaneously
**T63**: Comprehensive state snapshot — capture all state files, PIDs, log tails in single report
**T64**: Recovery from compression failure — induce failure, verify watcher enters cooldown and retries

---

## Test ID Summary

| Loop | Tests | Focus |
|------|-------|-------|
| 1 | T01-T15 | Foundational control + JICM baseline |
| 2 | T02,T05r,T16-T20 | JICM cycle + Command IPC |
| 3 | T21-T27 | Window management + cross-window ops |
| 4 | T28-T33 | Hook system validation |
| 5 | T34-T39 | Resilience & error recovery |
| 6 | T40-T44 | Autonomic components (AC) |
| 7 | T45-T49 | Session lifecycle |
| 8 | T50-T54 | Performance & timing |
| 9 | T55-T59 | Edge cases & boundaries |
| 10 | T60-T64 | Integration & end-to-end |

**Total**: 64 tests across 10 loops

---

## Environment Requirements

- tmux installed and `jarvis` session active with W0-W5
- JICM watcher running in W1
- Ennoia running in W2
- Virgil running in W3
- Command handler running in W4
- W0:Jarvis active and idle
- W5:Jarvis-dev (test executor)

**Current Blocker**: tmux not available in standalone Claude Code session. Loops 2-10 execution requires relaunching via `launch-jarvis-tmux.sh`.

---

*Wiggum Loops 2-10 Plan — 50 additional tests across 9 loops*
*Generated 2026-02-12 by Jarvis-dev*
