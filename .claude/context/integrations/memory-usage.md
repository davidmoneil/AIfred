# Memory MCP Usage

**Status**: Pending - Enable Docker Desktop MCP integration first

## Setup Required

1. Open Docker Desktop
2. Go to Settings → Features → Beta/Experimental
3. Enable "MCP (Model Context Protocol)"
4. Restart Docker Desktop
5. Run `/health-check` to verify MCP is available

## What to Store (Once Enabled)

- **Decisions and rationale**: Why you chose one approach over another
- **System relationships**: A depends on B, C connects to D
- **Temporal events**: Installs, migrations, incidents
- **Lessons learned**: What worked, what didn't

## What NOT to Store

- Detailed documentation (use context files)
- Secrets or credentials
- Temporary states
- Duplicates of file content

## Entity Types

| Type | Use For |
|------|---------|
| Event | Installations, migrations, incidents |
| Decision | Choices and their rationale |
| Lesson | What was learned from experience |
| Relationship | How systems connect |

## Memory vs Context Files

| Use Memory For | Use Context Files For |
|----------------|----------------------|
| Relationships | Step-by-step procedures |
| Decisions | Detailed documentation |
| Events | Configuration references |
| Lessons | Troubleshooting guides |

## Pruning (Future)

When enabled, entities inactive 90+ days will be archived automatically.
