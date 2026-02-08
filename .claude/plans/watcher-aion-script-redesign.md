# Watcher — Aion Script Dashboard Redesign

**Date**: 2026-02-07
**Status**: Design Brainstorm (Wiggum loop, exit gate 09:30 MST)
**Author**: Jarvis (brainstorm session, user-present)

---

## 1. Current State Assessment

### What the User Sees Now (jarvis:1)
```
16:12:48 ● 171739 tokens (86%) [monitoring]
16:13:00 ● 171739 tokens (86%) [monitoring] ♡
16:13:10 ◐ 140000 tokens (70%) [compression_triggered]
16:13:20 ◐ 140000 tokens (70%) [compression_triggered]
16:13:30 ● 38000 tokens (19%) [monitoring]
16:13:40 ● 38000 tokens (19%) [monitoring] ♡
...
```

A scrolling list of single-line token readings. The only visual variation is:
- `●` (green) for normal, `◐` (yellow) at threshold, `⚠` (red) at danger
- `♡` heartbeat marker every 6th iteration when tokens unchanged

### What's Wrong
1. **No dashboard** — it's a log, not a fixed display. Scrolling destroys context.
2. **Token count is the only metric** — no state visualization, no history, no trends
3. **Invisible events** — compression triggers, /clear, idle-hands, emergencies write to log file but nothing reaches the tmux pane
4. **No config visibility** — thresholds, lockout ceiling, session type hidden
5. **No health summary** — failure count, trigger count, uptime only in `.watcher-status`
6. **No temporal context** — can't see: when was last compression? how long has this session been running? what's the token burn rate?
7. **Wastes the tmux pane** — occupies a full window but delivers one data point per line

### What Works Well (Don't Break These)
1. **State machine logic** — rock solid after v5.6.0 rewrite (monitoring ↔ compression_triggered ↔ cleared)
2. **Token extraction** — TUI-exact method with pane buffer restriction (v5.4.3 fix)
3. **`.watcher-status` file** — clean YAML format, consumed by other tools (Virgil reads this)
4. **Log file** — structured `timestamp | LEVEL | message` format for debugging
5. **Signal file coordination** — well-designed JICM cycle orchestration
6. **5s poll interval** — responsive without being resource-hungry

---

## 2. Design Principle: Separation of Concerns

**Key insight**: The Watcher currently mixes two responsibilities:
1. **Engine** — the JICM state machine, compression orchestration, idle-hands, emergency handling
2. **Display** — showing the human what's happening

The redesign should separate these cleanly:
- The **engine** continues writing to `.watcher-status` and `jarvis-watcher.log` (no changes)
- A new **display layer** renders a fixed-layout dashboard by reading `.watcher-status`, the log file, and other data sources

### Two Architecture Options

**Option A: In-Script Dashboard**
Replace the scrolling `echo` on line 1620 with a `render_dashboard()` function that uses `tput`/ANSI to draw a fixed-layout dashboard. Pros: single process, real-time. Cons: mixes display with engine, harder to test, engine failure kills display.

**Option B: Separate Display Process**
Keep the engine script unchanged. Add a `watcher-dashboard.sh` that runs alongside it, reading `.watcher-status` + tail of log file + other sources. Pros: clean separation, engine/display independent, can restart display without affecting engine. Cons: two processes, slight data lag.

**Recommendation**: Option A with a clean `render_dashboard()` function. The Watcher engine already owns the tmux pane. Adding a second process for the same pane creates coordination complexity. But the render function should be well-isolated from engine logic.

**Counterpoint for Option B**: If we're building Virgil as a separate display process anyway, there's a pattern to follow. Both Virgil and Watcher-dashboard would be "display Aion Scripts" that read data and render. The engine stays pure.

---

## 3. Dashboard Layout (Mockup v1)

```
╔═══════════════════════════════════════════════════════╗
║  WATCHER — Context Guardian            09:25 MST     ║
║  Session: 2h 12m │ Type: continue │ v5.8.1           ║
╠═══════════════════════════════════════════════════════╣
║                                                       ║
║  CONTEXT GAUGE                                        ║
║  ░░░░░░░░░░░░░░░░░░░░██████████████████████████░░░░  ║
║  0%        38%                    70%  73% 78%  100%  ║
║            ▲ NOW                   │    │   │         ║
║                              threshold │   │         ║
║                              emergency─┘   │         ║
║                                   lockout──┘         ║
║                                                       ║
║  Tokens: 76,000 / 200,000 (38%)                      ║
║  Burn rate: ~2,400 tok/min │ ETA threshold: ~13 min   ║
║                                                       ║
╠═══════════════════════════════════════════════════════╣
║                                                       ║
║  STATE: ● monitoring                                  ║
║                                                       ║
║  RECENT EVENTS                                        ║
║  09:22  ● Context restored (18% → monitoring)         ║
║  09:15  ═ COMPRESSION SUCCESS → /clear sent           ║
║  09:10  ◐ Threshold hit (71%) → compression #5        ║
║  09:05  ⚠ Emergency /compact at 78%                   ║
║  08:50  ● Session resumed (jicm_resume SUCCESS)       ║
║                                                       ║
╠═══════════════════════════════════════════════════════╣
║                                                       ║
║  HEALTH                                               ║
║  Triggers: 5 │ Failures: 0 │ Uptime: 2h 12m          ║
║  Success rate: 100% │ Avg compress: 4m 20s            ║
║  Last compression: 7 min ago                          ║
║                                                       ║
╠═══════════════════════════════════════════════════════╣
║  ● monitoring   ◐ compressing   ⊘ cleared   ⚠ alert  ║
╚═══════════════════════════════════════════════════════╝
```

### Key Differences from Current
| Aspect | Current | Proposed |
|--------|---------|----------|
| Layout | Scrolling log | Fixed dashboard (redrawn in place) |
| Data | Token count only | Gauge + burn rate + ETA + events + health |
| Events | Silent (log only) | Last 5 events shown in dashboard |
| Trends | None | Burn rate + time-to-threshold estimate |
| Config | Hidden | Thresholds visible on gauge |
| Health | Hidden | Success rate, avg compress time, uptime |

---

## 4. Context Gauge Design

The centerpiece: a visual gauge showing where you are relative to the danger zones.

### ASCII Bar Version (terminal-friendly)
```
CONTEXT ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░░░░░░░░░░░░░░░░░░░░░ 38%
         ────────────────────┤────│────│──│────────
                        threshold  │    │
                           emergency    │
                                   lockout
```

### Color Zones
| Zone | Range | Color | Meaning |
|------|-------|-------|---------|
| Safe | 0-55% | Green | Normal operation |
| Caution | 55-70% | Yellow | Approaching threshold |
| Compress | 70-73% | Bright Yellow | Compression triggered/in-progress |
| Emergency | 73-78% | Red | Emergency /compact territory |
| Lockout | 78%+ | Bright Red | Claude Code refuses operations |

### Progress Bar Function
```bash
render_gauge() {
    local pct=$1 cols=${2:-50}
    local filled=$((pct * cols / 100))
    local threshold_pos=$((JICM_THRESHOLD * cols / 100))
    local emergency_pos=$((EMERGENCY_COMPACT_PCT * cols / 100))
    local lockout_pos=$((LOCKOUT_PCT * cols / 100))

    printf '  '
    for ((i=0; i<cols; i++)); do
        if ((i < filled)); then
            if ((i < threshold_pos)); then
                printf '\e[32m▓\e[0m'    # green
            elif ((i < emergency_pos)); then
                printf '\e[33m▓\e[0m'    # yellow
            elif ((i < lockout_pos)); then
                printf '\e[31m▓\e[0m'    # red
            else
                printf '\e[91m▓\e[0m'    # bright red
            fi
        else
            printf '░'
        fi
    done
    printf ' %d%%\n' "$pct"
}
```

---

## 5. Burn Rate & ETA Calculation

**Burn rate**: tokens consumed per minute, calculated from last N readings.

```bash
# Ring buffer of last 12 readings (1 minute of history at 5s intervals)
declare -a token_history
declare -a time_history
HISTORY_SIZE=12
history_idx=0

record_reading() {
    local tokens=$1
    token_history[$history_idx]=$tokens
    time_history[$history_idx]=$(date +%s)
    history_idx=$(( (history_idx + 1) % HISTORY_SIZE ))
}

calc_burn_rate() {
    # Tokens per minute based on oldest vs newest reading in buffer
    local oldest_idx=$(( (history_idx) % HISTORY_SIZE ))
    local newest_idx=$(( (history_idx - 1 + HISTORY_SIZE) % HISTORY_SIZE ))

    local t_old=${token_history[$oldest_idx]:-0}
    local t_new=${token_history[$newest_idx]:-0}
    local s_old=${time_history[$oldest_idx]:-0}
    local s_new=${time_history[$newest_idx]:-0}

    if [[ $s_old -eq 0 ]] || [[ $s_new -eq $s_old ]]; then
        echo "0"
        return 0
    fi

    local delta_tokens=$((t_new - t_old))
    local delta_seconds=$((s_new - s_old))
    local rate_per_min=$(( delta_tokens * 60 / delta_seconds ))
    echo "$rate_per_min"
    return 0
}

calc_eta_threshold() {
    local current_tokens=$1
    local threshold_tokens=$(( JICM_THRESHOLD * MAX_CONTEXT_TOKENS / 100 ))
    local burn_rate=$(calc_burn_rate)

    if [[ $burn_rate -le 0 ]] || [[ $current_tokens -ge $threshold_tokens ]]; then
        echo "—"
        return 0
    fi

    local remaining=$((threshold_tokens - current_tokens))
    local minutes=$((remaining / burn_rate))
    echo "${minutes}m"
    return 0
}
```

**Why this matters**: The user can glance at Watcher and instantly know "I have ~13 minutes before compression triggers" instead of mentally calculating from raw token counts.

---

## 6. Event Feed

Replace the scrolling log with a fixed-size event feed showing the last 5 significant events. Events stored in a ring buffer.

### Event Categories
| Category | Symbol | Color | Examples |
|----------|--------|-------|----------|
| State transition | `●→` | Cyan | monitoring → compression_triggered |
| Compression | `═` | Yellow | Compression started (#5), success, failure |
| Emergency | `⚠` | Red | Emergency /compact, lockout detection |
| Idle-hands | `⟳` | Magenta | jicm_resume active, session_start wake-up |
| Clear | `⊘` | Blue | /clear sent, context restored |
| Error | `✗` | Red | Failsafe timeout, compression failure |

### Implementation
```bash
declare -a event_buffer
EVENT_MAX=5
event_idx=0

add_event() {
    local msg="$1"
    local timestamp
    timestamp=$(date '+%H:%M')
    event_buffer[$event_idx]="$timestamp  $msg"
    event_idx=$(( (event_idx + 1) % EVENT_MAX ))
}

render_events() {
    echo -e "  \e[1mRECENT EVENTS\e[0m"
    # Display in reverse chronological order
    for ((i=EVENT_MAX-1; i>=0; i--)); do
        local idx=$(( (event_idx - 1 - i + EVENT_MAX * 2) % EVENT_MAX ))
        if [[ -n "${event_buffer[$idx]:-}" ]]; then
            echo "  ${event_buffer[$idx]}"
        fi
    done
}
```

Events would be added at key points in the engine:
- `add_event "● monitoring → compression_triggered"` when state changes
- `add_event "═ COMPRESSION SUCCESS → /clear sent"` on successful compression
- `add_event "⚠ Emergency /compact at ${pct}%"` on emergency
- etc.

---

## 7. Health Summary

Aggregate metrics computed from existing counters:

```
HEALTH
Triggers: 5 │ Failures: 0 │ Uptime: 2h 12m
Success rate: 100% │ Avg compress: 4m 20s
Last compression: 7 min ago
```

### New Counters Needed
| Counter | Source | Current? |
|---------|--------|----------|
| Trigger count | `$TRIGGER_COUNT` | Yes (exists) |
| Failure count | `$FAILURE_COUNT` | Yes (exists) |
| Uptime | `$START_TIME` vs now | Need to add START_TIME |
| Success count | `trigger_count - failure_count` | Derived |
| Last compression time | `$JICM_LAST_TRIGGER` | Yes (exists) |
| Avg compress duration | Ring buffer of durations | Need to add |
| Peak token % | Max seen pct | Need to add |

Most of these are trivially added — just record `START_TIME=$(date +%s)` at startup and track a few more timestamps.

---

## 8. Rendering Architecture

### Fixed-Layout Rendering with tput
```bash
render_dashboard() {
    # Move cursor to top of pane, overwrite in place
    tput cup 0 0     # Move to row 0, col 0
    tput ed           # Clear from cursor to end of screen

    local cols=$(tput cols)
    local rows=$(tput lines)

    # Header
    render_header "$cols"

    # Context gauge (the star of the show)
    render_gauge "$current_pct" "$((cols - 4))"
    render_gauge_labels "$cols"
    render_token_info "$current_tokens" "$current_pct"

    # State
    render_state "$JICM_STATE"

    # Event feed
    render_events

    # Health
    render_health

    # Footer
    render_footer "$cols"
}
```

### Rendering Cadence
- **Full redraw**: Every 5s (matches poll interval) using `tput cup 0 0` to overwrite in place
- **No scrolling**: Dashboard stays fixed; events update in their slot
- **Minimal flicker**: `tput cup` + selective redraw, not `clear` (which causes flash)

### Terminal Compatibility
- Uses standard ANSI escape codes (works in iTerm2, Terminal.app, any xterm-256color)
- `tput` for cursor positioning (POSIX standard, works in bash 3.2)
- No dependency on ncurses libraries
- Falls back gracefully if terminal too small (render compact mode)

---

## 9. Compact Mode (Small Terminals)

If terminal width < 50 or height < 15, render a minimal view:

```
WATCHER ● monitoring  38% (76K/200K)
Rate: 2.4K/min │ ETA: 13m │ T:5 F:0
Last: 09:22 Context restored (18%)
```

Three lines, essential info only. Detects terminal size at each render cycle.

---

## 10. Historical Sparkline (v0.2 Feature)

A miniature token history chart using Unicode block characters:

```
TOKEN HISTORY (last 30 min)
▁▁▂▃▅▇█▇▅▃▁▁▂▃▅▆▇█▆▃▁▁▁▂▃▅▆▇█▆
                          ▲ compressions
```

Each character represents a 1-minute average. Block height maps to percentage:
- `▁` = 0-12%, `▂` = 13-25%, `▃` = 26-37%, `▄` = 38-50%
- `▅` = 51-62%, `▆` = 63-75%, `▇` = 76-87%, `█` = 88-100%

This gives an instant visual history of the session's context usage pattern — the sawtooth of build-compress-build cycles becomes immediately visible.

---

## 11. State Machine Visualization

Show the JICM state machine with the current state highlighted:

```
STATE MACHINE
  ● monitoring ──▶ ◐ compression_triggered ──▶ ⊘ cleared
       ▲                    │ (failsafe)           │
       └────────────────────┴──────────────────────┘
  Current: ● monitoring (stable for 7 min)
```

Or more compactly:
```
  ● monitoring ──▶ ◐ compressing ──▶ ⊘ cleared ──▶ ● monitoring
                                              ▲ YOU ARE HERE
```

This demystifies the state machine for the human — they can see where in the cycle Watcher is and what transitions are possible.

---

## 12. Naming: Aion Scripts

Per user's direction, renaming "Angel Scripts" to "Aion Scripts":

| Script | Role | Literary Parallel |
|--------|------|-------------------|
| **Watcher** (`jarvis-watcher.sh`) | Context guardian — defensive, prevents lockout | The sentinel |
| **Virgil** (`virgil.sh`) | Codebase guide — informational, shows navigation | Dante's guide |
| (future) **Beatrice** (`beatrice.sh`) | Session sage — interpretive, review/insights | Higher wisdom |

**Aion Scripts** are tmux-resident bash processes that operate alongside Claude Code:
- Each occupies its own tmux window/pane
- Each has a focused responsibility
- Each reads shared data sources (`.watcher-status`, file-access.json, git)
- None modify Claude Code's conversation (only Watcher sends commands)
- All are separable — can stop/start independently

---

## 13. Integration with Virgil

Watcher and Virgil should be complementary, not redundant:

| Data Point | Watcher Shows | Virgil Shows |
|------------|--------------|--------------|
| Context % | Full gauge with zones + burn rate + ETA | Single line from .watcher-status |
| State machine | Full visualization + event feed | Just the state label |
| File activity | — | Full file list with hyperlinks |
| Git changes | — | Uncommitted changes + unpushed |
| Breadcrumbs | — | Session navigation trail |
| Compression history | Event feed with timing | — |
| "Says" recommendation | — | Priority-ranked heuristic |

**Watcher** = deep context monitoring.
**Virgil** = broad codebase awareness.

No overlap. Each excels at what the other doesn't show.

---

## 14. Implementation Approach

### Option A: In-Script Dashboard (Recommended for v0.1)

Modify `jarvis-watcher.sh` directly:
1. Replace the `echo` on line 1620 with `render_dashboard()`
2. Add ring buffers for token history and events
3. Add `add_event()` calls at key state transitions
4. Add `START_TIME`, `PEAK_PCT`, burn rate tracking

**Pros**: Single process, real-time data, minimal coordination
**Cons**: Larger script, display failure could affect engine

**Risk mitigation**: Wrap `render_dashboard()` in `|| true` so display errors can't crash the engine.

### Option B: Separate Display Script (Alternative)

Keep engine unchanged. New `watcher-dashboard.sh` reads:
- `.watcher-status` (YAML, updated every 5s)
- `jarvis-watcher.log` (tail for events)
- Derive burn rate from status file timestamp + token deltas

**Pros**: Clean separation, engine untouched
**Cons**: Event feed depends on log parsing (brittle), no access to engine ring buffers

### Hybrid (Best of Both)

Engine writes to a richer `.watcher-status` (add events, history, health metrics).
Display reads this enhanced status file.

```yaml
# Enhanced .watcher-status (v2)
timestamp: 2026-02-07T16:22:00Z
version: 5.9.0
tokens: 76000
percentage: 38%
threshold: 70%
emergency: 73%
lockout: 78%
state: monitoring
trigger_count: 5
failure_count: 0
success_rate: 100%
session_type: continue
uptime_seconds: 7920
peak_pct: 86%
burn_rate: 2400
eta_threshold: 13m
last_compression: 2026-02-07T16:15:00Z
events:
  - "16:22 ● Context restored (18%)"
  - "16:15 ═ COMPRESSION SUCCESS → /clear"
  - "16:10 ◐ Threshold (71%) → compression #5"
  - "16:05 ⚠ Emergency /compact at 78%"
  - "15:50 ● Session resumed (jicm_resume)"
token_history: [18,22,28,34,38,42,48,55,62,68,71,38]
```

This way the engine computes everything, and the display (or Virgil, or any future consumer) just renders from the status file.

---

## 15. Evolution Roadmap

| Version | Features | Scope |
|---------|----------|-------|
| **v0.1** | Fixed dashboard: gauge + state + events (replaces scrolling log) | Engine modification (render_dashboard) |
| **v0.2** | Burn rate + ETA + sparkline history | Engine + ring buffers |
| **v0.3** | Enhanced .watcher-status (v2 format) + health metrics | Engine + status file |
| **v1.0** | Separate display option (watcher-dashboard.sh) + Virgil integration | New script |

### v0.1 Acceptance Criteria
1. Dashboard renders as fixed layout (no scrolling)
2. Context gauge with color zones and threshold markers
3. Current state prominently displayed
4. Last 5 events visible (from ring buffer)
5. Token count, percentage, session type, uptime shown
6. Refreshes every 5s without flicker
7. Falls back to compact mode if terminal too small
8. Engine logic completely unchanged — only display code added

---

## 16. Open Questions for User

1. **Architecture**: In-script dashboard (Option A) or separate display process (Option B) or hybrid?
2. **Gauge style**: ASCII bar (`▓░`) or Unicode blocks (`█░`) or box drawing (`━╸`)?
3. **Event persistence**: Ring buffer in memory only, or also write to a `.watcher-events` file for Virgil?
4. **Sparkline**: Worth the complexity for v0.1, or defer to v0.2?
5. **Enhanced status file**: Worth enriching `.watcher-status` for multi-consumer use?

---

---

## 17. The Glanceability Principle

The user's core complaint: "endless scroll of token count checks... not a super convenient format for a human."

The redesigned dashboard must answer three questions at a glance:

1. **Am I safe?** → Context gauge color (green/yellow/red) + state indicator
2. **How long until I'm not?** → Burn rate + ETA to threshold
3. **Has anything happened?** → Event feed showing last 5 significant events

If the user can answer all three in under 2 seconds of looking at the pane, the dashboard succeeds. Everything else is secondary.

### Glanceability Hierarchy
```
1. GAUGE COLOR (peripheral vision — don't even need to read)
2. PERCENTAGE NUMBER (one glance — confirms what color told you)
3. STATE LABEL (one word — "monitoring" vs "compressing")
4. ETA (one number — "13m until threshold")
5. EVENTS (skim — "anything unusual happen while I wasn't looking?")
6. HEALTH (occasional — "is the system working correctly?")
```

The gauge color alone should communicate 80% of the information. A green bar = safe, yellow = caution, red = act now. This is the same design principle as car instrument clusters.

---

## 18. Critical Technical Notes

### bash 3.2 Compatibility
- `declare -a` (indexed arrays): YES, supported
- `declare -A` (associative arrays): NO, bash 4+ only — don't use
- Ring buffers via indexed arrays: safe
- `tput cup`: POSIX standard, works everywhere
- `printf '\e[...'`: works in all modern terminals

### Scrollback Behavior
`tput cup 0 0` moves cursor to top of visible area and overwrites. Old renders remain in scrollback buffer. This is identical to `htop`, `watch`, etc. Scrolling up shows previous dashboard snapshots — useful for debugging.

### Log File Unchanged
The `log()` function continues writing to `jarvis-watcher.log`. Dashboard display is additive, not a replacement for the structured log. The log remains the archival record for post-session analysis.

### Error Isolation
```bash
render_dashboard 2>/dev/null || true
```
Display errors must never crash the engine. All render functions wrapped in `|| true`.

---

## 19. v0.1 Implementation Skeleton

```bash
# ─── New globals (add near line 200) ─────────────────────
START_TIME=$(date +%s)
PEAK_PCT=0
declare -a EVENT_BUFFER
EVENT_IDX=0
EVENT_MAX=5
declare -a TOKEN_RING
declare -a TIME_RING
RING_SIZE=12
RING_IDX=0

# ─── New functions (add before main loop) ────────────────

add_event() {
    local msg="$1"
    EVENT_BUFFER[$EVENT_IDX]="$(date '+%H:%M')  $msg"
    EVENT_IDX=$(( (EVENT_IDX + 1) % EVENT_MAX ))
}

record_token() {
    local tokens=$1
    TOKEN_RING[$RING_IDX]=$tokens
    TIME_RING[$RING_IDX]=$(date +%s)
    RING_IDX=$(( (RING_IDX + 1) % RING_SIZE ))
}

calc_burn_rate() {
    local oldest=$(( RING_IDX % RING_SIZE ))
    local newest=$(( (RING_IDX - 1 + RING_SIZE) % RING_SIZE ))
    local t0=${TOKEN_RING[$oldest]:-0}
    local t1=${TOKEN_RING[$newest]:-0}
    local s0=${TIME_RING[$oldest]:-0}
    local s1=${TIME_RING[$newest]:-0}
    if [[ $s0 -eq 0 ]] || [[ $s1 -eq $s0 ]]; then echo "0"; return 0; fi
    echo $(( (t1 - t0) * 60 / (s1 - s0) ))
    return 0
}

render_gauge() {
    local pct=$1 width=${2:-40}
    local filled=$((pct * width / 100))
    local thresh_pos=$((JICM_THRESHOLD * width / 100))
    local emerg_pos=$((EMERGENCY_COMPACT_PCT * width / 100))
    printf '  '
    for ((i=0; i<width; i++)); do
        if ((i < filled)); then
            if ((i < thresh_pos)); then printf '\e[32m▓\e[0m'
            elif ((i < emerg_pos)); then printf '\e[33m▓\e[0m'
            else printf '\e[31m▓\e[0m'; fi
        else printf '░'; fi
    done
    printf ' %d%%\n' "$pct"
}

render_dashboard() {
    local pct=$1 tokens=$2 state=$3
    local cols=$(tput cols 2>/dev/null || echo 55)
    local now=$(date +%s)
    local uptime=$(( (now - START_TIME) / 60 ))
    local burn=$(calc_burn_rate)
    local pct_int=${pct%\%}

    tput cup 0 0 2>/dev/null
    tput ed 2>/dev/null

    # Header
    printf '\e[1;36m WATCHER\e[0m — Context Guardian'
    printf '%*s\n' $((cols - 30)) "$(date '+%H:%M %Z')"
    printf '  Session: %dm │ Type: %s │ v5.8.1\n' "$uptime" "$SESSION_TYPE"
    printf '%.0s─' $(seq 1 "$cols"); echo

    # Gauge
    echo -e "\n\e[1m  CONTEXT\e[0m"
    render_gauge "$pct_int" "$((cols - 6))"
    printf '  Tokens: %s / %s │ Burn: ~%s tok/min\n' \
        "$(printf '%'\''d' "$tokens")" \
        "$(printf '%'\''d' "$MAX_CONTEXT_TOKENS")" \
        "$(printf '%'\''d' "${burn:-0}")"
    if [[ ${burn:-0} -gt 0 ]] && [[ $pct_int -lt $JICM_THRESHOLD ]]; then
        local thresh_tok=$((JICM_THRESHOLD * MAX_CONTEXT_TOKENS / 100))
        local remaining=$((thresh_tok - tokens))
        local eta=$((remaining / burn))
        printf '  ETA threshold: ~%dm\n' "$eta"
    fi

    # State
    printf '\n%.0s─' $(seq 1 "$cols"); echo
    local state_color="\e[32m" state_sym="●"
    case "$state" in
        compression_triggered) state_color="\e[33m"; state_sym="◐" ;;
        cleared)               state_color="\e[34m"; state_sym="⊘" ;;
    esac
    printf '\n  STATE: %b%s %s\e[0m\n' "$state_color" "$state_sym" "$state"

    # Events
    echo -e "\n\e[1m  RECENT EVENTS\e[0m"
    local shown=0
    for ((i=EVENT_MAX-1; i>=0; i--)); do
        local idx=$(( (EVENT_IDX - 1 - i + EVENT_MAX * 2) % EVENT_MAX ))
        if [[ -n "${EVENT_BUFFER[$idx]:-}" ]]; then
            echo "  ${EVENT_BUFFER[$idx]}"
            shown=$((shown + 1))
        fi
    done
    [[ $shown -eq 0 ]] && echo "  (no events yet)"

    # Health
    printf '\n%.0s─' $(seq 1 "$cols"); echo
    local success=$((TRIGGER_COUNT - FAILURE_COUNT))
    local rate=0
    [[ $TRIGGER_COUNT -gt 0 ]] && rate=$((success * 100 / TRIGGER_COUNT))
    printf '  Triggers: %d │ Failures: %d │ Success: %d%% │ Peak: %d%%\n' \
        "$TRIGGER_COUNT" "$FAILURE_COUNT" "$rate" "$PEAK_PCT"

    # Footer
    printf '%.0s─' $(seq 1 "$cols"); echo
    printf '  \e[32m●\e[0m safe  \e[33m◐\e[0m compress  \e[34m⊘\e[0m cleared  \e[31m⚠\e[0m alert\n'
}

# ─── Modify main loop (replace echo on line 1620) ────────
# OLD:
#   echo -e "$(date +%H:%M:%S) ${color}${symbol}${NC} ${tokens} tokens (${pct}%) [$JICM_STATE]${heartbeat_marker}"
# NEW:
#   record_token "$tokens"
#   [[ $pct_int -gt $PEAK_PCT ]] && PEAK_PCT=$pct_int
#   render_dashboard "$pct" "$tokens" "$JICM_STATE" 2>/dev/null || true

# ─── Add add_event() calls at key transition points ──────
# In section 1.5 (compression success): add_event "═ COMPRESSION SUCCESS → /clear"
# In section 2.5 (emergency compact):   add_event "⚠ Emergency /compact at ${pct_int}%"
# In section 3 (threshold trigger):      add_event "◐ Threshold (${pct_int}%) → compression #${TRIGGER_COUNT}"
# In section 4 (cleared→monitoring):     add_event "● Context restored (${pct_int}%)"
# In idle-hands success:                  add_event "⟳ Session resumed (${mode})"
```

### Estimated Changes
- ~120 lines of new display functions
- ~15 lines of ring buffer globals/functions
- ~10 lines modifying existing code (replacing echo, adding events)
- **Total**: ~145 lines added, ~1 line removed (the old echo)
- Engine logic: ZERO changes

---

## 20. Brainstorm Evolution Summary
- Iterations 1-2: Current state assessment, problem identification (scrolling log, invisible events)
- Iteration 3: Dashboard mockup v1, gauge design, color zones
- Iteration 4: Burn rate + ETA calculation, event feed ring buffer
- Iteration 5: Health summary, rendering architecture (tput cup fixed layout)
- Iteration 6: Architecture options (in-script vs separate vs hybrid), Virgil integration
- Iteration 7: Self-review — glanceability principle, bash 3.2 compatibility, error isolation
- Iteration 8: v0.1 implementation skeleton with concrete code
- Iteration 9: Final review, open questions

---

## 21. Liveness & Visual Engagement

The user said the current output is "kinda boring." A dashboard needs visual *life*:

### Always-Moving Elements
- **Uptime counter**: Ticks every render (e.g., "2h 13m" → "2h 14m"). Shows the system is alive.
- **Gauge animation**: Even at steady state, the gauge fills/empties on each compression cycle. The sawtooth pattern is *visually interesting*.
- **Time-since-last-event**: "Last compression: 7 min ago" → "8 min ago" → "9 min ago". Passive motion.

### Color Pulsing (v0.2)
When in `compression_triggered` state, the state indicator could pulse:
```bash
# Alternating bright/dim yellow every render cycle
if [[ "$state" == "compression_triggered" ]]; then
    if [[ $((poll_count % 2)) -eq 0 ]]; then
        state_color="\e[33m"    # yellow
    else
        state_color="\e[93m"    # bright yellow
    fi
fi
```

This gives visual feedback that something is actively happening, without being distracting.

### Signal-Based Display Mode Toggle (v0.3)
```bash
DISPLAY_MODE="dashboard"  # or "log"
trap 'toggle_display' USR1

toggle_display() {
    if [[ "$DISPLAY_MODE" == "dashboard" ]]; then
        DISPLAY_MODE="log"
    else
        DISPLAY_MODE="dashboard"
    fi
}
# Toggle: kill -USR1 $(cat .watcher-pid)
```

This allows switching between the new dashboard and the classic scrolling log for debugging, without restarting.

---

## 22. Also Update Virgil Plan — Rename to Aion Scripts

The Virgil design doc should also be updated to use "Aion Scripts" instead of "Angel Scripts." The naming convention table becomes:

| Script | Role | Aion Aspect |
|--------|------|-------------|
| **Watcher** | Context guardian | Defensive awareness |
| **Virgil** | Codebase guide | Navigational awareness |
| (future) **Beatrice** | Session sage | Reflective awareness |

"Aion" captures the temporal, cyclical nature of these scripts — they watch over cycles of work, compression, and renewal. Less twee than "Angel," more aligned with the Project Aion branding.

---

## 23. Brainstorm Evolution Summary
- Iterations 1-2: Current state assessment, problem identification
- Iteration 3: Dashboard mockup v1, gauge design, color zones
- Iteration 4: Burn rate + ETA calculation, event feed ring buffer
- Iteration 5: Health summary, rendering architecture (tput fixed layout)
- Iteration 6: Architecture options (in-script vs separate vs hybrid), Virgil integration
- Iteration 7: Self-review — glanceability principle, bash 3.2 compat, error isolation
- Iteration 8: v0.1 implementation skeleton with concrete code
- Iteration 9: Compact mode, sparkline, state machine visualization
- Iteration 10: Liveness/engagement — always-moving elements, display mode toggle
- Iteration 11: Aion Script naming convention, final review

---

*Brainstorm produced over 11 Wiggum loop iterations, 2026-02-07 09:22-09:30 MST.*
