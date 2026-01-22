---
description: "Start a Feature Planning session for adding to existing projects"
argument-hint: "<feature-description>"
model: sonnet
---

# /plan:feature - Feature Planning

Start a lighter planning session for adding a feature to an existing project.

This is equivalent to `/plan --mode=feature`.

## When to Use

- Adding a new feature to existing codebase
- Extending current functionality
- Integrating a new capability
- Building on existing architecture

## Question Categories (Lighter Set)

1. **Feature Scope**: What capability, for whom, boundaries
2. **Integration**: How it fits, what it touches
3. **Acceptance**: How we know it's done

## Output

- Feature specification at `.claude/planning/specs/`
- Focused orchestration at `.claude/orchestration/`

## Usage

```
/plan:feature "dark mode toggle"
/plan:feature "Stripe payment integration"
/plan:feature "export to PDF functionality"
```

## Options

- `--depth=minimal` - Very quick, just essentials
- `--depth=comprehensive` - Full exploration even for features

## Flow

Executes `/plan` with `--mode=feature` automatically.

Note: Uses Sonnet model (faster, still high quality) since features are typically more bounded than full designs.

See `/plan` command for full execution details.
