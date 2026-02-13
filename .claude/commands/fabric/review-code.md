---
description: AI-powered code review with prioritized recommendations
argument-hint: <file> [--staged]
skill: fabric
allowed-tools:
  - Bash(scripts/fabric-review-code.sh:*)
---

# /fabric:review-code

AI-powered code review.

## Usage

```
/fabric:review-code <file> [options]
/fabric:review-code --staged
```

## Execution

```bash
scripts/fabric-review-code.sh $ARGUMENTS
```

## Examples

```bash
/fabric:review-code src/server.ts
/fabric:review-code --staged
```
