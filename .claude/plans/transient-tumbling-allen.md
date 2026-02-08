# Session Plan: MCP Decomposition + Session Start Redesign

## Context

JICM v5.8.0 shipped. This session tackles: (1) decompose Tier 1 MCPs into skills — establishing the phagocytosis workflow for all future MCP conversions, (2) redesign session-start.sh to eliminate ~1,500 tokens of redundant prompt injection and add --continue/--fresh autonomic behavior, (3) review JICM gating and resolve the emergency that fired.

**Key discoveries from exploration:**
- Only `filesystem` + `local-rag` are in project `.mcp.json`; git/memory/fetch are via `mcp-gateway` (global settings, not Docker-deployed)
- local-rag is installed but **dormant** (0 tool invocations found anywhere in codebase)
- session-start.sh injects ~1,200-1,500 tokens of redundant context that duplicates CLAUDE.md
- Weather uses direct curl (not MCP) — candidate for skill-ification
- mcp-gateway is documented but NOT Docker-deployed; memory+fetch configured via global `~/.claude/settings.json` permissions

---

## Milestone 1: Baseline + MCP Discovery

### 1.1 Baseline Token Measurement
Run `/context` to capture full category breakdown:
```
System prompt | System tools | Custom agents | Memory files | Skills | Messages | Compact buffer
```
Plus per-item token counts for: each MCP, each skill, each plugin. Save output verbatim.

### 1.2 Locate All MCP Configurations
| MCP | Location | Status |
|-----|----------|--------|
| `filesystem` | `.mcp.json` lines 3-16 | Active, 15 deferred tools |
| `local-rag` | `.mcp.json` lines 17-27 | Configured but **0 usage found** |
| `memory` | `~/.claude/settings.json` lines 68-70 (mcp-gateway) | Active, used by hooks |
| `fetch` | `~/.claude/settings.json` line 71 (mcp-gateway) | Configured, minimal usage |
| `git` | Deferred tools exist (`mcp__git__*`) — find source | Unknown config location |
| `weather` | `session-start.sh` line 91 (curl wttr.in) | Embedded, not MCP |

**Actions:**
- Search for git MCP server process/config (check `ps aux`, npm global installs, Docker Desktop MCP settings)
- Determine if mcp-gateway is a single npm process or separate servers
- Document all findings in MCP decomposition registry

### 1.3 Create MCP Decomposition Registry
**File:** `.claude/context/reference/mcp-decomposition-registry.md`

Master list tracking every MCP that has been analyzed and/or phagocytosed:
```markdown
| MCP | Status | Replacement | Tokens Saved | Date |
|-----|--------|-------------|-------------|------|
| filesystem | DECOMPOSED | filesystem-ops skill | TBD | 2026-02-06 |
| git | DECOMPOSED | git-ops skill | TBD | 2026-02-06 |
| fetch | DECOMPOSED | web-fetch skill | TBD | 2026-02-06 |
| weather (curl) | DECOMPOSED | weather skill | TBD | 2026-02-06 |
| memory | RETAINED | Unique: knowledge graph | N/A | 2026-02-06 |
| local-rag | RETAINED | Unique: vector DB/embeddings | N/A | 2026-02-06 |
```
Future MCP evaluations check this registry first to avoid re-analyzing already-handled MCPs.

---

## Milestone 2: Create Replacement Skills (4 skills)

### 2.1 `filesystem-ops` Skill
**File:** `.claude/skills/filesystem-ops/SKILL.md`

Maps 15 MCP tools to built-in equivalents:
| MCP Tool | Built-in | Notes |
|----------|----------|-------|
| `read_file/read_text_file/read_media_file` | `Read` | Images, PDFs, notebooks |
| `read_multiple_files` | Parallel `Read` calls | |
| `write_file` | `Write` | |
| `edit_file` | `Edit` | |
| `create_directory` | `Bash(mkdir -p)` | |
| `list_directory/list_directory_with_sizes` | `Bash(ls -la)` | |
| `directory_tree` | `Bash(tree)` | |
| `search_files` | `Glob` | Pattern-based |
| `get_file_info` | `Bash(stat)` | |
| `move_file` | `Bash(mv)` | |
| `list_allowed_directories` | N/A | Not needed |

Cross-workspace: Built-in `Read`/`Write` work with absolute paths. For dirs in `.mcp.json` args, use `Bash(ls)` / `Read` with full paths.

### 2.2 `git-ops` Skill
**File:** `.claude/skills/git-ops/SKILL.md`

Maps 12 MCP tools to `Bash(git ...)` commands. Includes:
- Safety patterns (never force push main, prefer specific file staging)
- HEREDOC commit pattern
- PAT-based push workflow (credential store reference)
- Pre-allowed commands from `~/.claude/settings.json` lines 4-12

### 2.3 `web-fetch` Skill
**File:** `.claude/skills/web-fetch/SKILL.md`

Maps `mcp__fetch__fetch` + `mcp__mcp-gateway__fetch` to built-in equivalents:
- Known URL → `WebFetch` (HTML→markdown + AI processing)
- Search query → `WebSearch`
- API/JSON → `Bash(curl)`
- Authenticated URL → check for specialized MCP tools first

### 2.4 `weather` Skill
**File:** `.claude/skills/weather/SKILL.md`

Extracts weather functionality from session-start.sh (lines 83-107):
- Wraps `curl -s --max-time 3 "wttr.in/${location}?format=j1"`
- Parses temperature, description, feels-like, humidity
- Configurable via `JARVIS_WEATHER_LOCATION` env var
- Can be invoked on-demand during sessions (not just startup)
- session-start.sh updated to reference skill pattern instead of inline curl

### 2.5 Update Skills Index
**File:** `.claude/skills/_index.md` — Add 4 new skills to table

### 2.6 Search for Other Embedded MCP-Like Patterns
Scan all hooks/scripts for curl API calls or external service invocations that could be skill-ified. Document findings in registry. Known patterns:
- `suggest-mcps.sh` — MCP suggestion logic (will be simplified post-decomposition)
- Hook scripts referencing `mcp__` tool names — update to handle both MCP and built-in names

**Commit:** `feat: Add filesystem-ops, git-ops, web-fetch, weather skills for MCP decomposition`

---

## Milestone 3: Validation + MCP Removal + Token Delta

### 3.1 Validate Skill Invocations
**Critical: Test actual skill triggers, not just built-in tools.**

For each skill, verify:
1. Skill frontmatter triggers correctly (description keywords match use cases)
2. Skill body provides correct guidance for the operation
3. Built-in tool completes the operation successfully
4. No regression vs MCP tool behavior

Test matrix (execute via Bash scripts where possible):
- **filesystem-ops:** `Read` cross-workspace file, `Glob` pattern search, `Bash(mkdir -p && ls)`
- **git-ops:** `Bash(git status/log/diff)` — verify pre-allowed commands work
- **web-fetch:** `WebFetch` on public URL, `WebSearch` for query
- **weather:** Invoke skill, verify curl returns valid JSON

### 3.2 Remove/Disable MCPs
| MCP | Action | Location |
|-----|--------|----------|
| `filesystem` | Remove from `.mcp.json` | Project config |
| `git` | Disable/remove from source (discovered in M1.2) | TBD |
| `fetch` | Remove `mcp__mcp-gateway__fetch` from `~/.claude/settings.json` permissions | Global config |
| `weather curl` | Move inline code to skill reference | `session-start.sh` |
| `local-rag` | **RETAIN** — unique server-side embeddings + vector DB; dormant but keep for future use | `.mcp.json` |
| `memory` | **RETAIN** — unique knowledge graph, actively used by hooks | Global config |

**mcp-gateway handling:** If mcp-gateway is a single process bundling memory+fetch:
- Investigate process internals (npm package, config files)
- If separable: remove fetch, keep memory
- If not separable: keep both, document fetch as "bundled with memory, low cost"
- **Approach:** Pull apart autonomously. Extract MCP tool definitions to local folder for analysis. If the gateway is just an npm package, check its source for config options to disable individual tools.

### 3.3 Update References
| File | Change |
|------|--------|
| `capability-matrix.md` | Tier 1: memory-only (+local-rag retained). Others → "Replaced by skills" |
| `mcp-loading-strategy.md` | Update Tier 1 list |
| `suggest-mcps.sh` | Remove decomposed MCPs from TIER1. If few MCPs remain, simplify or deprecate |
| `tool-selection-intelligence.md` | Reverse preference: built-in > MCP |
| Hook scripts referencing MCP tool names | Add built-in tool name patterns alongside |
| `mcp-decomposition-registry.md` | Update status and token savings |

### 3.4 Post-Removal Token Measurement
Run `/context` again. Fine-grained comparison:
- Per-category delta (System tools, Skills, etc.)
- Per-item delta (each MCP removed, each skill added)
- Net savings calculation
- Document in registry

**Commit:** `refactor: Remove filesystem/git/fetch MCPs — phagocytosed into skills`

---

## Milestone 4: Session Start Redesign

### 4.1 session-start.sh Cleanup — Eliminate Bloat

**Problem:** ~1,200-1,500 tokens of redundant prompt injection per startup. 60-70% of Phase A-C instructions duplicate CLAUDE.md.

**Changes:**

| Current (bloated) | New (lean) | Tokens Saved |
|-------------------|-----------|-------------|
| Lines 371-404: Full persona + autonomy instructions | Remove entirely — CLAUDE.md auto-loaded | ~800 |
| Lines 384-389: Greeting example variations | Remove — Jarvis knows how to greet from identity file | ~100 |
| Lines 260-312: Verbose env validation building | Condense to bullet list | ~200 |
| Lines 215-234: MCP suggestion injection | Remove/simplify — most MCPs decomposed | ~150 |
| Lines 354-368: AIfred sync instruction text | Auto-execute script, inject result not instruction | ~200 |

**Principle:** session-start.sh should perform **scripted actions** and inject **minimal directives**, not re-teach Jarvis things already in CLAUDE.md.

**New additionalContext structure:**
```
## Session Start Context
- Status: [1-line from session-state.md]
- Next priority: [1-line from current-priorities.md]
- Environment: [bullet list of any issues]
- AIfred baseline: [N new commits / up to date]
- Weather: [temp, conditions]

## Startup Options
[numbered list — see 4.3]

## Resume Instructions
[2-3 lines max, reference files by path instead of injecting content]
```

**Files NOT re-instructed** (already auto-loaded or referenced in CLAUDE.md):
- `CLAUDE.md` (auto-loaded)
- `jarvis-identity.md` (referenced in CLAUDE.md AC-01)
- `compaction-essentials.md` (used by compression agent, not startup)
- Psyche files (loaded on-demand via progressive disclosure)

### 4.2 Add `--fresh` Flag to Launcher
**File:** `.claude/scripts/launch-jarvis-tmux.sh`

**Current:** Always passes `--continue` (line 122). No fresh-start option.

**Change:**
- Add `--fresh` to argument parser (lines 33-38)
- Default: `--continue` (preserves current behavior)
- `--fresh`: Launch Claude without `--continue`, set `JARVIS_FRESH_START=true` in CLAUDE_ENV
- Pass to watcher: `--session-type fresh` vs `--session-type continue`

### 4.3 Both Paths Run Same Core SessionStart Tasks
**Key requirement:** Both `--continue` and `--fresh` execute the same startup checklist. The difference is timer behavior.

**Core sessionStart tasks (always executed):**
1. Phase A: Time-aware greeting + weather
2. Phase B: Silent system review (session-state, priorities, git status, env validation)
3. AIfred baseline check (auto-execute, inject result)
4. Present numbered options to user

**Numbered options (in additionalContext):**
```
1. Continue previous work: [summary from session-state]
2. Review priorities: Show current-priorities.md backlog
3. Start new task: Ask user for direction
4. Run health check: /tooling-health
5. Self-improvement: /reflect
6. Maintenance: /maintain
```

**Timer behavior:**
| Mode | Timer | Auto-select |
|------|-------|-------------|
| `--continue` | 60s countdown | Option 1 (continue previous work) → auto-resume |
| `--fresh` | No timer | Wait for user selection (future: idle-hands maintenance mode) |

### 4.4 Watcher: `session_options` Idle-Hands Mode
**File:** `.claude/scripts/jarvis-watcher.sh`

New function `idle_hands_session_options()` (~40 lines):
```
1. Detect .session-options-pending flag
2. Wait 5s for Claude to present options
3. Start 60s countdown (poll every 2s)
4. During countdown: is_claude_busy() → user responded → cancel timer, remove flag
5. On timeout: send "1" keystroke (continue previous work) → remove flag
```

Add to `check_idle_hands()` case statement: `session_options)` → call new function.

**session-start.sh creates flag:**
- For `--continue` sessions: create `.session-options-pending` with `timeout=60`
- For `--fresh` sessions: do NOT create flag (no auto-timer)

### 4.5 Verify Core Identity Files Load
Confirm that session-start.sh doesn't need to re-instruct about:
- `CLAUDE.md` → Auto-loaded by Claude Code (verified: root CLAUDE.md is canonical)
- `jarvis-identity.md` → Referenced in CLAUDE.md AC-01 section
- Session state files → Read by hook script, key data injected in compact form

### 4.6 Remove MCP Suggestions Section
Lines 215-234: MCP suggestion injection will be eliminated/simplified:
- If most MCPs decomposed → few remain → load by default
- Remove `suggest-mcps.sh` call or simplify to only suggest Tier 2/3 MCPs for specific tasks
- Saves ~150 tokens per startup + eliminates suggest-mcps.sh subprocess

### 4.7 Update Session Management Skill
**File:** `.claude/skills/session-management/SKILL.md`
- Document `--continue` vs `--fresh` launcher behavior
- Document startup checklist and 60s countdown
- Document how user interrupts countdown

**Commit:** `feat(session): Redesigned session-start — lean injection, --fresh flag, 60s timer`

---

## Milestone 5: JICM Review + Emergency Resolution

### 5.1 Add `.compression-in-progress` Cleanup
**File:** `.claude/scripts/jarvis-watcher.sh`

Add to both `cleanup_jicm_files()` and `cleanup_jicm_signals_only()`:
```bash
rm -f "$PROJECT_DIR/.claude/context/.compression-in-progress"
```

Currently only cleaned by `session-start.sh` — watcher should also handle mid-session agent crashes.

### 5.2 Document JICM-EMERGENCY as Expected Behavior
**File:** `.claude/context/designs/jicm-v5-design-addendum.md` (add section)

The `[JICM-EMERGENCY]` is the B2 FIX working correctly:
- Fires when hooks fail to create idle-hands flag after /clear
- Self-resolving: Jarvis reads context files and resumes
- Already resolved this session
- No manual intervention needed

### 5.3 JICM Gating Verification
All 4 gates confirmed by exploration:
- Gate A: Duplicate /clear skip (debounce) ✅
- Gate B: .in-progress-ready.md (45s soft timeout) ✅
- Gate C: Hook failure detection (B2 FIX) ✅
- Gate D: V5 signal file detection ✅

### 5.4 Version Bumps
- `jarvis-watcher.sh`: v5.8.1 (cleanup fix + session_options mode)
- `session-start.sh`: Note version in header comment

**Commit:** `fix(jicm): Compression flag cleanup + document JICM-EMERGENCY`

---

## Testing Strategy

**Self-contained tests (no manual session restart needed):**

| Test | Method | What it validates |
|------|--------|-------------------|
| Skill triggers | Read each SKILL.md, verify frontmatter description matches trigger patterns | Skill discovery |
| Built-in tool ops | `Bash` scripts performing file/git/fetch operations | Tool functionality |
| `/context` comparison | Signal-based command execution | Token delta |
| session-start.sh syntax | `bash -n session-start.sh` | No syntax errors |
| Watcher function | Read watcher code, verify function integration | Code correctness |
| Flag file creation | `Bash` test: create/check/cleanup `.session-options-pending` | Timer mechanism |

**Deferred tests (require session restart):**
- Full `--continue` vs `--fresh` end-to-end flow
- 60s timer auto-continue behavior
- Hold off and move on if blocking — document as "requires manual validation"

**Guard rails:**
- Do NOT send tmux commands that could interrupt this session
- Do NOT accidentally trigger /clear or /compact
- Test scripts run in subshells, not main session

---

## Implementation Sequence

```
M1 (Baseline + Discovery)     → /context baseline, locate MCPs, create registry
M2 (Skills Creation)          → 4 skills + index update + embedded MCP scan
M3 (Validation + Removal)     → Test skills, remove MCPs, /context delta
M4 (Session Start Redesign)   → Cleanup bloat, --fresh flag, timer, lean injection
M5 (JICM Review)              → Cleanup fix, document emergency, verify gates
```

Each milestone ends with a commit and brief review.

## Critical Files

| File | Milestones | Changes |
|------|-----------|---------|
| `.mcp.json` | M3 | Remove filesystem entry |
| `~/.claude/settings.json` | M3 | Remove fetch permission (if separable from memory) |
| `.claude/skills/filesystem-ops/SKILL.md` | M2 | Create new |
| `.claude/skills/git-ops/SKILL.md` | M2 | Create new |
| `.claude/skills/web-fetch/SKILL.md` | M2 | Create new |
| `.claude/skills/weather/SKILL.md` | M2 | Create new |
| `.claude/skills/_index.md` | M2 | Add 4 skills |
| `.claude/context/reference/mcp-decomposition-registry.md` | M1, M3 | Create, update |
| `.claude/hooks/session-start.sh` | M4 | Major cleanup: remove redundancy, lean injection |
| `.claude/scripts/jarvis-watcher.sh` | M4, M5 | session_options mode, cleanup fix |
| `.claude/scripts/launch-jarvis-tmux.sh` | M4 | --fresh flag, env vars |
| `.claude/skills/session-management/SKILL.md` | M4 | Document new flows |
| `.claude/context/designs/jicm-v5-design-addendum.md` | M5 | Document emergency |
| Various reference docs | M3 | Update MCP tier listings |
| Various hook scripts | M3 | Add built-in tool name patterns |

## Risks + Mitigations

| Risk | Mitigation |
|------|-----------|
| git MCP config location unknown | Discover autonomously in M1.2 — check processes, npm, Docker Desktop |
| mcp-gateway bundles memory+fetch | Pull apart: inspect npm package, find config to disable fetch while keeping memory |
| Cross-workspace file access regression | Skill documents `Read`/`Bash` with absolute paths |
| 60s timer fires during slow startup | 5s initial delay; busy detection cancels |
| session-start.sh changes break JICM flow | Test syntax first; preserve signal file logic unchanged |
| Accidental session interrupt during testing | All tests in subshells/background; no tmux send-keys to jarvis:0 |
