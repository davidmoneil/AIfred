# Parallelization Strategy Pattern

When and how to execute tools, agents, and operations in parallel vs sequential.

**Version**: 1.0.0
**Category**: Operational
**Strictness**: Recommended

---

## Core Principle

**Parallel when independent. Sequential when dependent.**

Operations can run in parallel when:
1. They don't share state
2. One doesn't need the output of another
3. They operate on different resources
4. Failure of one doesn't invalidate the other

---

## Tool Parallelization

### Parallel (Same Message, Multiple Tool Calls)

| Scenario | Example |
|----------|---------|
| Multiple file reads | Reading 5 different files to understand context |
| Independent searches | Grep for pattern A + Glob for pattern B |
| Parallel exploration | Multiple Explore agents for different areas |
| Status checks | git status + docker ps + npm list |
| Independent web fetches | Fetching docs from multiple URLs |

**How**: Include multiple tool calls in a single message.

```
<example>
User asks about authentication flow.
- Read auth/login.ts
- Read auth/middleware.ts
- Read auth/types.ts
All three reads in parallel (one message, three Read tools).
</example>
```

### Sequential (Dependent Operations)

| Scenario | Example |
|----------|---------|
| Read then edit | Must read file before editing it |
| Create then use | mkdir before writing files into it |
| Git workflow | git add → git commit → git push |
| Query then act | Search for files → edit found files |
| Validate then proceed | Check existence → create if missing |

**How**: Wait for tool result before issuing dependent call.

```
<example>
User asks to fix a bug.
1. First: Read the file (must see content)
2. Then: Edit the file (depends on read)
Cannot parallelize — edit needs read result.
</example>
```

---

## Agent Parallelization

### Parallel Agent Dispatch

Use multiple Task tool calls in one message when agents:
- Explore different areas of codebase
- Research independent topics
- Analyze unrelated systems

```
<example>
User asks to understand the authentication and logging systems.
Launch in parallel:
- Explore agent for auth/ directory
- Explore agent for logging/ directory
Both agents work simultaneously.
</example>
```

### Sequential Agent Work

Agents must be sequential when:
- Plan agent informs implementation agent
- Research must complete before design
- One agent's output is another's input

```
<example>
User asks to implement a feature.
1. First: Plan agent designs approach
2. Then: code-implementer uses the plan
Cannot parallelize — implementer needs plan.
</example>
```

---

## MCP Loading Strategy

### Tier-Based Loading

| Tier | Loading | Examples |
|------|---------|----------|
| **Tier 1** | Always loaded | memory, git |
| **Tier 2** | Task-loaded | filesystem, fetch |
| **Tier 3** | On-demand | specialized MCPs |

### Batch MCP Loading

When multiple MCPs needed for a task, load them together:

```
<example>
Research task needs:
- WebSearch (research)
- WebFetch (deep reading)
- Memory (store findings)

Load all three before starting (single loading cost).
</example>
```

---

## Token Efficiency

### Parallel Benefits

- Reduces round-trips (fewer API calls)
- Gathers information faster
- Better context utilization

### Parallel Costs

- All results arrive together (larger response)
- Can't adapt based on intermediate results
- Harder to handle partial failures

### Optimization Guidelines

1. **Batch reads at task start**: Read all potentially relevant files together
2. **Batch searches**: Multiple grep/glob patterns in parallel
3. **Batch status checks**: All health/status queries together
4. **Stream edits**: Edit files sequentially (need verification between)

---

## Decision Matrix

| Question | Yes → | No → |
|----------|-------|------|
| Does B need A's output? | Sequential | Check next |
| Do A and B modify same file? | Sequential | Check next |
| Does order matter for correctness? | Sequential | Check next |
| Would A's failure change B's approach? | Sequential | **Parallel** |

---

## Common Patterns

### Pattern: Exploration Fan-Out

```
User: "Understand the error handling in this codebase"

Parallel:
├─ Explore agent: "Find error handling patterns"
├─ Grep: "class.*Error"
└─ Grep: "catch.*throw"

Then synthesize results.
```

### Pattern: Multi-File Edit

```
User: "Rename userId to accountId everywhere"

Sequential per file:
For each file:
├─ Read file
└─ Edit file (if needed)

But files can be processed independently.
```

### Pattern: Research and Apply

```
User: "Add logging following project conventions"

Sequential:
1. First: Research existing logging patterns
2. Then: Implement following discovered patterns

Research informs implementation.
```

---

## Anti-Patterns

### Anti-Pattern: Speculative Parallel Edits

**Bad**: Edit multiple files in parallel hoping they all work
**Why**: One failure might invalidate others
**Better**: Edit sequentially, verify each

### Anti-Pattern: Dependent Searches in Parallel

**Bad**: Search for function, then search for its callers, in parallel
**Why**: Second search needs first search's result
**Better**: Sequential searches

### Anti-Pattern: Over-Serialization

**Bad**: Read files one at a time when understanding codebase
**Why**: Unnecessary round-trips
**Better**: Batch read related files

---

## Quick Reference

**Parallelize**:
- Multiple reads
- Independent searches
- Status checks
- Separate exploration areas

**Serialize**:
- Read → Edit sequences
- Create → Use sequences
- Any A → B where B needs A's output
- Validation → Action sequences

---

*Jarvis — Nous Layer (Patterns)*
