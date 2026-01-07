# Tooling Evaluation Workflow Template

**Purpose**: Repeatable process for evaluating new tools (MCPs, plugins, skills, hooks, agents)

**Output**: Updated `.claude/reports/pr-{N}-{type}-evaluation.md`

---

## When to Use

Use this workflow when:
- Adding a new MCP server
- Installing a new plugin
- Evaluating a new skill
- Considering a new hook or agent
- PR-driven tooling expansion (PR-6, PR-7, PR-8, etc.)

---

## Workflow Steps

### Phase 1: Discovery

1. **Identify the tool**
   - Name and source (URL, marketplace, manual install)
   - Version
   - Category (MCP, plugin, skill, hook, agent)

2. **Gather information**
   - Read README/documentation
   - Check source code structure
   - Identify dependencies
   - Note installation requirements

3. **Test basic functionality**
   - Install (if not already installed)
   - Run basic smoke test
   - Verify tool loads without errors

### Phase 2: Evaluation

For each tool, evaluate using this template:

```markdown
### {N}. {tool-name} ({source})

**Purpose**: {1-2 sentence description of what it does}

**Best-Use Scenarios**:
- {Scenario 1}
- {Scenario 2}
- {Scenario 3}

**Risks**: {LOW | MEDIUM | HIGH}
- {Risk factor 1}
- {Risk factor 2}

**Overlap**: {NONE | LOW | MEDIUM | HIGH} with `{existing-tool}`
- {How they overlap}
- {How they differ}

**Decision**: {✅ ADOPT | 🔄 ADAPT | ❌ REJECT}
- {Rationale 1}
- {Rationale 2}

**Selection Rule** (if overlap exists):
- {When to use this tool} → `{this-tool}`
- {When to use alternative} → `{alternative}`
```

### Phase 3: Classification

Classify each tool into one of three decisions:

| Decision | Criteria | Action |
|----------|----------|--------|
| **ADOPT** | Unique value, low risk, no major overlap | Add to capability matrix, document usage |
| **ADAPT** | Value with conditions, medium risk, some overlap | Add with configuration/restrictions |
| **REJECT** | Redundant, high risk, or problematic | Document reason, do not install |

### Phase 4: Documentation

1. **Update evaluation report**
   - Add evaluation entry for each tool
   - Update summary table with counts
   - List configuration actions required

2. **Update overlap analysis**
   - Add new overlap categories if needed
   - Update component inventory
   - Define selection rules

3. **Update capability matrix**
   - Add new task → tool mappings
   - Add to appropriate plugin/MCP section
   - Add selection rules

---

## Evaluation Criteria Checklist

| Criterion | Questions to Answer |
|-----------|-------------------|
| **Purpose** | What problem does it solve? Is it needed? |
| **Quality** | Is it well-maintained? Good documentation? |
| **Overlap** | Does it conflict with existing tools? |
| **Risk** | What could go wrong? Security concerns? |
| **Dependency** | What does it require? Chrome? API keys? |
| **Integration** | How does it fit with existing workflows? |
| **Testing** | Can we validate it works correctly? |

---

## Risk Assessment Guide

### LOW Risk
- Read-only operations
- Isolated functionality
- Well-documented
- No external dependencies
- No credential access

### MEDIUM Risk
- Write operations within workspace
- Network operations
- Requires API keys
- AI interpretation of commands
- Browser session access

### HIGH Risk
- Operations outside workspace
- Access to credentials/secrets
- Autonomous decision-making
- Destructive operations possible
- Difficult to audit/trace

---

## Phase 5: Validation (Proof of Use)

For each ADOPT/ADAPT decision, create a validation scenario:

```markdown
### Validation Scenarios

| Tool | Validation Command/Scenario | Expected Result |
|------|----------------------------|-----------------|
| `{tool-name}` | {command or user action} | {expected outcome} |
```

**Validation Requirements**:
- Each adopted tool must have at least ONE validation scenario
- Scenario should be simple and reproducible
- Record test date and result in validation status table

**Validation Status Template**:
```markdown
| Tool | Tested | Date | Notes |
|------|--------|------|-------|
| {name} | ⏳ Pending / ✅ Passed / ❌ Failed | {date} | {notes} |
```

---

## Output Artifacts

After completing evaluation:

1. **Evaluation Report**: `.claude/reports/pr-{N}-{type}-evaluation.md`
2. **Overlap Analysis Update**: `.claude/reports/pr-{N}-overlap-analysis.md`
3. **Capability Matrix Update**: `.claude/context/integrations/capability-matrix.md`
4. **CLAUDE.md Update**: If high-value tool, add to Quick Start
5. **Validation Status**: Track in evaluation report

---

## Example: Evaluating browser-automation Plugin

```markdown
### 17. browser-automation (browser-tools)

**Purpose**: Automate web browser interactions using natural language via Stagehand framework.

**Best-Use Scenarios**:
- Web scraping and data extraction
- QA testing web applications
- Automated form filling

**Risks**: MEDIUM
- Requires Chrome installation
- Browser sessions may access logged-in accounts

**Overlap**: MEDIUM with Playwright MCP
- browser-automation: Natural language, AI-interpreted
- Playwright MCP: Programmatic, deterministic

**Decision**: 🔄 ADAPT
- Natural language approach is context-efficient
- Higher risk profile requires guardrails awareness

**Selection Rule**:
- Natural language automation → browser-automation
- Deterministic scripts → Playwright MCP
```

---

*Template version: 1.0.0*
*Created: 2026-01-07*
