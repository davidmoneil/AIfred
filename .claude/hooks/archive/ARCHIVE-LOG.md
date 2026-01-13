# Hooks Archive Log

Records of archived hook files that are no longer active in settings.json.

---

## 2026-01-13 — PR-10.5 Hook Consolidation

**Archived**: 12 files
**Reason**: Hook cleanup during PR-10.5 Setup Upgrade

### Superseded by Shell Scripts
These JS hooks had shell script equivalents registered in settings.json:

| File | Superseded By | Notes |
|------|---------------|-------|
| `pre-compact.js` | `pre-compact.sh` | Shell wrapper registered in PreCompact |
| `session-start.js` | `session-start.sh` | Shell wrapper registered in SessionStart |

### Never Registered (Legacy AIfred)
These hooks existed but were never registered in Jarvis settings.json:

| File | Purpose | Notes |
|------|---------|-------|
| `audit-logger.js` | Session event logging | Replaced by context-accumulator.js |
| `context-reminder.js` | Context file suggestions | Not needed with current patterns |
| `docker-health-check.js` | Docker container checks | Can be re-enabled if needed |
| `memory-maintenance.js` | Memory MCP cleanup | Not needed currently |
| `project-detector.js` | Auto-detect projects | Replaced by project registration |
| `session-exit-enforcer.js` | Exit prompts | Not needed with /end-session |
| `session-tracker.js` | Session logging | Replaced by context-accumulator.js |
| `doc-sync-trigger.js` | Suggest doc updates | Future enhancement |
| `session-stop.js` | Stop notifications | Replaced by stop-auto-clear.sh |
| `worktree-manager.js` | Git worktree tracking | Future enhancement |

### To Re-enable
If any of these hooks are needed in the future:
1. Move back to `.claude/hooks/`
2. Add stdin/stdout wrapper if missing (see context-accumulator.js for pattern)
3. Register in `.claude/settings.json` under appropriate event

---

*Archived by Jarvis PR-10.5*
