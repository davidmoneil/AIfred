# Skill Template with Tools

This is the template for creating skills that follow the **Code Before Prompts** pattern.

## Pattern Overview

**Principle**: If something can be done deterministically, do it in code. Use AI for intelligence tasks, not routine operations.

| Task Type | Use Code | Use AI |
|-----------|----------|--------|
| File creation | Yes | No |
| Template rendering | Yes | No |
| Validation | Yes | No |
| Content generation | No | Yes |
| Decision making | No | Yes |
| Analysis | No | Yes |

## Directory Structure

```
.claude/skills/<skill-name>/
├── SKILL.md           # Main skill definition
├── config.json        # Skill configuration
├── package.json       # Node.js dependencies
├── tsconfig.json      # TypeScript configuration
├── README.md          # This file
├── templates/         # Document templates
│   ├── default.md
│   └── spec.md
└── tools/             # Deterministic code
    └── index.ts       # CLI tool entry point
```

## Usage

### Quick Commands

```bash
# Navigate to skill directory
cd .claude/skills/_template

# List available templates
npx tsx tools/index.ts list

# Create from template
npx tsx tools/index.ts create default "My Document"
npx tsx tools/index.ts create spec "My Specification"

# Validate a file
npx tsx tools/index.ts validate ./path/to/file.md

# Show help
npx tsx tools/index.ts help
```

### Using npm scripts

```bash
npm run list
npm run create -- default "My Document"
npm run validate -- ./path/to/file.md
```

## Creating a New Skill

1. **Copy this template**:
   ```bash
   cp -r .claude/skills/_template .claude/skills/my-new-skill
   ```

2. **Update config.json**:
   - Change `name` and `description`
   - Add skill-specific templates
   - Update validation rules

3. **Add templates**:
   - Create `.md` files in `templates/`
   - Use `{{NAME}}`, `{{DATE}}`, `{{SLUG}}`, `{{TIMESTAMP}}` placeholders

4. **Extend tools/index.ts** (optional):
   - Add skill-specific commands
   - Add custom validation logic
   - Add data transformation functions

5. **Write SKILL.md**:
   - Document workflow phases
   - Reference tools commands
   - Add integration points

## Extending the Tools

Add new commands by extending the switch statement in `tools/index.ts`:

```typescript
case 'my-command':
  // Your deterministic logic here
  break;
```

Add new types:

```typescript
interface MyCustomType {
  field: string;
  // ...
}
```

## Tool Type Selection

| Scenario | Tool Type | Location |
|----------|-----------|----------|
| Complex logic, type safety | TypeScript | `tools/index.ts` |
| System operations, CLI tasks | Bash | `~/AIProjects/Scripts/` |
| Data gathering for AI | Bash returning JSON | `~/AIProjects/Scripts/` |

**Note**: Bash scripts in `Scripts/` can be shared across skills and scheduled via cron.

## Related Documentation

- [Capability Layering Pattern](../../context/patterns/capability-layering-pattern.md) - CLI-first automation
- [Skill Architecture Pattern](../../context/patterns/skill-architecture-pattern.md) - Skill structure
- [Command Invocation Pattern](../../context/patterns/command-invocation-pattern.md) - Command routing
- [Code Before Prompts Pattern](../../context/patterns/code-before-prompts-pattern.md) - Deterministic ops
- [Skills Index](../_index.md)
