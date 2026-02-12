#!/bin/bash
# capture-jarvis.sh — Capture W0:Jarvis pane output via tmux
#
# Used by Jarvis-dev (W5) to read what W0 is displaying.
# Wrapper around tmux capture-pane with filtering options.
#
# Usage: capture-jarvis.sh [--tail N] [--file PATH] [--grep PATTERN]
#
# Exit codes: 0=success, 1=error, 2=session-not-found
#
# Part of Jarvis dev-ops testing infrastructure.
set -euo pipefail

# ─── Configuration ──────────────────────────────────────────────────────────
TMUX_BIN="${TMUX_BIN:-$HOME/bin/tmux}"
SESSION="${TMUX_SESSION:-jarvis}"
TARGET="${SESSION}:0"
TAIL_LINES=""
OUTPUT_FILE=""
GREP_PATTERN=""
HISTORY_LINES=""

# ─── Usage ──────────────────────────────────────────────────────────────────
show_usage() {
    cat <<EOF
capture-jarvis.sh — Capture W0:Jarvis pane output

Usage: capture-jarvis.sh [options]

Options:
  --tail N            Show only last N lines (default: all visible)
  --file PATH         Write to file instead of stdout
  --grep PATTERN      Filter output lines matching PATTERN (extended regex)
  --history N         Capture N lines of scrollback (default: visible only)
  --target W:P        Override tmux target (default: \$TMUX_SESSION:0)
  -h, --help          Show this help

Exit codes:
  0  Success
  1  Error (no output, grep no match)
  2  Session not found
EOF
    exit 0
}

# ─── Argument Parsing ──────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
    case $1 in
        --tail)    TAIL_LINES="$2"; shift 2 ;;
        --file)    OUTPUT_FILE="$2"; shift 2 ;;
        --grep)    GREP_PATTERN="$2"; shift 2 ;;
        --history) HISTORY_LINES="$2"; shift 2 ;;
        --target)  TARGET="$2"; shift 2 ;;
        -h|--help) show_usage ;;
        *)         shift ;;
    esac
done

# ─── Session Validation ───────────────────────────────────────────────────
if ! "$TMUX_BIN" has-session -t "$SESSION" 2>/dev/null; then
    echo "ERROR: tmux session '$SESSION' not found" >&2
    exit 2
fi

# ─── Capture ──────────────────────────────────────────────────────────────
capture_args=(-t "$TARGET" -p)

# Add scrollback history if requested
if [[ -n "$HISTORY_LINES" ]]; then
    capture_args+=(-S "-$HISTORY_LINES")
fi

output=$("$TMUX_BIN" capture-pane "${capture_args[@]}" 2>/dev/null) || {
    echo "ERROR: Failed to capture pane $TARGET" >&2
    exit 1
}

# ─── Filtering ─────────────────────────────────────────────────────────────

# Apply tail filter
if [[ -n "$TAIL_LINES" ]]; then
    output=$(echo "$output" | tail -n "$TAIL_LINES")
fi

# Apply grep filter
if [[ -n "$GREP_PATTERN" ]]; then
    output=$(echo "$output" | grep -E "$GREP_PATTERN" || true)
    if [[ -z "$output" ]]; then
        exit 1  # No matches
    fi
fi

# ─── Output ────────────────────────────────────────────────────────────────

if [[ -n "$OUTPUT_FILE" ]]; then
    echo "$output" > "$OUTPUT_FILE"
else
    echo "$output"
fi

exit 0
