# Upgrade: Implementation & Rollback

## Proposal Structure

Each proposal includes:
1. **Summary**: What the upgrade does
2. **Relevance**: Why it matters to your project
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

## Pre-Implementation Checklist

- [ ] Proposal approved by user
- [ ] Git working directory clean
- [ ] Checkpoint tag created: `pre-UP-xxx`
- [ ] Files to modify identified
- [ ] Rollback command ready

## Implementation Steps

1. **Create checkpoint**: `git tag pre-UP-xxx -m "Checkpoint before upgrade UP-xxx"`
2. **Apply changes**: Edit files as specified in proposal
3. **Validate**: Existing hooks run automatically, check for errors
4. **Log**: Append to `data/upgrade-history.jsonl`, update baselines, remove from pending

## Data Files

### baselines.json
Current known versions for comparison.

### pending-upgrades.json
Discovered but not yet applied upgrades with relevance scores and status.

### upgrade-history.jsonl
Audit trail: `{"id":"UP-001","timestamp":"2026-01-21","status":"applied","rollback_tag":"pre-UP-001"}`

## Rollback Procedure

### Manual Rollback
```bash
/upgrade rollback UP-xxx
# 1. Verify tag exists: pre-UP-xxx
# 2. Restore files from tag
# 3. Update history with rollback status
```

### Automatic Rollback (on failure)
If implementation fails: detect error -> `git checkout pre-UP-xxx -- .` -> log failure -> notify user.

## Integration Points

| Integration | How It Works |
|-------------|--------------|
| Memory MCP | Stores upgrade decisions, rationale, and learnings |
| Orchestration | Complex upgrades spawn `/orchestration:plan` |
| Hooks | Post-upgrade validation via existing hooks |
| Git MCP | Version control, checkpoints, rollbacks |
