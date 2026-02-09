# Patterns Index

Reusable implementation patterns organized by category. Consult before implementing significant tasks.

**Last Updated**: 2026-02-08 (Cross-reference audit)
**Total Patterns**: 51
**Audit Report**: `.claude/reports/pattern-cross-reference-audit-2026-02-08.md`

---

## Quick Reference — Mandatory Patterns

| Task Type | Pattern | Strictness |
|-----------|---------|------------|
| Multi-step implementation | [wiggum-loop-pattern](wiggum-loop-pattern.md) | **ALWAYS** |
| Milestone completion | [milestone-review-pattern](milestone-review-pattern.md) | **ALWAYS** |
| Tool/agent selection | [selection-intelligence-guide](selection-intelligence-guide.md) | **ALWAYS** |
| Context management | [jicm-pattern](jicm-pattern.md) | **ALWAYS** |
| Session start | [startup-protocol](startup-protocol.md) | **ALWAYS** |
| Session end | [session-exit](../workflows/session-exit.md) | **ALWAYS** |

---

## Session Lifecycle

Patterns for session management from start to finish.

| Pattern | Purpose | When to Use |
|---------|---------|-------------|
| [startup-protocol](startup-protocol.md) | AC-01 three-phase startup | Every session start |
| [session-start-checklist](session-start-checklist.md) | Mandatory session start steps | Every session start |
| [session-completion-pattern](session-completion-pattern.md) | AC-09 clean session exit | Every session end |

---

## Core Behaviors

Fundamental patterns that govern how Jarvis operates.

| Pattern | Purpose | When to Use |
|---------|---------|-------------|
| [wiggum-loop-pattern](wiggum-loop-pattern.md) | AC-02 multi-pass verification | **DEFAULT for all tasks** |
| [jicm-pattern](jicm-pattern.md) | Intelligent context management | Context approaching limits |
| [parallelization-strategy](parallelization-strategy.md) | Parallel vs sequential execution | Multi-tool/agent tasks |
| [self-interruption-prevention](self-interruption-prevention.md) | Prevent unintended work stops | When blockers encountered |

---

## Selection & Routing

Patterns for choosing the right tool, agent, or approach.

| Pattern | Purpose | When to Use |
|---------|---------|-------------|
| [selection-intelligence-guide](selection-intelligence-guide.md) | Quick tool/agent selection reference | Before any task |
| [agent-selection-pattern](agent-selection-pattern.md) | Detailed agent vs skill vs tool decision | Complex routing decisions |
| [tool-selection-intelligence](tool-selection-intelligence.md) | Research-backed tool precedence theory | Research/exploration tasks |
| [selection-validation-tests](selection-validation-tests.md) | 10 test cases for selection accuracy | Validating selection logic |

---

## MCP Management

Patterns for Model Context Protocol server management.

| Pattern | Purpose | When to Use |
|---------|---------|-------------|
| [mcp-loading-strategy](mcp-loading-strategy.md) | 3-tier MCP loading approach | Session start, MCP decisions |
| [context-budget-management](context-budget-management.md) | Token budgets and MCP tiers | Context optimization |
| [observation-masking-pattern](observation-masking-pattern.md) | Reduce tool output context (80%+ → 60-80% savings) | Large tool outputs, long sessions |
| [progressive-constraint-encoding](progressive-constraint-encoding.md) | 3-level constraint encoding for artifact generation prompts | Skill development, prompt engineering |
| [mcp-design-patterns](mcp-design-patterns.md) | Per-MCP best practices | Using specific MCPs |
| [mcp-validation-harness](mcp-validation-harness.md) | 5-phase MCP validation | Adding new MCPs |
| [batch-mcp-validation](batch-mcp-validation.md) | Batch testing for token limits | Validating MCP groups |

---

## Self-Improvement (Tier 2)

Patterns for autonomous self-improvement cycles.

| Pattern | Purpose | When to Use |
|---------|---------|-------------|
| [self-improvement-pattern](self-improvement-pattern.md) | Full self-improvement cycle | Idle time, session end |
| [self-reflection-pattern](self-reflection-pattern.md) | AC-05 session learnings | After significant work |
| [self-evolution-pattern](self-evolution-pattern.md) | AC-06 capability growth | Queued improvements |
| [rd-cycles-pattern](rd-cycles-pattern.md) | AC-07 research & development | New tool exploration |
| [maintenance-pattern](maintenance-pattern.md) | AC-08 health checks | Periodic maintenance |

---

## Development & Git

Patterns for code development and version control.

| Pattern | Purpose | When to Use |
|---------|---------|-------------|
| [milestone-review-pattern](milestone-review-pattern.md) | Validate milestone completion | PR/milestone completion |
| [branching-strategy](branching-strategy.md) | Git branching for Project Aion | Branch decisions |
| [cross-project-commit-tracking](cross-project-commit-tracking.md) | Multi-repo commit coordination | Working across repos |

---

## Capability Architecture (AIfred Ported)

Patterns for building layered, deterministic capabilities.

| Pattern | Purpose | When to Use |
|---------|---------|-------------|
| [capability-layering-pattern](capability-layering-pattern.md) | 5-layer capability stack | Creating new automated capabilities |
| [code-before-prompts-pattern](code-before-prompts-pattern.md) | Deterministic code over AI inference | Skill/command implementation |
| [command-invocation-pattern](command-invocation-pattern.md) | CLI/Agent/Skill routing | Designing new commands |
| [agent-invocation-pattern](agent-invocation-pattern.md) | Agent definition and invocation | Creating/invoking agents |
| [autonomous-execution-pattern](autonomous-execution-pattern.md) | Scheduled headless execution | Cron/systemd automation |

---

## Design & Planning

Patterns for design review and planning decisions.

| Pattern | Purpose | When to Use |
|---------|---------|-------------|
| [prompt-design-review](prompt-design-review.md) | PARC pre-implementation check | Before significant changes |
| [memory-storage-pattern](memory-storage-pattern.md) | When/how to store in Memory MCP | Deciding what to persist |
| [workspace-path-policy](workspace-path-policy.md) | Where projects and docs live | File placement decisions |

---

## Infrastructure

Patterns for service and infrastructure management.

| Pattern | Purpose | When to Use |
|---------|---------|-------------|
| [service-lifecycle-pattern](service-lifecycle-pattern.md) | Ephemeral service management | Docker/service work |
| [project-reporting-pattern](project-reporting-pattern.md) | Run reports + performance analysis | Demo/report tasks |
| [multi-repo-credential-pattern](multi-repo-credential-pattern.md) | Credential management across repos | Multi-repo operations |

---

## Automation & Integration

Patterns for automation and component integration.

| Pattern | Purpose | When to Use |
|---------|---------|-------------|
| [command-signal-protocol](command-signal-protocol.md) | Signal-based command invocation | Watcher integration |
| [component-interaction-protocol](component-interaction-protocol.md) | AC component communication | Component development |
| [override-disable-pattern](override-disable-pattern.md) | Suppress behaviors when needed | Troubleshooting |
| [automated-context-management](automated-context-management.md) | Smart checkpoint workflow | Context optimization |
| [jicm-continuation-prompt](jicm-continuation-prompt.md) | JICM post-clear continuation prompt | After /clear restore |

---

## Plugin & Skill Management

Patterns for managing plugins and skills.

| Pattern | Purpose | When to Use |
|---------|---------|-------------|
| [plugin-decomposition-pattern](plugin-decomposition-pattern.md) | Extract/customize skills from plugins | Plugin customization |

---

## Testing & Validation

Patterns for testing and setup validation.

| Pattern | Purpose | When to Use |
|---------|---------|-------------|
| [setup-validation](setup-validation.md) | Validate setup completeness | After setup changes |
| [autonomic-testing-framework](autonomic-testing-framework.md) | Test autonomic components | AC development |
| [tdd-enforcement-pattern](tdd-enforcement-pattern.md) | Proof-of-work TDD (test before impl) | Code changes, bug fixes, refactors |

---

## Architecture

Patterns defining Archon structure and organization.

| Pattern | Purpose | When to Use |
|---------|---------|-------------|
| [archon-architecture-pattern](archon-architecture-pattern.md) | Three-layer Archon structure | Designing new Archons |
| [organization-pattern](organization-pattern.md) | File placement decisions | Creating new files/directories |

---

## Reference (Less Common)

Patterns used less frequently or for specific scenarios.

| Pattern | Purpose |
|---------|---------|
| [worktree-shell-functions](worktree-shell-functions.md) | Git worktree helpers |
| [hook-consolidation-assessment](hook-consolidation-assessment.md) | Hook audit analysis |
| [self-monitoring-commands](self-monitoring-commands.md) | Self-monitoring command set |

---

## Usage Guidelines

### Before Implementing Tasks

1. Check if a pattern exists for the task type
2. **Mandatory patterns MUST be applied** (marked as ALWAYS)
3. Document any pattern deviations
4. Update pattern docs if pattern evolves

### Creating New Patterns

Create a pattern when:
- Same approach is used 3+ times
- Multiple commands share similar logic
- A decision framework would help consistency

### Pattern Strictness Levels

| Level | Meaning |
|-------|---------|
| **ALWAYS** | Mandatory — never skip |
| **Recommended** | Apply unless good reason not to |
| **Optional** | Apply when relevant |

---

*Patterns Index — Jarvis Organization Architecture Phase 6*
