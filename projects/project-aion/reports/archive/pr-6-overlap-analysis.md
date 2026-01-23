# PR-6 Overlap Analysis

**Generated**: 2026-01-07 (Revised with browser-automation)
**Purpose**: Map plugin capabilities against existing hooks, MCPs, and custom agents

---

## Component Inventory

### Plugins (17 total)

| Source | Plugin | Primary Function |
|--------|--------|------------------|
| claude-code-plugins | agent-sdk-dev | Agent SDK project validation |
| claude-code-plugins | code-review | PR code review with multi-agent |
| claude-code-plugins | explanatory-output-style | Educational output mode |
| claude-code-plugins | feature-dev | 7-phase feature development |
| claude-code-plugins | frontend-design | UI design guidance |
| claude-code-plugins | hookify | Create hooks from conversation |
| claude-code-plugins | learning-output-style | Interactive learning mode |
| claude-code-plugins | plugin-dev | Plugin creation toolkit |
| claude-code-plugins | pr-review-toolkit | Specialized PR review agents |
| claude-code-plugins | ralph-wiggum | Autonomous iteration loops |
| claude-code-plugins | security-guidance | Security pattern monitoring |
| mhattingpete | code-operations-skills | Bulk code operations |
| mhattingpete | engineering-workflow-skills | Git, testing, planning |
| mhattingpete | productivity-skills | Project bootstrap, auditing |
| mhattingpete | visual-documentation-skills | Diagrams, dashboards, timelines |
| anthropic-agent-skills | document-skills | Word/PDF/Excel/PPT generation |
| browser-tools | browser-automation | NL web browser automation (Stagehand) |

### Hooks (18 total)

| Category | Hook | Purpose |
|----------|------|---------|
| Lifecycle | session-start | Auto-load context |
| Lifecycle | session-stop | Desktop notification |
| Lifecycle | subagent-stop | Agent completion handling |
| Lifecycle | pre-compact | Preserve context |
| Lifecycle | self-correction-capture | Capture corrections |
| Lifecycle | worktree-manager | Track git worktrees |
| Guardrail | workspace-guard | Block forbidden paths |
| Guardrail | dangerous-op-guard | Block destructive commands |
| Guardrail | permission-gate | Soft gate policy-crossing |
| Security | secret-scanner | Block secret commits |
| Observability | audit-logger | Log tool executions |
| Observability | session-tracker | Track session lifecycle |
| Observability | session-exit-enforcer | Track activity for exit |
| Observability | context-reminder | Prompt for docs |
| Observability | docker-health-check | Verify container health |
| Observability | memory-maintenance | Track entity access |
| Documentation | doc-sync-trigger | Suggest sync after changes |
| Utility | project-detector | Detect GitHub URLs |

### Custom Agents (4 total)

| Agent | Purpose |
|-------|---------|
| deep-research | Multi-source technical research |
| docker-deployer | Guided Docker deployment |
| memory-bank-synchronizer | Sync docs with code changes |
| service-troubleshooter | Systematic service diagnosis |

---

## Overlap Analysis

### Category 1: Security Monitoring

| Component | Type | Function |
|-----------|------|----------|
| `security-guidance` | Plugin | Monitor 9 security patterns (injection, unsafe ops) |
| `secret-scanner` | Hook | Block commits with secrets |
| `dangerous-op-guard` | Hook | Block destructive shell commands |

**Overlap Level**: LOW (Complementary)
- `security-guidance`: Guidance and warnings during development
- `secret-scanner`: Hard block at commit time
- `dangerous-op-guard`: Hard block on shell commands

**Resolution**: KEEP ALL - defense in depth

---

### Category 2: Code Review

| Component | Type | Function |
|-----------|------|----------|
| `code-review` | Plugin | Multi-agent PR review with confidence scoring |
| `pr-review-toolkit` | Plugin | Specialized agents (silent failure, type design, etc.) |

**Overlap Level**: HIGH (Same domain)
- `code-review`: General PR review (1 skill: `/code-review`)
- `pr-review-toolkit`: Specialized review agents (7 agents)

**Resolution**: `pr-review-toolkit` is superset. Use `code-review` for quick reviews, `pr-review-toolkit` for comprehensive analysis.

**Selection Rule**:
- Quick review needed → `/code-review:code-review`
- Thorough PR review → `/pr-review-toolkit:review-pr`

---

### Category 3: Git Workflow

| Component | Type | Function |
|-----------|------|----------|
| `engineering-workflow-skills:git-pushing` | Plugin | Natural language git ops |
| `commit-commands` (orphaned) | Plugin | Explicit `/commit`, `/commit-push-pr` |
| Built-in git tools | Core | `Bash(git *)` |

**Overlap Level**: MEDIUM
- `git-pushing`: Conversational ("push these changes")
- `commit-commands`: Command-based (`/commit`)

**Resolution**: `git-pushing` sufficient for most cases. `commit-commands` would add `/clean_gone` for branch cleanup.

**Selection Rule**:
- Natural flow → git-pushing skill
- Explicit control → Bash(git) directly

---

### Category 4: Feature Development

| Component | Type | Function |
|-----------|------|----------|
| `feature-dev` | Plugin | 7-phase structured development |
| `engineering-workflow-skills:feature-planning` | Plugin | Plan + hand off to plan-implementer |
| `Plan` | Built-in Subagent | Design implementation strategy |

**Overlap Level**: HIGH
- `feature-dev`: Comprehensive workflow with specialized agents
- `feature-planning`: Simpler planning + execution
- `Plan`: One-shot architectural planning

**Resolution**: Use based on complexity:

**Selection Rule**:
- Quick feature → `feature-planning` skill
- Complex feature → `feature-dev` plugin
- Architecture only → `Plan` subagent

---

### Category 5: Hook Creation

| Component | Type | Function |
|-----------|------|----------|
| `hookify` | Plugin | Create hooks from conversation analysis |
| `self-correction-capture` | Hook | Capture corrections as lessons |

**Overlap Level**: LOW (Different purposes)
- `hookify`: Proactive hook creation
- `self-correction-capture`: Passive learning capture

**Resolution**: KEEP BOTH - `hookify` creates prevention, `self-correction-capture` learns from mistakes

---

### Category 6: Documentation Generation

| Component | Type | Function |
|-----------|------|----------|
| `document-skills` | Plugin | Word/PDF/Excel/PPT generation |
| `visual-documentation-skills` | Plugin | Diagrams, dashboards, flowcharts |
| `memory-bank-synchronizer` | Agent | Sync docs with code changes |
| `doc-sync-trigger` | Hook | Suggest sync after 5+ changes |

**Overlap Level**: LOW (Complementary)
- `document-skills`: Office document generation
- `visual-documentation-skills`: Visual artifacts
- `memory-bank-synchronizer`: Markdown sync
- `doc-sync-trigger`: Automation trigger

**Resolution**: KEEP ALL - different output formats

**Selection Rule**:
- Office docs → `document-skills`
- Diagrams/visuals → `visual-documentation-skills`
- Markdown sync → `memory-bank-synchronizer`

---

### Category 7: Research

| Component | Type | Function |
|-----------|------|----------|
| `deep-research` | Agent | Multi-source research with citations |
| `productivity-skills:codebase-documenter` | Plugin | Generate codebase documentation |
| `Explore` | Built-in Subagent | Fast codebase exploration |

**Overlap Level**: MEDIUM
- `deep-research`: External research (web, docs)
- `codebase-documenter`: Internal documentation
- `Explore`: Quick codebase queries

**Resolution**: Different targets:

**Selection Rule**:
- External topic research → `deep-research`
- Codebase understanding → `Explore` or `codebase-documenter`

---

### Category 8: Output Styles

| Component | Type | Function |
|-----------|------|----------|
| `explanatory-output-style` | Plugin | Educational insights |
| `learning-output-style` | Plugin | Interactive code contributions |

**Overlap Level**: HIGH (Same system)
- Both modify output behavior
- Only one active at a time

**Resolution**: Choose based on session goal:

**Selection Rule**:
- Learning mode → `learning-output-style`
- Teaching mode → `explanatory-output-style`
- Normal work → Neither (default style)

**Current State**: Both appear enabled in session hints

---

### Category 9: Autonomous Operation

| Component | Type | Function |
|-----------|------|----------|
| `ralph-wiggum` | Plugin | Autonomous iteration loops |
| `workspace-guard` | Hook | Block operations outside boundaries |
| `dangerous-op-guard` | Hook | Block destructive commands |

**Overlap Level**: LOW (Complementary)
- `ralph-wiggum`: Enables autonomy
- Guards: Constrain autonomy safely

**Resolution**: KEEP ALL - `ralph-wiggum` for capability, guards for safety

---

### Category 10: Browser Automation

| Component | Type | Function |
|-----------|------|----------|
| `browser-automation` | Plugin | Natural language browser control via Stagehand |
| `Playwright MCP` | MCP (PR-8) | Programmatic browser automation API |
| `WebFetch` | Built-in | Fetch web content (read-only, no interaction) |
| `WebSearch` | Built-in | Search the web (results only) |

**Overlap Level**: MEDIUM (Complementary approaches)
- `browser-automation`: Natural language → AI interprets → browser actions
- `Playwright MCP`: Direct API calls → precise control
- `WebFetch`/`WebSearch`: Content retrieval only, no interaction

**Resolution**: Different use cases:

**Selection Rule**:
- Simple web content retrieval → `WebFetch` / `WebSearch`
- Natural language browsing tasks → `browser-automation`
- Deterministic automation scripts → Playwright MCP
- QA testing with precise assertions → Playwright MCP
- Interactive logged-in sessions → `browser-automation` (with caution)

**Risk Note**: `browser-automation` has higher risk profile due to:
- Browser session access to logged-in accounts
- AI interpretation may produce unexpected actions
- Network operations outside workspace guardrails

---

## Summary: Overlap Resolutions

| Category | Resolution | Primary Tool | Fallback |
|----------|------------|--------------|----------|
| Security | Keep all | security-guidance (advice) | Hooks (enforcement) |
| Code Review | Specialize | pr-review-toolkit (thorough) | code-review (quick) |
| Git Workflow | Simplify | git-pushing skill | Bash(git) |
| Feature Dev | Tier by complexity | feature-dev (complex) | feature-planning (simple) |
| Hook Creation | Keep both | hookify (create) | self-correction-capture (learn) |
| Documentation | Keep all | By output format | - |
| Research | By target | deep-research (external) | Explore (internal) |
| Output Styles | Mutual exclusive | Choose per session | Default |
| Autonomy | Keep all | ralph-wiggum + guards | - |
| Browser | By abstraction | browser-automation (NL) | Playwright MCP (programmatic) |

---

## Recommendations

### High-Value Plugins (Keep, Document)
1. **pr-review-toolkit** — Comprehensive review capability
2. **feature-dev** — Structured development workflow
3. **hookify** — Unique hook creation from patterns
4. **ralph-wiggum** — Enables autonomous loops
5. **document-skills** — Office document generation
6. **visual-documentation-skills** — Diagrams and visuals

### Redundant but Useful (Keep, Lower Priority)
1. **code-review** — Simpler alternative to pr-review-toolkit
2. **engineering-workflow-skills** — Overlaps but conversational

### Output Style Plugins (Configure, Don't Stack)
1. **explanatory-output-style** — Educational mode
2. **learning-output-style** — Interactive mode
   - Note: Currently both seem enabled which may cause conflicts

### Browser Automation (Use with Caution)
1. **browser-automation** — Natural language browser control
   - Higher risk profile than other plugins
   - Requires Chrome dependency
   - Guardrails don't cover browser session actions
   - Use Playwright MCP for deterministic automation

### Consider Installing (Not Currently Present)
1. **commit-commands** — Adds `/clean_gone` for branch cleanup
2. **claude-opus-4-5-migration** — Model migration assistance

---

## Action Items

1. [x] Document selection rules in capability-matrix.md
2. [ ] Verify output style configuration (should be mutually exclusive)
3. [ ] Decide on commit-commands installation (for `/clean_gone`)
4. [x] Update CLAUDE.md with plugin guidance
5. [ ] Add browser-automation risk documentation to guardrails

---

*Generated for PR-6: Plugins Expansion (Revised 2026-01-07)*
