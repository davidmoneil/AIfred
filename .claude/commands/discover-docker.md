---
argument-hint: <container-name>
description: Discover Docker container details and create/update docs
skill: infrastructure-ops
allowed-tools:
  - Bash(scripts/discover-docker.sh:*)
  - Bash(docker:*)
  - Read
  - Write
  - Edit
---

# Discover Docker Container

Discover and document the `$ARGUMENTS` Docker container.

**CLI Script**: `scripts/discover-docker.sh` (data gathering)

---

## Parse Arguments

```
If $ARGUMENTS is empty:
  → Ask user for container name or list available containers

If $ARGUMENTS is a container name:
  → Run Full Discovery
```

---

## Section A: Full Discovery (Default)

### Step 1: Gather Data (CLI)

```bash
scripts/discover-docker.sh --full <container-name>
```

This returns JSON with:
- Info: container details, image, ports, volumes, networks, labels, env
- Watchtower: auto-update label status and recommendations
- Compose: compose file location if found
- Logs: recent logs with error/warning counts
- Documentation: whether context file exists

### Step 2: Analyze Data (AI Judgment)

Based on the gathered data:

1. **Evaluate Watchtower status**:
   - Complete: Has both `enable=true` AND `scope=prod|dev`
   - Incomplete: Missing labels
   - If missing/incomplete, suggest fix

2. **Check for issues**:
   - Container unhealthy/restarting
   - High error count in logs
   - Missing expected volumes/networks

3. **Determine documentation needs**:
   - Create new if doesn't exist
   - Update if exists but outdated

### Step 3: Create/Update Documentation

If documentation doesn't exist:
1. Create context file at `.claude/context/systems/docker/<container>.md`
2. Use template from `.claude/context/systems/_template-service.md`
3. Fill in discovered information

### Step 4: Update Registry

Add/update entry in `paths-registry.yaml`.

### Step 5: Suggest Follow-ups

- If compose file found: suggest symlink to `external-sources/docker/`
- If Watchtower incomplete: offer to fix labels
- If issues found: suggest troubleshooting

---

## Section B: List Containers

```bash
scripts/discover-docker.sh --list
```

## Section C: Quick Checks

```bash
scripts/discover-docker.sh --watchtower <container>
scripts/discover-docker.sh --compose <container>
scripts/discover-docker.sh --logs <container> [count]
```

## Related

- Script: @scripts/discover-docker.sh
- Service Template: @.claude/context/systems/_template-service.md
- Pattern: @.claude/context/patterns/capability-layering-pattern.md
