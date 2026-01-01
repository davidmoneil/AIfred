# /design-review Command

Run a PARC (Prompt → Assess → Relate → Create) design review before implementing a task.

## Usage

```
/design-review "<task description>"
```

## Examples

```
/design-review "Add a health check command for Docker services"
/design-review "Create backup automation for config files"
/design-review "Implement user authentication feature"
```

## What It Does

When invoked, Claude will walk through the PARC pattern:

### Phase 1: Prompt
- Parse and clarify the request
- Identify task type (code, infrastructure, documentation, automation)
- List explicit and implicit requirements

### Phase 2: Assess
- Search `.claude/context/patterns/` for relevant patterns
- Check `.claude/context/workflows/` for applicable workflows
- Query Memory MCP for similar past work
- Evaluate agent selection (custom vs built-in vs skill vs direct)

### Phase 3: Relate
- Consider scope (specific vs generalizable)
- Identify reuse opportunities
- Assess architectural impact
- Check for technical debt implications

### Phase 4: Create
- Recommend implementation approach
- Note patterns to apply
- Identify documentation updates needed
- Suggest follow-up actions

## Output Format

```markdown
## PARC Design Review: [Task]

### 1. PROMPT (Understanding)
- **Core Objective**: [What we're trying to achieve]
- **Task Type**: [code/infrastructure/documentation/automation]
- **Requirements**: [List of requirements]

### 2. ASSESS (Pattern Check)
- **Existing Patterns**: [Found or not found]
- **Similar Implementations**: [References]
- **Agent Selection**: [Recommendation]

### 3. RELATE (Architecture)
- **Scope**: [Specific or generalizable]
- **Reuse**: [Opportunities identified]
- **Impact**: [Systems affected]

### 4. CREATE (Recommendation)
- **Approach**: [How to implement]
- **Patterns to Apply**: [List]
- **Documentation**: [Updates needed]

### Proceed?
Ready to implement with the above approach.
```

## When to Use

- Before implementing new features
- Before creating new slash commands
- Before infrastructure changes
- When unsure about best approach
- When task might create technical debt

## Related

- @.claude/context/patterns/prompt-design-review.md - Full PARC documentation
- @.claude/context/patterns/agent-selection-pattern.md - Agent selection guidance
