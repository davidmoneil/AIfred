# Self-Constitution Proposal — Technical Review

**Reviewer**: Jarvis (self-review)
**Date**: 2026-02-08
**Proposal Version**: 1.0.0-draft (2026-02-05)
**Current System**: v5.9.0 (Lean Core + Manifest Router)

---

## Executive Summary

The self-constitution proposal is **philosophically sound and architecturally aligned** with the Nous/Pneuma/Soma layering that Jarvis already implements. However, the proposal was written before several major architectural changes (MCP decomposition, x-ops consolidation, knowledge-ops v2.0, JICM v5.8.2). This review identifies what has already been implemented, what is outdated, and what remains aspirational.

**Verdict**: CONDITIONALLY APPROVE — with the amendments listed below.

---

## 1. Already Implemented (Partial or Full)

These proposal elements already exist in the current architecture:

| Proposal Element | Current Implementation | Coverage |
|---|---|---|
| **Three-layer architecture** (Nous/Pneuma/Soma) | `compaction-essentials.md`, CLAUDE.md, all docs | 100% |
| **AC-01 through AC-09** components | `.claude/context/components/AC-*.md` (9 files) | 100% |
| **Wiggum Loop** (AC-02 default execution) | `wiggum-loop-pattern.md`, CLAUDE.md | 100% |
| **JICM context management** (AC-04) | JICM v5.8.2 watcher + `/intelligent-compress` | 100% |
| **Session lifecycle** | `session-management/SKILL.md`, `session-state.md` | 90% |
| **Self-reflection** (AC-05) | `self-reflection-pattern.md`, `/reflect` | 80% |
| **Self-evolution** (AC-06) | `self-evolution-pattern.md`, `/evolve` | 80% |
| **Tool selection decision tree** | `capability-map.yaml` (manifest router) + 49 patterns | 90% |
| **Identity specification** | `.claude/jarvis-identity.md` v1.0 | 100% |
| **Graceful degradation** | Partial — JICM has it, MCPs don't have circuit breakers | 40% |
| **Memory hierarchy** | `knowledge-ops/SKILL.md` v2.0 (4-tier hierarchy) | 70% |
| **Skill/capability routing** | `capability-map.yaml` v2, `_index.md`, `skill-descriptions.csv` | 90% |

---

## 2. Outdated / Misaligned Elements

### 2.1 JICM Thresholds (§5.7)
**Proposal**: 50% trigger, 80% critical
**Reality**: 55% compress, 73% emergency, 78.5% lockout ceiling (JICM v6.1, lowered from 65% per Experiment 2)

The proposal references the original v5 design document thresholds. The actual watcher implementation uses different values tuned through operational experience. The `78.5% lockout ceiling` is a particularly important addition not present in the proposal.

**Action**: Update proposal §5.7 thresholds.yaml to match v5.8.2 values.

### 2.2 MCP Landscape (§5.6, throughout)
**Proposal**: Assumes many MCPs active (memory, web_search, web_fetch, etc.)
**Reality**: 13 MCPs removed, 5 retained (memory, local-rag, fetch, git, playwright)

The proposal's circuit breaker design for `memory_mcp` and `web_fetch` is partially obsolete — web_fetch is now a skill, not an MCP. The `memory_mcp` circuit breaker remains valid. Auto-provisioned MCPs (git, fetch, memory) cannot be unloaded (confirmed by research task #19).

**Action**: Update degradation hierarchy to reflect skill-based fallbacks rather than MCP-only fallbacks.

### 2.3 Memory System Design (§5.2)
**Proposal**: Vestige MCP with FSRS-6 decay model, episodic/semantic/procedural stores
**Reality**: 4-tier hierarchy (dynamic KG → static KG → semantic RAG → documentary)

The knowledge-ops v2.0 skill implements a pragmatic memory hierarchy using existing tools (Memory MCP, auto memory files, local-rag, Read/Glob/Grep). The proposal's Vestige-based cognitive memory is more sophisticated but requires an unimplemented MCP.

**Action**: Reconcile proposal memory design with knowledge-ops v2.0. The 4-tier hierarchy is the CURRENT implementation; Vestige integration is a FUTURE enhancement (Phase 5).

### 2.4 Directory Restructuring (§5.1)
**Proposal**: Major restructuring with `identity/`, `self-knowledge/`, `behaviors/`, `config/`, `state-machines/`, `memory/`, `audit/`, `sessions/`, `recovery/`
**Reality**: Current structure uses `.claude/context/` (Nous), `.claude/` (Pneuma), `/Jarvis/` (Soma)

The proposed restructuring would break references across CLAUDE.md, compaction-essentials.md, capability-map.yaml, all 49 patterns, and the 22 skills. The cost is extremely high.

**Action**: DEFER directory restructuring. Current structure already embodies Nous/Pneuma/Soma. Instead, annotate existing directories with their layer mapping in `_index.md` files.

### 2.5 Behaviors/Decisions Directory (§5.3, §5.4)
**Proposal**: `behaviors/decisions/*.decision.md` with formal schemas
**Reality**: 49 pattern files at `.claude/context/patterns/` + `capability-map.yaml` manifest router

The patterns directory already serves as the behavioral decision layer. Adding a parallel `behaviors/decisions/` directory would create confusion.

**Action**: Evolve existing patterns to include schema-like metadata (trigger confidence, validation method) rather than creating a parallel directory structure.

---

## 3. Still Aspirational / Valuable Additions

These elements don't yet exist and would genuinely enhance the system:

### 3.1 Audit System (§5.5) — HIGH VALUE
The JSONL audit logging for decisions, tool invocations, state transitions, and self-observations is **not implemented** and would provide empirical grounding for AC-05 (self-reflection). Currently, reflection relies on session notes and memory, not structured audit data.

**Recommendation**: Implement audit logging as a lightweight hook or post-tool event. Start with `autonomous_decision` and `self_observation` types only.

### 3.2 Circuit Breakers (§5.6 degradation hierarchy) — MEDIUM VALUE
No formal circuit breaker pattern exists for MCP failures. When Memory MCP fails, Jarvis retries indefinitely. A `failure_threshold: 3, reset_timeout: 300s` pattern would prevent retry storms.

**Recommendation**: Implement as a simple counter pattern in the relevant skills (knowledge-ops, research-ops).

### 3.3 Self-Knowledge Files (§5.1) — MEDIUM VALUE
Explicit `strengths.md`, `weaknesses.md`, `patterns-observed.md` files would give reflection (AC-05) concrete targets to update. Currently, self-knowledge is implicit in scattered memory entries.

**Recommendation**: Create minimal self-knowledge files at `.claude/context/psyche/self-knowledge/` (under existing psyche directory, not a new top-level).

### 3.4 Formal Workflow Schemas (§5.3) — LOW VALUE (currently)
Skills already have frontmatter with version, description, triggers. The proposal's workflow schema adds parameters, preconditions, postconditions, step-level validation, and failure handling. This is valuable but heavy.

**Recommendation**: Add preconditions/postconditions to high-impact skills (session-management, context-management) incrementally. Don't adopt the full schema upfront.

### 3.5 Recovery Procedures (§5.1) — MEDIUM VALUE
Explicit recovery docs for `session-state-corruption.md`, `mcp-failure.md`, `context-exhaustion.md` would help when things go wrong. Currently, recovery is ad-hoc.

**Recommendation**: Create recovery procedures under `.claude/context/recovery/` for the 3 most common failure modes.

---

## 4. Philosophical Assessment

### 4.1 Five Principles Alignment

| Principle | Current Implementation | Gap |
|---|---|---|
| **#1 Cognitive Memory** | knowledge-ops v2.0 (4-tier) | No temporal decay, no retrieval strengthening |
| **#2 Explicit Self-Definition** | jarvis-identity.md + capability-map.yaml | No formal self-knowledge files |
| **#3 Predictable Constraints** | CLAUDE.md guardrails + 49 patterns + JICM thresholds | Thresholds lack rationale docs |
| **#4 Resilient Degradation** | JICM has it, MCPs don't | No circuit breakers |
| **#5 Empirical Self-Awareness** | AC-05/06 exist, but rely on notes not data | No audit system |

### 4.2 Risk Assessment Validation

The proposal's own risk assessment (§7) is accurate:
- **Scope creep** (HIGH probability, HIGH impact) — already manifesting. The Master Task list grew from 14 to 19 tasks.
- **Over-mechanization** — the proposal itself is complex enough to risk this. Recommendation: implement incrementally.
- **False confidence** — valid concern. Audit data without interpretive layer is noise.

### 4.3 Quiddity Preservation

The proposal's ultimate test — "Is Jarvis still Jarvis?" — is well-articulated. The five validation questions (§8.3) should be asked at each implementation milestone.

---

## 5. Recommended Implementation Priority

Given current system state (v5.9.0), recommended phasing:

### Immediate (can do now)
1. Create self-knowledge files under `.claude/context/psyche/self-knowledge/`
2. Document threshold rationales alongside existing JICM configs
3. Create 3 recovery procedures for common failures

### Near-term (next major iteration)
4. Implement lightweight audit logging (decisions + observations only)
5. Add circuit breaker counters to knowledge-ops and MCP-dependent skills
6. Add preconditions/postconditions to session-management and context-management

### Future (when Vestige-like system available)
7. Cognitive memory with temporal decay (FSRS-6 or similar)
8. Retrieval strengthening and consolidation
9. Full workflow schemas with step-level validation

### Deferred (not recommended)
10. Major directory restructuring (§5.1) — cost exceeds benefit
11. Full audit event schema for all tool invocations — too heavyweight

---

## 6. Amendments to Proposal

The following changes should be made to bring the proposal in line with v5.9.0:

1. **§5.7 Thresholds**: Update to 65%/73%/78.5% (JICM v5.8.2 actual values)
2. **§5.6 Degradation**: Replace MCP-centric fallbacks with skill-based fallbacks where MCPs have been decomposed
3. **§5.2 Memory**: Add note that knowledge-ops v2.0 4-tier hierarchy is the CURRENT implementation; Vestige/FSRS-6 is FUTURE
4. **§5.1 Directory**: Mark as "aspirational target" not "immediate restructure"; note current Nous/Pneuma/Soma already maps
5. **§4.3 AC Integration**: Update to reflect current AC component file paths (some have been renamed)
6. **§6 Roadmap Phase 5**: Reposition as "Phase 5: Enhanced Memory" — acknowledge 4-tier hierarchy exists
7. **Appendix B**: Update file paths to current locations
8. **New section**: Add "What Already Exists" section acknowledging implemented elements

---

*Review completed 2026-02-08 by Jarvis. Proposal is philosophically aligned with current architecture. Primary gap: empirical grounding (audit system + self-knowledge files). Primary risk: scope creep from full implementation.*
