---
name: task-dashboard
version: 1.0.0
description: Formatted task dashboard with categorized labels and priority grouping
category: task-management
tags: [tasks, beads, dashboard, cli-backed]
created: 2026-03-04
context: fork
allowed-tools:
  - Bash(npx tsx:*)
  - Read
---

# Task Dashboard Skill

Deterministic, zero-token task view that reads `.beads/issues.jsonl` directly and outputs pre-formatted markdown tables with parsed label categories.

---

## Overview

| Aspect | Description |
|--------|-------------|
| Purpose | Formatted Beads task views with label categorization |
| Pattern | Type 1: CLI-Backed (Deterministic) |
| When to Use | Viewing tasks, filtering by domain/project, getting stats |

---

## Quick Actions

| Need | Command |
|------|---------|
| Full categorized view | `/tasks` or `/tasks summary` |
| Actionable tasks only | `/tasks ready` |
| Filter by domain | `/tasks domain infrastructure` |
| Filter by project | `/tasks project aurora` |
| Label statistics | `/tasks stats` |

---

## Commands

### `/tasks` (or `/tasks summary`)

Full categorized table view. Groups by status (in_progress first, then open by priority).

Columns: ID, Task, Priority, Owner, Domain, Project, Type, Source, Flags

### `/tasks ready`

Only unblocked, actionable tasks (no `auto:blocked` label, status=open).

### `/tasks domain <name>`

Filter open/in_progress tasks by domain label (e.g., `infrastructure`, `coding`, `security`).

### `/tasks project <name>`

Filter open/in_progress tasks by project label (e.g., `aurora`, `my-project`).

### `/tasks stats`

Label summary counts -- how many tasks per domain, project, type, source, etc.

---

## Data Source

Reads `.beads/issues.jsonl` directly -- no `bd` CLI subprocess needed.

---

## Related

- [Beads Reference](../../context/tools/beads-reference.md) - Full CLI reference
- [Infrastructure Ops](../infrastructure-ops/SKILL.md) - Task metrics via `/metrics`
