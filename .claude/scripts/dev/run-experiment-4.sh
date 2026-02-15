#!/bin/bash
# run-experiment-4.sh — Master orchestration for Experiment 4: Model Selection
#
# Runs 24 trials (6 blocks × 4 cells) of the 1-way between-subjects design:
#   Treatment: /compact (baseline) | JICM-Haiku | JICM-Sonnet | JICM-Opus
#
# Context level fixed at ~45% (volume doesn't affect time — Exp 3).
#
# Designed to run from W5:Jarvis-dev or as a background process.
# Controls W0:Jarvis via tmux for context filling and treatment.
#
# Usage: run-experiment-4.sh [--start-block N] [--dry-run]
#
# Resume: If interrupted, restart with --start-block N to skip completed blocks.
# Data file is append-only JSONL, so partial data is preserved.
#
set -euo pipefail

# ─── Configuration ──────────────────────────────────────────────────────────
TMUX_BIN="${TMUX_BIN:-$HOME/bin/tmux}"
SESSION="${TMUX_SESSION:-jarvis}"
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$HOME/Claude/Jarvis}"
SCRIPTS_DIR="$PROJECT_DIR/.claude/scripts/dev"
DATA_FILE="$PROJECT_DIR/.claude/reports/testing/experiment-4-data.jsonl"
LOG_FILE="$PROJECT_DIR/.claude/logs/experiment-4.log"
PROGRESS_FILE="$PROJECT_DIR/.claude/reports/testing/experiment-4-progress.json"

START_BLOCK=1
DRY_RUN=false
INTER_TRIAL_WAIT=30       # Seconds between trials within a block
INTER_BLOCK_WAIT=60       # Seconds between blocks
WATCHER_SAFE_THRESHOLD=80 # During fills, watcher stays high to prevent premature trigger

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
run-experiment-4.sh — Master orchestration for Experiment 4: Model Selection

Usage: run-experiment-4.sh [options]

Options:
  --start-block N     Start from block N (1-6, default: 1)
  --dry-run           Show trial schedule without executing
  -h, --help          Show this help

Treatments:
  A = /compact (baseline, no agent)
  B = JICM-Haiku (compression-agent with haiku model)
  C = JICM-Sonnet (compression-agent with sonnet model, current default)
  D = JICM-Opus (compression-agent with opus model)

Context: Fixed at ~${TARGET_PCT}%
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
# Pre-randomized balanced blocks. Each block has one trial per cell.
# Format: "treatment:model"
# A=compact:none, B=jicm:haiku, C=jicm:sonnet, D=jicm:opus
declare -a BLOCK_1=("jicm:sonnet" "compact:none" "jicm:opus"   "jicm:haiku")
declare -a BLOCK_2=("jicm:haiku"  "jicm:opus"    "compact:none" "jicm:sonnet")
declare -a BLOCK_3=("compact:none" "jicm:sonnet"  "jicm:haiku"  "jicm:opus")
declare -a BLOCK_4=("jicm:opus"   "jicm:haiku"   "jicm:sonnet" "compact:none")
declare -a BLOCK_5=("jicm:sonnet" "compact:none"  "jicm:haiku"  "jicm:opus")
declare -a BLOCK_6=("jicm:haiku"  "jicm:opus"    "compact:none" "jicm:sonnet")

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

write_model_override() {
    local model="$1"
    local override_file="$PROJECT_DIR/.claude/context/.jicm-model-override"
    if [[ "$model" == "none" ]]; then
        rm -f "$override_file"
    else
        echo "$model" > "$override_file"
        log "  Model override written: $model"
    fi
}

clear_overrides() {
    rm -f "$PROJECT_DIR/.claude/context/.jicm-model-override"
    rm -f "$PROJECT_DIR/.claude/context/.jicm-thinking-override"
    rm -f "$PROJECT_DIR/.claude/context/.jicm-preassemble-override"
}

run_single_trial() {
    local block_num="$1"
    local trial_num="$2"
    local treatment="$3"
    local model="$4"
    local trial_id="${block_num}-${trial_num}"

    log "  Trial ${trial_id}: ${treatment} (model=${model}) at ${TARGET_PCT}%"

    # Clean up any leftover override files
    clear_overrides

    # For JICM trials, set model override and calculate trigger threshold
    local jicm_threshold=""
    if [[ "$treatment" == "jicm" ]]; then
        write_model_override "$model"
        jicm_threshold=$((TARGET_PCT - 5))
        [[ $jicm_threshold -lt 10 ]] && jicm_threshold=10
    fi

    # Ensure watcher is at safe threshold before filling
    ensure_watcher_safe

    # Build trial command
    local cmd="bash '$SCRIPTS_DIR/run-compression-trial.sh'"
    cmd+=" --single"
    cmd+=" --pair-id '$trial_id'"
    cmd+=" --target-pct $TARGET_PCT"
    cmd+=" --treatment $treatment"
    cmd+=" --context-level low"
    cmd+=" --block-id '$block_num'"
    cmd+=" --trial-id '$trial_id'"
    cmd+=" --data-file '$DATA_FILE'"
    cmd+=" --fill-tolerance $FILL_TOLERANCE"
    cmd+=" --fill-ceiling $FILL_CEILING"

    if [[ "$treatment" == "jicm" ]] && [[ -n "$jicm_threshold" ]]; then
        cmd+=" --jicm-threshold $jicm_threshold"
    fi

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

    # Inject model into the last data record
    if [[ -f "$DATA_FILE" ]] && [[ "$treatment" == "jicm" ]]; then
        local last_line tmp_file
        last_line=$(tail -1 "$DATA_FILE")
        tmp_file="${DATA_FILE}.tmp"
        sed '$d' "$DATA_FILE" > "$tmp_file" 2>/dev/null || true
        echo "$last_line" | jq -c --arg model "$model" '. + {model: $model}' >> "$tmp_file"
        mv "$tmp_file" "$DATA_FILE"
    elif [[ -f "$DATA_FILE" ]] && [[ "$treatment" == "compact" ]]; then
        local last_line tmp_file
        last_line=$(tail -1 "$DATA_FILE")
        tmp_file="${DATA_FILE}.tmp"
        sed '$d' "$DATA_FILE" > "$tmp_file" 2>/dev/null || true
        echo "$last_line" | jq -c '. + {model: "none"}' >> "$tmp_file"
        mv "$tmp_file" "$DATA_FILE"
    fi

    # Restore watcher to safe threshold after JICM trials
    if [[ "$treatment" == "jicm" ]]; then
        ensure_watcher_safe
    fi

    # Clean up overrides
    clear_overrides
}

# ─── Pre-flight ──────────────────────────────────────────────────────────────
mkdir -p "$(dirname "$DATA_FILE")"
mkdir -p "$(dirname "$LOG_FILE")"

log "${C_BOLD}════════════════════════════════════════════════════════════${C_RESET}"
log "${C_BOLD}  Experiment 4: Model Selection Effect on Compression Time${C_RESET}"
log "${C_BOLD}  24 trials, 6 blocks, 4 treatments${C_RESET}"
log "${C_BOLD}  Context: fixed at ~${TARGET_PCT}%${C_RESET}"
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
    for block_num in $(seq 1 6); do
        eval "block_trials=(\"\${BLOCK_${block_num}[@]}\")"
        log ""
        log "Block ${block_num}:"
        trial_in_block=0
        for trial_spec in "${block_trials[@]}"; do
            trial_in_block=$((trial_in_block + 1))
            total=$((total + 1))
            IFS=':' read -r treatment model <<< "$trial_spec"
            log "  ${block_num}-${trial_in_block}: ${treatment} (model=${model}) at ${TARGET_PCT}%"
        done
    done
    log ""
    log "Total trials: ${total}"
    log "Estimated time: ~$((total * 12))min (~$((total * 12 / 60))h)"
    exit 0
fi

# ─── Execute Blocks ──────────────────────────────────────────────────────────
TOTAL_DONE=$existing
EXPERIMENT_START=$(date +%s)

for block_num in $(seq "$START_BLOCK" 6); do
    eval "block_trials=(\"\${BLOCK_${block_num}[@]}\")"

    log ""
    log "${C_CYAN}╔═══════════════════════════════════════╗${C_RESET}"
    log "${C_CYAN}║  Block ${block_num} of 6  (${#block_trials[@]} trials)        ║${C_RESET}"
    log "${C_CYAN}╚═══════════════════════════════════════╝${C_RESET}"

    trial_in_block=0
    for trial_spec in "${block_trials[@]}"; do
        trial_in_block=$((trial_in_block + 1))
        TOTAL_DONE=$((TOTAL_DONE + 1))

        IFS=':' read -r treatment model <<< "$trial_spec"

        log ""
        log "${C_BOLD}── Trial ${TOTAL_DONE}/24 (Block ${block_num}, Trial ${trial_in_block}) ──${C_RESET}"

        update_progress "$block_num" "$trial_in_block" "$TOTAL_DONE" "running"

        run_single_trial "$block_num" "$trial_in_block" "$treatment" "$model"

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

    # Stopping rule check after block 2: if all Opus trials timed out, skip Opus
    if [[ $block_num -eq 2 ]]; then
        opus_total=$(grep -c '"model":"opus"' "$DATA_FILE" 2>/dev/null || echo "0")
        opus_timeouts=$(grep '"model":"opus"' "$DATA_FILE" 2>/dev/null | grep -c '"outcome":"timeout"' || echo "0")
        if [[ "$opus_total" -gt 0 ]] && [[ "$opus_timeouts" -eq "$opus_total" ]]; then
            log "${C_YELLOW}WARNING: All Opus trials timed out so far (${opus_timeouts}/${opus_total})${C_RESET}"
            log "Consider adding --skip-opus flag if this continues"
        fi
    fi

    # Inter-block wait
    if [[ $block_num -lt 6 ]]; then
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
log "${C_BOLD}  Experiment 4 Complete${C_RESET}"
log "${C_BOLD}  Total trials: ${FINAL_COUNT}${C_RESET}"
log "${C_BOLD}  Duration: $((EXPERIMENT_DURATION / 60))m ${EXPERIMENT_DURATION}s${C_RESET}"
log "${C_BOLD}  Data: ${DATA_FILE}${C_RESET}"
log "${C_BOLD}════════════════════════════════════════════════════════════${C_RESET}"

# Per-model summary
for m in none haiku sonnet opus; do
    count=$(grep -c "\"model\":\"$m\"" "$DATA_FILE" 2>/dev/null || echo "0")
    successes=$(grep "\"model\":\"$m\"" "$DATA_FILE" 2>/dev/null | grep -c '"outcome":"success"' || echo "0")
    log "  $m: ${count} trials, ${successes} successes"
done

update_progress 6 4 "$FINAL_COUNT" "complete"
log "Run analysis: python3 '$SCRIPTS_DIR/analyze-regression.py' --data '$DATA_FILE' --experiment 4"
exit 0
