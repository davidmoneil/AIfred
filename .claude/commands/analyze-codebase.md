# /analyze-codebase

Systematically analyze a codebase and generate modification-ready context documentation.

## Usage

```
/analyze-codebase <project-name> [options]
```

## Arguments

| Argument | Required | Description |
|----------|----------|-------------|
| `<project-name>` | Yes | Name of project (must exist in paths-registry.yaml or provide path) |
| `--path <path>` | No | Override path (if not in registry) |
| `--depth <level>` | No | Analysis depth: `quick`, `standard` (default), `deep` |
| `--output <dir>` | No | Output directory (default: `.claude/context/projects/<name>/`) |

## Examples

```bash
# Analyze registered project
/analyze-codebase codecloud

# Analyze with custom path
/analyze-codebase my-app --path ~/Code/my-app

# Quick analysis (structure only, no deep file analysis)
/analyze-codebase bishop-scheduler --depth quick

# Deep analysis (includes function-level documentation)
/analyze-codebase grc-platform --depth deep
```

## What Gets Generated

```
.claude/context/projects/<name>/
├── _index.md              # Quick reference, navigation, common tasks
├── architecture.md        # Mermaid diagrams (hierarchy, data flow, integrations)
├── modification-guide.md  # Where to change what for customizations
└── key-files.md          # Important files reference with LOC counts
```

## Analysis Phases

### Phase 1: Structure Discovery (Explore Agent)
- Directory tree mapping
- Entry point identification
- Package dependency analysis
- Configuration file inventory
- Source directory categorization

### Phase 2: Component Analysis
- **Quick**: Top-level structure only
- **Standard**: Key files identified, patterns recognized
- **Deep**: Function-level analysis, all exports mapped

### Phase 3: Documentation Generation
- Generate _index.md with quick reference
- Create architecture.md with Mermaid diagrams
- Build modification-guide.md with customization recipes
- Compile key-files.md with file reference table

### Phase 4: Integration
- Update main project context file with link
- Add codebase stats
- Commit changes (optional)

## Mermaid Diagrams Generated

| Diagram | Shows |
|---------|-------|
| Component Hierarchy | Parent-child relationships |
| Data Flow | State management patterns |
| Directory Structure | Source organization |
| Integration Points | External dependencies |
| Build Pipeline | Compilation/bundling |

## Depth Comparison

| Aspect | Quick | Standard | Deep |
|--------|-------|----------|------|
| Directory tree | ✓ | ✓ | ✓ |
| Entry points | ✓ | ✓ | ✓ |
| Dependencies | ✓ | ✓ | ✓ |
| Key files list | - | ✓ | ✓ |
| LOC counts | - | ✓ | ✓ |
| Mermaid diagrams | 2 | 5-6 | 8+ |
| Function mapping | - | - | ✓ |
| Export analysis | - | - | ✓ |
| Estimated time | 2-5 min | 5-15 min | 15-30 min |

## Supported Project Types

| Type | Special Analysis |
|------|------------------|
| React/Next.js | Component tree, hooks, state management |
| Python | Module structure, class hierarchy |
| Node.js | Express routes, middleware chain |
| Docker | Service dependencies, network topology |
| Monorepo | Package relationships, shared dependencies |

## Output Customization

The command adapts output based on detected patterns:

- **Redux apps**: Include reducer map and action flow
- **Express apps**: Include route table and middleware chain
- **React apps**: Include component hierarchy and prop flow
- **Python packages**: Include module dependency graph

## Post-Analysis

After running, you can:

1. **Review generated docs** in `.claude/context/projects/<name>/`
2. **Refine diagrams** by editing Mermaid blocks
3. **Add project-specific notes** to modification-guide.md
4. **Commit changes** with `/sync-git`

## Related Commands

- `/code analyze <project>` - Quick code analysis (less comprehensive)
- `/register-project` - Register new project in paths-registry
- `/consolidate-project` - Consolidate existing project knowledge

## Implementation Notes

This command uses:
- **Explore agent** for structure discovery
- **Glob/Grep** for file pattern analysis
- **Read** for key file inspection
- **Write** for documentation generation

The analysis is non-destructive - it only reads the codebase and writes to hub context.
