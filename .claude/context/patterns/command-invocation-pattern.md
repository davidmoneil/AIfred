# Command Invocation Pattern

**Status**: Active
**Created**: 2026-01-23 (ported from AIfred)
**Purpose**: Standardize how slash commands delegate work to ensure repeatability and efficiency

---

## Overview

This pattern defines how slash commands should invoke their underlying logic. The goal is to minimize prompt-heavy commands that re-implement logic on every execution, instead delegating to reusable CLI scripts, agents, or skills.

**Core Principle**: Commands are thin wrappers that route to the appropriate execution layer.

---

## Invocation Types

### Type 1: CLI-Backed (Preferred for Deterministic Tasks)

Commands that delegate to shell scripts. **This is the ideal pattern** for tasks that don't require AI judgment.

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  /command arg   │ ──▶ │  scripts/       │ ──▶ │    Output       │
│                 │     │  command.sh arg │     │                 │
└─────────────────┘     └─────────────────┘     └─────────────────┘
```

**Command Structure**:
```markdown
---
description: Brief description
argument-hint: <required> [optional]
allowed-tools:
  - Bash(scripts/command-name.sh:*)
---

# /command-name

Brief description of what this does.

## Execution

Run the CLI script:

\`\`\`bash
scripts/command-name.sh $ARGUMENTS
\`\`\`

Report the results to the user.
```

**When to Use**:
- Task is deterministic (same input → same output)
- Task can be automated (no judgment needed)
- Task might need scheduling (cron, systemd)
- Logic should be reusable outside Claude

**Examples**: `/context-analyze`, `/checkpoint`, `/tooling-health`

---

### Type 2: Agent-Backed (For Tasks Requiring Judgment)

Commands that launch agents via the Task tool.

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  /command arg   │ ──▶ │  Task tool      │ ──▶ │  Agent works    │
│                 │     │  + agent def    │     │  autonomously   │
└─────────────────┘     └─────────────────┘     └─────────────────┘
```

**When to Use**:
- Task requires pattern recognition
- Task requires judgment during execution
- Task has branching decisions based on context
- Task benefits from autonomous exploration

**Examples**: `/agent deep-research`, `/agent service-troubleshooter`

---

### Type 3: Skill-Backed (For Multi-Step Workflows)

Commands that are part of a skill's command set.

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  /skill:cmd     │ ──▶ │  Skill workflow │ ──▶ │  tools/ CLI +   │
│                 │     │  from SKILL.md  │     │  AI guidance    │
└─────────────────┘     └─────────────────┘     └─────────────────┘
```

**When to Use**:
- Command is part of a larger workflow
- Multiple related commands share context
- Skill has `tools/` directory for CLI operations
- Workflow combines deterministic + AI steps

**Examples**: `/capture learning`, `/history search`, `/orchestration:plan`

---

### Type 4: Isolated Session (For Heavy MCPs)

Commands that spawn separate Claude sessions with specific MCP configs.

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  /command task  │ ──▶ │  claude --mcp   │ ──▶ │  Isolated       │
│                 │     │  spawn new CLI  │     │  session works  │
└─────────────────┘     └─────────────────┘     └─────────────────┘
```

**When to Use**:
- MCP tools consume >10k tokens
- Task is self-contained
- Results can be summarized as text
- Main session should stay lightweight

---

### Type 5: Direct Execution (Use Sparingly)

Commands where the prompt IS the implementation. **Avoid when possible**.

**When Acceptable**:
- Task inherently requires AI reasoning throughout
- Task cannot be decomposed into deterministic parts
- Task is simple enough that CLI overhead isn't justified
- Task is exploratory/one-off

**Warning Signs** (consider CLI extraction):
- Command is >100 lines
- Command has numbered step-by-step instructions
- Command uses bash commands that could be scripted
- Command is used frequently

---

## Decision Tree

```
Is this task deterministic?
├─ YES → Can it be scripted?
│        ├─ YES → Type 1: CLI-Backed ✅
│        └─ NO  → Why not? (usually can be)
│
└─ NO → Does it require judgment THROUGHOUT?
        ├─ YES → Is it autonomous work?
        │        ├─ YES → Type 2: Agent-Backed
        │        └─ NO  → Type 5: Direct (if simple)
        │
        └─ NO → Can you separate deterministic parts?
                 ├─ YES → Type 3: Skill-Backed (hybrid)
                 └─ NO  → Type 5: Direct (last resort)

Special case: Heavy MCP needed?
└─ YES → Type 4: Isolated Session
```

---

## Command Template

### For New CLI-Backed Commands

```markdown
---
description: [One line description]
argument-hint: [<required>] [optional]
allowed-tools:
  - Bash(scripts/[name].sh:*)
---

# /[name]

[Brief description]

## Usage

\`\`\`
/[name] [arguments]
\`\`\`

## Execution

Run the CLI script:

\`\`\`bash
scripts/[name].sh $ARGUMENTS
\`\`\`

Report the results to the user.

## Options

| Flag | Description |
|------|-------------|
| `-h, --help` | Show help |
| [other flags] | [descriptions] |

## Script Location

\`scripts/[name].sh\`

## Related

- Script: scripts/[name].sh
- Pattern: capability-layering-pattern.md
```

---

## Anti-Patterns

### Anti-Pattern 1: Prompt Re-implements CLI Logic

```markdown
# BAD - command has 50 lines of bash commands inline
## Execution
1. Run `docker ps`
2. Parse output for container X
3. Run `docker inspect`
4. Extract ports...
```

**Fix**: Move to script, command just calls script.

### Anti-Pattern 2: Agent for Deterministic Task

```markdown
# BAD - agent launched for simple check
Launch agent to check if file exists and report status.
```

**Fix**: Use CLI script, agent is overkill.

### Anti-Pattern 3: Direct Execution for Complex Workflow

```markdown
# BAD - 200 line command with 10 numbered steps
## Step 1: ...
## Step 2: ...
...
## Step 10: ...
```

**Fix**: Extract to script or skill with tools/.

---

## Compliance Checklist

For each command, verify:

- [ ] **Invocation type identified**: CLI / Agent / Skill / Isolated / Direct
- [ ] **Appropriate for task**: Deterministic tasks have CLI backing
- [ ] **Script exists** (if CLI-backed): `scripts/[name].sh`
- [ ] **allowed-tools correct**: Matches actual tools used
- [ ] **Documentation complete**: Usage, options, examples, related

---

## Related Patterns

- capability-layering-pattern.md - The layering philosophy
- code-before-prompts-pattern.md - Deterministic code principle
- agent-invocation-pattern.md - Agent launching

---

*Ported from AIfred baseline — Jarvis v2.1.0*
