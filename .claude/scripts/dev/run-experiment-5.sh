#!/bin/bash
# run-experiment-5.sh — Master orchestration for Experiment 5: Thinking Mode
#
# Runs 16 trials (8 blocks × 2 cells) of the 2-level between-subjects design:
#   Treatment: JICM-Thinking-On (default) | JICM-Thinking-Off
#
# Model fixed at Sonnet. Context level fixed at ~45%.
#
# Designed to run from W5:Jarvis-dev or as a background process.
# Controls W0:Jarvis via tmux for context filling and treatment.
#
# Usage: run-experiment-5.sh [--start-block N] [--dry-run]
#
# Resume: If interrupted, restart with --start-block N to skip completed blocks.
# Data file is append-only JSONL, so partial data is preserved.
#
set -euo pipefail

# ─── Configuration ──────────────────────────────────────────────────────────
TMUX_BIN="${TMUX_BIN:-$HOME/bin/tmux}"
SESSION="${TMUX_SESSION:-jarvis}"
TARGET="${SESSION}:0"
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$HOME/Claude/Jarvis}"
SCRIPTS_DIR="$PROJECT_DIR/.claude/scripts/dev"
DATA_FILE="$PROJECT_DIR/.claude/reports/testing/experiment-5-data.jsonl"
LOG_FILE="$PROJECT_DIR/.claude/logs/experiment-5.log"
PROGRESS_FILE="$PROJECT_DIR/.claude/reports/testing/experiment-5-progress.json"

START_BLOCK=1
DRY_RUN=false
INTER_TRIAL_WAIT=30
INTER_BLOCK_WAIT=60
WATCHER_SAFE_THRESHOLD=80

# Context level config (fixed at ~45%)
TARGET_PCT=45
FILL_TOLERANCE=2
FILL_CEILING=78

# ─── Colors ──────────────────────────────────────────────────────────────────
C_RESET=$'\e[0m'
C_GREEN=$'\e[32m'
C_RED=$'\e[31m'
C_YELLOW=$'\e[33m'
C_CYAN=$'\e[36m'
C_BOLD=$'\e[1m'
C_DIM=$'\e[2m'

# ─── Usage ───────────────────────────────────────────────────────────────────
show_usage() {
    cat <<EOF
run-experiment-5.sh — Master orchestration for Experiment 5: Thinking Mode

Usage: run-experiment-5.sh [options]

Options:
  --start-block N     Start from block N (1-8, default: 1)
  --dry-run           Show trial schedule without executing
  -h, --help          Show this help

Treatments:
  A = JICM with thinking ON  (default behavior, Sonnet)
  B = JICM with thinking OFF (MAX_THINKING_TOKENS=0)

Context: Fixed at ~${TARGET_PCT}%
Model:   Fixed at Sonnet
Data: $DATA_FILE
Log:  $LOG_FILE
EOF
    exit 0
}

# ─── Argument Parsing ────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
    case $1 in
        --start-block) START_BLOCK="$2"; shift 2 ;;
        --dry-run)     DRY_RUN=true; shift ;;
        -h|--help)     show_usage ;;
        *)             shift ;;
    esac
done

# ─── Block Design ────────────────────────────────────────────────────────────
# Pre-randomized balanced blocks. Each block has one of each treatment.
# Format: "thinking_mode" (on or off)
declare -a BLOCK_1=("on"  "off")
declare -a BLOCK_2=("off" "on")
declare -a BLOCK_3=("on"  "off")
declare -a BLOCK_4=("off" "on")
declare -a BLOCK_5=("off" "on")
declare -a BLOCK_6=("on"  "off")
declare -a BLOCK_7=("off" "on")
declare -a BLOCK_8=("on"  "off")

NUM_BLOCKS=8

# ─── Helpers ─────────────────────────────────────────────────────────────────
log() {
    local msg="[$(date '+%Y-%m-%d %H:%M:%S')] $*"
    echo "$msg" | tee -a "$LOG_FILE"
}

update_progress() {
    local block="$1" trial="$2" total_done="$3" status="$4"
    jq -cn \
        --argjson block "$block" \
        --argjson trial "$trial" \
        --argjson total_done "$total_done" \
        --arg status "$status" \
        --arg timestamp "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
        '{block:$block, trial:$trial, total_done:$total_done, status:$status, timestamp:$timestamp}' \
        > "$PROGRESS_FILE"
}

count_completed() {
    if [[ -f "$DATA_FILE" ]]; then
        wc -l < "$DATA_FILE" | tr -d ' '
    else
        echo "0"
    fi
}

ensure_watcher_safe() {
    log "  Setting watcher to safe threshold (${WATCHER_SAFE_THRESHOLD}%)..."
    bash "$SCRIPTS_DIR/restart-watcher.sh" --threshold "$WATCHER_SAFE_THRESHOLD" 2>&1 | while read -r line; do
        log "    $line"
    done
    sleep 3
}

write_thinking_override() {
    local mode="$1"
    local override_file="$PROJECT_DIR/.claude/context/.jicm-thinking-override"
    if [[ "$mode" == "off" ]]; then
        echo "off" > "$override_file"
        log "  Thinking override written: off"
    else
        rm -f "$override_file"
        log "  Thinking override cleared (default: on)"
    fi
}

clear_overrides() {
    rm -f "$PROJECT_DIR/.claude/context/.jicm-model-override"
    rm -f "$PROJECT_DIR/.claude/context/.jicm-thinking-override"
    rm -f "$PROJECT_DIR/.claude/context/.jicm-preassemble-override"
    rm -f "$PROJECT_DIR/.claude/context/.jicm-thinking-cleanup-pending"
}

run_single_trial() {
    local block_num="$1"
    local trial_num="$2"
    local thinking_mode="$3"
    local trial_id="${block_num}-${trial_num}"

    log "  Trial ${trial_id}: JICM thinking=${thinking_mode} at ${TARGET_PCT}%"

    # Clean up any leftover override files
    clear_overrides

    # Set thinking override
    write_thinking_override "$thinking_mode"

    # Calculate JICM trigger threshold
    local jicm_threshold=$((TARGET_PCT - 5))
    [[ $jicm_threshold -lt 10 ]] && jicm_threshold=10

    # Ensure watcher is at safe threshold before filling
    ensure_watcher_safe

    # Build trial command (always JICM, always sonnet)
    local cmd="bash '$SCRIPTS_DIR/run-compression-trial.sh'"
    cmd+=" --single"
    cmd+=" --pair-id '$trial_id'"
    cmd+=" --target-pct $TARGET_PCT"
    cmd+=" --treatment jicm"
    cmd+=" --context-level low"
    cmd+=" --block-id '$block_num'"
    cmd+=" --trial-id '$trial_id'"
    cmd+=" --data-file '$DATA_FILE'"
    cmd+=" --fill-tolerance $FILL_TOLERANCE"
    cmd+=" --fill-ceiling $FILL_CEILING"
    cmd+=" --jicm-threshold $jicm_threshold"

    log "  Command: $cmd"

    # Execute trial
    local trial_start trial_end trial_duration outcome
    trial_start=$(date +%s)

    if eval "$cmd" 2>&1 | while read -r line; do log "    $line"; done; then
        outcome="completed"
    else
        outcome="error"
        log "  ${C_RED}Trial ${trial_id} exited with error${C_RESET}"
    fi

    trial_end=$(date +%s)
    trial_duration=$((trial_end - trial_start))
    log "  Trial ${trial_id} finished in ${trial_duration}s (${outcome})"

    # Inject thinking_mode into the last data record
    if [[ -f "$DATA_FILE" ]]; then
        local last_line tmp_file
        last_line=$(tail -1 "$DATA_FILE")
        tmp_file="${DATA_FILE}.tmp"
        sed '$d' "$DATA_FILE" > "$tmp_file" 2>/dev/null || true
        echo "$last_line" | jq -c --arg thinking "$thinking_mode" '. + {thinking_mode: $thinking}' >> "$tmp_file"
        mv "$tmp_file" "$DATA_FILE"
    fi

    # Restore watcher and clean overrides
    ensure_watcher_safe
    clear_overrides
}

# ─── Pre-flight ──────────────────────────────────────────────────────────────
mkdir -p "$(dirname "$DATA_FILE")"
mkdir -p "$(dirname "$LOG_FILE")"

log "${C_BOLD}════════════════════════════════════════════════════════════${C_RESET}"
log "${C_BOLD}  Experiment 5: Thinking Mode Effect on Compression Time${C_RESET}"
log "${C_BOLD}  16 trials, 8 blocks, 2 treatments${C_RESET}"
log "${C_BOLD}  Model: Sonnet (fixed), Context: ~${TARGET_PCT}% (fixed)${C_RESET}"
log "${C_BOLD}════════════════════════════════════════════════════════════${C_RESET}"

if ! "$TMUX_BIN" has-session -t "$SESSION" 2>/dev/null; then
    log "${C_RED}ERROR: tmux session '$SESSION' not found${C_RESET}"
    exit 1
fi

existing=$(count_completed)
log "Existing data: ${existing} trials in $DATA_FILE"
log "Starting from block: $START_BLOCK"

# ─── Dry Run ─────────────────────────────────────────────────────────────────
if [[ "$DRY_RUN" == "true" ]]; then
    log ""
    log "=== DRY RUN — Trial Schedule ==="
    total=0
    for block_num in $(seq 1 "$NUM_BLOCKS"); do
        eval "block_trials=(\"\${BLOCK_${block_num}[@]}\")"
        log ""
        log "Block ${block_num}:"
        trial_in_block=0
        for thinking_mode in "${block_trials[@]}"; do
            trial_in_block=$((trial_in_block + 1))
            total=$((total + 1))
            log "  ${block_num}-${trial_in_block}: JICM thinking=${thinking_mode} at ${TARGET_PCT}%"
        done
    done
    log ""
    log "Total trials: ${total}"
    log "Estimated time: ~$((total * 10))min (~$((total * 10 / 60))h)"
    exit 0
fi

# ─── Execute Blocks ──────────────────────────────────────────────────────────
TOTAL_DONE=$existing
EXPERIMENT_START=$(date +%s)

for block_num in $(seq "$START_BLOCK" "$NUM_BLOCKS"); do
    eval "block_trials=(\"\${BLOCK_${block_num}[@]}\")"

    log ""
    log "${C_CYAN}╔═══════════════════════════════════════╗${C_RESET}"
    log "${C_CYAN}║  Block ${block_num} of ${NUM_BLOCKS}  (${#block_trials[@]} trials)        ║${C_RESET}"
    log "${C_CYAN}╚═══════════════════════════════════════╝${C_RESET}"

    trial_in_block=0
    for thinking_mode in "${block_trials[@]}"; do
        trial_in_block=$((trial_in_block + 1))
        TOTAL_DONE=$((TOTAL_DONE + 1))

        log ""
        log "${C_BOLD}── Trial ${TOTAL_DONE}/16 (Block ${block_num}, Trial ${trial_in_block}) ──${C_RESET}"

        update_progress "$block_num" "$trial_in_block" "$TOTAL_DONE" "running"

        run_single_trial "$block_num" "$trial_in_block" "$thinking_mode"

        update_progress "$block_num" "$trial_in_block" "$TOTAL_DONE" "done"

        # Inter-trial wait (skip after last trial in block)
        if [[ $trial_in_block -lt ${#block_trials[@]} ]]; then
            log "  Waiting ${INTER_TRIAL_WAIT}s before next trial..."
            sleep "$INTER_TRIAL_WAIT"
        fi
    done

    # Interim stats after each block
    local_completed=$(count_completed)
    log ""
    log "${C_GREEN}Block ${block_num} complete. Total data points: ${local_completed}${C_RESET}"

    # Validation check after block 2: are the two groups producing different times?
    if [[ $block_num -eq 2 ]]; then
        on_count=$(grep -c '"thinking_mode":"on"' "$DATA_FILE" 2>/dev/null || echo "0")
        off_count=$(grep -c '"thinking_mode":"off"' "$DATA_FILE" 2>/dev/null || echo "0")
        log ""
        log "${C_YELLOW}=== Interim Validation (Block 2) ===${C_RESET}"
        log "  Thinking-On trials: ${on_count}"
        log "  Thinking-Off trials: ${off_count}"

        if [[ "$on_count" -ge 2 ]] && [[ "$off_count" -ge 2 ]]; then
            # Extract mean durations for quick comparison
            on_mean=$(grep '"thinking_mode":"on"' "$DATA_FILE" | jq -r '.duration_s' | awk '{s+=$1; n++} END{if(n>0) printf "%.0f", s/n; else print "0"}')
            off_mean=$(grep '"thinking_mode":"off"' "$DATA_FILE" | jq -r '.duration_s' | awk '{s+=$1; n++} END{if(n>0) printf "%.0f", s/n; else print "0"}')
            log "  Thinking-On mean: ${on_mean}s"
            log "  Thinking-Off mean: ${off_mean}s"

            # Check if difference is > 5%
            if [[ "$on_mean" -gt 0 ]]; then
                diff_pct=$(( (on_mean - off_mean) * 100 / on_mean ))
                if [[ ${diff_pct#-} -lt 5 ]]; then
                    log "  ${C_RED}WARNING: Means differ by only ${diff_pct}% — thinking toggle may not be propagating${C_RESET}"
                    log "  Consider investigating MAX_THINKING_TOKENS propagation"
                else
                    log "  ${C_GREEN}Means differ by ${diff_pct}% — propagation appears to work${C_RESET}"
                fi
            fi
        fi
    fi

    # Inter-block wait
    if [[ $block_num -lt "$NUM_BLOCKS" ]]; then
        log "Waiting ${INTER_BLOCK_WAIT}s before Block $((block_num + 1))..."
        sleep "$INTER_BLOCK_WAIT"
    fi
done

# ─── Summary ─────────────────────────────────────────────────────────────────
EXPERIMENT_END=$(date +%s)
EXPERIMENT_DURATION=$(( EXPERIMENT_END - EXPERIMENT_START ))
FINAL_COUNT=$(count_completed)

log ""
log "${C_BOLD}════════════════════════════════════════════════════════════${C_RESET}"
log "${C_BOLD}  Experiment 5 Complete${C_RESET}"
log "${C_BOLD}  Total trials: ${FINAL_COUNT}${C_RESET}"
log "${C_BOLD}  Duration: $((EXPERIMENT_DURATION / 60))m ${EXPERIMENT_DURATION}s${C_RESET}"
log "${C_BOLD}  Data: ${DATA_FILE}${C_RESET}"
log "${C_BOLD}════════════════════════════════════════════════════════════${C_RESET}"

# Per-condition summary
for mode in on off; do
    count=$(grep -c "\"thinking_mode\":\"$mode\"" "$DATA_FILE" 2>/dev/null || echo "0")
    successes=$(grep "\"thinking_mode\":\"$mode\"" "$DATA_FILE" 2>/dev/null | grep -c '"outcome":"success"' || echo "0")
    log "  thinking=${mode}: ${count} trials, ${successes} successes"
done

update_progress "$NUM_BLOCKS" 2 "$FINAL_COUNT" "complete"
log "Run analysis: python3 '$SCRIPTS_DIR/analyze-regression.py' --data '$DATA_FILE' --experiment 5"
exit 0
