# SOTA Catalog Structure Specification

**ID**: PR-14.1
**Version**: 1.0.0
**Status**: implementing
**Created**: 2026-01-16
**Last Modified**: 2026-01-16

---

## Purpose

Define the schema, structure, and organization for a catalog of state-of-the-art (SOTA) open-source projects, tools, and patterns that inform Jarvis' R&D cycles and self-evolution. The catalog serves as the reference library for external innovation discovery.

---

## Architecture

```
+---------------------------------------------------------------------+
|                    SOTA CATALOG ARCHITECTURE                          |
+---------------------------------------------------------------------+
|                                                                       |
|  CATALOG STRUCTURE                                                    |
|  +-------------------------+                                          |
|  | projects/project-aion/  |                                          |
|  | sota-catalog/           |                                          |
|  |   +-- _index.yaml       |  <-- Master index                        |
|  |   +-- categories/       |  <-- Category definitions                |
|  |   +-- entries/          |  <-- Individual catalog entries          |
|  |   +-- comparisons/      |  <-- Comparison analyses                 |
|  |   +-- evaluations/      |  <-- Evaluation reports                  |
|  |   +-- research-queue/   |  <-- Pending research items              |
|  +-------------------------+                                          |
|                                                                       |
|  CONSUMERS                                                            |
|  +---------------+  +---------------+  +---------------+              |
|  | AC-07 R&D     |  | AC-06 Self-   |  | AC-05 Self-   |              |
|  | Cycles        |  | Evolution     |  | Reflection    |              |
|  +-------+-------+  +-------+-------+  +-------+-------+              |
|          |                  |                  |                       |
|          +------------------+------------------+                       |
|                             |                                          |
|                             v                                          |
|                    +----------------+                                  |
|                    | Evolution      |                                  |
|                    | Queue          |                                  |
|                    +----------------+                                  |
|                                                                       |
+---------------------------------------------------------------------+
```

---

## Catalog Location

```
projects/project-aion/sota-catalog/
+-- _index.yaml              # Master catalog index
+-- categories/
|   +-- mcp-servers.yaml     # MCP server category
|   +-- plugins.yaml         # Plugin category
|   +-- agent-frameworks.yaml # Agent framework category
|   +-- patterns.yaml        # Design pattern category
|   +-- tools.yaml           # Development tools category
|   +-- documentation.yaml   # Documentation/reference category
+-- entries/
|   +-- mcp/
|   |   +-- memory-server.yaml
|   |   +-- filesystem-server.yaml
|   |   +-- ...
|   +-- plugins/
|   |   +-- ralph-wiggum.yaml
|   |   +-- feature-dev.yaml
|   |   +-- ...
|   +-- frameworks/
|   |   +-- anthropic-agent-sdk.yaml
|   |   +-- ...
|   +-- patterns/
|   |   +-- agentic-patterns.yaml
|   |   +-- ...
|   +-- tools/
|   |   +-- ...
+-- comparisons/
|   +-- 2026-01-comparison-mcp.md
|   +-- ...
+-- evaluations/
|   +-- 2026-01-eval-memory-server.md
|   +-- ...
+-- research-queue/
    +-- pending.yaml
    +-- completed.yaml
```

---

## Schema Definitions

### Master Index Schema

```yaml
# _index.yaml
version: "1.0.0"
last_updated: "2026-01-16"
total_entries: 0
categories:
  - id: mcp-servers
    name: "MCP Servers"
    description: "Model Context Protocol server implementations"
    entry_count: 0
  - id: plugins
    name: "Claude Code Plugins"
    description: "Plugins for Claude Code"
    entry_count: 0
  # ... more categories

statistics:
  by_status:
    adopted: 0
    adapted: 0
    evaluating: 0
    deferred: 0
    rejected: 0
  by_relevance:
    high: 0
    medium: 0
    low: 0
  last_scan: null
  next_scheduled_scan: null
```

### Category Schema

```yaml
# categories/<category>.yaml
id: "mcp-servers"
name: "MCP Servers"
description: "Model Context Protocol server implementations"
created: "2026-01-16"
last_updated: "2026-01-16"

# Evaluation criteria specific to this category
evaluation_criteria:
  - name: "stability"
    weight: 0.25
    description: "How stable and maintained is the project?"
  - name: "utility"
    weight: 0.30
    description: "How useful is it for Jarvis operations?"
  - name: "integration_effort"
    weight: 0.20
    description: "How much effort to integrate?"
  - name: "context_cost"
    weight: 0.15
    description: "What is the context/token cost?"
  - name: "overlap"
    weight: 0.10
    description: "Does it overlap with existing tools?"

# Source lists for discovery
discovery_sources:
  - name: "awesome-mcp-servers"
    url: "https://github.com/punkpeye/awesome-mcp-servers"
    scan_frequency: "monthly"
  - name: "modelcontextprotocol-servers"
    url: "https://github.com/modelcontextprotocol/servers"
    scan_frequency: "weekly"

entries: []  # List of entry IDs in this category
```

### Catalog Entry Schema

```yaml
# entries/<category>/<entry>.yaml
id: "memory-server"
category: "mcp-servers"
name: "Memory MCP Server"
description: "Persistent memory storage for Claude using knowledge graph"
created: "2026-01-16"
last_updated: "2026-01-16"
last_evaluated: null

# Source information
source:
  repository: "https://github.com/modelcontextprotocol/servers"
  path: "src/memory"
  documentation: "https://github.com/modelcontextprotocol/servers/tree/main/src/memory"
  version: "0.6.2"
  license: "MIT"
  stars: null  # Optional GitHub stars
  last_commit: null  # Optional last commit date

# Relevance to Jarvis
relevance:
  level: "high"  # high | medium | low
  use_cases:
    - "Persistent storage of session learnings"
    - "Cross-session knowledge retention"
    - "Pattern and decision storage"
  gap_addressed: "Session-to-session memory continuity"

# Evaluation scores (0-100)
evaluation:
  stability: 85
  utility: 90
  integration_effort: 20  # Lower = easier
  context_cost: 10  # Lower = better
  overlap: 15  # Lower = less overlap
  overall_score: 82  # Weighted average

# Status tracking
status:
  current: "adopted"  # adopted | adapted | evaluating | deferred | rejected
  status_date: "2026-01-01"
  rationale: "Core MCP for Jarvis operations"
  jarvis_integration:
    installed: true
    version_installed: "0.6.2"
    config_location: "~/.claude/settings.json"
    usage_tier: 1  # Tier 1 = always-on

# Comparison notes
comparison:
  alternatives:
    - entry_id: "chroma-mcp"
      relationship: "complementary"
      notes: "Chroma for vector search, Memory for graph storage"
  advantages:
    - "Simple knowledge graph model"
    - "Low token overhead"
  disadvantages:
    - "Limited query capabilities"
    - "No vector similarity search"

# Research history
research_history:
  - date: "2026-01-01"
    action: "initial_evaluation"
    notes: "Evaluated during PR-5 tooling setup"
  - date: "2026-01-08"
    action: "integration_complete"
    notes: "Integrated as Tier 1 MCP"

# Tags for discovery
tags:
  - "memory"
  - "persistence"
  - "knowledge-graph"
  - "tier-1"
```

### Research Queue Schema

```yaml
# research-queue/pending.yaml
version: "1.0.0"
last_updated: "2026-01-16"

queue:
  - id: "research-001"
    source: "awesome-mcp-servers"
    item: "mcp-sqlite"
    category: "mcp-servers"
    priority: "medium"
    added_date: "2026-01-16"
    reason: "Structured data storage alternative"
    status: "pending"

  - id: "research-002"
    source: "user-request"
    item: "langchain-agents"
    category: "agent-frameworks"
    priority: "low"
    added_date: "2026-01-16"
    reason: "Compare agent patterns"
    status: "pending"

completed:
  - id: "research-000"
    item: "memory-server"
    completion_date: "2026-01-08"
    outcome: "adopted"
    entry_id: "memory-server"
```

---

## Categorization System

### Primary Categories

| Category ID | Name | Description |
|-------------|------|-------------|
| `mcp-servers` | MCP Servers | Model Context Protocol server implementations |
| `plugins` | Claude Code Plugins | Official and community plugins |
| `agent-frameworks` | Agent Frameworks | Agent SDK and framework implementations |
| `patterns` | Design Patterns | Agentic and architectural patterns |
| `tools` | Development Tools | Supporting development tools |
| `documentation` | Documentation | Reference documentation and guides |

### Status Classifications

| Status | Description | Action |
|--------|-------------|--------|
| `adopted` | Integrated into Jarvis | Maintain, monitor updates |
| `adapted` | Integrated with modifications | Track custom changes |
| `evaluating` | Currently under evaluation | Complete evaluation |
| `deferred` | Postponed for future consideration | Review periodically |
| `rejected` | Not suitable for Jarvis | Document rationale |

### Relevance Levels

| Level | Criteria | Priority |
|-------|----------|----------|
| `high` | Directly addresses Jarvis gap | Research immediately |
| `medium` | Potentially useful enhancement | Queue for research |
| `low` | Nice-to-have, no urgent need | Log for future |

---

## Evaluation Criteria

### Universal Criteria

All catalog entries are evaluated on these dimensions:

| Criterion | Weight | Description | Scoring |
|-----------|--------|-------------|---------|
| Stability | 0.25 | Maintenance, community, reliability | 0-100, higher = better |
| Utility | 0.30 | Value to Jarvis operations | 0-100, higher = better |
| Integration Effort | 0.20 | Implementation complexity | 0-100, lower = easier |
| Context Cost | 0.15 | Token/context budget impact | 0-100, lower = better |
| Overlap | 0.10 | Redundancy with existing tools | 0-100, lower = less overlap |

### Overall Score Calculation

```javascript
function calculateOverallScore(entry) {
  const weights = {
    stability: 0.25,
    utility: 0.30,
    integration_effort: 0.20,
    context_cost: 0.15,
    overlap: 0.10
  };

  // Invert scores where lower is better
  const scores = {
    stability: entry.evaluation.stability,
    utility: entry.evaluation.utility,
    integration_effort: 100 - entry.evaluation.integration_effort,
    context_cost: 100 - entry.evaluation.context_cost,
    overlap: 100 - entry.evaluation.overlap
  };

  let total = 0;
  for (const [criterion, weight] of Object.entries(weights)) {
    total += scores[criterion] * weight;
  }

  return Math.round(total);
}
```

### Category-Specific Criteria

Categories may define additional evaluation criteria:

**MCP Servers**:
- Tool count and quality
- API design consistency
- Error handling

**Plugins**:
- Feature completeness
- Documentation quality
- Maintenance activity

**Agent Frameworks**:
- Pattern applicability
- Extensibility
- Learning curve

---

## Discovery Sources

### Automated Scan Targets

| Source | URL | Category | Frequency |
|--------|-----|----------|-----------|
| awesome-mcp-servers | github.com/punkpeye/awesome-mcp-servers | mcp-servers | Monthly |
| modelcontextprotocol/servers | github.com/modelcontextprotocol/servers | mcp-servers | Weekly |
| Anthropic Plugins | github.com/anthropics/anthropic-tools | plugins | Weekly |
| claude-code-plugins | github.com/davidteren/claude-code-plugins | plugins | Monthly |
| Anthropic Cookbook | github.com/anthropics/anthropic-cookbook | patterns | Monthly |
| Agent Skills | github.com/anthropics/anthropic-agent-skills | agent-frameworks | Weekly |

### Manual Addition Sources

- User requests (`/research <topic>`)
- R&D cycle discoveries
- Maintenance freshness findings
- External recommendations

---

## Query Interface

### Catalog Queries

```yaml
# Query by category
query:
  type: "category"
  category: "mcp-servers"
  status: ["adopted", "evaluating"]

# Query by relevance
query:
  type: "relevance"
  level: "high"
  status: "evaluating"

# Query by tag
query:
  type: "tag"
  tags: ["memory", "persistence"]

# Query by score threshold
query:
  type: "score"
  min_score: 70
  status: "evaluating"
```

### Query Results Format

```yaml
results:
  count: 5
  query: {...}
  entries:
    - id: "memory-server"
      name: "Memory MCP Server"
      category: "mcp-servers"
      overall_score: 82
      status: "adopted"
    - ...
```

---

## Command Interface

### `/catalog` Command

```
Usage: /catalog [subcommand] [options]

Subcommands:
  list          List catalog entries
  show <id>     Show entry details
  search <term> Search entries
  stats         Show catalog statistics
  add <url>     Add entry to research queue
  evaluate <id> Trigger evaluation of entry

Options:
  --category=<cat>   Filter by category
  --status=<status>  Filter by status
  --relevance=<lvl>  Filter by relevance
  --format=<fmt>     Output format (yaml, table, brief)

Examples:
  /catalog list --category=mcp-servers
  /catalog show memory-server
  /catalog search "vector database"
  /catalog stats
  /catalog add https://github.com/example/tool
```

---

## Integration Points

### With R&D Cycles (AC-07)

```javascript
// R&D discovery uses catalog
async function discoverNewEntries(category) {
  const sources = await getCategorySources(category);
  for (const source of sources) {
    const newItems = await scanSource(source);
    for (const item of newItems) {
      if (!catalogContains(item)) {
        addToResearchQueue(item, category);
      }
    }
  }
}
```

### With Self-Evolution (AC-06)

```javascript
// Evolution proposals reference catalog
function createAdoptionProposal(entryId) {
  const entry = getCatalogEntry(entryId);
  return {
    type: "adoption",
    source: "catalog",
    entry_id: entryId,
    rationale: entry.relevance.gap_addressed,
    effort: entry.evaluation.integration_effort,
    require_approval: true  // Catalog adoptions always need approval
  };
}
```

### With Self-Reflection (AC-05)

```javascript
// Reflection can suggest catalog research
function reflectOnToolGaps() {
  const gaps = identifyCapabilityGaps();
  for (const gap of gaps) {
    const candidates = searchCatalog({
      type: "relevance",
      level: "high",
      tags: gap.tags
    });
    if (candidates.length > 0) {
      createResearchProposal(candidates[0]);
    }
  }
}
```

---

## Maintenance

### Freshness Checks

| Check | Frequency | Action |
|-------|-----------|--------|
| Entry last_updated | Monthly | Flag stale entries |
| Source version check | Weekly | Update version info |
| Link validation | Monthly | Fix broken links |
| Discovery scan | Per-category | Add new items to queue |

### Stale Entry Handling

```yaml
# Entry flagged as stale if:
stale_criteria:
  days_since_update: 90
  days_since_evaluation: 180
  source_unavailable: true

# Stale entry actions:
stale_actions:
  - notify: "Entry {id} is stale, requires re-evaluation"
  - queue: "Add to research queue for re-evaluation"
  - archive: "If source unavailable, archive entry"
```

---

## Implementation Files

| File | Purpose | Status |
|------|---------|--------|
| `projects/project-aion/sota-catalog/` | Catalog directory | planned |
| `projects/project-aion/sota-catalog/_index.yaml` | Master index | planned |
| `projects/project-aion/sota-catalog/categories/` | Category definitions | planned |
| `projects/project-aion/sota-catalog/entries/` | Catalog entries | planned |
| `.claude/commands/catalog.md` | Command definition | planned |
| `.claude/hooks/catalog-scanner.js` | Discovery scanner | planned |

---

## Validation Checklist

- [ ] Catalog directory structure created
- [ ] Master index schema implemented
- [ ] Category schemas defined
- [ ] Entry schema supports all fields
- [ ] Research queue functional
- [ ] `/catalog` command operational
- [ ] Integration with AC-07 R&D working
- [ ] Freshness checks implemented

---

*SOTA Catalog Structure -- PR-14.1 Specification*
