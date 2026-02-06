# Vestige Dynamic Memory System Analysis

**Research Date**: 2026-02-05  
**Repository**: https://github.com/samvallad33/vestige  
**Latest Version**: v1.1.2 (2025-01-27)  
**Researcher**: Jarvis Deep Research Agent

---

## Executive Summary

Vestige is a cognitive memory MCP server that implements neuroscience-informed memory management for Claude, featuring FSRS-6 spaced repetition, dual-strength memory models, and intelligent forgetting curves. Unlike traditional RAG systems that treat all memories equally, Vestige models memory as a dynamic cognitive system where accessibility naturally decays over time and strengthens through retrieval.

**Key Differentiators**:
- **Cognitive Science Foundation**: Built on 130+ years of memory research (Bjork & Bjork, Ebbinghaus, Tulving & Thomson)
- **Natural Forgetting**: FSRS-6 algorithm models realistic memory decay (not static storage)
- **Intelligent Deduplication**: Prediction Error Gating auto-detects CREATE/UPDATE/SUPERSEDE decisions
- **Local-First**: 100% offline operation after initial model download (~130MB)
- **Hybrid Search**: Combines BM25 keyword + semantic embeddings + Reciprocal Rank Fusion

**Repository Health**:
- 340+ stars, 27 forks
- Active maintenance (last release: 2025-01-27)
- Dual-licensed: MIT OR Apache-2.0
- Pre-built binaries for macOS (ARM/Intel), Linux, Windows
- Comprehensive documentation (FAQ, SCIENCE.md, STORAGE.md, CONFIGURATION.md)

**Comparison to Jarvis**: Vestige offers sophisticated memory decay and retrieval strength modeling that Jarvis currently lacks. Jarvis has strong session continuity and context management (JICM v5) but treats all stored information equally without temporal decay or retrieval-based strengthening.

---

## Repository Overview

### Technical Stack

| Component | Technology |
|-----------|------------|
| **Backend** | Rust (74.4% of codebase) |
| **Database** | SQLite with FTS5 full-text search |
| **Embeddings** | Nomic Embed Text v1.5 (768-dimensional vectors) |
| **Vector Search** | HNSW via USearch (20x faster than FAISS) |
| **MCP Server** | TypeScript/Node.js (21.7%) |
| **Desktop App** | Tauri (optional GUI) |
| **Embedding Library** | fastembed v5 (local inference) |

### Project Structure

```
vestige/
├── crates/              # Rust implementation modules
│   ├── core/           # Memory engine, FSRS-6, dual-strength model
│   ├── storage/        # SQLite persistence layer
│   ├── search/         # Hybrid search (BM25 + semantic)
│   └── mcp-server/     # Model Context Protocol integration
├── packages/           # TypeScript/Node.js components
│   └── vestige-mcp/    # MCP server wrapper
├── tests/e2e/          # End-to-end integration tests
├── docs/               # Comprehensive documentation
│   ├── FAQ.md          # 30+ common questions
│   ├── SCIENCE.md      # Cognitive science foundations
│   ├── STORAGE.md      # Database architecture
│   └── CONFIGURATION.md # CLI and integration setup
└── .github/workflows/  # CI/CD with automated releases
```

### Maintainer Activity

- **Author**: Sam Valladares (@samvallad33)
- **Commit Frequency**: 51 commits on main branch
- **Release Cadence**: 3 major versions in 3 days (v1.0.0 → v1.1.2)
- **Issue Response**: All 4 GitHub issues resolved in v1.1.1
- **Documentation Quality**: Exceptional (neuroscience citations, comprehensive FAQ)

---

## Architecture Analysis

### Core Components

#### 1. FSRS-6 Spaced Repetition Engine

**Algorithm**: Free Spaced Repetition Scheduler (FSRS-6)  
**Formula**: `R(t, S) = (1 + factor × t / S)^(-w₂₀)`

- **Power-law decay** (not exponential) based on 700M+ Anki review dataset
- **21 personalized parameters** optimize per-user behavior
- **30% more efficient** than traditional SM-2 algorithms
- **Retrievability probability** decays realistically over time

**Implementation**: Tracks each memory's retrieval probability and updates it on every access. Memories below 10% retrievability enter "Unavailable" state but remain in database.

#### 2. Dual-Strength Memory Model

Based on Bjork & Bjork (1992) "New Theory of Disuse":

| Strength Type | Behavior | Purpose |
|---------------|----------|---------|
| **Storage Strength** | Only increases, never decreases | How deeply encoded |
| **Retrieval Strength** | Decays over time, restored through recall | Current accessibility |

**Key Insight**: Well-learned information can become temporarily inaccessible. This separation explains why you "know" something but can't access it in the moment.

**Memory States** (based on combined accessibility score):

| State | Retrievability | Search Behavior |
|-------|----------------|-----------------|
| **Active** | ≥70% | Surfaces readily |
| **Dormant** | 40-70% | Surfaces with effort |
| **Silent** | 10-40% | Rarely surfaces |
| **Unavailable** | <10% | Effectively forgotten |

Accessibility formula: `50% retention + 30% retrieval_strength + 20% storage_strength`

#### 3. Prediction Error Gating

**Purpose**: Automatic duplicate detection and merge decisions  
**Mechanism**: Compares new content against existing memories using embedding similarity

| Similarity Score | Action | Rationale |
|-----------------|--------|-----------|
| **>0.92** | REINFORCE | Near-identical content strengthens existing memory |
| **0.75-0.92** | UPDATE | Related information merges with existing record |
| **<0.75** | CREATE | Novel content becomes new memory |

**Smart Ingest Flow**:
```
New Content → Generate Embedding → Compare to Existing
              ↓
         Similarity Check
              ↓
    ┌─────────┼─────────┐
    ↓         ↓         ↓
REINFORCE   UPDATE   CREATE
(boost)     (merge)  (new)
```

**Advantage**: Prevents memory bloat while maintaining knowledge coherence. No manual deduplication required.

#### 4. Hybrid Search Architecture

**Three-Stage Retrieval Pipeline**:

```
Query → Stage 1: Keyword (BM25) + Semantic (Vector)
         ↓
      Stage 2: Reciprocal Rank Fusion (RRF)
         ↓
      Stage 3: Reranking (+15-20% precision)
         ↓
      Results (filtered by retrieval strength)
```

**BM25 Keyword Search**:
- SQLite FTS5 full-text search
- Exact term matching with ranking
- Fast: <10ms for 10K memories

**Semantic Vector Search**:
- 768-dimensional embeddings (Nomic Embed Text v1.5)
- HNSW indexing via USearch
- Conceptual similarity matching

**Reciprocal Rank Fusion**:
- Combines keyword + semantic rankings
- No parameter tuning required
- Proven effective in information retrieval research

**Performance Characteristics**:
- 1,000 memories: <50ms search
- 10,000 memories: <200ms search
- 100,000 memories: <1 second search
- Memory usage: 10-30MB per 1,000 memories

#### 5. Neuroscience-Inspired Mechanisms

**Spreading Activation** (Collins & Loftus 1975):
- Semantically related memories surface during searches
- Example: "React hooks" → retrieves "useEffect", "useState" through embedding proximity
- No manual tagging required

**Synaptic Tagging & Capture** (Frey & Morris 1997):
- Retroactive strengthening of nearby memories
- Temporal window: 9 hours backward, 2 hours forward (configurable)
- Triggered by `importance()` function flagging

**Example**:
```javascript
// Flag important moment
importance(
  memory_id="auth-bug-fix",
  event_type="user_flag",
  hours_back=9,
  hours_forward=2
)
// All memories within ±9 hours strengthened retroactively
```

**Context-Dependent Retrieval** (Tulving & Thomson 1973):
- Encoding-specificity principle
- Memories learned in authentication work surface more readily during auth tasks
- Temporal, topical, and emotional context matching

**Testing Effect**:
- Every search strengthens matching memories
- Frequently accessed information becomes more accessible
- Automatic reinforcement without explicit user action

---

## Feature Inventory

### MCP Tools API

Vestige exposes 8 cognitive primitives through the Model Context Protocol:

| Tool | Description | Key Parameters |
|------|-------------|----------------|
| **search** | Unified keyword + semantic + hybrid search | `query`, `limit`, `context` |
| **smart_ingest** | Intelligent ingestion with duplicate detection | `content`, `tags`, `importance` |
| **ingest** | Simple memory storage (no dedup) | `content`, `tags` |
| **memory** | State management operations | `get`, `delete`, `check_exists` |
| **codebase** | Architectural patterns and decisions | `pattern`, `file_path` |
| **intention** | Future reminders and triggers | `reminder`, `trigger_condition` |
| **promote_memory** | Mark memory as helpful (strengthens) | `memory_id` |
| **demote_memory** | Mark memory as wrong (weakens) | `memory_id` |

### Storage Backend

**Database**: SQLite with platform-specific locations

| Platform | Default Path |
|----------|--------------|
| macOS | `~/Library/Application Support/com.vestige.core/vestige.db` |
| Linux | `~/.local/share/vestige/core/vestige.db` |
| Windows | `%APPDATA%\vestige\core\vestige.db` |

**Schema** (simplified):
```sql
CREATE TABLE knowledge_nodes (
  id INTEGER PRIMARY KEY,
  content TEXT NOT NULL,
  embedding BLOB,  -- 768-dim vector
  storage_strength REAL,
  retrieval_strength REAL,
  retention REAL,  -- FSRS-6 retrievability
  tags TEXT,
  created_at TIMESTAMP,
  last_accessed TIMESTAMP
);

-- FTS5 virtual table for keyword search
CREATE VIRTUAL TABLE knowledge_fts USING fts5(content);

-- HNSW vector index for semantic search (via USearch)
```

**Storage Modes**:

1. **Global Memory** (default): Single database across all projects
2. **Per-Project Memory**: Separate databases via `--data-dir` flag
3. **Multi-Claude**: Multiple agents with distinct memory spaces

**Backup & Restore**:
```bash
vestige backup --output ~/vestige-backup-2026-02-05.db
vestige restore ~/vestige-backup-2026-02-05.db
```

### CLI Management Commands

| Command | Purpose |
|---------|---------|
| `vestige stats` | Memory statistics overview |
| `vestige stats --tagging` | Retention distribution by state |
| `vestige stats --states` | Cognitive state breakdown |
| `vestige health` | System health check |
| `vestige consolidate` | Memory maintenance (prune, optimize) |
| `vestige restore <file>` | Restore from backup |
| `vestige-mcp --version` | Check installed version |

### Configuration Options

**Environment Variables**:
```bash
export VESTIGE_DATA_DIR="/custom/path"
export VESTIGE_LOG_LEVEL="debug"
export FASTEMBED_CACHE_PATH="/custom/cache"
```

**MCP Integration** (Claude Code):
```json
{
  "mcpServers": {
    "vestige": {
      "command": "vestige-mcp",
      "args": ["--data-dir", "/project/.vestige"]
    }
  }
}
```

---

## Comparison to Jarvis

### Current Jarvis Memory Systems

| System | Location | Purpose | Limitations |
|--------|----------|---------|-------------|
| **Memory MCP** | Knowledge graph (pending Docker) | Entities, relationships, decisions | Not enabled; no temporal decay |
| **Session State** | `.claude/context/session-state.md` | Session continuity | Manual updates; no search |
| **Lessons** | `.claude/context/lessons/` | PRB/SOL/PAT tracking | Categorical only; no semantic search |
| **Corrections** | `.claude/context/lessons/corrections.md` | Self-correction log | Linear list; no retrieval ranking |
| **JICM v5** | Intelligent context compression | Token management | Context-focused, not memory-focused |

### Gap Analysis

| Feature | Vestige | Jarvis | Gap Severity |
|---------|---------|--------|--------------|
| **Temporal Decay** | FSRS-6 power-law | None (static files) | HIGH |
| **Retrieval Strengthening** | Automatic on access | None | HIGH |
| **Semantic Search** | Hybrid BM25+vector | None | HIGH |
| **Duplicate Detection** | Prediction Error Gating | Manual | MEDIUM |
| **Memory States** | 4 states (Active/Dormant/Silent/Unavailable) | Binary (stored/not stored) | MEDIUM |
| **Context-Dependent Retrieval** | Temporal + topical matching | Session-based only | MEDIUM |
| **Synaptic Tagging** | Retroactive strengthening | None | LOW (nice-to-have) |
| **Storage Backend** | SQLite with vector index | Flat files | HIGH |
| **Cross-Session Memory** | Automatic persistence | Manual checkpoint/restore | HIGH |

### Jarvis Advantages

| Capability | Jarvis | Vestige |
|------------|--------|---------|
| **Context Management** | JICM v5 with intelligent compression | No context window management |
| **Session Continuity** | Automatic restoration after `/clear` | N/A (different scope) |
| **Git Integration** | Full version control of lessons/state | No versioning |
| **Autonomic Components** | 9 AC systems (self-launch, self-reflect, etc.) | Memory-only (no autonomy) |
| **Multi-Agent Orchestration** | TodoWrite + agents | Single-purpose MCP server |
| **Hook Ecosystem** | 30+ hooks for lifecycle events | N/A |

---

## Key Innovations

### 1. Natural Forgetting as a Feature

**Traditional RAG Problem**: All information has equal weight forever  
**Vestige Solution**: FSRS-6 models realistic memory decay

- Unused memories naturally fade to "Unavailable" state
- Prevents memory bloat without manual pruning
- Recent and frequently accessed information prioritized

**Analogy**: Human memory doesn't store everything equally—neither should AI memory.

### 2. Prediction Error Gating

**Traditional Problem**: Duplicate information clutters memory  
**Vestige Solution**: Automatic similarity-based merge decisions

- No "did I already save this?" cognitive overhead
- UPDATE vs CREATE decisions handled algorithmically
- Maintains knowledge coherence without manual intervention

### 3. Testing Effect Automation

**Traditional Problem**: Important memories require manual reinforcement  
**Vestige Solution**: Every search strengthens matching memories

- Frequently queried information becomes more accessible
- Mimics human memory consolidation through retrieval practice
- Zero user effort required

### 4. Synaptic Tagging & Capture

**Traditional Problem**: Realizing importance retroactively requires manual backfill  
**Vestige Solution**: Flag importance now, strengthen past memories automatically

- Models biological memory consolidation
- Temporal window captures related memories
- Example: "That authentication discussion 6 hours ago turned out to be critical"

### 5. Dual-Strength Model

**Traditional Problem**: Binary "stored/forgotten" model is unrealistic  
**Vestige Solution**: Separate storage strength (encoding depth) from retrieval strength (accessibility)

- Explains tip-of-tongue phenomena
- Guides retrieval algorithms (surface high-retrieval memories first)
- Matches cognitive psychology research

---

## Implementation Recommendations

### Priority 1: Immediate Value (Low Effort, High Impact)

#### A. Enable Memory MCP in Jarvis

**Current State**: Memory MCP documented but not enabled  
**Action**: Enable Docker Desktop MCP integration  
**Effort**: 15 minutes  
**Value**: Unlock knowledge graph for entities/relationships

**Steps**:
1. Docker Desktop → Settings → Enable MCP
2. Restart Docker Desktop
3. Test with simple entity creation
4. Update `.claude/context/integrations/memory-usage.md` to "Active"

**Why Now**: Jarvis already has Memory MCP infrastructure designed; just needs activation.

---

### Priority 2: Core Memory Foundations (Medium Effort, High Impact)

#### B. SQLite-Based Lessons Storage

**Current State**: Lessons stored in flat markdown files  
**Vestige Inspiration**: SQLite with FTS5 for full-text search

**Implementation Plan**:

**Phase 1: Schema Design**
```sql
CREATE TABLE lessons (
  id INTEGER PRIMARY KEY,
  type TEXT CHECK(type IN ('PRB', 'SOL', 'PAT', 'EVO')),
  date TEXT,
  summary TEXT,
  content TEXT,
  status TEXT,
  frequency TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE VIRTUAL TABLE lessons_fts USING fts5(summary, content);

CREATE INDEX idx_lessons_type ON lessons(type);
CREATE INDEX idx_lessons_date ON lessons(date);
```

**Phase 2: Migration Script**
- Parse existing `.claude/context/lessons/*.md` files
- Extract PRB/SOL/PAT/EVO entries
- Populate SQLite database
- Archive original files

**Phase 3: Query Interface**
- `/search-lessons "<query>"` command
- Full-text search across summaries and content
- Filter by type, date range, status

**Effort**: 2-3 sessions  
**Dependencies**: None  
**Risk**: Low (reversible, keep markdown backups)

---

#### C. Semantic Search for Context Files

**Current State**: No search capability for patterns, lessons, designs  
**Vestige Inspiration**: Hybrid BM25 + semantic vector search

**Implementation Plan**:

**Option 1: Integrate Vestige Directly**
- Install Vestige MCP alongside Memory MCP
- Configure per-project storage: `--data-dir ./.vestige`
- Ingest key context files during session start
- Use `vestige search` for pattern/lesson retrieval

**Option 2: Build Custom Search MCP**
- Create `jarvis-search-mcp` server
- Use fastembed for local embeddings
- SQLite with FTS5 + vector extension
- Index `.claude/context/` directory

**Recommendation**: Option 1 (Integrate Vestige)  
**Reasoning**: Leverage mature, well-tested system; avoid reinventing wheel

**Effort**: 1-2 sessions (integration + testing)  
**Dependencies**: Rust/Cargo installed  
**Risk**: Low (non-invasive addition)

---

### Priority 3: Advanced Memory Features (High Effort, Medium-High Impact)

#### D. Temporal Decay for Session State

**Current State**: Session state file never expires  
**Vestige Inspiration**: FSRS-6 temporal decay

**Implementation Plan**:

**Phase 1: State Scoring**
- Add `last_accessed`, `access_count`, `importance` metadata to session-state.md
- Calculate "relevance score" based on recency and frequency
- Annotate entries with scores

**Phase 2: Automatic Archival**
- Completed tasks >30 days old → move to archive section
- Blockers resolved >60 days ago → remove
- Implement `/archive-old-state` command

**Phase 3: FSRS-Lite Algorithm**
- Simplified power-law decay for state relevance
- No need for full 21-parameter FSRS-6
- Focus on recency and access frequency

**Effort**: 3-4 sessions  
**Dependencies**: None  
**Risk**: Medium (requires careful testing to avoid data loss)

---

#### E. Duplicate Detection for Lessons

**Current State**: Manual checking required when creating lessons  
**Vestige Inspiration**: Prediction Error Gating with similarity thresholds

**Implementation Plan**:

**Phase 1: Embedding Generation**
- Generate embeddings for all existing lessons
- Store in SQLite (from Recommendation B)
- Use fastembed or Vestige's embedding model

**Phase 2: Similarity Check on Insert**
- New lesson → generate embedding
- Compare to existing lessons
- If similarity >0.85: suggest merge instead of create

**Phase 3: Merge UI**
- Present similar lessons to user
- Offer "Merge", "Keep Separate", or "Update Existing"
- Automated merge for >0.95 similarity (near-duplicate)

**Effort**: 3-4 sessions  
**Dependencies**: Recommendation B (SQLite storage), embeddings infrastructure  
**Risk**: Medium (requires UX design for merge workflow)

---

### Priority 4: Experimental Features (High Effort, Medium Impact)

#### F. Synaptic Tagging for Session Memory

**Current State**: No retroactive strengthening  
**Vestige Inspiration**: Synaptic tagging temporal window

**Use Case**: "That debug session 5 hours ago turned out to solve today's bug"

**Implementation Plan**:

**Phase 1: Timestamped Session Log**
- Enhanced session-state.md with precise timestamps
- Every decision/action gets timestamp
- Structured format for parsing

**Phase 2: Importance Flagging**
- `/flag-important <time_range>` command
- Example: `/flag-important last_6_hours`
- Marks all entries in window as "high importance"

**Phase 3: JICM Integration**
- Important flagged content prioritized during compression
- Survives `/clear` cycles more reliably
- Higher weight in preservation manifest

**Effort**: 4-5 sessions  
**Dependencies**: Enhanced session state tracking  
**Risk**: Medium (JICM integration requires careful testing)

---

#### G. Context-Dependent Memory Retrieval

**Current State**: No context matching beyond current session  
**Vestige Inspiration**: Tulving & Thomson encoding-specificity

**Use Case**: Working on authentication → surface past auth-related lessons automatically

**Implementation Plan**:

**Phase 1: Context Detection**
- Analyze current work (files, commands, patterns)
- Extract topics/domains (e.g., "authentication", "docker", "JICM")
- Store in session metadata

**Phase 2: Contextual Search**
- Search lessons/patterns filtered by current context
- Weight recent + contextually-relevant higher
- Automatic at session start and major context shifts

**Phase 3: Proactive Suggestions**
- "You're working on X; here are 3 relevant past lessons"
- Hook into PreToolUse or UserPromptSubmit
- Non-intrusive suggestions in skill loading

**Effort**: 5-6 sessions  
**Dependencies**: Recommendation C (semantic search), topic extraction  
**Risk**: High (requires sophisticated context analysis)

---

## Implementation Roadmap

### Phase 1: Foundation (Weeks 1-2)

| Task | Effort | Priority | Dependencies |
|------|--------|----------|--------------|
| Enable Memory MCP | 1 session | P1-A | None |
| SQLite Lessons Storage | 3 sessions | P2-B | None |
| Integrate Vestige MCP | 2 sessions | P2-C | Rust/Cargo |

**Milestone**: Jarvis has searchable lessons and basic semantic memory.

---

### Phase 2: Core Memory (Weeks 3-4)

| Task | Effort | Priority | Dependencies |
|------|--------|----------|--------------|
| Temporal Decay for Session State | 4 sessions | P3-D | Phase 1 |
| Duplicate Detection for Lessons | 4 sessions | P3-E | P2-B, P2-C |

**Milestone**: Jarvis automatically manages memory lifecycle with decay and deduplication.

---

### Phase 3: Advanced Features (Weeks 5-8)

| Task | Effort | Priority | Dependencies |
|------|--------|----------|--------------|
| Synaptic Tagging for Session Memory | 5 sessions | P4-F | Phase 2 |
| Context-Dependent Retrieval | 6 sessions | P4-G | P2-C, topic extraction |

**Milestone**: Jarvis has cognitive-science-informed memory with retroactive strengthening and context awareness.

---

## Detailed Implementation: Vestige Integration (P2-C)

### Step-by-Step Plan

#### Session 1: Installation & Setup

**Tasks**:
1. Install Rust/Cargo if not present: `curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh`
2. Clone Vestige: `git clone https://github.com/samvallad33/vestige ~/vestige`
3. Build: `cd ~/vestige && cargo build --release`
4. Install binary: `sudo cp target/release/vestige-mcp /usr/local/bin/`
5. Verify: `vestige-mcp --version`

**Validation**: Version output shows v1.1.2 or later

---

#### Session 2: Claude Code Integration

**Tasks**:
1. Configure per-project Vestige storage:
```json
// .claude/settings.local.json
{
  "mcpServers": {
    "vestige": {
      "command": "vestige-mcp",
      "args": ["--data-dir", "/Users/aircannon/Claude/Jarvis/.vestige"]
    }
  }
}
```

2. Restart Claude Code to load MCP server
3. Test basic operations:
   - `vestige ingest "Test memory: Jarvis uses Vestige for semantic search"`
   - `vestige search "semantic search"`
4. Verify SQLite database created: `ls -lh .vestige/vestige.db`

**Validation**: Search returns ingested test memory

---

#### Session 3: Context Ingestion Strategy

**Tasks**:
1. Create `/ingest-context` command:
   - Reads key files from `.claude/context/patterns/`, `.claude/context/lessons/`
   - Ingests each pattern/lesson with appropriate tags
   - Uses `smart_ingest` to avoid duplicates

2. Example ingestion:
```javascript
// Pseudo-code for ingest-context.md command
patterns = glob(".claude/context/patterns/*.md")
for pattern in patterns:
  content = read(pattern)
  vestige.smart_ingest({
    content: content,
    tags: ["pattern", extract_pattern_id(pattern)],
    importance: "high"
  })
```

3. Test ingestion: `/ingest-context`
4. Verify with stats: `vestige stats`

**Validation**: All patterns/lessons ingested, stats show correct count

---

#### Session 4: Search Integration

**Tasks**:
1. Create `/search-memory` command:
   - Takes query string
   - Calls `vestige search` with appropriate parameters
   - Formats results for readability

2. Create skill trigger: "search memory for" → loads search-memory skill
3. Test searches:
   - "search memory for context management patterns"
   - "search memory for JICM"
   - "search memory for bash scripting lessons"

4. Update `capability-matrix.md` with Vestige search capability

**Validation**: Searches return relevant patterns/lessons ranked by relevance

---

#### Session 5: Session Start Integration

**Tasks**:
1. Update `.claude/hooks/session-start.sh`:
   - Add Vestige context retrieval
   - Search for recent high-importance memories
   - Include in session start context injection

2. Test session start:
   - Exit and restart Claude Code session
   - Verify Vestige memories surface in initial context

3. Document integration in `.claude/context/integrations/vestige-integration.md`

**Validation**: Fresh session automatically includes relevant past context from Vestige

---

### Integration Architecture Diagram

```
┌─────────────────────────────────────────────────────────┐
│ Claude Code Session                                     │
│                                                           │
│  ┌──────────────┐     ┌──────────────┐                  │
│  │ Jarvis Agent │────▶│ Memory MCP   │ (Knowledge Graph)│
│  │              │     └──────────────┘                  │
│  │              │                                         │
│  │              │     ┌──────────────┐                  │
│  │              │────▶│ Vestige MCP  │ (Semantic Memory)│
│  │              │     └──────────────┘                  │
│  │              │            │                            │
│  │              │            ▼                            │
│  │              │     ┌──────────────┐                  │
│  │              │     │  SQLite DB   │                  │
│  │              │     │  + Vectors   │                  │
│  └──────────────┘     └──────────────┘                  │
│         │                                                 │
│         ▼                                                 │
│  ┌──────────────────────────────────────┐               │
│  │ .claude/context/                     │               │
│  │  ├── session-state.md (temporal)     │               │
│  │  ├── lessons/ (categorical)          │               │
│  │  └── patterns/ (reference)           │               │
│  └──────────────────────────────────────┘               │
└─────────────────────────────────────────────────────────┘
```

**Memory Hierarchy**:
1. **Vestige**: Semantic search, temporal decay, cross-session persistence
2. **Memory MCP**: Structured entities/relationships, knowledge graph
3. **Context Files**: Session continuity, immediate reference

---

## Risks and Considerations

### Technical Risks

| Risk | Severity | Mitigation |
|------|----------|------------|
| **Rust build failures** | Medium | Pre-built binaries available for macOS/Linux |
| **Embedding model size** | Low | 130MB one-time download, cached locally |
| **SQLite corruption** | Low | Regular backups via `vestige backup` |
| **MCP server crashes** | Low | Mature codebase, active maintenance |
| **Token usage increase** | Medium | Vestige results add context; monitor usage |

### Integration Risks

| Risk | Severity | Mitigation |
|------|----------|------------|
| **Duplicate memory systems** | Medium | Clear separation: Vestige=semantic, Memory MCP=graph |
| **JICM conflict** | Low | Vestige complements JICM (different scope) |
| **Session start slowdown** | Low | Vestige search <200ms for 10K memories |
| **Context file drift** | Medium | Periodic re-ingestion; Vestige doesn't replace files |

### Philosophical Risks

| Risk | Severity | Consideration |
|------|----------|---------------|
| **Over-reliance on automated memory** | Low | Jarvis still maintains explicit documentation |
| **Loss of manual curation** | Low | Vestige augments, doesn't replace human judgment |
| **Forgetting critical information** | Medium | Important memories manually promoted; regular review |

### Dependency Risks

| Risk | Severity | Mitigation |
|------|----------|------------|
| **Vestige project abandonment** | Low | Active development; can fork if needed |
| **Breaking changes in updates** | Low | Pin to specific version; test before upgrading |
| **License compatibility** | None | MIT OR Apache-2.0 fully compatible |

---

## Alternatives Considered

### 1. Build Custom Memory System

**Pros**:
- Full control over features
- Perfect integration with Jarvis architecture
- No external dependencies

**Cons**:
- High implementation effort (8-12 weeks)
- Requires expertise in vector search, FSRS algorithms
- Maintenance burden
- Reinventing well-tested wheel

**Decision**: Rejected. Vestige already implements desired features.

---

### 2. Use Traditional Vector Database (Pinecone, Weaviate)

**Pros**:
- Mature ecosystems
- Excellent search performance
- Rich querying capabilities

**Cons**:
- No temporal decay (static storage)
- No FSRS-6 spaced repetition
- No automatic duplicate detection
- Cloud-based (not local-first)
- Subscription costs for hosted versions

**Decision**: Rejected. Missing cognitive science features that make Vestige valuable.

---

### 3. Anthropic's Native Claude Memory

**Pros**:
- Official Anthropic feature
- Zero setup required
- Cross-device synchronization

**Cons**:
- Cloud-based (privacy concerns)
- No local control or customization
- Not available in Claude Code (as of 2026-02-05)
- No FSRS-6 or cognitive science features
- Limited to Anthropic's roadmap

**Decision**: Rejected. Not available in Claude Code; Vestige provides more control.

---

### 4. File-Based Embeddings (Local RAG)

**Pros**:
- Simple architecture
- Full control
- No database required

**Cons**:
- No temporal decay
- No duplicate detection
- No retrieval strengthening
- Manual maintenance required
- Limited search sophistication

**Decision**: Rejected. Lacks dynamic memory features.

---

## Conclusion

Vestige represents a significant advancement in AI memory systems by applying cognitive science principles to information retrieval and storage. Its FSRS-6 temporal decay, dual-strength memory model, and prediction error gating address fundamental limitations in traditional RAG systems.

**For Jarvis**, integrating Vestige would provide:
1. **Semantic search** across patterns, lessons, and context
2. **Natural forgetting** to prevent information overload
3. **Automatic deduplication** for lessons and memories
4. **Cross-session persistence** with intelligent retrieval

**Recommended Approach**: Phased integration starting with P1-A (Enable Memory MCP) and P2-C (Integrate Vestige), allowing Jarvis to leverage both structured knowledge graphs (Memory MCP) and semantic memory (Vestige) in complementary ways.

**Next Steps**:
1. Enable Memory MCP in Docker Desktop (15 minutes)
2. Install Vestige and configure per-project storage (1 session)
3. Create `/ingest-context` and `/search-memory` commands (2 sessions)
4. Integrate with session start for automatic context retrieval (1 session)

**Estimated Total Effort**: 4-5 sessions for core integration, 8-12 sessions for full feature parity.

---

## References

### Primary Sources
1. [Vestige GitHub Repository](https://github.com/samvallad33/vestige) - Main project repository
2. [Vestige README](https://github.com/samvallad33/vestige/blob/main/README.md) - Feature overview
3. [Vestige SCIENCE.md](https://github.com/samvallad33/vestige/blob/main/docs/SCIENCE.md) - Cognitive science foundations
4. [Vestige STORAGE.md](https://github.com/samvallad33/vestige/blob/main/docs/STORAGE.md) - Architecture details
5. [Vestige CONFIGURATION.md](https://github.com/samvallad33/vestige/blob/main/docs/CONFIGURATION.md) - Setup guide
6. [Vestige FAQ](https://github.com/samvallad33/vestige/blob/main/docs/FAQ.md) - 30+ common questions
7. [Vestige CHANGELOG](https://github.com/samvallad33/vestige/blob/main/CHANGELOG.md) - Version history

### Related Research
8. [Model Context Protocol Specification](https://modelcontextprotocol.io/specification/2025-06-18/server/tools) - MCP standard
9. [FSRS-6 Algorithm](https://github.com/open-spaced-repetition/fsrs4anki) - Spaced repetition research
10. Bjork, R. A., & Bjork, E. L. (1992). A new theory of disuse and an old theory of stimulus fluctuation - Dual-strength memory model
11. Collins, A. M., & Loftus, E. F. (1975). A spreading-activation theory of semantic processing - Spreading activation networks
12. Frey, U., & Morris, R. G. (1997). Synaptic tagging and long-term potentiation - Synaptic tagging mechanism
13. Tulving, E., & Thomson, D. M. (1973). Encoding specificity and retrieval processes - Context-dependent memory

---

**Report Compiled By**: Jarvis Deep Research Agent  
**Date**: 2026-02-05  
**Next Review**: After P1-A implementation (Memory MCP enablement)

