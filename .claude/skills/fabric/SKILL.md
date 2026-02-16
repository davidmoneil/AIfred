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
| Backend | Local Ollama (qwen2.5:32b primary, qwen2.5:7b-instruct fallback) |
| Pattern | Capability Layering - thin wrapper over existing CLI scripts |
| Cost | Free (local inference) |

---

## Quick Actions

| Need | Action | Command |
|------|--------|---------|
| Analyze logs | AI analysis of Docker container logs | `/fabric:analyze-logs <container>` |
| Commit message | Generate from staged changes | `/fabric:commit-msg` |
| Code review | AI-powered code review | `/fabric:review-code <file>` |
| List patterns | See all 234 available patterns | `/fabric patterns` |
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

**Output sections**: Overview, Key Observations, Patterns/Anomalies, Recommendations

### /fabric:commit-msg

Generate conventional commit messages from git diffs.

```bash
/fabric:commit-msg              # From staged changes
/fabric:commit-msg --all        # From all changes
```

**Output format**: `<type>: <description>` with change list

### /fabric:review-code

AI-powered code review with prioritized recommendations.

```bash
/fabric:review-code src/server.ts    # Single file
/fabric:review-code --staged         # Staged changes
```

**Output sections**: Overall Assessment, Prioritized Recommendations, Detailed Feedback

### /fabric patterns

List all available Fabric patterns.

```bash
/fabric patterns                # List all 234 patterns
/fabric patterns --search log   # Filter by keyword
```

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
  Scripts/fabric-analyze-logs.sh prometheus
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
| `Scripts/fabric-wrapper.sh` | Core wrapper with health checks, model fallback |
| `Scripts/fabric-analyze-logs.sh` | Log analysis for Docker/files |
| `Scripts/fabric-commit-msg.sh` | Commit message generation |
| `Scripts/fabric-review-code.sh` | Code review |

### Features Built Into Scripts

- **Ollama Health Check**: Auto-restarts Ollama if unresponsive
- **Model Fallback**: 32b → 7b on timeout (configurable)
- **Streaming Output**: Real-time results
- **Error Handling**: Clear error messages

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

### Model Selection Guide

| Task | Recommended Model | Reason |
|------|-------------------|--------|
| Log analysis | 32b (default) | Benefits from deep reasoning |
| Commit messages | 7b | Fast, simple task |
| Code review | 7b (default) | Good balance of speed/quality |
| Complex analysis | 32b | Use `--model 32b` flag |

---

## Patterns Reference

Fabric includes 234 patterns. Most useful for this infrastructure:

| Pattern | Use Case | Value |
|---------|----------|-------|
| `analyze_logs` | Docker/service troubleshooting | HIGH |
| `summarize_git_diff` | Commit messages | HIGH |
| `review_code` | Code review | HIGH |
| `extract_wisdom` | Document summarization | MEDIUM |
| `create_design_document` | Technical specs | MEDIUM |
| `analyze_threat_report` | Security analysis | MEDIUM |

Full pattern list: `fabric --list` or https://github.com/danielmiessler/fabric/tree/main/patterns

---

## Troubleshooting

### Ollama Not Responding

The wrapper auto-restarts Ollama, but if issues persist:

```bash
# Check Ollama status
systemctl status ollama

# Restart manually
sudo systemctl restart ollama

# Check models available
ollama list
```

### Model Timeout

For large inputs, increase timeout:

```bash
FABRIC_TIMEOUT_PRIMARY=180 fabric-analyze-logs.sh prometheus --lines 500
```

Or force the faster model:

```bash
fabric-analyze-logs.sh prometheus --model 7b
```

### Pattern Not Found

Update fabric patterns:

```bash
fabric --update
```

---

## Related

- **Capability Layering Pattern**: @.claude/context/patterns/capability-layering-pattern.md
- **Scripts Documentation**: @Scripts/README.md
- **Ollama Management**: `/ollama` skill (if needed)
- **Fabric GitHub**: https://github.com/danielmiessler/fabric

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | 2026-01-22 | Initial skill creation with 4 commands |
