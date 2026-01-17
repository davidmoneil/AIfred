# Integration Plan: example-plugin

**Source**: /Users/aircannon/.claude/plugins/marketplaces/claude-plugins-official/plugins/example-plugin
**Generated**: 2026-01-17T20:32:38Z
**Target**: /Users/aircannon/Claude/Jarvis

---

## File Mapping

| Source | Destination | Action |
|--------|-------------|--------|
| commands/example-command.md | .claude/commands/example-command.md | MERGE |
| skills/example-skill/ | .claude/skills/example-skill/ | MERGE |

---

## Integration Checklist

- [ ] Review each file mapping above
- [ ] Check for path variable updates (CLAUDE_PLUGIN_ROOT -> CLAUDE_PROJECT_DIR)
- [ ] Verify no conflicting function names
- [ ] Register any new hooks in settings.json
- [ ] Test each component after integration
- [ ] Update documentation

---

## Notes

- COPY: File can be copied directly
- MERGE: Existing file needs manual merge
- Source files should be reviewed for plugin-specific paths

