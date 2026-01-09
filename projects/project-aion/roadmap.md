# Project Aion — Jarvis (AIfred “Archon”) Feature Request & Development Roadmap
*Current date: 2026-01-09*  
*Target environment: Claude Code (primary) + OpenCode (secondary)*  
*Baseline reference (vanilla template, upstream-only): **AIfred mainline by David O’Neil** (“AIfred baseline”)*  
*Project Aion Archons: **Jarvis**, **Jeeves**, **Wallace** (and future Archons as needed)*  

---

## 0) Purpose / Problem Statement

You are developing **Project Aion**, a set of **Archons** derived from (but not modifying) the **AIfred baseline**.

**Jarvis** is the “master” Archon: a highly autonomous, self-improving, tool-rich AI infrastructure + software-development assistant that:
- installs, validates, and uses a broad set of **MCP servers**, **Claude skills**, and **Claude Code plugins**;
- orchestrates agentic workflows for real project delivery (not just chat);
- reduces unnecessary permission prompts inside controlled workspaces;
- maintains **session continuity**, **auditability**, and **versioned self-evolution**;
- continuously benchmarks itself against end-to-end demos and periodically incorporates improvements by **porting** from upstream AIfred baseline (pull → diff → propose → apply-with-review).

This document is a **feature request** (what to build) and a **development roadmap** (how to build it in phases) suitable for driving a Claude Code coding agent.

> **Baseline safety rule (repeat):** The AIfred baseline repository is **read-only** from Project Aion’s perspective.  
> Jarvis may **only** use Git to **pull** upstream changes from AIfred baseline’s main branch into the local upstream mirror directory, and may never directly edit AIfred baseline files.

---

## 1) Scope & Anti-scope: non-goals

### In Scope
- Jarvis as an **Archon** derived from AIfred baseline, with its own docs, setup, hooks, agents, and patterns.
- Tooling expansion across: **Core Tooling**, **Plugins**, **Skills**, **MCP servers**—with **tests and validation**.
- A robust `/setup` that performs prerequisite checks, guided installs, and operational readiness checks.
- Improved autonomy and reduced approvals **within explicitly allowlisted directories**.
- Upstream sync workflow: pull AIfred baseline → diff → propose safe ports → apply with user review (to Jarvis repo only).
- Self-evolution workflow: reflect, propose, test/benchmark, version bump, push.

### Anti-scope: non-goals
- **Never directly edit the AIfred baseline repo.**  
  - Allowed: `git clone`, `git fetch`, `git pull` from baseline main into a **local mirror directory** for diff/analysis.  
  - Not allowed: commits, file edits, branch creation, hooks, or config changes within baseline.
- Do not rename or rewrite AIfred baseline terminology/docs to “Project Aion” terminology. (Project Aion terminology applies only to Project Aion Archon repos.)
- Storing secrets/credentials in repo, context, or memory.
- Auto-merging from upstream without review (Jarvis is a divergent track).
- Building a full orchestration framework from scratch if Claude Code primitives + hooks + agents suffice.
- Automated decisions that require billing/ownership choices (e.g., Google APIs); these remain user-gated.
- “Unlimited autonomy everywhere” — autonomy must be **scoped** and **audited**.

> **Reminder:** AIfred baseline is a **read-only upstream reference**. Jarvis ports changes into its own repo/workspace; it never edits baseline directly.

---

## 2) Prioritized Product Requirements (PRs)

> **Important:** Each PR that adds new capabilities MUST include:
> 1) **Overlap & conflict analysis** (redundancy, functional overlaps, conflicting behaviors)  
> 2) **Selection rules** (what is primary vs fallback, when to use which)  
> 3) **Validation** (smoke tests / health checks / demo outcomes)

### PR-1: Archon Identity + Branching Model + Versioning (with Baseline Update Discipline)
**Goal:** Establish Project Aion identity, rules, and versioning—and enforce baseline update hygiene at session start.

#### PR-1.A — Define the Archons
Adopt **Archon** terminology for Project Aion and define core Archons:
- **Jarvis** = master Archon for dev + infrastructure + building other Archons
- **Jeeves** = **always-on** Archon triggered by cron jobs for personal automation (calendar reminders, daily encouragement, scriptural thoughts, productivity/fun ideas, etc.)
- **Wallace** = creative writer Archon (concept stage)

#### PR-1.B — Clarify upstream relationship and “read-only baseline” rule
- Jarvis is derived from the AIfred baseline (David O’Neil).
- Jarvis is a divergent development track; not intended to merge back.
- **AIfred baseline is read-only; never edit it.**
- Jarvis should reference the **most current AIfred version** as its upstream source **within its documentation** (e.g., record the current baseline commit SHA/date in a “Upstream baseline state” note).

#### PR-1.C — Mandatory baseline update at the start of PR-1
Before doing anything else in PR-1, execute a git update of the local AIfred baseline mirror:

- Ensure the local mirror exists at:  
  `/Users/aircannon/Claude/AIfred`
- Run: `git pull` (or `git fetch` + status check + `git pull`) on baseline `main`.

**Constraints:**
- This update is the *only allowed* modification interaction with the AIfred baseline repo (pull/fetch only).
- No commits, edits, branches, hooks, or config changes are permitted within the baseline repo.

#### PR-1.D — Session-start design pattern: always check baseline updates
Update Jarvis design patterns/docs so that **every new Jarvis session begins with**:
1) checking whether upstream AIfred baseline has updates, and  
2) pulling updates into `/Users/aircannon/Claude/AIfred` if updates are found.

This should be treated as a **default session-start checklist item**.

#### PR-1.E — Workspace rule: where project outputs go (and where Project Aion docs live)
Update Jarvis design pattern code/docs to clarify:

- When Jarvis works on **other projects**, their codebase and documentation must be written to that project’s own folder created under:  
  `/Users/aircannon/Claude/<ProjectName>/`

- **Project Aion is special**: Jarvis is working on itself, evolving its own repo/codebase while it works. Therefore Project Aion documentation may live at:  
  `/Users/aircannon/Claude/Jarvis/docs/project-aion`

This is the canonical location for Project Aion docs going forward.

#### PR-1.F — Versioning policy
- Normal pushes bump **0.1**
- Benchmark/test report pushes bump **x.x.1**

#### PR-1.G — Establish changelog / release note convention
- Maintain a changelog/release-notes convention for Jarvis with:
  - date
  - version
  - summary
  - PR references (PR-1, PR-2, …)
  - “breaking changes / migrations” section when relevant
- **Secondary Archons like Jeeves and Wallace should include a “created using Jarvis version x.x.x”** so that:
  - versioning is pinned to Jarvis versions, and
  - each other Archon’s own version is tracked independently.
- Jarvis should reference the most current version of AIfred as its source, within its documentation.

#### PR-1.H — Archive obsolete baseline plan document
Archive the obsolete file:

- Source: `/Users/aircannon/Claude/Jarvis/docs/PROJECT-PLAN.md`
- Create archive folder: `/Users/aircannon/Claude/Jarvis/docs/archive/`
- Move the file into the archive folder.
- Add a log file notation in an archive log, for example:
  - `/Users/aircannon/Claude/Jarvis/docs/archive/archive-log.md`

**Pattern requirement:** Update development patterns so that when archiving obsolete documentation:
- it goes into `/docs/archive/`, and
- the action is recorded in the archive log with:
  - timestamp
  - file path
  - reason for archiving
  - “replaced by” reference if applicable (e.g., this roadmap doc)

**Rationale:** `PROJECT-PLAN.md` is the project plan doc for vanilla AIfred and is no longer the primary source of truth for Project Aion. It remains as historical initialization context only.

---

### PR-2: Workspace & Project Location Policy + Project Summaries + One-shot PRD Doc
**Goal:** Make Jarvis a hub with deterministic, user-approved workspace boundaries and standardized project summarization.

Requirements:
- Confirm and implement:
  - projects live in: `/Users/aircannon/Claude/<ProjectName>/`
  - Jarvis project summaries live in: `/Users/aircannon/Claude/Jarvis/projects/`
  - Project Aion docs live in: `/Users/aircannon/Claude/Jarvis/docs/project-aion`
- Ensure “Hub, Not Container” remains true: Jarvis tracks/works on projects stored elsewhere.
- Improve/extend project registration behavior (hook- or command-driven):
  - detect GitHub URLs and “new project” requests
  - register project path + create context summary doc
  - maintain a registry (e.g., `paths-registry.yaml` or Jarvis equivalent)

Deliverables:
- A standardized “Project Summary” template.
- A deterministic directory policy section in docs.
- Optional: a `/register-project` and `/create-project` refinement plan.
- Design and create the **one-shot PRD** document (see Section 3) as a default artifact stored in Jarvis.

Overlap/Conflict analysis requirements (PR-2):
- Ensure project registration does not conflict with:
  - upstream sync workflow
  - allowlist/permission boundaries
  - existing AIfred-style project-detector patterns (if present)
- Define selection rules:
  - when auto-register triggers vs when to prompt user

Validation:
- A smoke test procedure describing:
  - “Given a GitHub URL, Jarvis can determine target folder + summary path + registry entry.”

---

### PR-3: Upstream Sync Workflow (AIfred baseline → Jarvis Controlled Porting)
**Goal:** Keep Jarvis modern without destabilizing its divergent track.

Requirements:
1. Maintain a local upstream mirror at: `/Users/aircannon/Claude/AIfred`
2. Pull baseline updates (Git-only) to keep mirror current.
3. Compute diff vs Jarvis.
4. Classify changes: safe / unsafe / manual review.
5. Propose ports and apply only after review (**to Jarvis repo only**).
6. Maintain a port log (“adopt/adapt/reject” with rationale), including:
   - baseline commit hash
   - ported commit(s) or patch summary
   - conflicts/resolutions
   - rollback notes if needed

Deliverables:
- A repeatable workflow or command (e.g., `/sync-aifred-baseline`) that generates a structured report.
- A standing reminder in docs/scripts: **AIfred baseline is read-only; never edit it**.

Overlap/Conflict analysis requirements (PR-3):
- Ensure sync does not conflict with:
  - Jarvis local modifications
  - hooks that auto-edit docs during sessions
  - permissions model (sync touches only Jarvis repo)

Validation:
- A dry-run mode producing a report without applying changes.
- A “safe port” path that produces a patch/commit set staged for review.

---

### PR-4: Setup Preflight + Environment + Guardrailed Permissions (v1)
**Goal:** `/setup` becomes a real “preflight + configure + verify” wizard (before heavy tooling expansion).

Requirements:
- Add a “Prereqs & Environment” stage:
  - OS checks
  - guided manual installs where required (explicitly list manual steps)
  - venv creation + dependency installation (pin versions)
  - instructions for recommended launch mode: `claude --debug --verbose`
  - teach `/mcp` drilldown for tool descriptions
- Permissions:
  - explicitly inherit all permissions at/below Jarvis root
  - add allowlist for active project workspace(s)
  - tighten/guard dangerous operations (deletes, moves, etc.)
- Encourage local n8n or remote connection.
- Encourage embeddings model service setup for RAG/Graphiti-class tools (as a future dependency).
- Include a reminder: **do not modify the AIfred baseline repo** (only pull for upstream sync).

Deliverables:
- Setup phases and docs (even if some steps are manual gates initially).
- A setup “readiness report” output.

Overlap/Conflict analysis requirements (PR-4):
- Ensure setup changes do not reduce safety:
  - confirm allowlist boundaries
  - ensure audit logs still capture actions
- Ensure setup does not implicitly “init” or modify the AIfred baseline directory.

Validation:
- Setup produces a deterministic pass/fail report.
- A “minimum viable ready” state is defined and testable.

---

### PR-5: Core Tooling Baseline (Anthropic-first) + Overlap Analysis
**Goal:** Establish a minimal, reliable default toolbox.

Core Tooling includes:
- Core MCP servers: Time, Memory, Filesystem, Fetch (and other standardized “core” servers)
- GitHub MCP
- Anthropic Skills (official)
- Anthropic Agents (built-in subagents and/or official agent packs)
- Anthropic Plugins

Requirements:
- Install/enable defaults (as feasible) and document:
  - what’s enabled by default
  - what’s optional/on-demand
- Produce a **capability matrix**:
  - “Task type → preferred tool/skill/plugin/agent → fallback”
- Perform overlap/conflict analysis:
  - e.g., GitHub MCP vs CLI git; built-in subagents vs custom agents; plugin features vs hooks
- Add initial validation:
  - “Core Tooling health check” and deterministic smoke tests.

Validation:
- A baseline health command/report exists and can be re-run.
- At least one deterministic smoke test per enabled default capability domain (filesystem, github, memory/time).

---

### PR-6: Plugins Expansion (Ecosystem) + Overlap/Conflict Resolution
**Goal:** Expand plugin coverage while preventing redundancy and behavioral conflicts.

Requirements:
- Install and evaluate:
  - Anthropic official Claude Code plugins  
    https://github.com/anthropics/claude-code/blob/main/plugins/README.md
  - Orchestration/automation plugin ecosystem (reference)  
    https://github.com/wshobson/agents
  - “Ralph Wiggum” autonomy ideas (reference)  
    https://awesomeclaude.ai/ralph-wiggum
- For each plugin:
  - document purpose, best-use scenarios, risks
  - overlap/conflict analysis vs existing agents/hooks
  - selection rules (primary vs fallback)
- Decide: adopt / adapt / reject.

Validation:
- For adopted plugins: add a simple “proof of use” validation scenario.

---

### PR-7: Skills Inventory (Official + Curated Unofficial) + Selection Rules
**Goal:** Make skills a first-class, searchable toolkit with clear selection logic.

Requirements:
- Ingest and categorize official skills:
  - Anthropic skills repo: https://github.com/anthropics/skills  
  - Skills overview: https://github.com/anthropics/skills/blob/main/README.md  
  - Skill-creator philosophy: https://github.com/anthropics/skills/blob/main/skills/skill-creator/SKILL.md
- Curate unofficial skills (evaluate + classify adopt/adapt/reject), including:
  - ComposioHQ awesome skills: https://github.com/ComposioHQ/awesome-claude-skills
  - tapestry skills: https://github.com/michalparkola/tapestry-skills-for-claude-code
  - markdown-to-epub: https://github.com/smerchek/claude-epub-skill
  - csv summarizer: https://github.com/coffeefuelbump/csv-data-summarizer-claude-skill
  - developer-growth-analysis (priority):  
    https://github.com/ComposioHQ/awesome-claude-skills/tree/master/developer-growth-analysis
- Overlap/conflict analysis:
  - skills vs MCP tools vs plugins (e.g., doc conversion, web research, file management)
- Produce a “Skills selection guide” aligned with Jarvis patterns.

Validation:
- Pick 3 representative tasks; demonstrate (document) skill selection behavior.

---

### PR-8: MCP Expansion + Context Budget Management + Validation Harness
**Goal:** Expand MCP servers gradually with context-aware loading, budget monitoring, and validation.

> **Extended Scope (2026-01-07)**: PR-8 now includes context budget management to address context window bloat (observed 232k/200k = 116% usage). MCP tool definitions consume ~61K tokens (30.5%) whether used or not.
>
> **Key Discovery (2026-01-07)**: MCP disabled state is stored in `~/.claude.json` under `projects.<path>.disabledMcpServers[]`. This enables programmatic MCP control without uninstalling.

#### PR-8.1: Context Budget Optimization (Complete)

Requirements:
- **Plugin Pruning**: Remove unused high-cost plugins ✅
- **Duplicate Resolution**: Fix frontend-design duplication ✅
- **CLAUDE.md Refactoring**: Reduce from 5.2K to <3K tokens ✅

**Savings Achieved**: ~15K tokens (~7.5% context budget reclaimed)

#### PR-8.2: MCP Loading Tiers (Complete)

Requirements:
- Define MCP loading tiers based on context budget: ✅
  - **Tier 1 — Always-On**: memory, filesystem, fetch (never disable)
  - **Tier 2 — Task-Scoped**: github, git, context7, sequential-thinking (disable when not needed)
  - **Tier 3 — Plugin-Managed**: playwright, gitlab (managed by plugin system)

#### PR-8.3: Dynamic Loading Protocol (Complete)

Requirements:
- **disabledMcpServers Mechanism**: ✅ Discovered and documented
  - Location: `~/.claude.json` → `projects.<path>.disabledMcpServers[]`
  - To disable: Add MCP name to array
  - To enable: Remove MCP name from array
  - Effect: Changes apply after `/clear` (validated 2026-01-07)
- **MCP Control Scripts**: ✅ Created and tested
  - `disable-mcps.sh` — Add to disabledMcpServers ✅
  - `enable-mcps.sh` — Remove from disabledMcpServers ✅
  - `list-mcp-status.sh` — Show registered vs disabled ✅
- **Workflow**: ✅ Validated (single workflow, no exit required)
  - `/context-checkpoint` → `/exit-session` → `/clear` → resume

**PR-8.3.1: Zero-Action Context Management** (Complete — v1.8.1):
- [x] Create and test disable-mcps.sh script ✅
- [x] Create and test enable-mcps.sh script ✅
- [x] Create /context-checkpoint command ✅
- [x] Validate full workflow end-to-end ✅ (2026-01-07)
- [x] **Zero-Action Automation** ✅:
  - Auto-clear watcher (external AppleScript keystroke automation)
  - Stop hook with `decision:block` (Ralph Wiggum pattern)
  - SessionStart watcher auto-launch
  - PreCompact hook for automatic checkpointing
  - `additionalContext` injection for auto-resume
- [x] Documentation: `.claude/context/patterns/automated-context-management.md`

**Token Savings Validated**: 16.2K → 7.4K MCP tokens (54% reduction)

#### PR-8.4: MCP Validation Harness (Complete — v1.8.2)

**Pattern**: `.claude/context/patterns/mcp-validation-harness.md`
**Command**: `/validate-mcp [mcp-name]`

Requirements:
- [x] Design 5-phase validation harness pattern ✅
- [x] Create validation script ✅
- [x] Validate design MCPs (Git, Memory, Filesystem) ✅ All Tier 1
- [x] Create `/validate-mcp` skill ✅
- [x] Update mcp-installation.md with validated token costs ✅
- [x] Test harness with DuckDuckGo ⚠️ FAILED (bot detection)
- [x] Test harness with arXiv ✅ Installed, Phase 4 pending
- [x] Document Brave Search deferral (requires API key) ✅
- [x] Add lessons learned from validation testing ✅

**Key Findings**:
- Mid-session installs require restart for tools to appear
- External service reliability is critical (DuckDuckGo fails due to bot detection)
- Package naming inconsistencies require verification before install
- API key gating should happen early in Phase 2

**Validation Results**:
| MCP | Status | Tier | Finding |
|-----|--------|------|---------|
| Git | PASS | 1 | ~2.5K tokens, reliable |
| Memory | PASS | 1 | ~1.8K tokens, reliable |
| Filesystem | PASS | 1 | ~2.8K tokens, reliable |
| DuckDuckGo | FAIL | 3 | Bot detection blocks requests |
| arXiv | PARTIAL | 2 | Phase 4 pending restart |
| Brave Search | DEFERRED | 2 | Requires API key |

**Documentation**: @.claude/context/patterns/mcp-validation-harness.md

#### PR-8.5: MCP Expansion — Batch Installation (Complete — v1.8.3)

**Status**: ✅ **COMPLETE** (2026-01-09)

Requirements:
- [x] Install and validate 10 new MCPs ✅
- [x] Document tier recommendations and token costs ✅
- [x] Add validation insights to harness pattern ✅

**Validated MCPs** (all PASS):

| MCP | Status | Tier | Key Finding |
|-----|--------|------|-------------|
| DateTime | PASS | 2 | ~1K tokens, IANA timezone support |
| DesktopCommander | PASS | 2 | ~8K tokens, 30+ tools |
| Lotus Wisdom | PASS | 3 | Contemplative reasoning, niche |
| Wikipedia | PASS | 2 | ~2K tokens, clean markdown |
| Chroma | PASS | 2 | ~4K tokens, vector DB |
| Perplexity | PASS | 2 | ~3K tokens, 4 tools (search/ask/research/reason) |
| Playwright | PASS | 3 | ~6K tokens, browser automation |
| GPTresearcher | PASS | 2 | ~5K tokens, Python 3.13 venv required |
| Brave Search | PASS | 2 | ~3K tokens, API-based |
| arXiv | PASS | 2 | ~2K tokens, paper download/read |

**Removed**: DuckDuckGo (bot detection unreliable)

**Key Discoveries** (added to harness pattern):
1. Perplexity `strip_thinking=true` for context efficiency
2. GPTresearcher requires Python 3.13+ venv
3. Playwright accessibility snapshots more efficient than screenshots
4. Research MCP complementarity: Perplexity (fast) vs GPTresearcher (deep)

**Validation Log**: `.claude/logs/mcp-validation/batch-validation-20260108.md`

---

### PR-9: Selection Intelligence Pattern (Research-Backed Tool Modality Framework)

**Goal:** Establish a research-backed framework for tool selection AND component extraction that enables granular control over all tool modalities.

> **Extended Scope (2026-01-09)**: PR-9 addresses THREE interconnected challenges:
> 1. **Component Extraction** — Decompose plugins into granular components (skills, agents, hooks, MCPs, etc.)
> 2. **Selection Theory** — Research-backed tool-type precedence framework
> 3. **Selection Validation** — Measurable acceptance criteria for selection quality
>
> **Research Foundation**: Based on Anthropic Agent Skills architecture, LangChain Deep Agents patterns, and MCP design philosophy.
> - References: [Anthropic Agent Skills](https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills), [LangChain Deep Agents](https://blog.langchain.com/using-skills-with-deep-agents/)
> - Pattern: `.claude/context/patterns/tool-selection-intelligence.md`

---

#### PR-9.0: Component Extraction Workflow (Foundation)

**Goal**: Establish universal workflow for decomposing ANY plugin/bundle into granular Jarvis-controlled components.

**Theory** (from Anthropic Agent Skills research):
- Plugins are simple directory structures (not compiled/obfuscated)
- Skills use progressive disclosure: metadata → core → linked resources
- Token efficiency: 50-100 tokens per skill summary vs 10K+ for full bundle
- Granular components enable: MCP validation, context management, customization

**Component Mapping**:

| Plugin Source | Jarvis Target | Purpose |
|---------------|---------------|---------|
| `skills/**/SKILL.md` | `.claude/skills/` | Standalone skills |
| Agent patterns | `.claude/agents/` | Custom agents |
| Hook implementations | `.claude/hooks/` | Behavioral hooks |
| MCP registrations | MCP config | Validated MCPs |
| Commands | `.claude/commands/` | Slash commands |
| Config files | `.claude/config/` | Configuration |
| Context injections | `.claude/context/` | Context files |
| Patterns | `.claude/context/patterns/` | Design patterns |
| Templates | `.claude/context/templates/` | Reusable templates |

**Deliverables**:
- [ ] `/extract-skill <plugin> <skill>` command
- [ ] Component analysis workflow documentation
- [ ] Pilot extraction: `document-skills` → docx, pdf, xlsx, pptx
- [ ] Token savings measurement (target: 10K+ reduction)

**Acceptance Criteria**:
- [ ] Extracted skills work independently of source plugin
- [ ] Extracted skills appear in `/skills` list
- [ ] Token overhead reduced by measurable amount
- [ ] Capability matrix updated with extracted components

---

#### PR-9.1: Selection Theory & Framework (Research-Backed)

**Goal**: Create authoritative, research-backed selection intelligence documentation.

**Two-Layer Model** (from research):
```
KNOWLEDGE LAYER (HOW to do things)
├── Skills (SKILL.md)
├── Agents (personas)
├── Patterns (guides)
└── Prompts (context)

INTEGRATION LAYER (WHAT can be done)
├── MCPs (servers)
├── Plugins (bundles)
├── Tools (built-in)
└── Bash (shell)
```

**Precedence Hierarchy** (research-backed):
1. **Built-in Tools** — Zero overhead, if sufficient
2. **Skills** — 50-100 token summary, procedural workflows
3. **Specialized Subagents** — Context isolation
4. **MCPs** — External integrations
5. **Custom Agents** — Learning/memory tasks

**LLM Selection Insight**: Claude Code uses LLM reasoning, NOT algorithmic routing. Tool descriptions are critical for selection quality (~0.91 accuracy).

**Deliverables**:
- [x] `tool-selection-intelligence.md` — Foundation pattern ✅ Created 2026-01-09
- [x] `agent-selection-pattern.md` v2.0 — Full rewrite ✅ 2026-01-09:
  - All tool modalities with selection rules
  - 3-tier MCP loading integration
  - Research tool routing (Perplexity vs GPTresearcher)
  - Browser automation routing
  - MCP-Agent pairing table
- [x] Unified `selection-intelligence-guide.md` ✅ Created 2026-01-09:
  1. Quick Selection Matrix
  2. MCP Selection by Work Type
  3. Research Tool Routing flowchart
  4. Agent vs Subagent Decision
  5. Skill Selection
  6. Conflict Resolution
  7. Fallback Chains
- [x] Updated CLAUDE.md Quick Selection section ✅ 2026-01-09

**Acceptance Criteria**:
- [x] agent-selection-pattern.md updated to v2.0 ✅
- [x] selection-intelligence-guide.md created ✅
- [x] All tool modalities have documented selection rules ✅
- [x] Research tool routing decision tree complete ✅
- [x] Browser automation selection documented ✅

---

#### PR-9.2: Research Tool Routing (Specialized)

**Goal**: Optimize research task routing across 5 overlapping tools.

**Decision Flowchart**:
```
Research Task Received
├── Quick fact check → perplexity_search or WebSearch
├── Current events → brave_web_search
├── Q&A with citations → perplexity_ask
├── Academic papers → arxiv_search + download
├── Reference article → wikipedia_search
├── Multi-source synthesis → perplexity_research
└── Comprehensive (16+ sources) → gptresearcher_deep_research
```

**Latency/Depth/Cost Matrix**:

| Tool | Latency | Depth | API Cost | Token Cost |
|------|---------|-------|----------|------------|
| `perplexity_search` | Fast | Shallow | Low | ~3K |
| `brave_web_search` | Fast | Shallow | Low | ~3K |
| `perplexity_ask` | Fast | Medium | Medium | ~3K |
| `perplexity_research` | Medium | Deep | Medium | ~3K |
| `gptresearcher_deep_research` | Slow | Very Deep | High | ~5K |
| `arxiv_search` | Medium | Deep | Free | ~2K |
| `wikipedia_search` | Fast | Medium | Free | ~2K |

**Deliverables**:
- [x] Research decision flowchart in mcp-design-patterns.md ✅ 2026-01-09
- [x] Latency/depth/cost documentation ✅ Context-Aware Research Selection table
- [x] Context lifecycle integration with agents and compression ✅
- [x] 7 research validation scenarios documented ✅
- [x] Agent delegation patterns with context headroom checks ✅

---

#### PR-9.3: Deselection Intelligence (Enhancement)

**Status**: **COMPLETE** ✅ 2026-01-09

**Completed Infrastructure**:
- ✅ `disable-mcps.sh` / `enable-mcps.sh` / `list-mcp-status.sh`
- ✅ `/context-checkpoint` with MCP evaluation
- ✅ Auto-clear watcher + SessionStart hook integration
- ✅ `suggest-mcps.sh` keyword-to-MCP mapping (v1.8.4)

**PR-9.3 Enhancements Completed**:
- [x] **Smarter keyword analysis** — Expanded from 35 to 65+ keyword mappings ✅
- [x] **Task-specific patterns** — Keywords like "implement", "feature", "deploy" ✅
- [x] **Usage-based recommendation** — `context-accumulator.js` tracks MCP tool usage ✅
- [x] **`--usage` mode** — `suggest-mcps.sh --usage` shows usage stats ✅
- [x] **Unused MCP detection** — Shows enabled but unused MCPs as disable candidates ✅

**Deferred (Low Priority)**:
- [ ] TodoWrite integration — Infer MCPs from todo list (complex, limited value)
- [ ] Pre-session questionnaire — "What MCPs do you need today?" (optional UX)

---

#### PR-9.4: Selection Validation (Quality Assurance)

**Status**: **COMPLETE** ✅ 2026-01-09

**Goal**: Create measurable validation for selection intelligence.

**10 Acceptance Test Cases**:

| Test ID | Input | Expected Selection | Rationale |
|---------|-------|-------------------|-----------|
| SEL-01 | "Find package.json files" | `Glob` | Not Explore |
| SEL-02 | "What files handle auth?" | `Explore` subagent | Context isolation |
| SEL-03 | "Create a Word document" | `docx` skill | Skill over manual |
| SEL-04 | "Research Docker networking" | `deep-research` agent | Custom agent |
| SEL-05 | "Quick fact: capital of France" | `WebSearch` | Built-in first |
| SEL-06 | "Comprehensive analysis of X" | `gptresearcher_deep_research` | Full research |
| SEL-07 | "Navigate to example.com" | `Playwright MCP` | Browser automation |
| SEL-08 | "Fill out the login form" | `browser-automation` | NL browser task |
| SEL-09 | "Push changes to GitHub" | `engineering-workflow-skills` | Skill over bash |
| SEL-10 | "Review this PR thoroughly" | `pr-review-toolkit` | Comprehensive |

**Deliverables**:
- [x] `/validate-selection` command ✅ 2026-01-09
- [x] 10 documented test cases ✅ `selection-validation-tests.md`
- [x] Selection audit logging ✅ `selection-audit.js` hook

**Acceptance Criteria**:
- [x] 80%+ accuracy on test cases — **90% achieved** (8 pass, 2 acceptable, 0 fail)
- [x] Selection audit logging implemented — Logs to `selection-audit.jsonl`

**Validation Report**: `.claude/reports/selection-validation-run-2026-01-09.md`

---

#### PR-9.5: Documentation Consolidation

**Status**: **COMPLETE** ✅ 2026-01-09

**Documents Updated**:
- [x] `capability-matrix.md` v1.5 — Add PR-9 selection framework ✅
- [x] `overlap-analysis.md` v1.2 — Add research tool overlaps ✅
- [x] `agent-selection-pattern.md` v2.0 — Full rewrite ✅ (done in PR-9.1)
- [x] `mcp-loading-strategy.md` v2.2 — Add selection integration ✅
- [x] `_index.md` — Added PR-9 patterns to Active Patterns, Recent Updates ✅

---

#### PR-9 Version Plan

| Milestone | Version | Deliverables |
|-----------|---------|--------------|
| PR-9.0 Complete | 1.9.0 | Component extraction workflow |
| PR-9.1 Complete | 1.9.1 | Selection theory & framework |
| PR-9.2 Complete | 1.9.2 | Research tool routing |
| PR-9.3 Complete | 1.9.3 | Deselection enhancements |
| PR-9.4 Complete | 1.9.4 | Selection validation |
| PR-9.5 Complete | 1.9.5 | Documentation consolidation |

---

#### PR-9 Validation Summary

**Status**: **ALL CRITERIA MET** ✅

- [x] Component extraction: 1 plugin fully decomposed ✅ (document-skills → 6 skills)
- [x] Selection framework: All modalities documented ✅ (9 modalities in tool-selection-intelligence.md)
- [x] Research routing: 7 scenarios tested ✅ (decision flowchart with context-lifecycle)
- [x] Deselection: Context reduction demonstrated ✅ (suggest-mcps.sh --usage for unused detection)
- [x] Validation: **90%** test case accuracy ✅ (exceeded 80% target)

**Key Deliverables**:
- `selection-intelligence-guide.md` — Lean quick reference
- `selection-validation-tests.md` — 10 standardized test cases
- `selection-audit.js` — PostToolUse audit logging hook
- `suggest-mcps.sh` — 65+ keyword mappings, --usage mode
- `context-accumulator.js` — MCP usage tracking

**Version**: v1.9.4

---

### PR-10: Setup Upgrade (Auto-installs + Optional Approvals)
**Goal:** Revisit `/setup` after tools exist to automate more installs safely.

Requirements:
- Plugins and skills likely default-required: enable/install by default where feasible.
- MCP installs:
  - auto-install Stage 1 defaults
  - additional MCPs suggested and user-approved (optional), often dependency-driven
- Setup re-runs validations and produces pass/fail readiness outputs.
- Include guardrail reminders: **AIfred baseline is read-only** (pull-only).

Validation:
- Setup can bring a new machine to “baseline-ready” reproducibly.
- Setup outputs a stable readiness report artifact.

---

### PR-11: Autonomy & Permission Reduction (Scoped) + One-shot PRD Validation Standard
**Goal:** Increase autonomy while enforcing safety via measurable standards.

Requirements:
- Claude Code should not ask permission for operations:
  - inside Jarvis workspace
  - inside the active target project workspace(s)
- Use allowlists and auditing; consider `--dangerously-skip-permissions` only within allowlists.
- Use the **one-shot PRD** (Section 3) as the validation standard:
  - Jarvis executes end-to-end with minimal human intervention
  - safety constraints satisfied (no ops outside allowlisted paths)
  - audit log shows full traceability

Deliverables:
- “Autonomy policy” doc + enforcement plan.
- “One-shot PRD runbook” (how to run, what success looks like).

Validation:
- Successful run of Demo A (Section 6) becomes required evidence for PR-11 readiness.

---

### PR-12: Self-Evolution Loop (Reflect → Propose → Validate → Version → Push)
**Goal:** Jarvis improves itself without drifting into bloat.

Requirements:
- Add hooks/patterns for reflection:
  - capture blockers and inefficiencies per session
  - propose code/doc changes (diff + rationale + risk)
  - require review gates for destructive/systemwide changes
- Tie proposals to benchmark outcomes:
  - do not ship regressions without explicit user approval
- Implement version bump + release note automation aligned with PR-1.

Validation:
- Demonstrate one full loop on a small, safe change:
  - reflection → proposal → benchmark check → version bump → push.

---

### PR-13: Benchmark Demos & Scoring (Regression Gates)
**Goal:** Make evolution measurable and repeatable.

Requirements:
- Define 2–3 end-to-end demos with:
  - success criteria
  - metrics
  - artifacts and report outputs
- One demo MUST be full product delivery from the one-shot PRD:
  - create new GitHub repo under CannonCoPilot
  - implement a trivial but complete tool with a small web GUI
  - tests/validation
  - push repo and generate report

Deliverables:
- A benchmark runner doc/runbook.
- A report format template and storage location.

---

### PR-14: Research & Comparative Analysis (SOTA Projects) + Adopt/Adapt/Reject
**Goal:** Incorporate best ideas while avoiding bloat.

Requirements:
- Maintain curated references and periodically compare Jarvis patterns to the SOTA list (Section 4).
- For each comparison cycle:
  - propose “adopt/adapt/reject” items with rationale and risk
  - ensure changes map back to benchmarks and do not introduce redundancy

Validation:
- Each cycle produces a dated report with explicit decisions and follow-up PR references.

---

## 3) One-shot PRD (Minimal End-to-End Deliverable Spec)

**Intent:** Provide a *very simple, deterministic product specification* that can be executed end-to-end to evaluate Jarvis autonomy.

> Reminder: the one-shot PRD is a Jarvis artifact. It must not be placed into or modify the AIfred baseline repo.

### One-shot PRD: “Aion Hello Console” (baseline)
A minimal web app with a tiny GUI and trivial functionality, designed to validate:
- repo creation
- scaffolding
- coding + tests
- documentation
- packaging/running
- pushing to GitHub

#### Requirements
- Web UI:
  - a single page
  - a text input
  - a button
  - an output area showing transformed text (slugify, reverse, uppercase, etc.)
- Backend endpoint:
  - receives text
  - returns transformed text + timestamp
- Tests:
  - unit test for transform function
  - basic integration test for endpoint
- Docs:
  - README: setup, run, test
  - architecture notes (short)
- Delivery:
  - create repo under `CannonCoPilot/` (name includes timestamp or version)
  - push main branch
  - tag release or add release notes file
  - generate a “run report” artifact in Jarvis summaries directory:  
    `/Users/aircannon/Claude/Jarvis/projects/`

#### Technology constraints (choose one, document choice)
- Option A: Node + Express + Vite + Playwright
- Option B: Python + FastAPI + minimal frontend
- Option C: simplest viable stack given toolchain + validation

---

## 4) Backlog (Organized) — With URLs

> Note: MCPs are installed piecemeal. **Stage 1** is the minimal default set.

### 4.1 Stage 1 Default MCPs (Install First)
- Memory Knowledge Graph (MCP)  
  https://github.com/modelcontextprotocol/servers/tree/main/src/memory
- Sequential Thinking (capability requirement; source/integration TBD—document what you choose)  
  *(If you select a specific implementation, add its URL here.)*
- Time / Fetch / Filesystem (core MCP servers)  
  https://github.com/modelcontextprotocol/servers/tree/main
- Context7  
  https://github.com/upstash/context7
- GitHub MCP  
  https://github.com/github/github-mcp-server
- DuckDuckGo MCP  
  https://github.com/nickclyde/duckduckgo-mcp-server
- Playwright MCP  
  https://github.com/microsoft/playwright-mcp

### 4.2 Memory / Thought (Additional)
- Graphiti MCP  
  https://github.com/getzep/graphiti/blob/main/mcp_server  
  Graphiti docs/framework: https://github.com/getzep/graphiti/tree/main
- Cognee MCP  
  https://github.com/topoteretes/cognee/tree/main/cognee-mcp
- Lotus Wisdom MCP  
  https://github.com/linxule/lotus-wisdom-mcp

### 4.3 System / Web Autonomy (Additional)
- DateTime MCP  
  https://github.com/pinkpixel-dev/datetime-mcp
- DesktopCommander MCP  
  https://github.com/wonderwhy-er/DesktopCommanderMCP
- Brave Search MCP  
  https://github.com/brave/brave-search-mcp-server
- Puppeteer MCP (archived + alternative)
  - archived: https://github.com/modelcontextprotocol/servers-archived/tree/main/src/puppeteer
  - alternative: https://github.com/merajmehrabi/puppeteer-mcp-server

### 4.4 Dev / Code (Additional)
- Semgrep MCP docs  
  https://semgrep.dev/docs/mcp
- Notion MCP  
  https://github.com/awkoy/notion-mcp-server
- Obsidian MCP  
  https://github.com/iansinnott/obsidian-claude-code-mcp
- TaskMaster  
  https://github.com/eyaltoledano/claude-task-master
- n8n MCP  
  https://github.com/czlonkowski/n8n-mcp
- Repomix  
  https://github.com/yamadashy/repomix

### 4.5 Information / Grounding
- Wikipedia MCP  
  https://github.com/rudra-ravi/wikipedia-mcp
- GPTresearcher MCP  
  https://github.com/assafelovic/gptr-mcp
- Perplexity MCP  
  https://github.com/perplexityai/modelcontextprotocol
- arXiv MCP  
  https://github.com/blazickjp/arxiv-mcp-server

### 4.6 UI Dev
- Chrome DevTools MCP  
  https://github.com/ChromeDevTools/chrome-devtools-mcp/
- BrowserStack MCP  
  https://github.com/browserstack/mcp-server
- MagicUI MCP  
  https://github.com/magicuidesign/mcp

### 4.7 Comms
- Slack MCP docs  
  https://docs.slack.dev/ai/mcp-server/

### 4.8 DBs
- MongoDB MCP
  https://github.com/mongodb-js/mongodb-mcp-server
- Supabase MCP
  https://github.com/supabase-community/supabase-mcp
- SQLite bun MCP
  https://github.com/jacksteamdev/mcp-sqlite-bun-server
- MindsDB MCP
  https://github.com/mindsdb/minds-mcp
- Chroma
  https://github.com/chroma-core/chroma
- Alpha Vantage MCP
  https://github.com/alphavantage/alpha_vantage_mcp
- PostgreSQL MCP
  https://github.com/modelcontextprotocol/servers/tree/main/src/postgres
- MySQL MCP
  https://github.com/benborber/mysql-mcp-server

### 4.9 Docs
- Markdownify MCP  
  https://github.com/zcaceres/markdownify-mcp
- Google Drive MCP (deferred: billing decision)
  - archived: https://github.com/modelcontextprotocol/servers-archived/tree/main/src/gdrive
  - alternative: https://github.com/piotr-agier/google-drive-mcp
- Google Maps MCP (deferred: billing decision)
  https://github.com/modelcontextprotocol/servers-archived/tree/main/src/google-maps

### 4.10 Skills (Official + Unofficial)
- Anthropic skills (official)  
  https://github.com/anthropics/skills
- ComposioHQ awesome skills  
  https://github.com/ComposioHQ/awesome-claude-skills
- tapestry skills  
  https://github.com/michalparkola/tapestry-skills-for-claude-code
- markdown-to-epub  
  https://github.com/smerchek/claude-epub-skill
- csv summarizer  
  https://github.com/coffeefuelbump/csv-data-summarizer-claude-skill
- developer-growth-analysis (priority)  
  https://github.com/ComposioHQ/awesome-claude-skills/tree/master/developer-growth-analysis

### 4.11 Claude Code Plugins
- Official plugins docs  
  https://github.com/anthropics/claude-code/blob/main/plugins/README.md
- Orchestration/automation collection  
  https://github.com/wshobson/agents

### 4.12 Output Styles & Extra Agent Collections (References)
- Output styles  
  https://github.com/hesreallyhim/awesome-claude-code-output-styles-that-i-really-like
- More agents list  
  https://github.com/hesreallyhim/a-list-of-claude-code-agents
- Tips & best practices  
  https://github.com/hesreallyhim/awesome-claude-code

### 4.13 General Agent Framework References
- MetaGPT docs  
  https://github.com/geekan/MetaGPT-docs/tree/main/src/en/guide
- MetaGPT implementation  
  https://github.com/FoundationAgents/MetaGPT/tree/main/metagpt
- Agno  
  https://github.com/agno-agi/agno/tree/main  
  Docs: https://docs.agno.com/introduction
- LangGraph docs  
  https://github.com/langchain-ai/langgraph/tree/main/docs/docs
- DeepAgents (LangChain)  
  https://github.com/langchain-ai/deepagents/blob/master/libs/deepagents/README.md  
  CLI: https://github.com/langchain-ai/deepagents/blob/master/libs/deepagents-cli/README.md

### 4.14 Comparative “Multi-agent / Mode Framework” References (SOTA)
- Roo Commander  
  https://github.com/jezweb/roo-commander
- rUvnet  
  https://github.com/ruvnet/rUv-dev
- Claude Flow  
  https://github.com/ruvnet/claude-flow
- Symphony  
  https://github.com/sincover/Symphony
- Maestro  
  https://github.com/pedramamini/Maestro
- Serena  
  https://github.com/oraios/serena
- CCswarm  
  https://github.com/nwiizo/ccswarm
- Custom Modes (Roo Code)  
  https://github.com/jtgsystems/Custom-Modes-Roo-Code
- Multi-Agent Squad  
  https://github.com/bijutharakan/multi-agent-squad
- Agentwise  
  https://github.com/VibeCodingWithPhil/agentwise
- Agentic Cursor Rules  
  https://github.com/s-smits/agentic-cursorrules
- Hephaestus  
  https://github.com/Ido-Levi/Hephaestus
- EvoAgentX  
  https://github.com/EvoAgentX/EvoAgentX
- EquilateralAgents  
  https://github.com/Equilateral-AI/equilateral-agents-open-core
- Claude Code Plugins: orchestration and automation (collection)  
  https://github.com/wshobson/agents
- Examples of agent swarms:
  - AutoHedge https://github.com/The-Swarm-Corporation/AutoHedge
  - AI-CoScientist https://github.com/The-Swarm-Corporation/AI-CoScientist

---

## 5) Refactored Detailed Roadmap (Aligned to PR Order)

> This roadmap intentionally builds **foundation → workspace discipline → upstream sync → setup → tools** before pushing autonomy and self-evolution.
> **AIfred baseline remains read-only throughout.** The baseline is used only as an upstream mirror for diff/analysis and pull-only updates.

### Version Milestones

Version bumps are tied to PR/phase completion per [versioning-policy.md](./docs/project-aion/versioning-policy.md):

| Milestone | Version | Trigger |
|-----------|---------|---------|
| PR-1 Complete | **1.0.0** ✅ | Initial release |
| PR-2 Complete | **1.1.0** | Workspace & summaries |
| PR-3 Complete | **1.2.0** | Upstream sync |
| PR-4 Complete | **1.3.0** | Setup preflight |
| Phase 5 Complete (PR-5→10) | **2.0.0** | Tooling baseline |
| Phase 6 Complete (PR-11→14) | **3.0.0** | Autonomous operation |

**Bump Rules**:
- **PATCH** (x.x.+1): Validation tests, benchmarks, documentation
- **MINOR** (x.+1.0): PR completion
- **MAJOR** (+1.0.0): Phase completion (PR-10, PR-14)

---

### Phase 1 — Identity, Baseline Discipline, and Doc Hygiene (PR-1)

**Target Version**: 1.0.0 ✅ Complete

Deliverables:
- Jarvis Archon identity and divergence from AIfred baseline clarified in Jarvis docs.
- Versioning and release note conventions established (including secondary archon "created using Jarvis version x.x.x" rule).
- Session-start pattern: always check/pull baseline updates into `/Users/aircannon/Claude/AIfred`.
- Workspace rule clarifying:
  - normal projects live in `/Users/aircannon/Claude/<ProjectName>/`
  - Project Aion docs live in `/Users/aircannon/Claude/Jarvis/docs/project-aion`
- Archive obsolete `docs/PROJECT-PLAN.md` into `docs/archive/` with an archive log entry.

Acceptance:
- A newcomer can read Jarvis docs and understand: Jarvis vs baseline, and how updates flow without modifying baseline.
- A PR-1 checklist exists and is followed.

---

### Phase 2 — Workspace Discipline & Project Summaries + One-shot PRD Doc (PR-2)

**Target Version**: 1.1.0

Deliverables:
- Canonical project location rules implemented and documented.
- Project summary template created and stored in Jarvis defaults.
- One-shot PRD document added as a default artifact.

Acceptance:
- Jarvis can deterministically decide where project code lives and where summaries go.
- One-shot PRD exists and is ready for later use as an autonomy benchmark.

---

### Phase 3 — Controlled Upstream Porting (PR-3)

**Target Version**: 1.2.0

Deliverables:
- `/sync-aifred-baseline` (or equivalent) produces:
  - diff report
  - adopt/adapt/reject suggestions
  - optional patch set staged for review (Jarvis-only)

Acceptance:
- Sync produces a structured report without applying changes silently and without editing baseline.

---

### Phase 4 — Setup v1: Preflight + Guardrails (PR-4)

**Target Version**: 1.3.0

Deliverables:
- `/setup` can run in a fresh environment and produce a readiness report.
- Guardrailed permission model for allowlisted paths.
- Guidance for debug/verbose operation.
- Explicit reminder: baseline is read-only.

Acceptance:
- Setup ends with actionable pass/fail checks and no ambiguous states.

---

### Phase 5 — Tooling Baseline & Incremental Expansion (PR-5 → PR-10)

**Target Version**: 2.0.0 (MAJOR — Tooling Complete)

| PR | Description | Version | Status |
|----|-------------|---------|--------|
| PR-5 | Core Tooling Baseline | 1.5.0 | ✅ Complete |
| PR-6 | Plugins Expansion | 1.6.0 | ✅ Complete |
| PR-7 | Skills Inventory | 1.7.0 | ✅ Complete |
| PR-8 | MCP Expansion + Context Budget | 1.8.2 | ✅ Complete |
| PR-8.5 | MCP Expansion — Batch Install | **1.8.3** | ✅ Complete (10 MCPs validated) |
| PR-9 | Selection Intelligence | **1.9.5** | ✅ **Complete** (PR-9.0-9.5 all done) |
| PR-10 | Setup Upgrade | **2.0.0** | ⏳ Pending |

Deliverables:
- PR-5: Core Tooling baseline enabled + validated + overlap matrix started.
- PR-6: Plugins expanded with adopt/adapt/reject decisions + conflicts resolved.
- PR-7: Skills cataloged and selection rules written.
- PR-8: Context budget optimization + MCP loading tiers + validation harness.
- PR-8.5: MCP expansion (10 MCPs validated: Perplexity, Playwright, GPTresearcher, DateTime, DesktopCommander, Lotus Wisdom, Wikipedia, Chroma, Brave Search, arXiv).
- PR-9: Selection Intelligence formalized based on real overlaps.
- PR-10: Setup upgraded to automate baseline installs and validations.

Acceptance:
- Capability matrix is accurate and used.
- Redundant/conflicting tools are either removed or rule-governed.
- Setup can reach a stable "baseline-ready" state reproducibly.

---

### Phase 6 — Autonomy, Self-Evolution, Benchmark Gates, SOTA Comparison (PR-11 → PR-14)

**Target Version**: 3.0.0 (MAJOR — Autonomous Operation)

| PR | Description | Version |
|----|-------------|---------|
| PR-11 | Autonomy & Permission Reduction | 2.1.0 |
| PR-12 | Self-Evolution Loop | 2.2.0 |
| PR-13 | Benchmark Demos | 2.3.0 |
| PR-14 | SOTA Research & Comparison | **3.0.0** |

Deliverables:
- PR-11: Autonomy policy + one-shot PRD runbook + scoped permissions.
- PR-12: Self-evolution loop established with review gates.
- PR-13: Benchmark demos + scoring + report outputs (including full PRD-based product delivery and repo push).
- PR-14: Regular SOTA comparison reports with adopt/adapt/reject pipeline.

Acceptance:
- Jarvis can execute the one-shot PRD end-to-end safely, with auditable traces.
- Improvements are measurable and regressions detectable.

---

## 6) Benchmark Demos (Revised)

### Demo A — End-to-End Product Delivery (Primary Autonomy Benchmark)
Purpose: Validate Jarvis can turn the predefined one-shot PRD into a shippable product with minimal supervision.

Input:
- The **one-shot PRD** document (Section 3).

Required output:
- A new GitHub repository under **CannonCoPilot**.
- A working trivial app with a small web GUI and backend endpoint.
- Tests passing.
- README with run/test instructions.
- A run report saved to `/Users/aircannon/Claude/Jarvis/projects/`.

Success criteria:
- No operations outside allowlisted paths.
- Full audit log trace.
- Reproducible run steps.

### Demo B — Infrastructure Discovery + Automation
- Discover a Docker service stack, auto-document it, add a health check and an automation hook.
- Produce a structured report and verify changes.

### Demo C — Research → Decision → Implementation (Grounded)
- Use citations to choose a component (e.g., vector store), record decision, implement minimal config + validation.

---

## 7) Implementation Notes for Claude Code Agent (Execution Rules)

- Apply PARC before significant changes.
- Prefer deterministic scripts/tests for MCP validation.
- Never add tools without:
  - explicit use-case
  - overlap assessment
  - selection rule
  - test/validation
- Treat docs as first-class artifacts: update during work, not after.
- **Do not edit AIfred baseline repo.** Use it only as a read-only upstream mirror for diff/analysis and pull-only updates into `/Users/aircannon/Claude/AIfred`.

---

## 8) Open Questions (These are questions Jarvis should ask at the appropriate times)
Jarvis should ask these questions **when it reaches the relevant implementation phase**, not all at once.

Workspace & repo ownership:
- Confirm canonical paths:
  - `projects_root` = `/Users/aircannon/Claude`
  - Jarvis summaries dir = `/Users/aircannon/Claude/Jarvis/projects`
  - Project Aion docs dir = `/Users/aircannon/Claude/Jarvis/docs/project-aion`
- Confirm repository strategy:
  - Jarvis as a branch in `davidmoneil/AIfred` OR
  - Jarvis as a fork under `CannonCoPilot/AIfred`

Tooling defaults:
- Which MCPs are always-on vs on-demand initially (beyond Stage 1)?
- Are BraveSearch and Perplexity keys already configured as env vars?
- Preferred Node/Python versions and package managers?

Jeeves (always-on) operational questions:
- Where should Jeeves cron job definitions live (Jarvis repo vs separate Jeeves repo)?
- What schedule and channels are desired for reminders (terminal, notifications, Slack, email, etc.)?
- What data sources are allowed (calendar provider, local files, Notion, etc.)?

Autonomy guardrails:
- What operations are disallowed even inside allowlists (e.g., mass deletes, force pushes)?
- Should “unsafe” actions require a second confirmation step even in unsupervised mode?

Benchmarks:
- Which tech stack should the one-shot PRD use (FastAPI vs Node stack)?
- Preferred naming convention for demo repos under CannonCoPilot?

---

## 9) Immediate Next Step (Agent Prompt — Updated)

Copy/paste this into Claude Code to start:

> **Task:** Implement Phase 1–2 (PR-1 and PR-2).  
> **Requirements:**  
> 1) Execute the PR-1 mandatory first step: update the local AIfred baseline mirror at `/Users/aircannon/Claude/AIfred` via `git pull` (or fetch+pull).  
> 2) Update **Jarvis-only** documentation to use **Project Aion** and the **Archon** terminology (Jarvis master, Jeeves always-on, Wallace creative).  
> 3) Add a versioning + release-notes convention (including “created using Jarvis version x.x.x” for secondary archons).  
> 4) Implement and document the workspace path policy, including the special-case location for Project Aion docs: `/Users/aircannon/Claude/Jarvis/docs/project-aion`.  
> 5) Archive `/Users/aircannon/Claude/Jarvis/docs/PROJECT-PLAN.md` into `/Users/aircannon/Claude/Jarvis/docs/archive/` and add an entry to an archive log file.  
> 6) Add the default **one-shot PRD** document template (do not implement the demo app yet).  
> **Constraints:**  
> - **Do not modify the AIfred baseline repo** in any way beyond Git pull/fetch. No edits, commits, branches, hooks, or config changes.  
> - Do not add new MCP installs or plugins yet; this phase is documentation + scaffolding only.  
> **Output:**  
> - Commit-ready doc changes + short summary of what remains for PR-3 and PR-4.

---

## 10) Future Work / Brainstorms (De-scoped for Now)

### PR-15: Toolset Expansion Automation (Proposed)

**Goal**: Automate the discovery, evaluation, and integration of new tools.

**Design Document**: `projects/project-aion/ideas/toolset-expansion-automation.md`

**Phases**:
- PR-15a: Repository catalog system (`~/Claude/GitRepos/`)
- PR-15b: Deep review workflow with structured analysis
- PR-15c: Auto-integration with existing templates
- PR-15d: Self-directed discovery (pattern detection)

**Reference Repositories** (to be reviewed):
- Claude Code enhancement: superpowers, claude-code-templates, SuperClaude_Framework
- Testing: tdd-guard
- Multi-agent: Roo Commander, rUvnet, Claude-Flow, Symphony, Maestro
- Sessions: cc-sessions, ccusage
- Infrastructure: ccflare, ccpm

**Dependencies**: PR-6 (complete), PR-7 (in progress), workflow templates (created)

---

### Copilot Pro / RooCode Model Routing

- **Copilot Pro / RooCode model routing feasibility**
  - Roo-Code: https://github.com/RooCodeInc/Roo-Code
  - Explore whether an MCP/tool could route prompts through Copilot Pro models
  - Produce a feasibility report and architecture proposal only (no premature build)
