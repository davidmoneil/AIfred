---
description: Edit an existing development plan
argument-hint: <plan-name> [--section <section>]
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - AskUserQuestion
model: opus
---

# Parallel-Dev: Edit Plan

Modify an existing development plan through guided questions or direct editing.

## Arguments

- `<plan-name>` - Name of the plan to edit
- `--section <section>` - Edit specific section only (vision, features, technical, constraints, risks)
- `--add-feature` - Add a new feature
- `--add-risk` - Add a new risk
- `--approve` - Mark plan as approved

## Process

### 1. Find Plan File

```bash
PLAN_NAME="$ARGUMENTS"
SECTION=""
ACTION=""

# Parse flags
[[ "$ARGUMENTS" == *"--section"* ]] && SECTION=$(echo "$ARGUMENTS" | sed 's/.*--section \([^ ]*\).*/\1/')
[[ "$ARGUMENTS" == *"--add-feature"* ]] && ACTION="add-feature"
[[ "$ARGUMENTS" == *"--add-risk"* ]] && ACTION="add-risk"
[[ "$ARGUMENTS" == *"--approve"* ]] && ACTION="approve"

# Get plan name (first non-flag argument)
PLAN_NAME=$(echo "$ARGUMENTS" | sed 's/--[^ ]*//g' | xargs | cut -d' ' -f1)

PLAN_FILE=".claude/parallel-dev/plans/${PLAN_NAME}.md"

if [ ! -f "$PLAN_FILE" ]; then
    echo "Plan not found: $PLAN_NAME"
    echo ""
    echo "Available plans:"
    ls -1 .claude/parallel-dev/plans/*.md 2>/dev/null | xargs -n1 basename | sed 's/.md$//'
    exit 1
fi
```

### 2. Read Current Plan

Read and parse the existing plan to understand current state.

### 3. Handle Actions

#### Approve Plan (--approve)

```bash
if [ "$ACTION" = "approve" ]; then
    # Update status in frontmatter
    sed -i 's/^status:.*/status: approved/' "$PLAN_FILE"

    # Add approval date
    APPROVAL_DATE=$(date +%Y-%m-%d)
    sed -i "s/\*\*Approved\*\*:.*/\*\*Approved\*\*: $APPROVAL_DATE/" "$PLAN_FILE"

    echo "Plan approved: $PLAN_NAME"
    echo ""
    echo "Next step: /parallel-dev:decompose $PLAN_NAME"
    exit 0
fi
```

#### Add Feature (--add-feature)

Ask for feature details:
```
1. "Feature name?"
2. "Description?"
3. "Acceptance criteria (how do we know it's done)?"
4. "Is this must-have (MVP) or nice-to-have?"
```

Then append to appropriate section in plan file.

#### Add Risk (--add-risk)

Ask for risk details:
```
1. "What's the risk?"
2. "Impact if it occurs? (High/Medium/Low)"
3. "How do we mitigate it?"
```

Then append to risks section.

### 4. Section-Specific Editing

If `--section` specified, focus on that section:

#### Vision Section
```
Current vision:
{current_vision}

What would you like to change?
1. Update core purpose
2. Update target users
3. Add/modify success criteria
4. No changes
```

#### Features Section
```
Current features:
{feature_list}

What would you like to change?
1. Add must-have feature
2. Add nice-to-have feature
3. Remove a feature
4. Modify acceptance criteria
5. Move feature (must-have <-> nice-to-have)
6. Add out-of-scope item
7. No changes
```

#### Technical Section
```
Current stack:
{stack_summary}

What would you like to change?
1. Change frontend technology
2. Change backend technology
3. Change database
4. Change infrastructure
5. Add integration
6. No changes
```

#### Constraints Section
```
Current constraints:
{constraints_summary}

What would you like to change?
1. Update performance requirements
2. Update security requirements
3. Update timeline
4. Add new constraint
5. No changes
```

#### Risks Section
```
Current risks:
{risks_summary}

What would you like to change?
1. Add new risk
2. Update risk mitigation
3. Remove risk
4. No changes
```

### 5. Full Edit Mode

If no section specified, offer menu:

```
What would you like to edit?

1. Vision & Goals
2. Features & Scope
3. Technical Decisions
4. Constraints
5. Risks
6. Approve plan
7. Cancel
```

### 6. Save Changes

After each edit:
1. Update the plan file
2. Add entry to "Questions Answered" section with timestamp
3. Show confirmation

```
Plan updated: $PLAN_NAME

Changes:
  - Added feature: "Password reset flow"
  - Updated timeline to "Q2 2026"

View updated plan: /parallel-dev:plan-show $PLAN_NAME
```

### 7. Version History (Optional)

For significant changes, note in plan file:

```markdown
## Change History

| Date | Change | Section |
|------|--------|---------|
| 2026-01-17 | Initial creation | All |
| 2026-01-18 | Added OAuth feature | Features |
| 2026-01-18 | Changed DB to PostgreSQL | Technical |
```

## Examples

```bash
# Full interactive edit
/parallel-dev:plan-edit auth-system

# Edit specific section
/parallel-dev:plan-edit auth-system --section features

# Quick add feature
/parallel-dev:plan-edit auth-system --add-feature

# Approve plan
/parallel-dev:plan-edit auth-system --approve
```

## Output

After editing:
1. Confirmation of changes made
2. Diff summary (what changed)
3. Suggestion to review: `/parallel-dev:plan-show`
