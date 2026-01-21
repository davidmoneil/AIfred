#!/bin/bash
# Auto-Command Watcher for Jarvis
# Monitors for command signals and executes via keystroke injection
#
# This script extends auto-clear-watcher.sh to support all slash commands.
# It runs in a separate terminal/tmux pane and monitors for signal files.
#
# REQUIRES: jq (JSON parsing), tmux or osascript (keystroke injection)

set -euo pipefail

# Configuration
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$HOME/Claude/Jarvis}"
SIGNAL_FILE="$PROJECT_DIR/.claude/context/.command-signal"
LEGACY_SIGNAL_FILE="$PROJECT_DIR/.claude/context/.auto-clear-signal"
LOG_FILE="$PROJECT_DIR/.claude/logs/command-signals.log"
CHECK_INTERVAL=2  # seconds

# Supported commands whitelist
SUPPORTED_COMMANDS=(
    "/compact"
    "/rename"
    "/resume"
    "/export"
    "/doctor"
    "/status"
    "/usage"
    "/cost"
    "/bashes"
    "/review"
    "/plan"
    "/security-review"
    "/stats"
    "/todos"
    "/context"
    "/hooks"
    "/release-notes"
    "/clear"  # Legacy support
)

# Commands that require arguments
REQUIRED_ARGS_COMMANDS=(
    "/rename"
)

# tmux configuration
TMUX_BIN="${TMUX_BIN:-$HOME/bin/tmux}"
TMUX_SESSION="${TMUX_SESSION:-jarvis}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Ensure log directory exists
mkdir -p "$(dirname "$LOG_FILE")"

# Banner
echo -e "${CYAN}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║           JARVIS AUTO-COMMAND WATCHER v1.0                   ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""
echo -e "  ${BLUE}Project:${NC}  $PROJECT_DIR"
echo -e "  ${BLUE}Signal:${NC}   $SIGNAL_FILE"
echo -e "  ${BLUE}Log:${NC}      $LOG_FILE"
echo -e "  ${BLUE}Status:${NC}   ${GREEN}ACTIVE${NC}"
echo ""
echo "  Supported commands:"
printf "    "
for cmd in "${SUPPORTED_COMMANDS[@]}"; do
    printf "%s " "$cmd"
done
echo ""
echo ""
echo "  This watcher executes slash commands autonomously when signals"
echo "  are created by skills or hooks."
echo ""
echo -e "  Press ${YELLOW}Ctrl+C${NC} to stop"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Log function
log_event() {
    local command="$1"
    local args="$2"
    local source="$3"
    local status="$4"
    local timestamp
    timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    echo "$timestamp | $command | \"$args\" | $source | $status" >> "$LOG_FILE"
}

# Validate command against whitelist
is_valid_command() {
    local cmd="$1"
    for valid_cmd in "${SUPPORTED_COMMANDS[@]}"; do
        if [[ "$cmd" == "$valid_cmd" ]]; then
            return 0
        fi
    done
    return 1
}

# Check if command requires arguments
requires_args() {
    local cmd="$1"
    for req_cmd in "${REQUIRED_ARGS_COMMANDS[@]}"; do
        if [[ "$cmd" == "$req_cmd" ]]; then
            return 0
        fi
    done
    return 1
}

# Sanitize arguments (basic injection prevention)
sanitize_args() {
    local args="$1"
    # Remove any potential command injection characters
    echo "$args" | tr -d '`$(){}[]|;&<>\\' | head -c 500
}

# Execute command via tmux send-keys
execute_via_tmux() {
    local full_command="$1"

    if [[ -x "$TMUX_BIN" ]] && "$TMUX_BIN" has-session -t "$TMUX_SESSION" 2>/dev/null; then
        echo -e "           ${GREEN}Using tmux send-keys (fully autonomous)...${NC}"
        "$TMUX_BIN" send-keys -t "$TMUX_SESSION" "$full_command" Enter
        return 0
    fi
    return 1
}

# Execute command via AppleScript (macOS fallback)
execute_via_applescript() {
    local full_command="$1"

    if [[ "$(uname)" == "Darwin" ]]; then
        echo -e "           ${YELLOW}Using AppleScript fallback...${NC}"
        osascript <<APPLESCRIPT
tell application "Terminal"
    activate
    delay 0.3
    repeat with w in windows
        if name of w contains "claude" then
            set frontmost of w to true
            exit repeat
        end if
    end repeat
end tell
tell application "System Events"
    tell process "Terminal"
        keystroke "$full_command"
    end tell
end tell
APPLESCRIPT
        # Play alert sound
        afplay /System/Library/Sounds/Glass.aiff &
        echo ""
        echo -e "           ${YELLOW}╔══════════════════════════════════════════════════════╗${NC}"
        echo -e "           ${YELLOW}║  Command typed - PRESS ENTER TO EXECUTE             ║${NC}"
        echo -e "           ${YELLOW}╚══════════════════════════════════════════════════════╝${NC}"
        return 0
    fi
    return 1
}

# Execute command via xdotool (Linux fallback)
execute_via_xdotool() {
    local full_command="$1"

    if command -v xdotool &> /dev/null; then
        echo -e "           ${YELLOW}Using xdotool...${NC}"
        CURRENT_WINDOW=$(xdotool getactivewindow)
        xdotool search --name "Terminal" | while read WID; do
            if [[ "$WID" != "$CURRENT_WINDOW" ]]; then
                xdotool windowactivate "$WID"
                break
            fi
        done
        sleep 0.3
        xdotool type "$full_command"
        xdotool key Return
        return 0
    fi
    return 1
}

# Process a command signal
process_signal() {
    local signal_content="$1"
    local signal_file="$2"

    # Parse JSON
    local command args timestamp source priority

    if ! command -v jq &> /dev/null; then
        echo -e "           ${RED}ERROR: jq not installed${NC}"
        log_event "unknown" "" "unknown" "ERROR: jq not installed"
        return 1
    fi

    command=$(echo "$signal_content" | jq -r '.command // empty')
    args=$(echo "$signal_content" | jq -r '.args // ""')
    timestamp=$(echo "$signal_content" | jq -r '.timestamp // "unknown"')
    source=$(echo "$signal_content" | jq -r '.source // "unknown"')
    priority=$(echo "$signal_content" | jq -r '.priority // "normal"')

    if [[ -z "$command" ]]; then
        echo -e "           ${RED}ERROR: No command in signal${NC}"
        log_event "empty" "" "$source" "ERROR: No command"
        return 1
    fi

    echo ""
    echo -e "$(date +%H:%M:%S) ${CYAN}SIGNAL DETECTED${NC}"
    echo -e "           Command:   ${GREEN}$command${NC}"
    echo -e "           Args:      $args"
    echo -e "           Source:    $source"
    echo -e "           Priority:  $priority"
    echo -e "           Timestamp: $timestamp"

    # Validate command
    if ! is_valid_command "$command"; then
        echo -e "           ${RED}ERROR: Unknown command '$command'${NC}"
        log_event "$command" "$args" "$source" "ERROR: Unknown command"
        return 1
    fi

    # Check required args
    if requires_args "$command" && [[ -z "$args" ]]; then
        echo -e "           ${RED}ERROR: Command '$command' requires arguments${NC}"
        log_event "$command" "" "$source" "ERROR: Missing required args"
        return 1
    fi

    # Sanitize arguments
    args=$(sanitize_args "$args")

    # Build full command
    local full_command="$command"
    if [[ -n "$args" ]]; then
        full_command="$command $args"
    fi

    echo -e "           Executing: ${BLUE}$full_command${NC}"
    echo -e "           Waiting 1s before injection..."
    sleep 1

    # Try execution methods in order
    if execute_via_tmux "$full_command"; then
        echo -e "           ${GREEN}SUCCESS via tmux${NC}"
        log_event "$command" "$args" "$source" "SUCCESS:tmux"
    elif execute_via_applescript "$full_command"; then
        echo -e "           ${YELLOW}TYPED via AppleScript (press Enter)${NC}"
        log_event "$command" "$args" "$source" "SUCCESS:applescript"
    elif execute_via_xdotool "$full_command"; then
        echo -e "           ${GREEN}SUCCESS via xdotool${NC}"
        log_event "$command" "$args" "$source" "SUCCESS:xdotool"
    else
        echo -e "           ${RED}FAILED: No execution method available${NC}"
        log_event "$command" "$args" "$source" "ERROR: No execution method"
        return 1
    fi

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    return 0
}

# Handle legacy /clear signal (backwards compatibility)
process_legacy_signal() {
    local signal_time="$1"

    echo ""
    echo -e "$(date +%H:%M:%S) ${YELLOW}LEGACY SIGNAL DETECTED${NC}"
    echo -e "           Type: /clear (auto-clear-signal)"
    echo -e "           Time: $signal_time"

    # Convert to new format and process
    local signal_json
    signal_json=$(cat <<EOF
{
    "command": "/clear",
    "args": "",
    "timestamp": "$signal_time",
    "source": "legacy:auto-clear-signal",
    "priority": "immediate"
}
EOF
)

    process_signal "$signal_json" "$LEGACY_SIGNAL_FILE"
}

# Cleanup handler
cleanup() {
    rm -f "$SIGNAL_FILE" 2>/dev/null
    rm -f "$LEGACY_SIGNAL_FILE" 2>/dev/null
    echo ""
    echo -e "${YELLOW}Watcher stopped${NC}"
    exit 0
}
trap cleanup INT TERM

# Record PID
echo $$ > "$PROJECT_DIR/.claude/context/.watcher-pid"

# Main loop
while true; do
    # Check for new-style command signal
    if [[ -f "$SIGNAL_FILE" ]]; then
        signal_content=$(cat "$SIGNAL_FILE")
        rm -f "$SIGNAL_FILE"

        if process_signal "$signal_content" "$SIGNAL_FILE"; then
            : # Success
        else
            echo -e "           ${RED}Signal processing failed${NC}"
        fi
    fi

    # Check for legacy clear signal (backwards compatibility)
    if [[ -f "$LEGACY_SIGNAL_FILE" ]]; then
        signal_time=$(cat "$LEGACY_SIGNAL_FILE")
        rm -f "$LEGACY_SIGNAL_FILE"

        # Also remove pending marker if exists
        rm -f "$PROJECT_DIR/.claude/context/.clear-pending" 2>/dev/null

        process_legacy_signal "$signal_time"
    fi

    sleep $CHECK_INTERVAL
done
