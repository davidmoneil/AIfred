#!/bin/bash
# ============================================================================
# JICM v5 - Submission Hypothesis Test
# ============================================================================
# PURPOSE: Test different ways of combining text + submission signal to
#          understand WHY some patterns work and others fail
#
# METHODOLOGY RECORD: This script is preserved as documentation of the
#                     hypothesis testing methodology.
#                     Archived copy: projects/project-aion/experiments/tmux-submission-2026-02-04/
#
# RESULTS (2026-02-04):
#   ✅ A (Separate with sleep): WORKS - text → sleep → C-m
#   ❌ B (Combined literal): FAILS - CR embedded in -l string
#   ✅ C (Combined args): WORKS - text → immediate C-m
#   ❌ D (Variable with CR): FAILS - CR in variable still literal
#   ✅ E (No sleep): WORKS - sleep is optional
#   ✅ F (Enter key): WORKS - Enter equivalent to C-m
#
# ROOT CAUSE: The -l flag makes EVERYTHING literal, including CR.
#             Submit MUST be a separate tmux key event (C-m or Enter).
#
# See: lessons/tmux-self-injection-limitation.md
#      projects/project-aion/experiments/tmux-submission-2026-02-04/experiment-report.md
#
# USAGE: Run from EXTERNAL terminal while Claude Code is at idle prompt
#        DO NOT run from within Claude Code (self-injection fails)
#
# Compatible with bash 3.2+ (macOS default)
# ============================================================================

set -euo pipefail

TMUX_BIN="${TMUX_BIN:-$HOME/bin/tmux}"
TMUX_SESSION="${TMUX_SESSION:-jarvis}"
TMUX_TARGET="${TMUX_SESSION}:0"
RESULTS_FILE="/tmp/jicm-hypothesis-test-results.txt"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${BLUE}[TEST]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
fail() { echo -e "${RED}[FAIL]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

check_prereqs() {
    if ! "$TMUX_BIN" has-session -t "$TMUX_SESSION" 2>/dev/null; then
        fail "tmux session '$TMUX_SESSION' not found"
        exit 1
    fi
    log "Prerequisites OK"
}

clear_buffer() {
    "$TMUX_BIN" send-keys -t "$TMUX_TARGET" C-c 2>/dev/null || true
    sleep 0.1
    "$TMUX_BIN" send-keys -t "$TMUX_TARGET" C-u 2>/dev/null || true
    sleep 0.3
}

# Hypothesis A: Separate calls (what test script does)
test_hypothesis_A() {
    log "Hypothesis A: Separate calls (text, sleep, C-m)"
    log "  Step 1: send-keys -l 'text'"
    log "  Step 2: sleep 0.2"
    log "  Step 3: send-keys C-m"

    clear_buffer
    sleep 0.5

    "$TMUX_BIN" send-keys -t "$TMUX_TARGET" -l "HYPOTHESIS-A-SEPARATE-CALLS"
    sleep 0.2
    "$TMUX_BIN" send-keys -t "$TMUX_TARGET" C-m
}

# Hypothesis B: Combined literal (text + CR in one -l string)
test_hypothesis_B() {
    log "Hypothesis B: Combined literal (text + CR in single -l)"
    log "  Command: send-keys -l 'text'$'\\r'"

    clear_buffer
    sleep 0.5

    "$TMUX_BIN" send-keys -t "$TMUX_TARGET" -l "HYPOTHESIS-B-COMBINED-LITERAL"$'\r'
}

# Hypothesis C: Combined args (text literal + C-m key in same call)
test_hypothesis_C() {
    log "Hypothesis C: Combined args (text + C-m in same call)"
    log "  Command: send-keys -l 'text' C-m (without -l on C-m)"

    clear_buffer
    sleep 0.5

    # Note: This sends text literally, then C-m as a key sequence
    "$TMUX_BIN" send-keys -t "$TMUX_TARGET" -l "HYPOTHESIS-C-COMBINED-ARGS"
    "$TMUX_BIN" send-keys -t "$TMUX_TARGET" C-m
}

# Hypothesis D: Variable with appended CR
test_hypothesis_D() {
    log "Hypothesis D: Variable with appended CR"
    log "  Variable: TEXT='content'$'\\r'"
    log "  Command: send-keys -l \"\$TEXT\""

    clear_buffer
    sleep 0.5

    local TEXT="HYPOTHESIS-D-VARIABLE-CR"$'\r'
    "$TMUX_BIN" send-keys -t "$TMUX_TARGET" -l "$TEXT"
}

# Hypothesis E: No sleep between text and submit
test_hypothesis_E() {
    log "Hypothesis E: No sleep between text and C-m"
    log "  Step 1: send-keys -l 'text'"
    log "  Step 2: send-keys C-m (immediate, no sleep)"

    clear_buffer
    sleep 0.5

    "$TMUX_BIN" send-keys -t "$TMUX_TARGET" -l "HYPOTHESIS-E-NO-SLEEP"
    "$TMUX_BIN" send-keys -t "$TMUX_TARGET" C-m
}

# Hypothesis F: Enter instead of C-m
test_hypothesis_F() {
    log "Hypothesis F: Using Enter key name"
    log "  Step 1: send-keys -l 'text'"
    log "  Step 2: send-keys Enter"

    clear_buffer
    sleep 0.5

    "$TMUX_BIN" send-keys -t "$TMUX_TARGET" -l "HYPOTHESIS-F-ENTER-KEY"
    sleep 0.2
    "$TMUX_BIN" send-keys -t "$TMUX_TARGET" Enter
}

run_test() {
    local hypothesis="$1"

    echo ""
    echo "========================================"
    "test_hypothesis_${hypothesis}"
    echo "========================================"

    sleep 3

    echo ""
    echo -e "${YELLOW}Did hypothesis $hypothesis submit successfully? (y/n/s=skip):${NC} "
    read -r result

    case "$result" in
        y|Y)
            success "Hypothesis $hypothesis WORKS"
            echo "HYPOTHESIS_${hypothesis}=SUCCESS" >> "$RESULTS_FILE"
            ;;
        s|S)
            warn "Hypothesis $hypothesis SKIPPED"
            echo "HYPOTHESIS_${hypothesis}=SKIPPED" >> "$RESULTS_FILE"
            ;;
        *)
            fail "Hypothesis $hypothesis FAILED"
            echo "HYPOTHESIS_${hypothesis}=FAILED" >> "$RESULTS_FILE"
            ;;
    esac
}

main() {
    echo "========================================"
    echo "  JICM Submission Hypothesis Tester"
    echo "========================================"

    check_prereqs

    echo "# Hypothesis Test Results - $(date)" > "$RESULTS_FILE"
    echo "" >> "$RESULTS_FILE"

    warn "Make sure Claude Code is at idle prompt"
    echo "Press Enter to begin, Ctrl+C to cancel..."
    read -r

    for h in A B C D E F; do
        run_test "$h"
        clear_buffer
        sleep 1
    done

    echo ""
    echo "========================================"
    echo "         RESULTS SUMMARY"
    echo "========================================"
    cat "$RESULTS_FILE"
    echo "========================================"
}

# Allow running single hypothesis
if [[ "${1:-}" =~ ^[A-F]$ ]]; then
    check_prereqs
    run_test "$1"
else
    main
fi
