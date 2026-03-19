#!/bin/bash
# Common setup for bats functional tests

# Project root
export PROJECT_ROOT="$(cd "$(dirname "${BATS_TEST_FILENAME}")/../.." && pwd)"
export CLAUDE_PROJECT_DIR="$PROJECT_ROOT"

# Temp directory for test isolation
setup() {
    TEST_TEMP="$(mktemp -d)"
    export TEST_TEMP
    # Prevent hooks from writing to real log dirs
    export AIFRED_LOG_DIR="$TEST_TEMP/logs"
    mkdir -p "$AIFRED_LOG_DIR"
}

teardown() {
    [[ -d "${TEST_TEMP:-}" ]] && rm -rf "$TEST_TEMP"
}

# Helper: check if a node module can be loaded without error
can_require() {
    node -e "require('$1')" 2>/dev/null
}
