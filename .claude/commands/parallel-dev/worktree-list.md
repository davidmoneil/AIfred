---
description: List all parallel-dev worktrees
allowed-tools:
  - Read
  - Bash
---

# Parallel-Dev: List Worktrees

Display all worktrees tracked by parallel-dev with their status.

## Process

### 1. Read Registry

```bash
REGISTRY=".claude/parallel-dev/registry.json"

if [ ! -f "$REGISTRY" ]; then
    echo "Parallel-dev not initialized. Run: /parallel-dev:init"
    exit 1
fi
```

### 2. Get Git Worktree List

Cross-reference with actual git worktrees:

```bash
# Get actual worktrees from git
GIT_WORKTREES=$(git worktree list --porcelain 2>/dev/null)
```

### 3. Format Output

Display table with:
- Branch name
- Status (active/orphaned/stale)
- Worktree path
- Allocated ports
- Created date

```bash
# Read from registry
echo "=== Parallel-Dev Worktrees ==="
echo ""

# If no worktrees
if [ "$(jq '.worktrees | length' "$REGISTRY")" = "0" ]; then
    echo "No worktrees registered."
    echo ""
    echo "Create one with: /parallel-dev:worktree-create <branch-name>"
    exit 0
fi

# Table header
printf "%-20s %-10s %-40s %-12s\n" "BRANCH" "STATUS" "PATH" "PORTS"
printf "%-20s %-10s %-40s %-12s\n" "------" "------" "----" "-----"

# Read and display each worktree
jq -r '.worktrees[] | "\(.branch)|\(.status)|\(.worktreePath)|\(.ports | join(","))"' "$REGISTRY" | \
while IFS='|' read -r branch status path ports; do
    # Verify worktree still exists
    if [ ! -d "$path" ]; then
        status="orphaned"
    fi
    printf "%-20s %-10s %-40s %-12s\n" "$branch" "$status" "$path" "${ports:-none}"
done
```

### 4. Show Git Worktree Comparison

Also show raw git worktree list for reference:

```bash
echo ""
echo "=== Git Worktrees (raw) ==="
git worktree list
```

### 5. Show Statistics

```bash
echo ""
TOTAL=$(jq '.worktrees | length' "$REGISTRY")
ACTIVE=$(jq '[.worktrees[] | select(.status == "active")] | length' "$REGISTRY")
PORTS_USED=$(jq '.portPool.allocated | length' "$REGISTRY")

echo "Summary: $TOTAL worktrees ($ACTIVE active), $PORTS_USED ports allocated"
```

## Output Format

```
=== Parallel-Dev Worktrees ===

BRANCH               STATUS     PATH                                     PORTS
------               ------     ----                                     -----
feature-auth         active     ~/tmp/worktrees/project/feature-auth     8100,8101
feature-logging      active     ~/tmp/worktrees/project/feature-logging  8102,8103
fix-bug-123          orphaned   ~/tmp/worktrees/project/fix-bug-123      none

=== Git Worktrees (raw) ===
/home/user/Code/project                    abc1234 [main]
/home/user/tmp/worktrees/project/feature-auth  def5678 [feature-auth]

Summary: 3 worktrees (2 active), 4 ports allocated
```

## Status Values

| Status | Meaning |
|--------|---------|
| `active` | Worktree exists and is usable |
| `orphaned` | Registry entry but worktree directory missing |
| `stale` | No activity for >30 minutes (future: heartbeat) |

## Arguments

- `--json` - Output as JSON instead of table
- `--project <name>` - Filter to specific project

## JSON Output (--json)

```json
{
  "worktrees": [
    {
      "branch": "feature-auth",
      "status": "active",
      "path": "~/tmp/worktrees/project/feature-auth",
      "ports": [8100, 8101],
      "created": "2026-01-17T10:00:00Z"
    }
  ],
  "summary": {
    "total": 2,
    "active": 2,
    "portsAllocated": 4
  }
}
```
