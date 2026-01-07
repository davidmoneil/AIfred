# Hookify Plugin Import Fix

**Created**: 2026-01-06
**Issue**: `No module named 'hookify'` error on every prompt
**Status**: RESOLVED

---

## Problem

After installing the hookify plugin (`hookify@claude-code-plugins`), every prompt submission triggers:

```
Hookify import error: No module named 'hookify'
```

This occurs because the plugin's Python hooks use absolute imports:

```python
from hookify.core.config_loader import load_rules
from hookify.core.rule_engine import RuleEngine
```

But Claude Code's plugin cache structure doesn't include a `hookify/` subdirectory:

```
~/.claude/plugins/cache/claude-code-plugins/hookify/0.1.0/
├── core/
│   ├── config_loader.py
│   └── rule_engine.py
├── hooks/
│   └── userpromptsubmit.py
└── ... (no hookify/ directory)
```

Python can't resolve `from hookify.core...` because there's no `hookify/` folder.

---

## Solution: Symlink Workaround (Recommended)

Create a symlink that points `hookify/` to the current directory:

```bash
cd ~/.claude/plugins/cache/claude-code-plugins/hookify/0.1.0/
ln -s . hookify
```

After this fix, the directory structure becomes:

```
~/.claude/plugins/cache/claude-code-plugins/hookify/0.1.0/
├── hookify -> .        # ← Symlink to self
├── core/
├── hooks/
└── ...
```

Now `hookify/core/config_loader.py` resolves to `./core/config_loader.py`.

---

## Verification

Test the fix:

```bash
# Test import directly
cd ~/.claude/plugins/cache/claude-code-plugins/hookify/0.1.0/
python3 -c "from hookify.core.config_loader import load_rules; print('✅ Success')"

# Test full hook execution
echo '{"prompt": "test"}' | \
  CLAUDE_PLUGIN_ROOT="/Users/aircannon/.claude/plugins/cache/claude-code-plugins/hookify/0.1.0" \
  python3 /Users/aircannon/.claude/plugins/cache/claude-code-plugins/hookify/0.1.0/hooks/userpromptsubmit.py

# Expected output: {} (empty JSON = success, no rules matched)
```

---

## Alternative Solutions

### Option B: Patch Import Statements

Modify the Python files to use relative imports:

```bash
cd ~/.claude/plugins/cache/claude-code-plugins/hookify/0.1.0/
sed -i '' 's/from hookify\.core\./from core./g' hooks/*.py
sed -i '' 's/from hookify\.core\./from core./g' core/rule_engine.py
```

**Note**: macOS requires `sed -i ''` (empty string for backup). Linux uses `sed -i`.

### Option C: Reinstall Plugin

If issues persist after Python environment changes:

```
/plugin uninstall hookify@claude-code-plugins
/plugin install hookify@claude-code-plugins
```

Then reapply the symlink fix.

---

## Durability

**Warning**: The symlink fix may be lost when:
- The plugin is updated
- The plugin is reinstalled
- The plugin cache is cleared

### Recommended: Add Check to Session Start

Consider adding a verification to the session-start hook or a startup script:

```bash
# Check if hookify symlink exists
HOOKIFY_DIR="$HOME/.claude/plugins/cache/claude-code-plugins/hookify"
if [ -d "$HOOKIFY_DIR" ]; then
  VERSION_DIR=$(ls -1 "$HOOKIFY_DIR" | head -1)
  if [ -n "$VERSION_DIR" ] && [ ! -L "$HOOKIFY_DIR/$VERSION_DIR/hookify" ]; then
    echo "Reapplying hookify symlink fix..."
    cd "$HOOKIFY_DIR/$VERSION_DIR" && ln -sf . hookify
  fi
fi
```

---

## Root Cause Analysis

| Factor | Description |
|--------|-------------|
| **Plugin Design** | Assumes installation as Python package with `hookify/` top-level |
| **Claude Code Cache** | Places plugins at `.../hookify/<version>/...` without package structure |
| **Python Import** | `from hookify.core...` requires `hookify/` on sys.path |
| **Environment Variable** | `CLAUDE_PLUGIN_ROOT` adds plugin dir to path, but not as package |

The symlink bridges the gap between the plugin's package expectations and Claude Code's flat cache structure.

---

## Related

- hookify plugin: `~/.claude/plugins/cache/claude-code-plugins/hookify/`
- Known issue reported on GitHub: anthropics/claude-code-plugins

---

*Documented: 2026-01-06 — Jarvis PR-5 Tooling Health*
