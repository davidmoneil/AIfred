# Plugin Decomposition Pattern

**Created**: 2026-01-07
**PR Reference**: PR-8 (Context Budget Management)
**Status**: Active

---

## Discovery

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

### Manifest Structure

```json
{
  "name": "plugin-name",
  "plugins": [
    {
      "name": "bundle-name",
      "skills": [
        "./skills/skill-a",
        "./skills/skill-b"
      ]
    }
  ]
}
```

### Skill Structure

Each skill is just:
- **SKILL.md**: YAML frontmatter (name, description, license) + detailed markdown instructions
- **templates/**: Optional supporting files (HTML, JS, etc.)
- **LICENSE.txt**: License terms

This means **skills are fully extractable and customizable**.

---

## Plugin Decomposition Process

### Step 1: Analyze Plugin Structure

```bash
# List plugin contents
ls -laR ~/.claude/plugins/cache/<marketplace>/<plugin-name>/

# Read manifest
cat ~/.claude/plugins/cache/<marketplace>/<plugin-name>/.claude-plugin/marketplace.json
```

### Step 2: Identify Skills to Extract

Review skills and classify:
- **KEEP**: High-value, frequently used
- **ADAPT**: Useful but needs customization
- **DROP**: Unused, context overhead

### Step 3: Extract Skill to Jarvis

```bash
# Copy skill directory
cp -r ~/.claude/plugins/cache/<marketplace>/<plugin-name>/skills/<skill-name>/ \
      /Users/aircannon/Claude/Jarvis/.claude/skills/

# Rename to avoid conflicts
mv .claude/skills/<skill-name>/SKILL.md .claude/skills/<skill-name>/SKILL.md
```

### Step 4: Adapt Skill for Jarvis

1. Update YAML frontmatter with Jarvis-specific metadata
2. Modify instructions to reference Jarvis patterns
3. Add integration with Jarvis workflows
4. Update skill inventory documentation

### Step 5: Test Extracted Skill

Verify the skill works standalone:
- Check it appears in `/skills` list
- Execute a test task using the skill
- Confirm no dependency on original plugin

---

## Example: Extracting docx Skill

### Source
- Plugin: `document-skills@anthropic-agent-skills`
- Path: `~/.claude/plugins/cache/anthropic-agent-skills/document-skills/69c0b1a06741/skills/docx/`

### Contents
- `SKILL.md` (197 lines) — Complete Word document workflow
- `docx-js.md` — Reference for creating documents
- `ooxml.md` — Reference for editing documents

### Extraction
```bash
cp -r ~/.claude/plugins/cache/anthropic-agent-skills/document-skills/*/skills/docx/ \
      .claude/skills/docx/
```

### Token Impact
- **Before**: Entire document-skills plugin loaded (~15K+ tokens)
- **After**: Only docx skill loaded when needed (~2-3K tokens)

---

## Benefits of Decomposition

| Aspect | Plugin Bundle | Extracted Skills |
|--------|---------------|------------------|
| Context overhead | All skills loaded | Only needed skills |
| Customization | Read-only | Full control |
| Updates | Automatic | Manual (controlled) |
| Dependencies | May conflict | Isolated |
| Token cost | Higher | Lower |

---

## When to Decompose

**Decompose when**:
- Plugin contains many skills but only few are used
- Skill needs customization for Jarvis patterns
- Context budget is constrained
- Skill has problematic dependencies

**Keep plugin when**:
- All skills are frequently used
- Plugin updates are valuable
- No customization needed
- Token cost is acceptable

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

## Implementation Plan

### Phase 1: Core Document Skills
1. Extract docx, pdf, xlsx, pptx to `.claude/skills/`
2. Adapt for Jarvis patterns
3. Test each skill independently
4. Uninstall document-skills plugin

### Phase 2: Development Skills
1. Extract mcp-builder, skill-creator
2. Integrate with plugin-dev workflows

### Phase 3: Cleanup
1. Document extracted skills in skills-selection-guide
2. Update capability matrix
3. Remove plugin from installed_plugins.json

---

## Command: /extract-skill

Future command to automate extraction:

```markdown
# Extract Skill from Plugin

Extract and adapt a skill from an installed plugin.

## Usage
/extract-skill <plugin-name> <skill-name>

## Process
1. Locate skill in plugin cache
2. Copy to .claude/skills/
3. Adapt frontmatter for Jarvis
4. Register in skills inventory
5. Optionally uninstall source plugin
```

---

## Related Documentation

- @.claude/context/patterns/context-budget-management.md
- @.claude/context/integrations/skills-selection-guide.md
- @.claude/skills/_index.md

---

*Plugin Decomposition Pattern v1.0 — PR-8 Research Finding*
