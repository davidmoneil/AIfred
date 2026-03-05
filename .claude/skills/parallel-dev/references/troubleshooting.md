# Parallel-Dev: Troubleshooting

## Plan not found?
- Check plan name matches file at `.claude/parallel-dev/plans/{name}.md`
- Use `/parallel-dev:plan-list` to see available plans

## Execution won't start?
- Ensure plan status is `approved` or `decomposed`
- Check tasks file exists: `.claude/parallel-dev/plans/{name}-tasks.yaml`
- Verify worktree base directory exists: `~/tmp/worktrees/`

## Agents seem stuck?
- Check `/parallel-dev:status` for details
- Use `/parallel-dev:pause` then `/parallel-dev:resume`
- Check for circular dependencies in tasks

## Validation failing?
- Review specific failures in validation report
- Use `--fix` flag to auto-fix formatting issues
- Fix failures in worktree, commit, re-validate

## Merge conflicts?
- Run `/parallel-dev:conflicts` first to preview
- Use `/parallel-dev:merge --resolve` for AI-assisted resolution
- Or resolve manually in worktree then merge
