# Skill Architecture Pattern

**Status**: Active
**Created**: 2026-01-21
**Purpose**: Define the required structure and components for skills to ensure consistency and reusability

---

## Overview

Skills are comprehensive workflow guides that consolidate related commands, hooks, and patterns. Unlike commands (single actions), skills provide end-to-end guidance for complex workflows.

**Core Principle**: Skills combine AI guidance with deterministic tooling via the Code Before Prompts pattern.

---

## Required Structure

Every skill MUST have this structure:

```
.claude/skills/<skill-name>/
├── SKILL.md           # Main skill definition (REQUIRED)
├── config.json        # Skill configuration (RECOMMENDED)
├── tools/             # Deterministic CLI tools (RECOMMENDED)
│   ├── index.ts       # CLI entry point
│   ├── types.ts       # TypeScript types
│   └── operations.ts  # Core operations
├── templates/         # Document templates (OPTIONAL)
│   └── *.md
├── workflows/         # Workflow documentation (OPTIONAL)
│   └── *.md
└── examples/          # Usage examples (OPTIONAL)
    └── *.md
```

---

## Component Requirements

### SKILL.md (Required)

The main skill definition file. Must include:

```markdown
---
name: skill-name
version: 1.0.0
description: One-line description
category: workflow | infrastructure | development
tags: [tag1, tag2]
created: YYYY-MM-DD
updated: YYYY-MM-DD
---

# Skill Name

## Purpose
[What this skill accomplishes]

## Quick Reference
[Table of commands/actions]

## Workflow
[Step-by-step guidance]

## Commands
[List of slash commands this skill provides]

## Integration
[How this skill connects to other systems]
```

### config.json (Recommended)

Machine-readable configuration:

```json
{
  "name": "skill-name",
  "version": "1.0.0",
  "commands": [
    {
      "name": "skill:command",
      "description": "What it does",
      "arguments": "<required> [optional]"
    }
  ],
  "tools": {
    "cli": "tools/index.ts",
    "operations": ["create", "validate", "list"]
  },
  "dependencies": {
    "skills": [],
    "mcps": [],
    "scripts": []
  }
}
```

### tools/ Directory (Recommended)

Deterministic operations in TypeScript. Following the **Code Before Prompts** pattern.

**Why TypeScript**:
- Type safety for complex operations
- Can be compiled to standalone CLI
- Reusable across commands and skills
- Testable independently

**Structure**:

```typescript
// tools/index.ts - CLI entry point
import { Command } from 'commander';
import { createPlan, validatePlan, listPlans } from './operations';

const program = new Command();

program
  .name('skill-name')
  .description('Skill CLI tools')
  .version('1.0.0');

program
  .command('create <name>')
  .description('Create a new item')
  .action(createPlan);

program.parse();
```

```typescript
// tools/types.ts - Type definitions
export interface PlanConfig {
  name: string;
  phases: Phase[];
  metadata: Metadata;
}

export interface Phase {
  id: string;
  name: string;
  tasks: Task[];
}
```

```typescript
// tools/operations.ts - Core logic
import { PlanConfig } from './types';

export function createPlan(name: string, config: Partial<PlanConfig>): PlanConfig {
  // Deterministic logic here
}

export function validatePlan(plan: PlanConfig): ValidationResult {
  // Validation logic
}
```

**Running tools**:
```bash
# Via npx (if package.json exists)
cd .claude/skills/skill-name && npx ts-node tools/index.ts create my-plan

# Via direct execution
npx ts-node .claude/skills/skill-name/tools/index.ts list
```

---

## Skill Categories

### Category: Workflow

Skills that guide multi-step processes.

| Characteristic | Description |
|----------------|-------------|
| **Purpose** | Guide user through complex workflow |
| **Commands** | Multiple related commands |
| **tools/** | Template rendering, validation |
| **Examples** | `structured-planning`, `session-management` |

### Category: Infrastructure

Skills for infrastructure operations.

| Characteristic | Description |
|----------------|-------------|
| **Purpose** | Health checks, discovery, operations |
| **Commands** | Check, discover, register commands |
| **tools/** | Health checks, status parsers |
| **Examples** | `infrastructure-ops`, `audio-tools` |

### Category: Development

Skills for development workflows.

| Characteristic | Description |
|----------------|-------------|
| **Purpose** | Code development assistance |
| **Commands** | Plan, implement, validate, merge |
| **tools/** | Code generation, validation |
| **Examples** | `parallel-dev`, `upgrade` |

---

## Command Naming Convention

Skills expose commands with consistent naming:

```
/skill-name              # Default action or help
/skill-name:action       # Specific action
/skill-name:sub-action   # Sub-action
```

**Examples**:
```
/parallel-dev            # Show status or help
/parallel-dev:plan       # Create a plan
/parallel-dev:start      # Start execution
/parallel-dev:validate   # Run validation
```

**Mapping to files**:
```
/skill-name:action  →  .claude/commands/skill-name/action.md
                   OR  .claude/skills/skill-name/commands/action.md
```

---

## Skill-to-Command Relationship

```
┌─────────────────────────────────────────────────────────────┐
│                         SKILL                                │
│  .claude/skills/parallel-dev/SKILL.md                       │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │
│  │ /pd:plan    │  │ /pd:start   │  │ /pd:validate│   ...   │
│  │ command.md  │  │ command.md  │  │ command.md  │         │
│  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘         │
│         │                │                │                 │
│         ▼                ▼                ▼                 │
│  ┌─────────────────────────────────────────────────┐       │
│  │              tools/index.ts                      │       │
│  │  - createPlan()   - startExecution()            │       │
│  │  - validatePlan() - listPlans()                 │       │
│  └─────────────────────────────────────────────────┘       │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## Creating a New Skill

### Step 1: Create Directory Structure

```bash
mkdir -p .claude/skills/my-skill/{tools,templates,workflows,examples}
```

### Step 2: Create SKILL.md

Copy from `_template/SKILL.md` and customize:

```bash
cp .claude/skills/_template/SKILL.md .claude/skills/my-skill/SKILL.md
```

### Step 3: Create config.json

```bash
cp .claude/skills/_template/config.json .claude/skills/my-skill/config.json
```

### Step 4: Implement tools/ (if applicable)

```bash
cp -r .claude/skills/_template/tools .claude/skills/my-skill/tools
# Edit tools/index.ts, types.ts, operations.ts
```

### Step 5: Create Commands

For each command the skill provides:

```bash
touch .claude/commands/my-skill.md           # Default command
touch .claude/commands/my-skill/action.md    # Sub-commands (optional)
```

### Step 6: Register in _index.md

Add entry to `.claude/skills/_index.md`:

```markdown
| [my-skill](my-skill/SKILL.md) | Description | /my-skill, /my-skill:action |
```

---

## Skill Compliance Checklist

For each skill, verify:

- [ ] **SKILL.md exists** with proper frontmatter
- [ ] **config.json exists** (recommended)
- [ ] **tools/ directory** for deterministic operations (recommended)
- [ ] **Commands documented** in SKILL.md
- [ ] **Registered in _index.md**
- [ ] **Examples provided** (optional but helpful)

---

## Current Skill Status

| Skill | SKILL.md | config.json | tools/ | Commands | Status |
|-------|----------|-------------|--------|----------|--------|
| structured-planning | ✅ | ✅ | ✅ | 4 | Compliant |
| parallel-dev | ✅ | ✅ | ✅ | 12+ | Compliant |
| upgrade | ✅ | ✅ | ✅ | 7 | Compliant |
| session-management | ✅ | ❌ | ❌ | 3 | Partial |
| infrastructure-ops | ✅ | ❌ | ❌ | 4 | Partial |
| project-lifecycle | ✅ | ❌ | ❌ | 4 | Partial |
| audio-tools | ✅ | ❌ | ❌ | 4 | Partial |
| _template | ✅ | ✅ | ✅ | N/A | Template |

---

## Anti-Patterns

### Anti-Pattern 1: Skill Without Commands

```
# BAD - Skill exists but no commands invoke it
.claude/skills/orphan-skill/SKILL.md  # exists
.claude/commands/*                     # no references to this skill
```

**Fix**: Create commands that invoke the skill, or reconsider if it should be a skill.

### Anti-Pattern 2: Command Logic in SKILL.md

```markdown
# BAD - SKILL.md has detailed execution steps
## Execution
1. Run `docker ps`
2. Parse output...
3. Check health...
```

**Fix**: Move execution logic to `tools/` or create CLI script.

### Anti-Pattern 3: Duplicate Logic

```
# BAD - Same logic in multiple places
.claude/skills/my-skill/tools/validate.ts
~/Scripts/validate-my-skill.sh          # duplicates logic
```

**Fix**: Single source of truth. Script calls tools/ or vice versa.

---

## Integration Points

### With Commands

Commands invoke skills by following SKILL.md guidance and calling tools/.

### With Agents

Some skills may spawn agents for complex autonomous work:
```markdown
## When to Use Agent

If task requires extended autonomous work, invoke:
- `/agent skill-specific-agent "task"`
```

### With Hooks

Skills may have associated hooks:
```json
{
  "hooks": {
    "pre": ".claude/hooks/skill-pre-hook.js",
    "post": ".claude/hooks/skill-post-hook.js"
  }
}
```

---

## Related Patterns

- @.claude/context/patterns/command-invocation-pattern.md - How commands invoke skills
- @.claude/context/patterns/capability-layering-pattern.md - Layering philosophy
- @.claude/context/patterns/code-before-prompts-pattern.md - Deterministic tools
- @.claude/skills/_index.md - Skill directory
- @.claude/skills/_template/ - Skill template

---

## Versioning

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-01-21 | Initial pattern definition |
