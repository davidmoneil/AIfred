# Code Before Prompts Pattern

**Created**: 2026-01-23 (ported from AIfred)
**Status**: Active
**Source**: Daniel Miessler's PAI v2 "Deterministic AI Architecture"

---

## Overview

The "Code Before Prompts" pattern ensures that **deterministic operations are handled by code**, not AI inference. This provides:

- **Repeatability**: Same inputs always produce same outputs
- **Scalability**: Code handles heavy lifting, AI handles intelligence
- **Reliability**: Fewer hallucinations in routine operations
- **Speed**: Code executes faster than prompt completion

**Principle**: If something can be done deterministically, do it in code. Use AI for intelligence tasks, not routine operations.

---

## When to Apply

| Task Type | Use Code | Use AI |
|-----------|----------|--------|
| File creation/manipulation | Yes | No |
| Template population | Yes | No |
| Validation | Yes | No |
| Path resolution | Yes | No |
| Data transformation | Yes | No |
| Content generation | No | Yes |
| Decision making | No | Yes |
| Analysis/synthesis | No | Yes |
| Creative tasks | No | Yes |

---

## Skill Directory Structure

```
.claude/skills/<skill-name>/
├── SKILL.md           # Main skill definition (prompts, guidance)
├── config.json        # Skill configuration
├── templates/         # Document/file templates
├── workflows/         # Workflow documentation (optional)
├── examples/          # Usage examples (optional)
└── tools/             # Deterministic code tools
    ├── index.ts       # Tool exports and CLI entry
    ├── types.ts       # TypeScript type definitions
    ├── operations.ts  # Core operations (file I/O, validation)
    └── templates.ts   # Template rendering functions
```

---

## Tools Directory Convention

### index.ts (Entry Point)

```typescript
#!/usr/bin/env ts-node
/**
 * Skill Tools Entry Point
 *
 * Usage: npx ts-node tools/index.ts <command> [args]
 *
 * Commands:
 *   create <type> <name>   - Create new file from template
 *   validate <path>        - Validate file against schema
 *   list                   - List available templates
 */

import { createFromTemplate, validate, listTemplates } from './operations';

const [command, ...args] = process.argv.slice(2);

switch (command) {
  case 'create':
    createFromTemplate(args[0], args[1]);
    break;
  case 'validate':
    validate(args[0]);
    break;
  case 'list':
    listTemplates();
    break;
  default:
    console.log('Usage: npx ts-node tools/index.ts <command> [args]');
}
```

### operations.ts (Core Operations)

```typescript
/**
 * Deterministic operations - no AI inference here
 */

import * as fs from 'fs';
import * as path from 'path';

export function createFromTemplate(templateId: string, name: string): string {
  // All logic is deterministic
  // File I/O, string replacement, path resolution
  // No AI involved
}

export function validate(filePath: string): ValidationResult {
  // Deterministic validation logic
  // Check file exists, parse content, validate structure
  // No AI involved
}
```

---

## Integration with SKILL.md

The SKILL.md file should reference tools when applicable:

```markdown
## Using Tools

This skill includes deterministic tools for common operations:

### Create New Spec
\`\`\`bash
npx ts-node .claude/skills/planning/tools/index.ts create spec "My Feature"
\`\`\`

### Validate Spec
\`\`\`bash
npx ts-node .claude/skills/planning/tools/index.ts validate ./specs/my-feature.md
\`\`\`
```

---

## Workflow Example

**Before (Prompt-Only)**:
```
User: Create a new feature spec for user authentication

Claude: [Generates entire file through inference]
         - Risk of inconsistent format
         - Risk of missing sections
         - Each generation may differ
```

**After (Code Before Prompts)**:
```
User: Create a new feature spec for user authentication

Claude:
1. [Code] Create file from template:
   npx ts-node tools/index.ts create feature-spec "user-authentication"

2. [AI] Fill in content sections:
   - Problem Statement: [AI generates]
   - Success Criteria: [AI generates]
   - Technical Approach: [AI generates]

3. [Code] Validate completed spec:
   npx ts-node tools/index.ts validate ./specs/user-authentication.md
```

---

## Adoption Checklist

When creating or updating a skill:

- [ ] Identify deterministic operations (file I/O, validation, formatting)
- [ ] Create `tools/` directory with TypeScript/bash code
- [ ] Move template files to `templates/` directory
- [ ] Add `config.json` with template definitions
- [ ] Update SKILL.md to reference tools
- [ ] Test tools work independently via CLI
- [ ] Document tool commands in SKILL.md

---

## Benefits Realized

| Before | After |
|--------|-------|
| Inconsistent file formats | Consistent templates |
| Manual validation | Automated validation |
| Repeated boilerplate prompts | Single code call |
| Hallucination risk in routine tasks | Deterministic execution |
| Slow for large operations | Fast code execution |

---

## Application in Jarvis

Skills and commands that should follow this pattern:

1. **session-management** - Checkpoint file creation
2. **context-compressor** - Context file operations
3. **history system** - Entry file creation from templates
4. **orchestration** - Task file generation

Future skills should follow this pattern by default.

---

## Related

- capability-layering-pattern.md - The layering philosophy
- command-invocation-pattern.md - Command routing
- agent-invocation-pattern.md - When to use code vs AI

---

*Ported from AIfred baseline — Jarvis v2.1.0*
