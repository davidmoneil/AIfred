# Command Signal Protocol

**Version**: 1.0.0
**Created**: 2026-01-20
**Purpose**: Define signal file format for autonomous command execution via watcher script.

---

## Overview

This protocol enables Claude (via skills) or external processes to trigger built-in Claude Code slash commands through a signal-based watcher system. The watcher monitors for signal files and dispatches commands via keystroke injection.

---

## Signal File Format

### Location

```
.claude/context/.command-signal
```

### Format (JSON)

```json
{
  "command": "/compact",
  "args": "Focus on recent changes only",
  "timestamp": "2026-01-20T17:45:00Z",
  "source": "skill:autonomous-compact",
  "priority": "normal"
}
```

### Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `command` | string | Yes | Slash command to execute (e.g., `/compact`, `/status`) |
| `args` | string | No | Arguments to pass to the command (space-separated) |
| `timestamp` | ISO 8601 | Yes | When signal was created |
| `source` | string | Yes | Origin identifier (skill name, hook name, or "manual") |
| `priority` | string | No | Execution priority: "immediate", "normal" (default), "low" |

---

## Supported Commands

### Information Commands (read-only)
| Command | Args | Description |
|---------|------|-------------|
| `/status` | none | Show session status |
| `/usage` | none | Show token usage |
| `/cost` | none | Show cost information |
| `/stats` | none | Show statistics |
| `/context` | none | Show context information |
| `/todos` | none | Show todo list |
| `/hooks` | none | List registered hooks |
| `/bashes` | none | List running bash processes |
| `/release-notes` | none | Show release notes |

### Action Commands (may modify state)
| Command | Args | Description |
|---------|------|-------------|
| `/compact` | `[instructions]` | Compact conversation with optional focus |
| `/rename` | `<name>` | Rename current session (required arg) |
| `/resume` | `[session]` | Resume previous session |
| `/export` | `[filename]` | Export conversation |
| `/doctor` | none | Run health diagnostics |
| `/review` | none | Review code changes |
| `/plan` | none | Enter plan mode |
| `/security-review` | none | Run security review |

---

## Watcher Behavior

### Signal Detection
1. Watcher polls `.claude/context/.command-signal` every 2 seconds
2. On detection, validates JSON structure
3. Validates command against whitelist
4. Executes via keystroke injection

### Execution Flow
```
Signal Created → Watcher Detects → Validate → Wait 1s → Inject Keystroke → Delete Signal → Log Result
```

### Keystroke Injection
```bash
# Via tmux (preferred - fully autonomous)
tmux send-keys -t jarvis "/command args" Enter

# Via AppleScript fallback (semi-autonomous - requires Enter)
osascript -e 'tell application "System Events" to keystroke "/command args"'
```

### Error Handling
| Error | Response |
|-------|----------|
| Invalid JSON | Log error, delete signal, continue |
| Unknown command | Log warning, delete signal, continue |
| Missing required arg | Log error, delete signal, continue |
| tmux not available | Fall back to AppleScript |

---

## Signal Creation

### From Skills (via Bash)
```bash
# Using signal helper
source .claude/scripts/signal-helper.sh
send_command_signal "/compact" "Focus on code changes" "skill:autonomous-compact"
```

### From Hooks (via Node.js)
```javascript
const fs = require('fs');
const signal = {
  command: '/status',
  args: '',
  timestamp: new Date().toISOString(),
  source: 'hook:pre-compact',
  priority: 'normal'
};
fs.writeFileSync('.claude/context/.command-signal', JSON.stringify(signal, null, 2));
```

### Manual (direct)
```bash
echo '{"command":"/status","args":"","timestamp":"'$(date -u +%Y-%m-%dT%H:%M:%SZ)'","source":"manual","priority":"normal"}' > .claude/context/.command-signal
```

---

## Security Considerations

1. **Command Whitelist**: Only commands in the supported list are executed
2. **Argument Sanitization**: Args are sanitized to prevent injection
3. **Source Tracking**: All signals log their source for audit
4. **Rate Limiting**: Max 1 command per 2 seconds (watcher poll interval)
5. **Local Only**: Signal files are local, not committed to git

---

## Logging

All signal executions are logged to `.claude/logs/command-signals.log`:

```
2026-01-20T17:45:03Z | /compact | "Focus on code changes" | skill:autonomous-compact | SUCCESS
2026-01-20T17:46:15Z | /status | "" | manual | SUCCESS
2026-01-20T17:47:00Z | /invalid | "" | manual | ERROR: Unknown command
```

---

## Integration Points

- **Skills**: Create signals via `signal-helper.sh`
- **Hooks**: Create signals via Node.js fs operations
- **Watcher**: `auto-command-watcher.sh` (enhanced from `auto-clear-watcher.sh`)
- **Launcher**: `launch-jarvis-tmux.sh` starts watcher automatically

---

*Command Signal Protocol v1.0.0*
