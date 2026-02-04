#!/bin/bash
# ============================================================================
# JARVIS UNIFIED WATCHER — JICM v5.0.0
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
#
# Design: .claude/context/designs/jicm-v5-design-addendum.md
#
# Usage:
#   .claude/scripts/jarvis-watcher.sh [--threshold PCT]
#
# ============================================================================

set -euo pipefail

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

# Thresholds (JICM v5)
# Single 50% threshold for compression trigger
# See: jicm-v5-design-addendum.md Section 2.2
JICM_THRESHOLD=${JICM_THRESHOLD:-50}
DEFAULT_INTERVAL=30

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
            echo "JARVIS WATCHER v5.0.0 — JICM Two-Mechanism Resume"
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
# CONTEXT MONITORING (v4.0.0)
# =============================================================================

STATUSLINE_FILE="$HOME/.claude/logs/statusline-input.json"

get_context_status() {
    if [[ ! -f "$STATUSLINE_FILE" ]]; then
        echo '{"context_window": {"used_percentage": 0, "remaining_percentage": 100}}'
        return 1
    fi
    cat "$STATUSLINE_FILE"
}

get_used_percentage() {
    local status
    status=$(get_context_status 2>/dev/null)
    echo "$status" | jq -r '.context_window.used_percentage // 0' 2>/dev/null || echo "0"
}

get_token_count() {
    local status
    status=$(get_context_status 2>/dev/null)
    local input_tokens output_tokens
    input_tokens=$(echo "$status" | jq -r '.context_window.total_input_tokens // 0' 2>/dev/null || echo "0")
    output_tokens=$(echo "$status" | jq -r '.context_window.total_output_tokens // 0' 2>/dev/null || echo "0")
    echo $((input_tokens + output_tokens))
}

update_status() {
    local tokens="$1"
    local pct="$2"
    local state="$3"
    cat > "$STATUS_FILE" <<EOF
timestamp: $(date -u +%Y-%m-%dT%H:%M:%SZ)
version: 5.0.0
tokens: $tokens
percentage: $pct%
threshold: $JICM_THRESHOLD%
state: $state
trigger_count: $TRIGGER_COUNT
failure_count: $FAILURE_COUNT
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
    ((FAILURE_COUNT++))
    if [[ $FAILURE_COUNT -ge $FAILURES_BEFORE_STANDDOWN ]]; then
        enter_standdown "Too many failures ($FAILURE_COUNT)"
    fi
}

reset_failure_count() {
    FAILURE_COUNT=0
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
    "compression_target": "10000-30000"
}
EOF

    JICM_STATE="compression_spawned"
    JICM_LAST_TRIGGER=$(date +%s)
    ((TRIGGER_COUNT++))

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
        if echo "$pane_content" | tail -10 | grep -qiE 'context restored|continuing|reading|writing|understood|resuming'; then
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
    if echo "$pane_content" | grep -qiE 'context restored|continuing|reading|writing|understood|resuming'; then
        return 0  # Success - Jarvis responded
    fi

    return 1  # Not yet successful
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

        ((cycle++))
        sleep $cycle_delay
    done

    log WARN "IDLE-HANDS: Max cycles reached without confirmed success"
    # Don't remove flag - leave for debugging
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
    ((TRIGGER_COUNT++))
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
    echo -e "${CYAN}━━━ JARVIS WATCHER v5.0 ━━━${NC} threshold:${JICM_THRESHOLD}% interval:${INTERVAL}s"
    echo -e "${GREEN}●${NC} Context ${GREEN}●${NC} JICM v5 ${GREEN}●${NC} Idle-Hands Monitor │ Ctrl+C to stop"
    echo ""
}

cleanup() {
    echo ""
    log INFO "Watcher shutting down..."
    rm -f "$STATUS_FILE"
    rm -f "$PID_FILE"
    exit 0
}

trap cleanup INT TERM

main() {
    banner

    if ! "$TMUX_BIN" has-session -t "$TMUX_SESSION" 2>/dev/null; then
        log ERROR "tmux session '$TMUX_SESSION' not found"
        echo "Start Jarvis with: .claude/scripts/launch-jarvis-tmux.sh"
        exit 1
    fi

    log INFO "Watcher started (JICM v5.0.0)"

    local last_tokens=0
    local poll_count=0
    local compression_wait_start=0

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
        # 1.5 Check for manual /intelligent-compress completion
        # ─────────────────────────────────────────────────────────────
        # This handles the case where user runs /intelligent-compress directly
        # which creates .compression-done.signal without setting JICM_STATE
        if [[ "$JICM_STATE" == "monitoring" ]] && [[ -f "$COMPRESSION_DONE_SIGNAL" ]]; then
            log JICM "Detected manual compression completion signal"
            check_debounce && check_trigger_limit
            if [[ $? -eq 0 ]]; then
                JICM_LAST_TRIGGER=$(date +%s)
                ((TRIGGER_COUNT++))
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
                JICM_STATE="cleared"
                # Let session-start.sh handle continuation injection
                sleep 5
                JICM_STATE="monitoring"
                reset_failure_count
                log JICM "Manual compression cycle complete"
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
            ((poll_count++))
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

        update_status "$tokens" "$pct" "$JICM_STATE"

        # Display status
        if [[ "$tokens" != "$last_tokens" ]]; then
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

            echo -e "$(date +%H:%M:%S) ${color}${symbol}${NC} ${tokens} tokens (${pct}%) [$JICM_STATE]"
            last_tokens=$tokens
        fi

        # ─────────────────────────────────────────────────────────────
        # 5. Threshold check (JICM v5 - single 50% threshold)
        # ─────────────────────────────────────────────────────────────
        if [[ "$JICM_STATE" == "monitoring" ]]; then
            # Check debounce
            if check_debounce && check_trigger_limit; then
                # Single threshold: Trigger /intelligent-compress
                if [[ $pct_int -ge $JICM_THRESHOLD ]]; then
                    log JICM "═══ JICM v5: Context at ${pct}% - triggering compression ═══"
                    wait_for_idle 30 || log WARN "Idle timeout, proceeding anyway"
                    send_command "/intelligent-compress"
                    JICM_STATE="compression_triggered"
                    JICM_LAST_TRIGGER=$(date +%s)
                    ((TRIGGER_COUNT++))
                fi
            fi
        fi

        # ─────────────────────────────────────────────────────────────
        # 6. Reset after JICM cycle completes
        # ─────────────────────────────────────────────────────────────
        if [[ "$JICM_STATE" == "resumed" ]] || [[ "$JICM_STATE" == "enforced" ]] || [[ "$JICM_STATE" == "compression_triggered" ]]; then
            local now
            now=$(date +%s)
            local elapsed=$((now - JICM_LAST_TRIGGER))

            # Reset after cooldown or if context is low
            if [[ $elapsed -gt $DEBOUNCE_SECONDS ]] || [[ $pct_int -lt 30 ]]; then
                log INFO "JICM cycle complete, returning to monitoring"
                cleanup_jicm_signals_only
                JICM_STATE="monitoring"
            fi
        fi

        ((poll_count++))
        sleep "$INTERVAL"
    done
}

# Run main
main
