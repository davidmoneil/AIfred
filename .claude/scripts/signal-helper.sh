#!/bin/bash
# Signal Helper Library for Jarvis
# Provides functions for creating command signals
#
# Usage:
#   source .claude/scripts/signal-helper.sh
#   send_command_signal "/compact" "Focus on code" "skill:my-skill"
#
# Or direct execution:
#   .claude/scripts/signal-helper.sh send "/compact" "args" "source"

set -euo pipefail

# Configuration
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$HOME/Claude/Jarvis}"
SIGNAL_FILE="$PROJECT_DIR/.claude/context/.command-signal"

# Supported commands (for validation)
SUPPORTED_COMMANDS=(
    "/compact" "/rename" "/resume" "/export" "/doctor"
    "/status" "/usage" "/cost" "/bashes" "/review"
    "/plan" "/security-review" "/stats" "/todos" "/context"
    "/hooks" "/release-notes" "/clear"
)

# Validate command against whitelist
validate_command() {
    local cmd="$1"
    for valid_cmd in "${SUPPORTED_COMMANDS[@]}"; do
        if [[ "$cmd" == "$valid_cmd" ]]; then
            return 0
        fi
    done
    return 1
}

# Create and write a command signal
# Args: command, args (optional), source, priority (optional)
send_command_signal() {
    local command="${1:-}"
    local args="${2:-}"
    local source="${3:-manual}"
    local priority="${4:-normal}"

    # Validate inputs
    if [[ -z "$command" ]]; then
        echo "ERROR: Command is required" >&2
        return 1
    fi

    # Ensure command starts with /
    if [[ ! "$command" =~ ^/ ]]; then
        command="/$command"
    fi

    # Validate command
    if ! validate_command "$command"; then
        echo "ERROR: Unknown command '$command'" >&2
        echo "Supported: ${SUPPORTED_COMMANDS[*]}" >&2
        return 1
    fi

    # Validate priority
    if [[ "$priority" != "immediate" && "$priority" != "normal" && "$priority" != "low" ]]; then
        echo "WARNING: Invalid priority '$priority', using 'normal'" >&2
        priority="normal"
    fi

    # Generate timestamp
    local timestamp
    timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)

    # Create JSON signal
    local signal_json
    signal_json=$(cat <<EOF
{
    "command": "$command",
    "args": "$args",
    "timestamp": "$timestamp",
    "source": "$source",
    "priority": "$priority"
}
EOF
)

    # Write signal file
    echo "$signal_json" > "$SIGNAL_FILE"

    echo "Signal created: $command ${args:+"\"$args\" "}(source: $source)"
    return 0
}

# Shorthand functions for common commands
signal_compact() {
    local instructions="${1:-}"
    local source="${2:-skill:compact}"
    send_command_signal "/compact" "$instructions" "$source"
}

signal_rename() {
    local name="${1:-}"
    local source="${2:-skill:rename}"
    if [[ -z "$name" ]]; then
        echo "ERROR: Name is required for /rename" >&2
        return 1
    fi
    send_command_signal "/rename" "$name" "$source"
}

signal_resume() {
    local session="${1:-}"
    local source="${2:-skill:resume}"
    send_command_signal "/resume" "$session" "$source"
}

signal_export() {
    local filename="${1:-}"
    local source="${2:-skill:export}"
    send_command_signal "/export" "$filename" "$source"
}

signal_status() {
    local source="${1:-skill:status}"
    send_command_signal "/status" "" "$source"
}

signal_usage() {
    local source="${1:-skill:usage}"
    send_command_signal "/usage" "" "$source"
}

signal_cost() {
    local source="${1:-skill:cost}"
    send_command_signal "/cost" "" "$source"
}

signal_stats() {
    local source="${1:-skill:stats}"
    send_command_signal "/stats" "" "$source"
}

signal_context() {
    local source="${1:-skill:context}"
    send_command_signal "/context" "" "$source"
}

signal_todos() {
    local source="${1:-skill:todos}"
    send_command_signal "/todos" "" "$source"
}

signal_hooks() {
    local source="${1:-skill:hooks}"
    send_command_signal "/hooks" "" "$source"
}

signal_bashes() {
    local source="${1:-skill:bashes}"
    send_command_signal "/bashes" "" "$source"
}

signal_doctor() {
    local source="${1:-skill:doctor}"
    send_command_signal "/doctor" "" "$source"
}

signal_review() {
    local source="${1:-skill:review}"
    send_command_signal "/review" "" "$source"
}

signal_plan() {
    local source="${1:-skill:plan}"
    send_command_signal "/plan" "" "$source"
}

signal_security_review() {
    local source="${1:-skill:security-review}"
    send_command_signal "/security-review" "" "$source"
}

signal_release_notes() {
    local source="${1:-skill:release-notes}"
    send_command_signal "/release-notes" "" "$source"
}

signal_clear() {
    local source="${1:-skill:clear}"
    send_command_signal "/clear" "" "$source" "immediate"
}

# Check if watcher is running
is_watcher_running() {
    local pid_file="$PROJECT_DIR/.claude/context/.watcher-pid"
    if [[ -f "$pid_file" ]]; then
        local pid
        pid=$(cat "$pid_file")
        if kill -0 "$pid" 2>/dev/null; then
            return 0
        fi
    fi
    return 1
}

# Get watcher status
watcher_status() {
    if is_watcher_running; then
        local pid
        pid=$(cat "$PROJECT_DIR/.claude/context/.watcher-pid")
        echo "Watcher is RUNNING (PID: $pid)"
        return 0
    else
        echo "Watcher is NOT RUNNING"
        echo "Start with: .claude/scripts/auto-command-watcher.sh"
        return 1
    fi
}

# List pending signal (if any)
pending_signal() {
    if [[ -f "$SIGNAL_FILE" ]]; then
        echo "Pending signal:"
        cat "$SIGNAL_FILE"
    else
        echo "No pending signal"
    fi
}

# CLI interface when run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "${1:-help}" in
        send)
            shift
            send_command_signal "$@"
            ;;
        compact)
            shift
            signal_compact "$@"
            ;;
        rename)
            shift
            signal_rename "$@"
            ;;
        resume)
            shift
            signal_resume "$@"
            ;;
        export)
            shift
            signal_export "$@"
            ;;
        status)
            signal_status "cli:signal-helper"
            ;;
        usage)
            signal_usage "cli:signal-helper"
            ;;
        cost)
            signal_cost "cli:signal-helper"
            ;;
        stats)
            signal_stats "cli:signal-helper"
            ;;
        context)
            signal_context "cli:signal-helper"
            ;;
        todos)
            signal_todos "cli:signal-helper"
            ;;
        hooks)
            signal_hooks "cli:signal-helper"
            ;;
        bashes)
            signal_bashes "cli:signal-helper"
            ;;
        doctor)
            signal_doctor "cli:signal-helper"
            ;;
        review)
            signal_review "cli:signal-helper"
            ;;
        plan)
            signal_plan "cli:signal-helper"
            ;;
        security-review)
            signal_security_review "cli:signal-helper"
            ;;
        release-notes)
            signal_release_notes "cli:signal-helper"
            ;;
        clear)
            signal_clear "cli:signal-helper"
            ;;
        watcher-status)
            watcher_status
            ;;
        pending)
            pending_signal
            ;;
        help|--help|-h|*)
            echo "Signal Helper - Create command signals for Jarvis watcher"
            echo ""
            echo "Usage:"
            echo "  $0 send <command> [args] [source] [priority]"
            echo "  $0 <shorthand> [args]"
            echo "  $0 watcher-status"
            echo "  $0 pending"
            echo ""
            echo "Shorthands:"
            echo "  compact [instructions]   - Signal /compact"
            echo "  rename <name>            - Signal /rename (name required)"
            echo "  resume [session]         - Signal /resume"
            echo "  export [filename]        - Signal /export"
            echo "  status                   - Signal /status"
            echo "  usage                    - Signal /usage"
            echo "  cost                     - Signal /cost"
            echo "  stats                    - Signal /stats"
            echo "  context                  - Signal /context"
            echo "  todos                    - Signal /todos"
            echo "  hooks                    - Signal /hooks"
            echo "  bashes                   - Signal /bashes"
            echo "  doctor                   - Signal /doctor"
            echo "  review                   - Signal /review"
            echo "  plan                     - Signal /plan"
            echo "  security-review          - Signal /security-review"
            echo "  release-notes            - Signal /release-notes"
            echo "  clear                    - Signal /clear"
            echo ""
            echo "Examples:"
            echo "  $0 send /compact \"Focus on code\" skill:test"
            echo "  $0 compact \"Summarize recent work\""
            echo "  $0 rename \"Feature Implementation\""
            echo "  $0 status"
            ;;
    esac
fi
