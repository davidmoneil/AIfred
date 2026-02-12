# Upgrade Proposal: UP-004

## LSP Tool - Language Server Protocol Integration

**Generated**: 2026-01-20
**Status**: READY FOR APPROVAL
**Risk Level**: LOW
**Estimated Effort**: 15-20 minutes

---

## Summary

Enable Language Server Protocol (LSP) integration in Claude Code to provide code intelligence features:
- **Go-to-definition**: Jump directly to function/class definitions
- **Find references**: Locate all usages of a symbol across the codebase
- **Hover documentation**: View function signatures and docs inline
- **Workspace symbols**: Search for symbols by name

**Performance Impact**: Navigate codebases in ~50ms vs 45 seconds with text search.

---

## Relevance to Your Hub

| Factor | Rating | Notes |
|--------|--------|-------|
| **Codebase Match** | HIGH | 35 hooks + 8 skills = extensive TypeScript/JavaScript |
| **Navigation Need** | HIGH | Complex `.claude/` structure with many cross-references |
| **Current Pain Point** | MEDIUM | Grep/Glob work but slow for definition lookups |
| **Risk/Effort Ratio** | EXCELLENT | Low effort, high potential benefit |

### Specific Use Cases in Your Hub

1. **Hook Development**: Navigate between hook files, trace imports
2. **Skill Maintenance**: Jump to shared utilities, find all references to patterns
3. **Plugin Understanding**: Understand external plugin code faster
4. **Debugging**: Trace call hierarchies when troubleshooting

---

## Implementation Plan

### Phase 1: Enable LSP Tool (5 minutes)

**Option A - Environment Variable (Recommended for Testing)**
```bash
# Test in current session
ENABLE_LSP_TOOL=1 claude

# Verify LSP tools are available
# Look for lsp_* tools in available tools
```

**Option B - Permanent Enable**
```bash
# Add to ~/.bashrc or ~/.zshrc
export ENABLE_LSP_TOOL=1
```

### Phase 2: Install TypeScript LSP Server (5 minutes)

```bash
# Install vtsls (TypeScript/JavaScript LSP server)
npm install -g @vtsls/language-server typescript

# Verify installation
which vtsls  # Should return path
```

### Phase 3: Register Plugin Marketplace (5 minutes)

```bash
# Start Claude Code
claude

# Add marketplace
/plugin marketplace add Piebald-AI/claude-code-lsps

# Navigate to plugins menu
/plugins
# → Marketplaces → claude-code-lsps → Select vtsls → Install

# Apply patch for LSP functionality
npx tweakcc --apply
```

### Phase 4: Validate (5 minutes)

Test in your hub directory:
```
# Go to definition test
"Show me the definition of the auditLogger function in hooks"

# Find references test
"Find all files that import from audit-logger.js"

# Hover test
"What are the parameters of the logToolExecution function?"
```

---

## Files to Modify

| File | Change | Purpose |
|------|--------|---------|
| `~/.bashrc` or `~/.zshrc` | Add `export ENABLE_LSP_TOOL=1` | Enable LSP permanently |
| None in hub | N/A | This is a tooling upgrade |

**Note**: No hub files are modified. This is a Claude Code configuration change.

---

## Risks & Mitigations

### Risk 1: LSP Feature Still Raw
**Level**: LOW
**Description**: José Valim noted LSP APIs can be "awkward for agentic usage" and there are some bugs.
**Mitigation**: Test thoroughly before relying on it. Keep Grep/Glob as fallback.

### Risk 2: vtsls Installation Conflicts
**Level**: LOW
**Description**: Global npm package could conflict with local TypeScript versions.
**Mitigation**: Test in isolated session first. Can uninstall cleanly with `npm uninstall -g @vtsls/language-server`.

### Risk 3: Performance Overhead
**Level**: MINIMAL
**Description**: LSP servers run in background.
**Mitigation**: Monitor resource usage. Can disable if problematic.

---

## Rollback Strategy

If issues occur:

```bash
# Remove environment variable
# Edit ~/.bashrc or ~/.zshrc, remove: export ENABLE_LSP_TOOL=1

# Uninstall LSP server
npm uninstall -g @vtsls/language-server

# Remove marketplace plugin
/plugin marketplace remove Piebald-AI/claude-code-lsps

# Restart Claude Code
```

**Recovery Time**: < 5 minutes

---

## Success Criteria

- [ ] LSP tools appear in available tools list
- [ ] "Go to definition" works for TypeScript/JavaScript files in `.claude/hooks/`
- [ ] "Find references" locates usages across hub
- [ ] No significant performance degradation
- [ ] Faster navigation than Grep/Glob for definition lookups

---

## Decision Points

### Approval Required For:

1. **Enable LSP globally** (Option B) vs **test only** (Option A)
   - Recommendation: Start with Option A (test), then move to Option B if successful

2. **Install via marketplace** vs **manual setup**
   - Recommendation: Use marketplace for easier management

---

## Cost Analysis

| Item | Cost |
|------|------|
| Implementation Time | ~20 minutes |
| Ongoing Maintenance | Minimal - updates via marketplace |
| Resource Usage | Minimal - LSP servers are lightweight |
| Risk Exposure | Low - easily reversible |

**Net Assessment**: HIGH value, LOW cost

---

## Sources

- [How I'm Using Claude Code LSP](https://medium.com/@joe.njenga/how-im-using-new-claude-code-lsp-to-code-fix-bugs-faster-language-server-protocol-cf744d228d02) - Practical usage guide
- [Claude Code LSP: Complete Setup Guide](https://www.aifreeapi.com/en/posts/claude-code-lsp) - 11 language support details
- [Piebald-AI/claude-code-lsps](https://github.com/Piebald-AI/claude-code-lsps) - Plugin marketplace
- [José Valim on LSP Limitations](https://x.com/josevalim/status/2002312493713015160) - Honest assessment of current state
- [Claude Code Just Got The Ultimate Dev Shortcut](https://lilys.ai/en/notes/claude-code-20260113/claude-code-lsp-ultimate-shortcut) - Feature overview

---

## Approval

**To approve this proposal, respond with**: `/upgrade implement UP-004`

**To defer**: This proposal will remain in `ready_for_proposal` status.

**To reject**: `/upgrade reject UP-004 [reason]`

---

*Proposal generated by upgrade skill v1.0*
