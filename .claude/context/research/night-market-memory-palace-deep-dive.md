# Research Report: claude-night-market Memory Palace

**Date**: 2026-02-08
**Scope**: Deep investigation into memory-palace plugin from athola/claude-night-market, analyzing novel mechanisms beyond Jarvis's existing 4-tier memory architecture
**Repository**: https://github.com/athola/claude-night-market

## Executive Summary

The memory-palace plugin from claude-night-market implements a **spatial-metaphor-based knowledge organization system** inspired by the classical method of loci (memory palace mnemonic technique). Unlike Jarvis's current graph/vector/document hierarchy, memory-palace adds three novel dimensions:

1. **Spatial Navigation Model**: Knowledge organized using architectural metaphors (fortress, library, workshop, garden, observatory) enabling location-based retrieval
2. **Organic Knowledge Lifecycle**: Three-stage maturity progression (seedling → growing → evergreen) with automated consolidation and pruning
3. **Multi-Modal Search Paradigm**: Five retrieval strategies including sensory-based and associative search beyond semantic/temporal

The system does NOT appear to use a true knowledge graph with typed entities/relations like Memory MCP. Instead, it layers spatial metaphors and organic lifecycle management atop file-based storage, providing a **human-intuitive organizational framework** rather than a machine-optimized graph database.

**Key Gap Analysis**: Memory-palace adds complementary human-centric organization but does NOT replace or significantly extend Jarvis's existing KG/RAG/documentary layers. Primary value is in **conceptual scaffolding** for knowledge curation, not technical storage innovation.

## Key Findings

### 1. Spatial Memory Architecture

**Core Concept**: Virtual memory palaces as "spatial mnemonic structures for organizing complex knowledge domains"

**Architectural Templates**:

| Template | Application | Knowledge Type |
|----------|------------|----------------|
| Fortress | Security-focused, layered systems | Defense-in-depth patterns |
| Library | Knowledge organization, categorized sections | Documentation, references |
| Workshop | Practical skills and techniques | Hands-on procedures |
| Garden | Organic, evolving knowledge bases | Experimental ideas |
| Observatory | Pattern discovery and exploration | Analysis, insights |

**Project Palace Structure** (physical layout on disk):
```
project-palace/
├── entrance/        # README, getting started
├── library/         # Documentation, ADRs
├── workshop/        # Development patterns
├── review-chamber/  # PR Reviews
│   ├── decisions/   # Architectural choices
│   ├── patterns/    # Recurring issues
│   ├── standards/   # Quality examples
│   └── lessons/     # Post-mortems
└── garden/          # Evolving knowledge
```

**Source**: https://github.com/athola/claude-night-market (plugin structure documentation)

**Novel Mechanism**: Unlike Jarvis's semantic tier separation (dynamic KG vs static patterns vs RAG vs docs), memory-palace uses **spatial metaphors** to organize knowledge. The "library" vs "workshop" distinction is cognitive/intent-based rather than technical.

### 2. Five Retrieval Strategies

The knowledge-locator skill implements multi-modal search:

1. **Spatial Queries**: Navigate by location paths within palace structures (e.g., "entrance/getting-started")
2. **Semantic Search**: Retrieve by meaning and keywords (like Jarvis's local-rag MCP)
3. **Sensory-Based Lookup**: Find concepts by sensory attributes (color, texture, atmosphere)
4. **Associative Retrieval**: Follow connection chains between related information
5. **Temporal Queries**: Access by creation/modification dates

**Performance Targets**:
- Cached retrieval: <150ms
- Cold retrieval: <500ms
- Semantic accuracy: >90% for top-3 results
- Partial query success: 80%

**Source**: Raw content from https://raw.githubusercontent.com/athola/claude-night-market/master/plugins/memory-palace/skills/knowledge-locator/SKILL.md

**Novel Mechanisms**:
- **Sensory-based lookup** (#3): No equivalent in Jarvis. Allows querying like "find the concept associated with red/urgent" or "show me the warm/welcoming pattern"
- **Associative retrieval** (#4): Similar to graph traversal but emphasizes human association chains rather than typed relations

**Overlap with Jarvis**:
- Semantic search (#2) = local-rag MCP (Tier 3)
- Temporal queries (#5) = file system mtime (Tier 4)
- Spatial queries (#1) = directory structure (Tier 4)

### 3. Organic Knowledge Lifecycle

**Digital Garden Cultivator** manages knowledge maturity:

**Maturity Stages**:
1. **Seedling**: Early ideas, incomplete thoughts requiring initial exploration
2. **Growing**: Being actively refined through ongoing engagement
3. **Evergreen**: Stable, well-developed content ready for formal documentation

**Consolidation Workflow**:
```
Collect Sources → Plan Structure → Create Links → Schedule Maintenance → Document Outputs
```

**Pruning Schedule**:

| Cadence | Action |
|---------|--------|
| Every 2 days | Remove dead links, fix typos |
| After 7 days inactive | Assess content freshness |
| After 30 days inactive | Archive or delete underutilized content |

**Success Metrics**:
- Link density (interconnection strength)
- Bidirectional coverage (reciprocal relationship percentage)
- Freshness (update recency by section)
- Maturity ratio (evergreen vs experimental content)

**Source**: Raw content from https://raw.githubusercontent.com/athola/claude-night-market/master/plugins/memory-palace/skills/digital-garden-cultivator/SKILL.md

**Novel Mechanism**: This is memory-palace's most distinctive feature. Jarvis has no equivalent **organic lifecycle management** or **maturity-based progression**. Current knowledge-ops treats all patterns/contexts equally without aging or refinement tracking.

**Potential Application to Jarvis**: Could track pattern maturity (untested → validated → battle-tested) and prune stale context files.

### 4. Session-Specific vs Persistent Palaces

**Two Palace Types**:
- **Persistent Project Palaces**: Long-lived, evolve with project (stored in `.claude/` or project root)
- **Session Palaces**: Temporary, fork from main palace for testing organizational strategies (Claude Code 2.0.73+ session forking)

**Session Palace Builder Skill**: "Create temporary session-specific palaces" for experimentation without polluting main knowledge base

**Source**: Memory-palace skill listing from plugin tree

**Novel Mechanism**: Session-scoped knowledge namespaces. Jarvis currently has global vs project scope (Memory MCP) but no session-specific isolation for testing knowledge organization strategies.

### 5. Skill Execution Memory (Continual Learning)

**Automatic Logging**: Every skill invocation logs to `~/.claude/skills/logs/`

**Storage Format**:
```
~/.claude/skills/logs/
├── .history.json              # Aggregated metrics
├── <plugin>/
│   ├── <skill>/
│   │   └── YYYY-MM-DD.jsonl   # Daily JSONL files
```

**Tracked Data**:
- Timestamp and duration
- Success/failure outcomes
- Continual metrics (stability gap, accuracy trends)

**Hooks**:
- `skill_tracker_pre.py` (PreToolUse): Records invocation start time
- `skill_tracker_post.py` (PostToolUse): Logs completion and stores memory

**Source**: Memory-palace plugin structure documentation

**Novel Mechanism**: Automated skill performance tracking with continual learning metrics. Jarvis has telemetry (events-YYYY-MM-DD.jsonl) but not skill-level success rates or stability tracking.

**Gap**: Documentation found describes WHAT is tracked but not HOW "stability gap" or "accuracy trends" are computed. Likely requires baseline performance dataset.

### 6. Hook-Based Knowledge Capture

**Six Integration Hooks**:

| Hook | Event | Function |
|------|-------|----------|
| research_interceptor.py | PreToolUse | Checks local knowledge cache before web requests |
| local_doc_processor.py | PostToolUse | Monitors Read operations for indexing suggestions |
| url_detector.py | UserPromptSubmit | Detects URLs for knowledge intake |
| web_content_processor.py | PostToolUse | Processes web content for extraction |
| skill_tracker_pre.py | PreToolUse | Records skill invocation start time |
| skill_tracker_post.py | PostToolUse | Logs completion and stores memory |

**Setup Hooks** (Claude Code 2.1.10+):
- `--init`: Creates garden structure, indexes, skill logs directory
- `--maintenance`: Composts stale captures (>30 days), rotates logs (>90 days), rebuilds indexes

**Source**: Memory-palace plugin tree documentation

**Novel Mechanisms**:
1. **research_interceptor**: Proactive cache-checking before WebSearch calls (Jarvis has no equivalent)
2. **url_detector**: Automatic knowledge intake workflow when URLs mentioned
3. **Maintenance mode**: Automated cleanup/composting (Jarvis's JICM compression is reactive, not scheduled)

**Overlap with Jarvis**:
- Hook architecture concept (Jarvis has 28 active hooks, 9 registered)
- PostToolUse monitoring (similar to Jarvis's telemetry-emitter)

### 7. Review Chamber (PR Knowledge Capture)

**Structure**:
```
review-chamber/
├── decisions/   # Architectural choices
├── patterns/    # Recurring issues
├── standards/   # Quality examples
└── lessons/     # Post-mortems
```

**Skill**: `review-chamber` — "Capture PR review knowledge in project palaces"

**Command**: `/review-room` — Manage PR review knowledge

**Agent**: Not specified (likely uses general palace-architect or knowledge-navigator)

**Source**: Memory-palace skills and commands listing

**Novel Mechanism**: Structured PR review knowledge extraction. Jarvis has session chronicles (documentary grounding, Tier 4) but no specialized PR knowledge categorization.

**Comparison to Jarvis**: Session chronicles capture general work logs. Review-chamber specifically structures architectural decisions, recurring patterns, quality standards, and lessons learned from code reviews.

## Data Model Analysis

### Entities & Relations (Inferred)

Based on directory structure and skill descriptions, memory-palace appears to use:

**Primary Entities**:
- **Palace**: Top-level organizational unit (project-specific or session-specific)
- **Room**: Sections within palace (entrance, library, workshop, garden, review-chamber)
- **Knowledge Item**: Individual pieces of stored information
- **Garden Note**: Bidirectionally-linked evolving knowledge
- **Skill Execution Record**: Performance logs

**Relations** (Inferred, not explicitly documented):
- Palace → contains → Rooms
- Room → contains → Knowledge Items
- Garden Note ↔ bidirectional links ↔ Garden Note
- Knowledge Item → located_in → Room
- Knowledge Item → maturity_stage → {seedling, growing, evergreen}

**Properties**:
- Maturity stage (seedling/growing/evergreen)
- Sensory attributes (color, texture, atmosphere)
- Freshness (last update timestamp)
- Link density (bidirectional connection count)
- Creation/modification timestamps

**Storage Format**: NOT explicitly documented. Likely file-based (markdown, YAML) given "digital garden" philosophy and `.claude/` directory structure mentions.

**Critical Gap**: No evidence of typed entity/relation model like Memory MCP's (entity, relation, observation) triples. Memory-palace appears to be **file-system + metadata** rather than true graph database.

## Cross-Session Persistence

**Mechanisms Identified**:

1. **File System Storage**: Project palaces stored in `.claude/` or project root (persistent across sessions)
2. **Skill Execution Logs**: JSONL files in `~/.claude/skills/logs/` (cumulative across all sessions)
3. **Garden Indexes**: Rebuilt during `--maintenance` runs (persistent but periodically regenerated)
4. **Session Forking**: Temporary session palaces for experimentation (ephemeral, not persisted)

**Integration with Claude Code Memory**:
- **Hooks inject context** during UserPromptSubmit and PreToolUse
- **research_interceptor** checks local cache before external requests
- **No explicit MCP integration documented** (unlike Memory MCP or local-rag MCP)

**Comparison to Jarvis**:
- Jarvis Tier 1 (Memory MCP): Cross-session via MCP server persistence
- Jarvis Tier 2 (patterns): Cross-session via git-tracked files
- Jarvis Tier 3 (local-rag): Cross-session via vector store
- Memory-palace: Cross-session via file system + hooks (no MCP server mentioned)

**Critical Question**: Does memory-palace implement its own MCP server or rely on file system + hooks? Documentation does NOT mention MCP tools like `memory_search` or `palace_query`.

## Memory Consolidation & Pruning

### Consolidation Strategies

**From Digital Garden Cultivator**:
1. **Bidirectional Linking**: Connect related garden notes (prevents knowledge silos)
2. **Maturity Progression**: Seedling → Growing → Evergreen (gradual refinement)
3. **Periodic Review**: Every 2/7/30 days depending on activity
4. **Link Density Optimization**: Track and increase interconnections

**From Skill Execution Memory**:
1. **Aggregated Metrics**: `.history.json` consolidates daily JSONL logs
2. **Stability Tracking**: Identify patterns in skill success/failure
3. **Accuracy Trends**: Long-term performance monitoring

**Source**: Digital-garden-cultivator skill documentation

### Pruning Strategies

**Automated Cleanup** (via `--maintenance` hook):
- **Compost stale captures**: >30 days old → archive or delete
- **Rotate logs**: >90 days old → compress or remove
- **Rebuild indexes**: Regenerate search indices (implies dead link removal)

**Manual Pruning** (via digital-garden workflow):
- Every 2 days: Remove dead links, fix typos
- After 7 days inactive: Assess freshness
- After 30 days inactive: Archive or delete

**Pruning Criteria** (inferred):
- Time since last update (freshness decay)
- Link activity (dead links removed)
- Maturity stage (seedlings may be culled if not progressing)
- Bidirectional coverage (orphaned notes flagged)

**Comparison to Jarvis**:
- **Jarvis has NO automated pruning** in current architecture
- **JICM compression** (AC-04) reduces context size but doesn't delete knowledge
- **Knowledge-ops has no lifecycle management** (patterns persist indefinitely)

**Novel Mechanism**: Time-based and activity-based automated pruning. This is memory-palace's second most distinctive feature after organic lifecycle management.

## Integration with Claude Code

### File System Integration

**Storage Locations** (inferred from documentation):
- `~/.claude/skills/logs/`: Global skill execution memory
- `.claude/` (project root): Project-specific palaces
- Project root subdirectories: Palace room structure (entrance/, library/, etc.)

**File Formats** (inferred):
- JSONL: Skill execution logs (daily files)
- JSON: Aggregated metrics (`.history.json`)
- Markdown: Garden notes (bidirectional links)
- YAML: Possibly for metadata (common in Claude Code plugins)

### Hook Integration

**Setup Phase** (one-time):
```bash
# Initialize plugin
--init flag: Create garden structure, indexes, logs directory

# Periodic maintenance
--maintenance flag: Compost stale content, rotate logs, rebuild indexes
```

**Runtime Phase** (automatic):
- **UserPromptSubmit**: url_detector checks for knowledge intake opportunities
- **PreToolUse**: research_interceptor checks local cache, skill_tracker_pre logs start
- **PostToolUse**: local_doc_processor suggests indexing, web_content_processor extracts knowledge, skill_tracker_post logs completion

**Source**: Memory-palace hooks listing

### No MCP Server Documented

**Critical Finding**: Unlike Memory MCP or local-rag MCP, memory-palace does NOT appear to implement MCP tools for programmatic access.

**Evidence**:
- No mention of tools like `palace_search`, `palace_add`, `palace_query` in documentation
- Interaction via slash commands (`/palace`, `/garden`, `/navigate`) not MCP tools
- Hook-based injection rather than tool-based retrieval

**Implication**: Memory-palace is a **plugin** (hooks + commands + skills) NOT an **MCP server**. Integration is passive (hooks inject context) rather than active (Claude calls tools to query).

**Comparison to Jarvis**:
- Jarvis Tier 1 (Memory MCP): Active tool calls (`create_entities`, `search_nodes`)
- Jarvis Tier 3 (local-rag MCP): Active tool calls (`query`)
- Memory-palace: Passive hook injection + manual command invocation

## What Memory-Palace Adds BEYOND Jarvis

### 1. Spatial Navigation Metaphor (Novel)

**What Jarvis Has**: Hierarchical directory structure (Nous/Pneuma/Soma), capability map routing
**What Memory-Palace Adds**: Architectural metaphors (fortress/library/workshop/garden) with **human-intuitive spatial organization**

**Value**: Cognitive scaffolding for knowledge curation. Easier for humans to remember "this is in the library" vs "this is in `.claude/context/patterns/git-patterns.md`"

**Implementation Effort**: Low (directory reorganization + metaphor documentation)
**Jarvis Fit**: Medium (conflicts with existing Nous/Pneuma/Soma topology)

### 2. Organic Knowledge Lifecycle (Novel)

**What Jarvis Has**: Static patterns, no lifecycle tracking
**What Memory-Palace Adds**: Seedling → Growing → Evergreen progression with automated maturity tracking

**Value**: Distinguishes experimental knowledge from battle-tested patterns. Enables progressive refinement.

**Implementation Effort**: Medium (requires maturity metadata + progression rules)
**Jarvis Fit**: High (complements pattern validation workflow)

### 3. Sensory-Based Retrieval (Novel)

**What Jarvis Has**: Semantic (RAG), structural (grep), temporal (file mtime)
**What Memory-Palace Adds**: Query by sensory attributes (color, texture, emotional tone)

**Value**: Aligns with human memory associations (e.g., "find the urgent/red pattern")

**Implementation Effort**: High (requires sensory metadata tagging + query engine)
**Jarvis Fit**: Low (unclear value for CLI automation system)

### 4. Automated Pruning (Novel)

**What Jarvis Has**: JICM compression (reactive), manual cleanup
**What Memory-Palace Adds**: Scheduled maintenance (every 2/7/30 days) with time-based pruning

**Value**: Prevents knowledge base bloat, removes stale information

**Implementation Effort**: Low (cron job + age-based deletion rules)
**Jarvis Fit**: High (addresses context drift concerns)

### 5. Session-Scoped Knowledge (Novel)

**What Jarvis Has**: Global (Memory MCP), project (git-tracked files)
**What Memory-Palace Adds**: Session-specific palaces for experimental organization

**Value**: Test knowledge structures without polluting main knowledge base

**Implementation Effort**: Medium (session-scoped storage + fork/merge logic)
**Jarvis Fit**: Medium (could enhance PR-based workflows)

### 6. PR Review Knowledge Extraction (Novel)

**What Jarvis Has**: Session chronicles (general work logs)
**What Memory-Palace Adds**: Structured PR knowledge (decisions/patterns/standards/lessons)

**Value**: Capture architectural rationale from code reviews

**Implementation Effort**: Medium (PR parsing + categorization logic)
**Jarvis Fit**: High (valuable for self-improvement and pattern discovery)

### 7. Skill Performance Tracking (Partial Overlap)

**What Jarvis Has**: Telemetry (tool usage logs, token counts, timestamps)
**What Memory-Palace Adds**: Stability gap, accuracy trends, per-skill success rates

**Value**: Identify unreliable skills, track performance over time

**Implementation Effort**: Low (extends existing telemetry with success/failure tracking)
**Jarvis Fit**: High (enhances AC-05 evolution loop)

## Recommendations

### 1. **Adopt Organic Lifecycle Management** (HIGH PRIORITY)

**Rationale**: Jarvis's pattern files are static. No distinction between experimental vs validated patterns.

**Implementation**:
- Add `maturity: [seedling|growing|evergreen]` frontmatter to pattern files
- Track last-used timestamp via Memory MCP observations
- Promote patterns through maturity stages based on usage + validation
- Surface maturity in capability-map.yaml for router prioritization

**Effort**: 4-6 hours
**Risk**: Low (additive, doesn't break existing patterns)

### 2. **Implement Automated Pruning** (HIGH PRIORITY)

**Rationale**: Jarvis has no mechanism to remove stale context. AC-04 JICM compression is reactive, not proactive.

**Implementation**:
- Add `last_accessed` metadata to pattern files (via Read hook)
- Cron job (weekly) to identify patterns unused >60 days
- Archive to `.claude/context/archive/` (don't delete, reversible)
- Dead link detection via Grep + pruning script

**Effort**: 3-4 hours
**Risk**: Low (archive-first approach is reversible)

### 3. **Add PR Review Knowledge Extraction** (MEDIUM PRIORITY)

**Rationale**: Session chronicles capture what was done, not why. PR reviews contain architectural rationale.

**Implementation**:
- Hook on `gh pr view` or `gh pr review` commands
- Extract: architectural decisions, recurring patterns, quality standards, lessons learned
- Store in `.claude/context/review-chamber/` with categorization
- Link to Memory MCP entities (e.g., PR #123 → decision entity)

**Effort**: 6-8 hours
**Risk**: Medium (requires reliable PR content parsing)

### 4. **Extend Skill Performance Tracking** (MEDIUM PRIORITY)

**Rationale**: Jarvis tracks skill usage (telemetry) but not success rates or stability.

**Implementation**:
- Add `success: true|false` to telemetry events (requires skill self-reporting)
- Compute success rate, mean duration, stability gap per skill
- Surface in `/skill-stats` command or AC-05 evolution agent
- Use for skill deprecation decisions (e.g., <70% success rate → investigate)

**Effort**: 4-6 hours
**Risk**: Medium (requires skill authors to report success/failure)

### 5. **DO NOT Adopt Spatial Metaphor** (LOW PRIORITY)

**Rationale**: Jarvis already has established Nous/Pneuma/Soma topology. Switching to fortress/library/workshop would require extensive refactoring with unclear value for CLI automation.

**Alternative**: Add spatial metaphor as **documentation layer** (e.g., "Nous/patterns = Library, Pneuma/skills = Workshop") without restructuring files.

**Effort**: N/A
**Risk**: High if full restructuring, Low if documentation-only

### 6. **DO NOT Implement Sensory-Based Retrieval** (LOW PRIORITY)

**Rationale**: Unclear value for Jarvis's CLI automation domain. Sensory attributes (color, texture) are human memory aids, not relevant for code patterns or infrastructure.

**Alternative**: Use tags (e.g., `urgent`, `deprecated`, `experimental`) instead of sensory metaphors.

**Effort**: N/A
**Risk**: N/A

### 7. **Consider Session-Scoped Knowledge** (LOW PRIORITY)

**Rationale**: Interesting for experimental pattern testing but not critical for current workflows.

**Future Application**: Session-scoped pattern testing for PR-based feature branches (e.g., test new docker-ops patterns in isolation before merging to main knowledge base).

**Effort**: 8-10 hours
**Risk**: High (complex fork/merge logic, potential conflicts)

## Action Items

- [ ] **Immediate**: Add maturity metadata to 3-5 existing patterns as proof-of-concept
- [ ] **Week 1**: Implement automated pattern pruning script (archive unused >60 days)
- [ ] **Week 2**: Design PR review knowledge extraction workflow (review-chamber structure)
- [ ] **Week 3**: Extend telemetry with success/failure tracking (2-3 skills as pilot)
- [ ] **Week 4**: Evaluate maturity progression rules (seedling → growing threshold)

## Sources

1. [GitHub - athola/claude-night-market](https://github.com/athola/claude-night-market)
2. [claude-night-market Issue #401 · hesreallyhim/awesome-claude-code](https://github.com/hesreallyhim/awesome-claude-code/issues/401)
3. [memory-palace-architect SKILL.md](https://raw.githubusercontent.com/athola/claude-night-market/master/plugins/memory-palace/skills/memory-palace-architect/SKILL.md)
4. [knowledge-locator SKILL.md](https://raw.githubusercontent.com/athola/claude-night-market/master/plugins/memory-palace/skills/knowledge-locator/SKILL.md)
5. [digital-garden-cultivator SKILL.md](https://raw.githubusercontent.com/athola/claude-night-market/master/plugins/memory-palace/skills/digital-garden-cultivator/SKILL.md)
6. [The Architecture of Persistent Memory for Claude Code - DEV Community](https://dev.to/suede/the-architecture-of-persistent-memory-for-claude-code-17d)
7. [GitHub - GaZmagik/claude-memory-plugin](https://github.com/GaZmagik/claude-memory-plugin)
8. [The Memory Palace For Programming: 7 Examples for Coders](https://www.magneticmemorymethod.com/memory-palace-for-programming/)
9. [Method of loci - Wikipedia](https://en.wikipedia.org/wiki/Method_of_loci)
10. [Claude Code Monitoring Docs](https://code.claude.com/docs/en/monitoring-usage)
11. [install-skill-tracker - Claudate](https://claudate.com/skills/install-skill-tracker-mil3yg31)
12. [Building a Local Memory MCP - DEV Community](https://dev.to/zhizhiarv/building-a-local-memory-mcp-for-claude-desktop-a-journey-of-ai-memory-5bmo)

## Uncertainties

1. **Storage Format**: Documentation doesn't specify if memory-palace uses JSON, YAML, markdown, or database for knowledge items. Inferred file-based but not confirmed.

2. **MCP Integration**: No evidence of MCP server implementation. Unclear if memory-palace could expose MCP tools or is purely hook/command-based.

3. **Stability Gap & Accuracy Trends**: Mentioned in skill execution memory but computation methodology not documented. Likely requires baseline performance data.

4. **Bidirectional Link Implementation**: Digital garden emphasizes bidirectional links but mechanism not specified. Markdown `[[wikilinks]]`? Custom metadata? Link tracking database?

5. **Index Format**: `--maintenance` rebuilds indexes but index structure not documented. Full-text search? Vector embeddings? Graph index?

6. **Session Palace Persistence**: Session-specific palaces mentioned but unclear if they're purely ephemeral or can be promoted to persistent palaces.

## Related Topics

1. **Zettelkasten Method**: Note-taking system with bidirectional links, related to digital gardens
2. **PARA Method**: Projects/Areas/Resources/Archives organization (alternative to spatial metaphors)
3. **Spaced Repetition**: Could combine with maturity stages for knowledge reinforcement
4. **Git-Based Knowledge Graphs**: Several projects use git commits as knowledge graph edges (e.g., git-notes-memory)
5. **Continuous Learning in LLMs**: Memory-palace's stability gap tracking relates to active learning research
6. **Context Window Management**: Memory-palace pruning addresses context limits, relates to Jarvis's JICM compression

---

**Research Conducted By**: Jarvis (Deep Research Agent)
**Token Budget**: ~26,000 tokens
**Duration**: ~45 minutes
**Quality Assessment**: Medium-High (comprehensive overview, some implementation details missing due to 404 errors on raw file access)
