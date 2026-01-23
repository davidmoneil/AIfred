# Agent Invocation Pattern

**Status**: Active
**Created**: 2026-01-23 (ported from AIfred)
**Purpose**: Standardize how agents are defined, invoked, and managed

---

## Overview

Agents are autonomous workers that operate with their own context window. They're invoked for tasks requiring judgment, exploration, or extended independent work.

**Core Principle**: Agents work autonomously and return summarized results. They're appropriate when tasks require AI reasoning throughout execution.

---

## Agent Types

### Type 1: Custom Agents (Project-Specific)

Defined in `.claude/agents/*.md`. Invoked via Task tool with agent definition.

| Agent | Purpose | Invocation |
|-------|---------|------------|
| `deep-research` | Web research with validation | Task tool with agent def |
| `service-troubleshooter` | Systematic diagnosis | Task tool with agent def |
| `docker-deployer` | Guided deployment | Task tool with agent def |
| `code-analyzer` | Code analysis | Task tool with agent def |
| `code-implementer` | Implementation | Task tool with agent def |
| `code-tester` | Testing | Task tool with agent def |
| `context-compressor` | Context compression | Task tool with agent def |

### Type 2: Built-in Subagents (Claude Code)

Automatically available. Invoked via Task tool with `subagent_type`.

| Subagent | Purpose | When to Use |
|----------|---------|-------------|
| `Explore` | Fast codebase exploration | Finding files, understanding architecture |
| `Plan` | Architecture design | Planning implementation strategies |
| `general-purpose` | Flexible worker | Custom agents, complex tasks |
| `claude-code-guide` | Documentation lookup | Claude Code/SDK questions |

---

## Invocation Methods

### Method 1: Via Task Tool with Subagent Type

The standard way to invoke built-in agents.

```typescript
Task({
  subagent_type: "Explore",
  prompt: "Find all files related to authentication",
  description: "Find auth files"
})
```

**Available subagent_types**:
- `Explore` - Fast exploration
- `Plan` - Architecture planning
- `general-purpose` - Flexible (for custom agents)
- `claude-code-guide` - Documentation

### Method 2: Via Task Tool with Custom Agent

For custom agents, load the agent definition and pass to Task.

```typescript
Task({
  subagent_type: "general-purpose",
  prompt: "[Agent definition loaded] + [User task]",
  description: "Run deep-research agent"
})
```

### Method 3: Via Skill Commands

Some skills invoke agents for specific operations.

```bash
/agent deep-research "topic"
# Internally uses Task tool with deep-research agent definition
```

---

## Agent Definition Structure

### Required Structure

```
.claude/agents/<agent-name>.md
```

### Template

```markdown
# [Agent Name]

**Purpose**: One-line description
**Type**: Research | Troubleshooting | Implementation | Orchestration

---

## Capabilities

- Capability 1
- Capability 2
- Capability 3

## Workflow

### Phase 1: [Name]
[Steps]

### Phase 2: [Name]
[Steps]

### Phase N: Completion
[Summary and output]

---

## Inputs

| Input | Required | Description |
|-------|----------|-------------|
| task | Yes | What to accomplish |
| context | No | Additional context |

## Outputs

| Output | Location | Description |
|--------|----------|-------------|
| Results | Return value | Main output |

---

## Examples

\`\`\`
Example task 1
Example task 2
\`\`\`

---

## Related

- Commands: /command-that-uses-this
- Docs: relevant/doc.md
```

---

## When to Use Agents vs Other Options

```
Is task deterministic?
├─ YES → Use CLI script, not agent
│
└─ NO → Does task require extended autonomous work?
        ├─ YES → Use Agent ✅
        │        - Will work independently
        │        - Returns summary when done
        │        - Appropriate for research, troubleshooting, implementation
        │
        └─ NO → Does task require specific expertise?
                ├─ YES → Use appropriate subagent
                │        - Explore for codebase navigation
                │        - Plan for architecture
                │
                └─ NO → Direct execution may be appropriate
                         - Simple AI tasks
                         - Interactive guidance
```

---

## Agent Session Flow

```
┌─────────────────────────────────────────────────────────────────┐
│  1. INVOCATION                                                   │
│     Task tool call with agent definition                        │
├─────────────────────────────────────────────────────────────────┤
│  2. CONTEXT BUILDING                                            │
│     - Load agent definition from .claude/agents/                │
│     - Build full prompt with task + context                     │
├─────────────────────────────────────────────────────────────────┤
│  3. TASK LAUNCH                                                 │
│     Task(subagent_type: "general-purpose", prompt: context)     │
├─────────────────────────────────────────────────────────────────┤
│  4. AUTONOMOUS WORK                                             │
│     Agent works independently:                                  │
│     - Explores codebase                                         │
│     - Makes decisions                                           │
│     - Creates results                                           │
├─────────────────────────────────────────────────────────────────┤
│  5. COMPLETION                                                  │
│     Returns summary with key findings/results                   │
└─────────────────────────────────────────────────────────────────┘
```

---

## Model Selection

| Task Type | Model | Reasoning |
|-----------|-------|-----------|
| Complex research | `opus` | Needs deep reasoning |
| Implementation | `sonnet` | Good balance |
| Simple diagnostics | `sonnet` | Standard tasks |
| Quick checks | `haiku` | Fast, cheap |

Specify in Task tool:
```typescript
Task({
  subagent_type: "general-purpose",
  model: "sonnet",  // or "opus", "haiku"
  prompt: "..."
})
```

---

## Anti-Patterns

### Anti-Pattern 1: Agent for Simple Tasks

```markdown
# BAD - Agent overkill
Task agent to check if config.json exists
```

**Fix**: Just use Read tool or `ls` directly.

### Anti-Pattern 2: Agent Re-implements CLI

```markdown
# BAD - Agent runs deterministic steps
Agent workflow:
1. Run docker ps
2. Parse output
3. Check health endpoints
```

**Fix**: Create CLI script, or handle directly.

### Anti-Pattern 3: Overly Specific Agent

```markdown
# BAD - Too narrow
Agent for checking nginx port 80 on aiserver only
```

**Fix**: Generalize to service-troubleshooter agent.

---

## Creating New Agents

### When to Create

Create an agent when:
- Task requires autonomous judgment
- Task is invoked repeatedly with variations
- Task involves exploration + decision-making

### Steps

1. **Define purpose** - What does this agent do?
2. **Create definition** - `.claude/agents/<name>.md`
3. **Test invocation** - Use Task tool with definition
4. **Iterate on workflow** - Refine based on results
5. **Create shortcut** (optional) - Dedicated command if frequently used

### Checklist

- [ ] Clear purpose statement
- [ ] Defined workflow phases
- [ ] Documented inputs/outputs
- [ ] Examples provided
- [ ] Tested end-to-end

---

## Related Patterns

- command-invocation-pattern.md - When to use agents vs CLI
- capability-layering-pattern.md - Where agents fit in layers
- code-before-prompts-pattern.md - When to use code vs AI

---

*Ported from AIfred baseline — Jarvis v2.1.0*
