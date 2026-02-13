---
description: Generate conventional commit messages from git diffs
argument-hint: [--all] [--staged]
skill: fabric
allowed-tools:
  - Bash(scripts/fabric-commit-msg.sh:*)
---

# /fabric:commit-msg

Generate commit messages from git diffs using AI.

## Usage

```
/fabric:commit-msg [options]
```

## Execution

```bash
scripts/fabric-commit-msg.sh $ARGUMENTS
```

## Examples

```bash
/fabric:commit-msg              # Staged changes
/fabric:commit-msg --all        # All changes
```
