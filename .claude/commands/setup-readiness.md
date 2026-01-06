---
description: Generate setup readiness report (post-setup validation)
allowed-tools: Bash(*), Read, Glob
---

# Setup Readiness Report

Generate a comprehensive readiness report validating that Jarvis setup is complete and operational.

## Purpose

This command produces a **deterministic pass/fail readiness report** that validates:

1. **Environment** — Workspace boundaries, baseline separation
2. **Structure** — Required directories, files, and configurations
3. **Components** — Hooks, settings, configurations operational
4. **Tools** — Git, Docker, and other dependencies available

## When to Run

- After completing `/setup` to confirm success
- After adding new tools/MCPs to validate no regression
- At session start (lightweight version) to catch drift
- Anytime you suspect setup may have regressed

## Readiness Check Categories

| Category | Check | Required | Weight |
|----------|-------|----------|--------|
| Environment | Jarvis workspace exists | Yes | Critical |
| Environment | Jarvis is git repo | Yes | Critical |
| Environment | AIfred baseline separate | Yes | Critical |
| Environment | Working directory safe | Yes | Critical |
| Structure | `.claude/` directory | Yes | High |
| Structure | `hooks/` directory | Yes | High |
| Structure | `settings.json` | Yes | High |
| Structure | `config/` directory | Yes | Medium |
| Structure | `workspace-allowlist.yaml` | Yes | Medium |
| Components | Hooks are valid JS | Yes | High |
| Components | Guardrail hooks present | Yes | High |
| Components | paths-registry.yaml valid | Recommended | Medium |
| Tools | Git available | Yes | Critical |
| Tools | Docker available | Recommended | Low |
| Tools | Node.js available | Recommended | Low |

## Execution

Run these validation checks and generate a structured report:

```bash
#!/bin/bash
# Jarvis Setup Readiness Report
# Run after /setup or anytime to validate configuration

set -e

JARVIS_PATH="/Users/aircannon/Claude/Jarvis"
AIFRED_PATH="/Users/aircannon/Claude/AIfred"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

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
echo "║             Generated: $(date +"%Y-%m-%d %H:%M")                   ║"
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
  ((MEDIUM_PASS++))  # Not critical if baseline doesn't exist
fi

# E4: Not in forbidden path
CURRENT_DIR=$(pwd)
IN_FORBIDDEN=false
FORBIDDEN_PATHS=("/" "/etc" "/usr" "/bin" "/sbin" "/var" "/System" "/Library")
for forbidden in "${FORBIDDEN_PATHS[@]}"; do
  if [[ "$CURRENT_DIR" == "$forbidden" || "$CURRENT_DIR" == "$forbidden/"* ]]; then
    if [[ "$CURRENT_DIR" != "/var/folders"* ]]; then
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
  echo "║  ✅ hooks/ directory exists ($HOOK_COUNT hooks)                    ║"
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
if [ -f "$JARVIS_PATH/.claude/hooks/workspace-guard.js" ]; then
  ((GUARDRAILS_PRESENT++))
fi
if [ -f "$JARVIS_PATH/.claude/hooks/dangerous-op-guard.js" ]; then
  ((GUARDRAILS_PRESENT++))
fi
if [ -f "$JARVIS_PATH/.claude/hooks/permission-gate.js" ]; then
  ((GUARDRAILS_PRESENT++))
fi

if [ $GUARDRAILS_PRESENT -eq 3 ]; then
  echo "║  ✅ All 3 guardrail hooks present                         ║"
  ((HIGH_PASS++))
elif [ $GUARDRAILS_PRESENT -gt 0 ]; then
  echo "║  ⚠️  Only $GUARDRAILS_PRESENT/3 guardrail hooks present                      ║"
  ((HIGH_FAIL++))
else
  echo "║  ❌ NO guardrail hooks found                              ║"
  ((HIGH_FAIL++))
fi

# C2: Validate hook syntax (requires node)
if command -v node &> /dev/null; then
  INVALID_HOOKS=0
  for hook in "$JARVIS_PATH/.claude/hooks"/*.js; do
    if [ -f "$hook" ]; then
      if ! node -c "$hook" 2>/dev/null; then
        ((INVALID_HOOKS++))
      fi
    fi
  done

  if [ $INVALID_HOOKS -eq 0 ]; then
    echo "║  ✅ All hooks have valid JavaScript syntax               ║"
    ((HIGH_PASS++))
  else
    echo "║  ❌ $INVALID_HOOKS hook(s) have syntax errors                      ║"
    ((HIGH_FAIL++))
  fi
else
  echo "║  ⚠️  Cannot validate hooks (Node.js not found)            ║"
  ((MEDIUM_FAIL++))
fi

# C3: CLAUDE.md exists
if [ -f "$JARVIS_PATH/.claude/CLAUDE.md" ]; then
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
  echo "║  ✅ Git available ($GIT_VERSION)                           ║"
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
  ((LOW_PASS++))  # Not required
fi

# T3: Node.js available (Low - optional)
if command -v node &> /dev/null; then
  NODE_VERSION=$(node --version)
  echo "║  ✅ Node.js available ($NODE_VERSION)                         ║"
  ((LOW_PASS++))
else
  echo "║  ⚠️  Node.js not installed (optional)                     ║"
  ((LOW_PASS++))  # Not required
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

echo "║  Total: $TOTAL_PASS/$TOTAL checks passed                              ║"
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
```

## Interpreting Results

### Status Levels

| Status | Meaning | Action |
|--------|---------|--------|
| **FULLY READY** | All checks passed | Setup complete, proceed normally |
| **READY (with warnings)** | No critical/high failures | Operational, consider fixing warnings |
| **DEGRADED** | High-priority failures | May work but missing important components |
| **NOT READY** | Critical failures | Setup incomplete, cannot operate safely |

### Severity Ratings

- **[X] CRITICAL**: Blocks operation entirely
- **[!] HIGH**: Important functionality affected
- **[~] MEDIUM**: Nice-to-have features missing
- **[-] LOW**: Optional components

## Integration

### After /setup

The `07-finalization.md` phase should call this command:

```markdown
### 8. Verify Readiness

Run the readiness report to confirm setup success:

/setup-readiness

Expected: READY or READY_WITH_WARNINGS
```

### Session Start (Tier 1 Quick Check)

A lightweight version for session start (checks only critical items):

```bash
# Quick readiness check (< 2 seconds)
[ -d "$JARVIS_PATH" ] && [ -d "$JARVIS_PATH/.git" ] && \
[ -f "$JARVIS_PATH/.claude/settings.json" ] && \
echo "Setup: ✓ Valid" || echo "Setup: ⚠ Run /setup-readiness"
```

---

## Related

- **Preflight checks**: `.claude/archive/setup-phases/00-preflight.md` (pre-setup)
- **Setup command**: `.claude/commands/setup.md`
- **Session checklist**: `.claude/context/patterns/session-start-checklist.md`
- **Validation pattern**: `.claude/context/patterns/setup-validation.md`

---

*Jarvis Setup Readiness Report — PR-4c*
*Validates post-setup configuration state*
