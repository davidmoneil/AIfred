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
/analyze-codebase project-aion

# Analyze with custom path
/analyze-codebase my-app --path ~/Code/my-app

# Quick analysis (structure only, no deep file analysis)
/analyze-codebase some-service --depth quick

# Deep analysis (includes function-level documentation)
/analyze-codebase complex-app --depth deep
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
| Directory tree | Yes | Yes | Yes |
| Entry points | Yes | Yes | Yes |
| Dependencies | Yes | Yes | Yes |
| Key files list | - | Yes | Yes |
| LOC counts | - | Yes | Yes |
| Mermaid diagrams | 2 | 5-6 | 8+ |
| Function mapping | - | - | Yes |
| Export analysis | - | - | Yes |

## Supported Project Types

| Type | Special Analysis |
|------|------------------|
| React/Next.js | Component tree, hooks, state management |
| Python | Module structure, class hierarchy |
| Node.js | Express routes, middleware chain |
| Docker | Service dependencies, network topology |
| Monorepo | Package relationships, shared dependencies |

## Post-Analysis

After running, you can:

1. **Review generated docs** in `.claude/context/projects/<name>/`
2. **Refine diagrams** by editing Mermaid blocks
3. **Add project-specific notes** to modification-guide.md
4. **Commit changes** with git

## Implementation Notes

This command uses:
- **Explore agent** for structure discovery (Task tool with subagent_type: Explore)
- **Glob/Grep** for file pattern analysis
- **Read** for key file inspection
- **Write** for documentation generation

The analysis is non-destructive - it only reads the codebase and writes to Jarvis context.

---

## Instructions for Claude

When user runs `/analyze-codebase <project-name> [options]`:

1. **Resolve project path**:
   - Check paths-registry.yaml for project
   - Use --path override if provided
   - Confirm path exists

2. **Launch Explore agent** for structure discovery:
   ```
   Task(subagent_type: "Explore", prompt: "Explore <path> and document:
   - Directory structure
   - Entry points (main, index, app files)
   - Package dependencies (package.json, requirements.txt, etc.)
   - Configuration files
   - Source code organization")
   ```

3. **Analyze depth** (based on --depth flag):
   - **quick**: Structure only, 2 Mermaid diagrams
   - **standard**: Key files, patterns, 5-6 diagrams
   - **deep**: Function-level, exports, 8+ diagrams

4. **Generate documentation**:
   - Create output directory if needed
   - Write _index.md with overview and navigation
   - Write architecture.md with Mermaid diagrams
   - Write modification-guide.md with customization recipes
   - Write key-files.md with file reference table

5. **Report completion** with:
   - Files generated
   - Key findings
   - Suggested next steps

## Related

- `/register-project` - Register new project in paths-registry
- code-analyzer agent - Detailed code analysis
- Explore agent - Codebase exploration
