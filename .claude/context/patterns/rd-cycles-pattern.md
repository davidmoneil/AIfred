# R&D Cycles Pattern

**Version**: 1.0.0
**Created**: 2026-01-16
**Component**: AC-07 R&D Cycles
**PR**: PR-12.7

---

## Overview

R&D Cycles is the pattern by which Jarvis discovers and evaluates improvements—both external (new tools, MCPs, plugins) and internal (token efficiency, file organization). The key principle is **informed adoption with high bar**—new capabilities must demonstrate clear value before integration.

### Core Principle

**Discovery without bloat.** Every new tool, pattern, or change must:
1. Solve an actual Jarvis problem
2. Justify its context/complexity cost
3. Pass user approval before implementation

---

## 1. Research Agenda

### Agenda Format

```yaml
# .claude/state/queues/research-agenda.yaml
version: 1.0.0
last_updated: 2026-01-16T18:00:00.000Z

# Configuration
config:
  max_topics_per_cycle: 5
  external_scan_interval: monthly
  internal_scan_interval: weekly

# External research topics
external:
  - id: EXT-2026-01-001
    created: 2026-01-16T10:00:00.000Z
    status: pending          # pending | researching | completed | deferred
    priority: medium         # low | medium | high
    source: awesome-mcp      # awesome-mcp | plugins | anthropic | user | sota

    topic: "New MCP: xyz-server"
    description: "Discovered in awesome-mcp list, provides XYZ capability"
    url: "https://github.com/..."

    relevance_hypothesis: "Could replace manual workflow for X"

  - id: EXT-2026-01-002
    created: 2026-01-15T14:00:00.000Z
    status: completed
    priority: high
    source: anthropic

    topic: "Claude Code 1.5 features"
    description: "New release with enhanced capabilities"
    url: "https://docs.anthropic.com/..."

    result:
      classification: adopt
      proposal_id: EVO-2026-01-010

# Internal research topics
internal:
  - id: INT-2026-01-001
    created: 2026-01-16T08:00:00.000Z
    status: pending
    priority: high
    type: efficiency         # efficiency | organization | redundancy | unused

    topic: "Context usage spike analysis"
    description: "Investigate why sessions hit 70%+ context"
    target_files:
      - .claude/context/patterns/
      - .claude/context/reference/

  - id: INT-2026-01-002
    created: 2026-01-14T12:00:00.000Z
    status: completed
    priority: medium
    type: redundancy

    topic: "Duplicate instructions audit"
    description: "Find repeated content across CLAUDE.md files"

    result:
      findings: 3
      proposal_id: EVO-2026-01-008

# Research history (recent)
history:
  - id: EXT-2026-01-000
    completed: 2026-01-10T16:00:00.000Z
    topic: "MCP server: memory"
    classification: adopt
    result: "Integrated successfully"
```

### Agenda Population

```
Sources for external topics:
1. awesome-mcp lists → monthly scan
2. claude-code-plugins → monthly scan
3. Anthropic release notes → on announcement
4. SOTA catalog (PR-14) → reference
5. User suggestions → /research add [topic]

Sources for internal topics:
1. Context usage patterns → automatic
2. File usage tracking → automatic
3. Reflection findings → from AC-05
4. Maintenance audits → from AC-08
```

---

## 2. Five-Step Research Process

### Step 1: Discovery

```
┌─────────────────────────────────────────────────────────────────────┐
│                    STEP 1: DISCOVERY                                 │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  EXTERNAL DISCOVERY                                                  │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │  1. Scan source lists                                          │  │
│  │     • awesome-mcp: https://github.com/punkpeye/awesome-mcp     │  │
│  │     • claude-code-plugins: registry                            │  │
│  │     • Anthropic docs: release notes                            │  │
│  │                                                                │  │
│  │  2. Identify new entries (not in SOTA catalog)                 │  │
│  │                                                                │  │
│  │  3. Fetch basic info                                           │  │
│  │     • README content                                           │  │
│  │     • Stars/activity metrics                                   │  │
│  │     • Last update date                                         │  │
│  │                                                                │  │
│  │  Output: List of candidates for relevance filtering            │  │
│  └───────────────────────────────────────────────────────────────┘  │
│                                                                      │
│  INTERNAL DISCOVERY                                                  │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │  1. Analyze file usage log                                     │  │
│  │     • Which files loaded most frequently?                      │  │
│  │     • Which files rarely/never loaded?                         │  │
│  │                                                                │  │
│  │  2. Check context estimates                                    │  │
│  │     • What's consuming context budget?                         │  │
│  │     • Any unexpected spikes?                                   │  │
│  │                                                                │  │
│  │  3. Compare file contents                                      │  │
│  │     • Duplicate content across files?                          │  │
│  │     • Outdated references?                                     │  │
│  │                                                                │  │
│  │  Output: List of efficiency concerns                           │  │
│  └───────────────────────────────────────────────────────────────┘  │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### Step 2: Relevance Filtering

```
┌─────────────────────────────────────────────────────────────────────┐
│                    STEP 2: RELEVANCE FILTERING                       │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  For each discovered item, answer:                                   │
│                                                                      │
│  1. PROBLEM FIT                                                      │
│     └── Does this solve an actual Jarvis problem?                   │
│     └── What capability gap does it address?                        │
│     └── Is this a "nice to have" or "need to have"?                 │
│                                                                      │
│  2. OVERLAP CHECK                                                    │
│     └── Does it duplicate existing functionality?                   │
│     └── Would it replace something or add to it?                    │
│     └── Any conflicts with current tools?                           │
│                                                                      │
│  3. COMPLEXITY ASSESSMENT                                            │
│     └── How hard to integrate?                                      │
│     └── Dependencies required?                                      │
│     └── Maintenance burden?                                         │
│                                                                      │
│  4. MATURITY CHECK                                                   │
│     └── How stable is it?                                           │
│     └── Active maintenance?                                         │
│     └── Community adoption?                                         │
│                                                                      │
│  FILTERING DECISION:                                                 │
│     └── RELEVANT → proceed to deep analysis                         │
│     └── MARGINAL → add to agenda as low-priority                    │
│     └── NOT RELEVANT → skip, log reason                             │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### Step 3: Deep Analysis

```
┌─────────────────────────────────────────────────────────────────────┐
│                    STEP 3: DEEP ANALYSIS                             │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  For relevant items, conduct thorough analysis:                      │
│                                                                      │
│  METHOD: Use deep-research agent                                     │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │  Agent prompt:                                                 │  │
│  │  "Research [topic] for potential Jarvis integration.           │  │
│  │   Evaluate:                                                    │  │
│  │   1. Capabilities and features                                 │  │
│  │   2. Integration requirements                                  │  │
│  │   3. Context/token cost                                        │  │
│  │   4. Risks and limitations                                     │  │
│  │   5. Alternative approaches                                    │  │
│  │   Provide recommendation: ADOPT/ADAPT/DEFER/REJECT"            │  │
│  └───────────────────────────────────────────────────────────────┘  │
│                                                                      │
│  ANALYSIS AREAS:                                                     │
│                                                                      │
│  1. CAPABILITIES                                                     │
│     └── What specifically can it do?                                │
│     └── How does it compare to alternatives?                        │
│     └── Any unique features?                                        │
│                                                                      │
│  2. INTEGRATION                                                      │
│     └── Installation process                                        │
│     └── Configuration requirements                                  │
│     └── Jarvis-specific adaptations needed                          │
│                                                                      │
│  3. COST-BENEFIT                                                     │
│     └── Token/context cost                                          │
│     └── Performance impact                                          │
│     └── Maintenance overhead                                        │
│     └── Value delivered                                             │
│                                                                      │
│  4. RISKS                                                            │
│     └── Stability concerns                                          │
│     └── Security implications                                       │
│     └── Breaking change potential                                   │
│                                                                      │
│  Output: Detailed analysis document                                 │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### Step 4: Classification

```
┌─────────────────────────────────────────────────────────────────────┐
│                    STEP 4: CLASSIFICATION                            │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  Based on analysis, classify each item:                              │
│                                                                      │
│  ┌─────────────────────────────────────────────────────────────────┐│
│  │  ADOPT                                                          ││
│  │  Criteria:                                                       ││
│  │  • Clear problem fit                                            ││
│  │  • Low integration complexity                                   ││
│  │  • Acceptable context cost                                      ││
│  │  • Stable and maintained                                        ││
│  │  • Benefits > costs                                             ││
│  │                                                                  ││
│  │  Action: Create evolution proposal for integration              ││
│  └─────────────────────────────────────────────────────────────────┘│
│                                                                      │
│  ┌─────────────────────────────────────────────────────────────────┐│
│  │  ADAPT                                                          ││
│  │  Criteria:                                                       ││
│  │  • Good problem fit but needs modification                      ││
│  │  • Higher integration complexity                                ││
│  │  • May need Jarvis-specific wrapper                             ││
│  │  • Worth the effort                                             ││
│  │                                                                  ││
│  │  Action: Create proposal with adaptation plan                   ││
│  └─────────────────────────────────────────────────────────────────┘│
│                                                                      │
│  ┌─────────────────────────────────────────────────────────────────┐│
│  │  DEFER                                                          ││
│  │  Criteria:                                                       ││
│  │  • Potential value but not ready                                ││
│  │  • Too early/unstable                                           ││
│  │  • Depends on other changes first                               ││
│  │  • Low priority vs current work                                 ││
│  │                                                                  ││
│  │  Action: Add to agenda with future review date                  ││
│  └─────────────────────────────────────────────────────────────────┘│
│                                                                      │
│  ┌─────────────────────────────────────────────────────────────────┐│
│  │  REJECT                                                         ││
│  │  Criteria:                                                       ││
│  │  • No clear problem fit                                         ││
│  │  • Too complex for value                                        ││
│  │  • Better alternatives exist                                    ││
│  │  • Unacceptable risks                                           ││
│  │                                                                  ││
│  │  Action: Document reason, remove from agenda                    ││
│  └─────────────────────────────────────────────────────────────────┘│
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### Step 5: Proposal Generation

```
┌─────────────────────────────────────────────────────────────────────┐
│                    STEP 5: PROPOSAL GENERATION                       │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  For ADOPT and ADAPT items, create evolution proposal:               │
│                                                                      │
│  PROPOSAL FORMAT:                                                    │
│  ```yaml                                                             │
│  id: EVO-2026-01-015                                                │
│  source: r&d                     # Always 'r&d' for these           │
│  require_approval: true          # Always true for R&D              │
│                                                                      │
│  title: "Integrate xyz-mcp server"                                  │
│  description: |                                                      │
│    Add xyz-mcp for enhanced XYZ capability.                         │
│    Replaces manual workflow for X.                                  │
│                                                                      │
│  research:                                                           │
│    topic_id: EXT-2026-01-001                                        │
│    classification: adopt                                            │
│    report_path: .claude/reports/research/xyz-mcp-analysis.md        │
│                                                                      │
│  type: integration                                                   │
│  risk: medium                                                        │
│  impact: medium                                                      │
│                                                                      │
│  files:                                                              │
│    - path: .claude/config/mcps.yaml                                 │
│      action: modify                                                 │
│    - path: .claude/scripts/setup-mcps.sh                            │
│      action: modify                                                 │
│                                                                      │
│  integration_steps:                                                  │
│    - Install xyz-mcp via npm                                        │
│    - Add configuration to mcps.yaml                                 │
│    - Update setup-mcps.sh                                           │
│    - Document usage in capability-matrix.md                         │
│                                                                      │
│  validation:                                                         │
│    - MCP responds to test query                                     │
│    - No context budget regression                                   │
│    - Tooling health passes                                          │
│  ```                                                                 │
│                                                                      │
│  IMPORTANT: R&D proposals ALWAYS require approval                   │
│  They are added to evolution-queue.yaml but NOT auto-executed       │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 3. Research Report Format

### Report Template

```markdown
# R&D Research Report: [Topic]

**Date**: 2026-01-16
**Researcher**: Jarvis AC-07
**Topic ID**: EXT-2026-01-001
**Classification**: ADOPT | ADAPT | DEFER | REJECT

---

## Summary

Brief description of what was researched and the conclusion.

---

## Subject Overview

### Description
What is this tool/pattern/approach?

### Source
- Repository: [URL]
- Documentation: [URL]
- Last Updated: [date]
- Stars/Activity: [metrics]

---

## Analysis

### Pro/Con Analysis

| Pros | Cons |
|------|------|
| + Clear capability X | - Adds N tokens to context |
| + Active maintenance | - Requires configuration |
| + Solves problem Y | - Learning curve |

### Cost/Benefit Analysis

| Factor | Assessment |
|--------|------------|
| **Missingness** | What capability gap does it fill? |
| **Value** | How valuable is that capability? (1-10) |
| **Context Cost** | Token/context budget impact |
| **Complexity** | Implementation difficulty (1-10) |
| **Net Benefit** | Value - Costs |

### Capability Comparison

| Feature | This Tool | Current Alternative |
|---------|-----------|---------------------|
| Feature A | Yes | Partial |
| Feature B | Yes | No |
| Feature C | No | Yes |

---

## Integration Assessment

### Requirements
- Dependencies: [list]
- Configuration: [description]
- Jarvis changes: [files affected]

### Effort Estimate
- Initial setup: [low/medium/high]
- Ongoing maintenance: [low/medium/high]

### Risks
- [Risk 1]: [mitigation]
- [Risk 2]: [mitigation]

---

## Recommendation

**Classification**: [ADOPT/ADAPT/DEFER/REJECT]

**Rationale**:
[Detailed reasoning for the classification]

**If ADOPT/ADAPT**:
- Proposal ID: EVO-2026-01-XXX
- Priority: [low/medium/high]
- Suggested timeline: [description]

**If DEFER**:
- Review again: [date/condition]
- Blocking factors: [list]

**If REJECT**:
- Reason: [explanation]
- Alternatives: [if any]

---

*Generated by Jarvis AC-07 R&D Cycles*
```

---

## 4. Internal Efficiency Research

### File Usage Tracking

```javascript
// .claude/hooks/file-usage-tracker.js
// Tracks which .claude files are read into context

async function trackFileUsage(input) {
  if (input.tool === 'Read' && input.tool_input?.file_path) {
    const filePath = input.tool_input.file_path;

    // Only track .claude files
    if (filePath.includes('.claude/')) {
      const log = loadLog('.claude/logs/file-usage.jsonl');
      log.push({
        timestamp: new Date().toISOString(),
        session_id: getSessionId(),
        file_path: filePath,
        estimated_tokens: estimateTokens(filePath)
      });
      saveLog(log);
    }
  }

  return { continue: true };
}
```

### Efficiency Analysis

```
┌─────────────────────────────────────────────────────────────────────┐
│                    INTERNAL EFFICIENCY ANALYSIS                      │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  1. FILE USAGE PATTERNS                                              │
│     ┌─────────────────────────────────────────────────────────────┐ │
│     │  High-Use Files (loaded every session):                      │ │
│     │  • CLAUDE.md                                                 │ │
│     │  • session-state.md                                          │ │
│     │  • current-priorities.md                                     │ │
│     │                                                              │ │
│     │  Medium-Use Files (loaded most sessions):                    │ │
│     │  • selection-intelligence-guide.md                           │ │
│     │  • capability-matrix.md                                      │ │
│     │                                                              │ │
│     │  Low-Use Files (rarely loaded):                              │ │
│     │  • [identify candidates for consolidation]                   │ │
│     │                                                              │ │
│     │  Never-Used Files (potential removal):                       │ │
│     │  • [identify candidates for archival]                        │ │
│     └─────────────────────────────────────────────────────────────┘ │
│                                                                      │
│  2. REDUNDANCY DETECTION                                             │
│     ┌─────────────────────────────────────────────────────────────┐ │
│     │  Check for:                                                  │ │
│     │  • Duplicate paragraphs across files                         │ │
│     │  • Repeated instruction patterns                             │ │
│     │  • Overlapping content                                       │ │
│     │                                                              │ │
│     │  Solution: Reference/link instead of duplicate               │ │
│     └─────────────────────────────────────────────────────────────┘ │
│                                                                      │
│  3. CONTEXT BUDGET ANALYSIS                                          │
│     ┌─────────────────────────────────────────────────────────────┐ │
│     │  By category:                                                │ │
│     │  • CLAUDE.md: ~3000 tokens                                   │ │
│     │  • Patterns: ~500-1000 tokens each                           │ │
│     │  • MCPs: ~15000 tokens (all loaded)                          │ │
│     │                                                              │ │
│     │  Optimization opportunities:                                 │ │
│     │  • Trim verbose sections                                     │ │
│     │  • Use on-demand loading for patterns                        │ │
│     │  • Reduce MCP tool descriptions                              │ │
│     └─────────────────────────────────────────────────────────────┘ │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 5. /research Command

### Command Definition

```markdown
# /research Command

Trigger R&D cycle to discover and evaluate improvements.

## Usage

```
/research                      # Run full R&D cycle
/research --external           # External discovery only
/research --internal           # Internal efficiency only
/research --topic="[topic]"    # Research specific topic
/research add "[topic]"        # Add topic to agenda
/research status               # Show agenda status
```

## Options

| Option | Description |
|--------|-------------|
| `--external` | Focus on MCP/plugin/tool discovery |
| `--internal` | Focus on token efficiency analysis |
| `--topic="X"` | Research specific topic immediately |
| `add "X"` | Add topic to research agenda |
| `status` | Show current agenda |

## Output

- Research reports in `.claude/reports/research/`
- Evolution proposals (require approval)
- SOTA catalog updates
- Agenda status updates

## Examples

```
# Full R&D cycle
/research

# Just check for new MCPs
/research --external

# Analyze file usage efficiency
/research --internal

# Research specific tool
/research --topic="playwright-mcp"

# Add user topic
/research add "Consider caching layer"
```
```

---

## 6. Configuration

### autonomy-config.yaml Settings

```yaml
components:
  AC-07-rd:
    enabled: true
    settings:
      # Research scope
      external_research: true
      internal_research: true

      # Scheduling
      external_scan_interval: monthly
      internal_scan_interval: weekly

      # Limits
      max_topics_per_cycle: 5
      max_token_budget: 20000

      # Classification defaults
      default_classification: defer  # Conservative
      require_approval_for_all: true

      # Sources
      scan_awesome_mcp: true
      scan_plugins_registry: true
      scan_anthropic_releases: true

      # Internal tracking
      track_file_usage: true
      redundancy_threshold: 0.8  # 80% similarity = duplicate

      # Output
      generate_reports: true
      update_sota_catalog: true
```

---

## 7. Examples

### External Discovery Cycle

```
/research --external

Jarvis: "Starting external R&D cycle...

Scanning sources:
- awesome-mcp: 3 new entries since last scan
- claude-code-plugins: 1 new entry
- Anthropic: No new releases

Filtering for relevance...
- xyz-mcp: Potentially relevant (scheduling capability)
- abc-plugin: Not relevant (duplicates existing)
- def-mcp: Not relevant (wrong domain)

Deep analysis: xyz-mcp
[Using deep-research agent]

Analysis complete.

## xyz-mcp

**Classification**: ADOPT

**Rationale**:
- Fills scheduling capability gap
- Low context cost (~500 tokens)
- Active maintenance, stable API
- Clear integration path

**Proposal Created**: EVO-2026-01-015
- Requires your approval to implement
- See: .claude/reports/research/xyz-mcp-analysis.md

Approve integration? [y/n]"
```

### Internal Efficiency Cycle

```
/research --internal

Jarvis: "Starting internal R&D cycle...

Analyzing file usage patterns...
- High-use: 5 files (loaded every session)
- Medium-use: 12 files
- Low-use: 8 files
- Never-used: 3 files

Checking for redundancy...
- Found: 2 duplicate sections
  - CLAUDE.md and reference/quick-start.md share 80% content
  - Two pattern files have identical examples

Context budget analysis...
- Average session: 45% at start
- Patterns account for 15%
- MCPs account for 20%

## Findings

1. **Duplicate Content**
   - CLAUDE.md/quick-start.md overlap
   - Recommendation: Reference instead of duplicate

2. **Unused Files**
   - archive/old-pattern.md (0 reads in 30 days)
   - Recommendation: Move to archive

3. **Context Optimization**
   - 3 pattern files rarely needed
   - Recommendation: Load on-demand

**Proposals Created**: 3
- EVO-2026-01-016: Consolidate CLAUDE.md overlap
- EVO-2026-01-017: Archive unused files
- EVO-2026-01-018: On-demand pattern loading

All require approval. Review? [y/n]"
```

---

*R&D Cycles Pattern — Jarvis Phase 6 PR-12.7*
