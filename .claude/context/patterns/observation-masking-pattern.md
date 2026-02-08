# Observation Masking Pattern

**Purpose**: Reduce context consumption from tool outputs (which consume 80%+ of context in agent workflows).

**Source**: Extracted from [context-engineering-marketplace](https://github.com/muratcankoylan/Agent-Skills-for-Context-Engineering) — context-optimization skill.

## When to Apply

Tool output exceeds threshold for its type:
- **Glob/find results**: >50 files → summarize count + key paths
- **Grep results**: >100 lines → write to temp file, inject summary
- **Bash output**: >2000 chars → write to temp file, inject summary + reference
- **Read of large files**: >500 lines when only needing overview → read key sections
- **Multi-file reads**: >3 files read in sequence → summarize key findings between reads

## Pattern

```
1. Execute tool operation normally
2. If output > threshold:
   a. (Optional) Write full output to /tmp/jarvis-{op}-{epoch}.md
   b. Extract key information (counts, paths, errors, key values)
   c. Formulate compact summary (100-200 tokens max)
   d. Include file reference for on-demand re-read if needed
3. Continue with compact summary in context
```

## Target Savings

| Context Item | % of Total | Masking Savings |
|-------------|-----------|----------------|
| Tool outputs | 80%+ | 60-80% reduction |
| Old conversation turns | 10-15% | Handled by compaction |
| System prompts/tools | 5-10% | Stable (don't compress) |

## Integration with JICM

- **Pre-compression**: Apply masking before JICM compression thresholds trigger
- **Multiplicative**: Masking + compaction together provide greater savings than either alone
- **Token-per-task**: Optimize for task completion, not per-request minimization
  - Don't mask file paths (re-fetching costs more than path tokens saved)
  - Don't mask error messages (debugging context is critical)
  - Don't mask small outputs (<500 tokens) — overhead exceeds savings

## Anti-Patterns

- Masking error outputs (hides debugging context)
- Masking security-relevant outputs (hides warnings)
- Over-aggressive masking of small outputs (net negative ROI)
- Losing file references when masking (makes re-read impossible)

## Related

- `jicm-pattern.md` — JICM threshold management
- `context-budget-management.md` — Token budget allocation
- `parallelization-strategy.md` — Context partitioning via sub-agents
