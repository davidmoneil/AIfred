# External Tool Evaluation Pattern

## Purpose

A systematic process for evaluating external tools, Claude Code projects, and GitHub repositories to determine what patterns or features are worth adopting into your project.

**Goal**: Extract value without unnecessary complexity. Adopt patterns, not entire systems.

---

## When to Use This Pattern

- Discovering a popular Claude Code project (like Ralph, fabric, etc.)
- Evaluating a new MCP server
- Reviewing a tool mentioned in Anthropic blog/docs
- Considering integration with external service

---

## Evaluation Framework

### Step 1: Quick Assessment (5 minutes)

| Question | Answer |
|----------|--------|
| What does it do? | _one sentence_ |
| How popular? | _stars, forks, recent activity_ |
| What problem does it solve? | _specific pain point_ |
| Do we have that problem? | _yes/no/sometimes_ |

**If "no" to the problem question -> Stop here. Log and move on.**

### Step 2: Pattern Extraction (15-30 minutes)

List the distinct patterns/techniques the tool uses:

| Pattern | What It Does | Do We Have It? | Gap? |
|---------|--------------|----------------|------|
| _pattern 1_ | _description_ | Yes/Partial/No | Yes/No |
| _pattern 2_ | _description_ | Yes/Partial/No | Yes/No |
| ... | ... | ... | ... |

### Step 3: Value Assessment (5 minutes per pattern)

For each pattern with a gap, evaluate:

| Criteria | Score (1-5) | Notes |
|----------|-------------|-------|
| **Solves real problem** | _ | Do we actually hit this? |
| **Unique approach** | _ | Different from what we have? |
| **Integration effort** | _ | 1=easy, 5=hard |
| **Maintenance burden** | _ | 1=none, 5=ongoing |

**Scoring**:
- 15-20: **YES** - Worth adopting
- 10-14: **MAYBE** - Consider if time permits
- 5-9: **NO** - Not worth the effort
- Below 5: **REDUNDANT** - We already have this

### Step 4: Adoption Decision

For each pattern, decide:

| Decision | Action |
|----------|--------|
| **YES** | Create design doc, add to backlog |
| **PARTIAL** | Note as enhancement to existing system |
| **MAYBE** | Track for future review |
| **NO** | Document why not (prevents re-evaluation) |

---

## Output Template

```markdown
## [Tool Name] Evaluation

**Date**: YYYY-MM-DD
**Source**: [URL]
**Popularity**: X stars, Y forks

### Quick Assessment

- **What it does**: [one sentence]
- **Problem it solves**: [specific]
- **Do we have that problem?**: Yes/No/Sometimes

### Patterns Identified

| Pattern | Worth Adopting? | Reasoning |
|---------|-----------------|-----------|
| Pattern 1 | YES/PARTIAL/MAYBE/NO | [why] |
| Pattern 2 | YES/PARTIAL/MAYBE/NO | [why] |

### Recommendations

1. **Adopt**: [list patterns to adopt]
2. **Track**: [list patterns to monitor]
3. **Skip**: [list patterns not worth it]

### Follow-up Actions

- [ ] Action item 1
- [ ] Action item 2
```

---

## Integration with Upgrade Skill

External tools can be added as monitoring sources in `/upgrade`:

```yaml
# In .claude/skills/upgrade/config.yaml
sources:
  supplementary:
    - name: ralph
      url: https://github.com/snarktank/ralph
      type: github-repo
      check_frequency: monthly
      extract: [releases, readme_changes]
```

**When to add as source**:
- Tool is actively maintained
- Has produced valuable patterns before
- Likely to evolve with new techniques

---

## Anti-Patterns

### Don't Do This

1. **Adopt entire systems** - Extract patterns, don't copy projects
2. **Duplicate functionality** - Check what you have first
3. **Chase popularity** - Stars don't mean it solves YOUR problem
4. **Over-engineer** - Simple enhancement > complex integration
5. **Skip documentation** - Always record why you did/didn't adopt

### Do This Instead

1. **Pattern-first thinking** - What technique is valuable?
2. **Integration-aware** - How does it fit existing systems?
3. **Problem-focused** - Does it solve something we struggle with?
4. **Minimal adoption** - Smallest useful enhancement
5. **Document decisions** - Future you will thank you

---

## Related

- @.claude/skills/upgrade/SKILL.md - Monitoring external sources
- @.claude/context/patterns/capability-layering-pattern.md - Integration approach
