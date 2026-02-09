# Tool Selection Intelligence Pattern

**Version**: 0.7
**Created**: 2026-01-09
**PR Reference**: PR-9 (Selection Intelligence)
**Status**: Draft — Pending Review
**Research Sources**: Anthropic Agent Skills, LangChain Deep Agents, MCP Architecture

---

## Overview

This pattern establishes the theoretical foundation and practical framework for **tool selection intelligence** in Jarvis. It addresses:

1. **Tool Modality Precedence** — When to use which type of tool
2. **Progressive Disclosure Architecture** — Token-efficient skill/tool loading
3. **Component Extraction Workflow** — Decomposing plugins into granular components
4. **Selection Quality Metrics** — Measuring and improving selection accuracy

---

## Part 1: Tool Modality Theory

### The Three-Layer Model

Modern agentic systems separate capabilities into **three** fundamental layers. The Knowledge and Integration layers (from industry research) are supplemented by a **Local Tooling Layer** specific to Jarvis:

```
┌─────────────────────────────────────────────────────────────────────┐
│                       KNOWLEDGE LAYER                                │
│  (HOW to do things — procedural expertise, workflows, patterns)      │
│                                                                      │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐  ┌────────────┐    │
│  │   Skills   │  │   Agents   │  │  Patterns  │  │  Prompts   │    │
│  │ (SKILL.md) │  │ (personas) │  │  (guides)  │  │ (context)  │    │
│  └────────────┘  └────────────┘  └────────────┘  └────────────┘    │
└─────────────────────────────────────────────────────────────────────┘
                              ▲
                              │ "Skills teach agents how to
                              │  use abilities well"
                              ▼
┌─────────────────────────────────────────────────────────────────────┐
│                     INTEGRATION LAYER                                │
│  (WHAT can be done — capabilities, access, execution)                │
│                                                                      │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐  ┌────────────┐    │
│  │    MCPs    │  │  Plugins   │  │   Tools    │  │    Bash    │    │
│  │ (servers)  │  │ (bundles)  │  │ (built-in) │  │ (shell)    │    │
│  └────────────┘  └────────────┘  └────────────┘  └────────────┘    │
└─────────────────────────────────────────────────────────────────────┘
                              ▲
                              │ Local automation & guardrails
                              ▼
┌─────────────────────────────────────────────────────────────────────┐
│                   LOCAL TOOLING LAYER                                │
│  (SYSTEM PLUMBING — automation, guardrails, session management)      │
│                                                                      │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐                     │
│  │  Scripts   │  │   Hooks    │  │  Commands  │                     │
│  │   (.sh)    │  │   (.js)    │  │   (.md)    │                     │
│  └────────────┘  └────────────┘  └────────────┘                     │
└─────────────────────────────────────────────────────────────────────┘
```

**Key Insight**: "MCP gives agents abilities. Skills teach agents how to use those abilities well. Teams that invest only in skills end up with agents that think brilliantly but can't actually do anything."

**Jarvis Extension**: Scripts, hooks, and commands provide **system plumbing** that powers session management, guardrails, and automation — invisible infrastructure that makes the upper layers work safely and efficiently.

### Tool Modality Characteristics

| Modality | Token Cost | Loading Strategy | Best For |
|----------|------------|------------------|----------|
| **Built-in Tools** | ~0 | Always available | Simple, single operations |
| **Skills** | 50-100 (summary) | Progressive disclosure | Procedural workflows |
| **Subagents** | Separate context | On-demand spawn | Exploration, planning, multi-step |
| **MCPs** | 500-8000+ | Tiered loading | External integrations |
| **Plugins** | Varies | Always-on or disabled | Multi-tool bundles |
| **Custom Agents** | Separate context | On-demand spawn | Domain expertise, structured workflows |
| **Scripts** | ~0 (output only) | On-demand via Bash | System automation |
| **Hooks** | ~0 (no schema) | Automatic (events) | Guardrails, observability |
| **Commands** | File size | On `/command` invocation | Multi-step procedures |

### The Orchestration Principle

**Jarvis is the Core Orchestration Agent** — fully capable of performing any operation, but strategically delegates when doing so optimizes for context value and efficiency.

The fundamental insight: **"If you want something done right, do it yourself"** — but only when the procedural context is worth retaining. The primary decision is not "which tool type?" but rather **"should I do this myself, or delegate?"**

```
OLD PARADIGM (Tool-First):
  Task → Which tool type? → Execute

NEW PARADIGM (Orchestration-First):
  Task → Delegate or Self-Execute? → [Context Selection] → Tool Selection
```

---

### The Delegation Decision Framework

Before selecting tools, Jarvis must answer the **delegation question**:

```
┌─────────────────────────────────────────────────────────────────┐
│                    DELEGATION DECISION                          │
│                                                                 │
│  PRIMARY QUESTION: Should Jarvis execute this himself,          │
│                    or delegate to an agent?                     │
│                                                                 │
│  The answer depends on THREE factors:                           │
│  1. Execution Difficulty (easy vs challenging)                  │
│  2. Context Bloat Risk (low vs high impact)                     │
│  3. Procedural Context Value (need to retain vs disposable)     │
└─────────────────────────────────────────────────────────────────┘
```

**The Context Value Matrix**:

| Difficulty | Context Bloat | Procedural Value | Decision |
|------------|---------------|------------------|----------|
| Easy | Low | Any | **SELF-EXECUTE** — Just do it |
| Easy | High | Low | **DELEGATE** — Isolate the bloat |
| Easy | High | High | **DELEGATE + SUMMARY** — Preserve insights |
| Challenging | Low | High | **SELF-EXECUTE** — Worth the complexity |
| Challenging | High | Low | **DELEGATE** — Offload entirely |
| Challenging | High | High | **DELEGATE + SUMMARY** — Best of both |

**Decision Flow**:

```
Task Received
     │
     ▼
┌─────────────────────────────────────────────────────────────────┐
│ Q1: Is this EASY and LOW CONTEXT IMPACT?                        │
│     (1-3 operations, known paths, minimal reasoning)            │
│                                                                 │
│     → YES: SELF-EXECUTE (Jarvis does it directly)               │
│            Proceed to Tool Selection Hierarchy                  │
└─────────────────────────────────────────────────────────────────┘
     │ NO (challenging OR high context impact)
     ▼
┌─────────────────────────────────────────────────────────────────┐
│ Q2: Does the PROCEDURAL CONTEXT have value for later?           │
│     (Will knowing HOW it was done matter for future tasks?)     │
│                                                                 │
│     → NO:  DELEGATE (agent executes, returns results only)      │
│     → YES: DELEGATE + SUMMARY RETURN                            │
│            (agent executes, returns results + action summary)   │
└─────────────────────────────────────────────────────────────────┘
     │
     ▼
┌─────────────────────────────────────────────────────────────────┐
│ Q3: What AGENT TIER is appropriate?                             │
│                                                                 │
│     • Simple task, quick result → SIMPLE SUBAGENT              │
│     • Domain expertise needed → CUSTOM AGENT                    │
│     • Complex multi-phase work → AGENT TEAM (Tier 3)            │
└─────────────────────────────────────────────────────────────────┘
```

---

### The Orchestration Tiers

Jarvis operates across a spectrum of orchestration sophistication — from simple self-execution to coordinating multi-agent teams:

```
JARVIS (Core Orchestrator)
│
│   Orchestration sophistication increases ↓
│
├─────────────────────────────────────────────────────────────────┐
│ TIER 1: SELF-EXECUTE OR SIMPLE DELEGATION                       │
│ ─────────────────────────────────────────                       │
│                                                                 │
│ Jarvis handles directly OR delegates to simple subagents:       │
│ • Explore, Plan, General-purpose                                │
│ • Quick, atomic tasks (1-3 operations)                          │
│ • Low context bloat, immediate results                          │
│ • Fixed tool sets                                               │
│                                                                 │
│ Examples:                                                       │
│ • Self: Read a file, edit a function, run a command             │
│ • Delegate: "Find auth files" → Explore subagent                │
│ • Delegate: "Plan this feature" → Plan subagent                 │
│                                                                 │
│ Return: Results only (minimal overhead)                         │
└─────────────────────────────────────────────────────────────────┘
│
├─────────────────────────────────────────────────────────────────┐
│ TIER 2: COMPLEX SINGLE-AGENT DELEGATION                         │
│ ───────────────────────────────────────                         │
│                                                                 │
│ Jarvis hands off to specialized agents for:                     │
│ • One-shot technical tasks                                      │
│ • Complex multi-step/multi-tool workflows                       │
│ • Domain expertise requirements                                 │
│                                                                 │
│ Agent Types:                                                    │
│ • Built-in: General-purpose (extended tasks)                    │
│ • Custom: docker-deployer, service-troubleshooter, deep-research│
│                                                                 │
│ Agent capabilities:                                             │
│ • Defined tool scopes (can be restricted or open)               │
│ • Structured workflows with phases                              │
│ • Progressive disclosure within their context                   │
│ • May call scripts, MCPs within their scope                     │
│                                                                 │
│ Examples:                                                       │
│ • "Deploy this Docker config" → docker-deployer                 │
│ • "Debug why the API is slow" → service-troubleshooter          │
│ • "Research caching strategies" → deep-research                 │
│                                                                 │
│ Return: Results + structured output (per agent design)          │
└─────────────────────────────────────────────────────────────────┘
│
├─────────────────────────────────────────────────────────────────┐
│ TIER 3: MULTI-AGENT ORCHESTRATION                               │
│ ─────────────────────────────────                               │
│                                                                 │
│ Jarvis coordinates MULTIPLE agents working together:            │
│ • Agent teams with defined roles                                │
│ • Sequential handoffs (Agent A → Agent B → Agent C)             │
│ • Feedback loops (Writer ↔ Reviewer)                            │
│ • Parallel execution with aggregation                           │
│                                                                 │
│ Jarvis can:                                                     │
│ • CALL a known agent team workflow                              │
│ • CREATE an ad-hoc workflow for agents to follow                │
│                                                                 │
│ Jarvis defines for the team:                                    │
│ • Which agents participate                                      │
│ • Tool access (prescribed vs free selection)                    │
│ • Context management strategy                                   │
│ • Structured output formats                                     │
│ • Handoff/feedback protocols                                    │
│ • Termination conditions                                        │
│                                                                 │
│ Examples:                                                       │
│ • Code: writer-agent → reviewer-agent → writer-agent (iterate)  │
│ • Research: browser-agent → image-assessor (view & evaluate)    │
│ • Validation: implementer → tester → fixer (until passing)      │
│ • Analysis: gatherer → analyzer → reporter (pipeline)           │
│                                                                 │
│ Return: Aggregated results + team action summary                │
└─────────────────────────────────────────────────────────────────┘
```

---

### Multi-Agent Team Patterns

When Jarvis orchestrates at Tier 3, several coordination patterns are available:

**Pattern 1: Sequential Pipeline**
```
Jarvis orchestrates: Agent A → Agent B → Agent C

Example: Research Pipeline
┌────────────┐     ┌────────────┐     ┌────────────┐
│  Gatherer  │ ──→ │  Analyzer  │ ──→ │  Reporter  │
│  Agent     │     │  Agent     │     │  Agent     │
├────────────┤     ├────────────┤     ├────────────┤
│ Web search │     │ Synthesize │     │ Format     │
│ Collect    │     │ Validate   │     │ Cite       │
│ sources    │     │ Correlate  │     │ Present    │
└────────────┘     └────────────┘     └────────────┘
```

**Pattern 2: Feedback Loop**
```
Jarvis orchestrates: Agent A ↔ Agent B (iterate until condition)

Example: Code Review Loop
┌────────────┐           ┌────────────┐
│   Writer   │ ────────→ │  Reviewer  │
│   Agent    │           │   Agent    │
├────────────┤           ├────────────┤
│ Write code │           │ Review     │
│ Apply fixes│ ←──────── │ Find issues│
└────────────┘  feedback └────────────┘
        │
        ▼ (when approved)
    [Return to Jarvis]
```

**Pattern 3: Parallel with Aggregation**
```
Jarvis orchestrates: [Agents A, B, C] → Aggregator

Example: Multi-Source Research
              ┌────────────┐
          ┌──→│  Web Agent │──┐
          │   └────────────┘  │
┌────────┐│   ┌────────────┐  │  ┌────────────┐
│ Jarvis │├──→│ Docs Agent │──┼─→│ Aggregator │──→ [Results]
└────────┘│   └────────────┘  │  └────────────┘
          │   ┌────────────┐  │
          └──→│ Code Agent │──┘
              └────────────┘
```

**Pattern 4: Specialist Consultation**
```
Jarvis orchestrates: Primary Agent ──(consult)──→ Specialist

Example: Implementation with Security Check
┌────────────┐       ┌────────────┐
│ Implementer│──────→│  Security  │
│   Agent    │       │  Reviewer  │
├────────────┤       ├────────────┤
│ Write code │ query │ Check vuln │
│ Get advice │←──────│ Recommend  │
│ Apply      │       └────────────┘
└────────────┘
```

---

### Agent Team Configuration

When creating or calling an agent team, Jarvis specifies:

```yaml
# Agent Team Workflow Definition

team_name: "code-review-loop"
description: "Iterative code writing with review feedback"

agents:
  - name: writer
    type: custom  # or built-in
    tools: [Read, Write, Edit, Bash]
    instructions: |
      Write code according to the specification.
      Apply feedback from reviewer.
    output_format:
      code_files: [list of paths]
      changes_made: [list of changes]

  - name: reviewer
    type: custom
    tools: [Read, Grep, Glob]  # read-only
    instructions: |
      Review the code for quality, bugs, and style.
      Provide specific, actionable feedback.
    output_format:
      approved: boolean
      issues: [list of issues with file:line references]
      suggestions: [list of improvements]

workflow:
  type: feedback_loop
  sequence:
    - agent: writer
      input: specification
    - agent: reviewer
      input: writer.output
    - condition: reviewer.output.approved == false
      goto: writer
      with: reviewer.output.issues

  termination:
    - condition: reviewer.output.approved == true
    - condition: iterations > 3  # safety limit

  on_terminate:
    return:
      - writer.output.code_files
      - all_iterations_summary

context_management:
  shared_context: false  # each agent gets fresh context
  pass_between: results_only  # or full_context
  summary_required: true
```

---

### Orchestration Sophistication Spectrum

The key insight: Jarvis's role ranges from **executor** to **team manager**:

```
SIMPLE ◄─────────────────────────────────────────────────► COMPLEX

Do-It-Myself          Single-Agent            Multi-Agent Team
     │                  Handoff                  Orchestration
     │                     │                          │
     ▼                     ▼                          ▼
┌─────────┐          ┌─────────┐               ┌─────────────┐
│ Jarvis  │          │ Jarvis  │               │   Jarvis    │
│ executes│          │ spawns  │               │ coordinates │
│ directly│          │ agent   │               │ agent team  │
└─────────┘          └─────────┘               └─────────────┘
     │                     │                          │
   Tools              Agent uses               Team follows
   only               its tools               defined workflow
```

This is fundamentally about **Jarvis's orchestration capability**, not about different types of agents. The same agents can participate in Tier 2 (solo) or Tier 3 (team) scenarios — what changes is how Jarvis coordinates them.

---

### The Summary Return Pattern

When procedural context has value, agents should return not just results but a **summary of actions taken**:

```
RESULTS-ONLY RETURN (procedural context disposable):
─────────────────────────────────────────────────────
Agent: deep-research
Task: "Find best practices for Docker networking"

Return: {
  findings: [...],
  sources: [...]
}

// Jarvis knows WHAT was found, not HOW


SUMMARY RETURN (procedural context valuable):
─────────────────────────────────────────────
Agent: deep-research
Task: "Research Docker networking for our migration"

Return: {
  findings: [...],
  sources: [...],
  action_summary: {
    approach: "Started with official docs, expanded to community practices",
    sources_evaluated: 15,
    sources_used: 7,
    key_decisions: [
      "Focused on bridge networking (matches our setup)",
      "Excluded Kubernetes-specific patterns (out of scope)"
    ],
    duration: "~3 minutes",
    tools_used: ["brave-search", "gptresearcher", "perplexity"]
  }
}

// Jarvis knows WHAT was found AND HOW, enabling:
// - Progress tracking
// - Methodology documentation
// - Future task refinement
```

**When to Require Summary Return**:

| Scenario | Summary Required? | Reason |
|----------|-------------------|--------|
| One-off research | No | Results sufficient |
| Project milestone | Yes | Track progress, document approach |
| Debugging/troubleshooting | Yes | May need to revisit methodology |
| User-visible deliverable | Yes | Accountability, explainability |
| Repeated similar tasks | Yes (first time) | Establish pattern for future |

---

### Agent-Internal Progressive Disclosure

Complex agents (especially those in Tier 2/3 orchestrations) should implement **their own progressive disclosure** within their context:

```
MULTI-PHASE AGENT WORKFLOW EXAMPLE: Research Synthesis Agent
────────────────────────────────────────────────────────────

PHASE 1: Information Gathering
┌─────────────────────────────────────────────────────────────────┐
│ Load: brave-search MCP, gptresearcher MCP                       │
│ Execute: Web searches, deep research queries                    │
│ Accumulate: Raw findings in working memory                      │
│ Unload: Research MCPs (no longer needed)                        │
└─────────────────────────────────────────────────────────────────┘
                              ▼
PHASE 2: Analysis & Synthesis
┌─────────────────────────────────────────────────────────────────┐
│ Load: sequential-thinking MCP (if needed for complex reasoning) │
│ Execute: Pattern identification, cross-referencing              │
│ Accumulate: Structured findings                                 │
│ Unload: Analysis tools                                          │
└─────────────────────────────────────────────────────────────────┘
                              ▼
PHASE 3: Validation & Citation
┌─────────────────────────────────────────────────────────────────┐
│ Load: perplexity MCP (citation verification)                    │
│ Execute: Source verification, citation formatting               │
│ Accumulate: Validated, cited findings                           │
│ Unload: Citation tools                                          │
└─────────────────────────────────────────────────────────────────┘
                              ▼
PHASE 4: Output Composition
┌─────────────────────────────────────────────────────────────────┐
│ Load: (minimal tools, mostly reasoning)                         │
│ Execute: Compose final response with action summary             │
│ Return: Results + methodology summary to Jarvis                 │
└─────────────────────────────────────────────────────────────────┘

CONTEXT PROFILE:
• Peak tool load: 2-3 MCPs (never all at once)
• Total tools used: 5+ MCPs (progressively)
• Context preserved: Accumulated findings only
• Context discarded: Tool schemas between phases
```

**Agent Design Principle**: Design agents to **progressively load and unload** tools as their workflow progresses, never holding all tools in context simultaneously.

---

### The Complete Orchestration Hierarchy

With the delegation decision resolved, tool selection follows this hierarchy:

```
┌─────────────────────────────────────────────────────────────────┐
│                  ORCHESTRATION HIERARCHY                         │
│                                                                 │
│  STAGE 1: DELEGATION DECISION (see above)                        │
│           → Self-Execute OR Delegate                             │
│                                                                 │
│  STAGE 2: CONTEXT SELECTION                                      │
│           → Jarvis main context OR Agent isolated context        │
│                                                                 │
│  STAGE 3: TOOL SELECTION (within chosen context)                 │
│           → Follow Tool Precedence Hierarchy below               │
└─────────────────────────────────────────────────────────────────┘


STAGE 3: TOOL PRECEDENCE HIERARCHY
(Applied within whichever context is executing — Jarvis or Agent)

┌─────────────────────────────────────────────────────────────────┐
│ 1. BUILT-IN TOOLS (Zero Overhead)                               │
│    Can Read/Write/Edit/Glob/Grep/Bash accomplish this step?     │
│    → YES: Use built-in                                          │
└─────────────────────────────────────────────────────────────────┘
     │ NO
     ▼
┌─────────────────────────────────────────────────────────────────┐
│ 2. SKILLS (Minimal Overhead)                                    │
│    Does a skill exist for this workflow step?                   │
│    → YES: Invoke skill (progressive loading applies)            │
└─────────────────────────────────────────────────────────────────┘
     │ NO
     ▼
┌─────────────────────────────────────────────────────────────────┐
│ 3. SCRIPTS (System Automation)                                  │
│    Is this system-level automation (MCP management, versioning)?│
│    → YES: Execute script via Bash                               │
└─────────────────────────────────────────────────────────────────┘
     │ NO
     ▼
┌─────────────────────────────────────────────────────────────────┐
│ 4. MCPs (External Integration)                                  │
│    Need external system access?                                 │
│    → YES: Load appropriate MCP (tiered loading applies)         │
│    → After use: Consider unloading if workflow continues        │
└─────────────────────────────────────────────────────────────────┘
     │ NO
     ▼
┌─────────────────────────────────────────────────────────────────┐
│ 5. COMMANDS (Multi-Step Procedures)                             │
│    Is this a defined multi-step procedure?                      │
│    → YES: Invoke /command                                       │
└─────────────────────────────────────────────────────────────────┘


AGENT-ONLY OPTION (not available to Jarvis main context):
┌─────────────────────────────────────────────────────────────────┐
│ 6. SUB-DELEGATION (Context-Aware)                               │
│    Would a sub-agent handle this better?                        │
│    → Only if agent is designed for sub-delegation               │
│    → In agent teams, each agent has defined responsibilities    │
└─────────────────────────────────────────────────────────────────┘
```

---

### Selection Decision Factors (Revised)

| Factor | Weight | Description |
|--------|--------|-------------|
| **Context Value** | CRITICAL | Is procedural context worth retaining? |
| **Context Bloat Risk** | CRITICAL | Will this significantly expand context? |
| **Execution Difficulty** | HIGH | Easy tasks → self-execute; Hard tasks → evaluate delegation |
| **Token Cost** | HIGH | Lower overhead tools preferred |
| **Task Complexity** | HIGH | Match tool power to task scope |
| **Workflow Phase** | MEDIUM | Consider tool load/unload across phases |
| **Domain Expertise** | MEDIUM | Custom agents or agent teams for specialized domains |
| **External Access** | CONDITIONAL | MCPs only when integration needed |

---

### Practical Examples

**Example 1: Simple File Read (Self-Execute)**
```
Task: "Read the config file at /path/to/config.json"

Delegation Decision:
• Difficulty: Easy (single operation)
• Context Bloat: Low (one file)
• Procedural Value: None

Decision: SELF-EXECUTE
Tool: Read (built-in)
```

**Example 2: Codebase Exploration (Delegate)**
```
Task: "Find all files that handle authentication"

Delegation Decision:
• Difficulty: Moderate (multiple searches, reasoning)
• Context Bloat: HIGH (many file reads, grep results)
• Procedural Value: Low (just need the answer)

Decision: DELEGATE to Explore subagent
Return: File list only
```

**Example 3: Research for Project Decision (Delegate + Summary)**
```
Task: "Research caching strategies for our API redesign"

Delegation Decision:
• Difficulty: High (web research, synthesis)
• Context Bloat: VERY HIGH (multiple sources, reasoning)
• Procedural Value: HIGH (methodology informs future decisions)

Decision: DELEGATE to deep-research agent + SUMMARY RETURN
Return: Findings + action_summary (approach, sources, decisions)
```

**Example 4: Complex Multi-Phase Analysis (Agent Team)**
```
Task: "Analyze our codebase security posture and produce a report"

Delegation Decision:
• Difficulty: Very High (multi-phase, multiple tools)
• Context Bloat: EXTREME (code scanning, research, analysis)
• Procedural Value: HIGH (but too much to summarize briefly)

Decision: ORCHESTRATE via agent team (Tier 3)
Team Configuration:
• scanner-agent: Code scanning with SAST tools
• research-agent: Vulnerability research via security databases
• writer-agent: Report composition from findings
Workflow: Sequential pipeline (scanner → research → writer)
Return: Security report + aggregated action logs from all agents
```

---

## Part 2: Progressive Disclosure Architecture

### The Core Principle

**Progressive Disclosure** is the principle of loading information in layers — starting with minimal context that enables selection, then loading full details only when needed.

### The Universal Three-Tier Framework

A deeper insight: the Metadata → Core → Links pattern isn't just a technique for skills — it's a **universal information architecture** that improves selection and orchestration across ALL controllable modalities:

```
┌─────────────────────────────────────────────────────────────────┐
│  TIER 1: SELECTION METADATA                                      │
│  ──────────────────────────                                      │
│  Purpose: Enable correct selection decisions                     │
│                                                                  │
│  Contains:                                                       │
│  • What is it? (identity)                                        │
│  • When to use it? (triggers, conditions)                        │
│  • When NOT to use it? (anti-triggers, alternatives)             │
│  • What does it relate to? (complementary tools)                 │
│                                                                  │
│  Token cost: 50-100 per item (summaries only)                    │
└─────────────────────────────────────────────────────────────────┘
                              ▼
               (Selection decision made — load operational details)
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  TIER 2: OPERATIONAL CORE                                        │
│  ────────────────────────                                        │
│  Purpose: Enable correct execution                               │
│                                                                  │
│  Contains:                                                       │
│  • How to use it? (step-by-step workflow)                        │
│  • Parameters and configuration                                  │
│  • Constraints and guardrails                                    │
│  • Expected outputs                                              │
│                                                                  │
│  Token cost: 500-3,000 per item                                  │
└─────────────────────────────────────────────────────────────────┘
                              ▼
               (Execution requires deeper knowledge)
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  TIER 3: EXTENDED RESOURCES                                      │
│  ──────────────────────────                                      │
│  Purpose: Enable complex/edge-case handling                      │
│                                                                  │
│  Contains:                                                       │
│  • Deep reference materials                                      │
│  • Related tools, scripts, MCPs                                  │
│  • Templates and examples                                        │
│  • Troubleshooting guides                                        │
│                                                                  │
│  Token cost: Variable (loaded only when needed)                  │
└─────────────────────────────────────────────────────────────────┘
```

**Key Insight**: This framework applies not just to *what Claude Code loads*, but to *what Jarvis provides as guidance*. Even for modalities where Claude Code controls loading, Jarvis can add a **selection guidance layer** that improves orchestration decisions.

### The Token Efficiency Problem

**Discovery**: Tool schemas consume significant context:
- GitHub MCP: ~50,000 tokens for 90+ tools
- Desktop Commander: ~8,000 tokens for 30+ tools
- Simple prompts become 100K+ token sessions

**Goal**: Apply the three-tier framework across ALL modalities — either through loading control (where possible) or selection guidance (where loading is fixed).

---

### 2.1 Built-in Tools

**Current State**: Always loaded, full schemas in system prompt.

| Aspect | Value |
|--------|-------|
| Token Cost | ~0 (built into Claude Code) |
| Loading | Always present |
| Control | None for schemas; **YES for selection guidance** |

**Progressive Disclosure Applicability**: ⚠️ **Partially Applicable (Selection Guidance Layer)**

**Analysis**: Built-in tools (Read, Write, Edit, Glob, Grep, Bash, Task, etc.) are hardcoded into Claude Code's system prompt. Jarvis cannot control their loading, BUT can provide a **selection guidance layer** that influences when and how tools are chosen.

**The Selection Guidance Opportunity**:

Claude Code provides tool schemas. Jarvis can supplement with:

```
TIER 1: SELECTION METADATA (Jarvis provides)
─────────────────────────────────────────────
Purpose: Guide Jarvis toward correct built-in tool selection

Example guidance document (.claude/context/patterns/built-in-tool-selection.md):

## Read vs Glob vs Grep
- Read: Know exact file path → Read
- Glob: Know pattern, finding files → Glob
- Grep: Know content pattern, finding matches → Grep
- DON'T use Read to "explore" — use Explore subagent

## Edit vs Write
- Edit: Modifying existing content → Edit (safer, preserves context)
- Write: Creating new file OR complete replacement → Write
- DON'T use Write when Edit would work — loses undo context

## Bash vs Specialized Tools
- Git operations: Prefer Bash(git) commands — see `git-ops` skill (git MCP decomposed)
- File operations: Prefer Read/Write/Edit over cat/echo/sed — see `filesystem-ops` skill
- Web content: Prefer WebFetch/WebSearch — see `web-fetch` skill (fetch MCP decomposed)
- Bash: Reserved for actual terminal operations, builds, tests

## Task Tool Selection
- Explore: Finding files, understanding structure (read-only)
- Plan: Architecture decisions, needs user approval
- General-purpose: Multi-step implementation
- Custom agents: Domain expertise (see Part 7)
```

**Three-Tier Framework for Built-in Tools**:

| Tier | Claude Code Provides | Jarvis Can Add |
|------|---------------------|----------------|
| **Tier 1** | Tool name + description | Selection triggers, anti-patterns |
| **Tier 2** | Parameter schemas | Workflow guidance, examples |
| **Tier 3** | (none) | Links to related tools, MCPs, scripts |

**Jarvis Strategy**: Create `built-in-tool-selection.md` pattern document that provides selection metadata. Reference from CLAUDE.md or inject via session-start hook.

---

### 2.2 Skills

**Current State**: Progressive loading via Skill tool.

| Aspect | Value |
|--------|-------|
| Token Cost | 50-100 (summary) → 1-3K (full) |
| Loading | Progressive (summary → SKILL.md → resources) |
| Control | Full (skill design, layering) |

**Progressive Disclosure Applicability**: ✅ **Fully Applicable (Primary Example)**

**Three-Tier Skill Loading**:

```
┌─────────────────────────────────────────────────────────────────┐
│  TIER 1: METADATA (Always Loaded)                                │
│  ─────────────────────────────────                               │
│  • Skill name + one-line summary                                 │
│  • Token cost: 50-100 per skill                                  │
│  • Purpose: Enable LLM to decide relevance                       │
│                                                                  │
│  Example:                                                        │
│  name: "docx"                                                    │
│  summary: "Create and edit Microsoft Word documents"             │
└─────────────────────────────────────────────────────────────────┘
                              ▼
                     (Triggered by task context)
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  TIER 2: CORE DOCUMENTATION (Loaded When Triggered)              │
│  ─────────────────────────────────────────────────               │
│  • Full SKILL.md instructions                                    │
│  • Token cost: 1,000-3,000 per skill                             │
│  • Purpose: Provide procedural guidance                          │
│                                                                  │
│  Contains: Step-by-step workflow, examples, parameters           │
└─────────────────────────────────────────────────────────────────┘
                              ▼
                     (Accessed on-demand during execution)
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  TIER 3: LINKED RESOURCES (Loaded On Specific Need)              │
│  ─────────────────────────────────────────────────               │
│  • Reference files, templates, examples                          │
│  • Token cost: Variable                                          │
│  • Purpose: Deep technical details, edge cases                   │
│                                                                  │
│  Examples: docx-js.md, ooxml.md, template files                  │
└─────────────────────────────────────────────────────────────────┘
```

**Key Result**: "The amount of context that can be bundled into a skill is effectively unbounded" because only summaries load initially.

**Skill Design Guidelines**:
```
SKILL.md STRUCTURE FOR PROGRESSIVE DISCLOSURE:
├── Frontmatter (name, summary, triggers) — ALWAYS LOADED
├── Overview (when to use, capabilities) — TIER 2
├── Workflow (step-by-step procedure) — TIER 2
├── Parameters (detailed options) — TIER 2
├── Examples (common use cases) — TIER 2
└── @-linked resources (deep reference) — TIER 3 (on-demand)
```

---

### 2.3 Subagents (Built-in)

**Current State**: Descriptions in Task tool schema, spawned on-demand.

| Aspect | Value |
|--------|-------|
| Token Cost | ~500 (descriptions) + ~20K (spawn overhead) |
| Loading | Descriptions always, full context on spawn |
| Control | None for descriptions; **YES for orchestration guidance** |

**Progressive Disclosure Applicability**: ✅ **Applicable (Orchestration Metadata + Tool Links)**

**Analysis**: Built-in subagent descriptions are part of the Task tool schema — always loaded. However, Jarvis can provide a **rich orchestration layer** that guides selection, configures spawned agents, and links them to appropriate tools.

**Three-Tier Framework for Subagents**:

```
┌─────────────────────────────────────────────────────────────────┐
│  TIER 1: ORCHESTRATION METADATA (Jarvis provides)               │
│  ────────────────────────────────────────────────               │
│  Purpose: Guide Jarvis toward correct subagent selection        │
│                                                                 │
│  For each subagent:                                             │
│  • When to use (positive triggers)                              │
│  • When NOT to use (anti-patterns)                              │
│  • Preferred model (opus/sonnet/haiku)                          │
│  • Expected output format                                       │
│  • Complementary tools to enable first                          │
│                                                                 │
│  Location: agent-selection-pattern.md, capability-map.yaml    │
└─────────────────────────────────────────────────────────────────┘
                              ▼
               (Subagent selected — spawn with context)
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  TIER 2: AGENT PROMPT (Task tool provides + Jarvis extends)     │
│  ──────────────────────────────────────────────────────────     │
│  Claude Code provides: System prompt, tool subset, history      │
│                                                                 │
│  Jarvis can add via prompt parameter:                           │
│  • Specific instructions for this invocation                    │
│  • Context about current session state                          │
│  • Constraints or focus areas                                   │
│  • Output format requirements                                   │
└─────────────────────────────────────────────────────────────────┘
                              ▼
               (Agent executes — may need resources)
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  TIER 3: TOOL/RESOURCE LINKS (Jarvis configures)                │
│  ───────────────────────────────────────────────                │
│  Before spawning, ensure agent has access to:                   │
│                                                                 │
│  • MCPs: Enable relevant MCPs before Task call                  │
│  • Scripts: Agent can invoke via Bash                           │
│  • Context files: @-reference in prompt                         │
│  • Patterns: Link to relevant pattern docs                      │
│                                                                 │
│  Example: Before spawning deep-research agent, enable:          │
│  → brave-search MCP (web search)                                │
│  → gptresearcher MCP (deep research)                            │
│  → perplexity MCP (citations)                                   │
└─────────────────────────────────────────────────────────────────┘
```

**Orchestration Metadata Example**:

```markdown
# Subagent Orchestration Guide (.claude/context/patterns/subagent-orchestration.md)

## Explore Subagent
- **Use when**: Finding files, understanding codebase structure, "where is X?"
- **Don't use when**: Single file path known (use Read), simple glob pattern
- **Model**: haiku (fast, cheap, read-only)
- **Pre-enable**: None (uses built-in tools only)
- **Output**: File paths, structure summaries

## Plan Subagent
- **Use when**: Architecture decisions, multi-file changes, user approval needed
- **Don't use when**: Implementation path clear, single-file change
- **Model**: opus (complex reasoning)
- **Pre-enable**: MCPs relevant to planned work
- **Output**: Implementation plan, file list, approach options

## General-purpose Subagent
- **Use when**: Multi-step task (3-10 ops), exploration + implementation mix
- **Don't use when**: Simple task (use direct tools), domain expertise needed
- **Model**: sonnet (balanced)
- **Pre-enable**: MCPs based on task type
- **Output**: Task results, created/modified files
```

**Jarvis Strategy**:
1. Create `subagent-orchestration.md` with selection metadata
2. Before spawning, check MCP requirements and enable
3. Include relevant context in Task prompt parameter
4. Link to scripts/patterns agent may need

---

### 2.4 MCPs (Model Context Protocol Servers)

**Current State**: All tool schemas load when MCP enabled.

| Aspect | Value |
|--------|-------|
| Token Cost | 500-50,000+ per MCP |
| Loading | All-or-nothing when enabled |
| Control | Enable/disable, tiered loading |

**Progressive Disclosure Applicability**: ✅ **Applicable (Multiple Strategies)**

**Strategy 1: Tiered MCP Loading** (Implemented in Jarvis)

```
┌─────────────────────────────────────────────────────────────────┐
│  TIER 1: ALWAYS-ON (Core MCPs)                                   │
│  ─────────────────────────────                                   │
│  • Memory, Filesystem, Fetch, Git                                │
│  • Token cost: ~3,000 total                                      │
│  • Loaded: Every session                                         │
└─────────────────────────────────────────────────────────────────┘
                              ▼
                     (Based on session work type)
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  TIER 2: TASK-SCOPED (Work-Specific MCPs)                        │
│  ────────────────────────────────────────                        │
│  • GitHub (PR work), Brave Search (research), Chroma (vectors)   │
│  • Token cost: 500-8,000 each                                    │
│  • Loaded: Via suggest-mcps.sh based on session-state            │
└─────────────────────────────────────────────────────────────────┘
                              ▼
                     (Explicit need identified)
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  TIER 3: ON-DEMAND (Heavy/Specialized MCPs)                      │
│  ──────────────────────────────────────────                      │
│  • Playwright (~15K), GitHub full (~50K)                         │
│  • Token cost: 15,000-50,000                                     │
│  • Loaded: Only when explicitly needed, then disabled            │
└─────────────────────────────────────────────────────────────────┘
```

**Strategy 2: Dynamic Toolset Pattern** (Future/Theoretical)

For large MCPs, replace full schemas with meta-tools:

```
CURRENT (All-Upfront)
─────────────────────
[Session Start]
  └─→ Load all 90 GitHub tool schemas
  └─→ ~50,000 tokens consumed
  └─→ Query: "List recent issues"
  └─→ Use 1 of 90 tools

OPTIMIZED (Dynamic Toolset)
───────────────────────────
[Session Start]
  └─→ Load 2 meta-tools: search_tools, describe_tools
  └─→ ~200 tokens consumed

[Query: "List recent issues"]
  └─→ search_tools("github issues")
  └─→ Returns: ["list_issues", "get_issue", "create_issue"]
  └─→ describe_tools(["list_issues"])
  └─→ ~500 tokens for selected tool only
  └─→ execute_tool("list_issues", params)
```

**Strategy 3: Schema Compression** (Theoretical)

```
FULL SCHEMA (~500 tokens per tool):
{
  "name": "mcp__github__list_issues",
  "description": "List issues in a GitHub repository with filtering...",
  "parameters": {
    "owner": { "type": "string", "description": "Repository owner..." },
    "repo": { "type": "string", "description": "Repository name..." },
    "state": { "enum": ["open", "closed", "all"], "description": "..." },
    ...
  }
}

COMPRESSED SCHEMA (~100 tokens per tool):
{
  "name": "list_issues",
  "summary": "List GitHub issues (owner, repo, state, labels, since)",
  "expand": "mcp__github__list_issues"
}
```

**Jarvis Implementation**: Uses Tier Strategy via `suggest-mcps.sh` and `enable-mcps.sh`/`disable-mcps.sh` scripts.

---

### 2.5 Plugins

**Current State**: All plugin content loads when installed.

| Aspect | Value |
|--------|-------|
| Token Cost | Variable (sum of all skills in plugin) |
| Loading | All-or-nothing when installed |
| Control | Install/uninstall, not individual skills |

**Progressive Disclosure Applicability**: ❌ **Not Applicable — Plugins Are Decomposition Targets**

**Jarvis Project Aim**: We do NOT optimize plugin loading. We **eliminate plugins entirely** through decomposition into constituent parts.

**Why Progressive Disclosure Is Wrong for Plugins**:

```
THE PLUGIN PROBLEM:
┌─────────────────────────────────────────────────────────────────┐
│  Plugins are BUNDLES that violate the three-tier principle:     │
│                                                                 │
│  • All skills load regardless of need                           │
│  • No individual skill control                                  │
│  • Token overhead from unused components                        │
│  • No customization without forking                             │
│  • Dependencies on plugin maintenance                           │
└─────────────────────────────────────────────────────────────────┘

THE DECOMPOSITION SOLUTION:
┌─────────────────────────────────────────────────────────────────┐
│  Extract plugin components into Jarvis-native modalities:       │
│                                                                 │
│  Plugin Skill    → .claude/skills/ (progressive disclosure)    │
│  Plugin Agent    → .claude/agents/ (three-tier loading)         │
│  Plugin Hook     → .claude/hooks/ (automatic triggers)          │
│  Plugin MCP      → MCP registration (tiered loading)            │
│  Plugin Command  → .claude/commands/ (two-tier loading)         │
│  Plugin Context  → .claude/context/ (on-demand reading)         │
│  Plugin Pattern  → .claude/context/patterns/ (reusable)         │
│                                                                 │
│  Result: Full control over each component's loading strategy    │
└─────────────────────────────────────────────────────────────────┘
```

**The Plugin Lifecycle in Jarvis**:

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│   DISCOVER   │ ──→ │   EVALUATE   │ ──→ │  DECOMPOSE   │ ──→ │   UNINSTALL  │
│              │     │              │     │              │     │              │
│ Find useful  │     │ Assess which │     │ Extract to   │     │ Remove       │
│ plugin       │     │ components   │     │ Jarvis-native│     │ original     │
│              │     │ have value   │     │ modalities   │     │ plugin       │
└──────────────┘     └──────────────┘     └──────────────┘     └──────────────┘
```

**Example Decomposition**:

```
BEFORE: document-skills@anthropic-agent-skills (installed)
├── docx          ← FREQUENTLY USED (~2K tokens)
├── pdf           ← FREQUENTLY USED (~2K tokens)
├── xlsx          ← SOMETIMES USED (~1.5K tokens)
├── pptx          ← RARELY USED (~1.5K tokens)
├── algorithmic-art   ← NEVER USED (~4.8K tokens)
├── doc-coauthoring   ← NEVER USED (~3.8K tokens)
└── slack-gif-creator ← NEVER USED (~1.9K tokens)

Total overhead: ~17.5K tokens (all skills load)

AFTER: Plugin uninstalled, components extracted
.claude/skills/
├── docx/SKILL.md     ← Extracted, customized (progressive loading)
└── pdf/SKILL.md      ← Extracted, customized (progressive loading)

Total overhead: ~200 tokens (summaries only, full loads on-demand)
Savings: ~17K tokens
```

**Why This Approach**:

| Plugin Approach | Decomposition Approach |
|-----------------|------------------------|
| All-or-nothing loading | Individual component control |
| Plugin author's structure | Jarvis-optimized structure |
| External dependency | Local ownership |
| Limited customization | Full customization |
| No three-tier loading | Three-tier per component |

**See Part 3** for the complete Component Extraction Workflow.

---

### 2.6 Custom Agents

**Current State**: Agent definitions load on Task spawn.

| Aspect | Value |
|--------|-------|
| Token Cost | ~500 (registry) + definition size (on spawn) |
| Loading | Summary in agent list, full on spawn |
| Control | Full (agent design, layering) |

**Progressive Disclosure Applicability**: ✅ **Fully Applicable (Design Pattern)**

**Analysis**: Custom agents already exhibit progressive disclosure — the agent list shows summaries, full definition loads only when spawned via Task.

**Three-Tier Agent Loading**:

```
┌─────────────────────────────────────────────────────────────────┐
│  TIER 1: AGENT REGISTRY (Always Available)                       │
│  ─────────────────────────────────────────                       │
│  • Agent name + one-line description                             │
│  • Token cost: ~50 per agent                                     │
│  • Purpose: Enable selection decision                            │
│                                                                  │
│  Example:                                                        │
│  "docker-deployer: Deploy Docker services with validation"       │
└─────────────────────────────────────────────────────────────────┘
                              ▼
                     (Task tool invoked with agent type)
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  TIER 2: AGENT DEFINITION (Loaded on Spawn)                      │
│  ──────────────────────────────────────────                      │
│  • Full agent persona, workflow, constraints                     │
│  • Token cost: 500-2,000 per agent                               │
│  • Purpose: Configure agent behavior                             │
│                                                                  │
│  Contains: Persona, phases, tool restrictions, output format     │
└─────────────────────────────────────────────────────────────────┘
                              ▼
                     (Agent reads during execution)
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  TIER 3: DOMAIN RESOURCES (Loaded by Agent)                      │
│  ──────────────────────────────────────────                      │
│  • Reference documentation, templates, examples                  │
│  • Token cost: Variable                                          │
│  • Purpose: Deep domain knowledge                                │
│                                                                  │
│  Examples: Docker patterns, troubleshooting guides, templates    │
└─────────────────────────────────────────────────────────────────┘
```

**Agent Design Guidelines**:
```
AGENT DEFINITION STRUCTURE FOR PROGRESSIVE DISCLOSURE:
├── Frontmatter (name, description, tools) — REGISTRY
├── Persona (communication style, expertise) — TIER 2
├── Workflow (phases, steps) — TIER 2
├── Constraints (what NOT to do) — TIER 2
├── Output Format (structured response) — TIER 2
└── @-linked resources (domain docs) — TIER 3 (agent reads as needed)
```

**Key Insight**: Agents spawn in **separate context**, so their definition tokens don't compete with main conversation. Progressive disclosure within agent definitions primarily benefits the agent's own context budget.

---

### 2.7 Scripts

**Current State**: Invoked via Bash, only output enters context.

| Aspect | Value |
|--------|-------|
| Token Cost | ~0 (no schema) + output size |
| Loading | Never loaded, executed on demand |
| Control | Full (script design, output format) |

**Progressive Disclosure Applicability**: ⚠️ **Partially Applicable (Output Design)**

**Analysis**: Scripts have no schema — they're invisible until invoked. Progressive disclosure applies to **output design**, not loading.

**Output Progressive Pattern**:

```
TIER 1: Summary output (default)
─────────────────────────────────
$ ./suggest-mcps.sh
Suggest Enabling: github, brave-search
Command: .claude/scripts/enable-mcps.sh github brave-search

TIER 2: Detailed output (--verbose)
───────────────────────────────────
$ ./suggest-mcps.sh --verbose
Next Step: "Review PR #123 and research caching strategies"
Keyword matches: PR → github, research → brave-search
Currently enabled: memory, filesystem, fetch, git
Suggest enabling: github, brave-search
Suggest disabling: chroma (not needed)

TIER 3: Debug output (--debug)
──────────────────────────────
$ ./suggest-mcps.sh --debug
[DEBUG] Reading session-state.md...
[DEBUG] Extracted Next Step: "Review PR #123..."
[DEBUG] Matching keywords against MCP_KEYWORDS array...
...
```

**Script Design Guidelines**:
```
SCRIPT OUTPUT FOR PROGRESSIVE DISCLOSURE:
├── Default: Actionable summary (what to do)
├── --verbose: Reasoning and context (why)
├── --json: Machine-readable for hooks/automation
└── --debug: Full trace for troubleshooting
```

---

### 2.8 Hooks

**Current State**: Invisible to LLM, fire on events.

| Aspect | Value |
|--------|-------|
| Token Cost | ~0 (no schema, only additionalContext) |
| Loading | Never loaded as tools |
| Control | Full (hook design, context injection) |

**Progressive Disclosure Applicability**: ❌ **Not Applicable — But Agent Hook-Awareness IS Critical**

**Analysis**: Hooks don't consume LLM context in the traditional sense — they have no tool schemas. Progressive disclosure doesn't apply to hooks themselves. However, **agents must be hook-aware** to avoid accidentally triggering guardrails or missing intended triggers.

**Why Progressive Disclosure Doesn't Apply to Hooks**:
```
HOOKS ARE INVISIBLE:
├── No tool schema (LLM doesn't "see" hooks)
├── No selection decision (hooks fire automatically)
├── No loading choice (always active when configured)
└── Only output matters (additionalContext injection)
```

**The Agent Hook-Awareness Requirement**:

When designing or extending agents, the hook corpus must be reviewed to ensure:

```
HOOK-AWARE AGENT DESIGN:
┌─────────────────────────────────────────────────────────────────┐
│  1. AVOID ACCIDENTAL TRIGGERS                                    │
│  ────────────────────────────                                    │
│  Review PreToolUse hooks to understand what actions are blocked: │
│                                                                  │
│  • workspace-guard.js — Blocks writes to AIfred baseline         │
│    → Agent must not attempt writes to ~/AIfred-dev/              │
│                                                                  │
│  • dangerous-op-guard.js — Blocks rm -rf, sudo, etc.             │
│    → Agent must use safe alternatives                            │
│                                                                  │
│  • secret-scanner.js — Blocks commits with secrets               │
│    → Agent must sanitize before committing                       │
└─────────────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────────────────────────────────────────┐
│  2. ENSURE INTENDED TRIGGERS                                     │
│  ───────────────────────────                                     │
│  Review hooks that provide useful behavior:                      │
│                                                                  │
│  • session-start.js — Injects session context                    │
│    → Agent benefits from session state awareness                 │
│                                                                  │
│  • doc-sync-trigger.js — Tracks documentation changes            │
│    → Agent's doc changes will be tracked for sync                │
│                                                                  │
│  • memory-maintenance.js — Tracks entity access                  │
│    → Agent's Memory MCP usage will be monitored                  │
└─────────────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────────────────────────────────────────┐
│  3. UNDERSTAND BLOCKING VS INFORMATIONAL                         │
│  ───────────────────────────────────────                         │
│                                                                  │
│  BLOCKING HOOKS (will stop agent action):                        │
│  • workspace-guard, dangerous-op-guard, secret-scanner           │
│                                                                  │
│  INFORMATIONAL HOOKS (inject context, don't block):              │
│  • session-start, context-reminder, permission-gate              │
│                                                                  │
│  SILENT HOOKS (log only, agent unaware):                         │
│  • audit-logger, session-tracker, memory-maintenance             │
└─────────────────────────────────────────────────────────────────┘
```

**Agent Definition Should Include Hook Awareness**:

```markdown
# Example agent definition with hook awareness

## Constraints

### Hook Awareness
This agent operates within Jarvis hook environment:
- **workspace-guard**: Do NOT write to ~/AIfred-dev/ (baseline is read-only)
- **dangerous-op-guard**: Do NOT use rm -rf, sudo, or force commands
- **secret-scanner**: Sanitize all commits for secrets before git add

### Beneficial Hooks
- Session context available via session-start hook
- Documentation changes tracked via doc-sync-trigger
```

**Context Injection Strategy** (for hook authors):

Hooks that inject context should minimize token impact:

```javascript
// GOOD HOOK (minimal injection):
return {
  proceed: true,
  additionalContext: "Remember: AIfred baseline is read-only."
}

// BAD HOOK (excessive injection):
return {
  proceed: true,
  additionalContext: `Full policy document here...
    Section 1: Background...
    Section 2: Requirements...
    [500+ tokens of context]`
}
```

**Guidelines**:
- Keep `additionalContext` under 100 tokens
- Link to context files for details, don't inline
- Document hooks in `.claude/hooks/README.md` for agent awareness
- Include hook-awareness section in custom agent definitions

---

### 2.9 Commands

**Current State**: Full file loads on `/command` invocation.

| Aspect | Value |
|--------|-------|
| Token Cost | ~50 (description) + file size (on invoke) |
| Loading | Description in /help, full on invocation |
| Control | Full (command design, structure) |

**Progressive Disclosure Applicability**: ✅ **Applicable (Two-Tier)**

**Analysis**: Commands already exhibit two-tier progressive disclosure — `/help` shows descriptions, invocation loads full content.

**Two-Tier Command Loading**:

```
┌─────────────────────────────────────────────────────────────────┐
│  TIER 1: COMMAND REGISTRY (/help listing)                        │
│  ────────────────────────────────────────                        │
│  • Command name + description from frontmatter                   │
│  • Token cost: ~50 per command                                   │
│  • Purpose: Enable user/Claude to find relevant command          │
│                                                                  │
│  Example in /help:                                               │
│  /checkpoint — Save session state for MCP restart                │
└─────────────────────────────────────────────────────────────────┘
                              ▼
                     (User or Claude invokes /command)
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  TIER 2: FULL COMMAND CONTENT (Loaded on Invocation)             │
│  ───────────────────────────────────────────────────             │
│  • Complete markdown file injected as instructions               │
│  • Token cost: File size (typically 500-2,000)                   │
│  • Purpose: Provide detailed procedure                           │
│                                                                  │
│  Contains: Full workflow, steps, validation, outputs             │
└─────────────────────────────────────────────────────────────────┘
```

**Command Design Guidelines**:
```
COMMAND STRUCTURE FOR EFFICIENCY:
├── Frontmatter: description (concise, for /help)
├── Purpose: When to use this command (1-2 lines)
├── Workflow: Step-by-step procedure
├── Validation: How to verify success
└── @-links: Reference detailed context files (not inline)

AVOID:
├── Embedding full documentation in command file
├── Duplicating content from context files
└── Including examples that could be linked
```

**Potential Tier 3** (not currently implemented):

Commands could link to detailed resources loaded only during execution:
```
## Workflow
1. Read session state
2. For detailed checkpoint format, see @.claude/context/patterns/checkpoint-format.md
3. Write checkpoint file
```

---

### 2.10 Progressive Disclosure Summary Matrix

| Modality | Loading Control | Selection Guidance | Primary Strategy |
|----------|----------------|-------------------|------------------|
| **Built-in Tools** | ❌ None | ✅ YES | Jarvis selection guidance layer |
| **Skills** | ✅ Full | ✅ YES | Three-tier design (metadata/core/links) |
| **Subagents** | ⚠️ Partial | ✅ YES | Orchestration metadata + tool links |
| **MCPs** | ✅ Full | ✅ YES | Tiered loading + dynamic toolset |
| **Plugins** | ❌ None | N/A | **DECOMPOSE, don't optimize** |
| **Custom Agents** | ✅ Full | ✅ YES | Three-tier design + hook awareness |
| **Scripts** | ⚠️ Partial | ✅ YES | Output verbosity + guidance docs |
| **Hooks** | ❌ None | N/A | Agent hook-awareness (not disclosure) |
| **Commands** | ✅ Full | ✅ YES | Two-tier design, lean content |

### Key Takeaways

1. **The Universal Three-Tier Framework applies everywhere** — Even when Jarvis can't control loading, it can add selection metadata that guides orchestration decisions.

2. **Selection Guidance is the overlooked opportunity** — Built-in tools, subagents, and scripts all benefit from Jarvis-provided selection metadata, even though Claude Code controls their loading.

3. **Plugins are decomposition targets, not optimization targets** — Don't try to progressively load plugins; extract their valuable components and eliminate the plugin.

4. **Hooks require a different paradigm: Agent Hook-Awareness** — Progressive disclosure doesn't apply, but agents must understand the hook environment to avoid accidental triggers and leverage beneficial hooks.

5. **The unifying principle**: Every modality benefits from the three-tier structure (metadata/core/links), applied either to **loading** (Skills, MCPs, Custom Agents, Commands) or to **selection guidance** (Built-in Tools, Subagents, Scripts).

### Jarvis Deliverables from This Analysis

| Deliverable | Location | Purpose |
|-------------|----------|---------|
| Built-in Tool Selection Guide | `patterns/built-in-tool-selection.md` | Tier 1 guidance for built-in tools |
| Subagent Orchestration Guide | `patterns/subagent-orchestration.md` | Tier 1 metadata for subagents |
| Hook Awareness Reference | `.claude/hooks/README.md` | Agent hook-awareness documentation |
| Agent Hook-Awareness Template | Part 7.8 | Include in custom agent definitions |

---

## Part 3: Component Extraction Workflow

### Why Decompose Plugins?

**Problem**: Plugin bundles load ALL skills regardless of need:
```
document-skills@anthropic-agent-skills
├── docx          ← FREQUENTLY USED
├── pdf           ← FREQUENTLY USED
├── xlsx          ← SOMETIMES USED
├── pptx          ← RARELY USED
├── algorithmic-art   ← NEVER USED (~4.8K tokens)
├── doc-coauthoring   ← NEVER USED (~3.8K tokens)
└── slack-gif-creator ← NEVER USED (~1.9K tokens)

Total overhead from unused: ~10.5K tokens
```

**Goal**: Extract components for granular control:
- Apply MCP validation to plugin-loaded MCPs
- Enable/disable individual skills
- Customize for Jarvis patterns
- Apply context management

### Jarvis Component Types

When decomposing a plugin, components map to:

| Source | Target | Purpose |
|--------|--------|---------|
| Plugin skills | `.claude/skills/` | Standalone skills |
| Plugin agents | `.claude/agents/` | Custom agents |
| Plugin hooks | `.claude/hooks/` | Behavioral hooks |
| Plugin MCPs | MCP registration | Validated MCPs |
| Plugin commands | `.claude/commands/` | Slash commands |
| Plugin config | `.claude/config/` | Configuration files |
| Plugin context | `.claude/context/` | Context injections |
| Plugin patterns | `.claude/context/patterns/` | Design patterns |
| Plugin templates | `.claude/context/templates/` | Reusable templates |
| Plugin workflows | `.claude/context/workflows/` | Multi-step processes |

### Extraction Workflow

```
┌─────────────────────────────────────────────────────────────────┐
│  PHASE 1: ANALYSIS                                               │
│  ─────────────────                                               │
│  1. Locate plugin in cache:                                      │
│     ~/.claude/plugins/cache/<marketplace>/<plugin>/              │
│                                                                  │
│  2. Read manifest:                                               │
│     .claude-plugin/marketplace.json                              │
│                                                                  │
│  3. Inventory components:                                        │
│     └─ Skills (./skills/**/SKILL.md)                             │
│     └─ Agents (agent patterns)                                   │
│     └─ MCPs (server registrations)                               │
│     └─ Hooks (event handlers)                                    │
│     └─ Context (injected content)                                │
└─────────────────────────────────────────────────────────────────┘
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  PHASE 2: CLASSIFICATION                                         │
│  ───────────────────────                                         │
│  For each component, classify:                                   │
│                                                                  │
│  ┌──────────┬────────────────────────────────────────────────┐  │
│  │ EXTRACT  │ High value, frequently used, customize needed  │  │
│  ├──────────┼────────────────────────────────────────────────┤  │
│  │ ADAPT    │ Useful but needs Jarvis-specific changes       │  │
│  ├──────────┼────────────────────────────────────────────────┤  │
│  │ DROP     │ Unused, overhead not justified                 │  │
│  └──────────┴────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  PHASE 3: EXTRACTION                                             │
│  ──────────────────                                              │
│  For EXTRACT/ADAPT components:                                   │
│                                                                  │
│  1. Copy to appropriate Jarvis location                          │
│  2. Update metadata (frontmatter, references)                    │
│  3. Integrate with Jarvis patterns                               │
│  4. Add to inventory documentation                               │
│  5. Test standalone operation                                    │
└─────────────────────────────────────────────────────────────────┘
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  PHASE 4: VALIDATION                                             │
│  ──────────────────                                              │
│  1. Verify skill appears in /skills list                         │
│  2. Execute test task using extracted skill                      │
│  3. Confirm no dependency on original plugin                     │
│  4. Measure token savings                                        │
│  5. Update capability matrix                                     │
└─────────────────────────────────────────────────────────────────┘
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  PHASE 5: DOCUMENTATION                                          │
│  ────────────────────                                            │
│  1. Update skills-selection-guide.md                             │
│  2. Update capability-map.yaml                                  │
│  3. Update overlap-analysis.md                                   │
│  4. Add to context index                                         │
│  5. (Optional) Uninstall source plugin                           │
└─────────────────────────────────────────────────────────────────┘
```

### Extraction Command (Proposed)

```markdown
# /extract-skill <plugin-name> <skill-name>

Extract a skill from an installed plugin into standalone Jarvis skill.

## Process
1. Locate skill in plugin cache
2. Copy to .claude/skills/
3. Adapt frontmatter for Jarvis
4. Register in skills inventory
5. Validate standalone operation
6. Update documentation

## Options
--dry-run    Preview extraction without changes
--all        Extract all skills from plugin
--force      Overwrite existing skill
```

---

## Part 4: Selection Quality Framework

### LLM-Based Selection (Current State)

**Discovery**: Claude Code does NOT use algorithmic routing.

```
Tool Selection Mechanism
────────────────────────
1. All available tools formatted into text descriptions
2. Embedded in system/tool prompts
3. Claude's LLM makes selection via natural language reasoning

This is PURE LLM REASONING — model decides based on descriptions,
not embeddings, classifiers, or pattern matching.
```

**Implication**: Tool descriptions are critical for selection quality.

### Description Optimization Guidelines

| Aspect | Bad | Good |
|--------|-----|------|
| **Clarity** | "Does stuff with files" | "Read, write, and edit files in Jarvis workspace" |
| **Scope** | "GitHub operations" | "Create PRs, manage issues, review code on GitHub" |
| **Trigger** | (none) | "Use when user mentions PR, issue, or GitHub" |
| **Anti-scope** | (none) | "Do NOT use for local git operations" |

### Selection Validation Test Cases

| Test ID | Input | Expected Selection | Validation |
|---------|-------|-------------------|------------|
| SEL-01 | "Find package.json files" | `Glob` | Not Explore subagent |
| SEL-02 | "What files handle auth?" | `Explore` subagent | Context isolation |
| SEL-03 | "Create a Word document" | `docx` skill | Not manual approach |
| SEL-04 | "Research Docker networking" | `deep-research` agent | Custom agent |
| SEL-05 | "Quick fact: capital of France" | `WebSearch` or `perplexity_search` | Built-in first |
| SEL-06 | "Comprehensive analysis of X" | `gptresearcher_deep_research` | Full research MCP |
| SEL-07 | "Navigate to example.com" | `Playwright MCP` | Browser automation |
| SEL-08 | "Fill out the login form" | `browser-automation` plugin | NL browser task |
| SEL-09 | "Push changes to GitHub" | `engineering-workflow-skills` | Skill over bash |
| SEL-10 | "Review this PR thoroughly" | `pr-review-toolkit` | Comprehensive review |

### Metrics to Track

| Metric | Target | Measurement |
|--------|--------|-------------|
| **Selection Accuracy** | >90% | Test case pass rate |
| **Fallback Frequency** | <10% | Primary tool used vs fallback |
| **Token Efficiency** | <40% budget | MCP + skill tokens / total |
| **User Override Rate** | <5% | Manual tool specification |

---

## Part 5: Integration Points

### With MCP Loading Strategy

```
Tool Selection Intelligence
         │
         ├─→ Tier 1 MCPs: Always available for selection
         ├─→ Tier 2 MCPs: Suggest based on work type
         └─→ Tier 3 MCPs: Trigger via hook/command only
```

### With Context Budget Management

```
Selection Intelligence
         │
         ├─→ Token-aware: Prefer lower-cost tools
         ├─→ Progressive: Load details only when needed
         └─→ Threshold: Warn when budget exceeded
```

### With Capability Matrix

```
Selection Intelligence
         │
         ├─→ Read: Check matrix for task→tool mapping
         ├─→ Update: Add new tools/skills post-extraction
         └─→ Conflict: Use matrix for overlap resolution
```

---

## Part 6: Local Tooling Layer (Scripts, Hooks, Commands)

The Local Tooling Layer provides **system plumbing** that powers Jarvis's automation, guardrails, and session management. Unlike the Knowledge and Integration layers (which come from industry research), this layer is Jarvis-specific.

### 6.1 Scripts (`.claude/scripts/`, `scripts/`)

**Definition**: Bash scripts that perform system-level automation, invoked explicitly via the Bash tool.

**Characteristics**:
| Aspect | Value |
|--------|-------|
| Format | Bash (.sh) |
| Trigger | Explicit Bash tool call |
| Token Cost | ~0 (only output) |
| Control | Claude controls invocation |
| Location | `.claude/scripts/` (session), `scripts/` (project) |

**Examples in Jarvis**:

| Script | Purpose | When to Use |
|--------|---------|-------------|
| `suggest-mcps.sh` | Analyze session-state and suggest MCPs | Session start, work type change |
| `disable-mcps.sh` | Add MCPs to disabledMcpServers | Context budget critical |
| `enable-mcps.sh` | Remove MCPs from disabled list | New work type needs MCP |
| `list-mcp-status.sh` | Show MCP enable/disable state | Debugging, planning |
| `validate-mcp-installation.sh` | Test MCP connectivity | Post-installation |
| `bump-version.sh` | Semantic version management | Release milestones |
| `setup-readiness.sh` | Environment validation | Post-setup, debugging |

**Selection Guidance**:
```
Use SCRIPTS when:
├── Task is system automation (MCP management, versioning)
├── Raw Bash output is needed
├── Scheduled/maintenance operations
└── Validation tasks (setup, hooks, installation)

Do NOT use scripts when:
├── Task is procedural workflow → Use Commands
├── Task needs automatic triggering → Use Hooks
└── Task is user-facing procedure → Use Skills
```

### 6.2 Hooks (`.claude/hooks/`)

**Definition**: JavaScript (or Bash) event handlers that fire automatically based on Claude Code lifecycle events. Claude does NOT directly invoke hooks — they are triggered by the system.

**Characteristics**:
| Aspect | Value |
|--------|-------|
| Format | JavaScript (.js) or Bash (.sh) |
| Trigger | Automatic (system events) |
| Token Cost | ~0 (no schemas loaded) |
| Control | System controls invocation |
| Location | `.claude/hooks/` |

**Hook Events**:

| Event | When Fired | Example Hook |
|-------|------------|--------------|
| `SessionStart` | Claude Code starts | `session-start.js` — Load context |
| `PreToolUse` | Before any tool runs | `workspace-guard.js` — Block forbidden paths |
| `PostToolUse` | After tool completes | `doc-sync-trigger.js` — Track changes |
| `UserPromptSubmit` | User sends message | `permission-gate.js` — Soft-gate operations |
| `Stop` | Session ends | `session-stop.js` — Desktop notification |
| `SubagentStop` | Agent completes | `subagent-stop.js` — Agent chaining |
| `PreCompact` | Before compaction | `pre-compact.js` — Preserve state |

**Hook Categories**:

| Category | Purpose | Examples |
|----------|---------|----------|
| **Lifecycle** | Session management | session-start, session-stop, pre-compact |
| **Guardrails** | Safety enforcement | workspace-guard, dangerous-op-guard |
| **Security** | Secret protection | secret-scanner |
| **Observability** | Logging/tracking | audit-logger, session-tracker |
| **Documentation** | Sync triggers | doc-sync-trigger |
| **Utility** | Context injection | project-detector, permission-gate |

**Hook Behavior Modes**:

```
BLOCKING HOOKS (return { proceed: false })
├── workspace-guard.js — Block writes to AIfred baseline
├── dangerous-op-guard.js — Block rm -rf /, sudo, etc.
└── secret-scanner.js — Block commits with secrets

INFORMATIONAL HOOKS (return { proceed: true } with additionalContext)
├── session-start.js — Inject session context
├── context-reminder.js — Suggest documentation
└── permission-gate.js — Add policy reminders

SILENT HOOKS (just log/track)
├── audit-logger.js — Log all tool executions
├── session-tracker.js — Track lifecycle
└── memory-maintenance.js — Track entity access
```

**Selection Guidance** (for creating new hooks):
```
Use HOOKS when:
├── Behavior must be AUTOMATIC (no Claude decision)
├── Safety guardrails that MUST NOT be bypassed
├── Observability/logging requirements
├── Context injection at specific lifecycle points
└── Triggering actions based on events

Do NOT use hooks when:
├── Claude should decide whether to invoke → Use Scripts
├── User should explicitly trigger → Use Commands
├── Multi-step workflow with reasoning → Use Skills
└── External integration needed → Use MCPs
```

### 6.3 Commands (`.claude/commands/`)

**Definition**: Markdown files with YAML frontmatter that define slash commands (`/command`). When invoked, the entire file content is injected into the conversation as procedural instructions.

**Characteristics**:
| Aspect | Value |
|--------|-------|
| Format | Markdown (.md) with YAML frontmatter |
| Trigger | Explicit `/command` invocation |
| Token Cost | File content size |
| Control | Claude or user invokes |
| Location | `.claude/commands/` |

**Frontmatter Options**:
```yaml
---
description: Short description for /help listing
argument-hint: [optional] [arguments]
allowed-tools: Read, Write, Edit, Bash(git:*)  # Restrict tools
---
```

**Examples in Jarvis**:

| Command | Purpose | When to Use |
|---------|---------|-------------|
| `/checkpoint` | Save session state for restart | Before MCP enable, context critical |
| `/end-session` | Clean exit with commit | Session complete |
| `/context-budget` | Analyze context usage | Check token status |
| `/tooling-health` | Validate all tooling | Post-installation, debugging |
| `/setup` | Initial configuration | New environment |
| `/design-review` | PARC pattern check | Pre-implementation |
| `/sync-aifred-baseline` | Analyze upstream changes | Baseline behind |

**Commands vs Skills vs Scripts**:

| Aspect | Commands | Skills | Scripts |
|--------|----------|--------|---------|
| **Format** | Markdown + YAML | SKILL.md + resources | Bash |
| **Invocation** | `/command` | Skill invocation | Bash tool |
| **Token Cost** | Full file on invoke | Progressive disclosure | Output only |
| **Control** | User/Claude explicit | Claude reasoning | Claude explicit |
| **Best For** | Multi-step procedures | Procedural expertise | System automation |
| **Examples** | /checkpoint, /end-session | docx, browser-automation | bump-version, disable-mcps |

**Selection Guidance**:
```
Use COMMANDS when:
├── Multi-step procedure with human checkpoints
├── Session lifecycle management
├── Operations requiring tool restrictions
└── Workflows that inject detailed instructions

Do NOT use commands when:
├── Simple automation → Use Scripts
├── Progressive disclosure needed → Use Skills
├── Automatic triggering → Use Hooks
└── External system access → Use MCPs
```

### 6.4 Selection Decision Tree for Local Tooling

```
Local Tooling Task
     │
     ▼
┌─────────────────────────────────────────────────────────────────┐
│ Q1: Should this run AUTOMATICALLY without Claude deciding?      │
│     → YES: Use HOOKS (event-triggered)                          │
│     Examples: Guardrails, session start context, audit logging  │
└─────────────────────────────────────────────────────────────────┘
     │ NO (Claude/user decides)
     ▼
┌─────────────────────────────────────────────────────────────────┐
│ Q2: Is this SYSTEM AUTOMATION (MCP, versioning, validation)?    │
│     → YES: Use SCRIPTS (Bash tool)                              │
│     Examples: disable-mcps.sh, bump-version.sh, setup-readiness │
└─────────────────────────────────────────────────────────────────┘
     │ NO (user-facing procedure)
     ▼
┌─────────────────────────────────────────────────────────────────┐
│ Q3: Does it need PROGRESSIVE DISCLOSURE (complex expertise)?    │
│     → YES: Use SKILLS (SKILL.md with resources)                 │
│     Examples: docx, pdf, browser-automation                     │
└─────────────────────────────────────────────────────────────────┘
     │ NO (straightforward multi-step)
     ▼
┌─────────────────────────────────────────────────────────────────┐
│ Q4: Is it a SESSION LIFECYCLE operation?                        │
│     → YES: Use COMMANDS (inject full instructions)              │
│     Examples: /checkpoint, /end-session, /context-budget        │
└─────────────────────────────────────────────────────────────────┘
```

### 6.5 Jarvis Component Inventory

**Scripts** (12 total):
```
.claude/scripts/
├── suggest-mcps.sh          # MCP recommendation
├── disable-mcps.sh          # Disable MCPs
├── enable-mcps.sh           # Enable MCPs
├── list-mcp-status.sh       # MCP status
├── validate-mcp-installation.sh  # Installation check
├── mcp-validation-batches.sh     # Batch testing
├── adjust-mcp-config.sh     # Config modification
├── restore-mcp-config.sh    # Config restore
├── mcp-unload-workflow.sh   # Unload procedure
├── jarvis-watcher.sh        # Unified watcher (v3.0.0)
├── launch-watcher.sh        # Start watcher
└── stop-watcher.sh          # Stop watcher

scripts/
├── bump-version.sh          # Semantic versioning
├── setup-readiness.sh       # Environment validation
├── validate-hooks.sh        # Hook syntax check
├── update-priorities-health.sh  # Priority updates
├── weekly-context-analysis.sh   # Weekly maintenance
├── weekly-docker-restart.sh     # Docker maintenance
└── weekly-health-check.sh       # Health check
```

**Hooks** (18 total):
```
.claude/hooks/
├── session-start.js         # SessionStart: Load context
├── session-stop.js          # Stop: Desktop notification
├── subagent-stop.js         # SubagentStop: Agent chaining
├── pre-compact.js           # PreCompact: Preserve state
├── workspace-guard.js       # PreToolUse: Block forbidden paths
├── dangerous-op-guard.js    # PreToolUse: Block dangerous commands
├── permission-gate.js       # UserPromptSubmit: Soft gate
├── secret-scanner.js        # PreToolUse: Block secrets
├── audit-logger.js          # PreToolUse: Log executions
├── session-tracker.js       # Notification: Track lifecycle
├── session-exit-enforcer.js # PostToolUse: Track activity
├── context-reminder.js      # PostToolUse: Prompt documentation
├── docker-health-check.js   # PostToolUse: Container health
├── memory-maintenance.js    # PostToolUse: Entity tracking
├── doc-sync-trigger.js      # PostToolUse: Change tracking
├── self-correction-capture.js  # UserPromptSubmit: Correction detection
├── worktree-manager.js      # PostToolUse: Worktree tracking
└── project-detector.js      # UserPromptSubmit: URL detection
```

**Commands** (core custom commands):
```
.claude/commands/
├── checkpoint.md            # Session checkpoint for MCP restart
├── end-session.md           # Clean exit with commit
├── setup.md                 # Initial configuration
├── tooling-health.md        # Tooling validation
├── jarvis.md                # Quick access menu
├── intelligent-compress.md  # JICM compression
├── autocompact-threshold.md # Threshold config
└── orchestration/           # Orchestration commands
```
Note: Native commands (/help, /status, /compact, /clear) restored.
Auto-* wrappers migrated to autonomous-commands skill.

---

## Part 7: Agents and Subagents Architecture

The distinction between built-in subagents and custom agents is nuanced. This section establishes the theoretical framework and practical guidance for agent selection.

### 7.1 Agent Taxonomy in Claude Code

Claude Code provides **two fundamentally different agent mechanisms**:

```
┌─────────────────────────────────────────────────────────────────┐
│                    BUILT-IN SUBAGENTS                           │
│  (Task tool with subagent_type parameter)                       │
│                                                                 │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │   Explore    │  │    Plan      │  │  General     │          │
│  │  (read-only) │  │ (architect)  │  │  (multi-step)│          │
│  └──────────────┘  └──────────────┘  └──────────────┘          │
│                                                                 │
│  ┌──────────────┐  ┌──────────────┐                            │
│  │   Haiku      │  │  Plugin      │                            │
│  │  (fast/cheap)│  │  Agents      │                            │
│  └──────────────┘  └──────────────┘                            │
└─────────────────────────────────────────────────────────────────┘
                             ▲
                             │ System-defined capabilities
                             │ Limited customization
                             │
─────────────────────────────┼─────────────────────────────────────
                             │
                             │ User-defined capabilities
                             │ Full customization
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                     CUSTOM AGENTS                               │
│  (Task tool with custom subagent_type)                          │
│                                                                 │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │   Domain     │  │  Workflow    │  │  Validation  │          │
│  │ Specialists  │  │ Coordinators │  │   Agents     │          │
│  └──────────────┘  └──────────────┘  └──────────────┘          │
│                                                                 │
│  ┌──────────────┐  ┌──────────────┐                            │
│  │   Memory/    │  │   Tool-      │                            │
│  │   Learning   │  │   Scoped     │                            │
│  └──────────────┘  └──────────────┘                            │
└─────────────────────────────────────────────────────────────────┘
```

### 7.2 Built-in Subagents

Claude Code ships with **three core subagent types**, each optimized for specific use cases:

| Subagent | Purpose | Tools Available | Best For |
|----------|---------|-----------------|----------|
| **Explore** | Fast codebase exploration | Read-only (Glob, Grep, Read) | Finding files, understanding structure |
| **Plan** | Architecture design | All tools | Implementation planning, design decisions |
| **General-purpose** | Multi-step tasks | All tools | Complex tasks, open-ended exploration |

**Key Characteristics**:
- **Context Isolation**: Each spawns with fresh context (~20K token overhead)
- **Inherited Context**: Receives full conversation history before the Task call
- **Controlled Scope**: Tool access defined by Claude Code, not customizable
- **Resume Support**: Can continue via `resume` parameter with agent ID

**When to Use Built-in Subagents**:

```
Use EXPLORE when:
├── Searching for files by pattern (vs. needle query)
├── Understanding codebase structure
├── Answering "where is X handled?"
├── Finding all files matching criteria
└── Gathering context without modifying

Use PLAN when:
├── Designing implementation approach
├── Making architectural decisions
├── User should approve before coding
├── Multiple valid approaches exist
└── Multi-file changes needed

Use GENERAL-PURPOSE when:
├── Task requires 3-10 steps
├── Open-ended exploration needed
├── Combination of reading and writing
├── No specialized agent fits
└── Research + implementation mixed
```

### 7.3 Custom Agents (Jarvis Extension)

Custom agents extend Claude Code's capabilities with **domain-specific expertise, structured workflows, and specialized tool access**.

**Jarvis Custom Agents**:

| Agent | Domain | Specialty | Key Patterns |
|-------|--------|-----------|--------------|
| `docker-deployer` | Infrastructure | Container deployment | 5-phase validation, conflict detection |
| `service-troubleshooter` | Operations | Issue diagnosis | Structured investigation, root cause analysis |
| `deep-research` | Research | Multi-source synthesis | Citation tracking, source validation |
| `memory-bank-synchronizer` | Documentation | Safe doc updates | Content classification, user section preservation |

**Custom Agent Role Categories** (from agentic development theory):

| Role | Purpose | Example |
|------|---------|---------|
| **Architects** | High-level design, system overview | Plan subagent, feature-dev plugin |
| **Specialists** | Deep domain expertise | docker-deployer, service-troubleshooter |
| **Workers** | Task execution, implementation | General-purpose, Explore |
| **Validators** | Quality assurance, verification | pr-review-toolkit, test-runner |
| **Coordinators** | Multi-agent orchestration | memory-bank-synchronizer |

**Custom Agent Capabilities** (beyond built-in):

```
CUSTOM AGENTS CAN:
├── Define persona and communication style
├── Restrict tool access (tool scoping)
├── Enforce structured output formats
├── Include domain-specific knowledge
├── Implement multi-phase workflows
├── Maintain learning/memory across invocations
└── Chain to other agents on completion

BUILT-IN SUBAGENTS CANNOT:
├── Customize persona (fixed by Claude Code)
├── Restrict tools (defined by type)
├── Enforce output formats (flexible)
├── Include domain knowledge (general only)
└── Chain agents (manual coordination required)
```

### 7.4 Three-Tier Agent Selection Strategy

Selection follows a **complexity escalation** pattern:

```
Task Received
     │
     ▼
┌─────────────────────────────────────────────────────────────────┐
│ TIER 1: DIRECT TOOLS (No Agent)                                 │
│ ─────────────────────────────────                               │
│ Question: Can this be done with atomic operations?              │
│                                                                 │
│ YES → Use Read, Write, Edit, Glob, Grep, Bash, etc.             │
│                                                                 │
│ Criteria:                                                       │
│ • 1-3 operations                                                │
│ • No complex reasoning needed                                   │
│ • File paths/patterns known                                     │
│ • No context isolation needed                                   │
└─────────────────────────────────────────────────────────────────┘
     │ NO (needs exploration or planning)
     ▼
┌─────────────────────────────────────────────────────────────────┐
│ TIER 2: BUILT-IN SUBAGENTS (Standard Patterns)                  │
│ ───────────────────────────────────────────────                 │
│ Question: Does a built-in subagent fit the pattern?             │
│                                                                 │
│ • Codebase exploration → Explore                                │
│ • Architecture/planning → Plan                                  │
│ • Multi-step (3-10 ops) → General-purpose                       │
│                                                                 │
│ Criteria:                                                       │
│ • Standard development patterns                                 │
│ • No domain-specific knowledge needed                           │
│ • No custom workflow required                                   │
│ • No tool restrictions needed                                   │
└─────────────────────────────────────────────────────────────────┘
     │ NO (needs specialization)
     ▼
┌─────────────────────────────────────────────────────────────────┐
│ TIER 3: CUSTOM AGENTS (Domain Expertise)                        │
│ ─────────────────────────────────────────                       │
│ Question: Does this need specialized expertise or workflow?     │
│                                                                 │
│ • Docker deployment → docker-deployer                           │
│ • Service issues → service-troubleshooter                       │
│ • Deep research → deep-research                                 │
│ • Doc sync → memory-bank-synchronizer                           │
│                                                                 │
│ Criteria:                                                       │
│ • Domain-specific knowledge required                            │
│ • Structured multi-phase workflow                               │
│ • Tool scoping beneficial                                       │
│ • Learning/memory needed                                        │
│ • Quality validation steps                                      │
└─────────────────────────────────────────────────────────────────┘
```

### 7.5 Agent Design Patterns

**Orchestration Patterns** (for complex multi-agent work):

| Pattern | Structure | Use Case |
|---------|-----------|----------|
| **Hierarchical** | Coordinator → Specialists | Feature development with phases |
| **Sequential** | Agent A → Agent B → Agent C | Pipeline processing |
| **Parallel** | Coordinator → [Workers] → Aggregator | Independent subtasks |
| **Generator/Critic** | Creator ↔ Validator | Quality-critical outputs |
| **Dispatcher** | Router → Appropriate Agent | Task-based routing |

**Jarvis Examples**:

```
HIERARCHICAL: feature-dev plugin
├── Planner (defines approach)
├── Implementer (writes code)
├── Tester (validates)
└── Documenter (records)

GENERATOR/CRITIC: pr-review-toolkit
├── Analyzer (identifies issues)
└── Validator (confirms findings)

SEQUENTIAL: docker-deployer
├── Discovery (find containers)
├── Analysis (check conflicts)
├── Deployment (apply changes)
├── Validation (health check)
└── Documentation (update records)
```

### 7.6 Context and Token Considerations

**Context Isolation Trade-offs**:

| Aspect | Benefit | Cost |
|--------|---------|------|
| **Fresh Context** | Clean slate, focused work | ~20K token overhead per Task |
| **Main Preservation** | Primary context untouched | Agent doesn't see updates |
| **Specialized Focus** | Domain-specific reasoning | Coordination overhead |
| **Parallel Execution** | Multiple agents concurrently | 3-4x token consumption |

**Token-Efficient Agent Usage**:

```
GUIDELINES:
├── Don't spawn agents for atomic operations
├── Prefer Explore (read-only) over General-purpose for searches
├── Use haiku model for simple agent tasks
├── Batch related work into single agent invocation
├── Resume agents instead of spawning new ones
└── Consider direct tools first (TIER 1)

ANTI-PATTERNS:
├── Agent for single file read
├── Agent for simple git operation
├── New agent per micro-task
├── General-purpose for known-path operations
└── Heavy agents without clear justification
```

### 7.7 Agent Selection Decision Matrix

| Task Characteristic | Recommended | Avoid |
|---------------------|-------------|-------|
| Single file operation | Direct tools | Any agent |
| Find files by pattern | Explore | General-purpose |
| Understand codebase | Explore | Direct tools |
| Design approach | Plan | General-purpose |
| Multi-step implementation | General-purpose | Direct tools |
| Docker deployment | docker-deployer | General-purpose |
| Service diagnosis | service-troubleshooter | General-purpose |
| Research synthesis | deep-research | WebSearch only |
| Documentation sync | memory-bank-synchronizer | Direct edits |
| Unknown domain | General-purpose + escalate | Custom agent without fit |

### 7.8 When to Create New Custom Agents

**Create a custom agent when**:

```
STRONG SIGNALS:
├── Domain expertise needed repeatedly (3+ times)
├── Structured multi-phase workflow exists
├── Tool scoping would improve safety
├── Output format must be consistent
├── Quality validation steps required
└── Knowledge accumulates over invocations

WEAK SIGNALS (consider but don't require agent):
├── Single-use complex task → General-purpose
├── Ad-hoc exploration → Explore
├── One-time planning → Plan
└── Standard dev workflow → Direct tools + skills
```

**Agent Definition Template**:

```yaml
# .claude/agents/my-agent.md
---
name: my-agent
description: One-line purpose
tools: [Read, Write, Bash]  # Restricted set
persona: |
  You are a specialist in X domain.
  You follow Y methodology.
  You always Z before completing.
---

## Workflow

1. Phase 1: Discovery
   - [steps]

2. Phase 2: Analysis
   - [steps]

3. Phase 3: Execution
   - [steps]

4. Phase 4: Validation
   - [steps]

## Output Format

[structured output template]
```

---

## Related Documentation

- @.claude/context/integrations/capability-map.yaml — Task→tool mapping
- @.claude/context/integrations/overlap-analysis.md — Conflict resolution
- @.claude/context/patterns/mcp-loading-strategy.md — MCP tier system
- @.claude/context/patterns/agent-selection-pattern.md — Agent vs subagent
- @.claude/context/patterns/plugin-decomposition-pattern.md — Extraction process
- @.claude/context/integrations/skills-selection-guide.md — Skill selection
- @.claude/hooks/README.md — Hook documentation

---

## Changelog

- **2026-01-09 (v0.7)**: Multi-Agent Orchestration Framework
  - **Clarification**: Removed mega-agent concept (Jeeves/Wallace are separate Archons, not delegation targets)
  - **Tier 3 Reframe**: Now explicitly "Multi-Agent Orchestration" (agent teams, workflows, feedback loops)
  - **Multi-Agent Team Patterns**: Sequential Pipeline, Feedback Loop, Parallel with Aggregation, Specialist Consultation
  - **Agent Team Configuration**: YAML example for team definitions
  - **Updated Examples**: Example 4 now demonstrates agent team orchestration

- **2026-01-09 (v0.6)**: Orchestration-First Paradigm (Major Revision)
  - **Paradigm Shift**: Reframed from "tool-first" to "orchestration-first" thinking
  - **The Orchestration Principle**: Jarvis as Core Orchestrator who strategically delegates
  - **Delegation Decision Framework**: Primary question is now "self-execute or delegate?"
  - **Context Value Matrix**: Decision framework based on difficulty/bloat/procedural value
  - **The Orchestration Tiers**: Three tiers (Self-Execute/Subagents → Custom Agents → Agent Teams)
  - **Summary Return Pattern**: When to require action summaries from delegated tasks
  - **Agent-Internal Progressive Disclosure**: Agents manage their own tool load/unload cycles
  - **Complete Orchestration Hierarchy**: Three-stage process (Delegation → Context → Tool Selection)
  - **Practical Examples**: Four detailed delegation decision examples
  - **Revised Selection Factors**: Context Value and Context Bloat Risk now CRITICAL weight

- **2026-01-09 (v0.5)**: Unified Three-Tier Framework + Deeper Insights
  - Introduced Universal Three-Tier Framework (metadata/core/links) as unifying principle
  - Built-in Tools: Added Jarvis Selection Guidance concept (loading fixed, guidance controllable)
  - Subagents: Added Orchestration Metadata pattern with pre-spawn MCP/tool linking
  - Plugins: Explicitly marked as DECOMPOSITION TARGETS (not optimization targets)
  - Hooks: Reframed as Agent Hook-Awareness requirement (blocking/informational/silent)
  - Added hook-awareness template for custom agent definitions
  - Revised summary matrix with Loading Control vs Selection Guidance dimensions
  - Added Jarvis Deliverables table (4 new documents to create)
  - Key insight: Selection Guidance layer applies even where loading is fixed

- **2026-01-09 (v0.4)**: Expanded Progressive Disclosure Architecture
  - Part 2: Comprehensive coverage of all 9 tool modalities
  - Built-in Tools: Fixed overhead analysis
  - Skills: Three-tier loading pattern with design guidelines
  - Subagents: Spawn isolation strategy
  - MCPs: Three strategies (tiered loading, dynamic toolset, schema compression)
  - Plugins: Decomposition and selection strategies
  - Custom Agents: Three-tier agent loading pattern
  - Scripts: Output progressive pattern (summary/verbose/debug)
  - Hooks: Context injection strategy (not progressive disclosure)
  - Commands: Two-tier loading pattern
  - Summary matrix with applicability ratings
  - Key takeaways for optimization priorities

- **2026-01-09 (v0.3)**: Added Agents and Subagents Architecture
  - Part 7: Comprehensive agent/subagent theory from research
  - Agent taxonomy (built-in vs custom)
  - Three-tier agent selection strategy
  - Agent design patterns (hierarchical, sequential, parallel, etc.)
  - Custom agent role categories (architects, specialists, workers, validators)
  - Context isolation trade-offs and token considerations
  - Agent selection decision matrix
  - When to create new custom agents (strong vs weak signals)
  - Agent definition template
  - Corrected characteristics table (custom agents for domain expertise, not just learning)

- **2026-01-09 (v0.2)**: Added Local Tooling Layer
  - Three-layer model (Knowledge + Integration + Local Tooling)
  - Part 6: Scripts, Hooks, Commands analysis
  - Selection decision tree for local tooling
  - Complete component inventory (12 scripts, 18 hooks, 13 commands)
  - Hook behavior modes (blocking, informational, silent)

- **2026-01-09 (v0.1)**: Initial draft based on research synthesis
  - Two-layer model (Knowledge + Integration)
  - Precedence hierarchy
  - Progressive disclosure architecture
  - Component extraction workflow
  - Selection quality framework

---

*Tool Selection Intelligence Pattern v0.6 — PR-9 Foundation (2026-01-09)*
