# /housekeep — Quick Infrastructure Cleanup

**Purpose**: Fast, safe cleanup of transient files and stale state. Lightweight complement to `/maintain`.

**Usage**: `/housekeep [--phase <1-7>] [--dry-run] [--quiet]`

---

## Overview

`/housekeep` performs quick infrastructure hygiene — clearing signal files, rotating logs, resetting stale state. Unlike `/maintain` (full audit cycle, ~10K tokens), `/housekeep` is fast (~2K tokens), non-destructive, and safe for auto-triggering during idle or "Carry On" mode.

**Design**: 7 phases, each independently skippable. All phases are non-destructive by default.

## Options

| Option | Values | Default | Description |
|--------|--------|---------|-------------|
| `--phase` | 1-7 | all | Run specific phase only |
| `--dry-run` | flag | false | Show what would be cleaned |
| `--quiet` | flag | false | Minimal output (counts only) |

## Phases

### Phase 1: JICM Reset
Clear stale JICM signal files that accumulate between compression cycles.

```
Files to check:
  .claude/context/.jicm-standdown
  .claude/context/.compression-done.signal
  .claude/context/.compressed-context-ready.md
  .claude/context/.in-progress-ready.md
  .claude/context/.soft-restart-checkpoint.md

Action: Remove if older than 1 hour (stale from prior cycle)
Safety: Never remove during active compression (check .watcher-status state)
```

### Phase 2: Signal File Cleanup
Clear transient signal files from various subsystems.

```
Files to check:
  .claude/context/.ennoia-trigger
  .claude/context/.carry-on.signal
  .claude/context/.session-kill.signal
  .claude/state/ulfhedthnar-signals.json (reset if decay expired)

Action: Remove expired signals, reset counters
Safety: Check timestamps, never remove active signals
```

### Phase 3: Log Rotation
Rotate oversized log files. Keep recent, archive old.

```
Targets:
  .claude/logs/telemetry/events-*.jsonl  (>100KB → archive)
  .claude/logs/jicm/*.log               (>50KB → archive)
  .claude/logs/file-access.json          (>500KB → trim old entries)

Action: Move to .claude/archive/logs/YYYY-MM-DD/
Safety: Never delete, only move
```

### Phase 4: Core File Validation
Quick existence check on critical infrastructure files.

```
Required files:
  CLAUDE.md
  .claude/context/session-state.md
  .claude/context/current-priorities.md
  .claude/context/psyche/capability-map.yaml
  .claude/context/psyche/jarvis-identity.md
  .claude/context/compaction-essentials.md
  .claude/scripts/jarvis-watcher.sh

Action: Report missing files (do not create)
Safety: Read-only check
```

### Phase 5: Git Hygiene
Quick git health check without full audit.

```
Checks:
  - Uncommitted changes count
  - Unpushed commits count
  - Branch divergence from origin
  - Stale merge conflicts

Action: Report status, suggest actions
Safety: Read-only (no git operations)
```

### Phase 6: Index Sync
Verify index files match filesystem reality.

```
Indexes to validate:
  .claude/skills/_index.md        vs  .claude/skills/*/SKILL.md
  .claude/agents/README.md        vs  .claude/agents/*.md
  .claude/commands/README.md      vs  .claude/commands/*.md

Action: Report count mismatches
Safety: Read-only (no index modification)
```

### Phase 7: State Freshness
Check AC state files for staleness.

```
State files:
  .claude/state/components/AC-*.json

Checks:
  - last_updated older than 7 days → flag as stale
  - status inconsistency (file says "active" but component not operational)

Action: Report stale entries
Safety: Read-only
```

## Execution

Run all 7 phases sequentially. Each phase reports:
- Items checked
- Items cleaned/flagged
- Errors encountered

### Output Format (default)

```
/housekeep — Quick Infrastructure Cleanup
──────────────────────────────────────────
Phase 1: JICM Reset ............ 2 cleared
Phase 2: Signal Cleanup ........ 0 cleared
Phase 3: Log Rotation .......... 1 archived
Phase 4: Core Files ............ 7/7 present
Phase 5: Git Hygiene ........... 3 uncommitted, 0 unpushed
Phase 6: Index Sync ............ all consistent
Phase 7: State Freshness ....... 2 stale
──────────────────────────────────────────
Total: 3 cleaned, 2 flagged, 0 errors
```

### Output Format (--quiet)

```
housekeep: 3 cleaned, 2 flagged, 0 errors
```

## When to Run

- **Session start**: After JICM compression/clear cycle
- **Carry On mode**: First action in idle maintenance queue
- **Before commit**: Ensure clean state
- **Manual**: When things feel cluttered

## Relationship to /maintain

| Aspect | /housekeep | /maintain |
|--------|-----------|-----------|
| Duration | ~30 seconds | ~5 minutes |
| Token cost | ~2K | ~10K |
| Scope | Transient files, quick checks | Full audit, reports |
| Output | Inline summary | Report file |
| Auto-trigger | Safe for idle/Carry On | Requires user or Ennoia |
| Destructive | Never (moves, never deletes) | Non-destructive default |

## Integration

- **Ennoia**: First action in idle maintenance queue (lowest threshold)
- **AC-09**: Part of session end cleanup
- **Watcher**: Safe to run post-compression (no context cost concern)

---

*Part of Jarvis Aion Trinity — lightweight infrastructure hygiene*
