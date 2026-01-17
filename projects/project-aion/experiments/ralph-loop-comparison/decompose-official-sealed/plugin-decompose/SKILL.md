---
name: plugin-decompose
description: Analyze, decompose, and integrate Claude Code plugins into Jarvis with rollback support
version: 2.0.0
triggers:
  - user asks to analyze a plugin
  - user wants to integrate a plugin
  - user asks about plugin structure
  - user wants to review plugin components
  - user asks about plugin redundancy
  - user wants to execute plugin integration
  - user wants to rollback plugin integration
---

# Plugin Decomposition Skill

This skill enables systematic analysis and integration of plugins from the Claude Code plugin ecosystem into Jarvis.

## When to Use

Activate this skill when:
- User wants to analyze a plugin's structure
- User is considering integrating a plugin
- User needs to understand what a plugin provides
- User wants to check for redundancy with existing Jarvis capabilities
- User needs a migration plan for plugin components

## Capabilities

### 1. Plugin Discovery
Find plugins by name across cache and marketplace directories.

```bash
.claude/scripts/plugin-decompose.sh --discover <name>
```

### 2. Structure Review
Generate detailed analysis of plugin components:
- Commands (slash commands)
- Hooks (event handlers)
- Scripts (shell utilities)
- Skills (model-invoked capabilities)
- Agents (specialized task handlers)
- MCP configuration

```bash
.claude/scripts/plugin-decompose.sh --review <path>
```

### 3. Integration Analysis
Classify each component as:
- **ADOPT**: Ready to use as-is
- **ADAPT**: Needs modification for Jarvis patterns
- **DEFER**: Future consideration
- **SKIP**: Redundant or not needed

```bash
.claude/scripts/plugin-decompose.sh --analyze <path>
```

### 4. Redundancy Scanning
Generate analysis request for code-analyzer agent to perform semantic comparison against Jarvis codebase.

```bash
.claude/scripts/plugin-decompose.sh --scan-redundancy <path>
```

### 5. Decomposition Planning
Create file mapping and integration checklist:
- Source → Target mappings
- COPY vs MERGE actions
- Step-by-step checklist

```bash
.claude/scripts/plugin-decompose.sh --decompose <path>
```

### 6. Interactive Browsing
List and select from available plugins.

```bash
.claude/scripts/plugin-decompose.sh --browse
```

### 7. Execute Integration
Actually perform the integration - copy/merge plugin files into Jarvis.

**Features:**
- Pre-flight checks (generates missing reports automatically)
- Backs up existing files before overwriting
- Validates all operations post-integration
- Creates rollback file for safe reverting

```bash
# Preview what would happen (no changes made)
.claude/scripts/plugin-decompose.sh --execute <path> --dry-run

# Actually execute the integration
.claude/scripts/plugin-decompose.sh --execute <path>
```

### 8. Rollback Integration
Revert a previous integration using the generated rollback file.

```bash
.claude/scripts/plugin-decompose.sh --rollback <rollback-file>
```

## Plugin Locations

| Location | Description |
|----------|-------------|
| `~/.claude/plugins/cache/` | Installed plugin cache |
| `~/.claude/plugins/marketplaces/` | Marketplace repositories |

## Output

All reports are saved to: `docs/reports/plugin-analysis/`

Report types:
- `{plugin}-review.md` - Structure analysis
- `{plugin}-analysis.md` - Integration classification
- `{plugin}-decompose.md` - Migration plan
- `{plugin}-redundancy-request.md` - Code-analyzer input

Rollback files are saved to: `docs/reports/plugin-analysis/rollbacks/`
- `{plugin}-{timestamp}.json` - Rollback manifest

## Workflow Example

For a complete plugin integration workflow:

1. **Discover**: Find the plugin
   ```
   /plugin-decompose discover feature-dev
   ```

2. **Review**: Understand structure
   ```
   /plugin-decompose review /path/to/plugin
   ```

3. **Analyze**: Classify components
   ```
   /plugin-decompose analyze /path/to/plugin
   ```

4. **Redundancy Check**: Semantic comparison
   ```
   /plugin-decompose scan-redundancy /path/to/plugin
   ```

5. **Decompose**: Generate migration plan
   ```
   /plugin-decompose decompose /path/to/plugin
   ```

6. **Dry Run**: Preview what would happen
   ```
   /plugin-decompose execute /path/to/plugin --dry-run
   ```

7. **Execute**: Perform the integration
   ```
   /plugin-decompose execute /path/to/plugin
   ```

8. **Rollback** (if needed): Revert the integration
   ```
   /plugin-decompose rollback docs/reports/plugin-analysis/rollbacks/{plugin}-{timestamp}.json
   ```

## Related Tools

- `extract-skill.sh` - Extract individual skills
- `setup-plugins.sh` - Plugin installation
- `capability-matrix.md` - Capability tracking

## Integration Notes

The `--execute` command handles these automatically:

1. **Commands**: Copies to `.claude/commands/`
2. **Hooks**: Copies to `.claude/hooks/`, makes scripts executable
3. **Scripts**: Copies to `.claude/scripts/`, makes executable
4. **Skills**: Copies entire skill directory to `.claude/skills/`
5. **Agents**: Copies to `.claude/agents/`

**Backup behavior:**
- Existing files are backed up with `.backup-{timestamp}` suffix
- MERGE operations preserve the backup for manual review
- Rollback restores from backups automatically

**Post-integration tasks** (manual):
- Register hooks in `settings.json` if needed
- Update `paths-registry.yaml` for new paths
- Update `capability-matrix.md` for new capabilities
- Update `CHANGELOG.md` for integration record
- Test integrated components work correctly
