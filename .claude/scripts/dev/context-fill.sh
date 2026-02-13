#!/bin/bash
# context-fill.sh — Fill W0:Jarvis context to a target % using deterministic workload
#
# Sends a sequence of file-read prompts to W0, polling context % after each.
# Stops when the target % is reached (within ±2% tolerance).
#
# The workload is deterministic: same files, same order, so context content
# is reproducible across trials.
#
# Usage: context-fill.sh --target-pct 55 [--tolerance 2] [--wait-per-prompt 30]
#
# Exit codes: 0=target reached, 1=error, 2=session-not-found, 3=target unreachable
#
# Part of compression timing experiment infrastructure.
set -euo pipefail

# ─── Configuration ──────────────────────────────────────────────────────────
TMUX_BIN="${TMUX_BIN:-$HOME/bin/tmux}"
SESSION="${TMUX_SESSION:-jarvis}"
TARGET_WINDOW="${SESSION}:0"
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$HOME/Claude/Jarvis}"
TARGET_PCT=55
TOLERANCE=2
WAIT_PER_PROMPT=45    # Seconds to wait after each prompt for W0 to process
MAX_PROMPTS=30        # Safety: abort after this many prompts
POLL_INTERVAL=3       # Seconds between context % polls while waiting
CEILING=78            # Abort if context reaches this level (lockout protection)

# Deterministic file list — ordered from smallest to largest context impact
# These are real project files that reliably consume context when read
FILL_FILES=(
    ".claude/context/compaction-essentials.md"
    ".claude/context/dev-session-instructions.md"
    ".claude/context/psyche/capability-map.yaml"
    ".claude/context/patterns/jicm-pattern.md"
    ".claude/skills/ralph-loop/SKILL.md"
    ".claude/skills/research-ops/SKILL.md"
    ".claude/context/workflows/wiggum-loop.md"
    ".claude/scripts/jicm-watcher.sh"
    ".claude/context/patterns/observation-masking-pattern.md"
    ".claude/context/designs/jicm-v5-design-addendum.md"
    ".claude/skills/knowledge-ops/SKILL.md"
    ".claude/skills/deck-ops/SKILL.md"
    ".claude/context/patterns/agent-selection-pattern.md"
    ".claude/context/patterns/context-budget-management.md"
    ".claude/context/components/orchestration-overview.md"
    ".claude/skills/self-ops/SKILL.md"
    ".claude/scripts/ennoia.sh"
    ".claude/scripts/virgil.sh"
    ".claude/context/designs/jicm-v6-design.md"
    ".claude/hooks/session-start.sh"
    ".claude/skills/doc-ops/SKILL.md"
    ".claude/skills/autonom-ops/SKILL.md"
    ".claude/context/patterns/startup-protocol.md"
    ".claude/context/patterns/milestone-review-pattern.md"
    ".claude/context/reference/glossary.md"
    ".claude/skills/dev-ops/SKILL.md"
    ".claude/skills/ulfhedthnar/SKILL.md"
    ".claude/scripts/command-handler.sh"
    ".claude/scripts/housekeep.sh"
    ".claude/scripts/launch-jarvis-tmux.sh"
)

# ─── Usage ──────────────────────────────────────────────────────────────────
show_usage() {
    cat <<EOF
context-fill.sh — Fill W0 context to target %

Usage: context-fill.sh --target-pct N [options]

Options:
  --target-pct N       Target context percentage (required, e.g., 55)
  --tolerance N        Acceptable range ±N% (default: 2)
  --ceiling N          Abort if context reaches N% (default: 78, lockout safety)
  --wait-per-prompt N  Seconds to wait per file-read prompt (default: 45)
  --max-prompts N      Safety limit on prompts sent (default: 30)
  -h, --help           Show this help

Exit codes:
  0  Target reached
  1  Error
  2  Session not found
  3  Target unreachable (exhausted fill files or max prompts)
EOF
    exit 0
}

# ─── Argument Parsing ──────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
    case $1 in
        --target-pct)      TARGET_PCT="$2"; shift 2 ;;
        --tolerance)       TOLERANCE="$2"; shift 2 ;;
        --ceiling)         CEILING="$2"; shift 2 ;;
        --wait-per-prompt) WAIT_PER_PROMPT="$2"; shift 2 ;;
        --max-prompts)     MAX_PROMPTS="$2"; shift 2 ;;
        -h|--help)         show_usage ;;
        *)                 shift ;;
    esac
done

# ─── Session Validation ───────────────────────────────────────────────────
if ! "$TMUX_BIN" has-session -t "$SESSION" 2>/dev/null; then
    echo "ERROR: tmux session '$SESSION' not found" >&2
    exit 2
fi

# ─── Helper Functions ─────────────────────────────────────────────────────

get_context_pct() {
    local pane
    pane=$("$TMUX_BIN" capture-pane -t "$TARGET_WINDOW" -p 2>/dev/null || true)
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

is_idle() {
    local pane
    pane=$("$TMUX_BIN" capture-pane -t "$TARGET_WINDOW" -p 2>/dev/null || true)
    echo "$pane" | grep -v '^$' | tail -10 | grep -q '❯' && return 0 || return 1
}

wait_for_idle() {
    local max_wait="$1"
    local waited=0
    while [[ $waited -lt $max_wait ]]; do
        if is_idle; then
            return 0
        fi
        sleep "$POLL_INTERVAL"
        waited=$((waited + POLL_INTERVAL))
    done
    return 1
}

send_prompt() {
    local prompt="$1"
    "$TMUX_BIN" send-keys -t "$TARGET_WINDOW" -l "$prompt"
    sleep 0.3
    "$TMUX_BIN" send-keys -t "$TARGET_WINDOW" C-m
}

# ─── Pre-flight ──────────────────────────────────────────────────────────
echo "Context fill: targeting ${TARGET_PCT}% (±${TOLERANCE}%)" >&2

CURRENT_PCT=$(get_context_pct)
echo "Current context: ${CURRENT_PCT}%" >&2

# Already at target?
LOW=$((TARGET_PCT - TOLERANCE))
HIGH=$((TARGET_PCT + TOLERANCE))
if [[ "$CURRENT_PCT" -ge "$LOW" ]] && [[ "$CURRENT_PCT" -le "$HIGH" ]]; then
    echo "Already at target range (${CURRENT_PCT}%)" >&2
    exit 0
fi

if [[ "$CURRENT_PCT" -gt "$HIGH" ]]; then
    echo "ERROR: Context already above target (${CURRENT_PCT}% > ${HIGH}%). Need /clear first." >&2
    exit 3
fi

# Wait for idle before starting
if ! is_idle; then
    echo "Waiting for W0 to become idle..." >&2
    if ! wait_for_idle 30; then
        echo "ERROR: W0 not idle after 30s" >&2
        exit 1
    fi
fi

# ─── Fill Loop ───────────────────────────────────────────────────────────
PROMPT_COUNT=0
FILE_INDEX=0

while [[ $PROMPT_COUNT -lt $MAX_PROMPTS ]] && [[ $FILE_INDEX -lt ${#FILL_FILES[@]} ]]; do
    CURRENT_PCT=$(get_context_pct)

    # Check if target reached (verify both bounds)
    if [[ "$CURRENT_PCT" -ge "$LOW" ]] && [[ "$CURRENT_PCT" -le "$HIGH" ]]; then
        echo "Target reached: ${CURRENT_PCT}% (target: ${TARGET_PCT}±${TOLERANCE}%)" >&2
        echo "$CURRENT_PCT"
        exit 0
    fi
    if [[ "$CURRENT_PCT" -gt "$CEILING" ]]; then
        echo "ABORT: Context at ${CURRENT_PCT}% ABOVE ceiling (${CEILING}%)." >&2
        exit 3
    fi
    if [[ "$CURRENT_PCT" -gt "$HIGH" ]] && [[ "$CURRENT_PCT" -le "$CEILING" ]]; then
        echo "WARNING: Overshoot to ${CURRENT_PCT}% (target: ${LOW}-${HIGH}%, ceiling: ${CEILING}%), continuing as usable" >&2
        echo "$CURRENT_PCT"
        exit 0
    fi

    # If close to target, switch to fine approach (prevents large-file overshoots)
    FINE_THRESHOLD=$((TARGET_PCT - 8))
    if [[ "$CURRENT_PCT" -ge "$FINE_THRESHOLD" ]]; then
        echo "  Switching to fine approach at ${CURRENT_PCT}% (within 8% of target)..." >&2
        break
    fi

    # Send next file-read prompt
    FILE="${FILL_FILES[$FILE_INDEX]}"
    FULL_PATH="$PROJECT_DIR/$FILE"

    if [[ -f "$FULL_PATH" ]]; then
        echo "  [$((PROMPT_COUNT + 1))] Reading $FILE (currently ${CURRENT_PCT}%)..." >&2
        send_prompt "Read the file $FILE and briefly summarize its purpose in one sentence."

        # Wait for W0 to process
        sleep 5  # Initial delay for prompt processing
        if ! wait_for_idle "$WAIT_PER_PROMPT"; then
            echo "  WARNING: W0 didn't return to idle after ${WAIT_PER_PROMPT}s — continuing" >&2
        fi

        # Safety: check for overshoot past ceiling (lockout protection)
        POST_PCT=$(get_context_pct)
        if [[ "$POST_PCT" -ge "$CEILING" ]]; then
            echo "ABORT: Context at ${POST_PCT}% reached ceiling (${CEILING}%). Risk of lockout." >&2
            exit 3
        fi

        PROMPT_COUNT=$((PROMPT_COUNT + 1))
    fi

    FILE_INDEX=$((FILE_INDEX + 1))
done

# ─── Fine Approach ───────────────────────────────────────────────────────
# Uses minimal-impact prompts to approach target precisely when close.
# Prevents catastrophic overshoots from large file reads.
CURRENT_PCT=$(get_context_pct)
if [[ "$CURRENT_PCT" -lt "$LOW" ]] && [[ "$CURRENT_PCT" -ge $((TARGET_PCT - 10)) ]]; then
    echo "  Fine approach: ${CURRENT_PCT}% → ${LOW}%+ using minimal prompts..." >&2
    FINE_COUNT=0
    FINE_MAX=30
    PLATEAU_COUNT=0
    PLATEAU_MAX=5       # Accept current level if stuck for this many iterations
    LAST_FINE_PCT=0
    while [[ $FINE_COUNT -lt $FINE_MAX ]]; do
        CURRENT_PCT=$(get_context_pct)

        # Detect context DROP (CC auto-compacted under us)
        if [[ "$LAST_FINE_PCT" -gt 0 ]] && [[ "$CURRENT_PCT" -lt $((LAST_FINE_PCT - 10)) ]]; then
            echo "  ABORT: Context dropped ${LAST_FINE_PCT}% → ${CURRENT_PCT}% (CC auto-compacted)" >&2
            exit 3
        fi

        # Hard abort: ABOVE ceiling (not recoverable)
        if [[ "$CURRENT_PCT" -gt "$CEILING" ]]; then
            echo "ABORT: Context at ${CURRENT_PCT}% ABOVE ceiling (${CEILING}%)." >&2
            exit 3
        fi
        # On-target check
        if [[ "$CURRENT_PCT" -ge "$LOW" ]] && [[ "$CURRENT_PCT" -le "$HIGH" ]]; then
            echo "Target reached: ${CURRENT_PCT}% (target: ${TARGET_PCT}±${TOLERANCE}%, fine approach)" >&2
            echo "$CURRENT_PCT"
            exit 0
        fi
        # Overshoot but still at or below ceiling — treat as usable (B9 fix)
        if [[ "$CURRENT_PCT" -gt "$HIGH" ]] && [[ "$CURRENT_PCT" -le "$CEILING" ]]; then
            echo "WARNING: Overshoot to ${CURRENT_PCT}% (target: ${LOW}-${HIGH}%, ceiling: ${CEILING}%), continuing as usable" >&2
            echo "$CURRENT_PCT"
            exit 0
        fi

        # Plateau detection (B10 fix): if context hasn't increased in PLATEAU_MAX iterations,
        # accept current level to prevent CC auto-compaction from stalled prompts
        if [[ "$CURRENT_PCT" -eq "$LAST_FINE_PCT" ]] || [[ "$CURRENT_PCT" -lt "$LAST_FINE_PCT" ]]; then
            PLATEAU_COUNT=$((PLATEAU_COUNT + 1))
        else
            PLATEAU_COUNT=0
        fi
        if [[ "$PLATEAU_COUNT" -ge "$PLATEAU_MAX" ]]; then
            echo "  Plateau detected: stuck at ${CURRENT_PCT}% for ${PLATEAU_COUNT} iterations" >&2
            if [[ "$CURRENT_PCT" -ge $((LOW - 5)) ]]; then
                echo "  Accepting ${CURRENT_PCT}% as close enough to target (within 5% of low bound ${LOW}%)" >&2
                echo "$CURRENT_PCT"
                exit 0
            else
                echo "  ERROR: Plateau at ${CURRENT_PCT}% too far from target ${LOW}%" >&2
                exit 3
            fi
        fi
        LAST_FINE_PCT=$CURRENT_PCT

        RAND_A=$((RANDOM % 1000 + 1))
        RAND_B=$((RANDOM % 1000 + 1))
        FINE_COUNT=$((FINE_COUNT + 1))
        echo "  [fine $FINE_COUNT] Minimal prompt (currently ${CURRENT_PCT}%)..." >&2
        send_prompt "What is ${RAND_A} + ${RAND_B}? Reply with only the number."
        sleep 5
        if ! wait_for_idle 30; then
            echo "  WARNING: W0 didn't return to idle after fine prompt" >&2
        fi
    done
fi

# Final check
CURRENT_PCT=$(get_context_pct)
if [[ "$CURRENT_PCT" -ge "$LOW" ]]; then
    echo "Target reached: ${CURRENT_PCT}% (after ${PROMPT_COUNT} prompts + fine approach)" >&2
    echo "$CURRENT_PCT"
    exit 0
fi

echo "ERROR: Could not reach ${TARGET_PCT}%. Stuck at ${CURRENT_PCT}% after ${PROMPT_COUNT} prompts." >&2
exit 3
