# MCP-to-Skill & Plugin-to-Skill Pipeline Design
## Context Token Overhead Reduction Plan

**Version**: 2.0
**Date**: 2026-02-07
**Status**: Plan — awaiting approval

---

## Context

MCP decomposition (18→5 MCPs) is complete. The next evolution is a **systematic pipeline** for converting external tool dependencies (MCPs, plugins) into lean, built-in skill equivalents — and simultaneously reducing the always-on context token footprint. This plan addresses both the *pipeline mechanics* (how we convert) and the *architectural optimization* (how we reduce overhead).

**Goals**:
1. Reduce preloaded tools in context
2. Decrease reliance on health-checked MCP servers
3. Enable refactoring of reconstructed tools
4. Greater atomization of tool options
5. Increased creative problem solving through unique tool combinations
6. Reliable, deterministic skill/pattern/workflow discovery and loading

---

## Part 1: Architecture — Manifest + Search Hybrid

### The Design Question

**Manifest/Router** vs **ToolSearch-like deferred loading** for Skills and Commands?

```
┌─────────────────────────────────────────────────────────────────────┐
│                   DISCOVERY MECHANISM COMPARISON                     │
├───────────────────────┬─────────────────────┬───────────────────────┤
│                       │ MANIFEST/ROUTER     │ TOOLSEARCH-LIKE       │
│                       │ (Static Index)      │ (Dynamic Search)      │
├───────────────────────┼─────────────────────┼───────────────────────┤
│ Discovery             │ Deterministic       │ Probabilistic         │
│ Token cost (idle)     │ ~400-800 tok (file) │ ~30 tok/entry listing │
│ Token cost (activate) │ ~200-300 tok (load) │ ~300 tok (full def)   │
│ Maintenance           │ Must update manifest│ Auto-discovers new    │
│ Reliability           │ 100% if maintained  │ ~90% (search quality) │
│ Novel combinations    │ Only what's listed  │ Can discover unexpected│
│ Architectural fit     │ Nous (knowledge)    │ Pneuma (capability)   │
│ Speed                 │ O(1) lookup         │ O(n) search           │
│ Stale risk            │ High (manual)       │ None (always current) │
└───────────────────────┴─────────────────────┴───────────────────────┘
```

### Recommendation: Hybrid — Manifest as Router, Search as Fallback

```
                        ┌─────────────┐
                        │  Task Need  │
                        └──────┬──────┘
                               │
                    ┌──────────▼──────────┐
                    │ Check Manifest      │ ← Fast path (Nous)
                    │ (capability-map.yaml)│
                    └──────────┬──────────┘
                          ┌────┴────┐
                     Found│         │Not Found
                          ▼         ▼
                    ┌──────────┐ ┌──────────────┐
                    │ Load by  │ │ Search       │ ← Discovery path
                    │ exact ID │ │ (Glob/Grep   │   (Pneuma)
                    │          │ │  or ToolSearch│
                    └────┬─────┘ │  for MCPs)   │
                         │       └──────┬───────┘
                         │         ┌────┴────┐
                         │    Found│         │Not Found
                         │         ▼         ▼
                         │   ┌──────────┐ ┌──────────┐
                         │   │ Load &   │ │ Report   │
                         │   │ update   │ │ gap to   │
                         │   │ manifest │ │ user     │
                         │   └────┬─────┘ └──────────┘
                         │        │
                         ▼        ▼
                    ┌─────────────────┐
                    │ Execute module  │
                    │ Record result   │
                    └─────────────────┘
```

**Why both**: The manifest provides the fast, deterministic "System 1" path — Jarvis knows what it can do. Search provides the "System 2" fallback for discovery when the manifest doesn't cover a need. The manifest self-heals: when search finds something new, it gets added.

**Architectural fit**: The manifest lives in **Nous** (knowledge of self), while the capabilities themselves live in **Pneuma**. This mirrors the Gnostic topology — Nous holds the map, Pneuma holds the territory.

### Manifest Design: `capability-map.yaml`

**Location**: `.claude/context/psyche/capability-map.yaml`

```yaml
version: 1
updated: 2026-02-07

# ─── SKILLS (multi-step workflows) ───
skills:
  - id: skill.filesystem-ops
    when: "File read/write/search/create/move operations"
    tools: [Read, Write, Edit, Glob, Grep, "Bash(ls|stat|mkdir|mv)"]
    replaces: mcp__filesystem (15 tools)
    file: .claude/skills/filesystem-ops/SKILL.md

  - id: skill.git-ops
    when: "Git status, log, diff, branch, commit, push"
    tools: ["Bash(git *)"]
    replaces: mcp__git (12 tools)
    file: .claude/skills/git-ops/SKILL.md

  - id: skill.web-fetch
    when: "Fetch URL content, web search, API calls"
    tools: [WebFetch, WebSearch, "Bash(curl)"]
    replaces: mcp__fetch
    file: .claude/skills/web-fetch/SKILL.md

  # ... (20 skills total, ~15 tokens per entry = ~300 tokens)

# ─── AGENTS (autonomous execution) ───
agents:
  - id: agent.deep-research
    when: "Thorough technical research with citations"
    file: .claude/agents/deep-research.md

  - id: agent.code-review
    when: "Technical quality review of code changes"
    file: .claude/agents/code-review.md

  # ... (14 agents, ~15 tokens per entry = ~210 tokens)

# ─── PATTERNS (behavioral rules) ───
patterns:
  - id: pattern.agent-selection
    when: "Choosing between tools, skills, agents"
    file: .claude/context/patterns/agent-selection-pattern.md

  # ... (key patterns only, not all 41)

# ─── WORKFLOWS (multi-phase processes) ───
workflows:
  - id: flow.jicm-compression
    when: "Context approaching threshold"
    file: .claude/commands/intelligent-compress.md

  - id: flow.end-session
    when: "Clean session exit"
    file: .claude/commands/end-session.md

# ─── AUTONOMIC COMPONENTS (AC signals) ───
components:
  - id: ac.01-self-launch
    signal: "SessionStart"
    file: .claude/context/components/AC-01-self-launch.md

  - id: ac.04-jicm
    signal: "context >= threshold"
    file: .claude/context/components/AC-04-jicm.md

  # ... (9 components, ~15 tokens per entry = ~135 tokens)
```

**Total manifest size**: ~400-800 tokens (vs ~2,000 tokens for current skill listings)

### Integration with Aion Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    AION ARCHITECTURE                     │
│                                                         │
│  NOUS (Knowledge)          PNEUMA (Capabilities)        │
│  .claude/context/          .claude/                     │
│  ┌─────────────────┐       ┌─────────────────┐         │
│  │ capability-map   │──────▶│ skills/          │         │
│  │   .yaml          │       │ agents/          │         │
│  │ (THE MAP)        │       │ commands/        │         │
│  │                  │       │ hooks/           │         │
│  │ patterns/        │       │ scripts/         │         │
│  │ components/      │       │ (THE TERRITORY)  │         │
│  └─────────────────┘       └─────────────────┘         │
│          │                          │                   │
│          │    ┌─────────────┐       │                   │
│          └───▶│ ENNOIA      │◀──────┘                   │
│               │ (Scheduler) │                           │
│               │ Uses map to │                           │
│               │ select idle │                           │
│               │ tasks       │                           │
│               └─────────────┘                           │
│                                                         │
│  SOMA (Infrastructure)                                  │
│  /Jarvis/                                              │
│  ┌─────────────────┐                                   │
│  │ docker/          │                                   │
│  │ scripts/         │                                   │
│  │ projects/        │                                   │
│  └─────────────────┘                                   │
└─────────────────────────────────────────────────────────┘
```

---

## Part 2: MCP-to-Skill Pipeline (Revised)

### Pipeline Schematic

```
┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐
│ DISCOVER │───▶│ ANALYZE  │───▶│ MAP      │───▶│ BUILD    │───▶│ VALIDATE │
│          │    │          │    │          │    │          │    │          │
│ Inventory│    │ Each tool│    │ Tool →   │    │ Skill    │    │ Test     │
│ all MCP  │    │ has built│    │ built-in │    │ file in  │    │ matrix   │
│ tools    │    │ -in eq?  │    │ mapping  │    │ standard │    │ (1 test  │
│          │    │          │    │ table    │    │ format   │    │  per tool│
└──────────┘    └──────────┘    └──────────┘    └──────────┘    └────┬─────┘
                                                                     │
┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐         │
│ DOCUMENT │◀───│ MEASURE  │◀───│ REMOVE   │◀───│ REGISTER │◀────────┘
│          │    │          │    │          │    │          │
│ Update   │    │ Before/  │    │ claude   │    │ Add to   │
│ registry │    │ after    │    │ mcp      │    │ manifest │
│ + pattern│    │ token    │    │ remove   │    │ .yaml    │
│ docs     │    │ delta    │    │ <name>   │    │          │
└──────────┘    └──────────┘    └──────────┘    └──────────┘
```

### Step-by-Step Protocol

**Step 1: DISCOVER** — Inventory the MCP
```bash
# List all tools from the MCP
ToolSearch "+<mcp-name>"
# Record: tool count, tool names, parameter schemas
```

**Step 2: ANALYZE** — For each tool, determine:
- Has built-in equivalent? (Read/Write/Edit/Glob/Grep/Bash/WebFetch/WebSearch)
- Unique capability? (no built-in can do this)
- If unique → RETAIN MCP (do not decompose)
- If all mapped → proceed to Step 3

**Step 3: MAP** — Create mapping table
```
| MCP Tool | Built-in | Notes |
|----------|----------|-------|
| tool_a   | Read     | Direct replacement |
| tool_b   | Bash(x)  | Via shell command  |
```

**Step 4: BUILD** — Create skill file using Skill File Format Standard (Section 5)

**Step 5: VALIDATE** — Run 1 test per mapped tool using ONLY built-ins

**Step 6: REGISTER** — Add entry to `capability-map.yaml`

**Step 7: REMOVE** — `claude mcp remove <name>`

**Step 8: MEASURE** — Record token count, compare to pre-removal baseline

**Step 9: DOCUMENT** — Update `mcp-decomposition-registry.md`

---

## Part 3: Plugin-to-Skill Pipeline

### Plugin Discovery

```bash
# List installed plugins
cat ~/.claude/plugins/installed_plugins.json
# Or check marketplace
ls ~/.claude/plugins/marketplaces/*/plugins/
```

### Pipeline (adapted from MCP pipeline)

```
┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐
│ DISCOVER │───▶│ ASSESS   │───▶│ EXTRACT  │───▶│ BUILD    │
│          │    │          │    │          │    │          │
│ List     │    │ What     │    │ Core     │    │ Compile  │
│ plugin   │    │ does it  │    │ logic &  │    │ into     │
│ skills,  │    │ provide  │    │ patterns │    │ skill    │
│ commands,│    │ that we  │    │ into     │    │ card     │
│ hooks    │    │ lack?    │    │ runbook  │    │ format   │
└──────────┘    └──────────┘    └──────────┘    └────┬─────┘
                                                     │
┌──────────┐    ┌──────────┐    ┌──────────┐         │
│ DOCUMENT │◀───│ DISABLE  │◀───│ VALIDATE │◀────────┘
│          │    │          │    │          │
│ Update   │    │ Disable  │    │ Test     │
│ manifest │    │ plugin   │    │ skill    │
│ + index  │    │ if fully │    │ replaces │
│          │    │ replaced │    │ plugin   │
└──────────┘    └──────────┘    └──────────┘
```

### Key Difference from MCP Pipeline

Plugins are different from MCPs:
- Plugins inject **prompts/skills/commands** (text), not **tool definitions** (schemas)
- Plugin overhead is in **skill listing tokens**, not tool definition tokens
- Plugins may provide **unique prompt engineering** that can't be replaced by built-ins
- Decomposition = extracting the valuable prompt patterns, not mapping to built-ins

### Assessment Criteria

```
Plugin provides:
├── Tool wrappers (calls Read/Write/Bash) → DECOMPOSE (skill covers this)
├── Unique prompt patterns → EXTRACT into skill (keep the pattern)
├── Workflow orchestration → EXTRACT into command/workflow
├── Hooks/automation → PORT to .claude/hooks/ if valuable
└── Novel capabilities → RETAIN plugin
```

---

## Part 4: Context Token Overhead Reduction — 6 Interventions

### Intervention 1: CLAUDE.md Split (High Priority)

**Current**: ~2,100 tokens (8.0K bytes, 171 lines) — always loaded
**Target**: ~600 tokens core + on-demand modules

**Approach**: Keep invariants in CLAUDE.md, move details to linked files.

```
BEFORE (171 lines, ~2,100 tokens):
┌──────────────────────────────────────┐
│ CLAUDE.md                            │
│ ├── Autonomic Behavior (detailed)    │  ← Move to AC overview
│ ├── Commands & Skills tables         │  ← Move to capability-map
│ ├── Guardrails NEVER/ALWAYS          │  ← Keep (safety-critical)
│ ├── Architecture (Archon) table      │  ← Condense to 3 lines
│ ├── Key File Map (3 subsections)     │  ← Move to psyche map
│ ├── JICM details                     │  ← Move to AC-04 spec
│ ├── Git Workflow                     │  ← Move to git-ops skill
│ ├── Tool Selection table             │  ← Move to capability-map
│ ├── Autonomic Components table       │  ← Redundant with AC specs
│ └── Progressive Disclosure links     │  ← Keep (tiny)
└──────────────────────────────────────┘

AFTER (~60-80 lines, ~600 tokens):
┌──────────────────────────────────────┐
│ CLAUDE.md (lean core)                │
│ ├── Identity (1 line)                │
│ ├── Autonomic: "default=autonomous"  │
│ ├── Guardrails NEVER/ALWAYS          │  ← Safety stays
│ ├── Architecture (3-line summary)    │
│ ├── Git: branch + push pattern       │
│ ├── Key refs: capability-map,        │
│ │   psyche-map, session-state        │
│ └── "Load details from linked files" │
└──────────────────────────────────────┘
```

**Files to create/update**:
- `/Users/aircannon/Claude/Jarvis/CLAUDE.md` — slim to ~60-80 lines
- Existing files already contain the details (AC specs, psyche maps, skills index)
- No new files needed — just remove redundancy

### Intervention 2: SessionStart Hook Trim (High Priority)

**Current**: ~800 tokens injected per session
**Target**: ~150 tokens

**Approach**: Emit only essentials; reference files for details.

```
BEFORE (session-start.sh additionalContext):
┌────────────────────────────────────────┐
│ Time greeting + weather (100 tok)      │
│ MCP tier suggestions (250 tok)         │  ← REMOVE (no more Tier 2)
│ Session state blob (500 tok)           │  ← COMPRESS to 2 lines
│ JICM debounce warnings (200 tok)      │  ← KEEP (safety)
│ Compressed context (variable)          │  ← KEEP (restoration)
└────────────────────────────────────────┘

AFTER:
┌────────────────────────────────────────┐
│ "Session [type]. Branch: Project_Aion. │
│  State: [1-line summary from file].    │
│  Read session-state.md for details."   │
│  + JICM debounce if applicable         │
│  + compressed context if applicable    │
└────────────────────────────────────────┘
```

**File**: `/Users/aircannon/Claude/Jarvis/.claude/hooks/session-start.sh`

### Intervention 3: MEMORY.md Restructure (Medium Priority)

**Current**: ~2,400 tokens (12K bytes, 202 lines, truncated at 200)
**Target**: ~500 tokens (structured index + pointers)

**Approach**: MEMORY.md becomes a concise index; detailed learnings move to topic files.

```
MEMORY.md (new format, ~500 tokens):
┌────────────────────────────────────────┐
│ # Jarvis Session Memory               │
│                                        │
│ ## Active Context                      │
│ - Branch: Project_Aion                 │
│ - Version: v5.8.1                      │
│ - MCPs: 5 (memory, local-rag,         │
│   fetch, git, playwright)              │
│                                        │
│ ## Key Gotchas (quick ref)             │
│ - bash 3.2: $() must return 0         │
│ - tmux: single-line -l strings only   │
│ - JICM lockout: ~78.5% ceiling        │
│                                        │
│ ## Topic Files                         │
│ - bash-patterns.md (bash 3.2 gotchas) │
│ - tmux-patterns.md (send-keys, TUI)   │
│ - credential-store.md (PAT, yq)       │
│ - jicm-thresholds.md (lockout calc)   │
│                                        │
│ ## Credential Quick Ref               │
│ - PAT: yq + head -1 + tr -d          │
│ - Push: see git-ops skill             │
└────────────────────────────────────────┘
```

**Files**:
- `/Users/aircannon/.claude/projects/-Users-aircannon-Claude-Jarvis/memory/MEMORY.md` — restructure
- Create topic files: `bash-patterns.md`, `tmux-patterns.md`, `credential-store.md`, `jicm-thresholds.md`

### Intervention 4: Skill File Format Standard (Medium Priority)

**Current**: Skill files are prose-heavy, ~800-3,000 tokens each
**Target**: ≤300 tokens per skill file (hard budget)

```
SKILL FILE FORMAT STANDARD v2.0
────────────────────────────────────────

Required Header (YAML frontmatter):
  ---
  name: <id>
  version: <semver>
  description: <one line, ≤ 15 words>
  replaces: <what this replaces, if any>
  ---

Body (imperative, no prose):
  ## Quick Reference
  | Need | Tool | Example |
  (max 10 rows)

  ## Tool Mapping (if replacing MCP/plugin)
  | Old | New | Notes |
  (only if applicable)

  ## Selection Rules (decision tree)
  ```
  Need X?
  ├── Case A → Tool 1
  └── Case B → Tool 2
  ```

FORBIDDEN:
  - Narrative paragraphs
  - Duplicated safety language (reference CLAUDE.md)
  - Examples > 2 lines
  - Sections > 15 lines
  - Token count > 300

DEDUPLICATION:
  - Safety → CLAUDE.md guardrails
  - Credentials → credential-store.md
  - Git patterns → git-ops skill
```

### Intervention 5: Test Skill Listing Impact (High Priority — Research)

**Question**: Does reducing skill file descriptions actually reduce the skill listings block that Claude Code injects into the system prompt?

**Experiment**:
1. Record current skill listing token count (count lines in system prompt referencing skills)
2. Rename one skill's SKILL.md to have a 5-word description vs current
3. Restart session
4. Compare skill listing block — did it change?

**If YES** → Implement Format Standard v2.0 across all 20 skills
**If NO** → Skill listings are Claude Code-internal; focus efforts elsewhere

**File**: All `.claude/skills/*/SKILL.md` files

### Intervention 6: Manifest/Router Implementation (Medium Priority)

Create `capability-map.yaml` as described in Part 1.

**Steps**:
1. Generate manifest from current skills index + agent README + command list
2. Add routing rules (`when:` field) for each entry
3. Add to CLAUDE.md: "Select capabilities from `.claude/context/psyche/capability-map.yaml`"
4. Test: Does Jarvis use the manifest for tool selection?
5. Iterate routing rules based on actual usage

**File**: `/Users/aircannon/Claude/Jarvis/.claude/context/psyche/capability-map.yaml`

---

## Part 5: Token Measurement Methodology

### Precise Measurement (from GPT5.2's recommendation)

```
METHOD: Capture exact token breakdown from Claude Code's JSON API

Source: ~/.claude/logs/statusline-input.json
Fields:
  context_window.current_usage.cache_creation_input_tokens  → Fixed overhead
  context_window.current_usage.cache_read_input_tokens      → Cached content
  context_window.current_usage.input_tokens                 → New per-turn
  context_window.current_usage.output_tokens                → Model output
  context_window.context_window_size                        → Total capacity

Measurement Protocol:
┌─────────────────────────────────────────────────────────────────┐
│ 1. Start fresh session (or /clear)                              │
│ 2. Send minimal first message ("hello")                        │
│ 3. Read statusline-input.json immediately                      │
│ 4. Record: cache_creation = BASELINE FIXED OVERHEAD             │
│ 5. This is the true cost of system prompt + tools + CLAUDE.md  │
│    + MEMORY.md + skill listings + hook output                  │
│                                                                 │
│ 6. Make intervention (e.g., slim CLAUDE.md)                    │
│ 7. Restart session                                              │
│ 8. Repeat steps 2-4                                            │
│ 9. Delta = intervention savings                                 │
└─────────────────────────────────────────────────────────────────┘

Current baseline (from this session):
  cache_creation_input_tokens: 12,008
  cache_read_input_tokens:    121,588
  Total context:              ~134,537 (of 200K)
```

### What This Tells Us

```
The 12,008 cache_creation tokens represent ALL fixed overhead:
  Claude Code system instructions  ~10,000  (immutable)
  Built-in tool definitions (21)    ~8,400  (immutable)
  ────────────────────────────────────────
  Subtotal (immutable)             ~18,400

  CLAUDE.md                         ~2,100  ← SLIMMABLE
  MEMORY.md                         ~2,400  ← SLIMMABLE (but may not be in cache_creation)
  Skill listings                    ~2,000  ← TEST IF CONTROLLABLE
  MCP deferred list                 ~  700  ← REDUCED (18→5 MCPs)
  Hook output                       ~  800  ← SLIMMABLE
  Git/session context               ~  500  ← MINOR
  ────────────────────────────────────────
  Subtotal (controllable)           ~8,500

  DISCREPANCY: 12,008 - 18,400 = NEGATIVE
  → Built-in tools + system prompt may be LESS than ~18,400
  → OR some "controllable" items are NOT in cache_creation
  → Measurement will clarify
```

**Important**: The precise methodology will resolve our estimates into exact numbers.

---

## Part 6: Implementation Phases

```
Phase 1: MEASURE (research, no code changes)
├── Run token measurement protocol (Part 5)
├── Test skill listing impact (Intervention 5)
├── Record precise baselines
└── Duration: 1 session

Phase 2: SLIM (low-risk reductions)
├── Intervention 1: CLAUDE.md split
├── Intervention 2: SessionStart hook trim
├── Intervention 3: MEMORY.md restructure
├── Re-measure after each
└── Duration: 1 session

Phase 3: STANDARDIZE (skill format)
├── Intervention 4: Skill File Format Standard v2.0
├── Rewrite 4 MCP-replacement skills to standard
├── Rewrite 3-5 most-used skills to standard
├── Re-measure
└── Duration: 1-2 sessions

Phase 4: MANIFEST (architectural)
├── Intervention 6: Create capability-map.yaml
├── Add routing rules
├── Test manifest-based selection
├── Update CLAUDE.md to reference manifest
└── Duration: 1 session

Phase 5: PIPELINE (ongoing)
├── Formalize MCP-to-Skill pipeline (Part 2)
├── Formalize Plugin-to-Skill pipeline (Part 3)
├── Apply to any future MCP/plugin additions
├── Document in registry
└── Duration: Ongoing
```

---

## Part 7: Best Practices (from GPT5.2 + Jarvis Experience)

### What GPT5.2 Got Right (Incorporated)

1. **"Treat .claude/ like a runtime, not a handbook"**
   → Implemented via manifest + module pattern. Index is tiny; modules load on demand.

2. **"Agent-runbook style, not narrative"**
   → Enforced via Skill File Format Standard v2.0 (imperative, tables, decision trees).

3. **"Put global safety in policies, not repeated in every module"**
   → CLAUDE.md guardrails are the single source; skills reference, never duplicate.

4. **"Micro-prompt budgets (≤200-300 tokens per skill)"**
   → Hard budget in Format Standard. Enforced during pipeline BUILD step.

5. **"Don't inject encyclopedias. Inject an index + retrieval strategy."**
   → The manifest IS the index. Progressive disclosure IS the retrieval strategy.

6. **"Two-tier memory"**
   → MEMORY.md = hot (concise index). Topic files = cold (detailed, on-demand).

7. **"Results cache for expensive tool outputs"**
   → Already partially implemented via `.compressed-context-ready.md`. Extend to manifest pattern.

8. **"Verify prompt caching"**
   → CONFIRMED WORKING: 12K creation, 121K reads. Per-turn cost is optimized.

### Combined Best Practices Registry

```
MCP-TO-SKILL BEST PRACTICES:
  BP-01: One test per mapped tool (no gaps in validation)
  BP-02: Skill file ≤ 300 tokens (hard budget)
  BP-03: Measure before AND after removal (precise methodology)
  BP-04: Register in manifest immediately (no orphan skills)
  BP-05: Any removed MCP can return via `claude mcp add` (reversible)

PLUGIN-TO-SKILL BEST PRACTICES:
  BP-06: Extract prompt patterns, not just tool mappings
  BP-07: Assess unique capabilities before decomposing
  BP-08: Plugin hooks → port to .claude/hooks/ if valuable
  BP-09: Plugin skills → compile to Format Standard v2.0

CONTEXT REDUCTION BEST PRACTICES:
  BP-10: Always-on content ≤ 1,000 tokens total (CLAUDE.md + MEMORY.md)
  BP-11: Reference, don't repeat (link to files, don't inline)
  BP-12: Measure via cache_creation_input_tokens (precise, not estimated)
  BP-13: Test changes via restart comparison (not mid-session)
  BP-14: Safety/guardrails always stay in CLAUDE.md (never moved to on-demand)
```

---

## Part 8: Projected Savings Summary

```
Intervention                   Savings      Phase    Difficulty
─────────────────────────────  ──────────   ──────   ──────────
MCP removal (18 → 5)          ~5,700 tok   DONE     ✅ Complete
CLAUDE.md split                ~1,500 tok   Phase 2  Easy
SessionStart hook trim         ~  650 tok   Phase 2  Easy
MEMORY.md restructure          ~1,900 tok   Phase 2  Easy
Skill format optimization      ~  800 tok   Phase 3  Medium
Manifest/router (vs listings)  ~1,200 tok   Phase 4  Medium
                               ──────────
TOTAL PROJECTED               ~11,750 tok   (~5.9% of 200K context window)

Additional benefits:
  - 13 fewer MCP server processes (reduced startup time)
  - Deterministic skill routing (via manifest)
  - Standardized pipeline for future conversions
  - Caching already reduces per-turn COST by ~90%
```

---

## Verification Plan

1. **Phase 1 gate**: Precise token baselines recorded via statusline JSON
2. **Phase 2 gate**: Each intervention measured independently; total ≥ 3,000 tokens saved
3. **Phase 3 gate**: ≥ 7 skill files converted to Format Standard v2.0
4. **Phase 4 gate**: Manifest created; Jarvis uses it for at least 3 tool selections in a test session
5. **Phase 5 gate**: Pipeline documented; next MCP/plugin addition follows the protocol

---

## Critical Files

| File | Action |
|------|--------|
| `/Users/aircannon/Claude/Jarvis/CLAUDE.md` | Slim to ~60-80 lines |
| `/Users/aircannon/Claude/Jarvis/.claude/hooks/session-start.sh` | Trim additionalContext output |
| `/Users/aircannon/.claude/projects/-Users-aircannon-Claude-Jarvis/memory/MEMORY.md` | Restructure + create topic files |
| `/Users/aircannon/Claude/Jarvis/.claude/skills/*/SKILL.md` | Reformat to Standard v2.0 |
| `/Users/aircannon/Claude/Jarvis/.claude/context/psyche/capability-map.yaml` | Create (new) |
| `/Users/aircannon/Claude/Jarvis/.claude/context/reference/mcp-decomposition-registry.md` | Update with pipeline protocol |
| `/Users/aircannon/Claude/Jarvis/.claude/context/patterns/mcp-loading-strategy.md` | Update Tier 1/2 tables |
| `~/.claude/logs/statusline-input.json` | Read for precise measurement |

---

*MCP-to-Skill & Plugin-to-Skill Pipeline Design v2.0 — 2026-02-07*
