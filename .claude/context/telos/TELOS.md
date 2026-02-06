---
type: strategic-framework
version: 1.0.0
owner: Your Name
review-schedule: weekly-light, monthly-deep, quarterly-planning
last-review: 2026-01-20
next-review: 2026-01-27
status: active
---

# TELOS - Personal Direction Framework

**Last Updated**: 2026-01-20
**Review Schedule**: Weekly (light), Monthly (comprehensive), Quarterly (planning)

---

## Quick Reference

| Need | Section | Action |
|------|---------|--------|
| Check current focus | [This Quarter's Focus](#this-quarters-focus) | See Top 3 Goals |
| Review principles | [Design Principles](#design-principles) | Apply to decisions |
| Check blockers | [Goal Blockers](#goal-blockers--dependencies) | Unblock actions |
| Weekly review | [Operational Workflows](#operational-workflows) | 15-min checklist |
| Monthly review | [Operational Workflows](#operational-workflows) | 45-min deep review |
| Track metrics | [Metrics Dashboard](#metrics-dashboard) | Update trends |
| Strategic decisions | [Decision Log](#strategic-decisions) | Document trade-offs |

---

## Identity Statement

**Core Identity**: A technologist and creator focused on building systems that amplify human capability through thoughtful automation and AI augmentation.

**Key Values**:
- **Craftsmanship**: Build things well, with attention to detail and long-term maintainability
- **Leverage**: Create systems that multiply effort rather than just adding to it
- **Clarity**: Understand deeply before building; document for future self and others
- **Iteration**: Start simple, evolve based on real use, avoid over-engineering

---

## Cross-Domain Mission

**Ultimate Purpose**: Build reliable, self-improving systems that amplify human capability while minimizing operational overhead - infrastructure that teaches itself and teaches me.

**Why This Matters**: As AI transforms how we work, those who build effective personal infrastructure will thrive. The goal isn't just automation, but augmentation - becoming more capable, not more dependent.

---

## Active Domains

| Domain | Focus | Status | Primary Goal |
|--------|-------|--------|--------------|
| [Technical](domains/technical.md) | AI infrastructure, home lab, professional growth | Active | G-T1: Infrastructure Maturity |
| [Creative](domains/creative.md) | Writing, worldbuilding, creative projects | Active | G-C1: TBD |
| [Personal](domains/personal.md) | Health, family, personal development | Placeholder | - |

---

## This Quarter's Focus

**Quarter**: Q1 2026 (Jan-Mar)

**Theme**: Foundation & Reliability - Establish solid infrastructure and workflows before expanding capabilities

**Top 3 Goals**:
1. **G-T1**: AIProjects Infrastructure Maturity - 🟢 On Track
2. **G-T4**: Deterministic AI Architecture (Code before Prompts) - 🟢 On Track
3. **G-C1**: Creative Domain Definition - 🟡 Needs Definition

---

## Metrics Dashboard

Track progress toward quarterly metrics in real-time.

### Q1 2026 Metrics

| Metric | Target | Current | Trend | Last Updated |
|--------|--------|---------|-------|--------------|
| Infrastructure Docs Coverage | 100% | ~80% | 📈 | 2026-01-20 |
| Service Uptime | 95% | Unknown | ❓ | Not tracked yet |
| Session Productivity (time to productive) | <5 min | ~10-15 min | 📊 | 2026-01-20 |
| TELOS Goal Completion | 3 of 3 | 0 of 3 | 📊 | 2026-01-20 |

**Trend Indicators**:
- 📈 Improving
- 📊 Stable
- 📉 Declining
- ❓ Unknown/Not tracked

**Update Frequency**: Weekly during review workflow

---

## Goal Blockers & Dependencies

### Active Blockers

| Goal | Blocker | Type | Unblock Action | Owner |
|------|---------|------|----------------|-------|
| G-C1 | No clear definition | Clarity | Define creative domain scope | Self |

**Blocker Types**:
- **Dependency**: Waiting on another Goal
- **Clarity**: Needs definition/specification
- **External**: Waiting on third-party
- **Resource**: Time/tool/knowledge gap
- **Energy**: Motivation/focus needed

### Cleared Blockers Log

| Date | Goal | Blocker | Resolution |
|------|------|---------|------------|
| 2026-01-20 | G-T1 | Documentation clarity | Resolved via TELOS system creation |
| 2026-01-20 | G-T4 | Needs definition | Defined via code-before-prompts pattern and _template skill |

---

## Anti-Goals

What we explicitly choose NOT to do this quarter (prevents scope creep).

### Q1 2026 Anti-Goals

- ❌ **No new Docker services** until existing ones documented (G-T1)
- ❌ **No creative worldbuilding expansion** until domain defined (G-C1)
- ❌ **No advanced automation** before basic monitoring works (G-T1)
- ❌ **No tool sprawl** - consolidate before adding new tech
- ❌ **No over-engineering** - YAGNI principle applies

**Purpose**: Guard against shiny object syndrome and maintain focus on Top 3 Goals.

---

## Design Principles

These principles guide all work across domains:

### 1. Scaffolding > Model
The orchestration and structure around AI is more important than the model's raw intelligence. Invest in infrastructure.

### 2. Code Before Prompts
If something can be done deterministically in code, do it in code. Use AI for intelligence tasks, not routine operations.

### 3. Solve Once, Reuse Forever
Every problem solved should become a reusable module - a command, pattern, workflow, or tool. "I only solve a problem once."

### 4. Progressive Context
Load context on-demand rather than upfront. Keep token usage efficient while maintaining depth when needed.

### 5. Hub, Not Container
AIProjects orchestrates but doesn't contain. Code lives in ~/Code/, infrastructure in ~/Docker/. Clear separation.

### 6. Right Tool for the Job
Use the appropriate automation level for each task. See @.claude/context/patterns/agent-selection-pattern.md
- **Agents** for complex autonomous tasks
- **Skills** for multi-step guided workflows
- **Commands** for single repeatable actions
- **Manual** for strategic decisions and creative work

---

## Operational Workflows

### Weekly Review (15 min)

**When**: Every Monday or start of work week

- [ ] Run `/telos goals` - Check all goal statuses
- [ ] Update any newly at-risk or blocked goals
- [ ] Mark any goals ready for completion
- [ ] Run `/update-priorities review` - Validate alignment
- [ ] Note blockers in session-state.md if any
- [ ] Update Metrics Dashboard with current values

### Monthly Review (45 min)

**When**: First Monday of each month

- [ ] Review all metrics in Metrics Dashboard
- [ ] Update "Current" values and trends
- [ ] For each Goal, assess % complete
- [ ] Validate Goals still align with Mission
- [ ] Review problems in domain files
- [ ] Check bidirectional links are current
- [ ] Update Review Log with decisions
- [ ] Adjust timelines if needed
- [ ] Add to/retire from backlog as appropriate

### Quarterly Planning (2-3 hours)

**When**: End of quarter (March, June, September, December)

- [ ] Complete quarterly retrospective in each domain
- [ ] Archive achieved goals to `goals/archive/YYYY-QX.yaml`
- [ ] Retire goals no longer relevant
- [ ] Review and update Mission if needed
- [ ] Assess problem evolution (improved/worsened/new)
- [ ] Set next quarter theme
- [ ] Define Top 3 Goals with specific metrics
- [ ] Check domain balance (Technical vs Creative vs Personal)
- [ ] Update TELOS.md "This Quarter's Focus" section

---

## Integration with Tactical Priorities

**Flow**: TELOS Goals → current-priorities.md execution

- TELOS defines **strategic direction** (quarterly Goals)
- current-priorities.md defines **tactical execution** (weekly/monthly tasks)
- Weekly review validates priorities align with active Goals
- Monthly review updates TELOS based on priority progress

**Validation Commands**:
- `/telos goals` - Check goal statuses
- `/update-priorities review` - Validate tactical alignment
- `/orchestration:plan "task"` - Break complex Goal work into phases

### Pre-Work Checklist

Before starting significant work:

- [ ] Does this align with active Goals?
- [ ] Does this fit Mission and Principles?
- [ ] Would this violate any Anti-Goals?
- [ ] Apply PARC pattern if complex (see @.claude/context/patterns/prompt-design-review.md)

---

## Strategic Decisions

Document significant goal-level decisions with reasoning.

| Date | Decision | Rationale | Trade-Off | Status |
|------|----------|-----------|-----------|--------|
| 2026-01-20 | Create TELOS system | Need strategic direction above tactical priorities | Time investment in setup | Active |
| 2026-01-20 | Focus G-T1 before G-T4 | Foundation must be solid before architecture patterns | Delays deterministic patterns work | Active |
| 2026-01-20 | Creative domain placeholder | Technical infrastructure takes priority Q1 | Creative work less structured | Active |

**Decision Criteria**:
- Alignment with Mission
- Domain balance impact
- Resource constraints (time, energy, tools)
- Dependencies between Goals

---

## Review Log

**Review Model**: Use Opus for quarterly reviews, Sonnet for weekly reviews (see @.claude/context/standards/model-selection.md)

| Date | Type | Summary | Decisions |
|------|------|---------|-----------|
| 2026-01-20 | Initial | TELOS system created | Structure based on PAI comparison analysis |
| 2026-01-20 | Enhancement | Added agent recommendations | Operational workflows, metrics dashboard, blockers, anti-goals |

---

## Links

### Tactical Execution
- [Current Priorities](../projects/current-priorities.md) - Weekly/monthly tasks
- [Session State](../session-state.md) - Current work focus
- [Orchestration Plans](../../orchestration/) - Multi-phase task tracking

### Workflows & Patterns
- [TELOS Review Workflow](../workflows/telos-review.md) - Review procedures
- [PARC Pattern](../patterns/prompt-design-review.md) - Pre-work design review
- [Priority Validation](../workflows/priority-validation-workflow.md) - Evidence-based validation
- [Agent Selection](../patterns/agent-selection-pattern.md) - Right tool for the job

### Standards
- [Severity System](../standards/severity-status-system.md) - Blocker classification
- [Model Selection](../standards/model-selection.md) - When to use Opus/Sonnet/Haiku

### Source Analysis
- [PAI Enhancement Plan](../../planning/specs/2026-01-20-pai-inspired-enhancements.md) - TELOS inspiration
