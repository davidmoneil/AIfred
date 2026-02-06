---
description: Manage AIfred environment profile layers
skill: null
standalone: true
allowed-tools:
  - Bash(node scripts/profile-loader.js:*)
  - Bash(node -c:*)
  - Read
---

# /profile - Environment Profile Management

Manage which environment profile layers are active. Profiles control which hooks, permissions, patterns, and agents are registered.

## Usage

```
/profile              Show current active layers
/profile list         Show all available profiles with descriptions
/profile add <layer>  Add a profile layer
/profile remove <x>   Remove a profile layer
/profile apply        Regenerate settings.json from current profile
```

## How To Execute

### `/profile` (no args) or `/profile current`

Run: `node scripts/profile-loader.js --current`

Show the user which layers are active and summarize what each provides.

### `/profile list`

Run: `node scripts/profile-loader.js --list`

Show all available profiles with their descriptions and hook counts.

### `/profile add <layer>`

1. Run: `node scripts/profile-loader.js --add <layer>`
2. This updates `.claude/config/active-profile.yaml` and regenerates `settings.json`
3. Tell the user: "Profile updated. **Restart Claude Code** for changes to take effect."

### `/profile remove <layer>`

1. Run: `node scripts/profile-loader.js --remove <layer>`
2. This updates `.claude/config/active-profile.yaml` and regenerates `settings.json`
3. Tell the user: "Profile updated. **Restart Claude Code** for changes to take effect."
4. Note: The `general` layer cannot be removed.

### `/profile apply`

1. Run: `node scripts/profile-loader.js`
2. This regenerates `settings.json` from the current active profile
3. Tell the user: "Settings regenerated. **Restart Claude Code** for changes to take effect."

### `/profile dry-run`

Run: `node scripts/profile-loader.js --dry-run`

Show what would be generated without writing any files. Useful for previewing changes before applying.

## Notes

- Profile changes require a Claude Code restart to take effect (hooks are loaded at session start)
- The `general` profile is always active and provides core hooks (audit, security, session management)
- Custom profiles can be created in `profiles/` - see `profiles/_template.yaml`
- Profile config is gitignored (`.claude/config/active-profile.yaml`) - it's user-specific
