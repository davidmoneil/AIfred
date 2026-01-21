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
| Autonomous | auto-command-watcher.sh exists | Recommended | Medium |
| Autonomous | signal-helper.sh exists | Recommended | Medium |
| Autonomous | launch-jarvis-tmux.sh exists | Recommended | Medium |
| Autonomous | jq available | Recommended | Medium |
| Autonomous | tmux available | Recommended | Medium |

## Execution

Run the readiness report script:

```bash
./scripts/setup-readiness.sh
```

The script automatically detects the Jarvis workspace path. For testing in other locations:

```bash
./scripts/setup-readiness.sh /path/to/jarvis
```

### Exit Codes

| Code | Status |
|------|--------|
| 0 | READY or READY_WITH_WARNINGS |
| 1 | DEGRADED (high-priority failures) |
| 2 | NOT_READY (critical failures) |

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
