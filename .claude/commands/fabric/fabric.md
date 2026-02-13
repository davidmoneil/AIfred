---
description: AI-powered text processing using Fabric patterns with local Ollama
argument-hint: <pattern> [options]
skill: fabric
allowed-tools:
  - Bash(scripts/fabric-wrapper.sh:*)
---

# /fabric - AI Text Processing

Run Fabric patterns with local Ollama inference.

## Usage

```
/fabric <pattern> [options]
/fabric patterns [--search keyword]
/fabric run <pattern>
```

## Execution

```bash
scripts/fabric-wrapper.sh $ARGUMENTS
```

## Examples

```bash
/fabric patterns                        # List all patterns
/fabric patterns --search log           # Filter patterns
echo "text" | /fabric run extract_wisdom
```
