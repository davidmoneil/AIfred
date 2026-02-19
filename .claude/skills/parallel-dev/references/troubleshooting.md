# Parallel-Dev: Troubleshooting

| Issue | Solution |
|-------|----------|
| **Plan not found** | Check name matches file at `.claude/parallel-dev/plans/{name}.md`. Use `/parallel-dev:plan-list`. |
| **Execution won't start** | Ensure plan status is `approved` or `decomposed`. Check tasks file exists. Verify `~/tmp/worktrees/` exists. |
| **Agents seem stuck** | Check `/parallel-dev:status`. Use pause then resume. Check for circular dependencies. |
| **Validation failing** | Review failures in report. Use `--fix` for auto-fix. Fix in worktree, commit, re-validate. |
| **Merge conflicts** | Run `/parallel-dev:conflicts` first. Use `--resolve` for AI-assisted resolution or resolve manually. |
