# Jarvis Glossary

Canonical definitions for all terminology used in Jarvis documentation.

**Version**: 1.0.0
**Layer**: Nous (reference)

---

## Project & Entity Terms

| Term | Greek | Definition |
|------|-------|------------|
| **Aion** | αἰών (ay-ON) | The PROJECT — an era/epoch of autopoietic AI entities. "Project Aion" is the initiative to create self-creating AI assistants. |
| **Archon** | ἄρχων (AR-kon) | The ENTITIES — individual autopoietic agents. Jarvis is an Archon. "Archon Architecture" is the blueprint for how an Archon is structured. |

---

## Systems Theory Terms

| Term | Greek | Definition |
|------|-------|------------|
| **Autonomous** | αὐτός + νόμος | Self-governing; volitional action toward goals. Jarvis operates autonomously — driven by internal states toward purposeful action under User guidance. |
| **Autonomic** | αὐτός + νόμος | Reflexive, involuntary, stimulus-triggered. Jarvis operates autonomically — self-regulating systems (the Hippocrenae) maintain operational homeostasis. |
| **Autopoietic** | αὐτός + ποίησις | Self-creating, self-evolving organizational identity. What Jarvis IS — continuously extending and refining his own structure. |
| **Homeodynamics** | ὅμοιος + δύναμις | Balance in motion; dynamic equilibrium. System resilience through continuous adjustment rather than static stability. |
| **Psychosomatic** | ψυχή + σῶμα | Mind-body integration. The Nous-Pneuma-Psyche-Soma-Neuro stack forms Jarvis's unified psychosomatic architecture. |
| **Hippocrenae** | Ἱπποκρήνη | The nine autonomic components (AC-01 through AC-09), named for the spring sacred to the nine Muses. |

**Key insight**: Jarvis HAS autonomic systems (the Hippocrenae). Jarvis IS autopoietic.

---

## Architectural Layers

| Term | Greek | Definition |
|------|-------|------------|
| **Nous** | νοῦς (NOOS) | Intellect, reason. The knowledge layer (`.claude/context/`) — patterns, state, memory. What Jarvis KNOWS. |
| **Pneuma** | πνεῦμα (NYOO-mah) | Vital force, spirit. The capabilities layer (`.claude/`) — skills, agents, commands, hooks. What Jarvis CAN DO. |
| **Soma** | σῶμα (SOH-mah) | Physical body. The infrastructure layer (`/Jarvis/`) — Docker, scripts, interfaces. How Jarvis INTERACTS. |
| **Neuro** | νεύρο (NYOO-roh) | Nerves, sinews. The navigation substrate — cross-references, links, breadcrumbs that connect layers. |
| **Psyche** | ψυχή (sy-KEE) | Soul. The documented maps of the Neuro — topology documentation in `psyche/` directory. |

---

## Autonomic Components (AC)

| ID | Name | Definition |
|----|------|------------|
| **AC-01** | Self-Launch | Session initialization with context awareness. Triggered at session start. |
| **AC-02** | Wiggum Loop | Multi-pass verification. DEFAULT behavior for all non-trivial tasks. |
| **AC-03** | Milestone Review | Independent quality gate at significant work milestones. |
| **AC-04** | JICM | Jarvis Intelligent Context Management. Handles context exhaustion gracefully. |
| **AC-05** | Self-Reflection | Learn from experience. Captures session learnings. |
| **AC-06** | Self-Evolution | Safe self-modification. Proposes and implements improvements. |
| **AC-07** | R&D Cycles | External + internal research. Explores new tools and approaches. |
| **AC-08** | Maintenance | Cleanup, audits, health checks. Scheduled housekeeping. |
| **AC-09** | Session Completion | User-prompted clean exit with documentation. |

---

## Patterns & Frameworks

| Term | Definition |
|------|------------|
| **Wiggum Loop** | Named after Ralph Wiggum. Multi-pass verification: Execute → Check → Review → Drift Check → Context Check → Continue/Complete. |
| **Ralph Loop** | Official Claude Code plugin for autonomous iteration. Related to but distinct from Wiggum Loop. |
| **JICM** | Jarvis Intelligent Context Management. Pattern for handling context exhaustion via compression and checkpointing. |
| **PARC** | Problem-Approach-Result-Considerations. Review structure for design decisions. |
| **DDLA** | Define-Design-Leverage-Assess. Feature development framework. |
| **COSA** | Context-Objectives-Strategy-Actions. Planning framework. |

---

## Tool Selection

| Term | Definition |
|------|------------|
| **MCP** | Model Context Protocol. External tool servers that provide capabilities to Claude. |
| **Tier 1 MCP** | Always loaded (memory, git). Essential for basic operation. |
| **Tier 2 MCP** | Task-loaded (filesystem, fetch). Loaded for specific task types. |
| **Tier 3 MCP** | On-demand (specialized). Loaded only when explicitly needed. |
| **Skill** | On-demand capability package. Loaded via `/skill-name` or Skill tool. |
| **Agent** | Specialized subagent for complex tasks. Launched via Task tool. |
| **Hook** | Event-triggered behavior. Runs on tool calls, session events, etc. |
| **Command** | User-invocable action via `/command-name`. |

---

## Session & State

| Term | Definition |
|------|------------|
| **Session State** | Current work status tracked in `session-state.md`. Updated at checkpoints. |
| **Checkpoint** | Saved state before context-intensive operations or MCP restarts. |
| **Context Budget** | Token allocation strategy. Managed by context-budget-management pattern. |
| **TodoWrite** | Task tracking tool. Used for any task with 2+ steps. |

---

## Project Structure

| Term | Definition |
|------|------------|
| **Project Aion** | Jarvis development meta-project. Lives in `projects/project-aion/`. |
| **AIfred** | Upstream baseline project. Read-only reference at commit `2ea4e8b`. |
| **Integration Chronicle** | Master document tracking AIfred integration decisions and progress. |
| **Capability Matrix** | Master task-to-tool mapping in `integrations/capability-matrix.md`. |

---

## Behavioral Hierarchy

The hierarchy from most to least strict:

```
Standards (MUST follow)
    ↓
Patterns (SHOULD follow)
    ↓
Workflows (Large task procedures)
    ↓
Designs (Architecture philosophy)
    ↓
Plans (Session-level work)
    ↓
Lessons (Memory)
```

---

## Abbreviations

| Abbrev | Expansion |
|--------|-----------|
| **PR** | Pull Request / Project Requirement (context-dependent) |
| **MCP** | Model Context Protocol |
| **AC** | Autonomic Component |
| **JICM** | Jarvis Intelligent Context Management |
| **SOTA** | State Of The Art |
| **RAG** | Retrieval Augmented Generation |

---

*Jarvis — Nous Layer (Reference)*
