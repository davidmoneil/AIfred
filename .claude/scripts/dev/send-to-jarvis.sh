#!/bin/bash
# send-to-jarvis.sh — Send prompts to W0:Jarvis via tmux, optionally wait for idle
#
# Used by Jarvis-dev (W5) to inject prompts into the system-under-test (W0).
# Reuses the watcher's idle detection pattern for reliable wait-for-idle.
#
# Usage: send-to-jarvis.sh "prompt text" [--wait SEC] [--escape-first]
#        send-to-jarvis.sh --check-idle [--timeout SEC]
#
# Exit codes: 0=success/idle, 1=timeout/busy, 2=session-not-found
#
# Part of Jarvis dev-ops testing infrastructure.
set -euo pipefail

# ─── Configuration ──────────────────────────────────────────────────────────
TMUX_BIN="${TMUX_BIN:-$HOME/bin/tmux}"
SESSION="${TMUX_SESSION:-jarvis}"
TARGET="${SESSION}:0"
PROMPT_TEXT=""
WAIT_SEC=0
ESCAPE_FIRST=false
CHECK_IDLE=false
IDLE_TIMEOUT=30

# Idle detection pattern (matches watcher's ESC-triggered idle check)
IDLE_PATTERN='Interrupted.*What should Claude do'
# Fallback: bare prompt at end of visible pane
PROMPT_PATTERN='^❯[[:space:]]*$'

# ─── Colors (ANSI-C quoting) ───────────────────────────────────────────────
C_RESET=$'\e[0m'
C_GREEN=$'\e[32m'
C_RED=$'\e[31m'
C_YELLOW=$'\e[33m'
C_DIM=$'\e[2m'

# ─── Usage ──────────────────────────────────────────────────────────────────
show_usage() {
    cat <<EOF
send-to-jarvis.sh — Send prompts to W0:Jarvis via tmux

Usage:
  send-to-jarvis.sh "prompt text" [options]
  send-to-jarvis.sh --check-idle [--timeout SEC]

Options:
  "prompt text"       Text to send to Jarvis (W0)
  --wait SEC          Wait up to SEC seconds for idle after sending (default: 0)
  --escape-first      Send ESC before prompt (cancel pending input)
  --check-idle        Just check if W0 is idle (exit 0=idle, 1=busy)
  --timeout SEC       Timeout for idle check (default: 30)
  --target W:P        Override tmux target (default: \$TMUX_SESSION:0)
  -h, --help          Show this help

Exit codes:
  0  Success (prompt sent, or W0 is idle)
  1  Timeout (W0 didn't become idle in time) or W0 is busy
  2  Session not found
EOF
    exit 0
}

# ─── Argument Parsing ──────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
    case $1 in
        --wait)         WAIT_SEC="$2"; shift 2 ;;
        --escape-first) ESCAPE_FIRST=true; shift ;;
        --check-idle)   CHECK_IDLE=true; shift ;;
        --timeout)      IDLE_TIMEOUT="$2"; shift 2 ;;
        --target)       TARGET="$2"; shift 2 ;;
        -h|--help)      show_usage ;;
        -*)             echo "Unknown option: $1" >&2; exit 1 ;;
        *)
            if [[ -z "$PROMPT_TEXT" ]]; then
                PROMPT_TEXT="$1"
            fi
            shift ;;
    esac
done

# ─── Session Validation ───────────────────────────────────────────────────
validate_session() {
    if ! "$TMUX_BIN" has-session -t "$SESSION" 2>/dev/null; then
        echo "${C_RED}ERROR: tmux session '$SESSION' not found${C_RESET}" >&2
        exit 2
    fi
    return 0
}

# ─── Idle Detection ───────────────────────────────────────────────────────
# Capture last 5 lines of the target pane and check for idle indicators
is_idle() {
    local pane_output
    pane_output=$("$TMUX_BIN" capture-pane -t "$TARGET" -p 2>/dev/null) || return 1

    local last_lines
    last_lines=$(echo "$pane_output" | tail -5)

    # Check for ESC-triggered idle pattern
    if echo "$last_lines" | grep -qE "$IDLE_PATTERN"; then
        return 0
    fi

    # Fallback: bare ❯ prompt at end (no spinner/activity)
    local last_nonempty
    last_nonempty=$(echo "$pane_output" | sed '/^[[:space:]]*$/d' | tail -1)
    if echo "$last_nonempty" | grep -qE "$PROMPT_PATTERN"; then
        return 0
    fi

    return 1
}

# Wait for idle state, polling every 2s
wait_for_idle() {
    local timeout="${1:-$IDLE_TIMEOUT}"
    local waited=0

    while [[ $waited -lt $timeout ]]; do
        if is_idle; then
            return 0
        fi
        sleep 2
        waited=$((waited + 2))
    done

    return 1
}

# ─── Send Functions ───────────────────────────────────────────────────────
send_escape() {
    "$TMUX_BIN" send-keys -t "$TARGET" Escape
    sleep 0.5
    return 0
}

# Send prompt text via send-keys -l (literal) + C-m (enter)
# Uses single-line send-keys -l to avoid tmux input buffer corruption
send_prompt() {
    local text="$1"
    "$TMUX_BIN" send-keys -t "$TARGET" -l "$text"
    sleep 0.2
    "$TMUX_BIN" send-keys -t "$TARGET" C-m
    return 0
}

# ─── Main ──────────────────────────────────────────────────────────────────
validate_session

if [[ "$CHECK_IDLE" == "true" ]]; then
    # Just check idle status
    if is_idle; then
        echo "${C_GREEN}W0 is idle${C_RESET}"
        exit 0
    else
        # Try waiting if timeout specified
        if [[ $IDLE_TIMEOUT -gt 0 ]]; then
            echo "${C_DIM}Waiting for idle (timeout: ${IDLE_TIMEOUT}s)...${C_RESET}" >&2
            if wait_for_idle "$IDLE_TIMEOUT"; then
                echo "${C_GREEN}W0 is idle${C_RESET}"
                exit 0
            fi
        fi
        echo "${C_YELLOW}W0 is busy${C_RESET}"
        exit 1
    fi
fi

# Must have prompt text for send mode
if [[ -z "$PROMPT_TEXT" ]]; then
    echo "${C_RED}ERROR: No prompt text provided${C_RESET}" >&2
    echo "Usage: send-to-jarvis.sh \"prompt text\" [--wait SEC]" >&2
    exit 1
fi

# Send ESC first if requested
if [[ "$ESCAPE_FIRST" == "true" ]]; then
    send_escape
fi

# Send the prompt
echo "${C_DIM}Sending to $TARGET: ${PROMPT_TEXT:0:60}...${C_RESET}" >&2
send_prompt "$PROMPT_TEXT"

# Wait for idle if requested
if [[ $WAIT_SEC -gt 0 ]]; then
    echo "${C_DIM}Waiting for idle (timeout: ${WAIT_SEC}s)...${C_RESET}" >&2
    if wait_for_idle "$WAIT_SEC"; then
        echo "${C_GREEN}W0 returned to idle${C_RESET}"
        exit 0
    else
        echo "${C_YELLOW}Timeout: W0 still busy after ${WAIT_SEC}s${C_RESET}"
        exit 1
    fi
fi

exit 0
