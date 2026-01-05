# Phase 0A: Environment Preflight

**Purpose**: Validate workspace configuration and environment before setup begins.

**Run BEFORE Phase 0B (Prerequisites).**

---

## Overview

Preflight checks ensure the environment is correctly configured before `/setup` runs.
These checks validate:

1. **Workspace isolation** — Jarvis and AIfred baseline are properly separated
2. **Safe working directory** — Not in forbidden system paths
3. **Required structure** — Essential directories and files exist
4. **Git status** — Clean working tree, correct branch

Unlike prerequisite checks (software versions), preflight checks validate **configuration and boundaries**.

---

## Preflight Check Categories

| Category | Check | Required | Pass Criteria |
|----------|-------|----------|---------------|
| Workspace | Jarvis path exists | **Yes** | Directory exists |
| Workspace | Jarvis is git repo | **Yes** | `.git/` present |
| Workspace | AIfred baseline separate | **Yes** | Different paths |
| Workspace | Not in AIfred baseline | **Yes** | cwd != AIfred path |
| Safety | Not in forbidden path | **Yes** | cwd not in `/`, `/etc`, etc. |
| Safety | Not in other user's home | **Yes** | cwd under current user |
| Structure | `.claude/` exists | Recommended | Directory present |
| Structure | `hooks/` exists | Recommended | Directory present |
| Structure | `settings.json` exists | Recommended | File present |
| Git | Working tree clean | Recommended | No uncommitted changes |
| Git | On correct branch | Recommended | `Project_Aion` or `main` |

---

## Preflight Execution Script

Run these checks at the start of `/setup`:

```bash
#!/bin/bash
# Jarvis Environment Preflight Checks

PASS_COUNT=0
WARN_COUNT=0
FAIL_COUNT=0

echo "╔══════════════════════════════════════════════════╗"
echo "║         Jarvis Environment Preflight             ║"
echo "╠══════════════════════════════════════════════════╣"

# -----------------------------------------------------------------------------
# REQUIRED CHECKS
# -----------------------------------------------------------------------------

# Check 1: Jarvis workspace exists
JARVIS_PATH="/Users/aircannon/Claude/Jarvis"
if [ -d "$JARVIS_PATH" ]; then
  echo "║ ✅ PASS: Jarvis workspace exists                 ║"
  ((PASS_COUNT++))
else
  echo "║ ❌ FAIL: Jarvis workspace not found              ║"
  echo "║         Expected: $JARVIS_PATH"
  ((FAIL_COUNT++))
fi

# Check 2: Jarvis is a git repository
if [ -d "$JARVIS_PATH/.git" ]; then
  echo "║ ✅ PASS: Jarvis is a git repository              ║"
  ((PASS_COUNT++))
else
  echo "║ ❌ FAIL: Jarvis is not a git repository          ║"
  ((FAIL_COUNT++))
fi

# Check 3: AIfred baseline is separate
AIFRED_PATH="/Users/aircannon/Claude/AIfred"
if [ "$JARVIS_PATH" != "$AIFRED_PATH" ]; then
  if [ -d "$AIFRED_PATH" ]; then
    echo "║ ✅ PASS: AIfred baseline properly separated      ║"
    ((PASS_COUNT++))
  else
    echo "║ ⚠️  WARN: AIfred baseline not found (optional)   ║"
    ((WARN_COUNT++))
  fi
else
  echo "║ ❌ FAIL: Jarvis path equals AIfred path!         ║"
  ((FAIL_COUNT++))
fi

# Check 4: Not currently in AIfred baseline
CURRENT_DIR=$(pwd)
if [[ "$CURRENT_DIR" == "$AIFRED_PATH"* ]]; then
  echo "║ ❌ FAIL: Currently in AIfred baseline!           ║"
  echo "║         cd to Jarvis workspace first             ║"
  ((FAIL_COUNT++))
else
  echo "║ ✅ PASS: Not in AIfred baseline                  ║"
  ((PASS_COUNT++))
fi

# Check 5: Not in forbidden system path
FORBIDDEN_PATHS=("/" "/etc" "/usr" "/bin" "/sbin" "/var" "/System" "/Library")
IN_FORBIDDEN=false
for forbidden in "${FORBIDDEN_PATHS[@]}"; do
  if [[ "$CURRENT_DIR" == "$forbidden" || "$CURRENT_DIR" == "$forbidden/"* ]]; then
    # Exception: /var/folders is ok (temp files)
    if [[ "$CURRENT_DIR" != "/var/folders"* ]]; then
      IN_FORBIDDEN=true
      break
    fi
  fi
done

if [ "$IN_FORBIDDEN" = true ]; then
  echo "║ ❌ FAIL: In forbidden system path                ║"
  echo "║         Current: $CURRENT_DIR"
  ((FAIL_COUNT++))
else
  echo "║ ✅ PASS: Not in forbidden system path            ║"
  ((PASS_COUNT++))
fi

# Check 6: In current user's directory
EXPECTED_USER_PATH="/Users/aircannon"
if [[ "$CURRENT_DIR" == "$EXPECTED_USER_PATH"* || "$CURRENT_DIR" == "/tmp"* || "$CURRENT_DIR" == "/var/folders"* ]]; then
  echo "║ ✅ PASS: In valid user directory                 ║"
  ((PASS_COUNT++))
else
  echo "║ ❌ FAIL: Not in current user's directory         ║"
  echo "║         Current: $CURRENT_DIR"
  ((FAIL_COUNT++))
fi

echo "╠══════════════════════════════════════════════════╣"

# -----------------------------------------------------------------------------
# RECOMMENDED CHECKS
# -----------------------------------------------------------------------------

# Check 7: .claude/ directory exists
if [ -d "$JARVIS_PATH/.claude" ]; then
  echo "║ ✅ PASS: .claude/ directory exists               ║"
  ((PASS_COUNT++))
else
  echo "║ ⚠️  WARN: .claude/ directory missing             ║"
  ((WARN_COUNT++))
fi

# Check 8: hooks/ directory exists
if [ -d "$JARVIS_PATH/.claude/hooks" ]; then
  echo "║ ✅ PASS: hooks/ directory exists                 ║"
  ((PASS_COUNT++))
else
  echo "║ ⚠️  WARN: hooks/ directory missing               ║"
  ((WARN_COUNT++))
fi

# Check 9: settings.json exists
if [ -f "$JARVIS_PATH/.claude/settings.json" ]; then
  echo "║ ✅ PASS: settings.json exists                    ║"
  ((PASS_COUNT++))
else
  echo "║ ⚠️  WARN: settings.json missing                  ║"
  ((WARN_COUNT++))
fi

# Check 10: workspace-allowlist.yaml exists
if [ -f "$JARVIS_PATH/.claude/config/workspace-allowlist.yaml" ]; then
  echo "║ ✅ PASS: workspace-allowlist.yaml exists         ║"
  ((PASS_COUNT++))
else
  echo "║ ⚠️  WARN: workspace-allowlist.yaml missing       ║"
  ((WARN_COUNT++))
fi

# Check 11: Git working tree clean
cd "$JARVIS_PATH"
if git diff --quiet 2>/dev/null && git diff --cached --quiet 2>/dev/null; then
  echo "║ ✅ PASS: Git working tree clean                  ║"
  ((PASS_COUNT++))
else
  echo "║ ⚠️  WARN: Uncommitted changes present            ║"
  ((WARN_COUNT++))
fi

# Check 12: On expected branch
CURRENT_BRANCH=$(git branch --show-current 2>/dev/null)
if [[ "$CURRENT_BRANCH" == "Project_Aion" || "$CURRENT_BRANCH" == "main" ]]; then
  echo "║ ✅ PASS: On expected branch ($CURRENT_BRANCH)"
  ((PASS_COUNT++))
else
  echo "║ ⚠️  WARN: On unexpected branch ($CURRENT_BRANCH)"
  ((WARN_COUNT++))
fi

echo "╠══════════════════════════════════════════════════╣"

# -----------------------------------------------------------------------------
# SUMMARY
# -----------------------------------------------------------------------------

echo "║                                                  ║"
echo "║  SUMMARY                                         ║"
echo "║  ────────                                        ║"
printf "║  ✅ Passed:  %2d                                  ║\n" $PASS_COUNT
printf "║  ⚠️  Warnings: %2d                                  ║\n" $WARN_COUNT
printf "║  ❌ Failed:  %2d                                  ║\n" $FAIL_COUNT
echo "║                                                  ║"

if [ $FAIL_COUNT -eq 0 ]; then
  echo "║  Status: ✅ PREFLIGHT PASSED                     ║"
  echo "║  → Proceed to Phase 0B (Prerequisites)          ║"
else
  echo "║  Status: ❌ PREFLIGHT FAILED                     ║"
  echo "║  → Fix failures before proceeding               ║"
fi

echo "╚══════════════════════════════════════════════════╝"

# Exit code
if [ $FAIL_COUNT -gt 0 ]; then
  exit 1
else
  exit 0
fi
```

---

## Check Details

### Workspace Isolation Check

**Why it matters**: Jarvis derives from AIfred but must remain separate. The AIfred baseline at `/Users/aircannon/Claude/AIfred` is **read-only** — it's the upstream reference. All development happens in Jarvis.

**Failure modes**:
- Jarvis path doesn't exist → Setup can't proceed
- Jarvis == AIfred → Configuration error, will cause conflicts
- Currently in AIfred → Will accidentally modify baseline

### Forbidden Path Check

**Why it matters**: Operations in system directories can brick the machine. Even read operations might leak sensitive data.

**Forbidden paths**:
| Path | Reason |
|------|--------|
| `/` | Root filesystem |
| `/etc` | System configuration |
| `/usr` | System binaries/libraries |
| `/bin`, `/sbin` | Essential binaries |
| `/var` | System data (except `/var/folders`) |
| `/System` | macOS system (SIP protected) |
| `/Library` | System-wide libraries |
| `~/.ssh` | SSH keys |
| `~/.gnupg` | GPG keys |

### Structure Checks

**Why it matters**: Missing directories cause runtime errors. Better to detect early.

**Expected structure**:
```
Jarvis/
├── .claude/
│   ├── config/
│   │   └── workspace-allowlist.yaml
│   ├── hooks/
│   │   ├── workspace-guard.js
│   │   ├── dangerous-op-guard.js
│   │   └── ...
│   ├── settings.json
│   └── ...
└── ...
```

---

## Handling Failures

### Required Check Failed

If any required check fails, `/setup` should **not proceed**:

```
❌ PREFLIGHT FAILED

Fix the following before running /setup:

1. Workspace not found
   → Clone Jarvis to /Users/aircannon/Claude/Jarvis

2. In AIfred baseline
   → cd /Users/aircannon/Claude/Jarvis

3. In forbidden path
   → Navigate to your workspace directory
```

### Recommended Check Failed (Warning)

Warnings don't block setup but should be noted:

```
⚠️ PREFLIGHT PASSED WITH WARNINGS

Consider fixing:

1. Uncommitted changes present
   → Commit or stash changes before setup

2. workspace-allowlist.yaml missing
   → Will be created during setup
```

---

## Integration with /setup

The `/setup` command should call preflight checks first:

```markdown
## Setup Flow

1. **Phase 0A: Preflight** ← NEW
   - Validate workspace configuration
   - Check environment boundaries
   - If FAIL → Stop with guidance

2. **Phase 0B: Prerequisites**
   - Check software versions (Git, Docker, Node)
   - Install missing dependencies

3. **Phases 1-7**: Main setup...
```

---

## Related Files

- **Allowlist config**: `.claude/config/workspace-allowlist.yaml`
- **Prerequisites phase**: `.claude/archive/setup-phases/00-prerequisites.md`
- **Workspace guard hook**: `.claude/hooks/workspace-guard.js`
- **Session start checklist**: `.claude/context/patterns/session-start-checklist.md`

---

*Phase 0A of 8 — Environment Preflight*
*Jarvis v1.2.2 — Project Aion Master Archon*
