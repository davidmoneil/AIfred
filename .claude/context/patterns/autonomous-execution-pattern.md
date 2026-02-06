# Autonomous Execution Pattern

**Status**: Active
**Created**: 2026-01-20
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
│  "0 6 * * 0 /path/to/claude-scheduled.sh upgrade-discover"                  │
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
  --allowedTools "Read,Glob,Grep,WebFetch,WebSearch,mcp__mcp-gateway__fetch,mcp__mcp-gateway__read_graph" \
  --max-turns 5 \
  --output-format json
```

**Allowed**:
- File reading (Read, Glob, Grep)
- Web fetching (WebFetch, WebSearch)
- Memory graph reading (read_graph, search_nodes)
- MCP read operations

**Blocked**:
- File writes (Edit, Write)
- Git operations (commit, push)
- Memory modifications (create_entities)
- Bash commands with side effects

### Tier 2: Analyze & Report (Read + Write Reports)
**Use for**: Generating reports, updating status files
**Risk**: Low - controlled write targets

```bash
claude -p "task description" \
  --allowedTools "Read,Glob,Grep,WebFetch,WebSearch,Write,mcp__filesystem__write_file" \
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
  --allowedTools "Read,Glob,Grep,Edit,Write,Bash(git:*),mcp__git__*" \
  --max-turns 20 \
  --max-budget-usd 5.00 \
  --output-format json
```

**Additional Allowed**:
- File editing (Edit)
- Git operations (checkpoint, commit)
- Limited bash commands

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
--allowedTools "Bash(npm run:*)"       # npm run scripts

# MCP tools
--allowedTools "mcp__mcp-gateway__fetch,mcp__git__git_status"

# Domain-restricted WebFetch
--allowedTools "WebFetch(domain:github.com)"
```

### Output Formats

```bash
# Plain text (default)
claude -p "task"

# JSON with metadata
claude -p "task" --output-format json
# Returns: { "result": "...", "session_id": "...", "cost_usd": 0.05 }

# Streaming JSON
claude -p "task" --output-format stream-json

# Schema-validated output
claude -p "Extract data" --output-format json --json-schema '{"type":"object"}'
```

---

## Wrapper Script Template

```bash
#!/bin/bash
# claude-scheduled.sh - Scheduled Claude Code execution wrapper
#
# Usage: claude-scheduled.sh <job-name> [additional args]
# Example: claude-scheduled.sh upgrade-discover
#
# Features:
# - Permission tier selection
# - Output capture and logging
# - Cost/turn limits
# - Error handling
# - Result processing

set -euo pipefail

# Configuration
PROJECT_DIR="${PROJECT_DIR:-<project_root>}"
LOG_DIR="$PROJECT_DIR/.claude/logs/scheduled"
JOBS_DIR="$PROJECT_DIR/.claude/jobs"

# Defaults
DEFAULT_MAX_TURNS=10
DEFAULT_MAX_BUDGET=2.00
DEFAULT_TIER="discovery"

# Job definitions (override defaults per job)
declare -A JOB_PROMPTS
declare -A JOB_TIERS
declare -A JOB_TURNS
declare -A JOB_BUDGETS

# --- Job Definitions ---
JOB_PROMPTS["upgrade-discover"]="Run the upgrade discovery workflow: Check external sources (GitHub releases, documentation, blogs) for Claude Code and MCP updates. Compare findings against the baselines in .claude/skills/upgrade/data/baselines.json. Store any new discoveries in .claude/skills/upgrade/data/pending-upgrades.json with proper IDs and metadata. Generate a discovery report."
JOB_TIERS["upgrade-discover"]="analyze"
JOB_TURNS["upgrade-discover"]=15
JOB_BUDGETS["upgrade-discover"]=3.00

JOB_PROMPTS["health-summary"]="Check infrastructure health: Review docker container status, check for any failed services, verify critical endpoints are responding. Output a brief health summary."
JOB_TIERS["health-summary"]="discovery"
JOB_TURNS["health-summary"]=5
JOB_BUDGETS["health-summary"]=1.00

JOB_PROMPTS["priority-review"]="Review current-priorities.md and session-state.md. Identify any items marked as completed that should be archived, or blocked items that need attention. Output recommendations only - do not modify files."
JOB_TIERS["priority-review"]="discovery"
JOB_TURNS["priority-review"]=5
JOB_BUDGETS["priority-review"]=1.00

# --- Permission Tiers ---
TIER_DISCOVERY="Read,Glob,Grep,WebFetch,WebSearch,mcp__mcp-gateway__fetch,mcp__mcp-gateway__read_graph,mcp__mcp-gateway__search_nodes,mcp__git__git_status,mcp__git__git_log,mcp__filesystem__read_text_file,mcp__filesystem__list_directory"

TIER_ANALYZE="$TIER_DISCOVERY,Write,mcp__filesystem__write_file"

TIER_IMPLEMENT="$TIER_ANALYZE,Edit,Bash(git:*),mcp__git__git_add,mcp__git__git_commit"

# --- Functions ---
log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

get_tier_tools() {
  local tier="$1"
  case "$tier" in
    discovery) echo "$TIER_DISCOVERY" ;;
    analyze)   echo "$TIER_ANALYZE" ;;
    implement) echo "$TIER_IMPLEMENT" ;;
    *)         echo "$TIER_DISCOVERY" ;;
  esac
}

# --- Main ---
JOB_NAME="${1:-}"
if [ -z "$JOB_NAME" ]; then
  echo "Usage: $0 <job-name>"
  echo "Available jobs: ${!JOB_PROMPTS[*]}"
  exit 1
fi

if [ -z "${JOB_PROMPTS[$JOB_NAME]:-}" ]; then
  echo "Unknown job: $JOB_NAME"
  echo "Available jobs: ${!JOB_PROMPTS[*]}"
  exit 1
fi

# Setup logging
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/$JOB_NAME-$(date +%Y%m%d-%H%M%S).log"
OUTPUT_FILE="$LOG_DIR/$JOB_NAME-$(date +%Y%m%d-%H%M%S).json"

log "Starting scheduled job: $JOB_NAME"

# Get job configuration
PROMPT="${JOB_PROMPTS[$JOB_NAME]}"
TIER="${JOB_TIERS[$JOB_NAME]:-$DEFAULT_TIER}"
MAX_TURNS="${JOB_TURNS[$JOB_NAME]:-$DEFAULT_MAX_TURNS}"
MAX_BUDGET="${JOB_BUDGETS[$JOB_NAME]:-$DEFAULT_MAX_BUDGET}"
ALLOWED_TOOLS=$(get_tier_tools "$TIER")

log "Tier: $TIER"
log "Max turns: $MAX_TURNS"
log "Max budget: $MAX_BUDGET"

# Change to project directory (loads CLAUDE.md and settings.json)
cd "$PROJECT_DIR"

# Execute Claude
log "Executing claude -p ..."
RESULT=$(claude -p "$PROMPT" \
  --allowedTools "$ALLOWED_TOOLS" \
  --max-turns "$MAX_TURNS" \
  --output-format json \
  --no-session-persistence \
  2>&1) || {
    log "ERROR: Claude execution failed"
    echo "$RESULT" >> "$LOG_FILE"
    exit 1
  }

# Save raw output
echo "$RESULT" > "$OUTPUT_FILE"
log "Output saved to: $OUTPUT_FILE"

# Extract and log key info
if command -v jq &>/dev/null; then
  COST=$(echo "$RESULT" | jq -r '.cost_usd // "unknown"' 2>/dev/null || echo "unknown")
  SESSION_ID=$(echo "$RESULT" | jq -r '.session_id // "unknown"' 2>/dev/null || echo "unknown")
  RESPONSE=$(echo "$RESULT" | jq -r '.result // .response // "no result"' 2>/dev/null || echo "$RESULT")

  log "Cost: \$$COST"
  log "Session ID: $SESSION_ID"
  log "Response preview: ${RESPONSE:0:200}..."
fi

log "Job completed: $JOB_NAME"

# --- Post-processing ---
# Check for critical findings and notify if needed
if echo "$RESULT" | grep -qi "critical\|security\|vulnerability"; then
  log "ALERT: Critical finding detected - manual review recommended"
  # TODO: Add notification (n8n webhook, email, etc.)
fi

exit 0
```

---

## Job Configuration

### upgrade-discover

**Purpose**: Check external sources for Claude Code updates
**Schedule**: Weekly (Sunday 6:00 AM)
**Tier**: Analyze (can write to data files)

**Prompt**:
```
Run the upgrade discovery workflow: Check external sources (GitHub releases,
documentation, blogs) for Claude Code and MCP updates. Compare findings against
the baselines in .claude/skills/upgrade/data/baselines.json. Store any new
discoveries in .claude/skills/upgrade/data/pending-upgrades.json with proper
IDs and metadata. Generate a discovery report.
```

**Tools Needed**:
- WebFetch (external sources)
- Read (baselines, existing data)
- Write (pending-upgrades.json)
- mcp__filesystem (data files)

### health-summary

**Purpose**: Quick infrastructure health check
**Schedule**: Daily (6:00 AM)
**Tier**: Discovery (read-only)

**Prompt**:
```
Check infrastructure health: Review docker container status, check for any
failed services, verify critical endpoints are responding. Output a brief
health summary.
```

### priority-review

**Purpose**: Review and flag stale priorities
**Schedule**: Weekly (Monday 7:00 AM)
**Tier**: Discovery (read-only)

**Prompt**:
```
Review current-priorities.md and session-state.md. Identify any items marked
as completed that should be archived, or blocked items that need attention.
Output recommendations only - do not modify files.
```

---

## Cron/Systemd Configuration

### Crontab Entries

```bash
# Claude Code Scheduled Jobs
# Runs in AIProjects directory to load context

# Weekly upgrade discovery (Sunday 6:00 AM)
0 6 * * 0 <project_root>/.claude/jobs/claude-scheduled.sh upgrade-discover >> <project_root>/.claude/logs/scheduled/cron.log 2>&1

# Daily health summary (6:00 AM)
0 6 * * * <project_root>/.claude/jobs/claude-scheduled.sh health-summary >> <project_root>/.claude/logs/scheduled/cron.log 2>&1

# Weekly priority review (Monday 7:00 AM)
0 7 * * 1 <project_root>/.claude/jobs/claude-scheduled.sh priority-review >> <project_root>/.claude/logs/scheduled/cron.log 2>&1
```

### Systemd Timer (Alternative)

```ini
# /etc/systemd/system/claude-upgrade-discover.timer
[Unit]
Description=Weekly Claude Code upgrade discovery

[Timer]
OnCalendar=Sun 06:00:00
Persistent=true
RandomizedDelaySec=300

[Install]
WantedBy=timers.target
```

```ini
# /etc/systemd/system/claude-upgrade-discover.service
[Unit]
Description=Claude Code upgrade discovery job
After=network-online.target

[Service]
Type=oneshot
User=<your-username>
WorkingDirectory=<project_root>
ExecStart=<project_root>/.claude/jobs/claude-scheduled.sh upgrade-discover
StandardOutput=append:<project_root>/.claude/logs/scheduled/systemd.log
StandardError=append:<project_root>/.claude/logs/scheduled/systemd.log

[Install]
WantedBy=multi-user.target
```

---

## Output Processing

### Extracting Results

```bash
# Parse JSON output
RESULT=$(cat output.json)

# Get the main result text
echo "$RESULT" | jq -r '.result'

# Get cost
echo "$RESULT" | jq -r '.cost_usd'

# Get session ID (for resumption)
echo "$RESULT" | jq -r '.session_id'

# Check for specific keywords
if echo "$RESULT" | jq -r '.result' | grep -qi "critical"; then
  echo "Critical finding detected"
fi
```

### Writing to Todo/Priorities

```bash
# Append findings to current-priorities.md
FINDINGS=$(echo "$RESULT" | jq -r '.result')
if [ -n "$FINDINGS" ]; then
  echo "" >> .claude/context/projects/current-priorities.md
  echo "## Automated Discovery - $(date +%Y-%m-%d)" >> .claude/context/projects/current-priorities.md
  echo "$FINDINGS" >> .claude/context/projects/current-priorities.md
fi
```

### n8n Integration

```json
{
  "nodes": [
    {
      "name": "Schedule Trigger",
      "type": "n8n-nodes-base.scheduleTrigger",
      "parameters": {
        "rule": { "interval": [{ "field": "weeks", "weeks": 1 }] }
      }
    },
    {
      "name": "Execute Claude Job",
      "type": "n8n-nodes-base.executeCommand",
      "parameters": {
        "command": "<project_root>/.claude/jobs/claude-scheduled.sh upgrade-discover"
      }
    },
    {
      "name": "Parse Output",
      "type": "n8n-nodes-base.code",
      "parameters": {
        "jsCode": "const output = JSON.parse($input.first().json.stdout);\nreturn [{ json: { result: output.result, cost: output.cost_usd } }];"
      }
    },
    {
      "name": "Check Critical",
      "type": "n8n-nodes-base.if",
      "parameters": {
        "conditions": {
          "string": [{ "value1": "={{ $json.result }}", "operation": "contains", "value2": "CRITICAL" }]
        }
      }
    },
    {
      "name": "Send Alert",
      "type": "n8n-nodes-base.slack",
      "parameters": {
        "channel": "#alerts",
        "text": "Critical upgrade discovered: {{ $json.result }}"
      }
    }
  ]
}
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
| No Session Persistence | Don't pollute session history | `--no-session-persistence` |

### Post-Execution

| Control | Purpose | Implementation |
|---------|---------|----------------|
| Output Logging | Audit trail | JSON output to log files |
| Result Validation | Check for errors | Parse JSON, check exit code |
| Alert on Critical | Human review trigger | grep for keywords |
| Git Checkpoint | Rollback capability | Pre-commit tag (Tier 3 only) |

---

## Troubleshooting

| Issue | Cause | Solution |
|-------|-------|----------|
| "Permission denied" | Tool not in allowlist | Add to `--allowedTools` |
| Empty output | Prompt unclear | Refine prompt with explicit instructions |
| Timeout | Too many turns | Increase `--max-turns` or simplify prompt |
| Wrong context | Not in project dir | Ensure `cd $PROJECT_DIR` before claude |
| High cost | Complex task | Add `--max-budget-usd` limit |
| Slash commands not working | Not supported in `-p` mode | Describe the task instead |

---

## Integration with Capability Layering

This pattern extends the Capability Layering Pattern for AI-assisted scheduled tasks:

```
LAYER 5: SCHEDULER (cron/systemd/n8n)
    ↓ triggers
LAYER 4: WRAPPER (claude-scheduled.sh)
    ↓ configures and executes
LAYER 3: CLAUDE CODE CLI (-p mode)
    ↓ with context from
LAYER 2: CONTEXT FILES (CLAUDE.md, settings.json)
    ↓ producing
LAYER 1: STRUCTURED OUTPUT (JSON results)
```

**Key Difference from Pure Scripts**: Unlike pure bash scripts, this pattern uses Claude for tasks requiring:
- Pattern recognition across sources
- Natural language understanding
- Multi-step reasoning
- Context-aware decisions

---

## Related Documentation

- @.claude/context/patterns/capability-layering-pattern.md - When to use scripts vs AI
- @.claude/skills/upgrade/SKILL.md - Upgrade discovery workflow
- @.claude/settings.json - Permission configuration
- @Scripts/weekly-context-analysis.sh - Example of scheduled AI (Ollama)
