#!/bin/bash
# ============================================================================
# JICM v5 - Submission Method Test Script
# ============================================================================
# PURPOSE: Determine which tmux send-keys method successfully submits prompts
#          to Claude Code's Ink-based TUI
#
# METHODOLOGY RECORD: This script is preserved as documentation of the testing
#                     methodology used to validate JICM submission patterns.
#                     Archived copy: projects/project-aion/experiments/tmux-submission-2026-02-04/
#
# RESULTS (2026-02-03):
#   ✅ Method 1 (C-m): WORKS
#   ✅ Method 2 (-l $'\r'): WORKS (as separate call)
#   ❌ Method 3 (-l $'\n'): FAILS
#   ❌ Method 4 (-l $'\r\n'): FAILS
#   ✅ Method 5 (Enter): WORKS
#   ❌ Method 6 (Escape C-m): FAILS
#   ❌ Method 7 (C-m C-m): FAILS
#
# KEY FINDING: Submit must be a SEPARATE send-keys call from the text.
#              See: lessons/tmux-self-injection-limitation.md
#
# USAGE: Run from EXTERNAL terminal while Claude Code is at idle prompt
#        DO NOT run from within Claude Code (self-injection fails)
#
# Compatible with bash 3.2+ (macOS default)
# ============================================================================

set -euo pipefail

# Configuration
TMUX_BIN="${TMUX_BIN:-$HOME/bin/tmux}"
TMUX_SESSION="${TMUX_SESSION:-jarvis}"
TMUX_TARGET="${TMUX_SESSION}:0"
RESULTS_FILE="/tmp/jicm-submission-test-results.txt"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() { echo -e "${BLUE}[TEST]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
fail() { echo -e "${RED}[FAIL]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

# Check prerequisites
check_prereqs() {
    if ! command -v "$TMUX_BIN" &> /dev/null; then
        fail "tmux not found at $TMUX_BIN"
        exit 1
    fi

    if ! "$TMUX_BIN" has-session -t "$TMUX_SESSION" 2>/dev/null; then
        fail "tmux session '$TMUX_SESSION' not found"
        exit 1
    fi

    log "Prerequisites OK - tmux session '$TMUX_SESSION' exists"
}

# Send prompt text (used by most methods)
send_prompt_text() {
    local text="$1"
    "$TMUX_BIN" send-keys -t "$TMUX_TARGET" -l "$text"
    sleep 0.2
}

# Clear any existing text in buffer
clear_buffer() {
    # Send Ctrl+C to cancel, then Ctrl+U to clear line
    "$TMUX_BIN" send-keys -t "$TMUX_TARGET" C-c
    sleep 0.1
    "$TMUX_BIN" send-keys -t "$TMUX_TARGET" C-u
    sleep 0.3
}

# Method descriptions (indexed array, bash 3.2 compatible)
get_method_desc() {
    case "$1" in
        1) echo "C-m (Standard Enter)" ;;
        2) echo "-l CR (Literal Carriage Return)" ;;
        3) echo "-l LF (Literal Line Feed)" ;;
        4) echo "-l CRLF (Literal CR+LF)" ;;
        5) echo "Enter (tmux Enter key)" ;;
        6) echo "Escape C-m (Escape + Enter)" ;;
        7) echo "C-m C-m (Double Enter)" ;;
        *) echo "Unknown method" ;;
    esac
}

test_method_1() {
    # Standard C-m
    "$TMUX_BIN" send-keys -t "$TMUX_TARGET" C-m
}

test_method_2() {
    # Literal CR
    "$TMUX_BIN" send-keys -t "$TMUX_TARGET" -l $'\r'
}

test_method_3() {
    # Literal LF
    "$TMUX_BIN" send-keys -t "$TMUX_TARGET" -l $'\n'
}

test_method_4() {
    # Literal CRLF
    "$TMUX_BIN" send-keys -t "$TMUX_TARGET" -l $'\r\n'
}

test_method_5() {
    # Enter key
    "$TMUX_BIN" send-keys -t "$TMUX_TARGET" Enter
}

test_method_6() {
    # Escape + Enter
    "$TMUX_BIN" send-keys -t "$TMUX_TARGET" Escape
    sleep 0.1
    "$TMUX_BIN" send-keys -t "$TMUX_TARGET" C-m
}

test_method_7() {
    # Double Enter
    "$TMUX_BIN" send-keys -t "$TMUX_TARGET" C-m
    sleep 0.1
    "$TMUX_BIN" send-keys -t "$TMUX_TARGET" C-m
}

# Run a single test
run_test() {
    local method_num="$1"
    local method_desc
    method_desc=$(get_method_desc "$method_num")
    local test_text="JICM-TEST-METHOD-${method_num}"

    echo ""
    log "Testing Method $method_num: $method_desc"
    echo "---"

    # Clear buffer first
    clear_buffer
    sleep 0.5

    # Send test text
    log "Sending test text: '$test_text'"
    send_prompt_text "$test_text"
    sleep 0.3

    # Apply submission method
    log "Applying submission method..."
    "test_method_${method_num}"

    # Wait for response
    sleep 3

    # Ask user for result
    echo ""
    echo -e "${YELLOW}Check the Claude Code window in tmux.${NC}"
    echo "Did the prompt submit and get a response? (y/n/s=skip): "
    read -r result

    case "$result" in
        y|Y)
            success "Method $method_num WORKS: $method_desc"
            echo "METHOD_${method_num}=SUCCESS" >> "$RESULTS_FILE"
            return 0
            ;;
        s|S)
            warn "Method $method_num SKIPPED"
            echo "METHOD_${method_num}=SKIPPED" >> "$RESULTS_FILE"
            return 2
            ;;
        *)
            fail "Method $method_num FAILED: $method_desc"
            echo "METHOD_${method_num}=FAILED" >> "$RESULTS_FILE"
            return 1
            ;;
    esac
}

# Summary
print_summary() {
    echo ""
    echo "========================================"
    echo "         TEST RESULTS SUMMARY"
    echo "========================================"

    local working_methods=""
    local first_working=""

    for i in 1 2 3 4 5 6 7; do
        local result
        result=$(grep "METHOD_${i}=" "$RESULTS_FILE" 2>/dev/null | cut -d= -f2 || echo "")
        local method_desc
        method_desc=$(get_method_desc "$i")

        case "$result" in
            SUCCESS)
                success "Method $i: $method_desc - WORKS"
                if [[ -z "$first_working" ]]; then
                    first_working="$i"
                fi
                working_methods="$working_methods $i"
                ;;
            FAILED)
                fail "Method $i: $method_desc - FAILED"
                ;;
            SKIPPED)
                warn "Method $i: $method_desc - SKIPPED"
                ;;
            *)
                echo "Method $i: $method_desc - NOT TESTED"
                ;;
        esac
    done

    echo ""
    echo "========================================"

    if [[ -n "$first_working" ]]; then
        success "Working methods:$working_methods"
        echo ""
        local recommended_desc
        recommended_desc=$(get_method_desc "$first_working")
        echo "Recommended: Use Method $first_working ($recommended_desc) as primary"

        # Write recommendation
        echo "" >> "$RESULTS_FILE"
        echo "RECOMMENDED=$first_working" >> "$RESULTS_FILE"
        echo "RECOMMENDED_DESC=$recommended_desc" >> "$RESULTS_FILE"
    else
        fail "No working methods found!"
        echo "Consider alternative approaches:"
        echo "  - Check Claude Code input settings"
        echo "  - Try pexpect/expect"
        echo "  - Investigate bracketed paste mode"
    fi

    echo ""
    echo "Full results saved to: $RESULTS_FILE"
}

# Main
main() {
    echo "========================================"
    echo "    JICM v5 Submission Method Tester"
    echo "========================================"
    echo ""

    check_prereqs

    # Clear previous results
    echo "# JICM Submission Method Test Results" > "$RESULTS_FILE"
    echo "# $(date)" >> "$RESULTS_FILE"
    echo "" >> "$RESULTS_FILE"

    echo ""
    warn "IMPORTANT: Make sure Claude Code is at an idle prompt (❯) in the tmux session"
    echo "Press Enter to begin testing, or Ctrl+C to cancel..."
    read -r

    # Test each method
    for i in 1 2 3 4 5 6 7; do
        run_test "$i" || true  # Continue even if test fails

        # Clear buffer between tests
        clear_buffer
        sleep 1
    done

    print_summary
}

# Run with specific method
if [[ "${1:-}" =~ ^[1-7]$ ]]; then
    check_prereqs
    run_test "$1"
else
    main
fi
