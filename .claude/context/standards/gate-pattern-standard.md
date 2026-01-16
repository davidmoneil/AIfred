# Gate Pattern Standard

**Version**: 1.0.0
**Created**: 2026-01-16
**Status**: Active
**PR**: PR-11.4

---

## Overview

This standard defines the approval checkpoint pattern used by autonomic components to control actions based on risk level. Gates ensure that higher-risk operations receive appropriate oversight while allowing low-risk operations to proceed autonomously.

### Core Principle

**Autonomy is default; gates are for exceptions.** Most operations should proceed without human intervention. Gates exist only for operations where the consequences of error are significant or irreversible.

---

## 1. Risk Levels

### 1.1 Risk Classification Matrix

| Risk Level | Definition | Human Involvement | Example Operations |
|------------|------------|-------------------|-------------------|
| **Low** | Reversible, Jarvis-internal, no external effect | None (auto-approve) | Read files, update metrics, emit events |
| **Medium** | Project-affecting, reversible with effort | Notify, proceed unless veto | Modify project code, create files |
| **High** | External/permanent effects, hard to reverse | Require explicit approval | Push to remote, delete files, API calls with side effects |
| **Critical** | Potentially destructive, irreversible | Block until confirmed | Force push, drop database, production changes |

### 1.2 Risk Assessment Criteria

| Factor | Low | Medium | High | Critical |
|--------|-----|--------|------|----------|
| **Scope** | Jarvis internal | Active project | External systems | Production |
| **Reversibility** | Trivially reversible | Reversible with effort | Difficult to reverse | Irreversible |
| **Side Effects** | None | Local | External | Permanent |
| **Data Loss Potential** | None | Recoverable | Significant | Catastrophic |
| **Cost Implication** | None | Minimal | Moderate | Significant |

### 1.3 Component Risk Profiles

| Component | Typical Risk Level | Elevated Risk Triggers |
|-----------|-------------------|------------------------|
| AC-01 Self-Launch | Low | External API calls (weather) |
| AC-02 Wiggum Loop | Low-Medium | Code modifications |
| AC-03 Milestone Review | Low | Rejection with recommendations |
| AC-04 JICM | Low | Checkpoint with continuation |
| AC-05 Self-Reflection | Low | Pattern storage |
| AC-06 Self-Evolution | Medium-High | Code changes, config updates |
| AC-07 R&D Cycles | Low-Medium | External queries, proposals |
| AC-08 Maintenance | Medium | File organization, cleanup |
| AC-09 Session Completion | Low | Commit, push |

---

## 2. Gate Types

### 2.1 Auto-Approve Gate (Low Risk)

```
┌─────────────────────────────────────────┐
│         AUTO-APPROVE GATE               │
├─────────────────────────────────────────┤
│  Risk Level: LOW                        │
│  Action: Proceed immediately            │
│  Notification: Silent (log only)        │
│  Timeout: N/A                           │
└─────────────────────────────────────────┘
```

**Behavior**:
- Operation proceeds without pause
- Event logged to audit trail
- No user notification
- No veto window

**Use Cases**:
- Reading configuration files
- Updating internal state
- Emitting metrics
- Internal calculations

### 2.2 Notify-Proceed Gate (Medium Risk)

```
┌─────────────────────────────────────────┐
│         NOTIFY-PROCEED GATE             │
├─────────────────────────────────────────┤
│  Risk Level: MEDIUM                     │
│  Action: Notify, proceed after window   │
│  Notification: User visible             │
│  Veto Window: 5 seconds                 │
└─────────────────────────────────────────┘
```

**Behavior**:
- Display notification to user
- Start veto window countdown
- If no veto: proceed
- If veto: abort with logged reason

**Notification Format**:
```
[GATE] Medium-risk operation: Creating new file src/utils/helper.js
       Proceeding in 5s unless interrupted (Ctrl+C to veto)
```

**Use Cases**:
- Creating new files in project
- Modifying existing code
- Running external commands
- Installing dependencies

### 2.3 Approval-Required Gate (High Risk)

```
┌─────────────────────────────────────────┐
│       APPROVAL-REQUIRED GATE            │
├─────────────────────────────────────────┤
│  Risk Level: HIGH                       │
│  Action: Queue and wait for approval    │
│  Notification: Prompt user              │
│  Timeout: Session-scoped (or explicit)  │
└─────────────────────────────────────────┘
```

**Behavior**:
- Add to approval queue
- Display prompt to user
- Wait for explicit yes/no
- Log decision and rationale

**Prompt Format**:
```
[APPROVAL REQUIRED] High-risk operation detected

Operation: Push commits to origin/Project_Aion
Risk: HIGH - External effect, visible to others
Rationale: 3 commits ready for push

Approve? (y/n/details):
```

**Use Cases**:
- Git push to remote
- Deleting files
- External API calls with side effects
- Self-evolution code changes

### 2.4 Confirmation-Required Gate (Critical Risk)

```
┌─────────────────────────────────────────┐
│      CONFIRMATION-REQUIRED GATE         │
├─────────────────────────────────────────┤
│  Risk Level: CRITICAL                   │
│  Action: Block, require confirmation    │
│  Notification: Warning + prompt         │
│  Timeout: None (must be explicit)       │
└─────────────────────────────────────────┘
```

**Behavior**:
- Display warning banner
- Require typed confirmation (not just y/n)
- Log full context and decision
- Support abort with no penalty

**Prompt Format**:
```
╔═══════════════════════════════════════════════════════════════╗
║  ⚠️  CRITICAL OPERATION - CONFIRMATION REQUIRED              ║
╠═══════════════════════════════════════════════════════════════╣
║  Operation: Force push to origin/main                         ║
║  Risk: CRITICAL - Destructive, affects shared branch          ║
║                                                               ║
║  This operation:                                              ║
║    - Will overwrite remote history                            ║
║    - May cause data loss for collaborators                    ║
║    - Cannot be easily undone                                  ║
║                                                               ║
║  Type "CONFIRM FORCE PUSH" to proceed, or "abort" to cancel:  ║
╚═══════════════════════════════════════════════════════════════╝
```

**Use Cases**:
- Force push
- Database drops
- Production deployments
- Bulk file deletion
- Configuration resets

---

## 3. Approval Queue

### 3.1 Queue Structure

**Location**: `.claude/state/queues/approval-queue.json`

```json
{
  "$schema": "approval-queue-v1",
  "queue_name": "approval-queue",
  "items": [
    {
      "id": "uuid-v4",
      "added": "2026-01-16T14:30:00.000Z",
      "source": "AC-06",
      "operation": "self-evolution",
      "description": "Update error handling pattern in session-start.sh",
      "risk_level": "high",
      "details": {
        "files_affected": ["session-start.sh"],
        "change_type": "modify",
        "estimated_impact": "low"
      },
      "status": "pending",
      "expires": "2026-01-17T14:30:00.000Z",
      "decision": null,
      "decided_at": null,
      "decided_by": null
    }
  ]
}
```

### 3.2 Queue Item States

| State | Description | Next States |
|-------|-------------|-------------|
| `pending` | Awaiting decision | `approved`, `rejected`, `expired` |
| `approved` | User approved | `executed`, `failed` |
| `rejected` | User rejected | (terminal) |
| `expired` | Timeout exceeded | (terminal) |
| `executed` | Successfully completed | (terminal) |
| `failed` | Execution failed | `pending` (retry) |

### 3.3 Queue Processing

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Pending   │────▶│  Decision   │────▶│  Execution  │
└─────────────┘     └─────────────┘     └─────────────┘
      │                   │                   │
      │ timeout           │ reject            │ fail
      ▼                   ▼                   ▼
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Expired   │     │  Rejected   │     │   Failed    │
└─────────────┘     └─────────────┘     └──────┬──────┘
                                               │ retry
                                               ▼
                                        ┌─────────────┐
                                        │   Pending   │
                                        └─────────────┘
```

---

## 4. User Notification Patterns

### 4.1 Notification Levels

| Level | When | Format | Persistence |
|-------|------|--------|-------------|
| **Silent** | Low risk, auto-approved | Log only | Audit file |
| **Info** | FYI, no action needed | Inline text | Session |
| **Notice** | Medium risk, veto window | Highlighted | Session |
| **Prompt** | High risk, needs response | Interactive | Until decided |
| **Warning** | Critical risk | Banner | Until confirmed |

### 4.2 Notification Formats

**Silent** (log only):
```jsonl
{"level": "silent", "operation": "read_config", "result": "auto_approved"}
```

**Info**:
```
[INFO] Self-reflection cycle completed: 3 patterns documented
```

**Notice**:
```
[NOTICE] Medium-risk: Modifying src/utils/helper.js
         Proceeding in 5s... (Ctrl+C to abort)
```

**Prompt**:
```
[APPROVAL] Push 3 commits to origin/Project_Aion?
           (y)es / (n)o / (d)etails:
```

**Warning**:
```
╔═══════════════════════════════════════╗
║  ⚠️  WARNING: Critical Operation      ║
╠═══════════════════════════════════════╣
║  [Details...]                         ║
╚═══════════════════════════════════════╝
```

### 4.3 Batch Notifications

When multiple items need approval:

```
[APPROVAL QUEUE] 3 items pending approval:

1. [HIGH] Push commits to origin (AC-09)
2. [HIGH] Update session-start.sh (AC-06)
3. [MEDIUM] Create new pattern file (AC-05)

Review queue? (y/n):
```

---

## 5. Override Mechanisms

### 5.1 Veto (Cancel Pending)

User can veto any operation during its window:

- **Low Risk**: No veto window
- **Medium Risk**: Ctrl+C during 5-second window
- **High Risk**: Respond "n" to prompt
- **Critical Risk**: Type "abort" at confirmation

### 5.2 Force Approve

Batch approve all pending items:

```bash
# Approve all pending items
jarvis approve --all

# Approve specific item
jarvis approve <item-id>

# Approve with expiration
jarvis approve --all --expires 1h
```

### 5.3 Bypass Gate

Temporarily bypass gates for a session:

```bash
# Lower gate threshold for session
export JARVIS_GATE_THRESHOLD=high  # Only critical requires approval

# Disable gates entirely (DANGEROUS)
export JARVIS_GATES_DISABLED=true
```

**Note**: Gate bypass is logged and flagged in session summary.

### 5.4 Escalation Override

Components can request gate escalation:

```json
{
  "gate_override": {
    "requested_level": "low",
    "actual_level": "high",
    "reason": "R&D-sourced proposal",
    "escalated_by": "AC-07"
  }
}
```

---

## 6. Audit Trail

### 6.1 Gate Event Schema

```jsonl
{
  "id": "uuid-v4",
  "timestamp": "2026-01-16T14:30:00.000Z",
  "event_type": "gate_decision",
  "gate_type": "approval_required",
  "risk_level": "high",
  "component": "AC-06",
  "operation": "self-evolution",
  "description": "Update error handling pattern",
  "decision": "approved",
  "decided_by": "user",
  "decided_at": "2026-01-16T14:30:15.000Z",
  "veto_window_ms": null,
  "queue_time_ms": 15000,
  "notes": "User approved after reviewing diff"
}
```

### 6.2 Audit File Location

```
.claude/audit/
├── gates/
│   ├── 2026-01-16.jsonl    # Daily gate decisions
│   └── archive/            # Older logs
└── summary/
    └── gate-stats.json     # Aggregated statistics
```

### 6.3 Gate Statistics

Tracked for analysis:

| Metric | Description |
|--------|-------------|
| `total_gates` | Total gate checks |
| `auto_approved` | Low-risk auto-approvals |
| `user_approved` | User-approved operations |
| `user_rejected` | User-rejected operations |
| `expired` | Timed-out items |
| `avg_decision_time` | Time to user decision |
| `veto_rate` | Percentage vetoed |

---

## 7. Implementation Checklist

### Per-Component Requirements

- [ ] Assess risk level for each operation type
- [ ] Invoke appropriate gate before risky operations
- [ ] Handle gate responses (approved/rejected/expired)
- [ ] Log all gate events to audit trail
- [ ] Support veto/abort gracefully

### System Requirements

- [ ] Implement approval queue manager
- [ ] Create notification display system
- [ ] Build gate decision prompt handler
- [ ] Set up audit logging
- [ ] Implement bypass controls with logging

### Integration Points

- [ ] Hook into component execution pipeline
- [ ] Connect to metrics collection
- [ ] Link to session completion summary
- [ ] Support Memory MCP for cross-session patterns

---

## 8. Gate Decision Tree

```
┌──────────────────────────────────────────────────────────┐
│                  OPERATION INITIATED                      │
└────────────────────────┬─────────────────────────────────┘
                         │
                         ▼
              ┌──────────────────────┐
              │  Assess Risk Level   │
              └──────────┬───────────┘
                         │
         ┌───────────────┼───────────────┬─────────────────┐
         │               │               │                 │
         ▼               ▼               ▼                 ▼
    ┌─────────┐    ┌─────────┐    ┌─────────┐       ┌──────────┐
    │   LOW   │    │ MEDIUM  │    │  HIGH   │       │ CRITICAL │
    └────┬────┘    └────┬────┘    └────┬────┘       └────┬─────┘
         │              │              │                  │
         ▼              ▼              ▼                  ▼
    ┌─────────┐    ┌─────────┐    ┌─────────┐       ┌──────────┐
    │  Auto-  │    │ Notify  │    │  Queue  │       │  Block   │
    │ Approve │    │ Proceed │    │  Wait   │       │ Confirm  │
    └────┬────┘    └────┬────┘    └────┬────┘       └────┬─────┘
         │              │              │                  │
         │         ┌────┴────┐    ┌────┴────┐       ┌────┴─────┐
         │         │ Vetoed? │    │Approved?│       │Confirmed?│
         │         └────┬────┘    └────┬────┘       └────┬─────┘
         │         Yes  │  No     Yes  │  No        Yes  │  No
         │          │   │          │   │             │   │
         │          ▼   ▼          ▼   ▼             ▼   ▼
         │       ┌─────┐ │      ┌─────┐ │         ┌─────┐ │
         │       │Abort│ │      │ Run │ │         │ Run │ │
         │       └─────┘ │      └─────┘ │         └─────┘ │
         │               │              │                 │
         └───────────────┴──────────────┴─────────────────┘
                                │
                                ▼
                    ┌───────────────────────┐
                    │   Log to Audit Trail  │
                    └───────────────────────┘
```

---

*Gate Pattern Standard — Jarvis Phase 6 PR-11.4*
