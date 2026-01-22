#!/bin/bash
# ============================================================================
# JARVIS UNIFIED WATCHER
# ============================================================================
# Single watcher script that handles:
#   1. Context monitoring (poll status line for token count)
#   2. Command signal execution (watch for signal files, send keystrokes)
#   3. JICM workflow coordination (trigger /context → /clear sequence)
#
# Usage:
#   .claude/scripts/jarvis-watcher.sh [--threshold PCT] [--interval SEC]
#
# Environment:
#   TMUX_BIN        - Path to tmux binary (default: $HOME/bin/tmux)
#   TMUX_SESSION    - tmux session name (default: jarvis)
#   CLAUDE_PROJECT_DIR - Project directory (default: $HOME/Claude/Jarvis)
#
# ============================================================================

set -euo pipefail

# =============================================================================
# CONFIGURATION
# =============================================================================

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$HOME/Claude/Jarvis}"
TMUX_BIN="${TMUX_BIN:-$HOME/bin/tmux}"
TMUX_SESSION="${TMUX_SESSION:-jarvis}"

# Target the main Claude Code window (window 0), not the whole session
# This ensures commands go to Claude Code even if watcher runs in window 1
TMUX_TARGET="${TMUX_SESSION}:0"

# Paths
SIGNAL_FILE="$PROJECT_DIR/.claude/context/.command-signal"
JICM_TRIGGER_FILE="$PROJECT_DIR/.claude/context/.jicm-trigger"
CONTEXT_READY_FILE="$PROJECT_DIR/.claude/context/.context-ready"
LOG_FILE="$PROJECT_DIR/.claude/logs/jarvis-watcher.log"
STATUS_FILE="$PROJECT_DIR/.claude/context/.watcher-status"

# Thresholds
# DEFAULT_THRESHOLD: 80% = 144000/180000 effective context (aligned with autonomy-config.yaml)
# JICM triggers at 80% to allow graceful compression before native auto-compact (99%)
DEFAULT_THRESHOLD=80
DEFAULT_INTERVAL=30
MAX_CONTEXT_TOKENS=200000
MAX_OUTPUT_TOKENS=20000  # Matches CLAUDE_CODE_MAX_OUTPUT_TOKENS

# Idle detection settings
IDLE_CHECK_INTERVAL=2     # Seconds between idle checks
IDLE_REQUIRED_CYCLES=3    # Number of stable cycles to confirm idle
IDLE_TIMEOUT=120          # Maximum seconds to wait for idle state

# Parse arguments
THRESHOLD=$DEFAULT_THRESHOLD
INTERVAL=$DEFAULT_INTERVAL
while [[ $# -gt 0 ]]; do
    case $1 in
        --threshold) THRESHOLD="$2"; shift 2 ;;
        --interval) INTERVAL="$2"; shift 2 ;;
        -h|--help)
            echo "Usage: $0 [--threshold PCT] [--interval SEC]"
            echo "  --threshold  Context threshold percentage (default: $DEFAULT_THRESHOLD)"
            echo "  --interval   Poll interval in seconds (default: $DEFAULT_INTERVAL)"
            exit 0
            ;;
        *) shift ;;
    esac
done

# Supported commands whitelist
# Updated 2026-01-21: Added /statusline
SUPPORTED_COMMANDS=(
    "/compact" "/rename" "/resume" "/export" "/doctor"
    "/status" "/usage" "/cost" "/bashes" "/review"
    "/plan" "/security-review" "/stats" "/todos" "/context"
    "/hooks" "/release-notes" "/clear" "/statusline"
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

# Write PID file for watcher detection
PID_FILE="$PROJECT_DIR/.claude/context/.watcher-pid"
echo $$ > "$PID_FILE"
mkdir -p "$(dirname "$STATUS_FILE")"
mkdir -p "$(dirname "$SIGNAL_FILE")"

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
# CONTEXT MONITORING
# =============================================================================

get_token_count() {
    local pane_content
    pane_content=$("$TMUX_BIN" capture-pane -t "$TMUX_TARGET" -p 2>/dev/null || echo "")

    # Extract token count from status line (format: "120916 tokens" or "120,916 tokens")
    local token_line
    token_line=$(echo "$pane_content" | grep -oE '[0-9,]+ tokens' | tail -1 || true)

    if [[ -n "$token_line" ]]; then
        echo "$token_line" | tr -d ', tokens'
    else
        echo "0"
    fi
}

calc_percentage() {
    local tokens="$1"
    if [[ "$tokens" -gt 0 ]]; then
        echo "scale=1; ($tokens * 100) / $MAX_CONTEXT_TOKENS" | bc 2>/dev/null || echo "0"
    else
        echo "0"
    fi
}

update_status() {
    local tokens="$1"
    local pct="$2"
    local state="$3"

    cat > "$STATUS_FILE" <<EOF
# Jarvis Watcher Status
timestamp: $(date -u +%Y-%m-%dT%H:%M:%SZ)
tokens: $tokens
percentage: $pct%
threshold: $THRESHOLD%
state: $state
max_context: $MAX_CONTEXT_TOKENS
EOF
}

# Write poll data to context-estimate.json (replaces context-accumulator.js)
update_context_estimate() {
    local tokens="$1"
    local pct="$2"
    local estimate_file="$PROJECT_DIR/.claude/logs/context-estimate.json"

    mkdir -p "$(dirname "$estimate_file")"

    cat > "$estimate_file" <<EOF
{
  "sessionStart": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "totalTokens": $tokens,
  "actualTokens": $tokens,
  "toolCalls": 0,
  "lastUpdate": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "percentage": $pct,
  "source": "jarvis-watcher"
}
EOF
}

# =============================================================================
# IDLE DETECTION
# =============================================================================

# Check if Claude is currently processing (has spinner or is mid-response)
is_claude_busy() {
    local pane_content
    pane_content=$("$TMUX_BIN" capture-pane -t "$TMUX_TARGET" -p 2>/dev/null || echo "")

    # Look for spinner characters or "Thinking" indicators
    # Common spinner chars: ⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏ ◐◓◑◒ ▁▂▃▄▅▆▇█
    if echo "$pane_content" | grep -qE '[⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏◐◓◑◒▁▂▃▄▅▆▇]|Thinking|thinking|Processing|⣾⣽⣻⢿⡿⣟⣯⣷'; then
        return 0  # Busy
    fi

    # Check for "Cooked for" or duration indicator (Claude finished a turn)
    if echo "$pane_content" | tail -5 | grep -qE 'Cooked for|tokens|>'; then
        return 1  # Not busy (showing prompt or completion message)
    fi

    # Default: assume not busy
    return 1
}

# Wait for Claude to become idle before triggering JICM
wait_for_idle() {
    local stable_count=0
    local wait_count=0

    log INFO "Waiting for idle state before JICM trigger..."

    while [[ $wait_count -lt $IDLE_TIMEOUT ]]; do
        if is_claude_busy; then
            stable_count=0
            if [[ $((wait_count % 10)) -eq 0 ]]; then
                log INFO "  Claude is busy, waiting... (${wait_count}s)"
            fi
        else
            ((stable_count++))
            if [[ $stable_count -ge $IDLE_REQUIRED_CYCLES ]]; then
                log INFO "  Idle state confirmed after ${wait_count}s"
                return 0
            fi
        fi

        sleep "$IDLE_CHECK_INTERVAL"
        ((wait_count += IDLE_CHECK_INTERVAL))
    done

    log WARN "Idle timeout after ${IDLE_TIMEOUT}s - proceeding anyway"
    return 1
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
    # Send command text as literal (no key parsing), then Enter separately
    # Using C-m (Ctrl+M = carriage return) instead of Enter keyword for reliability
    "$TMUX_BIN" send-keys -t "$TMUX_TARGET" -l "$full_command"
    sleep 0.1  # Brief delay to ensure text is rendered
    "$TMUX_BIN" send-keys -t "$TMUX_TARGET" C-m
    return 0
}

process_signal_file() {
    if [[ ! -f "$SIGNAL_FILE" ]]; then
        return 1
    fi

    # Read and parse signal
    local signal_content
    signal_content=$(cat "$SIGNAL_FILE")

    local command args source auto_resume resume_delay resume_message
    command=$(echo "$signal_content" | jq -r '.command // empty' 2>/dev/null || echo "")
    args=$(echo "$signal_content" | jq -r '.args // empty' 2>/dev/null || echo "")
    source=$(echo "$signal_content" | jq -r '.source // "unknown"' 2>/dev/null || echo "unknown")
    auto_resume=$(echo "$signal_content" | jq -r '.auto_resume // false' 2>/dev/null || echo "false")
    resume_delay=$(echo "$signal_content" | jq -r '.resume_delay // 3' 2>/dev/null || echo "3")
    resume_message=$(echo "$signal_content" | jq -r '.resume_message // "continue"' 2>/dev/null || echo "continue")

    if [[ -z "$command" ]]; then
        log WARN "Invalid signal file (no command)"
        rm -f "$SIGNAL_FILE"
        return 1
    fi

    # Validate command
    if ! is_valid_command "$command"; then
        log WARN "Command not in whitelist: $command"
        rm -f "$SIGNAL_FILE"
        return 1
    fi

    log INFO "Processing signal: $command from $source (auto_resume=$auto_resume)"

    # Remove signal file before executing
    rm -f "$SIGNAL_FILE"

    # Execute command
    send_command "$command" "$args"

    # Handle auto-resume if requested
    if [[ "$auto_resume" == "true" ]]; then
        log INFO "Auto-resume enabled, waiting ${resume_delay}s then sending: $resume_message"
        sleep "$resume_delay"
        send_command "$resume_message" ""
    fi

    return 0
}

# =============================================================================
# JICM WORKFLOW
# =============================================================================

# State tracking for JICM
JICM_STATE="monitoring"  # monitoring | triggered | awaiting_context | compacting | clearing

trigger_jicm() {
    local tokens="$1"
    local pct="$2"

    log JICM "═══ JICM TRIGGERED: $pct% ($tokens tokens) ═══"

    JICM_STATE="triggered"

    # Create trigger file for hooks to detect
    cat > "$JICM_TRIGGER_FILE" <<EOF
timestamp: $(date -u +%Y-%m-%dT%H:%M:%SZ)
tokens: $tokens
percentage: $pct
threshold: $THRESHOLD
reason: automatic_threshold
EOF

    # Step 0: Wait for Claude to become idle (graceful completion)
    # This ensures current task completes before compression starts
    log JICM "Step 0: Waiting for idle state (graceful completion)"
    JICM_STATE="waiting_idle"
    wait_for_idle

    # Step 1: Send /intelligent-compress for AI-powered context compression
    # This invokes the skill which updates session-state, priorities, and compressed-context
    log JICM "Step 1: /intelligent-compress (AI compression)"
    send_command "/intelligent-compress"
    JICM_STATE="compressing"

    # Step 2: Wait for intelligent compression to complete
    # The command will create .clear-ready-signal when done
    log JICM "Step 2: Waiting for compression (max 60s)..."
    local wait_count=0
    local max_wait=60
    while [[ ! -f "$PROJECT_DIR/.claude/context/.clear-ready-signal" ]] && [[ $wait_count -lt $max_wait ]]; do
        sleep 1
        ((wait_count++))
        if [[ $((wait_count % 10)) -eq 0 ]]; then
            log JICM "  Still waiting for compression... (${wait_count}s)"
        fi
    done

    if [[ -f "$PROJECT_DIR/.claude/context/.clear-ready-signal" ]]; then
        log JICM "Step 3: Compression complete, sending /clear"
        rm -f "$PROJECT_DIR/.claude/context/.clear-ready-signal"
        send_command "/clear"
        JICM_STATE="cleared"

        # Step 4: Wait for SessionStart hook to process, then trigger resume
        # The SessionStart hook will inject compressed context via additionalContext
        sleep 3  # Wait for /clear and hook processing
        log JICM "Step 4: Triggering work continuation"
        # This message triggers Jarvis to read session files and continue
        send_command "Resume work from the compressed context. Read session-state.md and current-priorities.md, then continue the task that was in progress."
        JICM_STATE="resumed"
    else
        # Timeout - fall back to simple checkpoint
        log JICM "Step 3: Compression timeout, falling back to simple checkpoint"
        create_watcher_checkpoint "$tokens" "$pct"
        send_command "/clear"
        JICM_STATE="cleared_fallback"

        # Step 4: Send continuation prompt to trigger context restoration
        sleep 3
        log JICM "Step 4: Triggering work continuation (fallback)"
        send_command "Resume work from checkpoint. Read session-state.md and current-priorities.md, then continue the task that was in progress."
        JICM_STATE="resumed"
    fi
}

create_watcher_checkpoint() {
    local tokens="$1"
    local pct="$2"
    local checkpoint_file="$PROJECT_DIR/.claude/context/.soft-restart-checkpoint.md"

    cat > "$checkpoint_file" <<EOF
# JICM Watcher Checkpoint

**Created**: $(date -u +%Y-%m-%dT%H:%M:%SZ)
**Reason**: Watcher-triggered at $pct% context ($tokens tokens)
**Threshold**: $THRESHOLD%

## Context at Checkpoint

The watcher detected context usage above threshold and triggered this checkpoint.
/context was run to show the breakdown before clearing.

## Continuation Instructions

1. Review session-state.md for current work status
2. Check current-priorities.md for active tasks
3. Continue from where work was interrupted

## JICM Info

- Tokens at trigger: $tokens
- Percentage: $pct%
- Threshold: $THRESHOLD%
- Source: jarvis-watcher.sh
EOF
}

check_for_clear_signal() {
    # Check if Claude has signaled that it's ready for /clear
    # Supports both signal file names:
    #   .auto-clear-signal - legacy/fallback flows
    #   .clear-ready-signal - /intelligent-compress manual invocation
    local signal_found=false

    if [[ -f "$PROJECT_DIR/.claude/context/.auto-clear-signal" ]]; then
        log JICM "Clear signal detected (.auto-clear-signal) - sending /clear"
        rm -f "$PROJECT_DIR/.claude/context/.auto-clear-signal"
        signal_found=true
    elif [[ -f "$PROJECT_DIR/.claude/context/.clear-ready-signal" ]]; then
        log JICM "Clear signal detected (.clear-ready-signal) - sending /clear"
        rm -f "$PROJECT_DIR/.claude/context/.clear-ready-signal"
        signal_found=true
    fi

    if [[ "$signal_found" == "true" ]]; then
        sleep 1  # Brief pause
        send_command "/clear"
        JICM_STATE="clearing"
        return 0
    fi
    return 1
}

# =============================================================================
# MAIN LOOP
# =============================================================================

banner() {
    # Compact 3-line banner for 12-line pane
    echo -e "${CYAN}━━━ JARVIS WATCHER v2.0 ━━━${NC} threshold:${THRESHOLD}% interval:${INTERVAL}s"
    echo -e "${GREEN}●${NC} Context ${GREEN}●${NC} Commands ${GREEN}●${NC} JICM │ Ctrl+C to stop"
    echo ""
}

cleanup() {
    echo ""
    log INFO "Watcher shutting down..."
    rm -f "$STATUS_FILE"
    exit 0
}

trap cleanup INT TERM

main() {
    banner

    # Check tmux session exists
    if ! "$TMUX_BIN" has-session -t "$TMUX_SESSION" 2>/dev/null; then
        log ERROR "tmux session '$TMUX_SESSION' not found"
        echo "Start Jarvis with: .claude/scripts/launch-jarvis-tmux.sh"
        exit 1
    fi

    log INFO "Watcher started"

    local jicm_triggered=false
    local last_tokens=0
    local poll_count=0

    while true; do
        # ─────────────────────────────────────────────────────────────
        # 1. Check for command signals (highest priority)
        # ─────────────────────────────────────────────────────────────
        if process_signal_file; then
            sleep 1  # Brief pause after executing command
        fi

        # ─────────────────────────────────────────────────────────────
        # 2. Check for clear signal from JICM workflow
        # ─────────────────────────────────────────────────────────────
        if check_for_clear_signal; then
            jicm_triggered=false
            JICM_STATE="monitoring"
            sleep 2
            continue
        fi

        # ─────────────────────────────────────────────────────────────
        # 3. Context monitoring
        # ─────────────────────────────────────────────────────────────
        local tokens
        tokens=$(get_token_count)

        if [[ "$tokens" == "0" ]]; then
            # Could not read tokens - might be between commands
            ((poll_count++))
            if [[ $((poll_count % 6)) -eq 0 ]]; then
                echo -e "$(date +%H:%M:%S) ${YELLOW}·${NC} Waiting for token count..."
            fi
            sleep "$INTERVAL"
            continue
        fi

        local pct
        pct=$(calc_percentage "$tokens")
        local pct_int
        pct_int=$(echo "$pct" | cut -d'.' -f1)

        # Update status file and context estimate (replaces context-accumulator.js)
        update_status "$tokens" "$pct" "$JICM_STATE"
        update_context_estimate "$tokens" "$pct"

        # Display status (only if changed significantly)
        if [[ "$tokens" != "$last_tokens" ]]; then
            local color="$GREEN"
            local symbol="●"

            if [[ $pct_int -ge $THRESHOLD ]]; then
                color="$RED"
                symbol="⚠"
            elif [[ $pct_int -ge $((THRESHOLD - 15)) ]]; then
                color="$YELLOW"
                symbol="◐"
            fi

            echo -e "$(date +%H:%M:%S) ${color}${symbol}${NC} Tokens: ${tokens} (${pct}%) [$JICM_STATE]"
            last_tokens=$tokens
        fi

        # ─────────────────────────────────────────────────────────────
        # 4. JICM threshold check
        # ─────────────────────────────────────────────────────────────
        if [[ $pct_int -ge $THRESHOLD ]] && [[ "$jicm_triggered" == "false" ]]; then
            trigger_jicm "$tokens" "$pct"
            jicm_triggered=true
        fi

        # Reset trigger after JICM completes and context drops below 50%
        # (Old logic: pct < threshold-20 was impossible with low thresholds like 20%)
        # New logic: After successful JICM (state=resumed), reset when context < 50%
        # This allows JICM to re-trigger when context builds up again
        if [[ "$jicm_triggered" == "true" ]] && [[ "$JICM_STATE" == "resumed" ]] && [[ $pct_int -lt 50 ]]; then
            log INFO "Resetting JICM trigger (context at ${pct_int}% after successful completion)"
            jicm_triggered=false
            JICM_STATE="monitoring"
        fi

        ((poll_count++))
        sleep "$INTERVAL"
    done
}

# Run main
main
