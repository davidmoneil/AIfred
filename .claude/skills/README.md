# Skills

**Purpose**: On-demand skill definitions — specialized capabilities loaded when needed.

**Layer**: Pneuma (capabilities)

---

## Structure

Each skill has its own directory:
```
<skill-name>/
├── SKILL.md        # Skill definition
├── scripts/        # Supporting scripts (optional)
├── templates/      # Templates (optional)
└── reference/      # Reference docs (optional)
```

## Available Skills

| Skill | Purpose |
|-------|---------|
| `docx` | Word document manipulation |
| `xlsx` | Spreadsheet with formulas |
| `pdf` | PDF manipulation |
| `pptx` | PowerPoint presentations |
| `mcp-builder` | MCP server development |
| `mcp-validation` | MCP testing |
| `skill-creator` | Skill development |
| `plugin-decompose` | Extract skills from plugins |
| `session-management` | Session lifecycle |
| `autonomous-commands` | Auto-* command wrapper |
| `example-skill` | Template for new skills |

## Shared Resources

`_shared/` contains resources used by multiple skills:
- `ooxml/` — Office Open XML schemas and scripts

## Creating New Skills

1. Copy `example-skill/`
2. Edit SKILL.md with definition
3. Add supporting scripts if needed
4. Test skill invocation

---

*Jarvis — Pneuma Layer (Capabilities)*
