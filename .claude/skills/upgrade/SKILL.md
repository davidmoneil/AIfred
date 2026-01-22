---
name: upgrade
version: 1.0.0
description: Self-improvement system for discovering and applying updates to AIProjects
category: maintenance
tags: [self-improvement, updates, monitoring, automation]
created: 2026-01-21
context: shared
model: sonnet
---

# Upgrade Skill

A **self-improvement system** that monitors external sources for updates to Claude Code, libraries, and infrastructure components, then proposes and implements improvements to AIProjects.

**Inspiration**: Daniel Miessler's PAI v2 - "Within 5 minutes, the entire Kai system was upgraded with this piece of functionality."

---

## Overview

| Aspect | Description |
|--------|-------------|
| Purpose | Proactively discover and apply improvements to AIProjects |
| Pattern | SKILL.md + config + data files (current pattern) |
| When to Use | Regular maintenance, after Claude Code releases, when exploring improvements |
| TELOS Link | G-T1 (Infrastructure Maturity), G-T3 (AI Assistant Context Depth) |

---

## Quick Actions

| Need | Action | Command |
|------|--------|---------|
| Find updates | Check sources for new releases | `/upgrade discover` |
| Evaluate relevance | Score and prioritize discoveries | `/upgrade analyze` |
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
|     - Read AIProjects current state (.claude/*, CLAUDE.md)           |
|     - Evaluate each discovery for relevance                          |
|     - Score impact (1-10) and complexity (Low/Med/High)              |
|     - Prioritize by value/effort ratio                               |
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
|     - Store in TELOS if goal-relevant                                |
+---------------------------------------------------------------------+
```

---

## Sources to Monitor

### Priority 1: Critical (Check Daily)

| Source | Type | What to Extract |
|--------|------|-----------------|
| Claude Code Releases | GitHub API | Version, changelog, breaking changes |
| Security Advisories | GitHub Security | CVEs, patches, mitigations |
| Claude Code Docs | Documentation | New features, API changes |

### Priority 2: Important (Check Weekly)

| Source | Type | What to Extract |
|--------|------|-----------------|
| Anthropic Engineering Blog | Blog | Techniques, best practices |
| Claude Code Discussions | GitHub | Community solutions, workarounds |
| MCP Servers Registry | GitHub | New MCP servers, updates |

### Priority 3: Supplementary (Check Bi-Weekly)

| Source | Type | What to Extract |
|--------|------|-----------------|
| Anthropic YouTube | Videos | Tutorials, feature demos |
| Claude API Changelog | Documentation | API changes affecting MCP |

Source configuration: See `config.yaml` for URLs and parsing details.

---

## Discovery Workflow

### Process (uses existing tools)

1. **Fetch sources** using WebFetch tool
   ```
   WebFetch: https://api.github.com/repos/anthropics/claude-code/releases
   Extract: version, tag_name, body (changelog), published_at
   ```

2. **Compare against baselines**
   - Read `data/baselines.json` for current known versions
   - Identify items where fetched version > baseline version
   - Flag new items not in baseline

3. **Store discoveries**
   - Write new items to `data/pending-upgrades.json`
   - Include: source, type, title, summary, URLs

4. **Generate report**
   - Use `templates/discovery-report.md`
   - Show count by priority, highlight critical items

### Example Discovery Session

```bash
/upgrade discover

# Output:
Discovery Report - 2026-01-21
=============================
Sources checked: 6
New discoveries: 3

CRITICAL:
- [UP-004] Claude Code 2.2.1 released (security patch)

HIGH:
- [UP-005] New hook event: PreToolUse validation

MEDIUM:
- [UP-006] MCP Gateway updated to 1.2.0

Run /upgrade analyze to evaluate relevance.
```

---

## Analysis Workflow

### Relevance Scoring Criteria

| Factor | Points | Description |
|--------|--------|-------------|
| Category Match | +3 | Affects hooks/skills/commands/MCP we use |
| Recency | +2 max | Newer = higher (decay over 30 days) |
| Security | +3 | Security-related update |
| Breaking Change | -2 | Has breaking changes |
| Dependencies | +1 | Updates our dependencies |

**Score Interpretation**:
- 8-10: Critical - Auto-notify, apply soon
- 6-7: High - Include in next session
- 4-5: Medium - Include in weekly review
- 1-3: Low - Log but don't notify

### Impact Levels

| Level | Description | Example |
|-------|-------------|---------|
| CRITICAL | Security vulnerability, data loss risk | CVE patch |
| HIGH | Significant functionality improvement | New hook events |
| MEDIUM | Useful enhancement | Performance improvement |
| LOW | Nice to have | Documentation update |

### Complexity Levels

| Level | Description | Effort |
|-------|-------------|--------|
| LOW | Config change only | < 5 min |
| MEDIUM | Code/file modifications | 15-30 min |
| HIGH | Architectural changes | > 1 hour |

---

## Proposal Workflow

### Proposal Structure

Each proposal includes:

1. **Summary**: What the upgrade does
2. **Relevance**: Why it matters to AIProjects
3. **Files to Modify**: Specific paths and changes
4. **Risks**: What could go wrong
5. **Rollback Strategy**: How to undo
6. **Estimated Effort**: Time to implement

### Risk Assessment

| Risk Level | Description | Action |
|------------|-------------|--------|
| Low | Config-only, easily reversible | Proceed |
| Medium | Code changes, tested rollback | Review before proceed |
| High | Breaking changes, complex rollback | Detailed review required |
| Critical | Security implications | Manual review mandatory |

---

## Implementation Workflow

### Pre-Implementation Checklist

- [ ] Proposal approved by user
- [ ] Git working directory clean
- [ ] Checkpoint tag created: `pre-UP-xxx`
- [ ] Files to modify identified
- [ ] Rollback command ready

### Implementation Steps

1. **Create checkpoint**
   ```bash
   git tag pre-UP-xxx -m "Checkpoint before upgrade UP-xxx"
   ```

2. **Apply changes**
   - Edit files as specified in proposal
   - Update configs if needed
   - Run any required commands

3. **Validate**
   - Existing hooks run automatically
   - Check for errors in modified files
   - Verify functionality if applicable

4. **Log**
   - Append to `data/upgrade-history.jsonl`
   - Update `data/baselines.json`
   - Remove from `data/pending-upgrades.json`

### Post-Implementation

- Memory MCP: Store decision with rationale
- TELOS: Update relevant goal if applicable
- Commit: Include upgrade ID in commit message

---

## Data Files

### baselines.json

Current known versions for comparison:
```json
{
  "version": "1.0",
  "components": {
    "claude-code": { "version": "2.1.14" },
    "mcp-git": { "version": "1.0.0" }
  }
}
```

### pending-upgrades.json

Discovered but not yet applied:
```json
{
  "upgrades": [
    {
      "id": "UP-001",
      "source": "claude-code-releases",
      "title": "Claude Code 2.2.0",
      "relevance_score": 9,
      "status": "pending_review"
    }
  ]
}
```

### upgrade-history.jsonl

Audit trail of all upgrades:
```json
{"id":"UP-001","timestamp":"2026-01-21","status":"applied","rollback_tag":"pre-UP-001"}
```

---

## Rollback Procedure

### Automatic Rollback (on failure)

If implementation fails:
1. Detect error condition
2. Run `git checkout pre-UP-xxx -- .`
3. Log failure to history
4. Notify user

### Manual Rollback

```bash
/upgrade rollback UP-xxx

# Process:
1. Verify tag exists: pre-UP-xxx
2. Restore files from tag
3. Update history with rollback status
4. Remove from pending if re-added
```

---

## Integration Points

| Integration | How It Works |
|-------------|--------------|
| Memory MCP | Stores upgrade decisions, rationale, and learnings |
| TELOS | Links upgrades to G-T1 (Infrastructure Maturity) |
| Orchestration | Complex upgrades spawn `/orchestration:plan` |
| Hooks | Post-upgrade validation via existing hooks |
| Git MCP | Version control, checkpoints, rollbacks |

---

## Best Practices

### Do

- Run `/upgrade discover` weekly at minimum
- Review proposals before implementing
- Keep baselines.json updated
- Document why upgrades were deferred

### Don't

- Apply upgrades without reading the proposal
- Skip the checkpoint step
- Ignore breaking change warnings
- Apply multiple upgrades at once (unless bundled)

---

## Troubleshooting

| Issue | Cause | Solution |
|-------|-------|----------|
| Discovery returns empty | Rate limited or source down | Wait and retry, check source URLs |
| Wrong relevance score | Missing context | Run analyze again after updating AIProjects state |
| Rollback fails | Tag missing | Check git tags, may need manual restore |
| Upgrade breaks something | Breaking change missed | Rollback, review changelog more carefully |

---

## Scheduled/Headless Execution

The upgrade discovery workflow can run autonomously on a schedule.

### Quick Start

```bash
# Test the scheduled job (dry run)
~/.claude/jobs/claude-scheduled.sh upgrade-discover --dry-run

# Run discovery headlessly
~/.claude/jobs/claude-scheduled.sh upgrade-discover --verbose

# View output
cat ~/.claude/logs/scheduled/upgrade-discover-*.json | tail -1 | jq '.result'
```

### Cron Schedule

```bash
# Weekly discovery - Sunday 6:00 AM
0 6 * * 0 /home/davidmoneil/AIProjects/.claude/jobs/claude-scheduled.sh upgrade-discover
```

### How It Works

1. **Wrapper script** (`claude-scheduled.sh`) configures environment and permissions
2. **Claude Code CLI** runs with `-p` flag (non-interactive mode)
3. **Permission tier** limits to "analyze" (read + write data files)
4. **Output** is captured as JSON and logged
5. **Discoveries** are written to `pending-upgrades.json`
6. **Next session** shows pending discoveries via session-start hook

### Permission Tier: Analyze

The scheduled job uses the "analyze" tier which allows:
- Reading files (baselines, config, existing data)
- Fetching external sources (GitHub, docs, blogs)
- Writing to data files (pending-upgrades.json)

It does NOT allow:
- Editing code files
- Git commits
- Implementing upgrades

Implementation still requires interactive approval.

### Monitoring

```bash
# Check recent runs
ls -la ~/.claude/logs/scheduled/upgrade-discover-*.log

# View costs
grep "Cost:" ~/.claude/logs/scheduled/upgrade-discover-*.log

# Check for alerts
cat ~/.claude/logs/scheduled/alerts.log
```

See @.claude/context/patterns/autonomous-execution-pattern.md for full documentation.

---

## Related

- [Upgrade Command](@.claude/commands/upgrade.md)
- [Config](@.claude/skills/upgrade/config.yaml)
- [Autonomous Execution Pattern](@.claude/context/patterns/autonomous-execution-pattern.md)
- [Deployment Plan](@.claude/planning/specs/2026-01-20-autonomous-execution-deployment.md)
- [TELOS Technical Domain](@.claude/context/telos/domains/technical.md)
