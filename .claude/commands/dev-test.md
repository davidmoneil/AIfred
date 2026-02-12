---
description: Run dev-ops tests against W0:Jarvis from Jarvis-dev
argument-hint: [suite|jicm|ipc|hooks|all]
allowed-tools: [Bash, Read, Glob, Grep]
---

# /dev-test — Autonomous Testing of W0:Jarvis

Run from Jarvis-dev (W5) to test the primary Jarvis session (W0).

## Usage

```
/dev-test              # Run everything (suite + jicm + ipc + hooks)
/dev-test suite        # Automated infrastructure test runner only
/dev-test jicm         # JICM compression cycle test (autonomous)
/dev-test ipc          # Command signal IPC test
/dev-test hooks        # Hook signal file validation
```

## Instructions

1. **Read the dev-ops Skill** for detailed workflow steps:
   Read @.claude/skills/dev-ops/SKILL.md

2. **Determine which test suite** to run from `$ARGUMENTS`:
   - `all` or empty: Run Workflow 1 (suite), then Workflow 2 (jicm), then Workflow 3 (ipc), then Workflow 4 (hooks)
   - `suite`: Run Workflow 1 only (automated test runner)
   - `jicm`: Run Workflow 2 only (JICM cycle — autonomous)
   - `ipc`: Run Workflow 3 only (command signal IPC)
   - `hooks`: Run Workflow 4 only (hook validation)

3. **Execute the workflow** step-by-step using Bash tool calls to the dev scripts.

4. **Report results** with pass/fail counts and any error details.

## Prerequisites

- Launched via `launch-jarvis-tmux.sh --dev`
- W0 (Jarvis) active and idle
- W1 (Watcher) running in tmux
