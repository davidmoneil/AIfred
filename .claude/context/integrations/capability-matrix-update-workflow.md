# Capability Matrix Update Workflow Template

**Purpose**: Repeatable process for updating the capability matrix when tools are added/changed

**Output**: Updated `.claude/context/integrations/capability-matrix.md`

---

## When to Use

Use this workflow:
- After completing a tooling evaluation
- After resolving overlaps
- When adding new task types
- When tool priorities change

---

## Workflow Steps

### Phase 1: Identify Updates Needed

Check which sections need updates:

| Section | Update When |
|---------|-------------|
| Task Type Matrix | New task type or tool added |
| Tool Category Reference | New tool category added |
| Plugin Selection Rules | New plugin with overlap |
| Selection Decision Tree | New branch point needed |
| Loading Strategy | MCP added/changed |

### Phase 2: Update Task Type Matrix

For each new capability, add to appropriate section:

```markdown
### {Operation Category} Operations

| Task | Primary Tool | Fallback | Notes |
|------|--------------|----------|-------|
| {task description} | `{primary-tool}` | {fallback} | {notes} |
```

Guidelines:
- Primary tool = most appropriate for typical use case
- Fallback = alternative when primary unavailable or unsuitable
- Notes = context, limitations, or conditions

### Phase 3: Update Tool Reference Tables

Add new tools to reference tables:

```markdown
#### {Category} ({source})

| Plugin/MCP/Skill | Purpose | Decision | When to Use |
|------------------|---------|----------|-------------|
| `{name}` | {purpose} | {ADOPT/ADAPT/REJECT} | {conditions} |
```

### Phase 4: Add Selection Rules

If tool has overlap, add selection rule:

```markdown
### {Domain} Selection
\`\`\`
{Domain} operations needed?
├── {Condition 1} → {tool-1}
├── {Condition 2} → {tool-2}
└── {Condition 3} → {tool-3}
\`\`\`
```

### Phase 5: Update Decision Tree

Add branch to main decision tree if new category:

```markdown
├── Is it {new category}?
│   ├── {Subcondition 1} → Use {tool-1}
│   ├── {Subcondition 2} → Use {tool-2}
│   └── {Subcondition 3} → Use {tool-3}
```

### Phase 6: Update Loading Strategy

If MCP added, update loading strategy section:

| Server | Purpose | Token Cost | Strategy |
|--------|---------|------------|----------|
| {name} | {purpose} | {~NNK} | {Always-On/On-Demand/Isolated} |

---

## Task Type Categories

Standard categories (add new rows, not new categories unless truly new domain):

| Category | Examples |
|----------|----------|
| File Operations | Read, write, edit, search files |
| Git Operations | Status, commit, branch, PR |
| Web/Research | Fetch, search, research |
| Browser Automation | Navigate, fill forms, scrape |
| GitHub Operations | Issues, PRs, code search |
| Code Exploration | Search, architecture, tracing |
| Development Workflows | Features, reviews, testing |
| Document Generation | Office docs, diagrams, PDFs |
| Infrastructure | Docker, services, deployment |
| Time & Memory | Timezone, knowledge graph |

---

## Selection Rule Patterns

### Abstraction Level Pattern
```
{Domain} task?
├── High-level (NL) → {plugin/agent}
├── Mid-level → {MCP/skill}
└── Low-level → {built-in/bash}
```

### Complexity Pattern
```
{Domain} task?
├── Simple → {lightweight-tool}
├── Complex → {comprehensive-tool}
└── Enterprise → {specialized-tool}
```

### Risk Pattern
```
{Domain} task?
├── Safe/internal → {any-tool}
├── External/risky → {guarded-tool}
└── Critical → {reviewed-tool}
```

---

## Quality Checks

Before finalizing updates:

1. [ ] Every new tool appears in at least one task row
2. [ ] Overlapping tools have selection rules
3. [ ] Decision tree covers new capabilities
4. [ ] Version number updated
5. [ ] Related documentation cross-referenced

---

## Version Bump Convention

```markdown
*Capability Matrix v{X.Y} (Revised {date} with {change-summary})*
```

- Increment minor version for new tools
- Increment patch for corrections/clarifications

---

## Example: Adding Browser Automation

1. **Add Task Type Matrix section**:
```markdown
### Browser Automation Operations

| Task | Primary Tool | Fallback | Notes |
|------|--------------|----------|-------|
| NL browser tasks | browser-automation | Playwright | NL-first |
| Programmatic automation | Playwright | browser-automation | Deterministic |
```

2. **Add Plugin Reference**:
```markdown
#### Browser Automation (browser-tools)

| Plugin | Purpose | Decision | When to Use |
|--------|---------|----------|-------------|
| browser-automation | NL browser control | ADAPT | NL web tasks (caution) |
```

3. **Add Selection Rule**:
```markdown
### Browser Automation Selection
\`\`\`
Need browser automation?
├── Simple fetch → WebFetch/WebSearch
├── Natural language → browser-automation
└── Deterministic → Playwright MCP
\`\`\`
```

4. **Update Decision Tree**:
```markdown
├── Is it browser automation?
│   ├── Simple fetch → WebFetch/WebSearch
│   ├── NL tasks → browser-automation
│   └── Scripts → Playwright MCP
```

---

*Template version: 1.0.0*
*Created: 2026-01-07*
