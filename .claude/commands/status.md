---
name: status
description: Display autonomic system status with component health and recent activity
category: monitoring
allowedPrompts:
  - tool: Bash
    prompt: run status report scripts
---

# /status Command

Display the current status of all autonomic components (AC-01 through AC-09).

## Execution Steps

1. Run benchmark tests to verify component health
2. Calculate scores from benchmark + telemetry data
3. Display component grades and recent activity
4. Show any active issues or warnings

## Output Format

```
╔══════════════════════════════════════════════════════════════╗
║              JARVIS AUTONOMIC SYSTEM STATUS                   ║
╠══════════════════════════════════════════════════════════════╣
║  Session Score: XX% (Grade)                                   ║
║  Components: X/9 operational                                  ║
╚══════════════════════════════════════════════════════════════╝

Component Status:
  AC-01 Self-Launch      [████████████] A+ | Active
  AC-02 Wiggum Loop      [████████████] A+ | Idle
  AC-03 Milestone Review [████████████] A+ | Idle
  AC-04 JICM            [████████████] A+ | Monitoring
  AC-05 Self-Reflection  [████████████] A+ | Idle
  AC-06 Self-Evolution   [████████████] A+ | Idle
  AC-07 R&D Cycles       [████████████] A+ | Idle
  AC-08 Maintenance      [████████████] A+ | Idle
  AC-09 Session Complete [████████████] A+ | Idle

Recent Activity:
  - [timestamp] AC-02: Iteration 5 started
  - [timestamp] AC-04: Context at 45%
  - [timestamp] AC-05: Correction captured

Alerts:
  (none)
```

## Implementation

Run the following commands to generate status:

```bash
# Run component benchmarks
node .claude/scripts/benchmark-runner.js --all --json

# Calculate scores
node .claude/scripts/scoring-engine.js --session --json

# Query recent telemetry
node .claude/scripts/telemetry-query.js --days 1 --aggregate daily --json
```

Then format the combined output for display.

## Related Commands

- `/health` - Detailed component health
- `/tooling-health` - MCP and plugin status
- `/context-budget` - Context usage analysis
