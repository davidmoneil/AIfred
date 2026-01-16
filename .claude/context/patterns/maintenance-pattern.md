# Maintenance Workflows Pattern

**Pattern ID**: maintenance-workflows
**Version**: 1.0.0
**Status**: implementing
**Created**: 2026-01-16
**Component**: AC-08

---

## Overview

The Maintenance Workflows pattern defines how Jarvis performs automated maintenance tasks across both the Jarvis codebase and active project spaces. This pattern ensures long-term codebase hygiene through cleanup, freshness audits, health checks, organization review, and optimization proposals.

### Core Principles

1. **Dual Scope**: Unique among Tier 2 components in maintaining both Jarvis AND active projects
2. **Non-Destructive**: Proposes changes; never executes destructive actions without approval
3. **Scheduled + On-Demand**: Runs at session boundaries, during idle time, or by user request
4. **Auditable**: All actions logged with timestamps and outcomes
5. **Progressive**: Tasks range from fully automatic (cleanup) to proposal-only (optimization)

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                   MAINTENANCE WORKFLOWS ARCHITECTURE                 │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  TRIGGERS                                                            │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │  /maintain          → Full maintenance cycle                 │    │
│  │  /self-improve      → As part of self-improvement           │    │
│  │  Session start      → Health checks only                    │    │
│  │  Session end        → Cleanup only                          │    │
│  │  Downtime (~30min)  → Selected tasks                        │    │
│  │  Weekly schedule    → Freshness audit                       │    │
│  └─────────────────────────────────────────────────────────────┘    │
│                                                                      │
│  TASK ROUTER                                                         │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │                                                              │    │
│  │  Trigger Type    Tasks Executed                              │    │
│  │  ─────────────   ───────────────────────────────────────    │    │
│  │  Manual full     All tasks (cleanup, freshness, health,     │    │
│  │                  organization, optimization)                │    │
│  │  Session start   Health checks only                         │    │
│  │  Session end     Cleanup only                               │    │
│  │  Downtime        Based on last-run times                    │    │
│  │  Weekly          Freshness audit                            │    │
│  │  Monthly         Optimization analysis                      │    │
│  │                                                              │    │
│  └─────────────────────────────────────────────────────────────┘    │
│                                                                      │
│  TASK EXECUTION                                                      │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐  │
│  │ Cleanup │  │Freshness│  │ Health  │  │  Org    │  │  Optim  │  │
│  │         │  │  Audit  │  │ Checks  │  │ Review  │  │ Analysis│  │
│  └────┬────┘  └────┬────┘  └────┬────┘  └────┬────┘  └────┬────┘  │
│       │            │            │            │            │        │
│       ▼            ▼            ▼            ▼            ▼        │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐  │
│  │ Actions │  │ Report  │  │ Report  │  │ Report  │  │Proposals│  │
│  │(auto)   │  │ → R&D   │  │(alert)  │  │ + Props │  │ → Evol  │  │
│  └─────────┘  └─────────┘  └─────────┘  └─────────┘  └─────────┘  │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Maintenance Tasks

### Task 1: Cleanup

**Purpose**: Remove stale logs, temporary files, and perform git housekeeping.

**Automation Level**: Fully automatic

**Frequency**: Daily (logs), Session end (temps)

```
┌─────────────────────────────────────────────────────────────────────┐
│                        CLEANUP TASKS                                 │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  LOG ROTATION                                                        │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │  Location: .claude/logs/                                       │  │
│  │                                                                │  │
│  │  Policy:                                                       │  │
│  │  • Logs < 7 days: Keep as-is                                  │  │
│  │  • Logs 7-30 days: Archive (compress)                         │  │
│  │  • Logs > 30 days: Delete archived                            │  │
│  │                                                                │  │
│  │  Implementation:                                               │  │
│  │  1. Scan .claude/logs/ for .log files                         │  │
│  │  2. Check modification time                                   │  │
│  │  3. Archive or delete based on age                            │  │
│  │  4. Log actions taken                                         │  │
│  └───────────────────────────────────────────────────────────────┘  │
│                                                                      │
│  TEMP FILE CLEANUP                                                   │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │  Locations:                                                    │  │
│  │  • .claude/context/.* (hidden transients)                     │  │
│  │  • .claude/state/temp/                                        │  │
│  │  • .claude/cache/ (if exists)                                 │  │
│  │                                                                │  │
│  │  Policy:                                                       │  │
│  │  • Remove all files matching patterns                         │  │
│  │  • Preserve checkpoint files (different directory)            │  │
│  │  • Never touch user files                                     │  │
│  └───────────────────────────────────────────────────────────────┘  │
│                                                                      │
│  ORPHAN DETECTION (Report Only)                                      │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │  Find files that are:                                          │  │
│  │  • Not referenced by any other file                           │  │
│  │  • Not listed in any index or registry                        │  │
│  │  • Not recently accessed (> 60 days)                          │  │
│  │                                                                │  │
│  │  Action: Report only, no deletion without approval            │  │
│  └───────────────────────────────────────────────────────────────┘  │
│                                                                      │
│  GIT HOUSEKEEPING                                                    │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │  Commands (notify user before running):                        │  │
│  │  • git gc --auto                                              │  │
│  │  • git prune (unreachable objects)                            │  │
│  │  • git remote prune origin                                    │  │
│  │                                                                │  │
│  │  Frequency: Monthly or when repo size exceeds threshold       │  │
│  └───────────────────────────────────────────────────────────────┘  │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### Task 2: Freshness Audit

**Purpose**: Detect stale documentation, outdated dependencies, and unused patterns.

**Automation Level**: Report + flag for R&D

**Frequency**: Idle/Weekly

```
┌─────────────────────────────────────────────────────────────────────┐
│                      FRESHNESS AUDIT                                 │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  DOCUMENTATION STALENESS                                             │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │  Scan Locations:                                               │  │
│  │  • .claude/context/**/*.md                                    │  │
│  │  • projects/project-aion/**/*.md                              │  │
│  │  • docs/**/*.md                                               │  │
│  │                                                                │  │
│  │  Staleness Criteria:                                           │  │
│  │  • STALE: Not modified in > 30 days                           │  │
│  │  • VERY STALE: Not modified in > 90 days                      │  │
│  │  • ORPHAN: Not referenced by any other file                   │  │
│  │                                                                │  │
│  │  Additional Checks:                                            │  │
│  │  • Version references (outdated versions mentioned)           │  │
│  │  • Broken internal links (references to missing files)        │  │
│  │  • TODO/FIXME comments older than 60 days                     │  │
│  │                                                                │  │
│  │  Output → Freshness Report → AC-07 R&D for review             │  │
│  └───────────────────────────────────────────────────────────────┘  │
│                                                                      │
│  DEPENDENCY FRESHNESS                                                │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │  MCP Servers:                                                  │  │
│  │  • Check installed versions vs npm registry latest            │  │
│  │  • Flag if > 2 minor versions behind                          │  │
│  │  • Flag if security advisories exist                          │  │
│  │                                                                │  │
│  │  Plugins:                                                      │  │
│  │  • Check installed plugin versions                            │  │
│  │  • Compare to source repository latest                        │  │
│  │                                                                │  │
│  │  Node.js Packages:                                             │  │
│  │  • Run npm outdated (if package.json exists)                  │  │
│  │  • Flag major version updates                                 │  │
│  │  • Flag security vulnerabilities                              │  │
│  └───────────────────────────────────────────────────────────────┘  │
│                                                                      │
│  PATTERN APPLICABILITY                                               │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │  Questions to Answer:                                          │  │
│  │  • Are documented patterns still in use?                      │  │
│  │  • Do patterns match current implementation?                  │  │
│  │  • Are there patterns that should be documented but aren't?   │  │
│  │                                                                │  │
│  │  Method:                                                       │  │
│  │  • Grep codebase for pattern references                       │  │
│  │  • Compare pattern docs to actual implementations             │  │
│  │  • Check pattern cross-references are valid                   │  │
│  │                                                                │  │
│  │  Output: Pattern applicability report                          │  │
│  └───────────────────────────────────────────────────────────────┘  │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### Task 3: Health Checks

**Purpose**: Validate hook syntax, settings schema, MCP connectivity, and git status.

**Automation Level**: Report + warn if issues

**Frequency**: Session start

```
┌─────────────────────────────────────────────────────────────────────┐
│                       HEALTH CHECKS                                  │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  HOOK VALIDATION                                                     │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │  For each .js hook in .claude/hooks/:                          │  │
│  │  1. Attempt to parse (Node.js syntax check)                   │  │
│  │  2. Check for required exports (if applicable)                │  │
│  │  3. Verify referenced dependencies exist                      │  │
│  │                                                                │  │
│  │  For each .sh hook:                                            │  │
│  │  1. Check bash syntax (bash -n)                               │  │
│  │  2. Verify shebang line                                       │  │
│  │  3. Check for referenced files/commands                       │  │
│  │                                                                │  │
│  │  On failure: Log error, continue (don't block session)        │  │
│  └───────────────────────────────────────────────────────────────┘  │
│                                                                      │
│  SETTINGS VALIDATION                                                 │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │  Location: ~/.claude/settings.json                             │  │
│  │                                                                │  │
│  │  Checks:                                                       │  │
│  │  1. Valid JSON syntax                                         │  │
│  │  2. All hook paths in settings exist                          │  │
│  │  3. Hook configurations are valid                             │  │
│  │  4. No duplicate hook registrations                           │  │
│  │  5. MCP configurations are syntactically correct              │  │
│  │                                                                │  │
│  │  On failure: Warn user, provide fix suggestions               │  │
│  └───────────────────────────────────────────────────────────────┘  │
│                                                                      │
│  MCP CONNECTIVITY                                                    │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │  For each configured MCP in settings.json:                     │  │
│  │  1. Attempt basic connection                                  │  │
│  │  2. Verify server responds                                    │  │
│  │  3. Check authentication (if required)                        │  │
│  │                                                                │  │
│  │  Timeout: 5 seconds per MCP                                    │  │
│  │  On failure: Log warning, don't block session                 │  │
│  └───────────────────────────────────────────────────────────────┘  │
│                                                                      │
│  GIT STATUS                                                          │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │  Checks:                                                       │  │
│  │  1. Is this a git repository?                                 │  │
│  │  2. Working tree clean? (uncommitted changes)                 │  │
│  │  3. Correct branch? (expected branch for project)             │  │
│  │  4. Remote accessible? (git fetch --dry-run)                  │  │
│  │  5. Behind/ahead of remote?                                   │  │
│  │                                                                │  │
│  │  On issues: Report status, don't auto-fix                     │  │
│  └───────────────────────────────────────────────────────────────┘  │
│                                                                      │
│  HEALTH REPORT FORMAT                                                │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │  # Health Report YYYY-MM-DD                                    │  │
│  │                                                                │  │
│  │  ## Summary                                                    │  │
│  │  - Hooks: X/Y valid                                           │  │
│  │  - Settings: Valid/Invalid                                    │  │
│  │  - MCPs: X/Y connected                                        │  │
│  │  - Git: Clean/Dirty                                           │  │
│  │                                                                │  │
│  │  ## Issues Found                                               │  │
│  │  1. [SEVERITY] Description                                    │  │
│  │     Suggested fix: ...                                        │  │
│  └───────────────────────────────────────────────────────────────┘  │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### Task 4: Organization Review

**Purpose**: Ensure files are in correct locations and references are valid.

**Automation Level**: Report + proposals

**Frequency**: Idle/Manual

```
┌─────────────────────────────────────────────────────────────────────┐
│                    ORGANIZATION REVIEW                               │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  JARVIS CODEBASE REVIEW                                             │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │  .claude/ Structure Validation:                                │  │
│  │  ├── context/ — documentation and patterns                    │  │
│  │  │   ├── components/ — AC-XX specs                            │  │
│  │  │   ├── patterns/ — behavior patterns                        │  │
│  │  │   ├── standards/ — standards documents                     │  │
│  │  │   ├── reference/ — on-demand reference                     │  │
│  │  │   └── integrations/ — tool integrations                    │  │
│  │  ├── hooks/ — hook scripts                                    │  │
│  │  ├── commands/ — command definitions                          │  │
│  │  ├── config/ — configuration files                            │  │
│  │  ├── state/ — runtime state                                   │  │
│  │  ├── logs/ — log files                                        │  │
│  │  └── reports/ — generated reports                             │  │
│  │                                                                │  │
│  │  Checks:                                                       │  │
│  │  • Each file in expected directory                            │  │
│  │  • No orphan files at root                                    │  │
│  │  • Naming conventions followed                                │  │
│  │  • Index files exist and are current                          │  │
│  └───────────────────────────────────────────────────────────────┘  │
│                                                                      │
│  ACTIVE PROJECT REVIEW                                               │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │  Check against project's design specs (if defined):            │  │
│  │                                                                │  │
│  │  • File placement matches design document                     │  │
│  │  • Directory structure follows conventions                    │  │
│  │  • Source code in expected locations                          │  │
│  │  • Documentation in expected locations                        │  │
│  │  • Test files alongside source (or in tests/)                 │  │
│  │                                                                │  │
│  │  Reference Integrity:                                          │  │
│  │  • Internal links resolve                                     │  │
│  │  • Import/require paths are valid                             │  │
│  │  • Configuration references exist                             │  │
│  └───────────────────────────────────────────────────────────────┘  │
│                                                                      │
│  REFERENCE/LINK VALIDATION                                           │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │  Markdown Links:                                               │  │
│  │  • Parse all [text](link) patterns                            │  │
│  │  • Verify internal links (relative paths) exist               │  │
│  │  • Flag broken links                                          │  │
│  │                                                                │  │
│  │  Code References:                                              │  │
│  │  • @path/to/file patterns in CLAUDE.md                        │  │
│  │  • Import statements in JS/TS                                 │  │
│  │  • Source references in YAML/JSON                             │  │
│  │                                                                │  │
│  │  Output: List of broken references with suggested fixes       │  │
│  └───────────────────────────────────────────────────────────────┘  │
│                                                                      │
│  ORGANIZATION REPORT FORMAT                                          │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │  # Organization Report YYYY-MM-DD                              │  │
│  │                                                                │  │
│  │  ## Jarvis Codebase                                            │  │
│  │  - Structure: Valid/Issues Found                               │  │
│  │  - Misplaced files: N                                         │  │
│  │  - Broken references: N                                       │  │
│  │                                                                │  │
│  │  ## Active Project (if applicable)                             │  │
│  │  - Structure: Valid/Issues Found                               │  │
│  │  - Misplaced files: N                                         │  │
│  │  - Broken references: N                                       │  │
│  │                                                                │  │
│  │  ## Recommendations                                            │  │
│  │  1. Move X to Y (reason)                                      │  │
│  │  2. Fix reference from A to B                                 │  │
│  └───────────────────────────────────────────────────────────────┘  │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### Task 5: Optimization Analysis

**Purpose**: Identify opportunities for reducing context cost and consolidating content.

**Automation Level**: Proposals only

**Frequency**: Idle/Monthly

```
┌─────────────────────────────────────────────────────────────────────┐
│                    OPTIMIZATION ANALYSIS                             │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  CONTEXT USAGE ANALYSIS                                              │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │  Data Source: File usage tracking (AC-07 R&D)                  │  │
│  │                                                                │  │
│  │  Analyze:                                                      │  │
│  │  • Which .claude files are loaded most frequently             │  │
│  │  • Which files are loaded but rarely used                     │  │
│  │  • Token cost per file (character count as proxy)             │  │
│  │  • Value ratio: usage frequency / token cost                  │  │
│  │                                                                │  │
│  │  Questions:                                                    │  │
│  │  • Should low-value files be moved to on-demand reference?    │  │
│  │  • Should high-use files be more concise?                     │  │
│  │  • Are there files that should be combined?                   │  │
│  └───────────────────────────────────────────────────────────────┘  │
│                                                                      │
│  DUPLICATE DETECTION                                                 │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │  Methods:                                                      │  │
│  │  • Near-duplicate content (>80% similarity)                   │  │
│  │  • Repeated instruction blocks                                │  │
│  │  • Same pattern documented in multiple places                 │  │
│  │                                                                │  │
│  │  Detection:                                                    │  │
│  │  • Hash comparison for exact duplicates                       │  │
│  │  • Fuzzy matching for near-duplicates                         │  │
│  │  • Cross-reference analysis                                   │  │
│  │                                                                │  │
│  │  Output: List of potential duplicates with locations          │  │
│  └───────────────────────────────────────────────────────────────┘  │
│                                                                      │
│  CONSOLIDATION PROPOSALS                                             │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │  Proposal Format:                                              │  │
│  │  {                                                            │  │
│  │    "type": "consolidation",                                   │  │
│  │    "source": ["file1.md", "file2.md"],                        │  │
│  │    "target": "combined.md",                                   │  │
│  │    "rationale": "80% content overlap",                        │  │
│  │    "estimated_savings": "~500 tokens",                        │  │
│  │    "risk": "low"                                              │  │
│  │  }                                                            │  │
│  │                                                                │  │
│  │  Proposals go to AC-06 Evolution queue                         │  │
│  │  Require user approval before implementation                  │  │
│  └───────────────────────────────────────────────────────────────┘  │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

---

## State Management

### Maintenance State File

**Location**: `.claude/state/components/AC-08-maintenance.json`

```json
{
  "component": "AC-08",
  "version": "1.0.0",
  "last_updated": "2026-01-16T18:00:00.000Z",
  "task_history": {
    "cleanup": {
      "last_run": "2026-01-16T17:30:00.000Z",
      "logs_rotated": 5,
      "temps_cleaned": 12
    },
    "freshness": {
      "last_run": "2026-01-15T10:00:00.000Z",
      "stale_files": 8,
      "broken_links": 2
    },
    "health": {
      "last_run": "2026-01-16T08:00:00.000Z",
      "issues": 0
    },
    "organization": {
      "last_run": "2026-01-14T14:00:00.000Z",
      "misplaced": 3,
      "orphaned": 1
    },
    "optimization": {
      "last_run": "2026-01-10T09:00:00.000Z",
      "proposals_generated": 2
    }
  },
  "schedule": {
    "next_freshness_audit": "2026-01-22T10:00:00.000Z",
    "next_optimization": "2026-02-10T09:00:00.000Z"
  },
  "cumulative_stats": {
    "total_runs": 47,
    "total_logs_rotated": 156,
    "total_issues_found": 89,
    "total_proposals_generated": 12
  }
}
```

---

## Report Templates

### Health Report Template

```markdown
# Health Report YYYY-MM-DD

**Generated**: {timestamp}
**Trigger**: {session-start|manual|scheduled}

## Summary

| Component | Status | Issues |
|-----------|--------|--------|
| Hooks | {X/Y valid} | {count} |
| Settings | {Valid/Invalid} | {count} |
| MCPs | {X/Y connected} | {count} |
| Git | {Clean/Dirty} | {count} |

**Overall Health**: {Healthy|Warnings|Critical}

## Issues Found

### High Priority
{list of critical issues}

### Medium Priority
{list of warnings}

### Low Priority
{list of minor issues}

## Suggested Fixes

{numbered list of actionable fixes}

---
*Generated by AC-08 Maintenance Workflows*
```

### Freshness Report Template

```markdown
# Freshness Report YYYY-MM-DD

**Generated**: {timestamp}
**Scan Scope**: {Jarvis codebase + active project}

## Documentation Freshness

### Stale Files (> 30 days)
| File | Last Modified | Days Stale |
|------|---------------|------------|
{table rows}

### Very Stale Files (> 90 days)
| File | Last Modified | Days Stale |
|------|---------------|------------|
{table rows}

### Broken Links
| Source File | Broken Link | Line |
|-------------|-------------|------|
{table rows}

## Dependency Freshness

### MCP Servers
| Server | Installed | Latest | Behind |
|--------|-----------|--------|--------|
{table rows}

### Plugins
| Plugin | Installed | Latest | Behind |
|--------|-----------|--------|--------|
{table rows}

## Recommendations

{numbered list of items to review with R&D}

---
*Generated by AC-08 Maintenance Workflows*
*Items flagged for AC-07 R&D review*
```

### Organization Report Template

```markdown
# Organization Report YYYY-MM-DD

**Generated**: {timestamp}
**Scope**: {Jarvis codebase + {project name}}

## Jarvis Codebase

### Structure Validation
- Total files scanned: {count}
- Files in correct location: {count}
- Misplaced files: {count}

### Misplaced Files
| Current Location | Should Be | Reason |
|------------------|-----------|--------|
{table rows}

### Broken References
| Source | Target | Line |
|--------|--------|------|
{table rows}

## Active Project: {name}

### Structure Validation
- Matches design spec: {Yes/No/Partial}
- Issues found: {count}

### Issues
{list of issues}

## Recommendations

### File Moves
{numbered list of suggested moves}

### Reference Fixes
{numbered list of link fixes}

---
*Generated by AC-08 Maintenance Workflows*
```

---

## Integration Points

### With AC-06 Self-Evolution

Optimization proposals are added to the evolution queue:

```yaml
# evolution-queue.yaml entry
- id: maint-2026-01-16-001
  source: AC-08
  type: optimization
  title: Consolidate duplicate context patterns
  description: |
    Files context-budget-management.md and jicm-pattern.md have
    80% content overlap. Recommend consolidation.
  files:
    - .claude/context/patterns/context-budget-management.md
    - .claude/context/patterns/jicm-pattern.md
  estimated_savings: "~500 tokens"
  risk: low
  status: pending
  require_approval: true
  created: 2026-01-16T18:00:00.000Z
```

### With AC-07 R&D Cycles

Freshness findings are flagged for R&D review:

```yaml
# research-agenda.yaml entry
- id: fresh-2026-01-16-001
  source: AC-08
  type: freshness-review
  title: Review stale pattern files
  description: |
    8 pattern files not updated in 30+ days. May need
    revision or removal.
  files:
    - .claude/context/patterns/old-pattern-1.md
    - .claude/context/patterns/old-pattern-2.md
  priority: low
  added: 2026-01-16T18:00:00.000Z
```

### With Downtime Detector

```
Downtime Detection Flow:
1. Downtime detector triggers (~30 min idle)
2. Check last maintenance run times
3. Select tasks based on schedule:
   - Cleanup: if > 1 day since last run
   - Freshness: if > 7 days since last run
   - Organization: if > 7 days since last run
   - Optimization: if > 30 days since last run
4. Execute selected tasks
5. Update state file with new run times
```

---

## Error Handling

### Task-Level Failures

```
For each maintenance task:

try:
    execute_task()
    update_metrics()
    update_state()
except PermissionError:
    log_warning("Access denied: {file}")
    skip_file()
    continue
except TimeoutError:
    log_warning("Task timeout")
    checkpoint()
    defer_remaining()
except Exception:
    log_error("Unexpected error")
    rollback_partial()
    continue_next_task()
```

### Graceful Degradation

| Failure | Degradation |
|---------|-------------|
| Git unavailable | Skip git housekeeping, continue |
| Settings missing | Skip hook validation, warn |
| MCP unreachable | Skip MCP health, note in report |
| File access denied | Skip file, log, continue |
| Timeout | Checkpoint, resume later |

---

## Command Implementation

### `/maintain` Command

```
Command: /maintain [--task=<task>] [--scope=<scope>]

Options:
  --task     Specific task to run: cleanup|freshness|health|organization|optimization
             Default: all

  --scope    Scope of maintenance: jarvis|project|all
             Default: all

Examples:
  /maintain                          # Full maintenance cycle
  /maintain --task=health            # Health checks only
  /maintain --scope=jarvis           # Jarvis codebase only
  /maintain --task=freshness --scope=project  # Project freshness audit
```

---

## Safety Considerations

### Never Auto-Execute

The following actions ALWAYS require explicit user approval:

1. **File deletion** (orphans, duplicates)
2. **Structure changes** (moving files)
3. **Reference updates** (could break things)
4. **Git operations** beyond status (gc, prune)

### Audit Trail

All maintenance actions logged with:
- Timestamp
- Action type
- Files affected
- Outcome (success/failure/skipped)
- User approval (if required)

### Rollback Capability

| Action | Rollback Method |
|--------|-----------------|
| Log archive | Restore from archive |
| Temp cleanup | Not reversible (low impact) |
| Git gc | Limited (reflog) |
| Reports | Delete and regenerate |

---

*Maintenance Workflows Pattern — AC-08 Implementation Guide*
