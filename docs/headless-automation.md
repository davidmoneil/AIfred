# Headless Automation Framework

AIfred includes a complete headless automation framework for running Claude Code jobs autonomously on a schedule. Jobs execute with persona-based permissions, cost controls, and optional notifications.

## Architecture

```
cron (every 5 min)
  └── dispatcher.sh          # Evaluates schedules, runs pre-checks
       ├── executor.sh        # Loads persona, builds prompt, invokes Claude/Ollama
       │    └── persona/      # prompt.md + permissions.yaml + config.yaml
       ├── team-runner.py     # Multi-agent consensus (parallel execution)
       └── msgbus.sh          # SQLite event bus → msg-relay.sh → Telegram
```

## Requirements

- **bash** 4.0+
- **python3** — SQLite wrapper and team orchestration
- **yq** — YAML parsing ([install](https://github.com/mikefarah/yq))
- **jq** — JSON parsing
- **curl** — API calls (Telegram, Ollama, health checks)
- **claude** CLI — Must be on PATH (install via `npm install -g @anthropic-ai/claude-code`)
- **Telegram Bot** (optional) — For notifications. See [Notification Setup](#notification-setup)
- **Ollama** (optional) — For local LLM jobs. See [Engine Routing](#engine-routing)

## Quick Start

### 1. Set up cron

Add these three entries (`crontab -e`):

```bash
# Job dispatcher — every 5 minutes
*/5 * * * * /path/to/your/project/.claude/jobs/dispatcher.sh >> /path/to/your/project/.claude/logs/headless/dispatcher.log 2>&1

# Telegram callback handler — every 5 minutes (skip if not using Telegram)
*/5 * * * * /path/to/your/project/.claude/jobs/lib/telegram-callback-handler.sh >> /path/to/your/project/.claude/logs/headless/callback.log 2>&1

# Dispatcher watchdog — every 15 minutes
*/15 * * * * /path/to/your/project/.claude/jobs/lib/dispatcher-watchdog.sh >> /path/to/your/project/.claude/logs/headless/watchdog.log 2>&1
```

Replace `/path/to/your/project` with your actual AIfred project root.

### 2. Configure notifications (optional)

```bash
cp .claude/jobs/.env.template .claude/jobs/.env
# Edit .env with your Telegram bot token and chat ID
```

### 3. Initialize the database

```bash
python3 .claude/jobs/lib/jobsdb.py init
```

### 4. Enable a job

Edit `.claude/jobs/registry.yaml` — set `enabled: true` on any job you want to run.

### 5. Verify it works

```bash
# Check the dashboard
.claude/jobs/dispatcher.sh --dashboard

# Run a specific job manually
.claude/jobs/dispatcher.sh --run health-check

# Check logs
tail -f .claude/logs/headless/dispatcher.log
```

## Directory Structure

```
.claude/jobs/
├── dispatcher.sh              # Master scheduler (cron entry point)
├── executor.sh                # Persona-aware job runner
├── team-runner.py             # Multi-agent consensus orchestrator
├── registry.yaml              # Job definitions (schedules, budgets, prompts)
├── .env                       # Telegram credentials (git-ignored)
├── .env.template              # Template for .env
├── lib/
│   ├── common.sh              # Shared bash utilities (colors, logging, yq)
│   ├── jobsdb.py              # SQLite wrapper (replaces sqlite3 CLI)
│   ├── msgbus.sh              # SQLite event bus (send, query, reply, deliver)
│   ├── msg-relay.sh           # DND-aware notification delivery
│   ├── send-telegram.sh       # Telegram Bot API wrapper
│   ├── telegram-callback-handler.sh  # Two-way Telegram (buttons, text commands)
│   ├── sessions.sh            # Conversation memory (multi-turn JSONL)
│   ├── dashboard.sh           # Terminal status dashboard
│   ├── cost-report.sh         # Cost aggregation and alerting
│   ├── dispatcher-watchdog.sh # Heartbeat monitor (sends alert if dispatcher dies)
│   ├── weekly-digest.sh       # Summary report generator
│   └── autofix-scoring-rules.md  # Task automation scoring reference
├── personas/
│   ├── _template/             # Boilerplate for creating new personas
│   ├── investigator/          # Read-only analysis
│   ├── analyst/               # Web and data analysis
│   ├── researcher/            # Deep research with write access
│   ├── troubleshooter/        # Infrastructure diagnostics
│   ├── autofix-executor/      # Autonomous task execution (limited write)
│   └── task-investigator/     # Task automation readiness evaluation
├── state/
│   ├── jobs.db                # SQLite database (events, job_state)
│   └── locks/                 # Per-job lock files (prevent duplicates)
├── sessions/                  # Conversation history JSONL files
└── logs -> ../../logs/headless  # Symlink to log directory
```

## Job Registry Reference

Jobs are defined in `registry.yaml`. Every field:

```yaml
jobs:
  my-job:
    description: "Human-readable description"    # Required
    persona: investigator                        # Required — persona directory name
    schedule:                                     # Required
      type: interval                             # interval | daily | weekly | on-demand
      every_hours: 6                             # For interval type
      day: monday                                # For weekly type
      hour: 9                                    # For daily/weekly type
    enabled: true                                # true/false — dispatcher skips disabled jobs
    engine: claude-code                          # claude-code | ollama (default: from defaults)
    model: sonnet                                # Model name (default: from defaults)
    max_turns: 10                                # Max conversation turns (default: 10)
    max_budget_usd: 2.00                         # Cost cap per run (default: 2.00)
    timeout_minutes: 10                          # Hard timeout (default: 10)
    max_retries: 1                               # Retry on failure (default: 1)
    retry_backoff_hours: 1                       # Wait between retries (default: 1)
    api_retries: 3                               # Retry on transient API errors (500s, rate limits)
    pre_check: "bash command"                    # Skip job if exit != 0 (cost optimization)
    trigger:                                     # For on-demand jobs
      webhook: true                              # Enable webhook trigger
      parameters:                                # Named parameters passed to prompt
        - name: issue
          default: "full diagnostic"
    prompt: |                                    # The prompt sent to Claude/Ollama
      Your job instructions here...
```

## Creating a Custom Job

### Step 1: Choose or create a persona

```bash
# Copy the template
cp -r .claude/jobs/personas/_template .claude/jobs/personas/my-persona

# Edit the three files:
# - prompt.md — System prompt (role, context, constraints)
# - permissions.yaml — Tool access (allowed_tools, denied_tools, allowed_bash)
# - config.yaml — Engine, limits, output format
```

### Step 2: Add to registry

```yaml
# In registry.yaml under jobs:
  my-custom-job:
    description: "What this job does"
    persona: my-persona
    schedule:
      type: daily
      hour: 8
    enabled: true
    max_budget_usd: 1.00
    prompt: |
      Your instructions here. The persona's prompt.md is prepended
      automatically, so focus on the specific task.
```

### Step 3: Test it

```bash
# Run once manually
.claude/jobs/dispatcher.sh --run my-custom-job

# Check output
cat .claude/logs/headless/executions/latest-my-custom-job.json
```

## Persona System

Each persona defines a role with specific permissions and limits.

### Files

| File | Purpose |
|------|---------|
| `prompt.md` | System prompt injected before the job prompt |
| `permissions.yaml` | Tool grants/denials, bash patterns, pre-approved actions |
| `config.yaml` | Engine, model, budget, timeout, output format |

### Built-in Personas

| Persona | Access | Use For |
|---------|--------|---------|
| **investigator** | Read-only (no Edit/Write) | Health checks, analysis, reporting |
| **analyst** | Read + WebFetch/WebSearch | Research, data analysis, comparisons |
| **researcher** | Read + Write (reports only) | Deep research with output files |
| **troubleshooter** | Read + Docker + SSH | Infrastructure diagnostics |
| **autofix-executor** | Limited write (scoped paths) | Autonomous task execution |
| **task-investigator** | Read + Beads CLI | Task evaluation and labeling |

## Task Automation Pipeline

The framework includes a task automation pipeline that autonomously processes Beads tasks.

### Label Taxonomy

| Label | Meaning |
|-------|---------|
| `auto:candidate` | Likely automatable, needs investigation |
| `auto:ready` | Cleared for autonomous execution |
| `auto:blocked` | Requires human judgment |
| `risk:safe` | Fully reversible (renames, metadata, temp files) |
| `risk:moderate` | Reversible with effort (multi-file edits) |
| `risk:destructive` | Irreversible (content deletion, API calls) |

### Pipeline Flow

1. **task-score** — Labels unlabeled tasks with `auto:` and `risk:` scores
2. **task-investigator** — Evaluates `auto:candidate` tasks, promotes to `auto:ready` or marks `auto:blocked`
3. **task-executor** — Executes `auto:ready` + `risk:safe` tasks (max 10 per run, 3-min timeout each)

### Safety Controls

- Only `risk:safe` tasks are auto-executed (reversible actions only)
- `risk:moderate` requires individual human approval
- `risk:destructive` is always manual
- Git stash before changes, revert on failure
- Budget caps per run ($2.50 default)

## Engine Routing

Jobs can use Claude Code or Ollama:

| Engine | Cost | Tools | Best For |
|--------|------|-------|----------|
| `claude-code` | Pay per use | Full tool access | Complex tasks, file operations |
| `ollama` | Free (local) | No tools | Summaries, text generation, analysis |

Set per-job with `engine: ollama` and `model: "llama3.2"` in registry.yaml.

## Team Orchestration

For high-stakes decisions, use multi-agent teams with consensus rules.

```yaml
jobs:
  my-team-job:
    persona: investigator  # Coordinator persona
    team:
      consensus_rule: unanimous-approve  # or majority-approve, any-deny
      members:
        - name: feasibility
          persona: analyst
          model: sonnet
        - name: risk-assessor
          persona: investigator
          model: sonnet
```

Team members execute in parallel. Verdicts (approve/deny/uncertain) are collected and consensus rules applied. Conflicts escalate to Telegram for human decision.

## Notification Setup

### Telegram

1. Create a bot via [@BotFather](https://t.me/BotFather) on Telegram
2. Get your chat ID via [@userinfobot](https://t.me/userinfobot)
3. Copy `.env.template` to `.env` and fill in values:
   ```
   TELEGRAM_BOT_TOKEN=your_bot_token_here
   TELEGRAM_CHAT_ID=your_chat_id_here
   ```
4. Test: `.claude/jobs/lib/send-telegram.sh --message "Hello from AIfred" --severity info`

### Quiet Hours (DND)

Configure in `registry.yaml` under `quiet_hours`:
- Non-critical notifications are held until DND ends
- `critical` severity always delivers immediately
- `batch_release: true` sends all held messages when DND ends

### Future Channels

The notification architecture is pluggable. `msg-relay.sh` abstracts the delivery channel — currently routes to `send-telegram.sh`. Future channels (email, WhatsApp, webhook) can be added by implementing a new send script and updating the relay routing.

## Observability

### Dashboard

```bash
.claude/jobs/dispatcher.sh --dashboard          # Full interactive dashboard
.claude/jobs/dispatcher.sh --dashboard --summary # One-line status
.claude/jobs/dispatcher.sh --dashboard --costs   # Cost section only
.claude/jobs/dispatcher.sh --dashboard --json    # JSON output for integration
```

### Cost Tracking

```bash
.claude/jobs/lib/cost-report.sh --today          # Today's spend
.claude/jobs/lib/cost-report.sh --period weekly   # Weekly breakdown
.claude/jobs/lib/cost-report.sh --alert-threshold 5.00  # Alert if over $5
```

### Log Locations

| Log | Location |
|-----|----------|
| Dispatcher | `.claude/logs/headless/dispatcher.log` |
| Job outputs | `.claude/logs/headless/executions/<job>-<timestamp>.json` |
| Latest output | `.claude/logs/headless/executions/latest-<job>.json` (symlink) |
| Telegram callbacks | `.claude/logs/headless/callback.log` |
| Watchdog | `.claude/logs/headless/watchdog.log` |
| Relay | `.claude/logs/headless/relay.log` |

### Watchdog

The dispatcher-watchdog monitors the dispatcher's heartbeat file. If the dispatcher hasn't run in 15+ minutes, a critical Telegram alert is sent. Alerts are throttled to one per 4 hours.

## Troubleshooting

### Dispatcher not running
- Check cron: `crontab -l | grep dispatcher`
- Check logs: `tail -20 .claude/logs/headless/dispatcher.log`
- Verify `claude` is on PATH: `which claude`

### Job stuck / not executing
- Check locks: `ls .claude/jobs/state/locks/`
- Stale lock? Remove it: `rm .claude/jobs/state/locks/<job>.lock`
- Check pre_check: run the pre_check command manually

### Notifications not sending
- Verify .env has valid token/chat ID
- Test: `.claude/jobs/lib/send-telegram.sh --message "test" --severity info`
- Check quiet hours — is DND active? Use `--severity critical` to bypass

### Database issues
- Re-initialize: `python3 .claude/jobs/lib/jobsdb.py init`
- Check WAL mode: `python3 .claude/jobs/lib/jobsdb.py pragma "journal_mode"`
