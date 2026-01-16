# Self-Evolution Pattern

**Version**: 1.0.0
**Created**: 2026-01-16
**Component**: AC-06 Self-Evolution
**PR**: PR-12.6

---

## Overview

Self-Evolution is the pattern by which Jarvis safely implements improvements to its own codebase. It transforms proposals from reflection, R&D, and maintenance into validated, reversible changes. The key principle is **controlled, validated change**—every modification goes through a seven-step pipeline with risk-based gates.

### Core Principle

**Change is managed, not chaotic.** Every evolution:
1. Is triaged and prioritized
2. Has a design phase
3. Passes through risk-based approval gates
4. Is implemented in an isolated branch
5. Is validated before merge
6. Can be rolled back if needed

---

## 1. Evolution Queue

### Queue Format

```yaml
# .claude/state/queues/evolution-queue.yaml
version: 1.0.0
last_updated: 2026-01-16T18:00:00.000Z

# Configuration
config:
  max_per_session: 5
  auto_approve_low_risk: true
  notify_on_completion: true

# Active proposals
proposals:
  - id: EVO-2026-01-001
    created: 2026-01-16T10:00:00.000Z
    source: reflection      # reflection | r&d | maintenance | user
    status: pending         # pending | approved | in_progress | completed | failed | rejected

    # Proposal details
    title: Add hook troubleshooting guide
    description: |
      Create comprehensive troubleshooting guide for JS hooks
      covering common issues like the stdin/stdout protocol.

    # Classification
    type: documentation     # documentation | pattern | hook | workflow | core
    risk: low               # low | medium | high
    impact: low             # low | medium | high

    # Implementation
    files:
      - path: .claude/context/troubleshooting/js-hooks.md
        action: create

    # Metadata
    rationale: |
      Hook format issues caused significant debugging time.
      Documentation would prevent recurrence.
    require_approval: false
    related_problems:
      - P-2026-01-001

    # Tracking
    attempts: 0
    last_attempt: null
    failure_reason: null

  - id: EVO-2026-01-002
    created: 2026-01-16T12:00:00.000Z
    source: r&d
    status: pending

    title: Integrate new MCP server
    description: Add xyz-mcp for enhanced functionality

    type: core
    risk: medium
    impact: high

    files:
      - path: .claude/config/mcps.yaml
        action: modify
      - path: .claude/scripts/setup-mcps.sh
        action: modify

    rationale: R&D discovered xyz-mcp provides needed capability
    require_approval: true  # R&D-sourced always requires approval
    related_problems: []

    attempts: 0
    last_attempt: null
    failure_reason: null

# Completed history (recent)
history:
  - id: EVO-2026-01-000
    completed: 2026-01-15T16:00:00.000Z
    status: completed
    title: Fix hook wrapper pattern
    result: success
    version_bump: 1.9.5
```

### Queue Operations

```javascript
// Add proposal to queue
function addProposal(proposal) {
  const queue = loadQueue();
  proposal.id = generateId();
  proposal.created = new Date().toISOString();
  proposal.status = 'pending';
  proposal.attempts = 0;
  queue.proposals.push(proposal);
  saveQueue(queue);
  return proposal.id;
}

// Get next proposal to process
function getNextProposal(queue) {
  return queue.proposals
    .filter(p => p.status === 'pending' || p.status === 'approved')
    .sort((a, b) => {
      // Priority: user > reflection > maintenance > r&d
      const sourcePriority = { user: 0, reflection: 1, maintenance: 2, r&d: 3 };
      return sourcePriority[a.source] - sourcePriority[b.source];
    })[0];
}

// Update proposal status
function updateProposal(id, updates) {
  const queue = loadQueue();
  const proposal = queue.proposals.find(p => p.id === id);
  Object.assign(proposal, updates);
  saveQueue(queue);
}
```

---

## 2. Seven-Step Pipeline

### Step 1: Proposal Triage

```
┌─────────────────────────────────────────────────────────────────────┐
│                    STEP 1: PROPOSAL TRIAGE                           │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  INPUT: New proposal from queue                                      │
│                                                                      │
│  EVALUATION CRITERIA:                                                │
│                                                                      │
│  1. IMPACT ASSESSMENT                                                │
│     └── Low: Single file, documentation only                        │
│     └── Medium: Multiple files, functional change                   │
│     └── High: Core system, workflow change                          │
│                                                                      │
│  2. RISK ASSESSMENT                                                  │
│     └── Low: No behavior change, additive only                      │
│     └── Medium: Behavior change, well-understood                    │
│     └── High: Complex change, potential for regression              │
│                                                                      │
│  3. ALIGNMENT CHECK                                                  │
│     └── Does this align with roadmap priorities?                    │
│     └── Does this conflict with pending work?                       │
│     └── Is the timing appropriate?                                  │
│                                                                      │
│  4. PRIORITIZATION                                                   │
│     └── User requests: highest                                      │
│     └── Regression fixes: high                                      │
│     └── Reflection proposals: medium                                │
│     └── R&D discoveries: lower (require approval anyway)            │
│                                                                      │
│  OUTPUT: Triaged proposal with risk/impact scores                   │
│                                                                      │
│  DECISION:                                                           │
│     └── Ready → proceed to Step 2                                   │
│     └── Defer → move to end of queue                                │
│     └── Reject → remove from queue with reason                      │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### Step 2: Design Phase

```
┌─────────────────────────────────────────────────────────────────────┐
│                    STEP 2: DESIGN PHASE                              │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  INPUT: Triaged proposal                                             │
│                                                                      │
│  DESIGN ACTIVITIES:                                                  │
│                                                                      │
│  1. IMPLEMENTATION PLAN                                              │
│     └── Detailed steps to implement change                          │
│     └── Order of file modifications                                 │
│     └── Dependencies between changes                                │
│                                                                      │
│  2. FILE IDENTIFICATION                                              │
│     └── List all files to create/modify/delete                      │
│     └── Identify backup requirements                                │
│     └── Note any file moves or renames                              │
│                                                                      │
│  3. VALIDATION CRITERIA                                              │
│     └── What tests should pass?                                     │
│     └── What benchmarks to run?                                     │
│     └── What manual checks needed?                                  │
│                                                                      │
│  4. COMPLEXITY ESTIMATE                                              │
│     └── Expected implementation time                                │
│     └── Context budget impact                                       │
│     └── Risk of partial completion                                  │
│                                                                      │
│  OUTPUT: Implementation design document                              │
│                                                                      │
│  DESIGN DOCUMENT FORMAT:                                             │
│  ```                                                                 │
│  ## Evolution Design: EVO-2026-01-001                                │
│                                                                      │
│  ### Implementation Steps                                            │
│  1. Create file X with content Y                                    │
│  2. Update file Z to reference X                                    │
│                                                                      │
│  ### Files Affected                                                  │
│  - CREATE: .claude/context/troubleshooting/js-hooks.md              │
│  - MODIFY: .claude/context/_index.md (add reference)                │
│                                                                      │
│  ### Validation                                                      │
│  - File exists and is valid markdown                                │
│  - Index reference resolves                                         │
│  - /tooling-health passes                                           │
│                                                                      │
│  ### Rollback                                                        │
│  - Delete created file                                              │
│  - Revert index change                                              │
│  ```                                                                 │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### Step 3: Approval Gate

```
┌─────────────────────────────────────────────────────────────────────┐
│                    STEP 3: APPROVAL GATE                             │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  INPUT: Design document with risk classification                     │
│                                                                      │
│  APPROVAL LOGIC:                                                     │
│                                                                      │
│  ┌─────────────────────────────────────────────────────────────────┐│
│  │  LOW RISK (documentation, patterns)                              ││
│  │                                                                  ││
│  │  → Auto-approve                                                  ││
│  │  → Notify user: "Implementing: [title]"                          ││
│  │  → Proceed immediately                                           ││
│  │                                                                  ││
│  │  Example: "Implementing: Add hook troubleshooting guide"         ││
│  └─────────────────────────────────────────────────────────────────┘│
│                                                                      │
│  ┌─────────────────────────────────────────────────────────────────┐│
│  │  MEDIUM RISK (hooks, workflows)                                  ││
│  │                                                                  ││
│  │  → Notify user with details                                      ││
│  │  → "Proceeding with: [title] in 10s unless you object"           ││
│  │  → Wait 10 seconds for potential veto                            ││
│  │  → Proceed if no objection                                       ││
│  │                                                                  ││
│  │  Example: "Proceeding with: Update session-start hook            ││
│  │           Files: .claude/hooks/session-start.sh                  ││
│  │           Object within 10s to cancel."                          ││
│  └─────────────────────────────────────────────────────────────────┘│
│                                                                      │
│  ┌─────────────────────────────────────────────────────────────────┐│
│  │  HIGH RISK (core changes, multi-file)                            ││
│  │                                                                  ││
│  │  → Request explicit approval                                     ││
│  │  → Present full details                                          ││
│  │  → Wait for "yes" or "approve"                                   ││
│  │  → Proceed only with explicit approval                           ││
│  │                                                                  ││
│  │  Example: "Approve evolution: Refactor context management?       ││
│  │           Risk: High                                             ││
│  │           Files: 5 files affected                                ││
│  │           [Details...]                                           ││
│  │           Reply 'yes' to approve, 'no' to reject"                ││
│  └─────────────────────────────────────────────────────────────────┘│
│                                                                      │
│  ┌─────────────────────────────────────────────────────────────────┐│
│  │  R&D-SOURCED (any risk level)                                    ││
│  │                                                                  ││
│  │  → Always require explicit approval                              ││
│  │  → Flag as require-approval in queue                             ││
│  │  → Present R&D findings for context                              ││
│  │                                                                  ││
│  │  Example: "R&D discovered: xyz-mcp server                        ││
│  │           Recommendation: ADOPT                                  ││
│  │           Approve integration? [y/n]"                            ││
│  └─────────────────────────────────────────────────────────────────┘│
│                                                                      │
│  OUTPUT: Approval status (approved | rejected | deferred)           │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### Step 4: Implementation

```
┌─────────────────────────────────────────────────────────────────────┐
│                    STEP 4: IMPLEMENTATION                            │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  INPUT: Approved design document                                     │
│                                                                      │
│  IMPLEMENTATION WORKFLOW:                                            │
│                                                                      │
│  1. CREATE BRANCH                                                    │
│     └── Branch name: evolution/EVO-2026-01-001                      │
│     └── From: Current working branch (usually Project_Aion)         │
│     └── Command: git checkout -b evolution/EVO-2026-01-001          │
│                                                                      │
│  2. IMPLEMENT CHANGES                                                │
│     └── Follow design document steps                                │
│     └── Create/modify/delete files as specified                     │
│     └── Track all changes for potential rollback                    │
│                                                                      │
│  3. VERIFY SYNTAX                                                    │
│     └── YAML files: valid YAML                                      │
│     └── JS files: valid JavaScript                                  │
│     └── Markdown: valid structure                                   │
│                                                                      │
│  4. COMMIT CHANGES                                                   │
│     └── Commit message format:                                      │
│         "Evolution: [title]                                         │
│                                                                      │
│          [description]                                              │
│                                                                      │
│          Proposal: EVO-2026-01-001                                  │
│          Risk: [low|medium|high]                                    │
│          Source: [reflection|r&d|maintenance|user]                  │
│                                                                      │
│          Co-Authored-By: Claude <noreply@anthropic.com>"            │
│                                                                      │
│  OUTPUT: Changes committed on evolution branch                       │
│                                                                      │
│  EXAMPLE:                                                            │
│  ```bash                                                             │
│  git checkout -b evolution/EVO-2026-01-001                           │
│  # ... make changes ...                                              │
│  git add .                                                           │
│  git commit -m "Evolution: Add hook troubleshooting guide           │
│                                                                      │
│  Create comprehensive guide for JS hook issues.                     │
│                                                                      │
│  Proposal: EVO-2026-01-001                                          │
│  Risk: low                                                          │
│  Source: reflection                                                 │
│                                                                      │
│  Co-Authored-By: Claude <noreply@anthropic.com>"                    │
│  ```                                                                 │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### Step 5: Validation

```
┌─────────────────────────────────────────────────────────────────────┐
│                    STEP 5: VALIDATION                                │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  INPUT: Committed changes on evolution branch                        │
│                                                                      │
│  VALIDATION CHECKS:                                                  │
│                                                                      │
│  1. BASIC VALIDATION                                                 │
│     └── All files exist as expected                                 │
│     └── No syntax errors                                            │
│     └── References resolve                                          │
│                                                                      │
│  2. TOOLING HEALTH                                                   │
│     └── Run /tooling-health                                         │
│     └── All MCPs responding                                         │
│     └── Hooks syntax valid                                          │
│                                                                      │
│  3. BENCHMARK COMPARISON (if PR-13 available)                        │
│     └── Run benchmark suite                                         │
│     └── Compare against baseline                                    │
│     └── Check for regressions:                                      │
│         - Performance degradation > 10%                             │
│         - New errors introduced                                     │
│         - Functionality broken                                      │
│                                                                      │
│  4. CUSTOM VALIDATION (per design document)                          │
│     └── Execute any proposal-specific checks                        │
│     └── Verify stated criteria met                                  │
│                                                                      │
│  VALIDATION RESULT:                                                  │
│                                                                      │
│  PASS:                                                               │
│    - All checks successful                                          │
│    - No regressions detected                                        │
│    - Proceed to Step 6 (Release)                                    │
│                                                                      │
│  FAIL:                                                               │
│    - One or more checks failed                                      │
│    - Regression detected                                            │
│    - Proceed to Step 7 (Rollback)                                   │
│                                                                      │
│  OUTPUT: Validation report with pass/fail status                    │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### Step 6: Release (on PASS)

```
┌─────────────────────────────────────────────────────────────────────┐
│                    STEP 6: RELEASE                                   │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  INPUT: Validated changes on evolution branch                        │
│                                                                      │
│  RELEASE WORKFLOW:                                                   │
│                                                                      │
│  1. MERGE TO MAIN BRANCH                                             │
│     └── git checkout Project_Aion                                   │
│     └── git merge --no-ff evolution/EVO-2026-01-001                 │
│     └── Merge commit: "Merge evolution/EVO-2026-01-001"             │
│                                                                      │
│  2. VERSION BUMP (if appropriate)                                    │
│     └── Patch: documentation, minor fixes                           │
│     └── Minor: new features, significant changes                    │
│     └── Update VERSION file                                         │
│                                                                      │
│  3. CHANGELOG UPDATE                                                 │
│     └── Add entry under "Unreleased" or new version                 │
│     └── Format: "- Evolution: [title] (EVO-2026-01-001)"            │
│                                                                      │
│  4. COMMIT RELEASE                                                   │
│     └── git add VERSION CHANGELOG.md                                │
│     └── git commit -m "Release: v1.9.6 (EVO-2026-01-001)"           │
│                                                                      │
│  5. PUSH TO ORIGIN                                                   │
│     └── git push origin Project_Aion                                │
│                                                                      │
│  6. CLEANUP                                                          │
│     └── git branch -d evolution/EVO-2026-01-001                     │
│     └── Update queue: mark proposal as "completed"                  │
│     └── Move to history section                                     │
│                                                                      │
│  7. NOTIFY                                                           │
│     └── "Evolution complete: [title]"                               │
│     └── "Version: v1.9.6"                                           │
│                                                                      │
│  OUTPUT: Merged changes, version bump, CHANGELOG update             │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### Step 7: Rollback (on FAIL)

```
┌─────────────────────────────────────────────────────────────────────┐
│                    STEP 7: ROLLBACK                                  │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  INPUT: Failed validation result                                     │
│                                                                      │
│  ROLLBACK WORKFLOW:                                                  │
│                                                                      │
│  1. REVERT CHANGES                                                   │
│     └── If on evolution branch: git checkout Project_Aion           │
│     └── If already merged: git revert <merge-commit>                │
│                                                                      │
│  2. DELETE BRANCH                                                    │
│     └── git branch -D evolution/EVO-2026-01-001                     │
│                                                                      │
│  3. LOG FAILURE                                                      │
│     └── Record in evolution.jsonl:                                  │
│         {                                                           │
│           "id": "EVO-2026-01-001",                                  │
│           "timestamp": "...",                                       │
│           "action": "rollback",                                     │
│           "reason": "Validation failed: [details]"                  │
│         }                                                           │
│                                                                      │
│  4. UPDATE PROPOSAL                                                  │
│     └── Status: "failed"                                            │
│     └── failure_reason: "[detailed reason]"                         │
│     └── attempts: increment                                         │
│                                                                      │
│  5. ADD TO REFLECTION DATA                                           │
│     └── Create problem entry for AC-05                              │
│     └── "Evolution EVO-2026-01-001 failed: [reason]"                │
│     └── Will be analyzed in next reflection cycle                   │
│                                                                      │
│  6. NOTIFY                                                           │
│     └── "Evolution failed: [title]"                                 │
│     └── "Reason: [failure reason]"                                  │
│     └── "Changes rolled back. Added to reflection queue."           │
│                                                                      │
│  RETRY POLICY:                                                       │
│     └── Max 3 attempts per proposal                                 │
│     └── After 3 failures: mark as "rejected"                        │
│     └── Rejected proposals require user review                      │
│                                                                      │
│  OUTPUT: Clean state, failure logged, proposal updated              │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 3. Downtime Detection

### Downtime Detector

```javascript
// .claude/hooks/downtime-detector.js
// Checks for user idle time and triggers self-improvement

const IDLE_THRESHOLD_MS = 30 * 60 * 1000; // 30 minutes

async function checkDowntime(input) {
  // Get last user message timestamp from conversation
  const lastUserMessage = getLastUserMessageTime();
  const now = Date.now();
  const idleTime = now - lastUserMessage;

  if (idleTime > IDLE_THRESHOLD_MS) {
    return {
      continue: true,
      downtime_detected: true,
      idle_minutes: Math.floor(idleTime / 60000),
      suggestion: "trigger_self_improvement"
    };
  }

  return { continue: true, downtime_detected: false };
}
```

### Downtime Triggers

```
┌─────────────────────────────────────────────────────────────────────┐
│                    DOWNTIME TRIGGER FLOW                             │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  User idle for ~30 minutes                                          │
│           │                                                          │
│           ▼                                                          │
│  Downtime detector fires                                            │
│           │                                                          │
│           ▼                                                          │
│  Check evolution queue                                              │
│           │                                                          │
│      ┌────┴────┐                                                    │
│      │         │                                                    │
│ Low-risk      Other                                                 │
│ proposals?    proposals                                             │
│      │         │                                                    │
│      ▼         ▼                                                    │
│ Auto-execute   Defer                                                │
│ low-risk      (require user)                                        │
│ proposals                                                           │
│      │                                                              │
│      ▼                                                              │
│ Notify on completion:                                               │
│ "While idle, implemented:                                           │
│  - EVO-001: Add troubleshooting guide                               │
│  - EVO-003: Update index format"                                    │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 4. /evolve Command

### Command Definition

```markdown
# /evolve Command

Trigger self-evolution to implement improvement proposals.

## Usage

```
/evolve                     # Process next proposal in queue
/evolve --all               # Process all auto-approvable proposals
/evolve --id=EVO-2026-01-001  # Process specific proposal
/evolve --status            # Show queue status
/evolve --approve=EVO-001   # Approve specific proposal
```

## Options

| Option | Description |
|--------|-------------|
| `--all` | Process all low-risk, auto-approvable proposals |
| `--id=ID` | Process specific proposal by ID |
| `--status` | Show evolution queue status |
| `--approve=ID` | Approve a pending high-risk proposal |
| `--reject=ID` | Reject a proposal with reason |

## Output

- Evolution report for each processed proposal
- Updated VERSION and CHANGELOG if released
- Notification of completion or failure

## When to Use

- When you have time for Jarvis to improve itself
- When reflection or R&D has generated proposals
- When explicitly requested improvement
```

---

## 5. Safety Mechanisms

### Rate Limiting

```yaml
# Rate limit configuration
rate_limits:
  per_session: 5           # Max evolutions per session
  per_day: 10              # Max evolutions per day
  high_risk_per_day: 2     # Max high-risk per day
  cooldown_minutes: 10     # Min time between evolutions
```

### AIfred Baseline Protection

```javascript
// Verify no changes to AIfred baseline
function verifyNoBaselineChanges(changedFiles) {
  const baselinePaths = [
    'alfred/',
    'AIfred/',
    '.alfred/'
  ];

  const violations = changedFiles.filter(file =>
    baselinePaths.some(base => file.startsWith(base))
  );

  if (violations.length > 0) {
    throw new Error(`BLOCKED: Cannot modify AIfred baseline: ${violations}`);
  }
}
```

### Rollback Guarantee

```javascript
// Every evolution must have a rollback path
function ensureRollbackCapability(proposal) {
  const rollbackPlan = proposal.rollback || [];

  // Auto-generate rollback for common operations
  for (const file of proposal.files) {
    switch (file.action) {
      case 'create':
        rollbackPlan.push({ action: 'delete', path: file.path });
        break;
      case 'modify':
        rollbackPlan.push({ action: 'git_revert', path: file.path });
        break;
      case 'delete':
        rollbackPlan.push({ action: 'git_restore', path: file.path });
        break;
    }
  }

  proposal.rollback = rollbackPlan;
  return proposal;
}
```

---

## 6. Evolution Report Format

### Report Template

```markdown
# Evolution Report: EVO-2026-01-001

**Date**: 2026-01-16
**Title**: Add hook troubleshooting guide
**Status**: COMPLETED

---

## Proposal

**Source**: Reflection (P-2026-01-001)
**Risk**: Low
**Impact**: Low

### Description
Create comprehensive troubleshooting guide for JS hooks covering
common issues like the stdin/stdout protocol requirement.

---

## Implementation

### Files Changed
| File | Action | Lines |
|------|--------|-------|
| `.claude/context/troubleshooting/js-hooks.md` | Create | 150 |
| `.claude/context/_index.md` | Modify | 2 |

### Branch
- Created: `evolution/EVO-2026-01-001`
- Merged: 2026-01-16T14:30:00Z
- Deleted: Yes

---

## Validation

| Check | Result |
|-------|--------|
| File exists | PASS |
| Valid markdown | PASS |
| Index reference | PASS |
| /tooling-health | PASS |

---

## Release

- **Version**: 1.9.5 → 1.9.6
- **CHANGELOG**: Entry added
- **Pushed**: Yes

---

## Metrics

| Metric | Value |
|--------|-------|
| Duration | 5 minutes |
| Tokens | 3,500 |
| Attempts | 1 |

---

*Generated by AC-06 Self-Evolution*
```

---

## 7. Configuration

### autonomy-config.yaml Settings

```yaml
components:
  AC-06-evolution:
    enabled: true
    settings:
      # Approval settings
      auto_approve_low_risk: true
      medium_risk_veto_window: 10  # seconds
      require_approval_for_r&d: true

      # Rate limits
      max_per_session: 5
      max_per_day: 10
      max_high_risk_per_day: 2
      cooldown_minutes: 10

      # Validation
      run_tooling_health: true
      run_benchmarks: true  # If PR-13 available
      validation_timeout: 300  # seconds

      # Git settings
      branch_prefix: "evolution/"
      auto_push: true
      auto_version_bump: true

      # Downtime
      idle_threshold_minutes: 30
      downtime_auto_evolve: true
      downtime_low_risk_only: true
```

---

## 8. Examples

### Low-Risk Auto-Approve Flow

```
Queue has proposal: EVO-2026-01-001 (documentation, low risk)

Jarvis: "Implementing: Add hook troubleshooting guide"

[Step 1-2: Triage and Design - automatic]
[Step 3: Auto-approved (low risk)]
[Step 4: Create branch, implement, commit]
[Step 5: Validation passes]
[Step 6: Merge, version bump 1.9.5 → 1.9.6, push]

Jarvis: "Evolution complete: Add hook troubleshooting guide
        Version: v1.9.6
        Files: .claude/context/troubleshooting/js-hooks.md (created)"
```

### High-Risk Approval Flow

```
Queue has proposal: EVO-2026-01-005 (core change, high risk)

Jarvis: "Approve evolution: Refactor context management?

        Risk: High
        Impact: High
        Files affected: 5

        Changes:
        - Modify context-accumulator.js
        - Modify JICM pattern
        - Update 3 component specs

        Reply 'yes' to approve, 'no' to reject."

User: "yes"

Jarvis: "Approved. Implementing refactor..."

[Full pipeline executes]

Jarvis: "Evolution complete: Refactor context management
        Version: v1.10.0
        All validations passed."
```

### Failed Validation with Rollback

```
[Step 4: Implementation complete]
[Step 5: Validation]

Jarvis: "Running validation..."

Validation result: FAIL
- /tooling-health: FAIL (hook syntax error)

Jarvis: "Validation failed. Rolling back...

        Reason: Hook syntax error in modified file
        Changes reverted.
        Branch deleted.

        Added to reflection queue for analysis."

[Step 7: Rollback complete]
[Proposal marked as failed, added to reflection data]
```

---

*Self-Evolution Pattern — Jarvis Phase 6 PR-12.6*
