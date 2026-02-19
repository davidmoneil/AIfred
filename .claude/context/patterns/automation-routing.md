# Automation Routing Pattern

When user asks to "schedule", "automate", or "run on cron", apply this decision tree:

```
Is it deterministic (same input -> same output)?
+-- YES -> Use pure bash script (capability layering)
|          Location: scripts/ or .claude/jobs/
|
+-- NO  -> Does it require AI judgment?
           +-- YES -> Use Headless Claude system
           |          Registry: .claude/jobs/registry.yaml
           |          Dispatcher: .claude/jobs/dispatcher.sh
           |
           +-- MAYBE -> Hybrid approach
                        Bash for deterministic parts, Claude for analysis
```

## Headless Claude Quick Commands

```bash
# List all registered jobs
.claude/jobs/dispatcher.sh --list

# Check what's due now
.claude/jobs/dispatcher.sh --check

# Force-run a specific job
.claude/jobs/dispatcher.sh --run health-summary

# Preview execution (dry run)
.claude/jobs/executor.sh --job health-summary --dry-run

# Observability dashboard
.claude/jobs/dispatcher.sh --dashboard
```

## Persona Safety Model

| Persona | Tier | Allowed Actions |
|---------|------|----------------|
| **investigator** | Read-only | Health checks, monitoring, analysis |
| **analyst** | Read + write data | Upgrade discovery, data collection |
| **troubleshooter** | Diagnose + fix | Service restarts, cache clearing |

## Cron Setup

Single entry, dispatcher handles all scheduling:
```bash
*/5 * * * * /path/to/aifred/.claude/jobs/dispatcher.sh >> /path/to/aifred/.claude/logs/headless/dispatcher.log 2>&1
```

Full documentation: @.claude/jobs/README.md
