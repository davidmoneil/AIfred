# Core Tooling Capability Matrix

**Created**: 2026-01-06
**PR Reference**: PR-5 (Core Tooling Baseline)
**Status**: Active

---

## Purpose

This document maps task types to preferred tools, providing clear selection guidance for when to use which mechanism: MCP servers, Claude Code plugins, skills, built-in subagents, or bash commands.

---

## Task Type → Tool Selection Matrix

### File Operations

| Task | Primary Tool | Fallback | Notes |
|------|--------------|----------|-------|
| Read file | `Read` (built-in) | `Bash(cat)` | Built-in is faster, respects permissions |
| Write file | `Write` (built-in) | `Bash(echo >)` | Built-in tracks changes |
| Edit file | `Edit` (built-in) | `Bash(sed)` | Built-in has context awareness |
| Search files by name | `Glob` (built-in) | `Bash(find)` | Glob is optimized |
| Search file contents | `Grep` (built-in) | `Bash(rg/grep)` | Grep is integrated |
| List directory | `Bash(ls)` | Filesystem MCP | Built-in sufficient |
| External file access | Filesystem MCP | N/A | When outside workspace |

### Git Operations

| Task | Primary Tool | Fallback | Notes |
|------|--------------|----------|-------|
| Git status/log/diff | `Bash(git)` | Git MCP | Bash is simpler |
| Commit (simple) | `Bash(git commit)` | Git MCP | Bash for single commits |
| Commit (multi-file) | `/commit` plugin | Git MCP | Plugin handles staging |
| PR creation | GitHub MCP / `gh` | `Bash(gh)` | MCP for complex workflows |
| Branch management | `Bash(git)` | Git MCP | Bash is sufficient |

### Web/Research Operations

| Task | Primary Tool | Fallback | Notes |
|------|--------------|----------|-------|
| Fetch web page | `WebFetch` (built-in) | Fetch MCP | Built-in converts to markdown |
| Web search | `WebSearch` (built-in) | DuckDuckGo MCP | Built-in is integrated |
| Deep research | `deep-research` agent | WebSearch + WebFetch | Agent for multi-source synthesis |
| API calls | `Bash(curl)` | Fetch MCP | Bash for full control |

### Browser Automation Operations

| Task | Primary Tool | Fallback | Notes |
|------|--------------|----------|-------|
| NL browser tasks | `browser-automation` plugin | Playwright MCP | NL-first, AI-interpreted |
| Programmatic automation | Playwright MCP | browser-automation | Precise control, deterministic |
| Form filling | `browser-automation` plugin | Playwright MCP | NL more intuitive |
| Web scraping | `browser-automation` plugin | WebFetch + parsing | Interactive content needs browser |
| QA testing | Playwright MCP | browser-automation | Assertions need determinism |
| Screenshots | Playwright MCP | browser-automation | Both support screenshots |
| Logged-in sessions | `browser-automation` plugin | N/A | Uses Chrome profile (caution) |

### GitHub Operations

| Task | Primary Tool | Fallback | Notes |
|------|--------------|----------|-------|
| View issues/PRs | `Bash(gh)` | GitHub MCP | CLI is quick |
| Create PR | `Bash(gh pr create)` | GitHub MCP | CLI for standard PRs |
| Complex automation | GitHub MCP | `Bash(gh)` | MCP for multi-step workflows |
| Code security scan | GitHub MCP | N/A | MCP-only feature |

### Code Exploration & Understanding

| Task | Primary Tool | Fallback | Notes |
|------|--------------|----------|-------|
| Quick file search | `Glob` + `Grep` | Explore subagent | Direct tools for targeted search |
| Codebase exploration | `Explore` subagent | `Task` with general-purpose | Subagent preserves context |
| Architecture analysis | `Plan` subagent | Explore + Read | Plan for design decisions |
| Feature tracing | `code-explorer` agent | Explore subagent | Plugin agent for depth |

### Development Workflows

| Task | Primary Tool | Fallback | Notes |
|------|--------------|----------|-------|
| Feature development | `feature-dev` plugin | Manual phases | Plugin provides structure |
| Code review | `code-review` plugin | Manual review | Plugin runs parallel agents |
| PR review | `pr-review-toolkit` | `code-review` | Toolkit for comprehensive review |
| Plugin creation | `plugin-dev` plugin | Manual | Plugin scaffolds new plugins |

### Document Generation

| Task | Primary Tool | Fallback | Notes |
|------|--------------|----------|-------|
| Word documents | `docx` skill | Manual + python-docx | Skill handles formatting |
| PDF generation | `pdf` skill | Manual + reportlab | Skill has templates |
| Spreadsheets | `xlsx` skill | Manual + openpyxl | Skill handles formulas |
| Presentations | `pptx` skill | Manual + python-pptx | Skill handles styling |

### Infrastructure & Docker

| Task | Primary Tool | Fallback | Notes |
|------|--------------|----------|-------|
| Docker operations | `Bash(docker)` | Docker MCP | Bash for direct control |
| Service discovery | `docker-deployer` agent | Manual | Agent for guided deployment |
| Troubleshooting | `service-troubleshooter` | Manual diagnosis | Agent for systematic approach |

### Time & Memory

| Task | Primary Tool | Fallback | Notes |
|------|--------------|----------|-------|
| Get current time | Time MCP | `Bash(date)` | MCP for timezone handling |
| Store decision | Memory MCP | Context files | MCP for relationships |
| Cross-session recall | Memory MCP | Context files | MCP is persistent |

---

## Tool Category Reference

### Built-in Tools (Always Available)

| Tool | Purpose | Token Cost |
|------|---------|------------|
| `Read` | Read files | ~0 (results only) |
| `Write` | Write files | ~0 (results only) |
| `Edit` | Edit files | ~0 (results only) |
| `Glob` | File pattern search | ~0 |
| `Grep` | Content search | ~0 |
| `Bash` | Shell commands | ~0 |
| `WebFetch` | Fetch web content | ~0 |
| `WebSearch` | Search the web | ~0 |
| `Task` | Spawn subagents | ~0 (subagent has own context) |
| `TodoWrite` | Task tracking | ~0 |

### Built-in Subagents

| Subagent | Purpose | When to Use |
|----------|---------|-------------|
| `Explore` | Codebase exploration | Open-ended search, architecture understanding |
| `Plan` | Implementation planning | Design decisions, multi-file changes |
| `claude-code-guide` | Documentation lookup | Claude Code/SDK questions |
| `general-purpose` | Full capability | Complex multi-step tasks |

### MCP Servers (Stage 1 - Core)

| Server | Purpose | Token Cost | Loading Strategy |
|--------|---------|------------|------------------|
| Memory | Knowledge graph | ~8-15K | Always-On |
| Filesystem | File operations | ~8K | On-Demand |
| Fetch | Web content | ~5K | On-Demand |
| Time | Timezone handling | ~3K | On-Demand |
| Git | Git operations | ~6K | On-Demand |
| GitHub | GitHub platform | ~15K | On-Demand |
| Sequential Thinking | Problem decomposition | ~5K | On-Demand |

### Claude Code Plugins (PR-6 Evaluated)

#### Official Plugins (claude-code-plugins)

| Plugin | Purpose | Decision | When to Use |
|--------|---------|----------|-------------|
| `agent-sdk-dev` | Agent SDK development | ADOPT | Creating/validating Agent SDK apps |
| `code-review` | Quick code review | ADAPT | Lightweight reviews (use pr-review-toolkit for thorough) |
| `explanatory-output-style` | Educational insights | ADAPT | Teaching mode (mutually exclusive with learning) |
| `feature-dev` | Feature development | ADOPT | Complex multi-phase features |
| `frontend-design` | UI design guidance | ADOPT | Building web interfaces |
| `hookify` | Hook creation | ADOPT | Creating prevention hooks from patterns |
| `learning-output-style` | Interactive contributions | ADAPT | Learning by doing (mutually exclusive with explanatory) |
| `plugin-dev` | Plugin development | ADOPT | Creating new plugins |
| `pr-review-toolkit` | Comprehensive PR review | ADOPT | Thorough PR reviews (7 specialized agents) |
| `ralph-wiggum` | Autonomous loops | ADOPT | "Keep going until done" workflows |
| `security-guidance` | Security monitoring | ADOPT | All development (defense in depth) |

#### Community Skills (mhattingpete-claude-skills)

| Plugin | Purpose | Decision | When to Use |
|--------|---------|----------|-------------|
| `code-operations-skills` | Bulk code operations | ADOPT | Renaming, pattern replacement across files |
| `engineering-workflow-skills` | Git, testing, planning | ADOPT | Natural language workflows ("push changes") |
| `productivity-skills` | Project bootstrap, audit | ADOPT | New projects, code quality audits |
| `visual-documentation-skills` | Diagrams, dashboards | ADOPT | Architecture diagrams, flowcharts, timelines |

#### Document Skills (anthropic-agent-skills)

| Plugin | Purpose | Decision | When to Use |
|--------|---------|----------|-------------|
| `document-skills` | Office documents | ADOPT | Word, PDF, Excel, PowerPoint generation |

#### Browser Automation (browser-tools)

| Plugin | Purpose | Decision | When to Use |
|--------|---------|----------|-------------|
| `browser-automation` | NL browser control | ADAPT | Natural language web tasks, scraping, form filling (caution with auth) |

### Skills (PR-7 Evaluated)

#### Document Skills (document-skills plugin)

| Skill | Purpose | When to Use |
|-------|---------|-------------|
| `docx` | Word documents | Creating/editing .docx files |
| `pdf` | PDF documents | Generating PDFs, extracting form data |
| `xlsx` | Spreadsheets | Excel file operations |
| `pptx` | Presentations | PowerPoint creation |
| `doc-coauthoring` | Collaborative editing | Multi-author document workflows |

#### Creative/Visual Skills (example-skills plugin)

| Skill | Purpose | When to Use |
|-------|---------|-------------|
| `algorithmic-art` | Generative art | Creating visual patterns, data art |
| `canvas-design` | Custom graphics | HTML5 Canvas diagrams beyond templates |
| `brand-guidelines` | Brand identity | Creating style guides |
| `theme-factory` | Design themes | Color schemes, dark/light modes |
| `web-artifacts-builder` | Interactive demos | Prototypes, shareable artifacts |
| `slack-gif-creator` | Animated GIFs | Slack emojis, reaction GIFs |
| `internal-comms` | Communications | Company announcements, newsletters |

#### Development Skills (example-skills plugin)

| Skill | Purpose | When to Use |
|-------|---------|-------------|
| `mcp-builder` | MCP servers | Creating new MCP integrations |
| `skill-creator` | Standalone skills | Skills not bundled in plugins |
| `webapp-testing` | Web app testing | QA with Playwright MCP |
| `frontend-design` | UI components | Building polished interfaces |

See @.claude/context/integrations/skills-selection-guide.md for full selection guidance.

---

## Plugin Selection Rules (PR-6)

### Code Review Selection
```
Need code review?
├── Quick review → code-review plugin
├── Thorough review → pr-review-toolkit (7 specialized agents)
└── Specific analysis → pr-review-toolkit agents directly:
    ├── Silent failures → silent-failure-hunter
    ├── Type design → type-design-analyzer
    ├── Test coverage → pr-test-analyzer
    └── Comment quality → comment-analyzer
```

### Feature Development Selection
```
Building a feature?
├── Simple feature → engineering-workflow-skills:feature-planning
├── Complex feature → feature-dev plugin (7-phase workflow)
└── Architecture only → Plan subagent
```

### Git Workflow Selection
```
Git operations needed?
├── Natural language ("push changes") → engineering-workflow-skills:git-pushing
├── Simple commands → Bash(git)
└── Complex automation → GitHub MCP
```

### Output Style Selection (Mutually Exclusive)
```
Session output style?
├── Learning mode → learning-output-style (user writes key code)
├── Teaching mode → explanatory-output-style (educational insights)
└── Normal work → Neither (default behavior)

WARNING: Only enable ONE output style per session
```

### Documentation Selection
```
Generating documentation?
├── Office formats (Word/Excel/PPT/PDF) → document-skills
├── Visual diagrams/flowcharts → visual-documentation-skills
├── Markdown sync → memory-bank-synchronizer agent
└── Codebase docs → productivity-skills:codebase-documenter
```

### Browser Automation Selection
```
Need browser automation?
├── Simple content fetch (no interaction) → WebFetch / WebSearch
├── Natural language browsing → browser-automation plugin
│   ├── "Go to X and extract Y" → browser-automation
│   ├── "Fill out this form" → browser-automation
│   └── "Navigate and click" → browser-automation
├── Deterministic automation → Playwright MCP
│   ├── Test scripts → Playwright MCP
│   ├── Precise assertions → Playwright MCP
│   └── Repeatable automation → Playwright MCP
└── Logged-in sessions → browser-automation (CAUTION)

RISK NOTE: browser-automation has higher risk profile:
- Uses Chrome profile with logged-in sessions
- AI interpretation may produce unexpected actions
- Operations outside workspace guardrails
```

---

## Selection Decision Tree

```
Need to accomplish a task?
│
├── Is it a file operation?
│   ├── Inside workspace → Use built-in (Read/Write/Edit/Glob/Grep)
│   └── Outside workspace → Use Filesystem MCP
│
├── Is it a git operation?
│   ├── Simple (status/log/diff) → Use Bash(git)
│   ├── Natural language ("commit and push") → engineering-workflow-skills:git-pushing
│   └── GitHub automation → Use gh CLI or GitHub MCP
│
├── Is it research/exploration?
│   ├── Targeted search → Use Glob + Grep directly
│   ├── Open-ended exploration → Use Explore subagent
│   └── Web research → Use WebSearch/WebFetch or deep-research agent
│
├── Is it browser automation?
│   ├── Simple content fetch → Use WebFetch/WebSearch
│   ├── Natural language tasks → Use browser-automation plugin
│   └── Deterministic scripts → Use Playwright MCP
│
├── Is it document generation?
│   ├── Office formats → Use document-skills
│   ├── Visual diagrams → Use visual-documentation-skills
│   └── Markdown → Write directly or memory-bank-synchronizer
│
├── Is it infrastructure?
│   ├── Docker commands → Use Bash(docker)
│   └── Complex deployment → Use docker-deployer agent
│
├── Is it code review?
│   ├── Quick check → Use code-review plugin
│   └── Thorough review → Use pr-review-toolkit
│
└── Is it a complex workflow?
    ├── Feature development → Use feature-dev plugin
    ├── Autonomous iteration → Use ralph-wiggum
    └── Multi-step automation → Use general-purpose subagent
```

---

## Loading Strategy Summary

### Always-On (Load at session start)

- Built-in tools (Read, Write, Edit, Glob, Grep, Bash, WebFetch, WebSearch)
- Built-in subagents (Explore, Plan)
- Memory MCP (when enabled)

### On-Demand (Enable per-session)

- Filesystem MCP
- Fetch MCP
- Time MCP
- Git MCP
- GitHub MCP
- Sequential Thinking MCP

### Isolated (Separate process)

- Playwright MCP (for browser automation)
- Heavy tools with >15K token cost

---

## Overlap Analysis Reference

See @.claude/context/integrations/overlap-analysis.md for detailed conflict resolution.

---

## Related Documentation

- @.claude/context/patterns/mcp-loading-strategy.md - MCP loading strategies
- @.claude/context/patterns/agent-selection-pattern.md - Agent vs subagent selection
- @.claude/context/integrations/overlap-analysis.md - Overlap/conflict resolution

---

*Core Tooling Baseline - Capability Matrix v1.3 (Revised 2026-01-07 PR-7 Skills)*
