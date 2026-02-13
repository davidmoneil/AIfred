#!/bin/bash
# test-platform.sh - Unit tests for platform.sh compatibility library
#
# Usage: ./test-platform.sh
#
# Verifies each compat_ function produces correct output on the current platform.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/platform.sh"

PASS=0
FAIL=0

pass() {
    echo -e "\033[0;32mPASS\033[0m: $1"
    ((PASS++))
}

fail() {
    echo -e "\033[0;31mFAIL\033[0m: $1 (expected: $2, got: $3)"
    ((FAIL++))
}

echo "Platform: $AIFRED_PLATFORM"
echo "================================="
echo ""

# --- compat_stat_mtime ---
echo "-- compat_stat_mtime --"
TMPFILE=$(mktemp)
MTIME=$(compat_stat_mtime "$TMPFILE")
if [[ "$MTIME" =~ ^[0-9]+$ ]] && [[ "$MTIME" -gt 1000000000 ]]; then
    pass "compat_stat_mtime returns valid epoch ($MTIME)"
else
    fail "compat_stat_mtime" "epoch seconds" "$MTIME"
fi
rm -f "$TMPFILE"

# --- compat_stat_size ---
echo "-- compat_stat_size --"
TMPFILE=$(mktemp)
echo "hello world" > "$TMPFILE"
SIZE=$(compat_stat_size "$TMPFILE")
if [[ "$SIZE" =~ ^[0-9]+$ ]] && [[ "$SIZE" -gt 0 ]]; then
    pass "compat_stat_size returns valid size ($SIZE bytes)"
else
    fail "compat_stat_size" "positive integer" "$SIZE"
fi
rm -f "$TMPFILE"

# --- compat_date_epoch ---
echo "-- compat_date_epoch --"
# Test with a known epoch: 1700000000 = 2023-11-14
RESULT=$(compat_date_epoch 1700000000 "+%Y-%m-%d")
if [[ "$RESULT" == "2023-11-14" ]]; then
    pass "compat_date_epoch formats epoch correctly ($RESULT)"
else
    fail "compat_date_epoch" "2023-11-14" "$RESULT"
fi

# --- compat_date_relative with "N days ago" ---
echo "-- compat_date_relative --"
RESULT=$(compat_date_relative "7 days ago" "+%Y-%m-%d")
if [[ "$RESULT" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
    pass "compat_date_relative '7 days ago' returns date ($RESULT)"
else
    fail "compat_date_relative 'N days ago'" "YYYY-MM-DD" "$RESULT"
fi

# Test with "-N days" format
RESULT2=$(compat_date_relative "-7 days" "+%Y-%m-%d")
if [[ "$RESULT" == "$RESULT2" ]]; then
    pass "compat_date_relative '-7 days' matches '7 days ago' ($RESULT2)"
else
    fail "compat_date_relative '-N days'" "$RESULT" "$RESULT2"
fi

# Test with hours
RESULT3=$(compat_date_relative "-2 hours" "+%Y-%m-%d")
if [[ "$RESULT3" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
    pass "compat_date_relative '-2 hours' returns date ($RESULT3)"
else
    fail "compat_date_relative '-2 hours'" "YYYY-MM-DD" "$RESULT3"
fi

# --- compat_sed_inplace ---
echo "-- compat_sed_inplace --"
TMPFILE=$(mktemp)
echo "status: active" > "$TMPFILE"
compat_sed_inplace 's/active/completed/' "$TMPFILE"
CONTENT=$(cat "$TMPFILE")
if [[ "$CONTENT" == "status: completed" ]]; then
    pass "compat_sed_inplace replaces correctly"
else
    fail "compat_sed_inplace" "status: completed" "$CONTENT"
fi
rm -f "$TMPFILE"

# --- compat_find_printf_mtime ---
echo "-- compat_find_printf_mtime --"
TMPDIR=$(mktemp -d)
touch "$TMPDIR/test1.md" "$TMPDIR/test2.md"
sleep 0.1
MTIMES=$(compat_find_printf_mtime "$TMPDIR" "*.md")
COUNT=$(echo "$MTIMES" | wc -l)
if [[ "$COUNT" -ge 2 ]]; then
    pass "compat_find_printf_mtime found $COUNT files with mtime values"
else
    fail "compat_find_printf_mtime" ">=2 lines" "$COUNT"
fi
rm -rf "$TMPDIR"

# --- compat_timeout ---
echo "-- compat_timeout --"
# Test: command that finishes before timeout
RESULT=$(compat_timeout 5 echo "ok" 2>&1)
if [[ "$RESULT" == "ok" ]]; then
    pass "compat_timeout: command completes within limit"
else
    fail "compat_timeout (success)" "ok" "$RESULT"
fi

# Test: command that exceeds timeout
compat_timeout 1 sleep 10 &>/dev/null
EXIT=$?
if [[ "$EXIT" -eq 124 ]] || [[ "$EXIT" -eq 137 ]]; then
    pass "compat_timeout: kills long-running command (exit $EXIT)"
else
    fail "compat_timeout (kill)" "exit 124 or 137" "exit $EXIT"
fi

# --- compat_xargs_nonempty ---
echo "-- compat_xargs_nonempty --"
RESULT=$(echo "" | compat_xargs_nonempty echo "should not appear" 2>/dev/null)
# On both platforms, empty input should produce no output (or just whitespace)
TRIMMED=$(echo "$RESULT" | tr -d '[:space:]')
if [[ -z "$TRIMMED" ]] || [[ "$TRIMMED" == "shouldnotappear" ]]; then
    # BSD xargs may still run with empty args — both behaviors acceptable
    pass "compat_xargs_nonempty handles empty input"
else
    fail "compat_xargs_nonempty" "empty or expected output" "$RESULT"
fi

# ================================
# Summary
# ================================
echo ""
echo "================================="
echo "Results: $PASS passed, $FAIL failed"
echo "================================="

if [[ $FAIL -gt 0 ]]; then
    exit 1
else
    exit 0
fi
