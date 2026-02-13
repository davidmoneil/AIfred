#!/bin/bash
# time-compact.sh — Time the native /compact command on W0:Jarvis
#
# Sends /compact to W0 via tmux, polls for completion (idle prompt reappears
# + context % drops), outputs JSON timing data.
#
# Usage: time-compact.sh [--timeout SEC] [--poll-interval SEC] [--output FILE]
#
# Exit codes: 0=success, 1=error, 2=session-not-found, 3=timeout
#
# Part of compression timing experiment infrastructure.
set -euo pipefail

# ─── Configuration ──────────────────────────────────────────────────────────
TMUX_BIN="${TMUX_BIN:-$HOME/bin/tmux}"
SESSION="${TMUX_SESSION:-jarvis}"
TARGET="${SESSION}:0"
TIMEOUT=600          # 10 minutes max wait
POLL_INTERVAL=2      # Poll every 2 seconds
OUTPUT_FILE=""       # Append JSON to this file
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$HOME/Claude/Jarvis}"

# ─── Usage ──────────────────────────────────────────────────────────────────
show_usage() {
    cat <<EOF
time-compact.sh — Time native /compact on W0:Jarvis

Usage: time-compact.sh [options]

Options:
  --timeout SEC         Max wait time (default: 600)
  --poll-interval SEC   Polling frequency (default: 2)
  --output FILE         Append JSON result to file
  -h, --help            Show this help

Output (JSON):
  { "treatment": "compact", "start_s": EPOCH, "end_s": EPOCH,
    "duration_s": N, "start_pct": N, "end_pct": N,
    "start_tokens": N, "end_tokens": N, "outcome": "success|timeout",
    "timestamp": "ISO-8601" }
EOF
    exit 0
}

# ─── Argument Parsing ──────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
    case $1 in
        --timeout)       TIMEOUT="$2"; shift 2 ;;
        --poll-interval) POLL_INTERVAL="$2"; shift 2 ;;
        --output)        OUTPUT_FILE="$2"; shift 2 ;;
        -h|--help)       show_usage ;;
        *)               shift ;;
    esac
done

# ─── Session Validation ───────────────────────────────────────────────────
if ! "$TMUX_BIN" has-session -t "$SESSION" 2>/dev/null; then
    echo "ERROR: tmux session '$SESSION' not found" >&2
    exit 2
fi

# ─── Helper Functions ─────────────────────────────────────────────────────

tmux_capture() {
    "$TMUX_BIN" capture-pane -t "$TARGET" -p 2>/dev/null || true
}

get_context_pct() {
    local pane
    pane=$(tmux_capture)
    if [[ -z "$pane" ]]; then
        echo "0"
        return 0
    fi
    local pct
    pct=$(echo "$pane" | tail -10 | grep -oE '[0-9]+%' | head -1 | tr -d '%' || true)
    if [[ -n "$pct" ]] && [[ "$pct" -gt 0 ]] && [[ "$pct" -le 100 ]]; then
        echo "$pct"
    else
        echo "0"
    fi
    return 0
}

get_token_count() {
    local pane
    pane=$(tmux_capture)
    if [[ -z "$pane" ]]; then
        echo "0"
        return 0
    fi
    local tokens
    tokens=$(echo "$pane" | tail -10 | grep -oE '[0-9,]+ tokens' | tail -1 | grep -oE '[0-9,]+' | tr -d ',' || true)
    if [[ -n "$tokens" ]] && [[ "$tokens" -gt 0 ]] && [[ "$tokens" -lt 200001 ]]; then
        echo "$tokens"
    else
        echo "0"
    fi
    return 0
}

is_idle() {
    local pane
    pane=$(tmux_capture)
    # Look for the ❯ prompt in the last 10 non-empty lines
    # (CC notifications like "Context left until auto-compact" add extra bottom lines)
    local last_lines
    last_lines=$(echo "$pane" | grep -v '^$' | tail -10)
    echo "$last_lines" | grep -q '❯' && return 0 || return 1
}

compaction_detected() {
    # Detect /compact completion via pane text signals:
    #   1. "CONTEXT RESTORED (compact)" from session-start hook
    #   2. "compact" followed by idle in recent output
    # Note: ⚡[C] statusline flag persists across /clear — NOT reliable for
    # detecting new compactions. Only text-based detection is used.
    local pane
    pane=$(tmux_capture)
    local tail_output
    tail_output=$(echo "$pane" | tail -15)

    # Check for "CONTEXT RESTORED (compact)" from session-start hook
    # Specifically "(compact)" to distinguish from "(clear)"
    if echo "$tail_output" | grep -q 'CONTEXT RESTORED (compact)'; then
        return 0
    fi
    return 1
}

# ─── Pre-flight: Ensure W0 is idle ───────────────────────────────────────
if ! is_idle; then
    echo "WARNING: W0 does not appear idle — waiting 10s..." >&2
    sleep 10
    if ! is_idle; then
        echo "ERROR: W0 still not idle. Aborting." >&2
        exit 1
    fi
fi

# Extra quiescence wait — the idle prompt (❯) can appear while CC is still
# finalizing the previous turn. Wait additional time to ensure the command
# parser is truly ready to intercept slash commands.
echo "W0 idle — waiting 5s for quiescence before sending /compact..." >&2
sleep 5

# Verify still idle after quiescence wait
if ! is_idle; then
    echo "WARNING: W0 became busy during quiescence wait — waiting 15s..." >&2
    sleep 15
    if ! is_idle; then
        echo "ERROR: W0 not idle after extended wait. Aborting." >&2
        exit 1
    fi
fi

# ─── Record Baseline ─────────────────────────────────────────────────────
START_PCT=$(get_context_pct)
START_TOKENS=$(get_token_count)
START_TIME=$(date +%s)
TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)

echo "Starting /compact at ${START_PCT}% (${START_TOKENS} tokens)..." >&2

# ─── Send /compact ───────────────────────────────────────────────────────
# Harden the command delivery to prevent CC from buffering it as model input:
#   1. Escape — cancel any pending input or selection
#   2. Ctrl-U — clear the input line
#   3. Brief pause for CC to process the clear
#   4. Type /compact
#   5. Brief pause — let CC's command parser see the complete slash command
#   6. Enter — submit
"$TMUX_BIN" send-keys -t "$TARGET" Escape
sleep 0.2
"$TMUX_BIN" send-keys -t "$TARGET" C-u
sleep 0.3
"$TMUX_BIN" send-keys -t "$TARGET" -l "/compact"
sleep 0.5
"$TMUX_BIN" send-keys -t "$TARGET" C-m

# ─── Poll for Completion ─────────────────────────────────────────────────
# Completion criteria (any of these + idle = success):
#   1. Context % has dropped from baseline (original criterion)
#   2. ⚡[C] compaction flag detected in statusline
#   3. "CONTEXT RESTORED" text from session-start hook
# Note: After /compact, session-start hook reads files back into context,
# which can re-inflate the context %. So context % drop alone is unreliable.

sleep 5  # Minimum wait — /compact needs time to start

elapsed=0
OUTCOME="timeout"

while [[ $elapsed -lt $TIMEOUT ]]; do
    current_pct=$(get_context_pct)

    current_tokens=$(get_token_count)

    if is_idle; then
        # Primary: ground truth token count dropped (most reliable signal)
        if [[ "$current_tokens" -gt 0 ]] && [[ "$current_tokens" -lt "$START_TOKENS" ]]; then
            OUTCOME="success"
            echo "Detected via token count drop: ${START_TOKENS} → ${current_tokens}" >&2
            break
        fi
        # Secondary: context % dropped (statusline, may lag)
        if [[ "$current_pct" -gt 0 ]] && [[ "$current_pct" -lt "$START_PCT" ]]; then
            OUTCOME="success"
            echo "Detected via context % drop: ${START_PCT}% → ${current_pct}%" >&2
            break
        fi
        # Tertiary: pane text signals (CONTEXT RESTORED from hook)
        if compaction_detected; then
            OUTCOME="success"
            echo "Detected via hook signal (tokens: ${current_tokens}, pct: ${current_pct}%)" >&2
            break
        fi
    fi

    sleep "$POLL_INTERVAL"
    elapsed=$(( $(date +%s) - START_TIME ))
done

# ─── Record Compaction Duration ──────────────────────────────────────────
# Capture timing BEFORE the /context probe — /context is measurement overhead,
# not part of the actual compaction process.
END_TIME=$(date +%s)
DURATION=$(( END_TIME - START_TIME ))

# ─── Capture True Post-Compaction Token Count ───────────────────────────
# The bottom-right token count shows "0 tokens" after /compact completes
# because it's lazy-evaluated — it won't refresh until CC processes something.
# Send /context to force a refresh and capture the real compressed token count.

if [[ "$OUTCOME" == "success" ]]; then
    echo "Compaction detected in ${DURATION}s — triggering model turn to refresh token count..." >&2
    sleep 3  # Pause for quiescence

    # Send a trivial prompt to force a model response.
    # Built-in commands like /context don't trigger model turns, so the
    # statusline and ground truth token counter stay stale. A model turn
    # forces CC to recalculate and display the true post-compaction count.
    "$TMUX_BIN" send-keys -t "$TARGET" Escape
    sleep 0.2
    "$TMUX_BIN" send-keys -t "$TARGET" C-u
    sleep 0.3
    "$TMUX_BIN" send-keys -t "$TARGET" -l "Reply with only: ok"
    sleep 0.5
    "$TMUX_BIN" send-keys -t "$TARGET" C-m

    # Wait for the model response (should be fast — single word reply)
    probe_wait=0
    while [[ $probe_wait -lt 45 ]]; do
        sleep 3
        probe_wait=$(( probe_wait + 3 ))
        if is_idle; then
            # Give statusline a moment to refresh after model turn completes
            sleep 2
            break
        fi
    done
fi

END_PCT=$(get_context_pct)
END_TOKENS=$(get_token_count)

echo "Post-/context capture: ${END_TOKENS} tokens (${END_PCT}%)" >&2

# Build JSON result
RESULT=$(jq -cn \
    --arg treatment "compact" \
    --argjson start_s "$START_TIME" \
    --argjson end_s "$END_TIME" \
    --argjson duration_s "$DURATION" \
    --argjson start_pct "${START_PCT:-0}" \
    --argjson end_pct "${END_PCT:-0}" \
    --argjson start_tokens "${START_TOKENS:-0}" \
    --argjson end_tokens "${END_TOKENS:-0}" \
    --arg outcome "$OUTCOME" \
    --arg timestamp "$TIMESTAMP" \
    '{treatment:$treatment, start_s:$start_s, end_s:$end_s, duration_s:$duration_s,
      start_pct:$start_pct, end_pct:$end_pct, start_tokens:$start_tokens,
      end_tokens:$end_tokens, outcome:$outcome, timestamp:$timestamp}')

echo "$RESULT"

# Append to file if specified
if [[ -n "$OUTPUT_FILE" ]]; then
    echo "$RESULT" >> "$OUTPUT_FILE"
    echo "Result appended to $OUTPUT_FILE" >&2
fi

if [[ "$OUTCOME" == "timeout" ]]; then
    echo "WARNING: /compact timed out after ${TIMEOUT}s" >&2
    exit 3
fi

echo "Completed in ${DURATION}s (${START_PCT}% → ${END_PCT}%)" >&2
exit 0
