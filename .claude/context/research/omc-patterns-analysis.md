# OMC (Oh-My-ClaudeCode) Architecture Analysis

**Date**: 2026-02-08  
**Source**: [GitHub: Yeachan-Heo/oh-my-claudecode](https://github.com/Yeachan-Heo/oh-my-claudecode)  
**Stats**: 28 agents, 37 skills, 31 hooks | Active maintenance, strong community

## What is OMC?

Oh-My-ClaudeCode is a mature multi-agent orchestration framework for Claude Code that abstracts agent selection, execution modes, and skill composition. It operates as a Claude Code plugin providing 5+ execution modes (Autopilot, Ultrapilot, Swarm, Pipeline, Ecomode, Ralph persistence, Ultrawork parallelism) with natural language interface and implicit mode selection.

## Key Patterns Worth Extracting

### 1. **Multi-Tier Model Routing**
Haiku → Sonnet → Opus selection by task complexity. Jarvis currently lacks explicit model tier guidance; OMC's cost optimization pattern (30-50% savings via Ecomode) directly applicable to v5.9.0.

### 2. **Persistent Execution Modes**
Ralph (task completion guarantee) and Ultrawork (maximum parallelism) maintain state across sessions. Jarvis autonomic AC components could benefit from explicit "persist until done" semantics.

### 3. **Hook-Based Context Management**
31 hooks vs. Jarvis's 28 hooks. OMC separates concerns: rules-injector, preemptive-compaction, recovery, permission-handler, think-mode. Jarvis hooks are more distributed; consolidation pattern worth studying.

### 4. **Skill Composition Over Solo Agents**
OMC uses orchestration skills (orchestrate, autopilot, ultrawork) to *compose* other agents rather than hardcoding delegation. Jarvis v5.9.0's manifest router could adopt this pattern for dynamic skill chaining.

### 5. **Configuration Hierarchy**
Project-scoped `.claude/CLAUDE.md` overrides global `~/.claude/CLAUDE.md`. Jarvis already implements this; validates approach.

### 6. **Automatic Skill Learning**
Session learner extracts patterns and reuses them—aligns with Jarvis Memory MCP and pattern accumulation (48 patterns).

## Architectural Differences

| Aspect | OMC | Jarvis |
|--------|-----|--------|
| **Agents** | 28 (predefined, specialized by domain) | 12 (lean core, absorbed subordinates) |
| **Skills** | 37 (orchestration + execution) | 26 (10 discoverable, 15 absorbed) |
| **Hooks** | 31 (concern-separated) | 28 (distributed by component) |
| **Model Routing** | Explicit Haiku/Sonnet/Opus tiers | Ad-hoc per task |
| **Execution Modes** | 5+ (implicit NL selection) | AC-01 to AC-09 (component-based) |
| **Skill Chaining** | Orchestration skills compose agents | Manifest router discovers, doesn't compose |
| **Persistence** | Explicit ralph/ultrawork modes | AC-02 loop (check → review → continue) |

## Recommendations

### Extract These Patterns
1. **Model tier vocabulary** (Ecomode cost optimization)—add to capability-map.yaml weights
2. **Hook consolidation** (rules-injector, preemptive-compaction cluster)—review JICM thresholds alignment
3. **Skill composition primitives** (orchestrate, ultrawork)—extend manifest router to enable dynamic chaining
4. **Automatic learner** (session → reusable skills)—validate against existing pattern accumulation logic

### Do NOT Wholesale Study
- OMC's agent library (28 predefined) incompatible with Jarvis lean-core philosophy
- Plugin architecture (Claude Code marketplace) orthogonal to Jarvis autonomic execution model
- Execution mode keywords (ralph, eco, ulw) valuable idioms but don't require architectural adoption

### Actionable Next Step
Study `/Users/aircannon/Claude/Jarvis/.claude/context/designs/jicm-v5-design-addendum.md` and `.claude/context/psyche/capability-map.yaml` against OMC's hook separation pattern. If JICM threshold formula alignment is weak, adopt OMC's "preemptive-compaction + recovery" pattern to prevent lockout spikes.

---

**Confidence**: High (GitHub source directly analyzed)  
**Applicability**: 6/10 (patterns extractable; wholesale adoption conflicts with Jarvis autonomic philosophy)
