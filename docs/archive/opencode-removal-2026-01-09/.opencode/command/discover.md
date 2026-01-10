---
description: Discover and document Docker services
agent: build
---

# Discover Command

Discover and document infrastructure components.

## Usage

`/discover $ARGUMENTS`

Arguments:
- `docker` - Discover all Docker containers
- `<service-name>` - Discover specific service
- `all` - Full infrastructure discovery

## Docker Discovery

Run container discovery:

```bash
docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"
```

For each running container, gather:
1. Container name and image
2. Port mappings
3. Volume mounts
4. Network connections
5. Health status

## Documentation Template

For each discovered service, create a context file:

```markdown
# Service: [Name]

## Overview
- **Container**: [name]
- **Image**: [image:tag]
- **Status**: [running/stopped]
- **Purpose**: [what it does]

## Networking
- **Ports**: [host:container mappings]
- **Networks**: [network names]
- **URL**: [access URL if applicable]

## Storage
- **Volumes**: [volume mappings]
- **Data location**: [host paths]

## Configuration
- **Compose file**: [path if known]
- **Config files**: [paths]

## Maintenance
- **Logs**: `docker logs [container]`
- **Restart**: `docker restart [container]`
- **Update**: [update procedure]

## Notes
[Any special considerations]
```

## Output

After discovery:

1. List all discovered services
2. Note any undocumented services
3. Suggest context files to create
4. Offer to update paths-registry.yaml
