---
description: "Analyze and decompose Claude Code plugins for Jarvis integration"
argument-hint: "[--discover|--review|--analyze|--scan-redundancy|--decompose|--execute|--browse] PLUGIN"
allowed-tools: ["Bash($CLAUDE_PROJECT_DIR/.claude/scripts/plugin-decompose.sh:*)"]
---

# Plugin Decomposition Tool

This tool analyzes Claude Code plugins and generates integration plans for incorporating them into Jarvis.

## Commands

Execute the appropriate command based on your workflow:

### Discovery
```!
"$CLAUDE_PROJECT_DIR/.claude/scripts/plugin-decompose.sh" --discover $ARGUMENTS
```

### Review
```!
"$CLAUDE_PROJECT_DIR/.claude/scripts/plugin-decompose.sh" --review $ARGUMENTS
```

### Analysis
```!
"$CLAUDE_PROJECT_DIR/.claude/scripts/plugin-decompose.sh" --analyze $ARGUMENTS
```

### Redundancy Scan
```!
"$CLAUDE_PROJECT_DIR/.claude/scripts/plugin-decompose.sh" --scan-redundancy $ARGUMENTS
```

### Decomposition
```!
"$CLAUDE_PROJECT_DIR/.claude/scripts/plugin-decompose.sh" --decompose $ARGUMENTS
```

### Execute (Dry Run)
```!
"$CLAUDE_PROJECT_DIR/.claude/scripts/plugin-decompose.sh" --execute $ARGUMENTS --dry-run
```

### Execute (Actual Integration)
```!
"$CLAUDE_PROJECT_DIR/.claude/scripts/plugin-decompose.sh" --execute $ARGUMENTS
```

### Rollback
```!
"$CLAUDE_PROJECT_DIR/.claude/scripts/plugin-decompose.sh" --rollback $ARGUMENTS
```

### Browse
```!
"$CLAUDE_PROJECT_DIR/.claude/scripts/plugin-decompose.sh" --browse
```

## Workflow

1. **Browse** available plugins to find candidates
2. **Discover** a specific plugin by name
3. **Review** the plugin structure and components
4. **Analyze** each component for integration classification
5. **Scan Redundancy** to check for overlaps with Jarvis codebase
6. **Decompose** to generate the integration plan
7. **Execute --dry-run** to preview changes
8. **Execute** to perform the integration
9. **Rollback** to undo if needed

## Examples

```bash
# Browse all available plugins
/plugin-decompose --browse

# Find a plugin
/plugin-decompose --discover example-plugin

# Full analysis workflow
/plugin-decompose --review example-plugin
/plugin-decompose --analyze example-plugin
/plugin-decompose --decompose example-plugin

# Execute integration
/plugin-decompose --execute example-plugin --dry-run
/plugin-decompose --execute example-plugin

# Rollback if needed
/plugin-decompose --rollback docs/reports/plugin-analysis/.rollback-example-plugin-TIMESTAMP.json
```

## Output

- Review reports are displayed to console
- Decomposition plans are saved to `docs/reports/plugin-analysis/`
- Rollback files are saved to `docs/reports/plugin-analysis/`
