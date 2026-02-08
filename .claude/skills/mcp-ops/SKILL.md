---
name: mcp-ops
version: 1.0.0
description: >
  MCP and skill lifecycle — build, validate, decompose, create.
  Use when: create MCP server, validate MCP, plugin decompose, create skill,
  build tools for Claude, FastMCP, skill development, plugin integration.
absorbs: mcp-builder, mcp-validation, plugin-decompose, skill-creator
---

## Lifecycle Router

```
MCP/Skill task?
├── Build MCP server → Read skills/mcp-builder/SKILL.md
│   4 phases: Research → Implement → Review/Test → Evaluate
│   Stack: TypeScript (recommended) or Python
│   Refs: reference/mcp_best_practices.md, node_mcp_server.md, python_mcp_server.md
│
├── Validate MCP → Read skills/mcp-validation/SKILL.md
│   5 phases: Install → Config → Inventory → Functional test → Tier classify
│   Script: .claude/scripts/validate-mcp-installation.sh {name}
│   Tiers: 1 (always-on <3K), 2 (task-scoped 3-8K), 3 (triggered >8K)
│   Log: .claude/logs/mcp-validation/{name}-{date}.md
│
├── Decompose plugin → Read skills/plugin-decompose/SKILL.md
│   Workflow: Browse → Discover → Review → Analyze → Decompose → Execute
│   Script: .claude/scripts/plugin-decompose.sh --{flag} {plugin}
│   Classifications: ADOPT / ADAPT / DEFER / SKIP
│   Output: docs/reports/plugin-analysis/{plugin}-decomposition.md
│
├── Create/update skill → Read skills/skill-creator/SKILL.md
│   6 steps: Understand → Plan resources → Init → Edit → Package → Iterate
│   Init: scripts/init_skill.py <name> --path <dir>
│   Package: scripts/package_skill.py <path>
│   Structure: SKILL.md + scripts/ + references/ + assets/
│   Design patterns: capability-layering, code-before-prompts
│
└── Install existing MCP → Read .claude/context/integrations/mcp-installation.md
```

## Quick Reference

| Task | Entry Point |
|------|-------------|
| `/validate-mcp git` | 5-phase validation harness |
| `/plugin-decompose --browse` | Browse available plugins |
| `scripts/init_skill.py name` | Initialize new skill |
| `scripts/package_skill.py path` | Package skill for distribution |

## Design Principles

- **Progressive Disclosure**: SKILL.md ≤500 lines, details in references/
- **Decomposition-First**: Default DECOMPOSE MCPs → skills. Only RETAIN server-dependent.
- **Concise is Key**: Context window is shared — justify every token
