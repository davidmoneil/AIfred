---
description: Check for and apply upstream AIfred updates
argument-hint: "[check|update|status|init]"
skill: upgrade
allowed-tools:
  - Bash(scripts/aifred-update.sh:*)
---

# Stay Current — AIfred Update System

Run the AIfred component update system to check for, review, and apply upstream changes.

## Usage

The user wants to run: `scripts/aifred-update.sh $ARGUMENTS`

### Subcommands

| Command | Purpose |
|---------|---------|
| `init` | First-time setup — scans components, creates `.aifred.yaml` manifest |
| `status` | Show local component inventory with modification detection |
| `check` | Compare local components against latest upstream tag |
| `update` | Interactive update — accept/skip/reject per component |

### Common Flags

- `-j` / `--json` — JSON output (for `check` and `status`)
- `-n` / `--dry-run` — Preview without applying changes
- `-q` / `--quiet` — Minimal output

## Behavior

1. If no arguments provided, default to `check`
2. Run the script and present results to the user
3. For `update`, the script runs interactively — let the user drive accept/skip/reject decisions
4. After `update`, suggest committing the changes if any were accepted

## Examples

```bash
# First-time setup after cloning AIfred
scripts/aifred-update.sh init

# Quick check for updates
scripts/aifred-update.sh check

# See what you have locally
scripts/aifred-update.sh status

# Apply updates interactively
scripts/aifred-update.sh update

# Preview what would change
scripts/aifred-update.sh update -n
```
