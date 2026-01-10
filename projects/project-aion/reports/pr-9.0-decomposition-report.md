# PR-9.0 Plugin Decomposition Report

**Date**: 2026-01-09
**Status**: Complete (awaiting post-restart validation)
**Source Plugin**: anthropic-agent-skills/document-skills

---

## Executive Summary

| Metric | Value |
|--------|-------|
| Skills Extracted | 6 |
| Total Tokens Available | ~65,500 |
| Phase 1 (Document) | 4 skills, ~37,400 tokens |
| Phase 2 (Development) | 2 skills, ~28,100 tokens |
| PD-Compliance | 100% (all 6 refactored) |

**Impact**: Previously the document-skills plugin loaded ~86K tokens (both bundles). Now Jarvis can load individual skills on-demand, reducing typical document task overhead from 86K to 2.6K-14K depending on the specific skill needed.

---

## Extracted Skills Inventory

### Phase 1: Core Document Skills

| Skill | Tokens | Category | Primary Use Case |
|-------|--------|----------|------------------|
| **xlsx** | ~2,600 | document | Spreadsheets, formulas, data analysis |
| **pdf** | ~8,300 | document | PDF creation, forms, merge/split |
| **docx** | ~12,500 | document | Word documents, tracked changes |
| **pptx** | ~14,000 | document | Presentations, slides, speaker notes |

### Phase 2: Development Skills

| Skill | Tokens | Category | Primary Use Case |
|-------|--------|----------|------------------|
| **skill-creator** | ~5,100 | development | Creating Claude Code skills |
| **mcp-builder** | ~23,000 | development | Building MCP servers |

---

## Overlap Analysis

### Document Skills Overlap Matrix

| Task | Primary | Alternative | Selection Rule |
|------|---------|-------------|----------------|
| Create Word doc | docx | - | Always use docx for .docx output |
| Create PDF | pdf | docx→export | Use pdf directly; docx if editing needed first |
| Create spreadsheet | xlsx | - | Always use xlsx for Excel output |
| Create presentation | pptx | - | Always use pptx for slides |
| Extract text from .docx | docx | Read+pandoc | Use Read+pandoc for simple text; docx for structure |
| Fill PDF form | pdf | - | Always use pdf skill |
| Financial model | xlsx | - | Always use xlsx |
| Report with charts | xlsx+pdf | - | xlsx for data, pdf for final |

### Development Skills Overlap Matrix

| Task | Primary | Alternative | Selection Rule |
|------|---------|-------------|----------------|
| Create Claude skill | skill-creator | - | Always use for skill development |
| Build MCP server | mcp-builder | - | Always use for MCP development |
| Create plugin | plugin-dev (plugin) | skill-creator | plugin-dev for full plugins; skill-creator for skills within |
| Integrate API | mcp-builder | WebFetch | mcp-builder for persistent tools; WebFetch for one-off |

### Cross-Category Overlaps

| Component A | Component B | Resolution |
|-------------|-------------|------------|
| docx | Write tool | Write for plain text; docx for formatted documents |
| xlsx | Read+pandas | xlsx for Excel output; Read+pandas for analysis only |
| pdf | docx | pdf for final distribution; docx for editing |
| mcp-builder | skill-creator | mcp-builder for tools; skill-creator for workflows/knowledge |
| pptx | visual-documentation-skills | pptx for PowerPoint; visual-docs for HTML diagrams |

---

## Capability Matrix Updates

### Document Operations (Updated)

| Task | Built-in | MCP | Skill | Notes |
|------|----------|-----|-------|-------|
| Create Word document | - | - | **docx** | Full .docx support |
| Create spreadsheet | - | - | **xlsx** | Formulas, formatting |
| Create PDF | - | desktop-commander | **pdf** | Forms, merge/split |
| Create presentation | - | - | **pptx** | Slides, speaker notes |
| Read .docx text | Read+pandoc | - | docx | Simple: pandoc; Complex: docx |
| Fill PDF form | - | - | **pdf** | Programmatic form filling |

### Development Operations (Updated)

| Task | Built-in | MCP | Skill | Notes |
|------|----------|-----|-------|-------|
| Create MCP server | - | - | **mcp-builder** | FastMCP, MCP SDK |
| Create Claude skill | - | - | **skill-creator** | Skill structure, patterns |
| Build plugin | - | - | plugin-dev (ext) | Full plugin development |

---

## Progressive Disclosure Compliance

### Tier 1 Metadata Completeness

| Skill | name | desc | ver | cat | tags | cost | when | deps | overlaps | source | license |
|-------|------|------|-----|-----|------|------|------|------|----------|--------|---------|
| docx | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| xlsx | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| pdf | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| pptx | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| mcp-builder | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| skill-creator | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |

### Selection Guidance Sections

All 6 skills include:
- ✅ "Use this skill when" (trigger conditions)
- ✅ "Do NOT use when" (alternatives)
- ✅ "Complements" (related skills)

---

## Validation Requirements (Post-Restart)

### Test Plan

| Skill | Test Prompt | Expected Result |
|-------|-------------|-----------------|
| docx | "Create a simple Word document with a heading and paragraph" | .docx file created |
| xlsx | "Create an Excel file with a sum formula" | .xlsx with working formula |
| pdf | "Create a PDF with a title and body text" | .pdf file created |
| pptx | "Create a 3-slide presentation" | .pptx with 3 slides |
| mcp-builder | "Show me the MCP server development workflow" | Workflow guidance displayed |
| skill-creator | "What's the structure of a Claude skill?" | Skill structure explained |

### Validation Criteria

- [ ] Skill appears in `/skills` list
- [ ] Skill activates on appropriate prompts
- [ ] Output is correct format/content
- [ ] No dependency on original plugin
- [ ] Token cost within 10% of estimate

---

## Recommendations

### Immediate Actions
1. **Restart session** to test skill recognition
2. **Run validation tests** per test plan above
3. **Update capability-matrix.md** with new skill entries

### Future Decomposition Candidates
From the remaining example-skills bundle:

| Skill | Tokens | Priority | Rationale |
|-------|--------|----------|-----------|
| webapp-testing | ~1,000 | MEDIUM | Useful with Playwright |
| web-artifacts-builder | ~800 | LOW | Niche use case |
| brand-guidelines | ~600 | DROP | Anthropic-specific |
| algorithmic-art | ~5,000 | DROP | Niche, unused |
| doc-coauthoring | ~4,000 | DROP | Niche workflow |
| slack-gif-creator | ~2,000 | DROP | Very niche |

### Plugin Cleanup
After validation passes:
1. Uninstall `document-skills@anthropic-agent-skills`
2. Verify skills still work (confirms standalone operation)
3. Document in CHANGELOG.md

---

*PR-9.0 Plugin Decomposition Report — Generated 2026-01-09*
