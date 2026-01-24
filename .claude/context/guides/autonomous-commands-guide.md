# Autonomous Commands User Guide

**Version**: 1.1.0
**Created**: 2026-01-20
**Updated**: 2026-01-23 (Skills Migration)

Execute Claude Code built-in slash commands autonomously without manual input.

---

## Quick Start

### 1. Launch Jarvis in tmux

```bash
.claude/scripts/launch-jarvis-tmux.sh
```

This starts Claude Code with the auto-command watcher in a split pane.

### 2. Use Natural Language

Just ask Claude to perform the action:

| Say this... | Claude executes... |
|-------------|-------------------|
| "Compact the context" | `/compact` |
| "Rename this session to Feature Work" | `/rename Feature Work` |
| "Show my token usage" | `/usage` |
| "Run a security review" | `/security-review` |

### 3. Signal is Sent Automatically

Claude creates a signal file, the watcher detects it, and executes the command via keystroke injection.

---

## Available Commands

### Information Commands (Read-Only)

| Command | Trigger Phrases | What It Does |
|---------|-----------------|--------------|
| `/status` | "show status", "session status" | Display session status |
| `/usage` | "show usage", "token usage" | Display token usage |
| `/cost` | "show cost", "how much" | Display cost information |
| `/stats` | "show statistics", "metrics" | Display session statistics |
| `/context` | "show context", "what's in context" | Display context information |
| `/todos` | "show todos", "my tasks" | Display todo list |
| `/hooks` | "list hooks", "show hooks" | List registered hooks |
| `/bashes` | "bash processes", "running commands" | List running bash processes |
| `/release-notes` | "release notes", "what's new" | Display release notes |

### Action Commands (May Modify State)

| Command | Trigger Phrases | What It Does |
|---------|-----------------|--------------|
| `/compact` | "compact context", "reduce tokens" | Compact conversation |
| `/rename` | "rename session", "call this" | Rename current session |
| `/resume` | "resume session", "continue from" | Resume previous session |
| `/export` | "export conversation", "save chat" | Export conversation |
| `/doctor` | "run doctor", "health check" | Run health diagnostics |
| `/review` | "review code", "code review" | Review code changes |
| `/plan` | "enter plan mode", "create plan" | Enter plan mode |
| `/security-review` | "security review", "vulnerability" | Run security review |

---

## How It Works

```
┌─────────────────────────────────────────────────────────────────┐
│  1. User: "Show me my token usage"                              │
├─────────────────────────────────────────────────────────────────┤
│  2. Claude (via autonomous-commands skill):                     │
│     - Detects intent matches /usage                             │
│     - Runs: signal_usage                                        │
│     - Creates: .claude/context/.command-signal                  │
├─────────────────────────────────────────────────────────────────┤
│  3. auto-command-watcher.sh (in tmux pane):                     │
│     - Detects signal file                                       │
│     - Validates JSON: {"command":"/usage",...}                  │
│     - Executes: tmux send-keys -t jarvis "/usage" Enter         │
├─────────────────────────────────────────────────────────────────┤
│  4. Claude Code executes /usage                                 │
│     - Token usage displayed in conversation                     │
└─────────────────────────────────────────────────────────────────┘
```

---

## Prerequisites

### Required

1. **tmux** - For autonomous keystroke injection
   ```bash
   # macOS
   brew install tmux

   # Linux
   apt-get install tmux
   ```

2. **jq** - For JSON parsing in watcher
   ```bash
   # macOS
   brew install jq

   # Linux
   apt-get install jq
   ```

### Recommended

- Launch Jarvis via `launch-jarvis-tmux.sh` (not plain `claude`)
- Keep the watcher pane visible to monitor command execution

---

## Manual Usage

If you need to trigger a command manually (without Claude):

```bash
# Via CLI
.claude/scripts/signal-helper.sh compact "Focus on recent changes"
.claude/scripts/signal-helper.sh rename "My Session Name"
.claude/scripts/signal-helper.sh status

# Or programmatically
source .claude/scripts/signal-helper.sh
signal_usage
```

---

## Troubleshooting

### Command not executing?

1. **Check watcher status**:
   ```bash
   .claude/scripts/signal-helper.sh watcher-status
   ```

2. **Check for pending signal**:
   ```bash
   .claude/scripts/signal-helper.sh pending
   ```

3. **View watcher logs**:
   ```bash
   tail -20 .claude/logs/command-signals.log
   ```

### Watcher not running?

Start Jarvis properly:
```bash
.claude/scripts/launch-jarvis-tmux.sh
```

Or start watcher manually in a separate terminal:
```bash
.claude/scripts/auto-command-watcher.sh
```

### tmux session not found?

The watcher expects a tmux session named `jarvis`. Check:
```bash
~/bin/tmux list-sessions
```

---

## Customization

### Change tmux session name

Set environment variable before launching:
```bash
export TMUX_SESSION=my-session
.claude/scripts/launch-jarvis-tmux.sh
```

### Add custom commands

1. Add to whitelist/blocklist in `auto-command-watcher.sh`
2. Add signal function in `signal-helper.sh`
3. Update `autonomous-commands` skill description with trigger phrases

---

## Security

- Commands are validated against a whitelist
- Arguments are sanitized to prevent injection
- All executions are logged with source tracking
- Signal files are local-only (not committed to git)

---

## Related Files

| File | Purpose |
|------|---------|
| `.claude/scripts/launch-jarvis-tmux.sh` | Launch Claude with watcher |
| `.claude/scripts/auto-command-watcher.sh` | Watcher script |
| `.claude/scripts/signal-helper.sh` | Signal creation library |
| `.claude/skills/autonomous-commands/SKILL.md` | Main skill definition (handles all commands) |
| `.claude/context/patterns/command-signal-protocol.md` | Protocol specification |
| `.claude/logs/command-signals.log` | Execution log |

---

*Autonomous Commands User Guide v1.0.0*
