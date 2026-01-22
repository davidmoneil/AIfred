---
argument-hint: <source-path> <category/link-name>
description: Create symlink in external-sources with documentation
allowed-tools:
  - Bash(~/Scripts/link-external.sh:*)
  - Read
---

# /link-external - Create External Source Link

Create a symlink in `external-sources/` with proper documentation.

## Quick Reference

```bash
# Dry run first
~/Scripts/link-external.sh "$SOURCE" "$CATEGORY/$NAME" --dry-run

# Create link with description
~/Scripts/link-external.sh "$SOURCE" "$CATEGORY/$NAME" -d "Description"
```

## Execution

**Parse arguments from**: $ARGUMENTS

Run the CLI script:

```bash
~/Scripts/link-external.sh $ARGUMENTS
```

### Categories

| Category | Purpose |
|----------|---------|
| docker | Docker configurations |
| logs | Log directories |
| nas | NAS mount points |
| configs | Configuration files |
| services | Service directories |

## Example Usages

```bash
# Link Docker compose file
/link-external /opt/docker/n8n/docker-compose.yml docker/n8n-compose.yml

# Link log directory
/link-external /var/log/nginx logs/nginx

# Link NAS share with description
/link-external /mnt/synology/obsidian nas/obsidian-vault -d "Obsidian vault on NAS"
```

## Post-Execution

After script runs, if `--description` was provided:
- Offer to add the suggested entry to paths-registry.yaml
- Suggest updating relevant service context file

## Script Details

**Location**: `~/Scripts/link-external.sh`
**Exit Codes**:
- 0: Success
- 1: Invalid arguments
- 2: Source path doesn't exist
- 3: Link already exists
