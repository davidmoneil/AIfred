# MCP Server Installation Guide

**Created**: 2026-01-06
**PR Reference**: PR-5 (Core Tooling Baseline)
**Status**: Active

---

## Overview

This guide documents installation procedures for Stage 1 MCP servers as defined in the Project Aion roadmap. Each server includes installation steps, configuration, validation, and loading strategy recommendation.

---

## Stage 1 MCP Servers (Core Baseline)

### 1. Memory Knowledge Graph

**Purpose**: Persistent cross-session memory using knowledge graph structure

**Installation**:
```bash
# Add to Claude Code
claude mcp add memory -- npx -y @modelcontextprotocol/server-memory
```

**Configuration**: None required (stores in default location)

**Tools Provided**:
- `create_entities` - Create nodes
- `create_relations` - Link nodes
- `add_observations` - Attach facts
- `delete_entities`, `delete_observations`, `delete_relations` - Remove data
- `read_graph` - Get full graph
- `search_nodes` - Query by name
- `open_nodes` - Get specific nodes

**Validation**:
```bash
# Test via Claude (after adding)
claude -p "Use Memory MCP to create an entity named 'test' of type 'validation'"
```

**Loading Strategy**: Always-On (when enabled)
**Token Cost**: ~8-15K

---

### 2. Filesystem

**Purpose**: Secure file operations with configurable access boundaries

**Installation**:
```bash
# Add with allowed directories
claude mcp add filesystem -- npx -y @modelcontextprotocol/server-filesystem \
  /Users/aircannon/Claude/Jarvis \
  /Users/aircannon/Claude
```

**Configuration**: Specify allowed directories as arguments

**Tools Provided**:
- `read_text_file`, `read_media_file`, `read_multiple_files`
- `write_file`, `edit_file`
- `create_directory`, `list_directory`, `directory_tree`
- `search_files`, `get_file_info`, `move_file`
- `list_allowed_directories`

**Validation**:
```bash
claude -p "Use Filesystem MCP to list allowed directories"
```

**Loading Strategy**: On-Demand (enable when working outside workspace)
**Token Cost**: ~8K

---

### 3. Fetch

**Purpose**: Web content fetching with HTML-to-markdown conversion and chunking

**Installation**:
```bash
# Python-based (requires uv)
claude mcp add fetch -- uvx mcp-server-fetch
```

**Prerequisites**: Install `uv` package manager
```bash
pip install uv
# or
brew install uv
```

**Tools Provided**:
- `fetch` - Fetch URL with options:
  - `url` (required)
  - `max_length` (default: 5000)
  - `start_index` (for chunked reading)
  - `raw` (return raw HTML)

**Validation**:
```bash
claude -p "Use Fetch MCP to get https://example.com"
```

**Loading Strategy**: On-Demand
**Token Cost**: ~5K

---

### 4. Time

**Purpose**: Time operations with IANA timezone support

**Installation**:
```bash
# Python-based (requires uv)
claude mcp add time -- uvx mcp-server-time
```

**Prerequisites**: Install `uv` package manager

**Tools Provided**:
- `get_current_time` - Get time in specified timezone
- `convert_time` - Convert between timezones

**Validation**:
```bash
claude -p "Use Time MCP to get current time in America/Los_Angeles"
```

**Loading Strategy**: On-Demand
**Token Cost**: ~3K

---

### 5. Git

**Purpose**: Git repository operations via MCP

**Installation**:
```bash
# Python-based (requires uv)
claude mcp add git -- uvx mcp-server-git --repository /Users/aircannon/Claude/Jarvis
```

**Tools Provided**:
- `git_status`, `git_diff_unstaged`, `git_diff_staged`, `git_diff`
- `git_commit`, `git_add`, `git_reset`
- `git_log`, `git_show`, `git_branch`
- `git_create_branch`, `git_checkout`

**Validation**:
```bash
claude -p "Use Git MCP to show git status"
```

**Loading Strategy**: On-Demand (Bash(git) preferred for most operations)
**Token Cost**: ~6K

---

### 6. Sequential Thinking

**Purpose**: Structured problem-solving with step-by-step reasoning

**Installation**:
```bash
claude mcp add sequential-thinking -- npx -y @modelcontextprotocol/server-sequential-thinking
```

**Tools Provided**:
- `sequential_thinking` - Structured thought process tool

**Validation**:
```bash
claude -p "Use Sequential Thinking to analyze: What are the tradeoffs of microservices vs monolith?"
```

**Loading Strategy**: On-Demand
**Token Cost**: ~5K

---

### 7. GitHub Official

**Purpose**: Comprehensive GitHub platform integration

**Installation Options**:

**Option A - Remote (OAuth)**:
```bash
# Uses GitHub Copilot authentication
claude mcp add github --remote https://api.githubcopilot.com/mcp/
```

**Option B - Local with PAT**:
```bash
# Set environment variable first
export GITHUB_PERSONAL_ACCESS_TOKEN="ghp_your_token_here"

# Docker-based
claude mcp add github -- docker run -i --rm \
  -e GITHUB_PERSONAL_ACCESS_TOKEN \
  ghcr.io/github/github-mcp-server
```

**Tools Provided** (grouped by toolset):
- **repos**: create, fork, search repositories
- **issues**: create, update, search, comment
- **pull_requests**: create, update, merge, review
- **actions**: list workflows, trigger, view runs
- **code_security**: code scanning, secret scanning
- **discussions**: create, list, comment
- **projects**: manage project boards
- **notifications**: list, manage
- **users**: get user info
- **context**: repository context tools

**Validation**:
```bash
claude -p "Use GitHub MCP to list my recent notifications"
```

**Loading Strategy**: On-Demand
**Token Cost**: ~15K

---

## Additional MCPs (Stage 2+)

These are documented for future reference but not part of Stage 1 baseline:

### DuckDuckGo Search
```bash
claude mcp add duckduckgo -- npx -y @nicholasrq/duckduckgo-mcp
```
**Token Cost**: ~5K

### Playwright (Browser Automation) — PR-8 Target

**Purpose**: Programmatic browser automation with precise control for testing and scraping

**Installation**:
```bash
claude mcp add playwright npx '@playwright/mcp@latest'
```

**Tools Provided**:
- `browser_navigate` - Go to URL
- `browser_snapshot` - Accessibility snapshot (better than screenshot)
- `browser_click`, `browser_type`, `browser_fill_form` - Interactions
- `browser_screenshot` - Visual capture
- `browser_evaluate` - Run JavaScript
- `browser_network_requests`, `browser_console_messages` - Debugging
- `browser_tabs` - Multi-tab management
- `browser_wait_for` - Wait conditions
- `browser_drag`, `browser_hover`, `browser_select_option` - Advanced interactions

**Prerequisites**:
```bash
# Install browser if not present
npx playwright install chromium
```

**Validation**:
```bash
claude -p "Use Playwright MCP to navigate to https://example.com and take a snapshot"
```

**Overlap with browser-automation plugin**:
- Playwright MCP: Programmatic, deterministic, precise control
- browser-automation: Natural language, AI-interpreted, context-efficient
- **Selection**: Use Playwright for QA tests/scripts, browser-automation for NL tasks

**Loading Strategy**: Isolated (spawn per-invocation, high resource usage)
**Token Cost**: ~15K

### Context7 (Upstash) — Documentation Provider

**Purpose**: Provides up-to-date, version-specific library documentation to prevent hallucinations

**Installation**:
```bash
# Requires API key from https://context7.io/dashboard
export CONTEXT7_API_KEY="ctx7sk-xxxxx"
claude mcp add context7 -- npx -y @upstash/context7-mcp --api-key $CONTEXT7_API_KEY
```

**Tools Provided**:
- `resolve-library-id` - Convert library name to Context7 ID
- `get-library-docs` - Retrieve version-specific documentation

**Key Features**:
- Access to ~20,000 indexed libraries
- Version-specific documentation (e.g., React 18 vs 19)
- Prevents hallucinations from outdated training data
- Higher rate limits with API key

**Validation**:
```bash
claude -p "Use Context7 to resolve the library ID for 'react'"
```

**Loading Strategy**: On-Demand (enable for documentation-heavy tasks)
**Token Cost**: ~8K

---

## Bulk Installation Script

For convenience, here's a script to install all Stage 1 MCPs:

```bash
#!/bin/bash
# install-stage1-mcps.sh

echo "Installing Stage 1 MCP Servers..."

# Memory (Always-On recommended)
claude mcp add memory -- npx -y @modelcontextprotocol/server-memory

# Filesystem (On-Demand)
claude mcp add filesystem -- npx -y @modelcontextprotocol/server-filesystem \
  /Users/aircannon/Claude/Jarvis \
  /Users/aircannon/Claude

# Fetch (On-Demand)
claude mcp add fetch -- uvx mcp-server-fetch

# Time (On-Demand)
claude mcp add time -- uvx mcp-server-time

# Git (On-Demand)
claude mcp add git -- uvx mcp-server-git --repository /Users/aircannon/Claude/Jarvis

# Sequential Thinking (On-Demand)
claude mcp add sequential-thinking -- npx -y @modelcontextprotocol/server-sequential-thinking

echo "Stage 1 MCPs installed. Restart Claude Code to activate."
echo ""
echo "Note: GitHub MCP requires separate authentication setup."
echo "Run: claude mcp add github --remote https://api.githubcopilot.com/mcp/"
```

---

## Managing MCPs

### List Installed
```bash
claude mcp list
```

### Remove MCP
```bash
claude mcp remove <name>
```

### Enable/Disable (per-session)
```bash
# Currently MCPs are all-or-nothing per config
# Use different mcp-config files for different setups:
claude --mcp-config ~/.claude/mcp-profiles/minimal.json
```

---

## Prerequisites Check

Before installing MCPs, ensure:

1. **Node.js 18+**
   ```bash
   node --version  # Should be v18.x or higher
   ```

2. **Python 3.10+ with uv** (for Python-based servers)
   ```bash
   python3 --version
   pip install uv  # or: brew install uv
   ```

3. **Docker** (for containerized servers)
   ```bash
   docker --version
   ```

---

## Token Cost Summary

| MCP | Token Cost | Loading Strategy | Tier | Validated |
|-----|------------|------------------|------|-----------|
| Memory | ~1.8K | Always-On | 1 | 2026-01-08 |
| Filesystem | ~2.8K | Always-On | 1 | 2026-01-08 |
| Fetch | ~1K | Always-On | 1 | Pending |
| Git | ~2.5K | Always-On | 1 | 2026-01-08 |
| GitHub | ~15K | Task-Scoped | 2 | Pending |
| Context7 | ~8K | Task-Scoped | 2 | Pending |
| Sequential Thinking | ~5K | Task-Scoped | 2 | Pending |
| Playwright | ~6K | Triggered | 3 | Pending |
| DuckDuckGo | ~2K | Triggered | 3 | 2026-01-09 ⚠️ |
| Brave Search | ~3K | Task-Scoped | 2 | Not Installed |
| arXiv | ~2K | Task-Scoped | 2 | 2026-01-09 (partial) |

**Note**: Token costs updated via validation harness (PR-8.4). Earlier estimates were based on total session overhead, not isolated MCP cost.

**Recommendation**: Start with Memory only as Always-On. Enable others as needed per session.

---

## Troubleshooting

### MCP Not Responding
```bash
# Check if server is running
claude mcp list

# Remove and re-add
claude mcp remove <name>
claude mcp add <name> -- <command>
```

### Permission Errors
- Ensure directories in Filesystem MCP are correct
- Check that GITHUB_PERSONAL_ACCESS_TOKEN is set for GitHub MCP

### High Token Usage
- Use `--mcp-config` with minimal profile for quick tasks
- Consider Isolated strategy for heavy MCPs like Playwright

---

## Related Documentation

- @.claude/context/patterns/mcp-loading-strategy.md - Loading strategy details
- @.claude/context/patterns/mcp-validation-harness.md - Validation harness pattern (PR-8.4)
- @.claude/context/integrations/capability-matrix.md - When to use which tool
- @.claude/context/integrations/overlap-analysis.md - Conflict resolution
- @.claude/skills/mcp-validation/SKILL.md - `/validate-mcp` command

---

*MCP Installation Guide - Updated 2026-01-08 (PR-8.4 Validation)*
