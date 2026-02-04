# Lessons Index

**Purpose**: Categorical and chronological index of problems, solutions, and patterns.

**Updated**: 2026-02-04 (PAT-005: tmux self-injection limitation)

---

## Problems

Problems identified during Jarvis operation.

| Date | ID | Summary | Status |
|------|----|---------|--------|
| 2026-01-17 | PRB-001 | AC-02 Wiggum Loop metrics not being captured | Open |
| 2026-01-17 | PRB-002 | Telemetry system not instrumented | Open |

---

## Solutions

Solutions proposed or implemented for identified problems.

| Date | ID | Problem | Status |
|------|----|---------|--------|
| 2026-01-18 | SOL-001 | PRB-002: PR-13 Telemetry specifications complete | Pending Implementation |

---

## Patterns

Recurring patterns discovered through reflection and R&D.

| Date | ID | Summary | Frequency |
|------|----|---------|-----------|
| 2026-01-18 | PAT-001 | Claude Code features evolve rapidly; regular R&D review valuable | Ongoing |
| 2026-01-18 | PAT-002 | MCP tool deferral (auto:N) reduces context usage | New Discovery |
| 2026-01-18 | PAT-003 | PreToolUse additionalContext enables dynamic context injection | New Discovery |
| 2026-01-18 | PAT-004 | Single-agent ReAct loop (Wiggum) more reliable than multi-agent swarms | Confirmed |
| 2026-02-04 | PAT-005 | **tmux self-injection fails from within Claude Code** | Critical Discovery |

---

## By Category

### Context Management
- PAT-002: MCP tool deferral (auto:N) reduces context usage
- PAT-003: PreToolUse additionalContext enables dynamic context injection

### Tool Selection
- PAT-001: Claude Code features evolve rapidly; regular R&D review valuable

### Hook Integration
- PAT-003: PreToolUse additionalContext enables dynamic context injection

### Agent Patterns
- PAT-004: Single-agent ReAct loop (Wiggum) more reliable than multi-agent swarms

### Signal Architecture / tmux Integration
- PAT-005: tmux self-injection fails from within Claude Code
  - **Full lesson**: `lessons/tmux-self-injection-limitation.md`
  - **Key insight**: Bash tool calls block TUI event loop; keystrokes queue unpredictably
  - **Solution**: All prompt injection must come from external processes (watcher pattern)
  - **Affects**: JICM, command-signal-protocol, any autonomous prompt submission

### Documentation
*None yet*

### R&D Findings (2026-01-18)

Key discoveries from full-scale R&D cycle:

**Claude Code 2026 Features**:
- Setup hook event (--init/--maintenance)
- PreToolUse additionalContext injection
- auto:N MCP tool search threshold
- plansDirectory setting (IMPLEMENTED)
- ${CLAUDE_SESSION_ID} substitution
- /rename and /resume commands

**MCP Ecosystem**:
- 1,200+ servers available in ecosystem
- Local RAG MCP for private semantic search
- Zapier MCP for workflow automation (5000+ integrations)
- Vector database + RAG MCPs mature

**Agent Patterns**:
- Reflexion loop pattern confirmed (already have via Wiggum)
- Self-Refine pattern (generate → critique → revise)
- Single-agent preferred over multi-agent swarms
- Dual-component reflection (separate telemetry from execution)

**Full Report**: `projects/project-aion/reports/rd-cycle-2026-01-18.md`

---

---

## Evolution Proposals (from Reflection)

| Date | ID | Summary | Priority | Status |
|------|----|---------|----------|--------|
| 2026-01-20 | EVO-2026-01-020 | Session State Auto-Update | Low | Queued |

See `.claude/evolution/evolution-queue.yaml` for full proposal details.

---

*Index maintained by AC-05 Self-Reflection — Updated 2026-02-04*
