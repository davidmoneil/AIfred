---
description: Access native Claude Code settings panel (version, model, account)
allowed-tools: Bash(.claude/scripts/*)
---

# Auto Settings

Access the native Claude Code settings panel that shows version, model, and account info.

**NAMESPACE NOTE**: This command exists because Jarvis has a custom `/status` skill that shows autonomic system status. Use this command when you need the native Claude Code settings panel.

## What This Shows

The native `/status` settings panel displays:
- Current Claude Code version
- Selected model (Opus, Sonnet, Haiku)
- Account information
- Configuration settings

## Usage Modes

### Mode 1: Fire-and-Forget (Default)

When the user asks to "show settings", "version info", "what model am I using":

```bash
.claude/scripts/signal-helper.sh status
```

**Note**: This sends the native `/status` command, which in Jarvis context may be intercepted by the custom status skill. For guaranteed native behavior, users should run `/status` directly in the terminal.

### Mode 2: With Auto-Resume

When Jarvis needs to check native settings AND continue working automatically:

```bash
.claude/scripts/signal-helper.sh with-resume /status "" "continue" 3
```

Parameters:
- Command: `/status`
- Args: `""` (none)
- Resume message: `"continue"` (sent after settings display)
- Resume delay: `3` (seconds)

## Important: Namespace Conflict

| Command | Result in Jarvis |
|---------|------------------|
| `/status` (typed directly) | Shows Jarvis autonomic system status |
| `/status` (via signal) | May show either depending on hook order |
| Direct terminal `/status` | Native settings panel |

**Recommendation**: If you need the native settings panel, either:
1. Run `/status` directly in the terminal (outside of Claude Code conversation)
2. Or use `/model` to switch models (which opens native settings)

## Examples

### Example 1: Check native settings

User: "What version of Claude Code am I running?"

Response:
1. Run: `.claude/scripts/signal-helper.sh status`
2. Say: "Signal sent for /status. Settings panel will appear shortly."
3. Note: May show Jarvis status if skill intercepts

### Example 2: Model information

User: "What model is selected?"

Better approach:
1. Check `~/.claude.json` for model configuration
2. Or use `/model` to see and switch models

## Related

- `/auto-status` — Jarvis autonomic system status
- `/model` — Switch between models (opens native settings)
- `self-monitoring-commands.md` — Full pattern documentation
