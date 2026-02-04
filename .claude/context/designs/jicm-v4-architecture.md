# JICM v4 Architecture — Parallel Compression with Cascade Resume

> ⚠️ **SUPERSEDED**: This document describes JICM v4. The current authoritative specification is **JICM v5** in `jicm-v5-design-addendum.md`. Key changes in v5:
> - Single 50% threshold (vs dual 70%/80%)
> - Two-mechanism resume (vs three-hook cascade)
> - Mode-based idle-hands system
> - 10k-30k token compression target
>
> Retained for historical reference.

**Version**: 4.0.0
**Status**: SUPERSEDED by v5 — See `jicm-v5-design-addendum.md`
**Date**: 2026-01-31
**Author**: Jarvis Autonomous Archon

---

## Executive Summary

JICM v4 implements **parallel compression** where a compression agent works while Jarvis continues, followed by a **two-layer executor** that gracefully interrupts and clears, and a **cascade resumer** that ensures robust continuation.

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         JICM v4 ARCHITECTURE                             │
│                                                                          │
│  ┌────────────────────────────────────────────────────────────────────┐ │
│  │ DETECTOR (jarvis-watcher.sh)                                       │ │
│  │   Source: ~/.claude/logs/statusline-input.json (authoritative)     │ │
│  │   x% threshold (y-10): Spawn compression agent                     │ │
│  │   y% threshold: Fallback to native /compact                        │ │
│  └────────────────────────────────────────────────────────────────────┘ │
│                │                          │                              │
│        At x%   │                  At y%   │                              │
│                ▼                          ▼                              │
│  ┌─────────────────────────┐   ┌─────────────────────────────────────┐  │
│  │ COMPRESSION AGENT       │   │ FALLBACK: signal native /compact    │  │
│  │ (Sonnet, background)    │   │ Let Claude Code handle it           │  │
│  │                         │   └─────────────────────────────────────┘  │
│  │ Reads:                  │                                            │
│  │  - session-state.md     │                                            │
│  │  - current-priorities   │                                            │
│  │  - cognitive-checkpoint │                                            │
│  │                         │                                            │
│  │ Writes:                 │                                            │
│  │  - .compressed-context  │                                            │
│  │  - .compression-done    │                                            │
│  └───────────┬─────────────┘                                            │
│              │                                                           │
│              ▼                                                           │
│  ┌────────────────────────────────────────────────────────────────────┐ │
│  │ EXECUTOR LAYER 1 (on .compression-done detection)                  │ │
│  │   - Sends interrupt + dump prompt to Jarvis                        │ │
│  │   - Jarvis writes current state to .in-progress-ready.md           │ │
│  │   - Writes .dump-requested.signal                                  │ │
│  └────────────────────────────────────────────────────────────────────┘ │
│                              │                                           │
│                              ▼                                           │
│  ┌────────────────────────────────────────────────────────────────────┐ │
│  │ EXECUTOR LAYER 2 (on .in-progress-ready.md detection)              │ │
│  │   - Verifies dump file exists and has content                      │ │
│  │   - Sends /clear command                                           │ │
│  │   - Writes .clear-sent.signal                                      │ │
│  └────────────────────────────────────────────────────────────────────┘ │
│                              │                                           │
│                              ▼                                           │
│  ┌────────────────────────────────────────────────────────────────────┐ │
│  │ CASCADE RESUMER (hooks chain)                                      │ │
│  │                                                                     │ │
│  │ Hook 1: session-start.sh                                           │ │
│  │   - Detects .compressed-context-ready.md                           │ │
│  │   - Detects .in-progress-ready.md                                  │ │
│  │   - Injects CONTINUATION additionalContext                         │ │
│  │   - Writes .continuation-injected.signal                           │ │
│  │                                                                     │ │
│  │ Hook 2: continuation-verifier.sh (5s delay)                        │ │
│  │   - Checks if session is idle (no response yet)                    │ │
│  │   - If idle: re-injects continuation prompt                        │ │
│  │   - Writes .continuation-verified.signal                           │ │
│  │                                                                     │ │
│  │ Hook 3: resume-enforcer.sh (10s delay)                             │ │
│  │   - Final check: is Jarvis working?                                │ │
│  │   - If still idle: force inject "Resume work immediately"          │ │
│  │   - Cleans up all signal files                                     │ │
│  └────────────────────────────────────────────────────────────────────┘ │
│                                                                          │
│  SAFEGUARDS:                                                             │
│    - Debounce: 5 min between JICM triggers                              │
│    - Max triggers: 5 per session                                        │
│    - Agent timeout: 3 min                                               │
│    - Dump timeout: 30s                                                  │
│    - Standdown mode: after 3 consecutive failures                       │
│    - Native auto-compact at 95%: always enabled as final safety         │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Signal Files

| File | Written By | Read By | Purpose |
|------|------------|---------|---------|
| `.compression-done.signal` | Compression Agent | Watcher | Agent finished compression |
| `.dump-requested.signal` | Executor L1 | Executor L2 | Dump prompt sent to Jarvis |
| `.in-progress-ready.md` | Jarvis (prompted) | Executor L2 | Jarvis's current state dump |
| `.clear-sent.signal` | Executor L2 | Cascade Hooks | /clear was sent |
| `.continuation-injected.signal` | Hook 1 | Hook 2 | First continuation sent |
| `.continuation-verified.signal` | Hook 2 | Hook 3 | Verified or re-sent |
| `.jicm-complete.signal` | Hook 3 | Watcher | Full cycle complete |

---

## Thresholds

| Name | Default | Purpose |
|------|---------|---------|
| x% | 70% | Spawn compression agent (parallel work) |
| y% | 80% | Fallback: trigger native /compact |
| 95% | (native) | Claude Code auto-compact safety net |

Configuration in `autonomy-config.yaml`:

```yaml
jicm:
  version: "4.0.0"
  thresholds:
    compression_trigger: 70    # x% - spawn agent
    fallback_trigger: 80       # y% - native /compact
    # 95% is handled by Claude Code auto-compact
  timeouts:
    agent_max_seconds: 180     # 3 min for compression
    dump_max_seconds: 30       # 30s for Jarvis to dump
    continuation_delay_1: 5    # First re-check
    continuation_delay_2: 10   # Second re-check
  safeguards:
    debounce_seconds: 300      # 5 min between triggers
    max_triggers_per_session: 5
    failures_before_standdown: 3
```

---

## Component Specifications

### 1. Compression Agent

File: `.claude/agents/compression-agent.md`

Spawned at x% threshold. Uses Sonnet model for quality compression.

### 2. Executor Layer 1

Embedded in `jarvis-watcher.sh`. Sends interrupt prompt.

### 3. Executor Layer 2

Embedded in `jarvis-watcher.sh`. Listens for dump, sends /clear.

### 4. Cascade Resumer

Hook chain in `.claude/hooks/`:
- `jicm-continuation-1.js` - Initial injection
- `jicm-continuation-2.js` - Verification
- `jicm-continuation-3.js` - Enforcement

---

## Continuation Prompt Template

```markdown
## CONTEXT CONTINUATION

**Status**: This is NOT a new session. Context was optimized mid-work.

**CRITICAL INSTRUCTIONS**:
1. DO NOT greet the user
2. DO NOT ask what they'd like to work on
3. DO resume work IMMEDIATELY from where you left off

**Your State**:
- Read `.claude/context/.compressed-context-ready.md` for preserved context
- Read `.claude/context/.in-progress-ready.md` for work-in-progress
- Continue the task that was interrupted

**Resume Point**:
[Specific task from in-progress file]
```

---

## Error Handling

| Failure | Detection | Recovery |
|---------|-----------|----------|
| Agent timeout | No .compression-done after 180s | Fallback to native /compact |
| Dump timeout | No .in-progress-ready after 30s | Proceed with /clear anyway |
| Clear fails | Percentage doesn't drop | Retry once, then standdown |
| Resume fails | Session idle after 15s | Cascade hooks re-inject |
| Loop detected | >3 triggers in 10 min | Enter standdown mode |

---

## Implementation Checklist

- [x] Update `autonomy-config.yaml` with v4.0.0 settings
- [x] Create `compression-agent.md` specification
- [x] Update `jarvis-watcher.sh` with two-threshold detection
- [x] Implement Executor Layer 1 (interrupt + dump prompt)
- [x] Implement Executor Layer 2 (wait for dump, send /clear)
- [x] Create cascade continuation hook (`jicm-continuation-verifier.js`)
- [x] Update `session-start.sh` to integrate with cascade (v4 signal detection)
- [x] Add debounce protection against double-clear
- [x] Add circuit breakers and standdown mode
- [x] Update `/intelligent-compress` command to v4 paradigm
- [ ] Test full cycle

**Implementation Notes (2026-01-31):**
- Cascade hooks consolidated into single `jicm-continuation-verifier.js` (timer-based cascade is in watcher)
- Added manual compression detection in watcher (for `/intelligent-compress` command)
- Session-start.sh now detects v4 signal files with priority over v2
- Debounce window of 30 seconds prevents double-clear stall scenario

---

*JICM v4.0.0 — Parallel Compression with Cascade Resume*
*Status: SUPERSEDED by JICM v5 — See `jicm-v5-design-addendum.md`*
