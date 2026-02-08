# Pattern Cross-Reference Audit

**Date**: 2026-02-08
**Scope**: All 48 pattern files in `.claude/context/patterns/`
**Objective**: Identify which patterns are referenced by files outside the patterns directory

---

## Executive Summary

**Total Patterns**: 48
**Well-Referenced** (both high-level + behavioral): **4 patterns (8.3%)**
**Partially Referenced** (behavioral only): **38 patterns (79.2%)**
**Orphaned** (no references): **6 patterns (12.5%)**

### Critical Finding

**3 out of 5 MANDATORY patterns lack high-level references**, meaning they are not discoverable from CLAUDE.md, compaction-essentials.md, or capability-map.yaml.

---

## Definitions

### High-Level Files (Discovery Layer)
Files that users and Jarvis consult first:
- `CLAUDE.md` — Primary instructions
- `.claude/context/compaction-essentials.md` — Context compression reference
- `.claude/context/psyche/capability-map.yaml` — Manifest router
- `.claude/context/psyche/_index.md` — Psyche topology

### Behavioral Files (Implementation Layer)
Files that implement behaviors:
- `.claude/skills/*/SKILL.md`
- `.claude/context/components/AC-*.md`
- `.claude/commands/*.md`
- `.claude/agents/*.md`
- Other context files (designs, guides, workflows)

---

## 1. ORPHANED PATTERNS (No References)

**Count**: 6 patterns

These patterns exist but are **never referenced** by any file outside `.claude/context/patterns/`:

| Pattern | Category (from _index.md) |
|---------|---------------------------|
| `agent-invocation-pattern` | Capability Architecture (AIfred Ported) |
| `autonomous-execution-pattern` | Capability Architecture (AIfred Ported) |
| `batch-mcp-validation` | MCP Management |
| `capability-layering-pattern` | Capability Architecture (AIfred Ported) |
| `code-before-prompts-pattern` | Capability Architecture (AIfred Ported) |
| `parallelization-strategy` | Core Behaviors |

### Analysis

**4 out of 6 orphaned patterns** are from the "Capability Architecture (AIfred Ported)" category, suggesting:
1. These patterns were ported from AIfred but not integrated
2. May be redundant with other patterns
3. May need implementation in skills/commands to become useful

**Recommended Actions**:
- Review each orphaned pattern for relevance
- Either integrate into high-level + behavioral files OR archive as historical
- `parallelization-strategy` is marked "Core Behaviors" but has zero references — likely critical gap

---

## 2. PARTIALLY REFERENCED PATTERNS (Behavioral Only)

**Count**: 38 patterns

These patterns are used in implementation files but **not discoverable from high-level references**:

### Session Lifecycle (3 patterns)
- `session-completion-pattern` — Used in AC-09 component, commands
- `session-start-checklist` — Used in AC-01 component, commands
- `startup-protocol` — ⚠️ **MANDATORY** but missing from high-level

### Core Behaviors (2 patterns)
- `jicm-pattern` — ⚠️ **MANDATORY** but missing from high-level
- `self-interruption-prevention` — Used in design docs

### Selection & Routing (2 patterns)
- `selection-validation-tests` — Used in validation skill
- `tool-selection-intelligence` — Used in psyche/nous-map

### MCP Management (4 patterns)
- `context-budget-management` — Used in reference docs, commands
- `mcp-design-patterns` — Used in workflows, troubleshooting
- `mcp-validation-harness` — Used in MCP validation skill

### Self-Improvement (Tier 2) (5 patterns)
- `maintenance-pattern` — Used in AC-08 component, skills
- `rd-cycles-pattern` — Used in AC-07 component, skills
- `self-evolution-pattern` — Used in AC-06 component, skills
- `self-improvement-pattern` — Used in archive session-state
- `self-reflection-pattern` — Used in AC-05 component, skills

### Development & Git (3 patterns)
- `branching-strategy` — Used in psyche/nous-map
- `cross-project-commit-tracking` — Used in archive session-state
- `milestone-review-pattern` — ⚠️ **MANDATORY** but missing from high-level

### Design & Planning (3 patterns)
- `memory-storage-pattern` — Used in overlap-analysis, lessons
- `prompt-design-review` — Used in commands, skills
- `workspace-path-policy` — Used in project management commands

### Infrastructure (3 patterns)
- `multi-repo-credential-pattern` — Used in lessons
- `project-reporting-pattern` — Used in reflections
- `service-lifecycle-pattern` — Used in reflections

### Automation & Integration (5 patterns)
- `automated-context-management` — Used in JICM designs, commands
- `command-signal-protocol` — Used in autonomous commands guide, skills
- `component-interaction-protocol` — Used in archive session-state
- `override-disable-pattern` — Used in archive session-state
- `jicm-continuation-prompt` — Used in JICM implementation report

### Plugin & Skill Management (1 pattern)
- `plugin-decomposition-pattern` — Used in archive session-state

### Testing & Validation (2 patterns)
- `autonomic-testing-framework` — Used in archive session-state
- `setup-validation` — Used in setup-readiness command

### Architecture (2 patterns)
- `archon-architecture-pattern` — Used in psyche/autopoietic-paradigm
- `organization-pattern` — Used in current-priorities, reflections

### Reference (Less Common) (3 patterns)
- `hook-consolidation-assessment` — Used in archive session-state
- `self-monitoring-commands` — Used in current-priorities, plans
- `worktree-shell-functions` — Used in archive session-state

---

## 3. WELL-REFERENCED PATTERNS (Both High-Level + Behavioral)

**Count**: 4 patterns

These patterns appear in **both** high-level discovery files and behavioral implementation files:

| Pattern | High-Level References | Key Behavioral Uses |
|---------|----------------------|---------------------|
| `agent-selection-pattern` | capability-map.yaml, psyche/_index.md | capability-matrix.md, workflow-patterns.md |
| `mcp-loading-strategy` | capability-map.yaml | psyche/nous-map.md, workflows, overlap-analysis |
| `selection-intelligence-guide` | capability-map.yaml, psyche/_index.md | current-priorities, capability-matrix |
| `wiggum-loop-pattern` | capability-map.yaml | AC-02 component, context/_index.md |

### Analysis

These 4 patterns represent **best practice** for pattern integration:
1. Discoverable from top-level files (CLAUDE.md router → capability-map.yaml)
2. Implemented in AC components and skills
3. Referenced in workflow and guide documents

---

## 4. CRITICAL GAP: MANDATORY PATTERNS

From `.claude/context/patterns/_index.md`, these patterns are marked **ALWAYS** (mandatory):

| Pattern | Purpose | High-Level Ref? | Status |
|---------|---------|----------------|--------|
| `wiggum-loop-pattern` | Multi-step implementation | ✅ Yes (capability-map.yaml) | **WELL-REFERENCED** |
| `milestone-review-pattern` | Milestone completion | ❌ No | ⚠️ **PARTIAL** |
| `selection-intelligence-guide` | Tool/agent selection | ✅ Yes (capability-map.yaml, psyche/_index.md) | **WELL-REFERENCED** |
| `jicm-pattern` | Context management | ❌ No | ⚠️ **PARTIAL** |
| `startup-protocol` | Session start | ❌ No | ⚠️ **PARTIAL** |
| `session-exit.md` (workflow) | Session end | N/A (not in patterns/) | N/A |

### Critical Finding

**3 MANDATORY patterns are not referenced in high-level files**:
- `milestone-review-pattern` — Used in AC-03, commands, but not in CLAUDE.md or capability-map
- `jicm-pattern` — Used in workflows, troubleshooting, but not in high-level refs
- `startup-protocol` — Used in AC-01, but not in high-level refs

**Impact**: These patterns are mandatory but not discoverable without reading patterns/_index.md first.

---

## 5. Observations by Category

### Well-Integrated Categories
- **Selection & Routing**: 2/4 patterns well-referenced (50%)
- **Core Behaviors**: 1/2 patterns well-referenced (50%)

### Poorly Integrated Categories
- **Capability Architecture (AIfred Ported)**: 0/5 patterns well-referenced (0%), 4/5 orphaned (80%)
- **Session Lifecycle**: 0/3 patterns well-referenced (0%)
- **Self-Improvement (Tier 2)**: 0/5 patterns well-referenced (0%)
- **MCP Management**: 1/5 patterns well-referenced (20%)

---

## Recommendations

### High Priority (Mandatory Patterns)

1. **Add to CLAUDE.md or capability-map.yaml**:
   - `jicm-pattern` — Reference in "Context (AC-04 JICM)" section or Key References
   - `startup-protocol` — Reference in "Session Start (AC-01)" section
   - `milestone-review-pattern` — Add to Key References table

2. **Update compaction-essentials.md**:
   - Add `jicm-pattern` reference (context compression directly relates to JICM)

### Medium Priority (High-Use Patterns)

3. **Add to capability-map.yaml or psyche/_index.md**:
   - `context-budget-management` (9 behavioral refs)
   - `mcp-design-patterns` (7 behavioral refs)
   - `automated-context-management` (7 behavioral refs)

4. **Verify relevance of Self-Improvement patterns**:
   - All 5 patterns in this category are partially referenced
   - Consider adding tier-2 patterns section to capability-map

### Low Priority (Orphaned Patterns)

5. **Review AIfred ported patterns**:
   - Decide if orphaned patterns should be:
     - **Integrated**: Add to skills/commands + high-level refs
     - **Archived**: Move to `patterns/archive/` with note
     - **Deleted**: If redundant with other patterns

6. **Integrate or archive**:
   - `parallelization-strategy` — Marked "Core Behaviors" but has zero refs
   - `batch-mcp-validation` — Likely replaced by `mcp-validation-harness`

### Documentation Improvement

7. **Pattern _index.md enhancements**:
   - Add "Referenced By" column showing high-level file count
   - Add warning badge for patterns with 0 high-level refs
   - Consider "integration status" field (well-referenced / partial / orphaned)

8. **Capability-map.yaml structure**:
   - Add section for session lifecycle patterns
   - Add section for self-improvement patterns (tier 2)
   - Ensure all mandatory patterns are listed

---

## Appendix: Full Reference Count by Pattern

### Well-Referenced (4 patterns)
- `agent-selection-pattern`: HIGH=2, BEHAV=12
- `mcp-loading-strategy`: HIGH=1, BEHAV=12
- `selection-intelligence-guide`: HIGH=2, BEHAV=11
- `wiggum-loop-pattern`: HIGH=1, BEHAV=6

### Partially Referenced — High Use (BEHAV ≥7)
- `context-budget-management`: HIGH=0, BEHAV=9
- `milestone-review-pattern`: HIGH=0, BEHAV=9
- `mcp-design-patterns`: HIGH=0, BEHAV=7
- `automated-context-management`: HIGH=0, BEHAV=7

### Partially Referenced — Medium Use (BEHAV 4-6)
- `jicm-pattern`: HIGH=0, BEHAV=6
- `prompt-design-review`: HIGH=0, BEHAV=5
- `mcp-validation-harness`: HIGH=0, BEHAV=5
- `selection-validation-tests`: HIGH=0, BEHAV=5
- `command-signal-protocol`: HIGH=0, BEHAV=5
- `memory-storage-pattern`: HIGH=0, BEHAV=4
- `organization-pattern`: HIGH=0, BEHAV=4
- `self-evolution-pattern`: HIGH=0, BEHAV=4
- `self-reflection-pattern`: HIGH=0, BEHAV=4
- `session-start-checklist`: HIGH=0, BEHAV=4
- `startup-protocol`: HIGH=0, BEHAV=4

### Partially Referenced — Low Use (BEHAV 1-3)
- `archon-architecture-pattern`: HIGH=0, BEHAV=1
- `autonomic-testing-framework`: HIGH=0, BEHAV=1
- `branching-strategy`: HIGH=0, BEHAV=2
- `command-invocation-pattern`: HIGH=0, BEHAV=1
- `component-interaction-protocol`: HIGH=0, BEHAV=1
- `cross-project-commit-tracking`: HIGH=0, BEHAV=1
- `hook-consolidation-assessment`: HIGH=0, BEHAV=1
- `jicm-continuation-prompt`: HIGH=0, BEHAV=2
- `maintenance-pattern`: HIGH=0, BEHAV=3
- `multi-repo-credential-pattern`: HIGH=0, BEHAV=1
- `override-disable-pattern`: HIGH=0, BEHAV=1
- `plugin-decomposition-pattern`: HIGH=0, BEHAV=1
- `project-reporting-pattern`: HIGH=0, BEHAV=2
- `rd-cycles-pattern`: HIGH=0, BEHAV=3
- `self-improvement-pattern`: HIGH=0, BEHAV=1
- `self-interruption-prevention`: HIGH=0, BEHAV=1
- `self-monitoring-commands`: HIGH=0, BEHAV=2
- `service-lifecycle-pattern`: HIGH=0, BEHAV=2
- `session-completion-pattern`: HIGH=0, BEHAV=3
- `setup-validation`: HIGH=0, BEHAV=2
- `tool-selection-intelligence`: HIGH=0, BEHAV=3
- `workspace-path-policy`: HIGH=0, BEHAV=3
- `worktree-shell-functions`: HIGH=0, BEHAV=1

### Orphaned (6 patterns)
- `agent-invocation-pattern`: HIGH=0, BEHAV=0
- `autonomous-execution-pattern`: HIGH=0, BEHAV=0
- `batch-mcp-validation`: HIGH=0, BEHAV=0
- `capability-layering-pattern`: HIGH=0, BEHAV=0
- `code-before-prompts-pattern`: HIGH=0, BEHAV=0
- `parallelization-strategy`: HIGH=0, BEHAV=0

---

## Search Methodology

**High-Level Files Searched**:
- `CLAUDE.md`
- `.claude/context/compaction-essentials.md`
- `.claude/context/psyche/capability-map.yaml`
- `.claude/context/psyche/_index.md`

**Behavioral Files Searched**:
- All `.md` and `.yaml` files in `.claude/` directory
- Excluding `.claude/context/patterns/` (to avoid self-references)

**Search Tool**: `grep -l` for filename matches (pattern name without `.md` extension)

**Date**: 2026-02-08
**Total Files Scanned**: ~200+ files across `.claude/` directory
**Patterns Analyzed**: 48 (excluding `_index.md`)

---

*Pattern Cross-Reference Audit — Jarvis v5.9.0*
