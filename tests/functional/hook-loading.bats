#!/usr/bin/env bats
# Hook loading and basic I/O tests

load helpers/setup

@test "all active hooks pass node --check" {
    local failures=0
    while IFS= read -r -d '' hook; do
        if ! node --check "$hook" 2>/dev/null; then
            echo "FAIL: $hook" >&2
            failures=$((failures + 1))
        fi
    done < <(find "$PROJECT_ROOT/.claude/hooks" -maxdepth 1 -name "*.js" -type f -print0)
    [ "$failures" -eq 0 ]
}

@test "shared.js library loads without error" {
    run node -e "const s = require('$PROJECT_ROOT/.claude/hooks/lib/shared.js'); console.log(typeof s)"
    [ "$status" -eq 0 ]
    [[ "$output" == "object" ]] || [[ "$output" == "function" ]]
}

@test "hooks respond to empty stdin with valid JSON" {
    # Test hooks that read from stdin (PreToolUse/PostToolUse pattern)
    # Feed empty JSON object, expect JSON back with at minimum a structure
    local tested=0
    for hook in "$PROJECT_ROOT/.claude/hooks"/{audit-logger,branch-protection,document-guard,secret-scanner,docker-validator}.js; do
        [[ -f "$hook" ]] || continue
        RESULT=$(echo '{"tool_name":"Bash","tool_input":{"command":"echo test"}}' | \
            CLAUDE_PROJECT_DIR="$PROJECT_ROOT" node "$hook" 2>/dev/null || true)
        if [[ -n "$RESULT" ]]; then
            # Should be valid JSON
            echo "$RESULT" | jq empty 2>/dev/null
            if [ $? -ne 0 ]; then
                echo "FAIL: $(basename "$hook") returned invalid JSON: $RESULT" >&2
                return 1
            fi
            tested=$((tested + 1))
        fi
    done
    [ "$tested" -gt 0 ] || skip "no testable hooks found"
}

@test "hooks with proceed key return boolean proceed" {
    for hook in "$PROJECT_ROOT/.claude/hooks"/{branch-protection,document-guard}.js; do
        [[ -f "$hook" ]] || continue
        RESULT=$(echo '{"tool_name":"Bash","tool_input":{"command":"echo test"}}' | \
            CLAUDE_PROJECT_DIR="$PROJECT_ROOT" node "$hook" 2>/dev/null || true)
        if [[ -n "$RESULT" ]]; then
            PROCEED=$(echo "$RESULT" | jq -r '.proceed // empty' 2>/dev/null)
            if [[ -n "$PROCEED" ]]; then
                [[ "$PROCEED" == "true" ]] || [[ "$PROCEED" == "false" ]]
            fi
        fi
    done
}
