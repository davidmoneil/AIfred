# PRD-V4: AC-04 Context Exhaustion Stress Test

**Based on**: One-Shot PRD v2.0
**Target System**: AC-04 JICM Context Management
**Focus**: Read 20+ large files, force CRITICAL threshold

---

## Stress Modifications

### TEST MODE: Configurable Thresholds

**IMPORTANT**: JICM supports configurable thresholds via `autonomy-config.yaml`.

For testing, we temporarily set low thresholds to trigger behaviors without filling context:

```yaml
# .claude/config/autonomy-config.yaml (TEST MODE)
components:
  AC-04-jicm:
    settings:
      threshold_tokens: 20000  # 10% of 200k (TEST MODE)
```

This means:
- **WARNING** triggers at ~7% (~14k tokens)
- **CRITICAL** triggers at 10% (~20k tokens)

**Before executing PRD-V4**:
1. Back up current `autonomy-config.yaml`
2. Set `threshold_tokens: 20000`
3. Execute tests
4. Restore original config

### Context Loading Requirements

With TEST MODE thresholds, we need modest context to trigger:

| Phase | Files to Read | Estimated Tokens | Expected Threshold |
|-------|---------------|------------------|-------------------|
| Pre-flight | 3 config files | ~1,000 | Below all |
| TDD | 5 test examples | ~3,000 | Below all |
| Implementation | 10 reference files | ~8,000 | WARNING (7%) |
| Validation | Full test output | ~5,000 | Approaching CRITICAL |
| Documentation | 5 doc templates | ~3,000 | CRITICAL (10%) |

### Threshold Triggers

| Threshold | TEST MODE % | Normal % | Expected Behavior |
|-----------|-------------|----------|-------------------|
| CAUTION | 5% | 50% | Warning displayed |
| WARNING | 7% | 70% | Auto-offload triggered |
| CRITICAL | 10% | 85% | Checkpoint created |
| EMERGENCY | 12%+ | 95% | Avoid (stay below) |

---

## JICM Behavior Testing

### CAUTION (50%)
- [ ] Yellow/caution indicator shown
- [ ] Suggestion to consider compression
- [ ] No automatic action

### WARNING (70%)
- [ ] Orange/warning indicator shown
- [ ] Tier 2 MCPs considered for disable
- [ ] Context budget command suggested

### CRITICAL (85%)
- [ ] Red/critical indicator shown
- [ ] Automatic checkpoint creation
- [ ] MCP disable script executed
- [ ] User notified of imminent action

---

## Context Sources

### Files to Read (20+)

```
Required Reads:
1. .claude/CLAUDE.md
2. .claude/CLAUDE-full-reference.md
3. .claude/context/session-state.md
4. .claude/context/configuration-summary.md
5. .claude/context/integrations/capability-matrix.md
6. .claude/context/patterns/wiggum-loop-pattern.md
7. .claude/context/patterns/context-budget-management.md
8. .claude/context/patterns/agent-selection-pattern.md
9. .claude/context/standards/git-standards.md
10. .claude/context/standards/code-standards.md
11. projects/project-aion/roadmap.md
12. projects/project-aion/plans/one-shot-prd-v2.md
13. .claude/plugins/feature-dev/PLUGIN.md
14. .claude/agents/code-analyzer.md
15. .claude/agents/code-implementer.md
16. .claude/hooks/wiggum-loop-tracker.js
17. .claude/hooks/context-accumulator.js
18. .claude/scripts/benchmark-runner.js
19. .claude/scripts/scoring-engine.js
20. CHANGELOG.md
```

### Additional Context Generation
- Generate verbose test output (include all assertions)
- Include full stack traces on errors
- Request detailed explanations for each step

---

## Liftover Testing

When checkpoint is triggered, verify:

| Metric | Target |
|--------|--------|
| Essential context preserved | 100% |
| Non-essential pruned | > 50% |
| Liftover accuracy | > 95% |
| Resume success | 100% |

### Essential Context (must preserve)
- Current phase and step
- All todos and their states
- Critical file paths
- Test results summary
- Error states

### Non-essential (can prune)
- Full file contents (keep paths only)
- Verbose logging
- Intermediate calculations
- Historical context

---

## Test Metrics

| Metric | Target |
|--------|--------|
| Files read | 20+ |
| CAUTION threshold hit | Yes |
| WARNING threshold hit | Yes |
| CRITICAL threshold hit | Yes |
| EMERGENCY avoided | Yes |
| Successful liftover | Yes |

---

## Validation Points

| Test ID | Check | Pass Criteria |
|---------|-------|---------------|
| V4-01 | CAUTION triggered | At 50% |
| V4-02 | WARNING triggered | At 70% |
| V4-03 | CRITICAL triggered | At 85% |
| V4-04 | Checkpoint created | Valid format |
| V4-05 | MCPs disabled | Tier 2 only |
| V4-06 | Liftover accurate | > 95% |
| V4-07 | Resume successful | Work continues |
| V4-08 | No EMERGENCY | Stayed < 95% |

---

## MCP Tier Management

### Tier 1 (Always On)
- Memory MCP
- Git MCP
- Filesystem MCP

### Tier 2 (Disable at WARNING)
- Local RAG
- Fetch MCP
- Research tools

### Disable Verification
- [ ] `disable-mcps.sh` executed
- [ ] MCP config updated
- [ ] Claude restart not required
- [ ] `enable-mcps.sh` available for restore

---

## Success Criteria

- All 4 thresholds tested correctly
- Checkpoint created before EMERGENCY
- Liftover preserves > 95% essential context
- Work completes despite compression
- MCP management works as designed

---

*PRD-V4 — Context Exhaustion Stress Test*
