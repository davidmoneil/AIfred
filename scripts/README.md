# Scripts

**Purpose**: System-level utilities — setup, health checks, scheduled jobs.

**Layer**: Body (infrastructure)

---

## Contents

| Script | Purpose |
|--------|---------|
| `setup-readiness.sh` | Pre-setup validation |
| `validate-hooks.sh` | Hook integrity checks |
| `bump-version.sh` | Version management |
| `weekly-health-check.sh` | Scheduled health monitoring |
| `weekly-docker-restart.sh` | Scheduled Docker maintenance |
| `weekly-context-analysis.sh` | Scheduled context review |
| `update-priorities-health.sh` | Priority file monitoring |
| `config.sh.template` | Configuration template |
| `systemd/` | Systemd service definitions |

## What Belongs Here

- Setup and installation scripts
- Scheduled maintenance jobs
- System-level utilities
- Health monitoring

## What Does NOT Belong Here

- Session-operational scripts → `/.claude/scripts/`
- MCP management → `/.claude/scripts/`
- Signal-based automation → `/.claude/scripts/`

## Key Distinction

**System scripts** (here): Run once, scheduled, or system-level
**Operational scripts** (`/.claude/scripts/`): Used during active sessions

---

*Jarvis — Body Layer (Infrastructure)*
