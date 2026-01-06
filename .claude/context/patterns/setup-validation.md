# Setup Validation Pattern

*Last updated: 2026-01-05*

---

## Overview

This pattern defines how to validate Jarvis setup at different stages and with different levels of thoroughness. It establishes a three-layer validation approach:

1. **Preflight** — Pre-setup boundary validation
2. **Readiness** — Post-setup completeness verification
3. **Health** — Ongoing operational validation

---

## Validation Layers

```
┌─────────────────────────────────────────────────────────────────┐
│                    SETUP VALIDATION FLOW                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  [PRE-SETUP]           [DURING]            [POST-SETUP]         │
│       │                   │                     │                │
│       ▼                   ▼                     ▼                │
│  ┌─────────┐        ┌─────────┐          ┌──────────┐           │
│  │PREFLIGHT│   →    │ PHASES  │    →     │READINESS │           │
│  │ (0A)    │        │ (0B-7)  │          │ REPORT   │           │
│  └─────────┘        └─────────┘          └──────────┘           │
│       │                                        │                 │
│       │            [ONGOING]                   │                 │
│       │                │                       │                 │
│       └───────────►┌───────┐◄──────────────────┘                │
│                    │HEALTH │                                     │
│                    │ CHECK │                                     │
│                    └───────┘                                     │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Layer 1: Preflight (Pre-Setup)

**When**: Before `/setup` runs
**Purpose**: Validate environment is correctly configured
**Command**: Embedded in Phase 0A

| Check Category | What's Validated | Failure Action |
|----------------|------------------|----------------|
| Workspace | Jarvis path exists, is git repo | Block setup |
| Baseline | AIfred separate from Jarvis | Block setup |
| Safety | Not in forbidden system paths | Block setup |
| Structure | Core directories exist | Warn, continue |
| Git | Clean tree, correct branch | Warn, continue |

**Reference**: `.claude/archive/setup-phases/00-preflight.md`

### Layer 2: Readiness (Post-Setup)

**When**: After `/setup` Phase 7 completes
**Purpose**: Confirm all components installed correctly
**Command**: `/setup-readiness`

| Check Category | What's Validated | Status Impact |
|----------------|------------------|---------------|
| Environment | Workspace, baseline separation | Critical |
| Structure | All required directories/files | High |
| Components | Hooks valid, guardrails present | High |
| Tools | Git, Docker, Node availability | Critical/Low |

**Reference**: `.claude/commands/setup-readiness.md`

### Layer 3: Health (Ongoing)

**When**: Session start, after tool installation, on-demand
**Purpose**: Detect regression and drift
**Command**: `/health-check` (includes setup status)

| Check Tier | When | Duration | What's Checked |
|------------|------|----------|----------------|
| Tier 1 (Quick) | Session start | < 2s | Critical items only |
| Tier 2 (Standard) | On-demand | 5-10s | Full setup + tools |
| Tier 3 (Deep) | Periodic | 30-60s | Smoke tests per tool |

**Reference**: `projects/project-aion/ideas/setup-regression-testing.md`

---

## Validation Severity System

Validation checks use the standard severity system:

| Level | Prefix | Meaning | Action |
|-------|--------|---------|--------|
| Critical | `[X]` | Blocks operation | Must fix |
| High | `[!]` | Important failure | Should fix |
| Medium | `[~]` | Missing feature | Consider fixing |
| Low | `[-]` | Optional item | Can ignore |

### Status Outcomes

| Status | Criteria | Proceed? |
|--------|----------|----------|
| **FULLY READY** | No failures at any level | Yes |
| **READY (warnings)** | No critical/high failures | Yes |
| **DEGRADED** | High failures present | Caution |
| **NOT READY** | Critical failures present | No |

---

## When to Run Each Validation

### Mandatory Validations

| Event | Validation | Layer |
|-------|------------|-------|
| Before `/setup` | Preflight | 1 |
| After `/setup` | Readiness | 2 |
| Session start | Quick check (Tier 1) | 3 |

### Recommended Validations

| Event | Validation | Layer |
|-------|------------|-------|
| After tool installation | Standard check (Tier 2) | 3 |
| Weekly (via Jeeves) | Deep check (Tier 3) | 3 |
| Before version bump | Full readiness | 2 |

---

## Integration Points

### Session Start Checklist

Add Tier 1 validation to `session-start-checklist.md`:

```markdown
### 5. Quick Validation (Recommended)

Quick setup check (< 2 seconds):
- If passes silently, continue
- If warns, consider running `/setup-readiness`
```

### Health Check Command

Extend `/health-check` to include setup status:

```markdown
## Health Check Output

### System Health
[existing checks]

### Setup Status
- Preflight: [PASS/FAIL from last run]
- Readiness: [status] (last run: [date])
- Quick Check: [PASS/WARN]
```

### End Session Workflow

Optionally add validation reminder:

```markdown
### Pre-Exit Validation

If significant changes were made this session:
- Consider running `/setup-readiness` before commit
```

---

## Troubleshooting Failures

### Common Preflight Failures

| Failure | Cause | Fix |
|---------|-------|-----|
| Jarvis workspace not found | Wrong directory | `cd /Users/aircannon/Claude/Jarvis` |
| In AIfred baseline | Started from wrong repo | Change working directory |
| In forbidden path | Started from system directory | Navigate to workspace |

### Common Readiness Failures

| Failure | Cause | Fix |
|---------|-------|-----|
| Guardrail hooks missing | PR-4a incomplete | Re-run hooks installation |
| workspace-allowlist.yaml missing | PR-4b incomplete | Create config file |
| Hooks have syntax errors | Code issue | Fix JavaScript syntax |

### Common Health Failures

| Failure | Cause | Fix |
|---------|-------|-----|
| MCP not responding | Server not enabled | Enable in Docker Desktop |
| Docker not running | Service stopped | Start Docker Desktop |
| Uncommitted changes | Work in progress | Commit or stash |

---

## Related Documentation

- **Preflight checks**: `.claude/archive/setup-phases/00-preflight.md`
- **Readiness command**: `.claude/commands/setup-readiness.md`
- **Health check**: `.claude/commands/health-report.md`
- **Regression testing brainstorm**: `projects/project-aion/ideas/setup-regression-testing.md`
- **Session checklist**: `.claude/context/patterns/session-start-checklist.md`

---

*Pattern: Setup Validation — Established PR-4c*
