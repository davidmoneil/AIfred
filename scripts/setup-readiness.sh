#!/bin/bash
# ==============================================================================
# Jarvis Setup Readiness Report
# ==============================================================================
# Run after /setup or anytime to validate configuration
#
# Usage: ./scripts/setup-readiness.sh [JARVIS_PATH]
#
# Arguments:
#   JARVIS_PATH  Optional. Path to Jarvis workspace.
#                Defaults to parent of scripts directory.
#
# Exit codes:
#   0 - READY or READY_WITH_WARNINGS
#   1 - DEGRADED (high-priority failures)
#   2 - NOT_READY (critical failures)
# ==============================================================================

set -e

# Determine Jarvis path
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
JARVIS_PATH="${1:-$(dirname "$SCRIPT_DIR")}"
AIFRED_PATH="/Users/aircannon/Claude/AIfred"

# Counters
CRITICAL_PASS=0
CRITICAL_FAIL=0
HIGH_PASS=0
HIGH_FAIL=0
MEDIUM_PASS=0
MEDIUM_FAIL=0
LOW_PASS=0
LOW_FAIL=0

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║             JARVIS SETUP READINESS REPORT                  ║"
printf "║             Generated: %s                   ║\n" "$(date +"%Y-%m-%d %H:%M")"
echo "╠════════════════════════════════════════════════════════════╣"

# =============================================================================
# ENVIRONMENT CHECKS (Critical)
# =============================================================================

echo "║                                                            ║"
echo "║  [ENVIRONMENT]                                             ║"
echo "║  ─────────────                                             ║"

# E1: Jarvis workspace exists
if [ -d "$JARVIS_PATH" ]; then
  echo "║  ✅ Jarvis workspace exists                               ║"
  ((CRITICAL_PASS++))
else
  echo "║  ❌ Jarvis workspace NOT FOUND                            ║"
  ((CRITICAL_FAIL++))
fi

# E2: Jarvis is git repo
if [ -d "$JARVIS_PATH/.git" ]; then
  echo "║  ✅ Jarvis is git repository                              ║"
  ((CRITICAL_PASS++))
else
  echo "║  ❌ Jarvis is NOT a git repository                        ║"
  ((CRITICAL_FAIL++))
fi

# E3: AIfred baseline separate
if [ "$JARVIS_PATH" != "$AIFRED_PATH" ] && [ -d "$AIFRED_PATH" ]; then
  echo "║  ✅ AIfred baseline properly separated                    ║"
  ((CRITICAL_PASS++))
elif [ "$JARVIS_PATH" = "$AIFRED_PATH" ]; then
  echo "║  ❌ Jarvis path EQUALS AIfred path (critical error)       ║"
  ((CRITICAL_FAIL++))
else
  echo "║  ⚠️  AIfred baseline not found (optional)                 ║"
  ((MEDIUM_PASS++))
fi

# E4: Not in forbidden path
CURRENT_DIR=$(pwd)
IN_FORBIDDEN=false
FORBIDDEN_PATHS=("/" "/etc" "/usr" "/bin" "/sbin" "/var" "/System" "/Library")
for forbidden in "${FORBIDDEN_PATHS[@]}"; do
  if [[ "$CURRENT_DIR" == "$forbidden" || "$CURRENT_DIR" == "$forbidden/"* ]]; then
    if [[ "$CURRENT_DIR" != "/var/folders"* && "$CURRENT_DIR" != "/private/tmp"* && "$CURRENT_DIR" != "/tmp"* ]]; then
      IN_FORBIDDEN=true
      break
    fi
  fi
done

if [ "$IN_FORBIDDEN" = false ]; then
  echo "║  ✅ Working directory is safe                             ║"
  ((CRITICAL_PASS++))
else
  echo "║  ❌ Working directory is FORBIDDEN: $CURRENT_DIR"
  ((CRITICAL_FAIL++))
fi

# =============================================================================
# STRUCTURE CHECKS (High/Medium)
# =============================================================================

echo "║                                                            ║"
echo "║  [STRUCTURE]                                               ║"
echo "║  ───────────                                               ║"

# S1: .claude/ directory
if [ -d "$JARVIS_PATH/.claude" ]; then
  echo "║  ✅ .claude/ directory exists                             ║"
  ((HIGH_PASS++))
else
  echo "║  ❌ .claude/ directory MISSING                            ║"
  ((HIGH_FAIL++))
fi

# S2: hooks/ directory
if [ -d "$JARVIS_PATH/.claude/hooks" ]; then
  HOOK_COUNT=$(find "$JARVIS_PATH/.claude/hooks" -name "*.js" 2>/dev/null | wc -l | tr -d ' ')
  printf "║  ✅ hooks/ directory exists (%2d hooks)                   ║\n" "$HOOK_COUNT"
  ((HIGH_PASS++))
else
  echo "║  ❌ hooks/ directory MISSING                              ║"
  ((HIGH_FAIL++))
fi

# S3: settings.json
if [ -f "$JARVIS_PATH/.claude/settings.json" ]; then
  echo "║  ✅ settings.json exists                                  ║"
  ((HIGH_PASS++))
else
  echo "║  ❌ settings.json MISSING                                 ║"
  ((HIGH_FAIL++))
fi

# S4: config/ directory
if [ -d "$JARVIS_PATH/.claude/config" ]; then
  echo "║  ✅ config/ directory exists                              ║"
  ((MEDIUM_PASS++))
else
  echo "║  ⚠️  config/ directory missing                            ║"
  ((MEDIUM_FAIL++))
fi

# S5: workspace-allowlist.yaml
if [ -f "$JARVIS_PATH/.claude/config/workspace-allowlist.yaml" ]; then
  echo "║  ✅ workspace-allowlist.yaml exists                       ║"
  ((MEDIUM_PASS++))
else
  echo "║  ⚠️  workspace-allowlist.yaml missing                     ║"
  ((MEDIUM_FAIL++))
fi

# S6: context/ directory
if [ -d "$JARVIS_PATH/.claude/context" ]; then
  echo "║  ✅ context/ knowledge base exists                        ║"
  ((MEDIUM_PASS++))
else
  echo "║  ⚠️  context/ knowledge base missing                      ║"
  ((MEDIUM_FAIL++))
fi

# S7: paths-registry.yaml
if [ -f "$JARVIS_PATH/paths-registry.yaml" ]; then
  echo "║  ✅ paths-registry.yaml exists                            ║"
  ((MEDIUM_PASS++))
else
  echo "║  ⚠️  paths-registry.yaml missing                          ║"
  ((MEDIUM_FAIL++))
fi

# =============================================================================
# COMPONENT CHECKS (High)
# =============================================================================

echo "║                                                            ║"
echo "║  [COMPONENTS]                                              ║"
echo "║  ────────────                                              ║"

# C1: Check guardrail hooks exist
GUARDRAILS_PRESENT=0
[ -f "$JARVIS_PATH/.claude/hooks/workspace-guard.js" ] && ((GUARDRAILS_PRESENT++))
[ -f "$JARVIS_PATH/.claude/hooks/dangerous-op-guard.js" ] && ((GUARDRAILS_PRESENT++))
[ -f "$JARVIS_PATH/.claude/hooks/permission-gate.js" ] && ((GUARDRAILS_PRESENT++))

if [ $GUARDRAILS_PRESENT -eq 3 ]; then
  echo "║  ✅ All 3 guardrail hooks present                         ║"
  ((HIGH_PASS++))
elif [ $GUARDRAILS_PRESENT -gt 0 ]; then
  printf "║  ⚠️  Only %d/3 guardrail hooks present                      ║\n" $GUARDRAILS_PRESENT
  ((HIGH_FAIL++))
else
  echo "║  ❌ NO guardrail hooks found                              ║"
  ((HIGH_FAIL++))
fi

# C2: Validate hook syntax (requires node)
if command -v node &> /dev/null; then
  INVALID_HOOKS=0
  VALID_HOOKS=0
  for hook in "$JARVIS_PATH/.claude/hooks"/*.js; do
    if [ -f "$hook" ]; then
      if node -c "$hook" 2>/dev/null | grep -q "Syntax OK"; then
        ((VALID_HOOKS++))
      else
        # Double check - node -c returns 0 on success
        if node -c "$hook" &>/dev/null; then
          ((VALID_HOOKS++))
        else
          ((INVALID_HOOKS++))
        fi
      fi
    fi
  done

  if [ $INVALID_HOOKS -eq 0 ]; then
    echo "║  ✅ All hooks have valid JavaScript syntax               ║"
    ((HIGH_PASS++))
  else
    printf "║  ❌ %d hook(s) have syntax errors                         ║\n" $INVALID_HOOKS
    ((HIGH_FAIL++))
  fi
else
  echo "║  ⚠️  Cannot validate hooks (Node.js not found)            ║"
  ((MEDIUM_FAIL++))
fi

# C3: CLAUDE.md exists
if [ -f "$JARVIS_PATH/CLAUDE.md" ] || [ -f "$JARVIS_PATH/.claude/CLAUDE.md" ]; then
  echo "║  ✅ CLAUDE.md configuration exists                        ║"
  ((MEDIUM_PASS++))
else
  echo "║  ⚠️  CLAUDE.md configuration missing                      ║"
  ((MEDIUM_FAIL++))
fi

# =============================================================================
# TOOL CHECKS (Critical/Recommended)
# =============================================================================

echo "║                                                            ║"
echo "║  [TOOLS]                                                   ║"
echo "║  ────────                                                  ║"

# T1: Git available (Critical)
if command -v git &> /dev/null; then
  GIT_VERSION=$(git --version | awk '{print $3}')
  printf "║  ✅ Git available (%-8s)                           ║\n" "$GIT_VERSION"
  ((CRITICAL_PASS++))
else
  echo "║  ❌ Git NOT AVAILABLE                                     ║"
  ((CRITICAL_FAIL++))
fi

# T2: Docker available (Low - optional)
if command -v docker &> /dev/null; then
  if docker info &> /dev/null; then
    echo "║  ✅ Docker available and running                         ║"
    ((LOW_PASS++))
  else
    echo "║  ⚠️  Docker installed but not running                    ║"
    ((LOW_FAIL++))
  fi
else
  echo "║  ⚠️  Docker not installed (optional)                      ║"
  ((LOW_PASS++))
fi

# T3: Node.js available (Low - optional)
if command -v node &> /dev/null; then
  NODE_VERSION=$(node --version)
  printf "║  ✅ Node.js available (%-10s)                       ║\n" "$NODE_VERSION"
  ((LOW_PASS++))
else
  echo "║  ⚠️  Node.js not installed (optional)                     ║"
  ((LOW_PASS++))
fi

# =============================================================================
# SUMMARY
# =============================================================================

echo "╠════════════════════════════════════════════════════════════╣"
echo "║                                                            ║"
echo "║  READINESS SUMMARY                                         ║"
echo "║  ─────────────────                                         ║"
echo "║                                                            ║"
printf "║  [X] CRITICAL:  %2d passed, %2d failed                      ║\n" $CRITICAL_PASS $CRITICAL_FAIL
printf "║  [!] HIGH:      %2d passed, %2d failed                      ║\n" $HIGH_PASS $HIGH_FAIL
printf "║  [~] MEDIUM:    %2d passed, %2d failed                      ║\n" $MEDIUM_PASS $MEDIUM_FAIL
printf "║  [-] LOW:       %2d passed, %2d failed                      ║\n" $LOW_PASS $LOW_FAIL
echo "║                                                            ║"

TOTAL_PASS=$((CRITICAL_PASS + HIGH_PASS + MEDIUM_PASS + LOW_PASS))
TOTAL_FAIL=$((CRITICAL_FAIL + HIGH_FAIL + MEDIUM_FAIL + LOW_FAIL))
TOTAL=$((TOTAL_PASS + TOTAL_FAIL))

printf "║  Total: %2d/%2d checks passed                              ║\n" $TOTAL_PASS $TOTAL
echo "║                                                            ║"

# Determine overall status
if [ $CRITICAL_FAIL -gt 0 ]; then
  echo "║  ╔═══════════════════════════════════════════════════╗    ║"
  echo "║  ║  STATUS: ❌ NOT READY (Critical failures)        ║    ║"
  echo "║  ╚═══════════════════════════════════════════════════╝    ║"
  READY_STATUS="NOT_READY"
elif [ $HIGH_FAIL -gt 0 ]; then
  echo "║  ╔═══════════════════════════════════════════════════╗    ║"
  echo "║  ║  STATUS: ⚠️  DEGRADED (High-priority failures)    ║    ║"
  echo "║  ╚═══════════════════════════════════════════════════╝    ║"
  READY_STATUS="DEGRADED"
elif [ $MEDIUM_FAIL -gt 0 ]; then
  echo "║  ╔═══════════════════════════════════════════════════╗    ║"
  echo "║  ║  STATUS: ✅ READY (with warnings)                ║    ║"
  echo "║  ╚═══════════════════════════════════════════════════╝    ║"
  READY_STATUS="READY_WITH_WARNINGS"
else
  echo "║  ╔═══════════════════════════════════════════════════╗    ║"
  echo "║  ║  STATUS: ✅ FULLY READY                          ║    ║"
  echo "║  ╚═══════════════════════════════════════════════════╝    ║"
  READY_STATUS="READY"
fi

echo "║                                                            ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Exit code based on status
case $READY_STATUS in
  "READY") exit 0 ;;
  "READY_WITH_WARNINGS") exit 0 ;;
  "DEGRADED") exit 1 ;;
  "NOT_READY") exit 2 ;;
esac
