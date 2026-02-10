---
name: plugin-decompose
model: sonnet
version: 2.0.0
description: Analyze and decompose Claude Code plugins for integration
---

# Plugin Decompose Skill

**Build Method**: Jarvis-native ralph-loop (blind build)
**Created**: 2026-01-17

## Purpose

Analyze and decompose Claude Code plugins for integration into Jarvis as native tools.

## Features

| Feature | Flag | Description |
|---------|------|-------------|
| Discovery | `--discover` | Find plugin by name or path |
| Review | `--review` | Analyze plugin structure |
| Analysis | `--analyze` | Classify components (ADOPT/ADAPT/DEFER/SKIP) |
| Redundancy | `--scan-redundancy` | Compare against Jarvis codebase |
| Decompose | `--decompose` | Generate integration plan |
| Browse | `--browse` | Interactive plugin browser |
| Execute | `--execute` | Perform actual integration |
| Dry Run | `--dry-run` | Preview changes without executing |
| Rollback | `--rollback` | Undo a previous integration |

## Usage

```bash
# Browse available plugins
.claude/scripts/plugin-decompose.sh --browse

# Full workflow
.claude/scripts/plugin-decompose.sh --discover example-plugin
.claude/scripts/plugin-decompose.sh --review example-plugin
.claude/scripts/plugin-decompose.sh --analyze example-plugin
.claude/scripts/plugin-decompose.sh --scan-redundancy example-plugin
.claude/scripts/plugin-decompose.sh --decompose example-plugin

# Execute integration
.claude/scripts/plugin-decompose.sh --execute example-plugin --dry-run
.claude/scripts/plugin-decompose.sh --execute example-plugin

# Rollback
.claude/scripts/plugin-decompose.sh --rollback docs/reports/plugin-analysis/.rollback-*.json
```

## Integration Workflow

1. **Browse** - Find available plugins
2. **Discover** - Locate specific plugin
3. **Review** - Understand structure
4. **Analyze** - Classify for integration
5. **Scan Redundancy** - Check for conflicts
6. **Decompose** - Generate plan
7. **Execute --dry-run** - Preview changes
8. **Execute** - Perform integration
9. **Rollback** - Undo if needed

## Output Files

Integration plans are saved to:
```
docs/reports/plugin-analysis/<plugin>-decomposition.md
```

Rollback files are saved to:
```
docs/reports/plugin-analysis/.rollback-<plugin>-<timestamp>.json
```

## Execute Feature Details

### Pre-flight Checks
- Verifies decomposition plan exists
- Auto-generates if missing
- Parses file mappings

### Integration Actions
- COPY: Files copied directly
- MERGE: Backup created, file copied (manual merge may be needed)

### Post-Integration
- Verifies all files copied
- Syntax checks shell scripts
- Creates rollback file

### Rollback Capability
- Removes copied files
- Removes created directories (if empty)
- Restores backed-up files

## Plugin Structure Expected

```
plugin/
├── .claude-plugin/
│   └── plugin.json
├── commands/
│   └── *.md
├── hooks/
│   ├── hooks.json
│   └── *.sh
├── scripts/
│   └── *.sh
├── skills/
│   └── <skill>/SKILL.md
└── README.md
```

## Component Classifications

| Classification | Meaning |
|----------------|---------|
| ADOPT | Copy directly, no conflicts |
| ADAPT | Manual merge required |
| DEFER | Consider for later |
| SKIP | Not needed |

## Dependencies

- bash 4.0+
- jq (for JSON parsing)
- Standard Unix tools (find, grep, sed)

## Related Commands

- `/plugin-decompose` - Invoke this skill
