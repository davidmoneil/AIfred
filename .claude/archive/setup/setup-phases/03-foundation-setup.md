# Phase 3: Foundation Setup

**Purpose**: Create the core structure based on discovery and interview results.

---

## Tasks

### 1. Create paths-registry.yaml

Based on Phase 1 discovery, create the paths registry:

```yaml
# AIfred Paths Registry
# Source of truth for all external paths
# Created: [date]

version: "1.0"
last_updated: "[date]"

# This Host
hosts:
  local:
    hostname: "[from discovery]"
    ip: "[from discovery]"
    role: "Primary AIfred host"
    os: "[from discovery]"
    status: "active"

# Docker (if discovered)
docker:
  socket: "/var/run/docker.sock"
  compose_files: []
  # Populated during container discovery

# Network Mounts (if discovered)
mounts:
  # Add discovered mounts here

# Discovered later via /discover
# docker:
#   containers:
#     service_name:
#       compose: "/path/to/compose.yml"
#       data: "/path/to/data"
```

### 2. Initialize External Sources

Create symlink structure:

```bash
mkdir -p external-sources/{docker,logs,configs}
```

Add README:

```markdown
# External Sources

Symlinks to external data. Never store actual data here.

## Structure

- `docker/` - Links to docker-compose files
- `logs/` - Links to important log directories
- `configs/` - Links to external configuration files

## Adding Links

Use the /link-external command or:
\`\`\`bash
ln -s /actual/path external-sources/category/link-name
\`\`\`

Then update paths-registry.yaml.
```

### 3. Document Discovered Systems

If Docker containers were discovered in Phase 1:

For each container:
1. Create `.claude/context/systems/[container-name].md` using template
2. Add to paths-registry.yaml
3. Note any symlinks to create

### 4. Configure Knowledge Base

Create initial documentation:

**knowledge/docs/getting-started.md**:
```markdown
# Getting Started with AIfred

Your AIfred environment was configured on [date].

## Your Configuration
- Automation Level: [from interview]
- Focus Areas: [from interview]
- Memory: [enabled/disabled]

## Key Commands
- `/end-session` - End work session cleanly
- `/discover <service>` - Document a new service
- `/health-check` - Verify system status

## Next Steps
1. [Based on focus areas]
2. [Based on discovered infrastructure]
```

### 5. Update Session State

Update `.claude/context/session-state.md`:

```markdown
## Current Work Status

**Status**: 🟡 Setup in Progress

**Current Task**: AIfred Setup - Phase 3 complete

**Next Step**: Continue to Phase 4 (MCP Integration)
```

---

## Validation

Before proceeding:

- [ ] paths-registry.yaml created with discovery results
- [ ] external-sources/ structure created
- [ ] Discovered systems documented (if any)
- [ ] getting-started.md created
- [ ] Session state updated

---

*Phase 3 of 7 - Foundation Setup*
