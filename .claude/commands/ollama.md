---
argument-hint: <command> [args]
description: Manage local Ollama LLM service
skill: infrastructure-ops
note: Requires Ollama installed locally. Configure via /setup Phase 8 (Optional Integrations).
allowed-tools:
  - SlashCommand(/agent:*)
---

Manage the local Ollama LLM service using the specialized ollama-manager agent.

## Available Commands

### Status & Information
- `/ollama status` - Check service status, version, and health
- `/ollama health` - Run comprehensive health check
- `/ollama list` - List all installed models with details
- `/ollama gpu` - Check GPU status and VRAM usage
- `/ollama logs [lines]` - View recent service logs (default: 30 lines)

### Model Management
- `/ollama pull <model-name>` - Download a new model
- `/ollama remove <model-name>` - Remove an installed model
- `/ollama test <model-name>` - Test model inference

### Maintenance
- `/ollama update` - Check for Ollama version updates

## Usage

If **NO ARGUMENTS** provided: Show help and quick status.
If **ARGUMENTS** provided: Launch ollama-manager agent.

## Quick Status (No Arguments)

```bash
# Check if ollama is available
command -v ollama &>/dev/null && echo "Ollama found" || echo "Ollama not installed"
ollama --version 2>/dev/null
ollama list 2>/dev/null | wc -l
curl -s -o /dev/null -w "%{http_code}" http://localhost:11434/api/version 2>/dev/null
```

## Examples

```bash
/ollama status
/ollama list
/ollama pull llama3:latest
/ollama test llama2
/ollama health
```
