# Consolidated Codebase Comparison Report

**Generated**: 2026-02-05
**Researcher**: Jarvis Deep Research Team (4 parallel agents)
**Purpose**: Feature comparison and implementation roadmap for Jarvis enhancement

---

## Executive Summary

Four codebases were analyzed for potential Jarvis integration opportunities:

| Project | Stars | Focus Area | Top Innovation |
|---------|-------|------------|----------------|
| **Vestige** | 340+ | Dynamic Memory | FSRS-6 spaced repetition + semantic search |
| **Marvin** | 819 | Chief of Staff | Session logs + retrospective reporting |
| **OpenClaw** | 164K | Multi-Channel | Gateway control plane + skills system |
| **AFK Code** | 62 | Remote Monitoring | PTY + Unix socket remote control |

### Critical Gaps Identified in Jarvis

| Gap | Severity | Solution Source |
|-----|----------|-----------------|
| No remote visibility/control | **CRITICAL** | AFK Code |
| Static memory (no decay/retrieval strengthening) | **HIGH** | Vestige |
| No session history archive | **HIGH** | Marvin |
| No retrospective reporting | **HIGH** | Marvin |
| No formalized skills system | **MAJOR** | OpenClaw |
| Limited hooks (git only) | **MAJOR** | OpenClaw |
| Goals vs tasks conflated | **MEDIUM** | Marvin |
| No semantic search for memories | **MEDIUM** | Vestige |

---

## Feature Matrix

### Memory & Knowledge Management

| Feature | Vestige | Marvin | OpenClaw | AFK Code | Jarvis |
|---------|---------|--------|----------|----------|--------|
| Semantic search | ✅ Hybrid BM25+vector | ❌ | ✅ Via skills | ❌ | ❌ |
| Temporal decay | ✅ FSRS-6 | ❌ | ❌ | ❌ | ❌ |
| Retrieval strengthening | ✅ Dual-strength | ❌ | ❌ | ❌ | ❌ |
| Knowledge graph | ❌ | ❌ | ❌ | ❌ | ✅ Memory MCP |
| Duplicate detection | ✅ Prediction error | ❌ | ❌ | ❌ | ❌ Manual |
| Session logs archive | ❌ | ✅ Daily logs | ✅ JSONL | ✅ JSONL | ❌ Overwrites |

### Session & Context Management

| Feature | Vestige | Marvin | OpenClaw | AFK Code | Jarvis |
|---------|---------|--------|----------|----------|--------|
| Session continuity | ✅ Memory persistence | ✅ State files | ✅ JSONL | ✅ JSONL | ✅ session-state.md |
| Structured briefing | ❌ | ✅ /start | ✅ AGENTS.md | ❌ | ⚠️ AC-01 (partial) |
| Checkpointing | ❌ | ✅ /update | ✅ Auto | ❌ | ✅ JICM |
| Context compression | ❌ | ❌ | ❌ | ❌ | ✅ JICM v5 |
| Goals vs tasks | ❌ | ✅ Separate | ⚠️ Partial | ❌ | ❌ Mixed |

### Automation & Control

| Feature | Vestige | Marvin | OpenClaw | AFK Code | Jarvis |
|---------|---------|--------|----------|----------|--------|
| Remote monitoring | ❌ | ❌ | ✅ Gateway | ✅ Full | ❌ |
| Remote control | ❌ | ❌ | ✅ Full | ✅ Full | ❌ |
| Multi-channel | ❌ | ❌ | ✅ 10+ platforms | ✅ 3 platforms | ❌ |
| Skills system | ❌ | ⚠️ Basic | ✅ 3-tier | ❌ | ⚠️ Ad-hoc |
| Hooks framework | ❌ | ❌ | ✅ Full lifecycle | ❌ | ✅ Git hooks |
| Cron scheduling | ❌ | ❌ | ✅ Built-in | ❌ | ❌ |
| Multi-agent | ❌ | ❌ | ✅ Routing | ❌ | ✅ Subagents |

### Reporting & Analytics

| Feature | Vestige | Marvin | OpenClaw | AFK Code | Jarvis |
|---------|---------|--------|----------|----------|--------|
| Weekly reports | ❌ | ✅ /report | ⚠️ Logs | ❌ | ❌ |
| Self-reflection | ❌ | ⚠️ Thought partner | ❌ | ❌ | ✅ AC-05 |
| Progress tracking | ❌ | ✅ Goals table | ⚠️ Via skills | ❌ | ✅ TodoWrite |
| Session summaries | ❌ | ✅ /end | ✅ JSONL | ✅ Relay | ⚠️ Manual |

---

## Prioritized Implementation Recommendations

### Priority 1: CRITICAL (Implement Immediately)

#### 1.1 Remote Monitoring via Telegram (from AFK Code)

**Why Critical**: No visibility into overnight/unattended Jarvis sessions. Failures go unnoticed.

**Implementation**:
1. Install `node-pty` and `grammy` (Telegram SDK)
2. Create `/Users/aircannon/Claude/Jarvis/.claude/services/telegram-relay/`
3. Port `session-manager.ts` pattern for JSONL watching
4. Implement read-only message relay first (LOW RISK)
5. Add command whitelist for bidirectional control (Phase 2)

**Effort**: 1-2 weeks
**Risk**: Low (separate process, graceful failure)
**Value**: HIGH — Know what Jarvis is doing from anywhere

#### 1.2 Session Log Archive (from Marvin)

**Why Critical**: Session history lost on each `/end-session`. No retrospective capability.

**Implementation**:
1. Create `.claude/sessions/` directory structure
2. Modify `/end-session` to append to `sessions/{DATE}.md` instead of overwriting
3. Add session metadata (start time, tasks completed, tokens used)
4. Preserve `session-state.md` for current state (compatibility)

**Effort**: 2-3 hours
**Risk**: Very Low
**Value**: HIGH — Historical context + foundation for reporting

---

### Priority 2: HIGH (Implement This Month)

#### 2.1 Vestige MCP Integration

**Why High**: Jarvis memories are static. No semantic search, no temporal decay.

**Implementation**:
1. `cargo build --release` Vestige from source
2. Configure per-project storage in `.vestige/`
3. Create `/ingest-context` command to push lessons to Vestige
4. Create `/search-memory` command for semantic retrieval
5. Integrate with AC-01 for automatic context retrieval

**Effort**: 3-4 sessions
**Risk**: Low (additive, doesn't replace existing systems)
**Value**: HIGH — Smart memory retrieval, natural forgetting

#### 2.2 Weekly Reporting Command (from Marvin)

**Why High**: No way to generate progress summaries from session history.

**Implementation**:
1. Requires Session Log Archive first (2.1)
2. Create `/report` command that parses `sessions/*.md`
3. Generate summary by date range (default: last 7 days)
4. Include: tasks completed, decisions made, blockers, patterns

**Effort**: 2-3 hours
**Risk**: Very Low
**Value**: HIGH — Stakeholder updates, performance tracking

#### 2.3 Goals vs Tasks Separation (from Marvin)

**Why High**: `current-priorities.md` mixes strategic goals with tactical tasks.

**Implementation**:
1. Create `.claude/context/goals.md` for long-term objectives
2. Refactor `current-priorities.md` for weekly/daily tasks only
3. Add goal tracking table (Goal | Status | Progress | Notes)
4. Reference goals in `/report` for progress alignment

**Effort**: 1-2 hours
**Risk**: Very Low
**Value**: MEDIUM-HIGH — Better long-term planning

---

### Priority 3: MEDIUM (Implement Next Quarter)

#### 3.1 Formalized Skills System (from OpenClaw)

**Why Medium**: Current skills are ad-hoc. No dependency checking, no auto-discovery.

**Implementation**:
1. Define `SKILL.md` frontmatter schema (name, requires, install)
2. Implement three-tier precedence (bundled → managed → workspace)
3. Add requirement checking (binaries, env vars, config)
4. Create skill auto-discovery on session start

**Effort**: 1-2 weeks
**Risk**: Medium (changes skill loading mechanism)
**Value**: MEDIUM — Better extensibility, dependency management

#### 3.2 Extended Hooks Framework (from OpenClaw)

**Why Medium**: Current hooks are git-only. Missing application lifecycle events.

**Implementation**:
1. Add hook events: SessionStart, SessionEnd, TaskComplete, ErrorOccurred
2. Extend `settings.json` hook configuration
3. Implement hook dispatch for new events
4. Document hook API for custom automation

**Effort**: 1 week
**Risk**: Medium (core behavior change)
**Value**: MEDIUM — More automation triggers

#### 3.3 Thought Partner Mode (from Marvin)

**Why Medium**: Jarvis executes but doesn't challenge decisions.

**Implementation**:
1. Add personality mode to `jarvis-identity.md`
2. Create `/brainstorm` command that activates critical thinking
3. In this mode: ask probing questions, play devil's advocate
4. Exit with `/execute` to return to normal mode

**Effort**: 3-4 hours
**Risk**: Low (personality change only)
**Value**: MEDIUM — Better decision support

---

### Priority 4: LOW (Evaluate Later)

#### 4.1 Full Gateway Control Plane (from OpenClaw)

**Why Low**: Major architectural change. Only valuable if multi-channel becomes a requirement.

**When to Reconsider**: If Jarvis needs to operate across Slack + Discord + Telegram simultaneously.

**Effort**: 4-6 weeks
**Risk**: High (fundamental architecture change)

#### 4.2 Temporal Decay for All Context (from Vestige)

**Why Low**: Full FSRS-6 integration requires significant refactoring.

**When to Reconsider**: After Vestige MCP is proven valuable in Phase 2.

**Effort**: 8-12 sessions
**Risk**: Medium (changes memory model)

---

## Implementation Roadmap

```
Week 1-2: CRITICAL FOUNDATION
├── Day 1-2: Session Log Archive (Marvin pattern)
├── Day 3-7: Telegram Relay - Read Only (AFK Code pattern)
└── Day 8-14: Telegram Relay - Bidirectional with safety

Week 3-4: HIGH VALUE ADDITIONS
├── Day 15-18: Vestige MCP Installation & Configuration
├── Day 19-21: /report Command (requires session logs)
└── Day 22-28: Goals vs Tasks Separation + Integration

Week 5-8: MEDIUM PRIORITY
├── Week 5: Skills System Foundation
├── Week 6: Skills Auto-Discovery + Requirements
├── Week 7: Extended Hooks Framework
└── Week 8: Thought Partner Mode + Testing

Week 9+: EVALUATION & OPTIMIZATION
├── Review Vestige usage patterns
├── Assess need for Gateway architecture
└── Consider full temporal decay integration
```

---

## Risk Assessment

| Implementation | Technical Risk | Integration Risk | Reversibility |
|----------------|---------------|------------------|---------------|
| Session Log Archive | Very Low | Very Low | Easy (delete dir) |
| Telegram Relay | Low | Low | Easy (separate process) |
| Vestige MCP | Low | Low-Medium | Easy (disable MCP) |
| Weekly Reporting | Very Low | Very Low | Easy (delete command) |
| Goals Separation | Very Low | Low | Easy (merge files) |
| Skills System | Medium | Medium | Medium (refactor skills) |
| Extended Hooks | Medium | Medium | Medium (config changes) |
| Gateway Architecture | High | High | Difficult |

---

## Architectural Considerations

### Complementary vs Replacement

| Feature | Approach | Rationale |
|---------|----------|-----------|
| Vestige Memory | **Complementary** | Add semantic search alongside existing Memory MCP |
| Session Logs | **Complementary** | Archive history, keep session-state.md for current |
| Telegram Relay | **Complementary** | New capability, doesn't change core |
| Skills System | **Evolution** | Formalize existing ad-hoc skills |
| Hooks Framework | **Evolution** | Extend existing hook system |
| Gateway | **Replacement** | Would fundamentally change architecture (defer) |

### Integration Strategy

```
                    ┌─────────────────────────────────┐
                    │         Jarvis Core             │
                    │  (Claude Code + Autonomics)     │
                    └─────────────┬───────────────────┘
                                  │
         ┌────────────────────────┼────────────────────────┐
         │                        │                        │
    ┌────▼────┐            ┌─────▼─────┐            ┌─────▼─────┐
    │ Memory  │            │  Session  │            │  Remote   │
    │ Layer   │            │  Layer    │            │  Layer    │
    │         │            │           │            │           │
    │ Vestige │            │ Log       │            │ Telegram  │
    │ Memory  │            │ Archive   │            │ Relay     │
    │ MCP     │            │ Reports   │            │           │
    └─────────┘            └───────────┘            └───────────┘
```

---

## Individual Report References

| Project | Report Location | Lines |
|---------|-----------------|-------|
| Vestige | `.claude/reports/research/vestige-analysis-2026-02-05.md` | 948 |
| Marvin | `.claude/reports/research/marvin-analysis-2026-02-04.md` | ~400 |
| OpenClaw | `.claude/reports/research/openclaw-analysis-2026-02-05.md` | 1,249 |
| AFK Code | `.claude/reports/research/afk-code-analysis-2026-02-05.md` | ~600 |

---

## Next Steps

1. **Review this report** with user for priority validation
2. **Begin Week 1** with Session Log Archive implementation
3. **Set up Telegram bot** credentials for remote monitoring
4. **Install Vestige** binary and configure MCP

---

*Generated by Jarvis Deep Research Team — 4 parallel agents, ~195K tokens analyzed*
