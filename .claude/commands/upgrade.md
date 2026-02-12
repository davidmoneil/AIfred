# /upgrade Command

Self-improvement system for discovering and applying updates to your hub.

## Usage

```
/upgrade [subcommand] [args]
```

## Subcommands

### /upgrade discover

Check all configured sources for new updates.

**Process**:
1. Fetch from sources defined in `.claude/skills/upgrade/config.yaml`
2. Compare against `.claude/skills/upgrade/data/baselines.json`
3. Store new discoveries in `.claude/skills/upgrade/data/pending-upgrades.json`
4. Generate discovery report

**Example**:
```
/upgrade discover

Discovery Report - 2026-01-21
Sources checked: 6 | New discoveries: 2
- [UP-001] Claude Code 2.2.0 (CRITICAL)
- [UP-002] New hook patterns (HIGH)
```

### /upgrade analyze

Evaluate pending upgrades for relevance to your hub.

**Process**:
1. Read current hub state (hooks, skills, MCP config)
2. Score each upgrade by relevance, impact, complexity
3. Prioritize by value/effort ratio
4. Update pending-upgrades.json with scores

**Scoring Factors**:
- Category Match (+3): Affects components we use
- Recency (+2 max): Newer items score higher
- Security (+3): Security-related updates
- Breaking Changes (-2): Penalty for breaking changes

### /upgrade propose [id]

Generate implementation proposal for an upgrade.

**Arguments**:
- `id` (optional): Specific upgrade ID (e.g., UP-001)
- If omitted, proposes highest-priority pending upgrade

**Output includes**:
- Summary of what the upgrade does
- Files to modify
- Commands to run
- Risk assessment
- Rollback strategy
- Estimated effort

### /upgrade implement <id>

Apply an approved upgrade.

**Arguments**:
- `id` (required): Upgrade ID to implement

**Process**:
1. Create git checkpoint tag: `pre-UP-xxx`
2. Apply changes as specified in proposal
3. Run validation checks
4. Log to upgrade-history.jsonl
5. Update baselines.json

### /upgrade status

Show current upgrade status.

**Output**:
- Pending upgrades count and list
- Recent upgrades applied
- Component versions
- Next scheduled discovery

### /upgrade history [count]

Show upgrade history.

**Arguments**:
- `count` (optional): Number of entries (default: 10)

**Output**:
- ID, date, title, status, impact for each upgrade

### /upgrade rollback <id>

Rollback a specific upgrade.

**Arguments**:
- `id` (required): Upgrade ID to rollback

**Process**:
1. Verify checkpoint tag exists: `pre-UP-xxx`
2. Restore files from tag
3. Update history with rollback status

### /upgrade defer <id> "reason"

Defer an upgrade for later.

**Arguments**:
- `id` (required): Upgrade ID to defer
- `reason` (required): Why deferring

## Examples

```bash
# Weekly routine
/upgrade discover              # Find new updates
/upgrade analyze               # Score them
/upgrade propose               # Review top proposal
/upgrade implement UP-001      # Apply if approved

# Check status
/upgrade status                # What's pending?
/upgrade history 5             # Last 5 upgrades

# If something breaks
/upgrade rollback UP-001       # Undo last upgrade
```

## Configuration

Sources and settings in: `.claude/skills/upgrade/config.yaml`
Current versions in: `.claude/skills/upgrade/data/baselines.json`

## Related

- [Upgrade Skill](@.claude/skills/upgrade/SKILL.md) - Full workflow documentation
- [Sample Workflow](@.claude/skills/upgrade/examples/sample-workflow.md) - Step-by-step example
