#!/bin/bash
# ============================================================================
# JARVIS UNIFIED WATCHER — JICM v5.4.2
# ============================================================================
# Implements the JICM v5 Two-Mechanism Resume architecture.
#
# Features:
#   1. Context monitoring via statusline JSON API (authoritative)
#   2. Single 50% threshold for compression trigger
#   3. Parallel compression agent spawning
#   4. Two-layer executor: interrupt→dump→clear sequence
#   5. Idle-hands monitor (Mechanism 2) with submission variants
#   6. Command signal execution
#   7. Circuit breakers and safeguards
#   8. TUI cache invalidation after /clear (v5.2.0)
#   9. Data consistency checks for stale cache detection (v5.2.0)
#  10. Critical state detection (v5.3.0 - JICM v6 prep)
#
# Design: .claude/context/designs/jicm-v5-design-addendum.md
#
# Changelog v5.4.2 (2026-02-05):
#   - DISABLED "interrupted" state handler - caused runaway prompt loop
#   - When watcher sends prompt, it interrupts Claude, which triggers "interrupted"
#     detection, which sends another prompt, creating infinite loop
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
#   - Added handle_critical_state() with responses for:
#     * post_clear_restore: "(no content)" after /clear
#     * fresh_session: "0 tokens" state
#     * interrupted: "Interrupted · What should Claude do" state
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

# Debug: trap ERR to show where script fails
trap 'echo "[DEBUG] Script failed at line $LINENO (exit code: $?)" >&2' ERR

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
PRE_CLEAR_TOKENS_FILE="$PROJECT_DIR/.claude/context/.pre-clear-tokens"
JICM_CONFIG_FILE="$PROJECT_DIR/.claude/context/.jicm-config"

# Thresholds (JICM v5)
# Single threshold for compression trigger (dynamically configurable)
# See: jicm-v5-design-addendum.md Section 2.2
JICM_THRESHOLD=${JICM_THRESHOLD:-80}
RESERVED_OUTPUT_TOKENS=${RESERVED_OUTPUT_TOKENS:-15000}
DEFAULT_INTERVAL=5

# Timeouts
AGENT_TIMEOUT=180        # 3 min for compression agent
DUMP_TIMEOUT=30          # 30s for Jarvis to dump state
CONTINUATION_DELAY_1=5   # First cascade check
CONTINUATION_DELAY_2=10  # Second cascade check
CONTINUATION_DELAY_3=15  # Final enforcement

# Circuit Breakers
DEBOUNCE_SECONDS=300     # 5 min between JICM triggers
MAX_TRIGGERS=5           # Max triggers per session
FAILURES_BEFORE_STANDDOWN=3

# Context window
MAX_CONTEXT_TOKENS=200000

# Parse arguments
INTERVAL=$DEFAULT_INTERVAL
while [[ $# -gt 0 ]]; do
    case $1 in
        --threshold) JICM_THRESHOLD="$2"; shift 2 ;;
        --interval) INTERVAL="$2"; shift 2 ;;
        -h|--help)
            echo "JARVIS WATCHER v5.4.0 — JICM Two-Mechanism Resume"
            echo ""
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  --threshold PCT   Compression trigger (default: $JICM_THRESHOLD)"
            echo "  --interval SEC    Poll interval (default: $DEFAULT_INTERVAL)"
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
echo $$ > "$PID_FILE"

# State tracking
JICM_STATE="monitoring"
JICM_LAST_TRIGGER=0
TRIGGER_COUNT=0
FAILURE_COUNT=0

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
        return 1
    fi

    CACHED_PANE_CONTENT=$("$TMUX_BIN" capture-pane -t "$TMUX_TARGET" -p 2>/dev/null || echo "")
    CACHED_PANE_TIME=$now
    echo "$CACHED_PANE_CONTENT"
}

# METHOD 1: Parse exact token count from TUI (e.g., "63257 tokens")
get_tokens_from_tui_exact() {
    local pane_content
    pane_content=$(capture_tui_pane)

    if [[ -z "$pane_content" ]]; then
        echo "0"
        return 1
    fi

    # Look for exact token count at end of status line: "63257 tokens"
    local exact_tokens
    exact_tokens=$(echo "$pane_content" | grep -oE '[0-9]+ tokens' | tail -1 | grep -oE '[0-9]+')

    if [[ -n "$exact_tokens" ]] && [[ "$exact_tokens" -gt 0 ]]; then
        echo "$exact_tokens"
        return 0
    fi

    echo "0"
    return 1
}

# METHOD 2: Parse abbreviated token count from TUI (e.g., "63.2k")
get_tokens_from_tui_abbreviated() {
    local pane_content
    pane_content=$(capture_tui_pane)

    if [[ -z "$pane_content" ]]; then
        echo "0"
        return 1
    fi

    # Look for abbreviated format in status bar: "63.2k" or "63k"
    # Pattern: number followed by 'k' (case insensitive) in status line
    local abbrev_tokens
    abbrev_tokens=$(echo "$pane_content" | tail -3 | grep -oE '[0-9]+\.?[0-9]*k' | head -1)

    if [[ -n "$abbrev_tokens" ]]; then
        # Remove 'k' suffix and multiply by 1000
        local numeric_part
        numeric_part=$(echo "$abbrev_tokens" | sed 's/k$//')
        # Handle decimal: 63.2 → 63200
        if [[ "$numeric_part" == *"."* ]]; then
            # Multiply by 1000, handling decimal
            local result
            result=$(echo "$numeric_part * 1000" | bc 2>/dev/null | cut -d'.' -f1)
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
    return 1
}

# METHOD 3: Parse percentage from TUI (e.g., "32%")
get_percentage_from_tui() {
    local pane_content
    pane_content=$(capture_tui_pane)

    if [[ -z "$pane_content" ]]; then
        echo "0"
        return 1
    fi

    # Look for percentage in status bar area (last 3 lines)
    local pct
    pct=$(echo "$pane_content" | tail -3 | grep -oE '[0-9]+%' | head -1 | tr -d '%')

    if [[ -n "$pct" ]] && [[ "$pct" -gt 0 ]] && [[ "$pct" -le 100 ]]; then
        echo "$pct"
        return 0
    fi

    echo "0"
    return 1
}

# METHOD 4: Get context from statusline JSON (fallback)
get_context_status() {
    if [[ ! -f "$STATUSLINE_FILE" ]]; then
        echo '{"context_window": {"used_percentage": 0, "remaining_percentage": 100}}'
        return 1
    fi
    cat "$STATUSLINE_FILE"
}

# METHOD 5: Sum current_usage fields from statusline JSON
get_tokens_from_json_current_usage() {
    local status
    status=$(get_context_status 2>/dev/null)

    if [[ -z "$status" ]]; then
        echo "0"
        return 1
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
version: 5.4.0
tokens: $tokens
percentage: $pct%
threshold: $JICM_THRESHOLD%
state: $state
trigger_count: $TRIGGER_COUNT
failure_count: $FAILURE_COUNT
token_method: $token_method
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

check_debounce() {
    local now
    now=$(date +%s)
    local elapsed=$((now - JICM_LAST_TRIGGER))
    if [[ $elapsed -lt $DEBOUNCE_SECONDS ]]; then
        log INFO "Debounce active (${elapsed}s < ${DEBOUNCE_SECONDS}s)"
        return 1  # Debounced
    fi
    return 0  # OK to trigger
}

check_trigger_limit() {
    if [[ $TRIGGER_COUNT -ge $MAX_TRIGGERS ]]; then
        enter_standdown "Max triggers reached ($TRIGGER_COUNT)"
        return 1  # Limit reached
    fi
    return 0  # OK
}

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
JICM_CRITICAL_PCT=${JICM_CRITICAL_PCT:-90}
RESERVED_OUTPUT_TOKENS=$RESERVED_OUTPUT_TOKENS
CONTEXT_WINDOW_SIZE=$MAX_CONTEXT_TOKENS
EOF
    log INFO "Wrote JICM config (threshold: ${JICM_THRESHOLD}%, reserved: ${RESERVED_OUTPUT_TOKENS})"
}

# =============================================================================
# IDLE DETECTION
# =============================================================================

is_claude_busy() {
    local pane_content
    pane_content=$("$TMUX_BIN" capture-pane -t "$TMUX_TARGET" -p 2>/dev/null || echo "")

    # Look for spinner or processing indicators
    if echo "$pane_content" | grep -qE '[⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏◐◓◑◒▁▂▃▄▅▆▇]|Thinking|Processing|⣾⣽⣻⢿⡿⣟⣯⣷'; then
        return 0  # Busy
    fi
    return 1  # Not busy
}

wait_for_idle() {
    local timeout="${1:-60}"
    local wait_count=0

    while [[ $wait_count -lt $timeout ]]; do
        if ! is_claude_busy; then
            return 0  # Idle
        fi
        sleep 2
        ((wait_count += 2))
    done
    return 1  # Timeout
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
        return 1
    fi

    local full_command="$command"
    if [[ -n "$args" ]]; then
        full_command="$command $args"
    fi

    log CMD "Sending: $full_command"
    "$TMUX_BIN" send-keys -t "$TMUX_TARGET" -l "$full_command"
    sleep 0.1
    "$TMUX_BIN" send-keys -t "$TMUX_TARGET" C-m
    return 0
}

send_text() {
    local text="$1"
    if ! "$TMUX_BIN" has-session -t "$TMUX_SESSION" 2>/dev/null; then
        log ERROR "tmux session '$TMUX_SESSION' not found"
        return 1
    fi
    log CMD "Sending text (${#text} chars)"
    "$TMUX_BIN" send-keys -t "$TMUX_TARGET" -l "$text"
    sleep 0.1
    "$TMUX_BIN" send-keys -t "$TMUX_TARGET" C-m
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
}

# Spawn compression agent (called by /intelligent-compress, not directly by watcher)
# In v5, the watcher sends /intelligent-compress command which handles spawning
spawn_compression_agent() {
    local tokens="$1"
    local pct="$2"

    log JICM "═══ SPAWNING COMPRESSION AGENT at ${pct}% ═══"

    # Create spawn signal for Claude to pick up
    # Claude's Task tool will be used to spawn the agent
    cat > "$PROJECT_DIR/.claude/context/.spawn-compression-agent.signal" <<EOF
{
    "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "action": "spawn_compression_agent",
    "trigger_percentage": $pct,
    "trigger_tokens": $tokens,
    "agent": "compression-agent",
    "model": "sonnet",
    "timeout_seconds": $AGENT_TIMEOUT,
    "compression_target": "5000-15000"
}
EOF

    JICM_STATE="compression_spawned"
    JICM_LAST_TRIGGER=$(date +%s)
    TRIGGER_COUNT=$((TRIGGER_COUNT + 1))

    log JICM "Compression agent spawn signaled, waiting for completion..."
}

# EXECUTOR LAYER 1: Send interrupt + dump prompt
executor_layer1_interrupt_and_dump() {
    log JICM "═══ EXECUTOR LAYER 1: Interrupt + Dump ═══"

    # Wait for Claude to be idle
    log JICM "Waiting for idle state..."
    wait_for_idle 30 || log WARN "Idle timeout, proceeding anyway"

    # Send the dump prompt
    local dump_prompt="JICM CONTEXT CHECKPOINT REQUEST

Your context is being optimized. Before proceeding:

1. Write your current work state to: .claude/context/.in-progress-ready.md
   Include:
   - What task you were working on
   - Your current reasoning/thought process
   - Any partial work or uncommitted changes
   - Immediate next steps

2. After writing the file, respond with exactly: DUMP_COMPLETE

This ensures your work-in-progress survives the context optimization."

    send_text "$dump_prompt"

    # Write signal that dump was requested
    echo "$(date -u +%Y-%m-%dT%H:%M:%SZ)" > "$DUMP_REQUESTED_SIGNAL"

    JICM_STATE="dump_requested"
    log JICM "Dump prompt sent, waiting for response..."
}

# EXECUTOR LAYER 2: Wait for dump, send /clear
executor_layer2_wait_and_clear() {
    log JICM "═══ EXECUTOR LAYER 2: Wait for Dump + Clear ═══"

    local wait_count=0

    # Wait for in-progress file to be written
    while [[ ! -f "$IN_PROGRESS_FILE" ]] && [[ $wait_count -lt $DUMP_TIMEOUT ]]; do
        sleep 2
        ((wait_count += 2))
        if [[ $((wait_count % 10)) -eq 0 ]]; then
            log JICM "  Waiting for dump... (${wait_count}s)"
        fi
    done

    if [[ -f "$IN_PROGRESS_FILE" ]]; then
        log JICM "In-progress dump received"
    else
        log WARN "Dump timeout after ${DUMP_TIMEOUT}s - proceeding with /clear anyway"
    fi

    # Check if /clear was already sent recently (avoid duplicate)
    if [[ -f "$CLEAR_SENT_SIGNAL" ]]; then
        local clear_ts=$(cat "$CLEAR_SENT_SIGNAL" 2>/dev/null)
        if [[ -n "$clear_ts" ]]; then
            local clear_epoch=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$clear_ts" +%s 2>/dev/null || echo "0")
            local now_epoch=$(date +%s)
            local clear_age=$((now_epoch - clear_epoch))
            if [[ $clear_age -lt 60 ]]; then
                log JICM "Skipping /clear - already sent ${clear_age}s ago"
                JICM_STATE="monitoring"
                reset_failure_count
                return
            fi
        fi
    fi

    # Send /clear
    log JICM "Sending /clear..."
    send_command "/clear"

    # Write signal that clear was sent
    echo "$(date -u +%Y-%m-%dT%H:%M:%SZ)" > "$CLEAR_SENT_SIGNAL"

    # Invalidate TUI cache - context data will be completely different after clear
    invalidate_tui_cache

    JICM_STATE="cleared"

    # Start cascade resumer
    trigger_cascade_resumer
}

# Cascade Resumer: Ensure Jarvis resumes properly
trigger_cascade_resumer() {
    log JICM "═══ CASCADE RESUMER: Starting ═══"

    # The session-start hook should inject continuation context
    # But we'll verify and re-inject if needed

    # Wait for initial injection
    sleep "$CONTINUATION_DELAY_1"

    if [[ -f "$CONTINUATION_INJECTED_SIGNAL" ]]; then
        log JICM "Continuation injected by hook"
    else
        log JICM "Cascade Check 1: Injecting continuation prompt"
        inject_continuation_prompt
    fi

    # Second check
    sleep "$CONTINUATION_DELAY_2"

    if is_claude_busy; then
        log JICM "Claude is working - continuation successful"
    else
        log JICM "Cascade Check 2: Re-injecting continuation"
        inject_continuation_prompt
    fi

    # Final enforcement
    sleep "$CONTINUATION_DELAY_3"

    if is_claude_busy; then
        log JICM "Work resumed successfully"
        JICM_STATE="resumed"
        reset_failure_count
    else
        log WARN "Cascade Check 3: Final enforcement"
        send_text "Resume work immediately. Read .claude/context/.compressed-context-ready.md and .claude/context/.in-progress-ready.md then continue the interrupted task."
        JICM_STATE="enforced"
    fi

    # Mark JICM cycle complete
    echo "$(date -u +%Y-%m-%dT%H:%M:%SZ)" > "$JICM_COMPLETE_SIGNAL"
    log JICM "═══ JICM CYCLE COMPLETE ═══"
}

inject_continuation_prompt() {
    local continuation_text="CONTEXT CONTINUATION - DO NOT GREET

Your context was just optimized. Resume work immediately.

1. Read: .claude/context/.compressed-context-ready.md (preserved context)
2. Read: .claude/context/.in-progress-ready.md (work in progress)
3. Continue the task that was interrupted

DO NOT say hello or ask how to help. Just resume working."

    send_text "$continuation_text"
    echo "$(date -u +%Y-%m-%dT%H:%M:%SZ)" > "$CONTINUATION_INJECTED_SIGNAL"
}

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
# CRITICAL STATE DETECTION (JICM v6)
# =============================================================================
# Detect specific TUI states that require immediate intervention.
# These are higher priority than general idle detection.
#
# States handled:
#   1. post_clear_restore: "(no content)" after /clear - IMMEDIATE action
#   2. fresh_session: "0 tokens" - full context restoration
#   3. interrupted: "Interrupted · What should Claude do" - resume prompt
#
# Returns: mode name if critical state detected, empty string otherwise

detect_critical_state() {
    local pane_content
    pane_content=$("$TMUX_BIN" capture-pane -t "$TMUX_TARGET" -p 2>/dev/null || echo "")

    if [[ -z "$pane_content" ]]; then
        echo ""
        return 0  # Always return 0 (bash 3.2 set -e compatibility)
    fi

    # Priority 1: Post-clear with no content - IMMEDIATE action required
    # Pattern: "⎿  (no content)" or "/clear" followed by "(no content)"
    if echo "$pane_content" | grep -qE '\(no content\)'; then
        echo "post_clear_restore"
        return 0
    fi

    # Priority 2: Fresh/cleared session with 0 tokens
    # Pattern: "0 tokens" in status line area
    if echo "$pane_content" | tail -5 | grep -qE '^\s*0 tokens|[^0-9]0 tokens'; then
        echo "fresh_session"
        return 0
    fi

    # Priority 3: Interrupted state - DISABLED (v5.4.2)
    # Previously triggered on "Interrupted · What should Claude do" but this
    # causes a runaway loop: watcher prompt → interrupt → detect → prompt → ...
    # When user interrupts Claude, they will provide the next instruction.
    # The watcher should NOT intervene in this state.
    #
    # if echo "$pane_content" | grep -qE 'Interrupted.*What should Claude do'; then
    #     echo "interrupted"
    #     return 0
    # fi

    # No critical state detected
    # IMPORTANT: Always return 0 to avoid set -e exit on command substitution
    # (bash 3.2 on macOS triggers exit when subshell returns non-zero)
    # Caller checks output: empty = no critical state, non-empty = critical state
    echo ""
    return 0
}

# Handle critical state with appropriate response
handle_critical_state() {
    local state="$1"

    case "$state" in
        post_clear_restore)
            log JICM "═══ CRITICAL STATE: Post-clear with no content ═══"
            # IMMEDIATE context restoration
            local restore_prompt='CONTEXT RESTORATION REQUIRED

Your context was just cleared. Resume work using these files:
1. .claude/context/.compressed-context-ready.md (if exists)
2. .claude/context/.in-progress-ready.md (if exists)
3. .claude/context/session-state.md

Do NOT greet. Continue the task that was in progress.'
            if ! "$TMUX_BIN" send-keys -t "$TMUX_TARGET" -l "$restore_prompt" 2>/dev/null; then
                log WARN "Failed to send restore prompt - tmux command failed"
                return 1
            fi
            sleep 0.1
            "$TMUX_BIN" send-keys -t "$TMUX_TARGET" C-m 2>/dev/null || true
            ;;

        fresh_session)
            log JICM "═══ CRITICAL STATE: Fresh session (0 tokens) ═══"
            # Check if this is a JICM resume or true fresh start
            if [[ -f "$COMPRESSED_CONTEXT_FILE" ]] || [[ -f "$IN_PROGRESS_FILE" ]]; then
                # JICM resume
                local jicm_prompt='JICM CONTEXT RESTORED

Read these files and continue your interrupted task:
1. .claude/context/.compressed-context-ready.md
2. .claude/context/.in-progress-ready.md

Do NOT greet. Resume work immediately.'
                if ! "$TMUX_BIN" send-keys -t "$TMUX_TARGET" -l "$jicm_prompt" 2>/dev/null; then
                    log WARN "Failed to send JICM prompt - tmux command failed"
                    return 1
                fi
            else
                # True fresh session - let session_start mode handle it
                log JICM "Fresh session without JICM context - deferring to session_start mode"
                return 1
            fi
            sleep 0.1
            "$TMUX_BIN" send-keys -t "$TMUX_TARGET" C-m 2>/dev/null || true
            ;;

        interrupted)
            log JICM "═══ CRITICAL STATE: Interrupted ═══"
            # Simple resume prompt
            if ! "$TMUX_BIN" send-keys -t "$TMUX_TARGET" -l "Resume your previous task." 2>/dev/null; then
                log WARN "Failed to send resume prompt - tmux command failed"
                return 1
            fi
            sleep 0.1
            "$TMUX_BIN" send-keys -t "$TMUX_TARGET" C-m 2>/dev/null || true
            ;;

        *)
            log WARN "Unknown critical state: $state"
            return 1
            ;;
    esac

    return 0
}

# Send prompt text based on prompt type
# NOTE: Text is sent via -l flag (literal), then submit is sent SEPARATELY
# See: lessons/tmux-self-injection-limitation.md
send_prompt_by_type() {
    local prompt_type="$1"

    case "$prompt_type" in
        "RESUME")
            # Full resume prompt with explicit file paths and anti-patterns
            "$TMUX_BIN" send-keys -t "$TMUX_TARGET" -l 'JICM CONTEXT RESTORED - RESUME WORK

Read these files and continue your interrupted task:
1. .claude/context/.compressed-context-ready.md
2. .claude/context/.in-progress-ready.md

Do NOT greet. Do NOT ask questions. Resume work immediately.'
            ;;
        "SIMPLE")
            # Simple directive if full prompt didn't work
            "$TMUX_BIN" send-keys -t "$TMUX_TARGET" -l 'Continue your work.'
            ;;
        "MINIMAL")
            # Minimal input to test basic submission
            "$TMUX_BIN" send-keys -t "$TMUX_TARGET" -l '.'
            ;;
        *)
            # Default to simple prompt
            log WARN "Unknown prompt type: $prompt_type, using SIMPLE"
            "$TMUX_BIN" send-keys -t "$TMUX_TARGET" -l 'Continue your work.'
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
submit_with_variant() {
    local variant=$SUBMISSION_VARIANT_INDEX
    local method_idx=$((variant % ${#SUBMISSION_METHODS[@]}))
    local prompt_idx=$((variant / ${#SUBMISSION_METHODS[@]} % ${#SUBMISSION_PROMPTS[@]}))
    local prompt_type="${SUBMISSION_PROMPTS[$prompt_idx]}"

    log JICM "Attempting submission variant $variant: method=$((method_idx + 1))/${#SUBMISSION_METHODS[@]} prompt=$prompt_type"

    # CANONICAL PATTERN: Send text first, then submit as SEPARATE call
    # This is validated to work; embedded CR in text fails
    send_prompt_by_type "$prompt_type"
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

    # Delete signal files
    rm -f "$COMPRESSION_DONE_SIGNAL"
    rm -f "$DUMP_REQUESTED_SIGNAL"
    rm -f "$CLEAR_SENT_SIGNAL"
    rm -f "$CONTINUATION_INJECTED_SIGNAL"

    # Delete context files (now that Jarvis is working)
    rm -f "$COMPRESSED_CONTEXT_FILE"
    rm -f "$IN_PROGRESS_FILE"

    # Delete idle-hands flag
    rm -f "$IDLE_HANDS_FLAG"

    # Mark JICM complete
    echo "$(date -u +%Y-%m-%dT%H:%M:%SZ)" > "$JICM_COMPLETE_SIGNAL"

    log JICM "JICM files cleaned up"
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
    local max_cycles=50       # ~10 minutes of attempts (50 * 12s)
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

            # Try submission
            submit_with_variant

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

    log WARN "IDLE-HANDS: Max cycles reached without confirmed success"
    # Don't remove flag - leave for debugging
    return 1
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

            # Send simple wake-up prompt
            # Use "startSession" which is recognized by Jarvis persona
            "$TMUX_BIN" send-keys -t "$TMUX_TARGET" -l 'startSession'
            sleep 0.1
            "$TMUX_BIN" send-keys -t "$TMUX_TARGET" C-m

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

    log WARN "IDLE-HANDS: session_start max cycles reached"
    # Clean up flag - don't leave stale session_start flags
    rm -f "$IDLE_HANDS_FLAG"
    return 1
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
            idle_hands_session_start
            return $?
            ;;
        long_idle)
            log INFO "IDLE-HANDS: long_idle mode not yet implemented"
            ;;
        workflow_chain)
            log INFO "IDLE-HANDS: workflow_chain mode not yet implemented"
            ;;
        *)
            log WARN "IDLE-HANDS: Unknown mode '$mode'"
            ;;
    esac

    return 1
}

# Fallback to native /compact at y% threshold
trigger_fallback_compact() {
    local tokens="$1"
    local pct="$2"

    log JICM "═══ FALLBACK: Native /compact at ${pct}% ═══"

    wait_for_idle 30 || log WARN "Idle timeout, proceeding anyway"

    send_command "/compact"

    JICM_STATE="fallback_compact"
    JICM_LAST_TRIGGER=$(date +%s)
    TRIGGER_COUNT=$((TRIGGER_COUNT + 1))
}

# Check for compression agent completion
check_compression_complete() {
    if [[ -f "$COMPRESSION_DONE_SIGNAL" ]]; then
        log JICM "Compression agent completed"
        rm -f "$COMPRESSION_DONE_SIGNAL"
        return 0
    fi
    return 1
}

# =============================================================================
# MAIN LOOP
# =============================================================================

banner() {
    echo -e "${CYAN}━━━ JARVIS WATCHER v5.4.0 ━━━${NC} threshold:${JICM_THRESHOLD}% interval:${INTERVAL}s"
    echo -e "${GREEN}●${NC} Context ${GREEN}●${NC} JICM v5.4.2 ${GREEN}●${NC} Idle-Hands Monitor │ Ctrl+C to stop"
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
trap 'echo "[DEBUG] EXIT trap fired (signal was: $SHUTDOWN_SIGNAL)" >&2' EXIT

main() {
    banner

    if ! "$TMUX_BIN" has-session -t "$TMUX_SESSION" 2>/dev/null; then
        log ERROR "tmux session '$TMUX_SESSION' not found"
        echo "Start Jarvis with: .claude/scripts/launch-jarvis-tmux.sh"
        exit 1
    fi

    log INFO "Watcher started (JICM v5.4.2)"

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
        # 1.1 Check for idle-hands flag (JICM v5 Mechanism 2)
        # ─────────────────────────────────────────────────────────────
        if [[ -f "$IDLE_HANDS_FLAG" ]]; then
            check_idle_hands
            # After handling, continue to next iteration
            sleep 2
            continue
        fi

        # ─────────────────────────────────────────────────────────────
        # 1.2 Check for critical TUI states (JICM v6)
        # ─────────────────────────────────────────────────────────────
        # These states require immediate intervention, higher priority than
        # normal idle detection. Checks for:
        #   - "(no content)" after /clear
        #   - "0 tokens" (fresh/cleared session)
        #   - "Interrupted" state
        #
        # Skip on first 2 iterations to avoid false positives on startup
        poll_count=$((poll_count + 1))
        if [[ $poll_count -gt 2 ]]; then
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
        # 1.5 Check for /intelligent-compress completion
        # ─────────────────────────────────────────────────────────────
        # This handles BOTH:
        #   - Manual: user runs /intelligent-compress (state=monitoring)
        #   - Watcher-triggered: watcher sends /intelligent-compress (state=compression_triggered)
        # In both cases, the compression agent creates .compression-done.signal when done
        if [[ -f "$COMPRESSION_DONE_SIGNAL" ]] && [[ "$JICM_STATE" == "monitoring" || "$JICM_STATE" == "compression_triggered" ]]; then
            log JICM "Detected compression completion signal (state: $JICM_STATE)"
            # No debounce needed - signal file is removed after processing, preventing re-trigger
            # Only check trigger_limit as safety net
            if check_trigger_limit; then
                JICM_LAST_TRIGGER=$(date +%s)
                TRIGGER_COUNT=$((TRIGGER_COUNT + 1))
                rm -f "$COMPRESSION_DONE_SIGNAL"
                # Skip Layer 1 (dump prompt) since /intelligent-compress already saved context
                # Go directly to sending /clear
                log JICM "═══ MANUAL COMPRESSION: Preparing /clear ═══"

                # Check if /clear was already sent recently (avoid duplicate with user's manual /clear)
                if [[ -f "$CLEAR_SENT_SIGNAL" ]]; then
                    local clear_ts=$(cat "$CLEAR_SENT_SIGNAL" 2>/dev/null)
                    if [[ -n "$clear_ts" ]]; then
                        local clear_epoch=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$clear_ts" +%s 2>/dev/null || echo "0")
                        local now_epoch=$(date +%s)
                        local clear_age=$((now_epoch - clear_epoch))
                        if [[ $clear_age -lt 60 ]]; then
                            log JICM "Skipping /clear - already sent ${clear_age}s ago"
                            JICM_STATE="monitoring"
                            reset_failure_count
                            log JICM "Manual compression cycle complete (no-op)"
                            continue
                        fi
                    fi
                fi

                wait_for_idle 30 || log WARN "Idle timeout, proceeding anyway"
                log JICM "Sending /clear..."
                send_command "/clear"
                echo "$(date -u +%Y-%m-%dT%H:%M:%SZ)" > "$CLEAR_SENT_SIGNAL"

                # Invalidate TUI cache - context data will be completely different after clear
                invalidate_tui_cache

                JICM_STATE="cleared"
                # Let session-start.sh handle continuation injection
                # Extended settling delay for TUI to stabilize after clear
                log JICM "Waiting 5s for TUI to stabilize after /clear..."
                sleep 5
                JICM_STATE="monitoring"
                reset_failure_count
                log JICM "Manual compression cycle complete"
            else
                # Trigger limit reached
                log WARN "Trigger limit reached - cannot process compression signal"
                rm -f "$COMPRESSION_DONE_SIGNAL"  # Clean up anyway to avoid loop
            fi
        fi

        # ─────────────────────────────────────────────────────────────
        # 2. Check for compression agent completion (watcher-spawned)
        # ─────────────────────────────────────────────────────────────
        if [[ "$JICM_STATE" == "compression_spawned" ]]; then
            if check_compression_complete; then
                # Compression done, proceed to Layer 1
                executor_layer1_interrupt_and_dump
            else
                # Check for timeout
                local now
                now=$(date +%s)
                local elapsed=$((now - JICM_LAST_TRIGGER))
                if [[ $elapsed -gt $AGENT_TIMEOUT ]]; then
                    log WARN "Compression agent timeout after ${elapsed}s"
                    record_failure
                    # Fall back to native /compact
                    trigger_fallback_compact "$(get_token_count)" "$(get_used_percentage)"
                fi
            fi
        fi

        # ─────────────────────────────────────────────────────────────
        # 3. Check for dump completion (Layer 2)
        # ─────────────────────────────────────────────────────────────
        if [[ "$JICM_STATE" == "dump_requested" ]]; then
            if [[ -f "$IN_PROGRESS_FILE" ]]; then
                executor_layer2_wait_and_clear
            fi
        fi

        # ─────────────────────────────────────────────────────────────
        # 4. Context monitoring
        # ─────────────────────────────────────────────────────────────
        local pct
        pct=$(get_used_percentage)

        if [[ "$pct" == "0" ]] || [[ -z "$pct" ]]; then
            poll_count=$((poll_count + 1))
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

        echo "[DEBUG] Reached section 5 - threshold check (method: $token_method, poll: $poll_count)" >&2

        # ─────────────────────────────────────────────────────────────
        # 5. Threshold check (JICM v5 - single threshold)
        # ─────────────────────────────────────────────────────────────
        # NOTE: No debounce here. Natural debounce is context level itself:
        # - If compression works → context drops below threshold
        # - Won't re-trigger until context grows back above threshold
        # Only trigger_limit as safety net (max triggers per session)
        if [[ "$JICM_STATE" == "monitoring" ]]; then
            if [[ $pct_int -ge $JICM_THRESHOLD ]]; then
                if check_trigger_limit; then
                    log JICM "═══ JICM v5: Context at ${pct}% - triggering compression ═══"
                    wait_for_idle 30 || log WARN "Idle timeout, proceeding anyway"
                    send_command "/intelligent-compress"
                    JICM_STATE="compression_triggered"
                    JICM_LAST_TRIGGER=$(date +%s)
                    TRIGGER_COUNT=$((TRIGGER_COUNT + 1))
                else
                    log WARN "Trigger limit reached ($TRIGGER_COUNT >= $MAX_TRIGGERS) - falling back to native /compact"
                fi
            fi
        fi

        # ─────────────────────────────────────────────────────────────
        # 6. Reset after JICM cycle completes
        # ─────────────────────────────────────────────────────────────
        # For "resumed" and "enforced" states: reset if cooldown passed OR context is low
        if [[ "$JICM_STATE" == "resumed" ]] || [[ "$JICM_STATE" == "enforced" ]]; then
            local now
            now=$(date +%s)
            local elapsed=$((now - JICM_LAST_TRIGGER))

            # Reset after cooldown or if context is low (indicates successful clear)
            if [[ $elapsed -gt $DEBOUNCE_SECONDS ]] || [[ $pct_int -lt 30 ]]; then
                log INFO "JICM cycle complete, returning to monitoring"
                cleanup_jicm_signals_only
                JICM_STATE="monitoring"
            fi
        fi

        # For "compression_triggered" state: ONLY reset after cooldown period
        # Do NOT reset based on low percentage - compression_triggered waits for
        # .compression-done.signal (handled in section 1.5) before the flow continues
        if [[ "$JICM_STATE" == "compression_triggered" ]]; then
            local now
            now=$(date +%s)
            local elapsed=$((now - JICM_LAST_TRIGGER))

            # Only reset after full debounce period (timeout scenario)
            if [[ $elapsed -gt $DEBOUNCE_SECONDS ]]; then
                log WARN "Compression trigger timeout (${elapsed}s > ${DEBOUNCE_SECONDS}s), returning to monitoring"
                cleanup_jicm_signals_only
                JICM_STATE="monitoring"
            fi
        fi

        # poll_count already incremented at start of loop (line ~1462) - no duplicate here
        echo "[DEBUG] End of loop iteration, about to sleep $INTERVAL (poll: $poll_count)" >&2
        sleep "$INTERVAL"
        echo "[DEBUG] Woke from sleep, starting next iteration" >&2
    done
}

# Run main
main
