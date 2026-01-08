---
name: validate-mcp
description: Validate MCP installation, configuration, and functionality
user_invocable: true
arguments:
  - name: mcp_name
    description: Name of the MCP to validate (e.g., 'git', 'memory')
    required: true
  - name: quick
    description: Skip Phase 4 functional tests (faster but less thorough)
    required: false
---

# MCP Validation Skill

Systematic validation of MCP servers following the 5-phase harness pattern.

## Purpose

Ensure MCPs are:
1. Properly installed and registered
2. Correctly configured
3. Functionally working
4. Token-cost measured
5. Tier-classified

## Validation Phases

Execute each phase in sequence:

### Phase 1: Installation Verification

1. Run the installation check script:
   ```bash
   .claude/scripts/validate-mcp-installation.sh {mcp_name}
   ```

2. Verify tool discovery by listing available tools for the MCP
3. Check for duplicate tool names across MCPs

### Phase 2: Configuration Audit

1. Check required configuration:
   - API keys (environment variables)
   - Path configurations
   - Permission requirements

2. Document configuration in results log

### Phase 3: Tool Inventory

For each tool in the MCP:
1. Document tool name and description
2. List required and optional parameters
3. Note return value format
4. Estimate token cost

Create inventory table:
```markdown
| Tool | Purpose | Params | Status |
|------|---------|--------|--------|
```

### Phase 4: Functional Testing (Skip if --quick)

For each tool:
1. **Happy Path Test**: Valid inputs → Expected output
2. **Error Handling Test**: Invalid inputs → Graceful error
3. Document test results

### Phase 5: Tier Recommendation

Apply tier criteria:

**Tier 1 (Always-On)**:
- Used in >50% of sessions
- Token cost <3K
- Core to primary workflows

**Tier 2 (Task-Scoped)**:
- Used in specific task categories
- Token cost 3K-8K
- Can be predicted at session start

**Tier 3 (Triggered/Isolated)**:
- Infrequent use (<20% of sessions)
- Token cost >8K
- Task-specific activation

## Output Requirements

1. **Create validation log**:
   `.claude/logs/mcp-validation/{mcp_name}-{date}.md`

2. **Update capability matrix** (if validated):
   Add tools to `.claude/context/integrations/capability-matrix.md`

3. **Update MCP installation docs** (if new MCP):
   Add entry to `.claude/context/integrations/mcp-installation.md`

## Example Invocation

```
User: /validate-mcp git
Claude: Running validation harness for Git MCP...

Phase 1: Installation ✓
Phase 2: Configuration ✓
Phase 3: Tool Inventory - 12 tools found
Phase 4: Functional Tests - 3/3 passed
Phase 5: Tier Recommendation - Tier 1 (Always-On)

Validation complete. Log written to .claude/logs/mcp-validation/git-20260108.md
```

## Reference

Full pattern documentation: @.claude/context/patterns/mcp-validation-harness.md
