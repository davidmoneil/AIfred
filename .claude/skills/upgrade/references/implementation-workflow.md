# Upgrade: Implementation Workflow

## Proposal Structure

Each proposal includes:
1. **Summary**: What the upgrade does
2. **Relevance**: Why it matters to your hub
3. **Files to Modify**: Specific paths and changes
4. **Risks**: What could go wrong
5. **Rollback Strategy**: How to undo
6. **Estimated Effort**: Time to implement

## Risk Assessment

| Risk Level | Description | Action |
|------------|-------------|--------|
| Low | Config-only, easily reversible | Proceed |
| Medium | Code changes, tested rollback | Review before proceed |
| High | Breaking changes, complex rollback | Detailed review required |
| Critical | Security implications | Manual review mandatory |

## Pre-Implementation Checklist

- [ ] Proposal approved by user
- [ ] Git working directory clean
- [ ] Checkpoint tag created: `pre-UP-xxx`
- [ ] Files to modify identified
- [ ] Rollback command ready

## Implementation Steps

1. **Create checkpoint**: `git tag pre-UP-xxx -m "Checkpoint before upgrade UP-xxx"`
2. **Apply changes**: Edit files as specified in proposal
3. **Validate**: Hooks run automatically, check for errors
4. **Log**: Update history, baselines, remove from pending

## Post-Implementation

- Memory MCP: Store decision with rationale
- TELOS: Update relevant goal if applicable
- Commit: Include upgrade ID in commit message

## Data File Schemas

### baselines.json
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
```json
{"id":"UP-001","timestamp":"2026-01-21","status":"applied","rollback_tag":"pre-UP-001"}
```

## Rollback Procedure

### On Failure (Automatic)
1. Detect error condition
2. Run `git checkout pre-UP-xxx -- .`
3. Log failure to history
4. Notify user

### Manual Rollback
```bash
/upgrade rollback UP-xxx
# Verifies tag, restores files, updates history
```
