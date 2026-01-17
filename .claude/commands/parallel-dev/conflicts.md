---
description: Check for merge conflicts before merging
argument-hint: <plan-name>
allowed-tools:
  - Read
  - Bash
  - Glob
  - Grep
---

# Parallel-Dev: Conflicts

Preview potential merge conflicts before attempting to merge back to main branch.

## Arguments

- `<plan-name>` - Name of the plan to check for conflicts

## Process

### 1. Validate Prerequisites

```bash
PLAN_NAME="$ARGUMENTS"
PLAN_SLUG=$(echo "$PLAN_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')
EXEC_DIR=".claude/parallel-dev/executions/${PLAN_SLUG}"
STATE_FILE="$EXEC_DIR/state.yaml"

if [ ! -f "$STATE_FILE" ]; then
    echo "No execution found for: $PLAN_NAME"
    exit 1
fi

WORKTREE=$(grep "worktree:" "$STATE_FILE" | head -1 | cut -d: -f2- | xargs)
BRANCH=$(grep "branch:" "$STATE_FILE" | head -1 | cut -d: -f2 | xargs)
BASE_BRANCH=$(grep "base_branch:" "$STATE_FILE" | head -1 | cut -d: -f2 | xargs)
BASE_BRANCH=${BASE_BRANCH:-main}
```

### 2. Fetch Latest Changes

```bash
cd "$WORKTREE"

echo "Fetching latest changes from origin..."
git fetch origin "$BASE_BRANCH"
```

### 3. Check for Conflicts

```bash
# Try merge without committing
echo "Checking for conflicts with $BASE_BRANCH..."

# Dry-run merge
MERGE_OUTPUT=$(git merge --no-commit --no-ff "origin/$BASE_BRANCH" 2>&1)
MERGE_EXIT=$?

# Abort the test merge
git merge --abort 2>/dev/null
```

### 4. Analyze Results

#### No Conflicts

```
===================================================================
 CONFLICT CHECK: {plan-name}
===================================================================

No conflicts detected!

Branch: {branch}
Target: {base-branch}

Changes since branch:
  - {base-branch} has {N} new commits
  - Your branch has {M} commits

Files changed in both branches:
  (none with conflicts)

-------------------------------------------------------------------

Ready to merge: /parallel-dev:merge {plan-name}

===================================================================
```

#### Conflicts Found

```
===================================================================
 CONFLICT CHECK: {plan-name}
===================================================================

Conflicts detected!

Branch: {branch}
Target: {base-branch}

Conflicting Files (3):
  x src/services/auth.ts
     Both branches modified lines 45-67
  x src/api/routes.ts
     Both branches added new routes
  x package.json
     Dependency version conflicts

-------------------------------------------------------------------

Conflict Details:

src/services/auth.ts
   Your changes: Added password reset logic
   Their changes: Refactored authentication flow
   Recommendation: Manual merge required

src/api/routes.ts
   Your changes: Added /auth/reset endpoint
   Their changes: Added /auth/verify endpoint
   Recommendation: Both additions can coexist

package.json
   Your changes: bcrypt@5.1.0
   Their changes: bcrypt@5.0.1
   Recommendation: Use your version (newer)

-------------------------------------------------------------------

Resolution Options:

1. Resolve manually:
   cd {worktree}
   git merge origin/{base-branch}
   # Fix conflicts
   git add .
   git commit

2. Rebase onto latest:
   cd {worktree}
   git rebase origin/{base-branch}
   # Fix conflicts during rebase

3. Request AI assistance:
   /parallel-dev:merge {plan-name} --resolve

===================================================================
```

### 5. Show File Diff Preview

For each conflicting file, show what changed:

```bash
echo "Showing conflict preview for: $FILE"

# Show what changed in base branch
echo "Changes in $BASE_BRANCH:"
git diff "$BRANCH"..."origin/$BASE_BRANCH" -- "$FILE" | head -50

# Show what changed in feature branch
echo "Your changes:"
git diff "origin/$BASE_BRANCH"..."$BRANCH" -- "$FILE" | head -50
```

### 6. Classify Conflicts

| Conflict Type | Severity | Resolution |
|---------------|----------|------------|
| Same lines modified | High | Manual merge |
| Adjacent lines | Medium | Review recommended |
| Different sections | Low | Usually auto-merge |
| Dependency versions | Medium | Pick latest |
| New files same name | High | Rename or merge |

### 7. Generate Recommendations

Based on conflict analysis, provide specific recommendations for each file.

## Output

Displays:
- Conflict status (clean or conflicted)
- List of conflicting files
- Conflict details with recommendations
- Resolution options

## Related Commands

- `/parallel-dev:merge <name>` - Merge with optional conflict resolution
- `/parallel-dev:status <name>` - View execution status
