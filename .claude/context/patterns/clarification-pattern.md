# Clarification Pattern

For complex or ambiguous requests, clarify scope and deliverable before implementing.

## When to Trigger

| Indicator | Example |
|-----------|---------|
| Vague scope | "improve the system", "make it better" |
| Multiple valid approaches | "add caching" (Redis? Memory? File?) |
| Cross-system impact | Touching 3+ services or config layers |
| Unclear deliverable | "set up monitoring" (dashboards? alerts? both?) |
| Missing context | References a service/system not in context files |

## Response Template

When complexity is detected:

1. **Parse**: Restate what you understand the request to be
2. **Identify gaps**: List 2-3 specific unknowns
3. **Propose options**: Give a recommended approach with alternatives
4. **Confirm scope**: "Before I start, I want to confirm: [specific question]"

## Simple Requests (Skip Clarification)

- Single file edits with clear instructions
- Commands with explicit parameters
- Questions that just need an answer
- Tasks matching an existing pattern exactly

## Before Starting Any Significant Task

1. Check `.claude/context/patterns/` for existing patterns
2. Check `.claude/context/projects/` for project context
3. If the task touches infrastructure, check `paths-registry.yaml`
4. If unclear, ask rather than assume
