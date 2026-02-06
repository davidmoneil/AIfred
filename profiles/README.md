# AIfred Environment Profiles

Composable environment profiles that shape which hooks, permissions, patterns, agents, and setup questions are active.

## How It Works

Profiles are **layers** that stack on top of each other:

```
general.yaml       <- Always active (core hooks, base permissions)
    +
homelab.yaml       <- Docker, NAS, monitoring, service discovery
    +
development.yaml   <- Code projects, CI/CD, parallel-dev, testing
    +
production.yaml    <- Security hardening, deployment gates, audit
```

You choose which layers to activate. Only the differences go in each layer file.

## Quick Start

```bash
# See available profiles
node scripts/profile-loader.js --list

# Set active layers
node scripts/profile-loader.js --layers general,homelab,development

# Preview changes without applying
node scripts/profile-loader.js --dry-run

# Add or remove a layer
node scripts/profile-loader.js --add production
node scripts/profile-loader.js --remove homelab

# Or use the slash command
/profile list
/profile add development
/profile remove homelab
/profile apply
```

## Available Profiles

| Profile | Description | Key Hooks |
|---------|-------------|-----------|
| **general** | Core hooks, security, audit logging | audit-logger, secret-scanner, skill-router |
| **homelab** | Docker services, NAS, monitoring | docker-health-check, compose-validator, port-conflict-detector |
| **development** | Code projects, git workflows | amend-validator, project-detector, orchestration-detector |
| **production** | Security hardening, deployment gates | credential-guard (strict), compose-validator, session-exit-enforcer |

## Common Combinations

| Use Case | Layers |
|----------|--------|
| Personal home lab | `general, homelab` |
| Developer workstation | `general, development` |
| Full home lab + dev | `general, homelab, development` |
| Production server | `general, homelab, production` |

## Merge Behavior

When multiple layers define the same item:

- **Hooks**: Last layer wins for configuration of the same hook name
- **Patterns/Skills/Agents**: Union with deduplication
- **Permissions**: Union. Deny always takes precedence over allow
- **Setup Questions**: Appended in layer order, duplicate IDs skipped
- **Cron Scripts**: Appended in layer order, duplicate scripts skipped

## Creating Custom Profiles

1. Copy `_template.yaml` to `my-profile.yaml`
2. Fill in hooks, patterns, permissions, etc.
3. Add the layer: `node scripts/profile-loader.js --add my-profile`

See `schema.yaml` for the full field reference.

## File Layout

```
profiles/
├── README.md           # This file
├── schema.yaml         # YAML schema reference
├── general.yaml        # Base layer (always active)
├── homelab.yaml        # Home lab additions
├── development.yaml    # Development additions
├── production.yaml     # Production additions
└── _template.yaml      # Template for custom profiles
```

## How Settings Are Generated

The profile loader (`scripts/profile-loader.js`) reads your active layers and generates:

1. **`.claude/settings.json`** - Hook registrations and permissions
2. **`.claude/config/profile-config.json`** - Runtime config for hooks needing profile awareness

Both files are regenerated from profiles. Manual edits to `settings.json` will be overwritten on next profile apply.

## Backward Compatibility

If no `active-profile.yaml` exists, the current `settings.json` works as-is. The profile system is opt-in.
