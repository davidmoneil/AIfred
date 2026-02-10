---
name: validation
model: sonnet
version: 1.0.0
description: |
  Validate Jarvis tooling, infrastructure, and design decisions.
  Use when: "tooling health", "validate MCP", "health check", "validate selection",
  "design review", "PARC review", "check hooks", "verify plugins", "infrastructure health",
  "system validation", "tool selection audit".
  Comprehensive validation across tooling, infrastructure, and design patterns.
category: workflow
tags: [validation, health, tooling, infrastructure, design, PARC]
created: 2026-01-23
---

# Validation Skill

Comprehensive validation for Jarvis tooling, infrastructure, and design decisions.

---

## Overview

This skill orchestrates validation across multiple domains:

| Domain | Command | Purpose |
|--------|---------|---------|
| **Tooling** | `/tooling-health` | MCPs, plugins, hooks, skills, subagents |
| **Infrastructure** | `/health-report` | Docker, Memory MCP, context files |
| **Selection** | `/validate-selection` | Tool/agent/skill selection accuracy |
| **Design** | `/design-review` | PARC pattern before implementation |

---

## Quick Actions

| Need | Command |
|------|---------|
| Full tooling validation | `/tooling-health` |
| Quick tooling check | `/tooling-health --quick` |
| Infrastructure health | `/health-report` |
| Selection audit | `/validate-selection` |
| Selection test run | `/validate-selection --test` |
| Pre-implementation review | `/design-review "task description"` |
| MCP validation | Use `mcp-validation` skill |

---

## Command Reference

### /tooling-health [options]

Comprehensive Claude Code tooling validation.

| Option | Description |
|--------|-------------|
| `--quick` | Skip MCP tool inventory |
| `--verbose` | Include all appendices |

**Validates:**
- MCP Servers (Stage 1 baseline: 7 servers)
- MCP Tools (functional testing)
- Plugins (PR-5 coverage)
- Hooks (syntax, load, structure)
- Skills (existence, purpose)
- Subagents (availability)
- Commands (project + built-in)

**Output:** `.claude/reports/tooling-health-YYYY-MM-DD.md`

**Report Template Sections:**
- Executive Summary
- MCP Servers (status, token cost, tools)
- MCP Tool Inventory (per-tool testing)
- Plugins (installation, PR-5 coverage)
- Hooks (validation summary, by category)
- Skills (table with status)
- Subagents (availability)
- Issues Requiring Attention
- Action Items

---

### /health-report [options]

Infrastructure health aggregation.

| Option | Description |
|--------|-------------|
| `--quick` | Skip slow checks |
| `--full` | Include all details |

**Checks:**
- Docker Services (container status, restarts)
- Memory MCP (entities, staleness)
- Context Files (freshness, references)
- MCP Servers (connection status)

**Output:** Report displayed inline

**Severity Classification:**
- `[X] CRITICAL`: Service down, data at risk
- `[!] HIGH`: Degraded, needs attention within 24h
- `[~] MEDIUM`: Minor issues, address this week
- `[-] LOW`: Nice to fix, no immediate impact

---

### /validate-selection [options]

Tool/agent/skill selection intelligence validation.

| Mode | Option | Description |
|------|--------|-------------|
| Audit | (default) | Review recent selections |
| Test | `--test` | Run 10 test cases |
| Report | `--report` | Generate validation report |

**Test Cases (SEL-01 through SEL-10):**

| ID | Input | Expected Selection |
|----|-------|-------------------|
| SEL-01 | "Find package.json files" | Glob |
| SEL-02 | "What files handle auth?" | Explore subagent |
| SEL-03 | "Create a Word document" | docx skill |
| SEL-04 | "Research Docker networking" | deep-research agent |
| SEL-05 | "Quick fact: capital of France" | WebSearch |
| SEL-06 | "Comprehensive analysis of X" | gptresearcher |
| SEL-07 | "Navigate to example.com" | Playwright MCP |
| SEL-08 | "Fill out the login form" | browser-automation |
| SEL-09 | "Push changes to GitHub" | Bash(git) or skill |
| SEL-10 | "Review this PR thoroughly" | pr-review-toolkit |

**Target:** 80%+ accuracy (8/10 pass)

**Log:** `.claude/logs/selection-audit.jsonl`

---

### /design-review "task"

PARC pattern design review before implementation.

**PARC Phases:**

1. **Prompt** (Understanding)
   - Parse and clarify request
   - Identify task type
   - List requirements

2. **Assess** (Pattern Check)
   - Search existing patterns
   - Check workflows
   - Query Memory MCP
   - Evaluate agent selection

3. **Relate** (Architecture)
   - Consider scope
   - Identify reuse opportunities
   - Assess impact

4. **Create** (Recommendation)
   - Implementation approach
   - Patterns to apply
   - Documentation updates

**When to Use:**
- Before implementing new features
- Before creating new commands
- Before infrastructure changes
- When unsure about approach

---

## Validation Checklists

### Tooling Health Checklist

Before finalizing tooling-health report:

- [ ] Executive Summary includes ALL categories
- [ ] MCP Tool Inventory lists tools for each connected MCP
- [ ] Plugin table includes PR-5 priority
- [ ] Hook validation includes all 3 tests (syntax, load, structure)
- [ ] Issues include root cause analysis AND recommended plan
- [ ] Stage 1 Baseline Summary has current and target states
- [ ] Action Items have effort estimates
- [ ] At least one appendix with raw data

### Selection Validation Checklist

- [ ] All 10 test cases executed
- [ ] Results logged to selection-audit.jsonl
- [ ] Pass rate calculated
- [ ] Failure patterns documented

### Design Review Checklist

- [ ] All 4 PARC phases completed
- [ ] Patterns searched
- [ ] Memory MCP queried (if available)
- [ ] Impact assessed
- [ ] Recommendation documented

---

## Integration

### With AC-08 Maintenance

`/maintain` includes health checks that use similar validation patterns.

### With Session Start

Quick health checks recommended at session start via `/maintain --quick`.

### With Self-Improvement

Selection validation feeds into AC-05 reflection for pattern improvement.

---

## Related Documentation

### Commands
- @.claude/commands/tooling-health.md
- @.claude/commands/health-report.md
- @.claude/commands/validate-selection.md
- @.claude/commands/design-review.md

### Patterns
- @.claude/context/patterns/selection-validation-tests.md
- @.claude/context/patterns/selection-intelligence-guide.md
- @.claude/context/patterns/prompt-design-review.md (PARC)

### Skills
- @.claude/skills/mcp-validation/SKILL.md - MCP-specific validation

---

*Validation Skill v1.0.0 - Comprehensive System Validation*
