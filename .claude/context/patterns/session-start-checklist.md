# Session Start Checklist Pattern

*Last updated: 2026-01-05*

---

## Overview

This pattern defines the standard checklist to execute at the beginning of every Jarvis session. Following this checklist ensures session continuity, baseline currency, and proper context loading.

---

## Mandatory Session Start Checklist

Execute these steps in order at the start of each session:

### 1. Check Session State

```
Read: .claude/context/session-state.md
```

Review:
- Previous session's work status
- Any pending tasks or blockers
- Notes for continuation

### 2. Check AIfred Baseline Updates

**This step is mandatory per PR-1.D.**

```bash
cd /Users/aircannon/Claude/AIfred && git fetch origin && git status
```

If the baseline is behind origin:

```bash
cd /Users/aircannon/Claude/AIfred && git pull origin main
```

**Constraints:**
- This is the ONLY allowed modification to the AIfred baseline repository
- No edits, commits, branches, hooks, or config changes are permitted
- Only `git fetch` and `git pull` operations are allowed

#### Quick Check: Any New Changes?

After pulling updates, check if any changes exist since Jarvis's last sync:

```bash
# Get last synced commit from paths-registry.yaml (aifred_baseline.last_synced_commit)
# Compare to current HEAD
cd /Users/aircannon/Claude/AIfred && git log --oneline <last_synced_commit>..HEAD
```

**If changes exist**, consider:
1. **Quick review**: Note significant changes for later
2. **Full sync**: Run `/sync-aifred-baseline` to generate a detailed adopt/adapt/reject report

**Reference**:
- Port log: `.claude/context/upstream/port-log.md`
- Sync reports: `.claude/context/upstream/sync-report-*.md`
- Sync command: `/sync-aifred-baseline`

### 3. Load Context

Review key context files as needed:
- `@.claude/context/projects/current-priorities.md` — Active tasks
- `@paths-registry.yaml` — Path configuration
- `@.claude/context/configuration-summary.md` — Current setup

### 4. Continue Previous Work or Start New

Based on session-state.md:
- If there's pending work, continue from where you left off
- If starting fresh, await user direction

---

## Session Start Quick Reference

```
┌─────────────────────────────────────────────────────────────────┐
│                    SESSION START CHECKLIST                       │
├─────────────────────────────────────────────────────────────────┤
│ 1. [ ] Read session-state.md                                    │
│ 2. [ ] Check AIfred baseline for updates (git fetch + pull)     │
│ 3. [ ] Load relevant context files                              │
│ 4. [ ] Continue pending work or await new direction             │
└─────────────────────────────────────────────────────────────────┘
```

---

## Rationale

### Why Check Baseline Updates?

The AIfred baseline may receive improvements that Jarvis should consider adopting. By checking for updates at session start:

1. **Stay Current**: Know when upstream has changes
2. **Inform Decisions**: Relevant changes can be queued for the sync workflow
3. **Prevent Drift**: Regular checks prevent Jarvis from diverging too far

### Why This Order?

1. **Session state first**: Understand context before taking action
2. **Baseline second**: Non-destructive check that informs planning
3. **Context third**: Load what's needed based on current work
4. **Continue last**: Act only after full context is established

---

## Integration with Hooks

The session-tracker hook (`audit-logger.js`) logs session start events. This pattern works alongside the hook system but is not enforced by hooks—it's a documented best practice.

Future enhancement: A pre-session hook could automate the baseline check.

---

## Related Patterns

- [mcp-loading-strategy.md](./mcp-loading-strategy.md) — MCP management
- [memory-storage-pattern.md](./memory-storage-pattern.md) — What to persist
- [Session Exit Workflow](../workflows/session-exit.md) — Clean session endings

---

*Pattern: Session Start Checklist — Established PR-1.D*
