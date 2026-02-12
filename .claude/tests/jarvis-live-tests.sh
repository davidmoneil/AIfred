#!/bin/bash
# jarvis-live-tests.sh — Automated live integration tests against W0:Jarvis
#
# Tests infrastructure health, dev tool validation, idle detection, and signal
# file health. Designed to be run standalone OR by Jarvis-dev via Bash tool.
#
# Does NOT include JICM cycle, IPC, or hook mutation tests — those are
# orchestrated by Jarvis-dev via the dev-ops Skill workflows.
#
# Prerequisites:
#   - tmux session running (jarvis or $TMUX_SESSION)
#   - W0 (Jarvis) active
#   - W1 (Watcher) running
#
# Usage: bash jarvis-live-tests.sh [--group N]
#
# Part of Jarvis dev-ops testing infrastructure.
set -euo pipefail

# ─── Configuration ──────────────────────────────────────────────────────────
TMUX_BIN="${TMUX_BIN:-$HOME/bin/tmux}"
SESSION="${TMUX_SESSION:-jarvis}"
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$HOME/Claude/Jarvis}"
CONTEXT_DIR="$PROJECT_DIR/.claude/context"
DEV_DIR="$PROJECT_DIR/.claude/scripts/dev"
STATE_FILE="$CONTEXT_DIR/.jicm-state"

# ─── Test Framework ─────────────────────────────────────────────────────────
PASS=0
FAIL=0
SKIP=0
ERRORS=""
GROUP_FILTER=""

pass() {
    PASS=$((PASS + 1))
    echo "  PASS  $1"
}

fail() {
    FAIL=$((FAIL + 1))
    ERRORS="${ERRORS}\n  FAIL  $1${2:+: $2}"
    echo "  FAIL  $1${2:+: $2}"
}

skip() {
    SKIP=$((SKIP + 1))
    echo "  SKIP  $1"
}

# ─── Argument Parsing ──────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
    case $1 in
        --group) GROUP_FILTER="$2"; shift 2 ;;
        -h|--help)
            echo "jarvis-live-tests.sh — Live integration tests"
            echo "  --group N    Run only group N (1-4)"
            echo "  -h, --help   Show this help"
            exit 0 ;;
        *) shift ;;
    esac
done

# ─── Preflight ──────────────────────────────────────────────────────────────
echo ""
echo "================================================================"
echo "  Jarvis Live Integration Tests"
echo "================================================================"
echo ""
echo "  Session:  $SESSION"
echo "  Project:  $PROJECT_DIR"
echo ""

# ─── Group 1: Infrastructure Health ─────────────────────────────────────────

test_group_1() {
    echo "Group 1: Infrastructure Health"
    echo "────────────────────────────────"

    # 1.1 tmux session exists
    if "$TMUX_BIN" has-session -t "$SESSION" 2>/dev/null; then
        pass "tmux session '$SESSION' exists"
    else
        fail "tmux session '$SESSION' exists" "Session not found"
        echo ""
        echo "  Cannot continue without tmux session. Aborting."
        return
    fi

    # 1.2 Jarvis window exists
    local windows
    windows=$("$TMUX_BIN" list-windows -t "$SESSION" -F '#{window_name}' 2>/dev/null || echo "")
    if echo "$windows" | grep -q "Jarvis"; then
        pass "Jarvis window exists in session"
    else
        fail "Jarvis window exists" "Windows: $windows"
    fi

    # 1.3 Watcher PID valid
    local pid_file="$CONTEXT_DIR/.jicm-watcher.pid"
    if [[ -f "$pid_file" ]]; then
        local watcher_pid
        watcher_pid=$(cat "$pid_file" 2>/dev/null || echo "")
        if [[ -n "$watcher_pid" ]] && kill -0 "$watcher_pid" 2>/dev/null; then
            pass "Watcher PID $watcher_pid is alive"
        else
            fail "Watcher PID valid" "PID $watcher_pid not running"
        fi
    else
        fail "Watcher PID file exists" "File not found: $pid_file"
    fi

    # 1.4 .jicm-state exists
    if [[ -f "$STATE_FILE" ]]; then
        pass ".jicm-state file exists"
    else
        fail ".jicm-state file exists" "Not found"
    fi

    # 1.5 Watcher state is WATCHING
    if [[ -f "$STATE_FILE" ]]; then
        local state
        state=$(awk '/^state:/{print $2}' "$STATE_FILE" 2>/dev/null || echo "UNKNOWN")
        if [[ "$state" == "WATCHING" ]]; then
            pass "Watcher state: WATCHING"
        else
            fail "Watcher state" "Expected WATCHING, got: $state"
        fi
    else
        skip "Watcher state (no state file)"
    fi

    # 1.6 Context % in valid range
    if [[ -f "$STATE_FILE" ]]; then
        local pct
        pct=$(awk '/^context_pct:/{print $2}' "$STATE_FILE" 2>/dev/null || echo "-1")
        if [[ "$pct" -ge 0 ]] && [[ "$pct" -le 100 ]] 2>/dev/null; then
            pass "Context % in range: ${pct}%"
        else
            fail "Context % in range" "Got: $pct"
        fi
    else
        skip "Context % (no state file)"
    fi

    echo ""
}

# ─── Group 2: Dev Tool Validation ──────────────────────────────────────────

test_group_2() {
    echo "Group 2: Dev Tool Validation"
    echo "────────────────────────────────"

    # 2.1 send-to-jarvis.sh help
    if "$DEV_DIR/send-to-jarvis.sh" -h >/dev/null 2>&1; then
        pass "send-to-jarvis.sh --help exits 0"
    else
        fail "send-to-jarvis.sh --help" "Non-zero exit"
    fi

    # 2.2 capture-jarvis.sh help
    if "$DEV_DIR/capture-jarvis.sh" -h >/dev/null 2>&1; then
        pass "capture-jarvis.sh --help exits 0"
    else
        fail "capture-jarvis.sh --help" "Non-zero exit"
    fi

    # 2.3 watch-jicm.sh help
    if "$DEV_DIR/watch-jicm.sh" -h >/dev/null 2>&1; then
        pass "watch-jicm.sh --help exits 0"
    else
        fail "watch-jicm.sh --help" "Non-zero exit"
    fi

    # 2.4 restart-watcher.sh help
    if "$DEV_DIR/restart-watcher.sh" -h >/dev/null 2>&1; then
        pass "restart-watcher.sh --help exits 0"
    else
        fail "restart-watcher.sh --help" "Non-zero exit"
    fi

    # 2.5 capture-jarvis.sh produces output
    local capture_output
    capture_output=$("$DEV_DIR/capture-jarvis.sh" --tail 5 2>/dev/null || echo "")
    if [[ -n "$capture_output" ]]; then
        pass "capture-jarvis.sh --tail 5 produces output"
    else
        fail "capture-jarvis.sh output" "Empty output"
    fi

    # 2.6 watch-jicm.sh one-shot JSON
    local jicm_json
    jicm_json=$("$DEV_DIR/watch-jicm.sh" --once --json 2>/dev/null || echo "")
    if echo "$jicm_json" | grep -q '"state"'; then
        pass "watch-jicm.sh --once --json produces valid JSON"
    else
        fail "watch-jicm.sh JSON output" "No 'state' key found: $jicm_json"
    fi

    echo ""
}

# ─── Group 3: W0 Idle Detection ──────────────────────────────────────────

test_group_3() {
    echo "Group 3: W0 Idle Detection"
    echo "────────────────────────────────"

    # 3.1 send-to-jarvis.sh --check-idle
    if "$DEV_DIR/send-to-jarvis.sh" --check-idle --timeout 10 >/dev/null 2>&1; then
        pass "W0 idle check (send-to-jarvis --check-idle)"
    else
        local rc=$?
        if [[ $rc -eq 2 ]]; then
            fail "W0 idle check" "Session not found"
        else
            fail "W0 idle check" "W0 appears busy (exit $rc)"
        fi
    fi

    # 3.2 Capture pane and check for idle pattern
    local pane_tail
    pane_tail=$("$TMUX_BIN" capture-pane -t "${SESSION}:0" -p 2>/dev/null | tail -5 || echo "")
    if echo "$pane_tail" | grep -qE 'Interrupted.*What should Claude do|^❯[[:space:]]*$'; then
        pass "W0 pane shows idle pattern"
    else
        # Not necessarily a failure — W0 might be at prompt without idle pattern
        skip "W0 idle pattern (pane may not show ESC-triggered pattern)"
    fi

    echo ""
}

# ─── Group 4: Signal File Health ──────────────────────────────────────────

test_group_4() {
    echo "Group 4: Signal File Health"
    echo "────────────────────────────────"

    # 4.1 .jicm-state age < 30s (watcher writes every 5s)
    if [[ -f "$STATE_FILE" ]]; then
        local file_mod now age
        file_mod=$(stat -f %m "$STATE_FILE" 2>/dev/null || echo "0")
        now=$(date +%s)
        age=$(( now - file_mod ))
        if [[ $age -lt 30 ]]; then
            pass ".jicm-state is fresh (${age}s old)"
        else
            fail ".jicm-state freshness" "File is ${age}s old (expected < 30s)"
        fi
    else
        fail ".jicm-state exists" "File not found"
    fi

    # 4.2 .virgil-tasks.json exists
    if [[ -f "$CONTEXT_DIR/.virgil-tasks.json" ]]; then
        pass ".virgil-tasks.json exists"
    else
        skip ".virgil-tasks.json (Virgil may not have written yet)"
    fi

    # 4.3 .ennoia-status exists
    if [[ -f "$CONTEXT_DIR/.ennoia-status" ]]; then
        pass ".ennoia-status exists"
    else
        skip ".ennoia-status (Ennoia may not have written yet)"
    fi

    echo ""
}

# ─── Main Runner ──────────────────────────────────────────────────────────

main() {
    local start_time
    start_time=$(date +%s)

    if [[ -n "$GROUP_FILTER" ]]; then
        case "$GROUP_FILTER" in
            1) test_group_1 ;;
            2) test_group_2 ;;
            3) test_group_3 ;;
            4) test_group_4 ;;
            *)
                echo "ERROR: Unknown group: $GROUP_FILTER (valid: 1-4)"
                exit 1 ;;
        esac
    else
        test_group_1
        test_group_2
        test_group_3
        test_group_4
    fi

    local end_time
    end_time=$(date +%s)
    local duration=$(( end_time - start_time ))

    echo "================================================================"
    echo "  Results: $PASS passed, $FAIL failed, $SKIP skipped"
    echo "  Duration: ${duration}s"
    echo "================================================================"

    if [[ $FAIL -gt 0 ]]; then
        echo ""
        echo "Failures:"
        echo -e "$ERRORS"
        exit 1
    fi
}

main
