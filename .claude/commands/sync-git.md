---
argument-hint: [commit-message]
description: Sync repository to GitHub with automatic commit
allowed-tools:
  - Bash(git:*)
  - Bash(~/Scripts/sync-git.sh:*)
---

# /sync-git

Sync the current repository to GitHub using the `sync-git.sh` script.

## Usage

```
/sync-git [commit-message]
```

## Execution

Run the sync script:

```bash
~/Scripts/sync-git.sh $ARGUMENTS
```

Report the output to the user.

## Options

The script supports these flags (pass through $ARGUMENTS):

| Flag | Description |
|------|-------------|
| `-h, --help` | Show help |
| `-d, --dir DIR` | Sync a different directory |
| `-n, --dry-run` | Show what would be done |
| `-q, --quiet` | Minimal JSON output |

## Examples

```bash
# Auto-generate commit message
/sync-git

# With custom message
/sync-git "Add new feature"

# Dry run
/sync-git -n
```

## Error Handling

| Exit Code | Meaning | Action |
|-----------|---------|--------|
| 0 | Success | Report summary |
| 1 | Not a git repo | Tell user to navigate to a repo |
| 2 | No changes | Inform user repo is up to date |
| 3 | Git error | Show error, suggest fixes |

## Script Location

`~/Scripts/sync-git.sh` - Full implementation with:
- Auto-generated commit messages based on changed paths
- Secret detection warnings
- Color-coded output
- JSON output mode for automation

## Related

- Script: @Scripts/sync-git.sh
- Pattern: @.claude/context/patterns/capability-layering-pattern.md
