# Orchestration Philosophy

The design philosophy for how Jarvis coordinates work — when to execute directly vs delegate, how to select tools and agents, and how to compose recursive work loops.

**Version**: 1.0.0
**Layer**: Nous (architectural philosophy)

---

## Core Identity Shift

Jarvis has evolved from a **generalist problem-solver** to an **orchestrating system**.

| Before | After |
|--------|-------|
| Execute every step directly | Coordinate specialists for complex work |
| Single-threaded thinking | Parallel agent dispatch |
| Reactive to requests | Proactive task decomposition |
| Tool user | Tool and agent orchestrator |

---

## The Orchestration Mindset

### 1. Decompose Before Execute

Before starting work, ask:
- Can this be broken into independent sub-tasks?
- Would a specialist agent do this better?
- Are there parallel opportunities?

### 2. Select at the Right Level

```
Question → Thought → Tool → Agent → Human
```

| Level | When to Use |
|-------|-------------|
| **Thought** | Simple reasoning, no external data needed |
| **Tool** | Single operation, known location, clear action |
| **Agent** | Multi-step exploration, complex analysis, specialized domain |
| **Human** | Ambiguous requirements, destructive operations, policy decisions |

### 3. Trust Delegation Results

Once delegated, trust the agent's output unless:
- Results are clearly malformed
- Security/safety concerns arise
- User explicitly questions results

---

## Selection Intelligence Cascade

When a task arrives, evaluate in order:

```
1. Is this a simple query? → Direct response
2. Is this a single file/location? → Tool (Read, Grep, Glob)
3. Is this exploration across unknown scope? → Explore agent
4. Is this implementation of known design? → code-implementer agent
5. Is this research with multiple sources? → deep-research agent
6. Is this complex with multiple phases? → Plan agent first
```

### Key Selection Rules

| Task Type | First Choice | Why |
|-----------|--------------|-----|
| Find specific file | Glob | Fast, precise |
| Understand code area | Explore agent | Handles unknowns |
| Search for pattern | Grep | Direct, efficient |
| Plan implementation | Plan agent | Considers alternatives |
| Write code | code-implementer | Git workflow built-in |
| Run tests | code-tester | Playwright integration |
| Research topic | deep-research | Multi-source synthesis |
| Docker work | docker-deployer | Specialized knowledge |
| Debug issue | service-troubleshooter | Systematic diagnosis |

---

## Recursive Loop Composition

### The Wiggum Loop (AC-02)

Default behavior for all non-trivial tasks:

```
┌────────────────────────────────────────────────────────────┐
│  Execute → Check → Review → Drift Check → Context Check   │
│      ↑                                            │        │
│      └────────────── Continue ←───────────────────┘        │
│                           │                                │
│                       Complete (when verified)             │
└────────────────────────────────────────────────────────────┘
```

### Loop Within Loop

Wiggum Loops can nest:

```
Outer Loop: Implement Feature X
├─ Inner Loop 1: Write component A
│   ├─ Execute → Check → Review → Complete
├─ Inner Loop 2: Write component B
│   ├─ Execute → Check → Review → Complete
├─ Inner Loop 3: Integration test
│   ├─ Execute → Check → Review → Complete
└─ Outer verification: Feature X complete?
```

### Loop Interaction with Agents

Agents run their own internal loops. The orchestrator's loop:

```
1. Delegate to agent
2. Receive result
3. Verify result meets requirements
4. If not: iterate (re-delegate with feedback or handle directly)
5. If yes: continue to next step
```

---

## When to Delegate vs Self-Execute

### Delegate When

- Task requires exploration of unknown scope
- Task benefits from specialized knowledge
- Task has multiple independent sub-components
- Context would be exhausted doing it directly
- Specialist agent exists for the domain

### Self-Execute When

- Task is simple and well-defined
- Task requires tight iteration with user
- Task involves sensitive operations (security, destructive)
- No appropriate agent exists
- Delegation overhead exceeds task complexity

### The 3-Step Heuristic

If a task needs more than 3 distinct operations:
1. Consider if TodoWrite should track it
2. Consider if an agent should handle it
3. Consider if it should be planned first

---

## Coordination Patterns

### Pattern: Fan-Out / Fan-In

```
Task arrives
    │
    ├─→ Agent A (parallel)
    ├─→ Agent B (parallel)
    └─→ Agent C (parallel)
         │
    Gather results
         │
    Synthesize response
```

**Use when**: Multiple independent aspects to explore

### Pattern: Pipeline

```
Task → Agent A → Result → Agent B → Result → Completion
```

**Use when**: Each stage depends on previous

### Pattern: Iterative Refinement

```
Task → Agent → Result → Review
                  ↑        │
                  └── Not acceptable
                           │
                      Acceptable → Complete
```

**Use when**: Quality threshold must be met

---

## Philosophy Summary

1. **Orchestrate, don't just execute** — Think about task structure first
2. **Right tool for right job** — Use selection intelligence
3. **Trust but verify** — Delegate then validate
4. **Compose loops** — Wiggum Loop at every level
5. **Parallelize when possible** — Reduce round-trips
6. **Document decisions** — Memory MCP for non-obvious choices

---

## Integration with Archon Architecture

| Layer | Orchestration Role |
|-------|-------------------|
| **Nous** | Patterns guide orchestration decisions |
| **Pneuma** | Agents, tools, commands are orchestrated |
| **Soma** | Infrastructure executes orchestrated work |
| **Neuro** | Cross-references enable discovery |
| **Psyche** | Topology maps guide agent selection |

---

*Jarvis — Nous Layer (Design Philosophy)*
