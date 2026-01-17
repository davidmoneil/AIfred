# Plugin Review: example-plugin

**Path:** `/Users/aircannon/.claude/plugins/marketplaces/claude-plugins-official/plugins/example-plugin`
**Generated:** 2026-01-17 12:02:54

## Metadata

- **Name:** example-plugin
- **Description:** A comprehensive example plugin demonstrating all Claude Code extension options including commands, agents, skills, hooks, and MCP servers
- **Author:** Anthropic

## Structure

```
.claude-plugin/plugin.json
.mcp.json
commands/example-command.md
README.md
skills/example-skill/SKILL.md
```

## Commands

### /example-command

- **File:** `commands/example-command.md`
- **Description:** An example slash command that demonstrates command frontmatter options

## Hooks

*No hooks directory*

## Scripts

*No scripts directory*

## Skills

### example-skill

- **Description:** This skill should be used when the user asks to demonstrate skills, show skill format, create a skill template, or discusses skill development patterns. Provides a reference template for creating Claude Code plugin skills.

## Agents

*No agents directory*

## MCP Configuration

```json
{
  "example-server": {
    "type": "http",
    "url": "https://mcp.example.com/api"
  }
}
```

## Size Analysis

- **Total files:** 5
- **Estimated tokens (markdown):** ~1244


