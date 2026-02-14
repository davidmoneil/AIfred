#!/bin/bash
# run-experiment-3.sh — Master orchestration for Experiment 3
#
# Runs 24 trials (6 blocks × 4 cells) of the 2×2 factorial:
#   Treatment (/compact vs JICM) × Context Level (40% vs 70%)
#
# Designed to run from W5:Jarvis-dev or as a background process.
# Controls W0:Jarvis via tmux for context filling and treatment.
#
# Usage: run-experiment-3.sh [--start-block N] [--dry-run]
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
DATA_FILE="$PROJECT_DIR/.claude/reports/testing/compression-exp3-data.jsonl"
LOG_FILE="$PROJECT_DIR/.claude/logs/experiment-3.log"
PROGRESS_FILE="$PROJECT_DIR/.claude/reports/testing/experiment-3-progress.json"

START_BLOCK=1
DRY_RUN=false
INTER_TRIAL_WAIT=30       # Seconds between trials within a block
INTER_BLOCK_WAIT=60       # Seconds between blocks
WATCHER_SAFE_THRESHOLD=80 # During fills, watcher stays at this to prevent premature trigger

# Context level configs
LOW_PCT=40
LOW_TOLERANCE=2
LOW_CEILING=78
HIGH_PCT=70
HIGH_TOLERANCE=1
HIGH_CEILING=72

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
run-experiment-3.sh — Master orchestration for Experiment 3

Usage: run-experiment-3.sh [options]

Options:
  --start-block N     Start from block N (1-6, default: 1)
  --dry-run           Show trial schedule without executing
  -h, --help          Show this help

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
# Format: "treatment:context_level"
# A=/compact-low, B=/compact-high, C=JICM-low, D=JICM-high
declare -a BLOCK_1=("jicm:low"    "compact:high" "compact:low"  "jicm:high")
declare -a BLOCK_2=("compact:high" "jicm:low"    "compact:low"  "jicm:high")
declare -a BLOCK_3=("jicm:high"   "compact:low"  "jicm:high"   "compact:low")
declare -a BLOCK_4=("compact:high" "jicm:low"    "jicm:low"    "compact:high")
declare -a BLOCK_5=("jicm:high"   "compact:low"  "compact:high" "jicm:low")
declare -a BLOCK_6=("compact:low"  "jicm:high"   "compact:high" "jicm:low")

# Fix Block 3 & 4 — each block must have exactly one of each cell
declare -a BLOCK_3=("jicm:high"   "compact:low"  "jicm:low"    "compact:high")
declare -a BLOCK_4=("compact:high" "jicm:low"    "compact:low"  "jicm:high")

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

run_single_trial() {
    local block_num="$1"
    local trial_num="$2"
    local treatment="$3"
    local context_level="$4"
    local trial_id="${block_num}-${trial_num}"

    # Determine target pct and fill params
    local target_pct fill_tolerance fill_ceiling jicm_threshold
    if [[ "$context_level" == "low" ]]; then
        target_pct=$LOW_PCT
        fill_tolerance=$LOW_TOLERANCE
        fill_ceiling=$LOW_CEILING
    else
        target_pct=$HIGH_PCT
        fill_tolerance=$HIGH_TOLERANCE
        fill_ceiling=$HIGH_CEILING
    fi

    log "  Trial ${trial_id}: ${treatment} at ${target_pct}% (${context_level})"

    # For JICM high trials, set threshold to trigger at target
    if [[ "$treatment" == "jicm" ]]; then
        jicm_threshold=$((target_pct - 5))
        [[ $jicm_threshold -lt 10 ]] && jicm_threshold=10
    fi

    # Ensure watcher is at safe threshold before filling
    ensure_watcher_safe

    # Build trial command
    local cmd="bash '$SCRIPTS_DIR/run-compression-trial.sh'"
    cmd+=" --single"
    cmd+=" --pair-id '$trial_id'"
    cmd+=" --target-pct $target_pct"
    cmd+=" --treatment $treatment"
    cmd+=" --context-level $context_level"
    cmd+=" --block-id '$block_num'"
    cmd+=" --trial-id '$trial_id'"
    cmd+=" --data-file '$DATA_FILE'"
    cmd+=" --fill-tolerance $fill_tolerance"
    cmd+=" --fill-ceiling $fill_ceiling"

    if [[ "$treatment" == "jicm" ]]; then
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

    # Restore watcher to safe threshold after JICM trials
    if [[ "$treatment" == "jicm" ]]; then
        ensure_watcher_safe
    fi
}

# ─── Pre-flight ──────────────────────────────────────────────────────────────
mkdir -p "$(dirname "$DATA_FILE")"
mkdir -p "$(dirname "$LOG_FILE")"

log "${C_BOLD}════════════════════════════════════════════════════════════${C_RESET}"
log "${C_BOLD}  Experiment 3: Context Volume Effect (40% vs 70%)${C_RESET}"
log "${C_BOLD}  24 trials, 6 blocks, 2×2 factorial${C_RESET}"
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
            IFS=':' read -r treatment level <<< "$trial_spec"
            local_pct=$LOW_PCT
            [[ "$level" == "high" ]] && local_pct=$HIGH_PCT
            log "  ${block_num}-${trial_in_block}: ${treatment} at ${local_pct}% (${level})"
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

        IFS=':' read -r treatment level <<< "$trial_spec"

        log ""
        log "${C_BOLD}── Trial ${TOTAL_DONE}/24 (Block ${block_num}, Trial ${trial_in_block}) ──${C_RESET}"

        update_progress "$block_num" "$trial_in_block" "$TOTAL_DONE" "running"

        run_single_trial "$block_num" "$trial_in_block" "$treatment" "$level"

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

    # Stopping rule check: if both JICM-high trials in block 1 failed, abort
    if [[ $block_num -eq 1 ]]; then
        jicm_high_failures=$(grep -c '"outcome":"timeout"' "$DATA_FILE" 2>/dev/null || echo "0")
        jicm_high_total=$(grep -c '"context_level":"high".*"treatment":"jicm"' "$DATA_FILE" 2>/dev/null || echo "0")
        if [[ "$jicm_high_total" -gt 0 ]] && [[ "$jicm_high_failures" -eq "$jicm_high_total" ]]; then
            log "${C_RED}STOPPING RULE: All JICM-high trials failed in Block 1${C_RESET}"
            log "70% may still be above JICM operational ceiling"
            break
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
log "${C_BOLD}  Experiment 3 Complete${C_RESET}"
log "${C_BOLD}  Total trials: ${FINAL_COUNT}${C_RESET}"
log "${C_BOLD}  Duration: $((EXPERIMENT_DURATION / 60))m ${EXPERIMENT_DURATION}s${C_RESET}"
log "${C_BOLD}  Data: ${DATA_FILE}${C_RESET}"
log "${C_BOLD}════════════════════════════════════════════════════════════${C_RESET}"

update_progress 6 4 "$FINAL_COUNT" "complete"
log "Run analysis: python3 '$SCRIPTS_DIR/analyze-regression.py' --data '$DATA_FILE'"
exit 0
