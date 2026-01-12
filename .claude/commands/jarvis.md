---
description: Quick access menu for commonly used Jarvis commands
---

# Jarvis Command Menu

Display this menu of commonly used commands for quick reference and selection.

## Available Commands (Alphabetical)

| Command | Description |
|---------|-------------|
| `/agent` | Launch a specialized agent with optional model selection |
| `/checkpoint` | Save session state for MCP restart |
| `/clear` | Clear conversation context and start fresh |
| `/compact` | Compact conversation history |
| `/config` | View/edit Claude Code configuration |
| `/context` | Show current context usage breakdown |
| `/context-budget` | Detailed context budget analysis with recommendations |
| `/context-checkpoint` | Save state and prepare for context reset |
| `/create-project` | Create new project with standard structure |
| `/design-review` | PARC pattern design review |
| `/doctor` | Diagnose Claude Code issues |
| `/end-session` | Clean session exit with commit and documentation |
| `/export` | Export conversation to file |
| `/health-report` | System health verification |
| `/plan` | Enter plan mode for implementation design |
| `/register-project` | Register existing project in paths-registry |
| `/rename` | Rename the current conversation |
| `/resume` | Resume a previous conversation |
| `/setup` | Initial configuration wizard |
| `/setup-readiness` | Post-setup validation report |
| `/smart-compact` | Intelligent context management with MCP evaluation |
| `/stats` | Show conversation statistics |
| `/sync-aifred-baseline` | Analyze upstream AIfred changes for porting |
| `/todos` | Show current todo list |
| `/tooling-health` | Validate MCPs, plugins, hooks, and skills |
| `/trigger-clear` | Signal auto-clear watcher to send /clear |
| `/usage` | Show API usage statistics |
| `/validate-mcp` | Validate MCP installation and functionality |
| `/validate-selection` | Validate tool selection decisions |

---

## Quick Categories

### Session Management
- `/end-session` — Clean exit
- `/setup` — Initial config
- `/setup-readiness` — Validation

### Context Management
- `/context` — Usage breakdown
- `/context-budget` — Detailed analysis
- `/context-checkpoint` — Save state
- `/smart-compact` — Intelligent reset
- `/clear` — Full reset
- `/compact` — History compaction

### Health & Diagnostics
- `/tooling-health` — Full tooling check
- `/health-report` — System health
- `/doctor` — Issue diagnosis
- `/validate-mcp` — MCP validation

### Upstream & Sync
- `/sync-aifred-baseline` — Port from AIfred

### Project Management
- `/create-project` — New project setup
- `/register-project` — Register existing project
- `/design-review` — PARC design review

### Agents
- `/agent` — Launch specialized agent

### Orchestration (namespaced)
- `/orchestration:plan` — Decompose complex task into phases
- `/orchestration:status` — Show progress tree
- `/orchestration:resume` — Resume orchestration after break
- `/orchestration:commit` — Link commit to task

### Commits (namespaced)
- `/commits:status` — Cross-project commit status
- `/commits:summary` — Generate session commit summary

### Utilities
- `/config` — Configuration
- `/export` — Export chat
- `/plan` — Planning mode
- `/rename` — Rename chat
- `/resume` — Resume chat
- `/stats` — Statistics
- `/todos` — Todo list
- `/trigger-clear` — Signal auto-clear
- `/usage` — API usage
- `/validate-selection` — Selection quality check

---

*Type any command to execute. Use `/jarvis` anytime to see this menu.*
