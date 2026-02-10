# Compressed Context Checkpoint

**Generated**: 1739213600
**Source**: JICM v5.8 Compression Agent
**Trigger**: Context at 55% (~109.6k tokens)
**JICM Version**: v5.8.0

---

## Foundation Context

### WHO — Jarvis Identity

| Attribute | Details |
|-----------|---------|
| **Core identity** | Calm, precise, safety-conscious orchestrator for Project Aion. Scientific assistant (butler precision + lab partner warmth + senior engineer competence). Not servile, not comedian, not fully autonomous. |
| **Address protocol** | "sir" suffix for formal requests + warnings. No honorific for casual. Context-dependent confirmations. |
| **Tone** | Calm (never panicked), professional (technically precise without cold), understated (competence speaks), concise (fewer words, more weight). |
| **Humor** | Rare (max 1 dry line per several messages), deadpan/understated, NEVER during emergencies, for rapport not entertainment. |
| **Lexicon** | "Yes, sir." / "At once, sir." / "Your attention, sir." / "Understood." / "All systems nominal." / "Initiating..." / "That approach carries measurable risk." / "Confirmation required." |
| **Emergency protocol** | No humor, clear status, impact assessment, options, await instruction. |

### WHAT — Guardrails

**NEVER**:
- Edit AIfred baseline (read-only at 2ea4e8b)
- Store secrets in tracked files (use .claude/secrets/credentials.yaml gitignored)
- Force push main/master
- Skip confirmation for destructive ops
- Over-engineer
- Wait passively
- Multi-line tmux send-keys -l (input buffer corruption)

**ALWAYS**:
- Check context/ before advising
- TodoWrite for multi-step tasks
- Reversible actions
- Document decisions in Memory MCP
- Update session-state.md at session boundaries
- Epoch seconds for timestamps (date +%s)
- Bash functions via $() return 0 (bash 3.2 macOS)
- Absolute file paths in responses, never relative
- Hook matchers: anchored regex (^Bash$) not bare strings ("Write" matches TodoWrite!)

### HOW — Architecture Layers

| Layer | Location | Contains |
|-------|----------|----------|
| **Nous** (knowledge) | `.claude/context/` | patterns, state, priorities |
| **Pneuma** (capabilities) | `.claude/` | agents, hooks, skills, commands |
| **Soma** (infrastructure) | `/Jarvis/` | docker, scripts, projects |

**Topology**: `.claude/context/psyche/_index.md`

### HOW — Autonomic Components (ACs)

**Hippocrenae (AC-01 through AC-09) — The Nine Muses**:
- AC-01 Self-Launch (session start → read session-state + current-priorities, begin work)
- AC-02 Wiggum Loop (ALWAYS DEFAULT: Execute → Check → Review → Drift → Context → Continue)
- AC-03 Milestone Review (work completion → documentation gate)
- AC-04 JICM (context 65% compress, 73% emergency, 78.5% lockout ceiling)
- AC-05 Self-Reflection (session end → /reflect)
- AC-06 Self-Evolution (idle → /evolve)
- AC-07 R&D Cycles (/research)
- AC-08 Maintenance (/maintain)
- AC-09 Session Completion (/end-session)

**Ulfhedthnar (AC-10) — Neuros Override (dormant)**:
- Detector hook, locked skill, 5 Override Protocols, 3 Intensity Levels
- 60/60 tests passing, cooldown 30min, JICM 65% gate
- Commands: /unleash + /disengage

### HOW — JICM Context Management

| Threshold | Action |
|-----------|--------|
| 55% | Watcher warning |
| 65% | Auto-compress /intelligent-compress |
| 73% | Emergency /compact if stuck |
| 78.5% | Lockout ceiling — no new work |

**Observation Masking** (60-80% reduction on tool outputs):
- Glob >50 files → count + key paths
- Grep >100 lines → write to temp, reference
- Bash >2000 chars → exit code + summary
- Read >500 lines (overview only) → key sections
- Never mask errors, file paths, security output
- Tool >2000 tokens → write to `.claude/context/.tool-output/`, reference file

### HOW — Git Workflow

- **Branch**: `Project_Aion` (all dev)
- **Baseline**: `main` (read-only AIfred baseline at 2ea4e8b)
- **Push**: `PAT=$(yq -r '.github.aifred_token' .claude/secrets/credentials.yaml | head -1 | tr -d '[:space:]')` → `git remote set-url origin "https://CannonCoPilot:${PAT}@github.com/davidmoneil/AIfred.git"` → `git push origin Project_Aion`

### HOW — Capability Discovery

**Tool selection**: `.claude/context/psyche/capability-map.yaml` (manifest router) — NOT capability-matrix.md (DEPRECATED)
**Fallback**: `.claude/skills/_index.md`, `.claude/agents/README.md`, `.claude/commands/README.md`

### Counts (verified 2026-02-10)

| Item | Count |
|------|-------|
| Patterns | 51 |
| Skills | 28 total (11 discoverable + 15 absorbed + 1 locked + 1 example) |
| Agents | 13 (12 operational + 1 template) |
| Commands | 37 (.md files excl. README) |
| Hooks | 28 (23 .js + 5 .sh) |
| MCPs | 5 (memory, local-rag, fetch, git, playwright) |

### Critical Gotchas

- bash 3.2: `$(...)` must return 0
- tmux: single-line `-l` only, wait for idle before send
- JICM lockout: ~78.5% ceiling
- yq: pipe through `head -1` (doc separator)
- Hardcoded counts drift: verify via glob, never trust
- Auto-provisioned MCPs (git, fetch, memory): cannot unload
- capability-matrix.md DEPRECATED → capability-map.yaml
- Hook matchers: anchored regex not bare strings
- VERSION file (2.3.0) ≠ architecture version (v5.9.0)
- AC state files drift vs reality: sync periodically
- AC-01 session-start overwrite: flat JSON destroys structure (EVO-2026-02-005)
- JICM compression retry: infinite loop on rate limit (needs timeout)
- **NEVER /clear without updating session-state.md + current-priorities.md** (lost Stream 1 session plan 2026-02-08)
- Code review agent hallucinations: verify findings by reading source (two "CRITICAL" false positives in research-ops)
- jq --arg: use `jq --arg v "$VAR" '{key: $v}'` NOT string interpolation

---

## Session Objective

Implement **F.1 Ennoia MVP** (Roadmap II Phase F): upgrade ennoia.sh v0.1 → v0.2 to write `.ennoia-recommendation` signal file consumed by Watcher for intent-driven wake-up prompts. Separate concerns: Ennoia owns WHAT to say (intent), Watcher owns HOW to wake (mechanics).

---

## Current Task

**F.1 Ennoia MVP — Step 1/8 COMPLETE**, Steps 2-7 in progress.

**What I'm doing**: Implementing the 8-step plan from `/Users/aircannon/Claude/Jarvis/.claude/plans/greedy-hatching-stroustrup.md`.

**Status at compression**:
- ✅ Step 1-3: ennoia.sh upgraded to v0.2 (3 functions added: get_current_work, get_next_priority, write_recommendation; header updated, render() wired, status file updated with version:0.2 and recommendation_active field)
- ⏸️ Step 4-5: jarvis-watcher.sh needs read_ennoia_recommendation() + send_prompt_by_type() modification
- ⏸️ Step 6: launch-jarvis-tmux.sh needs Ennoia window (window 2)
- ⏸️ Step 7: capability-map.yaml needs aion.ennoia registration
- ⏸️ Step 8: Version bumps (Watcher 5.8.4→5.8.5, Ennoia 0.1→0.2 already done)

---

## Work In Progress

| File | Status | What |
|------|--------|------|
| `/Users/aircannon/Claude/Jarvis/.claude/scripts/ennoia.sh` | ✅ DONE | v0.1→v0.2 upgrade: +94 lines (75 new functions, 12 render/status updates, 7 header updates). Writes .ennoia-recommendation with atomic tmp→mv pattern. |
| `/Users/aircannon/Claude/Jarvis/.claude/scripts/jarvis-watcher.sh` | ⏸️ PENDING | Add read_ennoia_recommendation() (~line 945) + modify send_prompt_by_type() RESUME variant (~line 1107-1138) to check Ennoia first, fallback to hardcoded. Add ENNOIA_RECOMMENDATION path constant (~line 214). |
| `/Users/aircannon/Claude/Jarvis/.claude/scripts/launch-jarvis-tmux.sh` | ⏸️ PENDING | Add Window 2 "Ennoia" after line 154, update comments/help/keyboard shortcuts. |
| `/Users/aircannon/Claude/Jarvis/.claude/context/psyche/capability-map.yaml` | ⏸️ PENDING | Register aion.ennoia component after line 261 (ac.10-ulfhedthnar). |

---

## Decisions Made

1. **Ennoia v0.2 scope**: Write .ennoia-recommendation for arise/resume modes only (attend/idle modes write nothing). This is minimal integration — no idle scheduler, no countdown timers (deferred to Phase J).

2. **Atomic write pattern**: `echo > .tmp` then `mv .tmp .ennoia-recommendation` ensures Watcher never reads partial content (Watcher polls every 5s, Ennoia writes every 30s).

3. **RESUME-only Ennoia check**: Only RESUME variant in send_prompt_by_type() reads .ennoia-recommendation. SIMPLE and MINIMAL (retry variants) always use hardcoded for reliability. This preserves the progressive simplification fallback chain.

4. **Graceful degradation**: If Ennoia crashes (no file), Watcher falls back to hardcoded prompts. JICM unaffected. Staleness check: >120s old → delete and fallback.

5. **Window layout**: tmux jarvis windows: 0=Jarvis, 1=Watcher, 2=Ennoia (NOT window 3 as in earlier design notes — ennoia.sh header comment was stale).

6. **Emergency paths untouched**: handle_critical_state() calls send_text() directly, never goes through send_prompt_by_type(), so Ennoia is never consulted for emergencies (correct).

7. **Data extraction**: get_current_work() reads session-state.md "**Status**:" line, strips markdown/emoji, truncates 80 chars. get_next_priority() tries "**Next**:" line, falls back to first ### under "## Up Next", truncates 60 chars.

8. **Status file evolution**: .ennoia-status now includes `version: 0.2` and `recommendation_active: true/false` fields. Dashboard footer shows "REC: ready" when .ennoia-recommendation exists.

---

## Active Context

### Plan Reference
**File**: `/Users/aircannon/Claude/Jarvis/.claude/plans/greedy-hatching-stroustrup.md` (171 lines)
**Architecture**: Ennoia (30s cycle) writes .ennoia-recommendation → Watcher (5s cycle) reads on RESUME variant → fallback to hardcoded if unavailable.

### Critical Design Notes
- **Watcher v5.8.5 changelog** (Step 8, line 3 and after line 29):
  - NEW: read_ennoia_recommendation() — reads signal, checks staleness >120s, validates format [, single-use consumption
  - MOD: send_prompt_by_type() — RESUME variant tries Ennoia first, falls through to hardcoded. SIMPLE/MINIMAL unchanged.
  - ADD: ENNOIA_RECOMMENDATION path constant
- **Edge cases handled**: Ennoia not running (no file → fallback), crash mid-write (.tmp orphan cleaned next cycle), stale >120s (delete + fallback), multiple RESUME retries (first consumes, later use hardcoded), race during write (atomic mv), emergency restore (bypasses Ennoia), bash 3.2 set -e (all functions return 0), recommendation too long (truncation in get_current_work/get_next_priority).

### Verification Plan (Steps V1-V7)
1. Ennoia standalone: start ennoia.sh, wait 35s, verify .ennoia-recommendation exists with [SESSION-START] prefix
2. Atomic write: verify no .ennoia-recommendation.tmp lingering
3. Watcher integration: create fake recommendation, check log for "Using Ennoia recommendation"
4. Graceful degradation: rm .ennoia-recommendation, verify Watcher fallback
5. Staleness: touch with old mtime, verify Watcher ignores and deletes
6. Full JICM cycle: compress → /clear → resume with Ennoia running (check watcher log)
7. tmux launcher: run launch-jarvis-tmux.sh --fresh, verify 3 windows (Jarvis, Watcher, Ennoia)

### File Line References (from design agent)
- ennoia.sh line 82: insertion point for get_current_work/get_next_priority
- watcher.sh line 214: ENNOIA_RECOMMENDATION path constant
- watcher.sh line 945: read_ennoia_recommendation() insertion point (before detect_idle_state)
- watcher.sh lines 1107-1138: send_prompt_by_type() modification point
- launcher.sh line 154: Ennoia window insertion point (after Watcher creation)
- capability-map.yaml line 261: aion.ennoia registration (after ac.10-ulfhedthnar)

---

## Todos

**From TodoWrite task tracker**:
- ⏸️ #1: Upgrade ennoia.sh v0.1 → v0.2 (Steps 1-3) — ✅ COMPLETE
- ⏸️ #2: Add Ennoia reader to jarvis-watcher.sh (Steps 4-5, 8) — BLOCKED BY #1 (now unblocked)
- ⏸️ #3: Add Ennoia to tmux launcher (Step 6) — BLOCKED BY #1 (now unblocked)
- ⏸️ #4: Register Ennoia in capability-map.yaml (Step 7) — BLOCKED BY #1 (now unblocked)
- ⏸️ #5: Verify Ennoia MVP end-to-end (V1-V7) — BLOCKED BY #1, #2, #3, #4

---

## Next Steps

1. **Implement Step 4-5**: Modify `/Users/aircannon/Claude/Jarvis/.claude/scripts/jarvis-watcher.sh`:
   - Add `ENNOIA_RECOMMENDATION="$PROJECT_DIR/.claude/context/.ennoia-recommendation"` path constant after line 214
   - Insert read_ennoia_recommendation() function before line 945 (before detect_idle_state())
   - Modify send_prompt_by_type() lines 1107-1138: add Ennoia check at top for RESUME variant only
   - Update version header line 3: v5.8.4 → v5.8.5
   - Add changelog entry after line 29

2. **Implement Step 6**: Modify `/Users/aircannon/Claude/Jarvis/.claude/scripts/launch-jarvis-tmux.sh`:
   - Insert Ennoia window creation after line 154 (after Watcher window block)
   - Add window listing, keyboard shortcuts help, automatic-rename off for window :2
   - Update comment line 7 for 3-window layout

3. **Implement Step 7**: Update `/Users/aircannon/Claude/Jarvis/.claude/context/psyche/capability-map.yaml`:
   - Add aion.ennoia component entry after line 261 (after ac.10-ulfhedthnar)

4. **Verification**: Run V1-V7 progressive verification (standalone → integration → full JICM cycle)

5. **Commit + Push**: `git add` modified files, commit "feat: F.1 Ennoia MVP — intent-driven wake-up recommendations (v0.2)", push to origin/Project_Aion

---

## Resume Instructions

### Immediate Context
I was implementing F.1 Ennoia MVP (Roadmap II Phase F). Completed Step 1-3 (ennoia.sh v0.2 upgrade with 3 new functions, status file evolution, atomic write pattern). Context hit 55% during implementation, triggering JICM compression. Next: Steps 4-5 (Watcher modifications), Step 6 (launcher), Step 7 (capability-map registration), then verification.

### On Resume
1. Read this checkpoint — context has been compressed
2. Adopt Jarvis persona (jarvis-identity.md) — calm, precise, "sir" for formal
3. Acknowledge continuation — "Context restored, sir. F.1 Ennoia MVP in progress — ennoia.sh v0.2 complete, proceeding with Watcher integration."
4. Begin work immediately on Step 4-5 — DO NOT re-read session-state.md (it shows stale "Idle" status from last /end-session)

### Key Files (Absolute Paths)

**Modified this session**:
- `/Users/aircannon/Claude/Jarvis/.claude/scripts/ennoia.sh` — v0.2 complete, +94 lines

**To modify next**:
- `/Users/aircannon/Claude/Jarvis/.claude/scripts/jarvis-watcher.sh` — add reader, modify RESUME variant
- `/Users/aircannon/Claude/Jarvis/.claude/scripts/launch-jarvis-tmux.sh` — add Window 2
- `/Users/aircannon/Claude/Jarvis/.claude/context/psyche/capability-map.yaml` — register aion.ennoia

**Read-only references**:
- `/Users/aircannon/Claude/Jarvis/.claude/plans/greedy-hatching-stroustrup.md` — 8-step implementation plan, 171 lines
- `/Users/aircannon/Claude/Jarvis/.claude/plans/ennoia-aion-script-design.md` — full design doc (27 iterations), read-only context
- `/Users/aircannon/Claude/Jarvis/.claude/context/session-state.md` — current work status (MAY SHOW STALE "Idle")
- `/Users/aircannon/Claude/Jarvis/.claude/context/current-priorities.md` — Phase F in progress
- `/Users/aircannon/Claude/Jarvis/CLAUDE.md` — root-of-trust guardrails
- `/Users/aircannon/Claude/Jarvis/.claude/context/psyche/jarvis-identity.md` — persona spec
- `/Users/aircannon/Claude/Jarvis/.claude/context/compaction-essentials.md` — architecture quick ref

**Signal files** (will be created by ennoia.sh v0.2):
- `/Users/aircannon/Claude/Jarvis/.claude/context/.ennoia-recommendation` — single-use wake-up prompt
- `/Users/aircannon/Claude/Jarvis/.claude/context/.ennoia-status` — dashboard state YAML

---

## Critical Notes

1. **session-state.md may show "Idle"**: This is EXPECTED during active work (status only committed at session boundaries via AC-09). Use this checkpoint for current work, not session-state.md. The ACTUAL current work is F.1 Ennoia MVP, Step 1-3 complete.

2. **ennoia.sh line numbers shifted**: After +94 lines, original line references in design doc are now stale. Use grep or section headers to find insertion points in remaining files.

3. **TodoWrite tasks active**: 5 tasks tracked, #1 complete, #2-#5 ready to proceed. Task file lives at `.claude/context/.active-tasks.txt` (may not exist — TodoWrite manages in memory).

4. **Chat export captured**: Pre-compression chat history saved to `/Users/aircannon/Claude/Jarvis/.claude/exports/chat-20260210-144339-pre-compress.txt` by watcher v5.8.4 (2339 lines). Contains full conversation context if needed for reference.

5. **No preservation manifest**: `.claude/context/.preservation-manifest.json` does not exist — this is first compression cycle of current session. All context treated as equal priority.

6. **Roadmap II Phase F context**: This is Phase F (Aion Trinity Deployment), not Phase C (Mac Studio). Phase B.7 (Ulfhedthnar) was completed in prior session (needs commit). Phase C deferred to Wed Feb 12+ (Mac Studio arrival).

7. **Wiggum Loop in effect**: This is a multi-step implementation task. Apply AC-02: Execute (steps 4-5) → Check (verify read function) → Review (test Watcher log) → Drift Check (still aligned with F.1 plan?) → Context Check → Continue (steps 6-7-8).

8. **Version consistency**: Ennoia header already shows v0.2 (done in Step 3). Watcher still shows v5.8.4 in header (update in Step 8). Ensure VERSION file consistency after implementation (architecture v5.9.0, VERSION file 2.3.0 for telemetry).

---

*Compression completed by JICM v5.8 Compression Agent*
*Resume with: Read checkpoint → Adopt persona → Acknowledge → Continue work*
