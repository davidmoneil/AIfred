---
name: fabric
version: 1.0.0
description: AI-powered text processing using Fabric patterns with local Ollama
category: automation
tags: [fabric, ollama, logs, code-review, commit-messages, ai-patterns]
created: 2026-01-22
context: shared
model: sonnet
---

# Fabric Skill

AI-powered text processing using [danielmiessler/fabric](https://github.com/danielmiessler/fabric) patterns with local Ollama inference.

---

## Overview

| Aspect | Description |
|--------|-------------|
| Purpose | Run pre-built AI prompt patterns for logs, code review, commit messages |
| Backend | Local Ollama (configurable models) |
| Pattern | Capability Layering - thin wrapper over existing CLI scripts |
| Cost | Free (local inference) |
| Requires | Ollama installed and running, fabric CLI |

---

## Quick Actions

| Need | Action | Command |
|------|--------|---------|
| Analyze logs | AI analysis of Docker container logs | `/fabric:analyze-logs <container>` |
| Commit message | Generate from staged changes | `/fabric:commit-msg` |
| Code review | AI-powered code review | `/fabric:review-code <file>` |
| List patterns | See all available patterns | `/fabric patterns` |
| Run any pattern | Execute arbitrary pattern | `/fabric run <pattern>` |

---

## Commands

### /fabric:analyze-logs

Analyze Docker container logs for patterns, anomalies, and recommendations.

```bash
/fabric:analyze-logs prometheus           # Last 50 lines
/fabric:analyze-logs nginx --lines 200    # More context
/fabric:analyze-logs n8n --since 1h       # Recent logs only
```

### /fabric:commit-msg

Generate conventional commit messages from git diffs.

```bash
/fabric:commit-msg              # From staged changes
/fabric:commit-msg --all        # From all changes
```

### /fabric:review-code

AI-powered code review with prioritized recommendations.

```bash
/fabric:review-code src/server.ts    # Single file
/fabric:review-code --staged         # Staged changes
```

### /fabric patterns

List all available Fabric patterns.

### /fabric run

Run any Fabric pattern directly.

```bash
echo "text" | /fabric run extract_wisdom
/fabric run summarize --file document.md
```

---

## Architecture

This skill follows the **Capability Layering Pattern**:

```
Layer 5: USER REQUEST
  "analyze the prometheus logs"
       ↓
Layer 4: PROMPT (this skill)
  Routes to correct script
       ↓
Layer 3: CLI
  scripts/fabric-analyze-logs.sh prometheus
       ↓
Layer 2: CODE
  fabric-wrapper.sh → fabric CLI → Ollama
       ↓
Layer 1: INFRASTRUCTURE
  Ollama service (localhost:11434)
```

### Scripts (Layer 3)

| Script | Purpose |
|--------|---------|
| `scripts/fabric-wrapper.sh` | Core wrapper with health checks, model fallback |
| `scripts/fabric-analyze-logs.sh` | Log analysis for Docker/files |
| `scripts/fabric-commit-msg.sh` | Commit message generation |
| `scripts/fabric-review-code.sh` | Code review |

---

## Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `FABRIC_PRIMARY_MODEL` | `qwen2.5:32b` | Primary model for analysis |
| `FABRIC_FALLBACK_MODEL` | `qwen2.5:7b-instruct` | Fallback on timeout |
| `FABRIC_TIMEOUT_PRIMARY` | `90` | Timeout in seconds for primary |
| `FABRIC_TIMEOUT_FALLBACK` | `120` | Timeout for fallback |
| `OLLAMA_URL` | `http://localhost:11434` | Ollama API endpoint |

---

## Troubleshooting

### Ollama Not Responding

The wrapper auto-restarts Ollama, but if issues persist:

```bash
# Check Ollama status
systemctl status ollama  # Linux
# or: ollama serve       # macOS

# Restart manually
sudo systemctl restart ollama  # Linux
# or: brew services restart ollama  # macOS
```

---

## Related

- **Capability Layering Pattern**: @.claude/context/patterns/capability-layering-pattern.md
- **Ollama Management**: `/ollama` command (if configured)
- **Fabric GitHub**: https://github.com/danielmiessler/fabric
