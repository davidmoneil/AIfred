# Plugin Decomposition Pattern

**Created**: 2026-01-07 | **Updated**: 2026-01-17
**PR Reference**: PR-9.0 (Component Extraction Workflow)
**Version**: 3.1
**Status**: Active — MANDATORY for all plugins

> **New (2026-01-17)**: The Decompose Tool (`.claude/scripts/plugin-decompose.sh`) now provides automated plugin analysis and integration. See [Decompose Tool](#decompose-tool-automated) section below.

---

## Core Policy: ALWAYS Decompose

**Decomposition is the DEFAULT for ALL plugins in Jarvis.**

| Action | When |
|--------|------|
| **DECOMPOSE** | Default for all plugins — extract valuable skills |
| **REJECT** | Plugin is unreliable (research user experiences), adds no useful capabilities, or duplicates existing functionality |
| **UNINSTALL** | After decomposition complete OR on rejection |

**Rationale**: Plugins bundle skills inefficiently (loading 86K+ tokens when you need 3K). Decomposition enables Progressive Disclosure Architecture compatibility.

---

## Plugin Structure Discovery

Plugins in Claude Code are **not compiled or obfuscated**. They are simple directory structures:

```
plugin-name/
├── .claude-plugin/
│   └── marketplace.json  # or plugin.json — manifest listing skills
├── skills/
│   ├── skill-a/
│   │   ├── SKILL.md      # YAML frontmatter + instructions
│   │   ├── LICENSE.txt
│   │   └── templates/    # optional resources
│   └── skill-b/
│       └── SKILL.md
└── README.md
```

This means **skills are fully extractable and customizable**.

---

## Progressive Disclosure Architecture Compatibility

All decomposed skills MUST conform to the **Universal Three-Tier Framework** from PR-9.1:

### Tier 1: Selection Metadata (YAML Frontmatter)

```yaml
---
name: skill-name
description: "One-line purpose for selection intelligence"
version: 1.0.0
category: document|development|research|workflow|visual
tags: [keyword1, keyword2, keyword3]
token_cost: ~XXXX  # Estimated tokens
when_to_use: |
  - Trigger condition 1
  - Trigger condition 2
  - Trigger condition 3
dependencies: [tool1, tool2]  # Required tools/MCPs
overlaps_with: [skill-x, tool-y]  # For deconfliction
source: original-plugin@marketplace
license: MIT|Proprietary|Apache-2.0
---
```

### Tier 2: Operational Core (SKILL.md Body)

The main SKILL.md should contain:
1. **Overview** — What this skill does
2. **Workflow Decision Tree** — When to use which approach
3. **Core Instructions** — The primary operational content
4. **Code Style Guidelines** — Format preferences
5. **Dependencies** — What needs to be installed

### Tier 3: Extended Resources (Supporting Files)

- **Reference files** (`reference.md`, `api.md`) — Detailed documentation
- **Templates** (`templates/`) — Reusable code/HTML templates
- **Examples** (`examples/`) — Sample outputs

### Progressive Loading Flow

```
Selection Query → Tier 1 (frontmatter scan) → Match?
                                               ↓ Yes
                                     Load Tier 2 (SKILL.md)
                                               ↓
                              Need details? → Load Tier 3 (references)
```

---

## Refactoring Standard for Extracted Skills

When extracting a skill, apply these transformations:

### 1. Frontmatter Enhancement

**Before** (typical plugin skill):
```yaml
---
name: docx
description: "Document creation and editing"
license: Proprietary
---
```

**After** (Jarvis-compatible):
```yaml
---
name: docx
description: "Comprehensive Word document creation, editing, and analysis with tracked changes support"
version: 1.0.0
category: document
tags: [word, docx, document, office, track-changes, comments]
token_cost: ~12500
when_to_use: |
  - User requests creating a Word document
  - User needs to edit an existing .docx file
  - User asks about document redlining or tracked changes
  - User needs to extract text from Word files
dependencies: [Bash, Write, Read]
overlaps_with: [pdf, pptx]
source: document-skills@anthropic-agent-skills
license: Proprietary
---
```

### 2. Usage Documentation Preservation

All reference files MUST be preserved and organized:
```
skill-name/
├── SKILL.md           # Main operational content
├── reference.md       # API/library reference (if exists)
├── examples/          # Usage examples
├── templates/         # Code templates
└── LICENSE.txt        # Original license
```

### 3. Selection Integration

Add a `## Selection Guidance` section at the top of SKILL.md:

```markdown
## Selection Guidance

**Use this skill when**:
- [Specific trigger 1]
- [Specific trigger 2]

**Do NOT use when**:
- [Alternative skill is better for X]
- [Built-in tool handles this case]

**Complements**: [Related skills/tools]
```

---

## Decomposition Process (6 Steps)

### Step 1: Extraction
```bash
.claude/scripts/extract-skill.sh <marketplace> <plugin> <skill>
```

### Step 2: Refactor Frontmatter
Update YAML to include all Tier 1 metadata fields.

### Step 3: Add Selection Guidance
Insert `## Selection Guidance` section.

### Step 4: Organize Resources
Ensure all reference files are properly linked.

### Step 5: Tool-Use Validation
Execute validation tests (see Validation Framework below).

### Step 6: Update Registries
- Add to skills-selection-guide.md
- Update capability-matrix.md
- Document overlaps

---

## Tool-Use Validation Framework

Each extracted skill requires validation before completion:

### Validation Checklist

| Check | Method | Pass Criteria |
|-------|--------|---------------|
| **Appears in /skills** | `claude` → `/skills` | Skill listed with description |
| **Frontmatter valid** | Parse YAML | All required fields present |
| **Invocation works** | Test task | Skill activates correctly |
| **Output correct** | Inspect result | Expected artifact created |
| **No plugin dependency** | Disable plugin | Still works standalone |
| **Token cost accurate** | `/context` | Within 10% of estimate |

### Validation Test Template

```markdown
## Validation: [skill-name]

**Date**: YYYY-MM-DD
**Tester**: Jarvis

### Tests Performed

1. **Skill Recognition**
   - Command: `/skills`
   - Result: ✅ Listed | ❌ Not found

2. **Basic Invocation**
   - Prompt: "[test prompt]"
   - Result: ✅ Activated | ❌ Failed
   - Notes: [observations]

3. **Output Validation**
   - Expected: [artifact type]
   - Actual: [what was produced]
   - Result: ✅ Correct | ❌ Incorrect

4. **Standalone Test**
   - Plugin disabled: Yes
   - Still works: ✅ Yes | ❌ No

5. **Token Cost**
   - Estimated: ~XXXX
   - Actual: ~YYYY
   - Variance: X%

### Validation Status: ✅ PASS | ❌ FAIL | ⚠️ PARTIAL
```

---

## Overlap Analysis Requirements

For each decomposed skill, document:

### Overlap Matrix Entry

```markdown
### [Skill Name] Overlaps

| Overlapping Component | Type | Resolution |
|-----------------------|------|------------|
| [component] | skill/tool/MCP | [which to prefer when] |

**Selection Rule**: [Clear decision guidance]
```

### Capability Matrix Entry

```markdown
| Task | Primary | Alternative | Notes |
|------|---------|-------------|-------|
| [task description] | [skill] | [alternative] | [context] |
```

---

## Skills Extraction Candidates

Based on PR-8 analysis of `document-skills@anthropic-agent-skills`:

### Extract (High Value)

| Skill | Size | Justification |
|-------|------|---------------|
| docx | ~3K | Frequently used for document generation |
| pdf | ~3K | PDF operations common |
| xlsx | ~2K | Spreadsheet operations needed |
| pptx | ~2K | Presentation creation |

### Drop (Low Value / High Cost)

| Skill | Size | Reason |
|-------|------|--------|
| algorithmic-art | ~4.8K | Niche, never used |
| doc-coauthoring | ~3.8K | Niche, never used |
| slack-gif-creator | ~1.9K | Niche, never used |
| frontend-design | ~1K | Duplicate of standalone plugin |

### Consider (Moderate Value)

| Skill | Size | Notes |
|-------|------|-------|
| mcp-builder | ~2K | Useful for MCP development |
| skill-creator | ~2K | Useful for skill development |
| webapp-testing | ~2K | Useful with Playwright |

---

## Token Cost Analysis (PR-9.0)

### anthropic-agent-skills/document-skills (2026-01-08)

**document-skills bundle** (4 skills):
| Skill | Tokens | Priority |
|-------|--------|----------|
| xlsx | 2,658 | HIGH (lightweight) |
| pdf | 8,299 | HIGH (common use) |
| docx | 12,557 | HIGH (frequent) |
| pptx | 13,949 | MEDIUM |
| **Total** | **~37,463** | |

**example-skills bundle** (12 skills):
| Skill | Tokens | Priority |
|-------|--------|----------|
| brand-guidelines | 558 | LOW |
| web-artifacts-builder | 771 | LOW |
| webapp-testing | 978 | MEDIUM |
| frontend-design | 1,110 | LOW (duplicate) |
| slack-gif-creator | 1,960 | DROP |
| theme-factory | 2,109 | LOW |
| internal-comms | 2,762 | LOW |
| canvas-design | 2,984 | LOW |
| doc-coauthoring | 3,953 | DROP |
| algorithmic-art | 4,942 | DROP |
| skill-creator | 5,117 | MEDIUM |
| mcp-builder | 22,933 | HIGH |
| **Total** | **~49,177** | |

**Combined plugin overhead**: ~86K tokens if both bundles load

---

## Extraction Script

The extraction workflow is now automated via:

```bash
.claude/scripts/extract-skill.sh
```

### Usage

```bash
# List available skills in a plugin
./extract-skill.sh --list <marketplace> <plugin>

# Extract a skill to Jarvis
./extract-skill.sh <marketplace> <plugin> <skill>
```

### Examples

```bash
# List skills in document-skills
./extract-skill.sh --list anthropic-agent-skills document-skills

# Extract xlsx skill
./extract-skill.sh anthropic-agent-skills document-skills xlsx

# Extract from claude-code-plugins
./extract-skill.sh claude-code-plugins feature-dev feature-dev
```

### What the script does
1. Locates skill in `~/.claude/plugins/cache/<marketplace>/<plugin>/<version>/skills/<skill>/`
2. Copies entire skill directory to `.claude/skills/<skill>/`
3. Reports token estimate and file counts
4. Provides next steps guidance

---

## Implementation Status (PR-9.0)

### Phase 1: Core Document Skills ✅ **COMPLETE**
| Skill | Extracted | Refactored | Tokens | Status |
|-------|-----------|------------|--------|--------|
| docx | ✅ | ✅ PD-compatible | ~12,500 | Ready for validation |
| xlsx | ✅ | ✅ PD-compatible | ~2,600 | Ready for validation |
| pdf | ✅ | ✅ PD-compatible | ~8,300 | Ready for validation |
| pptx | ✅ | ✅ PD-compatible | ~14,000 | Ready for validation |

**Phase 1 Total**: ~37,400 tokens available on-demand

### Phase 2: Development Skills ✅ **COMPLETE**
| Skill | Extracted | Refactored | Tokens | Status |
|-------|-----------|------------|--------|--------|
| mcp-builder | ✅ | ✅ PD-compatible | ~23,000 | Ready for validation |
| skill-creator | ✅ | ✅ PD-compatible | ~5,100 | Ready for validation |

**Phase 2 Total**: ~28,100 tokens available on-demand

### Phase 3: Validation & Cleanup 🔄 **IN PROGRESS**

#### Validation Status (Pre-Restart)

| Skill | Frontmatter | Selection Guidance | Resources | Test Required |
|-------|-------------|-------------------|-----------|---------------|
| docx | ✅ Enhanced | ✅ Added | ✅ 3 md, 55 files | ⏳ Post-restart |
| xlsx | ✅ Enhanced | ✅ Added | ✅ 1 md, 1 file | ⏳ Post-restart |
| pdf | ✅ Enhanced | ✅ Added | ✅ 3 md, 8 files | ⏳ Post-restart |
| pptx | ✅ Enhanced | ✅ Added | ✅ 3 md, 52 files | ⏳ Post-restart |
| mcp-builder | ✅ Enhanced | ✅ Added | ✅ 5 md, 3 files | ⏳ Post-restart |
| skill-creator | ✅ Enhanced | ✅ Added | ✅ 3 md, 3 files | ⏳ Post-restart |

#### Progressive Disclosure Compliance

All extracted skills now include:
- ✅ **Tier 1 Metadata**: name, description, version, category, tags, token_cost, when_to_use, dependencies, overlaps_with, source, license
- ✅ **Selection Guidance**: Use when / Do NOT use when / Complements
- ✅ **Preserved Resources**: All reference docs and templates intact

### Phase 4: Plugin Uninstall ⏳ DEFERRED
- Keep document-skills installed until post-restart validation confirms skill recognition
- Uninstall after all 6 skills confirmed working standalone

---

## Validation Checklist

After extracting a skill:

- [ ] Skill appears in `/skills` list after restart
- [ ] Skill can be invoked (e.g., "create a docx document")
- [ ] Token cost is as expected
- [ ] No dependency on original plugin

---

## Decompose Tool (Automated)

The Decompose Tool (`.claude/scripts/plugin-decompose.sh`) automates plugin analysis and integration workflows. Created during RLE-001 experiment (2026-01-17).

### Features (9 total)

| Feature | Flag | Purpose |
|---------|------|---------|
| Browse | `--browse` | List all installed plugins across marketplaces |
| Discover | `--discover <plugin>` | Find a plugin and show basic info |
| Review | `--review <plugin>` | Deep structural analysis |
| Analyze | `--analyze <plugin>` | Component extraction analysis |
| Scan Redundancy | `--scan-redundancy <plugin>` | Compare with existing Jarvis components |
| Decompose | `--decompose <plugin>` | Generate integration plan |
| Execute | `--execute <plugin>` | Perform integration (with backups) |
| Dry Run | `--execute --dry-run <plugin>` | Preview integration without changes |
| Rollback | `--rollback <file>` | Restore from rollback file |

### Usage

```bash
# Browse all plugins
.claude/scripts/plugin-decompose.sh --browse

# Full workflow
.claude/scripts/plugin-decompose.sh --discover example-plugin
.claude/scripts/plugin-decompose.sh --review example-plugin
.claude/scripts/plugin-decompose.sh --analyze example-plugin
.claude/scripts/plugin-decompose.sh --scan-redundancy example-plugin
.claude/scripts/plugin-decompose.sh --decompose example-plugin
.claude/scripts/plugin-decompose.sh --execute --dry-run example-plugin
.claude/scripts/plugin-decompose.sh --execute example-plugin

# Rollback if needed
.claude/scripts/plugin-decompose.sh --rollback .rollback-example-plugin-*.json
```

### Integration with Ralph Loop

The Decompose Tool can be used within Ralph Loop for automated plugin integration:

```bash
/ralph-loop "Integrate the feature-dev plugin using plugin-decompose.sh" \
  --max-iterations 5 \
  --completion-promise "All plugin components integrated and verified"
```

### RLE-001 Experiment Results

The tool was validated through the Ralph Loop Experiment:
- **Official-Built**: 1817 total lines
- **Native-Built**: 1375 total lines (24.3% reduction)
- **Both**: 16 functions, 9 features, 100% test pass rate

See: `projects/project-aion/reports/ralph-loop-experiment/RESEARCH-REPORT.md`

---

## Related Documentation

- @.claude/context/patterns/context-budget-management.md
- @.claude/context/integrations/skills-selection-guide.md
- @.claude/skills/_index.md
- @.claude/scripts/extract-skill.sh
- @.claude/scripts/plugin-decompose.sh
- @projects/project-aion/reports/ralph-loop-experiment/

---

*Plugin Decomposition Pattern v3.1 — Updated 2026-01-17 (Decompose Tool integration)*
