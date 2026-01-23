# M3 Implementation Plan: JICM Complement Commands

**Milestone**: AIfred Integration M3 — JICM Complements
**Sessions**: 3.1 (Context Analysis), 3.2 (Knowledge Capture)
**Estimated Effort**: 3.5-4 hours total
**Status**: ✅ COMPLETE (2026-01-23)
**Commit**: `a9cf29a`

---

## Overview

Port 4 AIfred commands that complement Jarvis's existing JICM system:

| Command | Purpose | Session |
|---------|---------|---------|
| `/context-analyze` | Weekly context usage analysis | 3.1 |
| `/context-loss` | Report forgotten context after compaction | 3.1 |
| `/capture` | Rapid knowledge capture (4 types) | 3.2 |
| `/history` | Search/browse captured knowledge | 3.2 |

---

## Session 3.1: Context Analysis Commands

### Files to Create

| File | Purpose |
|------|---------|
| `.claude/commands/context-analyze.md` | Command wrapper for analysis script |
| `.claude/commands/context-loss.md` | Context loss reporting command |
| `.claude/context/compaction-essentials.md` | Essential context preserved after compaction |

### Files to Modify

| File | Change |
|------|--------|
| `scripts/weekly-context-analysis.sh` | Update paths, adapt to Jarvis log sources |
| `.claude/logs/README.md` | Add context-loss-reports.jsonl documentation |
| `.claude/context/designs/unified-logging-architecture.md` | Add context-loss as event source |

### Key Adaptations

**1. `/context-analyze`**
- Update script path to `$CLAUDE_PROJECT_DIR/scripts/weekly-context-analysis.sh`
- Adapt log reading from AIfred's single `audit.jsonl` to Jarvis's multiple sources:
  - `telemetry/events-*.jsonl` (AC events)
  - `selection-audit.jsonl` (tool selections)
  - `session-events.jsonl` (lifecycle)
- Ollama integration remains optional with graceful degradation

**2. `/context-loss`**
- Use `CLAUDE_SESSION_ID` env var (Jarvis standard) instead of `.current-session` file
- Add Jarvis-specific categories: `archon`, `orchestration`, `wiggum`
- Integrate with telemetry-emitter.js for event emission
- Pattern detection: 3+ similar reports → suggest adding to `compaction-essentials.md`

**3. `compaction-essentials.md`** (new file)
- Archon architecture references (Nous/Pneuma/Soma)
- Wiggum Loop cycle
- AC component list (AC-01 through AC-09)
- Key file paths (session-state.md, current-priorities.md, paths-registry.yaml)
- Always-on MCPs (Memory, Git, Filesystem)

### Session 3.1 Exit Criteria

- [ ] `/context-analyze` generates reports from Jarvis logs
- [ ] `/context-loss` logs JSONL + detects patterns (3+ triggers recommendation)
- [ ] `compaction-essentials.md` contains Jarvis-specific essentials
- [ ] Telemetry events emitted for context loss reports
- [ ] Commit: `feat: Add context analysis commands (M3-S3.1)`

---

## Session 3.2: Knowledge Capture Commands

### Files to Create

| File | Purpose |
|------|---------|
| `.claude/commands/capture.md` | Knowledge capture command (4 types) |
| `.claude/commands/history.md` | History search/browse command (7 subcommands) |
| `.claude/history/index.md` | Master searchable index |
| `.claude/history/templates/learning.md` | Learning capture template |
| `.claude/history/templates/decision.md` | Decision capture template |
| `.claude/history/templates/session.md` | Session capture template |
| `.claude/history/templates/research.md` | Research capture template |
| `.claude/history/*/README.md` | Directory READMEs (4 files) |

### Directory Structure

```
.claude/history/
├── index.md
├── templates/
│   ├── learning.md, decision.md, session.md, research.md
├── learnings/
│   └── bugs/, patterns/, tools/, workflows/, archon/, orchestration/
├── decisions/
│   └── architecture/, tools/, approaches/, security/, integration/
├── sessions/
└── research/
    └── technologies/, approaches/, references/, aifred-porting/
```

### Key Adaptations

**1. `/capture` (4 types)**
- **learning**: bugs, patterns, tools, workflows + `archon`, `orchestration`
- **decision**: architecture, tools, approaches + `security`, `integration`
- **session**: date-based, includes commits and files modified
- **research**: technologies, approaches, references + `aifred-porting`

Integration:
- Auto-update `index.md` on capture
- Emit telemetry via `telemetry-emitter.js`
- Optional Memory MCP promotion via `/history promote`

**2. `/history` (7 subcommands)**
- `search "[query]"` — Full-text search with filters
- `recent [count]` — Most recent entries (default: 10)
- `stats` — Entry counts by type/category
- `show <path>` — Display specific entry
- `tags [tag]` — Browse by tag
- `category <cat>` — Browse by category
- `related <entry>` — Find related entries
- `promote <entry>` — (NEW) Promote to Memory MCP

### Session 3.2 Exit Criteria

- [ ] `/capture` creates entries in all 4 types
- [ ] `/history` searches and browses entries
- [ ] Templates exist for all capture types
- [ ] History directory structure created
- [ ] index.md auto-updates on capture
- [ ] Memory MCP integration works (promote command)
- [ ] Commit: `feat: Add knowledge capture commands (M3-S3.2)`

---

## Design Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Log source adaptation | Aggregate from Jarvis's multiple logs | Unified logging architecture (M2) provides richer data |
| History vs Memory MCP | Complement (not replace) | Files = full context; MCP = cross-session recall |
| Compaction essentials location | `.claude/context/` | Consistent with AIfred, part of Nous layer |
| Session tracking | `CLAUDE_SESSION_ID` env var | Already used by telemetry-emitter.js |
| Template location | `.claude/history/templates/` | Co-located for self-contained system |
| Ollama dependency | Optional with graceful degradation | Script already handles this |

---

## Integration Points

1. **Telemetry**: All events via `telemetry-emitter.js` (AC-04 for context, AC-05 for capture)
2. **Memory MCP**: Optional promotion for cross-session retrieval
3. **Self-Reflection (AC-05)**: `/reflect` can query history for patterns
4. **Session Completion (AC-09)**: `/end-session` prompts for `/capture session`
5. **JICM**: `/context-loss` feeds improvements to `compaction-essentials.md`

---

## Verification Plan

### Session 3.1 Verification
1. Run `/context-analyze --test` to verify Ollama (if available)
2. Run full analysis, verify report in `.claude/logs/reports/`
3. Run `/context-loss "forgot X"` 3 times, verify pattern detection
4. Verify telemetry events in `telemetry/events-*.jsonl`

### Session 3.2 Verification
1. `/capture learning "test insight"` — verify file created
2. `/capture decision "test choice"` — verify template populated
3. `/capture session "test session"` — verify commits/files listed
4. `/history search "test"` — verify search returns entries
5. `/history recent 5` — verify sorting
6. `/history promote <entry>` — verify Memory MCP entity created

---

## Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| Log format differences break script | Add format detection, fallback to empty |
| Large history bloats context | Don't auto-load; use search on demand |
| Memory MCP unavailable | Graceful degradation, warn user |
| Category detection incorrect | Allow manual `--category` override |

---

## Milestone 3 Completion Checklist

- [ ] Session 3.1 complete (context-analyze, context-loss, compaction-essentials)
- [ ] Session 3.2 complete (capture, history, templates, directory structure)
- [ ] Integration tested end-to-end
- [ ] Documentation updated (logs/README.md, unified-logging-architecture.md)
- [ ] Chronicle entry written
- [ ] Roadmap checkboxes marked
- [ ] Commit history clean

---

## Critical Source Files

| AIfred Source | Jarvis Target |
|---------------|---------------|
| `.claude/commands/context-analyze.md` | `.claude/commands/context-analyze.md` |
| `.claude/commands/context-loss.md` | `.claude/commands/context-loss.md` |
| `.claude/commands/capture.md` | `.claude/commands/capture.md` |
| `.claude/commands/history.md` | `.claude/commands/history.md` |
| `.claude/context/compaction-essentials.md` | `.claude/context/compaction-essentials.md` |
| `scripts/weekly-context-analysis.sh` | `scripts/weekly-context-analysis.sh` (modify) |

---

*Plan created: 2026-01-23*
