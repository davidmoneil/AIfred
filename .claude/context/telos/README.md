# TELOS Goal Alignment System

**Purpose**: Strategic layer providing clarity on problems being solved, mission, goals, and success metrics.

---

## Overview

TELOS (from Greek, meaning "purpose" or "end goal") is a framework for articulating identity, values, and goals. It sits **above** the tactical `current-priorities.md` system, providing the "why" behind daily work.

```
TELOS (Strategic)          "Why am I doing this?"
    │
    ├── Problems           What issues am I solving?
    ├── Mission            What's my ultimate purpose?
    ├── Goals              What am I trying to achieve?
    └── Metrics            How do I know I'm succeeding?
          │
          ▼
current-priorities.md      "What do I do today/this week?"
(Tactical)
          │
          ▼
orchestration/*.yaml       "How do I break this down?"
(Execution)
```

---

## Directory Structure

```
telos/
├── TELOS.md                    # Master file - overall direction
├── domains/
│   ├── technical.md            # AIProjects / Infrastructure / Professional
│   ├── creative.md             # Writing, CreativeProjects
│   └── personal.md             # Personal growth (placeholder)
├── goals/
│   ├── active-goals.yaml       # Machine-readable for hooks
│   └── archive/                # Completed goals by quarter
├── templates/
│   ├── domain-template.md      # Template for new domains
│   └── goal-template.yaml      # Template for goal entries
└── README.md                   # This file
```

---

## Quick Start

### View Current Status
```
/telos                    # Summary of mission + active goals
/telos goals              # List all goals with status
/telos domain technical   # Deep dive into technical domain
```

### Update Progress
```
/telos update G-T1        # Update goal status
/telos review             # Start review workflow
```

### Add New Goal
```
/telos add goal           # Guided goal creation
```

---

## Core Four Components

### 1. Problems (P)
What issues are you solving? Ground goals in real problems.

**Format**: `P-[D][N]` (e.g., P-T1 = Problem, Technical domain, #1)

### 2. Mission (M)
Why does this domain exist? What's the ultimate purpose?

One clear statement per domain that unifies all goals.

### 3. Goals (G)
What are you trying to achieve? Time-bound, measurable targets.

**Format**: `G-[D][N]` (e.g., G-T1 = Goal, Technical domain, #1)

**Status Values**:
- 🟢 On Track
- 🟡 At Risk
- 🔴 Blocked
- ✅ Achieved

### 4. Metrics (M)
How do you measure success? Objective indicators of progress.

**Format**: `M-[D][N]` (e.g., M-T1 = Metric, Technical domain, #1)

---

## Domains

| Domain | Code | Focus |
|--------|------|-------|
| Technical | T | AIProjects, infrastructure, professional |
| Creative | C | Writing, worldbuilding, artistic work |
| Personal | P | Health, family, growth (placeholder) |
| Cross-domain | X | Goals spanning multiple domains |

---

## Review Cadence

| Type | Frequency | Duration | Purpose |
|------|-----------|----------|---------|
| **Weekly** | Every Monday | 5-10 min | Status check, flag at-risk |
| **Monthly** | 1st of month | 30-60 min | Metrics review, adjust goals |
| **Quarterly** | End of quarter | 60-90 min | Strategic reassessment |
| **On-Change** | As needed | Varies | Goal completion, direction shift |

---

## Integration Points

### Session Start
- `session-start.js` hook auto-injects TELOS summary
- Shows mission + active goals at start of each session

### Current Priorities
- TELOS goals link to `current-priorities.md` items
- Bidirectional: priorities reference TELOS, TELOS references priorities

### Orchestration
- Complex goals can be broken into orchestration plans
- Link: `orchestration/*.yaml` → `telos_goal: G-T1`

---

## Files

| File | Purpose | Update Frequency |
|------|---------|------------------|
| `TELOS.md` | Master overview, cross-domain summary | Weekly/Monthly |
| `domains/*.md` | Domain-specific problems, mission, goals | Monthly |
| `goals/active-goals.yaml` | Machine-readable goals for hooks | On change |
| `goals/archive/*.yaml` | Historical record | Quarterly |

---

## Related Documentation

- [Current Priorities](../projects/current-priorities.md) - Tactical execution
- [Session State](../session-state.md) - Current work focus
- [TELOS Review Workflow](../workflows/telos-review.md) - Review procedures
- [Monthly Priority Review](../workflows/monthly-priority-review.md) - Integration point
