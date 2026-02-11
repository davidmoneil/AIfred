# AC-04 JICM — Autonomic Component Specification

**Component ID**: AC-04
**Version**: 5.6.2
**Status**: active
**Created**: 2026-01-16
**Last Modified**: 2026-02-06
**PR**: JICM v5.6.2 — Event-Driven State Machine with Dual-Mechanism Resume

---

## 1. Identity

### Purpose
Jarvis Intelligent Context Management (JICM) monitors the context window via an external watcher process, triggers AI-powered compression before lockout, and orchestrates seamless work resumption across /clear boundaries using a two-mechanism resume system. JICM triggers **continuation**, not session completion.

### Scope
| Dimension | Applies |
|-----------|---------|
| Jarvis Codebase | Yes |
| Active Project | Yes |
| All Sessions | Yes |

**Special Scope Note**: JICM applies to ALL agents and session types. The watcher runs externally in tmux and monitors any Claude Code session in the target pane.

### Tier Classification
- [x] **Tier 1**: Active Work (user-facing, direct task contribution)
- [ ] **Tier 2**: Self-Improvement (Jarvis-only, background operation)

### Design Principles

1. **Continuation, Not Exit**: Context exhaustion triggers work CONTINUATION, not session end
2. **Event-Driven State Machine**: States transition on signal files, not polling heuristics
3. **Two-Mechanism Resume**: Hook injection (Mechanism 1) + idle-hands keystroke injection (Mechanism 2) for reliability
4. **Single Threshold**: One trigger point (65%) with emergency fallback (73%), not tiered warnings
5. **Lockout Awareness**: All thresholds respect the ~78.5% hard ceiling imposed by Claude Code internals

---

## 2. Triggers

### Activation Conditions
| Trigger Type | Condition | Priority |
|--------------|-----------|----------|
| **Threshold-Based** | Context usage >= 65% | high (COMPRESS) |
| **Threshold-Based** | Context usage >= 73% | critical (EMERGENCY COMPACT) |
| **Failsafe** | "Context limit reached" in TUI | critical (AUTO-CLEAR) |
| **Failsafe** | "Conversation too long" in TUI | critical (AUTO-CLEAR) |

### Trigger Implementation
```
Event-driven state machine (v5.6.2):

  States: monitoring <-> compression_triggered <-> cleared

  monitoring:
    - jarvis-watcher.sh parses tmux pane statusline for token count + percentage
    - Polls every 30s (POLL_INTERVAL)
    - At 65%: transition to compression_triggered

  compression_triggered:
    - Wait for Claude idle (spinner detection, max 30s)
    - Send /intelligent-compress via tmux send-keys
    - Wait for .compression-done.signal (max 300s timeout)
    - Send /clear via tmux send-keys
    - Transition to cleared

  cleared:
    - session-start.sh hook fires (Mechanism 1: additionalContext injection)
    - Hook creates .idle-hands-active flag (mode: jicm_resume)
    - Watcher detects flag, sends resume prompt via keystrokes (Mechanism 2)
    - Transition back to monitoring
```

### Suppression Conditions
| Condition | Behavior |
|-----------|----------|
| `--threshold N` flag on watcher | Override 65% default |
| `.compression-in-progress` exists | Skip duplicate compression |
| `.clear-sent.signal` exists | Skip duplicate /clear |
| Watcher process not running | No automated JICM (manual /clear required) |

---

## 3. Inputs

### Required Inputs
| Input | Source | Format | Purpose |
|-------|--------|--------|---------|
| Token count + percentage | tmux pane statusline | Text (parsed) | Context usage monitoring |
| Pane content (last 5 lines) | tmux capture-pane | Text | Idle/busy detection, lockout detection |

### Optional Inputs
| Input | Source | Default | Purpose |
|-------|--------|---------|---------|
| `--threshold N` | Watcher CLI flag | 65 | Override JICM trigger percentage |
| `.jicm-config` | Signal file | Generated | Dynamic config (threshold markers) |
| Session state | `session-state.md` | None | Work context for compression agent |

### Context Requirements

- [x] tmux session with Claude Code running in target pane
- [x] Statusline visible in pane (token count and percentage)
- [x] Write access to `.claude/context/` for signal files
- [ ] session-state.md (used by compression agent if available)

---

## 4. Outputs

### Primary Outputs
| Output | Destination | Format | Consumers |
|--------|-------------|--------|-----------|
| Compressed context | `.claude/context/.compressed-context-ready.md` | Markdown | session-start.sh hook (AC-01) |
| Watcher log | `.claude/logs/jarvis-watcher.log` | Text | Debug, monitoring |
| Signal files | `.claude/context/` | Flag files | Inter-component coordination |
| Context estimate | `.claude/logs/context-estimate.json` | JSON | AC-02 queries |

### Side Effects
| Effect | Description | Reversible |
|--------|-------------|------------|
| /intelligent-compress sent | Spawns compression agent in Claude | No (consumes tokens) |
| /clear sent | Clears Claude conversation | No (conversation lost, context preserved in compressed file) |
| Resume prompt injected | Keystroke injection via tmux | N/A (just text input) |
| Signal files created/removed | Coordination state changes | Yes (delete files) |

### State Changes
| State | Location | Change Type |
|-------|----------|-------------|
| Compressed context | `.claude/context/.compressed-context-ready.md` | create/update |
| Compression signal | `.claude/context/.compression-done.signal` | create/remove |
| Compression guard | `.claude/context/.compression-in-progress` | create/remove |
| JICM state (v6) | `.claude/context/.jicm-state` | create/update |
| JICM watcher PID (v6) | `.claude/context/.jicm-watcher.pid` | create/update |
| Compression guard | `.claude/context/.compression-in-progress` | create/remove |
| Compression signal | `.claude/context/.compression-done.signal` | create/remove |

---

## 5. Dependencies

### System Dependencies
| Dependency | Type | Failure Behavior |
|------------|------|------------------|
| tmux | hard | Watcher cannot run without tmux session |
| bash 3.2+ | hard | macOS default; watcher is a bash script |
| jq | soft | Used for JSON parsing; fallback to grep |
| session-start.sh hook | hard | Mechanism 1 (additionalContext injection) fails without it |

### MCP Dependencies
| MCP Server | Tools Used | Required |
|------------|------------|----------|
| None | -- | JICM runs externally to Claude; no MCP access |

**Note**: JICM runs as an external bash process in tmux. It communicates with Claude Code exclusively via tmux keystrokes and signal files. It has no access to MCPs.

### File Dependencies
| File | Purpose | Create if Missing |
|------|---------|-------------------|
| `.claude/scripts/jarvis-watcher.sh` | Main monitoring loop | No (fatal) |
| `.claude/hooks/session-start.sh` | Context injection hook | No (fatal for resume) |
| `.claude/agents/compression-agent.md` | AI compression prompt | No (compression fails) |
| `.claude/hooks/jicm-continuation-verifier.js` | Cascade reinforcement | No (degraded resume) |
| `.claude/scripts/launch-jarvis-tmux.sh` | tmux session launcher | No (manual setup) |
| `.claude/context/.compressed-context-ready.md` | Compressed context | Yes (created by compression agent) |

---

## 6. Consumers

### Downstream Systems
| Consumer | Relationship | Data Consumed |
|----------|--------------|---------------|
| AC-01 Self-Launch | reads | `.compressed-context-ready.md` (via session-start.sh hook) |
| AC-02 Wiggum Loop | queries | Context usage percentage, resume state |
| AC-09 Session Completion | reads | Compression event count, context statistics |
| All AC components | depends | Session continuity across /clear boundaries |

### User Visibility
| Aspect | Visible to User |
|--------|-----------------|
| Watcher heartbeat | Yes (log file, periodic marker) |
| Compression trigger | Yes (/intelligent-compress appears in Claude) |
| /clear execution | Yes (conversation clears) |
| Resume prompt | Yes (appears as user input after clear) |
| Error conditions | Yes (watcher log, tmux output) |

### Integration Points

```
                    jarvis-watcher.sh (tmux window 1)
                           |
                    monitors pane 0
                           |
              ┌────────────┼─────────────────────────┐
              |            |                          |
         At 65%:     At 73%:                    Failsafe:
   /intelligent-     Emergency              "Context limit
      compress        /compact               reached" detected
              |            |                          |
              v            v                          v
    ┌──────────────────────────────────────────────────┐
    |         Compression Agent (spawned)                |
    |  Writes: .compressed-context-ready.md              |
    |  Writes: .compression-done.signal                  |
    └──────────────────────┬───────────────────────────┘
                           |
                    Watcher sends /clear
                           |
                           v
    ┌──────────────────────────────────────────────────┐
    |  Mechanism 1: session-start.sh hook fires          |
    |  - Reads .compressed-context-ready.md              |
    |  - Injects via additionalContext                   |
    |  - Creates .idle-hands-active (mode: jicm_resume)  |
    └──────────────────────┬───────────────────────────┘
                           |
                           v
    ┌──────────────────────────────────────────────────┐
    |  Mechanism 2: Watcher idle-hands monitor            |
    |  - Detects .idle-hands-active flag                  |
    |  - Waits for Claude idle                            |
    |  - Sends resume prompt via tmux keystrokes          |
    |  - Claude resumes work from compressed context      |
    └──────────────────────────────────────────────────┘
```

---

## 7. Gates

### Approval Checkpoints
| Gate ID | Trigger | Risk Level | Auto-Approve |
|---------|---------|------------|--------------|
| G-01 | Send /intelligent-compress | Low | Yes (non-destructive) |
| G-02 | Send /clear | Medium | Yes (after compression confirmed) |
| G-03 | Inject resume prompt | Low | Yes (text input only) |

### Risk Classification
| Action Type | Risk Level | Gate Requirement |
|-------------|------------|------------------|
| Token monitoring | Low | None |
| Idle detection | Low | None |
| Send /intelligent-compress | Low | Auto-approve |
| Wait for compression | Low | None (passive) |
| Send /clear | Medium | Auto after .compression-done.signal |
| Resume keystroke injection | Low | Auto-approve |
| Emergency /compact | Medium | Auto (last resort before lockout) |

### Gate Implementation
```
The critical gate is ensuring compression completes before /clear.
Watcher waits for .compression-done.signal with 300s timeout.
If timeout expires, watcher sends /clear anyway (data loss risk accepted
over lockout risk). Emergency /compact at 73% bypasses compression
entirely when approaching lockout ceiling.
```

---

## 8. Metrics

### Performance Metrics
| Metric | Unit | Target | Alert Threshold |
|--------|------|--------|-----------------|
| Compression time | seconds | < 120 | > 300 (timeout) |
| Resume latency | seconds | < 30 | > 60 |
| Liftover accuracy | % | > 90% | < 70% |
| Lockout events | count | 0 | > 0 |

### Component-Specific Metrics
| Metric | Description | Measurement |
|--------|-------------|-------------|
| `context_level` | Current usage percentage | float |
| `compression_events` | Times compression triggered | integer |
| `clear_events` | Times /clear sent | integer |
| `resume_success` | Work resumed after clear | boolean |
| `emergency_compact` | Emergency /compact triggered (73%+) | integer |
| `lockout_detected` | Claude lockout ceiling hit | integer |
| `compression_timeout` | Compression exceeded 300s | integer |
| `idle_wait_timeout` | Claude did not become idle in time | integer |

### Storage
| Metric Type | Storage Location | Retention |
|-------------|------------------|-----------|
| Per-poll | `.claude/logs/jarvis-watcher.log` | Session |
| Per-session | `.claude/logs/context-estimate.json` | Session |

### Emission Format
```
Watcher log entries (text, not JSONL):
  [HH:MM:SS] Context: 65% (130000/200000 tokens) — JICM TRIGGERED
  [HH:MM:SS] Compression done signal detected
  [HH:MM:SS] Sent /clear — transitioning to cleared state
  [HH:MM:SS] Resume prompt injected — returning to monitoring
```

---

## 9. Failure Modes

### Known Failure Scenarios
| Failure | Cause | Detection | Recovery |
|---------|-------|-----------|----------|
| Compression timeout | Agent takes >300s | Timer expiry | Send /clear anyway (accept context loss) |
| tmux session loss | tmux killed/detached | Watcher exit | Restart via launch-jarvis-tmux.sh |
| Lockout ceiling breach | Thresholds set too high | "Context limit reached" in TUI | Emergency /clear (bypasses compression) |
| Stale pane buffer | Old token counts in scroll history | Data inconsistency heuristic | Restrict parsing to last 3 lines of pane |
| Double compression | Race between poll cycles | `.compression-in-progress` guard | Skip if guard file exists |
| Keystroke injection during generation | Claude busy when watcher sends input | `is_claude_busy()` check | `wait_for_idle_brief(30)` polls before sending |
| Multi-line string corruption | tmux send-keys -l with newlines | Garbled TUI input | All -l strings must be single-line |
| bash 3.2 set -e exit | Subshell non-zero return in assignment | Unexpected watcher exit | All functions return 0; use output strings for status |

### Graceful Degradation
| Degradation Level | Trigger | Behavior |
|-------------------|---------|----------|
| Full | All systems operational | Full monitoring + compression + resume |
| Partial | Compression agent fails | Emergency /compact, then /clear |
| Partial | Hook injection fails | Idle-hands mechanism still sends resume prompt |
| Partial | Watcher not running | Manual /intelligent-compress + /clear required |
| Minimal | tmux unavailable | No automated JICM; user must manage context manually |

### Error Reporting
| Error Type | Notification | Log Location |
|------------|--------------|--------------|
| Warning | Watcher log only | `.claude/logs/jarvis-watcher.log` |
| Threshold hit | Watcher log + TUI action | `.claude/logs/jarvis-watcher.log` |
| Critical | Watcher log + emergency action | `.claude/logs/jarvis-watcher.log` |

### Rollback Procedures
1. Kill watcher: `kill $(cat .claude/context/.watcher-pid)`
2. Remove signal files: `rm -f .claude/context/.compression-* .claude/context/.clear-sent.signal .claude/context/.idle-hands-active .claude/context/.continuation-injected.signal`
3. Adjust thresholds: Edit `.claude/context/.jicm-config` or restart watcher with `--threshold N`
4. Compressed context is preserved in `.compressed-context-ready.md` across clears

---

## Implementation Notes

### Component Inventory (JICM v5.6.2)
| Artifact | Path | Role |
|----------|------|------|
| Watcher | `.claude/scripts/jarvis-watcher.sh` | Main monitoring loop (tmux window 1) |
| Session-start hook | `.claude/hooks/session-start.sh` | Mechanism 1: additionalContext injection on clear/startup/resume |
| Compression agent | `.claude/agents/compression-agent.md` | AI-powered context compression (spawned by /intelligent-compress) |
| Continuation verifier | `.claude/hooks/jicm-continuation-verifier.js` | Cascade reinforcement on UserPromptSubmit |
| Launcher | `.claude/scripts/launch-jarvis-tmux.sh` | Creates tmux session with Claude + watcher |
| Compress command | `.claude/commands/intelligent-compress.md` | Claude-side /intelligent-compress handler |
| Context management skill | `.claude/skills/context-management/SKILL.md` | User-facing context guidance |
| Component spec | `.claude/context/components/AC-04-jicm.md` | This file |

### Signal Files (v5 Protocol)
| Signal File | Purpose | Created By | Consumed By |
|-------------|---------|------------|-------------|
| `.compressed-context-ready.md` | Compressed context for restoration | Compression agent | session-start.sh hook |
| `.compression-done.signal` | Compression agent completion marker | Compression agent | Watcher |
| `.jicm-state` | v6 state (state, pct, tokens, threshold) | JICM watcher | Ennoia, Virgil, hooks |
| `.jicm-watcher.pid` | v6 watcher process tracking | JICM watcher | signal-helper, stop-watcher |
| `.compression-in-progress` | Guard against double compression | /intelligent-compress skill | session-start |
| `.compression-done.signal` | Compression agent completion marker | Compression agent | JICM watcher |

All signal files live in `.claude/context/` and are gitignored.

### Threshold Architecture
```
0%                    65%        70%       73%      78.5%    100%
|──────────────────────|──────────|──────────|─────────|──────|
      Normal            JICM     Native      Emergency  LOCKOUT
      Operation        Trigger   Auto-       Compact   CEILING
                                 Compact
                                 (env var)

JICM trigger:        65%  (configurable via --threshold)
Native auto-compact: 70%  (CLAUDE_AUTOCOMPACT_PCT_OVERRIDE=70)
Emergency compact:   73%  (LOCKOUT_PCT - 5)
Lockout ceiling:    ~78.5% ((200K - 15K - 28K) / 200K)

Where:
  200K = context window size
  15K  = CLAUDE_CODE_MAX_OUTPUT_TOKENS (output reserve)
  28K  = internal compact buffer (required by Claude Code to perform compaction)
```

### Environment Variables
Set by `.claude/scripts/claude-code-env.sh` (sourced from shell profile):
- `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE=70` -- Native auto-compact trigger (backup to JICM)
- `CLAUDE_CODE_MAX_OUTPUT_TOKENS=15000` -- Output reserve (affects lockout ceiling)

### Two-Mechanism Resume System

**Mechanism 1 -- Hook additionalContext Injection**:
When /clear fires, Claude Code triggers the `session-start.sh` hook. The hook detects that `.compressed-context-ready.md` exists, reads its contents, and injects them as `additionalContext` in the hook response JSON. This gives Claude the compressed context immediately upon session restart. The hook also creates `.idle-hands-active` with mode `jicm_resume`.

**Mechanism 2 -- Idle-Hands Keystroke Injection**:
The watcher detects the `.idle-hands-active` flag and enters idle-hands monitoring mode. It waits for Claude to become idle (no spinner), then sends a resume prompt via `tmux send-keys`. This prompt instructs Claude to continue the previous work using the compressed context it received via Mechanism 1. Two modes exist:
- `jicm_resume`: Resume after JICM compression cycle
- `session_start`: Initial session startup prompt

### JICM Compression Flow (Full Cycle)

```
1. Watcher polls tmux pane, parses statusline
   └── Extracts: token count, percentage, spinner state

2. At 65%: JICM triggered
   ├── wait_for_idle_brief(30)  -- don't interrupt active generation
   ├── Create .compression-in-progress guard
   └── Send "/intelligent-compress" via tmux send-keys

3. Claude spawns compression agent
   ├── Agent reads conversation context
   ├── Agent writes .compressed-context-ready.md
   └── Agent writes .compression-done.signal

4. Watcher detects .compression-done.signal
   ├── Remove .compression-in-progress
   ├── Create .clear-sent.signal (dedup)
   └── Send "/clear" via tmux send-keys

5. /clear triggers session-start.sh hook (Mechanism 1)
   ├── Hook reads .compressed-context-ready.md
   ├── Hook injects as additionalContext
   ├── Hook creates .idle-hands-active (mode: jicm_resume)
   └── Hook creates .continuation-injected.signal

6. Watcher detects .idle-hands-active (Mechanism 2)
   ├── wait_for_idle_brief(30)
   ├── Send resume prompt via tmux send-keys -l (single-line)
   ├── Send C-m to submit
   └── Remove .idle-hands-active, .clear-sent.signal

7. Claude resumes work from compressed context
   └── Watcher returns to monitoring state
```

### tmux Constraints (bash 3.2 / macOS)

- All `tmux send-keys -l` strings MUST be single-line (multi-line corrupts input buffer)
- Functions called via `$(...)` must always `return 0` (bash 3.2 `set -e` compatibility)
- Pane content parsing restricted to last 3 lines (`tail -3`) to avoid stale scroll history
- `is_claude_busy()` checks for spinner characters in last 5 lines before sending keystrokes
- `wait_for_idle_brief(N)` polls every 2s, max N seconds, sends anyway after timeout

### Design Decisions Log
| Date | Decision | Rationale |
|------|----------|-----------|
| 2026-01-16 | Continuation, not exit | Work should persist across compression |
| 2026-01-21 | Single threshold (was 80%) | Simplify; one trigger point is sufficient |
| 2026-01-21 | Opus model for compression | Higher quality context preservation |
| 2026-01-21 | Idle detection before trigger | Don't interrupt Claude mid-response |
| 2026-02-05 | Lower threshold to 65% | 80% was above lockout ceiling (~78.5%) |
| 2026-02-05 | Emergency compact at 73% | Last resort, 5% below lockout |
| 2026-02-05 | bash 3.2 return 0 pattern | Functions must return 0 for macOS compatibility |
| 2026-02-05 | Restrict pane parsing to tail -3 | Avoid stale token counts from scroll history |
| 2026-02-06 | Single-line send-keys -l | Multi-line strings corrupt tmux input buffer |
| 2026-02-06 | Two-mechanism resume | Hook injection alone insufficient; keystroke injection ensures continuation |
| 2026-02-06 | wait_for_idle before send | Keystrokes during active generation are lost |

---

## Validation Checklist

Before marking this component as "active":

- [x] All 9 specification sections completed
- [x] Triggers tested (65% threshold, emergency 73%, lockout failsafe)
- [x] Inputs/outputs validated (tmux pane parsing, signal file protocol)
- [x] Dependencies verified (tmux, bash 3.2+, hook registration)
- [x] Gates implemented (compression-before-clear, idle-before-send)
- [x] Failure modes tested (compression timeout, lockout breach, stale buffer)
- [x] Integration with consumers verified (AC-01 hook resume, AC-02 context queries)
- [x] Documentation updated (component spec reflects v5.6.2 reality)
- [ ] Metrics emission formalized (currently log-based, not structured JSONL)

---

*AC-04 JICM v5.6.2 — Event-Driven State Machine with Dual-Mechanism Resume*
