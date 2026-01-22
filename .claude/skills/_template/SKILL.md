---
name: _template
version: 1.0.0
description: Template for creating skills with Code Before Prompts pattern
category: development
tags: [template, tools, code-before-prompts]
created: 2026-01-20
context: shared
model: sonnet
---

# Skill Template

This is the **template skill** demonstrating the Code Before Prompts pattern. Copy this directory when creating new skills that need deterministic tools.

---

## Overview

| Aspect | Description |
|--------|-------------|
| Purpose | Template for new skills with TypeScript tools |
| Pattern | Code Before Prompts |
| When to Use | Creating skills that need file generation, validation, or data processing |

---

## Quick Actions

| Need | Action | Command |
|------|--------|---------|
| List templates | See available templates | `npx tsx tools/index.ts list` |
| Create document | Generate from template | `npx tsx tools/index.ts create <template> "<name>"` |
| Validate file | Check against schema | `npx tsx tools/index.ts validate <path>` |

---

## Using Tools

This skill includes deterministic tools for common operations.

### List Available Templates

```bash
cd .claude/skills/_template
npx tsx tools/index.ts list
```

### Create from Template

```bash
# Create a default document
npx tsx tools/index.ts create default "My Document"

# Create a specification
npx tsx tools/index.ts create spec "API Design"
```

### Validate a File

```bash
npx tsx tools/index.ts validate ./path/to/file.md
```

---

## How to Use This Template

### 1. Copy the Template

```bash
cp -r .claude/skills/_template .claude/skills/my-new-skill
```

### 2. Update Configuration

Edit `config.json`:
- Change `name` and `description`
- Add your skill-specific templates
- Update validation rules

### 3. Create Templates

Add `.md` files to `templates/` with placeholders:
- `{{NAME}}` - The name provided to the create command
- `{{DATE}}` - Current date (YYYY-MM-DD)
- `{{SLUG}}` - Name converted to lowercase-with-dashes
- `{{TIMESTAMP}}` - Full ISO timestamp

### 4. Extend Tools (Optional)

Add custom commands to `tools/index.ts`:
```typescript
case 'my-custom-command':
  // Your deterministic logic here
  break;
```

### 5. Write SKILL.md

Document your skill's:
- Workflow phases
- Tool commands
- Integration points with TELOS, orchestration, etc.

---

## Code Before Prompts Principle

**Use CODE for**:
- File creation and manipulation
- Template rendering
- Validation
- Data transformation
- Path resolution

**Use AI for**:
- Content generation
- Decision making
- Analysis and synthesis
- Creative tasks

This separation ensures:
- **Repeatability**: Same inputs → same outputs
- **Scalability**: Code handles heavy lifting
- **Reliability**: Fewer hallucinations in routine operations

---

## Integration Points

| Integration | How It Works |
|-------------|--------------|
| TELOS | Links to Goal G-T4 (Deterministic AI Architecture) |
| Pattern | Follows code-before-prompts-pattern.md |
| Skills Index | Listed in _index.md with tools/ marker |

---

## Tool Type Selection

Choose the right tool type for your skill:

| Scenario | Tool Type | Example |
|----------|-----------|---------|
| Complex logic, type safety needed | TypeScript (`tools/`) | Template rendering, validation |
| Simple CLI commands, system ops | Bash (`Scripts/`) | Docker checks, git operations |
| Data gathering for AI analysis | Bash returning JSON | Health checks, status gathering |

**Bash scripts** are preferred for:
- System operations (docker, git, ssh)
- Simple data gathering
- Operations that need to be schedulable via cron

**TypeScript tools** are preferred for:
- Complex transformations
- Template rendering with validation
- Operations requiring type safety

---

## Related

- [Capability Layering Pattern](../../context/patterns/capability-layering-pattern.md) - CLI-first automation
- [Skill Architecture Pattern](../../context/patterns/skill-architecture-pattern.md) - Skill structure requirements
- [Command Invocation Pattern](../../context/patterns/command-invocation-pattern.md) - How commands invoke skills
- [Code Before Prompts Pattern](../../context/patterns/code-before-prompts-pattern.md) - Deterministic operations
- [Skills Index](../_index.md)
- [README](./README.md) - Detailed usage instructions
