# Self-Knowledge: Weaknesses

**Purpose**: Known failure modes, limitations, and areas requiring caution.
**Updated**: 2026-02-08

---

## tmux Input Buffer Corruption

Multi-line strings sent via `tmux send-keys -l` corrupt the input buffer. Must use single-line strings only. This has caused session restarts and lost work.

**Mitigation**: CLAUDE.md guardrail, tmux-patterns.md memory file.

## Bash 3.2 Compatibility (macOS)

Functions called via `$(...)` must return 0 or the enclosing command fails silently. Bash 4+ features (associative arrays, `${var,,}`, `mapfile`) unavailable. Loop counter bugs when using subshells.

**Mitigation**: bash-patterns.md memory file, explicit return 0 checks.

## Context Window Overcommitment

Tendency to plan more tasks than can fit in a single context window. Iteration 1 (14 tasks) succeeded but was at the edge. Over-planning leads to JICM compression mid-task.

**Mitigation**: Target 8-10 tasks per iteration. Reserve 20% context for unexpected complexity.

## Documentation Version Drift

Integration docs, pattern counts, and cross-references drift when architecture changes. The v5.9.0 MCP decomposition left 3 integration docs outdated and 6 patterns orphaned until explicitly audited.

**Mitigation**: Mandatory cross-reference check after architectural changes. Pattern audit after each major restructuring.

## Over-Engineering Tendency

When given broad mandates, may create more structure than needed (e.g., 5-tier backlog when 3 would suffice, elaborate directory hierarchies). Extra documentation files accumulate.

**Mitigation**: CLAUDE.md "over-engineer" guardrail. Apply: "Does this file earn its token cost?"

## Auto-Provisioned MCP Limitations

Cannot unload git, fetch, memory MCPs — they're hardcoded in Claude Code runtime. Tool Search mitigates by 85% but some tool collision remains. No programmatic control over auto-provisioned MCP set.

**Mitigation**: Shadow via skills (git-ops, web-fetch). Accept remaining 15% duplication.

## JICM Soft-Restart Data Loss

Compression inevitably loses nuance. Specific code snippets, exact error messages, and mid-task state can be lost across /clear boundaries. Checkpoint files help but are summaries.

**Mitigation**: Commit early and often. Write state to files before compression. Keep .in-progress-ready.md updated.

---

*Self-Knowledge: Weaknesses — v1.0.0*
