# Environment Profile Pattern

**Purpose**: Composable environment layers that shape hooks, permissions, patterns, agents, and setup questions.

**Created**: 2026-02-05
**Category**: Architecture

---

## Problem

Different users need different AIfred configurations:
- Home lab users need Docker hooks but not development tools
- Developers need git safety hooks but not infrastructure monitoring
- Production environments need strict security but different hooks than development

Maintaining separate `settings.json` files for each combination doesn't scale.

## Solution

**Layered profiles** that compose left-to-right:

```
general.yaml       <- Always active (core hooks, base permissions)
    +
homelab.yaml       <- Docker, NAS, monitoring
    +
development.yaml   <- Code projects, CI/CD, parallel-dev
```

### Key Design Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Profile location | `profiles/` at project root | User-facing, visible |
| Active state | `.claude/config/active-profile.yaml` (gitignored) | User-specific |
| Hook activation | **Unregister** (not self-skipping) | Avoids process spawn overhead |
| Loader | Node.js (`scripts/profile-loader.js`) | Matches hook ecosystem, no deps |
| Settings generation | Loader generates `settings.json` | Clean, deterministic |
| Backward compat | No profiles = current settings.json works | Zero breaking changes |

### Merge Behavior

- **Hooks**: Union + last-write-wins for same hook name
- **Patterns/Skills/Agents**: Union with deduplication
- **Permissions**: Union (deny always takes precedence)
- **Setup Questions**: Append in layer order, skip duplicate IDs

## Usage

```bash
# Generate settings from profiles
node scripts/profile-loader.js --layers general,homelab,development

# Add/remove layers
node scripts/profile-loader.js --add production
node scripts/profile-loader.js --remove homelab

# Preview without writing
node scripts/profile-loader.js --dry-run

# Via slash command
/profile list
/profile add development
```

## Files

| File | Purpose |
|------|---------|
| `profiles/*.yaml` | Profile layer definitions |
| `profiles/schema.yaml` | YAML schema reference |
| `scripts/profile-loader.js` | Merge + settings generation |
| `.claude/hooks/_profile-check.js` | Runtime profile config utility |
| `.claude/config/active-profile.yaml` | Active layers (gitignored) |
| `.claude/config/profile-config.json` | Runtime config (gitignored) |

## When to Apply

- Setting up a new AIfred installation
- Adding or removing capabilities (e.g., adding Docker support)
- Creating a specialized configuration for a specific use case

## Anti-Patterns

- Don't edit `settings.json` directly (it gets overwritten by profile loader)
- Don't put user-specific paths in profile YAML (use `setup_questions` instead)
- Don't make hooks self-skipping based on profile (use unregistration instead)
