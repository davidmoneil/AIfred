# /tooling-health Command

Validate Claude Code tooling status: MCPs, plugins, skills, and subagents.

## Usage

```
/tooling-health
/tooling-health --quick    # Skip smoke tests
/tooling-health --verbose  # Show all tool details
```

## What It Checks

### 1. MCP Servers

- List configured MCPs
- Test connectivity for each
- Report token cost estimates
- Check for Stage 1 baseline coverage

### 2. Plugins

- List installed plugins
- Check for official plugins
- Report plugin health

### 3. Skills

- Check skill availability
- Verify document skills (docx, pdf, xlsx, pptx)

### 4. Built-in Tools

- Verify core tools available (Read, Write, Edit, Glob, Grep, Bash)
- Check WebFetch, WebSearch availability

### 5. Subagents

- Verify Explore, Plan, claude-code-guide availability

## Output Format

```markdown
# Tooling Health Report
**Generated**: YYYY-MM-DD HH:MM
**Claude Code Version**: X.X.X

## Summary
| Category | Status | Details |
|----------|--------|---------|
| MCP Servers | ⚠️ PARTIAL | 2/7 Stage 1 installed |
| Plugins | ✅ HEALTHY | 3 official plugins |
| Skills | ✅ HEALTHY | Document skills available |
| Built-in Tools | ✅ HEALTHY | All core tools available |
| Subagents | ✅ HEALTHY | All subagents available |

## MCP Servers

### Installed
| Server | Status | Token Cost |
|--------|--------|------------|
| memory | ✅ Connected | ~12K |

### Stage 1 Baseline (Not Installed)
| Server | Status | Install Command |
|--------|--------|-----------------|
| filesystem | ❌ Not installed | `claude mcp add filesystem -- npx -y @modelcontextprotocol/server-filesystem <dirs>` |
| fetch | ❌ Not installed | `claude mcp add fetch -- uvx mcp-server-fetch` |
| time | ❌ Not installed | `claude mcp add time -- uvx mcp-server-time` |
| git | ❌ Not installed | `claude mcp add git -- uvx mcp-server-git` |
| sequential-thinking | ❌ Not installed | `claude mcp add sequential-thinking -- npx -y @modelcontextprotocol/server-sequential-thinking` |
| github | ❌ Not installed | `claude mcp add github --remote https://api.githubcopilot.com/mcp/` |

## Plugins

### Installed
| Plugin | Scope | Version |
|--------|-------|---------|
| commit-commands | project | 6d3752c |
| github | project | 6d3752c |

### Recommended (Official)
- feature-dev - Feature development workflow
- code-review - Automated PR review
- hookify - Custom hook creation
- security-guidance - Security reminders

## Skills

### Document Skills
| Skill | Status |
|-------|--------|
| docx | ✅ Available (via marketplace) |
| pdf | ✅ Available (via marketplace) |
| xlsx | ✅ Available (via marketplace) |
| pptx | ✅ Available (via marketplace) |

## Built-in Tools

| Tool | Status |
|------|--------|
| Read | ✅ Available |
| Write | ✅ Available |
| Edit | ✅ Available |
| Glob | ✅ Available |
| Grep | ✅ Available |
| Bash | ✅ Available |
| WebFetch | ✅ Available |
| WebSearch | ✅ Available |
| Task | ✅ Available |
| TodoWrite | ✅ Available |

## Subagents

| Subagent | Status | Purpose |
|----------|--------|---------|
| Explore | ✅ Available | Codebase exploration |
| Plan | ✅ Available | Implementation planning |
| claude-code-guide | ✅ Available | Documentation lookup |
| general-purpose | ✅ Available | Complex tasks |

## Recommendations

1. [~] MEDIUM: Install Stage 1 MCPs (filesystem, fetch, time, git, sequential-thinking)
2. [~] MEDIUM: Configure GitHub MCP for automation workflows
3. [-] LOW: Consider feature-dev plugin for structured development

## Stage 1 Baseline Coverage

Current: 1/7 (14%)
Target: 7/7 (100%)

Missing:
- Filesystem MCP
- Fetch MCP
- Time MCP
- Git MCP
- Sequential Thinking MCP
- GitHub MCP
```

## Implementation

When invoked, Claude will:

### 1. Check MCP Servers
```bash
# List configured MCPs
claude mcp list

# For each MCP, attempt a simple operation
# (handled internally - no bash needed)
```

### 2. Check Plugins
```bash
# Read installed plugins
cat ~/.claude/plugins/installed_plugins.json
```

### 3. Verify Built-in Tools
- Attempt to use each tool with minimal operation
- Report availability

### 4. Check Subagents
- Verify Task tool can spawn each subagent type

### 5. Generate Report
- Compare against Stage 1 baseline
- Calculate coverage percentage
- Provide actionable recommendations

## Smoke Tests

When `--verbose` is used, run simple validation for each installed MCP:

| MCP | Test |
|-----|------|
| memory | Create/delete test entity |
| filesystem | List allowed directories |
| fetch | Fetch example.com |
| time | Get current time |
| git | Get git status |
| sequential-thinking | Simple reasoning test |
| github | List notifications |

## Related Documentation

- @.claude/context/integrations/capability-matrix.md - Capability matrix
- @.claude/context/integrations/mcp-installation.md - Installation procedures
- @.claude/context/integrations/overlap-analysis.md - Overlap analysis
- @.claude/commands/health-report.md - Infrastructure health

---

*PR-5 Core Tooling Baseline - Tooling Health Check v1.0*
