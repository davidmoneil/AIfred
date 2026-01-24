---
name: jarvis-status
version: 1.0.0
description: |
  Display Jarvis autonomic system status with component health and grades.
  Use when: user asks "jarvis status", "autonomic status", "AC component status",
  "system health", "show AC grades", "how are the autonomic components doing".
  Shows AC-01 through AC-09 operational status, grades, and recent activity.
category: monitoring
tags: [status, health, autonomic, components, grades]
created: 2026-01-23
user_invocable: true
arguments:
  - name: verbose
    description: Show detailed component information
    required: false
---

# Jarvis Status Skill

Display the current status of all Jarvis autonomic components (AC-01 through AC-09).

---

## Overview

This skill provides visibility into the Jarvis autonomic system health, showing:
- Component operational status
- Health grades (A+ through F)
- Recent activity logs
- Active alerts and warnings

**Note**: This is different from Claude Code's native `/status` command which shows session information. This skill shows Jarvis-specific autonomic component health.

---

## Output Format

```
+--------------------------------------------------------------+
|              JARVIS AUTONOMIC SYSTEM STATUS                   |
+--------------------------------------------------------------+
|  Session Score: XX% (Grade)                                   |
|  Components: X/9 operational                                  |
+--------------------------------------------------------------+

Component Status:
  AC-01 Self-Launch      [############] A+ | Active
  AC-02 Wiggum Loop      [############] A+ | Idle
  AC-03 Milestone Review [############] A+ | Idle
  AC-04 JICM            [############] A+ | Monitoring
  AC-05 Self-Reflection  [############] A+ | Idle
  AC-06 Self-Evolution   [############] A+ | Idle
  AC-07 R&D Cycles       [############] A+ | Idle
  AC-08 Maintenance      [############] A+ | Idle
  AC-09 Session Complete [############] A+ | Idle

Recent Activity:
  - [timestamp] AC-02: Iteration 5 started
  - [timestamp] AC-04: Context at 45%
  - [timestamp] AC-05: Correction captured

Alerts:
  (none)
```

---

## Execution Steps

To generate the status display:

1. **Run Component Benchmarks**
```bash
node .claude/scripts/benchmark-runner.js --all --json
```

2. **Calculate Scores**
```bash
node .claude/scripts/scoring-engine.js --session --json
```

3. **Query Recent Telemetry**
```bash
node .claude/scripts/telemetry-query.js --days 1 --aggregate daily --json
```

4. **Format Output**
Combine the JSON outputs and format for display.

---

## Component Grades

| Grade | Score Range | Meaning |
|-------|-------------|---------|
| A+ | 95-100% | Excellent, fully operational |
| A | 90-94% | Very good, minor issues |
| B | 80-89% | Good, some degradation |
| C | 70-79% | Fair, needs attention |
| D | 60-69% | Poor, significant issues |
| F | <60% | Failing, requires intervention |

---

## Components Overview

| Component | Purpose | Activity States |
|-----------|---------|-----------------|
| AC-01 Self-Launch | Session initialization | Active, Complete |
| AC-02 Wiggum Loop | Iterative work execution | Active, Idle |
| AC-03 Milestone Review | Work completion validation | Active, Idle |
| AC-04 JICM | Context management | Monitoring, Compacting |
| AC-05 Self-Reflection | Learning capture | Active, Idle |
| AC-06 Self-Evolution | Self-improvement | Active, Idle |
| AC-07 R&D Cycles | Research execution | Active, Idle |
| AC-08 Maintenance | System health | Active, Idle |
| AC-09 Session Complete | Exit procedures | Active, Idle |

---

## Quick Actions

| Need | Action |
|------|--------|
| Native Claude status | Use `/status` (native command) |
| Jarvis autonomic status | This skill |
| Detailed health report | `/tooling-health` command |
| Context usage | `/context` (native command) |

---

## Related

- Component Specs: @.claude/context/components/
- Scoring Framework: @.claude/context/infrastructure/scoring-framework.md
- Benchmark Suite: @.claude/context/infrastructure/benchmark-suite.md
- Native Status: Use `/status` command for Claude Code session info

---

*Jarvis Status Skill v1.0.0*
