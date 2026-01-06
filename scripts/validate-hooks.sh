#!/bin/bash
# ==============================================================================
# Jarvis Hook Validation
# ==============================================================================
# Validates JavaScript syntax of all hooks in .claude/hooks/
#
# Usage: ./scripts/validate-hooks.sh [JARVIS_PATH]
#
# Exit codes:
#   0 - All hooks valid
#   1 - One or more hooks have syntax errors
# ==============================================================================

set -e

# Determine paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
JARVIS_PATH="${1:-$(dirname "$SCRIPT_DIR")}"
HOOKS_DIR="$JARVIS_PATH/.claude/hooks"

# Check Node.js availability
if ! command -v node &> /dev/null; then
  echo "⚠️  Node.js not found - cannot validate hooks"
  exit 0
fi

# Check hooks directory exists
if [ ! -d "$HOOKS_DIR" ]; then
  echo "❌ Hooks directory not found: $HOOKS_DIR"
  exit 1
fi

# Count hooks
HOOK_COUNT=$(find "$HOOKS_DIR" -maxdepth 1 -name "*.js" -type f 2>/dev/null | wc -l | tr -d ' ')
if [ "$HOOK_COUNT" -eq 0 ]; then
  echo "⚠️  No hooks found in $HOOKS_DIR"
  exit 0
fi

echo "Validating $HOOK_COUNT hooks..."
echo ""

VALID=0
INVALID=0
INVALID_FILES=()

for hook in "$HOOKS_DIR"/*.js; do
  if [ -f "$hook" ]; then
    BASENAME=$(basename "$hook")

    # node -c outputs "Syntax OK" to stderr on success, error message on failure
    # It returns 0 on success, non-zero on failure
    if node -c "$hook" &>/dev/null; then
      echo "  ✅ $BASENAME"
      ((VALID++))
    else
      echo "  ❌ $BASENAME"
      INVALID_FILES+=("$BASENAME")
      ((INVALID++))
    fi
  fi
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
printf "Valid:   %2d\n" $VALID
printf "Invalid: %2d\n" $INVALID
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ $INVALID -gt 0 ]; then
  echo ""
  echo "Hooks with errors:"
  for f in "${INVALID_FILES[@]}"; do
    echo "  - $f"
    # Show the actual error
    echo "    Error: $(node -c "$HOOKS_DIR/$f" 2>&1 | head -1)"
  done
  exit 1
else
  echo "✅ All hooks valid"
  exit 0
fi
