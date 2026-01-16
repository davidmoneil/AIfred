# SOTA Catalog Initial Population Specification

**ID**: PR-14.2
**Version**: 1.0.0
**Status**: implementing
**Created**: 2026-01-16
**Last Modified**: 2026-01-16

---

## Purpose

Define the initial population strategy for the SOTA catalog, including source inventories, prioritized entry lists, and population workflows. This specification ensures the catalog launches with a comprehensive baseline of 50+ entries across all categories.

---

## Population Strategy

```
+---------------------------------------------------------------------+
|                    INITIAL POPULATION WORKFLOW                        |
+---------------------------------------------------------------------+
|                                                                       |
|  PHASE 1: INVENTORY                                                   |
|  +-------------------+                                                |
|  | Roadmap Section 4 |  --> Extract all referenced projects          |
|  | Current MCPs      |  --> Document installed MCPs                   |
|  | Current Plugins   |  --> Document installed plugins                |
|  | Current Agents    |  --> Document custom agents                    |
|  +-------------------+                                                |
|            |                                                          |
|            v                                                          |
|  PHASE 2: CATEGORIZATION                                              |
|  +-------------------+                                                |
|  | Assign categories |  --> Place each item in category              |
|  | Determine status  |  --> adopted/evaluating/deferred              |
|  | Assess relevance  |  --> high/medium/low                          |
|  +-------------------+                                                |
|            |                                                          |
|            v                                                          |
|  PHASE 3: ENTRY CREATION                                              |
|  +-------------------+                                                |
|  | Create YAML files |  --> One entry per item                       |
|  | Populate metadata |  --> Source, evaluation, status               |
|  | Update indices    |  --> Category and master index                |
|  +-------------------+                                                |
|            |                                                          |
|            v                                                          |
|  PHASE 4: VALIDATION                                                  |
|  +-------------------+                                                |
|  | Link validation   |  --> All URLs accessible                      |
|  | Schema validation |  --> All entries conform to schema            |
|  | Coverage check    |  --> All sources inventoried                  |
|  +-------------------+                                                |
|                                                                       |
+---------------------------------------------------------------------+
```

---

## Source Inventories

### 1. Installed MCP Servers (Tier 1-3)

Currently installed MCPs from Jarvis configuration:

| MCP Server | Tier | Status | Priority |
|------------|------|--------|----------|
| memory | 1 | adopted | P0 |
| filesystem | 1 | adopted | P0 |
| fetch | 1 | adopted | P0 |
| git | 1 | adopted | P0 |
| datetime | 2 | adopted | P1 |
| github | 2 | adopted | P1 |
| context7 | 2 | adopted | P1 |
| desktop-commander | 2 | adopted | P1 |
| chroma | 2 | adopted | P2 |
| perplexity | 2 | adopted | P2 |
| gptresearcher | 2 | adopted | P2 |
| playwright | 3 | adopted | P2 |
| lotus-wisdom | 3 | adopted | P3 |

### 2. Installed Plugins

Currently installed plugins from Claude Code:

| Plugin | Category | Status | Priority |
|--------|----------|--------|----------|
| ralph-wiggum | workflow | adopted | P0 |
| feature-dev | workflow | adopted | P0 |
| pr-review-toolkit | code-review | adopted | P1 |
| hookify | automation | adopted | P1 |
| browser-automation | browser | adapted | P1 |
| document-skills | document | adopted | P1 |
| frontend-design | design | adopted | P2 |
| research-assistant | research | adopted | P2 |
| testing-tools | testing | adopted | P2 |
| git-workflow | git | adopted | P2 |
| code-quality | quality | adopted | P2 |
| api-builder | api | adopted | P2 |
| db-tools | database | adopted | P2 |
| devops-tools | devops | adopted | P2 |
| security-scanner | security | adopted | P2 |
| performance-tools | performance | adopted | P2 |

### 3. Custom Agents

Jarvis-defined custom agents:

| Agent | Purpose | Status | Priority |
|-------|---------|--------|----------|
| docker-deployer | Docker deployment | adopted | P1 |
| service-troubleshooter | Issue diagnosis | adopted | P1 |
| deep-research | Multi-source research | adopted | P0 |
| memory-bank-synchronizer | Doc sync | adopted | P1 |
| code-analyzer | Pre-implementation analysis | adopted | P1 |
| code-implementer | Code writing | adopted | P1 |
| code-tester | Testing + automation | adopted | P1 |

### 4. Roadmap Section 4 References

From `projects/project-aion/roadmap.md` Section 4 (Backlog):

#### 4.1 MCP Servers (Priority List)
- PostgreSQL MCP (database operations)
- MySQL MCP (database operations)
- SQLite MCP (local database)
- Notion MCP (documentation)
- Linear MCP (project management)
- Slack MCP (communication)
- Discord MCP (communication)

#### 4.2 Research Sources
- awesome-mcp-servers (GitHub)
- modelcontextprotocol/servers (GitHub)
- anthropic-cookbook (GitHub)
- anthropic-agent-skills (GitHub)
- claude-code-plugins registry

#### 4.3 Agent Frameworks
- Anthropic Agent SDK
- LangChain Agents
- AutoGPT patterns
- CrewAI patterns
- OpenAI Swarm patterns

#### 4.4 Pattern References
- Anthropic Agentic Design Patterns
- LangChain Deep Agents
- Multi-agent orchestration patterns
- Tool-use best practices

### 5. Extracted Skills

Skills extracted from plugins (PR-9.0):

| Skill | Source Plugin | Status | Priority |
|-------|---------------|--------|----------|
| docx | document-skills | adopted | P1 |
| xlsx | document-skills | adopted | P1 |
| pdf | document-skills | adopted | P1 |
| pptx | document-skills | adopted | P1 |
| mcp-builder | anthropic-tools | adopted | P1 |
| skill-creator | anthropic-tools | adopted | P1 |

---

## Category Assignments

### MCP Servers Category

```yaml
category: mcp-servers
total_planned: 20
entries:
  # Tier 1 (Always-On)
  - id: memory-server
    status: adopted
    tier: 1
  - id: filesystem-server
    status: adopted
    tier: 1
  - id: fetch-server
    status: adopted
    tier: 1
  - id: git-server
    status: adopted
    tier: 1

  # Tier 2 (Task-Scoped)
  - id: datetime-server
    status: adopted
    tier: 2
  - id: github-server
    status: adopted
    tier: 2
  - id: context7-server
    status: adopted
    tier: 2
  - id: desktop-commander
    status: adopted
    tier: 2
  - id: chroma-server
    status: adopted
    tier: 2
  - id: perplexity-server
    status: adopted
    tier: 2
  - id: gptresearcher-server
    status: adopted
    tier: 2

  # Tier 3 (On-Demand)
  - id: playwright-server
    status: adopted
    tier: 3
  - id: lotus-wisdom-server
    status: adopted
    tier: 3

  # Backlog (Evaluating/Deferred)
  - id: postgresql-server
    status: evaluating
    relevance: medium
  - id: mysql-server
    status: evaluating
    relevance: medium
  - id: sqlite-server
    status: evaluating
    relevance: high
  - id: notion-server
    status: deferred
    relevance: low
  - id: slack-server
    status: deferred
    relevance: low
```

### Plugins Category

```yaml
category: plugins
total_planned: 20
entries:
  # Workflow Plugins
  - id: ralph-wiggum
    status: adopted
    subcategory: workflow
  - id: feature-dev
    status: adopted
    subcategory: workflow

  # Development Plugins
  - id: pr-review-toolkit
    status: adopted
    subcategory: code-review
  - id: hookify
    status: adopted
    subcategory: automation
  - id: testing-tools
    status: adopted
    subcategory: testing
  - id: code-quality
    status: adopted
    subcategory: quality

  # Infrastructure Plugins
  - id: browser-automation
    status: adapted
    subcategory: browser
  - id: devops-tools
    status: adopted
    subcategory: devops
  - id: security-scanner
    status: adopted
    subcategory: security

  # Document Plugins
  - id: document-skills
    status: adopted
    subcategory: document
```

### Agent Frameworks Category

```yaml
category: agent-frameworks
total_planned: 10
entries:
  # Anthropic
  - id: anthropic-agent-sdk
    status: evaluating
    relevance: high
  - id: anthropic-agent-skills
    status: adopted
    relevance: high

  # External
  - id: langchain-agents
    status: deferred
    relevance: medium
  - id: autogpt-patterns
    status: deferred
    relevance: low
  - id: crewai-patterns
    status: evaluating
    relevance: medium
  - id: openai-swarm
    status: evaluating
    relevance: medium
```

### Patterns Category

```yaml
category: patterns
total_planned: 15
entries:
  # Agentic Patterns
  - id: anthropic-agentic-patterns
    status: adopted
    source: "anthropic-cookbook"
  - id: langchain-deep-agents
    status: adopted
    source: "langchain-ai"

  # Orchestration Patterns
  - id: multi-agent-orchestration
    status: evaluating
    source: "various"
  - id: tool-use-patterns
    status: adopted
    source: "anthropic-cookbook"

  # Context Management
  - id: context-window-patterns
    status: adopted
    source: "jarvis-internal"
  - id: jicm-pattern
    status: adopted
    source: "jarvis-internal"
```

### Documentation Category

```yaml
category: documentation
total_planned: 10
entries:
  - id: claude-code-docs
    status: adopted
    url: "https://docs.anthropic.com/claude-code"
  - id: mcp-specification
    status: adopted
    url: "https://modelcontextprotocol.io/spec"
  - id: claude-api-docs
    status: adopted
    url: "https://docs.anthropic.com/claude/reference"
  - id: anthropic-cookbook
    status: adopted
    url: "https://github.com/anthropics/anthropic-cookbook"
```

---

## Entry Templates

### MCP Server Entry Template

```yaml
id: "{server-name}"
category: "mcp-servers"
name: "{Server Display Name}"
description: "{One-line description}"
created: "2026-01-16"
last_updated: "2026-01-16"
last_evaluated: "2026-01-16"

source:
  repository: "https://github.com/{owner}/{repo}"
  path: "{path/to/server}"
  documentation: "{docs-url}"
  version: "{version}"
  license: "{license}"
  stars: null
  last_commit: null

relevance:
  level: "{high|medium|low}"
  use_cases:
    - "{use case 1}"
    - "{use case 2}"
  gap_addressed: "{capability gap}"

evaluation:
  stability: 0
  utility: 0
  integration_effort: 0
  context_cost: 0
  overlap: 0
  overall_score: 0

status:
  current: "{adopted|adapted|evaluating|deferred|rejected}"
  status_date: "2026-01-16"
  rationale: "{reason for status}"
  jarvis_integration:
    installed: false
    version_installed: null
    config_location: null
    usage_tier: null

comparison:
  alternatives: []
  advantages: []
  disadvantages: []

research_history:
  - date: "2026-01-16"
    action: "initial_entry"
    notes: "Added during initial catalog population"

tags: []
```

### Plugin Entry Template

```yaml
id: "{plugin-name}"
category: "plugins"
name: "{Plugin Display Name}"
description: "{One-line description}"
created: "2026-01-16"
last_updated: "2026-01-16"
last_evaluated: "2026-01-16"

source:
  registry: "{registry-name}"
  package: "{package-name}"
  documentation: "{docs-url}"
  version: "{version}"
  author: "{author}"

relevance:
  level: "{high|medium|low}"
  use_cases:
    - "{use case 1}"
  gap_addressed: "{capability gap}"

evaluation:
  stability: 0
  utility: 0
  integration_effort: 0
  context_cost: 0
  overlap: 0
  overall_score: 0

status:
  current: "{adopted|adapted|evaluating|deferred|rejected}"
  status_date: "2026-01-16"
  rationale: "{reason}"
  jarvis_integration:
    installed: false
    install_command: null

skills_extracted:
  - "{skill-name}"

tags: []
```

---

## Population Workflow

### Phase 1: Create Directory Structure

```bash
# Create catalog directories
mkdir -p projects/project-aion/sota-catalog/{categories,entries,comparisons,evaluations,research-queue}
mkdir -p projects/project-aion/sota-catalog/entries/{mcp,plugins,frameworks,patterns,tools,docs}
```

### Phase 2: Create Category Files

Create category definition files:
- `categories/mcp-servers.yaml`
- `categories/plugins.yaml`
- `categories/agent-frameworks.yaml`
- `categories/patterns.yaml`
- `categories/tools.yaml`
- `categories/documentation.yaml`

### Phase 3: Create Entry Files

Priority order for entry creation:

1. **P0 - Critical (Day 1)**:
   - Tier 1 MCPs (4 entries)
   - Core workflow plugins (2 entries)
   - Custom agents (7 entries)

2. **P1 - High Priority (Week 1)**:
   - Tier 2 MCPs (7 entries)
   - Development plugins (4 entries)
   - Extracted skills (6 entries)

3. **P2 - Standard (Week 2)**:
   - Tier 3 MCPs (2 entries)
   - Remaining plugins (10 entries)
   - Agent frameworks (6 entries)

4. **P3 - Backlog (Week 3)**:
   - Backlog MCPs (7 entries)
   - Pattern references (15 entries)
   - Documentation (10 entries)

### Phase 4: Create Master Index

```yaml
# _index.yaml
version: "1.0.0"
last_updated: "2026-01-16"
total_entries: 50+
categories:
  - id: mcp-servers
    entry_count: 20
  - id: plugins
    entry_count: 20
  - id: agent-frameworks
    entry_count: 10
  - id: patterns
    entry_count: 15
  - id: documentation
    entry_count: 10

statistics:
  by_status:
    adopted: 35
    adapted: 2
    evaluating: 8
    deferred: 5
    rejected: 0
  by_relevance:
    high: 20
    medium: 20
    low: 10
  last_scan: "2026-01-16"
  next_scheduled_scan: "2026-02-16"
```

---

## Validation Requirements

### Structural Validation

- [ ] All directories exist
- [ ] All category files created
- [ ] Master index complete
- [ ] Entry count matches index

### Content Validation

- [ ] All entries have required fields
- [ ] All URLs are valid and accessible
- [ ] All statuses are valid values
- [ ] All relevance levels assigned

### Coverage Validation

- [ ] All installed MCPs cataloged
- [ ] All installed plugins cataloged
- [ ] All custom agents cataloged
- [ ] All roadmap Section 4 items addressed

---

## Success Criteria

| Metric | Target |
|--------|--------|
| Total entries | 50+ |
| MCP entries | 15+ |
| Plugin entries | 15+ |
| Agent/Framework entries | 10+ |
| Pattern entries | 10+ |
| Entries with evaluations | 80% |
| Entries with valid URLs | 100% |

---

## Implementation Files

| File | Purpose | Status |
|------|---------|--------|
| `projects/project-aion/sota-catalog/_index.yaml` | Master index | planned |
| `projects/project-aion/sota-catalog/categories/*.yaml` | Category definitions | planned |
| `projects/project-aion/sota-catalog/entries/**/*.yaml` | Catalog entries | planned |
| `.claude/scripts/populate-catalog.sh` | Population script | planned |
| `.claude/scripts/validate-catalog.sh` | Validation script | planned |

---

*SOTA Catalog Initial Population -- PR-14.2 Specification*
