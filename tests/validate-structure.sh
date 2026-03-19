#!/bin/bash
# validate-structure.sh — Structural validation for AIfred configuration framework
#
# Validates syntax, references, and integrity of all config files without
# requiring Claude Code to be running. Output: TAP format.
#
# Usage:
#   ./tests/validate-structure.sh              # Run all checks
#   ./tests/validate-structure.sh --verbose    # Show passing checks too
#   ./tests/validate-structure.sh --fix        # Auto-fix where possible (future)

set -uo pipefail

# --- Config ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
VERBOSE="${1:-}"

# --- Counters ---
PASS=0
FAIL=0
SKIP=0
TEST_NUM=0

# --- TAP helpers ---
tap_pass() {
    ((TEST_NUM++))
    ((PASS++))
    if [[ "$VERBOSE" == "--verbose" ]]; then
        echo "ok $TEST_NUM - $1"
    fi
}

tap_fail() {
    ((TEST_NUM++))
    ((FAIL++))
    echo "not ok $TEST_NUM - $1"
    if [[ -n "${2:-}" ]]; then
        echo "  ---"
        echo "  detail: $2"
        echo "  ..."
    fi
}

tap_skip() {
    ((TEST_NUM++))
    ((SKIP++))
    echo "ok $TEST_NUM - $1 # SKIP $2"
}

section() {
    echo ""
    echo "# $1"
}

# --- Tool checks ---
HAS_SHELLCHECK=0
HAS_YAMLLINT=0
command -v shellcheck &>/dev/null && HAS_SHELLCHECK=1
command -v yamllint &>/dev/null && HAS_YAMLLINT=1

echo "TAP version 13"
echo "# AIfred Structural Validation"
echo "# Project root: $PROJECT_ROOT"
echo "# Date: $(date -Iseconds)"

# ============================================================================
# 1. Required files exist
# ============================================================================
section "Required Files"

REQUIRED_FILES=(
    ".claude/CLAUDE.md"
    ".claude/settings.json"
    "README.md"
    "scripts/profile-loader.js"
    "profiles/general.yaml"
    "profiles/schema.yaml"
)

for f in "${REQUIRED_FILES[@]}"; do
    if [[ -f "$PROJECT_ROOT/$f" ]]; then
        tap_pass "required file exists: $f"
    else
        tap_fail "required file exists: $f" "file not found"
    fi
done

# ============================================================================
# 2. Bash syntax (bash -n)
# ============================================================================
section "Bash Syntax"

while IFS= read -r -d '' script; do
    rel="${script#"$PROJECT_ROOT/"}"
    if bash -n "$script" 2>/dev/null; then
        tap_pass "bash syntax: $rel"
    else
        ERROR=$(bash -n "$script" 2>&1 | head -3)
        tap_fail "bash syntax: $rel" "$ERROR"
    fi
done < <(find "$PROJECT_ROOT/scripts" "$PROJECT_ROOT/.claude/jobs" \
    -name "*.sh" -type f -print0 2>/dev/null)

# ============================================================================
# 3. JavaScript syntax (node --check)
# ============================================================================
section "JavaScript Syntax"

while IFS= read -r -d '' jsfile; do
    rel="${jsfile#"$PROJECT_ROOT/"}"
    if node --check "$jsfile" 2>/dev/null; then
        tap_pass "js syntax: $rel"
    else
        ERROR=$(node --check "$jsfile" 2>&1 | head -3)
        tap_fail "js syntax: $rel" "$ERROR"
    fi
done < <(find "$PROJECT_ROOT/.claude/hooks" -name "*.js" -type f -print0 2>/dev/null)

# ============================================================================
# 4. YAML lint
# ============================================================================
section "YAML Lint"

YAMLLINT_CONFIG="$PROJECT_ROOT/.yamllint"
if [[ $HAS_YAMLLINT -eq 1 ]]; then
    YAMLLINT_ARGS=(-d relaxed)
    [[ -f "$YAMLLINT_CONFIG" ]] && YAMLLINT_ARGS=(-c "$YAMLLINT_CONFIG")

    while IFS= read -r -d '' yamlfile; do
        rel="${yamlfile#"$PROJECT_ROOT/"}"
        if yamllint "${YAMLLINT_ARGS[@]}" "$yamlfile" 2>/dev/null; then
            tap_pass "yaml lint: $rel"
        else
            ERROR=$(yamllint "${YAMLLINT_ARGS[@]}" "$yamlfile" 2>&1 | tail -3)
            tap_fail "yaml lint: $rel" "$ERROR"
        fi
    done < <(find "$PROJECT_ROOT/profiles" "$PROJECT_ROOT/.claude/jobs" \
        "$PROJECT_ROOT/.claude/skills" "$PROJECT_ROOT/.claude/context" \
        \( -name "*.yaml" -o -name "*.yml" \) -type f -print0 2>/dev/null)
else
    tap_skip "yaml lint" "yamllint not installed"
fi

# ============================================================================
# 5. JSON syntax (jq)
# ============================================================================
section "JSON Syntax"

while IFS= read -r -d '' jsonfile; do
    rel="${jsonfile#"$PROJECT_ROOT/"}"
    if jq empty "$jsonfile" 2>/dev/null; then
        tap_pass "json syntax: $rel"
    else
        ERROR=$(jq empty "$jsonfile" 2>&1 | head -3)
        tap_fail "json syntax: $rel" "$ERROR"
    fi
done < <(find "$PROJECT_ROOT/.claude" "$PROJECT_ROOT" -maxdepth 2 \
    -name "*.json" -type f -print0 2>/dev/null | sort -z)

# ============================================================================
# 6. ShellCheck
# ============================================================================
section "ShellCheck"

if [[ $HAS_SHELLCHECK -eq 1 ]]; then
    SHELLCHECK_ARGS=(-S warning -s bash)
    [[ -f "$PROJECT_ROOT/.shellcheckrc" ]] && SHELLCHECK_ARGS+=(-x)

    while IFS= read -r -d '' script; do
        rel="${script#"$PROJECT_ROOT/"}"
        if shellcheck "${SHELLCHECK_ARGS[@]}" "$script" 2>/dev/null; then
            tap_pass "shellcheck: $rel"
        else
            ERROR=$(shellcheck "${SHELLCHECK_ARGS[@]}" "$script" 2>&1 | head -5)
            tap_fail "shellcheck: $rel" "$ERROR"
        fi
    done < <(find "$PROJECT_ROOT/scripts" "$PROJECT_ROOT/.claude/jobs" \
        -name "*.sh" -type f -print0 2>/dev/null)
else
    tap_skip "shellcheck" "shellcheck not installed"
fi

# ============================================================================
# 7. Hook alignment — settings.json references vs disk
# ============================================================================
section "Hook Alignment"

SETTINGS="$PROJECT_ROOT/.claude/settings.json"
if [[ -f "$SETTINGS" ]]; then
    # Extract all .js file references from hook commands
    while IFS= read -r hook_cmd; do
        # Strip quotes and resolve $CLAUDE_PROJECT_DIR
        js_path=$(echo "$hook_cmd" | sed 's/^node[[:space:]]*//' | tr -d '"' | sed "s|\\\$CLAUDE_PROJECT_DIR|$PROJECT_ROOT|g; s|\\\${CLAUDE_PROJECT_DIR}|$PROJECT_ROOT|g")
        [[ "$js_path" != *.js ]] && continue

        rel="${js_path#"$PROJECT_ROOT/"}"
        if [[ -f "$js_path" ]]; then
            tap_pass "hook file exists: $rel"
        else
            tap_fail "hook file exists: $rel" "referenced in settings.json but not found on disk"
        fi
    done < <(jq -r '.. | .command? // empty' "$SETTINGS" 2>/dev/null | grep 'node.*\.js' | sort -u)
else
    tap_fail "settings.json exists" "required for hook validation"
fi

# ============================================================================
# 8. Profile compilation (dry-run)
# ============================================================================
section "Profile Compilation"

PROFILE_LOADER="$PROJECT_ROOT/scripts/profile-loader.js"
if [[ -f "$PROFILE_LOADER" ]]; then
    OUTPUT=$(cd "$PROJECT_ROOT" && node "$PROFILE_LOADER" --dry-run 2>&1)
    EXIT=$?
    if [[ $EXIT -eq 0 ]]; then
        tap_pass "profile-loader --dry-run succeeds"
    else
        tap_fail "profile-loader --dry-run succeeds" "exit $EXIT: $(echo "$OUTPUT" | tail -3)"
    fi
else
    tap_skip "profile-loader --dry-run" "profile-loader.js not found"
fi

# ============================================================================
# 9. Hardcoded paths
# ============================================================================
section "Hardcoded Paths"

HARDCODED_PATTERNS=(
    "/home/davidmoneil"
    "/home/[a-z]*/AIProjects"
)

# Only check files that should be generalized (not docs/examples)
CHECK_DIRS=(
    "$PROJECT_ROOT/scripts"
    "$PROJECT_ROOT/.claude/hooks"
    "$PROJECT_ROOT/.claude/jobs"
    "$PROJECT_ROOT/.claude/settings.json"
    "$PROJECT_ROOT/profiles"
)

for pattern in "${HARDCODED_PATTERNS[@]}"; do
    MATCHES=""
    for dir in "${CHECK_DIRS[@]}"; do
        if [[ -d "$dir" ]]; then
            FOUND=$(grep -rl --exclude-dir='__pycache__' --exclude-dir='node_modules' --exclude='*.pyc' "$pattern" "$dir" 2>/dev/null || true)
        elif [[ -f "$dir" ]]; then
            FOUND=$(grep -l "$pattern" "$dir" 2>/dev/null || true)
        else
            FOUND=""
        fi
        if [[ -n "$FOUND" ]]; then
            MATCHES="${MATCHES}${FOUND}"$'\n'
        fi
    done
    MATCHES=$(echo "$MATCHES" | sed '/^$/d')
    if [[ -z "$MATCHES" ]]; then
        tap_pass "no hardcoded path: $pattern"
    else
        FILE_COUNT=$(echo "$MATCHES" | wc -l)
        FILES=$(echo "$MATCHES" | head -5 | sed "s|$PROJECT_ROOT/||g" | tr '\n' ', ')
        tap_fail "no hardcoded path: $pattern" "found in $FILE_COUNT file(s): ${FILES%, }"
    fi
done

# ============================================================================
# 10. Skill structure validation
# ============================================================================
section "Skill Structure"

SKILLS_DIR="$PROJECT_ROOT/.claude/skills"
if [[ -d "$SKILLS_DIR" ]]; then
    while IFS= read -r -d '' skill_dir; do
        skill_name=$(basename "$skill_dir")
        [[ "$skill_name" == "_template" ]] && continue

        rel=".claude/skills/$skill_name"
        if [[ -f "$skill_dir/SKILL.md" ]]; then
            tap_pass "skill has SKILL.md: $rel"
        else
            tap_fail "skill has SKILL.md: $rel" "SKILL.md missing"
        fi
    done < <(find "$SKILLS_DIR" -mindepth 1 -maxdepth 1 -type d -print0)
fi

# ============================================================================
# 11. Skill config.json validation
# ============================================================================
section "Skill Config"

if [[ -d "$SKILLS_DIR" ]]; then
    while IFS= read -r -d '' config; do
        rel="${config#"$PROJECT_ROOT/"}"
        if jq empty "$config" 2>/dev/null; then
            tap_pass "skill config valid: $rel"
        else
            tap_fail "skill config valid: $rel" "invalid JSON"
        fi
    done < <(find "$SKILLS_DIR" -name "config.json" -type f -print0 2>/dev/null)
fi

# ============================================================================
# Summary
# ============================================================================
echo ""
echo "1..$TEST_NUM"
echo ""

TOTAL=$((PASS + FAIL + SKIP))
if [[ $FAIL -eq 0 ]]; then
    echo -e "\033[0;32m# All $TOTAL tests passed ($PASS ok, $SKIP skipped)\033[0m"
    exit 0
else
    echo -e "\033[0;31m# $FAIL of $TOTAL tests failed ($PASS passed, $SKIP skipped)\033[0m"
    exit 1
fi
