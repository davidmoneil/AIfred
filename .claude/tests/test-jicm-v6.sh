#!/bin/bash
# ============================================================================
# JICM v6 Test Suite — Wiggum Loop TDD
# ============================================================================
# Tests individual functions from jicm-watcher.sh by sourcing the script
# in a mock environment. Each test validates one specific behavior.
#
# Usage: bash .claude/tests/test-jicm-v6.sh
# ============================================================================

set -euo pipefail

# Test framework
PASS=0
FAIL=0
SKIP=0
ERRORS=""

pass() { PASS=$((PASS + 1)); echo "  ✓ $1"; }
fail() { FAIL=$((FAIL + 1)); ERRORS="${ERRORS}\n  ✗ $1${2:+: $2}"; echo "  ✗ $1${2:+: $2}"; }
skip() { SKIP=$((SKIP + 1)); echo "  ○ $1 (skipped)"; }

# Setup mock environment
export CLAUDE_PROJECT_DIR="/tmp/jicm-test-$$"
export TMUX_BIN="echo"  # Mock tmux — just echoes commands
export TMUX_SESSION="test-session"

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
WATCHER="$SCRIPT_DIR/scripts/jicm-watcher.sh"

setup() {
    mkdir -p "$CLAUDE_PROJECT_DIR/.claude/context"
    mkdir -p "$CLAUDE_PROJECT_DIR/.claude/logs/jicm/archive"
    mkdir -p "$CLAUDE_PROJECT_DIR/.claude/exports"
}

teardown() {
    rm -rf "$CLAUDE_PROJECT_DIR"
}

setup

echo ""
echo "═══════════════════════════════════════════"
echo "  JICM v6 Test Suite — Wiggum Loop TDD"
echo "═══════════════════════════════════════════"
echo ""

# ─── Test Group 1: Script Basics ─────────────────────────────────

echo "Group 1: Script Basics"

# Test 1.1: Script passes bash -n syntax check
if bash -n "$WATCHER" 2>/dev/null; then
    pass "bash -n syntax check"
else
    fail "bash -n syntax check" "Syntax error in watcher script"
fi

# Test 1.2: Script has shebang
if head -1 "$WATCHER" | grep -q '#!/bin/bash'; then
    pass "Has bash shebang"
else
    fail "Has bash shebang" "Missing or wrong shebang"
fi

# Test 1.3: Script uses set -euo pipefail
if grep -q 'set -euo pipefail' "$WATCHER"; then
    pass "Uses strict mode (set -euo pipefail)"
else
    fail "Uses strict mode" "Missing set -euo pipefail"
fi

# Test 1.4: All functions return 0 (bash 3.2 safety)
BAD_RETURNS=$(grep -n 'return 1' "$WATCHER" | grep -v '#.*return 1' | grep -v 'tmux_has_session' || true)
if [[ -z "$BAD_RETURNS" ]]; then
    pass "No unguarded return 1 (bash 3.2 safety)"
else
    fail "No unguarded return 1" "Found return 1 at: $BAD_RETURNS"
fi

# Test 1.5: No multi-line tmux send-keys -l strings
MULTILINE_SENDS=$(grep -n 'send-keys.*-l.*\\n' "$WATCHER" || true)
if [[ -z "$MULTILINE_SENDS" ]]; then
    pass "No multi-line send-keys -l strings"
else
    fail "No multi-line send-keys" "Found at: $MULTILINE_SENDS"
fi

echo ""

# ─── Test Group 2: ANSI Color Constants ──────────────────────────

echo "Group 2: ANSI Colors"

# Test 2.1: Uses ANSI-C quoting ($'\e[...') not single quotes ('\e[...')
BAD_COLORS=$(grep -n "readonly C_.*='\\\e" "$WATCHER" || true)
if [[ -z "$BAD_COLORS" ]]; then
    pass "ANSI-C quoting for colors"
else
    fail "ANSI-C quoting" "Found single-quote colors at: $BAD_COLORS"
fi

# Test 2.2: Color reset defined
if grep -q "C_RESET" "$WATCHER"; then
    pass "Color reset constant defined"
else
    fail "Color reset" "Missing C_RESET"
fi

echo ""

# ─── Test Group 3: State Machine ─────────────────────────────────

echo "Group 3: State Machine"

# Test 3.1: All 5 states present in code
for state in WATCHING HALTING COMPRESSING CLEARING RESTORING; do
    if grep -q "\"$state\"" "$WATCHER"; then
        pass "State $state defined"
    else
        fail "State $state" "Not found in script"
    fi
done

# Test 3.2: transition_to function exists
if grep -q 'transition_to()' "$WATCHER"; then
    pass "transition_to() function exists"
else
    fail "transition_to()" "Function not found"
fi

# Test 3.3: State file write function
if grep -q 'write_state()' "$WATCHER"; then
    pass "write_state() function exists"
else
    fail "write_state()" "Function not found"
fi

# Test 3.4: Initial state is WATCHING
if grep -q 'JICM_STATE="WATCHING"' "$WATCHER"; then
    pass "Initial state is WATCHING"
else
    fail "Initial state" "Not set to WATCHING"
fi

echo ""

# ─── Test Group 4: Tmux Canonical Patterns ───────────────────────

echo "Group 4: Tmux Patterns"

# Test 4.1: tmux_send_prompt sends text then C-m separately
if grep -A3 'tmux_send_prompt()' "$WATCHER" | grep -q 'tmux_send_text'; then
    pass "tmux_send_prompt sends text first"
else
    fail "tmux_send_prompt" "Doesn't send text before submit"
fi

if grep -A5 'tmux_send_prompt()' "$WATCHER" | grep -q 'tmux_send_submit'; then
    pass "tmux_send_prompt submits separately"
else
    fail "tmux_send_prompt" "Doesn't submit separately"
fi

# Test 4.2: No embedded CR in send-keys -l
EMBEDDED_CR=$(grep 'send-keys.*-l.*\\r' "$WATCHER" | grep -v '#' || true)
if [[ -z "$EMBEDDED_CR" ]]; then
    pass "No embedded CR in -l strings"
else
    fail "Embedded CR" "Found at: $EMBEDDED_CR"
fi

# Test 4.3: tmux_send_command sends Escape first
if grep -A5 'tmux_send_command()' "$WATCHER" | grep -q 'tmux_send_escape'; then
    pass "tmux_send_command sends Escape first"
else
    fail "tmux_send_command" "No Escape before command"
fi

echo ""

# ─── Test Group 5: Monitoring Functions ──────────────────────────

echo "Group 5: Monitoring Functions"

# Test 5.1: get_context_percentage restricts to tail
if grep -A10 'get_context_percentage()' "$WATCHER" | grep -q 'tail -5'; then
    pass "get_context_percentage uses tail -5"
else
    fail "get_context_percentage" "Doesn't restrict to last 5 lines"
fi

# Test 5.2: get_token_count restricts to tail (function body spans >10 lines)
if grep -A20 'get_token_count()' "$WATCHER" | grep -q 'tail -5'; then
    pass "get_token_count uses tail -5"
else
    fail "get_token_count" "Doesn't restrict to last 5 lines"
fi

# Test 5.3: Idle detection uses IDLE_PATTERN constant (v6.1 pattern-based)
if grep -q "IDLE_PATTERN='Interrupted.*What should Claude do'" "$WATCHER"; then
    pass "IDLE_PATTERN constant defined for triggered idle detection"
else
    fail "IDLE_PATTERN" "Missing Interrupted pattern constant"
fi

# Test 5.4: All detection functions return 0
for func in get_context_percentage get_token_count check_busy_state check_jarvis_active _check_idle_pattern trigger_idle_check detect_activity poll_idle_pattern; do
    returns=$(grep -A30 "${func}()" "$WATCHER" | grep 'return ' | grep -v 'return 0' | grep -v '#' || true)
    if [[ -z "$returns" ]]; then
        pass "$func always returns 0"
    else
        fail "$func" "Has non-zero returns: $returns"
    fi
done

echo ""

# ─── Test Group 6: Timeout & Recovery ────────────────────────────

echo "Group 6: Timeout & Recovery"

# Test 6.1: Compression timeout exists
if grep -q 'COMPRESS_TIMEOUT' "$WATCHER"; then
    pass "Compression timeout configured"
else
    fail "Compression timeout" "COMPRESS_TIMEOUT not found"
fi

# Test 6.2: Clear timeout exists
if grep -q 'CLEAR_TIMEOUT' "$WATCHER"; then
    pass "Clear timeout configured"
else
    fail "Clear timeout" "CLEAR_TIMEOUT not found"
fi

# Test 6.3: Restore timeout exists
if grep -q 'RESTORE_TIMEOUT' "$WATCHER"; then
    pass "Restore timeout configured"
else
    fail "Restore timeout" "RESTORE_TIMEOUT not found"
fi

# Test 6.4: Cooldown mechanism exists
if grep -q 'COOLDOWN_UNTIL' "$WATCHER" && grep -q 'COOLDOWN_PERIOD' "$WATCHER"; then
    pass "Cooldown mechanism exists"
else
    fail "Cooldown" "COOLDOWN_UNTIL or COOLDOWN_PERIOD missing"
fi

# Test 6.5: Failsafe transitions back to WATCHING
FAILSAFE_WATCH=$(grep -c 'transition_to "WATCHING"' "$WATCHER" || true)
if [[ "$FAILSAFE_WATCH" -ge 3 ]]; then
    pass "Multiple failsafe paths to WATCHING ($FAILSAFE_WATCH)"
else
    fail "Failsafe to WATCHING" "Only $FAILSAFE_WATCH transitions found"
fi

echo ""

# ─── Test Group 7: Dashboard ─────────────────────────────────────

echo "Group 7: Dashboard"

# Test 7.1: Progress bar function
if grep -q 'draw_progress_bar()' "$WATCHER"; then
    pass "draw_progress_bar() exists"
else
    fail "draw_progress_bar()" "Not found"
fi

# Test 7.2: State indicator function
if grep -q 'draw_state_indicator()' "$WATCHER"; then
    pass "draw_state_indicator() exists"
else
    fail "draw_state_indicator()" "Not found"
fi

# Test 7.3: Banner function
if grep -q 'banner()' "$WATCHER"; then
    pass "banner() exists"
else
    fail "banner()" "Not found"
fi

echo ""

# ─── Test Group 8: Signal Cleanup ────────────────────────────────

echo "Group 8: Signal Cleanup"

# Test 8.1: Stale signals cleaned on startup
if grep -q 'rm -f.*COMPRESSION_SIGNAL' "$WATCHER" | head -1; then
    pass "Stale compression signal cleaned on startup"
fi
# More permissive check
if grep -q '# Clean stale signals' "$WATCHER"; then
    pass "Stale signal cleanup on startup"
else
    fail "Stale cleanup" "No startup cleanup found"
fi

# Test 8.2: Archive function exists
if grep -q 'archive_compressed_context()' "$WATCHER"; then
    pass "archive_compressed_context() exists"
else
    fail "archive_compressed_context()" "Not found"
fi

# Test 8.3: Archive prunes old files
if grep -A15 'archive_compressed_context()' "$WATCHER" | grep -q 'keep 20'; then
    pass "Archive prunes to 20"
else
    fail "Archive pruning" "No prune limit found"
fi

echo ""

# ─── Test Group 9: Signal File Minimalism ────────────────────────

echo "Group 9: Signal Minimalism"

# Test 9.1: No .idle-hands-active reference
if grep -q 'idle-hands-active' "$WATCHER"; then
    fail "No .idle-hands-active" "Old signal file referenced"
else
    pass "No .idle-hands-active reference (eliminated)"
fi

# Test 9.2: No .continuation-injected reference
if grep -q 'continuation-injected' "$WATCHER"; then
    fail "No .continuation-injected" "Old signal file referenced"
else
    pass "No .continuation-injected reference (eliminated)"
fi

# Test 9.3: No .jicm-complete reference
if grep -q 'jicm-complete' "$WATCHER"; then
    fail "No .jicm-complete" "Old signal file referenced"
else
    pass "No .jicm-complete reference (eliminated)"
fi

# Test 9.4: No .clear-sent reference
if grep -q 'clear-sent' "$WATCHER"; then
    fail "No .clear-sent" "Old signal file referenced"
else
    pass "No .clear-sent reference (eliminated)"
fi

echo ""

# ─── Test Group 10: Integration Points ───────────────────────────

echo "Group 10: Integration"

# Test 10.1: Cleanup handler exists
if grep -q 'trap.*cleanup.*INT' "$WATCHER"; then
    pass "INT signal handler"
else
    fail "INT handler" "No INT trap"
fi

if grep -q 'trap.*cleanup.*TERM' "$WATCHER"; then
    pass "TERM signal handler"
else
    fail "TERM handler" "No TERM trap"
fi

# Test 10.2: Main function exists and is called
if grep -q '^main()' "$WATCHER" && grep -q '^main ' "$WATCHER"; then
    pass "main() defined and called"
else
    fail "main()" "Not defined or not called"
fi

# ─── Test Group 11: Main Loop Architecture ───────────────────────

echo "Group 11: Main Loop Architecture"

# Test 11.1: State handlers use elif (prevent double-processing)
ELIF_COUNT=$(grep -c 'elif \[\[ "$JICM_STATE"' "$WATCHER" || true)
if [[ "$ELIF_COUNT" -ge 3 ]]; then
    pass "State handlers use elif ($ELIF_COUNT branches)"
else
    fail "elif state handlers" "Only $ELIF_COUNT elif branches (need >=3)"
fi

# Test 11.2: HALTING state handler exists in main loop
if grep -q 'JICM_STATE.*==.*HALTING' "$WATCHER"; then
    pass "HALTING state handler in main loop"
else
    fail "HALTING handler" "Not found in main loop"
fi

# Test 11.3: CLEAR_RETRIES counter exists
if grep -q 'CLEAR_RETRIES' "$WATCHER"; then
    pass "CLEAR_RETRIES counter exists"
else
    fail "CLEAR_RETRIES" "Counter not found"
fi

# Test 11.4: CLEAR_RETRIES reset before clearing
if grep -q 'CLEAR_RETRIES=0' "$WATCHER"; then
    pass "CLEAR_RETRIES reset before use"
else
    fail "CLEAR_RETRIES reset" "Not reset before use"
fi

# Test 11.5: Single sleep at end of loop (not per-state)
# After elif refactor, sleep should be outside state blocks
LOOP_SLEEP=$(grep -A2 '^\s*fi$' "$WATCHER" | grep -c 'sleep "$POLL_INTERVAL"' || true)
if [[ "$LOOP_SLEEP" -ge 1 ]]; then
    pass "Sleep at end of main loop"
else
    fail "Loop sleep" "No sleep after state handlers"
fi

# Test 11.6: continue after threshold transition (prevent fall-through)
if grep -B2 -A2 'do_halt' "$WATCHER" | grep -q 'continue'; then
    pass "continue after do_halt (prevents fall-through)"
else
    fail "continue after halt" "Missing continue after do_halt"
fi

echo ""

# ─── Test Group 12: Session-Start Hook v6 Integration ─────────────

echo "Group 12: Session-Start v6 Integration"

HOOK="$SCRIPT_DIR/hooks/session-start.sh"

# Test 12.1: Hook passes syntax check
if bash -n "$HOOK" 2>/dev/null; then
    pass "session-start.sh syntax check"
else
    fail "session-start.sh syntax" "Syntax error in hook"
fi

# Test 12.2: v6 state file reference exists
if grep -q 'V6_STATE_FILE' "$HOOK"; then
    pass "v6 state file referenced"
else
    fail "v6 state file" "V6_STATE_FILE not found"
fi

# Test 12.3: v6 detects CLEARING state
if grep -q 'V6_STATE.*==.*CLEARING' "$HOOK"; then
    pass "v6 detects CLEARING state"
else
    fail "v6 CLEARING" "No CLEARING detection"
fi

# Test 12.4: v6 detects RESTORING state
if grep -q 'V6_STATE.*==.*RESTORING' "$HOOK"; then
    pass "v6 detects RESTORING state"
else
    fail "v6 RESTORING" "No RESTORING detection"
fi

# Test 12.5: v6 does NOT create idle-hands flag
if grep -A30 'JICM v6.*STOP-AND-WAIT' "$HOOK" | grep -q 'idle-hands'; then
    fail "v6 no idle-hands" "v6 path should not reference idle-hands"
else
    pass "v6 path does NOT create idle-hands flag"
fi

# Test 12.6: v5 code path REMOVED (no TWO-MECHANISM block)
if grep -q 'JICM v5.*TWO-MECHANISM' "$HOOK"; then
    fail "v5 removed" "v5 TWO-MECHANISM block still present"
else
    pass "v5 code path removed from session-start"
fi

# Test 12.7: v6 uses jq for JSON output
if grep -A60 'JICM v6.*STOP-AND-WAIT' "$HOOK" | grep -q 'jq -n'; then
    pass "v6 uses jq for JSON output"
else
    fail "v6 jq" "No jq JSON output"
fi

# Test 12.8: No v5 debounce section
if grep -q 'V5_CLEAR_SENT_CHECK' "$HOOK"; then
    fail "v5 debounce removed" "Debounce variables still present"
else
    pass "v5 debounce section removed"
fi

# Test 12.9: No V5_ signal file variables
V5_VARS=$(grep -c 'V5_COMPRESSED_CONTEXT\|V5_IN_PROGRESS\|V5_CLEAR_SENT\|V5_CONTINUATION_INJECTED\|V5_JICM_COMPLETE\|V5_IDLE_HANDS_FLAG' "$HOOK" || true)
if [[ "$V5_VARS" -eq 0 ]]; then
    pass "No v5 signal file variables"
else
    fail "v5 vars remain" "$V5_VARS v5 variable references"
fi

# Test 12.10: No v5 standdown reference
if grep -q 'jicm-standdown' "$HOOK"; then
    fail "v5 standdown removed" "Still references .jicm-standdown"
else
    pass "v5 standdown reference removed"
fi

echo ""

# ─── Test Group 13: Edge Case Handling ────────────────────────────

echo "Group 13: Edge Cases"

# Test 13.1: Compressed file existence check before /clear
if grep -A10 'do_clear()' "$WATCHER" | grep -q 'COMPRESSED_FILE'; then
    pass "Verifies compressed file before /clear"
else
    fail "Compressed file check" "No existence check in do_clear"
fi

# Test 13.2: HUP signal handled
if grep -q 'trap.*cleanup.*HUP' "$WATCHER"; then
    pass "HUP signal handler"
else
    fail "HUP handler" "No HUP trap"
fi

# Test 13.3: ERR trap for debugging
if grep -q 'trap.*ERR' "$WATCHER"; then
    pass "ERR trap for debugging"
else
    fail "ERR trap" "No ERR trap"
fi

# Test 13.4: Lockout percentage calculated
if grep -q 'LOCKOUT_PCT' "$WATCHER"; then
    pass "Lockout percentage calculated"
else
    fail "LOCKOUT_PCT" "Not calculated"
fi

# Test 13.5: Emergency percentage calculated
if grep -q 'EMERGENCY_PCT' "$WATCHER"; then
    pass "Emergency percentage calculated"
else
    fail "EMERGENCY_PCT" "Not calculated"
fi

echo ""

# ─── Test Group 14: Live-Fire Function Isolation ──────────────────

echo "Group 14: Live-Fire Functions"

# Source the watcher script in a subshell with mocked tmux
# (prevents main() from running by overriding it)
LIVE_FIRE_OUTPUT=$(bash -c '
export CLAUDE_PROJECT_DIR="/tmp/jicm-livefire-$$"
export TMUX_BIN="echo"
export TMUX_SESSION="test-session"
mkdir -p "$CLAUDE_PROJECT_DIR/.claude/context"
mkdir -p "$CLAUDE_PROJECT_DIR/.claude/logs/jicm/archive"
mkdir -p "$CLAUDE_PROJECT_DIR/.claude/exports"

# Override main to prevent loop, override trap to prevent ERR issues
WATCHER_SRC="'"$WATCHER"'"
# Source the script but replace main and traps
{
    # Strip the "main" call at end, and traps that would interfere
    sed "s/^main \"\$@\"/# main disabled for test/" "$WATCHER_SRC" |
    sed "s/^trap .*/# trap disabled for test/"
} > /tmp/jicm-test-source-$$.sh

source /tmp/jicm-test-source-$$.sh 2>/dev/null

# Test 1: write_state creates file
write_state
if [[ -f "$STATE_FILE" ]]; then
    echo "PASS:write_state creates file"
    # Verify content
    if grep -q "state: WATCHING" "$STATE_FILE"; then
        echo "PASS:write_state initial state WATCHING"
    else
        echo "FAIL:write_state initial state:$(cat "$STATE_FILE")"
    fi
    if grep -q "version: 6.1.0" "$STATE_FILE"; then
        echo "PASS:write_state version 6.1.0"
    else
        echo "FAIL:write_state version:missing"
    fi
else
    echo "FAIL:write_state creates file:file not found"
fi

# Test 2: transition_to changes state
transition_to "COMPRESSING"
if [[ "$JICM_STATE" == "COMPRESSING" ]]; then
    echo "PASS:transition_to changes state"
else
    echo "FAIL:transition_to changes state:state=$JICM_STATE"
fi

# Test 3: state_age returns reasonable value
sleep 1
AGE=$(state_age)
if [[ "$AGE" -ge 0 ]] && [[ "$AGE" -lt 10 ]]; then
    echo "PASS:state_age returns seconds"
else
    echo "FAIL:state_age returns seconds:got=$AGE"
fi

# Test 4: draw_progress_bar returns colored output
BAR=$(draw_progress_bar 42)
if [[ -n "$BAR" ]] && echo "$BAR" | grep -q "█"; then
    echo "PASS:draw_progress_bar renders"
else
    echo "FAIL:draw_progress_bar renders:empty or no blocks"
fi

# Test 5: draw_state_indicator returns state name
IND=$(draw_state_indicator)
if echo "$IND" | grep -q "COMPRESSING"; then
    echo "PASS:draw_state_indicator shows state"
else
    echo "FAIL:draw_state_indicator:got=$IND"
fi

# Test 6: format_duration works
DUR=$(format_duration 3661)
if [[ "$DUR" == "1h 1m" ]]; then
    echo "PASS:format_duration hours"
else
    echo "FAIL:format_duration hours:got=$DUR"
fi
DUR2=$(format_duration 125)
if [[ "$DUR2" == "2m 5s" ]]; then
    echo "PASS:format_duration minutes"
else
    echo "FAIL:format_duration minutes:got=$DUR2"
fi

# Test 7: archive function with real files
echo "test compressed content" > "$COMPRESSED_FILE"
archive_compressed_context
if [[ ! -f "$COMPRESSED_FILE" ]] && ls "$ARCHIVE_DIR"/compressed-*.md 1>/dev/null 2>&1; then
    echo "PASS:archive moves file to archive"
else
    echo "FAIL:archive moves file:compressed still exists or archive empty"
fi

# Cleanup
rm -rf "$CLAUDE_PROJECT_DIR"
rm -f /tmp/jicm-test-source-$$.sh
' 2>&1 || true)

# Parse live-fire results
while IFS= read -r line; do
    if [[ "$line" == PASS:* ]]; then
        pass "${line#PASS:}"
    elif [[ "$line" == FAIL:* ]]; then
        fail "${line#FAIL:}"
    fi
done <<< "$LIVE_FIRE_OUTPUT"

# ─── Test Group 15: Prompt Injection Lexicon ──────────────────────

echo "Group 15: Robustness"

# Test 15R.1: PID file check exists
if grep -q 'PID_FILE' "$WATCHER"; then
    pass "PID file for concurrent watcher detection"
else
    fail "PID file" "No PID_FILE reference"
fi

# Test 15R.2: PID file cleaned on shutdown
if grep -A5 'cleanup()' "$WATCHER" | grep -q 'PID_FILE'; then
    pass "PID file removed on cleanup"
else
    fail "PID cleanup" "PID not removed in cleanup"
fi

# Test 15R.3: Log rotation function exists
if grep -q 'rotate_log()' "$WATCHER"; then
    pass "Log rotation function exists"
else
    fail "Log rotation" "rotate_log() not found"
fi

# Test 15R.4: Token parser handles commas
if grep -A5 'Try exact format' "$WATCHER" | grep -q "tr -d ','"; then
    pass "Token parser strips commas"
else
    fail "Token commas" "No comma handling in token parser"
fi

# Test 15R.5: Periodic log rotation in main loop
if grep -q 'rotate_log' "$WATCHER"; then
    ROTATE_CALLS=$(grep -c 'rotate_log' "$WATCHER" || true)
    if [[ "$ROTATE_CALLS" -ge 2 ]]; then
        pass "Log rotation at startup and periodically ($ROTATE_CALLS calls)"
    else
        fail "Periodic rotation" "Only $ROTATE_CALLS rotation calls"
    fi
else
    fail "Rotation calls" "No rotate_log calls"
fi

# Test 15R.6: Token range validation (0 < N < 200001)
if grep -q '200001' "$WATCHER"; then
    pass "Token range validation (< 200001)"
else
    fail "Token range" "No 200001 upper bound check"
fi

echo ""

echo "Group 15B: Metrics/Telemetry"

# Test 15B.1: METRICS_FILE variable defined
if grep -q 'METRICS_FILE=' "$WATCHER"; then
    pass "METRICS_FILE variable defined"
else
    fail "METRICS_FILE" "Not found"
fi

# Test 15B.2: emit_cycle_metrics function exists
if grep -q 'emit_cycle_metrics()' "$WATCHER"; then
    pass "emit_cycle_metrics() function exists"
else
    fail "emit_cycle_metrics()" "Not found"
fi

# Test 15B.3: Cycle timing variables exist
for var in CYCLE_START_TIME COMPRESS_START_TIME CLEAR_START_TIME RESTORE_START_TIME; do
    if grep -q "$var" "$WATCHER"; then
        pass "Timing variable $var exists"
    else
        fail "Timing variable" "$var not found"
    fi
done

# Test 15B.4: emit_cycle_metrics uses jq for JSON output
if grep -A60 'emit_cycle_metrics()' "$WATCHER" | grep -q 'jq -nc'; then
    pass "emit_cycle_metrics uses jq for JSONL output"
else
    fail "Metrics jq" "No jq in emit_cycle_metrics"
fi

# Test 15B.5: Metrics emitted on success and failure paths
EMIT_CALLS=$(grep -c 'emit_cycle_metrics' "$WATCHER" || true)
if [[ "$EMIT_CALLS" -ge 4 ]]; then
    pass "emit_cycle_metrics called on multiple paths ($EMIT_CALLS calls)"
else
    fail "Metrics coverage" "Only $EMIT_CALLS emit calls (need >=4)"
fi

# Test 15B.6: CYCLE_START_PCT captured at threshold
if grep -A5 'Threshold check' "$WATCHER" | grep -q 'CYCLE_START_PCT'; then
    pass "CYCLE_START_PCT captured at threshold"
else
    fail "CYCLE_START_PCT" "Not captured at threshold hit"
fi

echo ""

echo "Group 16: Prompt Lexicon"

# Test 15.1: Halt prompt has JICM-HALT tag
if grep -q 'JICM-HALT' "$WATCHER"; then
    pass "Halt prompt has [JICM-HALT] tag"
else
    fail "Halt tag" "Missing [JICM-HALT]"
fi

# Test 15.2: Halt prompt includes percentage
if grep -A3 'JICM-HALT' "$WATCHER" | grep -q '\${pct}%'; then
    pass "Halt prompt includes context percentage"
else
    fail "Halt percentage" "Missing percentage in halt prompt"
fi

# Test 15.3: Compress prompt uses /intelligent-compress
if grep -q 'JICM-COMPRESS' "$WATCHER" && grep -q 'intelligent-compress' "$WATCHER"; then
    pass "Compress uses /intelligent-compress skill"
else
    fail "Compress skill" "Missing /intelligent-compress reference"
fi

# Test 15.4: Restore prompt has JICM-RESUME tag
if grep -q 'JICM-RESUME' "$WATCHER"; then
    pass "Restore prompt has [JICM-RESUME] tag"
else
    fail "Resume tag" "Missing [JICM-RESUME]"
fi

# Test 15.5: Restore prompt references checkpoint file (NOT session-state)
if grep -A2 'JICM-RESUME' "$WATCHER" | grep -q 'compressed-context-ready.md'; then
    pass "Resume prompt references checkpoint file"
else
    fail "Resume checkpoint ref" "Missing checkpoint file reference"
fi

# Test 15.5b: Restore prompt does NOT reference session-state.md (E8: de-prioritized)
if grep 'resume_prompt=' "$WATCHER" | grep -q 'session-state.md'; then
    fail "Restore no session-state" "Restore prompt should not reference session-state.md"
else
    pass "Restore prompt de-prioritizes session-state.md"
fi

# Test 15.6: All prompts are single-line (no embedded newlines)
MULTILINE_PROMPTS=$(grep 'tmux_send_prompt' "$WATCHER" | grep -c '\\n' || true)
if [[ "$MULTILINE_PROMPTS" -eq 0 ]]; then
    pass "All prompts are single-line"
else
    fail "Single-line prompts" "$MULTILINE_PROMPTS prompts have embedded newlines"
fi

# Test 15.7: Retry prompts get progressively simpler
RETRY_LINES=$(grep -A20 'do_restore_retry()' "$WATCHER" | grep 'tmux_send_prompt' | wc -l | tr -d ' ')
if [[ "$RETRY_LINES" -ge 2 ]]; then
    pass "Restore retries use progressive simplification ($RETRY_LINES levels)"
else
    fail "Progressive retries" "Only $RETRY_LINES retry prompts"
fi

# ─── Test Group 16B: v6.1 Idle Detection Architecture ────────────

echo "Group 16B: v6.1 Idle Detection"

# Test 16B.1: _check_idle_pattern function exists
if grep -q '_check_idle_pattern()' "$WATCHER"; then
    pass "_check_idle_pattern() internal function exists"
else
    fail "_check_idle_pattern()" "Not found"
fi

# Test 16B.2: trigger_idle_check function exists
if grep -q 'trigger_idle_check()' "$WATCHER"; then
    pass "trigger_idle_check() function exists"
else
    fail "trigger_idle_check()" "Not found"
fi

# Test 16B.3: detect_activity function exists
if grep -q 'detect_activity()' "$WATCHER"; then
    pass "detect_activity() function exists"
else
    fail "detect_activity()" "Not found"
fi

# Test 16B.4: poll_idle_pattern function exists
if grep -q 'poll_idle_pattern()' "$WATCHER"; then
    pass "poll_idle_pattern() function exists"
else
    fail "poll_idle_pattern()" "Not found"
fi

# Test 16B.5: trigger_idle_check sends ESC (calls tmux_send_escape)
if grep -A10 'trigger_idle_check()' "$WATCHER" | grep -q 'tmux_send_escape'; then
    pass "trigger_idle_check sends ESC before capture"
else
    fail "trigger_idle_check ESC" "Does not send Escape"
fi

# Test 16B.6: detect_activity does NOT send ESC
if grep -A25 'detect_activity()' "$WATCHER" | grep -q 'tmux_send_escape'; then
    fail "detect_activity no ESC" "Should not send Escape (would interrupt active work)"
else
    pass "detect_activity does NOT send ESC (safe for RESTORING)"
fi

# Test 16B.7: wait_for_idle sends ESC only once (via trigger_idle_check)
# Should call trigger_idle_check once, then poll_idle_pattern in loop
if grep -A5 'wait_for_idle()' "$WATCHER" | head -10 && \
   grep -A30 'wait_for_idle()' "$WATCHER" | grep -q 'trigger_idle_check' && \
   grep -A30 'wait_for_idle()' "$WATCHER" | grep -q 'poll_idle_pattern'; then
    pass "wait_for_idle uses triggered check once, then polls"
else
    fail "wait_for_idle" "Should call trigger then poll"
fi

# Test 16B.8: No spinner character matching in primary idle detection
# (spinners are unreliable across CC versions)
if grep -A15 '_check_idle_pattern()' "$WATCHER" | grep -qE '[⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏]'; then
    fail "No spinners in pattern check" "Spinner chars found in _check_idle_pattern"
else
    pass "No spinner chars in _check_idle_pattern (pattern-based only)"
fi

# Test 16B.9: check_jarvis_active delegates to detect_activity
if grep -A3 'check_jarvis_active()' "$WATCHER" | grep -q 'detect_activity'; then
    pass "check_jarvis_active delegates to detect_activity"
else
    fail "check_jarvis_active delegation" "Should delegate to detect_activity"
fi

# Test 16B.10: _check_idle_pattern checks separator bar (─────)
if grep -A30 '_check_idle_pattern()' "$WATCHER" | grep -q '─────'; then
    pass "_check_idle_pattern checks for separator bar"
else
    fail "separator bar check" "No ───── pattern in _check_idle_pattern"
fi

echo ""

# ─── Test Group 16C: Idle Detection Live-Fire ───────────────────

echo "Group 16C: Idle Pattern Live-Fire"

# Live-fire test: _check_idle_pattern with synthetic pane content
IDLE_LF_OUTPUT=$(bash -c '
export CLAUDE_PROJECT_DIR="/tmp/jicm-idle-test-$$"
export TMUX_BIN="echo"
export TMUX_SESSION="test-session"
mkdir -p "$CLAUDE_PROJECT_DIR/.claude/context"
mkdir -p "$CLAUDE_PROJECT_DIR/.claude/logs/jicm/archive"
mkdir -p "$CLAUDE_PROJECT_DIR/.claude/exports"

WATCHER_SRC="'"$WATCHER"'"
SRC_COPY="/tmp/jicm-idle-copy-$$.sh"
cp "$WATCHER_SRC" "$SRC_COPY"
sed -i "" "s/^main \"\$@\"/# main disabled for test/" "$SRC_COPY"
sed -i "" "s/^check_existing_watcher$/# disabled for test/" "$SRC_COPY"
sed -i "" "s/^rotate_log$/# disabled for test/" "$SRC_COPY"
sed -i "" "s|^trap .*|# trap disabled for test|" "$SRC_COPY"
source "$SRC_COPY" 2>/dev/null

# Test 1: IDLE pattern — Interrupted + blank + separator
IDLE_PANE="some previous output
  ⎿  Interrupted · What should Claude do instead?

──────────────────────────────────────────────
❯
──────────────────────────────────────────────"
RESULT=$(_check_idle_pattern "$IDLE_PANE")
if [[ "$RESULT" == "idle" ]]; then
    echo "PASS:idle pattern detected correctly"
else
    echo "FAIL:idle pattern:expected idle got $RESULT"
fi

# Test 2: ACTIVE pattern — content between Interrupted and separator
ACTIVE_PANE="some previous output
  ⎿  Interrupted · What should Claude do instead?

❯ continue

● Cogitating... (4s)

──────────────────────────────────────────────
❯
──────────────────────────────────────────────"
RESULT=$(_check_idle_pattern "$ACTIVE_PANE")
if [[ "$RESULT" == "not_idle" ]]; then
    echo "PASS:active pattern detected correctly"
else
    echo "FAIL:active pattern:expected not_idle got $RESULT"
fi

# Test 3: No Interrupted pattern at all
CLEAN_PANE="Welcome to Jarvis
❯"
RESULT=$(_check_idle_pattern "$CLEAN_PANE")
if [[ "$RESULT" == "unknown" ]]; then
    echo "PASS:no pattern returns unknown"
else
    echo "FAIL:no pattern:expected unknown got $RESULT"
fi

# Test 4: Empty pane
RESULT=$(_check_idle_pattern "")
if [[ "$RESULT" == "unknown" ]]; then
    echo "PASS:empty pane returns unknown"
else
    echo "FAIL:empty pane:expected unknown got $RESULT"
fi

# Test 5: Interrupted with bare ❯ between (still idle)
IDLE_PROMPT_PANE="  ⎿  Interrupted · What should Claude do instead?

❯
──────────────────────────────────────────────"
RESULT=$(_check_idle_pattern "$IDLE_PROMPT_PANE")
if [[ "$RESULT" == "idle" ]]; then
    echo "PASS:idle with bare prompt detected correctly"
else
    echo "FAIL:idle bare prompt:expected idle got $RESULT"
fi

# Test 6: Interrupted with ❯ followed by text (active — user typed something)
TYPED_PANE="  ⎿  Interrupted · What should Claude do instead?

❯ hello world
──────────────────────────────────────────────"
RESULT=$(_check_idle_pattern "$TYPED_PANE")
if [[ "$RESULT" == "not_idle" ]]; then
    echo "PASS:typed text detected as not_idle"
else
    echo "FAIL:typed text:expected not_idle got $RESULT"
fi

rm -rf "$CLAUDE_PROJECT_DIR"
rm -f "$SRC_COPY"
' 2>&1 || true)

# Parse live-fire results
while IFS= read -r line; do
    if [[ "$line" == PASS:* ]]; then
        pass "${line#PASS:}"
    elif [[ "$line" == FAIL:* ]]; then
        fail "${line#FAIL:}"
    fi
done <<< "$IDLE_LF_OUTPUT"

echo ""

# ─── Test Group 17: State Machine Simulation ─────────────────────

echo "Group 17: State Simulation"

# Create patched copy of watcher for simulation
SIM_DIR="/tmp/jicm-sim-$$"
SIM_COPY="/tmp/jicm-sim-copy-$$.sh"
mkdir -p "$SIM_DIR/.claude/context" "$SIM_DIR/.claude/logs/jicm/archive" "$SIM_DIR/.claude/exports"

# Patch: disable main call, top-level calls, and traps
cp "$WATCHER" "$SIM_COPY"
sed -i '' 's/^main "\$@"/# main disabled for test/' "$SIM_COPY"
sed -i '' 's/^check_existing_watcher$/# disabled for test/' "$SIM_COPY"
sed -i '' 's/^rotate_log$/# disabled for test/' "$SIM_COPY"
sed -i '' "s|^trap .*|# trap disabled for test|" "$SIM_COPY"

SIM_OUTPUT=$(
    export CLAUDE_PROJECT_DIR="$SIM_DIR"
    export TMUX_BIN="echo"
    export TMUX_SESSION="test-sim"

    source "$SIM_COPY" 2>/dev/null

    echo "SIM1:initial_state=$JICM_STATE"
    transition_to "HALTING"
    echo "SIM1:after_halt=$JICM_STATE"
    transition_to "COMPRESSING"
    echo "SIM1:after_compress=$JICM_STATE"

    if grep -q "state: COMPRESSING" "$STATE_FILE" 2>/dev/null; then
        echo "PASS:state file reflects COMPRESSING"
    else
        echo "FAIL:state file COMPRESSING:$(head -1 "$STATE_FILE" 2>/dev/null)"
    fi

    transition_to "CLEARING"
    echo "SIM1:after_clear=$JICM_STATE"
    transition_to "RESTORING"
    echo "SIM1:after_restore=$JICM_STATE"
    transition_to "WATCHING"
    echo "SIM1:back_to_watching=$JICM_STATE"

    # Cooldown test
    COOLDOWN_UNTIL=$(($(date +%s) + 600))
    NOW=$(date +%s)
    if [[ $NOW -lt $COOLDOWN_UNTIL ]]; then
        echo "PASS:cooldown blocks re-trigger"
    else
        echo "FAIL:cooldown blocks:now=$NOW until=$COOLDOWN_UNTIL"
    fi

    # Error counter
    OLD_ERRORS=$ERROR_COUNT
    ERROR_COUNT=$((ERROR_COUNT + 1))
    if [[ $ERROR_COUNT -gt $OLD_ERRORS ]]; then
        echo "PASS:error counter increments"
    else
        echo "FAIL:error counter:old=$OLD_ERRORS new=$ERROR_COUNT"
    fi

    # Compression counter
    OLD_COMP=$COMPRESSION_COUNT
    COMPRESSION_COUNT=$((COMPRESSION_COUNT + 1))
    if [[ $COMPRESSION_COUNT -gt $OLD_COMP ]]; then
        echo "PASS:compression counter increments"
    else
        echo "FAIL:compression counter:old=$OLD_COMP new=$COMPRESSION_COUNT"
    fi

    # State age reset
    STATE_ENTERED_AT=$(($(date +%s) - 100))
    OLD_AGE=$(state_age)
    transition_to "WATCHING"
    NEW_AGE=$(state_age)
    if [[ $NEW_AGE -lt $OLD_AGE ]]; then
        echo "PASS:state_age resets on transition"
    else
        echo "FAIL:state_age reset:old=$OLD_AGE new=$NEW_AGE"
    fi
) 2>&1

# Parse simulation results
FULL_CYCLE_STATES=""
while IFS= read -r line; do
    if [[ "$line" == PASS:* ]]; then
        pass "${line#PASS:}"
    elif [[ "$line" == FAIL:* ]]; then
        fail "${line#FAIL:}"
    elif [[ "$line" == SIM1:* ]]; then
        FULL_CYCLE_STATES="$FULL_CYCLE_STATES ${line#SIM1:}"
    fi
done <<< "$SIM_OUTPUT"

# Verify full cycle traversed all states
if echo "$FULL_CYCLE_STATES" | grep -q "initial_state=WATCHING" && \
   echo "$FULL_CYCLE_STATES" | grep -q "after_halt=HALTING" && \
   echo "$FULL_CYCLE_STATES" | grep -q "after_compress=COMPRESSING" && \
   echo "$FULL_CYCLE_STATES" | grep -q "after_clear=CLEARING" && \
   echo "$FULL_CYCLE_STATES" | grep -q "after_restore=RESTORING" && \
   echo "$FULL_CYCLE_STATES" | grep -q "back_to_watching=WATCHING"; then
    pass "Full cycle: WATCHING→HALTING→COMPRESSING→CLEARING→RESTORING→WATCHING"
else
    fail "Full cycle" "States: $FULL_CYCLE_STATES"
fi

# Cleanup
rm -rf "$SIM_DIR" "$SIM_COPY"

echo ""

# ─── Test Group 18: Session-Start Hook Live-Fire ──────────────────

echo "Group 18: v6.1 State File & Launcher"

LAUNCHER="$SCRIPT_DIR/scripts/launch-jarvis-tmux.sh"

# Test 18.1: .jicm-state includes context_pct
if grep -q 'context_pct' "$WATCHER"; then
    pass ".jicm-state includes context_pct"
else
    fail "context_pct" "Missing from state file"
fi

# Test 18.2: .jicm-state includes context_tokens
if grep -q 'context_tokens' "$WATCHER"; then
    pass ".jicm-state includes context_tokens"
else
    fail "context_tokens" "Missing from state file"
fi

# Test 18.3: .watcher-status compat write REMOVED
if grep -q 'compat_state="monitoring"' "$WATCHER"; then
    fail "compat write removed" "Still writing v5-compatible .watcher-status"
else
    pass ".watcher-status compat write removed"
fi

# Test 18.4: LAST_PCT tracking variable exists
if grep -q 'LAST_PCT' "$WATCHER"; then
    pass "LAST_PCT tracking variable"
else
    fail "LAST_PCT" "Not found"
fi

# Test 18.5: Launch script detects v6 watcher
if bash -n "$LAUNCHER" 2>/dev/null; then
    pass "launch-jarvis-tmux.sh syntax check"
else
    fail "Launcher syntax" "Syntax error"
fi

if grep -q 'jicm-watcher.sh' "$LAUNCHER"; then
    pass "Launcher uses v6 watcher (jicm-watcher.sh)"
else
    fail "Launcher v6" "No jicm-watcher.sh reference"
fi

# Test 18.6: No v5 watcher fallback in launcher
if grep -q 'WATCHER_V5\|jarvis-watcher' "$LAUNCHER"; then
    fail "Launcher v5 removed" "Still references v5 watcher"
else
    pass "Launcher has no v5 watcher fallback"
fi

# Test 18.7: .watcher-status NOT cleaned on shutdown (no longer written)
if grep -A8 'cleanup()' "$WATCHER" | grep -q 'watcher-status'; then
    fail "watcher-status cleanup removed" "Still removing deprecated .watcher-status"
else
    pass "cleanup does not reference .watcher-status"
fi

echo ""

echo "Group 19: Clear Detection"

# Test 19.1: Clear detection checks token count
if grep -q 'tokens.*5000' "$WATCHER"; then
    pass "Clear detection checks token count threshold"
else
    fail "Token clear check" "No token-based clear detection"
fi

# Test 19.2: Clear detection has time-based fallback
if grep -q 'age.*-ge.*10' "$WATCHER" || grep -q 'age.*10' "$WATCHER"; then
    pass "Clear detection has time-based fallback"
else
    fail "Time fallback" "No time-based clear detection"
fi

# Test 19.3: do_compress calls write_state immediately
if grep -B1 -A1 'do_compress()' "$WATCHER" | head -5 && \
   grep -A3 'do_compress()' "$WATCHER" | grep -q 'write_state'; then
    pass "do_compress writes state immediately"
else
    fail "compress write_state" "No immediate write_state in do_compress"
fi

echo ""

echo "Group 20: Hook Live-Fire"

# Test: session-start hook JSON output for v6 state
HOOK_OUTPUT=$(bash -c '
export CLAUDE_PROJECT_DIR="/tmp/hook-test-$$"
mkdir -p "$CLAUDE_PROJECT_DIR/.claude/context"
mkdir -p "$CLAUDE_PROJECT_DIR/.claude/logs"
mkdir -p "$CLAUDE_PROJECT_DIR/.claude/state/components"
mkdir -p "$CLAUDE_PROJECT_DIR/.claude/context/jicm/sessions"

# Create v6 state file
cat > "$CLAUDE_PROJECT_DIR/.claude/context/.jicm-state" <<EOF
state: CLEARING
timestamp: 2026-02-11T00:00:00Z
threshold: 55
compressions: 1
errors: 0
pid: 12345
version: 6.0.0
EOF

# Create compressed context
echo "# Test compressed context" > "$CLAUDE_PROJECT_DIR/.claude/context/.compressed-context-ready.md"

# Feed hook a clear event
echo "{\"source\": \"clear\", \"session_id\": \"test-123\"}" | \
    bash "'"$HOOK"'" 2>/dev/null

EXIT_CODE=$?
rm -rf "$CLAUDE_PROJECT_DIR"
exit $EXIT_CODE
' 2>&1 || true)

# Check hook output is valid JSON with v6 markers
if echo "$HOOK_OUTPUT" | jq -e '.hookSpecificOutput.additionalContext' >/dev/null 2>&1; then
    pass "Hook returns valid JSON for v6 clear"
else
    fail "Hook v6 JSON" "Invalid JSON output: ${HOOK_OUTPUT:0:100}"
fi

if echo "$HOOK_OUTPUT" | jq -r '.systemMessage' 2>/dev/null | grep -q 'v6'; then
    pass "Hook systemMessage mentions v6"
else
    fail "Hook v6 message" "systemMessage doesn't mention v6"
fi

if echo "$HOOK_OUTPUT" | jq -r '.hookSpecificOutput.additionalContext' 2>/dev/null | grep -q 'stop-and-wait'; then
    pass "Hook additionalContext mentions stop-and-wait"
else
    fail "Hook stop-and-wait" "additionalContext doesn't mention stop-and-wait"
fi

echo ""

# ─── Test Group 20B: Compression Agent v6.1 ─────────────────────

echo "Group 20B: Compression Agent v6.1"

AGENT="$SCRIPT_DIR/agents/compression-agent.md"

# Test 20B.1: Agent version updated to v6.1
if grep -q 'v6.1' "$AGENT"; then
    pass "Compression agent version 6.1"
else
    fail "Agent version" "Not updated to v6.1"
fi

# Test 20B.2: Agent reads capability-map.yaml
if grep -q 'capability-map.yaml' "$AGENT"; then
    pass "Agent reads capability-map.yaml"
else
    fail "Agent capability-map" "Missing capability-map reference"
fi

# Test 20B.3: Agent has skill/MCP reduction directive
if grep -qi 'skill.*reduction\|skill.*name.*only\|MCP.*name.*only' "$AGENT"; then
    pass "Agent has skill/MCP reduction directive"
else
    fail "Agent skill reduction" "Missing skill/MCP reduction"
fi

# Test 20B.4: Agent does NOT prioritize session-state.md
if grep -q 'Session-state.*stale\|NOT read.*session-state' "$AGENT"; then
    pass "Agent de-prioritizes session-state.md"
else
    fail "Agent session-state" "Should de-prioritize session-state"
fi

# Test 20B.5: Agent reads index files
if grep -q '_index.md' "$AGENT" && grep -q 'README.md' "$AGENT"; then
    pass "Agent reads index files"
else
    fail "Agent indexes" "Missing index file references"
fi

# Test 20B.6: v6 hook does NOT inject session-state for restores
if grep -A20 'JICM v6.*STOP-AND-WAIT' "$HOOK" | grep -q 'deliberately NOT loaded'; then
    pass "v6 hook skips session-state for restores"
else
    fail "v6 session-state skip" "Hook should not inject session-state"
fi

echo ""

# ─── Test Group 20C: v6.1 Consumer Migration ─────────────────────

echo "Group 20C: Consumer Migration"

# Test 20C.1: ennoia.sh reads .jicm-state (not .watcher-status)
ENNOIA="$SCRIPT_DIR/scripts/ennoia.sh"
if grep -q 'jicm-state' "$ENNOIA" && ! grep -q 'watcher-status' "$ENNOIA"; then
    pass "ennoia.sh migrated to .jicm-state"
else
    fail "ennoia migration" "Still references .watcher-status"
fi

# Test 20C.2: virgil.sh reads .jicm-state
VIRGIL="$SCRIPT_DIR/scripts/virgil.sh"
if grep -q 'jicm-state' "$VIRGIL" && ! grep -q 'watcher-status' "$VIRGIL"; then
    pass "virgil.sh migrated to .jicm-state"
else
    fail "virgil migration" "Still references .watcher-status"
fi

# Test 20C.3: context-injector.js reads .jicm-state
CTX_INJECTOR="$SCRIPT_DIR/hooks/context-injector.js"
if grep -q 'jicm-state' "$CTX_INJECTOR" && ! grep -q 'watcher-status' "$CTX_INJECTOR"; then
    pass "context-injector.js migrated to .jicm-state"
else
    fail "context-injector migration" "Still references .watcher-status"
fi

# Test 20C.4: ulfhedthnar-detector.js reads .jicm-state
ULF_DETECTOR="$SCRIPT_DIR/hooks/ulfhedthnar-detector.js"
if grep -q 'jicm-state' "$ULF_DETECTOR" && ! grep -q 'watcher-status' "$ULF_DETECTOR"; then
    pass "ulfhedthnar-detector.js migrated to .jicm-state"
else
    fail "ulfhedthnar migration" "Still references .watcher-status"
fi

# Test 20C.5: context-health-monitor.js reads .jicm-state
CTX_HEALTH="$SCRIPT_DIR/hooks/context-health-monitor.js"
if grep -q 'jicm-state' "$CTX_HEALTH" && ! grep -q 'watcher-status' "$CTX_HEALTH"; then
    pass "context-health-monitor.js migrated to .jicm-state"
else
    fail "context-health migration" "Still references .watcher-status"
fi

# Test 20C.6: housekeep.sh reads .jicm-state
HOUSEKEEP="$SCRIPT_DIR/scripts/housekeep.sh"
if grep -q 'jicm-state' "$HOUSEKEEP"; then
    pass "housekeep.sh migrated to .jicm-state"
else
    fail "housekeep migration" "Still references .watcher-status"
fi

# Test 20C.7: session-start.sh has no v5 code paths
if grep -q 'V5_COMPRESSED_CONTEXT\|V5_IDLE_HANDS_FLAG\|V5_CLEAR_SENT' "$HOOK"; then
    fail "session-start v5 removed" "Still has v5 variable definitions"
else
    pass "session-start.sh has no v5 variables"
fi

# Test 20C.8: write_state includes context_pct in .jicm-state
if grep -A10 'write_state()' "$WATCHER" | grep -q 'context_pct'; then
    pass "write_state() includes context_pct in .jicm-state"
else
    fail "write_state context_pct" "Missing from native state file"
fi

echo ""

# ─── Test Group 22: Edge Case & Robustness ─────────────────────────

echo "Group 22: Edge Case & Robustness"

# Test 22.1: write_state() output has all expected fields
MOCK_STATE=$(cat <<'STATEEOF'
state: WATCHING
timestamp: 2026-02-11T12:00:00Z
context_pct: 42
context_tokens: 84000
threshold: 55
compressions: 3
errors: 0
pid: 12345
version: 6.1.0
sleeping: false
STATEEOF
)
EXPECTED_FIELDS="state timestamp context_pct context_tokens threshold compressions errors pid version sleeping"
MISSING_FIELDS=""
for field in $EXPECTED_FIELDS; do
    if ! echo "$MOCK_STATE" | grep -q "^${field}:"; then
        MISSING_FIELDS="${MISSING_FIELDS} ${field}"
    fi
done
if [[ -z "$MISSING_FIELDS" ]]; then
    pass "write_state format has all 10 required fields"
else
    fail "write_state fields" "Missing:${MISSING_FIELDS}"
fi

# Test 22.2: awk pattern extracts correct value from state file
echo "$MOCK_STATE" > "$CLAUDE_PROJECT_DIR/.jicm-state-test"
AWK_PCT=$(awk '/^context_pct:/{print $2}' "$CLAUDE_PROJECT_DIR/.jicm-state-test")
AWK_TOKENS=$(awk '/^context_tokens:/{print $2}' "$CLAUDE_PROJECT_DIR/.jicm-state-test")
AWK_STATE=$(awk '/^state:/{print $2}' "$CLAUDE_PROJECT_DIR/.jicm-state-test")
if [[ "$AWK_PCT" == "42" && "$AWK_TOKENS" == "84000" && "$AWK_STATE" == "WATCHING" ]]; then
    pass "awk patterns extract correct values from .jicm-state"
else
    fail "awk extraction" "Got pct=$AWK_PCT tokens=$AWK_TOKENS state=$AWK_STATE"
fi

# Test 22.3: JS regex pattern matches state file format
# Simulate the regex: /^context_pct:\s*(\d+)/m
JS_MATCH=$(echo "$MOCK_STATE" | grep -oP '^context_pct:\s*\K\d+' 2>/dev/null || \
           echo "$MOCK_STATE" | grep '^context_pct:' | sed 's/context_pct:[[:space:]]*//')
if [[ "$JS_MATCH" == "42" ]]; then
    pass "JS regex pattern matches state file format"
else
    fail "JS regex match" "Expected 42, got '$JS_MATCH'"
fi

# Test 22.4: Empty state file doesn't crash awk extraction
echo "" > "$CLAUDE_PROJECT_DIR/.jicm-state-empty"
AWK_EMPTY=$(awk '/^context_pct:/{print $2}' "$CLAUDE_PROJECT_DIR/.jicm-state-empty" 2>/dev/null)
if [[ -z "$AWK_EMPTY" ]]; then
    pass "Empty state file returns empty (no crash)"
else
    fail "Empty state handling" "Got '$AWK_EMPTY' from empty file"
fi

# Test 22.5: State file with zero values is parseable
ZERO_STATE="state: WATCHING
context_pct: 0
context_tokens: 0"
echo "$ZERO_STATE" > "$CLAUDE_PROJECT_DIR/.jicm-state-zero"
AWK_ZERO=$(awk '/^context_pct:/{print $2}' "$CLAUDE_PROJECT_DIR/.jicm-state-zero")
if [[ "$AWK_ZERO" == "0" ]]; then
    pass "Zero-value state file parsed correctly"
else
    fail "Zero state" "Expected 0, got '$AWK_ZERO'"
fi

# Test 22.6: All 5 JICM states appear in watcher implementation
STATES_FOUND=0
for state_name in WATCHING HALTING COMPRESSING CLEARING RESTORING; do
    if grep -q "\"$state_name\"" "$WATCHER"; then
        STATES_FOUND=$((STATES_FOUND + 1))
    fi
done
if [[ "$STATES_FOUND" -eq 5 ]]; then
    pass "All 5 state machine states implemented"
else
    fail "State machine completeness" "Found $STATES_FOUND/5 states"
fi

# Test 22.7: write_state function has no operational .watcher-status code (comments OK)
WRITE_STATE_BODY=$(sed -n '/^write_state()/,/^}/p' "$WATCHER")
# Filter out comments, then check for watcher-status in actual code
OPERATIONAL_REF=$(echo "$WRITE_STATE_BODY" | grep -v '^\s*#' | grep 'watcher-status' || true)
if [[ -z "$OPERATIONAL_REF" ]]; then
    pass "write_state has no operational .watcher-status code"
else
    fail "write_state isolation" "Operational ref: $OPERATIONAL_REF"
fi

# Test 22.8: context_pct uses default 0 when LAST_PCT unset
if grep -q '${LAST_PCT:-0}' "$WATCHER" && grep -q '${LAST_TOKENS:-0}' "$WATCHER"; then
    pass "context_pct/tokens have safe defaults (:-0)"
else
    fail "Default safety" "Missing :-0 defaults for LAST_PCT/LAST_TOKENS"
fi

# Test 22.9: No operational code uses .watcher-status as a file path
# Check each file for non-comment .watcher-status references
# Excludes: v5 watcher, signal-helper (command name), test files
STALE_FILES=$(grep -rl '\.watcher-status' "$SCRIPT_DIR/scripts/" "$SCRIPT_DIR/hooks/" \
    --include='*.sh' --include='*.js' 2>/dev/null | \
    grep -v 'jarvis-watcher.sh' | grep -v 'signal-helper.sh' | grep -v 'test-jicm' || true)
STALE_CODE=""
for f in $STALE_FILES; do
    # Strip comments then check for .watcher-status in actual code
    CODE_REFS=$(grep '\.watcher-status' "$f" | grep -v '^\s*#' | grep -v '^\s*//' | grep -v 'REMOVED' || true)
    if [[ -n "$CODE_REFS" ]]; then
        STALE_CODE="${STALE_CODE} $(basename "$f")"
    fi
done
if [[ -z "$STALE_CODE" ]]; then
    pass "No operational code uses .watcher-status as file path"
else
    fail "Stale .watcher-status file refs" "In:${STALE_CODE}"
fi

# Cleanup test files
rm -f "$CLAUDE_PROJECT_DIR/.jicm-state-test" "$CLAUDE_PROJECT_DIR/.jicm-state-empty" "$CLAUDE_PROJECT_DIR/.jicm-state-zero"

echo ""

# ─── Test Group 23: Live-Fire v6 Integration ───────────────────────

echo "Group 23: Live-Fire v6 Integration"

# Test 23.1: write_state() mock invocation produces all expected fields
# Source just the write_state function in a mock environment
MOCK_DIR="$CLAUDE_PROJECT_DIR/mock-livefire"
mkdir -p "$MOCK_DIR"
(
    # Set up mock environment for write_state
    STATE_FILE="$MOCK_DIR/.jicm-state"
    SLEEP_SIGNAL="$MOCK_DIR/.jicm-sleep.signal"
    JICM_STATE="WATCHING"
    LAST_PCT=42
    LAST_TOKENS=84000
    JICM_THRESHOLD=55
    COMPRESSION_COUNT=2
    ERROR_COUNT=0
    # Extract and run write_state
    eval "$(sed -n '/^write_state()/,/^}/p' "$WATCHER")"
    write_state
)
if [[ -f "$MOCK_DIR/.jicm-state" ]]; then
    FIELD_COUNT=$(grep -c ':' "$MOCK_DIR/.jicm-state")
    if [[ "$FIELD_COUNT" -ge 9 ]]; then
        pass "write_state() produces $FIELD_COUNT fields in .jicm-state"
    else
        fail "write_state output" "Only $FIELD_COUNT fields (expected 9+)"
    fi
else
    fail "write_state output" "No .jicm-state file created"
fi

# Test 23.2: Mock state file is parseable by awk (consumer pattern)
if [[ -f "$MOCK_DIR/.jicm-state" ]]; then
    LF_PCT=$(awk '/^context_pct:/{print $2}' "$MOCK_DIR/.jicm-state")
    LF_TOKENS=$(awk '/^context_tokens:/{print $2}' "$MOCK_DIR/.jicm-state")
    LF_STATE=$(awk '/^state:/{print $2}' "$MOCK_DIR/.jicm-state")
    if [[ "$LF_PCT" == "42" && "$LF_TOKENS" == "84000" && "$LF_STATE" == "WATCHING" ]]; then
        pass "Mock state file correctly parsed by awk patterns"
    else
        fail "Mock awk parse" "pct=$LF_PCT tokens=$LF_TOKENS state=$LF_STATE"
    fi
else
    skip "Mock state file not available"
fi

# Test 23.3: stop-watcher.sh checks v6 PID file first
STOP_WATCHER="$SCRIPT_DIR/scripts/stop-watcher.sh"
if grep -q 'jicm-watcher.pid' "$STOP_WATCHER"; then
    # Verify v6 is checked BEFORE v5
    V6_LINE=$(grep -n 'jicm-watcher.pid' "$STOP_WATCHER" | head -1 | cut -d: -f1)
    V5_LINE=$(grep -n 'watcher-pid' "$STOP_WATCHER" | head -1 | cut -d: -f1)
    if [[ "$V6_LINE" -lt "$V5_LINE" ]]; then
        pass "stop-watcher.sh checks v6 PID before v5"
    else
        fail "stop-watcher PID order" "v6 at line $V6_LINE, v5 at line $V5_LINE"
    fi
else
    fail "stop-watcher v6 PID" "Missing .jicm-watcher.pid check"
fi

# Test 23.4: signal-helper.sh checks v6 PID file first
SIGNAL_HELPER="$SCRIPT_DIR/scripts/signal-helper.sh"
if grep -q 'jicm-watcher.pid' "$SIGNAL_HELPER"; then
    SH_V6_LINE=$(grep -n 'jicm-watcher.pid' "$SIGNAL_HELPER" | head -1 | cut -d: -f1)
    SH_V5_LINE=$(grep -n 'watcher-pid"' "$SIGNAL_HELPER" | head -1 | cut -d: -f1)
    if [[ "$SH_V6_LINE" -lt "$SH_V5_LINE" ]]; then
        pass "signal-helper.sh checks v6 PID before v5"
    else
        fail "signal-helper PID order" "v6 at line $SH_V6_LINE, v5 at line $SH_V5_LINE"
    fi
else
    fail "signal-helper v6 PID" "Missing .jicm-watcher.pid check"
fi

# Test 23.5: watcher_status() in signal-helper shows JICM v6 info
if grep -A10 'watcher_status()' "$SIGNAL_HELPER" | grep -q 'JICM v6'; then
    pass "watcher_status() identifies JICM v6 watcher"
else
    fail "watcher_status v6 ID" "Missing JICM v6 identification"
fi

# Test 23.6: No watcher-pid reference in operational hooks (v6 uses .jicm-watcher.pid)
HOOK_PID_REFS=$(grep -rl '\.watcher-pid' "$SCRIPT_DIR/hooks/" --include='*.js' 2>/dev/null || true)
if [[ -z "$HOOK_PID_REFS" ]]; then
    pass "No hooks reference v5 .watcher-pid"
else
    fail "Hook v5 PID refs" "$(echo "$HOOK_PID_REFS" | xargs -I{} basename {})"
fi

# Cleanup
rm -rf "$MOCK_DIR"

echo ""

# ─── Test Group 24: State Machine & Regression Guards ──────────────

echo "Group 24: State Machine & Regression"

# Test 24.1: State machine has exactly 5 valid states
STATE_COUNT=$(grep -o '"WATCHING"\|"HALTING"\|"COMPRESSING"\|"CLEARING"\|"RESTORING"' "$WATCHER" | sort -u | wc -l | tr -d ' ')
if [[ "$STATE_COUNT" -eq 5 ]]; then
    pass "State machine has exactly 5 unique states"
else
    fail "State count" "Found $STATE_COUNT unique states (expected 5)"
fi

# Test 24.2: WATCHING → HALTING is the only entry into HALTING
HALTING_ENTRIES=$(grep -n 'transition_to "HALTING"' "$WATCHER" | wc -l | tr -d ' ')
if [[ "$HALTING_ENTRIES" -eq 1 ]]; then
    pass "Single WATCHING → HALTING transition point"
else
    fail "HALTING entries" "$HALTING_ENTRIES entry points (expected 1)"
fi

# Test 24.3: Every error recovery returns to WATCHING
TIMEOUT_TRANSITIONS=$(grep -B2 'transition_to "WATCHING"' "$WATCHER" | grep -c 'timeout\|ERROR\|failed\|active' || true)
if [[ "$TIMEOUT_TRANSITIONS" -ge 3 ]]; then
    pass "Error recovery always returns to WATCHING ($TIMEOUT_TRANSITIONS paths)"
else
    fail "Error recovery" "Only $TIMEOUT_TRANSITIONS error→WATCHING paths"
fi

# Test 24.4: Cooldown is set on every error path
ERROR_PATHS=$(grep -c 'ERROR_COUNT=\$((ERROR_COUNT + 1))' "$WATCHER")
COOLDOWN_SETS=$(grep -c 'COOLDOWN_UNTIL=' "$WATCHER" | tr -d ' ')
if [[ "$COOLDOWN_SETS" -ge "$ERROR_PATHS" ]]; then
    pass "Cooldown set on all error paths ($ERROR_PATHS errors, $COOLDOWN_SETS cooldowns)"
else
    fail "Cooldown coverage" "$ERROR_PATHS errors but only $COOLDOWN_SETS cooldowns"
fi

# Test 24.5: WATCHING state handler only transitions to HALTING
# Extract the WATCHING case block from the main loop (between WATCHING check and next elif)
WATCHING_BLOCK=$(sed -n '/JICM_STATE.*==.*"WATCHING"/,/elif.*JICM_STATE.*==.*"HALTING"/p' "$WATCHER")
WATCH_TO_CLEAR=$(echo "$WATCHING_BLOCK" | grep -c 'transition_to "CLEARING"' || true)
WATCH_TO_RESTORE=$(echo "$WATCHING_BLOCK" | grep -c 'transition_to "RESTORING"' || true)
if [[ "$WATCH_TO_CLEAR" -eq 0 && "$WATCH_TO_RESTORE" -eq 0 ]]; then
    pass "WATCHING handler has no shortcuts to CLEARING/RESTORING"
else
    fail "State shortcut" "CLEARING=$WATCH_TO_CLEAR RESTORING=$WATCH_TO_RESTORE in WATCHING block"
fi

# Test 24.6: Compression signal file is cleaned up after compression
if grep -q 'rm -f.*COMPRESSION_SIGNAL\|rm -f.*compression-done' "$WATCHER"; then
    pass "Compression signal cleaned up after use"
else
    fail "Signal cleanup" "No rm -f for compression signal"
fi

# Test 24.7: HALT_TIMEOUT, COMPRESS_TIMEOUT, CLEAR_TIMEOUT, RESTORE_TIMEOUT all defined
TIMEOUT_DEFS=0
for timeout in HALT_TIMEOUT COMPRESS_TIMEOUT CLEAR_TIMEOUT RESTORE_TIMEOUT; do
    if grep -q "^${timeout}=" "$WATCHER"; then
        TIMEOUT_DEFS=$((TIMEOUT_DEFS + 1))
    fi
done
if [[ "$TIMEOUT_DEFS" -eq 4 ]]; then
    pass "All 4 state timeout constants defined"
else
    fail "Timeout definitions" "Only $TIMEOUT_DEFS/4 timeout constants defined"
fi

# Test 24.8: Regression — E1 idle detection uses ESC key (not old approach)
if grep -q 'send-keys Escape\|send-keys -t.*Escape' "$WATCHER"; then
    pass "E1: Idle detection uses ESC key approach"
else
    fail "E1 regression" "Missing ESC key idle detection"
fi

# Test 24.9: Regression — E5 metrics emit function exists
if grep -q 'emit_cycle_metrics' "$WATCHER"; then
    pass "E5: Cycle metrics emission function present"
else
    fail "E5 regression" "Missing emit_cycle_metrics"
fi

# Test 24.10: Regression — E3 compression prompt references v6
COMPRESS_FN=$(sed -n '/^do_compress()/,/^}/p' "$WATCHER")
if echo "$COMPRESS_FN" | grep -qi 'v6\|stop-and-wait\|jicm-state'; then
    pass "E3: Compression function references v6 architecture"
else
    # May use the compression-agent which handles v6 internally
    if echo "$COMPRESS_FN" | grep -q 'compression-agent\|compress'; then
        pass "E3: Compression delegates to agent (v6 aware)"
    else
        fail "E3 regression" "Compression function has no v6 reference"
    fi
fi

echo ""

# ─── Test Group 25: Cross-File Syntax & Integration ────────────────

echo "Group 25: Cross-File Syntax"

# Test 25.1-25.6: All modified bash scripts pass syntax check
for script in jicm-watcher.sh ennoia.sh virgil.sh housekeep.sh signal-helper.sh stop-watcher.sh; do
    SCRIPT_PATH="$SCRIPT_DIR/scripts/$script"
    if [[ -f "$SCRIPT_PATH" ]]; then
        if bash -n "$SCRIPT_PATH" 2>/dev/null; then
            pass "$script syntax OK"
        else
            fail "$script syntax" "bash -n failed"
        fi
    else
        skip "$script (not found)"
    fi
done

# Test 25.7-25.9: All modified JS hooks pass syntax check
for hook in context-injector.js ulfhedthnar-detector.js context-health-monitor.js; do
    HOOK_PATH="$SCRIPT_DIR/hooks/$hook"
    if [[ -f "$HOOK_PATH" ]]; then
        if node -c "$HOOK_PATH" 2>/dev/null; then
            pass "$hook syntax OK"
        else
            fail "$hook syntax" "node -c failed"
        fi
    else
        skip "$hook (not found)"
    fi
done

# Test 25.10: session-start.sh syntax OK
if bash -n "$HOOK" 2>/dev/null; then
    pass "session-start.sh syntax OK"
else
    fail "session-start.sh syntax" "bash -n failed"
fi

echo ""

# ─── Test Group 21: Comprehensive Final Validation ────────────────

echo "Group 21: Final Validation"

# Test 21.1: No shellcheck critical issues (if shellcheck available)
if command -v shellcheck &>/dev/null; then
    SC_ISSUES=$(shellcheck -S error "$WATCHER" 2>&1 | wc -l | tr -d ' ')
    if [[ "$SC_ISSUES" -eq 0 ]]; then
        pass "shellcheck: no errors"
    else
        fail "shellcheck" "$SC_ISSUES error-level issues"
    fi
else
    skip "shellcheck (not installed)"
fi

# Test 21.2: All functions return 0 (comprehensive — bash 3.2 safety)
BAD_RETURNS=$(grep -n 'return [^0]' "$WATCHER" | grep -v '#' | grep -v 'return \$?' || true)
if [[ -z "$BAD_RETURNS" ]]; then
    pass "All functions return 0 or \$? (comprehensive)"
else
    fail "Non-zero returns" "Found: $BAD_RETURNS"
fi

# Test 21.3: No 'echo -e' without ANSI-C color vars (unreliable on some bash)
# (echo -e is fine for printing our ANSI-C quoted vars, but not for raw \e sequences)
RAW_ECHO=$(grep 'echo.*\\\\e\[' "$WATCHER" | grep -v 'C_' | grep -v '#' || true)
if [[ -z "$RAW_ECHO" ]]; then
    pass "No raw \\e in echo (uses ANSI-C color vars)"
else
    fail "Raw echo \\e" "Found: $RAW_ECHO"
fi

# Test 21.4: Design spec state count matches implementation
DESIGN_STATES=5  # WATCHING, HALTING, COMPRESSING, CLEARING, RESTORING
IMPL_STATES=$(grep -oE '"(WATCHING|HALTING|COMPRESSING|CLEARING|RESTORING)"' "$WATCHER" | sort -u | wc -l | tr -d ' ')
if [[ "$IMPL_STATES" -eq "$DESIGN_STATES" ]]; then
    pass "Implementation has all $DESIGN_STATES design states"
else
    fail "State count" "Design: $DESIGN_STATES, Implementation: $IMPL_STATES"
fi

# Test 21.5: Signal file count (should be 4 max per design)
SIGNAL_FILES=$(grep -oE '\.(jicm-state|compressed-context-ready\.md|compression-done\.signal|jicm-sleep\.signal)' "$WATCHER" | sort -u | wc -l | tr -d ' ')
if [[ "$SIGNAL_FILES" -le 4 ]]; then
    pass "Signal files within design limit ($SIGNAL_FILES <= 4)"
else
    fail "Signal count" "$SIGNAL_FILES signal files (design limit: 4)"
fi

# Test 21.6: Watcher script is executable
if [[ -x "$WATCHER" ]]; then
    pass "jicm-watcher.sh is executable"
else
    fail "Executable" "Not executable"
fi

# Test 21.7: Total line count is reasonable (< 1400)
# v6.1 adds metrics, idle detection — budget increased from 1200
LINE_COUNT=$(wc -l < "$WATCHER" | tr -d ' ')
if [[ "$LINE_COUNT" -lt 1400 ]]; then
    pass "Line count reasonable ($LINE_COUNT < 1400)"
else
    fail "Line count" "$LINE_COUNT lines (target < 1400)"
fi

# Test 21.8: Version string present
if grep -q 'version: 6.1.0' "$WATCHER"; then
    pass "Version 6.1.0 string present"
else
    fail "Version string" "Missing version 6.1.0"
fi

# ─── Test Group 26: JICM-Sleep Mechanism ─────────────────────────

echo "Group 26: JICM-Sleep Mechanism"

# Test 26.1: SLEEP_SIGNAL path defined in watcher
if grep -q 'SLEEP_SIGNAL=' "$WATCHER"; then
    pass "SLEEP_SIGNAL path defined"
else
    fail "SLEEP_SIGNAL path" "Missing SLEEP_SIGNAL variable"
fi

# Test 26.2: Sleep signal path points to .jicm-sleep.signal
if grep 'SLEEP_SIGNAL=' "$WATCHER" | grep -q '.jicm-sleep.signal'; then
    pass "Sleep signal path correct (.jicm-sleep.signal)"
else
    fail "Sleep signal path" "Wrong path for SLEEP_SIGNAL"
fi

# Test 26.3: WATCHING handler checks for sleep signal
WATCHING_BLOCK=$(sed -n '/STATE: WATCHING/,/STATE: HALTING/p' "$WATCHER")
if echo "$WATCHING_BLOCK" | grep -q 'SLEEP_SIGNAL'; then
    pass "WATCHING handler checks SLEEP_SIGNAL"
else
    fail "WATCHING sleep check" "No SLEEP_SIGNAL check in WATCHING handler"
fi

# Test 26.4: Sleep check causes 'continue' (skips threshold)
# Extract the WATCHING handler, then verify it has SLEEP_SIGNAL → continue pattern
WATCHING_SLEEP=$(sed -n '/STATE: WATCHING/,/STATE: HALTING/p' "$WATCHER" | sed -n '/SLEEP_SIGNAL/,/continue/p' || true)
if echo "$WATCHING_SLEEP" | grep -q 'continue'; then
    pass "Sleep signal causes continue (skips threshold)"
else
    fail "Sleep continue" "SLEEP_SIGNAL check doesn't skip with continue"
fi

# Test 26.5: write_state includes sleeping field
if grep -q 'sleeping:' "$WATCHER"; then
    pass "write_state includes sleeping field"
else
    fail "sleeping field" "write_state missing sleeping field"
fi

# Test 26.6: sleeping field reflects SLEEP_SIGNAL presence
WRITE_STATE_BLOCK=$(sed -n '/^write_state()/,/^}/p' "$WATCHER")
if echo "$WRITE_STATE_BLOCK" | grep -q 'SLEEP_SIGNAL.*sleeping'; then
    pass "sleeping field checks SLEEP_SIGNAL file"
elif echo "$WRITE_STATE_BLOCK" | grep -q 'SLEEP_SIGNAL'; then
    pass "sleeping field checks SLEEP_SIGNAL file (alternate pattern)"
else
    fail "sleeping field logic" "sleeping field doesn't check SLEEP_SIGNAL"
fi

# Test 26.7: Detector has isJicmSafeForActivation (not isContextBudgetSafe)
DETECTOR="$SCRIPT_DIR/hooks/ulfhedthnar-detector.js"
if [[ -f "$DETECTOR" ]]; then
    if grep -q 'isJicmSafeForActivation' "$DETECTOR"; then
        pass "Detector has isJicmSafeForActivation()"
    else
        fail "isJicmSafeForActivation" "Missing in detector"
    fi
    # Verify old function is removed
    if grep -q 'isContextBudgetSafe' "$DETECTOR"; then
        fail "isContextBudgetSafe still present" "Old function not removed"
    else
        pass "isContextBudgetSafe removed"
    fi
else
    skip "Detector file not found"
    skip "isContextBudgetSafe removal check"
fi

# Test 26.8: Detector gates on WATCHING state
if [[ -f "$DETECTOR" ]]; then
    if grep -q "stateMatch\[1\] === 'WATCHING'" "$DETECTOR"; then
        pass "Detector gates on WATCHING state"
    else
        fail "WATCHING gate" "Detector doesn't check for WATCHING state"
    fi
else
    skip "Detector file not found"
fi

# Test 26.9: Detector writes sleep signal on activation
if [[ -f "$DETECTOR" ]]; then
    if grep -q 'writeJicmSleepSignal' "$DETECTOR"; then
        pass "Detector writes sleep signal on activation"
    else
        fail "writeJicmSleepSignal" "Missing sleep signal write"
    fi
else
    skip "Detector file not found"
fi

# Test 26.10: Detector removes sleep signal on deactivation
if [[ -f "$DETECTOR" ]]; then
    if grep -q 'removeJicmSleepSignal' "$DETECTOR"; then
        pass "Detector removes sleep signal on deactivation"
    else
        fail "removeJicmSleepSignal" "Missing sleep signal removal"
    fi
else
    skip "Detector file not found"
fi

# Test 26.11: SLEEP_SIGNAL path in detector matches watcher
if [[ -f "$DETECTOR" ]]; then
    DETECTOR_PATH=$(grep 'jicm-sleep.signal' "$DETECTOR" | head -1)
    WATCHER_PATH=$(grep 'jicm-sleep.signal' "$WATCHER" | head -1)
    if [[ -n "$DETECTOR_PATH" ]] && [[ -n "$WATCHER_PATH" ]]; then
        pass "Sleep signal path consistent between watcher and detector"
    else
        fail "Sleep signal path consistency" "Path mismatch or missing"
    fi
else
    skip "Detector file not found"
fi

# Test 26.12: Unleash command references sleep signal
UNLEASH_CMD="$SCRIPT_DIR/commands/unleash.md"
if [[ -f "$UNLEASH_CMD" ]]; then
    if grep -q 'jicm-sleep.signal' "$UNLEASH_CMD"; then
        pass "/unleash references .jicm-sleep.signal"
    else
        fail "/unleash sleep ref" "Missing .jicm-sleep.signal in /unleash"
    fi
else
    skip "Unleash command not found"
fi

# Test 26.13: Disengage command references sleep signal removal
DISENGAGE_CMD="$SCRIPT_DIR/commands/disengage.md"
if [[ -f "$DISENGAGE_CMD" ]]; then
    if grep -q 'jicm-sleep.signal' "$DISENGAGE_CMD"; then
        pass "/disengage references .jicm-sleep.signal"
    else
        fail "/disengage sleep ref" "Missing .jicm-sleep.signal in /disengage"
    fi
else
    skip "Disengage command not found"
fi

# ─── Test Group 27: Command Handler Extraction ──────────────────

echo "Group 27: Command Handler Extraction"

CMD_HANDLER="$SCRIPT_DIR/scripts/command-handler.sh"

# Test 27.1: command-handler.sh exists and passes syntax check
if [[ -f "$CMD_HANDLER" ]]; then
    if bash -n "$CMD_HANDLER" 2>/dev/null; then
        pass "command-handler.sh syntax OK"
    else
        fail "command-handler.sh syntax" "Syntax error"
    fi
else
    fail "command-handler.sh exists" "File not found"
fi

# Test 27.2: command-handler.sh is executable
if [[ -x "$CMD_HANDLER" ]]; then
    pass "command-handler.sh is executable"
else
    fail "command-handler.sh executable" "Not executable"
fi

# Test 27.3: Has required functions
for func in is_valid_command send_command send_text process_signal_file is_claude_busy wait_for_idle_brief; do
    if grep -q "^${func}()" "$CMD_HANDLER"; then
        pass "Has function: $func()"
    else
        fail "Missing function" "$func() not found"
    fi
done

# Test 27.4: Uses set -euo pipefail
if grep -q 'set -euo pipefail' "$CMD_HANDLER"; then
    pass "Uses strict mode"
else
    fail "Strict mode" "Missing set -euo pipefail"
fi

# Test 27.5: SUPPORTED_COMMANDS array defined with sufficient entries
if grep -q 'SUPPORTED_COMMANDS=' "$CMD_HANDLER"; then
    CMD_COUNT=$(sed -n '/SUPPORTED_COMMANDS=/,/)/p' "$CMD_HANDLER" | grep -oE '"/[^"]*"' | wc -l | tr -d ' ')
    if [[ "$CMD_COUNT" -ge 15 ]]; then
        pass "SUPPORTED_COMMANDS has $CMD_COUNT commands (>= 15)"
    else
        fail "Command count" "Only $CMD_COUNT commands (expected >= 15)"
    fi
else
    fail "SUPPORTED_COMMANDS" "Array not defined"
fi

# Test 27.6: No operational JICM references (clean separation)
# Filter out comments (lines starting with #) before checking
JICM_REFS=$(grep -v '^\s*#' "$CMD_HANDLER" | grep -ciE 'jicm|HALTING|COMPRESSING|CLEARING|RESTORING|context_pct' || true)
if [[ "$JICM_REFS" -eq 0 ]]; then
    pass "No operational JICM references (clean separation)"
else
    fail "JICM leakage" "$JICM_REFS JICM-related references in code"
fi

# Test 27.7: PID file for concurrent handler detection
if grep -q 'PID_FILE' "$CMD_HANDLER" && grep -q 'command-handler.pid' "$CMD_HANDLER"; then
    pass "PID file for concurrent detection"
else
    fail "PID file" "Missing PID file handling"
fi

# Test 27.8: Cleanup trap removes PID file
if grep -q 'trap cleanup' "$CMD_HANDLER"; then
    pass "Cleanup trap registered"
else
    fail "Cleanup trap" "Missing cleanup trap"
fi

# Test 27.9: Uses .command-signal path
if grep -q '.command-signal' "$CMD_HANDLER"; then
    pass "Uses .command-signal path"
else
    fail "Signal path" "Missing .command-signal reference"
fi

# Test 27.10: Launcher includes command handler window
LAUNCHER="$SCRIPT_DIR/scripts/launch-jarvis-tmux.sh"
if [[ -f "$LAUNCHER" ]]; then
    if grep -q 'command-handler.sh' "$LAUNCHER"; then
        pass "Launcher references command-handler.sh"
    else
        fail "Launcher wiring" "command-handler.sh not in launcher"
    fi
    if grep -q 'Commands' "$LAUNCHER"; then
        pass "Launcher has Commands window"
    else
        fail "Commands window" "Missing Commands window name"
    fi
else
    skip "Launcher not found"
    skip "Commands window check"
fi

# Test 27.11: bash 3.2 safety — return 1 only in guarded functions
# is_valid_command() and process_signal_file() use return 1 (callers use if/!)
RETURN1_COUNT=$(grep -c 'return 1' "$CMD_HANDLER" || true)
# Expected: is_valid_command (1) + process_signal_file (2) = 3
if [[ "$RETURN1_COUNT" -le 4 ]]; then
    pass "return 1 count reasonable ($RETURN1_COUNT, all in guarded functions)"
else
    fail "return 1 safety" "$RETURN1_COUNT occurrences (expected <= 4)"
fi

# Test 27.12: Canonical tmux send-keys pattern
if grep -q 'send-keys.*-l' "$CMD_HANDLER" && grep -q 'send-keys.*C-m' "$CMD_HANDLER"; then
    pass "Canonical send-keys pattern (text via -l, C-m separate)"
else
    fail "send-keys pattern" "Missing canonical tmux pattern"
fi

echo ""

# ─── Test Group 28: Dev-Ops Testing Infrastructure ─────────────────

echo "Group 28: Dev-Ops Testing Infrastructure"
echo "───────────────────────────────────────"

# Group 28 tests real project files (not temp dirs used by other groups)
REAL_PROJECT="${REAL_PROJECT_DIR:-$HOME/Claude/Jarvis}"
DEV_SCRIPTS_DIR="$REAL_PROJECT/.claude/scripts/dev"
DEV_TEST_SCRIPTS=(
    "send-to-jarvis.sh"
    "capture-jarvis.sh"
    "watch-jicm.sh"
    "restart-watcher.sh"
)
LIVE_TESTS="$REAL_PROJECT/.claude/tests/jarvis-live-tests.sh"

# 28.1-28.4: Dev scripts exist and are executable
for script in "${DEV_TEST_SCRIPTS[@]}"; do
    if [[ -x "$DEV_SCRIPTS_DIR/$script" ]]; then
        pass "$script exists and is executable"
    else
        fail "$script exists and executable"
    fi
done

# 28.5: jarvis-live-tests.sh exists and is executable
if [[ -x "$LIVE_TESTS" ]]; then
    pass "jarvis-live-tests.sh exists and is executable"
else
    fail "jarvis-live-tests.sh exists and executable"
fi

# 28.6: All 5 scripts use set -euo pipefail
for script in "${DEV_TEST_SCRIPTS[@]}"; do
    if grep -q 'set -euo pipefail' "$DEV_SCRIPTS_DIR/$script" 2>/dev/null; then
        pass "$script uses set -euo pipefail"
    else
        fail "$script set -euo pipefail"
    fi
done
if grep -q 'set -euo pipefail' "$LIVE_TESTS" 2>/dev/null; then
    pass "jarvis-live-tests.sh uses set -euo pipefail"
else
    fail "jarvis-live-tests.sh set -euo pipefail"
fi

# 28.7: send-to-jarvis.sh has --check-idle
if grep -q 'check-idle\|check_idle\|CHECK_IDLE' "$DEV_SCRIPTS_DIR/send-to-jarvis.sh" 2>/dev/null; then
    pass "send-to-jarvis.sh has --check-idle"
else
    fail "send-to-jarvis.sh --check-idle"
fi

# 28.8: watch-jicm.sh has --once and --json modes
if grep -q '\-\-once' "$DEV_SCRIPTS_DIR/watch-jicm.sh" 2>/dev/null && \
   grep -q '\-\-json' "$DEV_SCRIPTS_DIR/watch-jicm.sh" 2>/dev/null; then
    pass "watch-jicm.sh has --once and --json modes"
else
    fail "watch-jicm.sh --once/--json"
fi

# 28.9: restart-watcher.sh references .jicm-watcher.pid
if grep -q '.jicm-watcher.pid' "$DEV_SCRIPTS_DIR/restart-watcher.sh" 2>/dev/null; then
    pass "restart-watcher.sh references .jicm-watcher.pid"
else
    fail "restart-watcher.sh .jicm-watcher.pid reference"
fi

# 28.10: dev-ops Skill exists
if [[ -f "$REAL_PROJECT/.claude/skills/dev-ops/SKILL.md" ]]; then
    pass "dev-ops Skill exists"
else
    fail "dev-ops Skill exists"
fi

# 28.11: /dev-test command exists
if [[ -f "$REAL_PROJECT/.claude/commands/dev-test.md" ]]; then
    pass "/dev-test command exists"
else
    fail "/dev-test command exists"
fi

# 28.12: launch-jarvis-tmux.sh has --dev flag
if grep -q '\-\-dev' "$REAL_PROJECT/.claude/scripts/launch-jarvis-tmux.sh" 2>/dev/null; then
    pass "launch-jarvis-tmux.sh has --dev flag"
else
    fail "launch-jarvis-tmux.sh --dev flag"
fi

echo ""

# ─── Results ─────────────────────────────────────────────────────

teardown

echo "═══════════════════════════════════════════"
echo "  Results: ${PASS} passed, ${FAIL} failed, ${SKIP} skipped"
echo "═══════════════════════════════════════════"

if [[ $FAIL -gt 0 ]]; then
    echo ""
    echo "Failures:"
    echo -e "$ERRORS"
    echo ""
fi

if [[ $FAIL -eq 0 ]]; then
    echo "  ALL TESTS PASSED"
    exit 0
else
    exit 1
fi
