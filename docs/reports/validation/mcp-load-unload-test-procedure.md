# MCP Load/Unload Test Procedure

**Created**: 2026-01-07
**Purpose**: Document MCP enable/disable mechanics for PR-8.4 validation harness
**Status**: COMPLETE — Key discovery made
**Updated**: 2026-01-07 (disabledMcpServers discovery)

---

## Key Discovery: disabledMcpServers Array

**Location**: `~/.claude.json` → `projects.<project-path>.disabledMcpServers`

```json
{
  "projects": {
    "/Users/aircannon/Claude/Jarvis": {
      "mcpServers": {
        "memory": { "type": "stdio", "command": "npx", ... },
        "fetch": { "type": "stdio", "command": "uvx", ... },
        "git": { "type": "stdio", "command": "uvx", ... },
        "filesystem": { "type": "stdio", "command": "npx", ... }
      },
      "disabledMcpServers": [
        "context7",
        "github",
        "plugin:playwright:playwright",
        "plugin:gitlab:gitlab",
        "sequential-thinking",
        "git"
      ]
    }
  }
}
```

### Key Insights

| Aspect | Finding |
|--------|---------|
| **Disable vs Remove** | Disable keeps MCP in settings, just skips loading |
| **Storage** | Array in `~/.claude.json` under project path |
| **Effect** | Takes effect on next session start (after exit or /clear) |
| **Plugin MCPs** | Use format `plugin:<plugin-name>:<server-name>` |
| **Modification** | Can use `jq` to programmatically add/remove entries |

### Disable vs Remove Comparison

| Action | Config Change | Runtime Effect | Re-enable |
|--------|---------------|----------------|-----------|
| **Disable** (add to array) | Adds to `disabledMcpServers` | MCP skipped on next start | Remove from array |
| **Remove** (`claude mcp remove`) | Deletes from `mcpServers` | MCP uninstalled | Must re-add with full args |

**Recommendation**: Use disable/enable for context management, not remove/add.

---

## Programmatic MCP Control

### Disable MCP

```bash
# Add to disabledMcpServers array
jq --arg path "/Users/aircannon/Claude/Jarvis" --arg server "git" '
  .projects[$path].disabledMcpServers |= (. + [$server] | unique)
' ~/.claude.json > ~/.claude.json.tmp && mv ~/.claude.json.tmp ~/.claude.json
```

### Enable MCP

```bash
# Remove from disabledMcpServers array
jq --arg path "/Users/aircannon/Claude/Jarvis" --arg server "git" '
  .projects[$path].disabledMcpServers |= (. - [$server])
' ~/.claude.json > ~/.claude.json.tmp && mv ~/.claude.json.tmp ~/.claude.json
```

### Check Current Status

```bash
# List disabled MCPs
jq '.projects["/Users/aircannon/Claude/Jarvis"].disabledMcpServers' ~/.claude.json

# List all registered MCPs
jq '.projects["/Users/aircannon/Claude/Jarvis"].mcpServers | keys' ~/.claude.json
```

---

## MCP Inventory

### Currently Registered (mcpServers)

| MCP | Command | Package |
|-----|---------|---------|
| memory | npx | @modelcontextprotocol/server-memory |
| fetch | uvx | mcp-server-fetch |
| git | uvx | mcp-server-git |
| filesystem | npx | @modelcontextprotocol/server-filesystem |

### Currently Disabled (disabledMcpServers)

| MCP | Reason |
|-----|--------|
| context7 | Not needed for current work |
| github | Not needed for current work |
| plugin:playwright:playwright | Not needed for current work |
| plugin:gitlab:gitlab | Connection failing |
| sequential-thinking | Not needed for current work |
| git | Context budget optimization |

### Tier Classification

| Tier | MCPs | Disable Policy |
|------|------|----------------|
| **1: Core** | memory, filesystem, fetch | Never disable |
| **2: Task-Scoped** | github, git, context7, sequential-thinking | Disable when not needed |
| **3: Plugin-Managed** | plugin:playwright:*, plugin:gitlab:* | Managed by plugin system |

---

## Historical Test Results (Original Investigation)

### Finding 1: `claude mcp remove` is Runtime-Blind

Original tests confirmed that `claude mcp remove`:
- Updates config file only
- Tools remain functional in current session
- MCP processes continue running
- **Session restart required** for changes to take effect

### Finding 2: MCP Processes Persist

```bash
# MCP processes spawned at session start
ps aux | grep -E "(mcp-server|@modelcontextprotocol)"
# Shows: mcp-server-fetch, mcp-server-git, etc.
# These persist until session ends regardless of config changes
```

### Finding 3: Re-addition Complexity

`claude mcp remove` completely removes the MCP, requiring full re-addition with args:

```bash
# Must remember all args for re-addition
claude mcp add context7 -s local -- npx -y @upstash/context7-mcp --api-key <key>
claude mcp add filesystem -s local -- npx -y @modelcontextprotocol/server-filesystem /path1 /path2
```

**This is why disabledMcpServers is superior** — no args lost, just toggle state.

---

## Workflow Validation Tests

> **VALIDATED 2026-01-07**: Tests confirm `/clear` respects `disabledMcpServers`. No `exit` + `claude` required.

### Test A: Verify Disable Takes Effect

```bash
# 1. Check current state
/mcp  # or claude mcp list
# Note which MCPs are connected

# 2. Disable an MCP
.claude/scripts/disable-mcps.sh fetch

# 3. Run /clear
/clear

# 4. Verify
/mcp
# Expected: fetch shows as "disabled"
```

**Result**: PASSED (2026-01-07) — fetch disabled after /clear

### Test B: Verify Enable Restores MCP

```bash
# 1. Enable the MCP
.claude/scripts/enable-mcps.sh fetch

# 2. Run /clear
/clear

# 3. Verify
/mcp
# Expected: fetch shows as "connected"
```

### Test C: Context Budget Impact

```bash
# Before: Check context usage
/context  # Note MCP tool tokens

# Disable several MCPs
.claude/scripts/disable-mcps.sh git context7 sequential-thinking

# Run /clear
/clear

# After: Check context usage
/context  # MCP tool tokens should be reduced
```

---

## Scripts for PR-8.3.1

### disable-mcps.sh

```bash
#!/bin/bash
# .claude/scripts/disable-mcps.sh
# Usage: disable-mcps.sh <server-name> [server-name...]

PROJECT_PATH="/Users/aircannon/Claude/Jarvis"
CONFIG_FILE="$HOME/.claude.json"

if [ $# -eq 0 ]; then
  echo "Usage: disable-mcps.sh <server-name> [server-name...]"
  exit 1
fi

for SERVER in "$@"; do
  jq --arg path "$PROJECT_PATH" --arg server "$SERVER" '
    .projects[$path].disabledMcpServers |= (. + [$server] | unique)
  ' "$CONFIG_FILE" > "$CONFIG_FILE.tmp" && mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
  echo "Disabled: $SERVER"
done

echo ""
echo "Changes will take effect after /clear"
```

### enable-mcps.sh

```bash
#!/bin/bash
# .claude/scripts/enable-mcps.sh
# Usage: enable-mcps.sh <server-name> [server-name...]

PROJECT_PATH="/Users/aircannon/Claude/Jarvis"
CONFIG_FILE="$HOME/.claude.json"

if [ $# -eq 0 ]; then
  echo "Usage: enable-mcps.sh <server-name> [server-name...]"
  exit 1
fi

for SERVER in "$@"; do
  jq --arg path "$PROJECT_PATH" --arg server "$SERVER" '
    .projects[$path].disabledMcpServers |= (. - [$server])
  ' "$CONFIG_FILE" > "$CONFIG_FILE.tmp" && mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
  echo "Enabled: $SERVER"
done

echo ""
echo "Changes will take effect after /clear"
```

### list-mcp-status.sh

```bash
#!/bin/bash
# .claude/scripts/list-mcp-status.sh
# Show registered vs disabled MCPs

PROJECT_PATH="/Users/aircannon/Claude/Jarvis"
CONFIG_FILE="$HOME/.claude.json"

echo "=== Registered MCPs ==="
jq -r --arg path "$PROJECT_PATH" '.projects[$path].mcpServers | keys[]' "$CONFIG_FILE" 2>/dev/null

echo ""
echo "=== Disabled MCPs ==="
jq -r --arg path "$PROJECT_PATH" '.projects[$path].disabledMcpServers[]' "$CONFIG_FILE" 2>/dev/null

echo ""
echo "=== Currently Active ==="
echo "(Run 'claude mcp list' in session to see runtime state)"
```

---

## Impact on PR-8.4 Validation Harness

| Requirement | Implementation |
|-------------|----------------|
| Test MCP availability | Use `claude mcp list` after enable/disable |
| Measure token impact | Compare /context before/after |
| Validate disable/enable | Use scripts above |
| Health checks | Integrate with /tooling-health |

---

## Related Documentation

- `.claude/reports/pr-8.3.1-hook-validation-roadmap.md` — Full implementation plan
- `.claude/context/patterns/automated-context-management.md` — Workflow pattern
- `.claude/context/patterns/context-budget-management.md` — Budget allocation
- `~/.claude.json` — Config file (user-level)

---

*MCP Load/Unload Test Procedure — Key Discovery Document*
*Updated: 2026-01-07 — disabledMcpServers array finding*
