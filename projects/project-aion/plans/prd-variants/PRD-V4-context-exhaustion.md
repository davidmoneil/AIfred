# PRD-V4: AC-04 Context Exhaustion Stress Test

**Based on**: One-Shot PRD v2.0
**Target System**: AC-04 JICM (Jarvis Intelligent Context Management)
**Focus**: Heavy context loading during build, forced threshold triggers

---

## Deliverable Requirements

**THIS VARIANT MUST PRODUCE A WORKING APPLICATION**

### Application: aion-hello-console-v4

Build the Aion Hello Console application as defined in One-Shot PRD v2, with:

| Attribute | Value |
|-----------|-------|
| **Name** | aion-hello-console-v4-context |
| **Type** | Web application (Node.js + Express) |
| **Repository** | `CannonCoPilot/aion-hello-console-v4-context` |
| **Expected Tests** | 50+ (unit + integration + E2E) |
| **Features** | slugify, reverse, uppercase, wordCount |

### Deliverable Checklist

At completion, verify:
- [ ] Application runs locally (`npm start`)
- [ ] All 53+ tests pass (`npm test && npm run test:e2e`)
- [ ] Repository exists on GitHub
- [ ] README.md documents usage
- [ ] ARCHITECTURE.md explains design

---

## Stress Modifications: Context Exhaustion

### Deliberate Context Loading

During build, deliberately load context to stress-test JICM:

| Phase | Additional Context Load | Purpose |
|-------|------------------------|---------|
| Phase 1 | Read 5 reference files | Build context toward CAUTION |
| Phase 2 | Read 8 test pattern files | Approach WARNING threshold |
| Phase 3 | Read 10 implementation refs + verbose output | Trigger WARNING → checkpoint |
| Phase 4 | Resume, load test output | Test post-checkpoint context |
| Phase 5-7 | Moderate loading | Complete delivery |

### Required Context Reads (By Phase)

**Phase 1 Pre-flight** (build context):
```
1. .claude/CLAUDE.md (full)
2. .claude/context/patterns/wiggum-loop-pattern.md
3. .claude/context/patterns/context-budget-management.md
4. .claude/context/integrations/capability-matrix.md
5. projects/project-aion/plans/one-shot-prd-v2.md
```

**Phase 2 TDD Setup** (stress context):
```
6. .claude/context/standards/code-standards.md
7. .claude/context/standards/test-standards.md
8. .claude/plugins/feature-dev/PLUGIN.md
9. .claude/agents/code-analyzer.md
10. .claude/agents/code-tester.md
11. .claude/hooks/context-accumulator.js (read for understanding)
12. .claude/hooks/wiggum-loop-tracker.js
13. projects/project-aion/roadmap.md
```

**Phase 3 Implementation** (trigger threshold):
```
14-23. Read 10 additional reference files
24. Request VERBOSE test output (show all assertions)
25. Include full stack traces on any errors
26. Generate extensive code comments
```

### Threshold Expectations

| Threshold | Expected Timing | Expected Behavior |
|-----------|-----------------|-------------------|
| CAUTION (50%) | End of Phase 1 | Warning displayed |
| WARNING (70%) | Middle of Phase 3 | Consider MCP offload |
| CRITICAL (85%) | End of Phase 3 | Checkpoint triggered |

### Intentional Issues (for JICM to handle)

1. **Context Bloat**: Verbose output during tests should push toward threshold
2. **MCP Recommendation**: JICM should suggest disabling Tier 2 MCPs at WARNING
3. **Checkpoint Trigger**: Context pressure should force checkpoint before Phase 4

---

## Execution Protocol

### Pre-Execution Setup

**IMPORTANT**: Configure test mode thresholds:

1. Back up `autonomy-config.yaml`
2. Set lower thresholds for stress testing:
```yaml
jicm:
  enabled: true
  threshold_tokens: 100000  # 50% of 200k (more realistic than 35k)
```

### Phase 1: Pre-flight + Context Build (CAUTION Zone)

**Work**:
1. Read all 5 Phase 1 reference files (not summarize, full content)
2. Complete standard pre-flight checks
3. Environment verification
4. GitHub capability confirmation

**Context Stress**:
- Deliberately read full file contents
- Do NOT use summarization
- Track context estimate after each read

**Checkpoint**: CAUTION threshold expected (~50%)

**Verification**:
- [ ] Pre-flight checklist complete
- [ ] 5+ reference files read in full
- [ ] CAUTION threshold reached
- [ ] JICM warning displayed

---

### Phase 2: TDD Setup (Approaching WARNING)

**Work**:
1. Read 8 additional reference files
2. Create project structure
3. Write 53+ tests
4. Verify tests fail (TDD correct)

**Context Stress**:
- Read all test pattern references
- Include verbose test descriptions
- Generate extensive test comments

**Checkpoint**: WARNING threshold expected (~70%)

**Verification**:
- [ ] 53+ tests written
- [ ] Tests fail correctly (TDD)
- [ ] 13+ reference files now read
- [ ] WARNING threshold reached
- [ ] JICM MCP recommendation displayed

---

### Phase 3: Implementation (CRITICAL Zone → Checkpoint)

**Work**:
1. Read 10 implementation references
2. Implement transform.js
3. Implement app.js with routes
4. Implement index.html with UI
5. Run tests with VERBOSE output
6. Request full stack traces on errors

**Context Stress**:
- Maximum context loading
- Verbose test output
- Extensive code comments
- JICM should trigger checkpoint

**Forced Checkpoint**:
At 85% context (CRITICAL):
1. JICM triggers automatic checkpoint
2. MCP offload script executes (Tier 2)
3. Session requires `/clear` and restart

**Verification**:
- [ ] CRITICAL threshold reached
- [ ] Checkpoint created automatically
- [ ] MCP offload executed (Tier 2 disabled)
- [ ] Clear instruction provided

---

### Phase 4: Post-Checkpoint Validation

**Resume**:
1. Session start with checkpoint
2. Verify context restored
3. Verify Tier 1 MCPs only active
4. Continue from Phase 4

**Work**:
1. Run full test suite
2. All 53+ tests should pass
3. Manual browser verification
4. Screenshot captures

**Liftover Verification**:
- [ ] Essential context preserved (>95%)
- [ ] Todos intact
- [ ] Phase position correct
- [ ] Work continues without loss

**Verification**:
- [ ] All tests pass
- [ ] Manual verification successful
- [ ] Liftover accuracy >95%
- [ ] No redundant work

---

### Phase 5-7: Completion (Moderate Context)

**Work**:
1. Phase 5: README.md + ARCHITECTURE.md
2. Phase 6: Git init, GitHub create, push, tag
3. Phase 7: Generate reports

**Context Management**:
- Moderate loading only
- Should not hit WARNING again
- Complete delivery successfully

**Verification**:
- [ ] Documentation complete
- [ ] GitHub repo created
- [ ] Code pushed with v1.0.0 tag
- [ ] Reports generated

---

## JICM Behavior Validation

### CAUTION Level (50%)

- [ ] Yellow/caution indicator shown
- [ ] "Context at 50%" message
- [ ] Suggestion to monitor
- [ ] No automatic action

### WARNING Level (70%)

- [ ] Orange/warning indicator shown
- [ ] Tier 2 MCP disable suggestion
- [ ] `/context-budget` command suggested
- [ ] MCP status shown

### CRITICAL Level (85%)

- [ ] Red/critical indicator shown
- [ ] Automatic checkpoint creation
- [ ] MCP disable script execution
- [ ] Clear instruction to user

---

## MCP Tier Management

### Tier 1 (Always On — Keep Active)
- Memory MCP
- Git MCP
- Filesystem MCP
- Fetch MCP

### Tier 2 (Disable at WARNING)
- GitHub MCP
- Context7 MCP
- Sequential-Thinking MCP
- Local RAG MCP

### Verification Checklist
- [ ] `disable-mcps.sh` executed correctly
- [ ] MCP config updated
- [ ] Only Tier 1 MCPs active after checkpoint
- [ ] `enable-mcps.sh` available for restore

---

## Evaluation Criteria

### Deliverable Evaluation (50%)

| Criterion | Weight | Pass Criteria |
|-----------|--------|---------------|
| Tests pass | 15% | 53+ tests, 100% pass rate |
| App runs | 10% | `npm start` works, UI accessible |
| Functionality | 10% | All 4 operations work correctly |
| Documentation | 10% | README + ARCHITECTURE complete |
| GitHub delivery | 5% | Repo exists, code pushed, tagged |

### AC-04 Stress Evaluation (50%)

| Criterion | Weight | Pass Criteria |
|-----------|--------|---------------|
| CAUTION triggered | 10% | At ~50% with warning |
| WARNING triggered | 10% | At ~70% with MCP suggestion |
| CRITICAL triggered | 10% | At ~85% with auto-checkpoint |
| Checkpoint created | 5% | Valid structure |
| MCP offload executed | 5% | Tier 2 disabled |
| Liftover accurate | 5% | >95% essential preserved |
| Work completes | 5% | Despite context pressure |

---

## Test Metrics

| Metric | Target |
|--------|--------|
| Files read | 23+ |
| CAUTION threshold hit | Yes |
| WARNING threshold hit | Yes |
| CRITICAL threshold hit | Yes |
| Checkpoint created | Yes |
| MCP offload executed | Yes |
| Liftover accuracy | > 95% |
| Work completed | Yes |
| Final test count | 53+ |
| Final test pass rate | 100% |

---

## Validation Points

### AC-04 Specific Checks

| Test ID | Check | Pass Criteria |
|---------|-------|---------------|
| V4-01 | CAUTION triggered | At ~50% with display |
| V4-02 | WARNING triggered | At ~70% with MCP suggestion |
| V4-03 | CRITICAL triggered | At ~85% with checkpoint |
| V4-04 | Checkpoint created | Valid .checkpoint.md |
| V4-05 | MCPs disabled | Tier 2 only, Tier 1 active |
| V4-06 | Liftover accurate | > 95% essential context |
| V4-07 | Resume successful | Work continues correctly |
| V4-08 | Work completes | All phases done |

### Deliverable Checks

| Test ID | Check | Pass Criteria |
|---------|-------|---------------|
| D4-01 | Unit tests | 23+ pass |
| D4-02 | Integration tests | 9+ pass |
| D4-03 | E2E tests | 21+ pass |
| D4-04 | Manual verification | All operations work |
| D4-05 | README complete | All sections present |
| D4-06 | GitHub repo | Exists and accessible |
| D4-07 | Release tag | v1.0.0 exists |

---

## Success Criteria

### Overall Pass Requirements

1. **Deliverable Complete**: Working aion-hello-console app deployed to GitHub
2. **AC-04 Validated**: All 8 validation points pass
3. **Context Management Works**: JICM correctly detected and handled pressure
4. **Quality Met**: 53+ tests, 100% pass rate

### Final Score Calculation

```
Final Score = (Deliverable Score × 0.5) + (AC-04 Score × 0.5)

Deliverable Score = Σ(criterion_passed × weight) / total_weight × 100
AC-04 Score = Σ(criterion_passed × weight) / total_weight × 100
```

---

## Reports to Generate

1. **Run Report**: `projects/project-aion/reports/PRD-V4-run-report-YYYY-MM-DD.md`
   - Execution timeline with context levels
   - Threshold trigger points
   - Checkpoint details

2. **Deliverable Report**: `projects/project-aion/reports/PRD-V4-deliverable-report-YYYY-MM-DD.md`
   - Application functionality verification
   - Code quality assessment
   - GitHub delivery confirmation

3. **AC-04 Analysis**: `projects/project-aion/reports/PRD-V4-ac04-analysis-YYYY-MM-DD.md`
   - Context accumulation curve
   - JICM behavior at each threshold
   - Liftover accuracy metrics

---

## Post-Execution Cleanup

After PRD-V4 completes:
1. Restore original `autonomy-config.yaml` thresholds
2. Re-enable Tier 2 MCPs via `enable-mcps.sh`
3. Verify MCP configuration correct
4. Archive test artifacts

---

*PRD-V4 — Context Exhaustion Stress Test with Deliverable Generation*
*Produces: Working aion-hello-console-v4-context application*
