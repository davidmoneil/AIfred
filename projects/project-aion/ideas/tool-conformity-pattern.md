# Brainstorm: Tool Conformity Pattern

*Created: 2026-01-05*
*Status: Brainstorm / Idea*
*Related PRs: PR-5 through PR-9 (potential sub-PR)*

---

## Problem Statement

As Jarvis integrates external tools—Claude Code built-in features, MCP servers, plugins, third-party agents—these tools often have their own behavior patterns that don't conform to Jarvis's established architecture.

### Example: Claude Code Plan Mode

When using Claude Code's `EnterPlanMode` tool:
- **Expected (by Jarvis)**: Plan files stored in `.claude/context/plans/` or `docs/project-aion/plans/`
- **Actual (Claude Code default)**: Plans stored in `~/.claude/plans/` with random codenames like `wild-mapping-rose.md`

This creates:
1. **Discoverability issues**: Plans aren't where Jarvis expects to find them
2. **Naming incoherence**: Random names don't convey content
3. **Workspace boundary violation**: Files outside the Jarvis workspace

### General Pattern

| Tool Behavior | Jarvis Expectation | Conflict |
|---------------|-------------------|----------|
| Claude Code Plan Mode | `~/.claude/plans/` | Files outside workspace |
| MCP servers | Various config locations | May not respect `paths-registry.yaml` |
| Plugins | May create caches/logs | Unknown file placement |
| Third-party agents | May have own conventions | Naming, storage, behavior |

---

## Proposed Solution: Tool Integration Layer

A pattern and/or enforcement mechanism that normalizes external tool behavior.

### Approach Options

#### Option A: Post-Hoc Remediation
- **What**: After a tool runs, move/rename artifacts to conformant locations
- **How**: Session-end hook or periodic cleanup
- **Pros**: Non-invasive, works with any tool
- **Cons**: Reactive, may miss things, creates duplicate locations

#### Option B: Tool Wrapper Pattern
- **What**: Wrap external tools with Jarvis-aware adapters
- **How**: Custom skills/commands that invoke tools then normalize output
- **Pros**: Proactive, full control
- **Cons**: Maintenance burden, may not cover all tools

#### Option C: Configuration Injection
- **What**: Where possible, configure tools to use Jarvis-conformant paths
- **How**: Environment variables, config files, CLI flags
- **Pros**: Clean solution when possible
- **Cons**: Not all tools support configuration

#### Option D: Conformity Audit + Documentation
- **What**: Accept non-conformity but document known behaviors
- **How**: Tool inventory with "behavior notes" and path mappings
- **Pros**: Low effort, transparent
- **Cons**: Doesn't actually solve the problem

### Recommended: Hybrid Approach

1. **Configuration First (Option C)**: Where tools support it, configure them
2. **Wrapper Where Needed (Option B)**: For critical tools, create Jarvis wrappers
3. **Document Everything (Option D)**: Maintain an inventory of tool behaviors
4. **Remediation Fallback (Option A)**: Cleanup hook for edge cases

---

## Implementation Considerations

### Tool Inventory Structure

```yaml
# .claude/config/tool-inventory.yaml
tools:
  claude-code-plan-mode:
    type: built-in
    default_behavior:
      storage: "~/.claude/plans/"
      naming: "random-three-words"
    jarvis_conformity:
      strategy: post-hoc-remediation
      target_path: "docs/project-aion/plans/"
      naming_pattern: "pr-{pr_number}-{description}.md"
    notes: "Cannot configure storage location"

  memory-mcp:
    type: mcp-server
    default_behavior:
      storage: "configurable"
    jarvis_conformity:
      strategy: configuration
      config_key: "MEMORY_FILE_PATH"
      target_path: ".claude/data/memory.json"
```

### Conformity Check Hook

A potential `tool-conformity-check.js` hook (PostToolUse or Notification event):
- Scans known non-conformant locations
- Alerts when artifacts found outside workspace
- Optionally moves/links to conformant locations

### Validation Pattern

Add to setup preflight or health-check:
- **Known External Artifacts**: Check `~/.claude/plans/`, etc.
- **Workspace Boundary**: Flag files that should be inside Jarvis but aren't
- **Path Registry Sync**: Ensure tools using paths match `paths-registry.yaml`

---

## PR Placement Options

### Option 1: Add to PR-9 (Selection Intelligence)
- **Rationale**: "Selection Intelligence" is about choosing the right tool—conformity is part of that
- **Scope**: Extend PR-9 to include conformity rules as part of selection

### Option 2: Create PR-9b (Tool Conformity) as Sub-PR
- **Rationale**: Distinct enough to warrant separation
- **Scope**: Focused PR just for conformity pattern

### Option 3: Create New PR-15 (Tool Integration Layer)
- **Rationale**: This is a cross-cutting concern across PR-5→8
- **Scope**: Comprehensive tool integration framework

### Recommendation

**PR-9b: Tool Conformity** as a sub-PR of PR-9 (Selection Intelligence).

Rationale:
- Conformity is part of "intelligence" about tools
- Keeps scope contained but acknowledges importance
- Can be implemented after core tool expansion (PR-5→8) but before PR-10 (Setup Upgrade)

---

## Related Patterns

- **workspace-path-policy.md** — Defines where things go (this extends it)
- **mcp-loading-strategy.md** — Already has conformity elements for MCPs
- **agent-selection-pattern.md** — Defines when to use which agent type

---

## Questions for Future Resolution

1. Should non-conforming tools be blocked until adapted?
2. How much remediation should be automatic vs prompted?
3. What's the cost/benefit of wrapping vs accepting divergence?
4. Should the tool inventory be human-maintained or auto-discovered?

---

## Action Items

- [ ] Decide PR placement (PR-9b recommended)
- [ ] Create tool inventory schema
- [ ] Document known non-conformant behaviors as tools are added
- [ ] Design conformity check for health-check command
- [ ] Consider session-end cleanup for known external locations

---

*Brainstorm: Tool Conformity Pattern — Awaiting Prioritization*
