# PR-7: Skills Overlap Analysis

**Created**: 2026-01-07
**PR**: PR-7 Skills Inventory
**Related**: pr-6-overlap-analysis.md (plugins), capability-matrix.md

---

## Overview

This document analyzes overlap between skills and other tooling components (MCPs, plugins, built-in tools). It extends PR-6's overlap analysis with skill-specific categories.

---

## Category 11: Document Generation

| Component | Type | Function |
|-----------|------|----------|
| `docx` skill | Skill | Microsoft Word documents |
| `pdf` skill | Skill | PDF creation and extraction |
| `pptx` skill | Skill | PowerPoint presentations |
| `xlsx` skill | Skill | Excel spreadsheets |
| `doc-coauthoring` skill | Skill | Collaborative document editing |
| Built-in Write tool | Tool | Plain text files |

### Selection Rule

```
Need to create documents?
├── Word document (.docx) → docx skill
├── PDF document (.pdf) → pdf skill
├── Presentation (.pptx) → pptx skill
├── Spreadsheet (.xlsx) → xlsx skill
├── Collaborative editing → doc-coauthoring skill
└── Plain text/code → Built-in Write tool
```

### Conflict Prevention

- **Hard Rule**: Use document skills for Office formats, Write for plain text
- **Rationale**: Document skills handle formatting, styles, and structure

---

## Category 12: Visual/Creative Design

| Component | Type | Function |
|-----------|------|----------|
| `algorithmic-art` skill | Skill | Generative art patterns |
| `canvas-design` skill | Skill | Custom HTML5 Canvas graphics |
| `theme-factory` skill | Skill | Design themes and color schemes |
| `frontend-design` skill/plugin | Both | UI component design |
| `visual-documentation-skills` plugin | Plugin | Technical diagrams |
| `web-artifacts-builder` skill | Skill | Interactive web demos |

### Selection Rule

```
Need visual output?
├── Technical diagram (architecture, flowchart) → visual-documentation-skills
├── Custom graphic/chart → canvas-design
├── Generative/artistic pattern → algorithmic-art
├── UI component → frontend-design
├── Color scheme/theme → theme-factory
└── Interactive demo/prototype → web-artifacts-builder
```

### Conflict Prevention

- **Hard Rule**: Technical diagrams use `visual-documentation-skills` for consistency
- **Soft Rule**: Custom artistic needs may use `algorithmic-art` or `canvas-design`

---

## Category 13: Development Skills

| Component | Type | Function |
|-----------|------|----------|
| `mcp-builder` skill | Skill | Create MCP servers |
| `skill-creator` skill | Skill | Create standalone skills |
| `plugin-dev:create-plugin` | Plugin | Full plugin development |
| `plugin-dev:skill-development` | Plugin | Plugin-bundled skills |
| `agent-sdk-dev:new-sdk-app` | Plugin | Agent SDK applications |

### Selection Rule

```
Need to create tooling?
├── MCP server → mcp-builder skill
├── Standalone skill (not in plugin) → skill-creator skill
├── Plugin with multiple components → plugin-dev:create-plugin
├── Skill inside a plugin → plugin-dev:skill-development
└── Agent SDK application → agent-sdk-dev:new-sdk-app
```

### Conflict Prevention

- **Hard Rule**: MCP servers use `mcp-builder`, not generic code generation
- **Soft Rule**: Skills can be standalone or plugin-bundled based on reuse needs

---

## Category 14: Testing & QA

| Component | Type | Function |
|-----------|------|----------|
| `webapp-testing` skill | Skill | Web app testing guidance |
| `Playwright MCP` | MCP | Programmatic browser automation |
| `browser-automation` plugin | Plugin | Natural language browser control |
| `pr-review-toolkit` plugin | Plugin | Code review workflows |

### Selection Rule

```
Need testing?
├── Web UI testing workflow → webapp-testing skill + Playwright MCP
├── Natural language browser testing → browser-automation
├── Code quality review → pr-review-toolkit
└── Unit/integration tests → Built-in Bash + test frameworks
```

### Conflict Prevention

- **Hard Rule**: `webapp-testing` provides guidance, Playwright MCP provides automation
- **Soft Rule**: Browser automation choice depends on determinism needs

---

## Category 15: Communication & Documentation

| Component | Type | Function |
|-----------|------|----------|
| `internal-comms` skill | Skill | Internal announcements |
| `brand-guidelines` skill | Skill | Brand identity guides |
| `technical-doc-creator` skill | Plugin | Technical documentation |
| `codebase-documenter` skill | Plugin | Codebase documentation |

### Selection Rule

```
Need documentation?
├── Internal announcement → internal-comms skill
├── Brand style guide → brand-guidelines skill
├── Technical/API docs → technical-doc-creator
├── Codebase overview → codebase-documenter
└── README/markdown → Built-in Write tool
```

### Conflict Prevention

- **Soft Rule**: Use specialized skills for professional output, Write for quick docs

---

## Cross-Reference: Skills vs PR-6 Plugins

| Skill | Overlapping Plugin | Resolution |
|-------|-------------------|------------|
| `frontend-design` skill | `frontend-design` plugin | Same source, use plugin invocation |
| `skill-creator` skill | `plugin-dev:skill-development` | Different scope (standalone vs bundled) |
| `webapp-testing` skill | `browser-automation` plugin | Complementary (guidance vs execution) |
| Document skills | `document-skills` plugin | Skills are the plugin content |

---

## New Overlap Categories Summary

| Category | Components | Primary Selection Factor |
|----------|------------|-------------------------|
| 11: Document Generation | 6 | Output format |
| 12: Visual/Creative | 6 | Design type |
| 13: Development Skills | 5 | Component type |
| 14: Testing & QA | 4 | Automation needs |
| 15: Communication | 4 | Audience type |

---

## Integration with PR-6 Categories

PR-6 established categories 1-10. PR-7 adds categories 11-15 for skills.

| Category | PR | Focus |
|----------|-----|-------|
| 1-9 | PR-6 | Plugin/MCP overlap |
| 10 | PR-6 | Browser automation |
| 11-15 | PR-7 | Skills overlap |

---

*PR-7 Skills Overlap Analysis*
*Jarvis v1.6.0 — Project Aion*
