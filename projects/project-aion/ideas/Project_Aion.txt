# Project Aion — Jarvis (AIfred “Archon”) Feature Request & Development Roadmap
*Current date: 2026-01-05*  
*Target environment: Claude Code (primary) + OpenCode (secondary)*  
*Baseline reference (vanilla template, upstream-only): **AIfred mainline by David O’Neil** (“AIfred baseline”)*  
*Project Aion Archons: **Jarvis**, **Jeeves**, **Wallace** (and future Archons as needed)*  

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
- Do not rename or rewrite AIfred baseline terminology/docs to “Project Aion” terminology. (Project Aion terminology applies only to Jarvis/Archon repos.)
- Storing secrets/credentials in repo, context, or memory.
- Auto-merging from upstream without review (Jarvis is a divergent track).
- Building a full orchestration framework from scratch if Claude Code primitives + hooks + agents suffice.
- Automated decisions that require billing/ownership choices (e.g., Google APIs); these remain user-gated.
- “Unlimited autonomy everywhere” — autonomy must be **scoped** and **audited**.

---

## 2) Prioritized Product Requirements (PRs) — Renumbered Sequentially

> **Important:** Each PR that adds new capabilities MUST include:
> 1) **Overlap & conflict analysis** (redundancy, functional overlaps, conflicting behaviors)  
> 2) **Selection rules** (what is primary vs fallback, when to use which)  
> 3) **Validation** (smoke tests / health checks / demo outcomes)

### PR-1: Archon Identity + Branching Model + Versioning
- Adopt **Archon** terminology for Project Aion and define core Archons:
  - **Jarvis** = master Archon for dev + infrastructure + building other Archons
  - **Jeeves** = **always-on** Archon triggered by cron jobs for personal automation (calendar reminders, daily encouragement, scripture/thoughts, productivity/fun ideas, etc.)
  - **Wallace** = creative writer Archon (concept stage)
- Clarify relationship to upstream:
  - derived from AIfred baseline (David O’Neil)
  - divergent development track; not intended to merge back
  - **AIfred baseline is read-only; never edit it**
- Versioning policy:
  - normal pushes bump **0.1**
  - benchmark/test report pushes bump **x.x.1**
- Establish changelog / release note convention. Secondary Archons like Jeeves and Wallace should include a "created using Jarvis version x.x.x" so that versioning is pinned to the Jarvis versions, as well as reflects each other Archon's own respective version.  Jarvis should reference the most current version of AIfred as its source, within its documentation.

---

### PR-2: Workspace & Project Location Policy + Project Summaries
**Goal:** Make Jarvis a hub with deterministic, user-approved workspace boundaries.

Requirements:
- Confirm and implement:
  - projects live in: `/Users/aircannon/Claude/<ProjectName>/`
  - Jarvis project summaries live in: `/Users/aircannon/Claude/Jarvis/projects/`
- Ensure “Hub, Not Container” remains true: Jarvis tracks/works on projects stored elsewhere.
- Improve/extend project registration behavior (hook- or command-driven):
  - detect GitHub URLs and “new project” requests
  - register project path + create context summary doc
  - maintain a registry (e.g., `paths-registry.yaml` or Jarvis equivalent)

Deliverables:
- A standardized “Project Summary” template.
- A deterministic directory policy section in docs.
- Optional: a `/register-project` and `/create-project` refinement plan.

**Addendum (required for later PR-8/PR-9):** Design and create the **one-shot PRD** document (see Section 3) as a default artifact stored in Jarvis.

---

### PR-3: Upstream Sync Workflow (AIfred baseline → Jarvis Controlled Porting)
**Goal:** Keep Jarvis modern without destabilizing its divergent track.

Requirements:
1. Pull AIfred baseline main into `/Users/aircannon/Claude/AIfred` (canonical local upstream mirror).
2. Compute diff vs Jarvis.
3. Classify changes: safe / unsafe / manual review.
4. Propose ports and apply only after review (**to Jarvis repo only**).
5. Maintain a port log (“adopt/adapt/reject” with rationale).

Deliverables:
- A repeatable workflow or command (e.g., `/sync-aifred-baseline`) that generates a structured report.
- A standing reminder in docs/scripts: **AIfred baseline is read-only; never edit it**.

---

### PR-4: Setup Preflight + Environment + Guardrailed Permissions (v1)
**Goal:** `/setup` becomes a real “preflight + configure + verify” wizard (before heavy tooling expansion).

Requirements:
- Add a “Prereqs & Environment” stage:
  - OS checks
  - guided manual installs where required
  - venv creation + dependency installation
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

---

### PR-8: MCP Expansion + Validation Harness (Install Piecemeal)
**Goal:** Expand MCP servers gradually, with tests and dependency-driven installs.

Requirements:
- Define MCP tiers:
  - **Stage 1 default MCPs (install early):**
    - Memory Knowledge Graph  
      https://github.com/modelcontextprotocol/servers/tree/main/src/memory
    - Sequential Thinking (capability requirement; source/integration TBD—document what you choose)  
      (If you select a specific implementation, add its URL.)
    - Time / Fetch / Filesystem (core MCP servers)  
      https://github.com/modelcontextprotocol/servers/tree/main
    - Context7  
      https://github.com/upstash/context7
    - GitHub Official MCP  
      https://github.com/github/github-mcp-server
    - DuckDuckGo MCP  
      https://github.com/nickclyde/duckduckgo-mcp-server
    - Playwright MCP  
      https://github.com/microsoft/playwright-mcp
- For each MCP:
  - install procedure (automated if possible, otherwise gated manual steps)
  - configuration requirements and env vars
  - **validation**: health + basic tool invocation + expected response contract
  - overlap analysis vs skills/plugins/other MCPs
- Add dependency-triggered installs:
  - when a workflow/agent depends on an MCP, Jarvis recommends enabling/installing it.

---

### PR-9: “Selection Intelligence” Pattern (MCP vs Skill vs Plugin vs Agent vs Bash)
**Goal:** Ensure Jarvis reliably chooses the right mechanism for the job.

Requirements:
- A documented decision framework and quick reference:
  - when to use custom agent vs Claude subagent vs plugin vs skill vs MCP vs Bash
- Conflict resolution rules:
  - if two tools do the same thing, define primary + fallback
- Include examples tied to real workflows:
  - research tasks, repo exploration, code generation, web automation, file operations

Deliverables:
- `agent-selection-pattern.md` v2 (or equivalent) + capability matrix updates.

---

### PR-10: Setup Upgrade (Auto-installs + Optional Approvals)
**Goal:** Revisit `/setup` after tools exist to automate more installs safely.

Requirements:
- Plugins and skills likely default-required: enable/install by default where feasible.
- MCP installs:
  - auto-install Stage 1 defaults
  - additional MCPs suggested and user-approved (optional), often dependency-driven
- Setup re-runs validations and produces pass/fail readiness outputs.
- Include guardrail reminders: **AIfred baseline is read-only**.

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

---

### PR-14: Research & Comparative Analysis (SOTA Projects) + Adopt/Adapt/Reject
**Goal:** Incorporate best ideas while avoiding bloat.

Requirements:
- Maintain curated references and periodically compare Jarvis patterns to the SOTA list (Section 4).
- For each comparison cycle:
  - propose “adopt/adapt/reject” items with rationale and risk
  - ensure changes map back to benchmarks and do not introduce redundancy

---

## 3) One-shot PRD (Minimal End-to-End Deliverable Spec)
*(unchanged; see prior content in this file)*

## 4) Backlog (Organized) — With URLs
*(unchanged; see prior content in this file)*

## 5) Refactored Detailed Roadmap (Aligned to PR Order)
*(unchanged; PR numbering remains consistent)*

## 6) Benchmark Demos (Revised)
*(unchanged; see prior content in this file)*

## 7) Implementation Notes for Claude Code Agent (Execution Rules)
*(unchanged; see prior content in this file)*

## 8) Open Questions (These are questions Jarvis should ask at the appropriate times)
*(unchanged; see prior content in this file)*

## 9) Immediate Next Step (Agent Prompt — Updated for Baseline Read-only Rule)
*(unchanged; see prior content in this file)*

## 10) Future Work / Brainstorms (De-scoped for Now)
*(unchanged; see prior content in this file)*
