# Autonomous Execution Pattern

**Status**: Active
**Created**: 2026-01-23 (ported from AIfred)
**Purpose**: Enable scheduled, headless Claude Code execution with safety controls

## Overview

The Autonomous Execution Pattern enables Claude Code to run scheduled tasks (cron, systemd timers) while maintaining context awareness and safety boundaries. This bridges the gap between interactive sessions and fully automated execution.

**Core Principle**: Claude Code can run autonomously with pre-defined permission boundaries, output capture, and safety limits.

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         AUTONOMOUS EXECUTION STACK                          │
├─────────────────────────────────────────────────────────────────────────────┤
│  LAYER 5: SCHEDULER                                                         │
│  Cron, systemd timer, or n8n workflow triggers execution                    │
│  "0 6 * * 0 /path/to/claude-scheduled.sh context-analyze"                   │
├─────────────────────────────────────────────────────────────────────────────┤
│  LAYER 4: WRAPPER SCRIPT                                                    │
│  Bash script that configures environment and captures output                │
│  claude-scheduled.sh - sets limits, captures JSON, processes results        │
├─────────────────────────────────────────────────────────────────────────────┤
│  LAYER 3: CLAUDE CODE CLI                                                   │
│  Headless execution with permission controls                                │
│  claude -p "task" --allowedTools "..." --max-turns 10 --output-format json  │
├─────────────────────────────────────────────────────────────────────────────┤
│  LAYER 2: PERMISSION MODEL                                                  │
│  settings.json + --allowedTools define what Claude can do                   │
│  Read-only discovery vs full implementation permissions                     │
├─────────────────────────────────────────────────────────────────────────────┤
│  LAYER 1: CONTEXT FILES                                                     │
│  CLAUDE.md, settings.json, skill definitions                                │
│  Full project context available just like interactive sessions              │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Permission Tiers

### Tier 1: Discovery (Read-Only)
**Use for**: Scheduled checks, monitoring, analysis
**Risk**: Minimal - no file modifications

```bash
claude -p "task description" \
  --allowedTools "Read,Glob,Grep,WebFetch,WebSearch" \
  --max-turns 5 \
  --output-format json
```

**Allowed**:
- File reading (Read, Glob, Grep)
- Web fetching (WebFetch, WebSearch)
- Memory graph reading (if Memory MCP available)

**Blocked**:
- File writes (Edit, Write)
- Git operations (commit, push)
- Memory modifications
- Bash commands with side effects

### Tier 2: Analyze & Report (Read + Write Reports)
**Use for**: Generating reports, updating status files
**Risk**: Low - controlled write targets

```bash
claude -p "task description" \
  --allowedTools "Read,Glob,Grep,WebFetch,WebSearch,Write" \
  --max-turns 10 \
  --output-format json
```

**Additional Allowed**:
- Write to specific paths (reports, logs, data files)
- Update JSON/YAML data files

**Still Blocked**:
- Git operations
- Code modifications
- System commands

### Tier 3: Implement (Full Autonomy)
**Use for**: Pre-approved changes, trusted automation
**Risk**: Moderate - requires checkpoint strategy

```bash
claude -p "task description" \
  --allowedTools "Read,Glob,Grep,Edit,Write,Bash(git:*)" \
  --max-turns 20 \
  --max-budget-usd 5.00 \
  --output-format json
```

**Safety Requirements**:
- Always create git checkpoint first
- Log all operations
- Validate output before proceeding

---

## CLI Reference

### Core Flags

| Flag | Purpose | Example |
|------|---------|---------|
| `-p "prompt"` | Non-interactive execution | `claude -p "Check for updates"` |
| `--allowedTools "..."` | Pre-authorize specific tools | `--allowedTools "Read,Glob,WebFetch"` |
| `--max-turns N` | Limit agentic iterations | `--max-turns 10` |
| `--max-budget-usd N` | Cost ceiling | `--max-budget-usd 2.00` |
| `--output-format json` | Structured output | Parse with `jq` |
| `--no-session-persistence` | Don't save session | One-off tasks |
| `--continue` | Resume previous session | Multi-step workflows |

### Tool Patterns

```bash
# Exact tool name
--allowedTools "Read,Glob,Grep"

# Prefix matching for Bash
--allowedTools "Bash(git:*)"           # All git commands
--allowedTools "Bash(docker ps:*)"     # docker ps variants

# MCP tools
--allowedTools "mcp__git__git_status"
```

---

## Wrapper Script Template

```bash
#!/bin/bash
# claude-scheduled.sh - Scheduled Claude Code execution wrapper
#
# Usage: claude-scheduled.sh <job-name>

set -euo pipefail

PROJECT_DIR="${JARVIS_DIR:-$HOME/Claude/Jarvis}"
LOG_DIR="$PROJECT_DIR/.claude/logs/scheduled"

# Permission tiers
TIER_DISCOVERY="Read,Glob,Grep,WebFetch,WebSearch"
TIER_ANALYZE="$TIER_DISCOVERY,Write"
TIER_IMPLEMENT="$TIER_ANALYZE,Edit,Bash(git:*)"

# Job definitions
declare -A JOB_PROMPTS JOB_TIERS JOB_TURNS

JOB_PROMPTS["context-analyze"]="Run context analysis: Check file sizes, log status, and generate recommendations."
JOB_TIERS["context-analyze"]="analyze"
JOB_TURNS["context-analyze"]=10

JOB_PROMPTS["health-check"]="Check infrastructure health: Docker status, critical endpoints."
JOB_TIERS["health-check"]="discovery"
JOB_TURNS["health-check"]=5

# ... execution logic ...
```

---

## Safety Controls

### Pre-Execution

| Control | Purpose | Implementation |
|---------|---------|----------------|
| Permission Tier | Limit available tools | `--allowedTools` flag |
| Turn Limit | Prevent infinite loops | `--max-turns 10` |
| Cost Limit | Control spending | `--max-budget-usd 2.00` |
| Working Directory | Load correct context | `cd $PROJECT_DIR` |

### During Execution

| Control | Purpose | Implementation |
|---------|---------|----------------|
| Tool Allowlist | Only pre-approved tools | settings.json + CLI flag |
| Deny List | Block dangerous operations | settings.json deny rules |

### Post-Execution

| Control | Purpose | Implementation |
|---------|---------|----------------|
| Output Logging | Audit trail | JSON output to log files |
| Result Validation | Check for errors | Parse JSON, check exit code |
| Alert on Critical | Human review trigger | grep for keywords |

---

## Integration with JICM

Scheduled tasks should respect JICM boundaries:
- Check context estimate before starting
- Use Tier 1 permissions when context is high
- Output results to files rather than building context

---

## Troubleshooting

| Issue | Cause | Solution |
|-------|-------|----------|
| "Permission denied" | Tool not in allowlist | Add to `--allowedTools` |
| Empty output | Prompt unclear | Refine prompt |
| Timeout | Too many turns | Increase `--max-turns` |
| Wrong context | Not in project dir | Ensure `cd $PROJECT_DIR` |
| Slash commands not working | Not supported in `-p` mode | Describe the task instead |

---

## Related Patterns

- capability-layering-pattern.md - Where scheduled tasks fit
- command-invocation-pattern.md - CLI-backed commands
- jicm-pattern.md - Context management

---

*Ported from AIfred baseline — Jarvis v2.1.0*
