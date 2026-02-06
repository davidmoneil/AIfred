# Vestige Design Philosophy Report

**Date**: 2026-02-05  
**Scope**: Deep analysis of Vestige's engineering excellence, architectural patterns, and design principles for reliability  
**Repository**: https://github.com/samvallad33/vestige

---

## Executive Summary

Vestige is a cognitive memory MCP server built in Rust that demonstrates **science-driven design philosophy** over feature accumulation. Its excellence emerges from three core principles:

1. **Cognitive Science as Architecture**: Rather than arbitrary technical choices, design decisions derive from 130+ years of memory research (FSRS-6, dual-strength model, spreading activation)
2. **Deterministic Decay**: Unlike traditional databases that promise perfect recall, Vestige embraces human-like memory fading as a *feature*, creating predictable, bounded behavior
3. **Simplicity with Depth**: Local-first SQLite storage, minimal dependencies, and progressive disclosure create a system that's approachable yet sophisticated

**Key Insight**: Vestige's reliability stems not from over-engineering but from **aligning system behavior with well-understood cognitive models**. When memory behaves like human memory, edge cases become predictable patterns.

---

## Architectural Excellence

### Design Patterns Used

#### 1. **Repository Pattern + Domain-Driven Design**
The system separates cognitive models (domain logic) from storage (infrastructure):
- **Domain Layer**: FSRS-6 algorithms, prediction error gating, spreading activation
- **Storage Layer**: SQLite with FTS5 (keyword) and HNSW vector indexing (semantic)
- **Interface Layer**: MCP protocol via stdio transport

This separation allows the cognitive models to evolve independently from storage implementation.

#### 2. **Strategy Pattern: Hybrid Search**
The system employs **Reciprocal Rank Fusion (RRF)** to combine three search strategies:
- BM25 keyword ranking (exact matches)
- Semantic embedding similarity (conceptual matches)
- Retention strength weighting (recency/importance)

Each strategy operates independently, with RRF mediating results. This prevents any single search mode from dominating inappropriately.

#### 3. **State Machine: Memory Accessibility**
Memories transition through four states based on composite accessibility scores:
- **Active** (≥70%): Immediately retrievable
- **Dormant** (40-70%): Retrievable with effort
- **Silent** (10-40%): Rarely surfaces
- **Unavailable** (<10%): Effectively forgotten

Accessibility = `0.5 × retention + 0.3 × retrieval_strength + 0.2 × storage_strength`

This creates deterministic state transitions rather than ad-hoc "important/not important" flags.

#### 4. **Factory Pattern: Prediction Error Gating**
The `ingest()` tool acts as a factory, classifying incoming information via similarity thresholds:
- **>0.92 similarity** → REINFORCE existing memory (no new entry)
- **0.75-0.92 similarity** → UPDATE (merge information)
- **<0.75 similarity** → CREATE new memory

This prevents duplicate memory bloat through automated classification.

#### 5. **Observer Pattern: Testing Effect**
Every search operation strengthens matching memories, implementing the "retrieval strengthens memory" principle. This creates a positive feedback loop where used knowledge becomes more accessible.

### Module Organization

The monorepo structure reveals clear separation of concerns:

```
crates/          → Rust core (74.4% of codebase)
  ├── memory/    → Cognitive models (FSRS-6, dual-strength)
  ├── search/    → Hybrid retrieval (BM25 + semantic)
  └── storage/   → SQLite persistence layer
packages/        → TypeScript tooling (21.7%)
  ├── cli/       → Command-line interface
  └── types/     → Shared type definitions
docs/            → Progressive disclosure documentation
tests/e2e/       → End-to-end behavioral validation
```

**Key Insight**: The 74% Rust / 21% TypeScript split shows a backend-focused design where performance-critical cognitive algorithms run in compiled code, while user-facing tooling uses developer-friendly TypeScript.

### Dependency Management

**Minimal External Dependencies**:
- **rusqlite**: SQLite interface (well-established, minimal attack surface)
- **fastembed**: Local embedding generation (~130MB, downloaded once)
- **serde**: Serialization (Rust ecosystem standard)
- **tokio**: Async runtime for MCP protocol

**Dependency Philosophy**: Vestige avoids framework lock-in. SQLite provides portability, fastembed runs locally (no API keys), and MCP protocol is language-agnostic.

**Lock Files**: Both `Cargo.lock` (Rust) and `pnpm-lock.yaml` (JavaScript) are committed, ensuring reproducible builds across environments.

---

## Reliability Engineering

### Error Handling Strategy

#### Rust Result Types
While specific code wasn't examined, Rust MCP servers typically use:
- `anyhow::Result<T>` for tool implementations (convenient error propagation)
- Custom error enums for protocol-level failures:
  - `Error::Protocol(code, msg)` for MCP spec violations
  - `Error::Transport(e)` for stdio communication failures
  - `Error::Storage(e)` for SQLite errors

**Pattern**: The `?` operator propagates errors up the call stack, ensuring failures surface rather than being silently swallowed.

#### Graceful Degradation
The system exhibits **partial failure tolerance**:
- If semantic search fails, keyword search (BM25) can still operate
- If embedding generation fails, memories remain queryable via keywords
- Low-retention memories don't block searches—they simply rank lower

#### Failure Recovery Patterns Identified

From the CHANGELOG, critical bugs reveal the **post-launch** error handling strategy:

- **SIGSEGV crash in vector index** (v1.0.0): Memory management bug where vector storage wasn't pre-allocated before insertion
  - **Fix**: `reserve()` before `add()` operations
  - **Lesson**: Rust's safety doesn't eliminate all memory issues (unsafe code in vector indexing)

- **SQL injection protection in FTS5 queries** (v1.0.0): Security vulnerability in keyword search
  - **Fix**: Parameterized queries or input sanitization
  - **Lesson**: Even with Rust, application-level SQL injection remains a risk

- **Infinite loop prevention in file watcher** (v1.0.0): Stability issue in change detection
  - **Fix**: Loop guards or timeout mechanisms
  - **Lesson**: External integrations (filesystem watchers) require defensive programming

- **UTF-8 string slicing issues** (v1.1.1): Character boundary violations when truncating text
  - **Fix**: Use `.chars().take(n)` instead of byte slicing
  - **Lesson**: Rust's string handling requires care at grapheme boundaries

### Data Integrity

**Minimal Application-Level Guarantees**:
The STORAGE.md documentation reveals Vestige delegates integrity to SQLite's ACID properties:
- **Atomicity/Consistency/Isolation/Durability**: Provided by SQLite
- **No application-level checksums**: No mention of corruption detection
- **No backup automation**: Users must implement external backup strategies
- **No redundancy**: Single SQLite file per project

**Risk Assessment by Use Case** (from documentation):
- AI conversation memory: **Low risk** (easily rebuilt)
- Coding patterns: **Medium risk** (periodic backups recommended)
- Sensitive data: **High risk** (explicitly NOT recommended)

**Design Trade-off**: Vestige prioritizes simplicity and local-first operation over enterprise-grade durability. This is appropriate for a personal productivity tool but limits production-critical applications.

### Edge Case Handling

#### Systematic Boundary Management

1. **Memory Decay Boundaries**: The FSRS-6 power-law curve asymptotically approaches zero but never reaches it. Silent memories (10-40% accessibility) can be revived if accessed again, preventing irreversible data loss.

2. **Similarity Threshold Boundaries**: The 0.75 and 0.92 similarity thresholds are **not arbitrary**—they map to cognitive research on memory interference:
   - <0.75: Information sufficiently distinct to warrant separate encoding
   - 0.75-0.92: Related but additive (merge information)
   - >0.92: Redundant (reinforce existing trace)

3. **Context Window Boundaries**: Synaptic tagging operates within a **9-hour retrospective window** and **2-hour prospective window**, mirroring biological memory consolidation timescales.

4. **Search Result Boundaries**: "Weak memories only appear when they're the best match"—low-retention memories aren't filtered out completely but rank lower, ensuring they surface only when no stronger alternatives exist.

#### Edge Cases Handled Systematically

- **Zero results**: System doesn't fail; returns empty set with guidance to check retention levels
- **Duplicate detection**: Handled automatically via prediction error gating (not user responsibility)
- **Missing embeddings**: `consolidate` command regenerates vectors for problematic memories
- **First-run network failure**: Explicitly documented (130MB embedding model download required)

---

## Predictability Mechanisms

### Configuration Management

#### Default Hierarchy
Vestige implements a four-tier configuration override system:

1. **Built-in Defaults** (lowest precedence):
   - Log level: `info`
   - Database location: Platform-specific (macOS: `~/Library/Application Support/com.vestige.core/`)
   - Model cache: Platform-specific (macOS: `~/Library/Caches/com.vestige.core/fastembed`)

2. **Configuration Files**:
   - `~/.claude/settings.json` for Claude integration
   - Claude Desktop app configs

3. **Environment Variables**:
   - `VESTIGE_DATA_DIR`: Override database location
   - `VESTIGE_LOG_LEVEL`: Control verbosity
   - `RUST_LOG`: Fine-grained logging control
   - `FASTEMBED_CACHE_PATH`: Override embedding model location

4. **Command-line Arguments** (highest precedence):
   - `--data-dir /custom/path`: Per-invocation override
   - `--version`, `--help`: Diagnostic commands

**Predictability Guarantee**: The hierarchy is deterministic—later layers always override earlier ones. No hidden auto-detection or heuristic fallbacks.

#### Configuration Validation

**Type Safety**: Moderate. JSON configs enforce structure, but environment variables are string-based with runtime parsing. No compile-time checking for paths or log levels.

**Error Detection**:
- `--help` provides schema documentation
- `--version` verifies binary correctness
- First-run failure is explicit (network required for model download)

**Weakness**: No documented schema validation errors. Unclear what happens with invalid `VESTIGE_LOG_LEVEL` values.

### State Management

#### Immutability Where Possible
- **Storage strength only increases**: Once information is encoded, the effort invested is never erased
- **Memories never auto-delete**: Fading in relevance ≠ deletion
- **Temporal context is immutable**: When a memory was created/accessed remains fixed

#### Controlled Mutation
- **Retrieval strength decays deterministically**: Follows FSRS-6 power-law curve `R(t, S) = (1 + factor × t / S)^(-w₂₀)`
- **Accessibility recomputed on access**: Testing effect strengthens retrieval each time memory is used
- **UPDATE operations merge information**: Rather than replacing, new data augments existing memories

**Pattern**: Mutations follow cognitive science rules, not arbitrary business logic. This makes state changes predictable through well-studied mathematical models.

### Deterministic Behavior

#### Mathematical Foundations
The FSRS-6 algorithm uses **21 parameters optimized on 700M+ Anki reviews**, providing deterministic retention curves. Given identical:
- Initial stability (`S`)
- Time elapsed (`t`)
- Review history

The same retention score (`R`) will always be computed.

**Caveat**: FSRS implementations can include `enableFuzzing` to add randomness to intervals (prevents "exam cramming" patterns). Vestige's implementation details aren't confirmed, but if fuzzing is disabled, behavior is fully deterministic.

#### Reproducibility Guarantees

**Same Input → Same Output** when:
1. Identical query text and context
2. Identical memory database state
3. Identical timestamp (for decay calculations)

**Variance Sources**:
- Embedding model updates (fastembed upgrades change vector representations)
- Timestamp differences (decay is time-dependent)
- Context changes (project/topic context affects retrieval)

**Design Philosophy**: Vestige doesn't promise absolute reproducibility across contexts (that would contradict context-dependent retrieval). Instead, it promises **predictable variance**—results change in documented ways based on time, context, and usage.

---

## Quality Assurance

### Testing Strategy

#### Multi-Level Testing
The repository structure reveals:
- **Unit tests**: `cargo test` for Rust core
- **End-to-end tests**: `tests/e2e/` directory for behavioral validation
- **Integration tests**: Likely cover MCP protocol compliance

#### Quality Gates (Pre-Merge Requirements)

From CONTRIBUTING.md:

**Rust Codebase**:
1. **Formatting**: `cargo fmt` (enforces consistent style)
2. **Linting**: `cargo clippy -- -D warnings` (promotes Rust idioms, catches bugs)
3. **Compilation**: Must compile without warnings
4. **Testing**: `cargo test` must pass

**TypeScript/JavaScript**:
1. **Linting**: `pnpm lint`
2. **Formatting**: `pnpm format`

**Pattern**: Automated tooling enforces consistency rather than manual review. This scales better across contributors.

#### Testing Philosophy Gaps

**Weaknesses Revealed by Changelog**:
- SIGSEGV, SQL injection, and infinite loops reached production (v1.0.0)
- UTF-8 slicing errors in v1.1.1

**Implication**: Despite `cargo test` requirements, edge cases in unsafe code (vector indexing), security (SQL injection), and string handling weren't caught pre-release. Test coverage exists but **critical paths were under-tested**.

### CI/CD Pipeline

#### Automated Workflows
The `.github/workflows/` directory indicates multi-platform builds:
- macOS Intel
- macOS ARM (Apple Silicon)
- Linux
- Windows

**Pattern**: Continuous integration runs tests across platforms, catching platform-specific issues early.

#### Release Automation
The rapid release cadence (v1.0.0 → v1.1.2 in 3 days) suggests:
- Automated versioning (Semantic Versioning compliance)
- Automated binary builds for multiple platforms
- Likely automated CHANGELOG generation

**Strength**: Fast iteration enables quick bug fixes (v1.1.1 → v1.1.2 same-day patch).

**Weakness**: Aggressive release pace without sufficient pre-release testing led to critical bugs in v1.0.0.

---

## Documentation System

### Structure & Organization

#### Progressive Disclosure Architecture

**Tier 1: Quick-Start (README.md)**
- Three-step setup (Download → Connect → Test)
- Immediate validation example ("Remember that I prefer TypeScript")
- Minimal cognitive load

**Tier 2: Operational Guidance**
- FAQ.md: Common problems and solutions
- CONFIGURATION.md: Override hierarchy and environment variables
- STORAGE.md: Data persistence and backup strategies

**Tier 3: Deep Understanding**
- SCIENCE.md: Cognitive science foundations (FSRS-6, dual-strength model, spreading activation)
- CONTRIBUTING.md: Development workflow and quality standards

**Pattern**: Users learn *what* before *how*, and *how* before *why*. This respects varying technical depth and time constraints.

#### Documentation Philosophy

**Cognitive Mapping**: Neuroscience concepts are translated into user-facing language:
- Technical: "Prediction Error Gating via similarity thresholds"
- User-facing: "Intelligent ingestion with duplicate detection"

**Problem-Solution Framing**: Features are presented as solutions to user pain points:
- Problem: "RAG dumps irrelevant context"
- Solution: "FSRS-6 naturally fades unused memories"

**Explicit Limitations**: The FAQ directly addresses what Vestige *cannot* do:
- Not HIPAA-compliant
- No cloud sync
- Requires technical setup (5 minutes for technical users)

**Strength**: Honesty builds trust. Users know constraints upfront.

### Maintenance Strategy

#### Synchronization Mechanisms

**Changelog-Driven Documentation**: The CHANGELOG.md shows feature additions (v1.1.0: tool consolidation) are immediately reflected in the README (tool descriptions updated).

**Version Alignment**: Documentation references specific versions ("removed in v2.0"), preventing outdated guidance.

#### Potential Weaknesses

**No Architecture Decision Records (ADRs)**: Design decisions (why 0.75/0.92 thresholds? why 9-hour synaptic tagging window?) are scattered across SCIENCE.md and FAQ.md rather than centralized.

**No API Documentation**: While MCP tool schemas exist (JSON configs), no human-readable API reference was evident. Users must infer tool behavior from README descriptions.

---

## Extensibility Design

### Extension Points

#### 1. **Data Directory Isolation**
`--data-dir` enables per-project memory stores, allowing:
- Separate knowledge bases for work/personal projects
- Testing environments without contaminating production data
- Multi-tenant deployments (though not the primary use case)

#### 2. **MCP Protocol as Interface**
By implementing Model Context Protocol, Vestige decouples from Claude-specific implementations:
- Any MCP-compatible client can use Vestige
- Future LLM platforms adopting MCP gain automatic compatibility

**Pattern**: Vestige doesn't expose a Vestige-specific API; it exposes cognitive primitives (search, ingest, importance, etc.) via a standard protocol.

#### 3. **Embedding Model Swappability**
While fastembed is the current provider, the architecture likely supports:
- Alternative embedding models (if they expose compatible APIs)
- Custom embeddings (if users generate vectors externally)

**Caveat**: This is inferred from architectural patterns—no explicit plugin system is documented.

### API Boundaries

#### Public Interface (MCP Tools)
From the v1.1.0 consolidation, the **8 cognitive primitives** are:
1. **search**: Hybrid keyword + semantic retrieval
2. **ingest**: Intelligent memory creation with duplicate detection
3. **importance**: Retroactive strengthening via synaptic tagging
4. **consolidate**: Regenerate embeddings for problematic memories
5-8. **[4 additional tools not specified in documentation]**

**Stability Promise**: Old tool names still work with warnings until v2.0, providing a deprecation grace period.

#### Internal Implementation (Hidden)
- SQLite schema details
- FSRS-6 parameter tuning
- Vector indexing algorithms (HNSW)
- Embedding generation internals (fastembed)

**Encapsulation Strength**: Users interact with cognitive abstractions (memories, retention, importance) rather than database queries or vector math. This allows internal optimization without breaking user workflows.

### Coupling Minimization

#### Loose Coupling via MCP
Claude communicates with Vestige through:
1. **stdio transport** (language-agnostic)
2. **JSON-RPC messages** (structured but flexible)
3. **Tool schemas** (self-describing APIs)

**Benefit**: Vestige can be swapped for alternative memory systems without changing Claude Code/Desktop—only the `~/.claude/settings.json` configuration changes.

#### Tight Coupling Risks
- **SQLite dependency**: Migrating to alternative storage (PostgreSQL, custom formats) would require significant refactoring
- **fastembed dependency**: Changing embedding providers risks breaking semantic search if vector dimensions change

**Design Trade-off**: Vestige accepts coupling to mature, stable dependencies (SQLite, fastembed) to avoid premature abstraction.

---

## Lessons for Jarvis

### Patterns to Adopt

| Pattern | Description | Jarvis Application |
|---------|-------------|-------------------|
| **Cognitive Model as Architecture** | Derive system behavior from well-understood models rather than ad-hoc rules | JICM could use information theory (compression ratios, entropy) to predict context exhaustion more accurately |
| **Deterministic State Machines** | Explicit state transitions with mathematical formulas (not heuristics) | Session states (active, idle, maintenance) with explicit transition rules |
| **Progressive Disclosure Documentation** | Tier 1 (quick-start) → Tier 2 (operations) → Tier 3 (deep understanding) | Current `.claude/context/` structure already follows this—reinforce it |
| **Prediction Error Gating** | Auto-classify incoming data to prevent redundancy | Apply to session notes: CREATE/UPDATE/SUPERSEDE logic for `session-state.md` |
| **Testing Effect Strengthening** | Frequently accessed knowledge becomes more accessible | Weight recent context files higher in JICM compression decisions |
| **Graceful Degradation** | Partial failures don't block entire workflows | If MCP fails, fall back to local tools; if git fails, save state locally |
| **Explicit Limitation Documentation** | FAQ directly states what the system *cannot* do | Add "Known Limitations" section to `CLAUDE.md` |
| **Monotonic Properties** | Storage strength only increases—never decreases | Apply to Memory MCP: never delete memories, only reduce accessibility |
| **Boundary-Based Classification** | Use thresholds from research (0.75/0.92 similarity) rather than arbitrary cutoffs | JICM's 50% threshold—validate via empirical testing across sessions |
| **Command-Line First, GUI Optional** | Power users need precision; GUIs can layer on top | Jarvis already follows this—maintain CLI-first design |

### Anti-Patterns to Avoid

#### 1. **Insufficient Pre-Release Testing**
**Vestige's Mistake**: SIGSEGV crashes, SQL injection, and infinite loops reached v1.0.0 despite `cargo test` requirements.

**Jarvis Guard**: 
- Add security-focused tests (injection attacks, privilege escalation)
- Add stress tests (long-running loops, edge cases)
- Require manual QA checklist for major releases (not just automated tests)

#### 2. **Weak Schema Versioning**
**Vestige's Gap**: No documented migration strategy for storage schema changes.

**Jarvis Guard**:
- Version all state files (add `schema_version: "1.2.0"` to session-state.md)
- Write migration scripts before introducing breaking changes
- Test downgrades (can v2 state safely degrade to v1?)

#### 3. **Configuration Validation Gaps**
**Vestige's Weakness**: No documented error handling for invalid `VESTIGE_LOG_LEVEL` or malformed paths.

**Jarvis Guard**:
- Validate all environment variables at startup
- Provide actionable error messages ("Expected log_level in [debug, info, warn, error], got 'foo'")
- Add `jarvis validate-config` command

#### 4. **Rapid Iteration Without Stabilization**
**Vestige's Pattern**: Three versions in three days (v1.0.0 → v1.1.2) suggests reactive firefighting.

**Jarvis Guard**:
- Maintain a `develop` branch for experimental features
- Require 48-hour soak period before promoting to `main`
- Use semantic versioning strictly (patch for bugs, minor for features, major for breaking changes)

#### 5. **Implicit Behavioral Contracts**
**Vestige's Gap**: Why 9-hour synaptic tagging window? Why 0.75 similarity threshold? These lack ADRs.

**Jarvis Guard**:
- Document *why* decisions were made, not just *what* was implemented
- Add `context/decisions/` directory for Architecture Decision Records
- Reference ADRs in code comments for critical thresholds

### Specific Improvements for Jarvis Reliability

#### 1. **JICM Enhancement: Entropy-Based Compression**
**Current**: Single 50% threshold triggers `/intelligent-compress`

**Improvement**: Use information entropy to predict *which* context elements are redundant:
```bash
# Pseudocode for entropy-based selection
for file in context/*; do
    entropy=$(calculate_information_density "$file")
    if [ "$entropy" -lt 0.3 ]; then
        mark_for_compression "$file"
    fi
done
```

**Rationale**: Vestige's prediction error gating shows that **similarity thresholds prevent redundancy**. Apply this to context files—compress low-information-density sections first.

#### 2. **Session State Machine**
**Current**: Session states are implicit (inferred from `session-state.md` content)

**Improvement**: Explicit state machine with transition rules:
```yaml
states:
  - active: 
      condition: "poll_count < max_polls && context < 70%"
      transitions: [idle, maintenance, exhaustion]
  - idle:
      condition: "no user activity for 10 minutes"
      transitions: [active, session_end]
  - maintenance:
      condition: "scheduled or /maintain invoked"
      transitions: [active]
  - exhaustion:
      condition: "context >= 70%"
      transitions: [checkpoint, clear]
```

**Rationale**: Vestige's memory states (Active/Dormant/Silent/Unavailable) show deterministic transitions improve predictability.

#### 3. **Memory MCP: Implement Dual-Strength Model**
**Current**: Memories are stored with equal weight

**Improvement**: Track *storage strength* (how well encoded) vs. *retrieval strength* (current accessibility):
```json
{
  "memory": "User prefers TypeScript over JavaScript",
  "storage_strength": 0.95,  // High (important decision)
  "retrieval_strength": 0.60, // Medium (hasn't been used recently)
  "last_accessed": "2026-02-01T10:30:00Z"
}
```

**Rationale**: Vestige separates encoding permanence from current accessibility. Apply this to Jarvis—important memories that haven't been used lately should still be **revivable** rather than buried.

#### 4. **Testing Effect in Context Management**
**Current**: Context files are treated equally regardless of usage

**Improvement**: Frequently accessed files persist longer during compression:
```bash
# Track access frequency in .context-access-log
echo "$file,$timestamp" >> .context-access-log

# During compression, weight by access frequency
access_count=$(grep "$file" .context-access-log | wc -l)
priority=$(( base_priority + access_count ))
```

**Rationale**: Vestige's testing effect (retrieval strengthens memory) shows that **usage signals importance**. Files Claude repeatedly reads are likely critical.

#### 5. **Graceful Degradation: MCP Fallback Chain**
**Current**: If MCP fails, operations may block

**Improvement**: Fallback hierarchy:
```bash
# Try MCP first
if ! memory_mcp_add "$content"; then
    # Fallback 1: Local memory file
    echo "$content" >> .claude/memory/local-fallback.md
    log "MCP unavailable, wrote to local memory"
    
    # Fallback 2: Session state annotation
    echo "## Pending Memory Sync\n$content" >> context/session-state.md
fi
```

**Rationale**: Vestige shows **partial failures shouldn't block workflows**. If keyword search fails, semantic search continues.

#### 6. **Explicit Limitation Documentation**
**Current**: `CLAUDE.md` focuses on capabilities

**Addition**: Add "Known Limitations" section:
```markdown
## Known Limitations

### What Jarvis Cannot Do
- Cross-session context without explicit checkpointing
- Recovery from interrupted `/intelligent-compress` (manual cleanup required)
- Parallel session support (single-session design)

### Risk Assessment
- Session state corruption: **Medium risk** (backup to `.claude/backups/` recommended)
- MCP connection loss: **Low risk** (graceful degradation to local files)
- JICM watcher crash: **Low risk** (heartbeat monitoring + auto-restart)
```

**Rationale**: Vestige's FAQ directly states constraints. Apply this to Jarvis for user trust.

#### 7. **Validation Command**
**Current**: No pre-flight checks for environment correctness

**Addition**: `/validate` command:
```bash
jarvis-validate.sh
  ✓ Git repository detected
  ✓ .claude/ structure intact
  ✓ MCPs responding (memory, filesystem)
  ✗ JARVIS_LOG_LEVEL invalid (expected [debug|info|warn|error], got 'verbose')
  ✓ tmux available
  ✓ Session state schema v1.2.0
```

**Rationale**: Vestige provides `--version` and `--help` for diagnostics. Jarvis needs equivalent.

#### 8. **Schema Versioning**
**Current**: State files lack version metadata

**Addition**: Add to `session-state.md`:
```yaml
---
schema_version: "1.2.0"
last_migration: "2026-02-01"
---
```

**Rationale**: Vestige's lack of versioning creates migration risk. Jarvis should avoid this.

---

## Functional Extensions Available in Vestige

From the research, Vestige provides:

### Core Capabilities
1. **Unified Search**: Keyword + Semantic + Hybrid (RRF)
2. **Intelligent Ingestion**: Prediction error gating (CREATE/UPDATE/REINFORCE)
3. **Memory Management**: Importance flagging, consolidation, retention tracking
4. **Codebase Pattern Memory**: Remembers architectural decisions, coding patterns
5. **Intention Setting**: Reminders for future sessions
6. **Context-Dependent Retrieval**: Temporal, topical, emotional context matching
7. **Synaptic Tagging**: Retroactive strengthening of related memories (9-hour window)

### NOT Available (Based on Research)
- **Voice/Audio**: No mention in documentation
- **Scheduling/Cron**: No automated triggers (user-initiated only)
- **External Integrations**: No Slack, email, or third-party connectors
- **Team Collaboration**: Local-only (no multi-user sync)
- **Cloud Sync**: Explicitly **not** supported (100% local)

**Jarvis Application**: Vestige's scope is deliberately narrow (personal memory augmentation). Jarvis could adopt this **focused scope philosophy** rather than building "all the things."

---

## References

### Primary Sources
1. [Vestige GitHub Repository](https://github.com/samvallad33/vestige) - Main codebase
2. [Vestige SCIENCE.md](https://github.com/samvallad33/vestige/blob/main/docs/SCIENCE.md) - Cognitive science foundations
3. [Vestige STORAGE.md](https://github.com/samvallad33/vestige/blob/main/docs/STORAGE.md) - Storage architecture
4. [Vestige CONFIGURATION.md](https://github.com/samvallad33/vestige/blob/main/docs/CONFIGURATION.md) - Configuration system
5. [Vestige CONTRIBUTING.md](https://github.com/samvallad33/vestige/blob/main/docs/CONTRIBUTING.md) - Quality standards
6. [Vestige CHANGELOG.md](https://github.com/samvallad33/vestige/blob/main/CHANGELOG.md) - Release history

### Design Pattern Resources
7. [Build MCP Servers in Rust - Complete Guide](https://mcpcat.io/guides/building-mcp-server-rust/) - MCP architecture patterns
8. [15 Best Practices for Building MCP Servers in Production](https://thenewstack.io/15-best-practices-for-building-mcp-servers-in-production/) - Production reliability
9. [MCP Server Best Practices for 2026](https://www.cdata.com/blog/mcp-server-best-practices-2026) - 2026 patterns
10. [Building a High-Performance MCP Server with Rust](https://medium.com/@bohachu/building-a-high-performance-mcp-server-with-rust-a-complete-implementation-guide-8a18ab16b538) - Implementation guide

### Error Handling & Reliability
11. [Error Handling and Fallback Mechanisms in AI Assistants](https://www.nexusflowinnovations.com/blog/error-handling-fallback-mechanisms-ai-assistants) - AI system reliability
12. [Best Practices for Ensuring AI Agent Performance and Reliability](https://dev.to/kuldeep_paul/best-practices-for-ensuring-ai-agent-performance-and-reliability-4ok0) - Agent patterns
13. [Integrating Rust with SQLite: A Practical Guide](https://dev.to/eleftheriabatsou/integrating-rust-with-sqlite-a-practical-guide-for-beginners-devs-3j40) - SQLite patterns

### Cognitive Architecture
14. [Design Patterns for Long-Term Memory in LLM-Powered Architectures](https://serokell.io/blog/design-patterns-for-long-term-memory-in-llm-powered-architectures) - Memory design patterns
15. [AI Memory Systems: A Deep Dive into Cognitive Architecture](https://pub.towardsai.net/ai-memory-systems-a-deep-dive-into-cognitive-architecture-83190b3e1ac5) - Cognitive models

### FSRS Algorithm
16. [The FSRS Spaced Repetition Algorithm](https://help.remnote.com/en/articles/9124137-the-fsrs-spaced-repetition-algorithm) - FSRS fundamentals
17. [Technical Principles and Application Prospects of FSRS](https://www.oreateai.com/blog/technical-principles-and-application-prospects-of-the-free-spaced-repetition-scheduler-fsrs/36ee752bd462235d0d5b903059bc8684) - FSRS implementation
18. [Free Spaced Repetition Scheduler GitHub](https://github.com/open-spaced-repetition/free-spaced-repetition-scheduler) - FSRS source code

---

## Conclusion

Vestige demonstrates that **reliability emerges from principled design** rather than defensive programming alone. By grounding system behavior in cognitive science, using deterministic mathematical models, and maintaining tight scope, Vestige achieves predictability without over-engineering.

**Key Takeaway for Jarvis**: Adopt Vestige's **model-driven architecture philosophy**. Rather than ad-hoc rules for context management, JICM should use information theory (entropy, compression ratios) to make mathematically grounded decisions. Rather than heuristic session states, implement explicit state machines with documented transition rules.

**Final Recommendation**: Audit Jarvis's autonomic components (AC-01 through AC-09) using Vestige's patterns as a lens:
- Does each component have deterministic state transitions?
- Are thresholds (70% context, 6 iterations for heartbeat) empirically justified?
- Can failures degrade gracefully rather than halting execution?

This research provides a blueprint for evolving Jarvis from "works well" to "works predictably."
