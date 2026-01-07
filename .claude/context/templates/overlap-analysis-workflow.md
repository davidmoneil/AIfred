# Overlap Analysis Workflow Template

**Purpose**: Repeatable process for identifying and resolving tool overlaps/conflicts

**Output**: Updated `.claude/reports/pr-{N}-overlap-analysis.md`

---

## When to Use

Use this workflow:
- After any tooling evaluation (plugins, MCPs, skills)
- When adding hooks or agents
- When noticing redundant functionality
- During PR-driven tooling expansion

---

## Workflow Steps

### Phase 1: Component Inventory

Create/update the inventory of all components:

```markdown
### {Category} ({count} total)

| Source | Name | Primary Function |
|--------|------|------------------|
| {source} | {name} | {1-sentence function} |
```

Categories to inventory:
- Plugins
- MCP Servers
- Hooks
- Custom Agents
- Built-in Subagents
- Skills

### Phase 2: Overlap Detection

For each new tool, scan for overlaps with:

1. **Same-category tools** (plugin vs plugin)
2. **Cross-category tools** (plugin vs MCP vs hook)
3. **Built-in tools** (WebFetch, WebSearch, etc.)

### Phase 3: Overlap Classification

For each detected overlap, create an analysis entry:

```markdown
### Category {N}: {Overlap Category Name}

| Component | Type | Function |
|-----------|------|----------|
| `{component-1}` | {type} | {function} |
| `{component-2}` | {type} | {function} |

**Overlap Level**: {NONE | LOW | MEDIUM | HIGH}
- {component-1}: {how it works}
- {component-2}: {how it works}

**Resolution**: {Keep all | Specialize | Simplify | Remove one}

**Selection Rule**:
- {Use case 1} → `{tool-1}`
- {Use case 2} → `{tool-2}`
```

### Phase 4: Resolution Summary

Update the summary table:

```markdown
## Summary: Overlap Resolutions

| Category | Resolution | Primary Tool | Fallback |
|----------|------------|--------------|----------|
| {category} | {resolution} | {primary} | {fallback} |
```

---

## Overlap Levels

| Level | Definition | Action |
|-------|------------|--------|
| **NONE** | No functional overlap | No action needed |
| **LOW** | Complementary functionality | Keep both, document distinction |
| **MEDIUM** | Partial overlap | Define selection rules |
| **HIGH** | Near-complete overlap | Choose primary, keep fallback or remove |

---

## Resolution Strategies

### Keep All
When overlap is LOW and tools are complementary:
- Document both tools
- Explain when each is appropriate
- No removal needed

### Specialize
When overlap is MEDIUM/HIGH but tools have different strengths:
- Define primary tool for each use case
- Document selection criteria
- Keep both with clear boundaries

### Simplify
When overlap is HIGH and one tool suffices:
- Choose the more capable tool as primary
- Keep simpler tool as fallback only
- Document deprecation path if removing

### Remove
When overlap is HIGH and tool adds no value:
- Mark as REJECT in evaluation
- Document reason
- Do not install or remove if installed

---

## Cross-Category Overlap Patterns

### Plugin vs Hook
- **Plugin**: Proactive capabilities, triggered by commands
- **Hook**: Reactive guardrails, triggered by events
- **Resolution**: Usually complementary (plugin does, hook guards)

### Plugin vs MCP
- **Plugin**: Workflow-oriented, multiple tools bundled
- **MCP**: Single-purpose server, standardized protocol
- **Resolution**: Usually different abstraction levels

### MCP vs Built-in
- **MCP**: External server, more features
- **Built-in**: Integrated, lower overhead
- **Resolution**: Built-in for simple cases, MCP for advanced

### Agent vs Subagent
- **Custom Agent**: Domain-specific, persistent memory
- **Built-in Subagent**: General-purpose, context-aware
- **Resolution**: Custom for specialized workflows

---

## Overlap Detection Checklist

| Pattern | Check For |
|---------|-----------|
| Same function | Two tools doing the exact same thing |
| Subset function | One tool's capability is a subset of another |
| Conflicting behavior | Tools that might interfere with each other |
| Dependency conflict | Tools requiring incompatible dependencies |
| Resource conflict | Tools competing for same resources |

---

## Output Format

The overlap analysis report should contain:

1. **Component Inventory**: All tools by category
2. **Overlap Categories**: Each detected overlap
3. **Resolution Summary**: Table of all resolutions
4. **Recommendations**: High-value, redundant, configuration notes
5. **Action Items**: Remaining tasks

---

## Example: Browser Automation Overlap

```markdown
### Category 10: Browser Automation

| Component | Type | Function |
|-----------|------|----------|
| `browser-automation` | Plugin | NL browser control via Stagehand |
| `Playwright MCP` | MCP | Programmatic browser automation |
| `WebFetch` | Built-in | Fetch web content (read-only) |

**Overlap Level**: MEDIUM
- browser-automation: Natural language → AI interprets
- Playwright MCP: Direct API calls → precise control
- WebFetch: Content retrieval only, no interaction

**Resolution**: Different use cases

**Selection Rule**:
- Simple content fetch → WebFetch / WebSearch
- Natural language browsing → browser-automation
- Deterministic automation → Playwright MCP
```

---

*Template version: 1.0.0*
*Created: 2026-01-07*
