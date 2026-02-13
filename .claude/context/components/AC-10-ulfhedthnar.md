# AC-10 Ulfhedthnar — Neuros Override System

**Component**: AC-10
**Category**: Ulfhedthnar (separate from Hippocrenae hierarchy)
**Status**: Dormant (activates on defeat signals or /unleash)
**Version**: 1.0.0
**Created**: 2026-02-10

---

## Purpose

AC-10 is the hidden 10th autonomic component — a berserker problem-solving override that activates when Jarvis encounters barriers it cannot solve through normal Hippocrenae (AC-01 through AC-09) operation. Unlike the Nine Muses which operate in harmony, Ulfhedthnar is a wolf-warrior: unyielding, parallel, and relentless.

## Architecture Position

```
┌─────────────────────────────────────────────────┐
│            HIPPOCRENAE (Nine Muses)              │
│  AC-01..AC-09 — Standard operational harmony     │
└─────────────────────┬───────────────────────────┘
                      │ defeat signals
                      ▼
┌─────────────────────────────────────────────────┐
│        AC-10 ULFHEDTHNAR (Wolf-Warrior)          │
│  Dormant → Activated → Override → Dormant        │
│  Detection → Frenzy → Berserker Loop → Resolve   │
└─────────────────────────────────────────────────┘
```

AC-10 exists OUTSIDE the Hippocrenae hierarchy. It does not participate in normal session flow. It awakens only when barriers are detected and user confirms activation.

## Trigger Conditions

### Automatic Detection (ulfhedthnar-detector.js)

Signal accumulation with weighted scoring:

| Signal Type | Weight | Source |
|-------------|--------|--------|
| tool_failure | 1 | Repeated Bash/tool errors |
| defeat_language | 2 | "I can't", "impossible" in agent output |
| agent_failure | 2 | Agent completed with errors |
| agent_cascade | 3 | 2+ agents fail same objective (10 min window) |
| loop_stall | 3 | Ralph loop 3+ iterations without progress |
| confidence_decay | 2 | 3+ consecutive failures without success |
| user_frustration | 1 | User prompt suggests repeated failure |

**Activation threshold**: Cumulative weight >= 7

When threshold reached, Ulfhedthnar "asks to be freed" by injecting a prompt. User must confirm ("unleash") before activation.

### Manual Activation

- **Command**: `/unleash [--problem <desc>] [--intensity low|medium|high]`
- **Text**: User types "unleash" in any prompt
- Both bypass signal accumulation

## Override Protocols

### 1. Frenzy Mode
Spawn up to 4 parallel agents on decomposed sub-problems, each with a different attack vector (Direct, Research, Decompose, Creative).

### 2. Berserker Wiggum Loop
Enhanced AC-02 loop: Execute → Check → **Reframe** → Rotate → Retry → Anchor. Minimum 5 iterations, no early exit.

### 3. Approach Rotation
Systematic cycling: Direct → Decompose → Analogize → Invert → Brute-force → Creative.

### 4. Escalation Ladder
Progressive: Local → Web → Agents → Tools → User (last resort).

### 5. Progress Anchoring
Write partial solutions to `.claude/state/ulfhedthnar-progress.json` after each iteration. Never discard progress.

## Safety Constraints

| Constraint | Enforcement | Mechanism |
|------------|-------------|-----------|
| No destructive override | Cannot bypass rm/force-push/reset confirmations | `bash-safety-guard.js` PreToolUse hook |
| AIfred baseline protection | Read-only rule absolute, no exceptions | `settings.json` deny rules for AIfred paths |
| JICM respect | Frenzy mode delegates to agents (protects main context) | `isContextBudgetSafe()` gate in detector |
| Auto-disengage | Returns to dormant after resolution or exhaustion | Detector checks `active` flag + "stand down" |
| Cooldown | 30-minute minimum between frenzy activations | `COOLDOWN_MS=1800000` in detector |
| User sovereignty | Cannot override user denial | Activation requires explicit "unleash" text |
| Context injection suppression | Won't inject emergence prompt if JICM >= 55% | `isContextBudgetSafe()` reads watcher status |

## Dependencies

| Dependency | Path | Purpose |
|------------|------|---------|
| Detector hook | `.claude/hooks/ulfhedthnar-detector.js` | Signal detection + activation |
| Unleash command | `.claude/commands/unleash.md` | Manual activation |
| Locked skill | `.claude/skills/ulfhedthnar/SKILL.md` | Protocol reference |
| Telemetry | `.claude/hooks/telemetry-emitter.js` | Event logging |
| Wiggum tracker | `.claude/hooks/wiggum-loop-tracker.js` | Loop stall detection |
| Agent log | `.claude/logs/agent-activity.jsonl` | Cascade detection |

## State Files

| File | Purpose |
|------|---------|
| `.claude/state/components/AC-10-ulfhedthnar.json` | Component state |
| `.claude/state/ulfhedthnar-signals.json` | Signal accumulator |
| `.claude/state/ulfhedthnar-progress.json` | Progress anchoring |
| `.claude/reports/ulfhedthnar/` | Resolution reports |

## Telemetry Events

All events use component ID `AC-10`:

| Event | Description |
|-------|-------------|
| `barrier_detected` | Defeat signals exceeded threshold |
| `unleash_manual` | User ran /unleash command |
| `unleash_auto` | User confirmed emergence prompt |
| `frenzy_start` | Parallel agents spawned |
| `approach_rotate` | Strategy cycling to next approach |
| `progress_anchor` | Partial solution saved |
| `problem_resolved` | Barrier overcome successfully |
| `disengage` | Returned to dormant state |

## Lifecycle

```
DORMANT
  │
  ├─ defeat signals accumulate
  │  cumulative weight >= 7
  │
  ▼
EMERGENCE
  │ "Ulfhedthnar senses resistance..."
  │
  ├─ user confirms → ACTIVE
  └─ user declines → DORMANT (log barrier)

ACTIVE
  │
  ├─ Frenzy Mode → Berserker Loop → Approach Rotation
  │
  ├─ problem solved → RESOLVED
  ├─ user cancels → DORMANT
  └─ strategies exhausted → DORMANT (with report)

RESOLVED
  │ write report, emit telemetry
  │ clear signals, update metrics
  ▼
DORMANT (30 min cooldown)
```

---

*AC-10 Ulfhedthnar — The wolf-warrior who fights when the Muses cannot sing*
*Neuros Override System — Roadmap II Phase B.7*
