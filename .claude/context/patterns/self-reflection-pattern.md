# Self-Reflection Pattern

**Version**: 1.0.0
**Created**: 2026-01-16
**Component**: AC-05 Self-Reflection
**PR**: PR-12.5

---

## Overview

Self-Reflection is the pattern by which Jarvis examines its own performance, identifies problems and patterns, and generates actionable improvement proposals. It transforms raw experience data (corrections, metrics, history) into structured insights that feed the Self-Evolution system.

### Core Principle

**Learn from experience systematically.** Every correction, every inefficiency, every success contains information. Self-Reflection extracts that information, organizes it, and converts it into improvement proposals.

---

## 1. Data Sources

### Primary Sources

```
┌─────────────────────────────────────────────────────────────────────┐
│                    REFLECTION DATA SOURCES                           │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  USER CORRECTIONS (corrections.md)                                   │
│  ├── Explicit corrections: "No, do X instead of Y"                  │
│  ├── Redirections: "Actually, let's focus on Z"                     │
│  ├── Preferences: "I prefer this approach"                          │
│  └── Format: Timestamped entries with context                       │
│                                                                      │
│  SELF-CORRECTIONS (self-corrections.md)                              │
│  ├── Realized mistakes: "I notice I made an error"                  │
│  ├── Approach changes: "Better approach would be..."                │
│  ├── Pattern violations: "This violates the X pattern"              │
│  └── Captured by: self-correction-capture.js hook                   │
│                                                                      │
│  SELECTION AUDIT (selection-audit.jsonl)                             │
│  ├── Tool choices: Which tool was selected for what task            │
│  ├── Agent delegations: When and why agents were spawned            │
│  ├── MCP usage: Which MCPs were invoked                             │
│  └── Patterns: Repeated selections, unusual choices                 │
│                                                                      │
│  CONTEXT USAGE (context-estimate.json)                               │
│  ├── Token consumption over time                                    │
│  ├── Peak usage periods                                             │
│  ├── MCP contribution to context                                    │
│  └── Checkpoint triggers                                            │
│                                                                      │
│  GIT HISTORY (git log)                                               │
│  ├── What files were changed                                        │
│  ├── Commit patterns (size, frequency)                              │
│  ├── Revert history (mistakes that were undone)                     │
│  └── PR completion patterns                                         │
│                                                                      │
│  MEMORY MCP (search_nodes)                                           │
│  ├── Prior reflections and insights                                 │
│  ├── Recurring problems                                             │
│  ├── Successful solutions                                           │
│  └── Cross-session patterns                                         │
│                                                                      │
│  AC-03 REVIEW FINDINGS                                               │
│  ├── Quality issues from milestone reviews                          │
│  ├── Remediation items                                              │
│  └── Approval/rejection reasons                                     │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### Data Collection

```javascript
// Pseudocode for data collection phase
async function collectReflectionData() {
  const data = {
    corrections: await readFile('lessons/corrections.md'),
    selfCorrections: await readFile('lessons/self-corrections.md'),
    selectionAudit: await readJsonl('selection-audit.jsonl'),
    contextUsage: await readJson('context-estimate.json'),
    gitHistory: await bash('git log --oneline -20'),
    memoryEntities: await memoryMcp.searchNodes('reflection'),
    reviewFindings: await glob('.claude/reports/reviews/*.md')
  };

  return data;
}
```

---

## 2. Corrections Format

### User Corrections (corrections.md)

```markdown
# Corrections Log

## 2026-01-16

### Context: PR-12.4 JICM Implementation

**Correction**: User clarified that JICM should trigger continuation, not session end.

**Original Approach**: Treating context exhaustion as session completion trigger.

**Corrected Approach**: Context exhaustion triggers checkpoint + /clear + resume. Work continues.

**Learning**: "Continuation, not exit" is a core principle for all context management.

---

### Context: Hook Development

**Correction**: User pointed out that JS hooks weren't executing.

**Original Approach**: Using module.exports = { handler } pattern.

**Corrected Approach**: Need stdin/stdout JSON wrapper for Claude Code hooks.

**Learning**: Claude Code hooks require specific communication protocol.

---
```

### Self-Corrections (self-corrections.md)

```markdown
# Self-Corrections Log

## 2026-01-16

### Context: AC-04 Component Spec

**Self-Correction**: Realized JICM cannot depend on MCPs.

**Original Design**: JICM using Memory MCP for state persistence.

**Corrected Design**: JICM must be MCP-independent since it may need to disable MCPs.

**Insight**: Components that manage resources cannot depend on those resources.

---

### Context: Pattern Document Structure

**Self-Correction**: Pattern documents were missing concrete examples.

**Original**: Abstract descriptions only.

**Corrected**: Added worked examples for each major workflow.

**Insight**: Patterns need examples to be actionable.

---
```

---

## 3. Three-Phase Reflection Process

### Phase 1: Identification

```
┌─────────────────────────────────────────────────────────────────────┐
│                    PHASE 1: IDENTIFICATION                           │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  QUESTIONS TO ANSWER:                                                │
│                                                                      │
│  1. What problems occurred?                                          │
│     └── Parse corrections for explicit issues                       │
│     └── Check git history for reverts                               │
│     └── Review AC-03 findings for quality issues                    │
│                                                                      │
│  2. What inefficiencies were observed?                               │
│     └── Context usage spikes (context-estimate.json)                │
│     └── Repeated tool selections (selection-audit.jsonl)            │
│     └── Long execution times                                        │
│                                                                      │
│  3. What corrections were received?                                  │
│     └── Count: N user corrections, M self-corrections               │
│     └── Categorize by type: approach, format, understanding         │
│     └── Note severity: minor adjustment vs major redirect           │
│                                                                      │
│  4. What patterns emerged?                                           │
│     └── Recurring correction types                                  │
│     └── Similar problems in different contexts                      │
│     └── Successful approaches that should be repeated               │
│                                                                      │
│  OUTPUT: Problem List                                                │
│  [                                                                   │
│    { "id": "P-001", "type": "approach", "description": "...",       │
│      "occurrences": 3, "severity": "medium" },                      │
│    ...                                                              │
│  ]                                                                   │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### Phase 2: Reflection

```
┌─────────────────────────────────────────────────────────────────────┐
│                    PHASE 2: REFLECTION                               │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  For each identified problem, answer:                                │
│                                                                      │
│  1. WHY did this problem occur?                                      │
│     └── Root cause analysis                                         │
│     └── Was information missing?                                    │
│     └── Was a pattern not followed?                                 │
│     └── Was this a capability gap?                                  │
│                                                                      │
│  2. What KNOWLEDGE was missing?                                      │
│     └── Was it documented but not read?                             │
│     └── Was it undocumented?                                        │
│     └── Was it documented incorrectly?                              │
│     └── Was context not loaded?                                     │
│                                                                      │
│  3. What approaches WORKED WELL?                                     │
│     └── Identify successful patterns                                │
│     └── Note efficient workflows                                    │
│     └── Mark for reinforcement                                      │
│                                                                      │
│  4. What should be AUTOMATED?                                        │
│     └── Repeated manual sequences                                   │
│     └── Error-prone operations                                      │
│     └── Consistency enforcement                                     │
│                                                                      │
│  OUTPUT: Analysis Results                                            │
│  [                                                                   │
│    { "problem_id": "P-001",                                         │
│      "root_cause": "Pattern not documented",                        │
│      "knowledge_gap": "Hook communication protocol",                │
│      "related_successes": ["similar fix in PR-9"],                  │
│      "automation_opportunity": "Hook validation script" },          │
│    ...                                                              │
│  ]                                                                   │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### Phase 3: Proposal

```
┌─────────────────────────────────────────────────────────────────────┐
│                    PHASE 3: PROPOSAL                                 │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  For each analysis result, generate:                                 │
│                                                                      │
│  1. SPECIFIC SOLUTION                                                │
│     └── Concrete change to make                                     │
│     └── Files/patterns affected                                     │
│     └── Implementation approach                                     │
│                                                                      │
│  2. RATIONALE                                                        │
│     └── Why this solution addresses the problem                     │
│     └── Expected impact                                             │
│     └── Alternative approaches considered                           │
│                                                                      │
│  3. RISK ASSESSMENT                                                  │
│     └── Low: Documentation update, new pattern file                 │
│     └── Medium: Hook modification, workflow change                  │
│     └── High: Core system change, multiple file edits               │
│                                                                      │
│  4. RELATED SOLUTIONS                                                │
│     └── Link to prior solutions for similar problems                │
│     └── Note if this extends/replaces existing solution             │
│                                                                      │
│  OUTPUT: Evolution Proposals                                         │
│  [                                                                   │
│    { "id": "EVO-2026-01-001",                                       │
│      "type": "documentation",                                       │
│      "title": "Document hook communication protocol",               │
│      "description": "Add troubleshooting guide for JS hooks",       │
│      "files": [".claude/context/troubleshooting/js-hooks.md"],      │
│      "risk": "low",                                                 │
│      "source": "reflection",                                        │
│      "related": ["EVO-2026-01-002"],                                │
│      "require_approval": false },                                   │
│    ...                                                              │
│  ]                                                                   │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 4. Lessons Directory Structure

### Directory Layout

```
.claude/context/lessons/
├── corrections.md              # User-provided corrections (append-only)
├── self-corrections.md         # Self-identified corrections (append-only)
├── index.md                    # Cross-referenced index
│
├── problems/                   # Problem entries
│   ├── 2026-01-hook-format.md
│   ├── 2026-01-context-bloat.md
│   ├── 2026-01-mcp-dependency.md
│   └── ...
│
├── solutions/                  # Solution entries
│   ├── 2026-01-hook-wrapper.md
│   ├── 2026-01-checkpoint-workflow.md
│   ├── 2026-01-mcp-independence.md
│   └── ...
│
└── patterns/                   # Discovered patterns
    ├── pattern-continuation-not-exit.md
    ├── pattern-progressive-disclosure.md
    ├── pattern-mcp-restart.md
    └── ...
```

### Problem Entry Format

```markdown
# Problem: Hook Format Incompatibility

**ID**: P-2026-01-001
**Date**: 2026-01-09
**Severity**: High
**Status**: Resolved

## Description

JavaScript hooks using `module.exports = { handler }` pattern were not executing in Claude Code. This affected all 18 JS hooks, meaning critical functionality (guardrails, context tracking, session management) was completely non-functional.

## Discovery

- User noticed hooks weren't firing during PR-5 validation
- Investigation revealed Claude Code hooks require stdin/stdout JSON protocol
- The module.exports pattern just defined a function but never invoked it

## Impact

- All guardrail hooks inactive (workspace-guard, dangerous-op-guard)
- Context tracking not working (context-accumulator)
- Session management not functioning (session-start, session-stop)

## Root Cause

Documentation gap: Hook communication protocol not documented. Assumed standard Node.js module pattern would work.

## Resolution

See: S-2026-01-001 (Hook Wrapper Solution)

## Related

- S-2026-01-001: Hook wrapper solution
- PATTERN-hook-protocol: Hook communication pattern
```

### Solution Entry Format

```markdown
# Solution: Hook Wrapper Pattern

**ID**: S-2026-01-001
**Date**: 2026-01-09
**Status**: Implemented
**Resolves**: P-2026-01-001

## Solution

Add `if (require.main === module)` wrapper to all JS hooks that:
1. Reads JSON from stdin
2. Calls the handler function
3. Outputs JSON to stdout
4. Uses console.error for debug messages (not stdout)

## Implementation

```javascript
// At the end of every JS hook file:
if (require.main === module) {
  let data = '';
  process.stdin.on('data', chunk => data += chunk);
  process.stdin.on('end', async () => {
    try {
      const input = JSON.parse(data);
      const result = await handler(input);
      console.log(JSON.stringify(result || { continue: true }));
    } catch (error) {
      console.error('Hook error:', error.message);
      console.log(JSON.stringify({ continue: true }));
    }
  });
}
```

## Files Changed

- `.claude/hooks/context-accumulator.js`
- `.claude/hooks/orchestration-detector.js`
- `.claude/hooks/cross-project-commit-tracker.js`
- `.claude/hooks/subagent-stop.js`
- `.claude/hooks/self-correction-capture.js`

## Validation

All 5 hooks now execute correctly. Verified by checking:
- context-estimate.json updates after tool calls
- orchestration-detector returns complexity scores
- self-correction patterns detected

## Lessons Learned

- Always verify hooks are actually executing, not just registered
- Claude Code has specific communication protocols not documented in obvious places
- Created troubleshooting doc: hookify-import-fix.md
```

### Pattern Entry Format

```markdown
# Pattern: Continuation, Not Exit

**ID**: PATTERN-continuation-not-exit
**Discovered**: 2026-01-16
**Status**: Active
**Components**: AC-02, AC-04

## Pattern

When a system encounters a boundary condition (context exhaustion, work completion, blocking issue), the default response should be **continuation** not **termination**.

## Application

| Situation | Wrong Response | Correct Response |
|-----------|----------------|------------------|
| Context exhaustion | End session | Checkpoint, clear, resume |
| Wiggum loop blocked | Stop and report | Investigate, attempt resolution |
| Scope drift | Exit with partial work | Realign and continue |
| Idle time | Wait for user | Trigger productive work |

## Rationale

User intervention should be the exception, not the rule. Jarvis is designed to operate autonomously. Stopping and waiting creates unnecessary friction and defeats the purpose of autonomous operation.

## Examples

1. **AC-04 JICM**: Context at 90% → checkpoint + /clear → resume work
2. **AC-02 Wiggum**: Blocker encountered → investigate → attempt fix → only then report
3. **AC-06 Downtime**: User idle 30 min → trigger self-improvement

## Anti-Patterns

- "Waiting for user instructions" when blocked
- "Session complete" when context is full
- "Cannot proceed" without investigation attempt
```

---

## 5. Index Management

### Index File Format (index.md)

```markdown
# Lessons Index

**Last Updated**: 2026-01-16
**Total Entries**: 15 problems, 12 solutions, 8 patterns

---

## By Category

### Hook Development
- P-2026-01-001: Hook Format Incompatibility
- S-2026-01-001: Hook Wrapper Pattern
- PATTERN-hook-protocol

### Context Management
- P-2026-01-002: Context Bloat
- S-2026-01-002: Checkpoint Workflow
- PATTERN-continuation-not-exit

### Component Design
- P-2026-01-003: MCP Dependency Issue
- S-2026-01-003: MCP Independence
- PATTERN-resource-independence

---

## By Date (Recent First)

### 2026-01-16
- P-2026-01-003: MCP Dependency Issue
- S-2026-01-003: MCP Independence
- PATTERN-continuation-not-exit

### 2026-01-09
- P-2026-01-001: Hook Format Incompatibility
- S-2026-01-001: Hook Wrapper Pattern
- P-2026-01-002: Context Bloat

---

## By Status

### Open Problems
- (none currently)

### Recently Resolved
- P-2026-01-001 → S-2026-01-001
- P-2026-01-002 → S-2026-01-002
- P-2026-01-003 → S-2026-01-003

---

## Cross-References

| Problem | Solution | Pattern |
|---------|----------|---------|
| P-2026-01-001 | S-2026-01-001 | PATTERN-hook-protocol |
| P-2026-01-002 | S-2026-01-002 | PATTERN-continuation-not-exit |
| P-2026-01-003 | S-2026-01-003 | PATTERN-resource-independence |
```

---

## 6. Evolution Queue Integration

### Proposal Format

```yaml
# .claude/state/queues/evolution-queue.yaml
version: 1.0.0
last_updated: 2026-01-16T18:00:00.000Z

proposals:
  - id: EVO-2026-01-001
    created: 2026-01-16T18:00:00.000Z
    source: reflection  # reflection | r&d | maintenance | user
    status: pending     # pending | approved | rejected | implemented

    title: Add hook troubleshooting guide
    description: |
      Create comprehensive troubleshooting guide for JS hooks
      covering common issues like the stdin/stdout protocol requirement.

    type: documentation
    risk: low

    files:
      - .claude/context/troubleshooting/js-hooks.md

    rationale: |
      Hook format issues caused significant debugging time.
      Documentation would prevent recurrence.

    require_approval: false  # Low risk, auto-approvable
    related_problems:
      - P-2026-01-001

  - id: EVO-2026-01-002
    created: 2026-01-16T18:00:00.000Z
    source: reflection
    status: pending

    title: Add hook validation script
    description: |
      Create script that validates all JS hooks are properly
      formatted with stdin/stdout wrapper.

    type: automation
    risk: low

    files:
      - .claude/scripts/validate-hooks.sh

    rationale: |
      Automated validation prevents regression of hook format issues.

    require_approval: false
    related_problems:
      - P-2026-01-001
```

---

## 7. Memory MCP Integration

### Entity Types

```yaml
# Reflection-related Memory entities

reflection_session:
  type: entity
  name: "Reflection: [date]"
  observations:
    - "Processed N corrections"
    - "Identified M problems"
    - "Generated K proposals"
  relations:
    - type: produced
      target: problem_entities
    - type: produced
      target: solution_entities

problem:
  type: entity
  name: "Problem: [title]"
  observations:
    - "Severity: [level]"
    - "Status: [status]"
    - "Root cause: [cause]"
  relations:
    - type: resolved_by
      target: solution_entity

solution:
  type: entity
  name: "Solution: [title]"
  observations:
    - "Status: [status]"
    - "Risk: [level]"
    - "Files changed: [list]"
  relations:
    - type: resolves
      target: problem_entity

pattern:
  type: entity
  name: "Pattern: [title]"
  observations:
    - "Components: [list]"
    - "Status: [active/deprecated]"
  relations:
    - type: derived_from
      target: problem_entities
```

### Memory Queries

```javascript
// Find recurring problems
await memory.search_nodes({ query: 'problem recurring' });

// Find solutions for similar issues
await memory.search_nodes({ query: 'solution hook' });

// Get reflection history
await memory.search_nodes({ query: 'reflection session' });
```

---

## 8. Reflection Report Format

### Report Template

```markdown
# Reflection Report

**Date**: 2026-01-16
**Session**: PR-12.5 Implementation
**Trigger**: PR Completion

---

## Summary

| Metric | Value |
|--------|-------|
| Corrections Processed | 5 |
| Problems Identified | 3 |
| Solutions Proposed | 3 |
| Patterns Discovered | 1 |
| Evolution Proposals | 4 |

---

## Corrections Analyzed

### User Corrections (3)

1. **JICM Continuation Principle**
   - Corrected: Session end on context exhaustion
   - To: Continuation after checkpoint

2. **Two-Level Review Structure**
   - Corrected: Single review pass
   - To: Code-review + project-manager agents

3. **Semi-Autonomous Triggers**
   - Corrected: Fully automatic triggers
   - To: Prompt user, then proceed on approval

### Self-Corrections (2)

1. **MCP Independence**
   - Realized JICM cannot depend on MCPs it may disable

2. **Pattern Examples**
   - Added concrete examples to abstract patterns

---

## Problems Identified

### P-2026-01-004: Incomplete Pattern Documentation

**Severity**: Medium
**Root Cause**: Time pressure led to abstract-only patterns
**Recommendation**: Always include worked examples

### P-2026-01-005: Missing Integration Tests

**Severity**: Low
**Root Cause**: Focus on specification over validation
**Recommendation**: Add validation checklist to component template

---

## Solutions Proposed

### S-2026-01-004: Pattern Example Requirement

Add "Examples" as mandatory section in pattern template.
**Risk**: Low | **Files**: pattern template

### S-2026-01-005: Component Validation Harness

Create validation script for component specs.
**Risk**: Low | **Files**: validate-component.sh

---

## Patterns Discovered

### PATTERN-continuation-not-exit

Boundary conditions (context exhaustion, blocking issues) should trigger
continuation, not termination. User intervention is exception, not rule.

---

## Evolution Queue

4 proposals added:

| ID | Title | Risk | Auto-Approve |
|----|-------|------|--------------|
| EVO-001 | Pattern example requirement | Low | Yes |
| EVO-002 | Component validation harness | Low | Yes |
| EVO-003 | Reflection trigger hook | Low | Yes |
| EVO-004 | Lessons index generator | Low | Yes |

---

## Next Actions

1. AC-06 will process low-risk proposals automatically
2. Review EVO-003 and EVO-004 for implementation priority
3. Update PATTERN-continuation-not-exit with more examples

---

*Generated by AC-05 Self-Reflection*
```

---

## 9. /reflect Command

### Command Definition

```markdown
# /reflect Command

Trigger self-reflection cycle to analyze recent work and generate improvement proposals.

## Usage

```
/reflect                    # Standard reflection
/reflect --quick            # Quick pass (corrections only)
/reflect --thorough         # Deep analysis (all sources)
/reflect --since=2026-01-15 # Reflect on work since date
```

## Options

| Option | Description |
|--------|-------------|
| `--quick` | Process corrections only, skip history analysis |
| `--thorough` | Full analysis including git history, selection audit |
| `--since=DATE` | Limit to work after specified date |
| `--pr=PR-12` | Limit to specific PR |

## Output

- Reflection report in `.claude/reports/reflections/`
- New entries in lessons directory
- Evolution proposals in queue
- Memory entities created

## When to Use

- After completing a PR
- At session end (called by /end-session)
- When you've received multiple corrections
- Before starting major new work
```

---

## 10. Configuration

### autonomy-config.yaml Settings

```yaml
components:
  AC-05-reflection:
    enabled: true
    settings:
      # Trigger settings
      auto_on_session_end: true
      auto_on_pr_complete: true
      min_session_duration: 5  # minutes, skip if shorter

      # Depth settings
      default_depth: standard  # quick | standard | thorough
      include_git_history: true
      include_selection_audit: true
      include_memory_search: true

      # Output settings
      create_memory_entities: true
      generate_evolution_proposals: true
      update_lessons_index: true

      # Thresholds
      correction_backlog_trigger: 5  # Auto-reflect after N corrections
```

---

## 11. Examples

### Session-End Reflection

```
User: /end-session

Jarvis: Running pre-exit reflection...

[AC-05 activates]

Phase 1: Identification
- Found 3 user corrections
- Found 2 self-corrections
- Selection audit: 45 tool calls, 3 agent delegations
- Context peak: 78%

Phase 2: Reflection
- Root causes identified for 3 problems
- 2 patterns recognized
- 1 automation opportunity found

Phase 3: Proposal
- Generated 4 evolution proposals
- Created 3 lessons entries
- Updated index

Jarvis: Reflection complete.
- 3 problems documented
- 4 proposals queued
- Report: .claude/reports/reflections/2026-01-16.md

Proceeding with session end...
```

### Manual Reflection

```
User: /reflect --thorough

Jarvis: Starting thorough reflection analysis...

[Extended analysis including git history, all data sources]

...

Reflection complete.

## Key Findings

1. **Hook Protocol Issue** (resolved)
   - 5 hooks were non-functional
   - Fixed with stdin/stdout wrapper
   - Pattern documented

2. **Context Management** (improved)
   - JICM designed with continuation principle
   - Checkpoint workflow established

3. **Component Patterns** (emerging)
   - 9-section spec template working well
   - Need more integration examples

## Proposals Generated: 6

Low risk (auto-approve): 4
Medium risk (queued): 2

See full report: .claude/reports/reflections/2026-01-16-thorough.md
```

---

*Self-Reflection Pattern — Jarvis Phase 6 PR-12.5*
