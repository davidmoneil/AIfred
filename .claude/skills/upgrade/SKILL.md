---
name: upgrade
version: 1.0.0
description: Self-improvement system for discovering and applying updates to your project
category: maintenance
tags: [self-improvement, updates, monitoring, automation]
created: 2026-01-21
updated: 2026-03-05
context: shared
model: sonnet
---

# Upgrade Skill

A **self-improvement system** that monitors external sources for updates to Claude Code, libraries, and infrastructure components, then proposes and implements improvements to your project.

**Inspiration**: Daniel Miessler's PAI v2 - "Within 5 minutes, the entire Kai system was upgraded with this piece of functionality."

---

## Overview

| Aspect | Description |
|--------|-------------|
| Purpose | Proactively discover and apply improvements to your project |
| Pattern | SKILL.md + config + data files (current pattern) |
| When to Use | Regular maintenance, after Claude Code releases, when exploring improvements |

---

## Quick Actions

| Need | Action | Command |
|------|--------|---------|
| Find updates | Check sources for new releases | `/upgrade discover` |
| Evaluate relevance | Score and prioritize discoveries | `/upgrade analyze` |
| Adopt features | Map new capabilities to infrastructure | `/upgrade adopt` |
| Get proposal | Generate implementation plan | `/upgrade propose` |
| Apply upgrade | Implement approved change | `/upgrade implement <id>` |
| Check status | View pending/recent upgrades | `/upgrade status` |
| View history | See past upgrades | `/upgrade history` |
| Undo change | Rollback an upgrade | `/upgrade rollback <id>` |

---

## Workflow

```
+---------------------------------------------------------------------+
|                      UPGRADE SKILL WORKFLOW                          |
+---------------------------------------------------------------------+
|  PHASE 1: DISCOVER                                                   |
|  /upgrade discover                                                   |
|     - Fetch sources from config.yaml                                 |
|     - Compare against baselines.json                                 |
|     - Identify new/changed items                                     |
|     - Store discoveries in pending-upgrades.json                     |
+---------------------------------------------------------------------+
|  PHASE 2: ANALYZE                                                    |
|  /upgrade analyze                                                    |
|     - Read project current state (.claude/*, CLAUDE.md)              |
|     - Evaluate each discovery for relevance                          |
|     - Score impact (1-10) and complexity (Low/Med/High)              |
|     - Prioritize by value/effort ratio                               |
+---------------------------------------------------------------------+
|  PHASE 2.5: ADOPT (Feature Upgrades Only)                            |
|  /upgrade adopt [id]                                                 |
|     - Triggered after Analyze for Claude feature-rich upgrades       |
|     - Map new features against project infrastructure                |
|     - Identify specific files/configs that should change             |
|     - Generate concrete Beads tasks for adoption work                |
|     - Separate "upgrade installed" from "capabilities leveraged"     |
+---------------------------------------------------------------------+
|  PHASE 3: PROPOSE                                                    |
|  /upgrade propose [id]                                               |
|     - Generate specific implementation proposals                     |
|     - Identify files to modify                                       |
|     - Note risks and rollback strategy                               |
|     - Present for user approval                                      |
+---------------------------------------------------------------------+
|  PHASE 4: IMPLEMENT                                                  |
|  /upgrade implement <id>                                             |
|     - Create git checkpoint (tag/branch)                             |
|     - Apply changes (edit files, update configs)                     |
|     - Run validation (hooks, tests if applicable)                    |
|     - Log to upgrade-history.jsonl                                   |
+---------------------------------------------------------------------+
|  PHASE 5: VERIFY & LEARN                                             |
|  Automatic via hooks                                                 |
|     - Capture learning if significant                                |
|     - Update Memory MCP with decision                                |
+---------------------------------------------------------------------+
```

---

## Sources to Monitor

| Priority | Source | Frequency |
|----------|--------|-----------|
| Critical | Claude Code Releases, Security Advisories, Docs | Daily |
| Important | Anthropic Blog, Claude Code Discussions, MCP Registry | Weekly |
| Supplementary | Anthropic YouTube, Claude API Changelog | Bi-Weekly |

Source configuration: See `config.yaml` for URLs and parsing details.

---

## Best Practices

- Run `/upgrade discover` weekly at minimum
- Review proposals before implementing
- Never skip the checkpoint step
- Don't apply multiple upgrades at once (unless bundled)

---

## Reference Documentation

For detailed information, see the references/ directory:
- @references/analysis-workflow.md -- Scoring criteria, adopt workflow, feature-to-infrastructure map
- @references/implementation-workflow.md -- Proposals, implementation steps, rollback, data file schemas
- @references/scheduled-execution.md -- Headless/cron execution, permission tiers, monitoring

## Related

- @.claude/commands/upgrade.md -- Command reference
- @.claude/skills/upgrade/config.yaml -- Source configuration
- @.claude/context/patterns/autonomous-execution-pattern.md -- Scheduled execution pattern
