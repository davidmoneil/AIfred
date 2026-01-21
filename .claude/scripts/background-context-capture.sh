#!/bin/bash
# Background Context Capture
# Run this script, then wait for it to complete and check the output file.
#
# Usage: Run in background, wait ~15 seconds, then read the output file
# Output: .claude/context/.context-captured.txt

set -euo pipefail

TMUX_BIN="${TMUX_BIN:-$HOME/bin/tmux}"
TMUX_SESSION="${TMUX_SESSION:-jarvis}"
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$HOME/Claude/Jarvis}"
OUT_FILE="$PROJECT_DIR/.claude/context/.context-captured.txt"
LOG_FILE="$PROJECT_DIR/.claude/logs/context-capture.log"

log() {
    echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) | $1" >> "$LOG_FILE"
    echo "$1"
}

mkdir -p "$(dirname "$OUT_FILE")"
mkdir -p "$(dirname "$LOG_FILE")"

log "=== Background Context Capture Started ==="
log "Session: $TMUX_SESSION"
log "Output: $OUT_FILE"

# Check tmux session exists
if ! "$TMUX_BIN" has-session -t "$TMUX_SESSION" 2>/dev/null; then
    log "ERROR: tmux session '$TMUX_SESSION' not found"
    exit 1
fi

# Wait a moment for any current activity to settle
log "Waiting 2 seconds for session to settle..."
sleep 2

# Clear any existing input state
log "Clearing input state (Escape, Ctrl-C)..."
"$TMUX_BIN" send-keys -t "$TMUX_SESSION" Escape
sleep 0.2
"$TMUX_BIN" send-keys -t "$TMUX_SESSION" C-c
sleep 0.3

# Clear screen to get clean capture area
log "Clearing screen..."
"$TMUX_BIN" send-keys -t "$TMUX_SESSION" C-l
sleep 0.5

# Record baseline
BASELINE=$("$TMUX_BIN" capture-pane -t "$TMUX_SESSION" -p -S - 2>/dev/null | wc -l)
log "Baseline: $BASELINE lines"

# Send the /context command
# Use literal mode and then Escape to dismiss autocomplete, then Enter to submit
log "Sending /context command..."
"$TMUX_BIN" send-keys -t "$TMUX_SESSION" -l "/context"
sleep 0.3
"$TMUX_BIN" send-keys -t "$TMUX_SESSION" Escape
sleep 0.2
"$TMUX_BIN" send-keys -t "$TMUX_SESSION" Enter

# Rapid capture loop - capture every 0.5 seconds for 12 seconds
# Save the capture with the most lines (likely when /context is displayed)
log "Starting rapid capture (12 seconds)..."
BEST_LINES=0
BEST_CONTENT=""

for i in $(seq 1 24); do
    sleep 0.5
    CAPTURE=$("$TMUX_BIN" capture-pane -t "$TMUX_SESSION" -p -S - 2>/dev/null || echo "")
    LINES=$(echo "$CAPTURE" | wc -l)

    log "  Capture $i: $LINES lines"

    if [[ $LINES -gt $BEST_LINES ]]; then
        BEST_LINES=$LINES
        BEST_CONTENT="$CAPTURE"
        log "  -> New best: $BEST_LINES lines"
    fi
done

# Save the best capture
log "Saving best capture ($BEST_LINES lines) to $OUT_FILE"
{
    echo "# Context Capture Results"
    echo "# Captured: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo "# Best capture: $BEST_LINES lines"
    echo "# Baseline was: $BASELINE lines"
    echo ""
    echo "$BEST_CONTENT"
} > "$OUT_FILE"

# Also save with escape sequences for potential formatting
"$TMUX_BIN" capture-pane -t "$TMUX_SESSION" -p -e -S - > "${OUT_FILE%.txt}-escaped.txt" 2>/dev/null || true

log "=== Capture Complete ==="
log "Output file: $OUT_FILE"
log "Lines captured: $BEST_LINES"

# Signal completion
echo "DONE" > "$PROJECT_DIR/.claude/context/.capture-complete"
