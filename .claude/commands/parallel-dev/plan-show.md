---
description: Display plan details with visual summary
argument-hint: <plan-name>
allowed-tools:
  - Read
  - Bash
  - Glob
---

# Parallel-Dev: Show Plan

Display a development plan with visual summary and status.

## Arguments

- `<plan-name>` - Name of the plan to display

## Process

### 1. Find Plan File

```bash
PLAN_NAME="$ARGUMENTS"

if [ -z "$PLAN_NAME" ]; then
    echo "Plan name required"
    echo "Usage: /parallel-dev:plan-show <plan-name>"
    echo ""
    echo "Available plans:"
    ls -1 .claude/parallel-dev/plans/*.md 2>/dev/null | xargs -n1 basename | sed 's/.md$//'
    exit 1
fi

# Try exact match first, then fuzzy
PLAN_FILE=".claude/parallel-dev/plans/${PLAN_NAME}.md"
if [ ! -f "$PLAN_FILE" ]; then
    # Try with slug conversion
    PLAN_SLUG=$(echo "$PLAN_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')
    PLAN_FILE=".claude/parallel-dev/plans/${PLAN_SLUG}.md"
fi

if [ ! -f "$PLAN_FILE" ]; then
    echo "Plan not found: $PLAN_NAME"
    echo ""
    echo "Available plans:"
    ls -1 .claude/parallel-dev/plans/*.md 2>/dev/null | xargs -n1 basename | sed 's/.md$//'
    exit 1
fi
```

### 2. Parse Plan Metadata

Extract frontmatter:
- name
- version
- created
- status
- project_type

### 3. Display Visual Summary

```
===================================================================
 PLAN: {name}
===================================================================

Status: {status}  |  Type: {project_type}  |  Created: {created}

-------------------------------------------------------------------
 VISION
-------------------------------------------------------------------

{Core Purpose summary}

Target Users: {target_users}

Success Criteria:
  - {criterion_1}
  - {criterion_2}
  - {criterion_3}

-------------------------------------------------------------------
 FEATURES
-------------------------------------------------------------------

Must-Have (MVP):
  1. {feature_1}
  2. {feature_2}
  3. {feature_3}

Nice-to-Have:
  - {nice_to_have_1}
  - {nice_to_have_2}

Out of Scope:
  x {out_of_scope_1}
  x {out_of_scope_2}

-------------------------------------------------------------------
 TECHNICAL STACK
-------------------------------------------------------------------

  Frontend:  {frontend}
  Backend:   {backend}
  Database:  {database}
  Infra:     {infrastructure}

-------------------------------------------------------------------
 CONSTRAINTS
-------------------------------------------------------------------

  Performance: {performance_req}
  Security:    {security_req}
  Timeline:    {timeline}

-------------------------------------------------------------------
 RISKS
-------------------------------------------------------------------

  ! {risk_1} -> {mitigation_1}
  ! {risk_2} -> {mitigation_2}

===================================================================

File: {plan_file}

Commands:
  Edit:      /parallel-dev:plan-edit {name}
  Decompose: /parallel-dev:decompose {name}  (when ready)

===================================================================
```

### 4. Show Related Artifacts

If tasks exist, show summary:
```
Tasks: 12 total (0 completed, 0 in progress)
Execution: Not started
```

## Arguments

- `--raw` - Show raw markdown instead of formatted
- `--section <name>` - Show only specific section (vision, features, technical, constraints, risks)

## Output

Displays:
1. Visual header with status
2. Vision summary
3. Feature list (categorized)
4. Technical stack table
5. Constraints and risks
6. Related commands
