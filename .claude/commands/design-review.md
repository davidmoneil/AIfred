---
argument-hint: "<task description>"
description: Apply PARC pattern to review task design before implementation
allowed-tools:
  - Read
  - Grep
  - Glob
  - mcp__mcp-gateway__search_nodes
  - mcp__mcp-gateway__open_nodes
---

Apply the **PARC Design Review Pattern** to the following task before implementation:

**Task**: $ARGUMENTS

---

## Phase 1: PROMPT (Parse the Request)

Analyze the request:
1. **Core Objective**: What is being asked?
2. **Task Type**: Classify as one of:
   - [ ] New Feature / Capability
   - [ ] Bug Fix / Issue Resolution
   - [ ] Infrastructure Change
   - [ ] Automation / Script
   - [ ] Documentation
   - [ ] Other: ___
3. **Explicit Requirements**: What was stated directly?
4. **Implicit Requirements**: What's needed but not stated?

---

## Phase 2: ASSESS (Pattern Check)

Search for existing patterns and precedents:

### 2.1 Check Pattern Files
```bash
# Search for relevant patterns
ls -la .claude/context/patterns/
```

Review relevant pattern files for applicable patterns.

### 2.2 Check Workflow Templates
```bash
# Search for relevant workflows
ls -la .claude/context/workflows/
```

Look for applicable workflow templates.

### 2.3 Search Memory MCP

Use Memory MCP to find similar past work:
```
mcp__mcp-gateway__search_nodes("$ARGUMENTS keywords")
```

Look for:
- Similar implementations
- Past lessons learned
- Relevant decisions

### 2.4 Search Codebase

Search for similar implementations in the codebase:
```
Grep: [relevant keywords]
Glob: [relevant file patterns]
```

---

## Phase 3: RELATE (Connect to Architecture)

Analyze how this task fits into the broader system:

### 3.1 Scope Analysis

| Question | Answer |
|----------|--------|
| Is this task-specific or generalizable? | |
| Should this become a reusable pattern? | |
| Will this likely be repeated? | |

### 3.2 Reuse Opportunities

| Existing Component | Can Reuse? | How? |
|-------------------|------------|------|
| | | |

### 3.3 Impact Assessment

| System/Component | Impact | Risk Level |
|------------------|--------|------------|
| | | |

### 3.4 Technical Debt Check

| Concern | Applies? | Mitigation |
|---------|----------|------------|
| Creates coupling? | | |
| Duplicates existing code? | | |
| Requires future refactoring? | | |
| Missing tests/docs? | | |

---

## Phase 4: CREATE (Implementation Plan)

Based on the analysis above, provide:

### 4.1 Patterns to Apply

List the patterns that should be applied:
1.
2.
3.

### 4.2 Implementation Approach

Recommend the approach:
- [ ] Follow existing pattern: [pattern name]
- [ ] Extend existing implementation: [what]
- [ ] Create new pattern (document after)
- [ ] Simple one-off (no pattern needed)

### 4.3 Documentation Plan

- [ ] Update existing context file: [which]
- [ ] Create new context file: [topic]
- [ ] No documentation needed
- [ ] Create slash command if used 3x

### 4.4 Memory MCP Storage Plan

Based on @.claude/context/patterns/memory-storage-pattern.md:
- [ ] Store new pattern if discovered
- [ ] Store lesson if non-obvious solution
- [ ] Store decision if architectural choice made
- [ ] No storage needed for routine implementation

---

## Summary

Provide a brief summary:

**Recommendation**: [One sentence recommendation]

**Patterns to Follow**: [List]

**Key Considerations**: [List]

**Proceed?**: Ready to implement with the above approach.

---

## Pattern Reference

**Full Pattern Documentation**: @.claude/context/patterns/prompt-design-review.md

**Related Patterns**:
- @.claude/context/patterns/memory-storage-pattern.md
- @.claude/context/integrations/workflow-patterns.md
