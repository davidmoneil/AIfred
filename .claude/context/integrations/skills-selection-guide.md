# Skills Selection Guide

**Purpose**: Quick reference for choosing the right skill for a task.

**Related**:
- @.claude/reports/pr-7-skills-evaluation.md — Full skill evaluations
- @.claude/reports/pr-7-skills-overlap-analysis.md — Overlap analysis
- @.claude/context/integrations/capability-map.yaml — Full tool selection

---

## Quick Selection Matrix

### By Output Type

| Need | Skill | Plugin (if via plugin) |
|------|-------|----------------------|
| Word document | `docx` | document-skills |
| PDF document | `pdf` | document-skills |
| PowerPoint | `pptx` | document-skills |
| Excel spreadsheet | `xlsx` | document-skills |
| Architecture diagram | `architecture-diagram-creator` | visual-documentation-skills |
| Flowchart | `flowchart-creator` | visual-documentation-skills |
| Timeline/Gantt | `timeline-creator` | visual-documentation-skills |
| Dashboard | `dashboard-creator` | visual-documentation-skills |
| Technical docs | `technical-doc-creator` | visual-documentation-skills |
| UI component | `frontend-design` | frontend-design |
| Design theme | `theme-factory` | example-skills |
| Custom graphic | `canvas-design` | example-skills |
| Generative art | `algorithmic-art` | example-skills |
| Interactive demo | `web-artifacts-builder` | example-skills |
| Animated GIF | `slack-gif-creator` | example-skills |

### By Task Type

| Task | Skill | Notes |
|------|-------|-------|
| Create MCP server | `mcp-builder` | For PR-8 MCP expansion |
| Create new skill | `skill-creator` | Standalone skills |
| Create plugin | `plugin-dev:create-plugin` | Full plugin |
| Test web app | `webapp-testing` | Use with Playwright MCP |
| Write announcement | `internal-comms` | Enterprise comms |
| Create brand guide | `brand-guidelines` | Brand identity |
| Collaborative editing | `doc-coauthoring` | Multi-author docs |

### By Workflow

| Workflow | Skills Chain |
|----------|--------------|
| Feature development | `feature-dev` → `pr-review-toolkit` |
| Plugin creation | `plugin-dev:create-plugin` → `plugin-dev:skill-development` |
| Document workflow | `docx`/`pdf` → `doc-coauthoring` (if collaborative) |
| Visual documentation | `architecture-diagram-creator` → `technical-doc-creator` |
| Testing workflow | `webapp-testing` + Playwright MCP → `pr-review-toolkit` |

---

## Decision Trees

### Document Creation

```
What document type?
├── Office format (.docx/.xlsx/.pptx) → Document skill
│   ├── Word → docx
│   ├── Excel → xlsx
│   └── PowerPoint → pptx
├── PDF → pdf skill
├── Collaborative editing → doc-coauthoring
└── Plain text/code → Write tool (built-in)
```

### Visual Output

```
What visual type?
├── Technical diagram
│   ├── Architecture → architecture-diagram-creator
│   ├── Flowchart → flowchart-creator
│   ├── Timeline → timeline-creator
│   └── Dashboard → dashboard-creator
├── Custom graphic → canvas-design
├── Generative art → algorithmic-art
├── UI component → frontend-design
└── Interactive prototype → web-artifacts-builder
```

### Development Task

```
What to create?
├── MCP server → mcp-builder
├── Skill
│   ├── Standalone → skill-creator
│   └── Plugin-bundled → plugin-dev:skill-development
├── Full plugin → plugin-dev:create-plugin
├── Agent SDK app → agent-sdk-dev:new-sdk-app
└── Hook → hookify
```

---

## High-Value Skills for Jarvis

### Tier 1: Daily Use

| Skill | Use Case |
|-------|----------|
| `docx`/`pdf`/`pptx`/`xlsx` | Professional documentation |
| `architecture-diagram-creator` | System diagrams |
| `frontend-design` | UI development |
| `feature-dev` | Feature development workflow |
| `pr-review-toolkit` | Code review |

### Tier 2: Frequent Use

| Skill | Use Case |
|-------|----------|
| `mcp-builder` | MCP expansion (PR-8) |
| `plugin-dev:create-plugin` | Plugin development |
| `webapp-testing` | QA testing |
| `technical-doc-creator` | Technical documentation |
| `code-auditor` | Code quality analysis |

### Tier 3: Occasional Use

| Skill | Use Case |
|-------|----------|
| `algorithmic-art` | Creative visuals |
| `brand-guidelines` | Brand documentation |
| `slack-gif-creator` | Fun communication |
| `theme-factory` | Design systems |
| `internal-comms` | Announcements |

---

## Skill + MCP Combinations

### Recommended Pairings

| Skill | MCP | Combined Capability |
|-------|-----|---------------------|
| `webapp-testing` | Playwright | Full web testing workflow |
| `mcp-builder` | Context7 | Documentation-aware MCP development |
| `frontend-design` | GitHub | Integrated UI + version control |
| `code-auditor` | Sequential Thinking | Deep analysis workflow |

---

## Skills Not Yet Available

Capabilities we may want to add in future PRs:

| Missing Capability | Workaround | Future PR |
|-------------------|------------|-----------|
| Database interaction | Manual SQL via Bash | PR-8 (MCP) |
| API testing | curl/httpie via Bash | PR-15 |
| Infrastructure (Terraform) | Manual HCL | PR-15 |
| Kubernetes management | kubectl via Bash | PR-15 |

---

## Quick Reference Commands

### Invoking Skills

```bash
# Document creation
"Create a Word document about X"
"Generate a PDF report"
"Make a presentation on Y"

# Visual creation
"Create an architecture diagram showing..."
"Generate a flowchart for..."
"Build a dashboard with..."

# Development
"Create an MCP server for X"
"Create a new skill called Y"
"Create a plugin for Z"

# Testing
"Test the web application login flow"
```

### Skill Information

```bash
# List all skills
/skills

# Get skill help
"How do I use the docx skill?"
"What can the mcp-builder skill do?"
```

---

## Troubleshooting

### Skill Not Working

1. **Check installation**: `/plugins list` to verify plugin
2. **Check invocation**: Mention skill by name or use command
3. **Check dependencies**: Some skills need MCPs (e.g., webapp-testing + Playwright)

### Wrong Skill Selected

If Claude uses wrong skill:
1. Explicitly name the skill: "Use the `docx` skill to..."
2. Specify output format: "Create a Word document (.docx)..."
3. Reference this guide: "Per skills-selection-guide.md, use..."

---

*Skills Selection Guide v1.0*
*PR-7 — Jarvis v1.6.0*
