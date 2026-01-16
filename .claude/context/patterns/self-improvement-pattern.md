# Self-Improvement Orchestration Pattern

**Pattern ID**: self-improvement-orchestration
**Version**: 1.0.0
**Status**: implementing
**Created**: 2026-01-16
**PR**: PR-12.10

---

## Overview

The Self-Improvement Orchestration pattern defines how Jarvis coordinates multiple Tier 2 autonomic components to achieve continuous self-improvement. This pattern enables Jarvis to reflect on experience, research new capabilities, maintain codebase health, and evolve safely—all without constant user oversight.

### Core Principles

1. **Orchestrated Sequence**: Components run in optimal order (reflect → maintain → research → evolve)
2. **Proposal Pipeline**: Earlier phases generate proposals; evolution phase processes them
3. **Risk-Based Gates**: Low-risk auto-approved; medium/high require user approval
4. **Extended Autonomy**: Can run for hours with periodic checkpoints
5. **Graceful Degradation**: Continues even when individual components fail

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│              SELF-IMPROVEMENT ORCHESTRATION ARCHITECTURE             │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  TRIGGER SOURCES                                                     │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐                 │
│  │ /self-      │  │ Downtime    │  │ Session     │                 │
│  │ improve     │  │ Detector    │  │ Pre-Exit    │                 │
│  │ (manual)    │  │ (~30 min)   │  │ (AC-09)     │                 │
│  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘                 │
│         │                │                │                         │
│         └────────────────┼────────────────┘                         │
│                          │                                          │
│                          ▼                                          │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │                   ORCHESTRATOR                               │   │
│  │                                                              │   │
│  │  • Parses options (--focus, --skip, --dry-run)              │   │
│  │  • Initializes state file                                   │   │
│  │  • Manages Wiggum Loop integration                          │   │
│  │  • Monitors JICM thresholds                                 │   │
│  │  • Handles errors and graceful degradation                  │   │
│  └──────────────────────────┬──────────────────────────────────┘   │
│                              │                                      │
│         ┌────────────────────┼────────────────────┐                │
│         │                    │                    │                │
│         ▼                    ▼                    ▼                │
│  ┌─────────────┐     ┌─────────────┐     ┌─────────────┐          │
│  │   Phase 1   │     │   Phase 2   │     │   Phase 3   │          │
│  │  AC-05      │────▶│  AC-08      │────▶│  AC-07      │          │
│  │ Reflection  │     │ Maintenance │     │ R&D Cycles  │          │
│  └──────┬──────┘     └──────┬──────┘     └──────┬──────┘          │
│         │                    │                    │                │
│         │    Proposals       │    Proposals       │    Proposals   │
│         └────────────────────┴────────────────────┘                │
│                              │                                      │
│                              ▼                                      │
│                    ┌─────────────────┐                             │
│                    │    Phase 4      │                             │
│                    │    AC-06        │                             │
│                    │  Self-Evolution │                             │
│                    └────────┬────────┘                             │
│                             │                                       │
│              ┌──────────────┼──────────────┐                       │
│              │              │              │                       │
│              ▼              ▼              ▼                       │
│       ┌───────────┐  ┌───────────┐  ┌───────────┐                 │
│       │ Auto-     │  │ Queued    │  │ Rejected  │                 │
│       │ Implement │  │ (Approval)│  │ (Logged)  │                 │
│       │ (Low Risk)│  │           │  │           │                 │
│       └───────────┘  └───────────┘  └───────────┘                 │
│                              │                                      │
│                              ▼                                      │
│                    ┌─────────────────┐                             │
│                    │    Phase 5      │                             │
│                    │  Summary &      │                             │
│                    │  Approval       │                             │
│                    └─────────────────┘                             │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Phase Orchestration

### Phase Ordering Rationale

The phases run in this specific order for optimal results:

| Order | Phase | Rationale |
|-------|-------|-----------|
| 1 | Reflection | Generates insights from recent work |
| 2 | Maintenance | Identifies structural issues |
| 3 | R&D | Discovers external improvements |
| 4 | Evolution | Processes all proposals from 1-3 |
| 5 | Summary | Presents results and requests approvals |

**Why this order?**
- Reflection first: Fresh insights from recent session
- Maintenance second: Identify issues before researching solutions
- R&D third: External research informed by known issues
- Evolution last: Process ALL proposals with full context

### Data Flow Between Phases

```
┌─────────────────────────────────────────────────────────────────────┐
│                    PROPOSAL PIPELINE                                 │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  Phase 1 (Reflection)                                                │
│  └─▶ Proposals:                                                     │
│      • Pattern improvements                                         │
│      • Correction-based fixes                                       │
│      • Efficiency learnings                                         │
│                                                                      │
│  Phase 2 (Maintenance)                                               │
│  └─▶ Proposals:                                                     │
│      • Organization fixes                                           │
│      • Freshness updates                                            │
│      • Consolidation opportunities                                  │
│                                                                      │
│  Phase 3 (R&D)                                                       │
│  └─▶ Proposals (require-approval):                                  │
│      • New tool adoptions                                           │
│      • Pattern adaptations                                          │
│      • Efficiency improvements                                      │
│                                                                      │
│  Phase 4 (Evolution)                                                 │
│  └─▶ Receives all proposals                                         │
│      └─▶ Triage by risk                                             │
│          └─▶ Low: Auto-implement                                    │
│          └─▶ Medium/High: Queue for approval                        │
│          └─▶ R&D-sourced: Always queue                              │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Trigger Integration

### Manual Trigger (/self-improve)

Primary invocation method:

```
User: /self-improve

Orchestrator:
  1. Parse options
  2. Initialize state
  3. Run phases in sequence
  4. Present summary
  5. Handle approvals
```

### Downtime Trigger

When user is idle for ~30 minutes:

```
Downtime Detector:
  1. Detect idle (no user input for 30 min)
  2. Check autonomy-config.yaml
  3. If auto_self_improve: true
     → Run /self-improve --focus=maintenance,reflection
  4. Save results silently
  5. Present summary when user returns
```

Configuration:
```yaml
# autonomy-config.yaml
downtime:
  idle_threshold_minutes: 30
  auto_self_improve: true
  focus: ["reflection", "maintenance"]  # Limited scope
```

### Pre-Session-End Trigger

When user runs `/end-session`:

```
AC-09 Pre-Completion:
  1. Offer Tier 2 cycles
  2. If user selects self-improvement
     → Run /self-improve with selected focus
  3. Then proceed to completion protocol
```

---

## Wiggum Loop Integration

### Loop Wrapper

Self-improvement runs inside Wiggum Loop:

```
Wiggum Loop wraps /self-improve:

  EXECUTE: Run current phase
  CHECK: Verify phase output valid
  REVIEW: Quality check proposals
  DRIFT: Still aligned with improvement goals?
  CONTEXT: JICM threshold check
  CONTINUE: Next phase or complete
```

### TodoWrite Tracking

Each phase uses TodoWrite for visibility:

```
TodoWrite state during /self-improve:

[✓] Phase 1: Self-Reflection
[✓] Phase 2: Maintenance
[▶] Phase 3: R&D Cycles
[ ] Phase 4: Self-Evolution
[ ] Phase 5: Summary & Approval
```

### Drift Detection

Detects when self-improvement goes off track:

```
Drift indicators:
  - Phase taking >2x expected time
  - Proposals unrelated to Jarvis improvement
  - Context usage spiking unexpectedly
  - External research diverging from agenda

Response:
  - Log drift warning
  - Realign to original scope
  - Continue with next phase if stuck
```

---

## JICM Integration

### Context Monitoring

JICM monitors throughout execution:

```
JICM checkpoints:
  - Before each phase: Check threshold
  - During long phases: Periodic checks
  - After each phase: Log usage

Thresholds:
  - <50%: Continue normally
  - 50-70%: Warn, suggest skipping verbose phases
  - 70-85%: Checkpoint between phases
  - >85%: Emergency checkpoint, pause
```

### Checkpoint Strategy

Between-phase checkpoints preserve progress:

```json
// .claude/state/self-improve-state.json
{
  "checkpoint": {
    "timestamp": "2026-01-16T19:30:00.000Z",
    "phases_completed": [1, 2],
    "current_phase": 3,
    "proposals_collected": [
      {"id": "refl-001", "source": "AC-05", "status": "pending"},
      {"id": "maint-001", "source": "AC-08", "status": "pending"}
    ],
    "context_usage": 65
  }
}
```

### Resume After Clear

If JICM triggers /clear:

```
Resume flow:
  1. Session starts
  2. SessionStart hook detects checkpoint
  3. Loads self-improve-state.json
  4. Presents: "Self-improvement was interrupted. Resume from Phase 3?"
  5. If yes: Continue from checkpoint
  6. If no: Discard progress, start fresh
```

---

## Proposal Management

### Proposal Format

Standard format for all proposals:

```yaml
# Proposal structure
id: refl-2026-01-16-001
source: AC-05  # AC-05, AC-06, AC-07, AC-08
type: pattern_improvement
title: Add file usage tracking to R&D cycles
description: |
  Track which .claude files are loaded each session
  to identify high-use vs low-use files for optimization.
rationale: |
  Reflection identified that we don't know which context
  files are actually being used. This data would inform
  future consolidation efforts.
files:
  - .claude/hooks/file-usage-tracker.js
  - .claude/context/patterns/rd-cycles-pattern.md
risk: medium
require_approval: false  # true for R&D-sourced
status: pending
created: 2026-01-16T19:00:00.000Z
```

### Risk Classification

```
Risk levels:

LOW:
  - Documentation updates
  - Configuration tweaks
  - Non-breaking additions
  → Auto-implement (unless --dry-run)

MEDIUM:
  - New hooks
  - Pattern changes
  - File reorganization
  → Queue for approval

HIGH:
  - Core behavior changes
  - Hook logic changes
  - Cross-component changes
  → Queue for approval

R&D-SOURCED:
  - Any proposal from AC-07
  → Always require approval
```

### Approval Queue

Proposals awaiting approval:

```yaml
# .claude/state/queues/approval-queue.yaml
queue:
  - id: refl-001
    title: Add correction pattern tracking
    source: AC-05
    risk: medium
    created: 2026-01-16T19:00:00.000Z
    status: pending_approval

  - id: rd-001
    title: Adopt new MCP for code search
    source: AC-07
    risk: medium
    require_approval: true
    created: 2026-01-16T19:15:00.000Z
    status: pending_approval
```

---

## Configuration

### Full Configuration Schema

```yaml
# autonomy-config.yaml - self-improvement section

self_improve:
  # Enable/disable self-improvement
  enabled: true

  # Default time limit (minutes)
  default_time_limit: 120

  # Auto-approve low-risk proposals
  auto_approve_low_risk: true

  # Run under Wiggum Loop
  wiggum_loop: true

  # JICM checkpoint threshold (%)
  checkpoint_threshold: 70

  # Generate reports
  generate_reports: true

  # Report storage path
  report_path: .claude/reports/self-improve/

  # Maximum proposals per run
  max_proposals: 20

  # R&D discovery limit
  rd_discovery_limit: 5

  # Phase-specific settings
  phases:
    reflection:
      enabled: true
      max_corrections_scan: 50
      pattern_detection: true

    maintenance:
      enabled: true
      freshness_threshold_days: 30
      health_checks: true
      organization_review: true

    research:
      enabled: true
      internal_analysis: true
      external_discovery: true
      require_approval_all: true

    evolution:
      enabled: true
      auto_implement_low_risk: true
      max_auto_implements: 5
      branch_workflow: true

# Downtime trigger settings
downtime:
  idle_threshold_minutes: 30
  auto_self_improve: true
  focus: ["reflection", "maintenance"]
```

---

## Error Handling

### Phase-Level Failures

Each phase handles failures independently:

```
Phase failure handling:

try:
  run_phase(phase_id)
  mark_complete(phase_id)
except PhaseError as e:
  log_error(phase_id, e)
  mark_failed(phase_id)
  # Continue to next phase
  continue_orchestration()
```

### Graceful Degradation Matrix

| Failure | Phase | Response |
|---------|-------|----------|
| Memory MCP down | All | Skip persistence, continue |
| Git unavailable | Evolution | Skip commits, queue proposals |
| Web access down | R&D | Skip external, do internal only |
| JICM threshold | Any | Checkpoint, pause, allow resume |
| Timeout | Any | Checkpoint, report partial |

### Recovery Patterns

```
Recovery options:

1. Resume from checkpoint:
   /self-improve  # Auto-detects and offers resume

2. Force restart:
   /self-improve --restart

3. Skip failed phase:
   /self-improve --skip=research

4. Reduce scope:
   /self-improve --focus=reflection,maintenance
```

---

## Output Artifacts

### Reports Generated

| Report | Location | Content |
|--------|----------|---------|
| Consolidated | `.claude/reports/self-improve/report-YYYY-MM-DD.md` | Full summary |
| Reflection | `.claude/reports/reflection/` | AC-05 findings |
| Maintenance | `.claude/reports/maintenance/` | AC-08 reports |
| R&D | `.claude/reports/research/` | AC-07 findings |
| Evolution | `.claude/reports/evolution/` | AC-06 changes |

### State Files

| File | Purpose |
|------|---------|
| `self-improve-state.json` | Orchestration state |
| `evolution-queue.yaml` | Pending proposals |
| `approval-queue.yaml` | Awaiting user approval |

### Metrics

```jsonl
{"timestamp": "2026-01-16T20:00:00.000Z", "event": "self_improve_start", "options": {"focus": "all"}}
{"timestamp": "2026-01-16T20:02:00.000Z", "event": "phase_complete", "phase": "reflection", "proposals": 3}
{"timestamp": "2026-01-16T20:05:00.000Z", "event": "phase_complete", "phase": "maintenance", "issues": 5}
{"timestamp": "2026-01-16T20:15:00.000Z", "event": "phase_complete", "phase": "research", "discoveries": 2}
{"timestamp": "2026-01-16T20:25:00.000Z", "event": "phase_complete", "phase": "evolution", "implemented": 2, "queued": 4}
{"timestamp": "2026-01-16T20:27:00.000Z", "event": "self_improve_complete", "duration_minutes": 27}
```

---

## Best Practices

### When to Use /self-improve

**Good times**:
- End of work session (via pre-completion offer)
- After completing major milestone
- When you'll be away for a while
- Weekly maintenance window

**Avoid when**:
- Active work in progress
- Context budget tight
- Critical deadline approaching

### Focus Selection

| Situation | Recommended Focus |
|-----------|-------------------|
| Quick break | `--focus=maintenance` |
| End of session | `--focus=reflection,maintenance` |
| Weekly review | `all` (default) |
| After major PR | `--focus=reflection,evolution` |
| Research needed | `--focus=research` |

### Approval Strategy

```
Approval workflow:

1. Review summary first
2. Check risk levels
3. Approve low-risk batch
4. Review medium/high individually
5. Defer if uncertain (won't be implemented)
```

---

*Self-Improvement Orchestration Pattern — Jarvis Phase 6 PR-12.10*
