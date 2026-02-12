# AIfred Headless Claude Jobs

Scheduled and on-demand AI-powered automation using the Headless Claude system.

**Last Updated**: 2026-02-12

---

## Quick Start

```bash
# List all registered jobs
.claude/jobs/dispatcher.sh --list

# Check what's due right now
.claude/jobs/dispatcher.sh --check

# Force-run a specific job
.claude/jobs/dispatcher.sh --run health-summary

# Preview execution (dry run)
.claude/jobs/executor.sh --job health-summary --dry-run

# View observability dashboard
.claude/jobs/dispatcher.sh --dashboard
```

---

## Architecture

```
dispatcher.sh (cron, every 5 min)
  ├── reads registry.yaml (job definitions + schedules)
  ├── checks state/last-run.json (when each job last ran)
  ├── launches executor.sh for due jobs
  └── runs lib/msg-relay.sh (delivers notifications)

executor.sh (per-job execution)
  ├── loads persona (prompt + permissions + config)
  ├── resolves engine (claude-code or ollama)
  ├── executes via claude -p or ollama API
  ├── extracts summary + severity from output
  ├── writes notification to message bus
  └── pushes metrics to Prometheus (if available)
```

---

## Personas (Safety Tiers)

| Persona | Tier | Can Do | Can't Do |
|---------|------|--------|----------|
| **investigator** | Read-only | Read files, check status, query services, search web | Modify files, create commits, change configs |
| **analyst** | Read + Write data | All investigator + write reports, create Beads tasks | Modify code, create commits |
| **troubleshooter** | Diagnose + Fix | All analyst + restart services, clear caches | Delete data, reboot machines (needs approval) |

Persona files: `.claude/jobs/personas/<name>/`
- `prompt.md` - System prompt defining behavior and constraints
- `permissions.yaml` - Allowed/denied tools and bash patterns
- `config.yaml` - Engine, limits, output settings

---

## Engines

| Engine | Cost | Speed | When to Use |
|--------|------|-------|-------------|
| `claude-code` | API pricing | Best quality | Complex analysis, multi-step tasks |
| `ollama` | $0 (local) | Fast, lower quality | Simple checks, summarization, triage |

Engine resolution priority: job config > persona config > registry defaults > claude-code

---

## Registry (registry.yaml)

### Included Template Jobs

| Job | Persona | Engine | Schedule | Purpose |
|-----|---------|--------|----------|---------|
| `health-summary` | investigator | claude-code | Every 12h | Infrastructure health check |
| `doc-sync-check` | investigator | claude-code | Weekly Sun 6am | Check for stale documentation |
| `ollama-test` | investigator | ollama | On-demand | Template for Ollama-powered jobs |

### Adding Custom Jobs

Add to `registry.yaml`:

```yaml
my-custom-job:
  description: "What this job does"
  persona: analyst              # investigator | analyst | troubleshooter
  model: sonnet                 # sonnet | haiku | llama3.2:3b (for ollama)
  engine: claude-code           # claude-code | ollama
  max_turns: 10
  max_budget_usd: 2.00
  schedule:
    type: interval              # interval | weekly | on-demand
    every_hours: 24
  prompt: |
    Your job instructions here...
```

---

## Support Libraries

| Script | Purpose |
|--------|---------|
| `lib/msgbus.sh` | Append-only message bus (events, questions, threads) |
| `lib/msg-relay.sh` | DND-aware delivery relay (polls bus, sends Telegram) |
| `lib/send-telegram.sh` | Telegram notification sender (messages + approval buttons) |
| `lib/dashboard.sh` | Terminal observability dashboard (status, costs, alerts) |
| `lib/cost-report.sh` | Cost aggregation (daily/weekly/today/alerts/JSON) |

### Message Bus (msgbus.sh)

```bash
# Write an event
lib/msgbus.sh send --type job_completed --source "headless:health" \
  --severity info --data '{"job":"health","summary":"All OK"}'

# Query events
lib/msgbus.sh query --type question_asked --status pending

# Check bus health
lib/msgbus.sh health

# View state
lib/msgbus.sh state
```

### Dashboard

```bash
dispatcher.sh --dashboard              # Full terminal dashboard
dispatcher.sh --dashboard --summary    # One-line status
dispatcher.sh --dashboard --json       # JSON output
dispatcher.sh --dashboard --costs      # Cost section only
```

### Notification History

```bash
dispatcher.sh --history                # Last 20 notifications
dispatcher.sh --history 50             # Last 50
dispatcher.sh --history --severity critical  # Critical only
dispatcher.sh --history --job health-summary # By job
dispatcher.sh --ack <id>               # Acknowledge alert
```

---

## Notifications (Telegram)

### Setup

1. Create a Telegram bot via [@BotFather](https://t.me/BotFather)
2. Get your chat ID via [@userinfobot](https://t.me/userinfobot)
3. Copy `.env.template` to `.env` and fill in:

```bash
cp .claude/jobs/.env.template .claude/jobs/.env
# Edit with your bot token and chat ID
```

### Quiet Hours (DND)

Configure in `registry.yaml` under `quiet_hours`:
- Weekday: 10 PM - 7 AM (default)
- Weekend: 11 PM - 9 AM (default)
- Critical severity bypasses DND

### Delivery Behavior

| Severity | DND Active | DND Inactive |
|----------|-----------|--------------|
| critical | Delivers (bypass) | Delivers |
| warning | Queued until DND ends | Delivers |
| info | Silent (recorded, not sent) | Silent |
| question | Always delivers | Delivers |

---

## Prometheus Metrics

If you have a Pushgateway running, executor.sh automatically pushes metrics:

```bash
# Metrics pushed per job execution:
headless_job_duration_seconds{engine, model, severity}
headless_job_cost_usd{engine, model}
headless_job_success{engine, model}
headless_job_last_run_timestamp_seconds{engine, model}
headless_job_runs_total{engine, model, status}
```

Configure: `PUSHGATEWAY_URL` environment variable (default: `http://localhost:9091`)

---

## Cron Setup

Single cron entry runs the dispatcher every 5 minutes:

```bash
crontab -e
# Add:
*/5 * * * * /path/to/aifred/.claude/jobs/dispatcher.sh >> /path/to/aifred/.claude/logs/headless/dispatcher.log 2>&1
```

The dispatcher handles all scheduling logic — individual jobs don't need their own cron entries.

---

## Legacy Scripts

These standalone scripts predate the Headless Claude system and can run independently:

| Script | Purpose | Schedule |
|--------|---------|----------|
| `memory-prune.sh` | Archive stale Memory MCP entities | Manual/Weekly |
| `context-staleness.sh` | Find outdated context files | Manual/Weekly |

---

## File Structure

```
.claude/jobs/
├── dispatcher.sh          # Master scheduler (cron entry point)
├── executor.sh            # Per-job execution engine
├── registry.yaml          # Job definitions and schedules
├── .env.template          # Telegram credentials template
├── .gitignore             # Runtime files exclusion
├── README.md              # This file
├── lib/
│   ├── msgbus.sh          # Message bus CLI
│   ├── msg-relay.sh       # DND-aware delivery relay
│   ├── send-telegram.sh   # Telegram sender
│   ├── dashboard.sh       # Observability dashboard
│   └── cost-report.sh     # Cost aggregation
├── personas/
│   ├── investigator/      # Read-only observer
│   │   ├── prompt.md
│   │   ├── permissions.yaml
│   │   └── config.yaml
│   ├── analyst/           # Research + write reports
│   │   ├── prompt.md
│   │   ├── permissions.yaml
│   │   └── config.yaml
│   └── troubleshooter/    # Diagnose + safe fixes
│       ├── prompt.md
│       ├── permissions.yaml
│       └── config.yaml
├── state/                 # Runtime state (gitignored)
│   ├── last-run.json
│   └── locks/
├── memory-prune.sh        # Legacy standalone script
└── context-staleness.sh   # Legacy standalone script
```

---

*AIfred Headless Claude v1.0 (2026-02-12)*
