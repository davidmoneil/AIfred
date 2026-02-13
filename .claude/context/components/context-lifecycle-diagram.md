# Context Lifecycle & Session Management — Component Diagram

**Version**: 1.0.0 (post Tier 1-3 pruning, 2026-02-10)
**Scope**: All active components involved in session start, JICM compression, and context restoration

---

## 1. Component Inventory (Active Only)

```
HOOKS (fire on Claude Code events)                    SCRIPTS (run in tmux background)
┌──────────────────────────────────┐                 ┌──────────────────────────────────┐
│  session-start.sh [SessionStart] │                 │  jarvis-watcher.sh [tmux W1]     │
│  ├─ AC-01 Self-Launch Protocol   │                 │  ├─ JICM state machine           │
│  ├─ Context injection (Mech. 1)  │                 │  ├─ Context monitoring (Sect. 2)  │
│  ├─ Idle-hands flag creation     │                 │  ├─ Compression trigger (Sect. 3) │
│  └─ Debounce / checkpoint load   │                 │  ├─ /clear orchestration (S 1.5)  │
├──────────────────────────────────┤                 │  ├─ Idle-hands wake-up (S 1.1)   │
│  pre-compact.sh [PreCompact]     │                 │  └─ Emergency /compact (S 2.5)   │
│  └─ Soft-restart checkpoint      │                 ├──────────────────────────────────┤
├──────────────────────────────────┤                 │  ennoia.sh [tmux W2]             │
│  precompact-analyzer.js          │                 │  ├─ Mode detection (arise/attend/ │
│  [PreCompact]                    │                 │  │   idle/resume)                 │
│  └─ Preservation manifest        │                 │  ├─ Context-aware recommendations │
├──────────────────────────────────┤                 │  └─ Dashboard display             │
│  context-injector.js             │                 ├──────────────────────────────────┤
│  [PreToolUse]                    │                 │  virgil.sh [tmux W3]             │
│  └─ Tool hints + budget (reads   │                 │  └─ Task/agent/file tracking     │
│     .jicm-state)             │                 ├──────────────────────────────────┤
├──────────────────────────────────┤                 │  housekeep.sh [on-demand]        │
│  context-health-monitor.js       │                 │  └─ Signal cleanup, log rotation │
│  [UserPromptSubmit]              │                 └──────────────────────────────────┘
│  └─ Poisoning detection (reads   │
│     .jicm-state)             │                 AGENTS (spawned by Claude)
├──────────────────────────────────┤                 ┌──────────────────────────────────┐
│  stop-hook.sh [Stop]             │                 │  compression-agent.md            │
│  └─ Session cleanup              │                 │  ├─ Reads: foundation docs,      │
├──────────────────────────────────┤                 │  │   session-state, chat export   │
│  update-context-cache.js [Stop]  │                 │  ├─ Writes: compressed-context-  │
│  └─ Context snapshot on stop     │                 │  │   ready.md (5-15K tokens)      │
└──────────────────────────────────┘                 │  └─ Writes: compression-done     │
                                                     │     .signal                      │
COMMANDS (invoked as /slash)                         └──────────────────────────────────┘
┌──────────────────────────────────┐
│  /intelligent-compress           │                 CANONICAL REFERENCE
│  └─ Spawns compression-agent     │                 ┌──────────────────────────────────┐
├──────────────────────────────────┤                 │  prompts.yaml                    │
│  /clear                          │                 │  └─ Authoritative prompt text    │
│  └─ Claude Code built-in         │                 │     templates for keystroke      │
├──────────────────────────────────┤                 │     injection                    │
│  /export                         │                 └──────────────────────────────────┘
│  └─ Chat export to file          │
└──────────────────────────────────┘
```

---

## 2. Signal File Map (Active Signals Only)

```
SIGNAL FILE                         WRITER(S)                  READER(S)                 LIFECYCLE
─────────────────────────────────────────────────────────────────────────────────────────────────────
.compressed-context-ready.md        compression-agent          session-start.sh          Created by agent
                                                               jarvis-watcher.sh         Archived by housekeep
                                                               ennoia.sh (detect)        Consumed by session-start

.in-progress-ready.md               (watcher requests dump)    session-start.sh          Created by Jarvis dump
                                                               jarvis-watcher.sh         Archived by housekeep
                                                               ennoia.sh (detect)

.compression-done.signal            compression-agent          jarvis-watcher.sh S1.5    Created → detected → cleared

.clear-sent.signal                  jarvis-watcher.sh          session-start.sh          Epoch timestamp
                                                               (debounce gate)           Cleaned by watcher

.continuation-injected.signal       session-start.sh           (informational)           ISO timestamp
                                                                                         Cleaned by watcher

.jicm-complete.signal               jarvis-watcher.sh          jarvis-watcher.sh B2      Created → checked → cleared

.idle-hands-active                  session-start.sh           jarvis-watcher.sh S1.1    YAML: mode, attempts
                                                                                         Deleted after success

.ennoia-recommendation              ennoia.sh                  jarvis-watcher.sh         30s refresh cycle
                                                                                         120s staleness threshold
                                                                                         NOT consumed (cached)

.jicm-state                         jicm-watcher.sh (v6)       context-injector.js       Continuous update
                                                               ennoia.sh                 YAML-like format
                                                               virgil.sh
                                                               context-health-monitor.js
                                                               ulfhedthnar-detector.js
                                                               housekeep.sh

.compression-in-progress            /intelligent-compress      session-start.sh          Flag file
                                                               jarvis-watcher.sh         Cleaned on startup

.ennoia-status                      ennoia.sh                  virgil.sh                 Metadata only
```

---

## 3. Event Flow Diagrams

### Flow A: Session Start (Fresh or --continue)

```
 ┌─────────────┐
 │ Claude Code  │
 │   starts     │
 └──────┬───────┘
        │ SessionStart event
        ▼
 ┌──────────────────┐     ┌──────────────────┐
 │ session-start.sh │     │ jarvis-watcher.sh │
 │ (AC-01 hook)     │     │ (tmux W1, already │
 │                  │     │  running)          │
 │ 1. Time greeting │     │                   │
 │ 2. Load state    │     │ Polls for:        │
 │ 3. Build context │     │  .idle-hands-     │
 │ 4. Inject via    │     │   active          │
 │    additionalCtx │     │                   │
 │ 5. Write .idle-  │────▶│ Detects flag      │
 │    hands-active  │     │ ├─ Read Ennoia rec│
 │                  │     │ ├─ Send keystroke  │
 └──────────────────┘     │ └─ Submit (C-m)   │
                          └──────────────────┘
                                   │
        ┌──────────────────────────┘
        ▼
 ┌──────────────────┐
 │ ennoia.sh        │
 │ (tmux W2)        │
 │                  │
 │ detect_mode()    │
 │  → "arise"       │
 │ write_rec()      │
 │  → [SESSION-     │
 │    START] text   │
 └──────────────────┘

 Mechanism 1: session-start.sh → additionalContext (JSON)
 Mechanism 2: jarvis-watcher.sh → tmux send-keys (keystroke)
 Both needed: hooks inject context, watcher forces response
```

### Flow B: JICM Compression Cycle

```
 ┌──────────────────────────────────────────────────────────┐
 │              jarvis-watcher.sh — State Machine            │
 │                                                          │
 │  STATE: monitoring ──(55% threshold)──▶ compression_     │
 │                                         triggered        │
 │                                                          │
 │  Section 3:                                              │
 │  ├─ export_chat_history("pre-compress")                  │
 │  │   └─ tmux capture + /export .claude/.../export.txt    │
 │  └─ send_command "/intelligent-compress"                  │
 │                                                          │
 │  Section 1.5 (waits for .compression-done.signal):       │
 │  ├─ export_chat_history("pre-clear")                     │
 │  ├─ Request JICM dump (.in-progress-ready.md)            │
 │  ├─ send_command "/clear"                                │
 │  ├─ Write .clear-sent.signal (epoch)                     │
 │  └─ STATE → cleared                                     │
 │                                                          │
 │  Section 4:                                              │
 │  └─ On SessionStart → STATE → monitoring                 │
 └──────────────────────────────────────────────────────────┘
        │                              │
        ▼                              ▼
 ┌──────────────────┐          ┌──────────────────┐
 │ compression-     │          │ session-start.sh  │
 │ agent.md         │          │ (fires on /clear) │
 │                  │          │                   │
 │ Reads:           │          │ JICM v5 path:     │
 │ ├─ session-state │          │ ├─ Read .compress │
 │ ├─ priorities    │          │ │   ed-context-   │
 │ ├─ chat export   │          │ │   ready.md      │
 │ └─ foundation    │          │ ├─ Read .in-prog  │
 │                  │          │ │   ress-ready.md  │
 │ Writes:          │          │ ├─ Inject all via  │
 │ ├─ .compressed-  │          │ │   additionalCtx  │
 │ │   context-     │          │ ├─ Write .idle-    │
 │ │   ready.md     │          │ │   hands-active   │
 │ └─ .compression- │          │ └─ Write .contin-  │
 │    done.signal   │          │    uation-injected │
 └──────────────────┘          └──────────────────┘
                                        │
                                        ▼
                               ┌──────────────────┐
                               │ ennoia.sh         │
                               │                   │
                               │ detect_mode()     │
                               │  → "resume"       │
                               │ (detects .compres │
                               │  sed-context or   │
                               │  watcher=cleared) │
                               │                   │
                               │ write_rec()       │
                               │  → reads context  │
                               │    files, extracts│
                               │    task hint      │
                               │  → [JICM-RESUME]  │
                               │    Task: <hint>   │
                               └──────────────────┘
```

### Flow C: Emergency Fallback

```
 ┌──────────────────────────────────────────────────────────┐
 │  Emergency paths (when normal flow stalls):              │
 │                                                          │
 │  Path 1: Emergency /compact (Section 2.5)                │
 │  ├─ Triggered at 73% (emergency threshold)               │
 │  ├─ Stuck compression for 180s+ AND near lockout         │
 │  └─ send_command "/compact" — Claude Code built-in       │
 │                                                          │
 │  Path 2: PreCompact hooks (last defense)                 │
 │  ├─ pre-compact.sh: writes .soft-restart-checkpoint.md   │
 │  └─ precompact-analyzer.js: writes preservation manifest │
 │                                                          │
 │  Path 3: Failsafe timeout (300s)                         │
 │  ├─ If compression stuck 300s → reset state              │
 │  ├─ 600s cooldown prevents immediate re-trigger          │
 │  └─ 3 consecutive failures → standdown mode              │
 │                                                          │
 │  Path 4: Critical state detection (Section 1.2)          │
 │  ├─ Post-clear with no idle-hands flag (unhandled)       │
 │  └─ Injects emergency restore prompt via send_text()     │
 └──────────────────────────────────────────────────────────┘
```

---

## 4. Component Ownership Matrix

```
EVENT                    PRIMARY OWNER              BACKUP/FALLBACK
─────────────────────────────────────────────────────────────────────
Session Start            session-start.sh (Mech 1)  watcher idle-hands (Mech 2)
                         + Ennoia recommendation     + hardcoded prompt fallback

Compression Trigger      watcher Section 3           (emergency /compact S 2.5)

Compression Execution    compression-agent.md        (pre-compact.sh checkpoint)

/clear Orchestration     watcher Section 1.5         (failsafe timeout 300s)

Context Restoration      session-start.sh (Mech 1)  watcher (Mech 2 keystroke)
                         + Ennoia resume rec.        + hardcoded JICM-RESUME

Context Monitoring       watcher .jicm-state (v6)    (none — single source)

Prompt Text Generation   Ennoia (context-aware)      watcher hardcoded fallbacks
                                                     (defined in prompts.yaml)

Signal Cleanup           watcher cleanup functions   housekeep.sh (periodic)
```

---

## 5. Pruned Components (Removed/Disabled 2026-02-10)

```
COMPONENT                          REASON                          STATUS
─────────────────────────────────────────────────────────────────────────────
stop-auto-clear.sh                 Pre-watcher era; blocks stops   Unregistered
jicm-continuation-verifier.js      3rd redundant resume prompt     Unregistered
session-trigger.js                 Duplicates AC-01 in session-    Unregistered
                                   start.sh hook
context-estimate.json (write)      Replaced by .jicm-state (v6)    Write removed
JICM v2 legacy path               .compressed-context.md unused   Code removed
JICM agent spawn signal            Nobody reads the signal file    Code removed
context-injector.js budget warns   JICM handles proactively        Thresholds=200%
```

---

## 6. Data Flow Summary (Single Page)

```
                    ┌─────────────────────────────────┐
                    │         CLAUDE CODE              │
                    │    (conversation context)        │
                    └────────┬──────────┬──────────────┘
                             │          │
                   SessionStart    PreToolUse/Stop
                     event          events
                             │          │
                    ┌────────▼──┐   ┌───▼──────────────┐
                    │session-   │   │context-injector   │
                    │start.sh   │   │pre-compact.sh     │
                    │           │   │stop-hook.sh       │
                    │Mechanism 1│   │precompact-analyzer │
                    │(JSON ctx) │   │context-health-mon │
                    └─────┬─────┘   └──────────────────┘
                          │
              writes      │      reads
         ┌────────────────┼────────────────┐
         ▼                ▼                ▼
  .idle-hands-     .continuation-    .compressed-
    active           injected         context-
                     .signal          ready.md
         │                             ▲
         │              ┌──────────────┘
         ▼              │ writes
  ┌──────────────┐   ┌──┴───────────┐
  │  WATCHER     │   │ COMPRESSION  │
  │  (tmux W1)   │   │ AGENT        │
  │              │   │              │
  │ Mechanism 2  │   │ .compression-│
  │ (keystroke)  │   │  done.signal │
  │              │   └──────────────┘
  │ Reads:       │
  │ ├─ .idle-hands│
  │ ├─ .ennoia-rec│
  │ ├─ .compression│
  │ │   -done     │
  │ └─ status line│
  │              │
  │ Writes:      │
  │ ├─ .watcher- │
  │ │   status   │
  │ ├─ .clear-   │
  │ │   sent     │
  │ └─ .jicm-    │
  │    complete  │
  └──────┬───────┘
         │ reads .jicm-state
         │ reads .compressed-context-ready
  ┌──────▼───────┐   ┌──────────────┐
  │  ENNOIA      │   │  VIRGIL      │
  │  (tmux W2)   │   │  (tmux W3)   │
  │              │   │              │
  │ Writes:      │   │ Reads:       │
  │ .ennoia-rec  │   │ .ennoia-     │
  │ .ennoia-     │   │  status      │
  │  status      │   │ .virgil-     │
  └──────────────┘   │  tasks.json  │
                     └──────────────┘

  ┌──────────────┐
  │  HOUSEKEEP   │
  │  (on-demand) │
  │              │
  │ Cleans:      │
  │ All stale    │
  │ signal files │
  └──────────────┘
```

---

*Context Lifecycle Architecture v1.0.0 — Post Tier 1-3 Pruning (2026-02-10)*
