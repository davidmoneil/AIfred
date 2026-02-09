#!/usr/bin/env bash
# research-ops validation suite — tests all backends with real API calls
# Usage: ./test-all.sh [--quick] [--backend NAME]
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

PASS=0 FAIL=0 SKIP=0
QUICK=false TARGET=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --quick) QUICK=true; shift ;;
        --backend) TARGET="$2"; shift 2 ;;
        --help)
            echo "Usage: test-all.sh [--quick] [--backend NAME]"
            echo "  --quick     Only test public APIs (no paid keys)"
            echo "  --backend   Test specific backend only"
            exit 0 ;;
        *) shift ;;
    esac
done

run_test() {
    local name="$1" cmd="$2" validator="$3"
    local output exit_code

    if [[ -n "$TARGET" && "$TARGET" != "$name" ]]; then
        return
    fi

    printf "[TEST] %-20s " "$name"

    output=$(eval "$cmd" 2>&1) || true
    exit_code=$?

    if [[ $exit_code -eq 0 ]] && eval "$validator" <<< "$output" >/dev/null 2>&1; then
        echo "PASS"
        PASS=$((PASS + 1))
    else
        echo "FAIL (exit=$exit_code)"
        echo "  Output (first 200 chars): ${output:0:200}"
        FAIL=$((FAIL + 1))
    fi
}

skip_test() {
    local name="$1" reason="$2"
    if [[ -n "$TARGET" && "$TARGET" != "$name" ]]; then
        return
    fi
    printf "[SKIP] %-20s %s\n" "$name" "$reason"
    SKIP=$((SKIP + 1))
}

echo "=== research-ops Backend Validation Suite ==="
echo "Date: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

# --- Public APIs (no key required) ---

run_test "arxiv" \
    "bash '$SCRIPT_DIR/search-arxiv.sh' 'transformers' --max 2" \
    "grep -q 'arXiv Search Results'"

run_test "wikipedia" \
    "bash '$SCRIPT_DIR/fetch-wikipedia.sh' 'Artificial_intelligence'" \
    "jq -e '.title' >/dev/null"

# --- Paid APIs (require keys) ---

if [[ "$QUICK" == true ]]; then
    skip_test "brave" "Skipped (--quick mode, paid API)"
    skip_test "perplexity" "Skipped (--quick mode, paid API)"
else
    run_test "brave" \
        "bash '$SCRIPT_DIR/search-brave.sh' 'Claude AI' --count 2" \
        "jq -e '.results' >/dev/null"

    run_test "perplexity" \
        "bash '$SCRIPT_DIR/search-perplexity.sh' 'What is Claude AI?' --model sonar" \
        "jq -e '.content' >/dev/null"
fi

# --- Workflow docs (always pass if they output JSON) ---

run_test "context7" \
    "bash '$SCRIPT_DIR/fetch-context7.sh' 'react' 'hooks'" \
    "jq -e '.backend' >/dev/null"

run_test "gptresearcher" \
    "bash '$SCRIPT_DIR/deep-research-gpt.sh' 'AI safety'" \
    "jq -e '.backend' >/dev/null"

# --- Help flag tests ---

echo ""
echo "--- Help flag tests ---"
for script in search-brave.sh search-arxiv.sh fetch-wikipedia.sh search-perplexity.sh fetch-context7.sh deep-research-gpt.sh; do
    printf "[HELP] %-20s " "$script"
    if bash "$SCRIPT_DIR/$script" --help >/dev/null 2>&1; then
        echo "PASS"
        PASS=$((PASS + 1))
    else
        echo "FAIL"
        FAIL=$((FAIL + 1))
    fi
done

echo ""
echo "=== Results ==="
echo "Pass: $PASS  Fail: $FAIL  Skip: $SKIP"
echo "Total: $((PASS + FAIL + SKIP))"

if [[ $FAIL -gt 0 ]]; then
    echo "STATUS: SOME TESTS FAILED"
    exit 1
else
    echo "STATUS: ALL TESTS PASSED"
    exit 0
fi
