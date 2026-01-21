---
name: autonomous-commands
version: 1.0.0
description: |
  Use this skill when the user wants to execute Claude Code built-in commands autonomously.
  Triggers on phrases like: "compact the context", "rename this session", "show my usage",
  "check status", "export conversation", "resume previous session", "run doctor",
  "show costs", "review code", "show todos", "list hooks", "security review",
  "show statistics", "show context info", "release notes", "bash processes".
  This skill creates signals that the auto-command-watcher executes via keystroke injection.
category: automation
tags: [commands, automation, signals, watcher]
created: 2026-01-20
---

# Autonomous Commands Skill

Execute Claude Code built-in slash commands autonomously via signal-based watcher system.

---

## Overview

This skill enables Claude to trigger built-in slash commands without user intervention. Commands are executed via keystroke injection through the auto-command-watcher running in a tmux pane.

**Prerequisites**:
- Claude running in tmux via `launch-jarvis-tmux.sh`
- Auto-command-watcher running in bottom pane
- jq installed for JSON parsing

---

## Quick Reference

| User Request | Command | Signal Function |
|--------------|---------|-----------------|
| "Compact the context" | `/compact` | `signal_compact` |
| "Rename this session to X" | `/rename X` | `signal_rename` |
| "Resume previous session" | `/resume` | `signal_resume` |
| "Export conversation" | `/export` | `signal_export` |
| "Show status" | `/status` | `signal_status` |
| "Show usage" | `/usage` | `signal_usage` |
| "Show costs" | `/cost` | `signal_cost` |
| "Show statistics" | `/stats` | `signal_stats` |
| "Show context" | `/context` | `signal_context` |
| "Show todos" | `/todos` | `signal_todos` |
| "List hooks" | `/hooks` | `signal_hooks` |
| "Show bash processes" | `/bashes` | `signal_bashes` |
| "Run doctor" | `/doctor` | `signal_doctor` |
| "Review code" | `/review` | `signal_review` |
| "Enter plan mode" | `/plan` | `signal_plan` |
| "Security review" | `/security-review` | `signal_security_review` |
| "Show release notes" | `/release-notes` | `signal_release_notes` |

---

## How to Execute Commands

### Step 1: Create the Signal

Use Bash to run the signal helper:

```bash
# Source the helper and call the appropriate function
source .claude/scripts/signal-helper.sh && signal_<command> [args]
```

### Step 2: Inform the User

After creating the signal, inform the user:

```
Signal sent for /<command>. The watcher will execute it momentarily.

If watcher is not running, start Jarvis with: .claude/scripts/launch-jarvis-tmux.sh
```

---

## Command Details

### /compact [instructions]

**Trigger phrases**: "compact context", "reduce tokens", "summarize conversation", "compress chat"

**Usage**:
```bash
source .claude/scripts/signal-helper.sh && signal_compact "Focus on recent code changes"
```

**Notes**: Optional instructions guide what to preserve during compaction.

---

### /rename <name>

**Trigger phrases**: "rename session", "call this session", "name this chat"

**Usage**:
```bash
source .claude/scripts/signal-helper.sh && signal_rename "Feature Implementation"
```

**Notes**: Name argument is required.

---

### /resume [session]

**Trigger phrases**: "resume session", "continue from checkpoint", "restore previous"

**Usage**:
```bash
# Resume most recent
source .claude/scripts/signal-helper.sh && signal_resume

# Resume specific session
source .claude/scripts/signal-helper.sh && signal_resume "session-id"
```

---

### /export [filename]

**Trigger phrases**: "export conversation", "save chat", "download transcript"

**Usage**:
```bash
source .claude/scripts/signal-helper.sh && signal_export "my-session.md"
```

---

### /status

**Trigger phrases**: "show status", "session status", "what's the status"

**Usage**:
```bash
source .claude/scripts/signal-helper.sh && signal_status
```

---

### /usage

**Trigger phrases**: "show usage", "token usage", "how much context"

**Usage**:
```bash
source .claude/scripts/signal-helper.sh && signal_usage
```

---

### /cost

**Trigger phrases**: "show cost", "how much did this cost", "spending"

**Usage**:
```bash
source .claude/scripts/signal-helper.sh && signal_cost
```

---

### /stats

**Trigger phrases**: "show statistics", "session stats", "metrics"

**Usage**:
```bash
source .claude/scripts/signal-helper.sh && signal_stats
```

---

### /context

**Trigger phrases**: "show context", "context info", "what's in context"

**Usage**:
```bash
source .claude/scripts/signal-helper.sh && signal_context
```

---

### /todos

**Trigger phrases**: "show todos", "my tasks", "todo list"

**Usage**:
```bash
source .claude/scripts/signal-helper.sh && signal_todos
```

---

### /hooks

**Trigger phrases**: "list hooks", "show hooks", "registered hooks"

**Usage**:
```bash
source .claude/scripts/signal-helper.sh && signal_hooks
```

---

### /bashes

**Trigger phrases**: "bash processes", "running commands", "background shells"

**Usage**:
```bash
source .claude/scripts/signal-helper.sh && signal_bashes
```

---

### /doctor

**Trigger phrases**: "run doctor", "health check", "diagnose"

**Usage**:
```bash
source .claude/scripts/signal-helper.sh && signal_doctor
```

---

### /review

**Trigger phrases**: "review code", "code review", "review changes"

**Usage**:
```bash
source .claude/scripts/signal-helper.sh && signal_review
```

---

### /plan

**Trigger phrases**: "enter plan mode", "plan this", "create plan"

**Usage**:
```bash
source .claude/scripts/signal-helper.sh && signal_plan
```

---

### /security-review

**Trigger phrases**: "security review", "security check", "vulnerability scan"

**Usage**:
```bash
source .claude/scripts/signal-helper.sh && signal_security_review
```

---

### /release-notes

**Trigger phrases**: "release notes", "what's new", "changelog"

**Usage**:
```bash
source .claude/scripts/signal-helper.sh && signal_release_notes
```

---

## Checking Watcher Status

Before sending signals, verify the watcher is running:

```bash
source .claude/scripts/signal-helper.sh && watcher_status
```

If not running, inform the user to start Jarvis via tmux:

```
The command watcher is not running. To enable autonomous command execution:

1. Exit this session
2. Start Jarvis with: .claude/scripts/launch-jarvis-tmux.sh

This will launch Claude in tmux with the watcher in a split pane.
```

---

## Architecture

```
┌──────────────────────────────────────────────────────────────────┐
│  User Request: "compact the context"                             │
├──────────────────────────────────────────────────────────────────┤
│  1. Claude (via this skill) creates signal file                  │
│     └── .claude/context/.command-signal (JSON)                   │
├──────────────────────────────────────────────────────────────────┤
│  2. auto-command-watcher.sh detects signal                       │
│     └── Polls every 2 seconds                                    │
├──────────────────────────────────────────────────────────────────┤
│  3. Watcher validates and executes                               │
│     └── tmux send-keys -t jarvis "/compact" Enter                │
├──────────────────────────────────────────────────────────────────┤
│  4. Claude Code executes /compact                                │
│     └── Context compacted, response shown                        │
└──────────────────────────────────────────────────────────────────┘
```

---

## Related

- Signal Protocol: @.claude/context/patterns/command-signal-protocol.md
- Signal Helper: @.claude/scripts/signal-helper.sh
- Watcher Script: @.claude/scripts/auto-command-watcher.sh
- tmux Launcher: @.claude/scripts/launch-jarvis-tmux.sh

---

*Autonomous Commands Skill v1.0.0*
