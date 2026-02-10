---
name: knowledge-ops
model: opus
version: 2.1.0
description: >
  4-tier memory hierarchy — dynamic KG, static KG, semantic RAG, documentary grounding.
  Use when: memory, remember, knowledge graph, reflect, lotus, obsidian, RAG, recall.
replaces: memory MCP (shadow), lotus-wisdom MCP
---

## 4-Tier Memory Architecture

Each tier serves a distinct purpose. None is a "fallback" — choose by need.

### Tier 1: Short-Term / Working Memory (Dynamic KG)
*Quick store-and-recall of session facts, entities, relations.*

| Operation | Method |
|-----------|--------|
| Search entities | `ToolSearch "+memory"` → `mcp__memory__search_nodes(query)` |
| Read full graph | `mcp__memory__read_graph()` |
| Create entities | `mcp__memory__create_entities([{name, entityType, observations}])` |
| Add observations | `mcp__memory__add_observations([{entityName, contents}])` |
| Create relations | `mcp__memory__create_relations([{from, to, relationType}])` |
| Open specific nodes | `mcp__memory__open_nodes([names])` |

**Scope**: Session-scoped (Memory MCP, 9 tools). Not persisted across restarts.

### Tier 2: Long-Term Memory (Static KG / Files)
*Persistent facts, gotchas, patterns that survive across sessions.*

| Store | Path | Method |
|-------|------|--------|
| Global memory | `~/.claude/projects/.../memory/MEMORY.md` | Read/Edit (auto-loaded) |
| Topic files | `~/.claude/projects/.../memory/*.md` | Read/Edit (linked from MEMORY.md) |
| Session state | `.claude/context/session-state.md` | Read/Edit |
| Compaction essentials | `.claude/context/compaction-essentials.md` | Read (survives /clear) |
| Patterns (51) | `.claude/context/patterns/*.md` | Read/Glob |

**Scope**: Persistent, file-based. Survives sessions, restarts, and compaction.

### Tier 3: Intuitive Recollection (Semantic RAG)
*Vector similarity search over ingested documents.*

| Operation | Method |
|-----------|--------|
| Query documents | `ToolSearch "+local-rag"` → `query_documents(query)` |
| Ingest file | `ingest_file(path)` |
| Ingest text | `ingest_data(content, metadata)` |
| List indexed files | `list_files()` |
| Check status | `status()` |

**Scope**: local-rag MCP (retained, server-dependent). Persistent embeddings.

### Tier 4: Documentary Grounding (Static Reference)
*Authoritative source files — designs, plans, configs, identity.*

| Document | Path |
|----------|------|
| Identity | `.claude/context/psyche/jarvis-identity.md` |
| Architecture | `.claude/context/psyche/_index.md` |
| AC components | `.claude/context/components/orchestration-overview.md` |
| JICM design | `.claude/context/designs/jicm-v5-design-addendum.md` |
| Pipeline design | `.claude/plans/pipeline-design-v3.md` |
| Capability map | `.claude/context/psyche/capability-map.yaml` |

**Scope**: Read-only reference. Use `Read`, `Glob`, `Grep`.

## Search Approaches

```
What do I need to know?
├── "What did I just learn?" → Tier 1: search_nodes (dynamic KG)
├── "What do I always need to know?" → Tier 2: MEMORY.md + topic files
├── "What document discusses X?" → Tier 3: local-rag query_documents
├── "What is the authoritative design?" → Tier 4: Read specific file
├── Multiple approaches (broad recall):
│   ├── Sequential: Tier 1 → Tier 2 → Tier 3 (widen until found)
│   └── Targeted: Pick tier by knowledge type, search directly
```

## Lotus Wisdom (AC-05/06)

| Pattern | Use | Invocation |
|---------|-----|------------|
| examine | Analyze decision/outcome | `/reflect` |
| reflect | End-of-session assessment | `/reflect` |
| verify | Validate assumptions | `/self-improve` |
| transform | Change behavior from learning | `/evolve` |
| integrate | Combine cross-session insights | `/self-improve` |

## Knowledge Lifecycle Management

*Inspired by memory-palace (claude-night-market). See `.claude/context/research/night-market-memory-palace-deep-dive.md`.*

### Maturity Stages

Knowledge items in Tier 2 (patterns, gotchas, topic files) progress through three stages:

| Stage | Criteria | Action |
|-------|----------|--------|
| **Seedling** | New, untested, single-session origin | Tag `maturity: seedling` in frontmatter |
| **Growing** | Used in 3+ sessions, validated once | Promote to `maturity: growing` |
| **Evergreen** | Battle-tested, referenced in decisions | Promote to `maturity: evergreen` |

**Progression Rules**:
- Seedlings unused for 30 days → archive to `.claude/context/archive/`
- Growing items unused for 60 days → demote to seedling
- Evergreen items are never auto-pruned (manual review only)
- Promotion tracked via Memory MCP observations or `last_accessed` metadata

### Automated Pruning

| Cadence | Target | Action |
|---------|--------|--------|
| Weekly | Patterns with `maturity: seedling` | Flag if unused >30 days |
| Monthly | All Tier 2 files | Archive files with no Read/Grep hits in 60 days |
| Quarterly | Archive directory | Delete archived items older than 90 days |

**Pruning is reversible**: Items move to `.claude/context/archive/` before deletion.
Dead links detected via Grep cross-reference are flagged in maintenance reports.

### Knowledge Capture Extensions

| Source | Captured Data | Storage |
|--------|--------------|---------|
| PR reviews | Decisions, recurring patterns, quality standards, lessons | `.claude/context/review-chamber/` |
| Skill execution | Success/failure rate, mean duration, stability | Telemetry + AC-05 evolution |
| Session reflections | Behavioral changes, self-corrections | Memory MCP + MEMORY.md |

**Status**: Design phase. Implementation tracked in tool-reconstruction-backlog.md.

## Future Integrations

| Backend | Target | Status |
|---------|--------|--------|
| Obsidian vault | Tier 2 (Read/Glob on vault) | Planned |
| Chroma (vector DB) | Tier 3 (replaces local-rag) | Planned (Docker) |
| Graphiti (Neo4j) | Tier 1 (graph DB KG) | Deferred (Neo4j needed) |
| Cognee | Tier 3 (RAG + KG pipeline) | Evaluate |
| claude-context (zilliztech) | Tier 3 (semantic code search) | Planned |
| ultrarag (openbmb) | Tier 3 (RAG pipeline patterns) | Study |
| claude-code-docs (ericbuess) | Tier 4 (reference docs) | Install or ingest |
