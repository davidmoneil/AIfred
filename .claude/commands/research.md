# /research — R&D Cycles Command

**Purpose**: Trigger AC-07 R&D Cycles to discover improvements and research topics.

**Usage**: `/research [--focus external|internal|all] [--topic <id>] [--dry-run]`

---

## Overview

The `/research` command triggers Jarvis' R&D cycles, investigating external innovations (MCPs, plugins, patterns) and internal efficiency opportunities.

## Options

| Option | Values | Default | Description |
|--------|--------|---------|-------------|
| `--focus` | external, internal, all | all | Focus area for research |
| `--topic` | topic-id | all pending | Research specific topic only |
| `--dry-run` | flag | false | Show what would be researched |
| `--quick` | flag | false | Abbreviated research (less thorough) |

## Focus Areas

### External Research
- New MCPs from awesome-mcp, modelcontextprotocol
- New plugins from claude-code-plugins
- SOTA patterns and practices
- Anthropic release notes and updates

### Internal Research
- Token usage patterns and optimization
- File organization and redundancy
- Context efficiency analysis
- Hook/command consolidation opportunities

## Examples

```bash
# Full R&D cycle
/research

# Only external discovery
/research --focus external

# Only internal efficiency
/research --focus internal

# Research specific topic
/research --topic rd-2026-01-001

# See what would be researched
/research --dry-run

# Quick abbreviated research
/research --quick
```

## Five-Step Process

### Step 1: Discovery
**External**: Scan registries for new tools
**Internal**: Analyze usage patterns

### Step 2: Filter
Apply adoption criteria:
- Stability (mature, maintained)
- Utility (clear use case)
- Integration cost (context overhead)
- Overlap (duplicates existing?)

### Step 3: Analyze
Deep-dive on candidates:
- Feature comparison
- Cost/benefit analysis
- Integration requirements

### Step 4: Classify
Assign recommendation:
| Classification | Meaning |
|----------------|---------|
| **ADOPT** | Implement as-is |
| **ADAPT** | Modify for Jarvis |
| **DEFER** | Watch, revisit later |
| **REJECT** | Not suitable |

### Step 5: Propose
Generate evolution proposals:
- ADOPT/ADAPT → queue for AC-06
- All proposals require user approval

## Adoption Criteria

### For MCPs
| Criterion | Weight | Threshold |
|-----------|--------|-----------|
| Stability | High | Must be stable release |
| Context cost | High | < 5K tokens ideal |
| Unique capability | Medium | Not duplicate |
| Active maintenance | Medium | Updated in last 6 months |

### For Plugins
| Criterion | Weight | Threshold |
|-----------|--------|-----------|
| Usefulness | High | Clear use case |
| Overlap | High | Doesn't duplicate |
| Token cost | Medium | Reasonable overhead |
| Quality | Medium | Well-documented |

### For Patterns
| Criterion | Weight | Threshold |
|-----------|--------|-----------|
| Applicability | High | Relevant to Jarvis |
| Evidence | High | Proven in practice |
| Complexity | Medium | Not over-engineered |

## Output

### Report Location
`.claude/reports/research/research-YYYY-MM-DD.md`

### Report Format
```markdown
# R&D Report — [Date]

## Summary
- Topics researched: X
- External discoveries: Y
- Internal findings: Z
- Proposals generated: W

## External Research
### MCPs Evaluated
[Table with name, verdict, rationale]

### Plugins Evaluated
[Table with name, verdict, rationale]

### Patterns Discovered
[List with applicability assessment]

## Internal Research
### Efficiency Findings
[Token usage, optimization opportunities]

### Organization Findings
[Redundancy, consolidation opportunities]

## Proposals Generated
[ADOPT/ADAPT items queued for evolution]

## Deferred for Later
[DEFER items with revisit timeline]
```

### Side Effects
- Updates research-agenda.yaml
- Creates evolution proposals (ADOPT/ADAPT)
- Creates Memory MCP entities (if available)

## Integration

- **AC-05**: May receive topics from reflection findings
- **AC-06**: ADOPT/ADAPT proposals queued for evolution
- **PR-14**: Uses SOTA catalog for reference

## Default Behavior

R&D proposals **always require user approval** before implementation:
- External discoveries could introduce bloat
- Internal changes could affect stability
- User should validate research conclusions

---

*Part of Jarvis Phase 6 Autonomic System (AC-07)*
