# AIProjects → AIFred Sync Pattern

**Status**: Active
**Created**: 2026-01-21
**Purpose**: Standardize the process of syncing innovations from AIProjects to AIFred

## Overview

AIProjects is the living, personalized AI infrastructure hub. AIFred is the **distributable starter kit** based on AIProjects. This pattern documents when, what, and how to sync between them.

## When to Sync

### Triggers
- **Major feature complete**: New pattern, skill, or hook system fully implemented
- **Capability milestone**: e.g., CLI extraction reaches 50%+
- **Monthly cadence**: At minimum, review for sync opportunities monthly
- **Before release**: Any planned AIFred version bump

### Maturity Criteria
Only sync features that meet these criteria:
1. **Tested** - Used in production for at least 1 week
2. **Documented** - Has README, _index entry, or pattern doc
3. **Generalizable** - Not tied to specific infrastructure

## What to Sync

### Always Sync (Universal)
| Category | Examples |
|----------|----------|
| **Patterns** | capability-layering, code-before-prompts, PARC |
| **Security Hooks** | branch-protection, credential-guard, secret-scanner |
| **Lifecycle Hooks** | session-start, session-stop, pre-compact |
| **Core Skills** | session-management, parallel-dev, upgrade |
| **Universal Scripts** | checkpoint.sh, sync-git.sh, audit-log-query.sh |

### Sync with Generalization
| Category | Generalization Required |
|----------|------------------------|
| **Autonomous execution** | Replace paths with `<project_root>` |
| **Service monitoring** | Make service lists configurable |
| **Health checks** | Use environment variables for thresholds |
| **TELOS** | Keep framework, remove personal goals |

### Never Sync (Infrastructure-Specific)
| Category | Examples |
|----------|----------|
| **Server configs** | MediaServer paths, IP addresses |
| **Personal goals** | TELOS G-T1 through G-T4 |
| **Service registries** | detected-issues.yaml, service-registry.yaml |
| **Project-specific** | outlook-intel, 18thLevelFun campaign data |

## How to Sync

### Step 1: Inventory
```bash
# Find what's new since last sync
git log --oneline --since="<last_sync_date>" | head -30

# Compare directories
diff <(ls AIProjects/.claude/patterns/) <(ls AIFred/.claude/context/patterns/)
diff <(ls AIProjects/.claude/hooks/) <(ls AIFred/.claude/hooks/)
```

### Step 2: Copy Files
```bash
# Patterns
cp ~/.../AIProjects/.claude/context/patterns/<pattern>.md ~/.../AIfred/.claude/context/patterns/

# Hooks
cp ~/.../AIProjects/.claude/hooks/<hook>.js ~/.../AIfred/.claude/hooks/

# Scripts
cp ~/.../AIProjects/Scripts/<script>.sh ~/.../AIfred/scripts/
chmod +x ~/.../AIfred/scripts/<script>.sh
```

### Step 3: Generalize Paths
```bash
# Replace hardcoded paths
sed -i 's|/home/davidmoneil/AIProjects|${AIFRED_ROOT:-$HOME/AIfred}|g' file
sed -i 's|/home/davidmoneil/Code|${PROJECTS_ROOT:-$HOME/Code}|g' file
sed -i 's|192.168.1.[0-9]+|<host_ip>|g' file
```

### Step 4: Update Indexes
- `patterns/_index.md`
- `hooks/README.md`
- `skills/_index.md`
- `settings.json` (hook registration)

### Step 5: Update Documentation
- `CLAUDE.md` - Quick Links, version
- `README.md` - What's New section
- Version bump (major for significant changes)

### Step 6: Commit and Push
```bash
git add .
git commit -m "Sync from AIProjects: <summary>"
git push origin main
```

## Generalization Checklist

For each file synced:

- [ ] Replace `/home/davidmoneil/AIProjects` → `<project_root>` or `${AIFRED_ROOT}`
- [ ] Replace `/home/davidmoneil/Code` → `<projects_root>` or `${PROJECTS_ROOT}`
- [ ] Replace specific IP addresses → `<host_ip>` or environment variable
- [ ] Replace server names (MediaServer, AIServer) → generic or configurable
- [ ] Remove personal goals/metrics (keep framework)
- [ ] Make service lists configurable (environment variable or config file)
- [ ] Verify paths-registry.yaml.template has required sections

## Sync Frequency

| Type | Frequency | Scope |
|------|-----------|-------|
| **Major Sync** | Quarterly | Full inventory, all phases |
| **Feature Sync** | As completed | Single feature/pattern |
| **Patch Sync** | As needed | Bug fixes, small improvements |

## Version Coordination

| AIProjects Change | AIFred Version |
|-------------------|----------------|
| New pattern | Patch (x.x.+1) |
| New skill with tools/ | Minor (x.+1.0) |
| Multiple skills/major hooks | Major (+1.0.0) |

## Examples

### 2026-01-21 Major Sync (v1.4 → v2.0)

**Trigger**: Capability layering reached 50% CLI coverage

**Synced**:
- 11 patterns (capability-layering, code-before-prompts, etc.)
- 9 hooks (pattern detection, security, workflow)
- 3 skills (upgrade, structured-planning, _template)
- 12 scripts (universal CLI layer)
- 18 commands
- TELOS framework (generalized)

**Total**: 93 files, 17,282 insertions

---

## Plugin Extraction Tier

When a feature from AIProjects/AIfred is **universal enough for standalone distribution**, extract it as a plugin:

```
AIProjects → AIfred → aifred-<plugin-name> → Marketplace
(innovate)   (generalize)  (universal only)     (distribute)
```

### Extraction Criteria

1. **Universal problem** - Every Claude Code user could benefit
2. **Self-contained** - No dependencies on AIProjects/AIfred infrastructure
3. **Works immediately** - Sensible defaults, zero config to start
4. **Differentiated** - Nothing like it in the marketplace

### Extraction Checklist

- [ ] Create `~/Code/aifred-<plugin-name>/` with `.claude-plugin/plugin.json`
- [ ] Copy source, apply plugin adaptations (PLUGIN_ROOT, two-tier config, etc.)
- [ ] Strip project-specific rules, keep only universal ones
- [ ] Add README, LICENSE (MIT), CHANGELOG
- [ ] Register in `paths-registry.yaml`
- [ ] Create context file at `.claude/context/projects/`

### Extracted Plugins

| Plugin | Source | Status |
|--------|--------|--------|
| `aifred-document-guard` | `document-guard.js` v2.1.0 | Active (2026-02-10) |

## Related

- @.claude/planning/specs/2026-01-21-aiprojects-aifred-sync-plan.md
- @.claude/orchestration/2026-01-21-aiprojects-aifred-sync.yaml
