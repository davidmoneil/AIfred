# Hooks Registration Audit

**Date**: 2026-01-09
**PR**: PR-10 Organization Cleanup

---

## Finding: Significant Hook Registration Gap

The hooks README claims 18 installed hooks, but only **10 hooks** are actually registered in `settings.json`.

---

## Actually Registered Hooks (10)

| Hook File | Event | Status |
|-----------|-------|--------|
| `session-start.sh` | SessionStart | ✅ Active |
| `pre-compact.sh` | PreCompact | ✅ Active |
| `stop-auto-clear.sh` | Stop | ✅ Active |
| `minimal-test.sh` | UserPromptSubmit | ✅ Active |
| `orchestration-detector.js` | UserPromptSubmit | ✅ Active |
| `self-correction-capture.js` | UserPromptSubmit | ✅ Active |
| `context-accumulator.js` | PostToolUse | ✅ Active |
| `cross-project-commit-tracker.js` | PostToolUse | ✅ Active |
| `selection-audit.js` | PostToolUse | ✅ Active |
| `subagent-stop.js` | SubagentStop | ✅ Active |

---

## Unregistered JS Files (16)

| File | README Claims | Recommendation |
|------|---------------|----------------|
| `audit-logger.js` | PreToolUse logging | **REVIEW** — May need registration |
| `context-reminder.js` | PostToolUse prompts | **REVIEW** — May be superseded |
| `dangerous-op-guard.js` | PreToolUse blocking | **REVIEW** — Critical if intended |
| `doc-sync-trigger.js` | PostToolUse tracking | **REVIEW** — May need registration |
| `docker-health-check.js` | PostToolUse verify | **REVIEW** — May need registration |
| `memory-maintenance.js` | PostToolUse tracking | **REVIEW** — May need registration |
| `permission-gate.js` | UserPromptSubmit | **REVIEW** — May need registration |
| `pre-compact.js` | PreCompact | Superseded by `pre-compact.sh` |
| `project-detector.js` | UserPromptSubmit | **REVIEW** — May need registration |
| `secret-scanner.js` | PreToolUse security | **REVIEW** — Critical if intended |
| `session-exit-enforcer.js` | PostToolUse tracking | **REVIEW** — May be superseded |
| `session-start.js` | SessionStart | Superseded by `session-start.sh` |
| `session-stop.js` | Stop | May be superseded by `stop-auto-clear.sh` |
| `session-tracker.js` | Notification | **REVIEW** — May need registration |
| `workspace-guard.js` | PreToolUse blocking | **REVIEW** — Critical if intended |
| `worktree-manager.js` | PostToolUse tracking | **REVIEW** — May need registration |

---

## Analysis

### Pattern Observed
Many JS hooks were created during earlier PRs but shell scripts later replaced them without cleaning up the JS files.

### Critical Unregistered Hooks
If these hooks are intended to be active, they need registration:
- `dangerous-op-guard.js` — Blocks destructive commands
- `workspace-guard.js` — Blocks writes to AIfred baseline
- `secret-scanner.js` — Blocks commits with secrets
- `permission-gate.js` — Soft-gates policy-crossing

### Likely Superseded (can archive)
- `session-start.js` → `session-start.sh`
- `pre-compact.js` → `pre-compact.sh`
- `session-stop.js` → `stop-auto-clear.sh`

---

## Recommendations

1. **Immediate**: Register critical guardrail hooks (`dangerous-op-guard`, `workspace-guard`, `secret-scanner`, `permission-gate`) — they should be active
2. **Preferred Approach**: JS hooks over shell scripts — greater capacity for logical structures and conditional triggering
3. **Cleanup**: Where shell wrappers exist that replaced JS hooks, consider migrating back to JS (or archive the shell version)
4. **Documentation**: Hooks README has been updated to reflect reality
5. **PR-10.5**: Register JS guardrail hooks as part of setup validation

---

*Audit completed as part of PR-10*
