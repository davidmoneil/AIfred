---
description: Show current orchestration progress with visual task tree
allowed-tools:
  - Read
  - Glob
model: haiku
---

# Task Orchestration: Status

Display the current state of active orchestrations.

## Process

### 1. Find Active Orchestrations

Search `.claude/orchestration/*.yaml` for files where `status: active` or `status: paused`.

### 2. For Each Orchestration

Parse the YAML and calculate:
- Total tasks count
- Completed tasks count
- Completion percentage
- Current phase (first non-completed phase)
- Next available tasks (pending with no unmet dependencies)
- Blocked tasks and their blockers

### 3. Display Task Tree

Format as visual tree with status icons:

```
📋 Build Authentication System (35% complete)
│
├── ✅ Phase 1: Foundation (100%)
│   ├── ✅ T1.1: Set up auth middleware
│   └── ✅ T1.2: Create user model
│
├── 🔄 Phase 2: Implementation (50%)
│   ├── ✅ T2.1: Login endpoint
│   ├── 🔄 T2.2: Registration endpoint (IN PROGRESS)
│   └── ⏳ T2.3: Password reset (blocked by T2.2)
│
└── 🔒 Phase 3: Testing (0%)
    └── ⏳ T3.1: Integration tests (blocked by Phase 2)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 Progress: 4/8 tasks (50%)
⏱️  Estimated remaining: 6h
🎯 Next available: T2.2 (Registration endpoint)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Status Icons

| Icon | Meaning |
|------|---------|
| ✅ | Completed |
| 🔄 | In Progress |
| ⏳ | Pending (ready to start) |
| 🔒 | Blocked (dependencies not met) |

### 4. Multiple Orchestrations

If multiple active orchestrations exist, show summary first:

```
📋 Active Orchestrations (2)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
1. Build Authentication System - 50% (4/8 tasks)
2. API Documentation Update - 25% (2/8 tasks)

Showing details for: Build Authentication System
[task tree follows]
```

### 5. No Active Orchestrations

If none found:

```
📋 No active orchestrations found.

Recent completed:
- 2026-01-01-setup-wizard.yaml (archived)

To create one:
- /orchestration:plan "your task description"
- Or describe a complex task and let the detector suggest it
```
