#!/bin/bash
# ============================================================================
# JICM v6 WATCHER — Ground-Up Redesign (Stop-and-Wait Architecture)
# ============================================================================
#
# A simple, precise, responsive, accurate, stable context monitoring and
# compression system. When context reaches threshold, Jarvis STOPS, context
# is compressed, /clear is sent, and Jarvis resumes from compressed context.
#
# State Machine: WATCHING → HALTING → COMPRESSING → CLEARING → RESTORING → WATCHING
#
# Design: .claude/context/designs/jicm-v6-design.md
# Analysis: .claude/context/designs/jicm-v6-critical-analysis.md
#
# Usage:
#   .claude/scripts/jicm-watcher.sh [--threshold PCT] [--interval SEC]
#
# ============================================================================

set -euo pipefail

# Trap ERR for debugging (essential for bash 3.2 set -e)
trap 'echo "[ERR] Line $LINENO (exit $?)" >&2' ERR

# =============================================================================
# CONFIGURATION
# =============================================================================

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$HOME/Claude/Jarvis}"
TMUX_BIN="${TMUX_BIN:-$HOME/bin/tmux}"
TMUX_SESSION="${TMUX_SESSION:-jarvis}"
TMUX_TARGET="${TMUX_SESSION}:0"

# Paths
LOG_FILE="$PROJECT_DIR/.claude/logs/jicm-watcher.log"
STATE_FILE="$PROJECT_DIR/.claude/context/.jicm-state"
COMPRESSED_FILE="$PROJECT_DIR/.claude/context/.compressed-context-ready.md"
COMPRESSION_SIGNAL="$PROJECT_DIR/.claude/context/.compression-done.signal"
SLEEP_SIGNAL="$PROJECT_DIR/.claude/context/.jicm-sleep.signal"
EXIT_SIGNAL="$PROJECT_DIR/.claude/context/.jicm-exit-mode.signal"
ARCHIVE_DIR="$PROJECT_DIR/.claude/logs/jicm/archive"
EXPORTS_DIR="$PROJECT_DIR/.claude/exports"

# Thresholds and timing
JICM_THRESHOLD=${JICM_THRESHOLD:-55}
POLL_INTERVAL=${POLL_INTERVAL:-5}
HALT_TIMEOUT=60
COMPRESS_TIMEOUT=300
CLEAR_TIMEOUT=60
RESTORE_TIMEOUT=120
RESTORE_RETRY_DELAY=15
COOLDOWN_PERIOD=600

# Context window constants
MAX_CONTEXT_TOKENS=200000
RESERVED_OUTPUT_TOKENS=${RESERVED_OUTPUT_TOKENS:-15000}
COMPACT_BUFFER=${COMPACT_BUFFER:-28000}
LOCKOUT_PCT=$(( (MAX_CONTEXT_TOKENS - RESERVED_OUTPUT_TOKENS - COMPACT_BUFFER) * 100 / MAX_CONTEXT_TOKENS ))
EMERGENCY_PCT=$((LOCKOUT_PCT - 5))

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --threshold) JICM_THRESHOLD="$2"; shift 2 ;;
        --interval) POLL_INTERVAL="$2"; shift 2 ;;
        -h|--help)
            echo "JICM v6 Watcher — Stop-and-Wait Context Management"
            echo ""
            echo "Usage: $0 [options]"
            echo "  --threshold PCT   Compression trigger (default: $JICM_THRESHOLD)"
            echo "  --interval SEC    Poll interval (default: $POLL_INTERVAL)"
            exit 0
            ;;
        *) shift ;;
    esac
done

# =============================================================================
# ANSI COLORS (ANSI-C quoting for reliable bash 3.2 rendering)
# =============================================================================

readonly C_RESET=$'\e[0m'
readonly C_RED=$'\e[0;31m'
readonly C_GREEN=$'\e[0;32m'
readonly C_YELLOW=$'\e[1;33m'
readonly C_BLUE=$'\e[0;34m'
readonly C_CYAN=$'\e[0;36m'
readonly C_MAGENTA=$'\e[0;35m'
readonly C_BOLD=$'\e[1m'
readonly C_DIM=$'\e[2m'

# =============================================================================
# STATE
# =============================================================================

JICM_STATE="WATCHING"
COMPRESSION_COUNT=0
ERROR_COUNT=0
COOLDOWN_UNTIL=0
SESSION_START_TIME=$(date +%s)
STATE_ENTERED_AT=$(date +%s)
RESTORE_ATTEMPTS=0
CLEAR_RETRIES=0
LAST_PCT=0
LAST_TOKENS=0
DASHBOARD_DRAWN=0

LAST_CYCLE_SUMMARY=""

# Metrics timing (E5: telemetry — track cycle phase durations)
CYCLE_START_TIME=0
CYCLE_START_PCT=0
CYCLE_START_TOKENS=0
COMPRESS_START_TIME=0
CLEAR_START_TIME=0
RESTORE_START_TIME=0
METRICS_FILE="$PROJECT_DIR/.claude/logs/telemetry/jicm-metrics.jsonl"

# =============================================================================
# SETUP
# =============================================================================

mkdir -p "$(dirname "$LOG_FILE")"
mkdir -p "$(dirname "$STATE_FILE")"
mkdir -p "$ARCHIVE_DIR"
mkdir -p "$EXPORTS_DIR"
mkdir -p "$(dirname "$METRICS_FILE")"

# Clean stale signals from previous runs
rm -f "$COMPRESSION_SIGNAL"

# PID file for concurrent watcher detection
PID_FILE="$PROJECT_DIR/.claude/context/.jicm-watcher.pid"

check_existing_watcher() {
    if [[ -f "$PID_FILE" ]]; then
        local old_pid
        old_pid=$(cat "$PID_FILE" 2>/dev/null || echo "0")
        if [[ -n "$old_pid" ]] && [[ "$old_pid" != "0" ]] && kill -0 "$old_pid" 2>/dev/null; then
            echo "ERROR: Another JICM watcher is already running (PID $old_pid)"
            echo "Kill it with: kill $old_pid"
            exit 1
        fi
        # Stale PID file — remove it
        rm -f "$PID_FILE"
    fi
    echo $$ > "$PID_FILE"
}

check_existing_watcher

# Log rotation (keep last 100KB)
rotate_log() {
    if [[ -f "$LOG_FILE" ]]; then
        local size
        size=$(wc -c < "$LOG_FILE" 2>/dev/null | tr -d ' ' || echo "0")
        if [[ "$size" -gt 102400 ]]; then
            local rotated="${LOG_FILE}.1"
            mv "$LOG_FILE" "$rotated" 2>/dev/null || true
            echo "$(date -u +"%Y-%m-%dT%H:%M:%SZ") | INFO | Log rotated ($size bytes)" > "$LOG_FILE"
        fi
    fi
}

rotate_log

# =============================================================================
# LOGGING
# =============================================================================

log() {
    local level="$1"
    shift
    local msg="$*"
    local ts
    ts=$(date +"%H:%M:%S")
    local iso_ts
    iso_ts=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    # File log (always)
    echo "$iso_ts | $level | $msg" >> "$LOG_FILE"

    # Console log (colored)
    case "$level" in
        INFO)  echo "${ts} ${C_GREEN}[INFO]${C_RESET} $msg" ;;
        WARN)  echo "${ts} ${C_YELLOW}[WARN]${C_RESET} $msg" ;;
        ERROR) echo "${ts} ${C_RED}[ERR]${C_RESET}  $msg" ;;
        JICM)  echo "${ts} ${C_MAGENTA}[JICM]${C_RESET} $msg" ;;
        STATE) echo "${ts} ${C_CYAN}[>>>>]${C_RESET} $msg" ;;
        *)     echo "${ts} [$level] $msg" ;;
    esac
}

# =============================================================================
# STATE FILE (unified — replaces 8+ signal files from v5)
# =============================================================================

write_state() {
    local sleeping="false"
    [[ -f "$SLEEP_SIGNAL" ]] && sleeping="true"
    cat > "$STATE_FILE" <<EOF
state: $JICM_STATE
timestamp: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
context_pct: ${LAST_PCT:-0}
context_tokens: ${LAST_TOKENS:-0}
threshold: $JICM_THRESHOLD
compressions: $COMPRESSION_COUNT
errors: $ERROR_COUNT
pid: $$
version: 6.1.0
sleeping: $sleeping
EOF

    # .watcher-status compat write REMOVED (v6.1) — all consumers migrated to .jicm-state
}

# =============================================================================
# TMUX INTERACTION
# =============================================================================
# CANONICAL PATTERNS (validated 2026-02-04):
#   Text:   send-keys -t TARGET -l "text"
#   Submit: send-keys -t TARGET C-m       (SEPARATE call, NEVER embedded)
#   Escape: send-keys -t TARGET Escape
#
# CONSTRAINTS:
#   - ALL prompts MUST be single-line (multi-line corrupts TUI input)
#   - Submit MUST be separate send-keys call (embedded CR = literal char)
#   - Only send when Jarvis is IDLE (no spinner in last 5 lines)
#   - This script runs EXTERNALLY to Claude Code (required for injection)

tmux_has_session() {
    "$TMUX_BIN" has-session -t "$TMUX_SESSION" 2>/dev/null
    return $?
}

tmux_capture() {
    "$TMUX_BIN" capture-pane -t "$TMUX_TARGET" -p 2>/dev/null || echo ""
}

tmux_send_escape() {
    "$TMUX_BIN" send-keys -t "$TMUX_TARGET" Escape 2>/dev/null || true
}

tmux_send_text() {
    local text="$1"
    "$TMUX_BIN" send-keys -t "$TMUX_TARGET" -l "$text" 2>/dev/null || true
}

tmux_send_submit() {
    "$TMUX_BIN" send-keys -t "$TMUX_TARGET" C-m 2>/dev/null || true
}

# Send text + submit as canonical two-step pattern
tmux_send_prompt() {
    local text="$1"
    tmux_send_text "$text"
    sleep 0.1
    tmux_send_submit
}

# Send a slash command (Escape first to clear any pending input)
tmux_send_command() {
    local cmd="$1"
    tmux_send_escape
    sleep 0.2
    tmux_send_prompt "$cmd"
}

# =============================================================================
# IDLE / ACTIVE DETECTION (v6.1 — ESC-triggered pattern matching)
# =============================================================================
#
# ARCHITECTURE:
#   1. Default assumption: Jarvis is ACTIVE
#   2. IDLE detection: Send ESC → capture → match "Interrupted" pattern
#   3. ACTIVE detection: After prompt submit → capture → detect content change
#
# STABLE PATTERN (observed across CC 2.0.x → 2.1.x versions):
#   IDLE:   "Interrupted · What should Claude do instead?" followed by
#           separator bar (─────) with ONLY blank lines / bare ❯ between
#   ACTIVE: Content appears between "Interrupted" and separator
#           (submitted text, activity indicators, response text)
#
# WHY NOT SPINNERS:
#   CC team actively changes spinner characters (⠋⠙ etc), activity text
#   ("Computing...", "Cogitating..."), and symbols (● ✻) between minor
#   versions. These persist on screen after work completes (false positive).
#   The "Interrupted" pattern is the only text observed stable across versions.

# Idle pattern constant — the stable anchor text
readonly IDLE_PATTERN='Interrupted.*What should Claude do'

# Internal: Analyze pane content for idle pattern. Pure string analysis.
# Returns "idle", "not_idle", or "unknown". Always returns 0 (bash 3.2).
_check_idle_pattern() {
    local pane="$1"

    if [[ -z "$pane" ]]; then
        echo "unknown"
        return 0
    fi

    # Look for "Interrupted" pattern anywhere in pane
    if ! echo "$pane" | grep -q "$IDLE_PATTERN"; then
        echo "unknown"
        return 0
    fi

    # Find LAST "Interrupted" occurrence (most recent on screen)
    local int_line_num
    int_line_num=$(echo "$pane" | grep -n "$IDLE_PATTERN" | tail -1 | cut -d: -f1)

    # Find first separator bar (─────) AFTER the Interrupted line
    local after_int
    after_int=$(echo "$pane" | tail -n +"$((int_line_num + 1))")
    local sep_offset
    sep_offset=$(echo "$after_int" | grep -n '─────' | head -1 | cut -d: -f1 || true)

    if [[ -z "$sep_offset" ]]; then
        echo "unknown"
        return 0
    fi

    # Extract lines between Interrupted and separator
    local between_count=$((sep_offset - 1))
    if [[ $between_count -le 0 ]]; then
        # Separator immediately after Interrupted = definitely idle
        echo "idle"
        return 0
    fi

    local between
    between=$(echo "$after_int" | head -n "$between_count")

    # Filter: blank lines and bare ❯ prompt (both expected in idle state)
    local content
    content=$(echo "$between" | grep -v '^\s*$' | grep -v '^❯\s*$' || true)

    if [[ -z "$content" ]]; then
        echo "idle"
    else
        echo "not_idle"
    fi
    return 0
}

# Poll idle pattern on current pane WITHOUT sending ESC.
# Safe to call repeatedly in a wait loop.
poll_idle_pattern() {
    local pane
    pane=$(tmux_capture)
    _check_idle_pattern "$pane"
}

# Send ESC and check for idle pattern. TRIGGERED check — sends ESC.
# Use only when halting is imminent (context at threshold).
# Returns "idle", "not_idle", or "unknown". Always returns 0.
trigger_idle_check() {
    # Step 1: Send ESC to trigger interrupt (if active) or no-op (if idle)
    tmux_send_escape
    sleep 0.5

    # Step 2: Capture and analyze
    local pane
    pane=$(tmux_capture)
    local result
    result=$(_check_idle_pattern "$pane")

    if [[ "$result" != "unknown" ]]; then
        echo "$result"
        return 0
    fi

    # Fallback: no Interrupted pattern on screen.
    # May be at clean prompt (never interrupted before).
    # Check for bare ❯ as weak idle indicator.
    if [[ -n "$pane" ]] && echo "$pane" | tail -3 | grep -qE '^❯\s*$'; then
        echo "idle"
    else
        echo "not_idle"
    fi
    return 0
}

# Detect if Jarvis has become active after a prompt was submitted.
# Does NOT send ESC — only captures and analyzes current screen state.
# Returns "active" or "inactive". Always returns 0.
detect_activity() {
    local pane
    pane=$(tmux_capture)

    if [[ -z "$pane" ]]; then
        echo "inactive"
        return 0
    fi

    # Method 1: Pattern break — content between Interrupted and separator
    local pattern_result
    pattern_result=$(_check_idle_pattern "$pane")
    if [[ "$pattern_result" == "not_idle" ]]; then
        echo "active"
        return 0
    fi

    # Method 2: Check last 15 lines for response activity
    local recent
    recent=$(echo "$pane" | tail -15)

    # JICM-tagged responses (our prompts being acknowledged)
    if echo "$recent" | grep -qiE 'context restored|understood|compression spawned'; then
        echo "active"
        return 0
    fi

    # Tool activity markers (output from Read, Write, Bash, etc.)
    if echo "$recent" | grep -qE '⎿|Wrote to|Created|Modified'; then
        echo "active"
        return 0
    fi

    # Token activity in status line (↑ N tokens with N > 0)
    if echo "$recent" | grep -qE '↑ [1-9][0-9]* tokens'; then
        echo "active"
        return 0
    fi

    echo "inactive"
    return 0
}

# Wait for Jarvis to become idle using triggered pattern check.
# Sends ESC ONCE (first call), then polls pattern without re-sending.
# Sets WAIT_RESULT to "idle" or "timeout". Always returns 0.
WAIT_RESULT=""
wait_for_idle() {
    local max_wait=${1:-30}
    local waited=0

    # First check: send ESC and check pattern (triggered)
    local state
    state=$(trigger_idle_check)
    if [[ "$state" == "idle" ]]; then
        WAIT_RESULT="idle"
        log INFO "Idle confirmed via triggered check"
        return 0
    fi

    # Subsequent checks: poll pattern without re-sending ESC
    while [[ $waited -lt $max_wait ]]; do
        sleep 2
        waited=$((waited + 2))

        state=$(poll_idle_pattern)
        if [[ "$state" == "idle" ]]; then
            WAIT_RESULT="idle"
            log INFO "Idle confirmed via pattern poll (${waited}s)"
            return 0
        fi

        # Fallback: bare prompt with no activity indicators nearby
        local pane
        pane=$(tmux_capture)
        if [[ -n "$pane" ]] && echo "$pane" | tail -3 | grep -qE '^❯\s*$'; then
            if ! echo "$pane" | tail -8 | grep -qE '↑ [1-9][0-9]* tokens'; then
                WAIT_RESULT="idle"
                log INFO "Idle confirmed via prompt fallback (${waited}s)"
                return 0
            fi
        fi
    done

    WAIT_RESULT="timeout"
    return 0
}

# Legacy wrapper: check_busy_state (backward compat for any callers)
# Returns "busy", "idle", or "unknown". Always returns 0.
check_busy_state() {
    local pane
    pane=$(tmux_capture)
    local result
    result=$(_check_idle_pattern "$pane")

    case "$result" in
        idle)     echo "idle" ;;
        not_idle) echo "busy" ;;
        *)
            # Fallback: bare prompt check
            if [[ -n "$pane" ]] && echo "$pane" | tail -5 | grep -qE '❯\s*$|>\s*$'; then
                echo "idle"
            else
                echo "unknown"
            fi
            ;;
    esac
    return 0
}

# Legacy wrapper: check_jarvis_active delegates to detect_activity
check_jarvis_active() {
    detect_activity
}

# =============================================================================
# CONTEXT MONITORING
# =============================================================================

# Get context usage percentage from TUI status line
# Restricts to last 5 lines to avoid stale scroll buffer
get_context_percentage() {
    local pane
    pane=$(tmux_capture)

    if [[ -z "$pane" ]]; then
        echo "0"
        return 0
    fi

    local pct
    pct=$(echo "$pane" | tail -5 | grep -oE '[0-9]+%' | head -1 | tr -d '%' || true)

    if [[ -n "$pct" ]] && [[ "$pct" -gt 0 ]] && [[ "$pct" -le 100 ]]; then
        echo "$pct"
        return 0
    fi

    echo "0"
    return 0
}

# Get token count from TUI status line
get_token_count() {
    local pane
    pane=$(tmux_capture)

    if [[ -z "$pane" ]]; then
        echo "0"
        return 0
    fi

    # Try exact format first: "63257 tokens" or "63,257 tokens"
    local tokens
    tokens=$(echo "$pane" | tail -5 | grep -oE '[0-9,]+ tokens' | tail -1 | grep -oE '[0-9,]+' | tr -d ',' || true)

    # Range validation: 0 < N < 200001 (context window max is 200K tokens)
    if [[ -n "$tokens" ]] && [[ "$tokens" -gt 0 ]] && [[ "$tokens" -lt 200001 ]]; then
        echo "$tokens"
        return 0
    fi

    # Try abbreviated: "63.2k"
    local abbrev
    abbrev=$(echo "$pane" | tail -5 | grep -oE '[0-9]+\.?[0-9]*k' | head -1 || true)
    if [[ -n "$abbrev" ]]; then
        local num="${abbrev%k}"
        if [[ "$num" == *"."* ]]; then
            tokens=$(echo "$num * 1000" | bc 2>/dev/null | cut -d'.' -f1 || echo "0")
        else
            tokens=$((num * 1000))
        fi
        if [[ -n "$tokens" ]] && [[ "$tokens" -gt 0 ]] && [[ "$tokens" -lt 200001 ]]; then
            echo "$tokens"
            return 0
        fi
    fi

    echo "0"
    return 0
}

# =============================================================================
# EXPORT (before compression)
# =============================================================================

export_chat() {
    local reason="${1:-manual}"
    local ts
    ts=$(date +%Y%m%d-%H%M%S)
    local file="$EXPORTS_DIR/chat-${ts}-${reason}.txt"

    # Raw tmux capture (instant, always works)
    "$TMUX_BIN" capture-pane -t "$TMUX_TARGET" -p -S - > "$file" 2>/dev/null || true
    local lines
    lines=$(wc -l < "$file" 2>/dev/null | tr -d ' ' || echo "0")
    log INFO "Exported chat: $file (${lines} lines, reason: $reason)"

    # Send /export for Claude Code's richer format
    tmux_send_command "/export .claude/context/export_chat.txt"

    # Prune old exports (keep 20)
    local count
    count=$(ls -1 "$EXPORTS_DIR"/chat-*.txt 2>/dev/null | wc -l | tr -d ' ' || echo "0")
    if [[ "$count" -gt 20 ]]; then
        ls -1t "$EXPORTS_DIR"/chat-*.txt 2>/dev/null | tail -n +21 | xargs rm -f 2>/dev/null || true
    fi
}

# =============================================================================
# ARCHIVE (compressed context files)
# =============================================================================

archive_compressed_context() {
    local ts
    ts=$(date +%Y%m%d-%H%M%S)

    if [[ -f "$COMPRESSED_FILE" ]]; then
        mv "$COMPRESSED_FILE" "$ARCHIVE_DIR/compressed-${ts}.md" 2>/dev/null || rm -f "$COMPRESSED_FILE"
    fi

    # Prune old archives (keep 20)
    local count
    count=$(ls -1 "$ARCHIVE_DIR" 2>/dev/null | wc -l | tr -d ' ' || echo "0")
    if [[ "$count" -gt 20 ]]; then
        ls -1t "$ARCHIVE_DIR"/* 2>/dev/null | tail -n +21 | xargs rm -f 2>/dev/null || true
    fi
}

# =============================================================================
# METRICS / TELEMETRY (E5: cycle performance tracking)
# =============================================================================

emit_cycle_metrics() {
    local outcome="${1:-success}"
    local now
    now=$(date +%s)

    local total_time=0
    if [[ "$CYCLE_START_TIME" -gt 0 ]]; then
        total_time=$((now - CYCLE_START_TIME))
    fi

    local compress_time=0
    if [[ "$COMPRESS_START_TIME" -gt 0 ]] && [[ "$CLEAR_START_TIME" -gt 0 ]]; then
        compress_time=$((CLEAR_START_TIME - COMPRESS_START_TIME))
    fi

    local clear_time=0
    if [[ "$CLEAR_START_TIME" -gt 0 ]] && [[ "$RESTORE_START_TIME" -gt 0 ]]; then
        clear_time=$((RESTORE_START_TIME - CLEAR_START_TIME))
    fi

    local restore_time=0
    if [[ "$RESTORE_START_TIME" -gt 0 ]]; then
        restore_time=$((now - RESTORE_START_TIME))
    fi

    local halt_time=0
    if [[ "$CYCLE_START_TIME" -gt 0 ]] && [[ "$COMPRESS_START_TIME" -gt 0 ]]; then
        halt_time=$((COMPRESS_START_TIME - CYCLE_START_TIME))
    fi

    # Get current tokens for compression accuracy
    local end_tokens
    end_tokens=$(get_token_count)

    local within_target="false"
    if [[ "$end_tokens" -ge 5000 ]] && [[ "$end_tokens" -le 15000 ]]; then
        within_target="true"
    fi

    local ratio="0:1"
    if [[ "$end_tokens" -gt 0 ]] && [[ "$CYCLE_START_TOKENS" -gt 0 ]]; then
        ratio="$(echo "scale=1; $CYCLE_START_TOKENS / $end_tokens" | bc 2>/dev/null || echo "0"):1"
    fi

    # Emit JSONL metric record
    local ts_iso
    ts_iso=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    jq -nc \
        --arg ts "$ts_iso" \
        --arg outcome "$outcome" \
        --argjson cycle "$COMPRESSION_COUNT" \
        --argjson compress_time "$compress_time" \
        --argjson start_pct "$CYCLE_START_PCT" \
        --argjson start_tokens "$CYCLE_START_TOKENS" \
        --argjson end_tokens "$end_tokens" \
        --arg within_target "$within_target" \
        --arg ratio "$ratio" \
        --argjson halt_time "$halt_time" \
        --argjson clear_time "$clear_time" \
        --argjson restore_time "$restore_time" \
        --argjson restore_retries "$RESTORE_ATTEMPTS" \
        --argjson total_time "$total_time" \
        --argjson error_count "$ERROR_COUNT" \
        '{
            timestamp: $ts,
            event: "jicm_cycle_complete",
            cycle_number: $cycle,
            compression_time_s: $compress_time,
            start_pct: $start_pct,
            start_tokens: $start_tokens,
            end_tokens: $end_tokens,
            within_target: ($within_target == "true"),
            compression_ratio: $ratio,
            halt_time_s: $halt_time,
            clear_time_s: $clear_time,
            restore_time_s: $restore_time,
            restore_retries: $restore_retries,
            total_cycle_time_s: $total_time,
            outcome: $outcome,
            error_count: $error_count
        }' >> "$METRICS_FILE" 2>/dev/null || true

    log JICM "Metrics: ${total_time}s total (halt:${halt_time}s compress:${compress_time}s clear:${clear_time}s restore:${restore_time}s) outcome=$outcome"

    # Store last cycle summary for dashboard display
    LAST_CYCLE_SUMMARY="${total_time}s (h:${halt_time} c:${compress_time} cl:${clear_time} r:${restore_time}) ${outcome}"

    # Reset timing variables
    CYCLE_START_TIME=0
    COMPRESS_START_TIME=0
    CLEAR_START_TIME=0
    RESTORE_START_TIME=0
}

# =============================================================================
# STATE MACHINE TRANSITIONS
# =============================================================================

transition_to() {
    local new_state="$1"
    log STATE "$JICM_STATE → $new_state"
    JICM_STATE="$new_state"
    STATE_ENTERED_AT=$(date +%s)
    write_state
}

state_age() {
    local now
    now=$(date +%s)
    echo $((now - STATE_ENTERED_AT))
}

# =============================================================================
# HALTING: Stop Jarvis from working
# =============================================================================

do_halt() {
    local pct="$1"

    log JICM "Context at ${pct}% — halting Jarvis for compression"

    # Step 1: Escape (cancel pending input)
    tmux_send_escape
    sleep 0.3

    # Step 2: Send halt instruction
    # PROMPT DESIGN: Imperative, unambiguous, structured.
    # - Opens with STOP for immediate attention
    # - States the reason (context percentage)
    # - Gives explicit instruction (do not continue, do not ask)
    # - Requests minimal confirmation (reduces token waste)
    tmux_send_prompt "[JICM-HALT] STOP. Context at ${pct}%. JICM compression cycle starting. HALT all work immediately. Do NOT continue interrupted tasks. Do NOT ask questions. Reply ONLY: Understood. Then STOP."

    # Step 3: Wait for Jarvis to become idle
    wait_for_idle "$HALT_TIMEOUT"

    if [[ "$WAIT_RESULT" == "idle" ]]; then
        log JICM "Jarvis confirmed idle — proceeding to compression"
    else
        log WARN "Jarvis did not halt within ${HALT_TIMEOUT}s — forcing compression anyway"
    fi

    transition_to "COMPRESSING"
    do_compress
}

# =============================================================================
# COMPRESSING: Export context and spawn compression agent
# =============================================================================

do_compress() {
    COMPRESSION_COUNT=$((COMPRESSION_COUNT + 1))
    COMPRESS_START_TIME=$(date +%s)
    write_state  # Ensure state file reflects COMPRESSING immediately

    # Step 1: Export chat history
    log JICM "Exporting chat history..."
    export_chat "pre-compress"
    sleep 3

    # Step 2: Wait for idle after export
    wait_for_idle 30

    # Step 3: Spawn compression agent
    # PROMPT DESIGN: The spawn prompt must produce an exact Task tool call.
    # - Uses /intelligent-compress skill (pre-validated, handles flag+spawn+cleanup)
    # - Falls back to direct Task tool call if skill unavailable
    # - Requests minimal confirmation output
    log JICM "Spawning compression agent (#${COMPRESSION_COUNT})..."
    tmux_send_escape
    sleep 0.3

    local spawn_prompt="[JICM-COMPRESS] Run /intelligent-compress NOW. Do NOT update session files. Do NOT read additional files. After spawning, say ONLY: Compression spawned."
    tmux_send_prompt "$spawn_prompt"

    log JICM "Waiting for compression agent to finish..."
    # Polling for .compression-done.signal is handled in main loop
}

# =============================================================================
# CLEARING: Send /clear after compression completes
# =============================================================================

do_clear() {
    CLEAR_START_TIME=$(date +%s)
    log JICM "Compression complete — sending /clear"

    # Clean up compression signal
    rm -f "$COMPRESSION_SIGNAL"

    # Verify compressed context file exists
    if [[ ! -f "$COMPRESSED_FILE" ]]; then
        log ERROR "Compressed context file missing! Aborting /clear — reset to WATCHING"
        transition_to "WATCHING"
        COOLDOWN_UNTIL=$(( $(date +%s) + COOLDOWN_PERIOD ))
        ERROR_COUNT=$((ERROR_COUNT + 1))
        return 0
    fi

    # Send /clear
    tmux_send_command "/clear"

    transition_to "CLEARING"
}

# =============================================================================
# RESTORING: Send resume prompt after /clear confirms
# =============================================================================

do_restore() {
    RESTORE_ATTEMPTS=0
    RESTORE_START_TIME=$(date +%s)

    log JICM "Context cleared — restoring Jarvis"

    # Brief pause for session-start hook to inject additionalContext
    # The hook fires on /clear and injects compressed context via JSON
    sleep 5

    # PROMPT DESIGN: Restore prompt is action-forcing.
    # - [JICM-RESUME] tag signals this is a JICM continuation
    # - Explicitly tells Jarvis to read the checkpoint
    # - "Do NOT greet" prevents token-wasting pleasantries
    # - "Do NOT ask" prevents clarification loops
    local resume_prompt='[JICM-RESUME] Context compressed and cleared. Read .claude/context/.compressed-context-ready.md then CLAUDE.md then resume work immediately. Do NOT greet. Do NOT ask what to work on.'
    tmux_send_prompt "$resume_prompt"

    transition_to "RESTORING"
}

# =============================================================================
# RESTORE RETRY: If Jarvis doesn't respond
# =============================================================================

do_restore_retry() {
    RESTORE_ATTEMPTS=$((RESTORE_ATTEMPTS + 1))

    if [[ $RESTORE_ATTEMPTS -le 3 ]]; then
        # Retries 1-3: Progressively simpler prompts
        case $RESTORE_ATTEMPTS in
            1) tmux_send_prompt '[JICM-RESUME] Read .claude/context/.compressed-context-ready.md — continue work.' ;;
            2) tmux_send_prompt '[JICM-RESUME] Continue.' ;;
            3) tmux_send_prompt '.' ;;
        esac
        log JICM "Restore retry #${RESTORE_ATTEMPTS}"
    elif [[ $RESTORE_ATTEMPTS -le 6 ]]; then
        # Retries 4-6: Try alternate submit methods
        case $RESTORE_ATTEMPTS in
            4)
                tmux_send_text '[JICM-RESUME] Continue.'
                sleep 0.1
                "$TMUX_BIN" send-keys -t "$TMUX_TARGET" Enter 2>/dev/null || true
                ;;
            5)
                tmux_send_text '.'
                sleep 0.1
                "$TMUX_BIN" send-keys -t "$TMUX_TARGET" Enter 2>/dev/null || true
                ;;
            6)
                tmux_send_submit  # Just C-m (in case text is buffered)
                ;;
        esac
        log JICM "Restore retry #${RESTORE_ATTEMPTS} (alternate method)"
    else
        # After 6 retries, give up gracefully — user will see prompt
        log WARN "Restore failed after ${RESTORE_ATTEMPTS} attempts — leaving at prompt"
        archive_compressed_context
        transition_to "WATCHING"
        COOLDOWN_UNTIL=$(( $(date +%s) + COOLDOWN_PERIOD ))
        ERROR_COUNT=$((ERROR_COUNT + 1))
        return 0
    fi
}

# =============================================================================
# DASHBOARD
# =============================================================================

draw_progress_bar() {
    local pct=${1:-0}
    local width=20
    local filled=$(( pct * width / 100 ))
    local empty=$((width - filled))

    local bar=""
    local i
    for ((i=0; i<filled; i++)); do bar+="█"; done
    for ((i=0; i<empty; i++)); do bar+="░"; done

    # Color based on percentage
    if [[ $pct -ge $EMERGENCY_PCT ]]; then
        echo "${C_RED}${bar}${C_RESET}"
    elif [[ $pct -ge $JICM_THRESHOLD ]]; then
        echo "${C_YELLOW}${bar}${C_RESET}"
    else
        echo "${C_GREEN}${bar}${C_RESET}"
    fi
}

draw_state_indicator() {
    case "$JICM_STATE" in
        WATCHING)    echo "${C_GREEN}●${C_RESET} WATCHING" ;;
        HALTING)     echo "${C_YELLOW}◐${C_RESET} HALTING" ;;
        COMPRESSING) echo "${C_YELLOW}◑${C_RESET} COMPRESSING" ;;
        CLEARING)    echo "${C_BLUE}◒${C_RESET} CLEARING" ;;
        RESTORING)   echo "${C_CYAN}◓${C_RESET} RESTORING" ;;
        *)           echo "? $JICM_STATE" ;;
    esac
}

format_duration() {
    local secs=$1
    if [[ $secs -ge 3600 ]]; then
        echo "$((secs / 3600))h $((secs % 3600 / 60))m"
    elif [[ $secs -ge 60 ]]; then
        echo "$((secs / 60))m $((secs % 60))s"
    else
        echo "${secs}s"
    fi
}

# Activity log (circular buffer of last 5 events)
ACTIVITY_LOG=()
MAX_LOG_ENTRIES=5

log_activity() {
    local msg="$1"
    local ts
    ts=$(date +%H:%M:%S)
    ACTIVITY_LOG+=("${ts}  ${msg}")
    # Keep only last N entries
    while [[ ${#ACTIVITY_LOG[@]} -gt $MAX_LOG_ENTRIES ]]; do
        ACTIVITY_LOG=("${ACTIVITY_LOG[@]:1}")
    done
}

draw_dashboard() {
    local pct=${1:-0}
    local tokens=${2:-0}

    local session_duration=$(( $(date +%s) - SESSION_START_TIME ))
    local bar
    bar=$(draw_progress_bar "$pct")
    local state_ind
    state_ind=$(draw_state_indicator)
    local uptime
    uptime=$(format_duration "$session_duration")
    local ts
    ts=$(date +%H:%M:%S)

    # Move cursor up to overwrite previous dashboard (8 lines)
    if [[ ${DASHBOARD_DRAWN:-0} -gt 0 ]]; then
        printf '\e[8A'
    fi
    DASHBOARD_DRAWN=1

    # Last cycle display (show metrics if available)
    local cycle_info="${C_DIM}no cycles yet${C_RESET}"
    if [[ -n "$LAST_CYCLE_SUMMARY" ]]; then
        cycle_info="${C_GREEN}${LAST_CYCLE_SUMMARY}${C_RESET}"
    fi

    # Dashboard (8 lines)
    echo -e "${C_CYAN}╔══════════════════════════════════════════════════════╗${C_RESET}"
    echo -e "${C_CYAN}║${C_RESET}  ${C_BOLD}JICM v6.1${C_RESET}                        ${state_ind}  ${C_CYAN}║${C_RESET}"
    echo -e "${C_CYAN}╠══════════════════════════════════════════════════════╣${C_RESET}"
    echo -e "${C_CYAN}║${C_RESET}  Context: ${bar} ${pct}%%  ${tokens} tokens$(printf '%*s' $((14 - ${#tokens} - ${#pct})) '')${C_CYAN}║${C_RESET}"
    echo -e "${C_CYAN}║${C_RESET}  Threshold: ${C_YELLOW}${JICM_THRESHOLD}%${C_RESET}  Emergency: ${C_RED}${EMERGENCY_PCT}%${C_RESET}  Lockout: ~${LOCKOUT_PCT}%     ${C_CYAN}║${C_RESET}"
    echo -e "${C_CYAN}║${C_RESET}  Session: ${uptime}  Comps: ${COMPRESSION_COUNT}  Errs: ${ERROR_COUNT}  Poll: ${ts}  ${C_CYAN}║${C_RESET}"
    echo -e "${C_CYAN}║${C_RESET}  Last: ${cycle_info}$(printf '%*s' $((42 - ${#LAST_CYCLE_SUMMARY})) '' 2>/dev/null || true)${C_CYAN}║${C_RESET}"
    echo -e "${C_CYAN}╚══════════════════════════════════════════════════════╝${C_RESET}"

    # Log the activity
    log_activity "${pct}% (${tokens} tok)"
}

banner() {
    echo ""
    echo -e "${C_CYAN}╔══════════════════════════════════════════════════════╗${C_RESET}"
    echo -e "${C_CYAN}║${C_RESET}  ${C_BOLD}JICM v6.1 WATCHER${C_RESET} —  Stop-and-Wait Architecture     ${C_CYAN}║${C_RESET}"
    echo -e "${C_CYAN}╚══════════════════════════════════════════════════════╝${C_RESET}"
    echo -e "  threshold: ${C_YELLOW}${JICM_THRESHOLD}%${C_RESET}  emergency: ${C_RED}${EMERGENCY_PCT}%${C_RESET}  lockout: ~${LOCKOUT_PCT}%  interval: ${POLL_INTERVAL}s"
    echo ""
}

# =============================================================================
# CLEANUP & SIGNALS
# =============================================================================

cleanup() {
    local sig="${1:-unknown}"
    echo ""
    log INFO "Watcher shutting down (signal: $sig)"
    rm -f "$STATE_FILE"
    rm -f "$PID_FILE"
    exit 0
}

trap 'cleanup INT' INT
trap 'cleanup TERM' TERM
trap 'cleanup HUP' HUP

# =============================================================================
# MAIN LOOP
# =============================================================================

main() {
    banner

    if ! tmux_has_session; then
        log ERROR "tmux session '$TMUX_SESSION' not found"
        echo "Start with: .claude/scripts/launch-jarvis-tmux.sh"
        exit 1
    fi

    log INFO "JICM v6 Watcher started (threshold=${JICM_THRESHOLD}%, interval=${POLL_INTERVAL}s)"
    write_state

    local poll_count=0

    while true; do
        # Verify tmux session still exists
        if ! tmux_has_session; then
            log ERROR "tmux session lost — exiting"
            exit 1
        fi

        # ─── STATE: WATCHING ─────────────────────────────────────
        if [[ "$JICM_STATE" == "WATCHING" ]]; then
            local pct
            pct=$(get_context_percentage)
            local tokens
            tokens=$(get_token_count)

            # Track for state file and dashboard
            LAST_PCT="$pct"
            LAST_TOKENS="$tokens"

            poll_count=$((poll_count + 1))

            # Periodic log rotation (every 100 polls)
            if [[ $((poll_count % 100)) -eq 0 ]]; then
                rotate_log
            fi

            # Dashboard update
            if [[ "$pct" != "0" ]]; then
                draw_dashboard "$pct" "$tokens"
            elif [[ $((poll_count % 6)) -eq 0 ]]; then
                echo -e "$(date +%H:%M:%S) ${C_DIM}· Waiting for context data...${C_RESET}"
            fi

            # Check cooldown
            local now
            now=$(date +%s)
            if [[ $now -lt $COOLDOWN_UNTIL ]]; then
                if [[ $((poll_count % 12)) -eq 0 ]]; then
                    local remaining=$((COOLDOWN_UNTIL - now))
                    log INFO "Cooldown: ${remaining}s remaining"
                fi
                sleep "$POLL_INTERVAL"
                continue
            fi

            # JICM Sleep check — Ulfhedthnar suppresses JICM when active
            if [[ -f "$SLEEP_SIGNAL" ]]; then
                if [[ $((poll_count % 12)) -eq 0 ]]; then
                    log INFO "JICM sleeping — Ulfhedthnar active (threshold checks suspended)"
                fi
                write_state
                sleep "$POLL_INTERVAL"
                continue
            fi

            # JICM Exit-Mode check — /end-session suppresses JICM during exit protocol
            if [[ -f "$EXIT_SIGNAL" ]]; then
                if [[ $((poll_count % 12)) -eq 0 ]]; then
                    log INFO "JICM paused — exit protocol active (threshold checks suspended)"
                fi
                write_state
                sleep "$POLL_INTERVAL"
                continue
            fi

            # Emergency /compact (last resort before lockout)
            if [[ "$pct" -ge "$EMERGENCY_PCT" ]] && [[ "$pct" != "0" ]]; then
                log JICM "EMERGENCY: ${pct}% — sending /compact (lockout at ~${LOCKOUT_PCT}%)"
                tmux_send_command "/compact"
                COOLDOWN_UNTIL=$(( $(date +%s) + COOLDOWN_PERIOD ))
                ERROR_COUNT=$((ERROR_COUNT + 1))
                sleep "$POLL_INTERVAL"
                continue
            fi

            # Threshold check → start JICM cycle
            if [[ "$pct" -ge "$JICM_THRESHOLD" ]] && [[ "$pct" != "0" ]]; then
                log JICM "Threshold hit: ${pct}% >= ${JICM_THRESHOLD}%"
                # Metrics: record cycle start
                CYCLE_START_TIME=$(date +%s)
                CYCLE_START_PCT="$pct"
                CYCLE_START_TOKENS="$tokens"
                transition_to "HALTING"
                do_halt "$pct"
                # do_halt transitions to COMPRESSING; skip to next iteration
                sleep "$POLL_INTERVAL"
                continue
            fi

        # ─── STATE: HALTING (waiting for Jarvis to stop) ─────────
        elif [[ "$JICM_STATE" == "HALTING" ]]; then
            # HALTING is normally transient (handled in do_halt).
            # This handler catches the case where do_halt returned
            # without transitioning (shouldn't happen, but safety net).
            local age
            age=$(state_age)
            if [[ $age -ge $HALT_TIMEOUT ]]; then
                log WARN "Stuck in HALTING for ${age}s — forcing to COMPRESSING"
                transition_to "COMPRESSING"
                do_compress
            fi

        # ─── STATE: COMPRESSING (waiting for agent) ──────────────
        elif [[ "$JICM_STATE" == "COMPRESSING" ]]; then
            local age
            age=$(state_age)

            if [[ -f "$COMPRESSION_SIGNAL" ]]; then
                log JICM "Compression done signal detected (after ${age}s)"
                CLEAR_RETRIES=0
                do_clear
            elif [[ $age -ge $COMPRESS_TIMEOUT ]]; then
                log ERROR "Compression timeout after ${age}s — reset to WATCHING"
                emit_cycle_metrics "compress_timeout"
                rm -f "$COMPRESSION_SIGNAL"
                transition_to "WATCHING"
                COOLDOWN_UNTIL=$(( $(date +%s) + COOLDOWN_PERIOD ))
                ERROR_COUNT=$((ERROR_COUNT + 1))
            else
                # Show waiting status
                if [[ $((age % 15)) -lt "$POLL_INTERVAL" ]]; then
                    echo -e "$(date +%H:%M:%S) ${C_YELLOW}◑${C_RESET} Compression running... (${age}s)"
                fi
            fi

        # ─── STATE: CLEARING (waiting for /clear to take effect) ─
        elif [[ "$JICM_STATE" == "CLEARING" ]]; then
            local pct
            pct=$(get_context_percentage)
            local tokens
            tokens=$(get_token_count)
            local age
            age=$(state_age)

            # Clear detection: pct < 10% OR token count visible and < 5000
            # Also accept: pct=0 + age > 10s (TUI refreshed but shows nothing = cleared)
            local clear_confirmed=false
            if [[ "$pct" != "0" ]] && [[ "$pct" -lt 10 ]]; then
                clear_confirmed=true
            elif [[ "$tokens" != "0" ]] && [[ "$tokens" -lt 5000 ]]; then
                clear_confirmed=true
            elif [[ "$pct" == "0" ]] && [[ $age -ge 10 ]]; then
                # After 10s of no percentage data, assume clear worked
                clear_confirmed=true
            fi

            if [[ "$clear_confirmed" == "true" ]]; then
                log JICM "Clear confirmed (pct=${pct}%, tokens=${tokens}, age=${age}s)"
                do_restore
            elif [[ $age -ge $CLEAR_TIMEOUT ]]; then
                CLEAR_RETRIES=$((CLEAR_RETRIES + 1))
                if [[ $CLEAR_RETRIES -ge 2 ]]; then
                    log ERROR "Clear failed after ${CLEAR_RETRIES} retries — reset to WATCHING"
                    emit_cycle_metrics "clear_failed"
                    transition_to "WATCHING"
                    COOLDOWN_UNTIL=$(( $(date +%s) + COOLDOWN_PERIOD ))
                    ERROR_COUNT=$((ERROR_COUNT + 1))
                else
                    log WARN "Clear timeout after ${age}s — retry #${CLEAR_RETRIES}"
                    tmux_send_command "/clear"
                    STATE_ENTERED_AT=$(date +%s)  # Reset timer for retry
                fi
            fi

        # ─── STATE: RESTORING (waiting for Jarvis to wake up) ────
        elif [[ "$JICM_STATE" == "RESTORING" ]]; then
            local status
            status=$(check_jarvis_active)
            local age
            age=$(state_age)

            if [[ "$status" == "active" ]]; then
                log JICM "Jarvis is active — JICM cycle complete!"
                emit_cycle_metrics "success"
                archive_compressed_context
                transition_to "WATCHING"
            elif [[ $age -ge $RESTORE_TIMEOUT ]]; then
                log WARN "Restore timeout after ${age}s"
                emit_cycle_metrics "restore_timeout"
                archive_compressed_context
                transition_to "WATCHING"
                COOLDOWN_UNTIL=$(( $(date +%s) + COOLDOWN_PERIOD ))
                ERROR_COUNT=$((ERROR_COUNT + 1))
            elif [[ $((age % RESTORE_RETRY_DELAY)) -lt "$POLL_INTERVAL" ]] && [[ $age -ge "$RESTORE_RETRY_DELAY" ]]; then
                do_restore_retry
            fi
        fi

        sleep "$POLL_INTERVAL"
    done
}

# Run
main "$@"
