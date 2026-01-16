# /self-improve Command

**Version**: 1.0.0
**Created**: 2026-01-16
**PR**: PR-12.10

---

## Purpose

Run Jarvis through self-improvement cycles without explicit user oversight. This command orchestrates all Tier 2 autonomic components (AC-05 through AC-08) in a structured sequence, allowing Jarvis to reflect, research, maintain, and evolve autonomously.

## Usage

```
/self-improve [--focus=<system>] [--skip=<system>] [--dry-run]
```

### Options

| Option | Description | Default |
|--------|-------------|---------|
| `--focus=<system>` | Run only specified system(s) | all |
| `--skip=<system>` | Skip specified system(s) | none |
| `--dry-run` | Plan only, no changes | false |
| `--approve-low` | Auto-approve low-risk proposals | true |
| `--time-limit=<minutes>` | Maximum runtime | 120 |

### Focus Options

| Focus | Component | Description |
|-------|-----------|-------------|
| `reflection` | AC-05 | Self-Reflection Cycles |
| `maintenance` | AC-08 | Maintenance Workflows |
| `research` | AC-07 | R&D Cycles |
| `evolution` | AC-06 | Self-Evolution Cycles |
| `all` | All | Complete self-improvement cycle |

### Examples

```bash
# Full self-improvement cycle (all systems)
/self-improve

# Focus on reflection only
/self-improve --focus=reflection

# Skip evolution (research + reflect + maintain only)
/self-improve --skip=evolution

# Multiple focuses
/self-improve --focus=reflection,maintenance

# Dry run to see what would happen
/self-improve --dry-run

# Set time limit
/self-improve --time-limit=60
```

---

## Execution Sequence

When invoked without focus options, `/self-improve` runs all four systems in this order:

```
┌─────────────────────────────────────────────────────────────────────┐
│                    /self-improve EXECUTION SEQUENCE                  │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  PHASE 1: SELF-REFLECTION (AC-05)                                   │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │  • Review session data sources                                 │  │
│  │  • Identify problems and patterns                              │  │
│  │  • Analyze corrections (user + self)                           │  │
│  │  • Generate reflection proposals                               │  │
│  │  • Output: Reflection report + proposals                       │  │
│  └───────────────────────────────────────────────────────────────┘  │
│                              │                                       │
│                              ▼                                       │
│  PHASE 2: MAINTENANCE (AC-08)                                       │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │  • Run health checks                                           │  │
│  │  • Run freshness audits                                        │  │
│  │  • Review organization (Jarvis + project)                      │  │
│  │  • Generate optimization proposals                             │  │
│  │  • Output: Maintenance report + proposals                      │  │
│  └───────────────────────────────────────────────────────────────┘  │
│                              │                                       │
│                              ▼                                       │
│  PHASE 3: R&D CYCLES (AC-07)                                        │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │  • Check research agenda for pending items                     │  │
│  │  • Review internal token efficiency                            │  │
│  │  • Discover new tools/patterns if agenda empty                 │  │
│  │  • Classify findings (ADOPT/ADAPT/DEFER/REJECT)                │  │
│  │  • Output: R&D report + proposals (require-approval)           │  │
│  └───────────────────────────────────────────────────────────────┘  │
│                              │                                       │
│                              ▼                                       │
│  PHASE 4: SELF-EVOLUTION (AC-06)                                    │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │  • Triage all proposals (from phases 1-3)                      │  │
│  │  • Implement LOW-risk proposals (auto-approve)                 │  │
│  │  • Queue MEDIUM/HIGH proposals for user approval               │  │
│  │  • Run validation on implemented changes                       │  │
│  │  • Output: Evolution report + pending approvals                │  │
│  └───────────────────────────────────────────────────────────────┘  │
│                              │                                       │
│                              ▼                                       │
│  PHASE 5: SUMMARY & APPROVAL REQUEST                                │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │  • Present consolidated report                                 │  │
│  │  • List proposals requiring user approval                      │  │
│  │  • Ask: Continue improving? Approve proposals?                 │  │
│  │  • Output: Final summary                                       │  │
│  └───────────────────────────────────────────────────────────────┘  │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Workflow Details

### Phase 1: Self-Reflection (AC-05)

**Duration**: ~10-20 minutes

**Actions**:
1. Scan data sources:
   - `corrections.md` (user corrections)
   - `self-corrections.md` (Jarvis corrections)
   - `selection-audit.jsonl` (tool selection patterns)
   - `context-estimate.json` (context usage)
   - Git history (recent changes)

2. Identify patterns:
   - Recurring mistakes
   - Successful approaches
   - Efficiency opportunities
   - Missing knowledge

3. Generate proposals:
   - Specific solutions with rationale
   - Files/patterns to modify
   - Risk assessment

**Output**: Reflection report + evolution proposals

### Phase 2: Maintenance (AC-08)

**Duration**: ~5-15 minutes

**Actions**:
1. Health checks:
   - Hook syntax validation
   - Settings schema validation
   - MCP connectivity test
   - Git status check

2. Freshness audits:
   - Stale documentation (>30 days)
   - Outdated dependencies
   - Broken internal links

3. Organization review:
   - Jarvis codebase structure
   - Active project structure
   - Reference integrity

**Output**: Health/freshness/organization reports + optimization proposals

### Phase 3: R&D Cycles (AC-07)

**Duration**: ~15-30 minutes

**Actions**:
1. Check research agenda:
   - Pending topics from `research-agenda.yaml`
   - User-suggested research items

2. Internal efficiency analysis:
   - File usage tracking
   - Redundant content detection
   - Context cost analysis

3. External discovery (if agenda empty):
   - Scan awesome-mcp lists
   - Check plugin registries
   - Review Anthropic updates

4. Classify findings:
   - ADOPT: High value, low risk
   - ADAPT: High value, needs modification
   - DEFER: Potential value, wait
   - REJECT: Low value or high risk

**Output**: R&D report + proposals (all marked require-approval)

### Phase 4: Self-Evolution (AC-06)

**Duration**: ~20-60 minutes

**Actions**:
1. Triage proposals:
   - Collect from phases 1-3
   - Assess impact and risk
   - Prioritize queue

2. Implement (low-risk only):
   - Create evolution branch
   - Apply changes
   - Run validation

3. Queue (medium/high-risk):
   - Add to approval queue
   - Document rationale
   - Prepare for user review

**Output**: Evolution report + list of implemented/queued changes

### Phase 5: Summary & Approval

**Duration**: ~2-5 minutes

**Actions**:
1. Generate consolidated report
2. List pending approvals
3. Present to user
4. Await response

**Output**: Final summary displayed to user

---

## Consolidated Report Format

```markdown
# Self-Improvement Report — {date}

## Executive Summary
- **Duration**: {X} minutes
- **Phases completed**: {N}/4
- **Proposals generated**: {N}
- **Changes implemented**: {N}
- **Pending approvals**: {N}

## Phase Results

### Self-Reflection (AC-05)
- Patterns identified: {N}
- Corrections reviewed: {N}
- Proposals generated: {N}

### Maintenance (AC-08)
- Health issues: {N}
- Stale files: {N}
- Organization issues: {N}

### R&D Cycles (AC-07)
- Topics researched: {N}
- Discoveries: {N}
- Recommendations: {N} ADOPT, {N} ADAPT, {N} DEFER, {N} REJECT

### Self-Evolution (AC-06)
- Proposals triaged: {N}
- Low-risk implemented: {N}
- Medium/high-risk queued: {N}

## Pending Approvals

| ID | Source | Title | Risk | Action |
|----|--------|-------|------|--------|
| {id} | {AC-0X} | {title} | {low/med/high} | {approve/reject} |

## Next Steps

{recommendations for further improvement}

---
*Generated by /self-improve*
```

---

## Loop Behavior

### Wiggum Loop Integration

`/self-improve` runs under the Wiggum Loop by default:

```
Wiggum Loop wraps /self-improve:
  - TodoWrite tracks each phase
  - Progress visible throughout
  - Drift detection active
  - Context checkpoint if needed
```

### Context Management (JICM)

The command respects JICM thresholds:

```
JICM integration:
  - Monitor context usage per phase
  - Checkpoint between phases if >70%
  - Pause at CRITICAL threshold
  - Resume after /clear
```

### Extended Operation

`/self-improve` can run for extended periods:

```
Extended operation:
  - Default time limit: 120 minutes
  - Checkpoint every 60 minutes
  - User can interrupt with Ctrl+C
  - Progress persisted for resume
```

---

## State Management

### State File

**Location**: `.claude/state/self-improve-state.json`

```json
{
  "started": "2026-01-16T18:00:00.000Z",
  "status": "in_progress",
  "current_phase": 3,
  "phases_completed": [1, 2],
  "options": {
    "focus": "all",
    "skip": [],
    "dry_run": false,
    "approve_low": true,
    "time_limit": 120
  },
  "results": {
    "reflection": { "proposals": 3, "status": "complete" },
    "maintenance": { "issues": 2, "status": "complete" },
    "research": { "discoveries": 1, "status": "in_progress" },
    "evolution": { "implemented": 0, "status": "pending" }
  },
  "proposals": [
    { "id": "refl-001", "source": "AC-05", "risk": "low", "status": "pending" }
  ]
}
```

### Resume Behavior

If interrupted, `/self-improve` can resume:

```bash
# Auto-resumes from last checkpoint
/self-improve

# Force restart (discard progress)
/self-improve --restart
```

---

## Configuration

### autonomy-config.yaml Settings

```yaml
self_improve:
  # Default time limit in minutes
  default_time_limit: 120

  # Auto-approve low-risk proposals
  auto_approve_low_risk: true

  # Run under Wiggum Loop
  wiggum_loop: true

  # JICM checkpoint threshold
  checkpoint_threshold: 70

  # Generate reports
  generate_reports: true

  # Report location
  report_path: .claude/reports/self-improve/

  # Maximum proposals per run
  max_proposals: 20

  # R&D discovery limit
  rd_discovery_limit: 5
```

---

## Error Handling

### Phase Failures

If a phase fails, the command continues with remaining phases:

```
Phase failure handling:
  - Log error with details
  - Mark phase as "failed" in state
  - Continue to next phase
  - Report failure in summary
```

### Graceful Degradation

| Failure | Response |
|---------|----------|
| Memory MCP down | Skip persistence, continue |
| Git unavailable | Skip evolution commits |
| Web access down | Skip external R&D |
| Timeout | Checkpoint, allow resume |

---

## Safety Mechanisms

### Proposal Gates

All proposals go through risk-based gates:

| Risk Level | Gate |
|------------|------|
| Low | Auto-approve (unless --dry-run) |
| Medium | Queue for user approval |
| High | Queue for user approval |
| Critical | Block, require explicit approval |

### R&D Require-Approval

ALL R&D-sourced proposals require user approval:

```
R&D proposals:
  - Always flagged "require-approval"
  - Never auto-implemented
  - User must explicitly approve
```

### Change Limits

Per-run limits prevent runaway changes:

```
Limits:
  - Max 20 proposals per run
  - Max 5 low-risk auto-implementations
  - Max 5 R&D discoveries
  - Time limit (default 120 min)
```

---

## Integration Points

### With Downtime Detector

When idle for ~30 minutes, downtime detector can auto-trigger:

```
Downtime trigger:
  - Detect idle session
  - Check autonomy-config.yaml
  - If enabled: run /self-improve --focus=maintenance,reflection
  - Present summary when user returns
```

### With Session Completion (AC-09)

Pre-completion offer includes self-improvement:

```
Pre-completion:
  - User triggers /end-session
  - Jarvis offers: "Run self-improvement before ending?"
  - If yes: run /self-improve (user selects focus)
  - Then proceed to completion
```

---

## Output Examples

### Progress Display

```
Running /self-improve (all systems)...

[1/4] Self-Reflection (AC-05)
      Scanning corrections... 5 entries
      Analyzing patterns... 2 found
      Generating proposals... 3 created
      ✓ Complete (2 minutes)

[2/4] Maintenance (AC-08)
      Running health checks... 0 issues
      Running freshness audit... 8 stale files
      Reviewing organization... 1 misplaced file
      ✓ Complete (3 minutes)

[3/4] R&D Cycles (AC-07)
      Checking research agenda... 2 pending
      Analyzing token efficiency... done
      ✓ Complete (5 minutes)

[4/4] Self-Evolution (AC-06)
      Triaging proposals... 6 total
      Implementing low-risk... 2 changes
      Queuing for approval... 4 proposals
      ✓ Complete (8 minutes)

Self-improvement complete (18 minutes total).
```

### Summary Display

```
# Self-Improvement Summary

## What I Did
- Reviewed 5 corrections, found 2 patterns
- Identified 8 stale documentation files
- Implemented 2 low-risk improvements
- Queued 4 proposals for your approval

## Pending Approvals

1. [MEDIUM] Add file usage tracking hook
   Source: R&D Cycles
   Risk: Medium (new hook)
   → Approve? [y/n]

2. [MEDIUM] Consolidate duplicate patterns
   Source: Maintenance
   Risk: Medium (file changes)
   → Approve? [y/n]

Would you like me to continue improving, or shall we review these proposals?
```

---

## Related Commands

| Command | Relationship |
|---------|--------------|
| `/reflect` | Runs AC-05 only |
| `/research` | Runs AC-07 only |
| `/maintain` | Runs AC-08 only |
| `/evolve` | Runs AC-06 only |
| `/end-session` | Offers self-improve before exit |

---

**/self-improve Command — Jarvis Phase 6 PR-12.10**
