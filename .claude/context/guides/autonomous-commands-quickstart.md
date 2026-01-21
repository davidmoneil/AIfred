# Autonomous Commands - 5-Minute Quickstart

Get autonomous command execution working in under 5 minutes.

---

## Step 1: Install Dependencies (1 min)

```bash
# macOS
brew install jq

# Linux
apt-get install jq
```

tmux should already be available at `~/bin/tmux` (built during Jarvis setup).

---

## Step 2: Launch Jarvis (30 sec)

```bash
cd ~/Claude/Jarvis
.claude/scripts/launch-jarvis-tmux.sh
```

You'll see a split screen:
- **Top pane**: Claude Code
- **Bottom pane**: Auto-command watcher

---

## Step 3: Test It (30 sec)

In your Claude conversation, say:

> "Show me my token usage"

Claude will:
1. Create a signal for `/usage`
2. Watcher detects and executes
3. Usage info appears

---

## Step 4: Use Naturally (ongoing)

Just ask for what you need:

| Say | Command |
|-----|---------|
| "Compact the context" | `/compact` |
| "Rename to Feature Work" | `/rename Feature Work` |
| "Show statistics" | `/stats` |
| "Run security review" | `/security-review` |

---

## That's It!

**Full guide**: `.claude/context/guides/autonomous-commands-guide.md`

**Troubleshooting**:
```bash
.claude/scripts/signal-helper.sh watcher-status
```
