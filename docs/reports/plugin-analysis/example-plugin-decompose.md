# Decomposition Plan: example-plugin

**Source:** `/Users/aircannon/.claude/plugins/marketplaces/claude-plugins-official/plugins/example-plugin`
**Target:** `/Users/aircannon/Claude/Jarvis/.claude`
**Generated:** 2026-01-17 12:03:04

## File Mapping

| Source | Target | Action |
|--------|--------|--------|
| commands/example-command.md | .claude/commands/example-command.md | COPY |
| skills/example-skill/ | .claude/skills/example-skill/ | COPY |

## Integration Checklist

[ ] Review plugin README.md for usage notes
[ ] Copy files marked COPY
[ ] Merge files marked MERGE (manual review required)
[ ] Update paths-registry.yaml if adding new paths
[ ] Register any new hooks in settings.json
[ ] Test commands work: /command-name --help
[ ] Test hooks trigger correctly
[ ] Update capability-matrix.md
[ ] Commit changes with descriptive message

## Notes

- COPY: File doesn't exist in Jarvis, safe to copy
- MERGE: File exists, requires manual review and merge

