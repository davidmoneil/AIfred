---
description: "Start a System Review planning session for improving existing systems"
argument-hint: "<system-name>"
model: opus
---

# /plan:review - System Review Planning

Start a planning session focused on reviewing and improving an existing system.

This is equivalent to `/plan --mode=system-review`.

## When to Use

- Auditing an existing system
- Planning improvements to current architecture
- Identifying and prioritizing technical debt
- Creating a modernization roadmap

## Question Categories

1. **Current State**: What exists, what works well
2. **Pain Points**: Issues, technical debt, friction
3. **Desired State**: Goals, target architecture
4. **Gap Analysis**: What needs to change
5. **Prioritization**: Quick wins vs strategic changes

## Output

- Review findings document at `.claude/planning/reviews/`
- Improvement orchestration at `.claude/orchestration/`

## Usage

```
/plan:review "voice character system"
/plan:review "current authentication flow"
/plan:review "Docker infrastructure"
```

## Options

- `--depth=minimal` - Quick assessment, base questions only
- `--depth=comprehensive` - Full audit, all questions

## Flow

Executes `/plan` with `--mode=system-review` automatically.

See `/plan` command for full execution details.
