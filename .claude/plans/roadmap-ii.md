# Roadmap II — Mac Studio Era & Beyond

**Created**: 2026-02-09
**Scope**: All remaining work from Roadmap I + new initiatives from Stream 2 research
**Architecture Version**: v5.9.0 to v6.5.0 (target)
**Mac Studio**: M4 Max 128GB arriving Wed Feb 12
**Total Estimate**: ~240-270 hours (~6-7 weeks at 40hrs/week)

---

## Preamble

This roadmap incorporates:
- Unfinished Roadmap I Phase 6 items (PR-12.6-12.8, PR-13, PR-14)
- AIfred integration roadmap M7-M11 (~39 hrs remaining)
- Research report action items (~40 hrs from consolidated analyses)
- Mac Studio era infrastructure + AI/ML capabilities
- Memory System Architecture (dedicated project phase)
- AC-10 Ulfhedthnar — hidden Neuros override system (berserker problem-solving)
- New feature requests (multi-agent coordination, agent library)
- Command-to-Skill migration (30+ commands)
- Aion script development (Ennoia, Virgil, Watcher dashboard)

**Relationship to Roadmap I**: Roadmap II is a CONTINUATION, not a replacement. Phase A completes Roadmap I Phase 6, then extends into Mac Studio era development.

### Autonomic Architecture — Hippocrenae + Ulfhedthnar

The nine standard ACs (AC-01 through AC-09) are the **Hippocrenae** — named for the sacred spring of the Nine Muses on Mount Helicon. Each Muse governs a domain of Jarvis's autonomous operation: launch, work, review, context, reflection, evolution, research, maintenance, and session completion.

Beyond the Nine Muses exists a hidden 10th component: **AC-10 Ulfhedthnar** — the wolf-warrior Neuros system. Unlike the Hippocrenae which operate in harmony, Ulfhedthnar awakens only when Jarvis encounters barriers it cannot solve through normal means. It is a berserker override: unyielding, parallel, and relentless.

---

## Phase A: Complete Roadmap I Phase 6 (~10-14 hrs) — COMPLETE

**Dependencies**: None (immediate)
**Status**: COMPLETE (verified 2026-02-09)
**Commit**: 5b38374 (32 files, +3874/-78)

### A.1 PR-12.6 — AC-06 Evolution (~2-3 hrs) — DONE (scaffolded)
- [x] Downtime detector — `.claude/scripts/downtime-detector.sh` (idle detection; rollback logic deferred to /evolve implementation)
- [x] Evolution log tracking — `.claude/logs/evolution.jsonl` (provisioned, empty until first evolution cycle)
- [x] Integration with `/evolve` command — `commands/evolve.md` spec complete; telemetry wired in emitter
- [x] State file: `AC-06-evolution.json` → status "active"
- **Residual gaps**: /evolve executable pipeline not implemented (spec-only); rollback mechanism not in detector script; failure_modes_tested=false
- **Carry-forward**: /evolve operational implementation → Phase B.6 (Automatic Skill Learning)

### A.2 PR-12.7 — AC-07 R&D (~2 hrs) — DONE (scaffolded)
- [x] File usage tracker — `.claude/scripts/file-usage-tracker.sh` (jq --arg hardened, bash 3.2 compatible)
- [x] External research integrator — research-ops v2.1.0 provides backends (implicit coupling)
- [x] Integration with research-ops skill — functional but undocumented cross-reference
- [x] State file: `AC-07-rd.json` → status "active"
- **Residual gaps**: research-ops SKILL.md has no AC-07 reference; file-usage.jsonl empty (no active caller); failure_modes_tested=false

### A.3 PR-12.8 — AC-08 Maintenance (~2 hrs) — DONE (fully operational)
- [x] Freshness auditor — `.claude/scripts/freshness-auditor.sh` (168 files scanned, 17 stale flagged)
- [x] Organization auditor — `.claude/scripts/organization-auditor.sh` (39/39 checks PASS)
- [x] State file: `AC-08-maintenance.json` → status "active"
- **Reports generated**: `reports/maintenance/freshness-2026-02-09.md`, `organization-2026-02-09.md`
- **Residual gap**: failure_modes_tested=false (deferred by design)

### A.4 PR-13 — Monitoring & Benchmarks (~4-6 hrs) — DONE
- [x] PR-13.1: Token usage + response time — `hooks/telemetry-emitter.js` (326 lines, JSONL events)
- [x] PR-13.2: 10-task benchmark suite — `test/benchmarks/benchmark-suite.yaml` (BM-01 to BM-10, all 9 ACs)
- [x] PR-13.3: Task complexity + success scoring — distributed: `scoring-engine.js` + `regression-detector.js`
- [x] PR-13.4: JICM threshold + compression metrics — 4 threshold levels captured in telemetry
- [x] PR-13.5: Aggregate telemetry dashboard — `.claude/scripts/telemetry-dashboard.sh` (101 lines)
- **Supporting infra (pre-existing)**: telemetry-aggregator.js, telemetry-query.js, benchmark-runner.js

### A.5 PR-14 — SOTA Catalog (~2 hrs) — DONE
- [x] 55 entries across 9 categories (AI/ML, DevOps, KnowledgeMgmt, CodeIntel, MCP, Automation, Testing, Research, Security)
- [x] Integration status tracking — 6 statuses (Active:9, Planned:14, Candidate:13, Monitor:5, Deferred:3, Decomposed:2)
- **File**: `projects/project-aion/sota-catalog/sota-catalog.yaml` (619 lines)

### Phase A Residual Items (carry-forward to Phase B)

| Item | Origin | Target |
|------|--------|--------|
| /evolve executable pipeline | A.1 | B.6 (Automatic Skill Learning) |
| AC-06 rollback mechanism | A.1 | B.6 |
| research-ops ↔ AC-07 cross-ref docs | A.2 | B.2 (Deep Research) |
| failure_modes_tested for AC-06/07/08 | A.1-A.3 | B.4 (Context Engineering, degradation testing) |
| Empty log files (evolution.jsonl, file-usage.jsonl) | A.1-A.2 | Populated when ACs execute |

---

## Phase B: Stream 2 Implementation (~15-20 hrs)

**Dependencies**: A (partial)

### B.1 Install claude-code-docs (~1 hr) — DONE
- [x] Forked costiash/claude-code-docs → CannonCoPilot/claude-code-docs
- [x] Refactored installer v0.6.0-jarvis: Jarvis-aware, GitRepos path, project-level /docs command
- [x] Installed to /Users/aircannon/Claude/GitRepos/claude-code-docs (543 files, 573 paths, Python 3.9.6)
- [x] Created /docs command at .claude/commands/docs.md (project-level, not user-level)
- [x] Session-start sync: git pull on startup (session-start.sh, after AIfred sync)
- [x] Zero hooks, zero persistent context overhead
- **Commit**: TBD (this session)

### B.2 Deep Research Pattern Decomposition (~3-4 hrs) — DONE
- [x] Extract `research-plan.sh` (query decomposition, sub-question generation, 8 question types)
- [x] Extract `research-synthesize.sh` (multi-source aggregation, citation, 3 synthesis styles)
- [x] NO direct LLM provider calls (uses heuristic keyword detection + backend mapping)
- [x] Integration with research-ops v2.2.0 (SKILL.md updated, capability-map.yaml registered)

### B.3 Hook Consolidation (~2-3 hrs) — DONE
- [x] Execute 5 merges from hook-consolidation-plan.md (34→23 hooks, 32% reduction)
- [x] Update settings.json hook registrations
- [x] Verify no regression (83% fewer spawns)
- **Commit**: c75f201

### B.4 Context Engineering JICM Integration (~5-7 hrs) — Wave 1 DONE
- [x] Wave 1: jarvis-watcher.sh v5.8.3 — 4 bug fixes (failsafe loops, /clear retry, cooldown, failure recording)
- [ ] Phase 1: Anchored Iterative Summarization at 65% trigger
- [ ] Phase 2: File-system-as-memory with session scoping
- [ ] Phase 3: Observation Masking for tool outputs (60-80% reduction)
- [ ] Phase 4: Context poisoning detection + degradation testing

### B.5 Skill-Level Model Routing (~2 hrs) — DONE
- [x] Add `model:` field to all 26 SKILL.md files (3 haiku, 2 opus, 21 sonnet)
- [x] capability-map.yaml v3: 11/11 skills + 12/12 agents with model routing
- [x] Opus: research-ops, knowledge-ops, deep-research agent
- [x] Sonnet: 7 skills + 8 agents (code-review, code-implementer, etc.)
- [x] Haiku: filesystem-ops, weather, autonom-ops + compression/JICM agents

### B.6 Automatic Skill Learning Enhancement (~2-3 hrs) — DONE
- [x] /reflect Phase 2.5: Process Simplification Detection (scans for repeated multi-step patterns)
- [x] /evolve Step 2.5: Skill Promotion Processing (auto-promotes candidates with frequency >= 3)
- [x] skill-candidates.yaml + skill-promotions.yaml created in .claude/context/learning/
- [x] Promotion criteria: frequency >= 3, complexity <= medium → auto-scaffold; high → evolution proposal

### B.7 AC-10 Ulfhedthnar — Neuros Override System (~6-8 hrs)

**The Hidden Tenth.** While the 9 Hippocrenae ACs operate in standard harmony, AC-10 exists outside their hierarchy as a **Neuros** (nerve/signal) layer — a berserker problem-solving override that activates when normal approaches fail.

#### B.7.1 Detection Hooks (~2 hrs)
- [ ] `ulfhedthnar-detector.js` hook on PostToolUse/Notification events
- [ ] Pattern matching for defeat signals:
  - "I can't" / "I'm unable to" / "I don't think I can"
  - "I don't know how to" / "This isn't possible"
  - "I'm not sure" (repeated 3+ times on same task)
  - Subagent failure cascades (2+ agents fail same objective)
  - Wiggum Loop stalls (3+ iterations with no progress)
- [ ] Confidence decay tracker (progressive confidence erosion detection)
- [ ] User-invocable trigger: `/unleash` command

#### B.7.2 Override Protocol (~2-3 hrs)
- [ ] **Frenzy Mode**: Spawn max parallel agents on decomposed sub-problems
- [ ] **Wiggum Berserker Loop**: Enhanced WL with no-quit iterator
  - Execute → Check → **Reframe** → Retry (alternate approach) → Check → Continue
  - Minimum 5 iterations before admitting defeat (vs standard 2-3)
- [ ] **Approach Rotation**: Systematic cycling through alternative strategies
  - Direct → Decompose → Analogize → Invert → Brute-force → Creative
- [ ] **Escalation Ladder**: Web research → Agent delegation → Tool discovery → User consultation (last resort)
- [ ] **Progress Anchoring**: Capture partial solutions, never discard progress

#### B.7.3 Ulfhedthnar Persona & Locked Skill (~2-3 hrs)
- [ ] Locked skill at `.claude/skills/ulfhedthnar/SKILL.md`
  - Hidden from standard skill discovery (`discoverable: false`)
  - Activated ONLY by detection hook or `/unleash` command
  - Contains berserker problem-solving protocols
- [ ] Persona emergence: When detection fires, Ulfhedthnar "asks to be freed"
  - Notification to user: *"Ulfhedthnar senses resistance. Shall I unleash the wolf-warrior?"*
  - User confirms → Skill unlocks → Override protocols engage
  - User declines → Log the barrier, return to normal operation
- [ ] Session state tracking: `AC-10-ulfhedthnar.json`
  - `barriers_detected`, `unleashes_requested`, `unleashes_granted`
  - `problems_solved_post_unleash`, `frenzy_duration_avg`
- [ ] Telemetry integration with `telemetry-emitter.js`

#### B.7.4 Safety Constraints
- [ ] **No destructive override**: Ulfhedthnar cannot bypass destructive action confirmations
- [ ] **AIfred baseline protection**: Read-only rule still absolute
- [ ] **Context budget awareness**: Frenzy mode respects JICM thresholds (delegates to agents to protect main context)
- [ ] **Auto-disengage**: Returns to normal Hippocrenae operation after problem solved or user cancels
- [ ] **Cooldown period**: 30-minute minimum between frenzy activations

---

## Phase C: Mac Studio Infrastructure (Wed Feb 12+, ~20 hrs)

**Dependencies**: Mac Studio arrival

### C.1 Base Setup & Docker Environment (~4 hrs)
- [ ] macOS config, dev tools, Docker Desktop
- [ ] Docker Compose for multi-service deployment
- [ ] Persistent storage + networking

### C.2 Obsidian Vault Setup (~3 hrs)
- [ ] Create vault (location TBD)
- [ ] Structure: Projects, Research, Logs, Patterns
- [ ] Integrate as knowledge-ops Tier 2 (Read/Glob)

### C.3 n8n Workflow Automation (~4 hrs)
- [ ] Docker deployment with PostgreSQL backend
- [ ] Initial workflow templates
- [ ] Jarvis integration documentation

### C.4 Local Supabase (~4 hrs)
- [ ] `supabase start` Docker deployment
- [ ] PostgreSQL + PostgREST + Realtime
- [ ] Fold into db-ops skill

### C.5 Language Servers (LSP) (~5 hrs)
- [ ] Python (pyright), TypeScript, Go (gopls), Bash, YAML
- [ ] Prepare for Serena integration when stable (#944 fixed)
- [ ] ~200-300MB RAM per server — trivial on Mac Studio

---

## Phase D: AI/ML First Round (~15-20 hrs)

**Dependencies**: C

### D.1 vLLM Local Inference (~4-5 hrs)
- [ ] Deploy for local model serving
- [ ] Download 70B quantized models (Llama 3.1, Qwen 2.5)
- [ ] API server + integration with research-ops

### D.2 lm-eval-harness (~2-3 hrs)
- [ ] Install + benchmark suite (MMLU, HumanEval)
- [ ] Baseline performance metrics

### D.3 DSPy Prompt Optimization (~3-4 hrs)
- [ ] Integrate patterns into research-ops prompt templates
- [ ] Compiler-optimized prompts for research tasks

### D.4 RAG Pipeline (Chroma/FAISS) (~4-5 hrs)
- [ ] Docker Chroma deployment (replace local-rag MCP)
- [ ] Ingest Jarvis context files
- [ ] Integration with knowledge-ops Tier 3

### D.5 First-Round AI Skill Installation (~2-3 hrs)
- [ ] Select 5-10 skills from AI-Research-Skills repo appropriate for M4 Max 128GB
- [ ] Candidates: code generation, summarization, embedding, QA

---

## Phase E: Memory System Architecture (~30-40 hrs, parallel with C/D)

**Dependencies**: C (partial, for vLLM)

### E.1 "Best Memory System Award" — Comparative Analysis (~5-6 hrs)
- [ ] Compare: Jarvis 4-tier vs Memory Palace vs Vestige vs FSRS-6 decay vs Temporal KG
- [ ] Scoring criteria + decision matrix
- [ ] Winner selection + migration plan

### E.2 Bidirectional Knowledge Graph Design (~6-8 hrs)
- [ ] Graph schema (Pattern, Skill, Agent, Command, Hook, File, Session, Decision nodes)
- [ ] Edge types (Uses, Depends, References, Supersedes, Contradicts)
- [ ] Link density tracking + dead link detection
- [ ] Topological optimization

### E.3 Organic Knowledge Lifecycle Implementation (~4-5 hrs)
- [ ] Maturity metadata on all 51 patterns (seedling/growing/evergreen)
- [ ] Progression rules + automated pruning scripts
- [ ] Archive-first approach (reversible)

### E.4 Memory "Subconsciousness" (~6-8 hrs)
- [ ] Local models (via vLLM) scanning memory sources in background
- [ ] Automatic categorization + similarity detection
- [ ] Relationship extraction into knowledge graph
- [ ] RAG pipeline integration

### E.5 Hippocrenae Integration (~5-6 hrs)
- [ ] Map each of the 9 Hippocrenae ACs to its memory domain (Muse mapping)
- [ ] Cross-domain queries between Muse domains
- [ ] ACs = mechanisms, memory system = structure they operate on
- [ ] AC-10 Ulfhedthnar memory isolation (barrier logs, frenzy session artifacts)
- [ ] Architectural documentation: Hippocrenae (harmony) vs Ulfhedthnar (override)

### E.6 Hook-Based Knowledge Capture (~3-4 hrs)
- [ ] Session insight auto-save hook
- [ ] Research interceptor (cache before web fetch)
- [ ] URL detection for knowledge intake

### E.7 PR Review Knowledge Extraction (~4-5 hrs)
- [ ] `.claude/context/review-chamber/` (decisions, patterns, standards, lessons)
- [ ] Auto-extraction from PR reviews
- [ ] Integration with Memory MCP

---

## Phase F: Multi-Agent Coordination (~16-20 hrs)

**Dependencies**: B.5 (model routing), B.7 (Ulfhedthnar — Frenzy Mode uses agent coordination)

### F.1 Task Tool Equivalent for Jarvis (~5-6 hrs)
- [ ] Task delegation protocol
- [ ] Subagent spawning + result aggregation
- [ ] Error handling + rollback

### F.2 Agent Chain/Group Architecture (~6-8 hrs)
- [ ] Chain: Main to [Analyzer to Planner to Implementer] to Main
- [ ] Group: Main to [Agent1, Agent2, Agent3] to Aggregator to Main
- [ ] Context isolation — free up main thread
- [ ] Ulfhedthnar Frenzy Mode integration (max parallel agent spawning)

### F.3 Agent Library — Comprehensive Sweep (~3-4 hrs)
- [ ] Survey ALL 45 marketplaces for agents
- [ ] Group by functional similarity (10+ categories)
- [ ] "Best in class" per category

### F.4 Best-in-Class Agent Implementation (~4-5 hrs)
- [ ] Update Jarvis's 12 operational agents with winning patterns
- [ ] Test + rollback plan

---

## Phase G: Research Implementation Backlog (~40 hrs)

**Dependencies**: A, B

### G.1 Consolidated Comparison Action Items (~20 hrs)
From `consolidated-comparison-2026-02-05.md`:
- [ ] Session log archive system
- [ ] State file validation (JSON schemas)
- [ ] Explicit state machines for AC components
- [ ] Decision tree interpreter

### G.2 Design Philosophy Implementation (~20 hrs)
From `consolidated-design-philosophy-2026-02-05.md`:
- [ ] Constraints-first patterns in frontmatter
- [ ] Workflow schemas (YAML)
- [ ] Degradation hierarchy (Optimal to Minimal)
- [ ] Circuit breaker pattern

### G.3 OpenClaw Patterns (~audit only)
- [ ] Verify existing implementations cover pre-compaction flush, config validation, hook isolation, token tracking

---

## Phase H: AIfred Integration Completion (~39 hrs)

**Dependencies**: A

### H.1 M7 — Parallel Development Integration (~8-16 hrs)
### H.2 M9 — TELOS Strategic Framework (~8-12 hrs)
### H.3 M10 — Upgrade System / AC-07 external updates (~8-12 hrs)
### H.4 M11 — Final Integration (~7-11 hrs)

---

## Phase I: Command-to-Skill Migration (~20 hrs)

**Dependencies**: B
**Source**: `proud-noodling-lovelace.md`

### I.1 Remove 4 conflicting commands (help, status, compact, clear) (~2 hrs)
### I.2 Convert 30+ commands to skills (~12 hrs)
### I.3 Migrate 17 auto-* commands to autonomous-commands skill (~3 hrs)
### I.4 Documentation sweep (62 files) (~3 hrs)

---

## Phase J: Aion Script Development (~30 hrs)

**Dependencies**: C (for dashboard)

### J.1 Ennoia — Session Orchestrator (~12 hrs)
From `ennoia-aion-script-design.md`: idle scheduling, priority queue, intent formation

### J.2 Virgil — Codebase Navigator (~10 hrs)
From `virgil-angel-script-design.md`: OSC 8 hyperlinks, mode detection, Virgil Says engine

### J.3 Watcher Dashboard Redesign (~8 hrs)
From `watcher-aion-script-redesign.md`: context gauge, burn rate, event feed

---

## Timeline Summary

| Phase | Focus | Hours | Dependencies | Start |
|-------|-------|-------|-------------|-------|
| **A** | Complete Roadmap I Phase 6 | 10-14 | None | Immediate |
| **B** | Stream 2 Implementation + AC-10 | 21-28 | A (partial) | After A.1-A.3 |
| **C** | Mac Studio Infrastructure | 20 | Mac Studio (Feb 12) | Feb 12+ |
| **D** | AI/ML First Round | 15-20 | C | After C |
| **E** | Memory System Architecture | 30-40 | C (partial) | Parallel with D |
| **F** | Multi-Agent Coordination | 16-20 | B.5, B.7 | After B |
| **G** | Research Implementation | 40 | A, B | After A, B |
| **H** | AIfred Integration | 39 | A | After A |
| **I** | Command Migration | 20 | B | After B |
| **J** | Aion Scripts | 30 | C | After C |
| **Total** | | **~242-272** | | |

### Parallel Execution

```
A (10-14h) --> B (21-28h) --> F (16-20h)
          \--> H (39h)    --> I (20h)
          \--> G (40h)

C (20h, Feb 12) --> D (15-20h)
             \----> E (30-40h, parallel with D)
             \----> J (30h)
```

**Critical path**: A to B to F + C to E = ~140-170 hours

### Version Progression

| Milestone | Version |
|-----------|---------|
| Current | v5.9.0 |
| Phase A complete | v5.9.5 (all 9 Hippocrenae ACs active) ← **HERE** (2026-02-09, commit 5b38374) |
| Phase B complete | v5.10.0 (Stream 2 + AC-10 Ulfhedthnar) |
| Phase C complete | v5.11.0 (Mac Studio infrastructure) |
| Phase D complete | v5.12.0 (AI/ML first round) |
| Phase E complete | v6.0.0 (Memory System v2) |
| Phase F complete | v6.1.0 (multi-agent coordination) |
| All phases complete | v6.5.0 |

---

## Risk Assessment

| Risk | Severity | Mitigation |
|------|----------|------------|
| Mac Studio delivery delay | HIGH | Start E.1-E.3 (independent) |
| vLLM performance on M4 Max | MEDIUM | Fallback to cloud models |
| Memory architecture decision paralysis | MEDIUM | Time-box E.1 to 1 week |
| Hook consolidation regressions | MEDIUM | Extensive testing + rollback plan |
| JICM integration bugs | MEDIUM | Phased rollout, degradation testing |
| Agent coordination overengineering | MEDIUM | Implement incrementally |

---

## Document References

| Need | File |
|------|------|
| Roadmap I | `projects/project-aion/roadmap.md` |
| AIfred integration | `projects/project-aion/evolution/aifred-integration/roadmap.md` |
| Tool reconstruction | `.claude/context/reference/tool-reconstruction-backlog.md` |
| Hook consolidation | `.claude/context/reference/hook-consolidation-plan.md` |
| Context engineering | `.claude/context/research/context-engineering-marketplace-analysis.md` |
| Memory palace | `.claude/context/research/night-market-memory-palace-deep-dive.md` |
| OMC patterns | `.claude/context/research/omc-skill-composition-deep-dive.md` |
| Self-constitution | `.claude/proposals/jarvis-self-constitution-proposal.md` |
| Pipeline design | `.claude/plans/pipeline-design-v3.md` |
| Autopoietic paradigm | `.claude/context/psyche/autopoietic-paradigm.md` |
| AC-10 Ulfhedthnar spec | `.claude/context/components/AC-10-ulfhedthnar.md` *(to be created in B.7)* |
| Orchestration overview | `.claude/context/components/orchestration-overview.md` |

---

### Architectural Note: Hippocrenae + Ulfhedthnar

The autonomic system is divided into two categories:

**Hippocrenae** (AC-01 through AC-09) — The Nine Muses. Standard operational harmony:
| AC | Muse Domain | Function |
|----|-------------|----------|
| AC-01 | Calliope (Epic Poetry) | Self-Launch — the epic beginning |
| AC-02 | Terpsichore (Dance) | Wiggum Loop — the rhythmic work cycle |
| AC-03 | Clio (History) | Milestone Review — recording achievements |
| AC-04 | Mnemosyne (Memory)* | JICM — guardian of context memory |
| AC-05 | Thalia (Comedy/Pastoral) | Self-Reflection — finding patterns in the pastoral |
| AC-06 | Polyhymnia (Sacred Poetry) | Self-Evolution — sacred transformation |
| AC-07 | Urania (Astronomy) | R&D Cycles — gazing outward for discovery |
| AC-08 | Erato (Lyric Poetry) | Maintenance — the lyric of clean code |
| AC-09 | Melpomene (Tragedy) | Session Completion — the final act |

*Mnemosyne is the Titaness mother of the Muses, not a Muse herself — fitting for JICM which births and preserves all context.

**Ulfhedthnar** (AC-10) — The Wolf-Warrior. Hidden Neuros override:
- Exists outside the Hippocrenae hierarchy
- Dormant until barriers are detected
- Engages berserker problem-solving protocols
- Returns to dormancy after resolution

---

### Phase A Verification Summary (2026-02-09)

| Component | Verdict | Operational | Notes |
|-----------|---------|-------------|-------|
| AC-06 Evolution | Scaffolded | 60% | Spec + detector + state; /evolve pipeline not built |
| AC-07 R&D | Scaffolded | 80% | Tracker + state; cross-ref docs missing |
| AC-08 Maintenance | Fully operational | 95% | Scripts tested (43/43), reports generated |
| PR-13 Monitoring | Operational | 90% | Scoring distributed; all else solid |
| PR-14 SOTA Catalog | Complete | 100% | 55 entries, 9 categories |
| Orchestration v1.1.0 | Updated | 100% | All 9 Hippocrenae active |

**Overall Phase A**: All deliverables present and committed. AC-08, PR-13, PR-14 are fully operational. AC-06 and AC-07 are scaffolded (specs, state files, scripts) with residual implementation gaps carried forward to Phase B.

---

*Roadmap II — Mac Studio Era & Beyond*
*Jarvis v5.9.0 to v6.5.0 — Hippocrenae + Ulfhedthnar*
*Created 2026-02-09, Updated 2026-02-09 (Phase A verified)*
