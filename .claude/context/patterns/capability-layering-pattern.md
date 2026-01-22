# Capability Layering Pattern

**Status**: Active
**Created**: 2026-01-20
**Purpose**: Maximize repeatability and minimize AI dependency for automated tasks

## Overview

The Capability Layering pattern ensures that automated capabilities are built through deterministic layers, with AI used only for creation and routing—not repeated execution.

**Core Principle**: AI creates automation once, execution flows through deterministic CLI calls thereafter.

## The Layers

```
┌─────────────────────────────────────────────────────────────────┐
│  LAYER 5: USER REQUEST                                          │
│  Natural language or programmatic delegation                    │
│  "Check my infrastructure health"                               │
├─────────────────────────────────────────────────────────────────┤
│  LAYER 4: PROMPT (Skill / Agent / Command)                      │
│  Routes request to correct CLI, handles edge cases              │
│  /check-health docker                                           │
├─────────────────────────────────────────────────────────────────┤
│  LAYER 3: CLI (Command Line Interface)                          │
│  Bash-callable with arguments, scriptable, schedulable          │
│  ./weekly-health-check.sh --section docker                      │
├─────────────────────────────────────────────────────────────────┤
│  LAYER 2: CODE (Implementation)                                 │
│  Actual logic - script, function, API wrapper                   │
│  weekly-health-check.sh (450 lines of bash)                     │
├─────────────────────────────────────────────────────────────────┤
│  LAYER 1: IDEA (Capability Goal)                                │
│  What we want to accomplish                                     │
│  "Validate infrastructure health automatically"                 │
└─────────────────────────────────────────────────────────────────┘
```

## Layer Definitions

### Layer 1: IDEA
- The capability goal or user need
- Example: "I want to sync my repo to GitHub"
- This is the starting point for new capabilities

### Layer 2: CODE
- The actual implementation that does the work
- Can be: Bash script, Python script, TypeScript tool, API wrapper
- Must be: Testable, version-controlled, documented
- Location: `Scripts/`, `.claude/skills/*/tools/`, or project-specific

### Layer 3: CLI
- Command-line interface that exposes the code
- Requirements:
  - Callable via `bash` or direct execution
  - Accepts arguments/flags for configuration
  - Returns meaningful exit codes (0 = success)
  - Outputs to stdout/stderr appropriately
- Benefits: Scriptable, schedulable (cron/systemd), composable

### Layer 4: PROMPT
- Slash command, skill, or agent that routes to CLI
- Responsibilities:
  - Parse natural language intent
  - Map to correct CLI command
  - Handle errors gracefully
  - Provide user-friendly output
- Should NOT: Re-implement logic that exists in CLI

**Prompt Layer Sub-Types** (see related patterns):

| Type | When to Use | Pattern |
|------|-------------|---------|
| **Command → CLI** | Deterministic tasks | @command-invocation-pattern.md |
| **Command → Agent** | Tasks requiring judgment | @agent-invocation-pattern.md |
| **Skill → tools/** | Multi-step workflows | @skill-architecture-pattern.md |
| **Isolated Session** | Heavy MCP usage | @command-invocation-pattern.md |

### Layer 5: USER REQUEST
- Natural language from user
- Programmatic delegation (n8n workflow, another agent, API call)
- The prompt layer handles translation to CLI

## When Each Layer is Appropriate

### Full Stack (All Layers) - PREFERRED

Use when:
- Task is repeatable (will be done again)
- Task is deterministic (same input → same output)
- Task can be automated (no human judgment needed mid-execution)

Examples:
- Health checks
- Git operations
- Backups
- Service restarts
- File operations

### AI-Appropriate (Prompt Only)

Use when task inherently requires:
- Pattern recognition across contexts
- Judgment calls during execution
- Creative synthesis
- Multi-step reasoning with branching decisions

Examples:
- Design review (`/design-review`)
- Code analysis (`/code analyze`)
- Research (`/agent deep-research`)
- Planning (`/plan`)
- Troubleshooting with diagnosis (`/agent service-troubleshooter`)

### Decision Tree

```
Is this task repeatable?
├─ NO → One-off, just do it directly
└─ YES → Continue...
    │
    Does it require judgment DURING execution?
    ├─ YES → AI-Appropriate (Prompt layer only)
    └─ NO → Continue...
        │
        Can it be expressed as: input → deterministic output?
        ├─ YES → FULL STACK (Code → CLI → Prompt)
        └─ NO → Hybrid (Code what you can, AI for the rest)
```

## Benefits of Full Stack

| Benefit | Explanation |
|---------|-------------|
| **Cost Control** | No tokens burned for repeated execution |
| **Predictability** | Same input always produces same output |
| **Schedulability** | Can run via cron, systemd, n8n without AI |
| **Composability** | CLI commands can be chained, piped, scripted |
| **Debuggability** | Logs, exit codes, deterministic behavior |
| **Speed** | No API latency for execution |
| **Offline Capable** | Works without internet (for local operations) |

## Implementation Template

When creating a new capability, follow this template:

### Step 1: Define the IDEA
```markdown
## Capability: [Name]
**Goal**: What should this accomplish?
**Trigger**: When would someone use this?
**Inputs**: What information is needed?
**Outputs**: What should be produced?
```

### Step 2: Write the CODE
```bash
#!/bin/bash
# Location: Scripts/[capability-name].sh
# Purpose: [One line description]
# Usage: ./[capability-name].sh [args]

set -euo pipefail

# Parse arguments
# Implement logic
# Output results
# Exit with appropriate code
```

### Step 3: Expose via CLI
Ensure the script:
- Is executable (`chmod +x`)
- Has a `--help` flag
- Accepts arguments for all configurable options
- Documents usage in header comments

### Step 4: Create PROMPT layer
```markdown
# /[capability-name]

## Usage
/[capability-name] [arguments]

## Execution
Run the CLI:
\`\`\`bash
~/Scripts/[capability-name].sh $ARGUMENTS
\`\`\`

Report the results to the user.
```

## Anti-Patterns

### Anti-Pattern 1: Prompt-Heavy
```
❌ /sync-git command that has LLM run 10 git commands each time
✅ sync-git.sh script that /sync-git calls
```

### Anti-Pattern 2: Reinventing in Prompt
```
❌ Prompt that re-implements health check logic
✅ Prompt that calls existing health check script
```

### Anti-Pattern 3: No CLI Layer
```
❌ Code exists but only callable through AI
✅ Code exposed via CLI, then AI routes to it
```

### Anti-Pattern 4: Over-Automating AI Tasks
```
❌ Trying to script design review decisions
✅ Accepting that some tasks need AI judgment
```

## Audit Checklist

For each capability, verify:

- [ ] **CODE exists**: Is there an implementation (script/function)?
- [ ] **CLI callable**: Can it be run from bash with arguments?
- [ ] **PROMPT routes**: Does the prompt call CLI (not re-implement)?
- [ ] **Documented**: Is usage documented in the script and prompt?
- [ ] **Tested**: Has it been run successfully?
- [ ] **Scheduled** (if recurring): Is it in cron/systemd?

## Migration Path

For existing Prompt-Heavy capabilities:

1. **Extract Logic**: Identify the commands/steps the LLM runs
2. **Create Script**: Write bash script that does those steps
3. **Test CLI**: Verify script works standalone
4. **Update Prompt**: Change prompt to call script instead of re-implementing
5. **Document**: Update any related documentation

## Related Concepts

See: [Pattern vs Workflow vs Script](#pattern-vs-workflow-vs-script) section below.

---

## Pattern vs Workflow vs Script

These terms are often confused. Here's how they differ in this system:

### Pattern

**What it is**: A reusable approach or design principle that guides HOW to build things.

**Characteristics**:
- Conceptual, not executable
- Describes "the way we do things"
- Applied across many different implementations
- Lives in `.claude/context/patterns/`

**Examples**:
- Capability Layering Pattern (this document)
- PARC Design Review Pattern
- Memory Storage Pattern
- Code Before Prompts Pattern

**Analogy**: A pattern is like an architectural style (e.g., "Victorian"). It guides decisions but isn't a specific house.

---

### Workflow

**What it is**: A documented sequence of steps to accomplish a specific outcome.

**Characteristics**:
- Procedural (step 1, step 2, step 3...)
- May combine multiple tools, commands, or patterns
- Describes WHAT to do in order
- Lives in `.claude/context/workflows/`

**Examples**:
- Session Exit Workflow (19 steps across 4 phases)
- Priority Validation Workflow
- Project Registration Workflow

**Analogy**: A workflow is like a recipe. It tells you what to do in what order.

---

### Script

**What it is**: Executable code that performs a specific task.

**Characteristics**:
- Actually runs (bash, python, etc.)
- Takes inputs, produces outputs
- Deterministic (same input → same output)
- Lives in `Scripts/` or `.claude/skills/*/tools/`

**Examples**:
- `weekly-health-check.sh`
- `sync-git.sh`
- `register-service.sh`

**Analogy**: A script is like a kitchen appliance. You push a button, it does a thing.

---

### How They Relate

```
PATTERN (how to think)
    ↓ guides
WORKFLOW (what to do)
    ↓ implemented by
SCRIPT (executable code)
    ↓ exposed via
CLI (command line)
    ↓ routed by
PROMPT (slash command)
```

**Example Flow**:
1. **Pattern**: "Capability Layering" says we should have deterministic CLI
2. **Workflow**: "Creating a New Capability" workflow describes the steps
3. **Script**: `new-capability.sh` is the actual code
4. **CLI**: `./new-capability.sh --name foo --type bash`
5. **Prompt**: `/new-capability foo bash`

---

### Quick Reference

| Concept | Question It Answers | Location | Executable? |
|---------|---------------------|----------|-------------|
| Pattern | "How should we approach this?" | `patterns/` | No |
| Workflow | "What steps do I follow?" | `workflows/` | No |
| Script | "What code runs?" | `Scripts/` | Yes |
| Prompt | "How do I invoke it?" | `commands/` | Via AI |

---

## Versioning

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-01-20 | Initial pattern definition |
| 1.1 | 2026-01-21 | Added prompt layer sub-types and pattern references |

## References

- @.claude/context/audits/cli-capability-audit.md - Full audit of current capabilities
- @.claude/context/audits/skill-system-audit.md - Skill system compliance audit
- @.claude/context/patterns/command-invocation-pattern.md - Command routing patterns
- @.claude/context/patterns/skill-architecture-pattern.md - Skill structure requirements
- @.claude/context/patterns/agent-invocation-pattern.md - Agent definition and invocation
- @.claude/skills/_template/ - Template following Code Before Prompts
- @Scripts/README.md - Script documentation
