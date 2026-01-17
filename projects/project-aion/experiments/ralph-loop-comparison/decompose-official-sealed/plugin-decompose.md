---
description: Analyze and decompose plugins for Jarvis integration
argument-hint: <subcommand> [path]
allowed-tools: [Read, Glob, Grep, Bash, Write, Edit, Task]
---

# Plugin Decomposition Tool

Analyze plugins from the Claude Code plugin ecosystem and generate integration plans for Jarvis.

## Subcommands

### discover <name>
Find a plugin by name or partial path.

```bash
/plugin-decompose discover ralph-loop
/plugin-decompose discover feature
```

### review <path>
Analyze plugin structure and document all components (commands, hooks, scripts, skills, agents).

```bash
/plugin-decompose review ~/.claude/plugins/marketplaces/claude-plugins-official/plugins/ralph-loop
```

### analyze <path>
Classify each plugin component for integration:
- **ADOPT**: Use as-is or with minimal changes
- **ADAPT**: Modify to fit Jarvis patterns
- **DEFER**: Useful but not immediate priority
- **SKIP**: Not needed or redundant

```bash
/plugin-decompose analyze /path/to/plugin
```

### scan-redundancy <path>
Generate a semantic comparison request for the code-analyzer agent. This identifies functional overlap (not just name matching) between plugin and Jarvis codebase.

```bash
/plugin-decompose scan-redundancy /path/to/plugin
```

### decompose <path>
Generate a file mapping and integration checklist showing:
- Source → Target file mappings
- COPY vs MERGE actions
- Step-by-step integration checklist

```bash
/plugin-decompose decompose /path/to/plugin
```

### browse
Interactive browser listing all available plugins from marketplaces. Select a plugin and choose an action.

```bash
/plugin-decompose browse
```

### execute <path> [--dry-run]
Execute the integration plan - actually copy/merge plugin files into Jarvis.

**Pre-flight checks:**
- Verifies review, analyze, and decompose reports exist (generates if missing)
- Parses decomposition plan for file mappings

**Operations:**
- COPY: Copies new files to Jarvis locations
- MERGE: Backs up existing files, then copies (flags for manual review)

**Post-integration:**
- Validates all files were copied correctly
- Runs syntax checks on shell scripts
- Creates rollback file for reverting

```bash
# Preview what would happen (no changes made)
/plugin-decompose execute /path/to/plugin --dry-run

# Actually execute the integration
/plugin-decompose execute /path/to/plugin
```

### rollback <file>
Rollback a previous integration using the generated rollback file.

- Removes copied files
- Restores backed-up files to their original state
- Cleans up backup files

```bash
/plugin-decompose rollback docs/reports/plugin-analysis/rollbacks/example-plugin-20260117-123456.json
```

## Implementation

When this command is invoked:

1. Parse the subcommand and arguments
2. Run the appropriate feature from `.claude/scripts/plugin-decompose.sh`
3. Report results to user

### Execution

```bash
# Run the appropriate subcommand
.claude/scripts/plugin-decompose.sh --$SUBCOMMAND $ARGS
```

### Output Location

Reports are saved to: `docs/reports/plugin-analysis/`

## Examples

**Full workflow for integrating a new plugin:**

```bash
# 1. Find the plugin
/plugin-decompose discover feature-dev

# 2. Review its structure
/plugin-decompose review ~/.claude/plugins/marketplaces/claude-plugins-official/plugins/feature-dev

# 3. Analyze for integration
/plugin-decompose analyze ~/.claude/plugins/marketplaces/claude-plugins-official/plugins/feature-dev

# 4. Check for redundancy
/plugin-decompose scan-redundancy ~/.claude/plugins/marketplaces/claude-plugins-official/plugins/feature-dev

# 5. Generate decomposition plan
/plugin-decompose decompose ~/.claude/plugins/marketplaces/claude-plugins-official/plugins/feature-dev

# 6. Preview the integration (dry run)
/plugin-decompose execute ~/.claude/plugins/marketplaces/claude-plugins-official/plugins/feature-dev --dry-run

# 7. Execute the integration
/plugin-decompose execute ~/.claude/plugins/marketplaces/claude-plugins-official/plugins/feature-dev

# 8. (If needed) Rollback the integration
/plugin-decompose rollback docs/reports/plugin-analysis/rollbacks/feature-dev-20260117-123456.json
```

## Related

- `.claude/scripts/extract-skill.sh` - Extract individual skills from plugins
- `.claude/scripts/setup-plugins.sh` - Plugin installation management
- `.claude/context/integrations/capability-matrix.md` - Jarvis capability tracking
