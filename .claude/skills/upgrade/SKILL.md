---
name: upgrade
version: 1.0.0
description: Self-improvement system for discovering and applying updates to your hub
category: maintenance
tags: [self-improvement, updates, monitoring, automation]
created: 2026-01-21
updated: 2026-02-18
context: shared
model: sonnet
---

# Upgrade Skill

A **self-improvement system** that monitors external sources for updates to Claude Code, libraries, and infrastructure components, then proposes and implements improvements to your hub.

## Quick Actions

| Need | Command |
|------|---------|
| Find updates | `/upgrade discover` |
| Evaluate relevance | `/upgrade analyze` |
| Adopt features | `/upgrade adopt` |
| Get proposal | `/upgrade propose` |
| Apply upgrade | `/upgrade implement <id>` |
| Check status | `/upgrade status` |
| View history | `/upgrade history` |
| Undo change | `/upgrade rollback <id>` |

## Workflow

```
DISCOVER -> ANALYZE -> ADOPT (features only) -> PROPOSE -> IMPLEMENT -> VERIFY
```

1. **Discover**: Fetch sources, compare baselines, identify new items
2. **Analyze**: Score relevance (impact 1-10, complexity Low/Med/High)
3. **Adopt**: Map new features to hub infrastructure, create Beads tasks
4. **Propose**: Generate implementation plan with risks and rollback strategy
5. **Implement**: Create checkpoint, apply changes, validate, log
6. **Verify**: Capture learnings, update Memory MCP

## Sources to Monitor

| Priority | Source | Frequency |
|----------|--------|-----------|
| Critical | Claude Code Releases, Security Advisories | Daily |
| Important | Anthropic Blog, Claude Code Discussions, MCP Registry | Weekly |
| Supplementary | Anthropic YouTube, Claude API Changelog | Bi-weekly |

Source configuration: `config.yaml` for URLs and parsing details.

## Best Practices

- Run `/upgrade discover` weekly at minimum
- Review proposals before implementing
- Keep `baselines.json` updated
- Never skip the checkpoint step
- Don't apply multiple upgrades at once (unless bundled)

## References

- @references/analysis-workflow.md — Relevance scoring, impact/complexity levels, adopt workflow, feature-to-infrastructure mapping
- @references/implementation-workflow.md — Proposal structure, risk assessment, pre-implementation checklist, data file schemas, rollback procedures
- @references/scheduled-execution.md — Headless/cron execution, permission tiers, monitoring

## Related

- @.claude/commands/upgrade.md — Command reference
- @.claude/skills/upgrade/config.yaml — Configuration
- @.claude/context/patterns/autonomous-execution-pattern.md — Headless execution pattern
