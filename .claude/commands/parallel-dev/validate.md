---
description: Run QA validation on completed execution
argument-hint: <plan-name> [--fix]
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
  - Task
model: opus
---

# Parallel-Dev: Validate

Run comprehensive QA validation on a completed (or in-progress) execution before merge.

## Arguments

- `<plan-name>` - Name of the plan to validate
- `--fix` - Attempt to auto-fix issues (formatting, simple lint errors)
- `--stage <stage>` - Run only specific stage (static-analysis, testing, build, acceptance)
- `--skip <check>` - Skip specific check (lint, typecheck, test, build)

## Prerequisites

- Execution must exist at `.claude/parallel-dev/executions/{plan-name}/`
- Worktree must be accessible
- Execution status should be `completed` or `paused` (warning if `executing`)

## Process

### 1. Validate Prerequisites

```bash
PLAN_NAME="$ARGUMENTS"
PLAN_SLUG=$(echo "$PLAN_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')
EXEC_DIR=".claude/parallel-dev/executions/${PLAN_SLUG}"
STATE_FILE="$EXEC_DIR/state.yaml"
TASKS_FILE=".claude/parallel-dev/plans/${PLAN_SLUG}-tasks.yaml"
VALIDATION_FILE="$EXEC_DIR/validation.yaml"

if [ ! -f "$STATE_FILE" ]; then
    echo "No execution found for: $PLAN_NAME"
    exit 1
fi

# Get worktree path
WORKTREE=$(grep "worktree:" "$STATE_FILE" | head -1 | cut -d: -f2- | xargs)

if [ ! -d "$WORKTREE" ]; then
    echo "Worktree not found: $WORKTREE"
    exit 1
fi
```

### 2. Initialize Validation

Create validation config from template:

```bash
mkdir -p "$EXEC_DIR"
TIMESTAMP=$(date -Iseconds)
```

### 3. Detect Project Type

```bash
cd "$WORKTREE"

# Detect project type
if [ -f "package.json" ]; then
    PROJECT_TYPE="javascript"
    [ -f "tsconfig.json" ] && PROJECT_TYPE="typescript"
elif [ -f "pyproject.toml" ] || [ -f "requirements.txt" ]; then
    PROJECT_TYPE="python"
elif [ -f "go.mod" ]; then
    PROJECT_TYPE="go"
elif [ -f "Cargo.toml" ]; then
    PROJECT_TYPE="rust"
else
    PROJECT_TYPE="unknown"
fi

echo "Detected project type: $PROJECT_TYPE"
```

### 4. Run Validation Stages

Display progress header:

```
===================================================================
 VALIDATING: {plan-name}
===================================================================

Worktree: {worktree-path}
Project Type: {project-type}

Running validation stages...
```

#### Stage 1: Static Analysis

```bash
echo ""
echo "Stage 1: Static Analysis"
echo "-------------------------"

# Linting
echo -n "  Linting... "
LINT_OUTPUT=$(npm run lint 2>&1) && echo "passed" || echo "failed"

# Type checking
echo -n "  Type checking... "
TYPE_OUTPUT=$(npx tsc --noEmit 2>&1) && echo "passed" || echo "failed"

# Formatting
echo -n "  Format check... "
FORMAT_OUTPUT=$(npx prettier --check . 2>&1) && echo "passed" || echo "warnings"
```

#### Stage 2: Testing

```bash
echo ""
echo "Stage 2: Testing"
echo "-------------------------"

# Unit tests
echo -n "  Unit tests... "
TEST_OUTPUT=$(npm test 2>&1)
TEST_EXIT=$?

if [ $TEST_EXIT -eq 0 ]; then
    PASSED=$(echo "$TEST_OUTPUT" | grep -oP '\d+(?= passed)' | tail -1)
    echo "$PASSED passed"
else
    FAILED=$(echo "$TEST_OUTPUT" | grep -oP '\d+(?= failed)' | tail -1)
    echo "$FAILED failed"
fi

# Coverage
COVERAGE=$(echo "$TEST_OUTPUT" | grep -oP '\d+(?=%)' | tail -1)
[ -n "$COVERAGE" ] && echo "  Coverage: $COVERAGE%"
```

#### Stage 3: Build Verification

```bash
echo ""
echo "Stage 3: Build Verification"
echo "-------------------------"

echo -n "  Building... "
BUILD_OUTPUT=$(npm run build 2>&1) && echo "passed" || echo "failed"

# Check bundle size
if [ -d "dist" ]; then
    SIZE=$(du -sh dist | cut -f1)
    echo "  Bundle size: $SIZE"
fi
```

#### Stage 4: Acceptance Criteria

Spawn the validator agent to review acceptance criteria:

The agent will:
1. Read each acceptance criterion
2. Search codebase for implementation evidence
3. Verify criterion is met
4. Return structured verification results

### 5. Generate Report

Compile results into validation report:

```
===================================================================
 VALIDATION REPORT: {plan-name}
===================================================================

Overall Status: PASSED (or FAILED)

Static Analysis
  Linting: 0 errors, 2 warnings
  Type Check: No errors
  Formatting: 3 files need formatting

Testing
  Unit Tests: 45/45 passed
  Integration Tests: skipped (none found)
  Coverage: 82%

Build
  Production Build: Success (12.3s)
  Bundle Size: 168kb

Acceptance Criteria (5/5 verified)
  [x] User can register with email
      Evidence: src/api/auth.ts:20
  [x] Passwords are hashed with bcrypt
      Evidence: src/services/auth.service.ts:45
  [x] JWT tokens returned on login
      Evidence: src/api/auth.ts:35
  [x] Protected routes require auth
      Evidence: src/middleware/auth.ts:10
  [x] User can reset password
      Evidence: src/api/auth.ts:78

-------------------------------------------------------------------

Summary:
  Total Checks: 8
  Passed: 7
  Warnings: 1
  Failed: 0

Recommendations:
  Run `prettier --write .` to fix formatting

-------------------------------------------------------------------

Ready to merge: YES

Next steps:
  1. Review any warnings above
  2. Run: /parallel-dev:merge {plan-name}

===================================================================
```

### 6. Handle Failures

If validation fails, show blockers and suggested fixes.

### 7. Auto-Fix Mode (--fix)

If `--fix` flag provided:

```bash
echo "Attempting auto-fixes..."

# Fix formatting
echo -n "  Fixing formatting... "
npx prettier --write . && echo "done"

# Fix auto-fixable lint issues
echo -n "  Fixing lint issues... "
npm run lint -- --fix && echo "done"

echo ""
echo "Re-running validation after fixes..."
```

### 8. Save Results

Save validation results:

```bash
# Update validation.yaml with results
# Update execution state with validation status

if [ "$VALIDATION_STATUS" = "passed" ]; then
    echo "validation_passed: true" >> "$STATE_FILE"
    echo "validated_at: $(date -Iseconds)" >> "$STATE_FILE"
fi
```

## Output

Creates/Updates:
- `.claude/parallel-dev/executions/{plan-name}/validation.yaml` - Full results
- `.claude/parallel-dev/executions/{plan-name}/validation-report.md` - Human-readable report

Updates:
- Execution state with validation status

## Validation Thresholds

| Check | Pass Criteria |
|-------|---------------|
| Lint | 0 errors (warnings OK) |
| Type Check | 0 errors |
| Unit Tests | 100% pass rate |
| Build | Exit code 0 |
| Acceptance | All criteria verified |

## Related Commands

- `/parallel-dev:status <name>` - View execution status
- `/parallel-dev:merge <name>` - Merge after validation passes
