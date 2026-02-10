# Compressed Context Checkpoint

**Generated**: 1739242972
**Source**: JICM v5.8 Compression Agent
**Trigger**: User request (intelligent-compress for continuation)
**JICM Version**: v5.8.0
**Cycle**: 3+ (anchored iterative summarization)

---

## Foundation Context

**Identity**: Jarvis — autonomous Archon, calm/precise/safety-conscious scientific assistant
- Address: "sir" (formal/warnings), no honorific (casual), never servile butler tone
- Humor: rare, dry, deadpan, NEVER during emergencies
- Tone: calm, professional, understated, concise

**Guardrails** (NEVER):
- Edit AIfred baseline (read-only at 2ea4e8b)
- Store secrets in tracked files (use .claude/secrets/credentials.yaml, gitignored)
- Force push to main/master
- Skip destructive op confirmation
- Over-engineer
- Wait passively
- tmux multi-line strings via send-keys -l (causes corruption)

**Guardrails** (ALWAYS):
- Check context/ before advising
- TodoWrite for 2+ step tasks
- Reversible actions preferred
- Document decisions in Memory MCP
- Update session-state.md at session boundaries
- Epoch seconds (date +%s) for signal file timestamps
- Bash functions in $(...) must return 0 (bash 3.2 macOS compat)
- Absolute paths in responses (/Users/aircannon/Claude/Jarvis/...)

**Architecture** (3 layers):
- Nous (knowledge): .claude/context/ — patterns, state, priorities
- Pneuma (capabilities): .claude/ — agents, hooks, skills, commands
- Soma (infrastructure): /Jarvis/ — docker, scripts, projects

**Git Workflow**:
- Branch: Project_Aion (all development)
- Baseline: main (read-only AIfred at 2ea4e8b)
- Push: PAT from yq -r '.github.aifred_token' credentials.yaml | head -1 | tr -d '[:space:]'

**Capability Discovery**: capability-map.yaml (manifest router) → skills/_index.md → agents/README.md → commands/README.md

**AC Components** (9 Hippocrenae + 1 Ulfhedthnar):
| ID | Component | When | Key File |
|----|-----------|------|----------|
| AC-01 | Self-Launch | Session start | hooks/session-start.sh |
| AC-02 | Wiggum Loop | Always (default) | hooks/wiggum-loop-tracker.js |
| AC-03 | Milestone Review | Work completion | hooks/milestone-coordinator.js |
| AC-04 | JICM | Context 65%/73%/78.5% | scripts/jarvis-watcher.sh |
| AC-05 | Self-Reflection | Session end | commands/reflect.md |
| AC-06 | Self-Evolution | Idle time | commands/evolve.md |
| AC-07 | R&D Cycles | Research | commands/research.md |
| AC-08 | Maintenance | Health checks | commands/maintain.md |
| AC-09 | Session Completion | Session end | commands/end-session.md |
| AC-10 | Ulfhedthnar | Berserker override (dormant) | skills/ulfhedthnar/ |

**Wiggum Loop** (AC-02 default): Execute → Check → Review → Drift Check → Context Check → Continue/Complete

**JICM Thresholds**:
- 55%: Warning begins
- 65%: Auto-compress (/intelligent-compress)
- 73%: Emergency /compact if stuck
- 78.5%: Lockout ceiling — no new work

**Observation Masking** (60-80% token reduction on tool outputs):
- Tool results → outcome + file ref: `[Read /path/file.sh → 113 lines, bash script]`
- Command outputs → exit code + 1-line summary: `[shellcheck → clean, 4 SC1091 info]`
- Search results → hit count + top 3 paths: `[Grep "pattern" → 8 files, top: p1, p2, p3]`
- API responses → status + key fields: `[curl brave-search → 200, 5 results]`
- Never mask errors, file paths, security output

**Key Counts** (verified 2026-02-10):
- Patterns: 51
- Skills: 28 total (11 discoverable + 15 absorbed + 1 example + 1 _shared)
- Agents: 13 (12 operational + 1 template)
- Commands: 40 (.md files excl. README)
- Hooks: 26 (21 .js + 5 .sh) — was 25, +1 from memory-mirror.js
- MCPs: 5 (memory, local-rag, fetch, git, playwright)

**Key Gotchas**:
- bash 3.2: $(...) must return 0
- tmux: single-line -l strings only, wait for idle before sending
- JICM lockout: ~78.5% ceiling
- yq: pipe through head -1 (doc separator)
- Hardcoded counts drift: verify via glob
- Auto-provisioned MCPs (git/fetch/memory): cannot unload, shadow via skills
- capability-matrix.md DEPRECATED → use capability-map.yaml
- Hook matchers: anchored regex (^Bash$) not bare strings ("Write" matches TodoWrite!)
- VERSION file (2.3.0) ≠ architecture version (v5.9.0)
- AC state file drift: .claude/state/components/ gets stale vs reality
- AC-01 state overwrite: session-start hook writes flat JSON, destroying structure (EVO-2026-02-005)
- NEVER /clear without updating session-state.md + current-priorities.md first
- Code review agent hallucinations: ALWAYS verify findings by reading source before acting
- jq --arg: Use `jq --arg v "$VAR" '{key: $v}'` NOT `"'"$VAR"'"` string interpolation
- /export path handling: /export takes relative path from cwd, not absolute path (double cwd bug)

---

## Session Objective

Complete Roadmap II Phase B (Stream 2 Implementation) — all 7 tasks. B.1-B.6 now complete, only B.7 (AC-10 Ulfhedthnar) remains.

---

## Current Task

**Status**: User requested 6 B.4 feature enhancements — 5/6 COMPLETE
**Active task**: #6 in_progress (status line accuracy — hardcoded overhead, stale cache, no data consistency validation)

User's B.4 feature requests (Feb 10 session):
1. ✅ Tmux window titles "Jarvis" and "Watcher" — DONE (launch-jarvis-tmux.sh + live rename)
2. ✅ /export before compress/clear — DONE (watcher v5.8.4, export_chat_history() function)
3. ✅ Memory mirror hook — DONE (memory-mirror.js PostToolUse Write hook, symlinks for external scripts)
4. ✅ Tool output offloading — DOCUMENTED (compaction-essentials.md strategy, .tool-output/ dir created, implementation deferred)
5. ⏳ Status line accuracy — IN PROGRESS (root cause: hardcoded 25.8K overhead vs actual ~50K+)
6. ✅ ~/.claude/ data concerns — ADDRESSED (symlinks for scripts, hook identified as Jarvis-created)

Phase B completion status: **6/7 tasks COMPLETE**
- B.1: claude-code-docs install — **COMPLETE** (CannonCoPilot fork, /docs command, session-start sync)
- B.2: Deep Research scripts — **COMPLETE** (research-plan.sh, research-synthesize.sh, v2.2.0)
- B.3: Hook consolidation — **COMPLETE** (34→23 hooks, later +3 = 26 hooks)
- B.4: JICM context engineering — **COMPLETE** (Phases 1-4 all done, watcher v5.8.4)
- B.5: Model routing — **COMPLETE** (26 SKILL.md + 23 capability-map entries)
- B.6: Automatic skill learning — **COMPLETE** (reflect Phase 2.5, evolve Step 2.5, skill-candidates.yaml + skill-promotions.yaml)
- B.7: AC-10 Ulfhedthnar — NOT STARTED (~6-8 hrs remaining)

---

## Work In Progress

**Current TodoWrite**: Task #6 (status line accuracy) — IN PROGRESS
- Root cause identified: hardcoded 25.8K overhead estimate in statusline script vs actual ~50K+ dynamic overhead
- No data consistency validation (can show wrong threshold percentages)
- Stale cache file reads
- Fix requires: dynamic overhead calculation, cache invalidation, threshold validation

**Files modified this session**:
- .claude/scripts/launch-jarvis-tmux.sh (tmux naming + automatic-rename off)
- .claude/scripts/jarvis-watcher.sh (v5.8.4: export_chat_history, version bump)
- .claude/agents/compression-agent.md (chat export as Priority 3 source)
- .claude/hooks/memory-mirror.js (NEW: PostToolUse Write mirror to MEMORY.md)
- .claude/settings.json (memory-mirror hook registration)
- .claude/context/compaction-essentials.md (tool output offloading docs, hook count 26)
- .gitignore (exports/, tool-output/, memory mirror, symlinks)

Last commits:
- de4ffd7: feat: B.4 Context Engineering JICM — Phases 1-4 complete (18 files, +578/-48)
- 6de205c: feat: B.1 claude-code-docs — Jarvis fork integrated
- c75f201: feat: B.3 Hook Consolidation — 34→23 hooks (32% reduction)
- 5f3cdc9: chore: file EVO-2026-02-010 — watcher startup recovery + emergency ESC interrupt
- 22192b5: fix: Phase B polish — 7 issues from validation sweep (3 files)
- 38f2e0e: chore: end-session — Phase B 4/7 complete (5 files)

Branch status: Project_Aion (commits through 38f2e0e pushed, likely uncommitted work on feature requests)

---

## Decisions Made

1. **B.2 Research Pattern**: Query decomposition uses keyword heuristics (not LLM) for speed and dependency-free operation. Type-aware sub-question generation (comparison queries get "alternatives", academic get papers, trend queries skip both).

2. **B.4 Watcher v5.8.3**: 4 bug fixes applied — failsafe loops on compression agent errors, emergency /compact when compression stalls, /clear retry mechanism, failure recording in state files.

3. **B.5 Model Routing Strategy**: Three-tier cost-quality tradeoff:
   - Opus (2 skills, 1 agent): Deep reasoning tasks (research synthesis, knowledge graph, multi-source analysis)
   - Sonnet (7 skills, 8 agents): Workhorse tier for implementation, review, standard agent work
   - Haiku (2 skills, 3 agents): Lightweight monitoring, compression, data transformation (speed > depth)

4. **B.6 Skill Learning Pipeline**: Closed-loop automation — /reflect Phase 2.5 detects repeated manual processes (3+ steps done 2+ times) → writes to skill-candidates.yaml → /evolve Step 2.5 promotes mature candidates (frequency >= 3, complexity <= medium) into full skills. High-complexity candidates become evolution proposals instead (preserves human oversight).

5. **Validation Sweep Findings** (commit 22192b5): 7 issues found:
   - 3 CRITICAL: Version string drift (jarvis-watcher.sh had v5.8.2 in banner/log, 5.6.2 in update_status vs actual v5.8.3)
   - 2 MEDIUM: research-ops version mismatch (capability-map.yaml said 2.1.0, SKILL.md was 2.2.0), reflect.md phase numbering error (said "Phase 5" should be "Phase 4")
   - 2 LOW: SC2005 useless echo, SC2001 sed vs ${var%suffix}

6. **Version String Drift Pattern**: jarvis-watcher.sh has 4 version locations (changelog, help, banner, startup log, update_status). Easy to update changelog and miss display strings. Consider single VERSION variable at top that all functions reference.

7. **B.4 Phase 1: Anchored Iterative Summarization**: Compression agent now reads prior checkpoint first (if exists), merges new session content into existing sections instead of regenerating from scratch. Prevents silent information loss across compression cycles. Section validation table added to compression-agent.md.

8. **B.4 Phase 2: File-system-as-memory**: `.claude/context/jicm/` hierarchy created with sessions/, cross-session/, archive/. session-start hook creates new session directory; end-session archives old sessions. Cross-session YAML files preserve patterns-observed, file-knowledge, error-solutions across sessions.

9. **B.4 Phase 3: Observation Masking**: observation-tracker.js PostToolUse hook tracks tool output size in telemetry. Masking thresholds documented in compaction-essentials.md (60-80% reduction target).

10. **B.4 Phase 4: Context Poisoning Detection**: context-health-monitor.js UserPromptSubmit hook monitors for context degradation (high entropy, off-topic drift, adversarial injection, repeated failures). 4 new degradation benchmarks added (BM-11: entropy tracking, BM-12: topic coherence, BM-13: injection patterns, BM-14: failure cascades). AC-06/07/08 failure_modes_tested now true.

11. **Phase A Residuals Addressed**: AC-07 cross-reference added to research-ops SKILL.md. Roadmap B.1 commit ref fixed. failure_modes_tested=true for AC-06/07/08 via B.4 degradation benchmarks.

12. **Critical Review Findings**: Code review agent generated 6 findings — 5 were false positives (Python injection in pure-bash files, bugs in code patterns that don't exist). 5 real issues found manually: unused vars in 2 hooks, hook count drift (25 not 23), stale roadmap refs, research-ops AC-07 cross-ref gap.

13. **EVO-2026-02-010**: Watcher startup recovery (checks for .compression-done.signal + .compressed-context-ready.md + .in-progress-ready.md on startup, resumes from partial compression). Emergency ESC interrupt at ~95% context (statusline monitor + tmux send-keys Escape + /compact).

14. **Watcher v5.8.4 /export Integration**: Two-layer export strategy — tmux capture-pane + /export command before compress/clear. export_chat_history() function in watcher extracts conversation to .claude/context/exports/. Compression agent reads exports as Priority 3 source.

15. **Memory Mirror Hook**: memory-mirror.js PostToolUse Write hook syncs MEMORY.md changes to ~/.claude/projects/-Users-aircannon-Claude-Jarvis/memory/MEMORY.md. External scripts (not in Jarvis repo) use symlinks to `.claude/scripts/` to avoid ~/.claude/ file ownership confusion.

16. **Tool Output Offloading Strategy**: Write large tool outputs (>2000 tokens) to `.claude/context/.tool-output/` temp files, reference inline with summary. Cleanup on session-start (>24h old). Deferred implementation until needed.

17. **Tmux Window Naming**: launch-jarvis-tmux.sh sets window names to "Jarvis" (window 0) and "Watcher" (window 1). `set -g automatic-rename off` prevents tmux from overwriting. Live rename via `tmux rename-window` after launch.

---

## Active Context

**Branch**: Project_Aion
**Version**: v5.9.0
**Last Commit**: 38f2e0e (end-session — Phase B 4/7 complete)
**Session Date**: 2026-02-10 (continuation from Feb 9-10 evening sessions)
**MCPs**: 5 active (memory, local-rag, fetch, git, playwright)

**Roadmap II Phase A**: COMPLETE (verified 2026-02-09)
- All 9 AC components active (PR-12.1-12.10)
- PR-13 monitoring: telemetry-dashboard.sh + benchmark-suite.yaml (14 benchmarks: 10 original + 4 degradation)
- PR-14 SOTA catalog: 55 entries, 9 categories

**Roadmap II Phase B Progress**: 6/7 tasks COMPLETE
- **Remaining work**: B.7 AC-10 Ulfhedthnar (6-8 hrs — berserker override system)
- **Phase B plan**: `.claude/plans/roadmap-ii.md` Section Phase B

**Git Status**: Committed through 38f2e0e (Phase B 4/7 done), likely uncommitted feature request work (telemetry logs, AC state files, new hook, watcher v5.8.4)

**Credential Quick Ref**:
- PAT extraction: `yq -r '.github.aifred_token' .claude/secrets/credentials.yaml | head -1 | tr -d '[:space:]'`
- Push pattern: See git-ops skill or memory MEMORY.md

**Recent Accomplishments** (this session, Feb 10):
- B.4 Phase 1: compression-agent.md updated with preservation manifest, section validation (14 lines)
- B.4 Phase 2: .claude/context/jicm/ hierarchy, README.md (40 lines), 3 cross-session YAML files, session-start integration (13 lines), end-session archival step
- B.4 Phase 3: observation-tracker.js (67 lines), compaction-essentials.md masking thresholds
- B.4 Phase 4: context-health-monitor.js (89 lines), 4 degradation benchmarks, AC-06/07/08 state file updates
- Phase A residuals: research-ops AC-07 cross-ref, roadmap commit ref fix
- Critical review: 5 real issues found and fixed (unused vars, hook count drift, stale refs)
- EVO-2026-02-010 filed: watcher startup recovery + emergency ESC interrupt
- User feature requests: tmux naming, /export wiring, memory-mirror.js, tool output offloading docs

**File Paths** (absolute):
- JICM infrastructure: /Users/aircannon/Claude/Jarvis/.claude/context/jicm/README.md, cross-session/*.yaml
- New hooks: /Users/aircannon/Claude/Jarvis/.claude/hooks/observation-tracker.js, context-health-monitor.js, memory-mirror.js
- Compression agent: /Users/aircannon/Claude/Jarvis/.claude/agents/compression-agent.md
- Compaction essentials: /Users/aircannon/Claude/Jarvis/.claude/context/compaction-essentials.md
- Session hooks: /Users/aircannon/Claude/Jarvis/.claude/hooks/session-start.sh
- Commands: /Users/aircannon/Claude/Jarvis/.claude/commands/end-session.md
- Benchmarks: /Users/aircannon/Claude/Jarvis/.claude/test/benchmarks/benchmark-suite.yaml
- AC state files: /Users/aircannon/Claude/Jarvis/.claude/state/components/AC-06-evolution.json, AC-07-rd.json, AC-08-maintenance.json
- Research scripts: /Users/aircannon/Claude/Jarvis/.claude/skills/research-ops/scripts/research-plan.sh, research-synthesize.sh
- Learning YAML: /Users/aircannon/Claude/Jarvis/.claude/context/learning/skill-candidates.yaml, skill-promotions.yaml
- Watcher: /Users/aircannon/Claude/Jarvis/.claude/scripts/jarvis-watcher.sh
- Launch script: /Users/aircannon/Claude/Jarvis/.claude/scripts/launch-jarvis-tmux.sh
- Capability map: /Users/aircannon/Claude/Jarvis/.claude/context/psyche/capability-map.yaml
- Commands: /Users/aircannon/Claude/Jarvis/.claude/commands/reflect.md, evolve.md
- Session state: /Users/aircannon/Claude/Jarvis/.claude/context/session-state.md
- Priorities: /Users/aircannon/Claude/Jarvis/.claude/context/current-priorities.md
- Roadmap: /Users/aircannon/Claude/Jarvis/.claude/plans/roadmap-ii.md
- Root of trust: /Users/aircannon/Claude/Jarvis/CLAUDE.md
- Persona: /Users/aircannon/Claude/Jarvis/.claude/jarvis-identity.md
- This checkpoint: /Users/aircannon/Claude/Jarvis/.claude/context/.compressed-context-ready.md
- Active tasks: /Users/aircannon/Claude/Jarvis/.claude/context/.active-tasks.txt

---

## Todos

**Active TodoWrite Task**: #6 (status line accuracy) — IN PROGRESS
- Root cause: hardcoded 25.8K overhead estimate vs actual ~50K+
- Fix requires: dynamic overhead calculation, cache invalidation, threshold validation
- Estimated effort: ~2-3 hrs

**Completed This Session**:
- #1 [completed] Fix tmux window titles to "Jarvis" and "Watcher"
- #2 [completed] Wire /export into compression and /clear workflows — watcher v5.8.4
- #4 [completed] Create memory-mirror hook for MEMORY.md
- #5 [completed] Document tool output offloading strategy

**Next session priorities**:
1. **Complete task #6** — status line accuracy fix
2. B.7 AC-10 Ulfhedthnar (berserker override system, 6-8 hrs)
3. Phase C Mac Studio Infrastructure (Wed Feb 12+ arrival)

---

## Next Steps

1. **Complete task #6: status line accuracy**
   - Read statusline script to understand current overhead calculation
   - Implement dynamic overhead detection (measure actual Claude Code baseline tokens)
   - Add cache invalidation logic
   - Add data consistency validation (threshold % matches JICM config)
   - Test across multiple context levels
   - Commit fix

2. **B.7 AC-10 Ulfhedthnar** — Berserker override system (6-8 hrs):
   - B.7.1: Detection hooks (ulfhedthnar-detector.js — defeat signals, confidence decay, user `/unleash` trigger)
   - B.7.2: Override protocol (Frenzy Mode, Berserker Wiggum Loop, approach rotation, escalation ladder, progress anchoring)
   - B.7.3: Persona & locked skill (hidden skill at skills/ulfhedthnar/, discoverable: false, notification "Ulfhedthnar asks to be freed")
   - B.7.4: Safety constraints (no destructive override, AIfred baseline protection, JICM awareness, auto-disengage, 30-min cooldown)
   - See roadmap-ii.md Phase B section B.7 for full scope

3. **Phase C Mac Studio Infrastructure** (Wed Feb 12+ arrival):
   - C.1: Base setup & Docker environment (~4 hrs)
   - C.2: Obsidian vault setup (~3 hrs)
   - C.3: n8n workflow automation (~4 hrs)
   - C.4: Local Supabase (~4 hrs)

---

## Resume Instructions

### Immediate Context
User requested 6 B.4 feature enhancements. 5 of 6 complete. Task #6 (status line accuracy) is IN PROGRESS. B.4 Context Engineering complete (all 4 phases done, commit de4ffd7). Phase B 6/7 done. Only B.7 (AC-10 Ulfhedthnar) remains after task #6.

### On Resume
1. Read this checkpoint — context has been compressed via JICM v5.8
2. Adopt Jarvis persona (jarvis-identity.md) — calm, precise, "sir" for formal
3. Acknowledge continuation — "Context restored, sir. Task #6 (status line accuracy) in progress — 5 of 6 feature requests complete. Phase B at 6/7 tasks done."
4. Begin work immediately — read .active-tasks.txt for task details, DO NOT re-read session-state.md (may show stale status)

### Key Files (Absolute Paths)
- /Users/aircannon/Claude/Jarvis/.claude/context/.active-tasks.txt — task #6 details
- /Users/aircannon/Claude/Jarvis/.claude/context/session-state.md — session history and next pickup
- /Users/aircannon/Claude/Jarvis/.claude/context/current-priorities.md — task queue with Phase B status
- /Users/aircannon/Claude/Jarvis/.claude/plans/roadmap-ii.md — full Phase B plan and scope
- /Users/aircannon/Claude/Jarvis/.claude/scripts/jarvis-watcher.sh — JICM watcher v5.8.4
- /Users/aircannon/Claude/Jarvis/.claude/scripts/launch-jarvis-tmux.sh — tmux window naming
- /Users/aircannon/Claude/Jarvis/.claude/hooks/memory-mirror.js — B.4 feature request deliverable
- /Users/aircannon/Claude/Jarvis/.claude/context/psyche/capability-map.yaml — v3 with full model routing
- /Users/aircannon/Claude/Jarvis/.claude/context/jicm/README.md — file-system-as-memory architecture
- /Users/aircannon/Claude/Jarvis/.claude/hooks/observation-tracker.js — B.4 Phase 3 deliverable
- /Users/aircannon/Claude/Jarvis/.claude/hooks/context-health-monitor.js — B.4 Phase 4 deliverable
- /Users/aircannon/Claude/Jarvis/.claude/skills/research-ops/scripts/research-plan.sh — B.2 deliverable
- /Users/aircannon/Claude/Jarvis/.claude/skills/research-ops/scripts/research-synthesize.sh — B.2 deliverable
- /Users/aircannon/Claude/Jarvis/.claude/context/learning/skill-candidates.yaml — B.6 deliverable
- /Users/aircannon/Claude/Jarvis/.claude/context/learning/skill-promotions.yaml — B.6 deliverable
- /Users/aircannon/Claude/Jarvis/.claude/commands/reflect.md — Phase 2.5 integration
- /Users/aircannon/Claude/Jarvis/.claude/commands/evolve.md — Step 2.5 integration
- /Users/aircannon/Claude/Jarvis/CLAUDE.md — root of trust (guardrails, architecture, quick ref)
- /Users/aircannon/Claude/Jarvis/.claude/jarvis-identity.md — persona specification
- /Users/aircannon/Claude/Jarvis/.claude/context/compaction-essentials.md — post-compression essentials

---

## Critical Notes

1. **B.4 all 4 phases complete** — Anchored iterative summarization (preservation manifest), file-system-as-memory (.claude/context/jicm/ hierarchy), observation masking (observation-tracker.js), context poisoning detection (context-health-monitor.js + 4 degradation benchmarks). Commit de4ffd7, 18 files changed, +578/-48.

2. **Task #6 IN PROGRESS** — Status line accuracy fix. User reported hardcoded overhead estimates, stale cache, no data consistency validation. Root cause identified as 25.8K hardcoded overhead vs actual ~50K+ dynamic overhead. Needs implementation.

3. **Phase B is 6/7 COMPLETE** — B.1, B.2, B.3, B.4, B.5, B.6 all done. B.7 AC-10 Ulfhedthnar is the only remaining Phase B task (6-8 hrs estimated).

4. **Hook count changed to 26** — Was 25 after B.4 Phase 4, now 26 with memory-mirror.js added. compaction-essentials.md updated to reflect 26 hooks (21 .js + 5 .sh). settings.json has new registration.

5. **Watcher now v5.8.4** — Added export_chat_history() function, two-layer export (tmux capture + /export), version bump. compression-agent.md reads exports as Priority 3 source.

6. **Memory mirror operational** — memory-mirror.js syncs MEMORY.md to ~/.claude/projects/memory/MEMORY.md. External scripts use symlinks to .claude/scripts/ (not direct files in ~/.claude/) to avoid file ownership confusion.

7. **Tool output offloading documented** — Strategy in compaction-essentials.md, .tool-output/ directory created, .gitignore updated. Implementation deferred until actually needed (strategy alone may be sufficient).

8. **Tmux window naming fixed** — launch-jarvis-tmux.sh sets window names "Jarvis" and "Watcher", automatic-rename off. Eliminates "[bash]" and "jarvis-watcher.sh" default names.

9. **EVO-2026-02-010 filed** — Watcher startup recovery (checks for partial compression artifacts on startup) + emergency ESC interrupt (statusline monitor sends Escape key at ~95% to interrupt runaway tool calls before lockout). Both documented in evolution proposal.

10. **Phase A residuals closed** — AC-07 cross-ref added to research-ops SKILL.md, roadmap B.1 commit ref fixed, failure_modes_tested=true for AC-06/07/08 via B.4 degradation benchmarks (BM-11/12/13/14).

11. **Critical review agent hallucinations confirmed again** — Generated 6 findings: 5 false positives (Python injection in pure-bash files, bugs in nonexistent code). ALWAYS verify agent findings by reading source. 5 real issues found manually and fixed.

12. **Git status likely has uncommitted auto-generated files** — Telemetry logs (.claude/logs/telemetry/events-*.jsonl), AC state files (.claude/state/components/*.json), JICM session files (.claude/context/jicm/sessions/*). This is expected and normal.

13. **Mac Studio arriving Wed Feb 12** — Phase C infrastructure setup queued. Obsidian vault, n8n workflows, local Supabase, Docker environment all planned.

14. **/export path handling bug** — /export command doubles cwd when given absolute path. Use relative path from cwd instead: `/export .claude/context/export_chat.txt` not `/export /Users/aircannon/Claude/Jarvis/.claude/context/export_chat.txt`.

---

*Compression completed by JICM v5.8 Compression Agent*
*Resume with: Read checkpoint → Adopt persona → Acknowledge task #6 in progress → Continue work*
