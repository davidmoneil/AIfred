# Scripts

**Purpose**: Operational scripts used during active sessions.

**Layer**: Pneuma (capabilities)

---

## Categories

### MCP Management
- `mcp-enable.sh`, `mcp-disable.sh`, `mcp-status.sh`
- `suggest-mcps.sh` — Keyword-to-MCP mapping

### Signal-Based Automation
- `signal-helper.sh` — Signal utility functions
- `jicm-watcher.sh` — JICM v6.1 context watcher (stop-and-wait architecture)
- `jarvis-watcher.sh` — Legacy v5 watcher (command signal execution only)

### Context Management
- `context-checkpoint.sh` — Save context state
- `restore-context.sh` — Restore from checkpoint

### Benchmarking & Scoring
- `benchmark-runner.js` — Execute benchmarks
- `scoring-engine.js` — Calculate scores
- `telemetry-collector.js`, `telemetry-analyzer.js`

### Setup & Validation
- `setup-*.sh` — Setup phase scripts
- `validate-*.sh` — Validation scripts

## What Does NOT Belong Here

- System-level utilities → `/Jarvis/scripts/`
- Weekly scheduled jobs → `/Jarvis/scripts/`

## Key Distinction

**Operational scripts** (here): Used during active sessions
**System scripts** (`/Jarvis/scripts/`): Setup, weekly health, system-level

---

*Jarvis — Pneuma Layer (Capabilities)*
