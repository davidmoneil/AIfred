---
description: AI-powered analysis of Docker container logs
argument-hint: <container> [--lines N] [--since TIME]
skill: fabric
allowed-tools:
  - Bash(scripts/fabric-analyze-logs.sh:*)
---

# /fabric:analyze-logs

Analyze Docker container logs using AI.

## Usage

```
/fabric:analyze-logs <container> [options]
```

## Execution

```bash
scripts/fabric-analyze-logs.sh $ARGUMENTS
```

## Examples

```bash
/fabric:analyze-logs prometheus
/fabric:analyze-logs nginx --lines 200
/fabric:analyze-logs n8n --since 1h
```
