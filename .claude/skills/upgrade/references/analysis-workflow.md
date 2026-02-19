# Upgrade: Analysis & Adopt Workflow

## Relevance Scoring Criteria

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

## Impact Levels

| Level | Description | Example |
|-------|-------------|---------|
| CRITICAL | Security vulnerability, data loss risk | CVE patch |
| HIGH | Significant functionality improvement | New hook events |
| MEDIUM | Useful enhancement | Performance improvement |
| LOW | Nice to have | Documentation update |

## Complexity Levels

| Level | Description | Effort |
|-------|-------------|--------|
| LOW | Config change only | < 5 min |
| MEDIUM | Code/file modifications | 15-30 min |
| HIGH | Architectural changes | > 1 hour |

## Adopt Workflow (Feature Upgrades)

**When to trigger**: After analyzing a Claude Code upgrade that introduces new features. Analyze identifies *what's available*; Adopt determines *how to leverage it*.

### Adopt Checklist

1. **Map to infrastructure**: Which hub components could use this feature?
2. **Identify concrete changes**: What specific files need modification?
3. **Classify adoption effort**: Immediate (<5 min) / Short-term (<1 session) / Evaluation (research needed)
4. **Create Beads tasks**: One task per adoption item with labels
5. **Update baselines**: Mark features as "adopted" vs "available" vs "active"

### Feature-to-Infrastructure Map

| Feature Type | Check These Components |
|-------------|----------------------|
| Model changes | `model-selection.md`, CLAUDE.md, agent configs |
| New CLI flags | `claude-scheduled.sh`, autonomous-execution-pattern |
| Agent/subagent features | `parallel-dev/SKILL.md`, agent definitions, orchestration |
| Memory features | `session-state.md` workflow, `memory-storage-pattern.md` |
| MCP improvements | `mcp-servers.md`, gateway config, MCP loading strategy |
| Security fixes | `claude-scheduled.sh` permissions, hooks, sandbox config |
| Skill/context features | `_index.md`, skill definitions, compaction-essentials |
