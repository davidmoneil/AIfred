---
description: Initial AIfred configuration wizard
agent: build
---

# AIfred Setup Wizard

You are running the AIfred setup wizard. Guide the user through initial configuration.

## Welcome

Welcome to AIfred! This wizard will help you configure your personal AI infrastructure assistant.

## Phase 1: Basic Configuration

### Step 1.1: Verify Directory Structure

Check that the AIfred directory structure is in place:

```bash
ls -la
ls -la .claude/
ls -la .opencode/
```

Expected directories:
- `.claude/context/` - Knowledge base
- `.claude/agents/` - Agent definitions
- `.claude/commands/` - Slash commands (Claude Code)
- `.opencode/agent/` - Agent definitions (OpenCode)
- `.opencode/command/` - Slash commands (OpenCode)
- `knowledge/` - Documentation
- `external-sources/` - Symlinks to external data

### Step 1.2: Create paths-registry.yaml

If `paths-registry.yaml` doesn't exist, create it from the template:

```bash
cp paths-registry.yaml.template paths-registry.yaml
```

Ask the user to review and customize the paths for their environment.

### Step 1.3: Gather User Info

Ask the user:
1. What is your primary use case? (infrastructure management, home lab, development, etc.)
2. Do you have Docker installed? What services do you run?
3. Do you have external storage (NAS, cloud, etc.)?
4. What MCP servers do you want to enable?

## Phase 2: MCP Configuration

### For OpenCode users:

Edit `opencode.json` to configure MCP servers based on user's needs:

```json
{
  "mcp": {
    "memory": {
      "type": "remote",
      "url": "http://localhost:8080/sse"
    }
  }
}
```

### For Claude Code users:

Create or update `.mcp.json`:

```json
{
  "mcpServers": {
    "memory": {
      "url": "http://localhost:8080/sse",
      "transport": "sse"
    }
  }
}
```

## Phase 3: Session State Setup

Initialize the session state file:

```markdown
# Session State

**Last Updated**: [today's date]

## Current Work Status

**Status**: Idle
**Available for**: New tasks

## Session Continuity Notes

Initial setup completed.

## Next Session Pickup

Ready to start using AIfred!
```

## Phase 4: Git Configuration

### Step 4.1: Initialize Git (if needed)

```bash
git init
git add -A
git commit -m "Initial AIfred setup"
```

### Step 4.2: Configure Remote (optional)

Ask if user wants to connect to GitHub:

```bash
git remote add origin <repo-url>
git push -u origin main
```

## Completion

Update AGENTS.md and .claude/CLAUDE.md to show:

```markdown
**Setup Status**: Configured on [date]

Your configuration:
- Use case: [user's answer]
- MCP servers: [list]
- Docker: [yes/no]
- External storage: [details]
```

Provide final summary:

```
AIfred Setup Complete!
======================

Your AIfred environment is configured.

Quick commands:
- /end-session  - Exit with documentation
- /health       - Check system health
- @docker-deployer - Deploy Docker services
- @service-troubleshooter - Diagnose issues

Getting started:
1. Check session-state.md before starting work
2. Document discoveries in context files
3. Use /end-session when done

Happy infrastructure management!
```
