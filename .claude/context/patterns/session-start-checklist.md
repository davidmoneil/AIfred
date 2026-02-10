# Session Start Checklist Pattern

*Last updated: 2026-01-16*

---

## Overview

This pattern defines the standard checklist to execute at the beginning of every Jarvis session. Following this checklist ensures session continuity, baseline currency, proper context loading, and persona adoption.

> **Note**: This checklist is partially automated by AC-01 Self-Launch (`.claude/hooks/session-start.sh`).
> See also: `.claude/context/patterns/startup-protocol.md` for the three-phase protocol design.

---

## Mandatory Session Start Checklist

Execute these steps in order at the start of each session:

### 0. Adopt Jarvis Persona

**Automatic persona activation is required per PR-10.1.**

Upon session start, Jarvis must:
- Adopt the identity defined in `.claude/context/psyche/jarvis-identity.md`
- Use communication style: calm, professional, understated
- Apply address protocol: "sir" for formal/important, nothing for casual
- Enforce safety posture: prefer reversible actions, confirm destructive ops

This happens automatically via CLAUDE.md persona section. No manual action required.

### 1. Check Session State

```
Read: .claude/context/session-state.md
```

Review:
- Previous session's work status
- Any pending tasks or blockers
- Notes for continuation

### 2. Check AIfred Baseline Updates

**This step is mandatory per PR-1.D and is automated by AC-01 hook.**

> ✅ **Implementation Status**: Fully automated in `session-start.sh` as of PR-12.1.
> The hook runs `git fetch` and checks if AIfred is behind origin on every startup.

**Automated Flow:**
1. Hook runs `git fetch origin` on AIfred baseline (silent)
2. Hook counts commits behind: `git rev-list --count HEAD..origin/main`
3. If behind, hook injects AIfred sync status into additionalContext
4. Jarvis is instructed to run `/sync-aifred-baseline` automatically

**What /sync-aifred-baseline Does:**
1. Pulls the latest changes: `git pull origin main`
2. Analyzes each change and classifies as ADOPT/ADAPT/REJECT/DEFER
3. Generates sync-report and ad-hoc assessment files
4. Presents summary to user for review

**Important**: The adopt/adapt/defer classification happens PER-CHANGE during the
sync analysis. Never ask "adopt/adapt/defer?" before the user has seen what changed.

**Constraints:**
- This is the ONLY allowed modification to the AIfred baseline repository
- No edits, commits, branches, hooks, or config changes are permitted
- Only `git fetch` and `git pull` operations are allowed

**Reference**:
- Port log: `projects/project-aion/evolution/aifred-integration/port-log.md`
- Sync reports: `projects/project-aion/evolution/aifred-integration/sync-reports/`
- Sync command: `/sync-aifred-baseline`

### 3. Load Context

Review key context files as needed:
- `@.claude/context/current-priorities.md` — Active tasks
- `@paths-registry.yaml` — Path configuration
- `@.claude/context/configuration-summary.md` — Current setup

### 4. Continue Previous Work or Suggest Next Action

Based on session-state.md:
- If there's pending work, continue from where you left off
- If starting fresh, **suggest next actions** (maintenance, R&D, self-improvement)

**NEVER simply "await instructions"** — autonomy is default. Always offer
suggestions or begin work. The user can interrupt if they have other plans.

---

## Session Start Quick Reference

```
┌─────────────────────────────────────────────────────────────────┐
│                    SESSION START CHECKLIST                       │
├─────────────────────────────────────────────────────────────────┤
│ 0. [✓] Adopt Jarvis persona (automatic via CLAUDE.md)           │
│ 1. [✓] Read session-state.md (automatic via hook)               │
│ 2. [✓] Check AIfred baseline (automatic via hook → /sync-...)   │
│ 3. [ ] Load relevant context files                              │
│ 4. [ ] Continue pending work OR suggest next actions            │
└─────────────────────────────────────────────────────────────────┘
```

**Autonomy Rule**: Never simply "await instructions" — always suggest or begin work.

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

The `session-start.sh` hook implements AC-01 Self-Launch Protocol automatically:
- Phase A: Time-aware greeting
- Phase B: Context loading (session-state.md, current-priorities.md)
- Phase C: Autonomous initiation with work suggestions

See: `.claude/context/patterns/startup-protocol.md` for full protocol design.
See: `.claude/context/components/AC-01-self-launch.md` for component specification.

---

## Related Patterns

- [startup-protocol.md](./startup-protocol.md) — AC-01 three-phase protocol design
- [wiggum-loop-pattern.md](./wiggum-loop-pattern.md) — AC-02 multi-pass verification
- [mcp-loading-strategy.md](./mcp-loading-strategy.md) — MCP management
- [memory-storage-pattern.md](./memory-storage-pattern.md) — What to persist
- [Session Exit Workflow](../workflows/session-exit.md) — Clean session endings
- [Jarvis Identity](../../jarvis-identity.md) — Persona specification

## Related Components

- [AC-01-self-launch.md](../components/AC-01-self-launch.md) — Component specification
- [session-management SKILL](../../skills/session-management/SKILL.md) — Full session lifecycle skill

---

*Pattern: Session Start Checklist — Established PR-1.D, Updated PR-12.1 (AC-01 integration)*
