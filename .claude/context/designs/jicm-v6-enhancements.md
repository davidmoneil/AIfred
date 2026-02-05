# JICM v6 Enhancement Design

**Status**: Design Phase
**Created**: 2026-02-05
**Author**: Jarvis

---

## Overview

This document captures design notes for four JICM enhancements:
1. Idle state detection patterns and response triggers
2. Token count consistency improvements
3. Progress bar enhancements with threshold markers
4. Compression agent and JICM procedure speed optimization

---

## 1. Idle State Detection Patterns

### 1.1 Identified States

#### State A: Interrupted
**TUI Pattern**:
```
⎿  Interrupted · What should Claude do instead?
```

**Detection Regex**:
```bash
grep -qE "Interrupted.*What should Claude do"
```

**Response**: Trigger "resume work" prompt via idle-hands
**Mode**: `interrupted_resume`
**Priority**: Medium (user may have intentionally interrupted)

#### State B: Post-Clear with No Content
**TUI Pattern**:
```
❯ /clear
  ⎿  (no content)
```

**Detection Regex**:
```bash
grep -qE "/clear.*\(no content\)"
# OR
grep -qE "⎿.*\(no content\)"
```

**Response**: IMMEDIATE context restoration and prompt injection
**Mode**: `post_clear_restore`
**Priority**: HIGH - this indicates JICM cycle completed but continuation failed

#### State C: Fresh Session (0 tokens)
**TUI Pattern**:
```
Debug mode
 0 tokens
 current: x.x.xx · latest: x.x.xx
```
**Alternative**:
```
0 tokens
```

**Detection Regex**:
```bash
grep -qE "^\s*0 tokens"
# Or check statusline JSON
jq '.context_window.used_percentage == 0'
```

**Response**: Full context restoration from foundation files
**Mode**: `session_start` (already implemented)
**Priority**: HIGH

#### State D: Debounce Ignored Clear
**TUI Pattern**:
```
⎿  SessionStart:clear says: JICM v5 debounce: duplicate clear ignored
```

**Detection Regex**:
```bash
grep -qE "JICM.*debounce.*duplicate clear ignored"
```

**Response**: This is informational - no action needed. But if followed by idle prompt, trigger restoration.
**Priority**: LOW

### 1.2 Detection Architecture

**Location**: `jarvis-watcher.sh` in the main loop

**New Function**:
```bash
# Detect specific TUI states requiring intervention
detect_critical_state() {
    local pane_content
    pane_content=$(capture_tui_pane)

    # Priority order (highest first)

    # 1. Post-clear with no content - IMMEDIATE action
    if echo "$pane_content" | grep -qE "(no content)|⎿.*\(no content\)"; then
        echo "post_clear_restore"
        return 0
    fi

    # 2. 0 tokens (fresh/cleared session)
    if echo "$pane_content" | grep -qE "^\s*0 tokens"; then
        echo "session_start"
        return 0
    fi

    # 3. Interrupted state
    if echo "$pane_content" | grep -qE "Interrupted.*What should Claude do"; then
        echo "interrupted_resume"
        return 0
    fi

    # No critical state detected
    return 1
}
```

### 1.3 Response Actions by Mode

| Mode | Action | Files to Inject |
|------|--------|-----------------|
| `post_clear_restore` | IMMEDIATE prompt with full context | .compressed-context-ready.md, .in-progress-ready.md, session-state.md |
| `session_start` | Wake-up prompt with startup context | CLAUDE.md, jarvis-identity.md, session-state.md, current-priorities.md |
| `interrupted_resume` | Simple resume prompt | "Continue your previous task" |

### 1.4 Prompt Templates

**post_clear_restore**:
```
CONTEXT RESTORED - CONTINUE IMMEDIATELY

Your context was just cleared. Resume work using these files:
1. .claude/context/.compressed-context-ready.md (if exists)
2. .claude/context/.in-progress-ready.md (if exists)
3. .claude/context/session-state.md

Do NOT greet. Continue the task that was in progress.
```

**interrupted_resume**:
```
Resume your previous task. You were interrupted but should continue working.
```

---

## 2. Token Count Consistency

### 2.1 Token Sources Identified

| Source | Location | Value Type | Update Frequency |
|--------|----------|------------|------------------|
| TUI Display | tmux capture | Formatted (e.g., "89.4k") | Real-time |
| TUI Debug Line | tmux capture | Exact (e.g., "89421 tokens") | Real-time |
| statusline JSON | ~/.claude/logs/statusline-input.json | Multiple fields | Per-turn |
| context-categories.json | ~/.claude/logs/context-categories.json | Category breakdown | Hook-triggered |

### 2.2 JSON Field Mapping

**statusline-input.json**:
```json
{
  "context_window": {
    "total_input_tokens": 351822,     // Cumulative session total
    "total_output_tokens": 440453,    // Cumulative session total
    "context_window_size": 200000,    // Fixed
    "current_usage": {
      "input_tokens": 7,              // This turn only
      "output_tokens": 3,             // This turn only
      "cache_creation_input_tokens": 1155,   // New cache
      "cache_read_input_tokens": 88256       // Existing cache read
    },
    "used_percentage": 45,            // Current usage %
    "remaining_percentage": 55        // Inverse
  }
}
```

**Actual current context calculation**:
```
current_context = cache_read_input_tokens
                + cache_creation_input_tokens
                + input_tokens
                + output_tokens

Example: 88256 + 1155 + 7 + 3 = 89,421 tokens
```

### 2.3 Discrepancy Causes

1. **Stale cache**: TUI pane content cached for 5 seconds
2. **Wrong fields**: Using `total_*` instead of `current_usage.*`
3. **JSON staleness**: statusline JSON only updates on Claude Code events
4. **Timing**: TUI updates faster than JSON file

### 2.4 Recommended Fix

Update `get_tokens_from_json_current_usage()` in jarvis-watcher.sh:

```bash
get_tokens_from_json_current_usage() {
    local status
    status=$(get_context_status 2>/dev/null)

    if [[ -z "$status" ]]; then
        echo "0"
        return 1
    fi

    # Sum current_usage fields (NOT total_* fields)
    local input output cache_create cache_read total
    input=$(echo "$status" | jq -r '.context_window.current_usage.input_tokens // 0')
    output=$(echo "$status" | jq -r '.context_window.current_usage.output_tokens // 0')
    cache_create=$(echo "$status" | jq -r '.context_window.current_usage.cache_creation_input_tokens // 0')
    cache_read=$(echo "$status" | jq -r '.context_window.current_usage.cache_read_input_tokens // 0')

    total=$((input + output + cache_create + cache_read))
    echo "$total"
}
```

---

## 3. Progress Bar Enhancements

### 3.1 Current State

**Claude Code's built-in bar** (debug mode):
```
89.4k [▓▓▒██████░░░░░░░░░░░] 45%
```
- Uses multiple fill characters: `▓` `▒` `█` `░`
- Shows category breakdown visually
- No threshold markers

**Jarvis's custom bar** (statusline-context-capture.sh):
```
🟢 [Opus 4.5] 45% [▓▓▓▓░░░░░░] | $76.32
```
- Simple single-fill style
- No categories
- No thresholds

### 3.2 Proposed Enhanced Bar

**Visual Design** (20 chars wide):
```
[▓▓▓▓▓▓▓▓▓|░░░░░|█░░░░]
         ↑     ↑
        50%   95%
        JICM  Auto-compact
```

**Character Legend**:
- `▓` = Used context (filled)
- `░` = Available context (empty)
- `█` = Output token reservation
- `|` = Threshold markers

**Color Coding**:
- Green (`\033[0;32m`): 0-49%
- Yellow (`\033[1;33m`): 50-79%
- Red (`\033[0;31m`): 80-94%
- Magenta (`\033[0;35m`): 95%+ (auto-compact zone)

### 3.3 Configuration Values

From settings.json:
- **JICM threshold**: 50% (JICM_THRESHOLD in watcher)
- **Auto-compact threshold**: 95% (claudeCode.autoCompact.threshold)

**Output token reservation**:
- Claude models reserve ~8,192 tokens for output
- On 200K context: 8192 / 200000 = 4.1%
- Should show last ~4% of bar as reserved

### 3.4 Implementation

**Updated statusline-context-capture.sh**:

```bash
#!/bin/bash
# Enhanced Status Line with Threshold Markers

JICM_THRESHOLD=50
AUTOCOMPACT_THRESHOLD=95
OUTPUT_RESERVE_PCT=4  # ~8K tokens on 200K context
BAR_WIDTH=20

build_progress_bar() {
    local used_pct="$1"
    local bar=""

    # Calculate positions
    local jicm_pos=$((JICM_THRESHOLD * BAR_WIDTH / 100))
    local auto_pos=$((AUTOCOMPACT_THRESHOLD * BAR_WIDTH / 100))
    local reserve_start=$((100 - OUTPUT_RESERVE_PCT) * BAR_WIDTH / 100)
    local filled=$((used_pct * BAR_WIDTH / 100))

    for ((i=0; i<BAR_WIDTH; i++)); do
        # Check for threshold markers
        if [[ $i -eq $jicm_pos ]] || [[ $i -eq $auto_pos ]]; then
            bar+="│"
            continue
        fi

        # Determine fill character
        if [[ $i -lt $filled ]]; then
            if [[ $i -ge $reserve_start ]]; then
                bar+="█"  # Output reserved (used)
            else
                bar+="▓"  # Regular used
            fi
        else
            if [[ $i -ge $reserve_start ]]; then
                bar+="█"  # Output reserved (empty state)
            else
                bar+="░"  # Empty
            fi
        fi
    done

    echo "[$bar]"
}
```

### 3.5 Category Breakdown Display

Using context-categories.json data:

```
Context: 45% [▓▓▓▓▓▓▓▓▓│░░░░░│█░░░░]
  System: 2.6k | Tools: 17k | Messages: 61k | Reserve: 8k
```

---

## 4. Compression Agent Speed Optimization

### 4.1 Current Timing Analysis

From agent logs (2026-02-05):
- Start: 01:37:15
- End: 01:40:12
- Duration: ~3 minutes (not 7 minutes)

The "7 minute" perception included:
- Wait for Jarvis idle
- Main thread processing /intelligent-compress
- Context balloon from Step 2 (now fixed in v5.2.0)
- Debounce/state machine issues (now fixed)

### 4.2 Optimization Opportunities

#### A. Model Selection
**Current**: `model: sonnet`
**Proposed**: `model: haiku`

Haiku is ~10x faster than Sonnet for similar tasks. Compression doesn't need Opus-level reasoning.

**Trade-off**: Slightly lower quality compression
**Recommendation**: Use haiku for speed, validate quality

#### B. Data Source Optimization

**Current reads**:
1. Session transcript JSONL (potentially large)
2. Foundation docs (CLAUDE.md, jarvis-identity.md, compaction-essentials.md)
3. Session state files

**Optimization**:
1. Use `.context-captured.txt` if recent (<5 min old) instead of parsing JSONL
2. Skip foundation docs - just reference them, don't read full content
3. Read only last 50KB of transcript (tail) for large sessions

```bash
# In compression agent prompt:
If .claude/context/.context-captured.txt exists and is < 5 min old:
  Use that instead of parsing transcript JSONL

For session-state.md and current-priorities.md:
  Read full files (they're small and essential)

For transcript:
  If > 100KB, read only last 50KB
```

#### C. Parallel File Reads

The compression agent currently reads files sequentially. Use parallel reads:

```
subagent_type: compression-agent
prompt: |
  Read these files IN PARALLEL:
  - .claude/context/session-state.md
  - .claude/context/current-priorities.md
  - .claude/context/.context-captured.txt

  Then process and write output.
```

#### D. Eliminate Unnecessary Waits

**Current waits in JICM flow**:
1. `wait_for_idle 30` before /intelligent-compress
2. `sleep 0.1` between send-keys calls
3. `sleep 15` post-clear settling (new in v5.2.0)
4. `sleep $cycle_delay` (12s) in idle-hands loop

**Optimization**:
- Reduce `wait_for_idle` timeout from 30s to 15s
- Keep 0.1s tmux delays (required)
- Post-clear settling can be reduced to 10s
- Idle-hands cycle delay can be 8s instead of 12s

### 4.3 Target Performance

| Phase | Current | Target |
|-------|---------|--------|
| Detect threshold | 0s | 0s |
| Wait for idle | 0-30s | 0-15s |
| Process /intelligent-compress | ~10s (context balloon) | ~2s (no balloon) |
| Spawn compression agent | ~1s | ~1s |
| Agent execution | ~3min (sonnet) | ~30s (haiku) |
| Signal detection | 30s (poll interval) | 10s (faster polling during compression) |
| Send /clear | ~1s | ~1s |
| Post-clear settling | 15s | 10s |
| Context restoration | 5-10s | 5-10s |

**Total**:
- Current: ~4-5 minutes (when working correctly)
- Target: ~1-2 minutes

### 4.4 Fast Polling Mode

During active JICM cycle, reduce poll interval:

```bash
# In main loop, when JICM_STATE != "monitoring":
if [[ "$JICM_STATE" != "monitoring" ]]; then
    CURRENT_INTERVAL=10  # Fast polling during JICM
else
    CURRENT_INTERVAL=$DEFAULT_INTERVAL  # Normal 30s
fi
sleep "$CURRENT_INTERVAL"
```

---

## 5. Implementation Plan

### Phase 1: Immediate (v5.2.1) — COMPLETE
- [x] Fix context balloon (Step 2 removal) - DONE
- [x] Fix cache race condition - DONE
- [x] Fix state machine bug - DONE
- [x] Add critical state detection function - DONE (v5.3.0)
- [x] Update compression agent to use haiku - DONE (tested 5.5:1 ratio)

### Phase 2: Short-term (v5.3.0) — COMPLETE
- [x] Implement enhanced progress bar - DONE (statusline-context-capture.sh)
- [x] Add threshold markers to watcher display - DONE (│ at 50%, 95%)
- [x] Fix token_method tracking (subshell → temp file)
- [ ] Implement fast polling during JICM cycle
- [ ] Reduce wait times

### Phase 3: Medium-term (v6.0.0)
- [ ] Full idle-hands mode expansion
- [ ] Custom statusline with category breakdown
- [ ] Self-tuning compression (based on session complexity)

---

## 6. Testing Checklist

### Idle State Detection
- [ ] Trigger interrupted state, verify detection
- [ ] Run /clear, verify "(no content)" detection
- [ ] Start fresh session, verify 0 tokens detection

### Token Consistency
- [ ] Compare TUI display with JSON values
- [ ] Verify percentage matches token count
- [ ] Test after /clear with fresh data

### Progress Bar
- [ ] Verify JICM marker at 50%
- [ ] Verify auto-compact marker at 95%
- [ ] Verify output reservation display

### Speed
- [ ] Time full JICM cycle with haiku
- [ ] Verify reduced wait times work correctly
- [ ] Test fast polling mode

---

*Design Document v1.0 — JICM v6 Enhancements*
