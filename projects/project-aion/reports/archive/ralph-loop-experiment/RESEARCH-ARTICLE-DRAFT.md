# Recursive Self-Bootstrapping in AI Agents: A Controlled Experiment in Tiered Tool Construction

**Draft Version 0.1 | January 2026**

---

## Abstract

We present a controlled experiment demonstrating recursive self-bootstrapping capabilities in AI agents through a tiered tool construction methodology. Using Claude Code as our experimental platform, we constructed a three-tier system where Tier 1 (self-referential development loops) builds Tier 2 (reverse-engineering and integration tools), which in turn integrates Tier 3 (external open-source capabilities). We compared two parallel construction paths: one using an official external plugin and one using a natively-integrated version of the same capability. Our results show that both paths achieve 100% feature parity, with the native-built variant producing 24.3% less code while maintaining functional equivalence. These findings suggest that AI agents can successfully bootstrap their own capabilities through recursive tool construction, and that independent (blind) development may produce more efficient implementations than reference-based development.

**Keywords**: AI agents, self-improvement, recursive development, capability bootstrapping, Claude Code, autonomous systems

---

## 1. Introduction

### 1.1 Background

The development of AI agents capable of self-improvement represents a significant frontier in artificial intelligence research. Unlike traditional software development where human programmers extend system capabilities, self-improving agents can potentially identify, analyze, and integrate new capabilities autonomously.

Recent advances in large language model (LLM) based agents have enabled sophisticated code generation and modification capabilities. However, the question of whether these agents can systematically bootstrap their own tooling remains underexplored.

### 1.2 Research Questions

This study addresses four primary research questions:

**RQ1**: Can an AI agent use external tools to construct sophisticated internal capabilities?

**RQ2**: Can those internal capabilities then be used to construct equivalent tools?

**RQ3**: How do tools built through external versus internal pathways compare in quality and efficiency?

**RQ4**: What implications does recursive capability bootstrapping have for AI agent development?

### 1.3 Contributions

This paper makes the following contributions:

1. A novel three-tier framework for analyzing self-bootstrapping in AI agents
2. Empirical evidence demonstrating successful recursive capability construction
3. Comparative analysis of external versus internal tool construction pathways
4. Identification of efficiency gains in blind (independent) development

---

## 2. Methodology

### 2.1 Experimental Platform

Experiments were conducted using Jarvis, a Claude Code-based AI orchestration system, running on Claude Opus 4.5 (claude-opus-4-5-20251101). The experimental environment consisted of:

- Operating System: macOS Darwin 25.2.0
- Claude Code: Standard installation with plugin support
- Memory MCP: Enabled for persistent knowledge storage
- Git: Version control for artifact tracking

### 2.2 Tiered System Architecture

We define a three-tier architecture for capability analysis:

**Tier 1 - Self-Referential Development Loops**
Systems that enable iterative, self-correcting development through stop-hook interception and prompt re-injection. The agent works on a task until a completion promise is genuinely satisfied.

**Tier 2 - Reverse-Engineering and Integration Systems**
Tools that analyze, deconstruct, and integrate external capabilities into the native ecosystem. These tools can discover, review, analyze, plan, execute, and rollback integrations.

**Tier 3 - External Capability Ecosystem**
Open-source tools, plugins, skills, and agents available for integration. These represent the raw capabilities to be bootstrapped.

### 2.3 Experimental Design

We employed a controlled parallel construction experiment:

**Independent Variable**: Construction pathway
- Treatment A: Official external plugin (Tier 1) → Official-built (Tier 2)
- Treatment B: Native integrated (Tier 1) → Native-built (Tier 2)

**Controlled Variables**:
- Identical prompt specifications
- Identical target capabilities (9 features)
- Identical validation criteria
- Same test targets (example-plugin)

**Dependent Variables**:
- Lines of code produced
- Function count
- Feature completeness
- Test pass rate
- Bugs discovered during development

### 2.4 Blinding Protocol

To ensure valid comparison, we implemented strict blinding:

1. Official-built Tier 2 code was sealed in an archive before native construction began
2. Native-built Tier 2 was constructed without reference to the sealed code
3. Identical prompts were used for both construction paths
4. Independent validation was performed on each implementation

---

## 3. System Descriptions

### 3.1 Tier 1: Ralph Loop System

The Ralph Loop implements self-referential development through the following mechanism:

```
┌─────────────────────────────────────────────────────────┐
│                  RALPH LOOP MECHANISM                   │
├─────────────────────────────────────────────────────────┤
│                                                         │
│    ┌──────────┐    Stop Hook    ┌──────────────────┐   │
│    │  Agent   │ ──attempts───▶  │  Intercept Exit  │   │
│    │  Works   │     exit        │  Check Promise   │   │
│    └────▲─────┘                 └────────┬─────────┘   │
│         │                                │             │
│         │                        ┌───────▼───────┐     │
│         │                        │ Promise TRUE? │     │
│         │                        └───────┬───────┘     │
│         │                           │         │        │
│         │                          No        Yes       │
│         │                           │         │        │
│         │                           ▼         ▼        │
│    ┌────┴─────┐              ┌──────────┐ ┌────────┐   │
│    │ Re-inject│◀─────────────│Increment │ │  EXIT  │   │
│    │  Prompt  │              │Iteration │ │  LOOP  │   │
│    └──────────┘              └──────────┘ └────────┘   │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

**Figure 1**: Ralph Loop mechanism showing stop-hook interception and prompt re-injection.

#### 3.1.1 Official Implementation

The Official Ralph Loop exists as an external plugin requiring explicit namespace invocation (`/ralph-loop:ralph-loop`). Key limitations include:
- Cannot be autonomously invoked by the agent
- Requires plugin installation and maintenance
- Uses plugin-relative paths (`${CLAUDE_PLUGIN_ROOT}`)

#### 3.1.2 Native Implementation

The Native Ralph Loop is integrated directly into the Jarvis ecosystem. Key advantages include:
- Can be self-invoked during autonomous task planning
- No external dependencies
- Uses project-relative paths (`$CLAUDE_PROJECT_DIR`)

### 3.2 Tier 2: Decompose Tool System

The Decompose Tool provides nine capabilities for reverse-engineering and integration:

| Feature | Description |
|---------|-------------|
| `--discover` | Locate plugins by name or path |
| `--review` | Analyze plugin structure and components |
| `--analyze` | Classify components for integration |
| `--scan-redundancy` | Compare against existing codebase |
| `--decompose` | Generate integration plan |
| `--browse` | Interactive plugin browser |
| `--execute` | Perform actual integration |
| `--dry-run` | Preview changes without executing |
| `--rollback` | Undo previous integration |

```
┌─────────────────────────────────────────────────────────────┐
│                DECOMPOSE TOOL WORKFLOW                       │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌──────────┐     ┌──────────┐     ┌───────────┐            │
│  │ DISCOVER │ ──▶ │  REVIEW  │ ──▶ │  ANALYZE  │            │
│  └──────────┘     └──────────┘     └─────┬─────┘            │
│       Find            Examine          Classify              │
│      plugin          structure       components              │
│                                          │                   │
│                                          ▼                   │
│  ┌──────────┐     ┌──────────┐     ┌───────────┐            │
│  │ ROLLBACK │ ◀── │ EXECUTE  │ ◀── │ DECOMPOSE │            │
│  └──────────┘     └──────────┘     └───────────┘            │
│     Undo if          Perform          Generate               │
│     needed          integration         plan                 │
│                         │                                    │
│                         ▼                                    │
│               ┌─────────────────┐                            │
│               │   INTEGRATED    │                            │
│               │   CAPABILITY    │                            │
│               └─────────────────┘                            │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

**Figure 2**: Decompose Tool workflow from discovery to integration.

---

## 4. Experimental Procedure

### 4.1 Phase 1: Construct Official-Built Tier 2

Using the Official Ralph Loop plugin, we constructed the first Decompose Tool implementation (Decompose-Official).

**Prompt**: Detailed specification for 6 initial features, followed by enhancement prompt for 3 additional features (see Appendix A).

**Process**:
1. Ralph loop activated with 15-iteration limit
2. Agent developed features iteratively
3. All features validated against example-plugin
4. Enhancement loop added --execute, --dry-run, --rollback
5. Final validation: 9/9 features passing

### 4.2 Phase 2A: Bootstrap Native Tier 1

Using Decompose-Official, we integrated the Ralph Loop plugin into Jarvis as a native capability.

**Components Integrated**: 6 (commands, hooks, scripts)
**Manual Fixes Required**: 2 (path variable translation, hook registration)

### 4.3 Phase 2B: Seal Official-Built Code

Decompose-Official source code was archived to prevent cross-contamination:
```
projects/project-aion/experiments/ralph-loop-comparison/decompose-official-sealed/
```

### 4.4 Phase 3: Construct Native-Built Tier 2

Using the Native Ralph Loop, we constructed the second Decompose Tool implementation (Decompose-Native) using identical prompts.

**Critical Constraint**: No reference to sealed Decompose-Official code.

**Process**:
1. Native ralph loop activated with identical prompts
2. Agent developed features independently
3. Bug discovered and fixed (empty array handling)
4. Enhancement loop completed
5. Final validation: 9/9 features passing

### 4.5 Phase 4-5: Validation and Integration Testing

Both Tier 2 implementations were validated with identical test suites and used to integrate example-plugin from the Claude Code marketplace.

---

## 5. Results

### 5.1 Quantitative Comparison

```
┌─────────────────────────────────────────────────────────────┐
│              CODE METRICS COMPARISON                         │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  Lines of Code                                               │
│  ═══════════════════════════════════════════════            │
│                                                              │
│  Official-Built  ████████████████████████████████  1817     │
│  Native-Built    █████████████████████████         1375     │
│                                                              │
│  Difference: -442 lines (-24.3%)                             │
│                                                              │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  Component Breakdown                                         │
│  ───────────────────                                         │
│                                                              │
│  Main Script:  Official 1467 │ Native 1151  │ Δ -316        │
│  Command File: Official  151 │ Native   98  │ Δ  -53        │
│  SKILL.md:     Official  199 │ Native  126  │ Δ  -73        │
│                                                              │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  Functional Metrics (Identical)                              │
│  ───────────────────────────────                             │
│                                                              │
│  Functions:     16 = 16                                      │
│  Features:       9 = 9                                       │
│  Test Pass:   100% = 100%                                    │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

**Figure 3**: Code metrics comparison between Official-Built and Native-Built implementations.

### 5.2 Feature Parity Analysis

| Feature | Official-Built | Native-Built | Match |
|---------|----------------|--------------|-------|
| --discover | PASS | PASS | ✓ |
| --review | PASS | PASS | ✓ |
| --analyze | PASS | PASS | ✓ |
| --scan-redundancy | PASS | PASS | ✓ |
| --decompose | PASS | PASS | ✓ |
| --browse | PASS | PASS | ✓ |
| --execute | PASS | PASS | ✓ |
| --dry-run | PASS | PASS | ✓ |
| --rollback | PASS | PASS | ✓ |

**Result**: 100% feature parity achieved.

### 5.3 Function Comparison

Both implementations defined 16 functions with near-identical names:

| Official-Built | Native-Built |
|----------------|--------------|
| print_header() | print_header() |
| print_section() | print_section() |
| print_success() | print_success() |
| print_warning() | print_warning() |
| print_error() | print_error() |
| print_info() | print_info() |
| usage() | usage() |
| discover_plugin() | discover_plugin() |
| review_plugin() | review_plugin() |
| analyze_plugin() | analyze_plugin() |
| scan_redundancy() | scan_redundancy() |
| decompose_plugin() | decompose_plugin() |
| browse_plugins() | browse_plugins() |
| execute_plugin() | execute_integration() |
| rollback_plugin() | rollback_integration() |
| main() | main() |

**Notable Difference**: Function naming convention for execute/rollback functions.

### 5.4 Bug Discovery

| Implementation | Bugs Found | Bugs Fixed |
|----------------|------------|------------|
| Official-Built | 0 | 0 |
| Native-Built | 1 | 1 |

The Native-Built implementation discovered and fixed an empty array iteration bug in the `--scan-redundancy` function. This represents a quality advantage of independent development—the blind build surfaced an edge case that the reference-based build missed.

### 5.5 Integration Results

Both Tier 2 implementations successfully integrated external plugins:

| Metric | Official-Built | Native-Built |
|--------|----------------|--------------|
| Integration Target | ralph-loop | example-plugin |
| Components | 6 | 2 |
| Success Rate | 100% | 100% |
| Manual Fixes | 2 | 0 |

---

## 6. Discussion

### 6.1 Hypothesis Evaluation

**H1**: "A tool built using Jarvis-native ralph-loop (Decompose-Native) will achieve feature parity with a tool built using the Official ralph-loop plugin (Decompose-Official), demonstrating successful capability bootstrapping."

**Result**: CONFIRMED. Both implementations achieved 100% feature parity with identical test pass rates.

### 6.2 Efficiency of Blind Development

The 24.3% code reduction in the native-built variant suggests that independent development may produce more efficient implementations. Possible explanations include:

1. **Cognitive Load Reduction**: Without reference code to follow, the agent may have focused more directly on requirements.
2. **Fresh Design Decisions**: Independent development allowed novel architectural choices.
3. **Implicit Learning**: The agent may have internalized patterns from the first build that led to more concise solutions.

### 6.3 Autonomy Implications

The key difference between Official and Native Tier 1 systems lies in autonomy:

```
┌─────────────────────────────────────────────────────────────┐
│                    AUTONOMY SPECTRUM                         │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ◀─────────────────────────────────────────────────────────▶│
│  LOW AUTONOMY                               HIGH AUTONOMY    │
│                                                              │
│  ┌─────────────┐                      ┌─────────────┐       │
│  │  Official   │                      │   Native    │       │
│  │ Ralph-Loop  │                      │ Ralph-Loop  │       │
│  ├─────────────┤                      ├─────────────┤       │
│  │ • User-only │                      │ • Self-     │       │
│  │   invoke    │                      │   invocable │       │
│  │ • External  │                      │ • Integrated│       │
│  │   depend.   │                      │ • Autonomous│       │
│  └─────────────┘                      └─────────────┘       │
│                                                              │
│        │                                      │              │
│        ▼                                      ▼              │
│  Agent cannot                         Agent can              │
│  self-initiate                        self-initiate          │
│  development                          development            │
│  loops                                loops                   │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

**Figure 4**: Autonomy comparison between Official and Native Tier 1 implementations.

### 6.4 Recursive Self-Improvement Pathway

This experiment validates a pathway for recursive self-improvement:

```
External Tool (Tier 3)
        │
        ▼
Tier 2 Decompose → Analyze → Integrate
        │
        ▼
Native Capability (becomes available)
        │
        ▼
Tier 1 Loop → Builds new Tier 2
        │
        ▼
New Tier 2 → Integrates more Tier 3
        │
        ▼
    ... (recursive)
```

**Figure 5**: Recursive self-improvement pathway through tiered tool construction.

---

## 7. Limitations

1. **Sample Size**: N=1 for each construction pathway. Additional experiments needed for statistical significance.

2. **Single Model**: All experiments used Claude Opus 4.5. Different models may produce different results.

3. **Sequential Bias**: Native construction followed Official construction, potentially introducing implicit learning effects.

4. **Prompt Design**: The agent participated in prompt design, which may have introduced bias.

5. **Single Test Target**: Only example-plugin was used for integration validation.

---

## 8. Conclusions

This study demonstrates that AI agents can successfully bootstrap their capabilities through recursive tool construction. Key findings include:

1. **Capability Bootstrapping Works**: An agent can use external tools to build internal capabilities, then use those to build equivalent tools.

2. **Feature Parity Achievable**: Both construction pathways produced functionally equivalent tools with 100% test pass rates.

3. **Blind Builds May Be Superior**: Independent development produced 24.3% less code while maintaining feature parity.

4. **Autonomy Enables Recursion**: Native integration enables self-invocation, which is critical for autonomous recursive improvement.

5. **Self-Improvement Pathway Validated**: The Tier 1 → Tier 2 → Tier 3 integration workflow provides a viable mechanism for ecosystem expansion.

---

## 9. Future Work

1. **Multi-Integration Study**: Test Tier 2 systems on multiple Tier 3 targets to validate consistency.

2. **Cross-Model Comparison**: Compare construction pathways across different LLM models.

3. **Bug Repair Capability**: Test whether Tier 2 can identify and repair buggy Tier 3 systems.

4. **Long-term Evolution**: Track tool quality over multiple recursive improvement cycles.

5. **Token Efficiency**: Analyze token consumption differences between construction pathways.

---

## References

[To be added in final version]

---

## Appendix A: Complete Prompts

[See data/prompts-used.md]

## Appendix B: Code Metrics

[See data/code-metrics.txt]

## Appendix C: Test Results

[See data/test-results.md]

---

*Draft generated: 2026-01-17*
*Status: Rough draft requiring peer review and additional experiments*
