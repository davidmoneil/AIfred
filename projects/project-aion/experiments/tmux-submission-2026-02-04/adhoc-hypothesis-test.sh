#!/bin/bash
# Ad Hoc Hypothesis Test - Run directly from Claude
# Testing: Does variable concatenation (text+CR) work vs separate calls?
#
# NOTE: Running this from within Claude Code sends keystrokes to THIS session,
# which may explain why ad hoc tests fail while external scripts succeed.

TMUX_BIN="$HOME/bin/tmux"
TMUX_TARGET="jarvis:0"

echo "=== Ad Hoc Submission Hypothesis Test ==="
echo ""

# Check tmux session exists
if ! "$TMUX_BIN" has-session -t jarvis 2>/dev/null; then
    echo "ERROR: jarvis tmux session not found"
    exit 1
fi

echo "Testing 3 approaches in sequence..."
echo "Watch the Claude Code window for submissions."
echo ""

# Clear any existing input first
"$TMUX_BIN" send-keys -t "$TMUX_TARGET" C-c 2>/dev/null || true
sleep 0.1
"$TMUX_BIN" send-keys -t "$TMUX_TARGET" C-u 2>/dev/null || true
sleep 0.5

echo "[Test 1] Separate calls with sleep (what test script does)..."
"$TMUX_BIN" send-keys -t "$TMUX_TARGET" -l "ADHOC-TEST-1-SEPARATE-WITH-SLEEP"
sleep 0.2
"$TMUX_BIN" send-keys -t "$TMUX_TARGET" C-m
echo "  Sent: text, sleep 0.2s, C-m"
sleep 3

# Clear
"$TMUX_BIN" send-keys -t "$TMUX_TARGET" C-c 2>/dev/null || true
sleep 0.1
"$TMUX_BIN" send-keys -t "$TMUX_TARGET" C-u 2>/dev/null || true
sleep 0.5

echo "[Test 2] Variable concatenation (text+CR in one variable)..."
PROMPT_WITH_CR="ADHOC-TEST-2-VAR-CONCAT"$'\r'
"$TMUX_BIN" send-keys -t "$TMUX_TARGET" -l "$PROMPT_WITH_CR"
echo "  Sent: single -l with text+CR variable"
sleep 3

# Clear
"$TMUX_BIN" send-keys -t "$TMUX_TARGET" C-c 2>/dev/null || true
sleep 0.1
"$TMUX_BIN" send-keys -t "$TMUX_TARGET" C-u 2>/dev/null || true
sleep 0.5

echo "[Test 3] Immediate separate calls (no sleep)..."
"$TMUX_BIN" send-keys -t "$TMUX_TARGET" -l "ADHOC-TEST-3-IMMEDIATE"
"$TMUX_BIN" send-keys -t "$TMUX_TARGET" C-m
echo "  Sent: text, C-m (no sleep between)"
sleep 3

echo ""
echo "=== Test Complete ==="
echo "Check Claude Code window to see which tests submitted successfully."
