---
name: context-management
version: 2.0.0
description: |
  Jarvis Intelligent Context Management (JICM) - monitor, analyze, and optimize context usage.
  Use when: "context budget", "context usage", "context analysis", "context checkpoint",
  "smart compact", "JICM", "reduce context", "context optimization", "token usage",
  "approaching context limit", "context threshold", "compaction".
  Orchestrates AC-04 JICM functionality across multiple commands.
category: workflow
tags: [context, JICM, tokens, compaction, optimization, AC-04]
created: 2026-01-23
---

# Context Management Skill

Comprehensive context management for Jarvis, implementing AC-04 (JICM - Jarvis Intelligent Context Management).

---

## Overview

This skill orchestrates context monitoring, analysis, and optimization:

- **Monitor**: Track current context usage vs budget
- **Analyze**: Identify patterns and optimization opportunities
- **Checkpoint**: Save state before context reduction
- **Compact**: Intelligently reduce context while preserving essential information

---

## Quick Actions

| Need | Command/Action |
|------|----------------|
| Check current context | Native `/context` command |
| Detailed budget analysis | `/context-budget` |
| Weekly usage analysis | `/context-analyze` |
| Save checkpoint (with MCP logic) | `/context-checkpoint` |
| Simple state save | `/checkpoint` |
| Manual JICM trigger | `/smart-compact` |
| Set auto-compact threshold | `/autocompact-threshold <tokens>` |
| Report forgotten context | `/context-loss "description"` |

---

## Context Budget Thresholds

| Status | Usage | Action |
|--------|-------|--------|
| HEALTHY | <50% | Continue normally |
| MODERATE | 50-74% | Monitor; checkpoint before heavy work |
| WARNING | 75-84% | Run `/smart-compact` assessment |
| CRITICAL | 85%+ | Immediate checkpoint required |

---

## Decision Flow

```
Context Usage?
    │
    ├─< 50% ─→ Continue normally
    │
    ├─ 50-74% ─→ Consider /checkpoint before long tasks
    │
    ├─ 75-84% ─→ Run /smart-compact (assessment)
    │               └─ If recommends action → /smart-compact --full
    │
    └─ 85%+ ─→ /context-checkpoint (full automation)
                └─ Then type /clear
```

---

## Command Reference

### /context (Native)

Native Claude Code command showing current context token usage.

**When to Use**: Quick check of current usage.

### /context-budget

Detailed context analysis by category (conversation, MCPs, plugins, etc.) with recommendations.

**When to Use**: Understanding what's consuming context.

### /context-analyze

Weekly analysis script examining patterns, git churn, stale files, and generating optimization report.

**When to Use**: Periodic maintenance, understanding long-term patterns.

### /context-checkpoint

Full automated checkpoint workflow:
1. Assesses current state
2. Evaluates which MCPs are needed
3. Creates checkpoint file
4. Disables unneeded MCPs
5. Commits state
6. Prepares for /clear

**When to Use**: Context approaching limit and need intelligent MCP reduction.

### /checkpoint (from session-management)

Simple state save without MCP logic.

**When to Use**: Quick save before manual /clear or session break.

### /smart-compact

Manual JICM trigger with modes:
- **Default**: Assessment only - shows status and recommendation
- **--force**: Create checkpoint immediately
- **--full**: Full automation (checkpoint + disable MCPs + signal /clear)

**When to Use**: Proactive context management, manual JICM trigger.

### /autocompact-threshold <tokens>

Set the JICM auto-compact threshold.

| Value | Description |
|-------|-------------|
| 30000 | Testing (very frequent) |
| 80000 | Aggressive (40% of context) |
| 100000 | Moderate (50%) |
| **130000** | Default (65%) |
| 150000 | Conservative (75%) |

### /context-loss "description"

Document when context is forgotten after compaction, building evidence for improving `compaction-essentials.md`.

**When to Use**: After noticing Jarvis forgot important context.

---

## MCP Token Reference

### Tier 1: Never Disable (~21K total)

| MCP | ~Tokens |
|-----|---------|
| memory | ~8K |
| filesystem | ~8K |
| fetch | ~5K |

### Tier 2: Disable When Not Needed

| MCP | ~Tokens | Disable If |
|-----|---------|------------|
| github | ~15K | No PR/issue work planned |
| git | ~4K | Only reading/editing code |
| context7 | ~8K | Research phase complete |
| sequential-thinking | ~5K | In implementation phase |

---

## JICM Architecture (v3.0.0)

```
┌─────────────────────────────────────────────────────────────────┐
│                    AC-04: JICM Components (v3)                  │
├─────────────────────────────────────────────────────────────────┤
│  MONITORING (Official API)                                      │
│  └─ jarvis-watcher.sh reads statusline-input.json              │
│  └─ used_percentage from Claude Code (authoritative)           │
├─────────────────────────────────────────────────────────────────┤
│  ANALYSIS                                                       │
│  └─ /context-budget → category breakdown                        │
│  └─ /context-analyze → weekly patterns                          │
├─────────────────────────────────────────────────────────────────┤
│  PRESERVATION (AI-Driven)                                       │
│  └─ precompact-analyzer.js → preservation manifest             │
│  └─ context-compressor agent → intelligent compression          │
│  └─ /context-loss → track forgotten context                     │
├─────────────────────────────────────────────────────────────────┤
│  OPTIMIZATION                                                   │
│  └─ /smart-compact → manual trigger                             │
│  └─ /context-checkpoint → automated workflow                    │
│  └─ jarvis-watcher.sh → JICM trigger at 80% threshold           │
└─────────────────────────────────────────────────────────────────┘
```

**Key v3.0.0 Changes**:
- Uses official Claude Code statusline JSON API (`~/.claude/logs/statusline-input.json`)
- PreCompact hook generates preservation manifest for AI-driven compression
- Unified jarvis-watcher.sh replaces separate watcher scripts

---

## Checkpoint File

When checkpointing, state is saved to `.claude/context/.soft-restart-checkpoint.md`:

```markdown
# Context Checkpoint

**Created**: [timestamp]
**Reason**: [trigger reason]

## Work Summary
[What was accomplished]

## Next Steps After Restart
1. [Immediate next step]
2. [Follow-up tasks]

## Critical Context
[Decisions, discoveries, blockers]

## MCP State
| MCP | Action | Reason |
|-----|--------|--------|
| memory | KEEP | Tier 1 |
| github | DISABLED | No PR work |
```

---

## Post-Clear Flow

After `/clear`:
1. SessionStart hook fires
2. Detects checkpoint file
3. Loads checkpoint context
4. Deletes checkpoint file
5. Resets context-estimate.json
6. Clears .compaction-in-progress flag
7. Claude continues from checkpoint

---

## Related Documentation

### Commands
- @.claude/commands/context-budget.md
- @.claude/commands/context-analyze.md
- @.claude/commands/context-checkpoint.md
- @.claude/commands/smart-compact.md
- @.claude/commands/autocompact-threshold.md
- @.claude/commands/context-loss.md

### Patterns
- @.claude/context/patterns/context-budget-management.md
- @.claude/context/patterns/automated-context-management.md
- @.claude/context/patterns/jicm-pattern.md

### Components
- @.claude/context/components/AC-04-jicm.md

### Infrastructure (JICM v3.0.0)
- @.claude/scripts/jarvis-watcher.sh (statusline JSON API monitoring)
- @.claude/hooks/precompact-analyzer.js (preservation manifest)
- @.claude/agents/context-compressor.md (AI-powered compression)
- @.claude/hooks/subagent-stop.js
- @.claude/context/compaction-essentials.md

### Design Documents
- @.claude/context/designs/jicm-architecture-solutions.md (complete v3 architecture)

### JICM Agent (Solution C)
- @.claude/agents/jicm-agent.md (autonomous monitoring agent)
- Status file: `.claude/context/.jicm-status.json`
- Provides: velocity tracking, threshold prediction, proactive management

---

*Context Management Skill v2.0.0 - AC-04 JICM v3 Orchestration*
