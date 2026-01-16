# Override and Disable Pattern

**Version**: 1.0.0
**Created**: 2026-01-16
**Status**: Active
**PR**: PR-11.5

---

## Overview

This pattern defines how to override default behavior or completely disable autonomic components. It ensures that users maintain ultimate control while preserving audit trails and enabling safe recovery.

### Core Principle

**User has ultimate authority.** While autonomy is the default, users can always override, pause, or disable any component at any time.

---

## 1. Disable Mechanisms

### 1.1 Component Disable Hierarchy

```
┌─────────────────────────────────────────────────────────────┐
│                    DISABLE HIERARCHY                         │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Level 1: Session Pause (Ctrl+C / interrupt)                │
│  └── Immediate pause, resumable                             │
│                                                             │
│  Level 2: Session Disable (environment variable)            │
│  └── Component skipped for this session only                │
│                                                             │
│  Level 3: Persistent Disable (config file)                  │
│  └── Component disabled until re-enabled                    │
│                                                             │
│  Level 4: Emergency Stop (kill switch)                      │
│  └── All autonomic systems halted immediately               │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### 1.2 Per-Component Disable

Each autonomic component can be individually disabled.

**Environment Variable Method** (session-scoped):
```bash
# Disable specific component for this session
export JARVIS_DISABLE_AC01=true  # Self-Launch
export JARVIS_DISABLE_AC02=true  # Wiggum Loop
export JARVIS_DISABLE_AC03=true  # Milestone Review
export JARVIS_DISABLE_AC04=true  # JICM
export JARVIS_DISABLE_AC05=true  # Self-Reflection
export JARVIS_DISABLE_AC06=true  # Self-Evolution
export JARVIS_DISABLE_AC07=true  # R&D Cycles
export JARVIS_DISABLE_AC08=true  # Maintenance
export JARVIS_DISABLE_AC09=true  # Session Completion
```

**Configuration File Method** (persistent):

**Location**: `.claude/config/autonomy-config.yaml`

```yaml
# Autonomic Component Configuration
version: "1.0"

components:
  AC-01-launch:
    enabled: true
    override_greeting: false

  AC-02-wiggum:
    enabled: true
    default_suppressed: false  # Set true to disable by default

  AC-03-review:
    enabled: true
    auto_escalate: true

  AC-04-jicm:
    enabled: true
    threshold_tokens: 150000

  AC-05-reflect:
    enabled: true
    min_idle_minutes: 30

  AC-06-evolve:
    enabled: true
    require_approval: true  # Cannot be disabled

  AC-07-rnd:
    enabled: true
    sources:
      - github
      - arxiv
      - web

  AC-08-maintain:
    enabled: true
    scope: both  # jarvis | project | both

  AC-09-session:
    enabled: true
    offer_self_improve: true
```

### 1.3 Disable Commands

**Via Command Line**:
```bash
# List current component status
jarvis status --components

# Disable component for session
jarvis disable AC-02 --session

# Disable component persistently
jarvis disable AC-02 --persistent

# Re-enable component
jarvis enable AC-02

# Check why component is disabled
jarvis status AC-02 --verbose
```

**Via Slash Command**:
```
/autonomy disable AC-02        # Persistent
/autonomy disable AC-02 --session
/autonomy enable AC-02
/autonomy status
```

---

## 2. Emergency Stop Mechanisms

### 2.1 Immediate Halt

**Keyboard Interrupt** (Ctrl+C):
- Pauses current operation
- Preserves state for resume
- Logs interrupt event
- Prompts for action: resume/abort/disable

**Kill Switch**:
```bash
# Stop all autonomic systems immediately
export JARVIS_EMERGENCY_STOP=true

# Or via command
jarvis stop --emergency
```

### 2.2 Emergency Stop Behavior

When emergency stop is triggered:

1. **All running components halt** — Current operations abort
2. **State snapshot saved** — For recovery
3. **Event logged** — With timestamp and trigger
4. **All queues frozen** — No new operations started
5. **User notified** — Clear message displayed

```
╔═══════════════════════════════════════════════════════════════╗
║  ⚠️  EMERGENCY STOP ACTIVATED                                 ║
╠═══════════════════════════════════════════════════════════════╣
║                                                               ║
║  All autonomic systems have been halted.                      ║
║                                                               ║
║  Triggered: 2026-01-16 14:30:00                               ║
║  Reason: User-initiated (Ctrl+C × 3)                          ║
║                                                               ║
║  State snapshot saved to:                                     ║
║    .claude/state/emergency-stop-2026-01-16-143000.json        ║
║                                                               ║
║  To resume: jarvis resume --from-stop                         ║
║  To reset:  jarvis reset --clear-stop                         ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝
```

### 2.3 Recovery from Emergency Stop

```bash
# View what was interrupted
jarvis status --emergency

# Resume from stop point
jarvis resume --from-stop

# Resume with specific components disabled
jarvis resume --from-stop --disable AC-06

# Full reset (discard interrupted work)
jarvis reset --clear-stop
```

---

## 3. Configuration Scope

### 3.1 Scope Types

| Scope | Duration | Storage | Override |
|-------|----------|---------|----------|
| **Invocation** | Single command | Memory | Environment var |
| **Session** | Until `/clear` or exit | Environment | Export |
| **Persistent** | Until changed | Config file | Edit file |
| **Default** | Always (baseline) | Code | Requires PR |

### 3.2 Scope Precedence

```
┌─────────────────────────────────────────────────────────────┐
│              CONFIGURATION PRECEDENCE                        │
│              (highest to lowest priority)                    │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  1. Emergency Stop       →  Overrides everything            │
│  2. Invocation Override  →  This specific call only         │
│  3. Session Override     →  Environment variable            │
│  4. Persistent Config    →  autonomy-config.yaml            │
│  5. Component Default    →  Built-in default behavior       │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### 3.3 Configuration Resolution

```javascript
// Pseudocode for config resolution
function isComponentEnabled(componentId) {
  // 1. Check emergency stop
  if (process.env.JARVIS_EMERGENCY_STOP === 'true') {
    return false;
  }

  // 2. Check invocation override
  if (invocationOverrides[componentId] !== undefined) {
    return invocationOverrides[componentId];
  }

  // 3. Check session override
  const envVar = `JARVIS_DISABLE_${componentId.replace('-', '')}`;
  if (process.env[envVar] === 'true') {
    return false;
  }

  // 4. Check persistent config
  const config = loadConfig('autonomy-config.yaml');
  if (config.components[componentId]?.enabled === false) {
    return false;
  }

  // 5. Return default (enabled)
  return true;
}
```

---

## 4. Override Patterns

### 4.1 Behavior Override

Override component behavior without disabling:

```yaml
# In autonomy-config.yaml
components:
  AC-02-wiggum:
    enabled: true
    overrides:
      max_passes: 2         # Default: 5
      timeout_ms: 60000     # Default: 300000

  AC-04-jicm:
    enabled: true
    overrides:
      threshold_tokens: 100000  # Default: 150000
      compression_target: 0.5   # Default: 0.6
```

### 4.2 Conditional Override

Enable/disable based on conditions:

```yaml
# In autonomy-config.yaml
components:
  AC-06-evolve:
    enabled: true
    conditions:
      disable_if:
        - "PROJECT_TYPE == 'production'"
        - "BRANCH == 'main'"
      enable_if:
        - "BRANCH =~ 'feature/*'"

  AC-07-rnd:
    enabled: true
    conditions:
      disable_if:
        - "OFFLINE_MODE == true"
```

### 4.3 Quick Mode

Disable autonomy features for quick operations:

```bash
# User says "quick" or "rough" or "simple"
# Automatically sets:
export JARVIS_QUICK_MODE=true

# Which disables:
# - AC-02 Wiggum Loop (single pass only)
# - AC-03 Milestone Review (skip)
# - AC-05 Self-Reflection (skip)
# - AC-08 Maintenance (skip)
```

### 4.4 Manual Mode

Full user control, no autonomy:

```bash
export JARVIS_MANUAL_MODE=true

# Disables all autonomic components
# Jarvis operates as reactive assistant only
```

---

## 5. Audit Logging Requirements

### 5.1 Required Audit Events

All override/disable actions MUST be logged:

| Event | Data Required |
|-------|---------------|
| Component disabled | component_id, scope, reason, timestamp |
| Component enabled | component_id, scope, timestamp |
| Override applied | component_id, override_type, value, timestamp |
| Emergency stop | trigger, components_affected, state_snapshot |
| Resume from stop | components_resumed, components_still_disabled |
| Quick mode activated | trigger_phrase, components_affected |
| Manual mode activated | timestamp, session_id |

### 5.2 Audit Event Schema

```jsonl
{
  "id": "uuid-v4",
  "timestamp": "2026-01-16T14:30:00.000Z",
  "event_type": "component_disabled",
  "component_id": "AC-02",
  "scope": "session",
  "reason": "User request via /autonomy disable",
  "triggered_by": "user",
  "session_id": "session-uuid",
  "previous_state": "enabled",
  "new_state": "disabled"
}
```

### 5.3 Audit File Location

```
.claude/audit/
├── overrides/
│   ├── 2026-01-16.jsonl    # Daily override events
│   └── archive/
├── emergency-stops/
│   ├── 2026-01-16-143000.json  # Emergency stop snapshots
│   └── archive/
└── config-changes/
    └── 2026-01-16.jsonl    # Config file changes
```

### 5.4 Audit Retention

| Event Type | Retention |
|------------|-----------|
| Component disable/enable | 90 days |
| Override applied | 90 days |
| Emergency stop | 1 year |
| Config changes | 1 year |

---

## 6. Safety Invariants

### 6.1 Cannot Be Disabled

Certain behaviors cannot be disabled even by user:

| Invariant | Reason |
|-----------|--------|
| Audit logging | Accountability requirement |
| Emergency stop | User safety |
| Gate enforcement for critical ops | Prevent accidental destruction |
| Baseline read-only rule | Protect upstream |

### 6.2 Degraded Mode Warnings

When components are disabled, warn user of implications:

```
[WARNING] Component AC-02 (Wiggum Loop) is disabled.
          Code changes will not be multi-pass verified.
          Quality may be reduced.
```

### 6.3 Disable Duration Limits

Optional limits on how long components can stay disabled:

```yaml
# In autonomy-config.yaml
safety:
  max_disable_duration:
    AC-02-wiggum: 24h      # Auto re-enable after 24 hours
    AC-06-evolve: 168h     # 1 week max
  warn_after:
    AC-02-wiggum: 4h       # Warn if disabled > 4 hours
```

---

## 7. File Structure

```
.claude/
├── config/
│   └── autonomy-config.yaml    # Persistent configuration
├── state/
│   ├── components/             # Component runtime state
│   └── emergency-stop-*.json   # Emergency stop snapshots
└── audit/
    ├── overrides/              # Override audit logs
    ├── emergency-stops/        # Emergency stop logs
    └── config-changes/         # Config change logs
```

---

## 8. Implementation Checklist

### Configuration System

- [ ] Create `autonomy-config.yaml` schema
- [ ] Implement config file reader
- [ ] Implement environment variable checks
- [ ] Build precedence resolver
- [ ] Add config validation

### Disable Mechanisms

- [ ] Per-component disable support
- [ ] Session-scoped disable
- [ ] Persistent disable
- [ ] Quick mode detection
- [ ] Manual mode support

### Emergency Stop

- [ ] Keyboard interrupt handler (Ctrl+C detection)
- [ ] Kill switch environment variable
- [ ] State snapshot on stop
- [ ] Recovery commands
- [ ] User notification display

### Commands

- [ ] `jarvis status --components`
- [ ] `jarvis disable <component>`
- [ ] `jarvis enable <component>`
- [ ] `jarvis stop --emergency`
- [ ] `jarvis resume --from-stop`
- [ ] `/autonomy` slash command

### Audit

- [ ] Event logging for all actions
- [ ] Audit file management
- [ ] Retention policy enforcement

---

## 9. Quick Reference

### Disable Component

```bash
# Session only
export JARVIS_DISABLE_AC02=true

# Persistent
jarvis disable AC-02 --persistent

# Slash command
/autonomy disable AC-02
```

### Emergency Stop

```bash
# Keyboard
Ctrl+C (3 times rapid = emergency)

# Command
jarvis stop --emergency

# Environment
export JARVIS_EMERGENCY_STOP=true
```

### Quick Mode

```
User: "just do a quick fix"
→ Wiggum Loop suppressed
→ Reviews skipped
→ Single-pass only
```

### Full Manual

```bash
export JARVIS_MANUAL_MODE=true
→ All autonomy disabled
→ Reactive mode only
```

---

*Override and Disable Pattern — Jarvis Phase 6 PR-11.5*
