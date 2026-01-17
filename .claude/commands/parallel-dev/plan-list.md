---
description: List all development plans with status
allowed-tools:
  - Read
  - Bash
  - Glob
---

# Parallel-Dev: List Plans

Display all development plans with their status and summary.

## Process

### 1. Find All Plans

```bash
PLANS_DIR=".claude/parallel-dev/plans"

if [ ! -d "$PLANS_DIR" ]; then
    echo "No plans directory found."
    echo "Create a plan with: /parallel-dev:plan <name>"
    exit 0
fi

PLAN_COUNT=$(ls -1 "$PLANS_DIR"/*.md 2>/dev/null | wc -l)

if [ "$PLAN_COUNT" -eq 0 ]; then
    echo "No plans found."
    echo ""
    echo "Create a plan with: /parallel-dev:plan <name>"
    exit 0
fi
```

### 2. Display Plan List

```
===================================================================
 DEVELOPMENT PLANS ($PLAN_COUNT total)
===================================================================

NAME                 STATUS      TYPE              CREATED
----                 ------      ----              -------
auth-system          approved    web-app           2026-01-17
grc-dashboard        draft       web-app           2026-01-16
cli-tool             executing   cli               2026-01-15

===================================================================

Commands:
  View:   /parallel-dev:plan-show <name>
  Edit:   /parallel-dev:plan-edit <name>
  New:    /parallel-dev:plan <name>

===================================================================
```

### 3. Parse Each Plan

For each plan file, extract from frontmatter:
- name
- status (draft, approved, executing, completed, abandoned)
- project_type
- created date

```bash
for plan in "$PLANS_DIR"/*.md; do
    NAME=$(basename "$plan" .md)

    # Extract frontmatter values
    STATUS=$(grep -m1 "^status:" "$plan" | cut -d: -f2 | xargs)
    TYPE=$(grep -m1 "^project_type:" "$plan" | cut -d: -f2 | xargs)
    CREATED=$(grep -m1 "^created:" "$plan" | cut -d: -f2 | cut -dT -f1 | xargs)

    printf "%-20s %-11s %-17s %s\n" "$NAME" "${STATUS:-draft}" "${TYPE:-unknown}" "${CREATED:-unknown}"
done
```

## Status Values

| Status | Meaning |
|--------|---------|
| `draft` | Plan created but not yet approved |
| `approved` | User approved, ready for decomposition |
| `decomposed` | Tasks generated, ready for execution |
| `executing` | Currently being built |
| `completed` | All tasks done, merged |
| `abandoned` | Work stopped, not completing |

## Arguments

- `--status <status>` - Filter by status
- `--type <type>` - Filter by project type
- `--json` - Output as JSON

## JSON Output (--json)

```json
{
  "plans": [
    {
      "name": "auth-system",
      "status": "approved",
      "type": "web-app",
      "created": "2026-01-17",
      "file": ".claude/parallel-dev/plans/auth-system.md"
    }
  ],
  "total": 3
}
```
