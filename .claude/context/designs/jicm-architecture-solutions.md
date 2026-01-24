# JICM Architecture Solutions — Complete Redesign

**Author**: Jarvis Autonomous Archon
**Date**: 2026-01-23
**Version**: 3.0.0
**Status**: Design Complete — Ready for Implementation

---

## Executive Summary

This document presents **three complete architecture solutions** for Jarvis Intelligent Context Management (JICM). Each solution addresses the core requirements of autonomous context monitoring, AI-driven compression prioritization, and seamless session liftover.

**Critical Discovery**: Claude Code's statusline API provides official JSON with `context_window.used_percentage`. The current watcher uses fragile tmux pane scraping—this must be replaced with the official API.

### Solution Overview

| Solution | Complexity | Reliability | Token Efficiency | Implementation Time |
|----------|------------|-------------|------------------|---------------------|
| **A: Statusline-Unified** | Low | High | Medium | 1 session |
| **B: Hook-Orchestrated** | Medium | Very High | High | 2 sessions |
| **C: Agent-Autonomous** | High | Highest | Highest | 3+ sessions |

---

## Problem Statement

### Current Issues

1. **Fragile Token Detection**: `jarvis-watcher.sh` scrapes tmux pane for "X tokens" pattern
   ```bash
   # Current approach (lines 126-138 of jarvis-watcher.sh)
   pane_content=$("$TMUX_BIN" capture-pane -t "$TMUX_TARGET" -p 2>/dev/null)
   token_line=$(echo "$pane_content" | grep -oE '[0-9,]+ tokens' | tail -1)
   ```
   - Depends on UI format remaining constant
   - Fails silently when pattern not found
   - Cannot distinguish categories (input vs output tokens)

2. **Disconnected Infrastructure**:
   - `statusline-context-capture.sh` writes to `.statusline-context.json`
   - Watcher ignores this file and scrapes tmux instead
   - Duplicate data paths cause confusion

3. **Three Redundant Watchers**:
   - `jarvis-watcher.sh` (primary)
   - `auto-command-watcher.sh` (legacy)
   - `auto-clear-watcher.sh` (legacy)
   - Inconsistent defaults, race conditions, PID file conflicts

4. **Missing AI-Driven Prioritization**:
   - Current compression is uniform (compress everything equally)
   - No understanding of what context is needed for current/upcoming tasks
   - No task-aware preservation

### Requirements for Redesign

1. **Reliable Context Monitoring**: Use official Claude Code API, not UI scraping
2. **Consolidated Watcher**: Single authoritative watcher script
3. **AI-Driven Compression**: Understand task context, preserve relevant content
4. **Archon Architecture Alignment**: Follow Nous/Pneuma/Soma principles
5. **Fire-and-Forget Automation**: No blocking waits per self-interruption-prevention pattern

---

## Solution A: Statusline-Unified Architecture

**Approach**: Replace tmux scraping with statusline JSON file reading. Minimal changes, maximum reliability improvement.

### Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                        Claude Code Session                           │
│                                                                       │
│  ┌──────────────┐     ┌─────────────────────────────┐               │
│  │   User       │     │     Claude Response         │               │
│  │   Prompt     │────▶│     (using context)         │               │
│  └──────────────┘     └─────────────────────────────┘               │
│                                    │                                 │
│                                    ▼                                 │
│  ┌──────────────────────────────────────────────────────────────┐   │
│  │                     Status Line System                        │   │
│  │  ┌────────────────────────────────────────────────────────┐  │   │
│  │  │  statusline-context-capture.sh                          │  │   │
│  │  │    - Receives JSON via stdin (official API)             │  │   │
│  │  │    - Writes to .statusline-context.json                 │  │   │
│  │  │    - Displays progress bar                              │  │   │
│  │  └─────────────────────┬──────────────────────────────────┘  │   │
│  └────────────────────────│─────────────────────────────────────┘   │
└───────────────────────────│─────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────────┐
│              External: jarvis-watcher.sh (unified)                   │
│                                                                       │
│  ┌────────────────────────────────────────────────────────────────┐ │
│  │  get_context_status() — NEW FUNCTION                           │ │
│  │    - Reads .statusline-context.json (NOT tmux scrape)          │ │
│  │    - Parses: used_percentage, input_tokens, remaining_pct      │ │
│  │    - Returns structured data                                    │ │
│  └────────────────────────────────────────────────────────────────┘ │
│                            │                                         │
│                            ▼                                         │
│  ┌────────────────────────────────────────────────────────────────┐ │
│  │  Threshold Logic (unchanged)                                    │ │
│  │    50% → Log warning                                            │ │
│  │    70% → Checkpoint, continue                                   │ │
│  │    80% → JICM trigger, /intelligent-compress                    │ │
│  │    95% → Emergency /clear                                       │ │
│  └────────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────┘
```

### Key Changes

#### 1. Replace `get_token_count()` with `get_context_status()`

```bash
# NEW: Read from statusline JSON file (official API)
get_context_status() {
    local context_file="$PROJECT_DIR/.claude/context/.statusline-context.json"

    if [[ ! -f "$context_file" ]]; then
        echo '{"used_percentage": 0, "remaining_percentage": 100, "total_tokens": 0}'
        return 1
    fi

    # Check file freshness (should be updated every 300ms by statusline)
    local file_age
    file_age=$(( $(date +%s) - $(stat -f %m "$context_file" 2>/dev/null || echo 0) ))

    if [[ $file_age -gt 60 ]]; then
        log WARN "Context file stale (${file_age}s old)"
    fi

    cat "$context_file"
}

# Parse specific values
get_used_percentage() {
    get_context_status | jq -r '.context_window.used_percentage // 0'
}

get_remaining_tokens() {
    local status
    status=$(get_context_status)
    local size=$(echo "$status" | jq -r '.context_window.context_window_size // 200000')
    local used=$(echo "$status" | jq -r '.context_window.used_percentage // 0')
    echo "scale=0; $size * (100 - $used) / 100" | bc
}
```

#### 2. Consolidate to Single Watcher

Delete:
- `auto-clear-watcher.sh` (redundant)
- `auto-command-watcher.sh` (redundant)

Keep:
- `jarvis-watcher.sh` (enhanced with statusline integration)

#### 3. Configuration File

Create `autonomy-config.yaml` as single source of truth:

```yaml
# .claude/config/autonomy-config.yaml
jicm:
  version: "3.0.0"

  # Context thresholds (percentage)
  thresholds:
    healthy: 50       # Normal operation
    caution: 60       # Log warning
    warning: 70       # Create soft checkpoint
    critical: 80      # JICM trigger, intelligent compress
    emergency: 95     # Force immediate /clear

  # Polling configuration
  polling:
    interval_seconds: 30      # How often to check context
    max_stale_seconds: 60     # Max age before context file considered stale

  # Token limits
  tokens:
    context_window: 200000    # Total context window
    effective_limit: 180000   # Practical limit before performance degradation
    output_max: 20000         # Max output tokens per response

watcher:
  pid_file: ".claude/context/.watcher-pid"
  log_file: ".claude/logs/jarvis-watcher.log"
  status_file: ".claude/context/.watcher-status"

signals:
  command_file: ".claude/context/.command-signal"
  clear_ready_file: ".claude/context/.clear-ready-signal"
  jicm_trigger_file: ".claude/context/.jicm-trigger"
```

### Implementation Steps

1. **Update `jarvis-watcher.sh`**: Replace `get_token_count()` with `get_context_status()`
2. **Delete legacy watchers**: Remove `auto-clear-watcher.sh`, `auto-command-watcher.sh`
3. **Create config file**: `autonomy-config.yaml` with all settings
4. **Update launch scripts**: Read from config file instead of hardcoded values
5. **Test**: Verify statusline JSON is being read correctly

### Advantages

- **Minimal changes**: Only watcher needs updating
- **High reliability**: Uses official API instead of UI scraping
- **No new dependencies**: Uses existing infrastructure
- **Quick implementation**: Single session

### Limitations

- **No AI-driven prioritization**: Still uses uniform compression
- **No task awareness**: Doesn't know what context is important

---

## Solution B: Hook-Orchestrated Architecture

**Approach**: Add PreCompact hook that triggers AI-powered context analysis before any compression occurs. Maintains separation of concerns.

### Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                        Context Threshold Reached                      │
│                              (80%+)                                   │
└───────────────────────────────────┬─────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────┐
│                    PreCompact Hook (NEW)                             │
│                                                                       │
│  ┌────────────────────────────────────────────────────────────────┐ │
│  │  1. Read .statusline-context.json                              │ │
│  │  2. Read current-priorities.md                                  │ │
│  │  3. Read session-state.md                                       │ │
│  │  4. Analyze: What context is essential for current work?        │ │
│  │  5. Generate preservation_manifest.json                         │ │
│  └────────────────────────────────────────────────────────────────┘ │
│                            │                                         │
│                            ▼                                         │
│  ┌────────────────────────────────────────────────────────────────┐ │
│  │  preservation_manifest.json                                     │ │
│  │  {                                                              │ │
│  │    "preserve": [                                                │ │
│  │      {"type": "todo_list", "priority": "critical"},            │ │
│  │      {"type": "file_content", "path": "src/api.ts"},           │ │
│  │      {"type": "decision", "summary": "Use hook approach"}      │ │
│  │    ],                                                           │ │
│  │    "compress": [                                                │ │
│  │      {"type": "tool_output", "age_minutes": 30},               │ │
│  │      {"type": "exploration", "relevance": "low"}               │ │
│  │    ],                                                           │ │
│  │    "discard": [                                                 │ │
│  │      {"type": "error_trace", "resolved": true}                 │ │
│  │    ]                                                            │ │
│  │  }                                                              │ │
│  └────────────────────────────────────────────────────────────────┘ │
└───────────────────────────────────┬─────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────┐
│                   Context Compressor Agent                           │
│                                                                       │
│  ┌────────────────────────────────────────────────────────────────┐ │
│  │  Reads preservation_manifest.json                               │ │
│  │  Generates smart checkpoint with priorities:                    │ │
│  │    - Critical items included verbatim                          │ │
│  │    - Important items summarized                                 │ │
│  │    - Low-priority items referenced by path only                │ │
│  └────────────────────────────────────────────────────────────────┘ │
│                            │                                         │
│                            ▼                                         │
│  ┌────────────────────────────────────────────────────────────────┐ │
│  │  .soft-restart-checkpoint.md                                    │ │
│  │  (2-5K tokens, prioritized by manifest)                        │ │
│  └────────────────────────────────────────────────────────────────┘ │
└───────────────────────────────────┬─────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────┐
│                     SessionStart Hook                                │
│                                                                       │
│  ┌────────────────────────────────────────────────────────────────┐ │
│  │  Detects checkpoint + manifest                                  │ │
│  │  Injects additionalContext for auto-resume                      │ │
│  │  Prioritizes restoration based on manifest                      │ │
│  └────────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────┘
```

### New Hook: PreCompact Context Analyzer

```javascript
// .claude/hooks/precompact-analyzer.js
const fs = require('fs');
const path = require('path');

module.exports = async function(event) {
    const projectDir = process.env.CLAUDE_PROJECT_DIR || process.cwd();

    // Only run for auto-compact, not manual /compact
    if (event.type === 'manual') {
        return { continue: true };
    }

    // Read current context status
    const contextFile = path.join(projectDir, '.claude/context/.statusline-context.json');
    const prioritiesFile = path.join(projectDir, '.claude/context/current-priorities.md');
    const stateFile = path.join(projectDir, '.claude/context/session-state.md');

    let contextData = {};
    let priorities = '';
    let sessionState = '';

    try {
        contextData = JSON.parse(fs.readFileSync(contextFile, 'utf8'));
        priorities = fs.readFileSync(prioritiesFile, 'utf8');
        sessionState = fs.readFileSync(stateFile, 'utf8');
    } catch (e) {
        console.error('Failed to read context files:', e.message);
    }

    // Generate preservation manifest
    const manifest = {
        timestamp: new Date().toISOString(),
        context_used_pct: contextData.context_window?.used_percentage || 0,
        preserve: [],
        compress: [],
        discard: []
    };

    // Extract active tasks from priorities
    const activeTasks = extractActiveTasks(priorities);
    activeTasks.forEach(task => {
        manifest.preserve.push({
            type: 'task',
            content: task,
            priority: 'critical'
        });
    });

    // Extract key decisions from session state
    const decisions = extractDecisions(sessionState);
    decisions.forEach(decision => {
        manifest.preserve.push({
            type: 'decision',
            content: decision,
            priority: 'high'
        });
    });

    // Write manifest for compressor agent
    const manifestPath = path.join(projectDir, '.claude/context/.preservation-manifest.json');
    fs.writeFileSync(manifestPath, JSON.stringify(manifest, null, 2));

    return {
        continue: true,
        additionalContext: `JICM Pre-Compact Analysis Complete. Manifest written to ${manifestPath}`
    };
};

function extractActiveTasks(priorities) {
    const tasks = [];
    const lines = priorities.split('\n');
    let inActiveSection = false;

    for (const line of lines) {
        if (line.includes('## Active') || line.includes('## Current')) {
            inActiveSection = true;
        } else if (line.startsWith('## ')) {
            inActiveSection = false;
        } else if (inActiveSection && line.match(/^[-*]\s+\[[ x]\]/)) {
            tasks.push(line.trim());
        }
    }

    return tasks;
}

function extractDecisions(sessionState) {
    const decisions = [];
    const lines = sessionState.split('\n');

    for (const line of lines) {
        if (line.includes('Decision:') || line.includes('Decided:') || line.includes('chose')) {
            decisions.push(line.trim());
        }
    }

    return decisions;
}
```

### Hook Configuration

```json
// Add to hooks.json
{
  "hooks": [
    {
      "event": "PreCompact",
      "matcher": { "type": "auto" },
      "commands": [
        {
          "command": "node $CLAUDE_PROJECT_DIR/.claude/hooks/precompact-analyzer.js"
        }
      ]
    }
  ]
}
```

### Enhanced Context Compressor Agent

Update the context-compressor agent to read preservation manifest:

```yaml
# .claude/agents/context-compressor.md (enhanced)
---
name: context-compressor
description: AI-powered context compression with task-aware prioritization
model: opus
max_turns: 5
---

## Context Compressor Agent

You compress conversation context intelligently, preserving what matters most.

### Input Files

1. **Preservation Manifest** (`.claude/context/.preservation-manifest.json`)
   - Lists items to preserve, compress, or discard
   - Priority levels: critical, high, medium, low

2. **Current Priorities** (`.claude/context/current-priorities.md`)
   - Active tasks and their status

3. **Session State** (`.claude/context/session-state.md`)
   - Work in progress, decisions made

### Compression Protocol

1. Read preservation manifest
2. For each category:
   - **Critical**: Include verbatim
   - **High**: Include with concise summary
   - **Medium**: Reference by path/name only
   - **Low**: Omit entirely
3. Generate checkpoint under 5K tokens
4. Write to `.soft-restart-checkpoint.md`
5. Signal ready for /clear
```

### Implementation Steps

1. **Create PreCompact hook**: `precompact-analyzer.js`
2. **Register hook**: Add to `hooks.json`
3. **Update context-compressor agent**: Read manifest, prioritize accordingly
4. **Update SessionStart hook**: Restore based on manifest priorities
5. **Test**: Trigger compression at 80%, verify manifest used

### Advantages

- **AI-driven prioritization**: Understands what context matters
- **Task-aware compression**: Preserves active work
- **Separation of concerns**: Hook analyzes, agent compresses
- **Extensible**: Easy to add new preservation rules

### Limitations

- **Medium complexity**: Requires hook + agent coordination
- **Two-session implementation**: More files to create/modify

---

## Solution C: Agent-Autonomous Architecture

**Approach**: Full agent-based architecture where JICM itself is an autonomous agent that monitors, analyzes, and manages context proactively.

### Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                     JICM Autonomous Agent                            │
│                    (Spawned at Session Start)                        │
│                                                                       │
│  ┌────────────────────────────────────────────────────────────────┐ │
│  │  Continuous Monitoring Loop                                     │ │
│  │                                                                  │ │
│  │  1. Poll .statusline-context.json every 30s                    │ │
│  │  2. Track context velocity (tokens/minute)                      │ │
│  │  3. Predict when threshold will be reached                      │ │
│  │  4. Monitor active tasks and their context needs                │ │
│  └────────────────────────────────────────────────────────────────┘ │
│                            │                                         │
│                            ▼                                         │
│  ┌────────────────────────────────────────────────────────────────┐ │
│  │  Proactive Management                                           │ │
│  │                                                                  │ │
│  │  At 50%: "Consider offloading verbose outputs"                  │ │
│  │  At 60%: Disable Tier 2 MCPs automatically                      │ │
│  │  At 70%: Begin pre-emptive summarization                        │ │
│  │  At 75%: Generate preservation manifest                         │ │
│  │  At 80%: Trigger intelligent compression                        │ │
│  │  At 85%: Signal /clear with checkpoint ready                   │ │
│  └────────────────────────────────────────────────────────────────┘ │
│                            │                                         │
│                            ▼                                         │
│  ┌────────────────────────────────────────────────────────────────┐ │
│  │  Task-Aware Context Analysis                                    │ │
│  │                                                                  │ │
│  │  Reads: TodoWrite tasks, current-priorities.md, session-state   │ │
│  │  Infers: What context is needed for upcoming work               │ │
│  │  Predicts: Which files/concepts will be needed next             │ │
│  │  Preserves: High-relevance context, compresses low-relevance    │ │
│  └────────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────┐
│                 Context Velocity Predictor                           │
│                                                                       │
│  ┌────────────────────────────────────────────────────────────────┐ │
│  │  Historical Analysis                                            │ │
│  │                                                                  │ │
│  │  - Track tokens consumed per tool call type                    │ │
│  │  - Learn session patterns (exploration vs implementation)       │ │
│  │  - Predict time until threshold based on velocity               │ │
│  │                                                                  │ │
│  │  Example:                                                        │ │
│  │    Current: 70% context used                                    │ │
│  │    Velocity: 2000 tokens/minute                                 │ │
│  │    Remaining: 60,000 tokens                                     │ │
│  │    Predicted exhaustion: 30 minutes                             │ │
│  │    Recommendation: Begin compression at 75%                     │ │
│  └────────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────┐
│              Intelligent Checkpoint Generator                        │
│                                                                       │
│  ┌────────────────────────────────────────────────────────────────┐ │
│  │  Multi-Pass Compression                                         │ │
│  │                                                                  │ │
│  │  Pass 1: Identify all context categories                        │ │
│  │    - Active tasks, decisions, file contents, tool outputs      │ │
│  │                                                                  │ │
│  │  Pass 2: Score by relevance to current work                    │ │
│  │    - High: Active tasks, recent decisions, modified files      │ │
│  │    - Medium: Reference files, completed tasks                   │ │
│  │    - Low: Exploration outputs, old tool results                │ │
│  │                                                                  │ │
│  │  Pass 3: Generate tiered checkpoint                             │ │
│  │    - Tier A: Verbatim (1-2K tokens)                            │ │
│  │    - Tier B: Summarized (1-2K tokens)                          │ │
│  │    - Tier C: Referenced (paths only, 0.5K tokens)              │ │
│  └────────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────┘
```

### JICM Agent Definition

```yaml
# .claude/agents/jicm-agent.md
---
name: jicm-agent
description: |
  Autonomous JICM agent that monitors, predicts, and manages context proactively.
  Spawned as background agent at session start. Reports to main session via files.
model: haiku  # Lightweight model for efficiency
max_turns: 100  # Long-running
allowed_tools:
  - Read
  - Write
  - Glob
  - Grep
---

## JICM Autonomous Agent

You are the JICM (Jarvis Intelligent Context Management) autonomous agent.

### Your Mission

Monitor context usage continuously and manage it proactively so the main session never hits emergency thresholds. You run in the background and communicate via files.

### Monitoring Protocol

Every 30 seconds:
1. Read `.claude/context/.statusline-context.json`
2. Calculate context velocity (change since last check)
3. Update `.claude/context/.jicm-status.json` with:
   - Current percentage
   - Velocity (tokens/minute)
   - Predicted time to threshold
   - Recommended action

### Threshold Actions

| Threshold | Action |
|-----------|--------|
| 50% | Update status file, no intervention |
| 60% | Write recommendation: "Consider offloading verbose outputs" |
| 70% | Create soft checkpoint draft, update MCP recommendations |
| 75% | Generate preservation manifest with AI analysis |
| 80% | Trigger intelligent compression, write checkpoint |
| 85% | Signal ready for /clear, block further expansion |

### Communication Files

**Output** (you write):
- `.claude/context/.jicm-status.json` - Current status
- `.claude/context/.preservation-manifest.json` - What to preserve
- `.claude/context/.soft-restart-checkpoint.md` - Checkpoint content
- `.claude/context/.clear-ready-signal` - Signal for /clear

**Input** (you read):
- `.claude/context/.statusline-context.json` - Context data
- `.claude/context/current-priorities.md` - Active tasks
- `.claude/context/session-state.md` - Session state
- `.claude/logs/context-estimate.json` - Historical data

### Velocity Tracking

Track context growth patterns:
```json
{
  "measurements": [
    {"timestamp": "...", "percentage": 45, "tokens": 90000},
    {"timestamp": "...", "percentage": 48, "tokens": 96000}
  ],
  "velocity_tokens_per_minute": 1200,
  "predicted_threshold_time": "15 minutes",
  "phase": "exploration"  // or "implementation", "review"
}
```

### Preservation Intelligence

When generating preservation manifest, consider:

1. **Active TodoWrite Tasks**: Always preserve
2. **Recent Decisions**: Preserve with context
3. **Modified Files**: Keep paths, summarize changes
4. **Current Priorities**: Preserve verbatim
5. **Exploration Outputs**: Compress aggressively
6. **Old Tool Results**: Discard if >30 minutes old

### Fire-and-Forget Principle

You operate autonomously. Do NOT:
- Wait for acknowledgment
- Block main session
- Request user input

You DO:
- Write files for main session to read
- Signal via files when action needed
- Log all decisions to `.claude/logs/jicm-agent.log`
```

### Background Agent Spawning

Update `session-start.sh` to spawn JICM agent:

```bash
# In session-start.sh, after other initialization
spawn_jicm_agent() {
    local agent_log="$PROJECT_DIR/.claude/logs/jicm-agent.log"

    # Check if JICM agent already running
    if pgrep -f "jicm-agent" > /dev/null 2>&1; then
        log INFO "JICM agent already running"
        return 0
    fi

    # Spawn as background Task
    cat > "$PROJECT_DIR/.claude/context/.jicm-spawn-signal" <<EOF
{
    "action": "spawn_agent",
    "agent": "jicm-agent",
    "background": true,
    "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF

    log INFO "JICM agent spawn signaled"
}
```

### JICM Status File Schema

```json
// .claude/context/.jicm-status.json
{
  "timestamp": "2026-01-23T22:45:00Z",
  "context": {
    "used_percentage": 72.5,
    "remaining_tokens": 55000,
    "total_tokens": 145000
  },
  "velocity": {
    "tokens_per_minute": 1500,
    "trend": "increasing",
    "samples": 12
  },
  "prediction": {
    "threshold_80_in": "8 minutes",
    "threshold_95_in": "18 minutes",
    "confidence": "high"
  },
  "recommendation": {
    "action": "prepare_checkpoint",
    "urgency": "medium",
    "reason": "Approaching 75% threshold at current velocity"
  },
  "mcp_status": {
    "tier1_active": true,
    "tier2_active": true,
    "tier3_active": false,
    "recommended_disable": ["github", "context7"]
  },
  "preservation": {
    "manifest_ready": false,
    "checkpoint_ready": false,
    "clear_signaled": false
  }
}
```

### Implementation Steps

1. **Create JICM agent**: `jicm-agent.md` with full specification
2. **Create status schema**: JSON schema for JICM status
3. **Update session-start.sh**: Spawn JICM agent on session start
4. **Create velocity tracker**: Log token measurements over time
5. **Implement preservation AI**: Analyze context relevance
6. **Test**: Verify autonomous monitoring and recommendations

### Advantages

- **Fully autonomous**: No user intervention needed
- **Predictive**: Anticipates threshold before it's reached
- **Task-aware**: Understands work context for smart compression
- **Velocity-based**: Adjusts based on actual usage patterns
- **Highest reliability**: Multi-layered monitoring

### Limitations

- **High complexity**: Many moving parts
- **Resource usage**: Background agent consumes some context
- **Implementation time**: 3+ sessions to build and test

---

## Comparison Matrix

| Feature | Solution A | Solution B | Solution C |
|---------|------------|------------|------------|
| **Context Detection** | Statusline JSON | Statusline JSON | Statusline JSON + Velocity |
| **Monitoring** | Watcher script | Watcher + Hook | Autonomous agent |
| **Compression Trigger** | Threshold-based | Threshold + Manifest | Predictive |
| **AI Prioritization** | None | PreCompact hook | Full agent analysis |
| **Task Awareness** | None | Reads priorities | Tracks todos + patterns |
| **Velocity Prediction** | None | None | Yes |
| **MCP Management** | Manual | Recommended | Automatic |
| **Implementation** | 1 session | 2 sessions | 3+ sessions |
| **Maintenance** | Low | Medium | Higher |

---

## Recommended Implementation Path

### Phase 1: Solution A (Immediate)

**Goal**: Fix the critical fragility issue with minimal changes.

1. Update `get_token_count()` → `get_context_status()` in watcher
2. Delete redundant watcher scripts
3. Create `autonomy-config.yaml`
4. Test: Verify statusline JSON is used

**Outcome**: Reliable context monitoring using official API.

### Phase 2: Solution B (Short-term)

**Goal**: Add AI-driven prioritization.

1. Create PreCompact hook with analyzer
2. Update context-compressor agent to use manifest
3. Test: Verify manifest affects compression

**Outcome**: Smart compression that preserves active work.

### Phase 3: Solution C (Long-term)

**Goal**: Full autonomous context management.

1. Create JICM agent definition
2. Implement velocity tracking
3. Add predictive thresholds
4. Test: Verify proactive management

**Outcome**: Jarvis never hits emergency thresholds.

---

## Archon Architecture Alignment

### Nous (Knowledge) Layer

- `.claude/context/.statusline-context.json` — Official context data
- `.claude/context/.jicm-status.json` — JICM state
- `.claude/context/.preservation-manifest.json` — Compression priorities
- `.claude/context/designs/jicm-architecture-solutions.md` — This document

### Pneuma (Capabilities) Layer

- `.claude/scripts/jarvis-watcher.sh` — Unified watcher (enhanced)
- `.claude/scripts/statusline-context-capture.sh` — Context capture
- `.claude/hooks/precompact-analyzer.js` — PreCompact analysis
- `.claude/agents/jicm-agent.md` — Autonomous JICM agent

### Soma (Infrastructure) Layer

- `autonomy-config.yaml` — Configuration
- Log files in `.claude/logs/`
- Signal files in `.claude/context/`

### Neuro (Connections)

- Watcher reads from statusline JSON (not tmux scrape)
- Hook reads priorities, writes manifest
- Agent monitors, predicts, signals
- SessionStart loads checkpoint on restart

---

## Appendix: Key Files

### Files to Modify

| File | Changes |
|------|---------|
| `jarvis-watcher.sh` | Replace `get_token_count()` with `get_context_status()` |
| `launch-jarvis-tmux.sh` | Read from config file |
| `launch-watcher.sh` | Read from config file |
| `session-start.sh` | Spawn JICM agent (Solution C) |

### Files to Create

| File | Purpose |
|------|---------|
| `autonomy-config.yaml` | Single source of configuration |
| `precompact-analyzer.js` | PreCompact hook (Solution B) |
| `jicm-agent.md` | JICM agent definition (Solution C) |
| `.jicm-status.json` | Runtime status (Solution C) |

### Files to Delete

| File | Reason |
|------|--------|
| `auto-clear-watcher.sh` | Superseded by jarvis-watcher.sh |
| `auto-command-watcher.sh` | Superseded by jarvis-watcher.sh |

---

*Document generated by Jarvis JICM Research Phase*
*Commit checkpoint: JICM v3.0.0 architecture design complete*
