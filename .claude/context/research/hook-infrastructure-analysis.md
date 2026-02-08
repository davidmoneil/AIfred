# Hook Infrastructure Analysis

**Date**: 2026-02-08
**Scope**: All hooks in `.claude/settings.json` — context overhead, execution frequency, optimization opportunities

---

## Hook Inventory

### By Event (Total: 30 hook registrations)

| Event | Count | Frequency |
|-------|-------|-----------|
| PreToolUse | 7 | Every tool call |
| PostToolUse | 7 | Every tool call |
| UserPromptSubmit | 8 | Every user message |
| SessionStart | 1 | Once per session |
| PreCompact | 2 | On compaction trigger |
| Stop | 3 | On session end |
| Notification | 1 | On notifications |
| SubagentStop | 1 | On subagent completion |

### PreToolUse Hooks (7 — fire on EVERY tool call)

| Hook | Purpose | Context Impact | Early Exit? |
|------|---------|---------------|-------------|
| credential-guard.js | Block sensitive file access | LOW — returns `{proceed:true}` for non-file-ops, only outputs on block | Yes (non-Read/Write/Bash) |
| branch-protection.js | Prevent force-push to main | LOW — only fires on git push | Yes (non-Bash) |
| amend-validator.js | Warn on git amend | LOW — only fires on git commit --amend | Yes (non-Bash) |
| workspace-guard.js | Block AIfred baseline writes | LOW — only fires on Write/Edit/Bash | Yes (non-modify-tools) |
| dangerous-op-guard.js | Confirm destructive operations | LOW — only fires on rm/reset/etc | Yes (non-Bash) |
| secret-scanner.js | Detect credentials in content | LOW — only fires on Write | Yes (non-Write) |
| context-injector.js | Inject tool hints | MEDIUM — can inject additionalContext on any tool | Partial (filters to medium/high priority) |

### PostToolUse Hooks (7 — fire on EVERY tool call)

| Hook | Purpose | Context Impact | Early Exit? |
|------|---------|---------------|-------------|
| cross-project-commit-tracker.js | Track cross-repo commits | LOW — only fires on Bash with git | Yes (non-git) |
| selection-audit.js | Log tool selections | ZERO — writes to JSONL file only, no context injection | Yes (filters by LOG_PATTERNS) |
| milestone-detector.js | Detect work milestones | LOW — rare context injection | Yes (pattern-based) |
| docker-health-monitor.js | Monitor Docker health | LOW — 30s throttle, only on docker ops | Yes (throttled) |
| docker-restart-loop-detector.js | Detect Docker restart loops | LOW — similar throttle pattern | Yes |
| docker-post-op-health.js | Post-Docker-op health check | LOW — only after docker commands | Yes (non-docker) |
| file-access-tracker.js | Track file reads | ZERO — writes to JSON file only, no context injection | Yes (only Read tool) |
| memory-maintenance.js | Track memory MCP access | ZERO — writes to JSON file only, no context injection | Yes (only memory MCP tools) |

### UserPromptSubmit Hooks (8 — fire on every user message)

| Hook | Purpose | Context Impact |
|------|---------|---------------|
| minimal-test.sh | Basic health check | LOW |
| orchestration-detector.js | Detect orchestration patterns | MEDIUM — can inject guidance |
| self-correction-capture.js | Capture self-corrections | LOW |
| permission-gate.js | Permission management | LOW |
| wiggum-loop-tracker.js | Track wiggum loop state | LOW |
| milestone-doc-enforcer.js | Enforce milestone docs | LOW — rare trigger |
| session-trigger.js | Session state management | LOW |
| jicm-continuation-verifier.js | Verify JICM continuation | LOW — only post-clear |

---

## Context Overhead Assessment

### Per-Tool-Call Overhead

Each tool call fires **14 hooks** (7 PreToolUse + 7 PostToolUse). However:

1. **Most hooks early-exit** — return `{proceed: true}` immediately for irrelevant tools
2. **Zero-context hooks** (selection-audit, file-access-tracker, memory-maintenance) — write to files, never inject context
3. **context-injector.js** is the only hook that regularly injects additionalContext, and it filters to medium/high priority

**Estimated per-tool-call overhead**: ~100-200ms execution time (14 Node.js processes spawned), but minimal context token cost for most calls.

### Hidden Overhead: System-Reminder Tags

Claude Code wraps hook outputs in `<system-reminder>` tags. Even when hooks return `{proceed: true}` with no additionalContext, the framework may inject hook progress events. These are visible in subagent transcripts as progress messages:

```
{"type":"progress","data":{"type":"hook_progress","hookEvent":"PreToolUse","hookName":"PreToolUse:Read",...}}
```

Each progress event consumes ~100-200 tokens. For 14 hooks per tool call, that's **1,400-2,800 tokens per tool call** in hook progress overhead alone.

### Cumulative Impact

A typical session with 50-100 tool calls:
- **Hook progress tokens**: 70,000-280,000 tokens (5-20% of 200K context)
- **additionalContext tokens**: ~500-1,000 tokens total (minimal)
- **Main overhead is execution latency**, not context consumption

---

## Optimization Opportunities

### Priority 1: Add Matchers (Reduce Hook Spawning)

Currently, ALL hooks use `"matcher": ""` (match everything). Adding tool-specific matchers would prevent hooks from spawning at all for irrelevant tools.

**Candidate hooks for matchers**:

| Hook | Current Matcher | Proposed Matcher | Savings |
|------|----------------|-----------------|---------|
| branch-protection.js | `""` (all tools) | `"Bash"` | Skip 80% of calls |
| amend-validator.js | `""` (all tools) | `"Bash"` | Skip 80% of calls |
| dangerous-op-guard.js | `""` (all tools) | `"Bash"` | Skip 80% of calls |
| secret-scanner.js | `""` (all tools) | `"Write"` | Skip 90% of calls |
| workspace-guard.js | `""` (all tools) | `"Write,Edit,Bash"` | Skip 50% of calls |
| docker-health-monitor.js | `""` (all tools) | `"Bash"` | Skip 80% of calls |
| docker-restart-loop-detector.js | `""` (all tools) | `"Bash"` | Skip 80% of calls |
| docker-post-op-health.js | `""` (all tools) | `"Bash"` | Skip 80% of calls |
| cross-project-commit-tracker.js | `""` (all tools) | `"Bash"` | Skip 80% of calls |
| file-access-tracker.js | `""` (all tools) | `"Read"` | Skip 70% of calls |
| memory-maintenance.js | `""` (all tools) | `"mcp__memory*,mcp__mcp-gateway*"` | Skip 95% of calls |

**Estimated savings**: From 14 hooks/tool-call → 6-8 hooks/tool-call average. ~40-50% fewer Node.js processes spawned.

### Priority 2: Consolidate Docker Hooks

Three Docker hooks fire on every PostToolUse:
- docker-health-monitor.js
- docker-restart-loop-detector.js
- docker-post-op-health.js

All three early-exit for non-Bash or non-Docker commands. Could be consolidated into a single `docker-ops-monitor.js` that handles all three concerns.

**Savings**: 2 fewer processes per PostToolUse hook event.

### Priority 3: Batch Zero-Context Hooks

selection-audit.js, file-access-tracker.js, and memory-maintenance.js are pure logging hooks. Could be consolidated into a single `telemetry-tracker.js` that handles all three.

**Savings**: 2 fewer processes per PostToolUse hook event.

### Priority 4: Context Injector Optimization

The context-injector.js already filters well (medium/high priority only), but could be further optimized:
- Skip injection entirely when context is < 30% (plenty of budget)
- Only inject context budget warnings (the most useful feature)
- Remove tool hints (these are already in the system prompt)

---

## Matcher Configuration Reference

Claude Code supports matchers in the format:
```json
{
  "matcher": "Bash",
  "hooks": [...]
}
```

Multiple matchers can be specified by adding multiple entries to the hooks array for the same event, each with different matchers.

---

## Implementation Status

### Priority 1: IMPLEMENTED (2026-02-08)

Matchers added to `settings.json`. All PreToolUse and PostToolUse hooks now use anchored regex matchers.

**Final matcher configuration**:

| Matcher Group | Event | Hooks | Matches |
|---------------|-------|-------|---------|
| `^Bash$` | PreToolUse | credential-guard, branch-protection, amend-validator, workspace-guard, dangerous-op-guard, secret-scanner | Bash only |
| `^Read$\|^Write$` | PreToolUse | credential-guard | Read/Write file ops |
| `^Write$\|^Edit$` | PreToolUse | workspace-guard | Write/Edit file ops |
| `""` (global) | PreToolUse | context-injector | All tools |
| `^Bash$\|^mcp__git__git_commit$` | PostToolUse | cross-project-commit-tracker | Bash + git MCP |
| `^Bash$` | PostToolUse | docker-health-monitor, docker-restart-loop-detector, docker-post-op-health | Bash only |
| `^(Task\|Skill\|...)$\|^mcp__` | PostToolUse | selection-audit | Delegations + MCP |
| `^TodoWrite$` | PostToolUse | milestone-detector | TodoWrite only |
| `^Read$` | PostToolUse | file-access-tracker | Read only |
| `^mcp__` | PostToolUse | memory-maintenance | MCP tools only |

**Measured impact**:

| Tool | Before | After | Reduction |
|------|--------|-------|-----------|
| Glob/Grep | 14 hooks | 1 hook | **93%** |
| Read | 14 hooks | 3 hooks | **79%** |
| Write | 14 hooks | 3 hooks | **79%** |
| Edit | 14 hooks | 2 hooks | **86%** |
| Task | 14 hooks | 2 hooks | **86%** |
| Bash | 14 hooks | 12 hooks | **14%** |
| **Overall (weighted)** | | | **~70%** |

### Remaining Recommendations

2. **Near-term**: Consolidate 3 Docker hooks → 1 (Priority 2)
3. **Near-term**: Consolidate 3 logging hooks → 1 (Priority 3)
4. **Deferred**: Context injector optimization (Priority 4) — measure first

---

*Hook Infrastructure Analysis — Jarvis v5.9.0 (Updated with implementation results)*
