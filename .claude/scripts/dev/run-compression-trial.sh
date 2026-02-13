#!/bin/bash
# run-compression-trial.sh — Run one matched-pair compression timing trial
#
# Orchestrates: fill context → run treatment A → reset → fill again → run treatment B
# Records both results to compression-timing-data.jsonl
#
# Usage: run-compression-trial.sh --pair-id N --target-pct 55 --order AB|BA
#
# Order: AB = compact first, JICM second; BA = JICM first, compact second
#
# Exit codes: 0=both treatments completed, 1=error, 2=session-not-found
#
# Part of compression timing experiment infrastructure.
set -euo pipefail

# ─── Configuration ──────────────────────────────────────────────────────────
TMUX_BIN="${TMUX_BIN:-$HOME/bin/tmux}"
SESSION="${TMUX_SESSION:-jarvis}"
TARGET="${SESSION}:0"
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$HOME/Claude/Jarvis}"
SCRIPTS_DIR="$PROJECT_DIR/.claude/scripts/dev"
DATA_FILE="$PROJECT_DIR/.claude/reports/testing/compression-timing-data.jsonl"
PAIR_ID=""
TARGET_PCT=55
ORDER="AB"          # AB=compact-first, BA=jicm-first
JICM_THRESHOLD=""   # Override watcher threshold (optional)
INTER_TRIAL_WAIT=60 # Seconds between treatments in a pair
DRY_RUN=false
SINGLE_MODE=false     # Single trial mode (for Exp 2 factorial design)
TREATMENT=""          # For single mode: compact|jicm
CONTEXT_LEVEL=""      # Metadata: low|high
BLOCK_ID=""           # Block identifier
TRIAL_ID=""           # Trial within block
FILL_TOLERANCE=2      # Context fill tolerance (pass through to context-fill.sh)
FILL_CEILING=78       # Context fill ceiling (lockout protection)

# ─── Usage ──────────────────────────────────────────────────────────────────
show_usage() {
    cat <<EOF
run-compression-trial.sh — Run one matched-pair trial

Usage: run-compression-trial.sh --pair-id N --target-pct PCT [options]

Options:
  --pair-id N            Unique pair identifier (required, e.g., 1, 2, 3...)
  --target-pct N         Target context % for both treatments (required)
  --order AB|BA          AB=compact first, BA=JICM first (default: AB)
  --jicm-threshold N     Override JICM watcher threshold % (restarts watcher)
  --inter-wait SEC       Wait between treatments (default: 60)
  --dry-run              Show what would happen without executing
  -h, --help             Show this help

Output:
  Appends 2 JSON records to $DATA_FILE (one per treatment)

Example:
  run-compression-trial.sh --pair-id 1 --target-pct 55 --order AB
  run-compression-trial.sh --pair-id 2 --target-pct 60 --order BA
EOF
    exit 0
}

# ─── Argument Parsing ──────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
    case $1 in
        --pair-id)         PAIR_ID="$2"; shift 2 ;;
        --target-pct)      TARGET_PCT="$2"; shift 2 ;;
        --order)           ORDER="$2"; shift 2 ;;
        --jicm-threshold)  JICM_THRESHOLD="$2"; shift 2 ;;
        --inter-wait)      INTER_TRIAL_WAIT="$2"; shift 2 ;;
        --dry-run)         DRY_RUN=true; shift ;;
        --single)          SINGLE_MODE=true; shift ;;
        --treatment)       TREATMENT="$2"; shift 2 ;;
        --context-level)   CONTEXT_LEVEL="$2"; shift 2 ;;
        --block-id)        BLOCK_ID="$2"; shift 2 ;;
        --trial-id)        TRIAL_ID="$2"; shift 2 ;;
        --data-file)       DATA_FILE="$2"; shift 2 ;;
        --fill-tolerance)  FILL_TOLERANCE="$2"; shift 2 ;;
        --fill-ceiling)    FILL_CEILING="$2"; shift 2 ;;
        -h|--help)         show_usage ;;
        *)                 shift ;;
    esac
done

if [[ -z "$PAIR_ID" ]] && [[ "$SINGLE_MODE" != "true" ]]; then
    echo "ERROR: --pair-id is required (or use --single mode)" >&2
    show_usage
fi

# ─── Session Validation ───────────────────────────────────────────────────
if ! "$TMUX_BIN" has-session -t "$SESSION" 2>/dev/null; then
    echo "ERROR: tmux session '$SESSION' not found" >&2
    exit 2
fi

# ─── Ensure data directory exists ─────────────────────────────────────────
mkdir -p "$(dirname "$DATA_FILE")"

# ─── Helper Functions ─────────────────────────────────────────────────────

log() {
    echo "[$(date +%H:%M:%S)] $*" >&2
}

tmux_capture() {
    "$TMUX_BIN" capture-pane -t "$TARGET" -p 2>/dev/null || true
}

is_idle() {
    local pane
    pane=$(tmux_capture)
    echo "$pane" | grep -v '^$' | tail -10 | grep -q '❯' && return 0 || return 1
}

get_context_pct() {
    local pane
    pane=$(tmux_capture)
    if [[ -z "$pane" ]]; then echo "0"; return 0; fi
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
    if [[ -z "$pane" ]]; then echo "0"; return 0; fi
    local tokens
    tokens=$(echo "$pane" | tail -10 | grep -oE '[0-9,]+ tokens' | tail -1 | grep -oE '[0-9,]+' | tr -d ',' || true)
    if [[ -n "$tokens" ]] && [[ "$tokens" -gt 0 ]] && [[ "$tokens" -lt 200001 ]]; then
        echo "$tokens"
    else
        echo "0"
    fi
    return 0
}

validate_watcher_for_high() {
    if [[ "$CONTEXT_LEVEL" != "high" ]]; then
        return 0
    fi
    local jicm_state_file="$PROJECT_DIR/.claude/context/.jicm-state"
    if [[ ! -f "$jicm_state_file" ]]; then
        log "WARNING: JICM state file not found — cannot validate watcher"
        return 0
    fi
    local threshold
    threshold=$(grep 'threshold:' "$jicm_state_file" | grep -oE '[0-9]+' || echo "0")
    if [[ "$threshold" -lt 78 ]]; then
        log "ERROR: Watcher threshold is ${threshold}%, must be >= 78% for high-range trials"
        log "Fix: restart-watcher.sh --threshold 80"
        return 1
    fi
    log "Watcher validated: threshold=${threshold}%, safe for high-range fill"
    return 0
}

send_clear() {
    log "Sending /clear to W0 (hardened delivery)..."
    # Hardened command delivery: ESC → Ctrl-U → text → pause → Enter (B11 fix)
    # Prevents stale input buffer from prepending to the /clear command
    "$TMUX_BIN" send-keys -t "$TARGET" Escape
    sleep 0.2
    "$TMUX_BIN" send-keys -t "$TARGET" C-u
    sleep 0.3
    "$TMUX_BIN" send-keys -t "$TARGET" -l "/clear"
    sleep 0.5
    "$TMUX_BIN" send-keys -t "$TARGET" C-m
    sleep 10  # Wait for /clear to process

    # Wait for idle
    local waited=0
    while [[ $waited -lt 60 ]]; do
        if is_idle; then
            log "/clear complete, W0 idle"
            return 0
        fi
        sleep 3
        waited=$((waited + 3))
    done
    log "WARNING: W0 not idle after /clear"
    return 0
}

run_context_fill() {
    log "Filling context to ${TARGET_PCT}% (tolerance: ±${FILL_TOLERANCE}%, ceiling: ${FILL_CEILING}%)..."
    bash "$SCRIPTS_DIR/context-fill.sh" --target-pct "$TARGET_PCT" \
        --tolerance "$FILL_TOLERANCE" --ceiling "$FILL_CEILING"
}

run_compact_trial() {
    log "Running /compact trial (pair $PAIR_ID)..."
    local result
    result=$(bash "$SCRIPTS_DIR/time-compact.sh" --output "$DATA_FILE")

    # Inject pair_id into the last line of the data file
    if [[ -f "$DATA_FILE" ]]; then
        # Read last line, add pair_id, rewrite
        local last_line
        last_line=$(tail -1 "$DATA_FILE")
        # Remove last line and re-add with pair_id
        local tmp_file="${DATA_FILE}.tmp"
        # Use sed '$d' (POSIX) instead of head -n -1 (GNU-only, fails on macOS BSD)
        sed '$d' "$DATA_FILE" > "$tmp_file" 2>/dev/null || true
        echo "$last_line" | jq -c \
            --arg pid "${PAIR_ID:-}" \
            --arg ctx "${CONTEXT_LEVEL:-}" \
            --arg blk "${BLOCK_ID:-}" \
            --arg trl "${TRIAL_ID:-}" \
            '. + {pair_id: $pid, context_level: $ctx, block_id: $blk, trial_id: $trl}' >> "$tmp_file"
        mv "$tmp_file" "$DATA_FILE"
    fi

    log "Compact trial result: $result"
}

run_jicm_trial() {
    log "Running JICM compression trial (pair $PAIR_ID)..."

    # Optionally restart watcher with specific threshold
    if [[ -n "$JICM_THRESHOLD" ]]; then
        log "Restarting watcher with threshold ${JICM_THRESHOLD}%..."
        bash "$SCRIPTS_DIR/restart-watcher.sh" --threshold "$JICM_THRESHOLD"
        sleep 5
    fi

    # Record pre-compression state from pane (avoids watcher poll race condition)
    local start_pct start_tokens start_time timestamp
    start_pct=$(get_context_pct)
    start_tokens=$(get_token_count)
    start_time=$(date +%s)
    timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    log "Pre-compression baseline: ${start_pct}% (${start_tokens} tokens)"

    # Trigger JICM by lowering threshold to current context %
    # (or it may already trigger if context >= threshold)
    local current_pct
    current_pct="$start_pct"
    if [[ -z "$JICM_THRESHOLD" ]]; then
        local trigger_threshold=$((current_pct - 2))
        [[ $trigger_threshold -lt 10 ]] && trigger_threshold=10
        log "Setting watcher threshold to ${trigger_threshold}% to trigger JICM..."
        bash "$SCRIPTS_DIR/restart-watcher.sh" --threshold "$trigger_threshold"
        sleep 5
    fi

    # Wait for JICM cycle to complete by monitoring state
    log "Waiting for JICM cycle to complete..."
    local waited=0
    local max_wait=600  # 10 minutes max
    local jicm_started=false
    local outcome="timeout"

    while [[ $waited -lt $max_wait ]]; do
        local state
        state=$(bash "$SCRIPTS_DIR/watch-jicm.sh" --once --json 2>/dev/null | jq -r '.state // "UNKNOWN"')

        case "$state" in
            HALTING|COMPRESSING|CLEARING|RESTORING)
                jicm_started=true
                ;;
            WATCHING)
                if [[ "$jicm_started" == "true" ]]; then
                    outcome="success"
                    break
                fi
                ;;
        esac

        sleep 3
        waited=$((waited + 3))
    done

    # After timeout or success, wait for W0 to become idle before measuring.
    # Prevents cascading failures where a slow JICM cycle is still running
    # when the next trial starts (B7 fix).
    if ! is_idle; then
        log "Waiting for W0 to become idle before recording end state..."
        local idle_wait=0
        while [[ $idle_wait -lt 120 ]]; do
            sleep 5
            idle_wait=$((idle_wait + 5))
            if is_idle; then break; fi
        done
        if ! is_idle; then
            log "WARNING: W0 not idle after 120s post-monitoring — end state may be stale"
        fi
    fi

    local end_time end_pct end_tokens duration_s
    end_time=$(date +%s)
    duration_s=$((end_time - start_time))

    # Capture true post-compression token count via model-turn probe
    # (CC's token display is lazy-evaluated — needs a model turn to refresh)
    if [[ "$outcome" == "success" ]]; then
        log "Triggering model turn to refresh token count..."
        sleep 3
        "$TMUX_BIN" send-keys -t "$TARGET" Escape
        sleep 0.2
        "$TMUX_BIN" send-keys -t "$TARGET" C-u
        sleep 0.3
        "$TMUX_BIN" send-keys -t "$TARGET" -l "Reply with only: ok"
        sleep 0.5
        "$TMUX_BIN" send-keys -t "$TARGET" C-m

        local probe_wait=0
        while [[ $probe_wait -lt 45 ]]; do
            sleep 3
            probe_wait=$((probe_wait + 3))
            if is_idle; then
                sleep 2
                break
            fi
        done
    fi
    end_pct=$(get_context_pct)
    end_tokens=$(get_token_count)
    log "Post-compression: ${end_pct}% (${end_tokens} tokens)"

    # Try to read phase timing from jicm-metrics.jsonl (most recent entry)
    local metrics_file="$PROJECT_DIR/.claude/logs/telemetry/jicm-metrics.jsonl"
    local halt_time compress_time clear_time restore_time
    halt_time=0; compress_time=0; clear_time=0; restore_time=0
    if [[ -f "$metrics_file" ]]; then
        local latest
        latest=$(tail -1 "$metrics_file")
        halt_time=$(echo "$latest" | jq -r '.halt_time_s // 0')
        compress_time=$(echo "$latest" | jq -r '.compression_time_s // 0')
        clear_time=$(echo "$latest" | jq -r '.clear_time_s // 0')
        restore_time=$(echo "$latest" | jq -r '.restore_time_s // 0')
    fi

    # Build result JSON
    local result
    result=$(jq -cn \
        --arg treatment "jicm" \
        --arg pair_id "${PAIR_ID:-}" \
        --arg ctx "${CONTEXT_LEVEL:-}" \
        --arg blk "${BLOCK_ID:-}" \
        --arg trl "${TRIAL_ID:-}" \
        --argjson start_s "$start_time" \
        --argjson end_s "$end_time" \
        --argjson duration_s "$duration_s" \
        --argjson start_pct "${start_pct:-0}" \
        --argjson end_pct "${end_pct:-0}" \
        --argjson start_tokens "${start_tokens:-0}" \
        --argjson end_tokens "${end_tokens:-0}" \
        --arg outcome "$outcome" \
        --arg timestamp "$timestamp" \
        --argjson halt_time_s "${halt_time:-0}" \
        --argjson compress_time_s "${compress_time:-0}" \
        --argjson clear_time_s "${clear_time:-0}" \
        --argjson restore_time_s "${restore_time:-0}" \
        '{treatment:$treatment, pair_id:$pair_id, context_level:$ctx, block_id:$blk,
          trial_id:$trl, start_s:$start_s, end_s:$end_s, duration_s:$duration_s,
          start_pct:$start_pct, end_pct:$end_pct, start_tokens:$start_tokens,
          end_tokens:$end_tokens, outcome:$outcome, timestamp:$timestamp,
          halt_time_s:$halt_time_s, compress_time_s:$compress_time_s,
          clear_time_s:$clear_time_s, restore_time_s:$restore_time_s}')

    echo "$result" >> "$DATA_FILE"
    log "JICM trial result: duration=${duration_s}s, outcome=${outcome}"
}

# ─── Determine Treatment Order ──────────────────────────────────────────
FIRST=""
SECOND=""
case "$ORDER" in
    AB) FIRST="compact"; SECOND="jicm" ;;
    BA) FIRST="jicm"; SECOND="compact" ;;
    *)
        echo "ERROR: --order must be AB or BA" >&2
        exit 1
        ;;
esac

# ─── Dry Run ─────────────────────────────────────────────────────────────
if [[ "$DRY_RUN" == "true" ]]; then
    echo "=== DRY RUN ==="
    echo "Pair ID:     $PAIR_ID"
    echo "Target PCT:  $TARGET_PCT%"
    echo "Order:       $ORDER ($FIRST first, $SECOND second)"
    echo "Data file:   $DATA_FILE"
    echo ""
    echo "Steps:"
    echo "  1. /clear W0"
    echo "  2. Fill context to ${TARGET_PCT}%"
    echo "  3. Run $FIRST treatment"
    echo "  4. Wait ${INTER_TRIAL_WAIT}s"
    echo "  5. /clear W0"
    echo "  6. Fill context to ${TARGET_PCT}%"
    echo "  7. Run $SECOND treatment"
    echo "  8. Record results"
    exit 0
fi

# ─── Single Trial Mode (Experiment 2 factorial design) ───────────────────
if [[ "$SINGLE_MODE" == "true" ]]; then
    if [[ -z "$TREATMENT" ]]; then
        echo "ERROR: --treatment (compact|jicm) required in --single mode" >&2
        exit 1
    fi

    validate_watcher_for_high || exit 1

    log "=== Single Trial: ${TREATMENT} at ${TARGET_PCT}% (${CONTEXT_LEVEL:-?}) [block=${BLOCK_ID:-?}, trial=${TRIAL_ID:-?}] ==="
    send_clear
    run_context_fill

    if [[ "$TREATMENT" == "compact" ]]; then
        run_compact_trial
    else
        run_jicm_trial
    fi

    log "=== Trial complete ==="
    exit 0
fi

# ─── Execute Trial Pair ──────────────────────────────────────────────────

log "=== Matched Pair $PAIR_ID: ${TARGET_PCT}% | Order: $ORDER ($FIRST → $SECOND) ==="

# Treatment 1
log "--- Treatment 1: $FIRST ---"
send_clear
run_context_fill

if [[ "$FIRST" == "compact" ]]; then
    run_compact_trial
else
    run_jicm_trial
fi

# Inter-treatment pause
log "Waiting ${INTER_TRIAL_WAIT}s between treatments..."
sleep "$INTER_TRIAL_WAIT"

# Treatment 2
log "--- Treatment 2: $SECOND ---"
send_clear
run_context_fill

if [[ "$SECOND" == "compact" ]]; then
    run_compact_trial
else
    run_jicm_trial
fi

log "=== Pair $PAIR_ID complete ==="
log "Results appended to $DATA_FILE"
exit 0
