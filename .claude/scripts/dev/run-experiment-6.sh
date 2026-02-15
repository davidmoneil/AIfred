#!/bin/bash
# run-experiment-6.sh — Master orchestration for Experiment 6: Preprocessing
#
# Runs 16 trials (8 blocks × 2 cells) of the 2-level between-subjects design:
#   Treatment: JICM-Standard (default) | JICM-PreAssembled
#
# Model fixed at Sonnet. Thinking fixed at default (on). Context ~45%.
#
# Designed to run from W5:Jarvis-dev or as a background process.
# Controls W0:Jarvis via tmux for context filling and treatment.
#
# Usage: run-experiment-6.sh [--start-block N] [--dry-run]
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
DATA_FILE="$PROJECT_DIR/.claude/reports/testing/experiment-6-data.jsonl"
LOG_FILE="$PROJECT_DIR/.claude/logs/experiment-6.log"
PROGRESS_FILE="$PROJECT_DIR/.claude/reports/testing/experiment-6-progress.json"

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
run-experiment-6.sh — Master orchestration for Experiment 6: Preprocessing

Usage: run-experiment-6.sh [options]

Options:
  --start-block N     Start from block N (1-8, default: 1)
  --dry-run           Show trial schedule without executing
  -h, --help          Show this help

Treatments:
  A = JICM Standard   (agent reads 10-17 files individually)
  B = JICM PreAssembled (preassemble-compression-input.sh → agent reads 1 file)

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
# Format: "preassemble_mode" (standard or preassembled)
declare -a BLOCK_1=("standard"      "preassembled")
declare -a BLOCK_2=("preassembled"  "standard")
declare -a BLOCK_3=("standard"      "preassembled")
declare -a BLOCK_4=("preassembled"  "standard")
declare -a BLOCK_5=("preassembled"  "standard")
declare -a BLOCK_6=("standard"      "preassembled")
declare -a BLOCK_7=("standard"      "preassembled")
declare -a BLOCK_8=("preassembled"  "standard")

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

write_preassemble_override() {
    local mode="$1"
    local override_file="$PROJECT_DIR/.claude/context/.jicm-preassemble-override"
    if [[ "$mode" == "preassembled" ]]; then
        echo "true" > "$override_file"
        log "  Preassemble override written: enabled"
    else
        rm -f "$override_file"
        log "  Preassemble override cleared (standard)"
    fi
}

clear_overrides() {
    rm -f "$PROJECT_DIR/.claude/context/.jicm-model-override"
    rm -f "$PROJECT_DIR/.claude/context/.jicm-thinking-override"
    rm -f "$PROJECT_DIR/.claude/context/.jicm-preassemble-override"
    rm -f "$PROJECT_DIR/.claude/context/.jicm-thinking-cleanup-pending"
    rm -f "$PROJECT_DIR/.claude/context/.compression-input-preassembled.md"
}

run_single_trial() {
    local block_num="$1"
    local trial_num="$2"
    local preassemble_mode="$3"
    local trial_id="${block_num}-${trial_num}"

    log "  Trial ${trial_id}: JICM preassemble=${preassemble_mode} at ${TARGET_PCT}%"

    # Clean up any leftover override files
    clear_overrides

    # Set preassemble override
    write_preassemble_override "$preassemble_mode"

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

    # Inject preassemble_mode into the last data record
    if [[ -f "$DATA_FILE" ]]; then
        local last_line tmp_file
        last_line=$(tail -1 "$DATA_FILE")
        tmp_file="${DATA_FILE}.tmp"
        sed '$d' "$DATA_FILE" > "$tmp_file" 2>/dev/null || true
        echo "$last_line" | jq -c --arg preassemble "$preassemble_mode" '. + {preassemble_mode: $preassemble}' >> "$tmp_file"
        mv "$tmp_file" "$DATA_FILE"
    fi

    # Record checkpoint size for preassembled trials
    if [[ "$preassemble_mode" == "preassembled" ]]; then
        local input_file="$PROJECT_DIR/.claude/context/.compression-input-preassembled.md"
        if [[ -f "$input_file" ]]; then
            local input_chars input_lines
            input_chars=$(wc -c < "$input_file" | tr -d ' ')
            input_lines=$(wc -l < "$input_file" | tr -d ' ')
            log "  Pre-assembled input: ${input_lines} lines, ${input_chars} chars"
        fi
    fi

    # Restore watcher and clean overrides
    ensure_watcher_safe
    clear_overrides
}

# ─── Pre-flight ──────────────────────────────────────────────────────────────
mkdir -p "$(dirname "$DATA_FILE")"
mkdir -p "$(dirname "$LOG_FILE")"

# Verify preprocessing script exists
if [[ ! -x "$SCRIPTS_DIR/preassemble-compression-input.sh" ]]; then
    echo "ERROR: preassemble-compression-input.sh not found or not executable" >&2
    echo "Run: chmod +x $SCRIPTS_DIR/preassemble-compression-input.sh" >&2
    exit 1
fi

log "${C_BOLD}════════════════════════════════════════════════════════════${C_RESET}"
log "${C_BOLD}  Experiment 6: Preprocessing Effect on Compression Time${C_RESET}"
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
        for preassemble_mode in "${block_trials[@]}"; do
            trial_in_block=$((trial_in_block + 1))
            total=$((total + 1))
            log "  ${block_num}-${trial_in_block}: JICM preassemble=${preassemble_mode} at ${TARGET_PCT}%"
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
    for preassemble_mode in "${block_trials[@]}"; do
        trial_in_block=$((trial_in_block + 1))
        TOTAL_DONE=$((TOTAL_DONE + 1))

        log ""
        log "${C_BOLD}── Trial ${TOTAL_DONE}/16 (Block ${block_num}, Trial ${trial_in_block}) ──${C_RESET}"

        update_progress "$block_num" "$trial_in_block" "$TOTAL_DONE" "running"

        run_single_trial "$block_num" "$trial_in_block" "$preassemble_mode"

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
log "${C_BOLD}  Experiment 6 Complete${C_RESET}"
log "${C_BOLD}  Total trials: ${FINAL_COUNT}${C_RESET}"
log "${C_BOLD}  Duration: $((EXPERIMENT_DURATION / 60))m ${EXPERIMENT_DURATION}s${C_RESET}"
log "${C_BOLD}  Data: ${DATA_FILE}${C_RESET}"
log "${C_BOLD}════════════════════════════════════════════════════════════${C_RESET}"

# Per-condition summary
for mode in standard preassembled; do
    count=$(grep -c "\"preassemble_mode\":\"$mode\"" "$DATA_FILE" 2>/dev/null || echo "0")
    successes=$(grep "\"preassemble_mode\":\"$mode\"" "$DATA_FILE" 2>/dev/null | grep -c '"outcome":"success"' || echo "0")
    log "  preassemble=${mode}: ${count} trials, ${successes} successes"
done

update_progress "$NUM_BLOCKS" 2 "$FINAL_COUNT" "complete"
log "Run analysis: python3 '$SCRIPTS_DIR/analyze-regression.py' --data '$DATA_FILE' --experiment 6"
exit 0
