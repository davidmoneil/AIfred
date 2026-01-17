# Plugin Review: ralph-loop

**Path:** `/Users/aircannon/.claude/plugins/marketplaces/claude-plugins-official/plugins/ralph-loop`
**Generated:** 2026-01-17 11:44:27

## Metadata

- **Name:** ralph-loop
- **Description:** Continuous self-referential AI loops for interactive iterative development, implementing the Ralph Wiggum technique. Run Claude in a while-true loop with the same prompt until task completion.
- **Author:** Anthropic

## Structure

```
.claude-plugin/plugin.json
commands/cancel-ralph.md
commands/help.md
commands/ralph-loop.md
hooks/hooks.json
hooks/stop-hook.sh
README.md
scripts/setup-ralph-loop.sh
```

## Commands

### /cancel-ralph

- **File:** `commands/cancel-ralph.md`
- **Description:** Cancel active Ralph Loop

### /help

- **File:** `commands/help.md`
- **Description:** Explain Ralph Loop plugin and available commands

### /ralph-loop

- **File:** `commands/ralph-loop.md`
- **Description:** Start Ralph Loop in current session

## Hooks

### hooks.json

```json
{
  "description": "Ralph Loop plugin stop hook for self-referential loops",
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/hooks/stop-hook.sh"
          }
        ]
      }
    ]
  }
}
```

### stop-hook.sh

Ralph Loop Stop Hook
Prevents session exit when a ralph-loop is active
Feeds Claude's output back as input to continue the loop
Read hook input from stdin (advanced stop hook API)
Check if ralph-loop is active

## Scripts

### setup-ralph-loop.sh

Ralph Loop Setup Script
Creates state file for in-session Ralph loop
Parse arguments
Parse options and positional arguments

## Skills

*No skills directory*

## Agents

*No agents directory*

## MCP Configuration

*No MCP configuration*

## Size Analysis

- **Total files:** 8
- **Estimated tokens (markdown):** ~2535


