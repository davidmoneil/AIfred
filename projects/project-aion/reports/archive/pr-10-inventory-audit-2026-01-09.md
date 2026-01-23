# Jarvis Inventory Audit Report

**Generated**: 2026-01-09
**Version**: 1.9.5
**Purpose**: Comprehensive inventory for organization design review

---

## Executive Summary

| Category | Count | Status |
|----------|-------|--------|
| Root-level items | 13 | Mixed (see analysis) |
| `.claude/` items | ~200+ | Jarvis Ecosystem |
| `projects/` items | ~25 | Project Aion |
| `docs/` items | ~8 | Mixed |
| `scripts/` items | 9 | Root utilities |

**Key Findings**:
- `.opencode/` directory is legacy/duplicate
- `paths-registry.yaml.template` may be legacy
- Some files have outdated version references
- OOXML schemas duplicated across docx/pptx skills

---

## Root-Level Items

| Item | Type | Space | Correct Location? | Notes |
|------|------|-------|-------------------|-------|
| `.claude/` | Dir | Ecosystem | ✅ Yes | Primary Jarvis operational directory |
| `.gitignore` | File | Ecosystem | ✅ Yes | Git configuration |
| `.opencode/` | Dir | Legacy | ⚠️ **REVIEW** | OpenCode compatibility — possibly obsolete |
| `AGENTS.md` | File | Ecosystem | ✅ Yes | OpenCode agent instructions |
| `CHANGELOG.md` | File | Ecosystem | ✅ Yes | Version history |
| `README.md` | File | Ecosystem | ✅ Yes | Project overview |
| `VERSION` | File | Ecosystem | ✅ Yes | Current version number |
| `docker/` | Dir | Ecosystem | ✅ Yes | Docker configurations |
| `docs/` | Dir | Mixed | ✅ Yes | Documentation + archive |
| `external-sources/` | Dir | Ecosystem | ✅ Yes | Symlinks to external data |
| `opencode.json` | File | Legacy | ⚠️ **REVIEW** | OpenCode config — still needed? |
| `paths-registry.yaml` | File | Ecosystem | ✅ Yes | Source of truth for paths |
| `paths-registry.yaml.template` | File | Legacy | ⚠️ **REVIEW** | Template — still needed? |
| `projects/` | Dir | Project Aion | ✅ Yes | Development artifacts |
| `scripts/` | Dir | Ecosystem | ✅ Yes | Root utility scripts |

### Recommendations (Root)

1. **`.opencode/`**: Evaluate if OpenCode support is still needed. If deprecated, archive to `docs/archive/`.
2. **`opencode.json`**: Same as above — archive if OpenCode deprecated.
3. **`paths-registry.yaml.template`**: If setup now generates this, archive the template.

---

## `.claude/` Directory (Jarvis Ecosystem)

### Top-Level `.claude/` Files

| Item | Type | Correct? | Current? | Notes |
|------|------|----------|----------|-------|
| `CLAUDE.md` | File | ✅ Yes | ✅ Current | Quick reference (v1.9.5) |
| `CLAUDE-full-reference.md` | File | ✅ Yes | ⚠️ Check | Full reference — verify alignment |
| `settings.json` | File | ✅ Yes | ✅ Current | Claude Code settings |
| `settings.local.json` | File | ✅ Yes | ✅ Current | Local overrides |

### `.claude/agents/`

| Item | Type | Space | Current? | Notes |
|------|------|-------|----------|-------|
| `_template-agent.md` | File | Ecosystem | ✅ | Agent template |
| `archive/` | Dir | Ecosystem | ✅ | Legacy agent formats |
| `code-analyzer.md` | File | Ecosystem | ✅ | AIfred sync agent |
| `code-implementer.md` | File | Ecosystem | ✅ | AIfred sync agent |
| `code-tester.md` | File | Ecosystem | ✅ | AIfred sync agent |
| `deep-research.md` | File | Ecosystem | ✅ | Custom agent |
| `docker-deployer.md` | File | Ecosystem | ✅ | Custom agent |
| `memory/` | Dir | Ecosystem | ✅ | Agent learnings |
| `memory-bank-synchronizer.md` | File | Ecosystem | ✅ | Custom agent |
| `results/` | Dir | Ecosystem | ✅ | Agent outputs |
| `service-troubleshooter.md` | File | Ecosystem | ✅ | Custom agent |
| `sessions/` | Dir | Ecosystem | ✅ | Agent sessions |

**Status**: ✅ All items correctly placed

### `.claude/archive/`

| Item | Type | Notes |
|------|------|-------|
| `memory/` | Dir | Archived memory items |
| `setup-phases/` | Dir | ⚠️ **OLD SETUP PHASES** — 9 files |

**Recommendation**: `setup-phases/` contains old setup phase files (00-preflight.md through 07-finalization.md). Verify if these are superceded by current setup.md. If yes, document what replaced them in archive-log.

### `.claude/commands/`

| Item | Count | Notes |
|------|-------|-------|
| Top-level commands | 20 | All correct location |
| `commits/` subdir | 2 | status.md, summary.md |
| `orchestration/` subdir | 4 | plan, status, resume, commit |

**Full Command List**:
- `agent.md` ✅
- `checkpoint.md` ✅
- `context-budget.md` ✅
- `context-checkpoint.md` ✅
- `create-project.md` ✅ (moved from root)
- `design-review.md` ✅
- `end-session.md` ✅
- `health-report.md` ✅
- `jarvis.md` ✅ (NEW - command menu)
- `register-project.md` ✅ (moved from root)
- `setup.md` ✅
- `setup-readiness.md` ✅
- `smart-checkpoint.md` ✅
- `smart-compact.md` ✅
- `soft-restart.md` ⚠️ **DEPRECATED** — superseded by checkpoint
- `sync-aifred-baseline.md` ✅
- `tooling-health.md` ✅
- `trigger-clear.md` ✅
- `validate-selection.md` ✅

**Recommendation**: Archive `soft-restart.md` — design plan notes it's deprecated.

### `.claude/config/`

| Item | Notes |
|------|-------|
| `credentials.local.yaml` | API keys (gitignored) ✅ |
| `workspace-allowlist.yaml` | Workspace boundaries ✅ |

**Status**: ✅ Correct

### `.claude/context/`

| Subdirectory | Files | Notes |
|--------------|-------|-------|
| Root files | 5 | `_index.md`, `configuration-summary.md`, `session-state.md`, `user-preferences.md`, `.soft-restart-checkpoint.md`, `.watcher-pid` |
| `designs/` | 0 | Empty placeholder |
| `integrations/` | 6 | capability-matrix, mcp-installation, memory-usage, overlap-analysis, search-api-research, skills-selection-guide |
| `lessons/` | 1 | corrections.md |
| `patterns/` | 21 | All active patterns |
| `projects/` | 1 | current-priorities.md |
| `standards/` | 3 | _index.md, model-selection.md, severity-status-system.md |
| `systems/` | 2 | _template.md, this-host.md |
| `templates/` | 5 | 3 workflow templates + 2 project templates |
| `troubleshooting/` | 2 | agent-format-migration.md, hookify-import-fix.md |
| `upstream/` | 6 | sync reports + port-log |
| `workflows/` | 1 | session-exit.md |

#### Context Patterns Analysis

| Pattern | Current? | Notes |
|---------|----------|-------|
| `_index.md` | ⚠️ Check | May need update after PR-10 |
| `agent-selection-pattern.md` | ✅ v2.0 | PR-9.1 |
| `automated-context-management.md` | ✅ | PR-8.3.1 |
| `batch-mcp-validation.md` | ✅ | PR-8.4 |
| `branching-strategy.md` | ✅ | PR-1 |
| `context-budget-management.md` | ✅ | PR-8.1 |
| `cross-project-commit-tracking.md` | ✅ | AIfred sync |
| `hook-consolidation-assessment.md` | ✅ | PR-8.3 |
| `mcp-design-patterns.md` | ✅ | PR-8.5 |
| `mcp-loading-strategy.md` | ✅ v2.2 | PR-8.2 |
| `mcp-validation-harness.md` | ✅ | PR-8.4 |
| `memory-storage-pattern.md` | ✅ | AIfred |
| `plugin-decomposition-pattern.md` | ✅ v3.0 | PR-9.0 |
| `prompt-design-review.md` | ✅ | AIfred |
| `selection-intelligence-guide.md` | ✅ | PR-9.1 |
| `selection-validation-tests.md` | ✅ | PR-9.4 |
| `session-start-checklist.md` | ✅ | Updated PR-10.1 |
| `setup-validation.md` | ✅ | PR-4 |
| `tool-selection-intelligence.md` | ✅ | PR-9.1 |
| `workspace-path-policy.md` | ✅ | PR-1 |
| `worktree-shell-functions.md` | ✅ | AIfred sync |

### `.claude/hooks/`

| Hook | Type | Registered? | Notes |
|------|------|-------------|-------|
| `README.md` | Doc | N/A | Documentation |
| `audit-logger.js` | JS | ⚠️ Check | Audit logging |
| `context-accumulator.js` | JS | ✅ PostToolUse | JICM tracking |
| `context-reminder.js` | JS | ⚠️ Check | Context reminders |
| `cross-project-commit-tracker.js` | JS | ✅ PostToolUse | Commit tracking |
| `dangerous-op-guard.js` | JS | ⚠️ Check | Security guard |
| `doc-sync-trigger.js` | JS | ⚠️ Check | Doc sync |
| `docker-health-check.js` | JS | ⚠️ Check | Docker health |
| `memory-maintenance.js` | JS | ⚠️ Check | Memory cleanup |
| `minimal-test.sh` | Shell | N/A | Test script |
| `orchestration-detector.js` | JS | ✅ UserPromptSubmit | Complexity detection |
| `permission-gate.js` | JS | ⚠️ Check | Permission soft-gate |
| `pre-compact.js` | JS | ⚠️ Check | Pre-compaction |
| `pre-compact.sh` | Shell | ✅ PreCompact | Shell hook |
| `project-detector.js` | JS | ⚠️ Check | Project detection |
| `secret-scanner.js` | JS | ⚠️ Check | Secret scanning |
| `selection-audit.js` | JS | ✅ PostToolUse | Selection logging |
| `self-correction-capture.js` | JS | ✅ UserPromptSubmit | Correction capture |
| `session-exit-enforcer.js` | JS | ⚠️ Check | Exit enforcement |
| `session-start.js` | JS | ⚠️ Check | Session start |
| `session-start.sh` | Shell | ✅ SessionStart | Main session hook |
| `session-stop.js` | JS | ⚠️ Check | Session stop |
| `session-tracker.js` | JS | ⚠️ Check | Session tracking |
| `stop-auto-clear.sh` | Shell | ⚠️ Check | Auto-clear stop |
| `subagent-stop.js` | JS | ✅ SubagentStop | Agent completion |
| `workspace-guard.js` | JS | ⚠️ Check | Workspace guard |
| `worktree-manager.js` | JS | ⚠️ Check | Worktree tracking |

**Recommendation**: Audit `settings.json` to verify which hooks are actually registered. Many JS hooks may be legacy (not registered).

### `.claude/jobs/`

| Item | Type | Notes |
|------|------|-------|
| `README.md` | Doc | Job documentation |
| `context-staleness.sh` | Script | Weekly staleness check |
| `logs/` | Dir | Job logs |
| `memory-prune.sh` | Script | Weekly memory prune |

**Status**: ✅ Correct — scheduled/periodic tasks

### `.claude/legal/`

| Item | Notes |
|------|-------|
| `ATTRIBUTION.md` | Credits (PR-10.4) ✅ |
| `README.md` | Directory index (PR-10.4) ✅ |

**Status**: ✅ NEW (PR-10.4)

### `.claude/logs/`

| Item | Type | Notes |
|------|------|-------|
| Root logs | 7 | agent-activity.jsonl, context-estimate.json, corrections.jsonl, etc. |
| `mcp-validation/` | Dir | 10 validation log files |

**Status**: ✅ Correct — runtime logs

### `.claude/orchestration/`

| Item | Notes |
|------|-------|
| `README.md` | Documentation |
| `_template.yaml` | Orchestration template |

**Status**: ✅ Correct — AIfred sync

### `.claude/persona/`

| Item | Notes |
|------|-------|
| `README.md` | Directory index (PR-10.1) |
| `jarvis-identity.md` | Full persona spec (PR-10.1) |

**Status**: ✅ NEW (PR-10.1)

### `.claude/reports/`

| Item | Type | Notes |
|------|------|-------|
| `README.md` | Doc | Directory index (PR-10.2) |
| `archive/` | Dir | 3 older tooling-health reports |
| Operational reports | 7 | context-*, mcp-*, selection-*, tooling-* |

**Status**: ✅ Correct after PR-10.2 reorganization

### `.claude/scripts/`

| Script | Purpose | Notes |
|--------|---------|-------|
| `adjust-mcp-config.sh` | MCP config adjustment | ✅ |
| `auto-clear-watcher.sh` | Context management watcher | ✅ |
| `disable-mcps.sh` | Disable MCPs | ✅ |
| `enable-mcps.sh` | Enable MCPs | ✅ |
| `extract-skill.sh` | Skill extraction | ✅ |
| `launch-watcher.sh` | Launch watcher | ✅ |
| `list-mcp-status.sh` | List MCP status | ✅ |
| `mcp-unload-workflow.sh` | MCP unload workflow | ⚠️ May be legacy |
| `mcp-validation-batches.sh` | Batch validation | ✅ |
| `restore-mcp-config.sh` | Restore MCP config | ✅ |
| `stop-watcher.sh` | Stop watcher | ✅ |
| `suggest-mcps.sh` | MCP suggestions | ✅ |
| `validate-mcp-installation.sh` | MCP validation | ✅ |

### `.claude/skills/`

| Skill | Files | Source | Notes |
|-------|-------|--------|-------|
| `_index.md` | 1 | Jarvis | Skill index |
| `docx/` | ~50+ | Extracted PR-9.0 | OOXML schemas included |
| `mcp-builder/` | ~10 | Extracted PR-9.0 | Reference docs + scripts |
| `mcp-validation/` | 1 | Jarvis | SKILL.md only |
| `pdf/` | ~10 | Extracted PR-9.0 | Scripts for PDF manipulation |
| `pptx/` | ~50+ | Extracted PR-9.0 | OOXML schemas (DUPLICATE) |
| `session-management/` | 2 | AIfred | SKILL.md + example |
| `skill-creator/` | ~8 | Extracted PR-9.0 | Reference + scripts |
| `xlsx/` | 3 | Extracted PR-9.0 | SKILL.md + recalc.py |

**Note**: `docx/ooxml/` and `pptx/ooxml/` contain identical OOXML schemas (~70 files duplicated). Consider consolidating to shared location.

---

## `projects/` Directory (Project Aion)

### `projects/project-aion/`

| Item | Type | Notes |
|------|------|-------|
| `archon-identity.md` | File | Archon definitions (PR-1) ✅ |
| `ideas/` | Dir | 10 brainstorm files ✅ |
| `one-shot-prd.md` | File | Benchmark PRD (PR-2) ✅ |
| `plans/` | Dir | 2 implementation plans ✅ |
| `pr2-validation.md` | File | ⚠️ Old validation doc — archive? |
| `reports/` | Dir | 7 PR-specific reports (PR-10.2) ✅ |
| `roadmap.md` | File | Development roadmap ✅ |
| `versioning-policy.md` | File | Version conventions (PR-1) ✅ |

**Recommendation**: Archive `pr2-validation.md` if superseded.

---

## `docs/` Directory

| Item | Type | Notes |
|------|------|-------|
| `archive/` | Dir | Archived docs |
| `user-guide.md` | File | User documentation (PR-10.4) ✅ |

### `docs/archive/`

| Item | Notes |
|------|-------|
| `PROJECT-PLAN.md` | Original AIfred plan (PR-1) |
| `archive-log.md` | Archive tracking |
| `knowledge-cleanup-2026-01-09/` | PR-10.3 cleanup artifacts |

**Status**: ✅ Correct

---

## `scripts/` Directory (Root)

| Script | Purpose | Notes |
|--------|---------|-------|
| `bump-version.sh` | Version bumping | ✅ |
| `config.sh.template` | Config template | ⚠️ May be legacy |
| `setup-readiness.sh` | Setup validation | ✅ |
| `systemd/` | Systemd services | ✅ |
| `update-priorities-health.sh` | Priority updates | ⚠️ Check if used |
| `validate-hooks.sh` | Hook validation | ✅ |
| `weekly-context-analysis.sh` | Weekly analysis | ⚠️ Check if used |
| `weekly-docker-restart.sh` | Docker restart | ✅ |
| `weekly-health-check.sh` | Health check | ⚠️ Check if used |

---

## Version Currency Check

| File | Version Shown | Current (1.9.5) | Notes |
|------|---------------|-----------------|-------|
| `VERSION` | Check | Should be 1.9.5 | ✅ |
| `README.md` | 1.9.5 | ✅ Current | Updated PR-10.4 |
| `CLAUDE.md` | 1.9.5 | ✅ Current | |
| `paths-registry.yaml` | 1.9.5 | ✅ Current | Updated PR-10.3 |
| `roadmap.md` | 1.9.5 | ✅ Current | |
| `CHANGELOG.md` | Check | Verify latest entry | |

---

## Cleanup Recommendations

### Priority 1 (Immediate)

| Item | Action | Reason |
|------|--------|--------|
| `.opencode/` | Archive or delete | Likely legacy |
| `opencode.json` | Archive or delete | Likely legacy |
| `soft-restart.md` | Archive | Deprecated per design plan |
| `pr2-validation.md` | Archive | Old validation |

### Priority 2 (Soon)

| Item | Action | Reason |
|------|--------|--------|
| `paths-registry.yaml.template` | Archive | Template may be obsolete |
| `config.sh.template` | Archive | May be obsolete |
| OOXML schemas | Deduplicate | ~70 files duplicated across docx/pptx |
| `.claude/archive/setup-phases/` | Document | Verify what replaced them |

### Priority 3 (Review)

| Item | Action | Reason |
|------|--------|--------|
| Unregistered hooks | Audit | Many JS hooks may not be active |
| Weekly scripts | Verify | Check if update-priorities, weekly-context are used |
| `mcp-unload-workflow.sh` | Verify | May be superseded |

---

## Summary Statistics

| Category | Items | Issues Found |
|----------|-------|--------------|
| Root level | 13 | 3 legacy candidates |
| `.claude/` | ~200 | 5 cleanup items |
| `projects/` | ~25 | 1 archive candidate |
| `docs/` | ~8 | 0 |
| `scripts/` | 9 | 3 review items |
| **Total** | ~255 | ~12 actionable |

---

*Inventory Audit Report — PR-10 Organization Review*
*Generated: 2026-01-09*
