#!/bin/bash
# ============================================================================
# Ad Hoc Hypothesis Test - DEMONSTRATES SELF-INJECTION FAILURE
# ============================================================================
# PURPOSE: This script was created to demonstrate that running tmux send-keys
#          from WITHIN Claude Code to the SAME session fails unpredictably.
#
# METHODOLOGY RECORD: Preserved as documentation of the self-injection failure mode.
#                     Archived copy: projects/project-aion/experiments/tmux-submission-2026-02-04/
#
# RESULT (2026-02-04): FAILS with exit 137 (SIGKILL) and multiple unexpected
#                      UserPromptSubmit hook events.
#
# ROOT CAUSE: When Claude Code executes a Bash command that sends tmux send-keys
#             to its own session, the TUI event loop is blocked. Keystrokes queue
#             and are processed unpredictably when control returns.
#
# LESSON: Prompt injection ONLY works from EXTERNAL processes (jarvis-watcher.sh).
#         See: lessons/tmux-self-injection-limitation.md
#
# WARNING: Running this script from within Claude Code will cause issues.
#          It exists only as documentation of what NOT to do.
# ============================================================================

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
