# Hook Consolidation Plan

**Date**: 2026-02-09
**Source**: Stream 2 Phase A2 — Hook cluster audit (agent ac5e550)
**Current State**: 28 active .js hooks + 6 .sh hooks = 34 total
**Target State**: 17 active .js hooks + 5 .sh hooks = 22 total (~35% reduction)

## Consolidation Rationale

Hook execution adds latency per tool call. Each PreToolUse:Bash invocation currently fires 6 separate hooks. Merging same-event/same-matcher hooks into single files reduces:
- Process spawn overhead (6 → 1 for security cluster)
- JSON parse/serialize cycles per invocation
- Maintenance surface area (fewer files to audit)

No functionality is removed — all checks preserved within merged hooks.

---

## Merge 1: bash-safety-guard.js (6 → 1) — Priority: HIGH

**Event**: PreToolUse | **Matcher**: `^Bash$`

| Current Hook | Purpose | Lines |
|-------------|---------|-------|
| credential-guard.js | Block credential reads/writes | ~80 |
| branch-protection.js | Prevent force push to main/master | ~60 |
| amend-validator.js | Validate git amend operations | ~70 |
| workspace-guard.js | Enforce workspace boundaries | ~90 |
| dangerous-op-guard.js | Block rm -rf, mkfs, etc. | ~60 |
| secret-scanner.js | Scan staged files for secrets | ~80 |

**Architecture**:
```
bash-safety-guard.js
├── checkCredentials(command)     ← credential-guard.js
├── checkBranchProtection(command) ← branch-protection.js
├── checkAmendSafety(command)     ← amend-validator.js
├── checkWorkspaceBounds(command)  ← workspace-guard.js
├── checkDangerousOps(command)    ← dangerous-op-guard.js
└── checkSecrets(command)         ← secret-scanner.js
```

**Execution order**: Short-circuit on first block (credential → dangerous-ops → branch → workspace → amend → secrets).

**Note**: credential-guard.js also registers for `^Read$|^Write$` and workspace-guard.js for `^Write$|^Edit$`. These secondary registrations must be preserved as separate entries in settings.json pointing to the merged file, or handled via internal matcher dispatch.

**Estimated effort**: 2-3 hours

---

## Merge 2: docker-monitor.js (3 → 1) — Priority: MEDIUM

**Event**: PostToolUse | **Matcher**: `^Bash$`

| Current Hook | Purpose |
|-------------|---------|
| docker-health-monitor.js | Track container health status changes |
| docker-restart-loop-detector.js | Detect restart loops |
| docker-post-op-health.js | Verify health after Docker ops |

**Architecture**:
```
docker-monitor.js
├── detectDockerCommand(output)    ← shared pre-filter
├── checkHealthStatus(containers)  ← docker-health-monitor.js
├── checkRestartLoops(containers)  ← docker-restart-loop-detector.js
└── postOpHealthCheck(operation)   ← docker-post-op-health.js
```

**Key optimization**: Single `docker ps` call shared across all three checks (currently each hook may invoke Docker separately).

**Estimated effort**: 1-2 hours

---

## Merge 3: usage-tracker.js (3 → 1) — Priority: MEDIUM

**Event**: PostToolUse | **Matchers vary** (need internal dispatch)

| Current Hook | Matcher | Purpose |
|-------------|---------|---------|
| selection-audit.js | `^(Task\|Skill\|WebSearch\|WebFetch\|EnterPlanMode)$\|^mcp__` | Log tool/skill selections |
| file-access-tracker.js | `^Read$` | Track context file reads |
| memory-maintenance.js | `^mcp__` | Track Memory MCP entity access |

**Architecture**:
```
usage-tracker.js
├── trackSelection(toolName, input)   ← selection-audit.js (Task/Skill/Web/MCP)
├── trackFileAccess(filePath)         ← file-access-tracker.js (Read)
└── trackMemoryAccess(entityName)     ← memory-maintenance.js (mcp__)
```

**Settings.json**: Register under broadest matcher (`^(Task|Skill|WebSearch|WebFetch|EnterPlanMode|Read)$|^mcp__`) or register once per original matcher pointing to same file.

**Estimated effort**: 1-2 hours

---

## Merge 4: milestone-coordinator.js (2 → 1) — Priority: LOW

**Events**: UserPromptSubmit + PostToolUse:TodoWrite

| Current Hook | Event | Purpose |
|-------------|-------|---------|
| milestone-doc-enforcer.js | UserPromptSubmit | Enforce docs at milestone |
| milestone-detector.js | PostToolUse:TodoWrite | Detect milestone completion |

**Architecture**:
```
milestone-coordinator.js
├── detectMilestone(todoData)        ← milestone-detector.js (PostToolUse)
└── enforceDocs(userPrompt)          ← milestone-doc-enforcer.js (UserPromptSubmit)
```

**Note**: Different events — requires two settings.json entries pointing to same file. Internal dispatch by `hookEvent` field.

**Estimated effort**: 1 hour

---

## Merge 5: jicm-coordinator.js (2 → 1) — Priority: LOW

**Events**: PostToolUse + UserPromptSubmit

| Current Hook | Event | Purpose |
|-------------|-------|---------|
| context-accumulator.js | PostToolUse (broad) | Track context consumption |
| jicm-continuation-verifier.js | UserPromptSubmit | Reinforce post-clear continuation |

**Architecture**:
```
jicm-coordinator.js
├── trackContext(toolOutput)         ← context-accumulator.js (PostToolUse)
└── verifyContinuation(userPrompt)   ← jicm-continuation-verifier.js (UserPromptSubmit)
```

**Estimated effort**: 1 hour

---

## Additional Cleanup

| Item | Action |
|------|--------|
| minimal-test.sh | **Remove** — test hook, no production purpose |
| 12 archived hooks | **Keep** in /archive/ — reference value |
| context-accumulator.js (unregistered) | Currently in hooks/ but NOT in settings.json registrations — verify if loaded via other mechanism or dead code |

---

## Implementation Sequence

1. **Merge 1** (bash-safety-guard.js) — Highest impact, most latency reduction
2. **Merge 2** (docker-monitor.js) — Clean separation, low risk
3. **Merge 3** (usage-tracker.js) — Telemetry consolidation
4. **Merge 4+5** (milestone + jicm coordinators) — Lower priority, cross-event

**Total estimated effort**: 6-10 hours across all merges

## Post-Consolidation Hook Map

| Event | Hooks (After) |
|-------|--------------|
| Setup | setup-hook.sh |
| SessionStart | session-start.sh |
| PreCompact | precompact-analyzer.js, pre-compact.sh |
| Stop | stop-auto-clear.sh, stop-hook.sh, update-context-cache.js |
| PreToolUse:Bash | **bash-safety-guard.js** |
| PreToolUse:Read\|Write | bash-safety-guard.js (credential check) |
| PreToolUse:Write\|Edit | bash-safety-guard.js (workspace check) |
| PreToolUse:* | context-injector.js |
| UserPromptSubmit | orchestration-detector.js, self-correction-capture.js, permission-gate.js, wiggum-loop-tracker.js, session-trigger.js, **milestone-coordinator.js**, **jicm-coordinator.js** |
| PostToolUse:Bash | **docker-monitor.js**, cross-project-commit-tracker.js |
| PostToolUse:TodoWrite | **milestone-coordinator.js** |
| PostToolUse:various | **usage-tracker.js** |
| PostToolUse:broad | **jicm-coordinator.js** |
| Notification | session-tracker.js |
| SubagentStop | subagent-stop.js |

---

*Hook Consolidation Plan — Stream 2 Phase A2*
*28 → 17 JS hooks (~39% reduction) | 6 → 5 .sh hooks*
