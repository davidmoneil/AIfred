# Vestige Memory System Research

**Date**: 2026-02-05  
**Agent**: Deep Research  
**Repository**: https://github.com/samvallad33/vestige

## Key Findings

### What Vestige Provides
1. **FSRS-6 Spaced Repetition**: Power-law temporal decay (30% more efficient than traditional algorithms)
2. **Dual-Strength Memory**: Storage strength (encoding depth) vs retrieval strength (accessibility)
3. **Prediction Error Gating**: Automatic CREATE/UPDATE/SUPERSEDE decisions based on similarity
4. **Hybrid Search**: BM25 keyword + semantic embeddings + Reciprocal Rank Fusion
5. **Natural Forgetting**: Memories decay to Unavailable state (<10% retrievability) without manual pruning
6. **Synaptic Tagging**: Retroactive strengthening of memories within temporal window

### What Jarvis Currently Has
1. **JICM v5**: Intelligent context compression and restoration
2. **Memory MCP**: Knowledge graph (pending Docker enablement)
3. **Session State**: Manual file-based continuity
4. **Lessons System**: Categorical PRB/SOL/PAT tracking in markdown
5. **Corrections**: Linear self-correction log

### Critical Gaps
1. **No semantic search** across patterns/lessons/context
2. **No temporal decay** (all stored information equal weight)
3. **No retrieval strengthening** (static files don't learn from access patterns)
4. **No duplicate detection** (manual checking required)
5. **No cross-session memory persistence** beyond checkpoint/restore

### Recommended Integration Path

**Phase 1** (Immediate, 1-2 sessions):
- Enable Memory MCP (Docker Desktop setting)
- Install Vestige via Cargo build
- Configure per-project storage: `.vestige/vestige.db`

**Phase 2** (Core, 3-4 sessions):
- SQLite-based lessons storage with FTS5
- Integrate Vestige MCP for semantic search
- Create `/ingest-context` and `/search-memory` commands

**Phase 3** (Advanced, 8-12 sessions):
- Temporal decay for session state
- Duplicate detection for lessons
- Synaptic tagging integration

### Technical Details
- **Language**: Rust (74.4%), TypeScript (21.7%)
- **Database**: SQLite + FTS5 + HNSW vector index
- **Embeddings**: Nomic Embed Text v1.5 (768-dim, ~130MB)
- **Performance**: <200ms search for 10K memories
- **License**: MIT OR Apache-2.0 (compatible)
- **Status**: Active (v1.1.2, 2025-01-27)

### Risks
- Low: Mature codebase, active maintenance, pre-built binaries
- Medium: Token usage increase from richer context (monitor JICM)
- Medium: Duplicate memory systems (mitigate via clear separation)

### Decision
**Recommended**: Integrate Vestige as complementary semantic memory layer alongside Memory MCP (structured knowledge graph). Vestige handles temporal decay and semantic search; Memory MCP handles entities/relationships.

## Full Report
`/Users/aircannon/Claude/Jarvis/.claude/reports/research/vestige-analysis-2026-02-05.md` (948 lines)
