---
description: "Start a New Design planning session for building from scratch"
argument-hint: "<description>"
model: opus
---

# /plan:new - New Design Planning

Start a full planning session for building something new from scratch.

This is equivalent to `/plan --mode=new-design`.

## When to Use

- Building a new application or system
- Starting a significant new project
- Designing architecture from scratch
- Creating a new service or platform

## Question Categories

1. **Vision & Goals**: Problem, users, success criteria
2. **Scope & Features**: MVP, phase 2, out of scope
3. **Technical**: Stack, architecture, integrations
4. **Constraints**: Timeline, performance, security
5. **Risks**: What could go wrong, mitigations

## Output

- Complete design specification at `.claude/planning/specs/`
- Full orchestration plan at `.claude/orchestration/`

## Usage

```
/plan:new "habit tracking application"
/plan:new "REST API for inventory management"
/plan:new "authentication system with OAuth"
```

## Options

- `--depth=minimal` - Quick planning, base questions only
- `--depth=comprehensive` - Full exploration, all questions

## Flow

Executes `/plan` with `--mode=new-design` automatically.

See `/plan` command for full execution details.
