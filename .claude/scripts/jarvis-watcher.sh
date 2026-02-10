#!/bin/bash
# ============================================================================
# JARVIS UNIFIED WATCHER — JICM v5.8.4
# ============================================================================
# Implements the JICM v5 context management architecture.
#
# Architecture:
#   Section 0:   Standdown check
#   Section 1:   Command signals
#   Section 1.1: Idle-hands (planned transitions — post-clear resume, session start)
#   Section 1.2: Critical state detection (unplanned emergencies — context lockout)
#   Section 1.5: Compression completion → /clear
#   Section 2:   Context monitoring (token count, percentage)
#   Section 2.5: Emergency /compact (last resort, 5% from lockout)
#   Section 3:   Threshold check → trigger /intelligent-compress
#   Section 4:   State transitions (event-driven, Swiss watch precision)
#
# State machine: monitoring ↔ compression_triggered ↔ cleared
# Flow: section 3 → /intelligent-compress → section 1.5 → /clear → section 4
#
# Design: .claude/context/designs/jicm-v5-design-addendum.md
#
# Changelog v5.8.4 (2026-02-10, B.4 Chat Export):
#   - NEW: export_chat_history() — captures chat via tmux scrollback + /export
#     before compression and /clear. Two-layer approach: instant raw capture
#     (tmux capture-pane -S -) plus Claude Code's native /export for richer format.
#   - NEW: Auto-prune keeps last 20 exports in .claude/exports/
#   - WIRE: Section 3 calls export_chat_history("pre-compress") before /intelligent-compress
#   - WIRE: Section 1.5 calls export_chat_history("pre-clear") before /clear
#
# Changelog v5.8.3 (2026-02-10, B.4 JICM Integration):
#   - FIX: 300s failsafe infinite loop — added cooldown period (600s) after failsafe
#     timeout to prevent immediate re-trigger. Root cause: state reset to monitoring
#     caused section 3 to immediately re-trigger compression since pct > threshold.
#   - FIX: Emergency /compact blocked during stuck compression — removed blanket
#     `state != compression_triggered` guard. Now allows emergency /compact when
#     compression has been stuck for 180s+ AND context is at emergency level.
#   - FIX: /clear failsafe too aggressive — extended from 60s to 120s, added retry
#     before giving up. On first timeout, retries /clear. On second, records failure.
#   - FIX: Failsafe timeouts now call record_failure() to trigger standdown after
#     3 consecutive failures (was missing, so standdown never activated).
#   - NEW: Cooldown mechanism (COOLDOWN_UNTIL) — suppresses auto-trigger for a
#     configurable period after failsafe fires. Breaks the cascading failure chain.
#   - NEW: Context file archival — cleanup_jicm_files() now archives compressed
#     context and in-progress files to .claude/logs/jicm/archive/ with timestamps
#     instead of deleting them. Keeps last 20 archives.
#
# Changelog v5.8.2 (2026-02-08):
#   - FIX: Section 1.5 JICM-DUMP now uses send_text() (includes wait_for_idle_brief)
#     instead of raw send-keys, preventing prompt text from getting stuck in TUI input
#   - FIX: Section 1.5 checks if .in-progress-ready.md already exists and is recent
#     (<120s old) before deleting and requesting a fresh dump. Prevents race with
#     Jarvis who may have already written the file before watcher reaches section 1.5
#   - FIX: Section 4 B2 check now also checks for JICM_COMPLETE_SIGNAL before
#     firing emergency restore. Previously, idle-hands would clean up its flag,
#     then B2 would see "no flag" and fire emergency even though resume succeeded
#   - FIX: handle_critical_state "post_clear_unhandled" now uses send_text()
#     instead of raw send-keys (same idle-wait fix as section 1.5)
#
# Changelog v5.8.2 (2026-02-08):
#   - FIX: Section 1.5 JICM-DUMP now uses send_text() (includes wait_for_idle_brief)
#     instead of raw send-keys, preventing prompt text stuck in TUI during generation
#   - FIX: Section 1.5 checks .in-progress-ready.md age before deleting — if <120s
#     old, skips dump request (Jarvis may have already written it)
#   - FIX: Section 4 B2 now checks JICM_COMPLETE_SIGNAL before firing emergency
#     restore. Idle-hands cleanup was deleting its flag, making B2 think hooks failed
#   - FIX: handle_critical_state post_clear_unhandled uses send_text() (idle-wait)
#
# Changelog v5.8.1 (2026-02-07):
#   - Added .compression-in-progress cleanup to cleanup_jicm_signals_only() and cleanup_jicm_files()
#   - Prevents stale compression flag from blocking future JICM cycles after agent crash
#   - Documented JICM-EMERGENCY as expected B2 FIX behavior in design addendum
#
# Changelog v5.8.2 (2026-02-06):
#   - Removed --continue skip for session_start idle-hands
#   - AC-01 protocol now runs for ALL session types (fresh and continue)
#   - Continued sessions need Mechanism 2 (keystroke injection) same as fresh
#
# Changelog v5.6.1 (2026-02-06):
#   - Fixed command delivery: wait_for_idle_brief() polls before send_command/send_text
#   - Root cause: tmux send-keys during active generation consumed as text input
#   - is_claude_busy() now returns via echo (bash 3.2 set -e safety), restricted to tail -5
#   - All send_prompt_by_type() prompts converted to single-line (multi-line -l corrupts input)
#   - Removed all DEBUG echo lines, cleaned up ERR/EXIT traps
#
# Changelog v5.6.0 (2026-02-06):
#   COMPREHENSIVE REWRITE — 19 issues addressed across 4 categories
#   Category A (Core Flow):
#   - A1: Fixed bash 3.2 return 1 in $() across 6 functions; extended tail -5
#   - A2: Event-driven state machine (Swiss watch), 3 active states only
#   - A3: Compression success path clarity — fixed double-counting, short-circuit
#   - A4: Grace period on ALL /clear paths (not just startup)
#   - A5: Single poll_count increment point (was double in pct=0 path)
#   Category B (Design Flaws):
#   - B1: Removed all wait_for_idle blocking calls
#   - B2: post_clear_unhandled catches hook failures at cleared→monitoring transition
#   - B3: Removed MAX_TRIGGERS death-count (penalized successful compressions)
#   - B4: All warnings now take corrective action or are informational
#   - B5: Resolved by B3 (no trigger limit = no else branch)
#   - B6: Reduced jicm_resume max_cycles from 50 to 20 (~4 min)
#   Category C (Dead Code):
#   - C1: Removed JICM_CRITICAL_PCT (never used as condition)
#   - C2: Removed trigger_fallback_compact (dead v4)
#   - C3: Removed 9 dead v4 functions (spawn, executor, cascade, etc.)
#   - C4: Removed sections 2 & 3 from main loop (v4 state handlers)
#   Category D (New Design):
#   - D1: Emergency /compact at 5% from lockout (73% with defaults)
#   - D2: --session-type flag for --continue awareness
#   - D3: Customized resume prompts per mode (jicm_resume, session_start)
#   - D4: Clear separation between idle-hands (planned) and critical-state (emergency)
#
# Changelog v5.5.1 (2026-02-05):
#   - detect_critical_state() restricts checks to last 8/10 lines (stale buffer fix)
#   - Extended startup grace period from 2 to 4 iterations
#
# Changelog v5.5.0 (2026-02-05):
#   - Lowered default JICM_THRESHOLD from 80% to 65% (lockout-aware, superseded by v5.7.0)
#
# Changelog v5.4.5 (2026-02-05):
#   - PROPERLY FIXED context_exhausted loop using state machine, not debouncing
#   - Root cause: After sending /clear, state remained "monitoring", so
#     context_exhausted was re-detected before TUI refreshed
#   - Fix: context_exhausted detection ONLY runs when JICM_STATE=="monitoring"
#   - After handling context_exhausted, transition to state "cleared"
#   - State machine prevents re-triggering; no debounce needed
#
# Changelog v5.4.4 (2026-02-05):
#   - Attempted fix with debouncing (reverted - wrong approach)
#
# Changelog v5.4.3 (2026-02-05):
#   - FIXED token extraction bug: get_tokens_from_tui_exact() now uses tail -3
#     to restrict search to statusline area, preventing false matches from
#     old tool outputs in scroll buffer (e.g., bash commands showing token counts)
#   - Root cause: grep on full pane captured "181417 tokens" from old output
#     while percentage correctly read 2% from statusline, causing data inconsistency
#   - Added emergency context limit detection for "Context limit reached" and
#     "Conversation too long" messages - triggers automatic /clear
#
# Changelog v5.4.2 (2026-02-05):
#   - DISABLED "interrupted" state handler (removed entirely in v5.6.0)
#   - User interrupts are intentional; user will provide next instruction
#
# Changelog v5.4.1 (2026-02-05):
#   - Reduced TUI stabilization wait from 15s to 5s (faster resume)
#   - Expanded idle detection keywords: added "already restored", "ready for",
#     "ready when", "acknowledged", "awaiting" patterns
#   - Prevents duplicate resume prompts after successful context restoration
#
# Changelog v5.4.0 (2026-02-05):
#   - Added signal-aware shutdown logging (shows which signal caused exit)
#   - Added heartbeat display every 6 iterations (even if tokens unchanged)
#   - Added token extraction method to debug output
#   - Fixed stale cache loop (limit consecutive inconsistency retries)
#   - Fixed display condition to show periodic status updates
#
# Changelog v5.3.2 (2026-02-05):
#   - Fixed bash 3.2 (macOS) set -e exit bug: detect_critical_state() now returns 0
#     (command substitution with non-zero return causes immediate exit in bash 3.2)
#
# Changelog v5.3.1 (2026-02-05):
#   - Fixed crash on startup due to missing error handling in handle_critical_state()
#   - Added 2>/dev/null || true to tmux send-keys commands
#   - Added startup grace period (skip critical state detection for first 2 iterations)
#   - Fixed token_method tracking (subshell export → temp file)
#   - Fixed poll_count=$((poll_count + 1)) causing exit when poll_count=0 (bash arithmetic gotcha)
#
# Changelog v5.3.0 (2026-02-05):
#   - Added detect_critical_state() for TUI state detection
#   - Added handle_critical_state() — see v5.6.0 for current scope
#   - Integrated critical state check into main loop (section 1.2)
#
# Changelog v5.2.0 (2026-02-05):
#   - Added invalidate_tui_cache() to reset cache after /clear
#   - Added check_data_consistency() to detect stale percentage/token mismatches
#   - Extended post-clear settling delay from 5s to 15s
#   - Fixed race condition causing stale token counts after context reset
#
# Usage:
#   .claude/scripts/jarvis-watcher.sh [--threshold PCT]
#
# ============================================================================

set -euo pipefail

# Trap ERR to show where script fails (essential for bash 3.2 set -e debugging)
trap 'echo "$(date +%H:%M:%S) [ERR] Script failed at line $LINENO (exit code: $?)" >&2' ERR

# =============================================================================
# CONFIGURATION
# =============================================================================

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$HOME/Claude/Jarvis}"
TMUX_BIN="${TMUX_BIN:-$HOME/bin/tmux}"
TMUX_SESSION="${TMUX_SESSION:-jarvis}"
TMUX_TARGET="${TMUX_SESSION}:0"

# Paths
SIGNAL_FILE="$PROJECT_DIR/.claude/context/.command-signal"
LOG_FILE="$PROJECT_DIR/.claude/logs/jarvis-watcher.log"
STATUS_FILE="$PROJECT_DIR/.claude/context/.watcher-status"
PID_FILE="$PROJECT_DIR/.claude/context/.watcher-pid"

# JICM v5 Signal Files (see jicm-v5-design-addendum.md Section 3)
COMPRESSION_DONE_SIGNAL="$PROJECT_DIR/.claude/context/.compression-done.signal"
DUMP_REQUESTED_SIGNAL="$PROJECT_DIR/.claude/context/.dump-requested.signal"
IN_PROGRESS_FILE="$PROJECT_DIR/.claude/context/.in-progress-ready.md"
COMPRESSED_CONTEXT_FILE="$PROJECT_DIR/.claude/context/.compressed-context-ready.md"
CLEAR_SENT_SIGNAL="$PROJECT_DIR/.claude/context/.clear-sent.signal"
CONTINUATION_INJECTED_SIGNAL="$PROJECT_DIR/.claude/context/.continuation-injected.signal"
JICM_COMPLETE_SIGNAL="$PROJECT_DIR/.claude/context/.jicm-complete.signal"
STANDDOWN_FILE="$PROJECT_DIR/.claude/context/.jicm-standdown"
IDLE_HANDS_FLAG="$PROJECT_DIR/.claude/context/.idle-hands-active"
COMPRESSION_IN_PROGRESS="$PROJECT_DIR/.claude/context/.compression-in-progress"
PRE_CLEAR_TOKENS_FILE="$PROJECT_DIR/.claude/context/.pre-clear-tokens"
JICM_CONFIG_FILE="$PROJECT_DIR/.claude/context/.jicm-config"

# Chat export directory (B.4 enhancement: auto-export before compress/clear)
EXPORTS_DIR="$PROJECT_DIR/.claude/exports"

# Thresholds (JICM v5)
# Single threshold for compression trigger (dynamically configurable)
# See: jicm-v5-design-addendum.md Section 2.2
#
# CRITICAL: Auto-compact fires at ~85% effective (default 95% minus internal reserves).
# Default threshold 55% provides 30% (60K tokens) headroom for:
#   - Current multi-step turn to complete before compression starts (~20% worst case)
#   - Compression skill overhead (~1%)
#   - Compression agent completion (~5%)
# Calculation: 55% + 20% + 1% + 5% = 81% < 85% auto-compact
JICM_THRESHOLD=${JICM_THRESHOLD:-55}
RESERVED_OUTPUT_TOKENS=${RESERVED_OUTPUT_TOKENS:-15000}
DEFAULT_INTERVAL=5

# v4 timeouts removed (C4): AGENT_TIMEOUT, DUMP_TIMEOUT, CONTINUATION_DELAY_*

# Circuit Breakers
DEBOUNCE_SECONDS=300     # 5 min (used as compression_triggered failsafe timeout)
FAILURES_BEFORE_STANDDOWN=3  # Consecutive failures before standdown
# NOTE: MAX_TRIGGERS removed (B3). Trigger count is tracked for observability
# but never used as a gate. Penalizing successful compressions is wrong.

# Context window & lockout (D1)
MAX_CONTEXT_TOKENS=200000
COMPACT_BUFFER_ESTIMATE=${COMPACT_BUFFER_ESTIMATE:-28000}  # Claude Code's internal compact buffer

# Emergency /compact threshold: 5% below lockout ceiling
# Lockout = (context_window - output_reserve - compact_buffer) / context_window
LOCKOUT_PCT=$(( (MAX_CONTEXT_TOKENS - RESERVED_OUTPUT_TOKENS - COMPACT_BUFFER_ESTIMATE) * 100 / MAX_CONTEXT_TOKENS ))
EMERGENCY_COMPACT_PCT=$((LOCKOUT_PCT - 5))

# Session type (D2: --continue awareness)
SESSION_TYPE="fresh"  # Default: fresh session. Set to "continue" via --session-type

# Parse arguments
INTERVAL=$DEFAULT_INTERVAL
while [[ $# -gt 0 ]]; do
    case $1 in
        --threshold) JICM_THRESHOLD="$2"; shift 2 ;;
        --interval) INTERVAL="$2"; shift 2 ;;
        --session-type) SESSION_TYPE="$2"; shift 2 ;;
        -h|--help)
            echo "JARVIS WATCHER v5.8.4 — JICM v5 with event-driven state machine"
            echo ""
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  --threshold PCT       Compression trigger (default: $JICM_THRESHOLD)"
            echo "  --interval SEC        Poll interval (default: $DEFAULT_INTERVAL)"
            echo "  --session-type TYPE   Session type: fresh|continue (default: fresh)"
            exit 0
            ;;
        *) shift ;;
    esac
done

# Supported commands whitelist
SUPPORTED_COMMANDS=(
    "/compact" "/rename" "/resume" "/export" "/doctor"
    "/status" "/usage" "/cost" "/bashes" "/review"
    "/plan" "/security-review" "/stats" "/todos" "/context"
    "/hooks" "/release-notes" "/clear" "/statusline"
    "/intelligent-compress"
)

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# =============================================================================
# SETUP
# =============================================================================

mkdir -p "$(dirname "$LOG_FILE")"
mkdir -p "$(dirname "$STATUS_FILE")"
mkdir -p "$(dirname "$SIGNAL_FILE")"
mkdir -p "$EXPORTS_DIR"
echo $$ > "$PID_FILE"

# State tracking
JICM_STATE="monitoring"
JICM_LAST_TRIGGER=0
TRIGGER_COUNT=0
FAILURE_COUNT=0
GRACE_RESUME_UNTIL=0  # Timestamp until which grace period is active (post-clear, startup)
EMERGENCY_COMPACT_SENT=false  # D1: Tracks if emergency /compact was sent (reset on context drop)
COOLDOWN_UNTIL=0             # B.4: Cooldown timestamp — suppresses auto-trigger after failsafe
CLEAR_RETRY_COUNT=0          # B.4: Track /clear retry attempts in "cleared" state

# =============================================================================
# LOGGING
# =============================================================================

log() {
    local level="$1"
    local msg="$2"
    local timestamp
    timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    echo "$timestamp | $level | $msg" >> "$LOG_FILE"

    case $level in
        INFO)  echo -e "${GREEN}[$level]${NC} $msg" ;;
        WARN)  echo -e "${YELLOW}[$level]${NC} $msg" ;;
        ERROR) echo -e "${RED}[$level]${NC} $msg" ;;
        JICM)  echo -e "${MAGENTA}[$level]${NC} $msg" ;;
        CMD)   echo -e "${CYAN}[$level]${NC} $msg" ;;
        *)     echo "[$level] $msg" ;;
    esac
}

# =============================================================================
# CONTEXT MONITORING (v5.1.0 — Robust Multi-Method)
# =============================================================================
# Token extraction priority:
#   1. PRIMARY: Parse exact tokens from TUI pane capture ("63257 tokens")
#   2. SECONDARY: Parse abbreviated format from TUI ("63.2k")
#   3. FALLBACK: Sum current_usage fields from statusline JSON
#   4. VALIDATION: Cross-check against percentage × context_window_size
#
# This approach handles:
#   - Debug mode vs non-debug mode screen format differences
#   - Stale or missing statusline JSON
#   - Various TUI layout configurations

STATUSLINE_FILE="$HOME/.claude/logs/statusline-input.json"

# Cache for TUI capture (avoid repeated tmux calls within same poll cycle)
CACHED_PANE_CONTENT=""
CACHED_PANE_TIME=0

# Invalidate TUI cache (call after /clear or state transitions)
invalidate_tui_cache() {
    CACHED_PANE_CONTENT=""
    CACHED_PANE_TIME=0
}

# Capture TUI pane content (cached for 5 seconds)
capture_tui_pane() {
    local now
    now=$(date +%s)
    local cache_age=$((now - CACHED_PANE_TIME))

    if [[ $cache_age -lt 5 ]] && [[ -n "$CACHED_PANE_CONTENT" ]]; then
        echo "$CACHED_PANE_CONTENT"
        return 0
    fi

    if ! "$TMUX_BIN" has-session -t "$TMUX_SESSION" 2>/dev/null; then
        echo ""
        return 0  # bash 3.2 set -e compatibility
    fi

    CACHED_PANE_CONTENT=$("$TMUX_BIN" capture-pane -t "$TMUX_TARGET" -p 2>/dev/null || echo "")
    CACHED_PANE_TIME=$now
    echo "$CACHED_PANE_CONTENT"
}

# METHOD 1: Parse exact token count from TUI (e.g., "63257 tokens")
# BUGFIX v5.4.3: Restrict to last 3 lines (statusline area) to avoid matching
# old tool outputs that show token counts elsewhere in the scroll buffer.
# Root cause: grep on full pane captured stale values from bash outputs.
get_tokens_from_tui_exact() {
    local pane_content
    pane_content=$(capture_tui_pane)

    if [[ -z "$pane_content" ]]; then
        echo "0"
        return 0  # Always return 0 (bash 3.2 set -e compatibility)
    fi

    # Look for exact token count in statusline area (last 5 lines)
    # Extended from tail -3 to tail -5 to handle varying TUI layouts:
    # bypass-permissions line, statusline, input prompt, etc.
    # CRITICAL: Must use tail BEFORE grep to avoid stale scroll buffer
    local exact_tokens
    exact_tokens=$(echo "$pane_content" | tail -5 | grep -oE '[0-9]+ tokens' | tail -1 | grep -oE '[0-9]+' || true)

    if [[ -n "$exact_tokens" ]] && [[ "$exact_tokens" -gt 0 ]]; then
        echo "$exact_tokens"
        return 0
    fi

    echo "0"
    return 0
}

# METHOD 2: Parse abbreviated token count from TUI (e.g., "63.2k")
get_tokens_from_tui_abbreviated() {
    local pane_content
    pane_content=$(capture_tui_pane)

    if [[ -z "$pane_content" ]]; then
        echo "0"
        return 0
    fi

    # Look for abbreviated format in status bar: "63.2k" or "63k"
    # Extended to tail -5 for varying TUI layouts
    local abbrev_tokens
    abbrev_tokens=$(echo "$pane_content" | tail -5 | grep -oE '[0-9]+\.?[0-9]*k' | head -1 || true)

    if [[ -n "$abbrev_tokens" ]]; then
        local numeric_part
        numeric_part="${abbrev_tokens%k}"
        if [[ "$numeric_part" == *"."* ]]; then
            local result
            result=$(echo "$numeric_part * 1000" | bc 2>/dev/null | cut -d'.' -f1 || true)
            if [[ -n "$result" ]] && [[ "$result" -gt 0 ]]; then
                echo "$result"
                return 0
            fi
        else
            echo $((numeric_part * 1000))
            return 0
        fi
    fi

    echo "0"
    return 0
}

# METHOD 3: Parse percentage from TUI (e.g., "32%")
get_percentage_from_tui() {
    local pane_content
    pane_content=$(capture_tui_pane)

    if [[ -z "$pane_content" ]]; then
        echo "0"
        return 0  # bash 3.2 set -e compatibility
    fi

    # Look for percentage in status bar area (last 5 lines)
    local pct
    pct=$(echo "$pane_content" | tail -5 | grep -oE '[0-9]+%' | head -1 | tr -d '%' || true)

    if [[ -n "$pct" ]] && [[ "$pct" -gt 0 ]] && [[ "$pct" -le 100 ]]; then
        echo "$pct"
        return 0
    fi

    echo "0"
    return 0
}

# METHOD 4: Get context from statusline JSON (fallback)
get_context_status() {
    if [[ ! -f "$STATUSLINE_FILE" ]]; then
        echo '{"context_window": {"used_percentage": 0, "remaining_percentage": 100}}'
        return 0
    fi
    cat "$STATUSLINE_FILE" 2>/dev/null || echo '{"context_window": {"used_percentage": 0}}'
    return 0
}

# METHOD 5: Sum current_usage fields from statusline JSON
get_tokens_from_json_current_usage() {
    local status
    status=$(get_context_status 2>/dev/null)

    if [[ -z "$status" ]]; then
        echo "0"
        return 0  # bash 3.2 set -e compatibility
    fi

    # Sum all current_usage token fields
    local input output cache_create cache_read total
    input=$(echo "$status" | jq -r '.context_window.current_usage.input_tokens // 0' 2>/dev/null || echo "0")
    output=$(echo "$status" | jq -r '.context_window.current_usage.output_tokens // 0' 2>/dev/null || echo "0")
    cache_create=$(echo "$status" | jq -r '.context_window.current_usage.cache_creation_input_tokens // 0' 2>/dev/null || echo "0")
    cache_read=$(echo "$status" | jq -r '.context_window.current_usage.cache_read_input_tokens // 0' 2>/dev/null || echo "0")

    total=$((input + output + cache_create + cache_read))
    echo "$total"
    return 0
}

# METHOD 6: Calculate tokens from percentage (validation/fallback)
get_tokens_from_percentage() {
    local pct="$1"
    local context_size="${2:-$MAX_CONTEXT_TOKENS}"
    echo $(( (pct * context_size) / 100 ))
}

# MAIN FUNCTION: Get percentage (prioritizes TUI, falls back to JSON)
get_used_percentage() {
    local pct

    # Try TUI first (most accurate, real-time)
    pct=$(get_percentage_from_tui)
    if [[ "$pct" != "0" ]] && [[ -n "$pct" ]]; then
        echo "$pct"
        return 0
    fi

    # Fallback to statusline JSON
    local status
    status=$(get_context_status 2>/dev/null)
    pct=$(echo "$status" | jq -r '.context_window.used_percentage // 0' 2>/dev/null || echo "0")
    echo "$pct"
}

# Sanity check: detect stale cache (percentage vs tokens mismatch)
# Returns 0 if data appears consistent, 1 if stale/mismatched
check_data_consistency() {
    local tokens="$1"
    local pct="$2"

    # If percentage < 10% but tokens > 100K, data is stale
    if [[ "$pct" -lt 10 ]] && [[ "$tokens" -gt 100000 ]]; then
        log WARN "Data inconsistency detected: ${tokens} tokens at ${pct}% - invalidating cache"
        invalidate_tui_cache
        return 1
    fi

    # If percentage > 50% but tokens < 50K, data is stale
    if [[ "$pct" -gt 50 ]] && [[ "$tokens" -lt 50000 ]]; then
        log WARN "Data inconsistency detected: ${tokens} tokens at ${pct}% - invalidating cache"
        invalidate_tui_cache
        return 1
    fi

    return 0
}

# MAIN FUNCTION: Get token count (multi-method with validation)
get_token_count() {
    local tokens=0
    local method_used=""

    # METHOD 1: Try exact TUI tokens first (most accurate)
    tokens=$(get_tokens_from_tui_exact)
    if [[ "$tokens" != "0" ]] && [[ -n "$tokens" ]]; then
        method_used="tui_exact"
    fi

    # METHOD 2: Try abbreviated TUI tokens
    if [[ "$tokens" == "0" ]] || [[ -z "$tokens" ]]; then
        tokens=$(get_tokens_from_tui_abbreviated)
        if [[ "$tokens" != "0" ]] && [[ -n "$tokens" ]]; then
            method_used="tui_abbrev"
        fi
    fi

    # METHOD 3: Try JSON current_usage sum
    if [[ "$tokens" == "0" ]] || [[ -z "$tokens" ]]; then
        tokens=$(get_tokens_from_json_current_usage)
        if [[ "$tokens" != "0" ]] && [[ -n "$tokens" ]]; then
            method_used="json_usage"
        fi
    fi

    # VALIDATION: Cross-check against percentage estimate
    local pct
    pct=$(get_used_percentage)
    local pct_estimate
    pct_estimate=$(get_tokens_from_percentage "$pct" "$MAX_CONTEXT_TOKENS")

    # If we got tokens, validate they're roughly consistent with percentage
    if [[ "$tokens" -gt 0 ]] && [[ "$pct_estimate" -gt 0 ]]; then
        # Allow 20% variance between token count and percentage estimate
        local variance_threshold=$((pct_estimate / 5))  # 20%
        local diff=$((tokens - pct_estimate))
        diff=${diff#-}  # Absolute value

        if [[ $diff -gt $variance_threshold ]] && [[ $variance_threshold -gt 1000 ]]; then
            # Significant mismatch - log warning but use TUI value if available
            # (TUI is authoritative, JSON might be stale)
            if [[ "$method_used" == "tui_exact" ]] || [[ "$method_used" == "tui_abbrev" ]]; then
                # Trust TUI over JSON estimate
                :
            else
                # No TUI data, use percentage estimate as more reliable
                tokens=$pct_estimate
                method_used="pct_estimate"
            fi
        fi
    fi

    # FALLBACK: If still no tokens, use percentage estimate
    if [[ "$tokens" == "0" ]] || [[ -z "$tokens" ]]; then
        tokens=$pct_estimate
        method_used="pct_fallback"
    fi

    # Store method used for debugging (write to file since subshell can't export)
    echo "$method_used" > /tmp/jicm-token-method.$$

    echo "$tokens"
}

update_status() {
    local tokens="$1"
    local pct="$2"
    local state="$3"

    # Read token method from temp file (set by get_token_count in subshell)
    local token_method="unknown"
    if [[ -f /tmp/jicm-token-method.$$ ]]; then
        token_method=$(cat /tmp/jicm-token-method.$$)
    fi

    cat > "$STATUS_FILE" <<EOF
timestamp: $(date -u +%Y-%m-%dT%H:%M:%SZ)
version: 5.8.4
tokens: $tokens
percentage: $pct%
threshold: $JICM_THRESHOLD%
state: $state
trigger_count: $TRIGGER_COUNT
failure_count: $FAILURE_COUNT
token_method: $token_method
session_type: $SESSION_TYPE
EOF
}

# =============================================================================
# CIRCUIT BREAKERS
# =============================================================================

check_standdown() {
    if [[ -f "$STANDDOWN_FILE" ]]; then
        log WARN "JICM in standdown mode - native auto-compact will handle"
        return 0  # In standdown
    fi
    return 1  # Not in standdown
}

enter_standdown() {
    local reason="$1"
    echo "standdown: $reason" > "$STANDDOWN_FILE"
    echo "timestamp: $(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$STANDDOWN_FILE"
    log ERROR "JICM entering STANDDOWN: $reason"
    log ERROR "Native Claude Code auto-compact will handle context management"
}

# check_debounce() removed (C3) — dead code, no callers
# check_trigger_limit() removed (B3) — penalizing successful compressions is wrong.
# Standdown is only triggered by FAILURES_BEFORE_STANDDOWN (consecutive failures).

record_failure() {
    FAILURE_COUNT=$((FAILURE_COUNT + 1))
    if [[ $FAILURE_COUNT -ge $FAILURES_BEFORE_STANDDOWN ]]; then
        enter_standdown "Too many failures ($FAILURE_COUNT)"
    fi
}

reset_failure_count() {
    FAILURE_COUNT=0
}

# Write JICM config file for statusline to read
# This allows the statusline to show dynamic threshold markers
write_jicm_config() {
    cat > "$JICM_CONFIG_FILE" << EOF
# JICM Configuration - shared between watcher and statusline
# Auto-generated by jarvis-watcher.sh on startup
# Last updated: $(date -u +%Y-%m-%dT%H:%M:%SZ)

JICM_THRESHOLD=$JICM_THRESHOLD
JICM_APPROACH_OFFSET=${JICM_APPROACH_OFFSET:-10}
# JICM_CRITICAL_PCT removed (C1) — was never used as a condition
RESERVED_OUTPUT_TOKENS=$RESERVED_OUTPUT_TOKENS
CONTEXT_WINDOW_SIZE=$MAX_CONTEXT_TOKENS

# Overhead category defaults (tokens) — tunable from /context output
# Last calibrated: 2026-01-24 (from captured /context data)
OVERHEAD_SYS_PROMPT=\${OVERHEAD_SYS_PROMPT:-2700}
OVERHEAD_SYS_TOOLS=\${OVERHEAD_SYS_TOOLS:-17100}
OVERHEAD_AGENTS=\${OVERHEAD_AGENTS:-300}
OVERHEAD_MEMORY=\${OVERHEAD_MEMORY:-1100}
OVERHEAD_SKILLS=\${OVERHEAD_SKILLS:-1700}
OVERHEAD_COMPACT=\${OVERHEAD_COMPACT:-3000}

# Cache consistency threshold — invalidate when API vs cache diverge by this fraction
CACHE_CONSISTENCY_THRESHOLD=0.25
EOF
    log INFO "Wrote JICM config (threshold: ${JICM_THRESHOLD}%, reserved: ${RESERVED_OUTPUT_TOKENS})"
}

# =============================================================================
# IDLE DETECTION
# =============================================================================

is_claude_busy() {
    # Returns via echo: "busy" or "idle" (not return codes — bash 3.2 set -e safety)
    local pane_content
    pane_content=$("$TMUX_BIN" capture-pane -t "$TMUX_TARGET" -p 2>/dev/null || echo "")

    # Check last 5 lines for spinner/processing indicators (avoid scroll history)
    local busy_match
    busy_match=$(echo "$pane_content" | tail -5 | grep -cE '[⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏◐◓◑◒▁▂▃▄▅▆▇]|Thinking|Processing|⣾⣽⣻⢿⡿⣟⣯⣷' || true)

    if [[ "$busy_match" -gt 0 ]]; then
        echo "busy"
        return 0
    fi
    echo "idle"
    return 0
}

# Wait for Claude to become idle before sending commands.
# Unlike the old wait_for_idle() (removed in B1/C3 for blocking the main loop),
# this is a BRIEF poll used ONLY inside send_command() — it blocks the command
# delivery, not the entire monitoring loop. Max wait: 30s with 2s intervals.
# After timeout, sends anyway (better to attempt delivery than skip entirely).
wait_for_idle_brief() {
    local max_wait=${1:-30}
    local poll_interval=2
    local waited=0

    while [[ $waited -lt $max_wait ]]; do
        local status
        status=$(is_claude_busy)
        if [[ "$status" == "idle" ]]; then
            return 0  # Ready to send
        fi
        log CMD "Waiting for Claude to finish generating... (${waited}s/${max_wait}s)"
        sleep "$poll_interval"
        waited=$((waited + poll_interval))
    done

    log WARN "wait_for_idle_brief: Claude still busy after ${max_wait}s, proceeding anyway"
    return 0  # Always return 0 for bash 3.2 safety
}

# =============================================================================
# COMMAND EXECUTION
# =============================================================================

is_valid_command() {
    local cmd="$1"
    for valid in "${SUPPORTED_COMMANDS[@]}"; do
        if [[ "$cmd" == "$valid" ]]; then
            return 0
        fi
    done
    return 1
}

send_command() {
    local command="$1"
    local args="${2:-}"

    if ! "$TMUX_BIN" has-session -t "$TMUX_SESSION" 2>/dev/null; then
        log ERROR "tmux session '$TMUX_SESSION' not found"
        return 0  # bash 3.2 safety
    fi

    local full_command="$command"
    if [[ -n "$args" ]]; then
        full_command="$command $args"
    fi

    # Wait for Claude to stop generating before injecting keystrokes.
    # Without this, send-keys text gets consumed as input buffer content
    # during active generation and never executes as a slash command.
    # See: first live test 2026-02-06, /clear was lost during generation.
    wait_for_idle_brief 30

    log CMD "Sending: $full_command"
    # Canonical pattern (Section 6.4.1): text via -l, then C-m as SEPARATE call
    "$TMUX_BIN" send-keys -t "$TMUX_TARGET" -l "$full_command"
    sleep 0.1
    "$TMUX_BIN" send-keys -t "$TMUX_TARGET" C-m
    return 0
}

send_text() {
    local text="$1"
    if ! "$TMUX_BIN" has-session -t "$TMUX_SESSION" 2>/dev/null; then
        log ERROR "tmux session '$TMUX_SESSION' not found"
        return 0  # bash 3.2 safety
    fi

    # Same idle-wait as send_command() — text prompts also need Claude to be at prompt
    wait_for_idle_brief 30

    log CMD "Sending text (${#text} chars)"
    # Canonical pattern (Section 6.4.1): text via -l, then C-m as SEPARATE call
    "$TMUX_BIN" send-keys -t "$TMUX_TARGET" -l "$text"
    sleep 0.1
    "$TMUX_BIN" send-keys -t "$TMUX_TARGET" C-m
    return 0
}

# =============================================================================
# CHAT EXPORT (B.4 enhancement)
# =============================================================================
# Captures chat history before compression or /clear for context preservation.
# Two-layer approach:
#   1. Raw tmux capture (instant, always works, limited by scrollback buffer)
#   2. Built-in /export command (full conversation, needs idle time)
#
# Called by: section 3 (before compression), section 1.5 (before /clear)
export_chat_history() {
    local trigger_reason="${1:-manual}"
    local timestamp
    timestamp=$(date +%Y%m%d-%H%M%S)
    local export_file="$EXPORTS_DIR/chat-${timestamp}-${trigger_reason}.txt"

    # Layer 1: Instant raw tmux capture (scrollback buffer)
    if "$TMUX_BIN" capture-pane -t "$TMUX_TARGET" -p -S - > "$export_file" 2>/dev/null; then
        local line_count
        line_count=$(wc -l < "$export_file" | tr -d ' ')
        log EXPORT "Raw capture saved: $export_file (${line_count} lines, trigger: $trigger_reason)"
    else
        log WARN "Raw tmux capture failed (trigger: $trigger_reason)"
    fi

    # Layer 2: Send built-in /export for Claude Code's richer format
    # This runs async — the file will be written by Claude Code to its default location
    send_command "/export"
    log EXPORT "Sent /export command (trigger: $trigger_reason)"

    # Prune old exports (keep last 20)
    local export_count
    export_count=$(ls -1 "$EXPORTS_DIR"/chat-*.txt 2>/dev/null | wc -l | tr -d ' ')
    if [[ "$export_count" -gt 20 ]]; then
        ls -1t "$EXPORTS_DIR"/chat-*.txt 2>/dev/null | tail -n +21 | xargs rm -f 2>/dev/null || true
        log EXPORT "Pruned old exports (kept 20, removed $((export_count - 20)))"
    fi

    return 0
}

process_signal_file() {
    if [[ ! -f "$SIGNAL_FILE" ]]; then
        return 1
    fi

    local signal_content
    signal_content=$(cat "$SIGNAL_FILE")

    local command args source
    command=$(echo "$signal_content" | jq -r '.command // empty' 2>/dev/null || echo "")
    args=$(echo "$signal_content" | jq -r '.args // empty' 2>/dev/null || echo "")
    source=$(echo "$signal_content" | jq -r '.source // "unknown"' 2>/dev/null || echo "unknown")

    if [[ -z "$command" ]]; then
        log WARN "Invalid signal file (no command)"
        rm -f "$SIGNAL_FILE"
        return 1
    fi

    if ! is_valid_command "$command"; then
        log WARN "Command not in whitelist: $command"
        rm -f "$SIGNAL_FILE"
        return 1
    fi

    log INFO "Processing signal: $command from $source"
    rm -f "$SIGNAL_FILE"
    send_command "$command" "$args"
    return 0
}

# =============================================================================
# JICM v4 WORKFLOW
# =============================================================================

# Clean up JICM signal files only (not context files)
cleanup_jicm_signals_only() {
    rm -f "$COMPRESSION_DONE_SIGNAL"
    rm -f "$DUMP_REQUESTED_SIGNAL"
    rm -f "$CLEAR_SENT_SIGNAL"
    rm -f "$CONTINUATION_INJECTED_SIGNAL"
    rm -f "$JICM_COMPLETE_SIGNAL"
    rm -f "$COMPRESSION_IN_PROGRESS"
}

# v4 functions removed (C3):
#   spawn_compression_agent() — v5 uses /intelligent-compress command
#   executor_layer1_interrupt_and_dump() — v5 compression handles context saving
#   executor_layer2_wait_and_clear() — v5 section 1.5 handles /clear
#   trigger_cascade_resumer() — v5 idle-hands handles resume
#   inject_continuation_prompt() — v5 session-start hook handles injection

# =============================================================================
# IDLE-HANDS MONITOR (JICM v5 Mechanism 2)
# =============================================================================
# See: jicm-v5-design-addendum.md Section 6, 7, and 10
# See: jicm-v5-resume-mechanisms.md
# See: lessons/tmux-self-injection-limitation.md
#
# CANONICAL SUBMISSION PATTERN (validated 2026-02-04):
#   1. Send text via: send-keys -t TARGET -l "text"
#   2. Send submit via SEPARATE call: send-keys -t TARGET C-m (or Enter)
#
# CRITICAL CONSTRAINTS:
#   - CR/Enter MUST be a separate send-keys call (NOT embedded in -l string)
#   - Embedded CR in -l string is treated as literal character, not submission
#   - Sleep between text and submit is OPTIONAL (not required)
#   - This watcher runs EXTERNALLY to Claude Code (required for self-injection)
#
# VALIDATED METHODS (from hypothesis testing):
#   ✅ C-m (key event)           - Works
#   ✅ Enter (key event)         - Works
#   ✅ -l $'\r' (separate call)  - Works (standalone CR)
#   ❌ -l "text"$'\r' (embedded) - FAILS (CR becomes literal)
#   ❌ -l $'\n' (LF)             - FAILS
#   ❌ Escape C-m                - FAILS
#   ❌ C-m C-m (double)          - FAILS
#   ❌ -l $'\r\n' (CRLF)         - FAILS

# Submission method variants - ONLY validated working methods
# Methods are cycled through on retry to handle edge cases
SUBMISSION_METHODS=(
    "C-m"                  # 1: Standard Enter (key event) - PRIMARY
    "Enter"                # 2: tmux Enter key name - ALTERNATE
    "-l_CR"                # 3: Literal CR as separate call - FALLBACK
)

SUBMISSION_PROMPTS=(
    "RESUME"   # A: Full resume prompt with file paths
    "SIMPLE"   # B: Simple continue directive
    "MINIMAL"  # C: Minimal dot (test if any input works)
)
# Note: EMPTY removed - always send at least minimal text to trigger response

SUBMISSION_VARIANT_INDEX=0

# Detect if Jarvis is idle (for idle-hands monitor)
detect_idle_state() {
    local pane_content
    pane_content=$("$TMUX_BIN" capture-pane -t "$TMUX_TARGET" -p 2>/dev/null || echo "")

    # Active indicators = NOT idle
    if echo "$pane_content" | grep -qE '⠋|⠙|⠹|⠸|⠼|⠴|⠦|⠧|⠇|⠏|◐|◓|◑|◒'; then
        return 1  # Spinner visible = working
    fi

    # Prompt visible without recent substantive output = idle
    if echo "$pane_content" | tail -5 | grep -qE '❯\s*$|>\s*$'; then
        # Check for recent response text
        if echo "$pane_content" | tail -10 | grep -qiE 'context restored|already restored|continuing|reading|writing|understood|resuming|ready for|ready when|acknowledged|awaiting'; then
            return 1  # Recent response = not idle
        fi
        return 0  # Idle
    fi

    return 1  # Unknown state, assume not idle
}

# Detect if submission was successful
detect_submission_success() {
    sleep 3  # Give Claude Code time to process

    local pane_content
    pane_content=$("$TMUX_BIN" capture-pane -t "$TMUX_TARGET" -p 2>/dev/null || echo "")

    # Check for spinner (active processing)
    if echo "$pane_content" | grep -qE '⠋|⠙|⠹|⠸|⠼|⠴|⠦|⠧|⠇|⠏|◐|◓|◑|◒'; then
        return 0  # Success - Jarvis is working
    fi

    # Check for response text indicating wake-up
    if echo "$pane_content" | grep -qiE 'context restored|already restored|continuing|reading|writing|understood|resuming|ready for|ready when|acknowledged|awaiting'; then
        return 0  # Success - Jarvis responded
    fi

    return 1  # Not yet successful
}

# =============================================================================
# CRITICAL STATE DETECTION (v5.6.0)
# =============================================================================
# SCOPE: Unplanned emergencies and edge cases where normal hooks have FAILED.
#
# This is the FALLBACK safety net. Normal transitions are handled by:
#   - idle-hands (check_idle_hands): Planned transitions — post-clear resume,
#     session start wake-up. Triggered by flag files from session-start.sh
#     or the JICM compression cycle. Has sophisticated retry/escalation.
#
# Critical-state handles ONLY:
#   1. context_exhausted: Claude Code is locked out — emergency /clear required
#   2. post_clear_unhandled: /clear was sent but NO idle-hands flag exists
#      AND 20+ seconds have elapsed — hooks have failed, emergency restore
#
# Removed in v5.6.0:
#   - fresh_session: Handled by session_start idle-hands mode
#   - interrupted: Disabled since v5.4.2 (causes runaway loop)
#
# Returns: state name string if emergency detected, empty string otherwise
# IMPORTANT: Always returns 0 (bash 3.2 set -e compatibility)

detect_critical_state() {
    local pane_content
    pane_content=$("$TMUX_BIN" capture-pane -t "$TMUX_TARGET" -p 2>/dev/null || echo "")

    if [[ -z "$pane_content" ]]; then
        echo ""
        return 0
    fi

    # EMERGENCY: Context exhausted — Claude Code can't proceed
    # Only check when state is "monitoring" to prevent re-triggering after /clear
    # Restrict to last 8 lines to avoid stale scroll buffer (v5.5.1 fix)
    if [[ "$JICM_STATE" == "monitoring" ]]; then
        if echo "$pane_content" | tail -8 | grep -qE 'Context limit reached|Conversation too long'; then
            echo "context_exhausted"
            return 0
        fi
    fi

    # EDGE CASE: /clear sent but idle-hands NOT active and 20s+ elapsed
    # This catches scenarios where /clear was sent manually or by a failed
    # JICM cycle that didn't create the idle-hands flag. If idle-hands IS
    # active, it handles restoration (skip this check entirely).
    if [[ ! -f "$IDLE_HANDS_FLAG" ]] && [[ "$JICM_STATE" == "cleared" ]]; then
        if echo "$pane_content" | tail -10 | grep -qE '\(no content\)'; then
            echo "post_clear_unhandled"
            return 0
        fi
    fi

    echo ""
    return 0
}

# Handle critical state with appropriate response
handle_critical_state() {
    local state="$1"

    case "$state" in
        context_exhausted)
            log JICM "═══ EMERGENCY: Context exhausted — sending /clear ═══"

            # Save current work state
            if [[ ! -f "$IN_PROGRESS_FILE" ]]; then
                cat > "$IN_PROGRESS_FILE" <<'DUMP'
# Emergency Context Checkpoint

Context exhausted - JICM triggered emergency /clear.
Read .claude/context/session-state.md for prior work context.
DUMP
            fi

            # Invalidate TUI cache and send /clear
            invalidate_tui_cache
            send_command "/clear"
            date +%s > "$CLEAR_SENT_SIGNAL"

            # STATE TRANSITION: Move to "cleared" state
            # This prevents re-triggering context_exhausted on next iteration
            # (the error message may still be visible until TUI refreshes)
            JICM_STATE="cleared"
            JICM_LAST_TRIGGER=$(date +%s)  # For section 4's 60s failsafe
            GRACE_RESUME_UNTIL=$(($(date +%s) + 20))  # Protect cleared state (A4)
            log JICM "State → cleared (awaiting post-clear restoration)"
            ;;

        post_clear_unhandled)
            log JICM "═══ EMERGENCY: Post-clear with no idle-hands recovery ═══"
            log JICM "Normal hooks failed to create idle-hands flag. Emergency restore."
            # Fires when: (a) detect_critical_state finds state==cleared + no idle-hands
            #             (b) section 4 transitions cleared→monitoring without idle-hands
            #
            # v5.8.2 FIX: Use send_text() which includes wait_for_idle_brief()
            # to prevent restore prompt from getting stuck in TUI input.
            # Previously used raw send-keys without idle check.
            local restore_prompt='[JICM-EMERGENCY] Hooks failed. Read .claude/context/.compressed-context-ready.md, .claude/context/.in-progress-ready.md, and .claude/context/session-state.md — resume work immediately. Do NOT greet.'
            send_text "$restore_prompt"
            # Transition back to monitoring — we've done what we can
            JICM_STATE="monitoring"
            GRACE_RESUME_UNTIL=$(($(date +%s) + 20))  # Protect new monitoring state (A4)
            ;;

        *)
            log ERROR "Unknown critical state: $state — ignoring"
            ;;
    esac

    return 0
}

# Send prompt text based on prompt type and mode
# NOTE: Text is sent via -l flag (literal), then submit is sent SEPARATELY
# See: lessons/tmux-self-injection-limitation.md
#
# Args: $1 = prompt_type (RESUME|SIMPLE|MINIMAL), $2 = mode context
# Each mode+type combination has a customized prompt so the user can identify
# which variant triggered, and Jarvis gets specialized instructions.
send_prompt_by_type() {
    local prompt_type="$1"
    local mode="${2:-jicm_resume}"

    # CRITICAL: All prompts MUST be single-line. Multi-line -l strings inject
    # literal newlines into the input buffer, causing premature submission or
    # corrupted commands. See: Section 6.4.1 Submission Pattern Requirements.
    case "${mode}:${prompt_type}" in
        "jicm_resume:RESUME")
            "$TMUX_BIN" send-keys -t "$TMUX_TARGET" -l '[JICM-RESUME] Context compressed and cleared. Read .claude/context/.compressed-context-ready.md, .claude/context/.in-progress-ready.md, and .claude/context/session-state.md — resume work immediately. Do NOT greet.'
            ;;
        "jicm_resume:SIMPLE")
            "$TMUX_BIN" send-keys -t "$TMUX_TARGET" -l '[JICM-RESUME] Read .claude/context/.compressed-context-ready.md and .claude/context/.in-progress-ready.md — continue work.'
            ;;
        "jicm_resume:MINIMAL")
            "$TMUX_BIN" send-keys -t "$TMUX_TARGET" -l '[JICM-RESUME] Continue.'
            ;;
        "session_start:RESUME")
            "$TMUX_BIN" send-keys -t "$TMUX_TARGET" -l '[SESSION-START] New session. Begin AC-01. Read .claude/context/session-state.md and .claude/context/current-priorities.md — assess state, decide next action, begin work. Do NOT just greet.'
            ;;
        "session_start:SIMPLE")
            "$TMUX_BIN" send-keys -t "$TMUX_TARGET" -l '[SESSION-START] Read session-state.md and begin work.'
            ;;
        "session_start:MINIMAL")
            "$TMUX_BIN" send-keys -t "$TMUX_TARGET" -l 'startSession'
            ;;
        *)
            # Fallback for any unrecognized combination
            "$TMUX_BIN" send-keys -t "$TMUX_TARGET" -l "[${mode^^}] Resume work. Read .claude/context/session-state.md and continue."
            ;;
    esac
}

# Apply submission method (validated patterns only)
# See: lessons/tmux-self-injection-limitation.md for why only these methods work
apply_submission_method() {
    local method_index="$1"
    local method="${SUBMISSION_METHODS[$method_index]}"

    log JICM "  Applying submission method $((method_index + 1)): $method"

    case $method_index in
        0) # C-m - Primary method (key event)
            "$TMUX_BIN" send-keys -t "$TMUX_TARGET" C-m
            ;;
        1) # Enter - Alternate method (key event)
            "$TMUX_BIN" send-keys -t "$TMUX_TARGET" Enter
            ;;
        2) # Literal CR as SEPARATE call - Fallback
            # NOTE: This works because CR is sent as its own send-keys call,
            # NOT embedded in the same -l string as the prompt text
            "$TMUX_BIN" send-keys -t "$TMUX_TARGET" -l $'\r'
            ;;
        *)
            # Default to C-m if index is out of range
            log WARN "Unknown submission method index: $method_index, using C-m"
            "$TMUX_BIN" send-keys -t "$TMUX_TARGET" C-m
            ;;
    esac
}

# Submit with current variant
# Cycles through combinations of: 3 methods × 3 prompts = 9 variants
# On retry, tries different combinations to find what works
# Args: $1 = mode context (jicm_resume|session_start)
submit_with_variant() {
    local mode="${1:-jicm_resume}"
    local variant=$SUBMISSION_VARIANT_INDEX
    local method_idx=$((variant % ${#SUBMISSION_METHODS[@]}))
    local prompt_idx=$((variant / ${#SUBMISSION_METHODS[@]} % ${#SUBMISSION_PROMPTS[@]}))
    local prompt_type="${SUBMISSION_PROMPTS[$prompt_idx]}"

    log JICM "Attempting submission variant $variant: mode=$mode method=$((method_idx + 1))/${#SUBMISSION_METHODS[@]} prompt=$prompt_type"

    # CANONICAL PATTERN: Send text first, then submit as SEPARATE call
    # This is validated to work; embedded CR in text fails
    send_prompt_by_type "$prompt_type" "$mode"
    sleep 0.1  # Brief pause (optional but safe)

    # Apply submission method (separate send-keys call)
    apply_submission_method "$method_idx"

    # Advance to next variant for next attempt
    SUBMISSION_VARIANT_INDEX=$(( (SUBMISSION_VARIANT_INDEX + 1) % (${#SUBMISSION_METHODS[@]} * ${#SUBMISSION_PROMPTS[@]}) ))
}

# Update idle-hands flag file
update_idle_hands_flag() {
    local attempts="$1"
    local timestamp
    timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)

    if [[ -f "$IDLE_HANDS_FLAG" ]]; then
        # Update attempt count (simple sed replacement)
        sed -i '' "s/^submission_attempts:.*/submission_attempts: $attempts/" "$IDLE_HANDS_FLAG" 2>/dev/null || true
        sed -i '' "s/^last_attempt:.*/last_attempt: $timestamp/" "$IDLE_HANDS_FLAG" 2>/dev/null || true
    fi
}

# Mark idle-hands as successful
mark_idle_hands_success() {
    if [[ -f "$IDLE_HANDS_FLAG" ]]; then
        sed -i '' "s/^success:.*/success: true/" "$IDLE_HANDS_FLAG" 2>/dev/null || true
    fi
}

# Clean up all JICM files after confirmed resume
cleanup_jicm_files() {
    log JICM "Cleaning up JICM files after confirmed resume"

    # B.4: Archive context files instead of deleting (datetime-stamped)
    local archive_dir="$PROJECT_DIR/.claude/logs/jicm/archive"
    local ts
    ts=$(date +%Y%m%d-%H%M%S)
    mkdir -p "$archive_dir"

    # Archive context files (valuable for debugging and history)
    if [[ -f "$COMPRESSED_CONTEXT_FILE" ]]; then
        mv "$COMPRESSED_CONTEXT_FILE" "$archive_dir/compressed-context-${ts}.md" 2>/dev/null || rm -f "$COMPRESSED_CONTEXT_FILE"
    fi
    if [[ -f "$IN_PROGRESS_FILE" ]]; then
        mv "$IN_PROGRESS_FILE" "$archive_dir/in-progress-${ts}.md" 2>/dev/null || rm -f "$IN_PROGRESS_FILE"
    fi

    # Prune old archives (keep last 20)
    local archive_count
    archive_count=$(ls -1 "$archive_dir" 2>/dev/null | wc -l | tr -d ' ')
    if [[ "$archive_count" -gt 20 ]]; then
        ls -1t "$archive_dir" | tail -n +21 | while read -r old_file; do
            rm -f "$archive_dir/$old_file"
        done
        log JICM "Pruned JICM archive (kept 20, removed $((archive_count - 20)))"
    fi

    # Delete signal files (ephemeral, no archive needed)
    rm -f "$COMPRESSION_DONE_SIGNAL"
    rm -f "$DUMP_REQUESTED_SIGNAL"
    rm -f "$CLEAR_SENT_SIGNAL"
    rm -f "$CONTINUATION_INJECTED_SIGNAL"

    # Delete idle-hands flag
    rm -f "$IDLE_HANDS_FLAG"

    # Delete stale compression flag
    rm -f "$COMPRESSION_IN_PROGRESS"

    # Mark JICM complete
    date -u +%Y-%m-%dT%H:%M:%SZ > "$JICM_COMPLETE_SIGNAL"

    log JICM "JICM files cleaned up (context archived to $archive_dir)"
}

# Main idle-hands jicm_resume mode handler
# Implements escalating retry strategy with method/prompt variations
#
# Strategy:
#   - Cycles through 9 variants (3 methods × 3 prompts)
#   - Each cycle waits 12 seconds before retry
#   - Methods: C-m (primary), Enter (alternate), literal CR (fallback)
#   - Prompts: RESUME (full), SIMPLE (directive), MINIMAL (dot)
#   - Total ~10 minutes before giving up
#
# All variants use the CANONICAL PATTERN:
#   1. send-keys -l "text"   (prompt text)
#   2. send-keys C-m         (submit as separate call)
#
idle_hands_jicm_resume() {
    local max_cycles=20       # ~4 minutes of attempts (20 * 12s), then emergency restore (B6)
    local cycle_delay=12      # Seconds between attempts
    local cycle=0

    log JICM "═══ IDLE-HANDS: jicm_resume mode active ═══"
    log JICM "Using validated submission patterns (see lessons/tmux-self-injection-limitation.md)"

    while [[ $cycle -lt $max_cycles ]]; do
        # Check if flag still exists (might be cleaned up externally)
        if [[ ! -f "$IDLE_HANDS_FLAG" ]]; then
            log JICM "IDLE-HANDS: Flag removed externally, stopping"
            return 0
        fi

        # Check if already marked successful
        if grep -q "success: true" "$IDLE_HANDS_FLAG" 2>/dev/null; then
            log JICM "IDLE-HANDS: Already marked successful"
            cleanup_jicm_files
            return 0
        fi

        # Check idle state
        if detect_idle_state; then
            log JICM "IDLE-HANDS: Jarvis idle, attempting submission (cycle $cycle)"

            # Update attempt count
            update_idle_hands_flag "$cycle"

            # Try submission with jicm_resume mode prompts
            submit_with_variant "jicm_resume"

            # Check if it worked
            if detect_submission_success; then
                log JICM "IDLE-HANDS: SUCCESS - Jarvis is awake!"
                mark_idle_hands_success
                cleanup_jicm_files
                return 0
            fi
        else
            log JICM "IDLE-HANDS: Jarvis appears active, checking..."
            if detect_submission_success; then
                log JICM "IDLE-HANDS: Confirmed active"
                mark_idle_hands_success
                cleanup_jicm_files
                return 0
            fi
        fi

        cycle=$((cycle + 1))
        sleep $cycle_delay
    done

    log WARN "IDLE-HANDS: Max cycles reached — firing emergency restore as last resort"
    # Fire emergency restore directly (bypass variant system which already exhausted)
    handle_critical_state "post_clear_unhandled"
    rm -f "$IDLE_HANDS_FLAG"
    return 0
}

# =============================================================================
# IDLE-HANDS: session_start mode
# =============================================================================
# Automatically wakes Jarvis after a fresh session start (startup/resume).
# The session-start hook injects context via additionalContext, but that only
# gets delivered WITH the next user message. This mode auto-injects a wake-up
# prompt so Jarvis starts working without user intervention.
#
# Trigger: .idle-hands-active flag with mode: session_start
# Created by: session-start.sh hook on startup/resume
#
# Detection strategy:
#   1. Wait for TUI to be ready (prompt visible, not processing)
#   2. Give a brief settling delay (3-5 seconds after session start)
#   3. Send minimal wake-up prompt and submit
#   4. Verify Jarvis responds
#
idle_hands_session_start() {
    local max_cycles=20       # ~2 minutes of attempts (20 * 6s)
    local cycle_delay=6       # Shorter interval for session start
    local initial_delay=5     # Wait for TUI to fully initialize
    local cycle=0

    log JICM "═══ IDLE-HANDS: session_start mode active ═══"

    # Initial delay to let TUI settle after startup
    log JICM "Waiting ${initial_delay}s for TUI to initialize..."
    sleep $initial_delay

    while [[ $cycle -lt $max_cycles ]]; do
        # Check if flag still exists
        if [[ ! -f "$IDLE_HANDS_FLAG" ]]; then
            log JICM "IDLE-HANDS: Flag removed externally, stopping"
            return 0
        fi

        # Check if already marked successful
        if grep -q "success: true" "$IDLE_HANDS_FLAG" 2>/dev/null; then
            log JICM "IDLE-HANDS: Already marked successful"
            rm -f "$IDLE_HANDS_FLAG"
            return 0
        fi

        # Check idle state - for session start, we just need prompt visible
        if detect_idle_state; then
            log JICM "IDLE-HANDS: Session idle, sending wake-up (cycle $cycle)"

            # Update attempt count
            update_idle_hands_flag "$cycle"

            # Send session-start wake-up using variant system
            submit_with_variant "session_start"

            # Check if it worked (give more time for session start response)
            sleep 5
            if detect_submission_success; then
                log JICM "IDLE-HANDS: SUCCESS - Jarvis is awake!"
                mark_idle_hands_success
                rm -f "$IDLE_HANDS_FLAG"
                return 0
            fi
        else
            log JICM "IDLE-HANDS: Session appears active, checking..."
            if detect_submission_success; then
                log JICM "IDLE-HANDS: Confirmed active"
                mark_idle_hands_success
                rm -f "$IDLE_HANDS_FLAG"
                return 0
            fi
        fi

        cycle=$((cycle + 1))
        sleep $cycle_delay
    done

    log WARN "IDLE-HANDS: session_start max cycles reached — sending final wake-up"
    # Send a direct session-start prompt as last resort
    send_prompt_by_type "RESUME" "session_start"
    sleep 0.1
    "$TMUX_BIN" send-keys -t "$TMUX_TARGET" C-m 2>/dev/null || true
    rm -f "$IDLE_HANDS_FLAG"
    return 0
}

# Check for and handle idle-hands flag
check_idle_hands() {
    if [[ ! -f "$IDLE_HANDS_FLAG" ]]; then
        return 1  # No flag, idle-hands not active
    fi

    local mode
    mode=$(grep "^mode:" "$IDLE_HANDS_FLAG" 2>/dev/null | cut -d: -f2 | tr -d ' ')

    case "$mode" in
        jicm_resume)
            idle_hands_jicm_resume
            return $?
            ;;
        session_start)
            # AC-01 session_start runs for ALL session types (including --continue).
            # The hook injects context (Mechanism 1) but Jarvis won't respond without
            # idle-hands keystroke injection (Mechanism 2). Previous sessions provide
            # context via session-state.md which AC-01 reads during briefing.
            idle_hands_session_start
            return $?
            ;;
        long_idle|workflow_chain)
            log INFO "IDLE-HANDS: '$mode' mode not yet implemented — removing flag"
            rm -f "$IDLE_HANDS_FLAG"
            ;;
        *)
            log WARN "IDLE-HANDS: Unknown mode '$mode' — removing flag to prevent loop"
            rm -f "$IDLE_HANDS_FLAG"
            ;;
    esac

    return 0  # Must return 0 for bash 3.2 set -e safety (CRIT-01 fix)
}

# trigger_fallback_compact() removed (C2) — dead v4 state, never reached in v5
# Emergency /compact is now handled by D1 mechanic (separate from compression flow)

# check_compression_complete() removed (C3) — section 1.5 checks signal directly

# =============================================================================
# MAIN LOOP
# =============================================================================

banner() {
    echo -e "${CYAN}━━━ JARVIS WATCHER v5.8.4 ━━━${NC} threshold:${JICM_THRESHOLD}% interval:${INTERVAL}s session:${SESSION_TYPE}"
    echo -e "${GREEN}●${NC} Context ${GREEN}●${NC} JICM v5.8.4 ${GREEN}●${NC} Idle-Hands Monitor │ Ctrl+C to stop"
    echo ""
}

# Track which signal caused shutdown (for debugging)
SHUTDOWN_SIGNAL=""

cleanup_with_signal() {
    local signal="$1"
    SHUTDOWN_SIGNAL="$signal"
    echo ""
    log INFO "Watcher shutting down (signal: $signal)"
    rm -f "$STATUS_FILE"
    rm -f "$PID_FILE"
    exit 0
}

cleanup() {
    cleanup_with_signal "unknown"
}

trap 'cleanup_with_signal INT' INT
trap 'cleanup_with_signal TERM' TERM
trap 'cleanup_with_signal HUP' HUP
trap 'log INFO "Watcher exiting (signal: $SHUTDOWN_SIGNAL)" 2>/dev/null || true' EXIT

main() {
    banner

    if ! "$TMUX_BIN" has-session -t "$TMUX_SESSION" 2>/dev/null; then
        log ERROR "tmux session '$TMUX_SESSION' not found"
        echo "Start Jarvis with: .claude/scripts/launch-jarvis-tmux.sh"
        exit 1
    fi

    log INFO "Watcher started (JICM v5.8.4, threshold=${JICM_THRESHOLD}%, emergency=${EMERGENCY_COMPACT_PCT}%, lockout=~${LOCKOUT_PCT}%)"

    # Write JICM config for statusline to read (dynamic threshold marker)
    write_jicm_config

    local last_tokens=0
    local poll_count=0
    local compression_wait_start=0
    local consecutive_inconsistencies=0  # Track stale data retries (v5.4.0)

    while true; do
        # ─────────────────────────────────────────────────────────────
        # 0. Check for standdown mode
        # ─────────────────────────────────────────────────────────────
        if check_standdown; then
            sleep "$INTERVAL"
            continue
        fi

        # ─────────────────────────────────────────────────────────────
        # 1. Check for command signals
        # ─────────────────────────────────────────────────────────────
        if process_signal_file; then
            sleep 1
        fi

        # ─────────────────────────────────────────────────────────────
        # 1.1 IDLE-HANDS: Planned transitions (flag-file triggered)
        # ─────────────────────────────────────────────────────────────
        # Handles: post-clear resume (jicm_resume), session start wake-up
        # (session_start). Has sophisticated retry/escalation logic.
        #
        # BLOCKS the main loop (up to ~4 min for jicm_resume, ~2 min for
        # session_start). This is acceptable because:
        #   - jicm_resume: context just cleared (~2-5%), no monitoring needed
        #   - session_start: context at 0%, no monitoring needed
        # Escape hatches: flag removal, success detection, max cycles → emergency restore (B4)
        if [[ -f "$IDLE_HANDS_FLAG" ]]; then
            check_idle_hands
            # After handling, continue to next iteration
            sleep 2
            continue
        fi

        # ─────────────────────────────────────────────────────────────
        # 1.2 CRITICAL STATE: Unplanned emergencies (TUI pattern detection)
        # ─────────────────────────────────────────────────────────────
        # FALLBACK safety net for when normal hooks have FAILED.
        # Handles ONLY:
        #   - context_exhausted: Claude Code lockout → emergency /clear
        #   - post_clear_unhandled: /clear sent but hooks didn't create
        #     idle-hands flag → emergency restore
        #
        # Skip during grace period to avoid false positives.
        # Grace period is active during:
        #   1. Startup: first 4 iterations (~20s)
        #   2. Post-clear: GRACE_RESUME_UNTIL timestamp (20s after clear)
        # This prevents false positives from stale TUI content after clear/restart.
        poll_count=$((poll_count + 1))
        local now_ts
        now_ts=$(date +%s)
        local grace_active=false
        if [[ $poll_count -le 4 ]] || [[ $now_ts -lt $GRACE_RESUME_UNTIL ]]; then
            grace_active=true
        fi
        if [[ "$grace_active" == "false" ]]; then
            local critical_state
            critical_state=$(detect_critical_state)
            if [[ -n "$critical_state" ]]; then
                log JICM "Critical state detected: $critical_state"
                if handle_critical_state "$critical_state"; then
                    # Give Jarvis time to process, then continue monitoring
                    sleep 5
                    continue
                fi
            fi
        fi

        # ─────────────────────────────────────────────────────────────
        # 1.5 Compression completion → send /clear
        # ─────────────────────────────────────────────────────────────
        # SUCCESS PATH for the JICM compression cycle:
        #   Section 5 (trigger) → /intelligent-compress → compression
        #   agent runs → agent writes .compression-done.signal →
        #   THIS SECTION detects signal → sends /clear → state="cleared"
        #   → Section 6 handles cleared→monitoring (pct < 30% event)
        #
        # Handles BOTH:
        #   - Watcher-triggered: section 3 set state=compression_triggered
        #   - User-triggered: user ran /intelligent-compress (state=monitoring)
        # In both cases, the compression agent creates .compression-done.signal
        #
        # NOTE: No trigger_limit check here — we're processing a COMPLETION,
        # not initiating a trigger. Section 5 already counted the trigger.
        if [[ -f "$COMPRESSION_DONE_SIGNAL" ]] && [[ "$JICM_STATE" == "monitoring" || "$JICM_STATE" == "compression_triggered" ]]; then
            local was_watcher_triggered="false"
            if [[ "$JICM_STATE" == "compression_triggered" ]]; then
                was_watcher_triggered="true"
            fi

            log JICM "Detected compression completion signal (state: $JICM_STATE)"
            rm -f "$COMPRESSION_DONE_SIGNAL"

            # Check if /clear was already sent recently (avoid duplicate)
            if [[ -f "$CLEAR_SENT_SIGNAL" ]]; then
                local clear_epoch
                clear_epoch=$(cat "$CLEAR_SENT_SIGNAL" 2>/dev/null)
                if [[ -n "$clear_epoch" ]] && [[ "$clear_epoch" =~ ^[0-9]+$ ]]; then
                    local now_epoch
                    now_epoch=$(date +%s)
                    local clear_age=$((now_epoch - clear_epoch))
                    if [[ $clear_age -lt 60 ]]; then
                        log JICM "Skipping /clear — already sent ${clear_age}s ago"
                        JICM_STATE="monitoring"
                        reset_failure_count
                        log JICM "Compression cycle complete (no-op, /clear already sent)"
                        continue
                    fi
                fi
            fi

            # ── .in-progress-ready.md gating (Item C) ──────────────────
            # Before /clear, check if Jarvis already wrote a work summary.
            # If recent file exists, skip the dump request entirely.
            # Otherwise, ask via send_text (which includes idle-wait).
            #
            # v5.8.2 FIX: Previously used raw send-keys without idle check,
            # causing prompt text to get stuck in TUI input during generation.
            # Also previously deleted existing file unconditionally.
            local ipr_skip=false
            if [[ -f "$IN_PROGRESS_FILE" ]]; then
                # Check file age — if written in last 120s, it's current
                local ipr_mtime
                ipr_mtime=$(stat -f %m "$IN_PROGRESS_FILE" 2>/dev/null || echo "0")
                local ipr_now
                ipr_now=$(date +%s)
                local ipr_age=$((ipr_now - ipr_mtime))
                if [[ $ipr_age -lt 120 ]]; then
                    log JICM "Got recent .in-progress-ready.md (${ipr_age}s old) — skipping dump request"
                    ipr_skip=true
                else
                    log JICM "Stale .in-progress-ready.md (${ipr_age}s old) — requesting fresh dump"
                    rm -f "$IN_PROGRESS_FILE"
                fi
            fi

            if [[ "$ipr_skip" == "false" ]]; then
                local ipr_prompt='[JICM-DUMP] Write your current work state to .claude/context/.in-progress-ready.md — include: current task, files modified, decisions made, active todos, blockers, next steps. Keep under 2000 tokens. Write the file immediately, no other output.'
                log JICM "Requesting .in-progress-ready.md from Jarvis"
                # v5.8.2: Use send_text() which includes wait_for_idle_brief()
                # to prevent prompt getting stuck in TUI input during generation
                send_text "$ipr_prompt"

                # Poll for .in-progress-ready.md (2s interval, 45s timeout)
                local ipr_wait=0
                local ipr_max=45
                while [[ $ipr_wait -lt $ipr_max ]]; do
                    if [[ -f "$IN_PROGRESS_FILE" ]]; then
                        log JICM "Got .in-progress-ready.md (${ipr_wait}s wait)"
                        break
                    fi
                    sleep 2
                    ipr_wait=$((ipr_wait + 2))
                done
                if [[ ! -f "$IN_PROGRESS_FILE" ]]; then
                    log JICM "WARN: .in-progress-ready.md not received after ${ipr_max}s — proceeding with /clear anyway"
                fi
            fi
            # ── end .in-progress-ready.md gating ─────────────────────────

            # B.4: Export chat history before /clear for failsafe context preservation
            export_chat_history "pre-clear"

            # Send /clear (compressed context is ready for post-clear hook to inject)
            if [[ "$was_watcher_triggered" == "true" ]]; then
                log JICM "═══ COMPRESSION SUCCESS: Sending /clear (watcher-triggered) ═══"
            else
                log JICM "═══ COMPRESSION SUCCESS: Sending /clear (user-triggered) ═══"
            fi

            send_command "/clear"
            date +%s > "$CLEAR_SENT_SIGNAL"
            invalidate_tui_cache

            # Transition to "cleared" — section 4 handles cleared→monitoring
            # via event detection (pct < 30%), not a hardcoded sleep
            JICM_STATE="cleared"
            JICM_LAST_TRIGGER=$(date +%s)  # Reset for section 4's failsafe
            CLEAR_RETRY_COUNT=0            # B.4: Reset retry counter for fresh tracking
            GRACE_RESUME_UNTIL=$(($(date +%s) + 20))  # Post-clear grace (A2)
            reset_failure_count
            log JICM "State → cleared (section 4 handles transition to monitoring)"
            continue
        fi

        # Sections 2 & 3 removed (C4) — v4 compression_spawned/dump_requested flow
        # v5 flow: section 3 → /intelligent-compress → section 1.5 → /clear → section 4

        # ─────────────────────────────────────────────────────────────
        # 2. Context monitoring
        # ─────────────────────────────────────────────────────────────
        local pct
        pct=$(get_used_percentage)

        if [[ "$pct" == "0" ]] || [[ -z "$pct" ]]; then
            # poll_count already incremented in section 1.2 — no duplicate here
            if [[ $((poll_count % 6)) -eq 0 ]]; then
                echo -e "$(date +%H:%M:%S) ${YELLOW}·${NC} Waiting for context data..."
            fi
            sleep "$INTERVAL"
            continue
        fi

        local tokens
        tokens=$(get_token_count)
        local pct_int
        pct_int=$(echo "$pct" | cut -d'.' -f1)

        # Sanity check for stale data (e.g., after /clear)
        if ! check_data_consistency "$tokens" "$pct_int"; then
            consecutive_inconsistencies=$((consecutive_inconsistencies + 1))

            if [[ $consecutive_inconsistencies -lt 3 ]]; then
                # Re-fetch with fresh data (up to 3 retries)
                sleep 2
                pct=$(get_used_percentage)
                tokens=$(get_token_count)
                pct_int=$(echo "$pct" | cut -d'.' -f1)
            else
                # After 3 consecutive inconsistencies, use percentage-based estimate
                log WARN "Persistent data inconsistency ($consecutive_inconsistencies in a row) - using percentage estimate"
                tokens=$(get_tokens_from_percentage "$pct_int" "$MAX_CONTEXT_TOKENS")
            fi
        else
            # Data is consistent, reset counter
            consecutive_inconsistencies=0
        fi

        update_status "$tokens" "$pct" "$JICM_STATE"

        # Read token method from temp file for debug output
        local token_method="unknown"
        if [[ -f /tmp/jicm-token-method.$$ ]]; then
            token_method=$(cat /tmp/jicm-token-method.$$)
        fi

        # Display status - show on change OR every 6 iterations (heartbeat)
        local display_heartbeat=false
        if [[ $((poll_count % 6)) -eq 0 ]]; then
            display_heartbeat=true
        fi

        if [[ "$tokens" != "$last_tokens" ]] || [[ "$display_heartbeat" == "true" ]]; then
            local color="$GREEN"
            local symbol="●"

            if [[ $pct_int -ge $JICM_THRESHOLD ]]; then
                color="$YELLOW"
                symbol="◐"
            fi
            if [[ $pct_int -ge 80 ]]; then
                color="$RED"
                symbol="⚠"
            fi

            # Add heartbeat indicator if showing due to heartbeat
            local heartbeat_marker=""
            if [[ "$tokens" == "$last_tokens" ]] && [[ "$display_heartbeat" == "true" ]]; then
                heartbeat_marker=" ♡"
            fi

            echo -e "$(date +%H:%M:%S) ${color}${symbol}${NC} ${tokens} tokens (${pct}%) [$JICM_STATE]${heartbeat_marker}"
            last_tokens=$tokens
        fi

        # ─────────────────────────────────────────────────────────────
        # 2.5 Emergency /compact — last resort before lockout (D1)
        # ─────────────────────────────────────────────────────────────
        # Fires at EMERGENCY_COMPACT_PCT (5% below lockout ceiling).
        # This is separate from JICM compression — it's a raw /compact
        # to prevent total lockout when compression is slow or fails.
        # Only fires once; resets when context drops below threshold.
        if [[ $pct_int -ge $EMERGENCY_COMPACT_PCT ]] && \
           [[ "$JICM_STATE" != "cleared" ]] && \
           [[ "$EMERGENCY_COMPACT_SENT" == "false" ]]; then
            # B.4 FIX: Allow emergency /compact during compression_triggered if stuck > 180s.
            # Previously, the check `state != compression_triggered` blocked the safety net
            # during stuck compression, allowing context to grow to lockout.
            local allow_emergency=false
            if [[ "$JICM_STATE" != "compression_triggered" ]]; then
                allow_emergency=true
            elif [[ $(($(date +%s) - JICM_LAST_TRIGGER)) -gt 180 ]]; then
                log JICM "Compression stuck for 180s+ at emergency level — overriding state guard"
                allow_emergency=true
            fi
            if [[ "$allow_emergency" == "true" ]]; then
                log JICM "═══ EMERGENCY /compact at ${pct_int}% (lockout at ~${LOCKOUT_PCT}%) ═══"
                send_command "/compact"
                EMERGENCY_COMPACT_SENT=true
            fi
        fi

        # Reset emergency compact flag when context drops below trigger
        if [[ $pct_int -lt $EMERGENCY_COMPACT_PCT ]] && [[ "$EMERGENCY_COMPACT_SENT" == "true" ]]; then
            EMERGENCY_COMPACT_SENT=false
        fi

        # ─────────────────────────────────────────────────────────────
        # 3. Threshold check → trigger compression (JICM v5)
        # ─────────────────────────────────────────────────────────────
        # TRIGGER POINT for the JICM compression cycle.
        # Natural debounce: if compression works, context drops below
        # threshold and won't re-trigger until it grows back.
        #
        # SUCCESS PATH continues in section 1.5:
        #   /intelligent-compress → compression agent runs →
        #   .compression-done.signal → section 1.5 sends /clear →
        #   state="cleared" → section 4 event: pct<30% → monitoring
        if [[ "$JICM_STATE" == "monitoring" ]]; then
            if [[ $pct_int -ge $JICM_THRESHOLD ]]; then
                # B.4 FIX: Check cooldown before triggering — prevents infinite
                # trigger→timeout→monitoring→trigger loop after failsafe fires.
                local now_s
                now_s=$(date +%s)
                if [[ $now_s -lt $COOLDOWN_UNTIL ]]; then
                    # Suppress trigger during cooldown (log every ~60s)
                    if [[ $((poll_count % 12)) -eq 0 ]]; then
                        local remaining=$((COOLDOWN_UNTIL - now_s))
                        log JICM "Cooldown active: ${remaining}s remaining (trigger suppressed at ${pct_int}%)"
                    fi
                else
                    TRIGGER_COUNT=$((TRIGGER_COUNT + 1))
                    log JICM "═══ JICM v5: Context at ${pct}% — triggering compression (#${TRIGGER_COUNT}) ═══"
                    # B.4: Export chat history before compression for context preservation
                    export_chat_history "pre-compress"
                    send_command "/intelligent-compress"
                    JICM_STATE="compression_triggered"
                    JICM_LAST_TRIGGER=$(date +%s)
                fi
            fi
        fi

        # ─────────────────────────────────────────────────────────────
        # 4. State transitions (event-driven, Swiss watch precision)
        # ─────────────────────────────────────────────────────────────
        # Each state transitions based on observable EVENTS, not timers.
        # Timeouts exist only as absolute last-resort failsafes.

        if [[ "$JICM_STATE" == "compression_triggered" ]]; then
            # EVENT: compression signal detected → handled in section 1.5
            # (section 1.5 transitions to cleared/monitoring)
            #
            # FAILSAFE ONLY: If /intelligent-compress completely failed and
            # no signal appeared after 300s, reset to monitoring
            local now
            now=$(date +%s)
            local elapsed=$((now - JICM_LAST_TRIGGER))
            if [[ $elapsed -gt $DEBOUNCE_SECONDS ]]; then
                log ERROR "compression_triggered: ${DEBOUNCE_SECONDS}s failsafe timeout. Compression may have failed."
                cleanup_jicm_signals_only
                # B.4 FIX: Record failure (triggers standdown after 3 consecutive)
                record_failure
                JICM_STATE="monitoring"
                # B.4 FIX: Set cooldown to prevent immediate re-trigger loop.
                # Without this, section 3 immediately re-triggers because pct is
                # still above threshold → creates infinite trigger→timeout→trigger cycle.
                COOLDOWN_UNTIL=$((now + 600))  # 10 min cooldown
                log JICM "Cooldown set for 600s to prevent re-trigger loop"
                # Fire emergency /compact as recovery attempt
                if [[ "$EMERGENCY_COMPACT_SENT" == "false" ]]; then
                    log JICM "Firing emergency /compact as failsafe recovery"
                    send_command "/compact"
                    EMERGENCY_COMPACT_SENT=true
                fi
            fi
        fi

        if [[ "$JICM_STATE" == "cleared" ]]; then
            # EVENT: Context has dropped (clear succeeded) → return to monitoring
            # This is the precise gear: we KNOW /clear worked when pct drops
            if [[ $pct_int -lt 30 ]]; then
                log JICM "State: cleared → monitoring (context at ${pct_int}%, clear confirmed)"
                cleanup_jicm_signals_only
                JICM_STATE="monitoring"
                # Re-engage grace period for post-clear stability
                GRACE_RESUME_UNTIL=$(($(date +%s) + 20))

                # B2 FIX: If idle-hands flag was never created (hooks failed),
                # fire emergency restore NOW. Without this, post_clear_unhandled
                # can never fire because it requires state==cleared, but we just
                # transitioned to monitoring.
                #
                # v5.8.2 FIX: Also check for JICM_COMPLETE_SIGNAL which is
                # written by cleanup_jicm_files() when idle-hands succeeds.
                # Previously, idle-hands would clean up the flag, then this
                # check would see "no flag" and fire emergency restore even
                # though idle-hands already handled the resume successfully.
                if [[ ! -f "$IDLE_HANDS_FLAG" ]] && [[ ! -f "$JICM_COMPLETE_SIGNAL" ]]; then
                    log JICM "No idle-hands flag after clear — hooks may have failed. Emergency restore."
                    handle_critical_state "post_clear_unhandled"
                elif [[ -f "$JICM_COMPLETE_SIGNAL" ]]; then
                    log JICM "Idle-hands already completed (JICM complete signal present) — no emergency needed."
                    rm -f "$JICM_COMPLETE_SIGNAL"
                fi
            else
                # FAILSAFE: If /clear didn't reduce context after timeout.
                # B.4 FIX: Extended from 60s to 120s, added retry before giving up.
                # Previously, immediate reset to monitoring caused section 3 to re-trigger
                # compression, creating a cascade when /clear was lost by TUI.
                local now
                now=$(date +%s)
                local elapsed=$((now - JICM_LAST_TRIGGER))
                if [[ $elapsed -gt 120 ]]; then
                    if [[ $CLEAR_RETRY_COUNT -lt 1 ]]; then
                        log WARN "cleared: 120s without context drop. Retrying /clear (attempt 2)"
                        send_command "/clear"
                        date +%s > "$CLEAR_SENT_SIGNAL"
                        invalidate_tui_cache
                        JICM_LAST_TRIGGER=$(date +%s)
                        CLEAR_RETRY_COUNT=$((CLEAR_RETRY_COUNT + 1))
                    else
                        log ERROR "cleared: /clear retry failed after ${CLEAR_RETRY_COUNT} retries. Recording failure."
                        record_failure
                        CLEAR_RETRY_COUNT=0
                        JICM_STATE="monitoring"
                        COOLDOWN_UNTIL=$(($(date +%s) + 300))  # 5 min cooldown
                        log JICM "Cooldown set for 300s after failed /clear"
                    fi
                fi
            fi
        fi

        # poll_count already incremented at start of loop (line ~1462) - no duplicate here
        sleep "$INTERVAL"
    done
}

# Run main
main
